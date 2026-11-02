extends Node3D
## §2.5 punto 5 (31-10-2026): cuatro futbolistas sin foto con corte rizado o flequillo (pelo del Drive) y las manos (postura «atleta»).
##   SUFIJO=despues herramientas/captura.sh res://pruebas/captura_futbolistas_acabado.tscn
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
	_cam.position = Vector3(0, 1.5, 2.2)
	_cam.fov = 34
	add_child(_cam)
	_cam.look_at(Vector3(0, 1.45, 0))
	var sp := PlayerSpawner.new()
	var elegidos := []
	var cortes := {}
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantel():
			var datos := Puente3D.jugador(j)
			var look_j = datos.get("look")
			var corte := String(look_j.get("pelo", "")) if typeof(look_j) == TYPE_DICTIONARY else ""
			if String(datos.get("foto", "")) == "" and corte in ["rizado", "flequillo", "ondulado"] and int(cortes.get(corte, 0)) < 2:
				cortes[corte] = int(cortes.get(corte, 0)) + 1
				elegidos.append([c, j, datos])
			if elegidos.size() == 4:
				break
		if elegidos.size() == 4:
			break
	for i in elegidos.size():
		var c: Club = elegidos[i][0]
		var kit := Puente3D.kit(c)
		sp._kit_x = kit["x"]
		var datos: Dictionary = elegidos[i][2]
		var look: Array = PlayerSpawner._look_de(datos)
		var nodo := sp._crear_jugador(self, (elegidos[i][1] as Jugador).id, "DEL", "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 10, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
		var n3 := nodo["nodo"] as Node3D
		n3.position = Vector3(-0.9 + i * 0.6, 0, 0)
		n3.rotation_degrees.y = [0.0, 30.0, -30.0, 0.0][i]
		print("futbolista ", i, ": ", String(datos["look"]["pelo"]))
func _process(_d: float) -> void:
	_n += 1
	var suf := OS.get_environment("SUFIJO")
	if _n == 14:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/futbolistas_cabezas_%s.png" % suf)
		_cam.position = Vector3(-0.6, 0.95, 1.3)
		_cam.look_at(Vector3(-0.6, 0.9, 0))
	if _n == 20:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/futbolistas_manos_%s.png" % suf)
		get_tree().quit()
