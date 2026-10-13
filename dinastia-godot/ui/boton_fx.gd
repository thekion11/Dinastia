class_name BotonFx
extends RefCounted
## FEEDBACK TÁCTIL DE LOS BOTONES (informe de diseño, 13-10-2026: «los botones
## carecen de estados de transición; el cambio es abrupto; interpolar 0,1 s»).
## Se engancha UNA vez al árbol: cada botón que se crea se aclara al pasar el
## ratón, se oscurece y encoge un pelo al pulsarlo, con una transición de 0,1 s.
## Usa `self_modulate` (no `modulate`, que ya usan varias pantallas para
## atenuar) y salta los botones con el meta «sin_fx».
const SEG := 0.1

static func activar(arbol: SceneTree) -> void:
	if arbol == null or arbol.root.has_meta("boton_fx"):
		return
	arbol.root.set_meta("boton_fx", true)
	arbol.node_added.connect(_nuevo)

static func _nuevo(n: Node) -> void:
	if n is BaseButton and not n.has_meta("sin_fx"):
		var b := n as BaseButton
		b.mouse_entered.connect(_a.bind(b, Color(1.14, 1.14, 1.14), Vector2.ONE))
		b.mouse_exited.connect(_a.bind(b, Color.WHITE, Vector2.ONE))
		b.button_down.connect(_a.bind(b, Color(0.88, 0.88, 0.88), Vector2(0.97, 0.97)))
		b.button_up.connect(_arriba.bind(b))

static func _arriba(b: BaseButton) -> void:
	_a(b, Color(1.14, 1.14, 1.14) if b.is_hovered() else Color.WHITE, Vector2.ONE)

static func _a(b: BaseButton, color: Color, escala: Vector2) -> void:
	if not is_instance_valid(b) or b.disabled or not b.is_inside_tree():
		return
	b.pivot_offset = b.size * 0.5
	var tw := b.create_tween().set_parallel(true)
	tw.tween_property(b, "self_modulate", color, SEG)
	tw.tween_property(b, "scale", escala, SEG)
