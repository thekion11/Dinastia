extends Node
## C14 EN PANTALLA: el globo con fronteras, relieve y pines, y la ficha del país.
## Además comprueba que un clic en el pin de Argentina elige Argentina.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_globo_c14.tscn
var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/eleccion_club.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	var g: Globo3D = _pantalla.get("_globo")
	if _n == 8:
		_pantalla.call("_elegir_pais", "CHI")
		g.ir_a("CHI", true)
		g.set("_giro_idle", 0.0)
	if _n == 20:
		var arg: MeshInstance3D = g.get("_pines")["ARG"]
		var cam: Camera3D = g.get("_cam")
		var vp: SubViewport = g.get("_viewport")
		var punto := cam.unproject_position(arg.global_position) / (Vector2(vp.size) / g.size)
		print("clic en ARG -> ", g.pais_en(punto))
		get_viewport().get_texture().get_image().save_png("res://pruebas/globo_c14.png")
		get_tree().quit()
