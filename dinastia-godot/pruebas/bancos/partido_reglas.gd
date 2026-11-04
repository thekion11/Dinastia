extends BaseIdea
## BANCO ESPECIALIZADO «partido_reglas», FASE 2 (4-11-2026, megarreforma de los bancos): el REGLAMENTO del partido simulado.
## No mira la IA ni la física (eso es de la sesión PES 6 y del dueño): solo que el acta y la tabla cumplan las reglas.
##   1. ACTA de 40 partidos: marcador = goles avisados = goles en la crónica; cada gol de alguien que está en el campo,
##      asistente distinto del autor y del mismo club; minutos dentro del partido; estadísticas no negativas y coherentes;
##      once inicial de 11 sin repetidos, sin lesionados ni sancionados y sin nadie en los dos equipos.
##   2. CAMBIOS: como mucho 5 (+1 en la prórroga); el que sale no vuelve a entrar; un lesionado no entra.
##   3. PRÓRROGA Y PENALES: solo con empate a los 90; la tanda nunca termina empatada.
##   4. MENOS DE SIETE: con 5 rojas el partido se suspende y se da por perdido 3-0.
##   5. DISCIPLINA: la 5.ª amarilla de la temporada sanciona; la roja sanciona el partido SIGUIENTE (no se descuenta esa
##      misma semana); un sancionado no sale en el once siguiente. (También se mira en cada tarjeta de los 40 partidos.)
##   6. TABLA tras 12 semanas: puntos = 3G + E, PJ = G + E + P, goles a favor = goles en contra, victorias = derrotas.
## Lo que antes era SIMPLIFICACIÓN del simulado (la roja no sacaba a nadie del once; arreglado en A4-PAR-L01) sigue como AVISO.

var _goles_aviso := {"l": 0, "v": 0}
var _en_campo := {}        ## jugador id -> "l" / "v" mientras esté en el campo
var _salieron := {}        ## los que ya dejaron el campo por un cambio
var _malos: Array[String] = []
var _rojas := {}           ## jugador id -> minuto de su roja
var _tras_roja := 0        ## goles de jugadores ya expulsados (aviso)
var _rojas_simples := 0    ## rojas por «segunda amarilla» con una sola amarilla en ESTE partido (aviso)
var _amarillas_hoy := {}

func _probar() -> void:
	_titulo("BANCO PARTIDO_REGLAS (fase 2): acta, cambios, prórroga, menos de siete, disciplina y tabla")
	var m := _mundo_n(5150, 2)
	_actas(m)
	_cambios(m)
	_prorroga_y_penales(m)
	_menos_de_siete(m)
	_disciplina(m)
	_tabla(_mundo_n(6060, 12))

func _mundo_n(semilla: int, semanas: int) -> Mundo:
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI", "ARG"]
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for i in semanas:
		m.avanzar_semana()
	return m

func _pareja(m: Mundo, i: int) -> Array[Club]:
	var l: Liga = m.ligas[i % m.ligas.size()]
	var a: Club = l.clubes[(i * 3) % l.clubes.size()]
	var b: Club = l.clubes[(i * 3 + 1 + i % 5) % l.clubes.size()]
	if a == b:
		b = l.clubes[(l.clubes.find(a) + 1) % l.clubes.size()]
	return [a, b]

func _malo(texto: String) -> void:
	if _malos.size() < 12:
		_malos.append(texto)

# --- 1. ACTA ---------------------------------------------------------------------------------------------------------------------

func _actas(m: Mundo) -> void:
	var n_goles := 0
	var n_cambios := 0
	for i in 40:
		Azar.sembrar(9000 + i)
		var par := _pareja(m, i)
		var p := Partido.new(par[0], par[1])
		_vigilar(p)
		p.preparar()
		_once_inicial(p, i)
		while not p.terminado_ya:
			p.simular_minuto()
		_acta(p, i)
		n_goles += p.goles_local + p.goles_visita
		n_cambios += p.cambios_local + p.cambios_visita
	_comprobar(_malos.is_empty(), "40 partidos (%d goles, %d cambios): el acta cumple el reglamento%s" % [n_goles, n_cambios, "" if _malos.is_empty() else " — " + str(_malos)])
	_comprobar(n_goles > 40, "  hubo goles que mirar (%d)" % n_goles)
	print("  AVISO (simplificación del simulado): goles de jugadores ya expulsados: %d; rojas por «segunda amarilla» con una sola amarilla en el partido: %d" % [_tras_roja, _rojas_simples])

func _vigilar(p: Partido) -> void:
	_goles_aviso = {"l": 0, "v": 0}
	_en_campo.clear()
	_salieron.clear()
	_rojas.clear()
	_amarillas_hoy.clear()
	p.gol.connect(func(c: Club, autor: Jugador, minuto: int, asistente: Jugador) -> void:
		var lado := "l" if c == p.local else "v"
		_goles_aviso[lado] = int(_goles_aviso[lado]) + 1
		if minuto < 0 or minuto > p.minutos_fin:
			_malo("gol en el minuto %d (fin %d)" % [minuto, p.minutos_fin])
		if autor != null:
			if String(_en_campo.get(autor.id, "")) != lado:
				_malo("gol de %s, que no está en el campo con %s (min %d)" % [autor.nombre, c.nombre, minuto])
			if _rojas.has(autor.id):
				_tras_roja += 1
		if asistente != null and (asistente == autor or String(_en_campo.get(asistente.id, "")) != lado):
			_malo("asistencia imposible de %s (min %d)" % [asistente.nombre, minuto]))
	p.cambio_hecho.connect(func(sale: Jugador, entra: Jugador, minuto: int) -> void:
		var lado := String(_en_campo.get(sale.id, ""))
		if lado == "":
			_malo("sale %s, que no estaba en el campo (min %d)" % [sale.nombre, minuto])
		if _salieron.has(entra.id):
			_malo("%s vuelve a entrar después de salir (min %d)" % [entra.nombre, minuto])
		_en_campo.erase(sale.id)
		_salieron[sale.id] = true
		_en_campo[entra.id] = lado)
	p.tarjeta.connect(func(j: Jugador, roja: bool, minuto: int) -> void:
		_amarillas_hoy[j.id] = int(_amarillas_hoy.get(j.id, 0)) + 1
		if minuto < 0 or minuto > p.minutos_fin:
			_malo("tarjeta en el minuto %d" % minuto)
		if roja and (j.suspension < 1 or j.susp_semana != Jugador.semana_global):
			_malo("la roja de %s no lo sanciona para el próximo partido (sanción %d, semana %d)" % [j.nombre, j.suspension, j.susp_semana])
		if not roja and j.amarillas > 0 and j.amarillas % Disciplina.AMARILLAS_CICLO == 0 and j.suspension < 1:
			_malo("%s llega a %d amarillas y no queda sancionado" % [j.nombre, j.amarillas])
		if roja:
			if _rojas.has(j.id):
				_malo("%s ve dos rojas" % j.nombre)
			_rojas[j.id] = minuto
			if int(_amarillas_hoy[j.id]) < 2:
				_rojas_simples += 1)

func _once_inicial(p: Partido, i: int) -> void:
	for lado in ["l", "v"]:
		var once: Array[Jugador] = p.once_local if lado == "l" else p.once_visita
		var club: Club = p.local if lado == "l" else p.visita
		if once.size() != 11:
			_malo("partido %d: %s sale con %d" % [i, club.nombre, once.size()])
		for j: Jugador in once:
			if _en_campo.has(j.id):
				_malo("partido %d: %s está dos veces en el campo" % [i, j.nombre])
			if not j.disponible():
				_malo("partido %d: %s juega lesionado o sancionado" % [i, j.nombre])
			if not club.plantilla.has(j):
				_malo("partido %d: %s no es de %s" % [i, j.nombre, club.nombre])
			_en_campo[j.id] = lado

func _acta(p: Partido, i: int) -> void:
	var cron := {"l": 0, "v": 0}
	for e: Dictionary in p.cronica:
		if String(e.get("tipo", "")) == "gol":
			cron["l" if String(e.get("club", "")) == p.local.id else "v"] += 1
		var mi := int(e.get("min", 0))
		if mi < 0 or mi > p.minutos_fin:
			_malo("partido %d: crónica en el minuto %d" % [i, mi])
	if p.goles_local != int(_goles_aviso["l"]) or p.goles_visita != int(_goles_aviso["v"]) or p.goles_local != int(cron["l"]) or p.goles_visita != int(cron["v"]):
		_malo("partido %d: marcador %d-%d, avisados %s, crónica %s" % [i, p.goles_local, p.goles_visita, _goles_aviso, cron])
	var nums := [p.remates_local, p.remates_visita, p.tiros_puerta_local, p.tiros_puerta_visita, p.corners_local, p.corners_visita,
		p.faltas_local, p.faltas_visita, p.fueras_local, p.fueras_visita]
	if nums.any(func(x: int) -> bool: return x < 0) or p.xg_local < 0.0 or p.xg_visita < 0.0:
		_malo("partido %d: estadística negativa %s" % [i, nums])
	if p.tiros_puerta_local > p.remates_local or p.tiros_puerta_visita > p.remates_visita:
		_malo("partido %d: más tiros a puerta que remates (%d/%d, %d/%d)" % [i, p.tiros_puerta_local, p.remates_local, p.tiros_puerta_visita, p.remates_visita])
	if p.posesion_local < 0.0 or p.posesion_local > 100.0:
		_malo("partido %d: posesión %.1f" % [i, p.posesion_local])
	if p.cambios_local > Partido.MAX_CAMBIOS + p.cambios_extra or p.cambios_visita > Partido.MAX_CAMBIOS + p.cambios_extra:
		_malo("partido %d: cambios %d/%d" % [i, p.cambios_local, p.cambios_visita])
	if p.once_local.size() > 11 or p.once_visita.size() > 11:
		_malo("partido %d: más de 11 en el campo" % i)

# --- 2. CAMBIOS ------------------------------------------------------------------------------------------------------------------

func _banquillo(c: Club, once: Array[Jugador]) -> Array[Jugador]:
	var out: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if not once.has(j) and j.disponible():
			out.append(j)
	return out

func _cambios(m: Mundo) -> void:
	Azar.sembrar(31)
	var par := _pareja(m, 7)
	var p := Partido.new(par[0], par[1])
	p.preparar()
	for k in 30:
		p.simular_minuto()
	var banco := _banquillo(p.local, p.once_local)
	if banco.size() < 7:
		_comprobar(false, "hay banquillo para probar los cambios (%d)" % banco.size())
		return
	var primero_sale: Jugador = p.once_local[10]
	var errores: Array[String] = []
	for k in 5:
		errores.append(p.cambiar(p.once_local[10 - k], banco[k]))
	_comprobar(errores.all(func(e: String) -> bool: return e == ""), "se pueden hacer los 5 cambios%s" % ("" if errores.all(func(e: String) -> bool: return e == "") else ": " + str(errores)))
	var sexto := p.cambiar(p.once_local[1], banco[5])
	_comprobar(sexto != "", "el 6.º cambio se rechaza («%s»)" % sexto)
	## El que salió no vuelve: se prueba con cupo libre (prórroga).
	p.cambios_extra = 1
	var vuelve := p.cambiar(p.once_local[1], primero_sale)
	_comprobar(vuelve != "", "el que salió no puede volver a entrar%s" % ("" if vuelve != "" else " (ENTRÓ OTRA VEZ)"))
	p.cambios_extra = 3   ## cupo libre: que el rechazo sea por la lesión, no por los cambios
	var lesionado: Jugador = banco[6]
	var antes := lesionado.lesion
	lesionado.lesion = 3
	var les := p.cambiar(p.once_local[2], lesionado)
	lesionado.lesion = antes
	_comprobar(les.contains("condiciones"), "un lesionado no puede entrar («%s»)" % les)

# --- 3. PRÓRROGA Y PENALES -------------------------------------------------------------------------------------------------------

func _prorroga_y_penales(m: Mundo) -> void:
	var empates := 0
	var raros: Array[String] = []
	for i in 30:
		Azar.sembrar(700 + i)
		var par := _pareja(m, i + 11)
		var p := Partido.new(par[0], par[1])
		p.prorroga_si_empate = true
		var a_los_90 := [-1, -1]
		p.minuto_jugado.connect(func(mi: int) -> void:
			if mi == Partido.MINUTOS:
				a_los_90[0] = p.goles_local
				a_los_90[1] = p.goles_visita)
		p.simular()
		var hubo := p.minutos_fin > Partido.MINUTOS
		if hubo != (a_los_90[0] == a_los_90[1]):
			raros.append("partido %d: %d-%d a los 90 y prórroga=%s" % [i, a_los_90[0], a_los_90[1], hubo])
		if hubo:
			empates += 1
			if p.cambios_extra != 1:
				raros.append("partido %d: prórroga sin el cambio extra" % i)
			if p.goles_local == p.goles_visita:
				var pen := p.penales()
				if pen.size() != 2 or int(pen[0]) == int(pen[1]) or int(pen[0]) < 0 or int(pen[1]) < 0:
					raros.append("partido %d: tanda %s" % [i, pen])
	_comprobar(raros.is_empty(), "30 partidos de eliminatoria: prórroga solo con empate a los 90 y la tanda nunca empata%s" % ("" if raros.is_empty() else " — " + str(raros.slice(0, 5))))
	_comprobar(empates > 0, "  hubo prórrogas que mirar (%d)" % empates)

# --- 4. MENOS DE SIETE -----------------------------------------------------------------------------------------------------------

func _menos_de_siete(m: Mundo) -> void:
	Azar.sembrar(77)
	var par := _pareja(m, 3)
	var p := Partido.new(par[0], par[1])
	p.preparar()
	for k in 20:
		p.simular_minuto()
	var ids: Array[String] = []
	for j: Jugador in p.once_local.slice(0, 5):
		ids.append(j.id)
	var guardado := {}
	for j: Jugador in p.once_local:
		guardado[j] = [j.amarillas, j.suspension, j.susp_semana]
	for id in ids:
		p.tarjeta_externa(id, true)
	_comprobar(p.terminado_ya and p.goles_local == 0 and p.goles_visita == 3, "con 5 rojas (6 en el campo) el partido se suspende y se pierde 0-3 (%d-%d, terminado %s)" % [p.goles_local, p.goles_visita, p.terminado_ya])
	for j: Jugador in guardado:
		j.amarillas = guardado[j][0]
		j.suspension = guardado[j][1]
		j.susp_semana = guardado[j][2]

# --- 5. DISCIPLINA ---------------------------------------------------------------------------------------------------------------

func _disciplina(m: Mundo) -> void:
	var c := m.mi_club()
	var j: Jugador = c.once()[3]
	var antes := [j.amarillas, j.suspension]
	j.amarillas = Disciplina.AMARILLAS_CICLO - 1
	j.suspension = 0
	j.amarillas += 1
	_comprobar(Disciplina.acumula(j) and j.suspension >= 1, "la %d.ª amarilla de la temporada sanciona un partido" % Disciplina.AMARILLAS_CICLO)
	_comprobar(not c.once().has(j), "un sancionado no sale en el once siguiente")
	j.amarillas = antes[0]
	j.suspension = antes[1]

# --- 6. TABLA --------------------------------------------------------------------------------------------------------------------

func _tabla(m: Mundo) -> void:
	var raros: Array[String] = []
	var ligas := 0
	for l: Liga in m.ligas:
		var gf := 0
		var gc := 0
		var g := 0
		var p := 0
		var pj_min := 1 << 30
		var pj_max := 0
		for f: Dictionary in l.tabla():
			var c: Club = f["club"]
			var d: Dictionary = l.tabla_puntos[c.id]
			if int(d["pts"]) != l.puntos_victoria * int(d["g"]) + int(d["e"]) - _descuento(l, c):
				raros.append("%s: %d pts con %d-%d-%d" % [c.nombre, int(d["pts"]), int(d["g"]), int(d["e"]), int(d["p"])])
			if int(d["pj"]) != int(d["g"]) + int(d["e"]) + int(d["p"]):
				raros.append("%s: PJ %d ≠ G+E+P" % [c.nombre, int(d["pj"])])
			gf += int(d["gf"]); gc += int(d["gc"]); g += int(d["g"]); p += int(d["p"])
			pj_min = mini(pj_min, int(d["pj"])); pj_max = maxi(pj_max, int(d["pj"]))
		if gf != gc or g != p:
			raros.append("%s: GF %d / GC %d, G %d / P %d" % [l.nombre, gf, gc, g, p])
		if pj_max - pj_min > 1:
			raros.append("%s: partidos jugados de %d a %d" % [l.nombre, pj_min, pj_max])
		if pj_max > 0:
			ligas += 1
	_comprobar(raros.is_empty(), "12 semanas: en las tablas puntos = %s·G + E, PJ = G+E+P, GF = GC, G = P y todos con los mismos partidos%s" % ["3", "" if raros.is_empty() else " — " + str(raros.slice(0, 6))])
	_comprobar(ligas > 0, "  hubo ligas con partidos (%d)" % ligas)

## Puntos que la federación le quitó al club (sanciones): no son de la cancha.
func _descuento(l: Liga, c: Club) -> int:
	if "descuentos" in l:
		return int(l.descuentos.get(c.id, 0))
	return 0
