extends Node
## EL DT EN LA BANDA (26-9-2026): tu personaje del creador delante de los
## suplentes locales, y el DT rival en la otra área técnica.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_dt_banda.tscn
var _vista: VistaEstadio
var _frame := 0
var _cam: Camera3D

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	PersonajeDT.del_usuario = {"ropa": "traje", "gafas": "ver", "barba": true, "c_ropa": "111111", "bufanda": true}
	PersonajeDT.club_usuario = m.mi_club_id
	var par := m.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.fov = 45.0
	_cam.position = Vector3(27.0, 2.0, -12.0)
	_cam.look_at(Vector3(35.0, 1.2, -6.5), Vector3.UP)

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 3:
		_cam.make_current()
	if _frame == 40:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/dt_banda.png")
		_cam.position = Vector3(27.0, 2.0, 12.0)
		_cam.look_at(Vector3(35.0, 1.2, 6.5), Vector3.UP)
	if _frame == 46:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/dt_banda_rival.png")
		get_tree().quit()
