extends Node3D
## LOS BALONES (29-9-2026, mapa de metas 19): las ocho pieles, de cerca.
##   godot --path . --rendering-driver opengl3 --resolution 1600x500 res://pruebas/captura_balones.tscn
var _n := 0
var _bolas: Array[Node3D] = []
func _ready() -> void:
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.12, 0.2, 0.14)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.5, 0.5, 0.5)
	amb.environment = ent
	add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, -35, 0)
	add_child(luz)
	var club := Club.new()
	club.color1 = "#b01e2d"
	club.color2 = "#ffffff"
	var skins := Comercial.balones()
	for i in skins.size():
		var cb := Comercial.color_balon(String(skins[i][0]), club)
		var b := Balon3D.crear(Vector3((float(i) - (skins.size() - 1) * 0.5) * 0.3, 0, 0), cb[0], cb[1], String(cb[2]))
		b.rotation = Vector3(0.4, float(i) * 0.7, 0.2)
		add_child(b)
		_bolas.append(b)
	var cam := Camera3D.new()
	cam.fov = 45
	add_child(cam)
	cam.position = Vector3(0, 0.12, 1.55)
	cam.look_at(Vector3.ZERO)
	cam.current = true
func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/balones.png")
		get_tree().quit()
