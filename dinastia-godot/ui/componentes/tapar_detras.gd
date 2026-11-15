class_name TaparDetras
extends RefCounted
## LO QUE QUEDA DEBAJO DE UNA PANTALLA OPACA NO SE DIBUJA (15-11-2026, repaso de menús pedido por el dueño).
## Medido con `pruebas/zz_medir_menu_gpu.tscn`: con un menú lateral abierto (`PantallaMenu`, opaco y a pantalla completa) seguían
## visibles los ~430 elementos del menú central de debajo, y Godot no descarta en 2D lo que queda tapado: se dibujaban igual.
## `tapar` oculta los hermanos ANTERIORES de la pantalla (los que quedan debajo) con su mismo `z_index` o menor y sin `top_level`;
## `destapar` los devuelve tal cual. Lo que se abre DESPUÉS (avisos, diálogos) no se toca. La imagen no cambia: solo se oculta lo tapado.
const META := "tapados_detras"
static var activo := OS.get_environment("SIN_TAPAR") == ""   ## SIN_TAPAR=1: como antes (para medir y comparar)

static func tapar(n: CanvasItem) -> void:
	var p := n.get_parent()
	if p == null or n.has_meta(META) or not activo:
		return
	var lista: Array = []
	for c: Node in p.get_children():
		if c == n:
			break
		var ci := c as CanvasItem
		if ci == null or not ci.visible or ci.top_level or ci.z_index > n.z_index:
			continue
		ci.visible = false
		lista.append(ci)
	n.set_meta(META, lista)

static func destapar(n: CanvasItem) -> void:
	if not n.has_meta(META):
		return
	for ci: Variant in n.get_meta(META):
		if is_instance_valid(ci):
			(ci as CanvasItem).visible = true
	n.remove_meta(META)
