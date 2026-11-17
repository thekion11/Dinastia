class_name MandoMenuPartido
extends Node
## EL MANDO EN TODAS LAS PANTALLAS DEL PARTIDO (17-11-2026, Auditoría: «R2 o A confirma, Cuadrado o B vuelve» en la previa, sus pestañas, el plan,
## la pausa, el descanso, el final y los momentos). A y B ya los da Godot (`ui_accept` / `ui_cancel`); lo que faltaba es lo del dueño (orden 33):
## R2 pulsa el botón que tiene el foco y Cuadrado vuelve atrás. Se cuelga como hijo de la pantalla (`escuchar`) y solo actúa si el foco está
## DENTRO de ella (o, para volver, si la pantalla está a la vista), así dos pantallas apiladas no se pisan.

var pantalla: Node   ## un Control o una capa (`PantallaMaqueta` es un CanvasLayer)
var atras: Callable
var _r2_abajo := false

## Cuelga el oyente de `pantalla`. `al_volver` es lo que hace Cuadrado (vacío: Cuadrado no hace nada en esa pantalla).
static func escuchar(p: Node, al_volver: Callable = Callable()) -> MandoMenuPartido:
	var m := MandoMenuPartido.new()
	m.name = "MandoMenuPartido"
	m.pantalla = p
	m.atras = al_volver
	p.add_child(m)
	return m

func _input(e: InputEvent) -> void:
	if manejar(e):
		get_viewport().set_input_as_handled()

## Devuelve true si el evento era suyo (R2 sobre un botón de la pantalla, o Cuadrado con la pantalla a la vista).
func manejar(e: InputEvent) -> bool:
	if not is_instance_valid(pantalla) or not a_la_vista(pantalla):
		return false
	if e is InputEventJoypadMotion and (e as InputEventJoypadMotion).axis == JOY_AXIS_TRIGGER_RIGHT:
		var abajo := (e as InputEventJoypadMotion).axis_value > 0.6
		var antes := _r2_abajo
		_r2_abajo = abajo
		if abajo and not antes:
			var f := pantalla.get_viewport().gui_get_focus_owner()
			if f is BaseButton and pantalla.is_ancestor_of(f) and not (f as BaseButton).disabled:
				(f as BaseButton).pressed.emit()
				return true
		return false
	if e is InputEventJoypadButton and (e as InputEventJoypadButton).pressed and (e as InputEventJoypadButton).button_index == JOY_BUTTON_X:
		if atras.is_valid():
			atras.call()
			return true
	return false

static func a_la_vista(n: Node) -> bool:
	if n is CanvasItem:
		return (n as CanvasItem).is_visible_in_tree()
	if n is CanvasLayer:
		return (n as CanvasLayer).visible and n.is_inside_tree()
	return n.is_inside_tree()
