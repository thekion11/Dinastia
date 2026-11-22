class_name SalaVAR
extends "res://ui/sala_var_p1.gd"

static func abrir(padre: Control, mundo_partido: World3D, foco: Vector3, minuto: int, motivo: String, opc: Dictionary = {}) -> SalaVAR:
	var anular: bool = opc.get("anular", false)
	var lineas_off: Dictionary = opc.get("lineas", {})
	var s := SalaVAR.new()
	s.anula = anular
	s.lineas = lineas_off
	s._mundo_partido = mundo_partido
	s._foco = foco
	s._minuto = minuto
	s._motivo = motivo
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	## Encima de todo el HUD del partido (rótulos de repetición incluidos).
	s.z_index = 100
	padre.add_child(s)
	s._montar()
	return s

func _montar() -> void:
	var cont := SubViewportContainer.new()
	cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	cont.stretch = true
	add_child(cont)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.size = Vector2i(1600, 900)
	_vp.msaa_3d = Viewport.MSAA_2X
	cont.add_child(_vp)
	_sala()
	## Rótulos de transmisión.
	var barra := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.1, 0.88)
	sb.border_color = Color("3fa9f5")
	sb.border_width_bottom = 3
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	barra.add_theme_stylebox_override("panel", sb)
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	barra.add_child(fila)
	_rotulo = Label.new()
	_rotulo.text = Idiomas.t("🖥️  REVISIÓN VAR  ·  %d'  ·  %s") % [_minuto, Idiomas.t(_motivo)]
	_rotulo.add_theme_font_size_override("font_size", Tema.letra(26))
	_rotulo.add_theme_color_override("font_color", Color("e8f4ff"))
	_rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_rotulo)
	_reloj = Label.new()
	_reloj.add_theme_font_size_override("font_size", Tema.letra(26))
	_reloj.add_theme_color_override("font_color", Color("3fa9f5"))
	fila.add_child(_reloj)
	_decision = PanelContainer.new()
	var sd := StyleBoxFlat.new()
	sd.bg_color = Color(0.45, 0.06, 0.06, 0.95) if anula else Color(0.05, 0.35, 0.15, 0.95)
	sd.set_corner_radius_all(10)
	sd.content_margin_left = 40
	sd.content_margin_right = 40
	sd.content_margin_top = 18
	sd.content_margin_bottom = 18
	_decision.add_theme_stylebox_override("panel", sd)
	_decision.set_anchors_preset(Control.PRESET_CENTER)
	_decision.visible = false
	add_child(_decision)
	var ld := Label.new()
	ld.text = Idiomas.t("✖  DECISIÓN: GOL ANULADO") if anula else Idiomas.t("✔  DECISIÓN: SE MANTIENE LO DECIDIDO EN EL CAMPO")
	ld.add_theme_font_size_override("font_size", Tema.letra(30))
	ld.add_theme_color_override("font_color", Color.WHITE)
	_decision.add_child(ld)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

## La sala: suelo, paredes, luz fría, la pared de monitores, dos puestos con
## operadores y el rótulo.
func _sala() -> void:
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	_sala_entorno(raiz)
	_sala_rotulo(raiz)
	_sala_monitores(raiz)
	_sala_puestos(raiz)
	_cam = Camera3D.new()
	_cam.fov = 52
	_cam.position = Vector3(2.8, 2.1, 3.6)
	raiz.add_child(_cam)
	_cam.look_at(Vector3(0, 1.5, -2.5), Vector3.UP)
	_cam.current = true

## Suelo, paredes, luz fría y la luz del techo.
func _sala_entorno(raiz: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.03, 0.05)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.25, 0.32, 0.45)
	e.ambient_light_energy = 0.6
	e.glow_enabled = ModoRendimiento.glow(Calidad.elegida)
	e.glow_intensity = 0.7
	env.environment = e
	raiz.add_child(env)
	_caja(raiz, Vector3(0, -0.05, 0), Vector3(12, 0.1, 9), Color(0.07, 0.08, 0.1), 0.0)       ## suelo
	_caja(raiz, Vector3(0, 1.6, -3.2), Vector3(12, 3.4, 0.1), Color(0.09, 0.11, 0.15), 0.0)   ## pared de monitores
	_caja(raiz, Vector3(-5.0, 1.6, 0), Vector3(0.1, 3.4, 9), Color(0.08, 0.09, 0.12), 0.0)
	_caja(raiz, Vector3(5.0, 1.6, 0), Vector3(0.1, 3.4, 9), Color(0.08, 0.09, 0.12), 0.0)
	## Tiras de luz en el techo y el zócalo azul.
	for x: float in [-3.0, 0.0, 3.0]:
		_caja(raiz, Vector3(x, 3.25, 0), Vector3(1.6, 0.04, 0.12), Color(0.8, 0.9, 1.0), 2.5)
	_caja(raiz, Vector3(0, 0.05, -3.12), Vector3(12, 0.06, 0.04), Color("3fa9f5"), 3.0)
	var luz := OmniLight3D.new()
	luz.position = Vector3(0, 2.8, 0.5)
	luz.light_color = Color(0.75, 0.85, 1.0)
	luz.light_energy = 1.4
	luz.omni_range = 9.0
	raiz.add_child(luz)

## Rótulo VAR en la pared de monitores.
func _sala_rotulo(raiz: Node3D) -> void:
	## Rótulo VAR.
	var var_rot := Label3D.new()
	var_rot.text = Idiomas.t("VAR")
	var_rot.font_size = 160
	var_rot.pixel_size = 0.004
	var_rot.modulate = Color("3fa9f5")
	var_rot.outline_size = 0
	var_rot.position = Vector3(0, 2.95, -3.12)
	raiz.add_child(var_rot)

## Los monitores: cuatro cámaras sobre el partido real (o con la línea del fuera de juego).
func _sala_monitores(raiz: Node3D) -> void:
	## Los monitores: cuatro cámaras sobre el partido real.
	var angulos := [
		[Vector3(_foco.x * 0.3, 8.0, _foco.z + signf(_foco.z + 0.01) * 16.0), _foco, 40.0],  ## detrás de la jugada
		[Vector3(36.0, 2.0, _foco.z), _foco, 30.0],                                          ## lateral a ras de campo (fuera de juego)
		[Vector3(_foco.x, 45.0, _foco.z + 0.1), _foco, 45.0],                                 ## cenital
		[Vector3(-30.0, 14.0, _foco.z * 0.6), _foco, 28.0],                                   ## tele contraria
	]
	var hay_lineas := lineas.has("linea") and lineas.has("atacante")
	if hay_lineas:
		## Alto y de lado, en diagonal sobre la zona de las dos líneas.
		var zl := (float(lineas["linea"]) + float(lineas["atacante"])) * 0.5
		var hacia := signf(_foco.z + 0.01)
		angulos[1] = [Vector3(44.0, 17.0, zl - hacia * 12.0), Vector3(0.0, 0.0, zl + hacia * 2.0), 38.0]
	var pos_mon := [Vector3(-1.1, 1.75, -3.1), Vector3(1.1, 1.75, -3.1), Vector3(-3.3, 1.75, -3.1), Vector3(3.3, 1.75, -3.1)]
	var tam_mon := [Vector2(2.0, 1.12), Vector2(2.0, 1.12), Vector2(1.6, 0.9), Vector2(1.6, 0.9)]
	for i in 4:
		var tex: Texture2D = null
		if _mundo_partido != null:
			var sv := SubViewport.new()
			sv.world_3d = _mundo_partido
			sv.size = Vector2i(480, 270)
			sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			add_child(sv)
			var c := Camera3D.new()
			c.fov = float(angulos[i][2])
			c.far = 400.0
			sv.add_child(c)
			c.position = angulos[i][0]
			c.look_at(angulos[i][1], Vector3.UP if i != 2 else Vector3(0, 0, -1))
			c.current = true
			tex = sv.get_texture()
			_monitores.append(c)
		_monitor(raiz, pos_mon[i], tam_mon[i], tex, i)
		if i == 1 and hay_lineas and _monitores.size() > 1:
			_dibujar_lineas(raiz, _monitores[1], Vector2(480, 270), pos_mon[i], tam_mon[i])

## Dos puestos con su operador (auriculares y polo oscuro).
func _sala_puestos(raiz: Node3D) -> void:
	## Dos puestos con su operador (auriculares y polo oscuro).
	for lado: float in [-1.0, 1.0]:
		var mesa_x := 1.6 * lado
		_caja(raiz, Vector3(mesa_x, 0.75, -0.9), Vector3(2.2, 0.06, 0.9), Color(0.13, 0.14, 0.17), 0.0)
		_caja(raiz, Vector3(mesa_x, 0.37, -0.9), Vector3(2.1, 0.74, 0.08), Color(0.1, 0.1, 0.12), 0.0)
		## Pantallas de mesa encendidas.
		_caja(raiz, Vector3(mesa_x - 0.45, 1.05, -1.15), Vector3(0.7, 0.42, 0.03), Color(0.25, 0.55, 0.9), 1.4)
		_caja(raiz, Vector3(mesa_x + 0.45, 1.05, -1.15), Vector3(0.7, 0.42, 0.03), Color(0.2, 0.7, 0.45), 1.2)
		_operador(raiz, Vector3(mesa_x, 0.0, -0.1), lado)

func _process(delta: float) -> void:
	## Paso acotado: el primer fotograma (cargando a los operadores) puede
	## durar segundos, y la revisión se "terminaba" antes de verse.
	delta = minf(delta, 0.1)
	_t += delta
	if int(_t) != _ult_seg:   ## (28-10) el texto del reloj solo al cambiar el segundo
		_ult_seg = int(_t)
		_reloj.text = "⏱ %02d" % _ult_seg

	## La cámara se acerca despacio a la pared de monitores.
	if _cam != null:
		_cam.position = _cam.position.lerp(Vector3(0.6, 1.9, 1.4), 0.25 * delta)
		_cam.look_at(Vector3(0, 1.6, -3.0), Vector3.UP)
	if _t > DURACION - 1.6 and not _decision.visible:
		_decision.visible = true
		_decision.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_decision.reset_size()
		_decision.position = (size - _decision.get_combined_minimum_size()) * 0.5
		_decision.pivot_offset = _decision.get_combined_minimum_size() * 0.5
		_decision.scale = Vector2(0.6, 0.6)
		create_tween().tween_property(_decision, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	if _t > DURACION:
		set_process(false)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
		tw.tween_callback(func() -> void:
			terminada.emit()
			queue_free())
