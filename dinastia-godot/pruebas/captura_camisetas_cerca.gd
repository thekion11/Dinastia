extends Node3D
## De cerca: cuatro equipaciones (frente, tres cuartos, espalda), pecho y piernas.
##   SUFIJO=despues herramientas/captura.sh res://pruebas/captura_camisetas_cerca.tscn
var _n := 0
var _cam: Camera3D
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI", "ESP", "ARG", "GER", "ITA", "ENG"], 77)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.3, 0.25)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 30, 0)
	sol.shadow_enabled = true
	add_child(sol)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 1.1, 3.4)
	_cam.fov = 36
	add_child(_cam)
	var cs: Array = m.clubes.values()
	var sp := PlayerSpawner.new()
	var giros := [0.0, 35.0, 180.0, -30.0]
	for i in 4:
		var c: Club = cs[(i * 5 + 2) % cs.size()]
		var kit := Puente3D.kit(c)
		sp._kit_x = kit["x"]
		var j: Jugador = c.plantel()[0]
		var datos := Puente3D.jugador(j)
		var look: Array = PlayerSpawner._look_de(datos)
		var nodo := sp._crear_jugador(self, j.id, "DEL", "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 10, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
		var n3 := nodo["nodo"] as Node3D
		n3.position = Vector3(-1.5 + i * 1.0, 0, 0)
		n3.rotation_degrees.y = giros[i]
func _process(_d: float) -> void:
	_n += 1
	var suf := OS.get_environment("SUFIJO")
	if _n == 14:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/camisetas_cerca_%s.png" % suf)
		_cam.position = Vector3(-1.5, 1.25, 1.15)
		_cam.fov = 40
	if _n == 20:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/camisetas_detalle_%s.png" % suf)
		_cam.position = Vector3(-0.5, 0.6, 1.25)
		_cam.fov = 40
	if _n == 26:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/camisetas_piernas_%s.png" % suf)
		get_tree().quit()
