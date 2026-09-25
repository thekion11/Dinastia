extends Node3D
## Confirma visualmente lo que sugiere el atlas de textura: el modelo
## Quaternius "Superhero" trae torso desnudo, no camiseta.

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
	cam.position = Vector3(0, 1.1, 3.2)
	cam.fov = 40
	add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true

	var d := FutbolistaQ.crear(1.80, "male")
	add_child(d["nodo"])
	FutbolistaQ.terminar(d, false)
	(d["anim"] as AnimationPlayer).play("parado")

func _process(_delta: float) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://pruebas/quaternius_desnudo.png")
	get_tree().quit(0)
