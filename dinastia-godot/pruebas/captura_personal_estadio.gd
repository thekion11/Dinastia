extends Node
## CAMARÓGRAFOS, GUARDIAS Y LA BARRA DE ENERGÍA (26-9-2026), de cerca.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_personal_estadio.tscn
const TOMAS := [
	[Vector3(28.0, 3.0, 47.0), Vector3(21.0, 1.2, 54.5)],
	[Vector3(-30.0, 3.0, -4.0), Vector3(-38.8, 1.2, -12.0)],
	[Vector3(18.0, 5.0, 10.0), Vector3(0.0, 1.0, 0.0)],
]
var _n := 0
var _vista: VistaEstadio
var _cam: Camera3D

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 2026)
	m.mi_club_id = m.ligas[0].clubes[0].id
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(m.mi_club(), 0.86, m.ligas[0].clubes[1])

func _process(_d: float) -> void:
	_n += 1
	if _n < 24:
		return
	var t := _n - 24
	var i := t / 8
	if i >= TOMAS.size():
		get_tree().quit()
		return
	if t % 8 == 0:
		if _cam == null:
			_cam = Camera3D.new()
			_cam.fov = 50.0
			add_child(_cam)
		_cam.position = TOMAS[i][0]
		_cam.look_at(TOMAS[i][1])
		_cam.make_current()
	elif t % 8 == 6:
		get_viewport().get_texture().get_image().save_png("res://pruebas/personal_estadio_%d.png" % (i + 1))
