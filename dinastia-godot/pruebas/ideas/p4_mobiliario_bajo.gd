extends BaseIdea
## p4 · MOBILIARIO BAJO QUE SE ATRAVIESA (plan §4, colisiones de la ciudad, 27-10-2026): lo estático de
## 0,4 a 0,9 m de alto -papeleras, contenedores bajos, maceteros, jardineras- quedaba por debajo del
## umbral de `Optimizar.obstaculos` y el DT pasaba a través. Cuenta las piezas de esa franja que no
## caen dentro de ningún círculo de choque de la ciudad.

var _vista: VistaCiudad

func _ready() -> void:
	await get_tree().process_frame
	await _probar_async()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _probar_async() -> void:
	_titulo("p4: mobiliario bajo de la ciudad con su choque")
	var m := _mundo(4242)
	var club := m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(club, m.obras, m.ciudad, m.perfil_estadio_de(club))
	_vista.explorar("pie", Vector3(0, 0, -440))
	await get_tree().process_frame
	await get_tree().process_frame
	var cb: CityBuilder = _vista._explorador.cb
	var circ: PackedVector3Array = cb.circulos
	var bajos := _bajos(cb)
	var rects: Array[Rect2] = ExploradorCiudad.construir_obstaculos(cb)
	var sin := 0
	for o in bajos:
		var cubierto := false
		for r in rects:
			if r.has_point(Vector2(o.x, o.y)):
				cubierto = true
				break
		for c in circ:
			if Vector2(c.x - o.x, c.y - o.y).length() < c.z + 0.05:
				cubierto = true
				break
		if not cubierto:
			sin += 1
			var nom: String = _nombre_de[bajos.find(o)]
			_nombres[nom] = int(_nombres.get(nom, 0)) + 1
	var top := _nombres.keys()
	top.sort_custom(func(x, y) -> bool: return int(_nombres[x]) > int(_nombres[y]))
	print("  más frecuentes: %s" % str(top.slice(0, 12).map(func(k) -> String: return "%s×%d" % [k, _nombres[k]])))
	print("  piezas bajas (0,4-0,9 m): %d; sin choque: %d" % [bajos.size(), sin])
	_comprobar(sin * 10 <= bajos.size(), "al menos el 90 %% del mobiliario bajo choca (%d de %d sin choque)" % [sin, bajos.size()])

## Centros (x, z, nombre) de lo estático de 0,4 a 0,9 m con base en el suelo y planta de 8 cm a 3 m.
func _bajos(raiz: Node3D) -> Array:
	var sal: Array = []
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		_mirar(sal, mi.global_transform * mi.get_aabb(), raiz, _nombre_malla(mi.mesh, mi))
	for n in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		var mm := (n as MultiMeshInstance3D).multimesh
		if mm == null or mm.mesh == null or mm.instance_count > 30000 or not (n as Node3D).is_visible_in_tree():
			continue
		var t := (n as Node3D).global_transform
		for i in mm.instance_count:
			_mirar(sal, t * mm.get_instance_transform(i) * mm.mesh.get_aabb(), raiz, _nombre_malla(mm.mesh, n))
	return sal

func _mirar(sal: Array, caja: AABB, raiz: Node3D, nombre: String) -> void:
	var lado := maxf(caja.size.x, caja.size.z)
	if caja.size.y < 0.4 or caja.size.y >= 0.9 or caja.position.y - raiz.global_position.y > 0.5 or lado > 3.0 or minf(caja.size.x, caja.size.z) < 0.08:
		return
	var c := caja.get_center()
	sal.append(Vector3(c.x, c.z, 0.0))
	_nombre_de.append(nombre)

var _nombres := {}
var _nombre_de: Array = []

func _nombre_malla(m: Mesh, n: Node) -> String:
	if m.resource_name != "":
		return m.resource_name
	if m.resource_path != "":
		return m.resource_path.get_file()
	return "%s/%s" % [n.get_parent().name, m.get_class()]
