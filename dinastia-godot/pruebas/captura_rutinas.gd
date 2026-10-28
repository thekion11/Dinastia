extends Node
## Rutinas de peatones por hora (M-183): la misma calle a las 3, 8, 13 y 19 h. RUTINA_PEATONES=0 las apaga («antes»). SECTOR=200 (por defecto 100).
## → /tmp/rutina_<antes|despues>_<hora>.png y una línea «gente» con los visibles a 70 m.
var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo
var _horas := [3.0, 8.0, 13.0, 19.0]
var _i := 0
var _fase := 0
var _centro := Vector3.ZERO

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad, _mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)
	_centro = {"100": Vector3(120, 0, 40), "200": Vector3(60, 0, -520), "400": Vector3(60, 0, 740)}.get(OS.get_environment("SECTOR") if OS.get_environment("SECTOR") != "" else "100", Vector3(120, 0, 40))

func _process(_d: float) -> void:
	_n += 1
	if _n < 12 or _i >= _horas.size():
		if _i >= _horas.size():
			get_tree().quit()
		return
	var cam: Camera3D = _vista.get("_camara")
	var traf := (_vista.get("_ciudad") as CityBuilder).get_node_or_null("Trafico") as TraficoCiudad
	if _fase == 0:
		_vista.set_process(false)
		_vista.set("_hora", _horas[_i])
		_vista.call("_aplicar_hora")
		traf.reciclar_peatones(_centro, Vector3(0, 0, 1), 0.0, 400, 400, true)
		RutinaPeatones._ultimo_ms = -100000
		cam.global_position = _centro + Vector3(-30, 9.0, 34)
		cam.look_at(_centro + Vector3(0, 1.0, 0), Vector3.UP)
		_fase = 1
		return
	_fase += 1
	if _fase == 6:
		var cerca := 0
		var total := 0
		for v: Dictionary in traf._vehiculos:
			if bool(v.get("peaton", false)) and is_instance_valid(v["nodo"]):
				var nd := v["nodo"] as Node3D
				if Vector2(nd.position.x, nd.position.z).distance_to(Vector2(_centro.x, _centro.z)) < 70.0:
					total += 1
					if nd.visible:
						cerca += 1
		print("gente %02d h: %d visibles de %d a 70 m" % [int(_horas[_i]), cerca, total])
		get_viewport().get_texture().get_image().save_png("/tmp/rutina_%s_%02d.png" % ["antes" if OS.get_environment("RUTINA_PEATONES") == "0" else "despues", int(_horas[_i])])
		_i += 1
		_fase = 0
