extends Node
## EL MÓVIL EN LA MANO, DE CERCA (28-9-2026): tres ángulos del agarre.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_mano_movil.tscn
const TOMAS := [
	[Vector3(0.55, 1.25, 1.35), Vector3(-0.12, 0.95, 0.3)],
	[Vector3(-0.95, 1.2, 0.9), Vector3(-0.12, 0.95, 0.3)],
	[Vector3(-0.35, 1.55, -0.35), Vector3(-0.12, 0.92, 0.35)],
]
var _esc: CasaEscena3D
var _cam: Camera3D
var _n := 0

func _ready() -> void:
	_esc = CasaEscena3D.new()
	add_child(_esc)
	_esc.montar("jardin", "micro", {}, Color("1f5fa8"), Color.WHITE)
	_cam = Camera3D.new()
	_cam.fov = 35.0
	add_child(_cam)

func _process(_d: float) -> void:
	_n += 1
	var i := (_n - 10) / 10
	if _n < 10:
		return
	if i >= TOMAS.size():
		get_tree().quit()
		return
	_cam.position = TOMAS[i][0]
	_cam.look_at(TOMAS[i][1])
	_cam.make_current()
	if (_n - 10) % 10 == 8:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/mano_movil_%d.png" % (i + 1))
