extends RefCounted
## (Parte 1 de 2 de `pelo_capas.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `pelo_capas.gd`, conserva la clase.)

## EL PELO DE LOS JUGADORES REALES, POR CAPAS (30-9-2026, pedido: «mejorar el
## pelo, tanto cabelludo como de barba, y pestañas, cejas»). Todo sale de su
## foto (`herramientas/caras_reales_malla.py`: segmentación de pelo y piel de
## MediaPipe): el color del pelo, cuánto abulta, si es rizado, dónde nace, si
## los lados van rapados; la barba y las cejas, punto por punto, con el color
## exacto de la foto. Ver `pelo_capas.gdshader` para la técnica.
##
## Cada zona es UNA malla (las N capas juntas): una llamada de dibujo por zona
## y jugador.

const SHADER := "res://visor/pelo_capas.gdshader"
const SHADER_PESTANAS := "res://visor/pestanas.gdshader"
## Capas por zona (menos en calidad baja: `Calidad`).
const CAPAS_CUERO := 14
const CAPAS_BARBA := 10
const CAPAS_CEJAS := 5
## Detalle según la distancia a la cámara (17-10-2026): ver `poner`. Los
## primeros planos, la carta del goleador, el retrato y la ceremonia están por
## debajo de estas distancias y se ven con todo.
const CAPAS_LEJOS := 4
const DIST_CUERO := 22.0
const DIST_PESTANAS := 20.0
## Párpado de arriba (MediaPipe), de fuera hacia dentro, en cada ojo.
const PARPADO_DER := [33, 246, 161, 160, 159, 158, 157, 173, 133]
const PARPADO_IZQ := [263, 466, 388, 387, 386, 385, 384, 398, 362]
## Altura del cráneo sobre el punto 10 (arriba de la frente), en cm de la malla
## canónica: lo que mide un rapado. Lo que sobra es pelo.
const CRANEO_CM := 6.0
const BARBA_CEJAS_3D := false  # (30-9: por capas se veían manchas negras; la textura limpia las trae mejor)
## Desde aquí (0-1, `caras_reales_malla.py`: hasta dónde baja el pelo) es melena.
const LARGO_MELENA := 0.12

static var _mat_cache := {}

## Contorno de los labios (MediaPipe).
const LABIOS := [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185,
	78, 95, 88, 178, 87, 14, 317, 402, 318, 324, 308, 415, 310, 311, 312, 13, 82, 81, 80, 191]

## CACHÉS (MEGAPLAN fase 2, carga del estadio): la cabeza del cuerpo y el
## cuero cabelludo de cada jugador se recalculaban en GDScript cada vez que
## se abría el partido (~2 s por apertura). El resultado solo depende de la
## malla del cuerpo y de lo medido en la foto: se guarda.
static var _cache_cuerpo := {}
static var _cache_cuero := {}
static var _cache_pestanas := {}

static func _normales(pos: PackedVector3Array, tri: PackedInt32Array) -> PackedVector3Array:
	var n := PackedVector3Array()
	n.resize(pos.size())
	for t in range(0, tri.size() - 2, 3):
		var a := pos[tri[t]]
		var fn := (pos[tri[t + 1]] - a).cross(pos[tri[t + 2]] - a)
		for j in 3:
			n[tri[t + j]] += fn
	## Que miren hacia fuera (la nariz hacia delante).
	var signo := 1.0 if n[1].z >= 0.0 else -1.0
	for i in n.size():
		n[i] = (n[i] * signo).normalized()
	return n

static func _densidades(b64: String, n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	if b64 == "":
		return out
	var bytes := Marshalls.base64_to_raw(b64)
	for i in mini(bytes.size(), n):
		out[i] = bytes[i] / 255.0
	return out

## Los vértices a `anillos` pasos (por triángulos) de los de `base`.
static func _anillo(base: Array, tri: PackedInt32Array, anillos: int) -> Dictionary:
	var dentro := {}
	for i: int in base:
		dentro[i] = true
	for _k in anillos:
		var nuevos := {}
		for t in range(0, tri.size() - 2, 3):
			if dentro.has(tri[t]) or dentro.has(tri[t + 1]) or dentro.has(tri[t + 2]):
				for j in 3:
					nuevos[tri[t + j]] = true
		for i: int in nuevos:
			dentro[i] = true
	return dentro

static func _max(a: PackedFloat32Array) -> float:
	var m := 0.0
	for v in a:
		m = maxf(m, v)
	return m

## N capas de los triángulos donde `dens` > 0. UV2 = coordenadas en cm.
static func _capas_sobre(pos: PackedVector3Array, nor: PackedVector3Array, uv: PackedVector2Array,
		tri: PackedInt32Array, dens: PackedFloat32Array, alto: PackedFloat32Array, capas: int,
		con_base: bool) -> ArrayMesh:
	var usados: Array[int] = []
	for t in range(0, tri.size() - 2, 3):
		var a := tri[t]
		var b := tri[t + 1]
		var c := tri[t + 2]
		if maxf(dens[a], maxf(dens[b], dens[c])) > 0.03:
			usados.append(t)
	if usados.is_empty() or capas < 1:
		return null
	var mapa := {}
	var orden: Array[int] = []
	for t in usados:
		for j in 3:
			var i := tri[t + j]
			if not mapa.has(i):
				mapa[i] = orden.size()
				orden.append(i)
	var v := PackedVector3Array()
	var nn := PackedVector3Array()
	var u1 := PackedVector2Array()
	var u2 := PackedVector2Array()
	var col := PackedColorArray()
	var cus := PackedFloat32Array()
	var idx := PackedInt32Array()
	var desde := 0 if con_base else 1
	var total := capas + (1 if con_base else 0)
	for capa in range(desde, capas + 1):
		var base := v.size()
		var f := float(capa) / float(capas)
		for i in orden:
			v.append(pos[i])
			nn.append(nor[i])
			u1.append(uv[i] if i < uv.size() else Vector2.ZERO)
			u2.append(Vector2(pos[i].x, pos[i].y) * 100.0)
			col.append(Color(dens[i], alto[i], 0.0, 1.0))
			cus.append_array([f, 0.0, 0.0, 0.0])
		for t in usados:
			for j in 3:
				idx.append(base + int(mapa[tri[t + j]]))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nn
	arr[Mesh.ARRAY_TEX_UV] = u1
	arr[Mesh.ARRAY_TEX_UV2] = u2
	arr[Mesh.ARRAY_COLOR] = col
	arr[Mesh.ARRAY_CUSTOM0] = cus
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {},
		Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	return m if m.get_surface_count() > 0 or total == 0 else null

## Los triángulos con al menos `minimo` vértices de densidad > 0.
static func _solo_con(tri: PackedInt32Array, dens: PackedFloat32Array, minimo: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for t in range(0, tri.size() - 2, 3):
		var n := 0
		for j in 3:
			if tri[t + j] < dens.size() and dens[tri[t + j]] > 0.02:
				n += 1
		if n >= minimo:
			out.append_array([tri[t], tri[t + 1], tri[t + 2]])
	return out

static func _material(p: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SHADER)
	for k: String in p:
		m.set_shader_parameter(k, p[k])
	return m

static func _wb(datos: Dictionary) -> Vector3:
	var wb: Variant = datos.get("wb")
	if wb is Array and (wb as Array).size() == 3:
		return Vector3(float(wb[0]), float(wb[1]), float(wb[2]))
	return Vector3.ONE

static func _lineal(c: Color) -> Vector3:
	var l := c.srgb_to_linear()
	return Vector3(l.r, l.g, l.b)

static func _colgar(anc: Node3D, t: Transform3D, malla: Mesh, mat: Material, nombre: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = malla
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = t
	anc.add_child(mi)
	if nombre == "Pestanas":
		## Tiras de 1-2 mm: a más de `DIST_PESTANAS` m no llegan a un píxel y
		## solo costaban una llamada de dibujo por jugador.
		mi.visibility_range_end = DIST_PESTANAS
		mi.visibility_range_end_margin = 2.0
	return mi

## Las pestañas: una tira por párpado, del borde hacia fuera y arriba.
static func _pestanas(pos: PackedVector3Array, nor: PackedVector3Array) -> ArrayMesh:
	if pos.size() < CaraMalla.N:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for parpado: Array in [PARPADO_DER, PARPADO_IZQ]:
		var n := parpado.size()
		for j in n - 1:
			var ia: int = parpado[j]
			var ib: int = parpado[j + 1]
			var pa := pos[ia] + nor[ia] * 0.0012
			var pb := pos[ib] + nor[ib] * 0.0012
			## Más largas en el centro y hacia fuera del ojo.
			var ta := float(j) / float(n - 1)
			var tb := float(j + 1) / float(n - 1)
			var la := 0.0065 * (0.45 + 0.55 * sin(PI * clampf(ta * 1.1, 0.0, 1.0)))
			var lb := 0.0065 * (0.45 + 0.55 * sin(PI * clampf(tb * 1.1, 0.0, 1.0)))
			var da := (nor[ia] * 0.7 + Vector3(0, 0.75, 0.25)).normalized() * la
			var db := (nor[ib] * 0.7 + Vector3(0, 0.75, 0.25)).normalized() * lb
			for q: Array in [[pa, Vector2(ta, 0)], [pb, Vector2(tb, 0)], [pb + db, Vector2(tb, 1)],
					[pa, Vector2(ta, 0)], [pb + db, Vector2(tb, 1)], [pa + da, Vector2(ta, 1)]]:
				st.set_uv(q[1])
				st.add_vertex(q[0])
	st.generate_normals()
	return st.commit()

## La cabeza del cuerpo (pose de reposo): vértices, normales e índices.
static func _malla_cuerpo(modelo: Node) -> Dictionary:
	if modelo == null:
		return {}
	for mv in VestidorQ._mallas(modelo):
		var mi: MeshInstance3D = mv
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s)
			if mat != null and mat.resource_name.begins_with("MI_Superhero"):
				var clave := "%s|%d|%d" % [mi.mesh.resource_name, mi.mesh.surface_get_array_len(s), mi.mesh.surface_get_array_index_len(s)]
				if _cache_cuerpo.has(clave):
					return _cache_cuerpo[clave]
				var a := mi.mesh.surface_get_arrays(s)
				var r := {"v": a[Mesh.ARRAY_VERTEX], "n": a[Mesh.ARRAY_NORMAL], "i": a[Mesh.ARRAY_INDEX], "id": clave}
				_cache_cuerpo[clave] = r
				return r
	return {}

## El tipo de corte, de lo medido en la foto.
static func corte_de(h: Dictionary) -> String:
	var alto := float(h.get("alto", 7.0))
	var lados := float(h.get("lados", 0.5))
	if float(h.get("rizo", 0.0)) > 0.5 and alto > 9.5 and lados > 0.45:
		return "afro"
	## Melena que abulta a los lados (rizos largos: Cucurella): el pelo largo del
	## pack es liso y lacio; esto va por capas, con volumen y rizo.
	if float(h.get("largo", 0.0)) >= LARGO_MELENA and lados > 0.75:
		return "melena_rizada"
	if alto < 6.6:
		return "rapado"
	if alto > 8.3 and lados < 0.45:
		return "tupe"
	if lados < 0.35:
		return "degradado"
	return "normal"

## La altura de la línea del pelo en x (interpolada; por fuera, la del borde).
static func _linea_en(puntos: Array, x: float) -> float:
	if puntos.is_empty():
		return 1.76
	if x <= (puntos[0] as Vector2).x:
		return (puntos[0] as Vector2).y
	for i in range(1, puntos.size()):
		var a: Vector2 = puntos[i - 1]
		var b: Vector2 = puntos[i]
		if x <= b.x:
			return lerpf(a.y, b.y, (x - a.x) / maxf(b.x - a.x, 0.0001))
	return (puntos[puntos.size() - 1] as Vector2).y

## El cuero cabelludo: los triángulos de la cabeza del cuerpo con la densidad
## del nacimiento del pelo de ESTE jugador (la línea de la frente sale del
## anillo de arriba de su cara 3D y de dónde la foto muestra pelo).
static func _cuero(cuerpo: Dictionary, cara: PackedVector3Array, datos: Dictionary, h: Dictionary,
		capas: int) -> ArrayMesh:
	var v: PackedVector3Array = cuerpo["v"]
	var nor: PackedVector3Array = cuerpo["n"]
	var ind: PackedInt32Array = cuerpo["i"]
	## La línea de la frente: los vértices del anillo que suben (y > ojos), en
	## orden de x, con su altura; donde la foto no ve pelo encima, sube 1,5 cm.
	var linea: Array = h.get("linea", [])
	var puntos: Array = []
	var n0 := CaraMalla.N
	for kk in linea.size():
		var i := n0 + kk
		if i >= cara.size():
			break
		var p := cara[i]
		if p.y < CaraMalla.OJO_Y + 0.02:
			continue
		puntos.append(Vector2(p.x, p.y + (0.0 if int(linea[kk]) == 1 else 0.015)))
	puntos.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	## Suavizada (media de 5): con los saltos de 1,5 cm punto a punto la línea
	## salía con muescas rectangulares.
	var suave: Array = []
	for i in puntos.size():
		var acc := 0.0
		var n := 0
		for j in range(maxi(0, i - 2), mini(puntos.size(), i + 3)):
			acc += (puntos[j] as Vector2).y
			n += 1
		suave.append(Vector2((puntos[i] as Vector2).x, acc / n))
	puntos = suave
	var lados := float(h.get("lados", 0.5))
	var corte := corte_de(h)
	if corte == "afro" or corte == "melena_rizada":
		lados = 1.0
	var dens := PackedFloat32Array()
	var alto := PackedFloat32Array()
	dens.resize(v.size())
	alto.resize(v.size())
	for i in v.size():
		var p := v[i]
		if p.y < 1.52 or absf(p.x) > 0.14:
			continue
		var yl := _linea_en(puntos, p.x)
		var frente := smoothstep(-0.02, 0.04, p.z)
		var lateral := smoothstep(0.05, 0.08, absf(p.x))
		var y_atras := lerpf(1.575, 1.67, lateral)
		var y_lim := lerpf(y_atras, yl, frente)
		## Nacimiento difuso: el pelo se aclara en ~1,6 cm, no corta en seco.
		dens[i] = smoothstep(y_lim - 0.006, y_lim + 0.016, p.y)
		## Lados rapados (degradado): más corto y más ralo a los costados.
		var corto := lerpf(1.0, lerpf(0.25, 1.0, lados), lateral * (1.0 - smoothstep(1.72, 1.77, p.y)))
		## LA FORMA DEL CORTE (pasada 2): no un casco parejo.
		var arriba := smoothstep(1.72, 1.80, p.y)
		match corte:
			"tupe":
				## Alto arriba y hacia la frente; costados casi al ras.
				corto = lerpf(0.12, 1.0, (1.0 - lateral) * arriba) * (1.0 + 0.6 * frente * arriba)
			"degradado":
				## Arriba normal; abajo de los costados, degradado al ras.
				corto = lerpf(lerpf(0.1, 0.5, smoothstep(1.64, 1.74, p.y)), 1.0, (1.0 - lateral) * arriba + arriba * 0.3)
			"normal":
				## Domo: más en la coronilla y la frente que sobre las orejas.
				corto *= lerpf(0.7, 1.0, arriba)
			"rapado":
				corto = lerpf(0.6, 1.0, arriba)
		## Y corto en la nuca y sobre las orejas: si no, colgaba hasta el
		## cuello (parecía una melena "mullet").
		if corte != "melena_rizada":
			corto *= lerpf(0.15, 1.0, smoothstep(1.6, 1.74, p.y))
		alto[i] = corto
		## Calvo: solo la herradura de los lados y la nuca (hoy `poner` no la
		## cuelga: cabeza afeitada).
		if bool(h.get("calvo", false)):
			dens[i] *= 1.0 - smoothstep(1.695, 1.725, p.y)
		dens[i] *= lerpf(1.0, lerpf(0.55, 1.0, lados), lateral)
		## LA OREJA no lleva pelo (salía con pelo encima: manchas oscuras o
		## doradas en la oreja). Es lo que sobresale del cráneo a esa altura.
		var oreja := smoothstep(0.068, 0.073, absf(p.x)) * smoothstep(1.63, 1.645, p.y) \
				* (1.0 - smoothstep(1.735, 1.75, p.y))
		dens[i] *= 1.0 - oreja
	var uv := PackedVector2Array()
	uv.resize(v.size())
	var m := _capas_sobre(v, nor, uv, ind, dens, alto, capas, true)
	if m == null:
		return null
	## UV2 del cuero: por el ángulo, no por x (si no, las hebras se estiran en
	## los costados).
	var arr := m.surface_get_arrays(0)
	var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var u2 := PackedVector2Array()
	u2.resize(vv.size())
	for i in vv.size():
		var p := vv[i] - Vector3(0.0, 1.66, 0.0)
		u2[i] = Vector2(atan2(p.x, p.z) * 0.1, p.y) * 100.0
	arr[Mesh.ARRAY_TEX_UV2] = u2
	var m2 := ArrayMesh.new()
	m2.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {},
		Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	return m2
