extends SceneTree
## Mide los modelos de los kits que usan los interiores (a escala 1): caja
## (AABB), altura del asiento (rayo hacia abajo en el centro de la huella) y de
## qué lado está lo alto (respaldo / cabecero).
##   godot --headless --path . -s res://pruebas/medir_muebles.gd
##   (MODELOS="muebles/chair,comida/pizza" para medir solo esos)

func _init() -> void:
	var lista: Array = []
	var env := OS.get_environment("MODELOS")
	if env != "":
		for m in env.split(","):
			lista.append(m)
	else:
		for kit: String in ["muebles", "mini_mercado", "mini_arcade"]:
			for f in DirAccess.get_files_at("res://assets/kenney/%s" % kit):
				if f.ends_with(".glb"):
					lista.append("%s/%s" % [kit, f.get_basename()])
	for m: String in lista:
		var ruta := "res://assets/kenney/%s.glb" % m if not m.begins_with("res://") else m
		var ps: PackedScene = load(ruta)
		if ps == null:
			print("FALTA ", ruta)
			continue
		var n: Node3D = ps.instantiate()
		var caja := AABB()
		var primera := true
		var tris := 0
		var caras := PackedVector3Array()
		for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
			var t := _t_rel(mi, n)
			var a := t * mi.get_aabb()
			caja = a if primera else caja.merge(a)
			primera = false
			var f := mi.mesh.get_faces()
			tris += f.size() / 3
			for v in f:
				caras.append(t * v)
		var c := caja.get_center()
		## Asiento: el punto más alto bajo un rayo en el centro de la huella
		## (algo hacia +Z, lejos del respaldo si lo hay en −Z).
		var asiento := _alto_en(caras, Vector2(c.x, c.z + caja.size.z * 0.1))
		var alto_menos := _alto_lado(caras, c.z, -1.0)
		var alto_mas := _alto_lado(caras, c.z, 1.0)
		print("%-36s tam=(%.2f, %.2f, %.2f) min=(%.2f, %.2f, %.2f) asiento=%.2f altoZ-=%.2f altoZ+=%.2f tris=%d" % [m,
			caja.size.x, caja.size.y, caja.size.z, caja.position.x, caja.position.y, caja.position.z, asiento, alto_menos, alto_mas, tris])
		n.free()
	quit()

func _t_rel(nodo: Node3D, raiz: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var x: Node = nodo
	while x != null and x != raiz:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t

## Altura del triángulo más alto que cubre el punto (x, z).
func _alto_en(caras: PackedVector3Array, p: Vector2) -> float:
	var mejor := -1.0
	var i := 0
	while i + 2 < caras.size():
		var r: Variant = Geometry3D.ray_intersects_triangle(Vector3(p.x, 50, p.y), Vector3.DOWN, caras[i], caras[i + 1], caras[i + 2])
		if r != null:
			mejor = maxf(mejor, (r as Vector3).y)
		i += 3
	return mejor

## El vértice más alto en la mitad −Z (lado = −1) o +Z (lado = +1).
func _alto_lado(caras: PackedVector3Array, cz: float, lado: float) -> float:
	var mejor := 0.0
	for v in caras:
		if (v.z - cz) * lado > 0.0:
			mejor = maxf(mejor, v.y)
	return mejor
