class_name TactilPartido
extends RefCounted
## LAS PANTALLAS DEL PARTIDO EN EL TELÉFONO (17-11-2026, Auditoría: «táctil a 2400×1080: botones de ≥ 9 mm, nada debajo de la muesca»). En un móvil
## (o cuando una prueba lo simula: `PantallaMovil.dpi_forzado`) se sabe cuántos píxeles del lienzo hay por milímetro de pantalla; con eso:
##  · `agrandar`: todo lo que se toca dentro de una pantalla mide al menos `MIN_MM` de alto y de ancho;
##  · `zona_segura`: el contenido se aparta `MARGEN_MM` de los bordes cortos (la cámara del teléfono queda a un lado u otro según se gire);
##  · `es_movil`: para que cada pantalla elija su diseño compacto (el lienzo del teléfono es ~1067×480: más ancho y mucho más bajo que el PC).
## En un PC (sin puntos por pulgada) no cambia nada. Lo usa `pruebas/auditoria_tactil_partido`.

const MIN_MM := 9.0
const MARGEN_MM := 6.0   ## la muesca (~5 mm) y un poco de aire

static func mm(n: Node) -> float:
	return PantallaMovil.px_por_mm(n) if n != null and n.is_inside_tree() else 0.0

static func es_movil(n: Node) -> bool:
	return mm(n) > 0.0

## Lo que se toca dentro de `raiz`, a 9 mm como mínimo (ahora y lo que entre después: las pestañas se rellenan al abrirlas).
static func agrandar(raiz: Node) -> void:
	var k := mm(raiz)
	if k <= 0.0:
		return
	for b in raiz.find_children("*", "BaseButton", true, false):
		_minimo(b as Control, k)
	if raiz.has_meta("tactil_vigilado"):
		return
	raiz.set_meta("tactil_vigilado", true)
	var arbol := raiz.get_tree()
	var vigia := func(n: Node) -> void:
		if n is BaseButton and is_instance_valid(raiz) and raiz.is_ancestor_of(n):
			_minimo(n as Control, k)
	arbol.node_added.connect(vigia)
	raiz.tree_exiting.connect(func() -> void:
		if arbol.node_added.is_connected(vigia):
			arbol.node_added.disconnect(vigia))

static func _minimo(c: Control, k: float) -> void:
	var lado := MIN_MM * k
	c.custom_minimum_size = Vector2(maxf(c.custom_minimum_size.x, lado), maxf(c.custom_minimum_size.y, lado))

## Un contenedor a pantalla completa menos la franja de la muesca a los dos lados (en el PC, la propia `raiz`). El fondo se queda en `raiz` (llega al borde).
static func zona_segura(raiz: Control) -> Control:
	var k := mm(raiz)
	if k <= 0.0:
		return raiz
	var z := Control.new()
	z.name = "ZonaSegura"
	z.set_anchors_preset(Control.PRESET_FULL_RECT)
	z.offset_left = MARGEN_MM * k
	z.offset_right = -MARGEN_MM * k
	z.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(z)
	return z
