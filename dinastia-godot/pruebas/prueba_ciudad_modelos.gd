extends Node
## INVENTARIO DE LA CIUDAD (7-10-2026, pedido: «asegúrate de que los modelos de
## la anterior ciudad estén»). Construye la ciudad 3D como la abre el juego y
## lista qué modelos de `assets/ciudad/` aparecen y cuáles no.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/prueba_ciudad_modelos.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _todos_los_modelos() -> Array:
	var sal: Array = []
	var pila: Array = ["res://assets/ciudad"]
	while not pila.is_empty():
		var dir: String = pila.pop_back()
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for sub in d.get_directories():
			pila.append(dir + "/" + sub)
		for f in d.get_files():
			if f.get_extension() in ["glb", "obj", "fbx"]:
				sal.append(dir + "/" + f)
	return sal

func _process(_d: float) -> void:
	_n += 1
	if _n != 6:
		return
	_p.call("_ver_ciudad_propia")
	var v: VistaCiudad = null
	for h in _p.get_children():
		if h is VistaCiudad:
			v = h
	var cb := v.get("_ciudad") as CityBuilder
	var vistos := {}
	var pila: Array = [cb]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		if n.scene_file_path != "":
			vistos[n.scene_file_path] = true
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).mesh.resource_path != "":
			vistos[(n as MeshInstance3D).mesh.resource_path] = true
		if n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null and (n as MultiMeshInstance3D).multimesh.mesh != null:
			var rp := (n as MultiMeshInstance3D).multimesh.mesh.resource_path
			if rp != "":
				vistos[rp.split("::")[0]] = true
		for h in n.get_children():
			pila.append(h)
	## Lo que se usa fuera del mapa o que se retiró a propósito (documentado):
	## el estadio .obj es el respaldo sin perfil; la farola .obj se cambió por
	## farolas propias; las butacas se usan en la grada (malla extraída).
	var aparte := {"estadio.obj": true, "farola.obj": true, "asientos_lod.glb": true}
	var faltan: Array = []
	for m in _todos_los_modelos():
		if not vistos.has(m) and not aparte.has(m.get_file()):
			faltan.append(m.replace("res://assets/ciudad/", ""))
	print("MODELOS en la ciudad: %d · sin usar: %d" % [vistos.size(), faltan.size()])
	for f in faltan:
		print("  SIN USAR ", f)
	print("===== FIN INVENTARIO =====")
	get_tree().quit()
