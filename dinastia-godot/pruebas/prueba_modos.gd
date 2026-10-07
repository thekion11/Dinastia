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
