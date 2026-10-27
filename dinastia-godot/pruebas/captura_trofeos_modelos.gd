extends Node3D
## Todas las copas de receta (orden 15 e) en una hoja: 9 por fila. GRUPO=liga|copa|conf|todo (por defecto todo).
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_trofeos_modelos.tscn
var _f := 0

func _ready() -> void:
	var ids: Array = TrofeosReales.ids()
	var g := OS.get_environment("GRUPO")
	if g != "" and g != "todo":
		ids = ids.filter(func(i: String) -> bool: return i.begins_with(g))
	var por_fila := 9
	for k in ids.size():
		var n := TrofeoModelo.nodo(TrofeosReales.receta(String(ids[k])), 0.62)
		n.position = Vector3((k % por_fila - (por_fila - 1) * 0.5) * 0.55, -(k / por_fila) * 0.9, 0)
		add_child(n)
	var filas := (ids.size() + por_fila - 1) / por_fila
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(float(filas) * 0.9 + 0.3, 1.6)
	cam.position = Vector3(0, -float(filas - 1) * 0.45 + 0.3, 5)
	add_child(cam)
	cam.current = true
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-25, -25, 0)
	l.light_energy = 1.3
	add_child(l)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.14, 0.16)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.55, 0.58)
	add_child(env)

func _process(_d: float) -> void:
	_f += 1
	if _f == 8:
		get_viewport().get_texture().get_image().save_png("/tmp/trofeos_modelos.png")
		print("FIN. 0 fallos")
		get_tree().quit()
