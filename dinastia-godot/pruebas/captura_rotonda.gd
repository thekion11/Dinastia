extends Node
## La rotonda (M-168): vista desde un brazo, aérea y desde la isla. → /tmp/rotonda_<n>.png. SIN_ROTONDA=1 quita la rotonda («antes»: cruce con semáforos).
var _n := 0
var _vista: VistaCiudad

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4713)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(m.mi_club(), m.obras, m.ciudad, m.perfil_estadio_de(m.mi_club()))
	_vista.set("_girando", false)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_vista.set_process(false)
		_vista.set("_ciclo_activo", false)
		_vista.set("_hora", 13.0)
		_vista.call("_aplicar_hora")
	if _n < 12:
		return
	var c := CiudadRotonda.CENTRO
	var cam: Camera3D = _vista.get("_camara")
	var vistas := [[c + Vector3(0, 2.0, 38), c + Vector3(0, 2.0, 0)], [c + Vector3(30, 38, 30), c], [c + Vector3(-17, 1.9, 17), c + Vector3(6, 1.5, -6)]]
	var i := (_n - 12) / 6
	if i >= vistas.size():
		get_tree().quit()
		return
	if (_n - 12) % 6 == 0:
		cam.global_position = vistas[i][0]
		cam.look_at(vistas[i][1], Vector3.UP)
		cam.fov = 60.0
	if (_n - 12) % 6 == 4:
		get_viewport().get_texture().get_image().save_png("/tmp/rotonda_%s_%d.png" % ["antes" if OS.get_environment("SIN_ROTONDA") != "" else "despues", i])
