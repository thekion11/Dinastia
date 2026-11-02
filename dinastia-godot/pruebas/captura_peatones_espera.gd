extends Node3D
## Las formas de esperar de los peatones (`PeatonVida.en_anden`): móvil, llamada, brazos cruzados (UAL2, 31-10) y quieto.
##   SUFIJO=despues herramientas/captura.sh res://pruebas/captura_peatones_espera.tscn
var _n := 0
func _ready() -> void:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.32, 0.36, 0.4)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 25, 0)
	sol.shadow_enabled = true
	add_child(sol)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.35, 4.2)
	cam.fov = 34
	add_child(cam)
	cam.look_at(Vector3(0, 1.0, 0))
	var rs := [0.1, 0.6, 0.8, 0.95]
	for i in 4:
		var d := PeatonVida.nuevo(self, 300 + i * 7)
		if d.is_empty():
			continue
		(d["nodo"] as Node3D).position = Vector3(-1.5 + i * 1.0, 0, 0)
		(d["nodo"] as Node3D).rotation_degrees.y = [10.0, 25.0, -10.0, -25.0][i]
		print("peatón ", i, ": variante ", PeatonVida.en_anden(d, rs[i]))
func _process(_d: float) -> void:
	_n += 1
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/peatones_espera_%s.png" % OS.get_environment("SUFIJO"))
		get_tree().quit()
