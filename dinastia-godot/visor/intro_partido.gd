class_name IntroPartido
extends Node
## LA PRESENTACIÓN DEL PARTIDO (25-9-2026, plan maestro B3). Antes del saque, la
## cámara vuela alrededor del estadio mientras abajo aparece el rótulo del
## partido -los dos equipos, el estadio, el aforo y la competición-, como la
## apertura de una transmisión. Dura `DURACION` segundos y se salta con un clic
## o una tecla. Mientras dura, la vista congela el partido (no corre el reloj).

signal terminada

const DURACION := 6.0

var activa := false
var _cam: Camera3D
var _previa: Camera3D
var _t := 0.0
var _radio := 90.0
var _alto := 30.0
var _rotulo: Control

## `ui`: el Control donde va el rótulo (la propia vista del estadio).
static func iniciar(ui: Control, dx: float, dz: float, alto_estadio: float, titulo: String, sub: String) -> IntroPartido:
	var n := IntroPartido.new()
	ui.add_child(n)
	n._montar(ui, dx, dz, alto_estadio, titulo, sub)
	return n

func _montar(ui: Control, dx: float, dz: float, alto_estadio: float, titulo: String, sub: String) -> void:
	activa = true
	_previa = get_viewport().get_camera_3d()
	_radio = maxf(dx, dz) * 1.25 + 20.0
	_alto = alto_estadio + 22.0
	_cam = Camera3D.new()
	_cam.fov = 50.0
	add_child(_cam)
	_colocar(0.0)
	_cam.current = true
	## El rótulo, estilo transmisión: una franja abajo con los dos nombres.
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Color(0.03, 0.06, 0.05, 0.86), Tema.RADIO_GRANDE, Color(1, 1, 1, 0.15)))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_child(v)
	var t := Tema.etiqueta(Tema.TAM_TITULO + 6, Tema.TEXTO, titulo)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := Tema.etiqueta(Tema.TAM_CUERPO + 1, Tema.ORO, sub)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var salta := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "Clic para saltar")
	salta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(salta)
	ui.add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caja.offset_bottom = -60
	_rotulo = caja
	Animar.aparecer(caja, 0.3, 0.5)

## Media vuelta alrededor del estadio, bajando mientras se acerca.
func _colocar(f: float) -> void:
	var a := lerpf(deg_to_rad(215.0), deg_to_rad(325.0), f)
	var r := lerpf(_radio, _radio * 0.72, f)
	var y := lerpf(_alto, _alto * 0.55, f)
	_cam.global_position = Vector3(cos(a) * r, y, sin(a) * r)
	_cam.look_at(Vector3(0, 2.0, 0), Vector3.UP)

func _process(delta: float) -> void:
	if not activa:
		return
	_t += delta
	var f := clampf(_t / DURACION, 0.0, 1.0)
	## Suave al principio y al final, como un travelling de grúa.
	_colocar(f * f * (3.0 - 2.0 * f))
	if _t >= DURACION:
		terminar()

func _unhandled_input(e: InputEvent) -> void:
	if activa and ((e is InputEventMouseButton and (e as InputEventMouseButton).pressed) or (e is InputEventKey and (e as InputEventKey).pressed)):
		terminar()
		get_viewport().set_input_as_handled()

func terminar() -> void:
	if not activa:
		return
	activa = false
	if is_instance_valid(_previa):
		_previa.current = true
	if is_instance_valid(_rotulo):
		var tw := _rotulo.create_tween()
		tw.tween_property(_rotulo, "modulate:a", 0.0, 0.35)
		tw.tween_callback(_rotulo.queue_free)
	_cam.queue_free()
	terminada.emit()
