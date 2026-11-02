class_name OptimizarGrada
extends RefCounted
## CULLING POR TROZOS DE LA GRADA (M-345, 28-10-2026). Cada tribuna lleva UN `MultiMesh` de miles de butacas (y otro de hinchas): su caja envolvente
## abarca toda la tribuna, así que con un solo rincón en pantalla se dibuja ENTERO. Aquí se parte en `tramos` trozos del mismo número de
## instancias a lo largo del eje largo de la tribuna: cada trozo tiene su propia caja y el culling de la cámara descarta los que no se ven.
## Mismo material, sombra y capa; el nombre se conserva con sufijo (`ButacasCerca_3`), que es lo que buscan `Optimizar.butacas_livianas` y la prueba.

const NOMBRES := ["ButacasCerca", "ButacasLejos", "Hinchada", "HinchadaCerca"]
const MIN_INSTANCIAS := 600
static var activo := true   ## las comprobaciones de «antes» (imágenes sin trocear) lo apagan

## Parte los MultiMesh grandes de la grada colgados de `raiz`. Devuelve cuántos partió.
## 2-11-2026 (120 FPS): en calidad MEDIO (y en el perfil ligero automático) las butacas cercanas llevan desde el principio la malla
## liviana (84 triángulos en vez de 1 944): medido en el partido, −36 % de triángulos (1,34 M → 0,85 M). ALTO y ULTRA no cambian.
static func trocear(raiz: Node, tramos := 8) -> int:
	var hechos := _trocear(raiz, tramos)
	if Calidad.elegida == Calidad.MEDIO:
		Optimizar.butacas_livianas(raiz, true)
	return hechos

static func _trocear(raiz: Node, tramos: int) -> int:
	if not activo or DisplayServer.get_name() == "headless":
		return 0   ## sin pantalla los MultiMesh no guardan sus datos
	var hechos := 0
	for nombre: String in NOMBRES:
		for n in raiz.find_children(nombre, "MultiMeshInstance3D", true, false):
			var mmi := n as MultiMeshInstance3D
			var mm := mmi.multimesh
			if mm == null or mm.mesh == null or mm.instance_count < MIN_INSTANCIAS or mm.transform_format != MultiMesh.TRANSFORM_3D:
				continue
			_partir(mmi, tramos)
			hechos += 1
	return hechos

static func _partir(mmi: MultiMeshInstance3D, tramos: int) -> void:
	var mm := mmi.multimesh
	var cuantas := mm.instance_count
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var pos := PackedVector2Array()
	pos.resize(cuantas)
	for i in cuantas:
		var o := mm.get_instance_transform(i).origin
		pos[i] = Vector2(o.x, o.z)
		lo = lo.min(pos[i])
		hi = hi.max(pos[i])
	var eje := 0 if (hi.x - lo.x) >= (hi.y - lo.y) else 1
	var orden: Array = range(cuantas)
	orden.sort_custom(func(a: int, b: int) -> bool: return pos[a][eje] < pos[b][eje])
	var por_tramo := ceili(float(cuantas) / float(tramos))
	var padre := mmi.get_parent()
	for t in tramos:
		var desde := t * por_tramo
		var hasta := mini(cuantas, desde + por_tramo)
		if desde >= hasta:
			break
		var nuevo := MultiMesh.new()
		nuevo.transform_format = MultiMesh.TRANSFORM_3D
		nuevo.use_colors = mm.use_colors
		nuevo.use_custom_data = mm.use_custom_data
		nuevo.mesh = mm.mesh
		nuevo.instance_count = hasta - desde
		for j in hasta - desde:
			var k: int = orden[desde + j]
			nuevo.set_instance_transform(j, mm.get_instance_transform(k))
			if mm.use_colors:
				nuevo.set_instance_color(j, mm.get_instance_color(k))
			if mm.use_custom_data:
				nuevo.set_instance_custom_data(j, mm.get_instance_custom_data(k))
		var m2 := MultiMeshInstance3D.new()
		m2.name = "%s_%d" % [mmi.name, t]
		m2.multimesh = nuevo
		m2.transform = mmi.transform
		m2.material_override = mmi.material_override
		m2.material_overlay = mmi.material_overlay
		m2.cast_shadow = mmi.cast_shadow
		m2.layers = mmi.layers
		m2.gi_mode = mmi.gi_mode
		m2.visibility_range_begin = mmi.visibility_range_begin
		m2.visibility_range_end = mmi.visibility_range_end
		m2.visibility_range_end_margin = mmi.visibility_range_end_margin
		for g in mmi.get_groups():
			m2.add_to_group(g)
		for m in mmi.get_meta_list():
			m2.set_meta(m, mmi.get_meta(m))
		padre.add_child(m2)
	padre.remove_child(mmi)
	mmi.free()

## EL PRÓLOGO NO NECESITA VER LEJOS (2-11-2026): tope de distancia de dibujo para todo lo pequeño o mediano que no tenga uno más
## corto (lo grande -terreno, horizonte, edificios de más de `GRANDE` m- se queda). Fuera del estadio (`sin_corte`) y sin rótulos.
## Devuelve cuántos objetos recibieron el tope.
static func limitar_vista(raiz: Node, hasta: float, grande := 90.0) -> int:
	var fuera := {}
	for r in raiz.find_children("*", "Node3D", true, false):
		if r.has_meta("sin_corte"):
			for x in r.find_children("*", "GeometryInstance3D", true, false):
				fuera[x] = true
	var n := 0
	for g_n in raiz.find_children("*", "GeometryInstance3D", true, false):
		var g := g_n as GeometryInstance3D
		if fuera.has(g) or g is Label3D or (g.visibility_range_end > 0.0 and g.visibility_range_end <= hasta):
			continue
		if g.get_aabb().size.length() > grande:
			continue
		g.visibility_range_end = hasta
		g.visibility_range_end_margin = hasta * 0.1
		n += 1
	return n

