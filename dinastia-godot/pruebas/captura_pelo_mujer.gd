extends Node3D
## Corte rapado en una mujer: la malla de hombre (antes) frente a `Hair_BuzzedFemale` (ahora). ANTES=1 fuerza la de antes.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_pelo_mujer.tscn → /tmp/pelo_mujer_<antes|despues>.png
var _n := 0

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	for k in 3:
		rng.seed = 90 + k
		var d := FutbolistaQ.crear(1.65, "female")
		add_child(d["nodo"])
		(d["nodo"] as Node3D).position = Vector3(-1.2 + float(k) * 1.2, 0, 0)
		FutbolistaQ.terminar(d, false)
		var pelo := Color("#3a2a1c") if k != 1 else Color("#c9a56a")
		if OS.get_environment("ANTES") == "1":
			d["cuerpo"] = "male"
		PeloQ.poner(d, "corto", pelo, false)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, 30, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.6, 0.7)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.62)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 1.55, 1.7)
	cam.look_at(Vector3(0, 1.45, 0), Vector3.UP)
	cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		var tag := "antes" if OS.get_environment("ANTES") == "1" else "despues"
		get_viewport().get_texture().get_image().save_png("/tmp/pelo_mujer_%s.png" % tag)
		get_tree().quit()
