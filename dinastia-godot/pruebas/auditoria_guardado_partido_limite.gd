extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): guardar a mitad de temporada justo ANTES y justo DESPUÉS de un partido 3D de la carrera y cargar, y ABANDONAR partidos a mitad.
##   godot --headless --path . res://pruebas/auditoria_guardado_partido_limite.tscn
## Sin partidos dobles ni jornadas saltadas al cargar; abandonar un partido no repite el entreno de la semana (antes: un intento = una mejora de atributo posible y 14 de energía).
const LIENZO := Vector2(1600, 720)
var _n := 0
var _fallos := 0
var _ui: CarreraJugadorUI
var _corriendo := false

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	PartidoJugable.con_ceremonia = false
	ControlesTactiles.forzar = true
	PantallaMovil.dpi_forzado = 400.0
	PantallaMovil.ventana_forzada = Vector2i(2400, 1080)
	PantallaMovil.lienzo_forzado = LIENZO
	AjustesTactil.restaurar()
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_ui._crear()
	if _n == 20 and not _corriendo:
		_corriendo = true
		await _todo()
		for nombre in ["t_pre", "t_post", "t_a"]:
			Partida.borrar(nombre)
		ControlesTactiles.forzar = false
		PantallaMovil.dpi_forzado = 0.0
		PantallaMovil.ventana_forzada = Vector2i.ZERO
		PantallaMovil.lienzo_forzado = Vector2.ZERO
		AjustesTactil.restaurar()
		print("===== FIN. %d fallos =====" % _fallos)
		get_tree().quit(0 if _fallos == 0 else 1)

func _marco(k: int) -> void:
	for i in k:
		await get_tree().process_frame

func _pj() -> PartidoJugable:
	for h: Node in _ui.get_children():
		if h is PartidoJugable and not h.is_queued_for_deletion():
			return h
	return null

func _pj_de_mi_club(m: Mundo, club_id: String) -> int:
	for l in m.ligas:
		for c: Club in l.clubes:
			if c.id == club_id:
				return int((l.tabla_puntos[c.id] as Dictionary)["pj"])
	return -1

func _todo() -> void:
	var m := CarreraJugadorUI.mundo
	var c := _ui.carrera
	var club := c.club(m)
	## Una semana de partido de liga de verdad (si el sorteo dejó la primera en blanco, se avanzan semanas simuladas).
	var intentos := 0
	while _ui._partido_de_la_semana(club).is_empty() and intentos < 8:
		_ui._cerrar_semana({})
		intentos += 1
	## 1) Abandonar: el entreno de la semana no se repite.
	var j := c.jugador(m)
	_ui._jugar_partido()
	await _marco(3)
	var e1 := c.energia
	var atr1: Dictionary = j.atributos.duplicate()
	var msg1 := c.entreno_msg
	var pj := _pj()
	_comprobar(pj != null, "«Jugar el partido» abre el partido 3D")
	pj.queue_free()
	await _marco(3)
	for k in 5:
		_ui._jugar_partido()
		await _marco(3)
		var q := _pj()
		if q != null:
			q.queue_free()
		await _marco(3)
	_comprobar(c.energia == e1 and j.atributos == atr1, "abandonar el partido 6 veces seguidas entrena UNA sola vez (energía %d → %d, atributos iguales: %s)" % [e1, c.energia, str(j.atributos == atr1)])
	_comprobar(c.entreno_msg == msg1 and msg1 != "", "…y el mensaje de la semana es el mismo")
	_comprobar(m.semana == m.semana and c.entreno_semana == m.anio * 60 + m.semana, "el entreno se anota en su semana (%d)" % c.entreno_semana)
	## 2) Guardar justo antes, jugar entero (a toda prisa), guardar justo después.
	var semana0 := m.semana
	var anio0 := m.anio
	var pj0 := _pj_de_mi_club(m, club.id)
	var carrera_pj0 := c.pj_carrera
	_comprobar(Partida.guardar(m, "t_pre"), "guardado justo antes del partido")
	_ui._jugar_partido()
	await _marco(3)
	var pj1 := _pj()
	pj1._simular_resto()
	await _marco(5)
	_comprobar(pj1.motor.estado == "fin", "el partido llega al final")
	pj1._cerrar()   ## «continuar» en la pantalla final: sale el resultado y se cierra la semana
	await _marco(5)
	var semana1 := m.semana
	_comprobar(m.anio * 60 + m.semana == anio0 * 60 + semana0 + 1 or m.anio > anio0, "el partido avanza UNA semana (%d → %d)" % [semana0, m.semana])
	_comprobar(_pj_de_mi_club(m, club.id) == pj0 + 1, "tu club suma UN partido en su liga (%d → %d)" % [pj0, _pj_de_mi_club(m, club.id)])
	_comprobar(c.pj_carrera == carrera_pj0 + 1, "tu carrera suma UN partido (%d → %d)" % [carrera_pj0, c.pj_carrera])
	_comprobar(Partida.guardar(m, "t_post"), "guardado justo después del partido")
	## 3) Cargar el de antes: vuelve a la jornada del partido, sin él jugado; cargar el de después: ni doble ni saltada.
	var pre := Partida.cargar("t_pre")
	var post := Partida.cargar("t_post")
	_comprobar(pre != null and post != null, "los dos guardados cargan")
	_comprobar(pre.semana == semana0 and pre.anio == anio0 and _pj_de_mi_club(pre, club.id) == pj0 and pre.carrera_jugador.pj_carrera == carrera_pj0, "el de ANTES vuelve a la jornada del partido sin jugarlo (semana %d, %d PJ)" % [pre.semana, _pj_de_mi_club(pre, club.id)])
	_comprobar(post.semana == semana1 and _pj_de_mi_club(post, club.id) == pj0 + 1 and post.carrera_jugador.pj_carrera == carrera_pj0 + 1, "el de DESPUÉS tiene el partido jugado UNA vez (semana %d, %d PJ)" % [post.semana, _pj_de_mi_club(post, club.id)])
	## 4) Con el de antes: se vuelve a jugar la jornada y avanza UNA semana (ni doble ni saltada); el entreno ya hecho no se repite tras cargar.
	_ui.mundo = pre
	CarreraJugadorUI.mundo = pre
	_ui.carrera = pre.carrera_jugador

	_comprobar(_ui.carrera.entreno_semana == pre.anio * 60 + pre.semana or _ui.carrera.entreno_semana < pre.anio * 60 + pre.semana, "la semana de entreno guardada es coherente")
	_ui._cerrar_semana({})
	await _marco(2)
	_comprobar(pre.anio * 60 + pre.semana == anio0 * 60 + semana0 + 1 or pre.anio > anio0, "cargar el de antes y cerrar la semana avanza UNA (semana %d)" % pre.semana)
	_comprobar(_pj_de_mi_club(pre, club.id) <= pj0 + 1, "…sin partido doble (%d PJ)" % _pj_de_mi_club(pre, club.id))
