extends Node
## ESTADIO INTERACTIVO 2.0, fase 1: de la calle al estadio por la puerta del
## club, con el DT. Hoja: `pruebas/capturas/estadio_ciudad.png`.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/captura_estadio_ciudad.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _imgs: Array[Image] = []

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto() -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(480, 270)
	_imgs.append(img)
	print("FOTO ", _imgs.size(), " estado=", _e.estado, " zona=", _e._zona_est, " pos=", _e.cuerpo.position)

func _andar(seg: float, corre := false) -> void:
	## Avanza simulando la tecla W (sin pulsarla: se fuerza la entrada).
	_e._tactil_vec = Vector2(0, 1)
	for i in int(seg * 30.0):
		_e._physics_process(1.0 / 30.0)
	_e._tactil_vec = Vector2.ZERO

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 16.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_e = _v.get("_explorador")
		var pu: Vector3 = CityBuilder.ESTADIO_EN + (_e._est["puerta"] as Vector3)
		_e.cuerpo.position = pu + Vector3(0, 0.2, 7.0)
		_e.rumbo = PI
		_e._colocar_camara(1.0)
		for r: Rect2 in _e.obstaculos:
			if r.grow(0.6).has_point(Vector2(pu.x, pu.z + 3.0)) or r.grow(0.6).has_point(Vector2(pu.x, pu.z + 1.0)):
				print("OBST ", r)
		print("PUERTA ", pu)
		var x0 := CityBuilder.ESTADIO_EN.x + float(_e._est["x0"])
		var rv := Rect2(x0 - 8.0, CityBuilder.ESTADIO_EN.z + float(_e._est["z_out"]), 16.0, 13.0)
		_buscar_intrusos(_v.get("_ciudad"), rv)
	if _n == 12:
		_e.call("_buscar_cerca")
		_foto()                             # 1: en la calle, delante de la puerta
		_andar(3.4)
		_e.call("_buscar_cerca")
		_e.call("_usar")                    # entrar
	if _n == 18:
		_andar(0.3)
		_foto()                             # 2: dentro del vestuario
		_e.rumbo = PI
		_e.cuerpo.position.x = CityBuilder.ESTADIO_EN.x + float(_e._est["x0"])
		_andar(5.0, true)
	if _n == 24:
		_foto()                             # 3: el túnel
		_andar(6.0, true)
	if _n == 30:
		_foto()                             # 4: en la cancha
		## De vuelta: media vuelta y a la puerta del club.
		_e.rumbo = 0.0
		_andar(9.0, true)
		_e.cuerpo.position.x = CityBuilder.ESTADIO_EN.x + float(_e._est["x0"]) + TunelVestuario.PUERTA_X
		_andar(8.0, true)
	if _n == 36:
		_foto()                             # 5: de nuevo en la calle
		## Vista aérea del estadio en la ciudad y del edificio del vestuario.
		_e.set_physics_process(false)
		_e.camara.position = CityBuilder.ESTADIO_EN + Vector3(60, 45, 140)
		_e.camara.look_at(CityBuilder.ESTADIO_EN + Vector3(0, 5, 70), Vector3.UP)
	if _n == 42:
		_foto()                             # 6: aérea
		var hoja := Image.create(480 * 3, 270 * 2, false, Image.FORMAT_RGBA8)
		for k in _imgs.size():
			hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 3) * 480, (k / 3) * 270))
		hoja.save_png("res://pruebas/capturas/estadio_ciudad.png")
		print("HOJA OK")
		get_tree().quit()

func _buscar_intrusos(n: Node, rv: Rect2) -> void:
	if n.name == "TunelVestuario":
		return
	if n is MeshInstance3D:
		var p: Vector3 = (n as Node3D).global_position
		if rv.has_point(Vector2(p.x, p.z)):
			print("INTRUSO ", n.get_parent().name, " ", (n as MeshInstance3D).mesh.get_class(), " ", (n as MeshInstance3D).get_aabb().size, " ", p)
	elif n is MultiMeshInstance3D:
		var mm := (n as MultiMeshInstance3D).multimesh
		var t0: Transform3D = (n as Node3D).global_transform
		for i in mm.instance_count:
			var p2: Vector3 = t0 * mm.get_instance_transform(i).origin
			if rv.has_point(Vector2(p2.x, p2.z)):
				print("INTRUSO_MM ", n.get_path(), " i=", i, " ", p2)
				break
	for h in n.get_children():
		_buscar_intrusos(h, rv)
