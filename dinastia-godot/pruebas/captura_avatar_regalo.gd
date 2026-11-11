extends Node3D
## El avatar regalo animado con el cuerpo del juego (retarget): parado, trotar y correr, de frente y de lado.
##   herramientas/captura.sh res://pruebas/captura_avatar_regalo.tscn
var _n := 0
var _ds: Array = []

func _ready() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(2.0, 1.2, 6.5)
	cam.look_at(Vector3(2.0, 0.95, 0.0))
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, 25, 0)
	add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.22, 0.24, 0.26)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	print("disponible: ", AvatarRegalo.disponible())
	for i in 5:
		var raiz := Node3D.new()
		raiz.position = Vector3(i * 1.0, 0, 0)
		add_child(raiz)
		var d := PersonajeDT.crear(raiz, {"modelo": AvatarRegalo.CLAVE, "altura": 1.8})
		print(i, " ", d.keys())
		_ds.append(d)
		var ap: AnimationPlayer = d["anim"]
		var nombres := ["parado", "trotar", "correr", "patear", "celebrar"]
		var nom: String = nombres[i]
		if ap.has_animation(nom):
			ap.play(nom)
		else:
			print("falta anim ", nom, " ", ap.get_animation_list())
		(d["nodo"] as Node3D).rotation_degrees.y = 0 if i < 3 else 20

func _process(_dt: float) -> void:
	_n += 1
	if _n == 45:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/avatar_regalo_anim.png")
		get_tree().quit()
