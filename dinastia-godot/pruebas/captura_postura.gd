extends Node3D
## Postura de los peatones (hombros, cuello, manos). ANTES=1 quita el modificador. EJE_DEDOS/EJE_HOMBRO/EJE_CUELLO="x"|"y"|"z" (+/-) para sondear.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_postura.tscn → /tmp/postura_<antes|despues>_<frente|lado>.png
var _n := 0
var _ids: Array = []

static func _eje(t: String, def: Vector3) -> Vector3:
	match t:
		"x": return Vector3.RIGHT
		"-x": return Vector3.LEFT
		"y": return Vector3.UP
		"-y": return Vector3.DOWN
		"z": return Vector3.BACK
		"-z": return Vector3.FORWARD
	return def

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	PosturaQ.eje_dedos = _eje(OS.get_environment("EJE_DEDOS"), PosturaQ.eje_dedos)
	PosturaQ.eje_hombro = _eje(OS.get_environment("EJE_HOMBRO"), PosturaQ.eje_hombro)
	PosturaQ.eje_cuello = _eje(OS.get_environment("EJE_CUELLO"), PosturaQ.eje_cuello)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(40, 0.2, 40), Mini3D.mat(Color(0.5, 0.5, 0.48)))
	for k in 3:
		var d := PeatonVida.nuevo(self, 61 + k * 7)
		var n := d["nodo"] as Node3D
		n.position = Vector3(-1.2 + float(k) * 1.2, 0, 0)
		Mini3D.anim(d, "parado", "")
		_ids.append(n)
		if OS.get_environment("ANTES") == "1":
			var esq := FutbolistaQ.esqueleto_de(n)
			esq.get_node("PosturaQ").queue_free()
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 20, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.66, 0.7)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.name = "Cam"
	add_child(cam)
	cam.fov = 40.0
	cam.position = Vector3(0, 1.3, 3.2)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	var tag := "antes" if OS.get_environment("ANTES") == "1" else "despues"
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("/tmp/postura_%s_frente.png" % tag)
		for n: Node3D in _ids:
			n.rotation.y = -PI / 2.0
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("/tmp/postura_%s_lado.png" % tag)
		get_tree().quit()
