extends "res://pruebas/banco_p3.gd"
## [Capa 4/27 de `banco.gd`] _probar_banquillo, _dinero, _probar_finanzas, _probar_mercado, _probar_puente3d, _probar_notas … (+1)

func _probar_banquillo() -> void:
	_titulo("BANQUILLO: ONCE, CAMBIOS Y PENALES")
	var m := Mundo.new()
	m.generar(["CHI"], 1234)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]

	## El once que elige el entrenador manda sobre el automatico.
	var mio: Array[Jugador] = []
	var libres := a.disponibles()
	for i in 11:
		mio.append(libres[i])
	a.fijar_once(mio)
	var salido := a.once()
	var coincide := salido.size() == 11
	if coincide:
		for i in 11:
			if salido[i] != mio[i]:
				coincide = false
				break
	_comprobar(coincide, "el once elegido a mano es el que sale al campo")
	## Y si uno de los elegidos se lesiona, se arma el automatico en vez de
	## sacar a diez: es el caso que rompe un once guardado de la semana pasada.
	mio[5].lesion = 3
	_comprobar(a.once().size() == 11, "con un titular lesionado sigue saliendo un once de 11")
	mio[5].lesion = 0
	a.limpiar_once()

	var p := Partido.new(a, b)
	p.preparar()
	for i in 20:
		p.simular_minuto()
	var titular: Jugador = p.once_local[7]
	var suplente: Jugador = null
	for j in a.plantilla:
		if not p.once_local.has(j) and j.disponible():
			suplente = j
			break
	var fuerza_antes: float = p.fuerza(p.once_local, a)["ata"]
	_comprobar(p.cambiar(titular, suplente) == "", "se puede hacer un cambio")
	_comprobar(p.once_local.has(suplente) and not p.once_local.has(titular), "el suplente entra y el titular sale")
	_comprobar(p.cambiar(titular, suplente) != "", "no se puede sacar a quien ya no esta en el campo")
	## Lo que de verdad importa: que el cambio SE NOTE. Si la fuerza cacheada no
	## se invalida, el equipo sigue jugando con el once que ya no esta ahi y la
	## pizarra es un menu decorativo.
	var fuerza_despues: float = p.fuerza(p.once_local, a)["ata"]
	_comprobar(not is_equal_approx(fuerza_antes, fuerza_despues) or titular.ovr == suplente.ovr,
		"cambiar a alguien cambia la fuerza del equipo")

	## El tope de cinco.
	var hechos := 1
	for j in a.plantilla:
		if hechos >= 8:
			break
		if p.once_local.has(j) or not j.disponible():
			continue
		if p.cambiar(p.once_local[0], j) == "":
			hechos += 1
	_comprobar(p.cambios_local == Partido.MAX_CAMBIOS, "no se pueden hacer mas de %d cambios (van %d)" % [
		Partido.MAX_CAMBIOS, p.cambios_local])

	## Penales: nunca pueden acabar en empate.
	## `penales()` quedó memoizado (`partido_vivo.gd` puede resolverlos en vivo y
	## `Copa.jugar_ronda()` los vuelve a pedir después sobre el MISMO objeto, y
	## sin caché el visor podía anunciar un ganador distinto del que la copa
	## calculaba al avanzar la semana) -así que probar 200 tandas hace falta un
	## `Partido` nuevo cada vez, o las 200 vueltas leerían la primera memoizada.
	var empates := 0
	for i in 200:
		var pp := Partido.new(a, b)
		var r := pp.penales()
		if r[0] == r[1]:
			empates += 1
	_comprobar(empates == 0, "una tanda de penales nunca acaba empatada (%d de 200)" % empates)

	## Y el partido dirigido: su resultado tiene que ser el que va a la tabla.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 31)
	m2.mi_club_id = m2.ligas[0].clubes[2].id
	var par := m2.proximo_partido()
	_comprobar(par.size() == 2, "hay partido esta jornada")
	var dirigido := Partido.new(par[0], par[1])
	dirigido.simular()
	## Se fuerza un marcador imposible de repetir por azar: si en la tabla
	## aparece otro numero, es que la jornada lo volvio a simular por dentro.
	dirigido.goles_local = 7
	dirigido.goles_visita = 3
	m2.avanzar_semana(dirigido)
	var liga := m2.liga_de(m2.mi_club())
	var gf_local := 0
	var gc_local := 0
	for fila: Dictionary in liga.tabla():
		if fila["club"] == par[0]:
			gf_local = fila["gf"]
			gc_local = fila["gc"]
	_comprobar(gf_local == 7 and gc_local == 3,
		"el resultado del partido dirigido es el que va a la tabla (%d-%d)" % [gf_local, gc_local])

func _dinero(n: int) -> String:
	var euros := float(n) * Eco.ECO
	if euros >= 1000000.0:
		return "%.1fM EUR" % (euros / 1000000.0)
	return "%dk EUR" % int(euros / 1000.0)

func _probar_finanzas() -> void:
	_titulo("FINANZAS")
	var m := Mundo.new()
	m.generar(["CHI"], 88)
	var c: Club = m.ligas[0].clubes[0]
	var f := Finanzas.new(c)
	_linea("  %s: aforo %d, %d socios, entrada %.1f" % [c.nombre, c.estadio_aforo, c.socios, c.precio_entrada])
	var base := f.asistencia()
	_linea("  asistencia con entrada a 6: %d (%.0f%% del aforo)" % [base, 100.0 * float(base) / float(c.estadio_aforo)])
	## Subir el precio tiene que VACIAR el estadio, o el precio no es una
	## decision: es un boton de dinero gratis.
	c.precio_entrada = 14.0
	var cara := f.asistencia()
	c.precio_entrada = 2.0
	var barata := f.asistencia()
	c.precio_entrada = 6.0
	_linea("  a 14 entran %d, a 2 entran %d" % [cara, barata])
	_comprobar(cara < base and base < barata, "el precio de la entrada mueve la asistencia en el sentido correcto")
	_comprobar(f.asistencia() >= int(float(c.estadio_aforo) * 0.12), "nunca baja del 12% del aforo")
	c.precio_entrada = 99.0
	_comprobar(f.asistencia() >= int(float(c.estadio_aforo) * 0.12), "ni con la entrada a 99 se vacia del todo")
	c.precio_entrada = 6.0
	## Una semana con partido en casa tiene que dejar mas que una sin el.
	var antes := c.saldo
	f.semana(true)
	var con_casa := c.saldo - antes
	c.saldo = antes
	f.semana(false)
	var sin_casa := c.saldo - antes
	c.saldo = antes
	_linea("  semana en casa: %s   |   semana fuera: %s" % [_dinero(con_casa), _dinero(sin_casa)])
	_comprobar(con_casa > sin_casa, "jugar en casa deja mas dinero que jugar fuera")

	## El cierre de mes, que es donde se paga todo de golpe.
	var m4 := f.mes()
	c.saldo = antes
	_linea("  cierre de mes: entran %s, salen %s, neto %s" % [
		_dinero(m4["entra"]), _dinero(m4["sale"]), _dinero(m4["neto"])])
	_comprobar(m4["entra"] > 0 and m4["sale"] > 0, "el mes tiene ingresos y gastos")

	## Y lo que de verdad importa: que un club llevado por la IA ni quiebre ni se
	## haga de oro solo con dejar pasar el tiempo. Es la prueba que caza los
	## errores de unidades, que son los que no hacen ruido.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 606)
	var vigilados: Array[Club] = [m2.ligas[0].clubes[0], m2.ligas[0].clubes[8], m2.ligas[1].clubes[0]]
	var caja0: Array[int] = []
	for v in vigilados:
		caja0.append(v.saldo)
	for temporada in 3:
		m2.jugar_temporada()
		m2.nueva_temporada()
	var rotos := 0
	var ricos := 0
	for i in vigilados.size():
		var v := vigilados[i]
		var factor := float(v.saldo) / float(maxi(caja0[i], 1))
		_linea("  %-22s %s -> %s  (x%.1f)" % [v.nombre, _dinero(caja0[i]), _dinero(v.saldo), factor])
		if v.saldo < 0:
			rotos += 1
		if factor > 12.0:
			ricos += 1
	_comprobar(rotos == 0, "ningun club quiebra en tres temporadas (%d)" % rotos)
	_comprobar(ricos == 0, "ningun club multiplica su caja por doce sin hacer nada (%d)" % ricos)

func _probar_mercado() -> void:
	_titulo("MERCADO DE FICHAJES")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	var mk := m.mercado
	var grande: Club = null
	var chico: Club = null
	for c: Club in m.clubes.values():
		if grande == null or c.rep > grande.rep: grande = c
		if chico == null or c.rep < chico.rep: chico = c
	_linea("  club grande: %s (rep %d)   club chico: %s (rep %d)" % [grande.nombre, grande.rep, chico.nombre, chico.rep])

	## La joya de 20 con techo alto tiene que costar bastante mas que su valor.
	var joya := Jugador.new()
	joya.club_id = chico.id
	joya.edad = 20; joya.ovr = 75; joya.pot = 90; joya.anios_contrato = 4
	joya.tasar()
	var normal := Jugador.new()
	normal.club_id = chico.id
	normal.edad = 27; normal.ovr = 75; normal.pot = 75; normal.anios_contrato = 4
	normal.tasar()
	_linea("  joya de 20 (75/90): valor %s, piden %s" % [_dinero(joya.valor), _dinero(mk.valor_pedido(joya))])
	_linea("  jugador de 27 (75/75): valor %s, piden %s" % [_dinero(normal.valor), _dinero(mk.valor_pedido(normal))])
	_comprobar(mk.valor_pedido(joya) > mk.valor_pedido(normal), "por la joya piden mas que por el hecho")
	_comprobar(mk.valor_pedido(joya) > joya.valor, "el club pide por encima del valor de tasacion")

	## El deseo de venir: al grande se va casi cualquiera, al chico no.
	var suyo: Jugador = grande.plantilla[0]
	suyo.club_id = grande.id
	var al_chico: float = mk.deseo_de_venir(suyo, chico)["p"]
	var del_chico: Jugador = chico.plantilla[0]
	var al_grande: float = mk.deseo_de_venir(del_chico, grande)["p"]
	_linea("  del grande al chico: %.0f%% de ganas   |   del chico al grande: %.0f%%" % [al_chico * 100.0, al_grande * 100.0])
	_comprobar(al_grande > al_chico, "se quiere subir de club, no bajar")
	var razones: Array = mk.deseo_de_venir(suyo, chico)["razones"]
	_comprobar(razones.size() > 0, "la negativa viene con motivos que se le pueden ensenar al jugador")

	## Y el que no quiere venir se pone caro en vez de decir que no.
	var pide_al_chico := mk.ficha_que_pide(suyo, chico)
	var pide_al_grande := mk.ficha_que_pide(suyo, grande)
	_linea("  ficha que pide: al chico %s, al grande %s" % [_dinero(pide_al_chico), _dinero(pide_al_grande)])
	_comprobar(pide_al_chico > pide_al_grande, "al club que no le seduce le pide mas ficha")

	## Regateo: el club acepta cerca de lo pedido y nunca una miseria.
	var pedido := mk.valor_pedido(normal)
	_comprobar(mk.club_acepta(normal, pedido), "acepta lo que pide")
	_comprobar(not mk.club_acepta(normal, int(float(pedido) * 0.5)), "no acepta la mitad")

	## El mercado de la IA tiene que mover el mundo, pero sin deshacerlo.
	var antes_totales := m.cuantos_jugadores()
	var hechos := 0
	for semana in 20:
		hechos += mk.mover().size()
	_linea("  %d traspasos entre clubes de la IA en 20 semanas" % hechos)
	_comprobar(hechos > 0, "el mercado de la IA mueve jugadores")
	_comprobar(m.cuantos_jugadores() == antes_totales, "no se pierde ni se duplica ningun jugador (%d)" % m.cuantos_jugadores())
	var cortas := 0
	var sin_club := 0
	for c: Club in m.clubes.values():
		if c.plantilla.size() < 18:
			cortas += 1
		for j in c.plantilla:
			if j.club_id != c.id:
				sin_club += 1
	_comprobar(cortas == 0, "ningun club se queda corto de plantilla por vender (%d)" % cortas)
	_comprobar(sin_club == 0, "cada jugador apunta al club en el que esta (%d descuadrados)" % sin_club)

	## jugador_por_id(): lo usa el comparador nuevo de la ficha para resolver
	## los tres ids que guarda `_comparar_ids` en memoria.
	var cualquiera: Jugador = grande.plantilla[0]
	_comprobar(m.jugador_por_id(cualquiera.id) == cualquiera, "jugador_por_id encuentra al jugador correcto")
	_comprobar(m.jugador_por_id("no-existe-esto") == null, "jugador_por_id no encuentra lo que no existe")

func _probar_puente3d() -> void:
	_titulo("PUENTE AL 3D (los 22 al campo)")
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	_linea("  %s viste %s / %s   |   %s viste %s / %s" % [
		a.nombre, a.color1, a.color2, b.nombre, b.color1, b.color2])
	_comprobar(a.color1 != "" and a.color1.begins_with("#"), "el club conserva su color de camiseta")

	var once := Puente3D.once(a.once())
	_comprobar(once["xi"].size() == 11, "el once que va al 3D tiene 11 (%d)" % once["xi"].size())
	_comprobar(once["jugadores"].size() == 11, "hay una ficha por jugador")
	var primero: Dictionary = once["jugadores"][once["xi"][0]]
	_comprobar(primero.has("dorsal") and primero.has("look") and primero.has("alt"),
		"la ficha trae dorsal, aspecto y altura")

	## Las alturas por demarcacion: el central tiene que ser mas alto que el
	## lateral, o el once parece una fila de clones.
	var alt_dfc: float = Puente3D.ALTURA["DFC"]
	var alt_ld: float = Puente3D.ALTURA["LD"]
	_linea("  altura: central %.2f m, lateral %.2f m, portero %.2f m" % [
		alt_dfc, alt_ld, Puente3D.ALTURA["POR"]])
	_comprobar(alt_dfc > alt_ld, "el central es mas alto que el lateral")

	## El aspecto tiene que ser ESTABLE: el mismo jugador, la misma cara siempre.
	var j: Jugador = a.once()[3]
	_comprobar(Puente3D.jugador(j)["look"]["piel"] == Puente3D.jugador(j)["look"]["piel"],
		"el mismo jugador tiene siempre el mismo aspecto")

	## Y el portero tiene que CONTRASTAR con sus companeros, o desde la camara
	## alta no se distingue del central.
	var kp := Puente3D.kit_portero(a)
	var d := Puente3D._distancia(Color(kp["c1"]), Color(a.color1))
	_linea("  %s de campo %s, portero %s" % [a.nombre, a.color1, kp["c1"]])
	_comprobar(d > 0.25, "la camiseta del portero contrasta con la del equipo (%.2f)" % d)

	## Y la formacion tiene que traer sus once ranuras del catalogo del HTML.
	var f := Puente3D.formacion(a.tactica.formacion)
	_comprobar(f.get("s", []).size() == 11, "la formacion %s trae 11 ranuras" % a.tactica.formacion)

func _probar_notas() -> void:
	_titulo("NOTAS POR PARTIDO")
	var m := Mundo.new()
	m.generar(["CHI"], 8080)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[10]
	var p := Partido.new(a, b)
	p.simular()
	_linea("  %s %d-%d %s" % [a.nombre, p.goles_local, p.goles_visita, b.nombre])
	var con_nota := 0
	var fuera_de_rango := 0
	for j in p.once_local + p.once_visita:
		if not j.notas.is_empty():
			con_nota += 1
			if j.notas[0] < 3.0 or j.notas[0] > 10.0:
				fuera_de_rango += 1
	_comprobar(con_nota == 22, "los 22 salen con nota (%d)" % con_nota)
	_comprobar(fuera_de_rango == 0, "todas las notas caen entre 3 y 10 (%d fuera)" % fuera_de_rango)

	## El que marca tiene que puntuar mejor que la media de su equipo: si no, la
	## nota no mide nada y la tabla de goleadores y el equipo ideal dan igual.
	var goleador: Jugador = null
	for j in p.once_local:
		if j.goles > 0:
			goleador = j
			break
	if goleador != null:
		var media := 0.0
		for j in p.once_local:
			media += j.notas[0]
		media /= float(p.once_local.size())
		_linea("  %s marco y saco %.1f; la media de su equipo fue %.1f" % [
			goleador.nombre, goleador.notas[0], media])
		_comprobar(goleador.notas[0] > media, "el que marca puntua por encima de su equipo")

	## Ganar tiene que puntuar mejor que perder, en promedio.
	var suma_gana := 0.0
	var suma_pierde := 0.0
	var n_gana := 0
	var n_pierde := 0
	for i in 40:
		var q := Partido.new(a, b)
		var r := q.simular()
		if r["local"] == r["visita"]:
			continue
		var gano: bool = r["local"] > r["visita"]
		for j in q.once_local:
			if gano: suma_gana += j.notas[j.notas.size() - 1]; n_gana += 1
			else: suma_pierde += j.notas[j.notas.size() - 1]; n_pierde += 1
	if n_gana > 0 and n_pierde > 0:
		_linea("  nota media ganando %.2f, perdiendo %.2f" % [
			suma_gana / n_gana, suma_pierde / n_pierde])
		_comprobar(suma_gana / n_gana > suma_pierde / n_pierde, "ganar puntua mejor que perder")

	## Solo se guardan las ocho ultimas: con mas, un mal mes queda enterrado.
	var uno: Jugador = a.plantilla[0]
	for i in 20:
		uno.anotar_nota(7.0)
	_comprobar(uno.notas.size() == 8, "se guardan solo las ocho ultimas notas (%d)" % uno.notas.size())
	## Y la media no se inventa nada mientras no haya partidos suficientes.
	var nuevo := Jugador.new()
	_comprobar(is_zero_approx(nuevo.media_notas()), "sin partidos, la media de notas es cero, no un 6 regalado")

	## Y la forma tiene que seguir a las notas: una racha buena la sube.
	var antes := uno.forma
	uno.forma = 40
	var q2 := Partido.new(a, b)
	q2.preparar()
	if q2.once_local.has(uno):
		for i in 5:
			var q3 := Partido.new(a, b)
			q3.simular()
	_comprobar(uno.forma >= 20 and uno.forma <= 99, "la forma se queda en su rango tras jugar (%d)" % uno.forma)
	uno.forma = antes

func _probar_directiva() -> void:
	_titulo("LA DIRECTIVA: OBJETIVO, CONFIANZA Y DESPIDO")
	var m := Mundo.new()
	m.generar(["CHI"], 3131)
	var grande: Club = null
	var chico: Club = null
	for c: Club in m.ligas[0].clubes:
		if grande == null or c.rep > grande.rep: grande = c
		if chico == null or c.rep < chico.rep: chico = c

	var d1 := m.tomar_el_mando(grande.id)
	_linea("  a %s (rep %d) le piden: %s" % [grande.nombre, grande.rep, d1.objetivo])
	var m2 := Mundo.new()
	m2.generar(["CHI"], 3131)
	var d2 := m2.tomar_el_mando(chico.id)
	_linea("  a %s (rep %d) le piden: %s" % [chico.nombre, chico.rep, d2.objetivo])
	## El objetivo NO se elige: te lo pone el club segun lo que es. Es lo que hace
	## que dirigir a un grande y a un chico sean dos juegos distintos.
	_comprobar(d1.meta_puesto < d2.meta_puesto, "al grande le exigen mas que al chico (%d vs %d)" % [
		d1.meta_puesto, d2.meta_puesto])

	## Ganar sube la confianza y perder la baja, y el tamano del rival pesa.
	var antes := d1.confianza
	d1.tras_partido(3, 0, chico)
	var por_ganar_al_chico := d1.confianza - antes
	d1.confianza = antes
	d1.tras_partido(3, 0, grande)
	var por_ganar_al_grande := d1.confianza - antes
	d1.confianza = antes
	_linea("  ganar al chico suma %d, ganar a uno grande suma %d" % [por_ganar_al_chico, por_ganar_al_grande])
	_comprobar(por_ganar_al_grande >= por_ganar_al_chico, "ganarle a uno grande vale mas")
	d1.tras_partido(0, 2, chico)
	_comprobar(d1.confianza < antes, "perder baja la confianza")

	## Y lo que de verdad importa: que te puedan echar. Un manager sin despido no
	## es un manager.
	var visto := {"echado": false}
	d1.despedido.connect(func(_motivo: String) -> void: visto["echado"] = true)
	for i in 30:
		d1.tras_partido(0, 3, chico)
	_comprobar(visto["echado"], "una racha de derrotas acaba en despido (confianza %d)" % d1.confianza)
	_comprobar(d1.despedido_ya, "queda marcado como despedido")
	var c_tras := d1.confianza
	d1.tras_partido(5, 0, grande)
	_comprobar(d1.confianza == c_tras, "despues del despido ya no se mueve nada")

	## Cumplir el objetivo repone confianza; fallarlo cuesta mas cuanto mas lejos.
	var d3 := Directiva.new(grande, 1)
	var r_bien := d3.tras_temporada(1, true, false)
	_linea("  campeon cumpliendo: confianza %d (%+d)" % [r_bien["confianza"], r_bien["delta"]])
	_comprobar(r_bien["cumplido"] and r_bien["delta"] > 0, "cumplir y ganar la liga sube la confianza")
	var d4 := Directiva.new(grande, 1)
	var r_mal := d4.tras_temporada(14, false, false)
	_linea("  decimocuarto fallando: confianza %d (%+d)" % [r_mal["confianza"], r_mal["delta"]])
	_comprobar(not r_mal["cumplido"] and r_mal["delta"] < 0, "fallar el objetivo baja la confianza")
	_comprobar(d3.humor() != d4.humor(), "el humor de la directiva se lee distinto en cada caso")
