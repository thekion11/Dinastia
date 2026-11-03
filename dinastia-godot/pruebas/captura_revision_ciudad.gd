extends Node
## REVISIÓN VISUAL de lo de la ciudad del 3-11 (carteles de fachada, tienda deportiva, ropero en el DT, rincón de la casa, peajes), con cámaras colocadas a mano.
##   NIVEL=minimo|medio OUT=/ruta  xvfb-run -a godot --path . --rendering-driver vulkan --resolution 1280x720 res://pruebas/captura_revision_ciudad.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _cola: Array = []   ## [nombre, pos_cam, mira] o [nombre, "natural", rumbo, pos_cuerpo]
var _i := 0
var _k := 0
var _out := "/tmp"
var _nivel := "medio"
var _fase := 0

func _ready() -> void:
	process_priority = 1000
	_nivel = OS.get_environment("NIVEL") if OS.get_environment("NIVEL") != "" else "medio"
	_out = OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp"
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/rev_%s_%s.png" % [_out, _nivel, n])
	print("FOTO ", n)

func _etiqueta(clave: String) -> Label3D:
	for l in _v.get("_ciudad").find_children("*", "Label3D", true, false):
		if (l as Label3D).billboard == BaseMaterial3D.BILLBOARD_FIXED_Y and (l as Label3D).text.contains(clave):
			return l
	return null

func _cartel(nombre: String, clave: String, dist: float = 16.0) -> void:
	var l := _etiqueta(clave)
	if l == null:
		print("SIN CARTEL ", clave)
		return
	var g := l.global_position
	_cola.append([nombre, g + Vector3(2.0, 2.5 - g.y * 0.55, dist), g])

func _process(_d: float) -> void:
	_n += 1
	if _n == 3:
		Calidad.elegida = Calidad.MINIMO if _nivel == "minimo" else Calidad.MEDIO
	if _n == 6:
		Calidad.elegida = Calidad.MINIMO if _nivel == "minimo" else Calidad.MEDIO
		var m: Mundo = _p.get("mundo")
		for id in ["camiseta_club", "gorra_club", "bufanda_club", "botines", "balon", "balon_playa"]:
			RoperoDT.agregar(m.roles.ropero, id)
		var club := m.mi_club()
		var asp := PersonajeDT.aspecto(m.roles.aspecto_3d())
		for id in ["camiseta_club", "gorra_club", "bufanda_club"]:
			asp = RoperoDT.aplicar(asp, id, Color(club.color1), Color(club.color2))
		m.roles.look["p3d"] = asp
		PersonajeDT.del_usuario = asp   ## lo que hace `PersonajeDatos.aplicar_aspecto` al guardar en «Mi personaje»
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 13.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_e = _v.get("_explorador")
		return
	if _n < 14 or _e == null:
		return
	if _n == 14:
		var tp := Vector3.ZERO
		for pc: Dictionary in _e.cb.puntos_clic:
			if String(pc.get("k", "")).begins_with("deportes_"):
				tp = pc["pos"]
		_cola.append(["dt_ropero", "natural", PI, _e.cuerpo.position])
		_cola.append(["plaza_tienda_pie", "natural", PI, tp + Vector3(0, 0.2, 10.0)])
		_cartel("c_peaje", "PEAJE", 14.0)
		_cartel("c_tienda_banco", "DEPORTIVA", 14.0)
		_cartel("c_gasolinera", "Gasolina", 22.0)
		_cartel("c_lavado", "LAVADO", 18.0)
		_cartel("c_karting", "Karting", 30.0)
		_cartel("c_parque", "🌳", 30.0)
		_cartel("c_atracciones", "atracciones", 40.0)
		_cartel("c_rusa", "Montaña", 30.0)
		_cartel("c_puente", "🌉", 30.0)
		_cartel("c_puerto", "Puerto", 30.0)
		_cartel("c_casa_grande", "Casa Grande", 40.0)
		_cartel("c_vip", "VIP", 18.0)
		_cartel("c_autopista", "Autopista", 40.0)
		var solo := OS.get_environment("SOLO")   ## SOLO=a,b: solo esas tomas
		if solo != "":
			_cola = _cola.filter(func(s): return String(s[0]) in solo.split(","))
		_fase = 1
	if _fase == 1 and _i < _cola.size():
		var s: Array = _cola[_i]
		if typeof(s[1]) == TYPE_STRING:
			if _k == 0:
				_e.cuerpo.position = s[3]
				_e.rumbo = float(s[2])
				_e.cuerpo.rotation.y = _e.rumbo
			_k += 1
			if _k == 8:
				_foto(String(s[0]))
				_i += 1
				_k = 0
		else:
			_e.camara.global_position = s[1]
			_e.camara.look_at(s[2], Vector3.UP)
			_k += 1
			if _k == 3:
				_foto(String(s[0]))
				_i += 1
				_k = 0
		return
	if _fase == 1:
		_fase = 2
		_k = 0
		if _e.vida == null:
			_e.vida = VidaCiudad.enganchar(_e, _v, _p.get("mundo"))
		_e.vida.entrar_casa()
		return
	if _fase == 2:
		_k += 1
		if _k < 20:
			return
		var base := _e._INT_ORIGEN + RoperoCasa.BASE
		_e.camara.global_position = base + Vector3(2.6, 2.4, -2.6)
		_e.camara.look_at(base + Vector3(-0.4, 0.5, 0.2), Vector3.UP)
		if _k == 24:
			_foto("casa_rincon")
			get_tree().quit()
