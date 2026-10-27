extends Node3D
## Sombra de contacto (P4): peatones lejos de la sombra del sol. ANTES=1 los deja sin la mancha.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_contacto.tscn → /tmp/contacto_<antes|despues>.png
var _n := 0

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	var suelo := Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(120, 0.2, 120), Mini3D.mat(Color(0.55, 0.55, 0.53)))
	suelo.name = "Suelo"
	for k in 6:
		var d := PeatonVida.nuevo(self, 40 + k)
		var n := d["nodo"] as Node3D
		n.position = Vector3(-6.0 + float(k) * 2.4, 0, -4.0 + float(k % 2) * 3.0)
		n.rotation.y = 0.5 * float(k)
		if OS.get_environment("ANTES") == "1":
			n.get_node("Contacto").queue_free()
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, 30, 0)
	sol.shadow_enabled = false   ## como pasa más allá del alcance de la sombra
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.66)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 3.5, 9)
	cam.look_at(Vector3(0, 0.6, -1), Vector3.UP)
	cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		var tag := "antes" if OS.get_environment("ANTES") == "1" else "despues"
		get_viewport().get_texture().get_image().save_png("/tmp/contacto_%s.png" % tag)
		get_tree().quit()
