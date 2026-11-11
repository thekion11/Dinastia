class_name VotoMotor
extends CanvasLayer
## EL VOTO DE DIVERSIÓN (11-11-2026, sesión 11): al acabar un partido jugado con una letra A/B/C, una pregunta rápida («¿cuánto te
## divirtió?», 1 a 5) que se guarda con el motor REAL detrás (`MotorEleccion.votar`). Vive en la raíz del árbol para sobrevivir al
## cierre del estadio y se quita al votar u omitir. Con el motor por defecto o en headless no aparece.

var _motor := ""
var _extra := {}

## `motor`: el motor del partido que acaba de terminar (lleva `motor_id` en su meta). Devuelve null si no toca preguntar.
static func mostrar(desde: Node, motor: Object) -> VotoMotor:
	if desde == null or not MotorEleccion.a_ciegas() or DisplayServer.get_name() == "headless":
		return null
	var v := VotoMotor.new()
	v._motor = String((motor as Object).get_meta("motor_id", MotorEleccion.motor_activo())) if motor != null else MotorEleccion.motor_activo()
	if motor != null:
		v._extra = {"marcador": "%d-%d" % [int(motor.goles[0]), int(motor.goles[1])], "tiros": int(motor.tiros[0]) + int(motor.tiros[1])}
	v.layer = 100
	desde.get_tree().root.add_child(v)
	return v

func _ready() -> void:
	var fondo := PanelContainer.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	fondo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	fondo.grow_vertical = Control.GROW_DIRECTION_BEGIN
	fondo.offset_bottom = -24.0
	add_child(fondo)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	fondo.add_child(caja)
	var q := Label.new()
	q.text = Idiomas.t("¿Cuánto te divirtió este partido?")
	q.add_theme_font_size_override("font_size", 18)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(q)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	for n in range(1, 6):
		var b := Button.new()
		b.text = str(n)
		b.custom_minimum_size = Vector2(64, 56)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(func() -> void:
			MotorEleccion.votar(n, _motor, _extra)
			queue_free())
		fila.add_child(b)
	var o := Button.new()
	o.text = Idiomas.t("Omitir")
	o.pressed.connect(queue_free)
	caja.add_child(o)
