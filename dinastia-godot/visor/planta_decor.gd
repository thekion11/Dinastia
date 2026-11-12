class_name PlantaDecor
extends RefCounted
## LA PLANTA DE DECORACIÓN DEL CLUB (12-11-2026). Antes era una maceta-caja con una esfera verde encima: con la cámara en primera
## persona (orden 45) se ve de cerca y parecía un globo. Ahora: maceta troncocónica con borde, tierra y 22 hojas alargadas en
## varios verdes, inclinadas hacia fuera a distintas alturas. TODO en una sola malla con colores por vértice (una llamada de dibujo,
## una menos que antes) y cacheada: se construye una vez para todas las plantas del club.

const HOJAS := 22
const ALTO_MACETA := 0.42

static var _malla: ArrayMesh = null
static var _mat: StandardMaterial3D = null

static func nodo() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Planta"
	mi.mesh = malla()
	mi.material_override = material()
	return mi

## El cuerpo sólido de la maceta (la misma caja de 0,45 m que tenía la de antes).
static func choque() -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.45, 0.5, 0.45)
	forma.shape = bs
	cuerpo.add_child(forma)
	cuerpo.position = Vector3(0, 0.25, 0)
	return cuerpo

static func material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.vertex_color_use_as_albedo = true
		_mat.roughness = 0.85
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED   ## las hojas se ven por los dos lados
	return _mat

static func malla() -> ArrayMesh:
	if _malla != null:
		return _malla
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var barro := Color(0.42, 0.25, 0.17)
	_cono(st, 0.17, 0.23, 0.0, ALTO_MACETA, barro)                          ## maceta, más ancha arriba
	_cono(st, 0.245, 0.245, ALTO_MACETA - 0.05, ALTO_MACETA, barro.darkened(0.15))   ## borde
	_disco(st, 0.22, ALTO_MACETA - 0.03, Color(0.17, 0.12, 0.08))              ## tierra
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242   ## siempre la misma planta
	for i in HOJAS:
		var ang := TAU * float(i) / float(HOJAS) + rng.randf_range(-0.25, 0.25)
		var largo := rng.randf_range(0.38, 0.62)
		var incl := rng.randf_range(0.35, 1.05)   ## de casi vertical a muy abierta
		var verde := Color(0.16, 0.42, 0.18).lerp(Color(0.32, 0.58, 0.22), rng.randf())
		_hoja(st, Vector3(0, ALTO_MACETA - 0.02, 0), ang, incl, largo, rng.randf_range(0.07, 0.11), verde)
	st.generate_normals()
	_malla = st.commit()
	return _malla

static func _cono(st: SurfaceTool, r0: float, r1: float, y0: float, y1: float, col: Color, lados := 14) -> void:
	for k in lados:
		var a0 := TAU * float(k) / float(lados)
		var a1 := TAU * float(k + 1) / float(lados)
		var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
		var p01 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
		var p10 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
		var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
		for p: Vector3 in [p00, p10, p11, p00, p11, p01]:
			st.set_color(col)
			st.add_vertex(p)

static func _disco(st: SurfaceTool, r: float, y: float, col: Color, lados := 14) -> void:
	for k in lados:
		var a0 := TAU * float(k) / float(lados)
		var a1 := TAU * float(k + 1) / float(lados)
		for p: Vector3 in [Vector3(0, y, 0), Vector3(cos(a1) * r, y, sin(a1) * r), Vector3(cos(a0) * r, y, sin(a0) * r)]:
			st.set_color(col)
			st.add_vertex(p)

## Una hoja: dos tramos que se abren desde la base, se ensanchan en el medio y acaban en punta, con la punta un poco caída.
static func _hoja(st: SurfaceTool, base: Vector3, ang: float, incl: float, largo: float, ancho: float, col: Color) -> void:
	var fuera := Vector3(cos(ang), 0, sin(ang))
	var lado := Vector3(-sin(ang), 0, cos(ang))
	var dir := (Vector3.UP * cos(incl) + fuera * sin(incl)).normalized()
	var medio := base + dir * largo * 0.55
	var punta := base + dir * largo + Vector3(0, -largo * 0.18 * sin(incl), 0)
	var oscuro := col.darkened(0.25)
	var tri := [[base, oscuro], [medio + lado * ancho, col], [medio - lado * ancho, col],
		[medio + lado * ancho, col], [punta, col.lightened(0.1)], [medio - lado * ancho, col]]
	for v: Array in tri:
		st.set_color(v[1])
		st.add_vertex(v[0])
