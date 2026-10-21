extends "res://pruebas/claude_juega.gd"
## EL PARTIDO DEL VÍDEO DE GAMEPLAY (21-10-2026). Pedido del dueño: «el vídeo con
## sonido y gameplay real, más largo, más detallado; probar cada mecánica y
## variable». Es `claude_juega` (el equipo local lo maneja un guion que pulsa
## los MISMOS botones que una persona) con la ceremonia entera, la música
## encendida, el ritmo «normal» (4 s por minuto: ~6 min de juego, como un
## partido de FC) y, en minutos fijos, las mecánicas que no salen solas:
## cámaras, estadísticas a pedido y la pausa con pizarra y cambio. Lo demás
## (goles con su realización, tarjetas por puntos, VAR, cambios del DT rival,
## la ola, el descanso, el añadido) pasa porque el motor lo decide.
##   CEREMONIA=1 RITMO=normal xvfb-run -a godot --path . --rendering-driver vulkan \
##       --resolution 960x540 --fixed-fps 25 --write-movie partido.avi res://pruebas/video_partido.tscn
var _vf := 0
var _fin_en := -1
var _hechos := {}
var _cap: Label
var _cap_hasta := 0
var _musica_antes := false

func _ready() -> void:
	_musica_antes = Musica.encendida
	Musica.encendida = true
	Musica.volumen = 0.22
	super._ready()
	salir_al_terminar = false
	Musica.ambientar("partido")
	var capa := CanvasLayer.new()
	capa.layer = 120
	add_child(capa)
	_cap = Label.new()
	_cap.add_theme_font_size_override("font_size", 19)
	_cap.add_theme_color_override("font_color", Color("#c9f24b"))
	_cap.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_cap.add_theme_constant_override("outline_size", 7)
	_cap.anchor_top = 1.0
	_cap.anchor_bottom = 1.0
	_cap.offset_left = 18
	_cap.offset_top = -40
	capa.add_child(_cap)
	if OS.get_environment("CEREMONIA") != "":
		_rotulo("Ceremonia: niños de la mano, mascota, lona, alineaciones e himno", 12.0)

func _rotulo(texto: String, segundos: float) -> void:
	_cap.text = "▶ " + texto
	_cap_hasta = _vf + int(segundos * 25.0)

func _en_ceremonia() -> bool:
	var c: Variant = _vista.get("_ceremonia")
	return c != null and is_instance_valid(c) and (c as CeremoniaPartido).activa

func _process(d: float) -> void:
	_vf += 1
	if _vf > _cap_hasta:
		_cap.text = ""
	if _fin:
		## El final: el pitido, el marcador y la grada, unos segundos más.
		if _fin_en < 0:
			_fin_en = _vf
			_rotulo("Final del partido" if OS.get_environment("MITADES") != "1" else "Descanso", 6.0)
		if _vf - _fin_en > 250:
			Musica.encendida = _musica_antes
			print("VIDEO_PARTIDO hechos: ", _hechos.keys(), " fotogramas ", _vf)
			get_tree().quit()
		return
	if _vista != null and is_instance_valid(_vista) and _en_ceremonia():
		return
	if not _hechos.has("control"):
		_hechos["control"] = true
		if OS.get_environment("SIN_MANDO") != "":
			_rotulo("CPU contra CPU: la IA juega los dos lados (otro partido, primera parte)", 9.0)
		else:
			_rotulo("Juego con el equipo local: stick relativo a la cámara de TV, pase, tiro cargado, sprint, Q para cambiar", 9.0)
	super._process(d)
	if _motor == null or _fin:
		return
	_mecanicas()

func _una(clave: String, minuto: int) -> bool:
	if _hechos.has(clave) or _motor.minuto() < minuto:
		return false
	_hechos[clave] = true
	return true

func _mecanicas() -> void:
	var rig: CameraRig = _vista.get("_rig")
	if _motor.estado == "gol" and not _hechos.has("gol%d_%d" % [_motor.goles[0], _motor.goles[1]]):
		_hechos["gol%d_%d" % [_motor.goles[0], _motor.goles[1]]] = true
		_rotulo("Gol: carrera al córner, abrazo, carta del goleador y repetición", 7.0)
	if _una("cam_pro", 14) and rig != null:
		var i := rig.camera_names.find("Pro (Tercera Persona)")
		if i != -1:
			rig.switch_to(i)
			_rotulo("Cámara «Pro»: detrás del jugador que manejas", 6.0)
	if _una("cam_tv", 17) and rig != null:
		rig.switch_to(0)
		_rotulo("Vuelve la transmisión: cierra en el área, abre en las contras", 6.0)
	if _una("stats", 30):
		_vista.abrir_estadisticas()
		_rotulo("Estadísticas a pedido (T): tiros con xG, xA, mapa de tiros y de calor", 5.0)
	if _hechos.has("stats") and not _hechos.has("stats_fuera"):
		var ps: Variant = _vista.get("_panel_stats")
		if ps != null and is_instance_valid(ps):
			_hechos["stats_t"] = int(_hechos.get("stats_t", 0)) + 1
			if int(_hechos["stats_t"]) == 70:
				(ps as PanelEstadisticas).call("_cambiar_calor")
			if int(_hechos["stats_t"]) > 140:
				(ps as PanelEstadisticas).cerrar()
				_hechos["stats_fuera"] = true
	if _una("pausa", 57):
		_vista.call("_abrir_panel_dt")
		_rotulo("Pausa: pizarra en vivo y cambios (el más cansado sale)", 8.0)
	var pd: Variant = _vista.get("_panel_dt")
	if _hechos.has("pausa") and not _hechos.has("pausa_fuera") and pd != null and is_instance_valid(pd):
		var panel: PanelDTPartido = pd
		_hechos["pausa_t"] = int(_hechos.get("pausa_t", 0)) + 1
		var t := int(_hechos["pausa_t"])
		if t == 40:
			panel.call("_fijar", "mentalidad", 2)
		if t == 75:
			## El que menos energía tiene, fuera; entra el primero del banco.
			var peor: Jugador = null
			var menos := 9.0
			for j: Jugador in panel.call("_mi_once"):
				var e: float = panel.call("_energia", j)
				if j.pos_e != "POR" and e < menos:
					menos = e
					peor = j
			if peor != null:
				panel.set("_sale", peor)
				panel.call("_pintar_cambios")
		if t == 110:
			var col: Node = panel.get("_col_banco")
			for b in col.get_children():
				if b is Button and not (b as Button).disabled:
					(b as Button).pressed.emit()
					break
		if t > 170:
			panel.cerrar()
			_hechos["pausa_fuera"] = true
			_rotulo("El cambio se hace en la banda: cartel del cuarto árbitro y palmada", 6.0)
	if _una("cam_tele", 72) and rig != null:
		var i := rig.camera_names.find("Tele Dinámica")
		if i != -1:
			rig.switch_to(i)
			_rotulo("Otra cámara: «Tele dinámica»", 5.0)
	if _una("cam_tv2", 75) and rig != null:
		rig.switch_to(0)
