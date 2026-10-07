extends Node
## Diagnostico rapido (18-9-2026): inspecciona el modelo Quaternius que el
## usuario descargo (Universal Base Characters, version Standard) para ver si
## es candidato limpio a reemplazar/sumar al futbolista_cr7.glb -esqueleto,
## huesos, pose de reposo- sin necesitar partido ni escena real.
##
##   godot --path . --rendering-driver opengl3 --position 0,0 res://pruebas/diagnostico_quaternius.tscn

const RUTA := "res://assets/characters/quaternius/Superhero_Male_FullBody.gltf"

func _ready() -> void:
	var env := Node3D.new()
	add_child(env)
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.05, 0.06, 0.07)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.3, 0.3, 0.32)
	ent.ambient_light_energy = 0.6
	amb.environment = ent
	env.add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.2
	env.add_child(luz)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.1, 3.2)
	cam.fov = 40
	env.add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true

	## Ya copiado e importado dentro del proyecto (assets/characters/quaternius/):
	## `load()` normal, el mismo camino que usara PlayerSpawner de verdad.
	var packed: PackedScene = load(RUTA)
	if packed == null:
		print("NO SE PUDO CARGAR: ", RUTA)
		get_tree().quit(1)
		return
	var modelo: Node3D = packed.instantiate()
	add_child(modelo)
	print("modelo cargado: ", modelo.name)

	var esq := _buscar_esqueleto(modelo)
	if esq == null:
		print("NO TIENE Skeleton3D")
		get_tree().quit(1)
		return
	print("huesos totales: ", esq.get_bone_count())
	for i in esq.get_bone_count():
		print("  hueso %d: %s  (padre: %s)" % [i, esq.get_bone_name(i),
			esq.get_bone_name(esq.get_bone_parent(i)) if esq.get_bone_parent(i) >= 0 else "-"])
	# Busca huesos clave por nombre para comparar con AnimMixamo.HUESOS
	for clave in ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Neck",
			"mixamorig_LeftHand", "mixamorig_RightHand", "Hips", "Spine", "Neck"]:
		var idx := esq.find_bone(clave)
		if idx >= 0:
			var e := esq.get_bone_rest(idx).basis.get_euler() * (180.0 / PI)
			print("  encontrado '%s' (idx %d), reposo: x=%.1f y=%.1f z=%.1f" % [clave, idx, e.x, e.y, e.z])

	# Caja del modelo, para saber su escala real (igual que hace Futbolista con el otro)
	_medir(modelo, Transform3D.IDENTITY, null, true)
	print("AABB del modelo: pos=%s tam=%s" % [_acc.position, _acc.size])

	get_tree().create_timer(0.3).timeout.connect(func():
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/quaternius_vista.png")
		print("captura guardada")
		print("FIN. 0 fallos")
		get_tree().quit(0))

func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _buscar_esqueleto(c)
		if r:
			return r
	return null

var _acc: AABB
var _acc_iniciada := false
func _medir(n: Node, t: Transform3D, _aabb, _es_raiz) -> void:
	var tt := t
	if n is Node3D:
		tt = t * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var a: AABB = tt * (n as MeshInstance3D).get_aabb()
		if not _acc_iniciada:
			_acc = a
			_acc_iniciada = true
		else:
			_acc = _acc.merge(a)
	for c in n.get_children():
		_medir(c, tt, null, false)
