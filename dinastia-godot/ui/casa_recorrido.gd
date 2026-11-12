class_name CasaRecorrido
extends Control
## LA CASA DEL PERSONAJE, A PIE Y SIN CIUDAD (10-11, orden 33 «solo club»). Menú Vida → «Ver tu casa» con la ciudad apagada:
## pantalla completa con la casa más básica (`CasaPlano` / `CasaConstruccion`: sala, cocina, pasillo, dormitorio, baño y estudio) y tu DT
## caminándola en tercera persona (V: primera persona), igual que el club con `ExploradorEstadio`: W/S/A/D o flechas, mando o
## cruceta táctil, Mayús corre, E en la puerta de la calle (o Esc) vuelve al menú. Paredes y muebles chocan (`CasaPlano.mover`).
## NO construye la ciudad ni nombra sus clases: el menú llega aquí por `CasaAcceso` con `load()`.

signal cerrado

const VEL_PIE := 1.6
const VEL_CORRER := 3.6

var pos2 := CasaPlano.INICIO
var rumbo := CasaPlano.RUMBO_INICIO
var vel := 0.0
var primera_persona := VistaJuego.inicial()   ## (12-11, dueño) en el juego, solo primera persona (`VistaJuego`)
var mirada_v := -0.03   ## (12-11) cabeceo de la mirada (rad; > 0 arriba)
var cuerpo: Node3D
var camara: Camera3D
var zona_actual := ""
var _obst: Array = []
var _anim: AnimationPlayer
var _es_dt := false
var _mundo3d: Node3D
var _lugar: Label
var _aviso: Label
var _ayuda: Label
var _boton_e: Button
var _tactil_vec := Vector2.ZERO

## Abre la casa sobre `p` (principal). Devuelve el control para poder cerrarlo desde fuera.
static func abrir(p: Control, m: Mundo, _bandeja: Array = []) -> Control:
	var r := CasaRecorrido.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(r)
	r.montar(m)
	return r

func montar(m: Mundo) -> void:
	_obst = CasaPlano.obstaculos()
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.035, 0.04)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cont)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Calidad.msaa_ui(Viewport.MSAA_4X)
	CalidadRes3D.limitar(vp)   ## (10-11, P1) tope de altura del 3D en móvil
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cont.add_child(vp)
	_mundo3d = Node3D.new()
	vp.add_child(_mundo3d)
	CasaConstruccion.construir(_mundo3d)
	var c := m.mi_club() if m != null else null
	cuerpo = _crear_cuerpo(m, Color(c.color1) if c != null else Color("1f5fa8"), Color(c.color2) if c != null else Color.WHITE)
	_mundo3d.add_child(cuerpo)
	camara = Camera3D.new()
	camara.fov = 70.0
	camara.near = 0.05
	camara.environment = CasaConstruccion.entorno()
	_mundo3d.add_child(camara)
	camara.make_current()
	_montar_interfaz()
	_poner_cuerpo()
	_colocar_camara(1.0)

func _crear_cuerpo(m: Mundo, c1: Color, c2: Color) -> Node3D:
	var asp: Dictionary = m.roles.aspecto_3d() if m != null and m.roles != null else {}
	var raiz := Node3D.new()
	_mundo3d.add_child(raiz)
	var dt := PersonajeDT.crear(raiz, asp, c1, c2)
	if not dt.is_empty():
		_anim = dt.get("anim") as AnimationPlayer
		_es_dt = true
		_mundo3d.remove_child(raiz)
		return raiz
	raiz.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var d = CargaCiudad.de("PeatonQ").crear(rng)
	if d.is_empty():
		return Node3D.new()
	var n: Node3D = d["nodo"]
	_mundo3d.add_child(n)
	CargaCiudad.de("PeatonQ").terminar(d)
	_mundo3d.remove_child(n)
	_anim = _buscar_anim(n)
	return n

func _buscar_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for h in n.get_children():
		var a := _buscar_anim(h)
		if a != null:
			return a
	return null

func _montar_interfaz() -> void:
	_lugar = Tema.etiqueta(Tema.TAM_DESTACADO + 6, Tema.TEXTO, "")
	_lugar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_lugar.offset_top = 28
	_lugar.offset_left = -300
	_lugar.offset_right = 300
	_lugar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lugar.add_theme_constant_override("outline_size", 8)
	_lugar.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_lugar.modulate.a = 0.0
	_lugar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lugar)
	_aviso = Label.new()
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.offset_top = -96
	_aviso.offset_left = -320
	_aviso.offset_right = 320
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 20)
	_aviso.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	_aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override("outline_size", 8)
	_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_aviso)
	_ayuda = Label.new()
	_ayuda.text = Idiomas.t("W/S/A/D o mando · Mayús: correr · V: primera persona · E: usar · Esc: volver") if VistaJuego.puede_cambiar() \
		else Idiomas.t("W/S/A/D o mando · ratón: mirar · Mayús: correr · E: usar · Esc: volver")
	_ayuda.position = Vector2(18, 14)
	_ayuda.add_theme_font_size_override("font_size", 16)
	_ayuda.add_theme_color_override("font_outline_color", Color.BLACK)
	_ayuda.add_theme_constant_override("outline_size", 6)
	_ayuda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ayuda)
	var tw := _ayuda.create_tween()
	tw.tween_interval(9.0)
	tw.tween_property(_ayuda, "modulate:a", 0.0, 1.5)
	## Táctil: cruceta abajo a la izquierda, E abajo a la derecha y «Volver» arriba a la derecha.
	var tam := 74.0
	var base := Control.new()
	base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	base.offset_left = 24
	base.offset_top = -tam * 3.0 - 24
	base.visible = CargaCiudad.de("ExploradorCiudad").es_tactil()
	add_child(base)
	for d: Array in [["▲", Vector2(1, 0), Vector2(0, 1)], ["▼", Vector2(1, 2), Vector2(0, -1)],
			["◀", Vector2(0, 1), Vector2(-1, 0)], ["▶", Vector2(2, 1), Vector2(1, 0)]]:
		var b := Button.new()
		b.text = String(d[0])
		b.position = (d[1] as Vector2) * tam
		b.size = Vector2(tam - 6, tam - 6)
		b.add_theme_font_size_override("font_size", 28)
		b.modulate = Color(1, 1, 1, 0.7)
		var v: Vector2 = d[2]
		b.button_down.connect(func() -> void: _tactil_vec += v)
		b.button_up.connect(func() -> void: _tactil_vec -= v)
		base.add_child(b)
	_boton_e = Button.new()
	_boton_e.text = "E"
	_boton_e.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_boton_e.offset_left = -240
	_boton_e.offset_top = -100
	_boton_e.offset_right = -166
	_boton_e.offset_bottom = -24
	_boton_e.focus_mode = Control.FOCUS_NONE
	_boton_e.visible = false
	_boton_e.pressed.connect(usar)
	add_child(_boton_e)
	var volver := Button.new()
	volver.text = Idiomas.t("✕ Volver")
	volver.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	volver.offset_left = -130
	volver.offset_right = -30
	volver.offset_top = 24
	volver.offset_bottom = 60
	volver.focus_mode = Control.FOCUS_NONE
	volver.pressed.connect(salir)
	add_child(volver)

func _poner_cuerpo() -> void:
	cuerpo.position = Vector3(pos2.x, 0.0, pos2.y)
	cuerpo.rotation.y = rumbo
	_animar_paso()

func _entrada() -> Vector2:
	var x := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var y := float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
	var jx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var jy := -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(jx) > 0.2:
		x = jx
	if absf(jy) > 0.2:
		y = jy
	if _tactil_vec != Vector2.ZERO:
		x = clampf(_tactil_vec.x, -1.0, 1.0)
		y = clampf(_tactil_vec.y, -1.0, 1.0)
	return Vector2(x, y)

func _animar_paso() -> void:
	if _anim == null:
		return
	if _es_dt:
		var quiere := "correr" if absf(vel) > 2.6 else ("caminar" if absf(vel) > 0.05 else "parado")
		if _anim.has_animation(quiere) and _anim.current_animation != quiere:
			_anim.play(quiere, 0.25)
	else:
		_anim.speed_scale = absf(vel) / 1.4 if absf(vel) > 0.05 else 0.0

## Un paso de simulación (lo usan `_physics_process` y las pruebas).
func paso(e: Vector2, corre: bool, delta: float) -> void:
	var objetivo := (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
	vel = move_toward(vel, objetivo, (7.0 if absf(objetivo) > absf(vel) else 12.0) * delta) if delta > 0.0 else objetivo
	rumbo -= e.x * delta * 2.6
	var adelante := Vector2(sin(rumbo), cos(rumbo))
	var ant := pos2
	pos2 = CasaPlano.mover(ant, ant + adelante * vel * delta, _obst)
	var pedido := vel * delta
	var hecho := (pos2 - ant).length()
	if absf(pedido) > 1e-4 and hecho < absf(pedido) * 0.2:
		vel = 0.0
	_poner_cuerpo()

func _colocar_camara(delta: float) -> void:
	var adelante := Vector2(sin(rumbo), cos(rumbo))
	if primera_persona:
		camara.position = Vector3(pos2.x + adelante.x * 0.18, 1.62, pos2.y + adelante.y * 0.18)
		camara.look_at(camara.position + Vector3(adelante.x * 5.0, tan(mirada_v) * 5.0, adelante.y * 5.0), Vector3.UP)
		cuerpo.visible = false
		return
	cuerpo.visible = true
	## Detrás de ti, pero sin meterse en una pared: si la habitación es corta la cámara se acerca y sube.
	var atras := CasaPlano.distancia_camara(pos2, -adelante, 3.0, _obst)
	var falta := 1.0 - atras / 3.0
	var alto := minf(1.9 + 0.5 * falta, CasaPlano.ALTO - 0.25)
	var deseo := Vector3(pos2.x - adelante.x * atras, alto, pos2.y - adelante.y * atras)
	var nueva := camara.position.lerp(deseo, clampf(delta * 6.0, 0.0, 1.0)) if delta < 1.0 else deseo
	if not CasaPlano.libre(Vector2(nueva.x, nueva.z), _obst, 0.1):
		nueva = deseo
	camara.position = nueva
	camara.look_at(Vector3(pos2.x, 1.35 - 0.3 * falta, pos2.y) + Vector3(adelante.x, 0.0, adelante.y) * (2.8 - 0.8 * falta), Vector3.UP)

func _junto_a_la_puerta() -> bool:
	return pos2.distance_to(CasaPlano.PUERTA_CALLE) < 1.5

func _rotulos() -> void:
	var nombre := CasaPlano.sala_en(pos2)
	if nombre != zona_actual and nombre != "":
		zona_actual = nombre
		_lugar.text = Idiomas.t(nombre)
		var tw := _lugar.create_tween()
		tw.tween_property(_lugar, "modulate:a", 1.0, 0.3)
		tw.tween_interval(1.8)
		tw.tween_property(_lugar, "modulate:a", 0.0, 0.8)
	var puerta := _junto_a_la_puerta()
	_aviso.text = Idiomas.t("E: salir de casa") if puerta else ""
	_boton_e.visible = puerta

## E: junto a la puerta de la calle, sales de la casa.
func usar() -> void:
	if _junto_a_la_puerta():
		salir()

func salir() -> void:
	cerrado.emit()
	queue_free()

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE   ## (12-11) el cursor vuelve al salir de la casa

func _physics_process(delta: float) -> void:
	if cuerpo == null:
		return
	var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	paso(_entrada(), corre, minf(delta, 0.05))
	## (12-11) Mirar en primera persona: ratón capturado (PC), stick derecho y arrastre del dedo (en `_unhandled_input`).
	var raton := Input.MOUSE_MODE_CAPTURED if primera_persona and is_visible_in_tree() and DisplayServer.get_name() != "headless" and not EscalaMovil.es_movil() \
		else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != raton:
		Input.mouse_mode = raton
	var st := VistaJuego.mirada_stick(delta) if primera_persona else Vector2.ZERO
	rumbo -= st.x
	mirada_v = VistaJuego.cabeceo(mirada_v, st.y)
	_colocar_camara(delta)
	_rotulos()

func _unhandled_input(ev: InputEvent) -> void:
	var mira := VistaJuego.mirada_por_evento(ev, get_viewport_rect().size.x) if primera_persona else Vector2.ZERO
	if mira != Vector2.ZERO:
		rumbo -= mira.x
		mirada_v = VistaJuego.cabeceo(mirada_v, mira.y)
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			salir()
		elif k == KEY_V and VistaJuego.puede_cambiar():
			primera_persona = not primera_persona
		elif k == KEY_E:
			get_viewport().set_input_as_handled()
			usar()
	elif ev is InputEventJoypadButton and ev.pressed:
		var b := (ev as InputEventJoypadButton).button_index
		if b == JOY_BUTTON_B:
			get_viewport().set_input_as_handled()
			salir()
		elif b == JOY_BUTTON_X:
			get_viewport().set_input_as_handled()
			usar()
