class_name TelefericoTorre
extends RefCounted
## LAS TORRES DEL TELEFÉRICO (27-10-2026, el dueño: «torres de celosía con su cabezal y las ruedas por donde pasa el cable, no dos palos»):
## un mástil de celosía de cuatro montantes que se estrechan hacia arriba, con travesaños y diagonales en cruz en cada tramo, una
## plataforma con barandilla y un cabezal con una cruceta y, bajo cada cable, un balancín de cuatro ruedas. Las barras son cajas
## unitarias en UN MultiMesh y las ruedas otro (dos mallas por torre).

const ACERO := Color(0.42, 0.45, 0.48)
const NARANJA := Color(0.9, 0.45, 0.1)

## Una barra de `a` a `b` con sección `g` (la caja unitaria se estira a lo largo de su eje).
static func _barra(a: Vector3, b: Vector3, g: float) -> Transform3D:
	var d := b - a
	var eje := d.normalized()
	var x := eje.cross(Vector3.UP)
	if x.length() < 0.01:
		x = eje.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(eje)
	return Transform3D(Basis(x * g, eje * d.length(), z * g), (a + b) * 0.5)

static func _multi(t: Node3D, malla: Mesh, mat: Material, ts: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	t.add_child(mi)

## `p`: el cable en lo alto de la torre; `giro`: el rumbo del cable (la cruceta va de lado a lado, ±2,5 m).
static func montar(t: Node3D, b: CityBuilder, p: Vector3, giro: float) -> int:
	var suelo := TelefericoFlora.altura_malla(b, p.x, p.z)
	var alto := maxf(p.y - suelo, 8.0)
	var lado := Vector3(cos(giro), 0.0, -sin(giro))
	var fondo := Vector3(sin(giro), 0.0, cos(giro))
	var ancho_pie := clampf(alto * 0.2, 2.6, 5.5)
	var ancho_cab := 1.3
	var y_cab := p.y - 1.6                         ## donde acaban los montantes (la cruceta va encima)
	var n := clampi(int(alto / 4.5), 3, 9)
	var barras: Array[Transform3D] = []
	## Anillos de la celosía: de cada altura salen cuatro esquinas; entre anillos, montantes y diagonales en cruz.
	var anillos: Array = []
	for k in n + 1:
		var f := float(k) / float(n)
		var y := lerpf(suelo - 1.0, y_cab, f)
		var w := lerpf(ancho_pie, ancho_cab, f) * 0.5
		anillos.append([p.x, y, p.z, w])
	for k in n:
		var a: Array = anillos[k]
		var c: Array = anillos[k + 1]
		var esq := [[-1.0, -1.0], [1.0, -1.0], [1.0, 1.0], [-1.0, 1.0]]
		for i in 4:
			var e0: Array = esq[i]
			var e1: Array = esq[(i + 1) % 4]
			var pa := Vector3(a[0], a[1], a[2]) + lado * float(e0[0]) * float(a[3]) + fondo * float(e0[1]) * float(a[3])
			var pc := Vector3(c[0], c[1], c[2]) + lado * float(e0[0]) * float(c[3]) + fondo * float(e0[1]) * float(c[3])
			var pa1 := Vector3(a[0], a[1], a[2]) + lado * float(e1[0]) * float(a[3]) + fondo * float(e1[1]) * float(a[3])
			var pc1 := Vector3(c[0], c[1], c[2]) + lado * float(e1[0]) * float(c[3]) + fondo * float(e1[1]) * float(c[3])
			barras.append(_barra(pa, pc, 0.34))                 ## montante
			barras.append(_barra(pc, pc1, 0.16))                ## travesaño superior del tramo
			barras.append(_barra(pa, pc1, 0.13))                ## diagonal
			barras.append(_barra(pa1, pc, 0.13))                ## la otra diagonal (la cruz)
	## Plataforma de mantenimiento a media altura y la cruceta del cabezal.
	var y_pl := lerpf(suelo, y_cab, 0.62)
	var w_pl := lerpf(ancho_pie, ancho_cab, 0.62) * 0.5 + 0.5
	for s: float in [-1.0, 1.0]:
		barras.append(_barra(Vector3(p.x, y_pl, p.z) + lado * s * w_pl + fondo * -w_pl, Vector3(p.x, y_pl, p.z) + lado * s * w_pl + fondo * w_pl, 0.12))
		barras.append(_barra(Vector3(p.x, y_pl + 0.9, p.z) + lado * s * w_pl + fondo * -w_pl, Vector3(p.x, y_pl + 0.9, p.z) + lado * s * w_pl + fondo * w_pl, 0.08))
	barras.append(_barra(Vector3(p.x, y_cab, p.z) - lado * 3.4, Vector3(p.x, y_cab, p.z) + lado * 3.4, 0.4))        ## cruceta
	barras.append(_barra(Vector3(p.x, y_cab + 0.2, p.z) - lado * 3.4, Vector3(p.x, y_cab + 0.2, p.z) - lado * 2.5 + Vector3(0, 0.9, 0), 0.2))
	barras.append(_barra(Vector3(p.x, y_cab + 0.2, p.z) + lado * 3.4, Vector3(p.x, y_cab + 0.2, p.z) + lado * 2.5 + Vector3(0, 0.9, 0), 0.2))
	var mat_a := StandardMaterial3D.new()
	mat_a.albedo_color = ACERO
	mat_a.metallic = 0.5
	mat_a.roughness = 0.55
	_multi(t, BoxMesh.new(), mat_a, barras)
	## Balancín de cada cable: dos brazos cortos a lo largo del cable con cuatro ruedas, justo bajo el cable.
	var ruedas: Array[Transform3D] = []
	var brazos: Array[Transform3D] = []
	for s2: float in [-1.0, 1.0]:
		var c0 := Vector3(p.x, p.y - 0.45, p.z) + lado * s2 * 2.5
		brazos.append(_barra(c0 - fondo * 1.7, c0 + fondo * 1.7, 0.26))
		brazos.append(_barra(c0 + Vector3(0, -0.2, 0), Vector3(p.x, y_cab + 0.4, p.z) + lado * s2 * 2.5, 0.22))
		for k2 in 4:
			var cen := c0 + fondo * (-1.3 + 0.87 * float(k2))
			## Cilindro tumbado (eje a lo largo del lado: el cable rueda por el canal).
			ruedas.append(Transform3D(Basis(fondo * 0.7, lado * 0.28, Vector3.UP * 0.7), cen))
	var mat_n := StandardMaterial3D.new()
	mat_n.albedo_color = NARANJA
	mat_n.roughness = 0.5
	_multi(t, BoxMesh.new(), mat_n, brazos)
	var rueda := CylinderMesh.new()
	rueda.top_radius = 0.5
	rueda.bottom_radius = 0.5
	rueda.height = 1.0
	rueda.radial_segments = 10
	rueda.rings = 0
	var mat_r := StandardMaterial3D.new()
	mat_r.albedo_color = Color(0.12, 0.12, 0.13)
	mat_r.roughness = 0.6
	_multi(t, rueda, mat_r, ruedas)
	return barras.size() + brazos.size() + ruedas.size()
