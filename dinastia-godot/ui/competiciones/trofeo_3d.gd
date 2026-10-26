class_name Trofeo3D
extends RefCounted
## LOS TROFEOS EN 3D, hechos por código (26-10, pedido del dueño): inspirados en
## los de verdad, sin copiarlos. Cada tipo tiene una silueta que se reconoce
## de lejos, armada con perfiles de revolución (`_torno()`: un perfil r(y) que
## se gira con `SurfaceTool`) y asas hechas de tramos de cilindro sobre un arco:
##   - copa nacional: la copa clásica de dos asas sobre un pie;
##   - liga: una columna con un plato abierto arriba y una esfera;
##   - supercopa: un plato pequeño sobre pie;
##   - continental: la copa grande de asas enormes que bajan casi hasta el pie;
##   - segunda continental: una copa alta y fina sin asas;
##   - mundial (clubes y selecciones): un cuerpo que se abre hacia arriba
##     sosteniendo un globo, con dos anillos de color en la base.
## Altura total ≈ `alto` metros, con la base apoyada en y = 0.

static func crear(tipo: String, alto: float = 0.4) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Trofeo_" + tipo
	var oro := _metal(Color(0.95, 0.76, 0.32))
	var plata := _metal(Color(0.86, 0.87, 0.9))
	var base := StandardMaterial3D.new()
	base.albedo_color = Color(0.08, 0.07, 0.07)
	base.roughness = 0.35
	var k := alto / 1.0
	match tipo:
		"copa":
			raiz.add_child(_torno([[0.22, 0.0], [0.22, 0.1], [0.12, 0.12], [0.06, 0.2], [0.05, 0.32], [0.09, 0.38],
				[0.2, 0.46], [0.28, 0.62], [0.31, 0.8], [0.3, 0.84]], k, plata))
			_asas(raiz, 0.29 * k, 0.74 * k, 0.12 * k, 0.018 * k, plata, PI * 1.1)
			raiz.add_child(_torno([[0.24, 0.0], [0.24, 0.1]], k, base))
		"liga":
			raiz.add_child(_torno([[0.2, 0.0], [0.2, 0.14], [0.08, 0.16], [0.06, 0.6], [0.1, 0.66], [0.32, 0.72],
				[0.34, 0.75], [0.1, 0.76]], k, plata))
			var bola := _esfera(0.1 * k, oro)
			bola.position.y = 0.86 * k
			raiz.add_child(bola)
			raiz.add_child(_torno([[0.22, 0.0], [0.22, 0.14]], k, base))
		"supercopa":
			raiz.add_child(_torno([[0.18, 0.0], [0.18, 0.12], [0.05, 0.16], [0.04, 0.45], [0.36, 0.52], [0.38, 0.55],
				[0.0, 0.56]], k, oro))
			raiz.add_child(_torno([[0.2, 0.0], [0.2, 0.12]], k, base))
		"continental":
			raiz.add_child(_torno([[0.22, 0.0], [0.22, 0.16], [0.1, 0.18], [0.07, 0.3], [0.12, 0.4], [0.24, 0.55],
				[0.3, 0.75], [0.3, 0.92], [0.27, 0.95]], k, plata))
			## Las «orejas»: asas enormes que nacen en la boca y bajan hasta el pie.
			_asas(raiz, 0.28 * k, 0.6 * k, 0.32 * k, 0.03 * k, plata, PI * 1.25)
			raiz.add_child(_torno([[0.24, 0.0], [0.24, 0.16]], k, base))
		"continental2":
			raiz.add_child(_torno([[0.18, 0.0], [0.18, 0.12], [0.06, 0.15], [0.04, 0.4], [0.12, 0.6], [0.16, 0.9],
				[0.15, 0.95]], k, oro))
			raiz.add_child(_torno([[0.2, 0.0], [0.2, 0.12]], k, base))
		"mundial_clubes", "mundial_sel":
			raiz.add_child(_torno([[0.2, 0.0], [0.2, 0.06], [0.16, 0.18], [0.09, 0.3], [0.07, 0.42], [0.12, 0.58],
				[0.18, 0.7], [0.0, 0.72]], k, oro))
			var globo := _esfera(0.17 * k, oro)
			globo.position.y = 0.84 * k
			raiz.add_child(globo)
			var anillo := StandardMaterial3D.new()
			anillo.albedo_color = Color(0.1, 0.45, 0.25) if tipo == "mundial_sel" else Color(0.15, 0.25, 0.55)
			anillo.metallic = 0.3
			anillo.roughness = 0.3
			raiz.add_child(_torno([[0.21, 0.07], [0.205, 0.1]], k, anillo))
			raiz.add_child(_torno([[0.19, 0.13], [0.18, 0.16]], k, anillo))
		_:
			raiz.add_child(_torno([[0.18, 0.0], [0.18, 0.1], [0.06, 0.14], [0.05, 0.4], [0.2, 0.6], [0.0, 0.62]], k, oro))
	return raiz

## Para el tipo de una competición por su nombre del núcleo.
static func de_competicion(nombre: String, alto: float = 0.4) -> Node3D:
	return crear(CompeticionInfo.tipo_de(nombre), alto)

static func _metal(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 1.0
	m.roughness = 0.22
	m.metallic_specular = 0.8
	return m

## Sólido de revolución: `perfil` = [[radio, y], ...] de abajo arriba (en
## unidades de 1 m de alto, escalado por `k`), con tapas planas arriba y abajo.
static func _torno(perfil: Array, k: float, mat: Material, lados: int = 40) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector2] = []
	pts.append(Vector2(0.0, float(perfil[0][1])))
	for p: Array in perfil:
		pts.append(Vector2(float(p[0]), float(p[1])))
	pts.append(Vector2(0.0, float(perfil[perfil.size() - 1][1])))
	for i in pts.size() - 1:
		var a := pts[i] * k
		var b := pts[i + 1] * k
		for s in lados:
			var t0 := TAU * float(s) / float(lados)
			var t1 := TAU * float(s + 1) / float(lados)
			var p00 := Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x)
			var p01 := Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x)
			var p10 := Vector3(cos(t0) * b.x, b.y, sin(t0) * b.x)
			var p11 := Vector3(cos(t1) * b.x, b.y, sin(t1) * b.x)
			for v: Vector3 in [p00, p10, p11, p00, p11, p01]:
				st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi

static func _esfera(r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.material_override = mat
	return mi

## Dos asas en arco a los lados: arco de radio `r` centrado a la altura `y`,
## pegado al cuerpo a distancia `x`; `barrido` es el ángulo que recorre.
static func _asas(raiz: Node3D, x: float, y: float, r: float, grosor: float, mat: Material, barrido: float) -> void:
	for lado in [-1.0, 1.0]:
		var prev := Vector3.ZERO
		var tramos := 14
		for i in tramos + 1:
			var a := -barrido / 2.0 + barrido * float(i) / float(tramos)
			var p := Vector3(lado * (x + r * cos(a)), y + r * sin(a), 0.0)
			if i > 0:
				raiz.add_child(_tramo(prev, p, grosor, mat))
			prev = p

static func _tramo(desde: Vector3, hasta: Vector3, radio: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radio
	cm.bottom_radius = radio
	cm.height = maxf(desde.distance_to(hasta) + radio, radio * 2.0)
	cm.radial_segments = 10
	mi.mesh = cm
	mi.material_override = mat
	var dir := (hasta - desde).normalized()
	mi.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), (desde + hasta) * 0.5)
	return mi
