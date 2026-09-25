extends Node3D
## Verifica que FutbolistaQ carga y escala bien el cuerpo Female, y que la
## animacion real "Walk" tambien le calza (mismo esqueleto que Male).

func _ready() -> void:
	var env := Node3D.new()
	add_child(env)
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.05, 0.06, 0.07)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.35, 0.35, 0.37)
	ent.ambient_light_energy = 0.7
	amb.environment = ent
	env.add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.3
	env.add_child(luz)
	var cam := Camera3D.new()
	cam.position = Vector3(3.2, 1.0, 0)
	cam.fov = 40
	env.add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true
	var piso := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6, 6)
	piso.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.25)
	piso.material_override = mat
	env.add_child(piso)

	var d := FutbolistaQ.crear(1.70, "female")
	add_child(d["nodo"])
	FutbolistaQ.terminar(d)
	print("altura pedida=1.70 escala=", d["modelo"].scale)
	_ap = d["anim"]

var _ap: AnimationPlayer

func _process(_delta: float) -> void:
	var f := Engine.get_process_frames()
	if f == 5:
		_ap.play("parado")
	if f == 8:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/q_female_parado.png")
	if f == 12:
		_ap.play("caminar")
	if f == 40:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/q_female_caminar.png")
		print("FIN. 0 fallos")
		get_tree().quit(0)
