extends Node3D
## LA GORRA CON CADA CORTE (28-9-2026): con gorra el pelo con volumen queda
## debajo y la copa arranca sobre la frente.
func _ready() -> void:
	var e := WorldEnvironment.new(); var en := Environment.new(); en.background_mode = Environment.BG_COLOR; en.background_color = Color(0.6,0.7,0.85); en.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; en.ambient_light_color = Color(0.7,0.7,0.7); e.environment = en; add_child(e)
	var sol := DirectionalLight3D.new(); sol.rotation_degrees = Vector3(-40, -30, 0); add_child(sol)
	var i := 0
	for corte in ["rizado", "afro", "ondulado", "tupe", "largo", "fade"]:
		var d := PersonajeDT.crear(self, {"pelo": corte, "gorra": true, "ropa": "polo", "c_ropa": "c0392b"}, Color("1f5fa8"), Color.WHITE)
		(d["nodo"] as Node3D).position = Vector3(-1.5 + i * 0.6, 0, 0)
		i += 1
	var c := Camera3D.new(); c.position = Vector3(0.3, 1.72, 1.4); c.look_at(Vector3(0, 1.62, 0)); c.fov = 45; add_child(c)
	await get_tree().create_timer(0.6).timeout
	get_viewport().get_texture().get_image().save_png("res://pruebas/gorras.png")
	get_tree().quit()
