class_name SalaVAR
extends Control
## LA SALA VAR POR DENTRO (26-9-2026). Pedido: *"ver el VAR por dentro"*.
##
## Cuando el árbitro pide revisar, la transmisión se va a la sala de vídeo:
## una sala oscura con una pared de monitores, dos puestos con sus operadores
## (auriculares, polo oscuro) y el rótulo VAR. Los monitores NO son dibujos:
## cada uno es una cámara de verdad sobre el MISMO mundo 3D del partido (detrás
## del arco, lateral a ras de campo, cenital y la de la jugada), así que se ve
## lo que está pasando en el campo desde cuatro ángulos.
## Dura unos segundos, muestra la decisión y se cierra sola. El partido se
## pausa mientras tanto (lo reanuda quien la abrió, con `terminada`).

signal terminada

const DURACION := 6.5

var _vp: SubViewport
var _cam: Camera3D
var _t := 0.0
var _rotulo: Label
var _reloj: Label
var _decision: PanelContainer
var _motivo := ""
var _minuto := 0
var _mundo_partido: World3D
var _foco := Vector3.ZERO
var _monitores: Array = []

static func abrir(padre: Control, mundo_partido: World3D, foco: Vector3, minuto: int, motivo: String) -> SalaVAR:
	var s := SalaVAR.new()
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
	_rotulo.text = "🖥️  REVISIÓN VAR  ·  %d'  ·  %s" % [_minuto, _motivo]
	_rotulo.add_theme_font_size_override("font_size", 26)
	_rotulo.add_theme_color_override("font_color", Color("e8f4ff"))
	_rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_rotulo)
	_reloj = Label.new()
	_reloj.add_theme_font_size_override("font_size", 26)
	_reloj.add_theme_color_override("font_color", Color("3fa9f5"))
	fila.add_child(_reloj)
	_decision = PanelContainer.new()
	var sd := StyleBoxFlat.new()
	sd.bg_color = Color(0.05, 0.35, 0.15, 0.95)
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
	ld.text = "✔  DECISIÓN: SE MANTIENE LO DECIDIDO EN EL CAMPO"
	ld.add_theme_font_size_override("font_size", 30)
	ld.add_theme_color_override("font_color", Color.WHITE)
	_decision.add_child(ld)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

## La sala: suelo, paredes, luz fría, la pared de monitores, dos puestos con
## operadores y el rótulo.
func _sala() -> void:
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.03, 0.05)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.25, 0.32, 0.45)
	e.ambient_light_energy = 0.6
	e.glow_enabled = true
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
	## Rótulo VAR.
	var var_rot := Label3D.new()
	var_rot.text = "VAR"
	var_rot.font_size = 160
	var_rot.pixel_size = 0.004
	var_rot.modulate = Color("3fa9f5")
	var_rot.outline_size = 0
	var_rot.position = Vector3(0, 2.95, -3.12)
	raiz.add_child(var_rot)
	## Los monitores: cuatro cámaras sobre el partido real.
	var angulos := [
		[Vector3(_foco.x * 0.3, 8.0, _foco.z + signf(_foco.z + 0.01) * 16.0), _foco, 40.0],  ## detrás de la jugada
		[Vector3(36.0, 2.0, _foco.z), _foco, 30.0],                                          ## lateral a ras de campo (fuera de juego)
		[Vector3(_foco.x, 45.0, _foco.z + 0.1), _foco, 45.0],                                 ## cenital
		[Vector3(-30.0, 14.0, _foco.z * 0.6), _foco, 28.0],                                   ## tele contraria
	]
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
	## Dos puestos con su operador (auriculares y polo oscuro).
	for lado: float in [-1.0, 1.0]:
		var mesa_x := 1.6 * lado
		_caja(raiz, Vector3(mesa_x, 0.75, -0.9), Vector3(2.2, 0.06, 0.9), Color(0.13, 0.14, 0.17), 0.0)
		_caja(raiz, Vector3(mesa_x, 0.37, -0.9), Vector3(2.1, 0.74, 0.08), Color(0.1, 0.1, 0.12), 0.0)
		## Pantallas de mesa encendidas.
		_caja(raiz, Vector3(mesa_x - 0.45, 1.05, -1.15), Vector3(0.7, 0.42, 0.03), Color(0.25, 0.55, 0.9), 1.4)
		_caja(raiz, Vector3(mesa_x + 0.45, 1.05, -1.15), Vector3(0.7, 0.42, 0.03), Color(0.2, 0.7, 0.45), 1.2)
		_operador(raiz, Vector3(mesa_x, 0.0, -0.1), lado)
	_cam = Camera3D.new()
	_cam.fov = 52
	_cam.position = Vector3(2.8, 2.1, 3.6)
	raiz.add_child(_cam)
	_cam.look_at(Vector3(0, 1.5, -2.5), Vector3.UP)
	_cam.current = true

func _caja(raiz: Node3D, pos: Vector3, tam: Vector3, col: Color, emision: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.7
	if emision > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emision
	mi.material_override = m
	mi.position = pos
	raiz.add_child(mi)
	return mi

func _monitor(raiz: Node3D, pos: Vector3, tam: Vector2, tex: Texture2D, i: int) -> void:
	_caja(raiz, pos + Vector3(0, 0, -0.03), Vector3(tam.x + 0.08, tam.y + 0.08, 0.05), Color(0.02, 0.02, 0.03), 0.0)
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = tam
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if tex != null:
		m.albedo_texture = tex
	else:
		m.albedo_color = Color(0.1, 0.3, 0.2)
	mi.material_override = m
	mi.position = pos
	raiz.add_child(mi)
	var et := Label3D.new()
	et.text = ["CÁMARA 1 · JUGADA", "CÁMARA 2 · LÍNEA", "CÁMARA 3 · CENITAL", "CÁMARA 4 · CONTRA"][i]
	et.font_size = 28
	et.pixel_size = 0.0035
	et.modulate = Color(0.85, 0.92, 1.0)
	et.position = pos + Vector3(-tam.x * 0.5 + 0.35, tam.y * 0.5 - 0.07, 0.01)
	raiz.add_child(et)

func _operador(raiz: Node3D, pos: Vector3, lado: float) -> void:
	var d := FutbolistaQ.crear(1.78, "male")
	if d.is_empty():
		return
	var nodo: Node3D = d["nodo"]
	nodo.position = pos
	nodo.rotation_degrees.y = 180.0
	raiz.add_child(nodo)
	FutbolistaQ.terminar(d, false)
	VestidorQ.vestir_equipacion(d, Color("1b1f27"), Color("3fa9f5"), "liso", Color("b98a66") if lado < 0 else Color("7a5238"),
		Color(0.1, 0.08, 0.06), Color("22252c"), Color("111111"))
	var ap: AnimationPlayer = d["anim"]
	if ap.has_animation("sentado"):
		ap.play("sentado")
	## Auriculares: una diadema y dos cascos.
	var cab := Node3D.new()
	cab.position = pos + Vector3(0, 1.28, 0.05)
	raiz.add_child(cab)
	for s: float in [-1.0, 1.0]:
		var casco := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.045
		cm.bottom_radius = 0.045
		cm.height = 0.03
		casco.mesh = cm
		casco.rotation_degrees.z = 90.0
		casco.position = Vector3(0.085 * s, 0.0, 0.0)
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.08, 0.08, 0.09)
		casco.material_override = mm
		cab.add_child(casco)
	var diadema := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.085
	tm.outer_radius = 0.1
	diadema.mesh = tm
	diadema.rotation_degrees.z = 90.0
	diadema.rotation_degrees.y = 90.0
	diadema.position = Vector3(0, 0.02, 0)
	cab.add_child(diadema)

func _process(delta: float) -> void:
	## Paso acotado: el primer fotograma (cargando a los operadores) puede
	## durar segundos, y la revisión se "terminaba" antes de verse.
	delta = minf(delta, 0.1)
	_t += delta
	_reloj.text = "⏱ %02d" % int(_t)
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
