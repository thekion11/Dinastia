extends Node
## f9 · GALERÍA DE UN KIT (27-10-2026): pone en fila las piezas de `assets/kenney/<KIT>/` que se pidan y las fotografía de frente,
## con su nombre debajo. Sirve para elegir piezas de fachada sin adivinar.
##   KIT=edificios_modulares PIEZAS=building-block,building-door ESCALA=1 SALIDA=galeria_kit
## Sin pantalla no hace nada.
var _n := 0

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.55, 0.62, 0.72)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(1, 1, 1)
	ent.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = ent
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, -30, 0)
	add_child(sol)
	var kit := OS.get_environment("KIT") if OS.get_environment("KIT") != "" else "edificios_modulares"
	var piezas: PackedStringArray = OS.get_environment("PIEZAS").split(",", false)
	var esc := float(OS.get_environment("ESCALA")) if OS.get_environment("ESCALA") != "" else 1.0
	var x := 0.0
	for p in piezas:
		var ps := load("res://assets/kenney/%s/%s.glb" % [kit, p]) as PackedScene
		if ps == null:
			continue
		var m := ps.instantiate() as Node3D
		m.scale = Vector3.ONE * esc
		m.position = Vector3(x, 0, 0)
		add_child(m)
		var l := Label3D.new()
		l.text = p
		l.pixel_size = 0.004 * esc
		l.position = Vector3(x, -0.15 * esc, 0.5 * esc)
		l.modulate = Color.BLACK
		add_child(l)
		x += 1.25 * esc
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(x * 0.5, 0.45 * esc + 0.2, x * 0.55 + 2.0 * esc)
	cam.look_at(Vector3(x * 0.5, 0.3 * esc, 0.0))

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var nombre := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "galeria_kit"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas/regalos"))
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/regalos/%s.png" % nombre)
		print("FOTO ", nombre)
		get_tree().quit()
