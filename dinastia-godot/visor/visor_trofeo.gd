class_name VisorTrofeo
extends PanelContainer
## LA COPA EN PRIMER PLANO (27-10-2026). Un panel central: a la izquierda la copa (la malla real del trofeo, o una de cilindros) girando
## despacio en su propio `SubViewport`, que se gira a mano arrastrando el ratón o con A/D y las flechas; a la derecha su ficha: competición, año,
## final y goleadores (lo que no se guardó, «Sin datos»). Esc o «Cerrar» lo quitan. Es un `PanelContainer` para encajar en `_menu_asc`.

var _pivote: Node3D
var _arrastrando := false
var _auto := true

static func abrir(capa: CanvasLayer, ficha: Dictionary) -> VisorTrofeo:
	var v := VisorTrofeo.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.offset_left = -430
	v.offset_right = 430
	v.offset_top = -250
	v.offset_bottom = 250
	v.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	v.construir(ficha)
	capa.add_child(v)
	return v

func construir(ficha: Dictionary) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	add_child(fila)
	var cont := SubViewportContainer.new()
	cont.custom_minimum_size = Vector2(380, 440)
	cont.stretch = true
	cont.gui_input.connect(_arrastre)
	fila.add_child(cont)
	var sv := SubViewport.new()
	sv.size = Vector2i(380, 440)
	sv.own_world_3d = true
	sv.transparent_bg = false
	cont.add_child(sv)
	_escena(sv, bool(ficha.get("vacia", false)))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	fila.add_child(col)
	col.add_child(_etiqueta(String(ficha.get("titulo", "")), 24, Color(1.0, 0.86, 0.45)))
	if bool(ficha.get("vacia", false)):
		col.add_child(_etiqueta(Idiomas.t("Aquí irá el próximo título del club."), 14, Color(0.8, 0.85, 0.82)))
	else:
		var anio := int(ficha.get("anio", 0))
		col.add_child(_dato(Idiomas.t("Competición"), String(ficha.get("titulo", ""))))
		col.add_child(_dato(Idiomas.t("Año"), str(anio) if anio > 0 else Idiomas.t("Sin datos")))
		var fin := String(ficha.get("final", ""))
		col.add_child(_dato(Idiomas.t("Final"), fin if fin != "" else Idiomas.t("Sin datos")))
		var gol: Array = ficha.get("goleadores", []) as Array
		col.add_child(_dato(Idiomas.t("Goleadores"), ", ".join(gol) if not gol.is_empty() else Idiomas.t("Sin datos")))
	var ayuda := _etiqueta(Idiomas.t("Arrastra el ratón o A/D para girar la copa"), 12, Color(0.6, 0.68, 0.64))
	ayuda.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ayuda.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	col.add_child(ayuda)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("Cerrar")
	cerrar.pressed.connect(queue_free)
	col.add_child(cerrar)

func _etiqueta(t: String, tam: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", c)
	return l

func _dato(clave: String, valor: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.add_child(_etiqueta(Idiomas.mayusculas(clave), 11, Color(0.55, 0.7, 0.6)))
	v.add_child(_etiqueta(valor, 17, Color(0.95, 0.96, 0.93)))
	return v

## La copa, un foco cálido y otro frío de contraluz, cámara delante.
func _escena(sv: SubViewport, vacia: bool) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.08, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.47, 0.5)
	var we := WorldEnvironment.new()
	we.environment = env
	sv.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, -30, 0)
	sol.light_energy = 1.4
	sv.add_child(sol)
	var contra := DirectionalLight3D.new()
	contra.rotation_degrees = Vector3(-20, 150, 0)
	contra.light_color = Color(0.7, 0.8, 1.0)
	contra.light_energy = 0.8
	sv.add_child(contra)
	_pivote = Node3D.new()
	sv.add_child(_pivote)
	var mi := MeshInstance3D.new()
	SalasClub._cargar_trofeo()
	if SalasClub._trofeo != null and SalasClub._trofeo_mat != null and not vacia:
		mi.mesh = SalasClub._trofeo
		var m: StandardMaterial3D = (SalasClub._trofeo_mat as StandardMaterial3D).duplicate()
		m.metallic = 0.55
		m.roughness = 0.3
		mi.material_override = m
		var ab: AABB = SalasClub._trofeo.get_aabb()
		var esc := 1.55 / maxf(ab.size.y, 0.01)
		mi.scale = Vector3.ONE * esc
		mi.position = -(ab.position + ab.size * 0.5) * esc
	else:
		mi.mesh = SalasClub._cilindro(0.3, 0.12, 1.2) if not vacia else SalasClub._esfera(0.3)
		mi.material_override = Texturas.metal(Color(0.95, 0.78, 0.3), 0.22)
	_pivote.add_child(mi)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.15, 3.0)
	cam.fov = 40.0
	sv.add_child(cam)
	cam.current = true

func _process(delta: float) -> void:
	if _pivote == null:
		return
	var giro := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		giro -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		giro += 1.0
	if giro != 0.0:
		_auto = false
		_pivote.rotation.y += giro * delta * 2.2
	elif _auto and not _arrastrando:
		_pivote.rotation.y += delta * 0.5

func _arrastre(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = (ev as InputEventMouseButton).pressed
		_auto = false
	elif ev is InputEventMouseMotion and _arrastrando and _pivote != null:
		_pivote.rotation.y += (ev as InputEventMouseMotion).relative.x * 0.012

func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
