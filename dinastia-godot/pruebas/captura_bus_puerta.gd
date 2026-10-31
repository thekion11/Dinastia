extends Node
## Paraderos y buses de la ciudad: pone un bus en su parada y fotografía la puerta y el paradero (M-171/186). Imprime la distancia de cada puerta a la espera.
##   → /tmp/busp_<n>.png  (BUS_I = qué bus, por defecto 0)
var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo
var _bus: Dictionary = {}
var _fotos := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad, _mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)

func _process(_d: float) -> void:
	_n += 1
	var cb := _vista.get("_ciudad") as CityBuilder
	var traf := cb.get_node_or_null("Trafico") as TraficoCiudad
	if _n == 10:
		_vista.set_process(false)
		var buses: Array = []
		for v: Dictionary in traf._vehiculos:
			if v.has("paradas") and not (v["paradas"] as Array).is_empty():
				buses.append(v)
		print("buses con paradas: ", buses.size(), " esperas: ", cb.esperas_bus.size())
		_bus = buses[int(OS.get_environment("BUS_I")) % buses.size()]
		traf._cuadro = 0
		_bus["s"] = float((_bus["paradas"] as Array)[0]) - 0.2
		_bus["vel"] = 0.0
		traf._colocar(_bus)
	if _n == 14 and not _bus.is_empty():
		var nodo := _bus["nodo"] as Node3D
		var izq := nodo.global_transform * Vector3(1.5, 0, 4.6)
		var der := nodo.global_transform * Vector3(-1.5, 0, 4.6)
		var mejor := Vector3.ZERO
		var dm := 1e9
		for p: Vector3 in cb.esperas_bus:
			if Vector2(p.x - nodo.position.x, p.z - nodo.position.z).length() < dm:
				dm = Vector2(p.x - nodo.position.x, p.z - nodo.position.z).length()
				mejor = p
		print("bus en ", nodo.position, " espera más cercana ", mejor, " a ", dm, " m; puerta nueva (−X) a ", Vector2(der.x - mejor.x, der.z - mejor.z).length(), " m; el lado antiguo (+X) a ", Vector2(izq.x - mejor.x, izq.z - mejor.z).length(), " m")
		var cam: Camera3D = _vista.get("_camara")
		cam.global_position = nodo.global_position + Vector3(0, 7.0, 0) + (mejor - nodo.global_position).normalized() * 12.0 + Vector3(0, 0, 0)
		cam.look_at(nodo.global_position + Vector3(0, 1.5, 0), Vector3.UP)
	if _n == 20:
		get_viewport().get_texture().get_image().save_png("/tmp/busp_%s.png" % OS.get_environment("BUS_I"))
		get_tree().quit()
