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
	## `node_added` vuelve a saltar al cambiar un nodo de padre (los menús laterales
	## «mudan» las pestañas): cada botón se conecta UNA vez.
	if n is BaseButton and not n.has_meta("sin_fx") and not n.has_meta("_fx"):
		var b := n as BaseButton
		b.set_meta("_fx", true)
		b.mouse_entered.connect(_a.bind(b, Color(1.14, 1.14, 1.14), Vector2.ONE))
		b.mouse_exited.connect(_a.bind(b, Color.WHITE, Vector2.ONE))
		b.button_down.connect(_a.bind(b, Color(0.88, 0.88, 0.88), Vector2(0.97, 0.97)))
		b.button_up.connect(_arriba.bind(b))
		## SONIDO AL RECORRER Y AL ACEPTAR (14-10-2026, pedido: «que al ir
		## bajando o aceptando tenga sonido»): un tic suave al pasar por un
		## botón -con el ratón o con el mando/teclado- y el clic al pulsarlo.
		if not n.has_meta("sin_sonido"):
			b.focus_entered.connect(_sonar.bind("clic_suave"))
			b.mouse_entered.connect(_sonar.bind("clic_suave"))
			b.pressed.connect(_sonar.bind("clic"))

static var _ultimo_ms := {}

## Con tope: un mismo sonido no se repite en menos de 60 ms (pasar el ratón
## por una lista no hace una ráfaga).
static func _sonar(nombre: String) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - int(_ultimo_ms.get(nombre, -1000)) < 60:
		return
	_ultimo_ms[nombre] = ahora
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol == null:
		return
	var s := arbol.root.get_node_or_null("Sonido")
	if s != null and s.has_method("toca"):
		s.call("toca", nombre, 2)

static func _arriba(b: BaseButton) -> void:
	_a(b, Color(1.14, 1.14, 1.14) if b.is_hovered() else Color.WHITE, Vector2.ONE)

static func _a(b: BaseButton, color: Color, escala: Vector2) -> void:
	if not is_instance_valid(b) or b.disabled or not b.is_inside_tree():
		return
	b.pivot_offset = b.size * 0.5
	var tw := b.create_tween().set_parallel(true)
	tw.tween_property(b, "self_modulate", color, SEG)
	tw.tween_property(b, "scale", escala, SEG)
