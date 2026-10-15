extends Node3D
## Ocho clubes DISTINTOS (no solo Marga Marga) con su camiseta 3D: escudo del club
## y patrocinador en el pecho (14-10-2026).
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_camisetas_3d_clubes.tscn
var _n := 0
func _ready() -> void:
	VestidorQ.ropa_aparte = OS.get_environment("APARTE") != ""
	var m := Mundo.new()
	m.generar(["CHI", "ESP", "ARG", "GER", "ITA", "ENG"], 77)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.3, 0.25)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.85)
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-30, 20, 0)
	add_child(sol)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.45, 5.2)
	cam.fov = 38
	add_child(cam)
	var cs: Array = m.clubes.values()
	var sp := PlayerSpawner.new()
	for i in 8:
		var c: Club = cs[(i * 5 + 2) % cs.size()]
		var kit := Puente3D.kit(c)
		sp._kit_x = kit["x"]
		var j: Jugador = c.plantel()[0]
		var datos := Puente3D.jugador(j)
		var look: Array = PlayerSpawner._look_de(datos)
		var nodo := sp._crear_jugador(self, j.id, "DEL", "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 10, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
		(nodo["nodo"] as Node3D).position = Vector3(-3.6 + (i % 4) * 2.4, 0, -(i / 4) * 0.0 + (i / 4) * -0.01)
		(nodo["nodo"] as Node3D).position.x = -4.2 + i * 1.2
		print("CLUB ", c.nombre)
func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/camisetas_3d_clubes%s.png" % ("_aparte" if OS.get_environment("APARTE") != "" else ""))
		print("FIN. 0 fallos")
		get_tree().quit()
