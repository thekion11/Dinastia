extends Node
## Gasolinera con lavado de autos y aparcamiento (M-177). → /tmp/lavado_<n>.png (túnel desde la calle, aérea, aparcamiento)
var _n := 0
var _vista: VistaCiudad
var _l: Node

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
	var cb := _vista.get("_ciudad") as CityBuilder
	if _n == 10:
		_vista.set_process(false)
		_l = cb.get_node_or_null("LavadoDeAutos")
		print("lavado: ", _l != null)
	if _l == null or _n < 12:
		return
	var t: Vector3 = _l.get_meta("tunel")
	var ap: Vector3 = _l.get_meta("aparcamiento")
	var cam: Camera3D = _vista.get("_camara")
	var vistas := [[t + Vector3(0.5, 2.0, -21), t + Vector3(0, 1.8, 0)], [t + Vector3(28, 20, -6), (t + ap) * 0.5], [ap + Vector3(14, 3.0, -8), ap + Vector3(-2, 0.8, 0)]]
	var i := (_n - 12) / 6
	if i >= vistas.size():
		get_tree().quit()
		return
	if (_n - 12) % 6 == 0:
		cam.global_position = vistas[i][0]
		cam.look_at(vistas[i][1], Vector3.UP)
		cam.fov = 60.0
	if (_n - 12) % 6 == 4:
		get_viewport().get_texture().get_image().save_png("/tmp/lavado_%d.png" % i)
