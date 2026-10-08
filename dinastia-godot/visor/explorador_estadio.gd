class_name ExploradorEstadio
extends Node3D
## RECORRER EL ESTADIO A PIE (7-10-2026, pedido: «a futuro el estadio será
## navegable con el protagonista»).
##
## Se empieza en el vestuario, se cruza el túnel y se sale a la cancha. Usa el
## mismo control que el paseo por la ciudad (`ExploradorCiudad`): W/S/A/D o
## flechas, el mando o la cruceta táctil; Mayús para correr y E para usar.
## El suelo transitable son las zonas de `TunelVestuario.datos()` (vestuario,
## pasillo, el paso de la banda y el campo); la cámara no sale del pasillo ni
## atraviesa su techo.

signal salir

const VEL_PIE := 1.8
const VEL_CORRER := 5.2
const RADIO := 0.45

var cuerpo: Node3D
var camara: Camera3D
var rumbo := PI
var vel := 0.0
var zonas: Array = []
var club_nombre := ""
var _anim: AnimationPlayer
var _hud: Label
var _aviso: Label
var _capa: CanvasLayer
var _tactil_vec := Vector2.ZERO
var _zona_actual := ""
var _datos: Dictionary = {}
var _rugido_hecho := false
## La planta del edificio del club en la que estás (0 = vestuario y campo).
var planta := 0
var _menu: PanelContainer

func iniciar(est: Dictionary, niveles: int, club: Club) -> void:
	_datos = TunelVestuario.datos(est, niveles)
	_est_perfil = est
	zonas = _datos["zonas"]
	club_nombre = Nombres.visible(club.nombre) if club != null else ""
	cuerpo = _crear_cuerpo()
	add_child(cuerpo)
	cuerpo.position = _datos["inicio"]
	rumbo = float(_datos["rumbo_inicio"])
	camara = Camera3D.new()
	camara.fov = 68.0
	camara.near = 0.05
	add_child(camara)
	camara.make_current()
	_montar_hud()
	_colocar_camara(1.0)

var _es_dt := false

func _crear_cuerpo() -> Node3D:
	## Tu personaje: el DT con su aspecto, si lo hay.
	if not PersonajeDT.del_usuario.is_empty():
		var raiz := Node3D.new()
		add_child(raiz)
		var dt := PersonajeDT.crear(raiz, PersonajeDT.del_usuario, Color(0.12, 0.13, 0.16), Color(0.9, 0.9, 0.92))
		remove_child(raiz)
		if not dt.is_empty():
			_anim = dt.get("anim") as AnimationPlayer
			_es_dt = true
			return raiz
		raiz.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var d := PeatonQ.crear(rng)
	if d.is_empty():
		return Node3D.new()
	var n: Node3D = d["nodo"]
	add_child(n)
	PeatonQ.terminar(d)
	remove_child(n)
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

## ¿En qué zona de la planta actual cae este punto? (vacío: no se pisa).
func zona_en(p: Vector3, _radio: float = 0.0) -> Dictionary:
	return TunelVestuario.zona_en(zonas, p, planta)

## Cambia de planta por el ascensor (misma x y z: el hueco está apilado).
func ir_a_planta(p: int) -> void:
	planta = p
	cuerpo.position.y = RecorridoClub.y_de(p)
	_zona_actual = "?"
	_colocar_camara(1.0)

func _montar_hud() -> void:
	_capa = CanvasLayer.new()
	add_child(_capa)
	_hud = Label.new()
	_hud.position = Vector2(18, 14)
	_hud.add_theme_font_size_override("font_size", 16)
	_hud.add_theme_color_override("font_color", Color.WHITE)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 6)
	_capa.add_child(_hud)
	_aviso = Label.new()
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.offset_top = -90
	_aviso.offset_left = -320
	_aviso.offset_right = 320
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 20)
	_aviso.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	_aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override("outline_size", 8)
	_capa.add_child(_aviso)
	## Táctil: cruceta abajo a la izquierda y «Salir» abajo a la derecha.
	var tam := 74.0
	var base := Control.new()
	base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	base.offset_left = 24
	base.offset_top = -tam * 3.0 - 24
	_capa.add_child(base)
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
	var be := Button.new()
	be.text = "E"
	be.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	be.offset_left = -240
	be.offset_top = -100
	be.offset_right = -166
	be.offset_bottom = -24
	be.modulate = Color(1, 1, 1, 0.75)
	be.focus_mode = Control.FOCUS_NONE
	be.pressed.connect(usar)
	_capa.add_child(be)
	var bs := Button.new()
	bs.text = Idiomas.t("Salir")
	bs.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bs.offset_left = -150
	bs.offset_top = -100
	bs.offset_right = -24
	bs.offset_bottom = -24
	bs.modulate = Color(1, 1, 1, 0.75)
	bs.focus_mode = Control.FOCUS_NONE
	bs.pressed.connect(func() -> void: salir.emit())
	_capa.add_child(bs)

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

## Un paso de simulación (lo usa `_physics_process` y las pruebas).
func paso(e: Vector2, corre: bool, delta: float) -> void:
	vel = (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
	rumbo -= e.x * delta * 2.6
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var nueva := cuerpo.position + adelante * vel * delta
	if not zona_en(nueva, RADIO).is_empty():
		cuerpo.position = Vector3(nueva.x, RecorridoClub.y_de(planta), nueva.z)
	else:
		vel = 0.0
	cuerpo.rotation.y = rumbo
	if _es_dt and _anim != null:
		var quiere := "correr" if absf(vel) > 3.0 else ("caminar" if absf(vel) > 0.05 else "parado")
		if _anim.has_animation(quiere) and _anim.current_animation != quiere:
			_anim.play(quiere, 0.25)
	elif _anim != null:
		_anim.speed_scale = absf(vel) / 1.4 if absf(vel) > 0.05 else 0.0

func _physics_process(delta: float) -> void:
	if cuerpo == null:
		return
	if sentado:
		## Sentado: A/D giran la mirada (hasta 70° a cada lado).
		_mirada = clampf(_mirada - _entrada().x * delta * 1.4, -1.2, 1.2)
		var dir := Vector3(sin(rumbo + _mirada), 0, cos(rumbo + _mirada))
		camara.position = cuerpo.position + Vector3(0, 1.2, 0) + Vector3(sin(rumbo), 0, cos(rumbo)) * 0.1
		camara.look_at(camara.position + dir * 10.0 + Vector3(0, -1.6, 0), Vector3.UP)
		return
	var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	paso(_entrada(), corre, delta)
	_colocar_camara(delta)
	_rotulos()

func _junto_a_la_persiana() -> bool:
	var x0 := float(_datos.get("x0", 0.0))
	return absf(cuerpo.position.x - (x0 + TunelVestuario.PUERTA_X)) < GaleriaClub.MEDIO + 0.6 \
		and cuerpo.position.z > float(_datos.get("z_fin", 0.0)) - 1.6

func _rotulos() -> void:
	var z := zona_en(cuerpo.position)
	var nombre := String(z.get("nombre", ""))
	var g := _persona_cerca()
	if not g.is_empty():
		_aviso.text = Idiomas.t("E: hablar con %s (%s)") % [String(g["nombre"]), Idiomas.t(String(g["puesto"]))]
		_zona_actual = "·" + nombre
	elif RecorridoClub.junto_a_la_grada(cuerpo.position, planta):
		_aviso.text = Idiomas.t("E: sentarse en la grada")
		_zona_actual = "·grada"
	elif planta == GaleriaClub.PLANTA and nombre == "Pasillo" and _junto_a_la_persiana():
		## La puerta de la galería: aquí está cerrada (el complejo está en la ciudad).
		if _zona_actual != "·galeria":
			_zona_actual = "·galeria"
			_aviso.text = Idiomas.t("La galería al complejo se recorre desde la ciudad (Ciudad 3D → a pie)")
	elif nombre != _zona_actual:
		_zona_actual = nombre
		_aviso.text = RecorridoClub.aviso_de(nombre, club_nombre)
		if RecorridoClub.sala_decorable(nombre):
			_aviso.text += "  ·  " + Idiomas.t("E: decorar")
		if nombre == "Banda" and not _rugido_hecho:
			_rugido_hecho = true
			Sonido.toca("salida_tunel", Sonido.Bus.AMBIENTE)
	_hud.text = "📍 %s · %s %d  ·  %s" % [Idiomas.t(nombre), Idiomas.t("Planta"), planta, Idiomas.t("W/S/A/D o mando · Mayús: correr · E: usar · Esc: salir")]

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		salir.emit()
	elif (ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_E) \
			or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_X):
		get_viewport().set_input_as_handled()
		usar()

## Sentado en la grada: dónde y hacia dónde se mira.
var sentado := false
var _de_pie := Vector3.ZERO
var _mirada := 0.0
var _est_perfil: Dictionary = {}

func sentarse() -> void:
	var lado := signf(cuerpo.position.x)
	var b := RecorridoClub.butaca(_est_perfil, lado, cuerpo.position.z)
	_de_pie = cuerpo.position
	cuerpo.position = b["pos"]
	rumbo = float(b["rumbo"])
	_mirada = 0.0
	cuerpo.rotation.y = rumbo
	sentado = true
	## Desde los ojos: el propio cuerpo no se ve y nadie ocupa tu butaca.
	cuerpo.visible = false
	_hinchas_quitados = RecorridoClub.despejar_hinchas(get_parent(), cuerpo.global_position + Vector3(0, 0.5, 0))
	_aviso.text = Idiomas.t("En la grada. A/D: mirar alrededor · E: levantarse")

var _hinchas_quitados: Array = []

func levantarse() -> void:
	sentado = false
	cuerpo.visible = true
	RecorridoClub.devolver_hinchas(_hinchas_quitados)
	_hinchas_quitados = []
	cuerpo.position = _de_pie
	_aviso.text = ""
	_zona_actual = "?"

## E: lo que haya a mano: alguien del club para hablar, o el ascensor.
func usar() -> void:
	if is_instance_valid(_menu):
		return
	if sentado:
		levantarse()
		return
	if RecorridoClub.junto_a_la_grada(cuerpo.position, planta) and _persona_cerca().is_empty():
		sentarse()
		return
	var g := _persona_cerca()
	if not g.is_empty():
		_menu = RecorridoClub.dialogo(_capa, _personal(), g, cuerpo.position)
		return
	if _zona_actual == "Ascensor":
		_menu = RecorridoClub.menu_ascensor(_capa, planta, ir_a_planta)
	elif RecorridoClub.sala_decorable(_zona_actual):
		_menu = RecorridoClub.panel_decorar(_capa, get_tree(), _zona_actual)

func _personal() -> PersonalEstadio:
	return get_tree().get_first_node_in_group("personal_club") as PersonalEstadio

func _persona_cerca() -> Dictionary:
	var pe := _personal()
	return pe.cercano(cuerpo.position, planta) if pe != null else {}

## Cámara en tercera persona. Dentro del vestuario y del túnel no sale de las
## paredes ni pasa del techo: si no, se vería el exterior de la caja.
func _colocar_camara(delta: float) -> void:
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var z := zona_en(cuerpo.position)
	var cerrado := float(z.get("techo", 99.0)) < 50.0
	var atras := 3.2 if cerrado else 5.5
	var alto := 1.9 if cerrado else 2.6
	var deseo := cuerpo.position - adelante * atras + Vector3(0, alto, 0)
	if cerrado:
		var r: Rect2 = z["r"]
		## La cámara puede ir un poco por detrás del límite de la zona por donde
		## se viene (la boca, la puerta) pero nunca atravesar una pared lateral.
		deseo.x = clampf(deseo.x, r.position.x + 0.15, r.end.x - 0.15)
		var holgura := 1.0 if String(z.get("nombre", "")) == "Túnel" else -0.15
		deseo.z = clampf(deseo.z, r.position.y - holgura, r.end.y + holgura)
		deseo.y = minf(deseo.y, RecorridoClub.y_de(planta) + float(z["techo"]) - 0.25)
	camara.position = camara.position.lerp(deseo, clampf(delta * 6.0, 0.0, 1.0)) if delta < 1.0 else deseo
	camara.look_at(cuerpo.position + Vector3(0, 1.4, 0) + adelante * 3.0, Vector3.UP)
