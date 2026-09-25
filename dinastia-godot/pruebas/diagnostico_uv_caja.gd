extends Node
## ¿CUÁNTO DE UNA TEXTURA SE VE EN UNA CARA DE `BoxMesh`? (23-9-2026)
##
##   godot --headless --path . res://pruebas/diagnostico_uv_caja.tscn
##
## Se escribe esta sonda porque el arreglo de la pantalla gigante (pasarla de
## `BoxMesh` a `QuadMesh`) demostró que una caja NO mapea la textura entera a
## cada cara. Antes de tocar la GRADA -que son cajas texturadas y es la
## superficie más grande del estadio- hay que saber el número exacto, no
## suponerlo: si cada cara solo ve un trozo, el patrón de butacas que el
## usuario elige en Club → Estadio se está viendo a trozos y ampliado.
##
## No se mira a ojo: se leen las UV reales del `ArrayMesh` que genera Godot.

func _ready() -> void:
	_medir("BoxMesh", BoxMesh.new())
	_medir("QuadMesh", QuadMesh.new())
	_medir("PlaneMesh", PlaneMesh.new())
	print("FIN. 0 fallos")
	get_tree().quit()

func _medir(nombre: String, m: PrimitiveMesh) -> void:
	var arr := m.get_mesh_arrays()
	var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var vtx: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	if uvs.is_empty():
		print("%s: sin UV" % nombre)
		return
	var umin := 9.9
	var umax := -9.9
	var vmin := 9.9
	var vmax := -9.9
	for u in uvs:
		umin = minf(umin, u.x)
		umax = maxf(umax, u.x)
		vmin = minf(vmin, u.y)
		vmax = maxf(vmax, u.y)
	print("%s: %d vertices, U %.3f..%.3f  V %.3f..%.3f" % [nombre, vtx.size(), umin, umax, vmin, vmax])
	## Por cara: se agrupan los vértices por normal y se mide el rectángulo UV
	## de cada grupo. Eso es lo que de verdad importa -cuánto de la imagen le
	## toca a UNA cara.
	var normales: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var caras: Dictionary = {}
	for i in vtx.size():
		var n: Vector3 = normales[i] if i < normales.size() else Vector3.UP
		var clave := "%.0f,%.0f,%.0f" % [n.x, n.y, n.z]
		if not caras.has(clave):
			caras[clave] = [Vector2(9.9, 9.9), Vector2(-9.9, -9.9)]
		var caja: Array = caras[clave]
		caja[0] = Vector2(minf(caja[0].x, uvs[i].x), minf(caja[0].y, uvs[i].y))
		caja[1] = Vector2(maxf(caja[1].x, uvs[i].x), maxf(caja[1].y, uvs[i].y))
		caras[clave] = caja
	for clave: String in caras:
		var caja: Array = caras[clave]
		var ancho: float = caja[1].x - caja[0].x
		var alto: float = caja[1].y - caja[0].y
		print("   cara normal(%s): U %.3f..%.3f (%.0f%%)  V %.3f..%.3f (%.0f%%)  -> ve el %.0f%% de la imagen" % [
			clave, caja[0].x, caja[1].x, ancho * 100.0,
			caja[0].y, caja[1].y, alto * 100.0, ancho * alto * 100.0])
