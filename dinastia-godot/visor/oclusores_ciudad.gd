class_name OclusoresCiudad
## OCLUSIÓN EN LA CIUDAD (21-10-2026, informe técnico punto 8, aceptado por el
## dueño). Godot ya descarta lo que queda fuera de la cámara, pero NO lo que
## queda detrás de un edificio: a pie de calle se dibujaban manzanas enteras
## tapadas. Aquí cada edificio grande (las huellas y fachadas que ya sirven para
## chocar) pone CUATRO PAREDES finas de oclusión, no una caja: desde el aire una
## caja taparía los patios de manzana; las paredes, no.
##   · Solo edificios de al menos 8 x 8 m (los quioscos y andenes no tapan nada).
##   · Altura fija de 6 m: más baja que cualquier edificio, así nunca esconde algo
##     que asome por encima de un tejado.
##   · Fuera el estadio (su cuenco está abierto por dentro).
##   · Con el jugador DENTRO de un edificio se apagan (`activar`): por la puerta
##     se tiene que seguir viendo la calle.
## En Compatibility (motor ligero, móvil) Godot no hace oclusión: no cuesta nada.

const ALTO := 6.0
const GROSOR := 0.4
const LADO_MIN := 8.0

static func montar(b: CityBuilder) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Oclusores"
	b.add_child(raiz)
	var estadio := Rect2(CityBuilder.ESTADIO_EN.x - 80.0, CityBuilder.ESTADIO_EN.z - 100.0, 160.0, 200.0)
	var hechos := {}
	var rects: Array[Rect2] = []
	rects.append_array(b._frentes)
	rects.append_array(b.huellas)
	for r: Rect2 in rects:
		if r.size.x < LADO_MIN or r.size.y < LADO_MIN or estadio.intersects(r):
			continue
		## La misma huella llega a veces por las dos listas.
		var clave := Vector4i(roundi(r.position.x), roundi(r.position.y), roundi(r.size.x), roundi(r.size.y))
		if hechos.has(clave):
			continue
		hechos[clave] = true
		var a := r.grow(-0.6)
		var y := 0.0
		_pared(raiz, Vector3(a.get_center().x, y, a.position.y), Vector3(a.size.x, ALTO, GROSOR))
		_pared(raiz, Vector3(a.get_center().x, y, a.end.y), Vector3(a.size.x, ALTO, GROSOR))
		_pared(raiz, Vector3(a.position.x, y, a.get_center().y), Vector3(GROSOR, ALTO, a.size.y))
		_pared(raiz, Vector3(a.end.x, y, a.get_center().y), Vector3(GROSOR, ALTO, a.size.y))
	return raiz

static func _pared(raiz: Node3D, base: Vector3, tam: Vector3) -> void:
	var o := OccluderInstance3D.new()
	var caja := BoxOccluder3D.new()
	caja.size = tam
	o.occluder = caja
	o.position = base + Vector3(0, tam.y * 0.5, 0)
	raiz.add_child(o)

## Cuántas paredes hay (para la prueba del banco).
static func cuantas(b: CityBuilder) -> int:
	var n := b.get_node_or_null("Oclusores")
	return 0 if n == null else n.get_child_count()

static func activar(b: CityBuilder, si: bool) -> void:
	var n := b.get_node_or_null("Oclusores") as Node3D
	if n != null and n.visible != si:
		n.visible = si
