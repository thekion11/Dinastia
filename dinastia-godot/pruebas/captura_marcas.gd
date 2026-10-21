extends Node3D
## Los seis fabricantes en el pecho (21-10-2026, M-057): marca propia, Korrida,
## Astra Sport, Nimbo, Salto y Volkspor.
##   herramientas/captura.sh res://pruebas/captura_marcas.tscn
var _n := 0
var _cam: Camera3D
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.3, 0.25)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-30, 10, 0)
	add_child(sol)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 1.38, 2.6)
	_cam.fov = 34
	add_child(_cam)
	var cs: Array = m.clubes.values()
	var sp := PlayerSpawner.new()
	var marcas := DisenosKit.MARCA_FORMA.keys()
	for i in marcas.size():
		var c: Club = cs[(i * 3 + 1) % cs.size()]
		var kit := Puente3D.kit(c)
		kit["x"]["marca"] = marcas[i]
		sp._kit_x = kit["x"]
		var j: Jugador = c.plantel()[0]
		var datos := Puente3D.jugador(j)
		var look: Array = PlayerSpawner._look_de(datos)
		var nodo := sp._crear_jugador(self, j.id, "DEL", "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 10, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
		var n3 := nodo["nodo"] as Node3D
		n3.position = Vector3(-1.5 + i * 0.6, 0, 0)
func _process(_d: float) -> void:
	_n += 1
	if _n == 14:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/marcas_fabricantes.png")
		print("FOTO marcas")
		get_tree().quit()
