extends Node3D
## LA BANDERA ONDEA (25-9-2026): tres fotos de la misma bandera en momentos
## distintos; si el shader no la moviera, las tres serían idénticas.
##   godot --path . --rendering-driver opengl3 --resolution 480x320 res://pruebas/captura_bandera.tscn
var _n := 0
var _imgs: Array[Image] = []

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.6)
	amb.environment = e
	add_child(amb)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sol)
	StadiumBuilder._bandera_ondeante(self, Vector3(-0.65, 0, 0), Vector2(1.3, 0.85), Color("c8102e"), 0.0, 0.0)
	var cam := Camera3D.new()
	cam.position = Vector3(-0.4, 0.35, 1.9)
	add_child(cam)
	cam.look_at(Vector3(0.0, -0.05, 0), Vector3.UP)
	cam.current = true

func _process(_d: float) -> void:
	_n += 1
	if _n in [20, 45, 70]:
		_imgs.append(get_viewport().get_texture().get_image())
	if _n == 71:
		var distintas := 0
		for k in range(1, _imgs.size()):
			var dif := 0
			for y in range(0, 320, 8):
				for x in range(0, 480, 8):
					if _imgs[k].get_pixel(x, y) != _imgs[k - 1].get_pixel(x, y):
						dif += 1
			if dif > 30:
				distintas += 1
		print(("  ok    " if distintas == 2 else "  FALLO ") + "la bandera se mueve entre fotos (%d de 2 pares distintos)" % distintas)
		var hoja := Image.create(480 * 3, 320, false, Image.FORMAT_RGBA8)
		for k in 3:
			hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 320), Vector2i(k * 480, 0))
		hoja.save_png("res://pruebas/bandera_ondea.png")
		get_tree().quit()
