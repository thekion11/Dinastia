extends Node
## LOS MODOS HASTA EL FINAL (MEGAPLAN fase 4, E16): cada modo de juego del
## menú de inicio, arrancado como lo hace `Principal`, juega una temporada
## entera semana a semana, cambia de temporada y sigue unas semanas más. Si un
## modo se rompe a mitad o deja el mundo en un estado imposible, aquí se ve.
##   godot --headless --path . res://pruebas/prueba_modos.tscn
## (Los errores de script salen por la consola con «SCRIPT ERROR».)
const MODOS := ["dt", "dir", "ayudante", "interino", "cantera", "imperio", "jeque", "creador", "fondo", "retos", "tutorial"]
var _fallos: Array[String] = []

func _comprobar(c: bool, que: String) -> void:
	print(("  ok    " if c else "  FALLO ") + que)
	if not c:
		_fallos.append(que)

func _ready() -> void:
	var solo := OS.get_environment("MODO")
	for modo: String in MODOS:
		if solo != "" and modo != solo:
			continue
		_un_modo(modo)
	if solo == "" or solo == "jugador":
		_carrera_jugador()
	print("")
	for f in _fallos:
		print("  FALLO ", f)
	print("===== FIN MODOS. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _un_modo(modo: String) -> void:
	print("")
	print("===== MODO %s =====" % modo)
	var t0 := Time.get_ticks_msec()
	var m := Mundo.new()
	m.generar(["CHI"], 600 + MODOS.find(modo))
	if modo == "interino":
		m.roles.arrancar(modo, "Prueba")
		if m.mi_club() == null:
			m.tomar_el_mando(m.ligas[0].clubes[4].id)
	else:
		m.tomar_el_mando(m.ligas[0].clubes[4].id)
		m.roles.arrancar(modo, "Prueba")
	if modo == "fondo" and m.mi_club() != null:
		m.fondo = FondoInversion.new()
		m.fondo.caja = int(round(Eco.ref_caja(70.0) * 2.5))
	_comprobar(m.mi_club() != null, "%s: arranca con un club" % modo)
	if m.mi_club() == null:
		return
	var semanas := 0
	while m.temporada_en_curso() and semanas < 80:
		m.avanzar_semana()
		semanas += 1
	_comprobar(not m.temporada_en_curso(), "%s: la temporada termina (%d semanas)" % [modo, semanas])
	var anio := m.anio
	m.nueva_temporada()
	for k in 6:
		m.avanzar_semana()
	_comprobar(m.anio == anio + 1, "%s: arranca la temporada siguiente" % modo)
	var club := m.mi_club()
	_comprobar(club != null, "%s: sigue habiendo un club al mando (o el siguiente)" % modo)
	if club != null:
		_comprobar(absi(club.saldo) < 50_000_000_000, "%s: la caja tiene sentido (%d)" % [modo, club.saldo])
		_comprobar(club.plantilla.size() >= 16, "%s: el plantel no se vacía (%d)" % [modo, club.plantilla.size()])
	_comprobar(String(m.roles.rol) != "", "%s: el rol sigue definido (%s)" % [modo, m.roles.rol])
	print("  %s en %d ms" % [modo, Time.get_ticks_msec() - t0])

## LA CARRERA DE JUGADOR, de punta a punta como la juega `CarreraJugadorUI`
## con los partidos simulados: entrenar, la semana, los eventos (se elige
## siempre la primera opción), el cierre de temporada, la siguiente y el
## guardado de ida y vuelta.
func _carrera_jugador() -> void:
	print("")
	print("===== MODO jugador (Carrera de Jugador) =====")
	var t0 := Time.get_ticks_msec()
	var m := Mundo.new()
	m.generar(["CHI"], 640)
	m.carrera_jugador = CarreraJugador.crear(m, "Prueba", "DC", false, 640)
	var c := m.carrera_jugador
	_comprobar(c != null and c.jugador(m) != null and c.club(m) != null, "jugador: arranca con jugador y club")
	if c == null or c.jugador(m) == null:
		return
	var semanas := 0
	var eventos := 0
	while m.temporada_en_curso() and semanas < 80:
		c.entrenar(m)
		var j := c.jugador(m)
		var goles_antes := j.goles
		var titular := c.es_titular(m)
		var hay := not CarreraJugador.partido_de_la_semana(m, c.club(m)).is_empty()
		m.avanzar_semana()
		if titular and hay:
			var g := j.goles - goles_antes
			j.goles = goles_antes
			c.tras_partido(m, {"minutos": 90, "goles": g, "asist": 0, "nota": 6.5 + float(g), "titular": true})
		for ev: Dictionary in c.semana(m):
			eventos += 1
			var i := c.eventos.find(ev)
			if i >= 0:
				c.resolver(m, i, 0)
		semanas += 1
	_comprobar(not m.temporada_en_curso(), "jugador: la temporada termina (%d semanas)" % semanas)
	var pj := int(c.stats_temp["pj"])
	_comprobar(pj >= 5, "jugador: juega partidos (%d) y vive eventos (%d)" % [pj, eventos])
	c.fin_de_temporada(m)
	_comprobar(c.temporadas.size() == 1 and int(c.temporadas[0]["pj"]) == pj, "jugador: la temporada queda en su historial")
	var anio := m.anio
	m.nueva_temporada()
	for k in 6:
		m.avanzar_semana()
		c.semana(m)
	_comprobar(m.anio == anio + 1 and c.jugador(m) != null, "jugador: sigue en la temporada siguiente")
	var copia := CarreraJugador.desde_dic(c.a_dic())
	_comprobar(copia.temporadas.size() == 1 and copia.goles_carrera == c.goles_carrera and copia.pj_carrera == c.pj_carrera,
		"jugador: el guardado de la carrera va y vuelve (%d PJ, %d goles)" % [copia.pj_carrera, copia.goles_carrera])
	_comprobar(not c.toca_retirarse(m), "jugador: a los %d años no le toca retirarse" % c.jugador(m).edad)
	print("  jugador en %d ms" % (Time.get_ticks_msec() - t0))
