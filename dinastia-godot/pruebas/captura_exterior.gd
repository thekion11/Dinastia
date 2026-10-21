extends Node
## EL ESTADIO POR FUERA (21-10-2026): tres tomas — aérea de esquina, desde la
## calle (a la altura de los ojos) y de lado — de la forma FORMA (cuenco por defecto).
##   FORMA=rect herramientas/captura.sh res://pruebas/captura_exterior.tscn  (SUFIJO=_antes)
var _vista: VistaEstadio
var _n := 0
var _cam: Camera3D
const TOMAS := [
	["aerea", Vector3(150.0, 55.0, 125.0), Vector3(0.0, 5.0, 0.0), 50.0],
	["calle", Vector3(95.0, 1.7, 80.0), Vector3(40.0, 14.0, 30.0), 70.0],
	["lado", Vector3(150.0, 12.0, 0.0), Vector3(0.0, 12.0, 0.0), 60.0],
]

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var club := mundo.mi_club()
	var perfil := club.perfil_estadio()
	if OS.get_environment("FORMA") != "":
		perfil["forma"] = OS.get_environment("FORMA")
	perfil["niveles"] = 2
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.9, null, null, perfil)

func _process(_d: float) -> void:
	_n += 1
	var i := (_n - 12) / 5
	if _n < 12:
		return
	if i >= TOMAS.size():
		get_tree().quit()
		return
	var t: Array = TOMAS[i]
	if (_n - 12) % 5 == 0:
		if _cam == null:
			_cam = Camera3D.new()
			(_vista.get("_raiz3d") as Node3D).add_child(_cam)
			_vista.set_process(false)
		_cam.global_position = t[1]
		_cam.look_at(t[2])
		_cam.fov = float(t[3])
		_cam.far = 2000.0
		_cam.current = true
	if (_n - 12) % 5 == 3:
		var f := OS.get_environment("FORMA") if OS.get_environment("FORMA") != "" else "cuenco"
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/exterior_%s_%s%s.png" % [f, t[0], OS.get_environment("SUFIJO")])
		print("FOTO ", t[0])
