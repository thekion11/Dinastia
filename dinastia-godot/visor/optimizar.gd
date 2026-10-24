class_name Optimizar
extends "res://visor/optimizar_p1.gd"
## [Capa 2/2 de `optimizar.gd`] informe, _rejilla, _sin_dinamica, _en_rejilla, obstaculos, trocear

## INFORME para perfilar una escena: los que más triángulos y piezas suman
## (malla × instancias), entre lo visible. Lo usan las pruebas `medir_*` con
## DETALLE=1; no se llama en el juego.
static func informe(raiz: Node, cuantos := 20) -> Array:
	var suma := {}
	for n in raiz.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var m: Mesh = null
		var veces := 1
		if g is MeshInstance3D:
			m = (g as MeshInstance3D).mesh
		elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
			var mm := (g as MultiMeshInstance3D).multimesh
			m = mm.mesh
			veces = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
		if m == null:
			continue
		var clave := "%s %s <%s>" % [g.get_class().left(5), m.get_class(), (m.resource_name if m.resource_name != "" else String(g.get_parent().name)).left(28)]
		if not suma.has(clave):
			suma[clave] = {"clave": clave + " nodo=" + String(g.name) + " x" + str(veces) + " t/u=" + str(_tris(m)), "tris": 0, "piezas": 0, "corte": g.visibility_range_end}
		suma[clave]["tris"] += _tris(m) * veces
		suma[clave]["piezas"] += 1
	var lista := suma.values()
	lista.sort_custom(func(a, b): return a["tris"] > b["tris"])
	return lista.slice(0, cuantos)

static func _rejilla(rects: Array[Rect2]) -> Dictionary:
	var rej := {}
	for r: Rect2 in rects:
		for cx in range(floori(r.position.x / CELDA_REJ), floori(r.end.x / CELDA_REJ) + 1):
			for cz in range(floori(r.position.y / CELDA_REJ), floori(r.end.y / CELDA_REJ) + 1):
				var k := Vector2i(cx, cz)
				if not rej.has(k):
					rej[k] = []
				(rej[k] as Array).append(r)
	return rej

static func _sin_dinamica(mi: Node, raiz: Node) -> bool:
	if mi.get_script() != null or not mi.get_groups().is_empty():
		return false
	var p := mi.get_parent()
	while p != null and p != raiz:
		if p.get_script() != null or p is Skeleton3D or not p.get_groups().is_empty():
			return false
		p = p.get_parent()
	return true

static func _en_rejilla(rej: Dictionary, x: float, z: float) -> bool:
	var k := Vector2i(floori(x / CELDA_REJ), floori(z / CELDA_REJ))
	if rej.has(k):
		for r: Rect2 in rej[k]:
			if r.has_point(Vector2(x, z)):
				return true
	return false

## OBSTÁCULOS PARA CAMINAR (etapa 5, 12-10-2026). El paseo solo chocaba con los
## rectángulos de manzanas e instalaciones: farolas, troncos, hidrantes,
## kioscos y coches aparcados se atravesaban. Se sacan de la propia escena
## -así lo que se añada mañana también es sólido-: cada pieza quieta que
## apoya en el suelo, mide más de 0,9 m de alto y cabe en 8 m de lado, y no
## cae dentro de un rectángulo ya sólido, pasa a ser un círculo [x, z, radio].
## Se llama ANTES de `agrupar` (después las piezas ya no son nodos sueltos).
static func obstaculos(raiz: Node3D, rects: Array[Rect2], min_alto := 0.9, max_base := 0.9) -> PackedVector3Array:
	var sal := PackedVector3Array()
	var rej := _rejilla(rects)
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or mi.transparency > 0.0:
			continue
		if not _sin_dinamica(mi, raiz):
			continue
		var caja := mi.global_transform * mi.get_aabb()
		var sx := caja.size.x
		var sz := caja.size.z
		var base_y := caja.position.y - raiz.global_position.y
		if caja.size.y < min_alto or base_y > max_base or maxf(sx, sz) > 8.0 or minf(sx, sz) < 0.08:
			continue
		var c := caja.get_center()
		if _en_rejilla(rej, c.x, c.z):
			continue
		## Una pieza alargada (un coche) se cubre con dos círculos a lo largo.
		var largo := maxf(sx, sz)
		var ancho := minf(sx, sz)
		var r_c := clampf(ancho * 0.5, 0.15, 2.5)
		if largo > ancho * 1.8:
			var eje := Vector2(1, 0) if sx >= sz else Vector2(0, 1)
			var sep := (largo - ancho) * 0.5
			sal.append(Vector3(c.x + eje.x * sep, c.z + eje.y * sep, r_c))
			sal.append(Vector3(c.x - eje.x * sep, c.z - eje.y * sep, r_c))
		else:
			sal.append(Vector3(c.x, c.z, clampf(maxf(sx, sz) * 0.5, 0.15, 3.0)))
	## Lo repetido en MultiMesh (postes, troncos, hidrantes...): una por instancia.
	for n in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		var mm := mmi.multimesh
		if mm == null or mm.mesh == null or not mmi.is_visible_in_tree() or not _sin_dinamica(mmi, raiz):
			continue
		if mm.instance_count > 30000 or String(mmi.name).begins_with("Butacas") or String(mmi.name).begins_with("Hinchada"):
			continue
		var base := mm.mesh.get_aabb()
		var nodo_t := mmi.global_transform
		for i in mm.instance_count:
			var caja := nodo_t * mm.get_instance_transform(i) * base
			if caja.size.y < min_alto or caja.position.y - raiz.global_position.y > max_base or maxf(caja.size.x, caja.size.z) > 8.0 or minf(caja.size.x, caja.size.z) < 0.08:
				continue
			var c := caja.get_center()
			if not _en_rejilla(rej, c.x, c.z):
				sal.append(Vector3(c.x, c.z, clampf(maxf(caja.size.x, caja.size.z) * 0.5, 0.15, 3.0)))
	return sal

static func trocear(raiz: Node3D) -> int:
	if DisplayServer.get_name() == "headless":
		return 0
	var fuera := {}
	for r in raiz.find_children("*", "Node3D", true, false):
		if r.has_meta("sin_corte"):
			for x in r.find_children("*", "MultiMeshInstance3D", true, false):
				fuera[x] = true
	var hechos := 0
	for n in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		var mm := mmi.multimesh
		if fuera.has(mmi) or mm == null or mm.mesh == null or mm.instance_count < MIN_INSTANCIAS_TROCEO:
			continue
		if mmi.visibility_range_end > 0.0 or String(mmi.name).begins_with("Agrupado") or String(mmi.name).begins_with("Edificios"):
			continue
		if not _sin_dinamica(mmi, raiz) or mm.transform_format != MultiMesh.TRANSFORM_3D:
			continue
		var base := mm.mesh.get_aabb()
		var diag := base.size.length()
		var corte := 0.0
		for f: Array in TROCEO_CORTE:
			if diag <= float(f[0]):
				corte = float(f[1])
				break
		var por_celda := {}
		for i in mm.instance_count:
			var o := mmi.global_transform * mm.get_instance_transform(i)
			var k := Vector2i(floori(o.origin.x / CELDA_TROCEO), floori(o.origin.z / CELDA_TROCEO))
			if not por_celda.has(k):
				por_celda[k] = []
			(por_celda[k] as Array).append(i)
		if por_celda.size() < 2 and corte <= 0.0:
			continue
		for k: Vector2i in por_celda:
			var idx: Array = por_celda[k]
			var nuevo := MultiMesh.new()
			nuevo.transform_format = MultiMesh.TRANSFORM_3D
			nuevo.use_colors = mm.use_colors
			nuevo.use_custom_data = mm.use_custom_data
			nuevo.mesh = mm.mesh
			nuevo.instance_count = idx.size()
			for j in idx.size():
				nuevo.set_instance_transform(j, mm.get_instance_transform(idx[j]))
				if mm.use_colors:
					nuevo.set_instance_color(j, mm.get_instance_color(idx[j]))
				if mm.use_custom_data:
					nuevo.set_instance_custom_data(j, mm.get_instance_custom_data(idx[j]))
			var m2 := MultiMeshInstance3D.new()
			m2.name = "Troceo"
			m2.multimesh = nuevo
			m2.transform = mmi.transform
			m2.material_override = mmi.material_override
			m2.material_overlay = mmi.material_overlay
			m2.cast_shadow = mmi.cast_shadow
			m2.layers = mmi.layers
			m2.gi_mode = mmi.gi_mode
			if corte > 0.0:
				m2.visibility_range_end = corte
				m2.visibility_range_end_margin = corte * 0.1
			mmi.get_parent().add_child(m2)
		mmi.get_parent().remove_child(mmi)
		mmi.free()
		hechos += 1
	return hechos
