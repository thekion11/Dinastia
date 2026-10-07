class_name Autopista
extends RefCounted
## LA AUTOPISTA (7-10-2026, pedido: «metro y carretera… la ciudad debe ser
## real»). Un anillo ELEVADO que rodea la ciudad a 1.420 m del centro, sobre
## pilares (así no corta ninguna calle ni el río), con tres carriles por
## sentido, mediana con barrera, quitamiedos y farolas altas. Cuatro enlaces
## bajan en rampa a las avenidas del borde de la ciudad (norte, sur, este y
## oeste) y dos carreteras salen del anillo hacia el horizonte siguiendo las
## lomas del terreno. El tráfico va más rápido que en la ciudad.

const R := 1420.0          ## medio lado del anillo
const ALTO := 8.0
const ANCHO := 30.0
const RAMPA := 80.0
const SALIDAS := [Vector3(1, 0, 0), Vector3(0, 0, -1)]   ## carreteras al horizonte

static func montar(b: CityBuilder) -> Dictionary:
	var asf: StandardMaterial3D = Texturas.asfalto(Color(0.13, 0.13, 0.14)).duplicate()
	var horm := b._mat_simple(Color(0.7, 0.69, 0.66), 0.8)
	var barrera := b._mat_simple(Color(0.85, 0.85, 0.83), 0.5)
	var linea := b._mat_simple(Color(0.95, 0.93, 0.85), 0.6)
	var esquinas := [Vector3(-R, 0, -R), Vector3(R, 0, -R), Vector3(R, 0, R), Vector3(-R, 0, R)]
	var pilares: Array[Transform3D] = []
	var marcas: Array[Transform3D] = []
	var postes: Array[Transform3D] = []
	for k in 4:
		var a: Vector3 = esquinas[k]
		var c: Vector3 = esquinas[(k + 1) % 4]
		var m := (a + c) * 0.5
		var largo := a.distance_to(c) + ANCHO
		var vertical := absf(a.x - c.x) < 0.1
		var tam := Vector3(ANCHO, 1.0, largo) if vertical else Vector3(largo, 1.0, ANCHO)
		b._caja_en(m + Vector3(0, ALTO, 0), tam, asf)
		b._caja_en(m + Vector3(0, ALTO - 1.2, 0), Vector3(tam.x - 2.0, 1.4, tam.z - 2.0) if vertical else Vector3(tam.x - 2.0, 1.4, tam.z - 2.0), horm)
		## Mediana y quitamiedos.
		b._caja_en(m + Vector3(0, ALTO + 1.0, 0), Vector3(1.0, 1.0, largo) if vertical else Vector3(largo, 1.0, 1.0), barrera)
		for lado: float in [-1.0, 1.0]:
			var off := Vector3(lado * (ANCHO * 0.5 - 0.3), 0, 0) if vertical else Vector3(0, 0, lado * (ANCHO * 0.5 - 0.3))
			b._caja_en(m + off + Vector3(0, ALTO + 1.0, 0), Vector3(0.4, 1.2, largo) if vertical else Vector3(largo, 1.2, 0.4), barrera)
		var n := int(largo / 40.0)
		for q in n:
			var p := a.lerp(c, (float(q) + 0.5) / float(n))
			pilares.append(Transform3D(Basis.from_scale(Vector3(3.0, ALTO, 3.0)), p + Vector3(0, ALTO * 0.5 - 0.5, 0)))
			postes.append(Transform3D(Basis.from_scale(Vector3(0.3, 12.0, 0.3)), p + Vector3(0, ALTO + 6.5, 0)))
			## Líneas de carril (dos por sentido).
			for d: float in [-9.0, -4.5, 4.5, 9.0]:
				var pm := p + (Vector3(d, 0, 0) if vertical else Vector3(0, 0, d))
				marcas.append(Transform3D(Basis.from_scale(Vector3(0.25, 0.05, 6.0) if vertical else Vector3(6.0, 0.05, 0.25)), pm + Vector3(0, ALTO + 0.55, 0)))
	_mm(b, BoxMesh.new(), horm, pilares)
	_mm(b, BoxMesh.new(), linea, marcas)
	_mm(b, CylinderMesh.new(), b._mat_simple(Color(0.3, 0.31, 0.32), 0.5), postes)
	## Los cuatro enlaces: rampa del anillo al borde de la ciudad (avenida k=±12).
	var enlaces := [Vector3(0, 0, -R), Vector3(0, 0, R), Vector3(R, 0, 0), Vector3(-R, 0, 0)]
	for e: Vector3 in enlaces:
		var hacia := -e.normalized()
		## Centrada en la avenida que continúa (antes iba 20 m desplazada).
		var base := e + hacia * (ANCHO * 0.5 + RAMPA * 0.5)
		var r := b._caja_en(base + Vector3(0, ALTO * 0.5, 0), Vector3(16.0, 0.8, sqrt(RAMPA * RAMPA + ALTO * ALTO)) if absf(hacia.z) > 0.5 else Vector3(sqrt(RAMPA * RAMPA + ALTO * ALTO), 0.8, 16.0), asf)
		var ang := atan2(ALTO, RAMPA)
		if absf(hacia.z) > 0.5:
			r.rotation.x = ang * signf(hacia.z)
		else:
			r.rotation.z = -ang * signf(hacia.x)
		b._rotulo(e + Vector3(0, ALTO + 14.0, 0), "🛣️ Autopista · salida", Color(0.6, 0.9, 1.0), 18)
	## Las carreteras al horizonte: siguen el terreno, a tramos cortos.
	for s: Vector3 in SALIDAS:
		var desde := s * (R + ANCHO * 0.5)
		var pts: Array = []
		var d0 := 0.0
		while d0 < 1600.0:
			var p := desde + s * d0
			pts.append(Vector3(p.x, b.altura_en(p.x, p.z) + 0.3 if d0 > 60.0 else ALTO * (1.0 - d0 / 60.0) + 0.3, p.z))
			d0 += 40.0
		for i in pts.size() - 1:
			var p0: Vector3 = pts[i]
			var p1: Vector3 = pts[i + 1]
			var seg := b._caja_en((p0 + p1) * 0.5, Vector3(ANCHO * 0.8, 0.5, p0.distance_to(p1) + 1.0) if absf(s.z) > 0.5 else Vector3(p0.distance_to(p1) + 1.0, 0.5, ANCHO * 0.8), asf)
			var pend := atan2(p1.y - p0.y, Vector2(p1.x - p0.x, p1.z - p0.z).length())
			if absf(s.z) > 0.5:
				seg.rotation.x = pend * signf(s.z)
			else:
				seg.rotation.z = -pend * signf(s.x) * -1.0
	return {"enlaces": enlaces.size(), "carreteras": SALIDAS.size()}

## Los recorridos del tráfico de la autopista: el anillo en los dos sentidos,
## por el carril central de cada calzada.
static func rutas() -> Array:
	var sal: Array = []
	for sentido: float in [1.0, -1.0]:
		var off := 7.5 * sentido
		var pts := PackedVector3Array([
			Vector3(-R + off, ALTO + 0.6, -R + off), Vector3(R - off, ALTO + 0.6, -R + off),
			Vector3(R - off, ALTO + 0.6, R - off), Vector3(-R + off, ALTO + 0.6, R - off)])
		if sentido < 0.0:
			pts.reverse()
		sal.append(pts)
	return sal

static func _mm(b: CityBuilder, malla: Mesh, mat: Material, ts: Array[Transform3D]) -> void:
	if ts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	b.add_child(mi)
