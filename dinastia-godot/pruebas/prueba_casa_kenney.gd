extends Node3D
## Una fila de casas del kit suburbano con `casa_kenney.gdshader` (tejado por
## instancia, fachada teñida), sin construir la ciudad entera: para revisar el
## shader en segundos.  herramientas/captura.sh res://pruebas/prueba_casa_kenney.tscn
func _ready() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 9, 26)
	cam.look_at(Vector3(0, 3, 0))
	cam.current = true
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -35, 0)
	sol.shadow_enabled = true
	add_child(sol)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.7, 0.8, 0.9)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.68, 0.74)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 40)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.3, 0.5, 0.25)
	suelo.material_override = ms
	add_child(suelo)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://visor/casa_kenney.gdshader")
	mat.set_shader_parameter("paleta", load("res://assets/kenney/suburbano/Textures/colormap.png"))
	var tejados := [Color(0.62, 0.28, 0.2), Color(0.35, 0.33, 0.33), Color(0.5, 0.36, 0.26)]
	var fachadas := [Color(0.93, 0.89, 0.8), Color(0.85, 0.52, 0.38), Color(0.6, 0.72, 0.85), Color(0.66, 0.82, 0.7)]
	for i in 4:
		var ps := load("res://assets/kenney/suburbano/building-type-%s.glb" % ["a", "c", "f", "k"][i]) as PackedScene
		var inst := ps.instantiate()
		var malla: Mesh = (inst.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
		inst.free()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = malla
		mm.instance_count = 1
		mm.set_instance_transform(0, Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * 5.6), Vector3(-15 + i * 10, 0, 0)))
		mm.set_instance_color(0, (fachadas[i] as Color).lerp(Color(0.72, 0.7, 0.66), 0.25).srgb_to_linear())
		mm.set_instance_custom_data(0, (tejados[i % 3] as Color).srgb_to_linear())
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = mat
		add_child(mi)
	for k in 8:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/prueba_casa_kenney.png")
	get_tree().quit()
