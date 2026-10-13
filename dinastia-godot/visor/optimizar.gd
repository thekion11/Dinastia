class_name Optimizar
extends RefCounted
## OPTIMIZACIÓN POR CÓDIGO (etapa 3, 8-10-2026).
##
## Lo que reveló `pruebas/medir_ciudad.gd` en la ciudad 3D (calidad MEDIO):
## 30 M de triángulos y 8.100 llamadas de dibujo en la vista aérea. El mayor
## culpable eran las PRIMITIVAS DE GODOT CON SU DETALLE DE FÁBRICA: un
## `CylinderMesh` nace con 64 lados y 4 anillos (768 triángulos) y la ciudad
## los usa a miles para postes, troncos, farolas, bolardos y semáforos (un solo
## MultiMesh de 3.000 postes sumaba 2,3 M). Un poste de 20 cm con 8 lados se ve
## igual a cualquier distancia de juego.
##
## `primitivas(raiz)` recorre una escena y BAJA (nunca sube) los lados de
## cilindros, conos y esferas según su tamaño. Las mallas son recursos
## compartidos: cada una se toca una sola vez.

## Lados según el radio (m): [radio máximo, lados del cilindro, segmentos de la esfera].
const ESCALA := [[0.15, 6, 8], [0.6, 8, 10], [2.0, 12, 14], [6.0, 18, 20]]

static func primitivas(raiz: Node) -> Dictionary:
	var vistas := {}
	var antes := 0
	var despues := 0
	for n in raiz.find_children("*", "GeometryInstance3D", true, false):
		var m: Mesh = null
		if n is MeshInstance3D:
			m = (n as MeshInstance3D).mesh
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			m = (n as MultiMeshInstance3D).multimesh.mesh
		if m == null or vistas.has(m):
			continue
		vistas[m] = true
		if m is CylinderMesh:
			var c := m as CylinderMesh
			antes += c.radial_segments * (c.rings + 1) * 2
			var lados := _lados(maxf(c.top_radius, c.bottom_radius), 1)
			if lados > 0 and c.radial_segments > lados:
				c.radial_segments = lados
			c.rings = mini(c.rings, 0 if c.height < 12.0 else 1)
			despues += c.radial_segments * (c.rings + 1) * 2
		elif m is SphereMesh:
			var e := m as SphereMesh
			antes += e.radial_segments * e.rings * 2
			var seg := _lados(e.radius, 2)
			if seg > 0 and e.radial_segments > seg:
				e.radial_segments = seg
				e.rings = mini(e.rings, maxi(4, seg / 2))
			despues += e.radial_segments * e.rings * 2
		elif m is CapsuleMesh:
			var k := m as CapsuleMesh
			var seg2 := _lados(k.radius, 2)
			if seg2 > 0 and k.radial_segments > seg2:
				k.radial_segments = seg2
				k.rings = mini(k.rings, 2)
	return {"mallas": vistas.size(), "tris_tipo_antes": antes, "tris_tipo_despues": despues}

static func _lados(radio: float, col: int) -> int:
	for f: Array in ESCALA:
		if radio <= float(f[0]):
			return int(f[col])
	return 0

## Las butacas cercanas del estadio (1.944 triángulos cada una) cambian a la
## malla liviana; se guarda la buena para devolverla al entrar a pie.
static func butacas_livianas(raiz: Node, si: bool) -> void:
	for n in raiz.find_children("ButacasCerca*", "MultiMeshInstance3D", true, false):
		var mm := (n as MultiMeshInstance3D).multimesh
		if mm == null:
			continue
		if si:
			if not n.has_meta("malla_buena"):
				n.set_meta("malla_buena", mm.mesh)
			mm.mesh = StadiumBuilder._malla_butaca_lejos()
		elif n.has_meta("malla_buena"):
			mm.mesh = n.get_meta("malla_buena")

## Distancia de corte por TAMAÑO (diagonal en metros): [máximo, distancia].
## La cámara del mapa mira desde ~440 m; a esa distancia una papelera o un
## banco ocupa menos de un píxel pero igual costaba una llamada de dibujo.
## Lo grande (edificios, estadio, suelo) no se toca nunca.
const CORTE := [[1.5, 180.0], [4.0, 320.0], [10.0, 600.0]]

static func distancias(raiz: Node) -> int:
	var n_puestas := 0
	## Lo que cuelga de un nodo con meta "sin_corte" (el estadio) no se toca.
	var fuera := {}
	for r in raiz.find_children("*", "Node3D", true, false):
		if r.has_meta("sin_corte"):
			for x in r.find_children("*", "GeometryInstance3D", true, false):
				fuera[x] = true
	for n in raiz.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if g.get_parent() is Skeleton3D and g.visibility_range_end <= 0.0:
			## Cuerpos con esqueleto (personal, mascota): 12 mil triángulos cada
			## uno. A más de 150 m no se distingue ni que son personas.
			g.visibility_range_end = 150.0
			g.visibility_range_end_margin = 15.0
			n_puestas += 1
			continue
		if fuera.has(g) or g is Label3D or g.visibility_range_end > 0.0:
			continue
		var diag := _diagonal(g)
		for f: Array in CORTE:
			if diag > 0.0 and diag <= float(f[0]):
				g.visibility_range_end = float(f[1])
				g.visibility_range_end_margin = float(f[1]) * 0.1
				n_puestas += 1
				break
	return n_puestas

static func _diagonal(g: GeometryInstance3D) -> float:
	var caja := g.get_aabb()
	var b := g.global_transform.basis if g.is_inside_tree() else g.transform.basis
	var esc := maxf(b.x.length(), maxf(b.y.length(), b.z.length()))
	return caja.size.length() * esc

## AGRUPAR PIEZAS REPETIDAS. La ciudad pone ~2.500 edificios del kit y miles de
## piezas iguales como nodos sueltos: cada uno es una llamada de dibujo. Aquí
## se juntan las que comparten malla y materiales en un MultiMesh por celda de
## `CELDA` m (así la cámara sigue recortando por zonas) y se borran las sueltas.
## Solo lo QUIETO: se salta todo lo que cuelga de un nodo con script (tráfico,
## metro, semáforos, peatones), de un grupo (puertas que se abren) o con hijos.
const CELDA := 160.0
const MIN_GRUPO := 2
const UMBRAL_PESADO := 1500       ## triángulos a partir de los cuales hay proxy lejano
const RANGO_EDIFICIO := 520.0     ## hasta dónde se dibuja el edificio entero

static func agrupar(raiz: Node3D) -> Dictionary:
	_motivos.clear()
	var grupos := {}
	var mallas_con_mat := {}
	var mats := {}
	var proxies: Array = []
	var colores := {}
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not _quieto(mi, raiz):
			continue
		if mi.material_override != null:
			mi.material_override = _mat_unico(mi.material_override, mats)
		var malla := _malla_efectiva(mi, mallas_con_mat)
		var t := mi.global_transform
		## LOD JERÁRQUICO: un edificio pesado se dibuja entero hasta RANGO_EDIFICIO
		## y, más allá, como una caja de su color medio (12 triángulos).
		if mi.mesh is ArrayMesh and _tris(mi.mesh) > UMBRAL_PESADO and mi.visibility_range_end <= 0.0 and not _sin_lod(mi):
			var caja_e := mi.get_aabb()
			proxies.append([t * Transform3D(Basis.from_scale(caja_e.size), caja_e.get_center()), _color_medio(mi, colores), Vector2i(floori(t.origin.x / CELDA), floori(t.origin.z / CELDA))])
			mi.visibility_range_end = RANGO_EDIFICIO
			mi.visibility_range_end_margin = 20.0
		var pleg := _plegar(mi, malla)
		if not pleg.is_empty():
			malla = pleg[0]
			t = t * Transform3D(Basis.from_scale(pleg[1]), Vector3.ZERO)
		var celda := Vector2i(floori(t.origin.x / CELDA), floori(t.origin.z / CELDA))
		var clave := [malla, mi.material_override, mi.cast_shadow, mi.visibility_range_end, mi.layers, celda]
		var k := str(clave.map(func(x): return x.get_instance_id() if x is Object else x))
		if not grupos.has(k):
			grupos[k] = {"malla": malla, "mi": mi, "lista": [], "t": []}
		(grupos[k]["lista"] as Array).append(mi)
		(grupos[k]["t"] as Array).append(t)
	if OS.get_environment("DETALLE") != "":
		var tam := {}
		for k2: String in grupos:
			var c: int = (grupos[k2]["lista"] as Array).size()
			tam[mini(c, 10)] = int(tam.get(mini(c, 10), 0)) + c
		print("AGRUPAR tamaños ", tam, " motivos ", _motivos)
		var sol := {}
		for k2: String in grupos:
			if (grupos[k2]["lista"] as Array).size() == 1:
				var mi0: MeshInstance3D = grupos[k2]["mi"]
				var c2 := mi0.mesh.get_class() + (" ovr" if mi0.material_override != null else "") + " " + mi0.mesh.resource_name.left(20)
				sol[c2] = int(sol.get(c2, 0)) + 1
		print("AGRUPAR solos ", sol)
	var piezas := 0
	var hechos := 0
	var inv := raiz.global_transform.affine_inverse()
	for k: String in grupos:
		var g: Dictionary = grupos[k]
		var lista: Array = g["lista"]
		if lista.size() < MIN_GRUPO:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = g["malla"]
		mm.instance_count = lista.size()
		for i in lista.size():
			mm.set_instance_transform(i, inv * (g["t"][i] as Transform3D))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Agrupado"
		mmi.multimesh = mm
		var modelo: MeshInstance3D = g["mi"]
		mmi.material_override = modelo.material_override
		mmi.cast_shadow = modelo.cast_shadow
		mmi.visibility_range_end = modelo.visibility_range_end
		mmi.visibility_range_end_margin = modelo.visibility_range_end_margin
		mmi.layers = modelo.layers
		raiz.add_child(mmi)
		for mi: MeshInstance3D in lista:
			mi.get_parent().remove_child(mi)
			mi.free()
		piezas += lista.size()
		hechos += 1
	_montar_proxies(raiz, proxies)
	return {"multimesh": hechos, "piezas": piezas, "proxies": proxies.size()}

static var _motivos := {}
static func _no(m: String) -> bool:
	_motivos[m] = int(_motivos.get(m, 0)) + 1
	return false

static func _quieto(mi: MeshInstance3D, raiz: Node) -> bool:
	if mi.mesh == null or mi.get_child_count() > 0 or not mi.visible or mi.skin != null:
		return _no("propio")
	if mi.transparency > 0.0 or not mi.get_groups().is_empty() or mi.get_script() != null:
		return _no("propio2")
	var p := mi.get_parent()
	while p != null and p != raiz:
		if p.get_script() != null:
			return _no("script:" + String(p.get_script().resource_path.get_file()))
		if not p.get_groups().is_empty():
			return _no("grupo")
		if p is Skeleton3D:
			return _no("esqueleto")
		if p is Node3D and not (p as Node3D).visible:
			return _no("oculto")
		p = p.get_parent()
	return p == raiz

## La malla con los materiales que de verdad usa ese nodo (los «override» por
## superficie no existen en un MultiMesh: se hornean en una copia, cacheada).
static func _malla_efectiva(mi: MeshInstance3D, cache: Dictionary) -> Mesh:
	var m := mi.mesh
	var ids := []
	var cambia := false
	for s in m.get_surface_count():
		var o := mi.get_surface_override_material(s)
		ids.append(o.get_instance_id() if o != null else 0)
		cambia = cambia or o != null
	if not cambia or not (m is ArrayMesh):
		return m
	var k := str(m.get_instance_id()) + ":" + str(ids)
	if not cache.has(k):
		var copia := m.duplicate() as ArrayMesh
		for s in m.get_surface_count():
			var o := mi.get_surface_override_material(s)
			if o != null:
				copia.surface_set_material(s, o)
		cache[k] = copia
	return cache[k]

## PLEGAR EL TAMAÑO EN LA ESCALA. Cada caja de la ciudad era un `BoxMesh.new()`
## con su tamaño: miles de mallas distintas que no se pueden agrupar. Una caja
## de 3x1x2 es la caja unidad escalada (3,1,2), con las mismas UV y, al ser
## caras alineadas a los ejes, las mismas normales. Igual con cilindros rectos,
## planos y esferas redondas. No se pliega si el material reparte la textura
## por la posición local (triplanar no mundial o shader propio).
static var _unidad := {}

static func _plegar(mi: MeshInstance3D, m: Mesh) -> Array:
	var mat := mi.material_override
	if mat == null and m.get_surface_count() > 0:
		mat = m.surface_get_material(0)
	if mat is ShaderMaterial:
		return []
	if mat is BaseMaterial3D and (mat as BaseMaterial3D).uv1_triplanar and not (mat as BaseMaterial3D).uv1_world_triplanar:
		return []
	if m is BoxMesh:
		var b := m as BoxMesh
		if b.subdivide_width + b.subdivide_height + b.subdivide_depth > 0 or b.size.x * b.size.y * b.size.z <= 0.0:
			return []
		return [_unidad_de("caja", b.material, func():
			var u := BoxMesh.new(); u.size = Vector3.ONE; return u), b.size]
	if m is CylinderMesh:
		var c := m as CylinderMesh
		if not is_equal_approx(c.top_radius, c.bottom_radius) or c.top_radius <= 0.0 or not c.cap_top or not c.cap_bottom:
			return []
		var clave := "cil%d_%d" % [c.radial_segments, c.rings]
		return [_unidad_de(clave, c.material, func():
			var u := CylinderMesh.new(); u.top_radius = 1.0; u.bottom_radius = 1.0; u.height = 1.0
			u.radial_segments = c.radial_segments; u.rings = c.rings; return u),
			Vector3(c.top_radius, c.height, c.top_radius)]
	if m is PlaneMesh:
		var p := m as PlaneMesh
		if p.subdivide_width + p.subdivide_depth > 0 or p.orientation != PlaneMesh.FACE_Y or p.center_offset != Vector3.ZERO:
			return []
		return [_unidad_de("plano", p.material, func():
			var u := PlaneMesh.new(); u.size = Vector2.ONE; return u), Vector3(p.size.x, 1.0, p.size.y)]
	if m is SphereMesh:
		var e := m as SphereMesh
		if not is_equal_approx(e.height, e.radius * 2.0) or e.is_hemisphere or e.radius <= 0.0:
			return []
		var clave2 := "esf%d_%d" % [e.radial_segments, e.rings]
		return [_unidad_de(clave2, e.material, func():
			var u := SphereMesh.new(); u.radius = 1.0; u.height = 2.0
			u.radial_segments = e.radial_segments; u.rings = e.rings; return u), Vector3.ONE * e.radius]
	return []

static func _unidad_de(clave: String, mat: Material, crear: Callable) -> Mesh:
	var k := clave + ":" + str(mat.get_instance_id() if mat != null else 0)
	if not _unidad.has(k) or not is_instance_valid(_unidad[k]):
		var u: PrimitiveMesh = crear.call()
		u.material = mat
		_unidad[k] = u
	return _unidad[k]

## Materiales iguales -mismo color, rugosidad, textura...- creados uno por
## pieza se cambian por UNO compartido. Nunca los que brillan (emisión: son los
## que se encienden de noche), los que llevan meta ni los encadenados.
static var _props_mat: PackedStringArray = []

static func _mat_unico(m: Material, vistos: Dictionary) -> Material:
	var id := m.get_instance_id()
	if vistos.has(id):
		return vistos[id]
	var res := m
	if m is StandardMaterial3D and m.next_pass == null and m.get_meta_list().is_empty() \
			and not (m as StandardMaterial3D).emission_enabled:
		if _props_mat.is_empty():
			for prop: Dictionary in m.get_property_list():
				if int(prop["usage"]) & PROPERTY_USAGE_STORAGE != 0 and not String(prop["name"]).begins_with("resource_"):
					_props_mat.append(prop["name"])
		var firma := []
		for nombre in _props_mat:
			var v: Variant = m.get(nombre)
			firma.append(v.get_instance_id() if v is Object else v)
		var k := str(firma)
		if not vistos.has(k):
			vistos[k] = m
		res = vistos[k]
	vistos[id] = res
	return res

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

static var _tris_cache := {}
static func _tris(m: Mesh) -> int:
	if _tris_cache.has(m):
		return _tris_cache[m]
	var t := 0
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		t += (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	_tris_cache[m] = t
	return t

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

const CELDA_REJ := 32.0

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

static func _en_rejilla(rej: Dictionary, x: float, z: float) -> bool:
	var k := Vector2i(floori(x / CELDA_REJ), floori(z / CELDA_REJ))
	if rej.has(k):
		for r: Rect2 in rej[k]:
			if r.has_point(Vector2(x, z)):
				return true
	return false

static func _sin_dinamica(mi: Node, raiz: Node) -> bool:
	if mi.get_script() != null or not mi.get_groups().is_empty():
		return false
	var p := mi.get_parent()
	while p != null and p != raiz:
		if p.get_script() != null or p is Skeleton3D or not p.get_groups().is_empty():
			return false
		p = p.get_parent()
	return true


## Lo que no debe tener proxy: nada que se vea de cerca y de lejos igual de bien.
static func _sin_lod(_mi: MeshInstance3D) -> bool:
	return false

## Color medio del material de un modelo (textura × color), cacheado.
static func _color_medio(mi: MeshInstance3D, cache: Dictionary) -> Color:
	var mat: Material = mi.material_override
	if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
		mat = mi.mesh.surface_get_material(0)
	var clave := mat.get_instance_id() if mat != null else 0
	if cache.has(clave):
		return cache[clave]
	var c := Color(0.74, 0.74, 0.77)
	if mat is BaseMaterial3D:
		var bm := mat as BaseMaterial3D
		c = bm.albedo_color
		if bm.albedo_texture != null:
			var img := bm.albedo_texture.get_image()
			if img != null:
				if img.is_compressed():
					img.decompress()
				img.resize(1, 1, Image.INTERPOLATE_LANCZOS)
				c = c * img.get_pixel(0, 0)
	## Un poco más claro y sin brillo: de lejos lo oscuro se traga los detalles.
	c = c.lerp(Color(0.92, 0.92, 0.94), 0.5)
	cache[clave] = c
	return c

## Las cajas lejanas, un MultiMesh por celda con el color de cada edificio.
static func _montar_proxies(raiz: Node3D, proxies: Array) -> void:
	if proxies.is_empty():
		return
	var por_celda := {}
	for p: Array in proxies:
		var k: Vector2i = p[2]
		if not por_celda.has(k):
			por_celda[k] = []
		(por_celda[k] as Array).append(p)
	var caja := BoxMesh.new()
	caja.size = Vector3.ONE
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	var inv := raiz.global_transform.affine_inverse()
	for k: Vector2i in por_celda:
		var lista: Array = por_celda[k]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = caja
		mm.instance_count = lista.size()
		for i in lista.size():
			mm.set_instance_transform(i, inv * (lista[i][0] as Transform3D))
			mm.set_instance_color(i, lista[i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "EdificiosLejos"
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_begin = RANGO_EDIFICIO - 20.0
		mmi.visibility_range_begin_margin = 20.0
		raiz.add_child(mmi)


## TROCEAR MULTIMESH GRANDES (bucle de optimización, 13-10-2026). Medido en la
## vista aérea: cilindros y esferas -troncos, copas, postes, semáforos- eran lo
## que más triángulos sumaba y no se podían recortar por distancia, porque cada
## MultiMesh abarca la ciudad ENTERA (una sola caja de 2,6 km) y la distancia de
## visibilidad se aplica a esa caja. Aquí se parte cada uno en celdas de 100 m
## con su propia caja, y a las piezas pequeñas se les pone distancia de corte.
## Todas las de un mismo tamaño comparten distancia, así que un tronco y su
## copa desaparecen a la vez. Sin gráfica (headless) el servidor no guarda las
## transformaciones y no se hace nada.
const CELDA_TROCEO := 100.0
const MIN_INSTANCIAS_TROCEO := 48

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

## Tamaño de la pieza (diagonal en m) -> distancia de corte. Lo pequeño y
## numeroso (postes, troncos, copas, hidrantes, setos) no se ve de lejos.
const TROCEO_CORTE := [[4.5, 380.0]]
