extends Node3D
## Prueba rapida: que pasa si se pega una foto real de camiseta (la misma que
## usa `Vestidor._tex_camiseta()` para el modelo viejo) directo sobre el UV
## de la tunica Peasant, sin ningun ajuste -para ver de una si el atlas
## complejo la arruina o no, antes de invertir mas tiempo en esto.

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.05, 0.06, 0.07)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.3, 0.3, 0.32)
	ent.ambient_light_energy = 0.6
	add_child(amb)
	amb.environment = ent
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.2
	add_child(luz)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 2.2)
	cam.fov = 40
	add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true

	var packed: PackedScene = load("res://assets/characters/quaternius/ropa_temp/Male_Peasant_Body.gltf")
	var n: Node3D = packed.instantiate()
	add_child(n)

	## `recursos/` vive FUERA del proyecto Godot (hermana de `dinastia-godot/`),
	## asi que no hay un `res://` que la alcance -ruta absoluta del SO en su lugar.
	var foto := Image.load_from_file("C:/Users/Alumno/Desktop/Proyecto x/recursos/equipaciones/boca_juniors_1.png")
	if foto == null:
		print("ERROR: no cargo la foto")
		get_tree().quit(1)
		return
	var tex := ImageTexture.create_from_image(foto)
	for hijo in _mallas(n):
		var mi := hijo as MeshInstance3D
		for s in range(mi.mesh.get_surface_count()):
			var m := mi.get_active_material(s)
			if m is StandardMaterial3D:
				var sm: StandardMaterial3D = (m as StandardMaterial3D).duplicate()
				sm.albedo_texture = tex
				mi.set_surface_override_material(s, sm)

func _mallas(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_mallas(c))
	return out

func _process(_d: float) -> void:
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://pruebas/pieza_ropa_foto_real_boca.png")
	get_tree().quit(0)
