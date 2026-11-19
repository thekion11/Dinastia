class_name PrologoPlanos
extends Node
## LOS PLANOS DEL PRÓLOGO (18-11-2026, decisión del dueño: prólogo «mixto» que varíe según el club; paso 2 = planos de cámara por paso).
## Al llegar a cada sala del recorrido, ANTES de que hable el mentor, un plano de establecimiento: franjas de cine, el nombre de la sala con el
## color del club y la cámara recorriendo la sala de una esquina alta a la otra; al final vuelve, suave, a tus ojos (primera persona, orden 45).
## Qué esquina, qué altura y hacia dónde se mueve salen de la semilla club + paso: cada club ve su edificio desde otro sitio.
## Se salta con E / Intro / Espacio / X / A o un clic. Es la base de la cinemática pregrabada (mismos planos, grabados con `--write-movie`).

signal terminado

const SEG_RECORRIDO := 3.0
const SEG_VUELTA := 0.7
const SALAS := ["vestuario", "utileria", "enfermeria", "presidente", "video", "prensa", "comedor", "oficina"]
const ALTO_FRANJA := 0.11   ## fracción de la pantalla que tapa cada franja de cine

var _cam: Camera3D
var _expl: Node
var _modo_antes := Node.PROCESS_MODE_INHERIT
var _vuelta := Transform3D.IDENTITY
var _capa: CanvasLayer
var _franjas: Array[ColorRect] = []
var _rotulo: VBoxContainer
var _tw: Tween
var _saltar := false
var _activo := false

## ¿Tiene plano este paso del guion?
static func tiene(clave: String) -> bool:
	return clave in SALAS

## Las dos poses (desde, hasta) del recorrido por la sala `r` (suelo x-z en el mundo; la puerta da a +Z, la pared del fondo es `r.position.y`).
static func poses(r: Rect2, y0: float, semilla: int) -> Array[Transform3D]:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var izq := rng.randf() < 0.5
	var alto := rng.randf_range(2.05, 2.55)
	var m := 0.45
	var x_a := r.position.x + m if izq else r.end.x - m
	var x_b := r.end.x - m if izq else r.position.x + m
	var c := r.get_center()
	var fondo := r.position.y + minf(0.9, r.size.y * 0.25)
	var a := Vector3(x_a, y0 + alto, r.end.y - m)
	var b := Vector3(lerpf(x_b, c.x, 0.35), y0 + alto - 0.45, lerpf(r.end.y - m, c.y, rng.randf_range(0.15, 0.4)))
	var mira_a := Vector3(lerpf(c.x, x_b, 0.25), y0 + 1.0, fondo)
	var mira_b := Vector3(lerpf(c.x, x_a, 0.3), y0 + 1.15, fondo)
	return [Transform3D(Basis.IDENTITY, a).looking_at(mira_a, Vector3.UP), Transform3D(Basis.IDENTITY, b).looking_at(mira_b, Vector3.UP)]

## Rueda el plano y vuelve a los ojos del explorador. `sala`: el nombre (se traduce); `club`: el nombre visible; `color`: el del club.
func rodar(explorador: Node, r: Rect2, y0: float, semilla: int, sala: String, club: String, color: Color) -> void:
	_expl = explorador
	_cam = explorador.get("camara") as Camera3D
	if _cam == null or not _cam.is_inside_tree():
		terminado.emit()
		return
	_activo = true
	_vuelta = _cam.global_transform
	_modo_antes = explorador.process_mode
	explorador.process_mode = Node.PROCESS_MODE_DISABLED
	_montar_capa(Idiomas.t(sala), club, color)
	var p := poses(r, y0, semilla)
	_cam.global_transform = p[0]
	_entrar_capa(true)
	_tw = create_tween()
	_tw.tween_method(_poner.bind(p[0], p[1]), 0.0, 1.0, SEG_RECORRIDO).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tw.finished
	_entrar_capa(false)
	var desde := _cam.global_transform
	_tw = create_tween()
	_tw.tween_method(_poner.bind(desde, _vuelta), 0.0, 1.0, 0.05 if _saltar else SEG_VUELTA).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _tw.finished
	_cerrar()

func _poner(k: float, a: Transform3D, b: Transform3D) -> void:
	if is_instance_valid(_cam):
		_cam.global_transform = PcAnimacion._mezcla(a, b, k)

func _cerrar() -> void:
	_activo = false
	if is_instance_valid(_cam):
		_cam.global_transform = _vuelta
	if is_instance_valid(_expl):
		_expl.process_mode = _modo_antes
	if is_instance_valid(_capa):
		_capa.queue_free()
	terminado.emit()

func _unhandled_input(ev: InputEvent) -> void:
	if not _activo or _saltar:
		return
	var salta := (ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo and (ev as InputEventKey).keycode in [KEY_E, KEY_ENTER, KEY_SPACE]) \
		or (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index in [JOY_BUTTON_X, JOY_BUTTON_A]) \
		or (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed)
	if salta:
		get_viewport().set_input_as_handled()
		_saltar = true
		if _tw != null and _tw.is_valid():
			_tw.custom_step(SEG_RECORRIDO)   ## acaba el recorrido ya: la vuelta a los ojos es casi inmediata

## Franjas de cine (arriba y abajo) y el rótulo de la sala abajo a la izquierda, con una raya del color del club.
func _montar_capa(sala: String, club: String, color: Color) -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 40
	add_child(_capa)
	for arriba in [true, false]:
		var f := ColorRect.new()
		f.color = Color(0, 0, 0, 1)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.anchor_left = 0.0
		f.anchor_right = 1.0
		f.anchor_top = 0.0 if arriba else 1.0
		f.anchor_bottom = 0.0 if arriba else 1.0
		_capa.add_child(f)
		_franjas.append(f)
	_rotulo = VBoxContainer.new()
	_rotulo.anchor_top = 1.0 - ALTO_FRANJA - 0.17
	_rotulo.anchor_bottom = 1.0 - ALTO_FRANJA - 0.02
	_rotulo.anchor_left = 0.05
	_rotulo.anchor_right = 0.6
	_rotulo.modulate.a = 0.0
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(_rotulo)
	var raya := ColorRect.new()
	raya.color = color
	raya.custom_minimum_size = Vector2(90, 4)
	raya.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_rotulo.add_child(raya)
	var t := Label.new()
	t.text = sala.to_upper()
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	t.add_theme_constant_override("outline_size", 6)
	_rotulo.add_child(t)
	var s := Label.new()
	s.text = club
	s.add_theme_font_size_override("font_size", 18)
	s.add_theme_color_override("font_color", color.lerp(Color.WHITE, 0.45))
	s.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	s.add_theme_constant_override("outline_size", 5)
	_rotulo.add_child(s)

func _entrar_capa(entra: bool) -> void:
	var alto := get_viewport().get_visible_rect().size.y * ALTO_FRANJA
	var tw := create_tween().set_parallel(true)
	for i in _franjas.size():
		var f := _franjas[i]
		var arriba := i == 0
		tw.tween_property(f, "offset_bottom" if arriba else "offset_top", (alto if arriba else -alto) if entra else 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_rotulo, "modulate:a", 1.0 if entra else 0.0, 0.5 if entra else 0.25).set_delay(0.35 if entra else 0.0)
