extends Node
## La gente del teleférico: bajan por la puerta de la estación y suben desde la plaza. → /tmp/telegente_<n>.png
var _n := 0
var _vista: VistaCiudad
var _tele: Teleferico
var _k := 0
const MOMENTOS := [-4.0, 1.5, 5.0, 8.5]
## [posición local de la cámara, punto al que mira] por toma: cabina llegando (de lado), los que bajan, la rampa y la gente que sube.
const CAMARAS := [[Vector3(24, 6, -16), Vector3(0, 6, -5)], [Vector3(10, 1.8, 30), Vector3(0, 3.0, 9)], [Vector3(9, 2.6, 34), Vector3(0, 3.2, 15)], [Vector3(-6, 2.0, 34), Vector3(0, 1.5, 18)]]

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
		_tele = cb.get_node_or_null("Teleferico") as Teleferico
		print("teleférico: ", _tele != null)
		_tele._t = PasajerosTeleferico.llegada() - 4.4
	if _n > 10 and _tele != null and _k < MOMENTOS.size():
		var est := _tele.estacion_base
		var cam: Camera3D = _vista.get("_camara")
		cam.global_position = est.global_transform * (CAMARAS[_k][0] as Vector3)
		cam.look_at(est.global_transform * (CAMARAS[_k][1] as Vector3), Vector3.UP)
		cam.fov = 60.0
		var u := _tele._t - PasajerosTeleferico.llegada()
		if u >= float(MOMENTOS[_k]):
			get_viewport().get_texture().get_image().save_png("/tmp/telegente_%d.png" % _k)
			print("t=", u, " andando=", _tele.get_node("PasajerosTeleferico")._andando.size())
			_k += 1
	if _tele != null and _k >= MOMENTOS.size():
		get_tree().quit()
