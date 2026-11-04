extends Node
## PASADAS VISUALES DE LA CIUDAD (4-11-2026): una toma aérea y una a pie por zona (centro, barrios, estadio por fuera, transporte), con la cámara del explorador.
##   FASE=antes|despues NIVEL=minimo|medio OUT=/ruta  herramientas/captura.sh res://pruebas/captura_pasada_ciudad.tscn   (Forward+; las PNG salen en OUT como pas_<FASE>_<zona>_<aerea|pie>.png)
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _cola: Array = []   ## [nombre, pos_cam, mira]
var _i := 0
var _k := 0
var _out := "/tmp"
var _fase_nombre := "antes"
var _nivel := "medio"
var _fase := 0

func _ready() -> void:
	process_priority = 1000
	_nivel = OS.get_environment("NIVEL") if OS.get_environment("NIVEL") != "" else "medio"
	_out = OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp"
	_fase_nombre = OS.get_environment("FASE") if OS.get_environment("FASE") != "" else "antes"
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/pas_%s_%s_%s.png" % [_out, _nivel, _fase_nombre, n])
	print("FOTO ", n)

## Aérea: 55 m de alto y 75 de retranqueo; a pie: a 1,7 m desde el borde de la manzana mirando a su centro.
func _zona(nombre: String, centro: Vector3, fuera := Vector3(0, 0, -1)) -> void:
	_cola.append([nombre + "_aerea", centro + fuera.normalized() * 75.0 + Vector3(0, 55.0, 0), centro])
	_cola.append([nombre + "_pie", centro + fuera.normalized() * 26.0 + Vector3(0, 1.7, 0), centro + Vector3(0, 4.0, 0)])

func _process(_d: float) -> void:
	_n += 1
	if _n == 3 or _n == 6:
		Calidad.elegida = Calidad.MINIMO if _nivel == "minimo" else Calidad.MEDIO
	if _n == 6:
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
		var ex = _e.cb.expansion
		var por_uso := {}
		for bl: Dictionary in ex.bloques:
			var u := String(bl["uso"])
			if not por_uso.has(u):
				por_uso[u] = []
			por_uso[u].append(bl)
		print("USOS ", por_uso.keys())
		for u in ["plaza_mayor", "ayuntamiento", "mercado", "comercial", "torres", "pisos", "casas", "industrial", "parque", "gasolinera", "puerto"]:
			if por_uso.has(u):
				var bl: Dictionary = (por_uso[u] as Array)[0]
				var c2: Vector2 = (bl["rect"] as Rect2).get_center()
				_zona(("centro_" if u in ["plaza_mayor", "ayuntamiento", "mercado", "comercial", "torres"] else "barrio_") + u, Vector3(c2.x, 0.0, c2.y), Vector3(0, 0, -1))
		_zona("estadio_fuera", CityBuilder.ESTADIO_EN + Vector3(0, 0, 0), Vector3(0, 0, -1) * 1.9)
		for pa in get_tree().get_nodes_in_group("paradero_red").slice(0, 1):
			_zona("transporte_paradero", (pa as Node3D).global_position, Vector3(0.5, 0, 0.8))
		if _e.metro != null and not _e.metro.accesos.is_empty():
			_zona("transporte_metro", _e.metro.accesos[0]["pie"], Vector3(0.6, 0, 0.8))
		var solo := OS.get_environment("SOLO")
		if solo != "":
			_cola = _cola.filter(func(s): return String(s[0]).contains(solo))
		_fase = 1
	if _fase == 1 and _i < _cola.size():
		var s: Array = _cola[_i]
		_e.camara.global_position = s[1]
		_e.camara.look_at(s[2], Vector3.UP)
		_k += 1
		if _k == 4:
			_foto(String(s[0]))
			_i += 1
			_k = 0
		return
	if _fase == 1:
		get_tree().quit()
