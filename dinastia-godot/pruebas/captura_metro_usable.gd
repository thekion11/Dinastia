extends Node
## El metro a pie: andén elevado (con su gente y sus máquinas), el tren por
## fuera y por dentro (frente y ventana), andén subterráneo y viaje por el túnel.
##   herramientas/captura.sh res://pruebas/captura_metro_usable.tscn
##   PREFIJO=metro_antes  -> otro nombre para las fotos (antes/después).
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
## Cámara fija (se aplica DESPUÉS del explorador, que mueve la suya cada fotograma).
var _cam_pos := Vector3.ZERO
var _cam_mira := Vector3.ZERO
var _cam_fija := false

func _ready() -> void:
	process_priority = 1000
	## Que el tutorial de la ciudad no tape las fotos.
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n.replace("metro", OS.get_environment("PREFIJO") if OS.has_environment("PREFIJO") else "metro"))
	print("FOTO ", n, " estado=", _e.estado if _e else "-")

func _parar_tren(linea: String, idx: int, k: int) -> void:
	var l := _e.metro.linea(linea)
	var t: MetroCiudad.Tren = l["trenes"][k]
	t.s = float(l["est_s"][idx])
	t.v = 0.0
	t.espera = 6.5

## Un punto del andén donde está el jugador: `db` desde la vía hacia la pared,
## `f` a lo largo, `h` de altura sobre el suelo del andén.
func _en_anden(db: float, f: float, h: float) -> Vector3:
	var c: Vector3 = _e.get("_anden_c")
	var lat: Vector3 = _e.get("_anden_lat")
	var lon: Vector3 = _e.get("_anden_lon")
	var est: Vector3 = _e.metro.linea(String(_e.get("_linea")))["estaciones"][int(_e.get("_idx"))]
	var hacia_pared := lat * signf((c - est).dot(lat))
	var borde := est + hacia_pared * 2.0
	return Vector3(borde.x, c.y, borde.z) + hacia_pared * db + lon * f + Vector3(0, h, 0)

func _fijar(pos: Vector3, mira: Vector3) -> void:
	_cam_pos = pos
	_cam_mira = mira
	_cam_fija = true

func _process(_d: float) -> void:
	_n += 1
	if _cam_fija and _e != null:
		_e.camara.global_position = _cam_pos
		_e.camara.look_at(_cam_mira, Vector3.UP)
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 15.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_e = _v.get("_explorador")
		## Al pie de la escalera de la estación «Cine» (L1, idx 2).
		for a: Dictionary in _e.metro.accesos:
			if String(a["linea"]) == "Línea 1" and int(a["idx"]) == 2:
				_e.cuerpo.position = a["pie"] + Vector3(0, 0.2, 0)
				break
	if _n == 10:
		_e.call("_buscar_cerca")
		_foto("metro_1_escalera")
		_e.call("_usar")
	if _n == 16:
		_parar_tren("Línea 1", 2, 0)
	if _n == 20:
		_foto("metro_2_anden")
	## La gente del andén aparece de una en una: se espera a que estén todos.
	if _n == 44:
		_fijar(_en_anden(1.2, 27.0, 1.7), _en_anden(1.6, 0.0, 0.9))
	if _n == 48:
		_foto("metro_2b_anden_gente")
		_fijar(_en_anden(1.4, -1.0, 1.5), _en_anden(3.4, -8.0, 0.7))
	if _n == 52:
		_foto("metro_2c_bancos")
		_fijar(_en_anden(1.9, -16.0, 1.6), _en_anden(3.4, -26.0, 1.0))
	if _n == 56:
		_foto("metro_2d_maquinas")
		var tren: Node3D = _e.metro.linea("Línea 1")["nodos"][0]
		_fijar(tren.global_transform * Vector3(3.2, 2.4, 31.0), tren.global_transform * Vector3(0.0, 1.8, 22.0))
	if _n == 60:
		_foto("metro_2e_tren_frente")
		_cam_fija = false
		_parar_tren("Línea 1", 2, 0)
		_e.call("_usar")
	if _n == 66:
		_foto("metro_3_dentro")
		_e.set("_ventana", true)
	if _n == 72:
		_foto("metro_4_ventana")
		_e.set("_ventana", false)
		var t: MetroCiudad.Tren = _e.metro.linea("Línea 1")["trenes"][0]
		t.espera = 0.0
	if _n == 100:
		_foto("metro_5_en_marcha")
		## A la línea 2: boca de «Plaza Mayor».
		_v.call("_dejar_de_explorar")
		_v.explorar("pie")
		_e = _v.get("_explorador")
		for a2: Dictionary in _e.metro.accesos:
			if String(a2["linea"]) == "Línea 2" and int(a2["idx"]) == 3:
				_e.call("_entrar_al_anden", a2)
				break
	if _n == 106:
		_parar_tren("Línea 2", 3, 1)
	if _n == 110:
		_foto("metro_6_anden_subterraneo")
	if _n == 130:
		_fijar(_en_anden(1.0, 28.0, 1.7), _en_anden(3.5, 0.0, 1.0))
	if _n == 134:
		_foto("metro_6b_subterraneo_gente")
		_cam_fija = false
		_parar_tren("Línea 2", 3, 1)
		_e.call("_usar")
	if _n == 140:
		_foto("metro_7_dentro_tunel")
		var t2: MetroCiudad.Tren = _e.metro.linea("Línea 2")["trenes"][1]
		t2.espera = 0.0
	if _n == 174:
		_e.set("_ventana", true)
	if _n == 178:
		_foto("metro_8_tunel_ventana")
		get_tree().quit()
