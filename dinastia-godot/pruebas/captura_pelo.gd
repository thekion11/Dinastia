extends Node3D
## EL PELO DE LOS JUGADORES (25-9-2026): los cuatro peinados 3D, la barba y la
## cabeza rapada, teñidos con colores distintos, de frente y de perfil.
##   godot --path . --rendering-driver opengl3 --resolution 1280x480 res://pruebas/captura_pelo.tscn
const CASOS := [["corto", "#2a1a10", false], ["tupe", "#6b4a2a", true], ["largo", "#e0c070", false],
	["coleta", "#111111", false], ["afro", "#1a120c", true], ["calvo", "#333333", true]]
var _n := 0

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.12, 0.18, 0.15)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.55)
	amb.environment = e
	add_child(amb)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, -25, 0)
	add_child(sol)
	for i in CASOS.size():
		var caso: Array = CASOS[i]
		var d := FutbolistaQ.crear(1.8, "male")
		add_child(d["nodo"])
		FutbolistaQ.terminar(d, true)
		VestidorQ.vestir_equipacion(d, Color("c8102e"), Color.WHITE, "liso", Color(0.78, 0.6, 0.47), Color(caso[1]))
		PeloQ.poner(d, String(caso[0]), Color(caso[1]), bool(caso[2]))
		(d["nodo"] as Node3D).position = Vector3((i - 2.5) * 0.7, 0, 0)
		(d["nodo"] as Node3D).rotation.y = 0.35 if i % 2 == 0 else -0.35
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.62, 2.4)
	cam.fov = 38
	add_child(cam)
	cam.look_at(Vector3(0, 1.55, 0), Vector3.UP)
	cam.current = true

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		get_viewport().get_texture().get_image().save_png("res://pruebas/pelo_jugadores.png")
		get_tree().quit()
