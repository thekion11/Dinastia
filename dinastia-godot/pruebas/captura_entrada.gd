extends Node
## LA ENTRADA DEL CLUB CON PORTERO (8-10-2026). Hoja: `pruebas/capturas/entrada.png`.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/captura_entrada.tscn
var _t := 0.0
var _paso := 0
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
	print("FOTO ", _imgs.size(), " estado=", _e.estado, " zona=", _e._zona_est, " pos=", _e.cuerpo.position, " aviso=", _e._aviso.text, " abierta=", EntradaClub.abierta(get_tree()))

func _andar(seg: float) -> void:
	_e._tactil_vec = Vector2(0, 1)
	for i in int(seg * 30.0):
		_e._physics_process(1.0 / 30.0)
	_e._tactil_vec = Vector2.ZERO

## Cada paso espera `seg` segundos de verdad (las puertas y los gestos van
## con su propio tiempo).
func _process(d: float) -> void:
	_t += d
	var pasos := [1.5, 1.0, 1.0, 1.0, 0.6, 1.4, 1.6, 1.0, 1.0, 1.4, 1.2, 0.5]
	if _paso >= pasos.size() or _t < float(pasos[_paso]):
		return
	_t = 0.0
	_paso += 1
	match _paso:
		1:
			_p.call("_ver_ciudad_propia")
			for h in _p.get_children():
				if h is VistaCiudad:
					_v = h
			_v.set("_ciclo_activo", false)
			_v.set("_hora", 10.5)
			_v.call("_aplicar_hora")
			_v.explorar("pie")
			_e = _v.get("_explorador")
			var pu: Vector3 = CityBuilder.ESTADIO_EN + (_e._est["puerta"] as Vector3)
			_e.cuerpo.position = pu + Vector3(-1.0, 0.2, 9.5)
			_e.rumbo = PI + 0.15
			_e._colocar_camara(1.0)
		2:
			_foto()                         # 1: la entrada desde la calle
			_andar(5.6)
			_e._colocar_camara(1.0)
		3:
			_e.call("_buscar_cerca")
			_foto()                         # 2: delante, el portero
			_e.call("_usar")                # hablar con el portero
		4:
			_foto()                         # 3: el diálogo
			for b in _e._menu_asc.find_children("*", "Button", true, false):
				if (b as Button).text.begins_with("🚪"):
					(b as Button).pressed.emit()
		5:
			_e._colocar_camara(1.0)
		6:
			_foto()                         # 4: abre y saluda
		7:
			_foto()                         # 5: entrando
		8:
			_foto()                         # 6: dentro, la puerta se cierra
			_e.rumbo = 0.0
			_andar(1.5)
		9:
			_foto()                         # 7: saliendo
			_andar(1.0)
		10:
			_e.rumbo = PI
			_e._colocar_camara(1.0)
		11:
			_foto()                         # 8: el portero se despide
			_e.set_physics_process(false)
			var pu2: Vector3 = CityBuilder.ESTADIO_EN + (_e._est["puerta"] as Vector3)
			_e.camara.position = pu2 + Vector3(9, 6, 13)
			_e.camara.look_at(pu2 + Vector3(0, 2, 0), Vector3.UP)
		12:
			_foto()                         # 9: la entrada en conjunto
			var hoja := Image.create(480 * 3, 270 * 3, false, Image.FORMAT_RGBA8)
			for k in _imgs.size():
				hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 3) * 480, (k / 3) * 270))
			hoja.save_png("res://pruebas/capturas/entrada.png")
			print("HOJA OK")
			get_tree().quit()
