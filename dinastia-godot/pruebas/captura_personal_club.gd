extends Node3D
## El personal del club con su apariencia propia en 3 clubes de países distintos (una fila por club).
##   herramientas/captura.sh res://pruebas/captura_personal_club.tscn
const CLUBES := ["CHI-colo", "ESP-sevilla", "ARG-rosario"]
var _n := 0

func _ready() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	var claves: Array = PersonalEstadio.PUESTOS.keys()
	var ancho := claves.size() * 1.0
	cam.position = Vector3(ancho * 0.5, 2.6, 11.5)
	cam.look_at(Vector3(ancho * 0.5, 2.2, 0.0))
	cam.fov = 50
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
	var mujeres := {"secretaria": true, "cocinera": true}
	for f in CLUBES.size():
		var aspectos: Dictionary = AparienciaPersonal.generar(CLUBES[f], claves, mujeres)
		for i in claves.size():
			var p: Array = PersonalEstadio.PUESTOS[claves[i]]
			var asp: Dictionary = aspectos[claves[i]]
			asp["ropa"] = String(p[2])
			asp["c_ropa"] = String(p[3]) if String(p[3]) != "club" else "1f5fa8"
			asp["c_ropa2"] = String(p[4]) if String(p[4]) != "club2" else "ffffff"
			var raiz := Node3D.new()
			raiz.position = Vector3(i * 1.0, (CLUBES.size() - 1 - f) * 2.3, 0)
			add_child(raiz)
			PersonajeDT.crear(raiz, asp)
			if f == 0:
				var et := Label3D.new()
				et.text = String(claves[i])
				et.font_size = 24
				et.pixel_size = 0.004
				et.position = raiz.position + Vector3(0, 2.05, 0.2)
				add_child(et)

func _process(_dt: float) -> void:
	_n += 1
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/personal_club.png")
		get_tree().quit()
