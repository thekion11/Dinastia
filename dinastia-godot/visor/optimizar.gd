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
