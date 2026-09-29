extends Node3D
## Sonda de ejes del muslo (abducción y rotación), columna y pelvis (26-9-2026).
const CASOS := [["cadera", Vector3(40, 0, 0)], ["cadera", Vector3(0, 0, 40)], ["cadera", Vector3(-40, 0, 0)], ["espalda2", Vector3(0, 40, 0)], ["espalda1", Vector3(30, 0, 0)], ["cuello", Vector3(0, 40, 0)], ["pie_d", Vector3(0, 40, 0)], ["pie_d", Vector3(0, 0, 40)]]
var _n := 0
func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.13, 0.32, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.7)
	env.environment = e
	add_child(env)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.1, 6.0)
	cam.fov = 58
	add_child(cam)
	for i in CASOS.size():
		var d := FutbolistaQ.crear(1.8, "male")
		var raiz: Node3D = d["nodo"]
		raiz.position = Vector3(-4.2 + i * 1.2, 0, 0)
		raiz.rotation_degrees.y = 35.0
		add_child(raiz)
		FutbolistaQ.terminar(d, false)
		var esq: Skeleton3D = raiz.find_children("*", "Skeleton3D", true, false)[0]
		var ap: AnimationPlayer = d["anim"]
		var a := AnimQuaternius._nueva(1.0, true)
		var caso: Array = CASOS[i]
		AnimQuaternius._pista(a, esq, "brazo_i" if caso[0] != "brazo_i" else "brazo_d", [[0.0, Vector3.ZERO]], str(ap.get_path_to(esq)) if false else AnimQuaternius.HUESOS.get("x", str(esq.get_path())))
		var lib := AnimationLibrary.new()
		var pre := str(ap.get_node(ap.root_node).get_path_to(esq))
		var b := AnimQuaternius._nueva(1.0, true)
		if false:
			AnimQuaternius._pista(b, esq, "brazo_i", [[0.0, Vector3(0, 0, 0)], [1.0, Vector3(0, 0, 0)]], pre)
		AnimQuaternius._pista(b, esq, caso[0], [[0.0, caso[1]], [1.0, caso[1]]], pre)
		## Rodilla doblada para ver hacia dónde gira la pierna.
		if String(caso[0]).begins_with("muslo"):
			var l := String(caso[0]).right(1)
			AnimQuaternius._pista(b, esq, "pierna_" + l, [[0.0, Vector3(70, 0, 0)], [1.0, Vector3(70, 0, 0)]], pre)
		lib.add_animation("sonda", b)
		ap.add_animation_library("s", lib)
		ap.play("s/sonda")
		var r := Label3D.new()
		r.text = "%s %s" % [caso[0], str(caso[1])]
		r.font_size = 20
		r.pixel_size = 0.004
		r.position = Vector3(raiz.position.x, 2.1, 0)
		add_child(r)
func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/sonda_piernas2.png")
		get_tree().quit()
