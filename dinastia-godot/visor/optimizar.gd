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
		obstaculo_malla(n, raiz, rej, sal, min_alto, max_base)
	## Lo repetido en MultiMesh (postes, troncos, hidrantes...): una por instancia.
	for n in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		obstaculo_multimalla(n, raiz, rej, sal, min_alto, max_base)
	return sal

## Una malla suelta (6-11: el cuerpo del bucle de `obstaculos`, aparte para que `CargaPartes` lo recorra cediendo fotogramas; mismo resultado).
static func obstaculo_malla(n: Node, raiz: Node3D, rej: Dictionary, sal: PackedVector3Array, min_alto: float, max_base: float) -> void:
	var mi := n as MeshInstance3D
	if mi.mesh == null or not mi.is_visible_in_tree() or mi.transparency > 0.0:
		return
	if not _sin_dinamica(mi, raiz):
		return
	var caja := mi.global_transform * mi.get_aabb()
	var sx := caja.size.x
	var sz := caja.size.z
	var base_y := caja.position.y - raiz.global_position.y
	if caja.size.y < min_alto or base_y > max_base or maxf(sx, sz) > 8.0 or minf(sx, sz) < 0.08:
		return
	var c := caja.get_center()
	if _en_rejilla(rej, c.x, c.z):
		return
	_circulos(sal, c, sx, sz)

## Un MultiMesh: un círculo por instancia que cumple los umbrales.
static func obstaculo_multimalla(n: Node, raiz: Node3D, rej: Dictionary, sal: PackedVector3Array, min_alto: float, max_base: float) -> void:
	var mmi := n as MultiMeshInstance3D
	var mm := mmi.multimesh
	if mm == null or mm.mesh == null or not mmi.is_visible_in_tree() or not _sin_dinamica(mmi, raiz):
		return
	if mm.instance_count > 30000 or String(mmi.name).begins_with("Butacas") or String(mmi.name).begins_with("Hinchada"):
		return
	var base := mm.mesh.get_aabb()
	var nodo_t := mmi.global_transform
	## (7-11) Se lee el `buffer` entero de una vez (una llamada) en vez de `get_instance_transform` por instancia.
	## Sin pantalla el MultiMesh no guarda datos: ahí se sigue por instancia.
	var buf := mm.buffer
	var paso := paso_buffer(mm)
	var en_buffer := mm.transform_format == MultiMesh.TRANSFORM_3D and buf.size() >= mm.instance_count * paso
	for i in mm.instance_count:
		var caja := nodo_t * (BufferMM.transform_de(buf, i * paso) if en_buffer else mm.get_instance_transform(i)) * base
		if caja.size.y < min_alto or caja.position.y - raiz.global_position.y > max_base or maxf(caja.size.x, caja.size.z) > 8.0 or minf(caja.size.x, caja.size.z) < 0.08:
			continue
		var c := caja.get_center()
		if not _en_rejilla(rej, c.x, c.z):
			_circulos(sal, c, caja.size.x, caja.size.z)

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
	var fuera := trocear_fuera(raiz)
	var hechos := 0
	for n in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		hechos += trocear_uno(n, fuera, raiz)
	return hechos

## Los MultiMesh que cuelgan de un nodo `sin_corte` (el estadio en el mapa) no se trocean.
static func trocear_fuera(raiz: Node3D) -> Dictionary:
	var fuera := {}
	for r in raiz.find_children("*", "Node3D", true, false):
		if r.has_meta("sin_corte"):
			for x in r.find_children("*", "MultiMeshInstance3D", true, false):
				fuera[x] = true
	return fuera

## Trocea UN MultiMesh (6-11: el cuerpo del bucle de `trocear`, aparte para que `CargaPartes` lo recorra cediendo fotogramas). Devuelve 1 si lo partió.
static func trocear_uno(n: Node, fuera: Dictionary, raiz: Node3D) -> int:
	var mmi := n as MultiMeshInstance3D
	var mm := mmi.multimesh
	if fuera.has(mmi) or mm == null or mm.mesh == null or mm.instance_count < MIN_INSTANCIAS_TROCEO:
		return 0
	if mmi.visibility_range_end > 0.0 or String(mmi.name).begins_with("Agrupado") or String(mmi.name).begins_with("Edificios"):
		return 0
	if not _sin_dinamica(mmi, raiz) or mm.transform_format != MultiMesh.TRANSFORM_3D:
		return 0
	var base := mm.mesh.get_aabb()
	var diag := base.size.length()
	var corte := 0.0
	for f: Array in TROCEO_CORTE:
		if diag <= float(f[0]):
			corte = float(f[1])
			break
	var por_celda := celdas_de(mmi.global_transform, mm.buffer, paso_buffer(mm), CELDA_TROCEO)
	if por_celda.size() < 2 and corte <= 0.0:
		return 0
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
	return 1

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

## `con_proxies` = false: solo junta piezas iguales, sin la caja lejana (el entorno del estadio).
## (6-11) Partida en trozos (`agrupar_inicio`, `agrupar_uno`, `agrupar_fusion`, `agrupar_fin`) para que `CargaPartes` la recorra cediendo fotogramas; `agrupar` los encadena
## sin ceder, igual que antes. `ctx`: lo que se arrastra de un trozo al siguiente.
static func agrupar(raiz: Node3D, con_proxies: bool = true) -> Dictionary:
	var ctx := agrupar_inicio(raiz)
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		agrupar_uno(n, raiz, con_proxies, ctx)
	agrupar_detalle(ctx)
	for k: String in ctx["grupos"]:
		agrupar_fusion(k, raiz, ctx)
	return agrupar_fin(raiz, ctx)

static func agrupar_inicio(raiz: Node3D) -> Dictionary:
	_motivos.clear()
	SubsistemasQuietos.registrar(raiz)   ## (7-11) metro: sus mallas quietas también se agrupan
	## (4-11, A4-M3D-X01) Estas dos cachés tenían como CLAVE una malla / un material y no se vaciaban nunca: cada
	## ciudad o estadio construido dejaba vivas sus mallas y unidades para siempre (+123 objetos y +5 MB por entrada).
	_tris_cache.clear()
	_unidad.clear()
	return {"grupos": {}, "mallas": {}, "mats": {}, "proxies": [], "colores": {}, "piezas": 0, "hechos": 0, "vaciados": {}, "inv": raiz.global_transform.affine_inverse()}

## Clasifica UNA malla suelta en su grupo.
static func agrupar_uno(n: Node, raiz: Node3D, con_proxies: bool, ctx: Dictionary) -> void:
	var mi := n as MeshInstance3D
	if not _quieto(mi, raiz):
		return
	if mi.material_override != null:
		mi.material_override = _mat_unico(mi.material_override, ctx["mats"])
	var malla := _malla_efectiva(mi, ctx["mallas"])
	var t := mi.global_transform
	## LOD JERÁRQUICO: un edificio pesado se dibuja entero hasta RANGO_EDIFICIO
	## y, más allá, como una caja de su color medio (12 triángulos).
	if con_proxies and mi.mesh is ArrayMesh and _tris(mi.mesh) > UMBRAL_PESADO and mi.visibility_range_end <= 0.0 and not _sin_lod(mi):
		var caja_e := mi.get_aabb()
		(ctx["proxies"] as Array).append([t * Transform3D(Basis.from_scale(caja_e.size), caja_e.get_center()), _color_medio(mi, ctx["colores"]), Vector2i(floori(t.origin.x / CELDA), floori(t.origin.z / CELDA))])
		mi.visibility_range_end = RANGO_EDIFICIO
		mi.visibility_range_end_margin = 20.0
	var pleg := _plegar(mi, malla)
	if not pleg.is_empty():
		malla = pleg[0]
		t = t * Transform3D(Basis.from_scale(pleg[1]), Vector3.ZERO)
	var celda := Vector2i(floori(t.origin.x / CELDA), floori(t.origin.z / CELDA))
	var k := "%d|%d|%d|%s|%d|%d,%d" % [malla.get_instance_id(), mi.material_override.get_instance_id() if mi.material_override != null else 0, mi.cast_shadow, mi.visibility_range_end, mi.layers, celda.x, celda.y]   ## (7-11) misma partición que la lista de ids, sin lambda ni str() por pieza
	if not ctx["grupos"].has(k):
		ctx["grupos"][k] = {"malla": malla, "mi": mi, "lista": [], "t": []}
	(ctx["grupos"][k]["lista"] as Array).append(mi)
	(ctx["grupos"][k]["t"] as Array).append(t)

static func agrupar_detalle(ctx: Dictionary) -> void:
	if OS.get_environment("DETALLE") != "":
		var tam := {}
		for k2: String in ctx["grupos"]:
			var c: int = (ctx["grupos"][k2]["lista"] as Array).size()
			tam[mini(c, 10)] = int(tam.get(mini(c, 10), 0)) + c
		Registro.depurar("AGRUPAR", "tamaños %s motivos %s" % [str(tam), str(_motivos)])
		var sol := {}
		for k2: String in ctx["grupos"]:
			if (ctx["grupos"][k2]["lista"] as Array).size() == 1:
				var mi0: MeshInstance3D = ctx["grupos"][k2]["mi"]
				var c2 := mi0.mesh.get_class() + (" ovr" if mi0.material_override != null else "") + " " + mi0.mesh.resource_name.left(20)
				sol[c2] = int(sol.get(c2, 0)) + 1
		Registro.depurar("AGRUPAR", "solos %s" % str(sol))

## Pasa a MultiMesh el grupo `k` (si tiene al menos MIN_GRUPO piezas) y quita las mallas sueltas que sustituye.
static func agrupar_fusion(k: String, raiz: Node3D, ctx: Dictionary) -> void:
	var g: Dictionary = ctx["grupos"][k]
	var lista: Array = g["lista"]
	if lista.size() < MIN_GRUPO:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = g["malla"]
	mm.instance_count = lista.size()
	mm.buffer = a_buffer(g["t"], ctx["inv"])
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
		var pa := mi.get_parent()
		pa.remove_child(mi)
		mi.free()
		ctx["vaciados"][pa] = true
	ctx["piezas"] += lista.size()
	ctx["hechos"] += 1

static func agrupar_fin(raiz: Node3D, ctx: Dictionary) -> Dictionary:
	PodaVacios.de(raiz, (ctx["vaciados"] as Dictionary).keys())   ## A4-REND: quita los Node3D que agrupar dejó vacíos
	_montar_proxies(raiz, ctx["proxies"])
	return {"multimesh": ctx["hechos"], "piezas": ctx["piezas"], "proxies": (ctx["proxies"] as Array).size()}
