class_name Optimizar
extends "res://visor/optimizar_p1.gd"
## [Capa 2/2 de `optimizar.gd`] informe, _rejilla, _sin_dinamica, _en_rejilla, obstaculos, _circulos … (+1)

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
		if (p.get_script() != null and not SubsistemasQuietos.permite(p, mi)) or p is Skeleton3D or not p.get_groups().is_empty():
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
		_circulos(sal, c, sx, sz)
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
				_circulos(sal, c, caja.size.x, caja.size.z)
	return sal

## Círculos de choque de una pieza de base `sx` × `sz` centrada en `c`. Una pieza
## alargada (un coche, un poste con travesaño, un panel fino) se cubre con círculos
## repartidos a lo largo cada 2·r, de punta a punta (26-10-2026, pedido de la S1:
## con solo dos en los extremos, el centro de 87 postes y ~104 paneles finos se
## atravesaba). Una pieza redonda o casi cuadrada, con un círculo.
static func _circulos(sal: PackedVector3Array, c: Vector3, sx: float, sz: float) -> void:
	var largo := maxf(sx, sz)
	var ancho := minf(sx, sz)
	if largo <= ancho * 1.8:
		sal.append(Vector3(c.x, c.z, clampf(largo * 0.5, 0.15, 3.0)))
		return
	var r_c := clampf(ancho * 0.5, 0.15, 2.5)
	var eje := Vector2(1, 0) if sx >= sz else Vector2(0, 1)
	var sep := maxf(0.0, largo * 0.5 - r_c)
	var n := maxi(2, ceili(sep * 2.0 / (2.0 * r_c)) + 1)
	for i in n:
		var t := lerpf(-sep, sep, float(i) / float(n - 1))
		sal.append(Vector3(c.x + eje.x * t, c.z + eje.y * t, r_c))

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
		var por_celda := celdas_de(mmi.global_transform, mm.buffer, paso_buffer(mm), CELDA_TROCEO)
		if por_celda.size() < 2 and corte <= 0.0:
			continue
		por_celda = fundir_pequenas(por_celda)
		for k: Vector2i in por_celda:
			var nuevo := MultiMesh.new()
			nuevo.transform_format = MultiMesh.TRANSFORM_3D
			nuevo.use_colors = mm.use_colors
			nuevo.use_custom_data = mm.use_custom_data
			nuevo.mesh = mm.mesh
			nuevo.instance_count = int((por_celda[k] as Array)[0])
			nuevo.buffer = (por_celda[k] as Array)[1]
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

## Trozos con menos de `MIN_TROZO` instancias se juntan por celdas de FACTOR_TROZO veces el lado (7-11, meta de RAM): la ciudad salía en 20.040 trozos de ~7 instancias y cada nodo
## (MultiMeshInstance3D + MultiMesh + su buffer) cuesta ~5 KB: +104 MB. Las instancias y su dibujo no cambian; solo el tamaño de la caja que decide el recorte por cámara.
const MIN_TROZO := 40
const FACTOR_TROZO := 4

static func fundir_pequenas(por: Dictionary) -> Dictionary:
	var salida := {}
	var juntos := {}   ## celda grande → [[cuantas, buffer]…] (un Array se modifica en sitio; un Packed dentro de un contenedor se copiaría)
	for k: Vector2i in por:
		var v: Array = por[k]
		if int(v[0]) >= MIN_TROZO:
			salida[k] = v
			continue
		var g := Vector2i(floori(float(k.x) / FACTOR_TROZO), floori(float(k.y) / FACTOR_TROZO))
		if not juntos.has(g):
			juntos[g] = []
		(juntos[g] as Array).append(v)
	for g: Vector2i in juntos:
		var datos := PackedFloat32Array()
		var cuantas := 0
		for v: Array in juntos[g]:
			datos.append_array(v[1])
			cuantas += int(v[0])
		salida[Vector2i(g.x + 1000000, g.y)] = [cuantas, datos]   ## (otro espacio de claves: no choca con las celdas finas)
	return salida

## Floats por instancia en el `buffer` de un MultiMesh 3D: 12 de la transformación (origen en las posiciones 3, 7 y 11), 4 de color y 4 de datos si los usa (comprobado con renderizador real).
static func paso_buffer(mm: MultiMesh) -> int:
	return 12 + (4 if mm.use_colors else 0) + (4 if mm.use_custom_data else 0)

## Parte las instancias del `buffer` (`paso` floats cada una) por celdas de `celda` m, según el origen de cada una en el mundo (`gt` = el transform global del nodo): devuelve
## celda → [cuántas, buffer]. (7-11) Antes se leía y escribía una instancia cada vez con `get_instance_transform`/`set_instance_*` (1.058 ms en la ciudad, la pasada más lenta
## de `despejar`); ahora se copian tramos seguidos de la misma celda (las instancias de un agrupado suelen venir en orden de zona). Mismo resultado y mismo orden en cada celda.
static func celdas_de(gt: Transform3D, buf: PackedFloat32Array, paso: int, celda: float) -> Dictionary:
	var n := buf.size() / paso
	var tramos := {}   ## celda → [inicio, fin, inicio, fin…] (un Array se modifica en sitio; un Packed guardado dentro de otro contenedor se copiaría)
	var i := 0
	while i < n:
		var b := i * paso
		var o := gt * Vector3(buf[b + 3], buf[b + 7], buf[b + 11])
		var k := Vector2i(floori(o.x / celda), floori(o.z / celda))
		var j := i + 1
		while j < n:
			var bj := j * paso
			var oj := gt * Vector3(buf[bj + 3], buf[bj + 7], buf[bj + 11])
			if floori(oj.x / celda) != k.x or floori(oj.z / celda) != k.y:
				break
			j += 1
		if not tramos.has(k):
			tramos[k] = []
		(tramos[k] as Array).append(i)
		(tramos[k] as Array).append(j)
		i = j
	var salida := {}
	for k: Vector2i in tramos:
		var t: Array = tramos[k]
		var datos := PackedFloat32Array()
		var cuantas := 0
		for q in range(0, t.size(), 2):
			datos.append_array(buf.slice(int(t[q]) * paso, int(t[q + 1]) * paso))
			cuantas += int(t[q + 1]) - int(t[q])
		salida[k] = [cuantas, datos]
	return salida

## Transformaciones `inv * ts[i]` en el formato del `buffer` de un MultiMesh 3D sin color (12 floats por instancia, filas de la matriz 3x4; origen en 3, 7 y 11).
## (7-11) Igual que `set_instance_transform` instancia a instancia, pero de una sola vez.
static func a_buffer(ts: Array, inv: Transform3D) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(ts.size() * 12)
	var o := 0
	for t: Transform3D in ts:
		var m := inv * t
		var bs := m.basis
		var org := m.origin
		b[o] = bs.x.x; b[o + 1] = bs.y.x; b[o + 2] = bs.z.x; b[o + 3] = org.x
		b[o + 4] = bs.x.y; b[o + 5] = bs.y.y; b[o + 6] = bs.z.y; b[o + 7] = org.y
		b[o + 8] = bs.x.z; b[o + 9] = bs.y.z; b[o + 10] = bs.z.z; b[o + 11] = org.z
		o += 12
	return b
