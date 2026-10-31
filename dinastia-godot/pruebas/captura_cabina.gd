extends Node
## El coche por dentro (M-174): primera persona con la cabina 3D. → /tmp/cabina_<n>.png
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
		_vista.set("_ciclo_activo", false)
		_vista.set("_hora", 13.0)
		_vista.call("_aplicar_hora")
		_vista.explorar("coche")
		var e: ExploradorCiudad = _vista.get("_explorador")
		e.cuerpo.position = Vector3(334, 0.2, -560)
		e.rumbo = PI
		e.vel = 12.0
		e.cam_coche = 2
	if _n == 22:
		get_viewport().get_texture().get_image().save_png("/tmp/cabina_0.png")
		var e2: ExploradorCiudad = _vista.get("_explorador")
		print("cabina 3D: ", e2.get("_cabina") != null)
		get_tree().quit()
