extends Node
## El metro a pie: andén elevado, dentro del tren (frente y ventana), andén
## subterráneo y viaje por el túnel.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_metro_usable.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n)
	print("FOTO ", n, " estado=", _e.estado if _e else "-")

func _parar_tren(linea: String, idx: int, k: int) -> void:
	var l := _e.metro.linea(linea)
	var t: MetroCiudad.Tren = l["trenes"][k]
	t.s = float(l["est_s"][idx])
	t.v = 0.0
	t.espera = 6.5

func _process(_d: float) -> void:
	_n += 1
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
		_e.call("_usar")
	if _n == 26:
		_foto("metro_3_dentro")
		_e.set("_ventana", true)
	if _n == 32:
		_foto("metro_4_ventana")
		_e.set("_ventana", false)
		var t: MetroCiudad.Tren = _e.metro.linea("Línea 1")["trenes"][0]
		t.espera = 0.0
	if _n == 60:
		_foto("metro_5_en_marcha")
		## A la línea 2: boca de «Plaza Mayor».
		_v.call("_dejar_de_explorar")
		_v.explorar("pie")
		_e = _v.get("_explorador")
		for a2: Dictionary in _e.metro.accesos:
			if String(a2["linea"]) == "Línea 2" and int(a2["idx"]) == 3:
				_e.call("_entrar_al_anden", a2)
				break
	if _n == 66:
		_parar_tren("Línea 2", 3, 1)
	if _n == 70:
		_foto("metro_6_anden_subterraneo")
		_e.call("_usar")
	if _n == 76:
		_foto("metro_7_dentro_tunel")
		var t2: MetroCiudad.Tren = _e.metro.linea("Línea 2")["trenes"][1]
		t2.espera = 0.0
	if _n == 110:
		_e.set("_ventana", true)
	if _n == 114:
		_foto("metro_8_tunel_ventana")
		get_tree().quit()
