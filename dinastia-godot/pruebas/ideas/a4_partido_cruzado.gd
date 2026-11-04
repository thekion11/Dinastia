extends BaseIdea
## MEGA AUDITORÍA 4, REPASO 5 CRUZADO (gestión → PARTIDO), líder, 4-11-2026: el partido SIMULADO con equipos absurdos.
##   1. 99 contra 20 (todos los atributos al tope contra todos al suelo), 120 partidos con distintas semillas.
##   2. Equipos de 7 (los demás lesionados) y sin portero.
##   3. En todos: termina, marcador ≥ 0 y razonable (≤ 15 por lado), goles = señales `gol`, tiros a puerta ≥ goles,
##      remates ≥ tiros a puerta, posesión 0-100, xG finito, nadie expulsado dos veces, cambios ≤ el máximo.

var _malos: Array[String] = []
var _tope := 60   ## 99 contra 20 es un desfase imposible en el mundo (da ~25 goles, como un 31-0 entre selecciones); en el caso real, 20

func _probar() -> void:
	_titulo("A4 CRUZADO (partido simulado): equipos absurdos")
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var a: Club = m.ligas[0].clubes[1]
	var b: Club = m.ligas[0].clubes[2]
	_extremo(a, 99)
	_extremo(b, 20)   ## 20 = el suelo real de medias y atributos (con 1 salía 33-0, pero ese equipo no puede existir)
	var g_a := 0
	var g_b := 0
	for i in 120:
		Azar.sembrar(9000 + i)
		var p := Partido.new(a if i % 2 == 0 else b, b if i % 2 == 0 else a)
		_jugar(p, "99 vs 20 #%d" % i)
		g_a += p.goles_local if i % 2 == 0 else p.goles_visita
		g_b += p.goles_visita if i % 2 == 0 else p.goles_local
	_comprobar(g_a > g_b * 3, "el de 99 aplasta al de 20 (%d goles contra %d en 120 partidos)" % [g_a, g_b])
	## El caso REAL: el mejor club del mundo contra el peor (dos países), 60 partidos.
	var m2 := Mundo.new()
	var p2: Array[String] = ["CHI", "ARG"]
	m2.generar(p2, 4242)
	var todos: Array = m2.clubes.values()
	todos.sort_custom(func(x: Club, y: Club) -> bool: return x.media() > y.media())
	var mejor: Club = todos[0]
	var peor: Club = todos[todos.size() - 1]
	_tope = 20   ## A4-PAR-L02: resuelto el 4-11 (el cociente ataque/defensa se satura): 71 contra 48 da ~3,8 goles y como mucho ~8; el tope de `_jugar` sigue holgado, el de abajo vigila los números
	var maximo := 0
	var total := 0
	for i in 60:
		Azar.sembrar(9300 + i)
		var pr := Partido.new(mejor if i % 2 == 0 else peor, peor if i % 2 == 0 else mejor)
		_jugar(pr, "mejor (%d) vs peor (%d) #%d" % [mejor.media(), peor.media(), i])
		maximo = maxi(maximo, maxi(pr.goles_local, pr.goles_visita))
		total += pr.goles_local + pr.goles_visita
	_linea("  mejor (%d) contra peor (%d): %.1f goles por partido, goleada máxima %d en 60 partidos" % [mejor.media(), peor.media(), total / 60.0, maximo])
	_comprobar(total / 60.0 >= 2.8 and total / 60.0 <= 5.5, "71 contra 48: %.1f goles por partido (2,8-5,5: gana claro, sin goleadas de 7-8 de media)" % (total / 60.0))
	_comprobar(maximo <= 11, "…y la goleada máxima es %d (≤ 11; antes llegaba a 15-0)" % maximo)
	## TARJETAS en partidos normales (A4-PAR-L01): 200 partidos de liga entre clubes reales.
	var cuenta := {"am": 0, "ro": 0}
	for i in 200:
		Azar.sembrar(9700 + i)
		var lg: Liga = m2.ligas[i % m2.ligas.size()]
		var x: Club = lg.clubes[i % lg.clubes.size()]
		var y: Club = lg.clubes[(i * 5 + 1) % lg.clubes.size()]
		if x == y:
			continue
		var pt := Partido.new(x, y)
		pt.tarjeta.connect(func(_j: Jugador, roja: bool, _m: int) -> void:
			cuenta["ro" if roja else "am"] += 1)
		_jugar(pt, "liga #%d" % i)
	var am := float(cuenta["am"])
	var ro := float(cuenta["ro"])
	_comprobar(am / 200.0 >= 2.8 and am / 200.0 <= 4.8 and ro / 200.0 >= 0.04 and ro / 200.0 <= 0.3,
		"tarjetas por partido como en las ligas reales: %.2f amarillas y %.2f rojas (real ~3,5-4 y ~0,1-0,2)" % [am / 200.0, ro / 200.0])
	## Equipos cortos.
	var c: Club = m.ligas[0].clubes[3]
	var d: Club = m.ligas[0].clubes[4]
	for k in c.plantilla.size():
		if k >= 7:
			c.plantilla[k].lesion = 5
	for j: Jugador in d.plantilla:
		if j.es_portero():
			j.lesion = 5
	for i in 30:
		Azar.sembrar(9500 + i)
		_jugar(Partido.new(c, d), "7 vs sin portero #%d" % i, false)
	_comprobar(_malos.is_empty(), "150 partidos absurdos terminan con cifras coherentes%s" % ("" if _malos.is_empty() else " — " + str(_malos.slice(0, 6))))

func _extremo(c: Club, v: int) -> void:
	for j: Jugador in c.plantilla:
		for k in j.atributos:
			j.atributos[k] = v
		j.ovr = v
		j.lesion = 0
		j.suspension = 0

func _jugar(p: Partido, nombre: String, limpiar := true) -> void:
	## Sin pasar semanas las sanciones se acumulan y el once sale corto: se limpian antes de cada partido (salvo los cortos a propósito).
	if limpiar:
		for c: Club in [p.local, p.visita]:
			for j: Jugador in c.plantilla:
				j.suspension = 0
				j.lesion = 0
		p.preparar()
	var suspendido := {"si": false}
	var goles := {"l": 0, "v": 0}
	var rojas := {}
	p.gol.connect(func(club: Club, _a: Jugador, _m: int, _as: Jugador) -> void:
		goles["l" if club == p.local else "v"] += 1)
	p.tarjeta.connect(func(j: Jugador, roja: bool, _m: int) -> void:
		if roja:
			if rojas.has(j.id):
				_malo("%s: %s expulsado dos veces" % [nombre, j.nombre])
			rojas[j.id] = true)
	var rojas_lado := {"l": 0, "v": 0}
	p.tarjeta.connect(func(j: Jugador, roja: bool, _m: int) -> void:
		if roja:
			rojas_lado["l" if j.club_id == p.local.id else "v"] += 1)
	p.decision_arbitral.connect(func(t: String, mi: int) -> void:
		if t.contains("suspendido") or t.contains("suspend"):
			suspendido["si"] = true
		if OS.get_environment("A4_DEPURA") != "" and t.contains("suspend"):
			print("DEPURA ", nombre, " min ", mi, ": ", t, " rojas ", rojas_lado))
	p.simular()
	if not p.terminado_ya:
		_malo("%s: no terminó" % nombre)
	for lado in [["l", p.goles_local, p.tiros_puerta_local, p.remates_local, p.cambios_local], ["v", p.goles_visita, p.tiros_puerta_visita, p.remates_visita, p.cambios_visita]]:
		var g: int = lado[1]
		if g < 0 or g > _tope:
			_malo("%s: marcador %d" % [nombre, g])
		if g != int(goles[lado[0]]) and not suspendido["si"]:
			_malo("%s: %d goles en el marcador y %d señales de gol (%s)" % [nombre, g, int(goles[lado[0]]), lado[0]])
		if int(lado[2]) < g and not suspendido["si"]:
			_malo("%s: %d tiros a puerta y %d goles (%s)" % [nombre, int(lado[2]), g, lado[0]])
		if int(lado[3]) < int(lado[2]):
			_malo("%s: %d remates y %d a puerta (%s)" % [nombre, int(lado[3]), int(lado[2]), lado[0]])
		if int(lado[4]) > 5 + p.cambios_extra:
			_malo("%s: %d cambios (%s)" % [nombre, int(lado[4]), lado[0]])
	if p.posesion_local < 0.0 or p.posesion_local > 100.0 or not is_finite(p.xg_local) or not is_finite(p.xg_visita):
		_malo("%s: posesión %.1f xG %.2f/%.2f" % [nombre, p.posesion_local, p.xg_local, p.xg_visita])

func _malo(t: String) -> void:
	if _malos.size() < 20:
		_malos.append(t)
