extends Node
## EL EXTERIOR DEL ESTADIO (25-9-2026, plan maestro B6.2): taquillas, tienda y
## estacionamiento, de día y desde dos lados.
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_exterior_estadio.tscn
var _n := 0
var _cam: Camera3D
var _dz := 0.0
var _dx := 0.0
var _alto := 0.0

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var e := EstadioPropio.new()
	for k: String in (EstadioPropio.PRESETS_B6[1][3] as Dictionary):
		e.ajustes[k] = EstadioPropio.PRESETS_B6[1][3][k]
	e.ajustes["clima"] = "dia"
	var perfil := e.perfil(c)
	perfil["niveles"] = 2
	perfil["aforo"] = 52000
	var raiz := Node3D.new()
	add_child(raiz)
	Ambience.apply(raiz, perfil, null, Calidad.elegida)
	StadiumBuilder.build_pitch(raiz, perfil, c)
	StadiumBuilder.build(raiz, perfil, 52000, 0.85, c._hash_id(), c)
	var g := StadiumBuilder.geom_de_forma(String(perfil["forma"]))
	_dx = float(g["dx"])
	_dz = StadiumBuilder.centro_tribuna(float(g["dz"]), 2) + StadiumBuilder.fondo_tribuna(2) / 2.0
	_alto = StadiumBuilder.altura_de(perfil, 52000)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.fov = 60.0
	_cam.position = Vector3(-18.0, 12.0, _dz + 48.0)
	_cam.look_at(Vector3(8.0, 2.0, _dz + 10.0), Vector3.UP)
	_cam.current = true

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		get_viewport().get_texture().get_image().save_png("res://pruebas/exterior_estadio_sur.png")
		_cam.position = Vector3(30.0, 22.0, -_dz - 60.0)
		_cam.look_at(Vector3(0.0, 0.0, -_dz - 22.0), Vector3.UP)
	if _n == 14:
		get_viewport().get_texture().get_image().save_png("res://pruebas/exterior_estadio_norte.png")
		get_tree().quit()
