extends Control
## Todos los vehículos de la ciudad en fila, con una persona para la escala.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_vehiculos.tscn
var _n := 0

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	var v := Mini3D.vista(self, Calidad.DIA)
	var raiz: Node3D = v["raiz"]
	Mini3D.caja(raiz, Vector3(0, -0.05, 0), Vector3(120, 0.1, 40), Mini3D.mat(Color(0.3, 0.3, 0.32), 0.9))
	var x := -26.0
	var flota: Array = CityBuilder.flota_coches()
	var vistos := {}
	for ruta in CityBuilder.RUTAS_SERVICIO:
		flota.append({"esc": load(ruta), "escala": 1.65, "fbx": false})
	for par: Dictionary in flota:
		var r: String = (par["esc"] as PackedScene).resource_path
		if vistos.has(r):
			continue
		vistos[r] = true
		var n := CityBuilder.instanciar_coche(par)
		n.position = Vector3(x, 0, 0)
		n.rotation.y = PI * 0.5
		raiz.add_child(n)
		var largo := 5.0 if not r.contains("truck") and not r.contains("fire") else 9.0
		x += largo * 0.5 + 2.6
		n.position.x = x - largo * 0.5
	var bus := CityBuilder.autobus(Color(0.85, 0.15, 0.12), "BUS 10")
	bus.position = Vector3(x + 7.0, 0, 0)
	bus.rotation.y = PI * 0.5
	raiz.add_child(bus)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 3:
		var d := Mini3D.persona(raiz, rng, Vector3(-30.0 + float(k) * 34.0, 0, 3.0))
		if not d.is_empty():
			(d["nodo"] as Node3D).rotation.y = 0.0
	var cam: Camera3D = v["cam"]
	cam.fov = 50.0
	cam.position = Vector3(10, 9, 40)
	cam.look_at(Vector3(10, 1.5, 0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/vehiculos_escala.png")
		get_tree().quit()
