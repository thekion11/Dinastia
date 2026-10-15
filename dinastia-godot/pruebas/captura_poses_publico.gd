extends Node
## Las 6 poses horneadas del público, de frente y de lado, con el shader de la hinchada.
var _f := 0
func _ready() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 0.6, 5.6)
	cam.fov = 40
	cam.current = true
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, 30, 0)
	add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.2, 0.25, 0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	add_child(env)
	var mallas := StadiumBuilder._hinchas_horneados(OS.get_environment("NIVEL") if OS.get_environment("NIVEL") != "" else "cerca")
	for i in mallas.size():
		var mat := ShaderMaterial.new()
		mat.shader = load("res://visor/hinchada.gdshader")
		mat.set_shader_parameter("cuello_desde", float(mallas[i].get_meta("cuello_desde", 0.7)))
		mat.set_shader_parameter("cuello_hasta", float(mallas[i].get_meta("cuello_hasta", 0.73)))
		mat.set_shader_parameter("pelo_desde", float(mallas[i].get_meta("pelo_desde", 0.86)))
		mat.set_shader_parameter("lado_max", 0.14)
		mat.set_shader_parameter("amplitud", 0.0)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mallas[i]
		mm.instance_count = 2
		for k in 2:
			mm.set_instance_transform(k, Transform3D(Basis().rotated(Vector3.UP, 0.0 if k == 0 else 0.9), Vector3(-4.2 + i * 1.2, -0.3 - 0.8 * k * 0, -float(k) * 0.0) + Vector3(0, -0.25 + k * -0.75, 0)))
			mm.set_instance_color(k, Color(0.8, 0.2, 0.2) if k == 0 else Color(0.2, 0.3, 0.8))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = mat
		add_child(mi)
func _process(_d: float) -> void:
	_f += 1
	if _f == 6:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/poses_publico.png")
		print("FIN. 0 fallos")
		get_tree().quit()
