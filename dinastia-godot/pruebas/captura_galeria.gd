extends Node
## ESTADIO INTERACTIVO 2.0, fase 6: la galería subterránea del sótano del club
## al complejo. Hoja: `pruebas/capturas/galeria.png`.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/captura_galeria.tscn
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
	print("FOTO ", _imgs.size(), " estado=", _e.estado, " zona=", _e._zona_est, " planta=", _e._planta, " pos=", _e.cuerpo.position, " aviso=", _e._aviso.text)

func _andar(seg: float) -> void:
	_e._tactil_vec = Vector2(0, 1)
	for i in int(seg * 30.0):
		_e._physics_process(1.0 / 30.0)
	_e._tactil_vec = Vector2.ZERO

func _girar_a(r: float) -> void:
	_e.rumbo = r
	_e._tactil_vec = Vector2.ZERO
	for i in 20:
		_e._physics_process(1.0 / 30.0)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 11.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_e = _v.get("_explorador")
		var pu: Vector3 = CityBuilder.ESTADIO_EN + (_e._est["puerta"] as Vector3)
		_e.cuerpo.position = pu + Vector3(0, 0.2, 2.0)
		_e.rumbo = PI
		_e.cuerpo.position = GaleriaClub.boca_mundo(_e._est) + Vector3(0, 0.2, 1.2)
		_e.call("_buscar_cerca")
		_e.call("_usar")                    # dentro del vestuario
		_e.call("_ir_a_planta", -2)         # ascensor al sótano
		var t := GaleriaClub.trazado(_e._est)
		_e.cuerpo.position = CityBuilder.ESTADIO_EN + Vector3(float(t["xa"]) - 2.5, RecorridoClub.y_de(-2), float(_e._est["z_fin"]) - 1.5)
		_girar_a(PI / 2.0 - 0.7)
	if _n == 14:
		_foto()                             # 1: el pasillo del sótano y la puerta
		var t := GaleriaClub.trazado(_e._est)
		_e.cuerpo.position.x = CityBuilder.ESTADIO_EN.x + float(t["xa"])
		_girar_a(0.0)
		_andar(2.5)
	if _n == 20:
		_foto()                             # 2: dentro de la galería
		_andar(14.0)
	if _n == 26:
		_foto()                             # 3: la cinta, a mitad de camino
		_andar(30.0)
		var t := GaleriaClub.trazado(_e._est)
		_e.cuerpo.position.z = CityBuilder.ESTADIO_EN.z + float(t["zc"])
		_girar_a(PI / 2.0 * signf(float(t["xb"]) - float(t["xa"])) if float(t["xb"]) != float(t["xa"]) else 0.0)
		_andar(1.5)
	if _n == 32:
		_foto()                             # 4: el giro
		var t := GaleriaClub.trazado(_e._est)
		_e.cuerpo.position.x = CityBuilder.ESTADIO_EN.x + float(t["xb"])
		_girar_a(0.0)
	if _n == 38:
		_foto()                             # 5: al pie de la escalera mecánica
		_andar(4.0)
	if _n == 44:
		_e.cuerpo.position = GaleriaClub.boca_mundo(_e._est) + Vector3(-1.5, 0.2, 6.0)
		_girar_a(PI + 0.25)
		_e._colocar_camara(1.0)
	if _n == 50:
		_foto()                             # 6: en la calle, la caseta
		_e.set_physics_process(false)
		var b := GaleriaClub.boca_mundo(_e._est)
		_e.camara.position = b + Vector3(-9, 6, 12)
		_e.camara.look_at(b + Vector3(0, 1, -2), Vector3.UP)
	if _n == 56:
		_foto()                             # 7: la caseta desde fuera
		_e.camara.position = CityBuilder.ESTADIO_EN + Vector3(60, 45, 150)
		_e.camara.look_at(CityBuilder.ESTADIO_EN + Vector3(0, 0, 160), Vector3.UP)
	if _n == 62:
		_foto()                             # 8: aérea: estadio, campos y complejo
		## Y de vuelta abajo, desde la caseta.
		_e.set_physics_process(true)
		_e.rumbo = PI
		_e.cuerpo.position = GaleriaClub.boca_mundo(_e._est) + Vector3(0, 0.2, 1.2)
		_e.call("_buscar_cerca")
		print("CERCA ", _e._cerca)
		_e.call("_usar")
		_girar_a(PI)
	if _n == 68:
		_foto()                             # 9: bajando desde la calle
		var hoja := Image.create(480 * 3, 270 * 3, false, Image.FORMAT_RGBA8)
		for k in _imgs.size():
			hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 3) * 480, (k / 3) * 270))
		hoja.save_png("res://pruebas/capturas/galeria.png")
		print("HOJA OK")
		get_tree().quit()
