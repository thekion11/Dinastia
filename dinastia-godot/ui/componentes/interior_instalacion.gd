class_name InteriorInstalacion
extends Control
## LAS INSTALACIONES POR DENTRO (7-10-2026, pedido: «crear las instalaciones
## por dentro con NPC trabajando»). Una sala 3D cerrada por tipo de lugar
## -oficina, hospital, comisaría, cuartel de bomberos, aula, estación, mercado,
## cine, tienda, gimnasio, sala de análisis, comedor, sala de prensa, museo y
## piscina- con sus muebles y su gente trabajando:
##   · puestos fijos: sentados al escritorio, detrás del mostrador, junto a una
##     cama... y de vez en cuando hacen un gesto (hablan, saludan, señalan);
##   · caminantes: van de un punto a otro de la sala, se paran y siguen.
## Se abre con E en la puerta de un lugar de la ciudad, o con «Ver por dentro»
## en la ficha de una instalación del club. La cámara gira sola; arrastrando
## se mueve y la rueda acerca. Todo con `Mini3D` en un mundo aparte.

signal cerrado

## Qué sala corresponde a cada lugar (ciudad y club).
const SALAS := {
	"ciudad_ayuntamiento": ["oficina", "Ayuntamiento"], "ciudad_hospital": ["hospital", "Hospital"],
	"ciudad_comisaria": ["comisaria", "Comisaría"], "ciudad_bomberos": ["bomberos", "Parque de bomberos"],
	"ciudad_escuela": ["aula", "Escuela"], "ciudad_instituto": ["aula", "Instituto"],
	"ciudad_universidad": ["aula", "Universidad"], "ciudad_estacion_central": ["estacion", "Estación Central"],
	"ciudad_mercado": ["mercado", "Mercado"], "ciudad_cine": ["cine", "Cine"],
	"ciudad_centro_comercial": ["tienda", "Centro Comercial"], "ciudad_gasolinera": ["tienda", "Tienda de la gasolinera"],
	"med": ["hospital", "Centro médico del club"], "rehab": ["hospital", "Centro de rehabilitación"],
	"gim": ["gimnasio", "Gimnasio y recuperación"], "ct": ["gimnasio", "Centro de entrenamiento"],
	"bienestar": ["gimnasio", "Espacio de bienestar"], "video": ["analisis", "Sala de video y análisis"],
	"esports": ["analisis", "Sala de juegos y e-sports"], "cocina": ["comedor", "Comedor y nutrición"],
	"pren": ["prensa", "Sala de prensa"], "museo": ["museo", "Museo del club"], "com": ["tienda", "Tienda del club"],
	"piscina": ["piscina", "Piscina de recuperación"], "acad": ["aula", "Academia juvenil"],
	"resid": ["comedor", "Residencia de canteranos"], "guarderia": ["aula", "Guardería y zona familiar"],
}

static func tiene(clave: String) -> bool:
	return SALAS.has(clave)

static func abrir(padre: Control, clave: String, club: Club = null, minijuego: Callable = Callable()) -> InteriorInstalacion:
	if not SALAS.has(clave):
		return null
	var n := InteriorInstalacion.new()
	n.clave = clave
	n.club = club
	n._minijuego = minijuego
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

var clave := ""
var club: Club
var tipo := ""
var _minijuego: Callable
var _rng := RandomNumberGenerator.new()
var _v := {}
var _cam: Camera3D
var _raiz: Node3D
var _tam := Vector3(30, 7, 20)
var _fijos: Array = []        ## {d, gestos, t}
var _caminantes: Array = []   ## {d, puntos, i, espera}
var _ang := 0.6
var _dist := 1.0
var _arrastre := false
var _girando := true
var _titulo: Label
var _c1 := Color(0.2, 0.45, 0.3)
var _c2 := Color.WHITE
var _gente := 0

func _montar() -> void:
	_rng.seed = hash(clave) + Time.get_ticks_msec()
	var sala: Array = SALAS[clave]
	tipo = String(sala[0])
	if club != null:
		_c1 = Color(club.color1)
		_c2 = Color(club.color2)
	_v = Mini3D.vista(self, Calidad.DIA)
	_cam = _v["cam"]
	_raiz = _v["raiz"]
	## Dentro no hay cielo: fondo oscuro, luz ambiente suave y lámparas.
	(_v["sol"] as DirectionalLight3D).visible = false
	for we in _raiz.get_children():
		if we is WorldEnvironment:
			var env: Environment = (we as WorldEnvironment).environment
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.05, 0.05, 0.06)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.85, 0.85, 0.9)
			env.ambient_light_energy = 0.55
			env.tonemap_exposure = 1.0
	match tipo:
		"oficina": _oficina()
		"hospital": _hospital()
		"comisaria": _comisaria()
		"bomberos": _bomberos()
		"aula": _aula()
		"estacion": _estacion()
		"mercado": _mercado()
		"cine": _cine()
		"tienda": _tienda()
		"gimnasio": _gimnasio()
		"analisis": _analisis()
		"comedor": _comedor()
		"prensa": _prensa()
		"museo": _museo()
		"piscina": _piscina()
	_interfaz(String(sala[1]))
	_colocar_camara()

# ------------------------------------------------------------------ la sala

func _sala(tam: Vector3, suelo: Color, pared: Color) -> void:
	_tam = tam
	Mini3D.caja(_raiz, Vector3(0, -0.1, 0), Vector3(tam.x, 0.2, tam.z), Mini3D.mat(suelo, 0.7))
	## Baldosas: un damero suave encima del suelo.
	var losa := Mini3D.mat(suelo.lightened(0.06), 0.7)
	var paso := 2.0
	for i in int(tam.x / paso):
		for j in int(tam.z / paso):
			if (i + j) % 2 == 0:
				Mini3D.caja(_raiz, Vector3(-tam.x * 0.5 + (float(i) + 0.5) * paso, 0.005, -tam.z * 0.5 + (float(j) + 0.5) * paso), Vector3(paso, 0.01, paso), losa)
	var m := Mini3D.mat(pared, 0.85)
	## Paredes del fondo y laterales; la de delante, baja, para ver dentro.
	Mini3D.caja(_raiz, Vector3(0, tam.y * 0.5, -tam.z * 0.5), Vector3(tam.x, tam.y, 0.3), m)
	for lado: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(lado * tam.x * 0.5, tam.y * 0.5, 0), Vector3(0.3, tam.y, tam.z), m)
	Mini3D.caja(_raiz, Vector3(0, 0.5, tam.z * 0.5), Vector3(tam.x, 1.0, 0.3), m)
	## Zócalo de otro tono y el techo con sus lámparas.
	var zocalo := Mini3D.mat(pared.darkened(0.25), 0.8)
	Mini3D.caja(_raiz, Vector3(0, 0.5, -tam.z * 0.5 + 0.17), Vector3(tam.x, 1.0, 0.05), zocalo)
	Mini3D.caja(_raiz, Vector3(0, tam.y + 0.1, -tam.z * 0.25), Vector3(tam.x, 0.2, tam.z * 0.5), Mini3D.mat(Color(0.92, 0.92, 0.9), 0.9))
	var lampara := Mini3D.mat(Color(1.0, 0.97, 0.9), 0.3, 2.2)
	for i in 3:
		for j in 2:
			var p := Vector3((float(i) - 1.0) * tam.x * 0.3, tam.y - 0.05, (float(j) - 0.5) * tam.z * 0.45)
			Mini3D.caja(_raiz, p, Vector3(2.4, 0.08, 0.6), lampara)
			var o := OmniLight3D.new()
			o.position = p - Vector3(0, 0.5, 0)
			o.omni_range = maxf(tam.x, tam.z) * 0.45
			o.light_energy = 0.9
			o.shadow_enabled = false
			_raiz.add_child(o)

func _cartel(texto: String, pos: Vector3, tam: int = 64, col: Color = Color.WHITE) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = tam
	l.pixel_size = 0.01
	l.modulate = col
	l.outline_size = 8
	l.outline_modulate = Color(0, 0, 0, 0.7)
	l.position = pos
	_raiz.add_child(l)

# ------------------------------------------------------------------ muebles

func _escritorio(p: Vector3, giro: float, con_pantalla: bool = true) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = giro
	_raiz.add_child(n)
	var madera := Mini3D.mat(Color(0.55, 0.4, 0.28), 0.6)
	Mini3D.caja(n, Vector3(0, 0.74, 0), Vector3(1.6, 0.06, 0.8), madera)
	for x: float in [-0.75, 0.75]:
		Mini3D.caja(n, Vector3(x, 0.37, 0), Vector3(0.06, 0.74, 0.75), madera)
	if con_pantalla:
		Mini3D.caja(n, Vector3(0, 1.05, -0.25), Vector3(0.6, 0.4, 0.04), Mini3D.mat(Color(0.08, 0.08, 0.1), 0.3))
		Mini3D.caja(n, Vector3(0, 1.05, -0.225), Vector3(0.55, 0.35, 0.01), Mini3D.mat(Color(0.3, 0.6, 0.95), 0.2, 1.0))
		Mini3D.caja(n, Vector3(0, 0.79, 0.1), Vector3(0.45, 0.02, 0.15), Mini3D.mat(Color(0.15, 0.15, 0.17), 0.4))
	## Papeles y una taza.
	Mini3D.caja(n, Vector3(0.5, 0.78, 0.15), Vector3(0.25, 0.02, 0.32), Mini3D.mat(Color(0.97, 0.97, 0.95), 0.8))
	Mini3D.cilindro(n, Vector3(-0.55, 0.82, 0.2), 0.05, 0.1, Mini3D.mat(Color(0.9, 0.3, 0.2), 0.4))

func _silla(p: Vector3, giro: float, col: Color = Color(0.2, 0.2, 0.25)) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = giro
	_raiz.add_child(n)
	var m := Mini3D.mat(col, 0.6)
	Mini3D.caja(n, Vector3(0, 0.45, 0), Vector3(0.5, 0.06, 0.5), m)
	Mini3D.caja(n, Vector3(0, 0.75, -0.24), Vector3(0.5, 0.6, 0.05), m)
	Mini3D.cilindro(n, Vector3(0, 0.22, 0), 0.03, 0.44, Mini3D.mat(Color(0.3, 0.3, 0.32), 0.3))

func _mostrador(p: Vector3, largo: float, giro: float, col: Color) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = giro
	_raiz.add_child(n)
	Mini3D.caja(n, Vector3(0, 0.55, 0), Vector3(largo, 1.1, 0.7), Mini3D.mat(col, 0.5))
	Mini3D.caja(n, Vector3(0, 1.12, 0), Vector3(largo + 0.1, 0.05, 0.8), Mini3D.mat(Color(0.9, 0.9, 0.88), 0.3))

func _estanteria(p: Vector3, giro: float, cosas: Color) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = giro
	_raiz.add_child(n)
	var m := Mini3D.mat(Color(0.45, 0.33, 0.22), 0.7)
	Mini3D.caja(n, Vector3(0, 1.1, 0), Vector3(2.0, 2.2, 0.05), m)
	for k in 4:
		Mini3D.caja(n, Vector3(0, 0.25 + float(k) * 0.6, 0.2), Vector3(2.0, 0.04, 0.4), m)
		for q in 7:
			var h := _rng.randf_range(0.2, 0.4)
			Mini3D.caja(n, Vector3(-0.85 + float(q) * 0.28, 0.27 + float(k) * 0.6 + h * 0.5, 0.2), Vector3(0.18, h, 0.28),
				Mini3D.mat(cosas.lerp(Color.from_hsv(_rng.randf(), 0.5, 0.8), 0.5), 0.6))

func _planta(p: Vector3) -> void:
	Mini3D.cilindro(_raiz, p + Vector3(0, 0.3, 0), 0.3, 0.6, Mini3D.mat(Color(0.6, 0.35, 0.2), 0.7), 0.24)
	Mini3D.esfera(_raiz, p + Vector3(0, 1.0, 0), 0.5, Mini3D.mat(Color(0.2, 0.5, 0.25), 0.9))

func _cama(p: Vector3, giro: float) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = giro
	_raiz.add_child(n)
	Mini3D.caja(n, Vector3(0, 0.5, 0), Vector3(1.0, 0.2, 2.1), Mini3D.mat(Color(0.95, 0.95, 0.97), 0.7))
	Mini3D.caja(n, Vector3(0, 0.62, -0.85), Vector3(0.7, 0.12, 0.35), Mini3D.mat(Color.WHITE, 0.8))
	Mini3D.caja(n, Vector3(0, 0.62, 0.3), Vector3(1.02, 0.06, 1.3), Mini3D.mat(Color(0.55, 0.75, 0.9), 0.8))
	for x: float in [-0.45, 0.45]:
		for z: float in [-0.95, 0.95]:
			Mini3D.cilindro(n, Vector3(x, 0.2, z), 0.03, 0.4, Mini3D.mat(Color(0.7, 0.7, 0.72), 0.3))
	## Monitor junto a la cama.
	Mini3D.cilindro(n, Vector3(0.75, 0.75, -0.9), 0.03, 1.5, Mini3D.mat(Color(0.7, 0.7, 0.72), 0.3))
	Mini3D.caja(n, Vector3(0.75, 1.5, -0.9), Vector3(0.4, 0.3, 0.06), Mini3D.mat(Color(0.1, 0.4, 0.2), 0.3, 1.0))

func _pantalla(p: Vector3, tam: Vector2, col: Color, giro: float = 0.0) -> MeshInstance3D:
	var mi := Mini3D.caja(_raiz, p, Vector3(tam.x, tam.y, 0.08), Mini3D.mat(col, 0.2, 1.4))
	mi.rotation.y = giro
	return mi

# ------------------------------------------------------------------ gente

## Alguien en su puesto: quieto (o sentado) y de vez en cuando un gesto.
func _trabajador(p: Vector3, giro: float, sentado: bool, gestos: Array = ["charla", "saludo_mano", "brazos_jarra", "pedir_calma"], deporte: Array = []) -> void:
	var d := Mini3D.persona(_raiz, _rng, p, deporte)
	if d.is_empty():
		return
	(d["nodo"] as Node3D).rotation.y = giro
	Mini3D.anim(d, "sentado" if sentado else "parado", "")
	(d["anim"] as AnimationPlayer).seek(_rng.randf() * 0.5, true)
	_fijos.append({"d": d, "gestos": [] if sentado else gestos, "t": _rng.randf_range(1.0, 5.0), "base": "sentado" if sentado else "parado"})

## Alguien que va y viene entre varios puntos de la sala.
func _caminante(puntos: Array, deporte: Array = [], correr: bool = false) -> void:
	## Cada uno con su desvío y empezando en un punto distinto del recorrido:
	## si no, iban todos en fila india.
	var desvio := Vector3(_rng.randf_range(-0.8, 0.8), 0, _rng.randf_range(-0.8, 0.8))
	var pts: Array = []
	for q: Vector3 in puntos:
		pts.append(q + desvio)
	var i := _rng.randi() % pts.size()
	var siguiente := (i + 1) % pts.size()
	var inicio: Vector3 = (pts[i] as Vector3).lerp(pts[siguiente], _rng.randf())
	var d := Mini3D.persona(_raiz, _rng, inicio, deporte)
	if d.is_empty():
		return
	Mini3D.anim(d, "trotar" if correr else "caminar", "")
	(d["anim"] as AnimationPlayer).seek(_rng.randf(), true)
	_caminantes.append({"d": d, "puntos": pts, "i": siguiente, "espera": 0.0, "vel": (3.2 if correr else 1.3) * _rng.randf_range(0.85, 1.15), "clip": "trotar" if correr else "caminar"})

func _process(delta: float) -> void:
	for f: Dictionary in _fijos:
		if (f["gestos"] as Array).is_empty():
			continue
		f["t"] = float(f["t"]) - delta
		if float(f["t"]) <= 0.0:
			f["t"] = _rng.randf_range(3.0, 7.0)
			var g: Array = f["gestos"]
			Mini3D.anim(f["d"], String(g[_rng.randi() % g.size()]), String(f["base"]))
	for c: Dictionary in _caminantes:
		var n: Node3D = c["d"]["nodo"]
		if float(c["espera"]) > 0.0:
			c["espera"] = float(c["espera"]) - delta
			if float(c["espera"]) <= 0.0:
				Mini3D.anim(c["d"], String(c["clip"]), "")
			continue
		var pts: Array = c["puntos"]
		var dest: Vector3 = pts[int(c["i"])]
		var dd := dest - n.position
		dd.y = 0.0
		if dd.length() < 0.2:
			c["i"] = (int(c["i"]) + 1) % pts.size()
			c["espera"] = _rng.randf_range(0.8, 3.0)
			Mini3D.anim(c["d"], ["parado", "charla", "saludo_mano"][_rng.randi() % 3], "parado")
			continue
		n.rotation.y = lerp_angle(n.rotation.y, atan2(dd.x, dd.z), clampf(delta * 6.0, 0.0, 1.0))
		n.position += dd.normalized() * minf(float(c["vel"]) * delta, dd.length())
	if _girando and not _arrastre:
		_ang += delta * 0.06
	_colocar_camara()

func _colocar_camara() -> void:
	if _cam == null:
		return
	var r := maxf(_tam.x, _tam.z) * 0.46 * _dist
	_cam.position = Vector3(sin(_ang) * r, _tam.y * 0.72 * _dist + 1.0, cos(_ang) * r)
	## Que no se salga del lado abierto de la sala: siempre por delante.
	if _cam.position.z < _tam.z * 0.2:
		_cam.position.z = _tam.z * 0.2 + absf(_cam.position.z - _tam.z * 0.2) * 0.3
	_cam.look_at(Vector3(0, 1.0, -_tam.z * 0.18), Vector3.UP)

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_arrastre = mb.pressed
			_girando = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist = clampf(_dist - 0.06, 0.55, 1.4)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist = clampf(_dist + 0.06, 0.55, 1.4)
		accept_event()
	elif ev is InputEventMouseMotion and _arrastre:
		_ang -= (ev as InputEventMouseMotion).relative.x * 0.005
		accept_event()
	elif ev is InputEventScreenDrag:
		_ang -= (ev as InputEventScreenDrag).relative.x * 0.005
		_girando = false
		accept_event()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		_cerrar()
		get_viewport().set_input_as_handled()

func _cerrar() -> void:
	cerrado.emit()
	queue_free()

func _interfaz(nombre: String) -> void:
	var banda := ColorRect.new()
	banda.color = Color(0, 0, 0, 0.5)
	banda.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banda.offset_bottom = 56
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banda)
	_titulo = Label.new()
	_titulo.text = "🚪 %s  ·  %d personas  ·  arrastra para girar, rueda para acercar, Esc para salir" % [nombre, _raiz.find_children("*", "Skeleton3D", true, false).size()]
	_titulo.add_theme_font_size_override("font_size", 20)
	_titulo.position = Vector2(20, 14)
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_titulo)
	var salir := Button.new()
	salir.text = "Salir"
	salir.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	salir.offset_left = -110
	salir.offset_right = -20
	salir.offset_top = 10
	salir.offset_bottom = 46
	salir.pressed.connect(_cerrar)
	add_child(salir)
	if _minijuego.is_valid():
		var jugar := Button.new()
		jugar.text = "🎮 Jugar aquí"
		jugar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		jugar.offset_left = -260
		jugar.offset_right = -120
		jugar.offset_top = 10
		jugar.offset_bottom = 46
		jugar.pressed.connect(func() -> void:
			var f := _minijuego
			_cerrar()
			f.call())
		add_child(jugar)

# ------------------------------------------------------------------ recetas

func _oficina() -> void:
	_sala(Vector3(30, 7, 20), Color(0.55, 0.45, 0.35), Color(0.9, 0.86, 0.78))
	_mostrador(Vector3(0, 0, -5.5), 12.0, 0.0, Color(0.45, 0.3, 0.2))
	for k in 4:
		var x := -4.5 + float(k) * 3.0
		_silla(Vector3(x, 0, -6.6), 0.0)
		_trabajador(Vector3(x, 0, -6.4), 0.0, true)
		Mini3D.caja(_raiz, Vector3(x, 1.25, -5.4), Vector3(0.5, 0.3, 0.04), Mini3D.mat(Color(0.3, 0.6, 0.95), 0.2, 0.9))
	## La cola de vecinos y el ordenanza que pasea.
	for k in 4:
		_trabajador(Vector3(-3.0 + float(k) * 2.0, 0, -3.6 + float(k % 2) * 0.4), PI, false, ["charla", "brazos_jarra", "cruzar_brazos"])
	_caminante([Vector3(-12, 0, 4), Vector3(12, 0, 4), Vector3(12, 0, -2), Vector3(-12, 0, -2)])
	for x: float in [-12.0, 12.0]:
		_planta(Vector3(x, 0, -8.5))
	for k in 3:
		var bandera := Mini3D.caja(_raiz, Vector3(-1.5 + float(k) * 1.5, 4.5, -9.6), Vector3(1.2, 1.8, 0.04), Mini3D.mat([Color(0.8, 0.1, 0.1), Color(0.95, 0.8, 0.1), _c1][k], 0.6))
		bandera.rotation.z = 0.05
	_cartel("🏛️ ATENCIÓN AL VECINO", Vector3(0, 3.0, -9.7))
	for k in 3:
		_escritorio(Vector3(-11.0, 0, -4.0 + float(k) * 3.0), PI * 0.5)
		_trabajador(Vector3(-12.0, 0, -4.0 + float(k) * 3.0), PI * 0.5, true)
		_silla(Vector3(-12.1, 0, -4.0 + float(k) * 3.0), PI * 0.5)

func _hospital() -> void:
	_sala(Vector3(30, 7, 20), Color(0.75, 0.82, 0.82), Color(0.92, 0.96, 0.96))
	for k in 6:
		var x := -12.0 + float(k) * 4.8
		_cama(Vector3(x, 0, -6.5), 0.0)
		_trabajador(Vector3(x - 0.2, 0.3, -6.9), PI, true)
		## Cortinas entre camas.
		Mini3D.caja(_raiz, Vector3(x + 2.4, 1.3, -6.5), Vector3(0.04, 2.2, 2.6), Mini3D.mat(Color(0.6, 0.8, 0.85, 0.8), 0.8))
	_mostrador(Vector3(6, 0, 3.0), 6.0, 0.0, Color(0.3, 0.55, 0.6))
	_trabajador(Vector3(6, 0, 2.1), 0.0, false, ["charla", "pedir_calma", "saludo_mano"], [Color(0.4, 0.7, 0.75), Color(0.4, 0.7, 0.75), true])
	_trabajador(Vector3(7.5, 0, 2.1), 0.0, false, ["charla", "senalar_cielo"], [Color(0.4, 0.7, 0.75), Color(0.4, 0.7, 0.75), true])
	## Médicos de bata que pasan de cama en cama.
	for k in 2:
		var pts: Array = []
		for q in 6:
			pts.append(Vector3(-12.0 + float(q) * 4.8, 0, -4.4 + float(k) * 0.6))
		if k == 1:
			pts.reverse()
		_caminante(pts, [Color(0.96, 0.96, 0.97), Color(0.3, 0.45, 0.7), true])
	_cartel("➕ PLANTA DE RECUPERACIÓN", Vector3(0, 4.6, -9.7), 64, Color(0.6, 1.0, 0.7))
	for x: float in [-13.0, 13.0]:
		_planta(Vector3(x, 0, 5.0))
	## Sillas de la sala de espera con pacientes.
	for k in 4:
		_silla(Vector3(-8.0 + float(k) * 1.2, 0, 4.5), PI)
		if k % 2 == 0:
			_trabajador(Vector3(-8.0 + float(k) * 1.2, 0, 4.3), PI, true)

func _comisaria() -> void:
	_sala(Vector3(28, 6.5, 18), Color(0.4, 0.42, 0.46), Color(0.78, 0.82, 0.86))
	for k in 4:
		var x := -9.0 + float(k) * 4.0
		_escritorio(Vector3(x, 0, -3.0), 0.0)
		_silla(Vector3(x, 0, -3.9), 0.0)
		_trabajador(Vector3(x, 0, -3.7), 0.0, true, [], [Color(0.1, 0.18, 0.35), Color(0.1, 0.12, 0.2), true])
	## La celda: rejas en una esquina.
	for k in 12:
		Mini3D.cilindro(_raiz, Vector3(7.0 + float(k) * 0.55, 1.6, -4.5), 0.04, 3.2, Mini3D.mat(Color(0.3, 0.3, 0.32), 0.3))
	Mini3D.caja(_raiz, Vector3(10.0, 3.2, -4.5), Vector3(6.6, 0.1, 0.1), Mini3D.mat(Color(0.3, 0.3, 0.32), 0.3))
	Mini3D.caja(_raiz, Vector3(10.0, 0.4, -8.0), Vector3(4.0, 0.5, 0.8), Mini3D.mat(Color(0.5, 0.5, 0.5), 0.8))
	_mostrador(Vector3(-4, 0, 3.0), 6.0, 0.0, Color(0.15, 0.25, 0.45))
	_trabajador(Vector3(-4, 0, 2.2), 0.0, false, ["charla", "senalar_falta", "brazos_jarra"], [Color(0.1, 0.18, 0.35), Color(0.1, 0.12, 0.2), true])
	_caminante([Vector3(-11, 0, 1), Vector3(5, 0, 1), Vector3(5, 0, -6), Vector3(-11, 0, -6)], [Color(0.1, 0.18, 0.35), Color(0.1, 0.12, 0.2), true])
	_cartel("🚔 COMISARÍA DEL DISTRITO", Vector3(0, 4.4, -8.7))
	for k in 3:
		_estanteria(Vector3(-12.0 + float(k) * 2.2, 0, -8.6), 0.0, Color(0.3, 0.35, 0.45))

func _bomberos() -> void:
	_sala(Vector3(32, 9, 22), Color(0.45, 0.45, 0.47), Color(0.85, 0.4, 0.35))
	## Las dos autobombas del kit.
	for k in 2:
		var cam := Mini3D.kit("res://assets/ciudad/kenney_cars/firetruck.glb")
		if cam != null:
			cam.scale = Vector3.ONE * 2.6
			cam.position = Vector3(-6.0 + float(k) * 9.0, 0, -3.0)
			cam.rotation.y = 0.0
			_raiz.add_child(cam)
	## Taquillas con los equipos y el poste para bajar.
	for k in 8:
		Mini3D.caja(_raiz, Vector3(-14.5, 1.1, -9.0 + float(k) * 1.1), Vector3(0.6, 2.2, 1.0), Mini3D.mat(Color(0.7, 0.72, 0.75), 0.4))
	Mini3D.cilindro(_raiz, Vector3(12, 4.5, -8), 0.08, 9.0, Mini3D.mat(Color(0.85, 0.75, 0.3), 0.2))
	var bombero := [Color(0.25, 0.22, 0.12), Color(0.9, 0.75, 0.1), true]
	_caminante([Vector3(-12, 0, 6), Vector3(12, 0, 6), Vector3(12, 0, 3), Vector3(-12, 0, 3)], bombero, true)
	_caminante([Vector3(9, 0, 4), Vector3(-9, 0, 4)], bombero)
	_trabajador(Vector3(-13.5, 0, -6.0), PI * 0.5, false, ["brazos_jarra", "charla"], bombero)
	_trabajador(Vector3(1.5, 0, 2.5), 0.0, false, ["senalar_cielo", "charla", "pedir_calma"], bombero)
	_trabajador(Vector3(11.0, 0, -6.5), -PI * 0.5, false, ["charla", "saludo_mano"], bombero)
	_cartel("🚒 PARQUE DE BOMBEROS", Vector3(0, 7.0, -10.7))
	## Mangueras enrolladas.
	for k in 3:
		var m := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.2
		tm.outer_radius = 0.5
		m.mesh = tm
		m.material_override = Mini3D.mat(Color(0.85, 0.2, 0.15), 0.6)
		m.position = Vector3(13.0, 1.0 + float(k) * 0.5, -2.0)
		m.rotation.z = PI * 0.5
		_raiz.add_child(m)

func _aula() -> void:
	var peques := clave == "ciudad_escuela" or clave == "guarderia"
	var uni := clave == "ciudad_universidad"
	_sala(Vector3(26, 6.5, 18), Color(0.6, 0.48, 0.34), Color(0.95, 0.9, 0.75) if peques else Color(0.85, 0.88, 0.9))
	## La pizarra y la mesa del profesor.
	Mini3D.caja(_raiz, Vector3(0, 2.4, -8.8), Vector3(9.0, 2.6, 0.08), Mini3D.mat(Color(0.12, 0.3, 0.2), 0.8))
	_cartel("2 + 2 = 4" if peques else ("∫ f(x) dx" if uni else "La Revolución Industrial"), Vector3(0, 2.6, -8.7), 72, Color(0.95, 0.95, 0.9))
	_escritorio(Vector3(-5.0, 0, -6.5), 0.0, uni)
	_caminante([Vector3(-4, 0, -7.5), Vector3(4, 0, -7.5)])
	## Pupitres en filas, con los alumnos sentados mirando a la pizarra.
	var filas := 4
	var cols := 5
	for i in filas:
		for j in cols:
			var p := Vector3(-8.0 + float(j) * 4.0, 0, -3.0 + float(i) * 2.6)
			_escritorio(p, PI, false)
			_silla(p + Vector3(0, 0, 0.75), PI, Color(0.2, 0.35, 0.65) if peques else Color(0.25, 0.25, 0.28))
			if _rng.randf() < 0.8:
				_trabajador(p + Vector3(0, 0, 0.9), PI, true)
	for k in 3:
		_estanteria(Vector3(12.5, 0, -6.0 + float(k) * 2.4), -PI * 0.5, Color(0.6, 0.4, 0.3))
	if peques:
		for k in 6:
			Mini3D.esfera(_raiz, Vector3(-11.5 + float(k) * 0.6, 0.25, 7.0), 0.25, Mini3D.mat(Color.from_hsv(float(k) / 6.0, 0.7, 0.95), 0.4))
	_cartel("🎓 " + String(SALAS[clave][1]).to_upper(), Vector3(0, 5.2, -8.7), 56)

func _estacion() -> void:
	_sala(Vector3(40, 10, 24), Color(0.62, 0.58, 0.52), Color(0.82, 0.76, 0.66))
	## El panel de salidas.
	Mini3D.caja(_raiz, Vector3(0, 6.0, -11.7), Vector3(12.0, 3.2, 0.2), Mini3D.mat(Color(0.05, 0.05, 0.06), 0.4))
	_cartel("SALIDAS\n10:15  Puerto      vía 2\n10:22  Alto Norte  vía 1\n10:30  Ribera      vía 3", Vector3(0, 6.0, -11.55), 44, Color(1.0, 0.8, 0.2))
	## Taquillas, bancos y el reloj.
	_mostrador(Vector3(-12, 0, -8.0), 8.0, 0.0, Color(0.35, 0.25, 0.18))
	for k in 3:
		_trabajador(Vector3(-14.5 + float(k) * 2.5, 0, -8.9), 0.0, true)
		_silla(Vector3(-14.5 + float(k) * 2.5, 0, -9.1), 0.0)
	for k in 4:
		var bp := Vector3(-6.0 + float(k) * 6.0, 0, 3.0)
		Mini3D.caja(_raiz, bp + Vector3(0, 0.45, 0), Vector3(3.0, 0.1, 0.6), Mini3D.mat(Color(0.5, 0.35, 0.2), 0.6))
		if k % 2 == 0:
			_trabajador(bp + Vector3(0.5, 0, 0.1), PI, true)
	var reloj := Mini3D.cilindro(_raiz, Vector3(14, 6.5, -11.6), 1.2, 0.15, Mini3D.mat(Color.WHITE, 0.4, 0.4))
	reloj.rotation.x = PI * 0.5
	## Viajeros que van y vienen con prisa.
	for k in 5:
		var z := -4.0 + float(k) * 1.6
		_caminante([Vector3(-18, 0, z), Vector3(18, 0, z + _rng.randf_range(-1, 1))], [], k % 3 == 0)
	_cartel("🚉 ESTACIÓN CENTRAL", Vector3(0, 8.6, -11.7))

func _mercado() -> void:
	_sala(Vector3(34, 9, 22), Color(0.5, 0.48, 0.44), Color(0.85, 0.8, 0.7))
	var colores := [Color(0.95, 0.5, 0.1), Color(0.85, 0.12, 0.1), Color(0.95, 0.85, 0.2), Color(0.3, 0.65, 0.2), Color(0.55, 0.2, 0.55)]
	for k in 6:
		var x := -12.5 + float(k) * 5.0
		var col: Color = colores[k % colores.size()]
		_mostrador(Vector3(x, 0, -4.0), 3.6, 0.0, Color(0.5, 0.35, 0.22))
		## Toldo y la fruta.
		Mini3D.caja(_raiz, Vector3(x, 3.0, -4.6), Vector3(4.0, 0.08, 2.0), Mini3D.mat(col.lightened(0.3), 0.7))
		for q in 14:
			Mini3D.esfera(_raiz, Vector3(x - 1.5 + float(q % 7) * 0.5, 1.25, -4.2 + float(q / 7) * 0.35), 0.16, Mini3D.mat(col, 0.5))
		_trabajador(Vector3(x, 0, -5.0), 0.0, false, ["saludo_mano", "charla", "aplaudir"])
	for k in 5:
		var z := -1.5 + float(k) * 1.4
		_caminante([Vector3(-15, 0, z), Vector3(15, 0, z)])
	_cartel("🍊 MERCADO DE ABASTOS", Vector3(0, 6.8, -10.7))

func _cine() -> void:
	_sala(Vector3(28, 9, 26), Color(0.3, 0.08, 0.1), Color(0.25, 0.1, 0.12))
	_pantalla(Vector3(0, 5.0, -12.6), Vector2(18.0, 7.0), Color(0.75, 0.85, 1.0))
	_cartel("🎬 ESTRENO", Vector3(0, 5.0, -12.5), 120, Color(0.1, 0.1, 0.2))
	## Filas de butacas en grada con el público sentado.
	for i in 6:
		var y := float(i) * 0.4
		Mini3D.caja(_raiz, Vector3(0, y * 0.5, -3.0 + float(i) * 2.0), Vector3(24, y + 0.05, 2.0), Mini3D.mat(Color(0.2, 0.06, 0.08), 0.8))
		for j in 10:
			var p := Vector3(-10.0 + float(j) * 2.2, y, -3.0 + float(i) * 2.0)
			_silla(p, PI, Color(0.6, 0.1, 0.12))
			if _rng.randf() < 0.45:
				_trabajador(p + Vector3(0, 0, 0.2), PI, true)
	_caminante([Vector3(-12.5, 0, 10), Vector3(-12.5, 0, -8), Vector3(12.5, 0, -8), Vector3(12.5, 0, 10)])

func _tienda() -> void:
	_sala(Vector3(30, 7, 20), Color(0.82, 0.82, 0.8), Color(0.95, 0.95, 0.95))
	var col := _c1 if clave == "com" else Color(0.2, 0.5, 0.8)
	for k in 5:
		_estanteria(Vector3(-11.0 + float(k) * 2.2, 0, -9.3), 0.0, col)
		_estanteria(Vector3(2.0 + float(k) * 2.2, 0, -9.3), 0.0, col.lerp(Color.WHITE, 0.4))
	## Islas centrales con camisetas o productos.
	for k in 3:
		var p := Vector3(-6.0 + float(k) * 6.0, 0, -2.5)
		Mini3D.caja(_raiz, p + Vector3(0, 0.5, 0), Vector3(3.0, 1.0, 1.6), Mini3D.mat(Color(0.35, 0.35, 0.38), 0.5))
		for q in 5:
			Mini3D.caja(_raiz, p + Vector3(-1.2 + float(q) * 0.6, 1.1, 0), Vector3(0.5, 0.15, 0.6), Mini3D.mat(_c1 if q % 2 == 0 else _c2, 0.7))
	_mostrador(Vector3(10, 0, 4.0), 5.0, PI * 0.5, Color(0.25, 0.25, 0.28))
	_trabajador(Vector3(11.0, 0, 4.0), -PI * 0.5, false, ["saludo_mano", "charla"])
	for k in 4:
		var z := 1.0 + float(k) * 1.3
		_caminante([Vector3(-12, 0, z), Vector3(6, 0, z), Vector3(6, 0, -5.5), Vector3(-12, 0, -5.5)])
	_cartel("🛍️ " + String(SALAS[clave][1]).to_upper(), Vector3(0, 5.2, -9.7), 56)

func _gimnasio() -> void:
	_sala(Vector3(30, 7.5, 20), Color(0.25, 0.25, 0.28), Color(0.85, 0.85, 0.88))
	var dep := [_c1, _c2]
	## Cintas de correr con jugadores trotando en el sitio.
	for k in 4:
		var p := Vector3(-10.0 + float(k) * 3.0, 0, -7.0)
		Mini3D.caja(_raiz, p + Vector3(0, 0.15, 0), Vector3(1.0, 0.3, 2.2), Mini3D.mat(Color(0.15, 0.15, 0.17), 0.4))
		Mini3D.caja(_raiz, p + Vector3(0, 1.1, -1.0), Vector3(0.9, 0.5, 0.1), Mini3D.mat(Color(0.2, 0.2, 0.22), 0.4))
		var d := Mini3D.persona(_raiz, _rng, p + Vector3(0, 0.3, 0.1), dep)
		if not d.is_empty():
			(d["nodo"] as Node3D).rotation.y = PI
			Mini3D.anim(d, "trotar", "")
	## Pesas, bancos y colchonetas.
	for k in 3:
		var p := Vector3(4.0 + float(k) * 3.5, 0, -6.0)
		Mini3D.caja(_raiz, p + Vector3(0, 0.45, 0), Vector3(0.5, 0.1, 1.8), Mini3D.mat(Color(0.15, 0.15, 0.17), 0.5))
		Mini3D.cilindro(_raiz, p + Vector3(0, 1.4, -0.6), 0.03, 1.8, Mini3D.mat(Color(0.7, 0.7, 0.72), 0.2)).rotation.z = PI * 0.5
		for x: float in [-0.85, 0.85]:
			Mini3D.cilindro(_raiz, p + Vector3(x, 1.4, -0.6), 0.25, 0.1, Mini3D.mat(Color(0.1, 0.1, 0.1), 0.4)).rotation.z = PI * 0.5
	for k in 4:
		Mini3D.caja(_raiz, Vector3(-9.0 + float(k) * 2.6, 0.04, 2.5), Vector3(2.2, 0.08, 1.2), Mini3D.mat(_c1.lightened(0.2), 0.8))
	_trabajador(Vector3(-6.0, 0, 3.6), PI, false, ["dominadas", "saltar_inicio", "cansado"], dep)
	_trabajador(Vector3(-1.0, 0, 3.6), PI, false, ["dominadas", "aplaudir"], dep)
	## El preparador físico, que va de máquina en máquina.
	_caminante([Vector3(-10, 0, -4.5), Vector3(10, 0, -4.5), Vector3(10, 0, 0), Vector3(-10, 0, 0)], [Color(0.15, 0.15, 0.18), Color(0.15, 0.15, 0.18), true])
	Mini3D.caja(_raiz, Vector3(14.8, 3.0, 0), Vector3(0.05, 4.0, 14.0), Mini3D.mat(Color(0.75, 0.85, 0.95), 0.05))
	_cartel("💪 " + String(SALAS[clave][1]).to_upper(), Vector3(0, 5.6, -9.7), 56)

func _analisis() -> void:
	_sala(Vector3(24, 6, 16), Color(0.18, 0.18, 0.22), Color(0.3, 0.32, 0.38))
	_pantalla(Vector3(0, 3.2, -7.8), Vector2(10.0, 4.2), Color(0.2, 0.55, 0.3))
	_cartel("⚽ 4-3-3  ·  presión alta" if clave == "video" else "🎮 TORNEO DEL CLUB", Vector3(0, 3.2, -7.7), 72)
	for i in 2:
		for j in 4:
			var p := Vector3(-6.0 + float(j) * 4.0, 0, -2.5 + float(i) * 3.2)
			_escritorio(p, 0.0)
			_silla(p + Vector3(0, 0, 0.8), PI)
			_trabajador(p + Vector3(0, 0, 0.95), PI, true, [], [_c1, _c2] if clave == "esports" else [])
	_caminante([Vector3(-8, 0, -6), Vector3(8, 0, -6)])
	_cartel("📊 " + String(SALAS[clave][1]).to_upper(), Vector3(0, 5.4, -7.8), 44)

func _comedor() -> void:
	_sala(Vector3(30, 7, 20), Color(0.7, 0.62, 0.5), Color(0.95, 0.92, 0.85))
	## La cocina al fondo con los cocineros.
	_mostrador(Vector3(0, 0, -7.5), 16.0, 0.0, Color(0.75, 0.75, 0.78))
	for k in 4:
		Mini3D.cilindro(_raiz, Vector3(-6.0 + float(k) * 4.0, 1.3, -7.5), 0.3, 0.35, Mini3D.mat(Color(0.6, 0.6, 0.62), 0.2))
	for k in 3:
		_trabajador(Vector3(-5.0 + float(k) * 5.0, 0, -8.6), 0.0, false, ["charla", "pedir_calma", "saludo_mano"], [Color.WHITE, Color(0.2, 0.2, 0.22), true])
	## Mesas con los jugadores comiendo.
	for i in 2:
		for j in 3:
			var p := Vector3(-8.0 + float(j) * 8.0, 0, -1.0 + float(i) * 5.0)
			Mini3D.caja(_raiz, p + Vector3(0, 0.74, 0), Vector3(4.0, 0.06, 1.4), Mini3D.mat(Color(0.6, 0.45, 0.3), 0.6))
			for q in 3:
				for lado: float in [-1.0, 1.0]:
					var ps := p + Vector3(-1.3 + float(q) * 1.3, 0, lado * 1.05)
					_silla(ps, 0.0 if lado > 0.0 else PI)
					Mini3D.cilindro(_raiz, ps + Vector3(0, 0.78, -lado * 0.6), 0.18, 0.03, Mini3D.mat(Color.WHITE, 0.4))
					if _rng.randf() < 0.6:
						_trabajador(ps + Vector3(0, 0, lado * 0.2), 0.0 if lado > 0.0 else PI, true, [], [_c1, _c2])
	_cartel("🥗 " + String(SALAS[clave][1]).to_upper(), Vector3(0, 5.2, -9.7), 52)

func _prensa() -> void:
	_sala(Vector3(26, 6.5, 18), Color(0.2, 0.22, 0.3), Color(0.25, 0.3, 0.45))
	## El panel de patrocinadores con los colores del club y la mesa.
	for i in 6:
		for j in 3:
			Mini3D.caja(_raiz, Vector3(-7.5 + float(i) * 3.0, 1.2 + float(j) * 1.4, -8.75), Vector3(2.9, 1.3, 0.05),
				Mini3D.mat(_c1 if (i + j) % 2 == 0 else _c2, 0.6))
	Mini3D.caja(_raiz, Vector3(0, 0.45, -6.5), Vector3(6.0, 0.9, 1.0), Mini3D.mat(Color(0.12, 0.12, 0.15), 0.5))
	for k in 2:
		_silla(Vector3(-1.2 + float(k) * 2.4, 0, -7.4), 0.0)
	_trabajador(Vector3(-1.2, 0, -7.2), 0.0, false, ["charla", "pedir_calma", "senalar_cielo"], [Color(0.1, 0.1, 0.12), Color(0.1, 0.1, 0.12), true])
	_trabajador(Vector3(1.2, 0, -7.2), 0.0, false, ["charla", "aplaudir"], [_c1, _c2])
	for k in 2:
		Mini3D.cilindro(_raiz, Vector3(-1.2 + float(k) * 2.4, 1.15, -6.3), 0.02, 0.4, Mini3D.mat(Color(0.1, 0.1, 0.1), 0.3))
	## Periodistas sentados con sus cámaras detrás.
	for i in 3:
		for j in 6:
			var p := Vector3(-6.25 + float(j) * 2.5, 0, -1.5 + float(i) * 2.2)
			_silla(p, PI, Color(0.2, 0.2, 0.25))
			_trabajador(p + Vector3(0, 0, 0.2), PI, true)
	for k in 3:
		var cp := Vector3(-5.0 + float(k) * 5.0, 0, 6.5)
		Mini3D.cilindro(_raiz, cp + Vector3(0, 0.75, 0), 0.04, 1.5, Mini3D.mat(Color(0.2, 0.2, 0.2), 0.4))
		Mini3D.caja(_raiz, cp + Vector3(0, 1.6, 0), Vector3(0.4, 0.35, 0.7), Mini3D.mat(Color(0.12, 0.12, 0.13), 0.4))
		_trabajador(cp + Vector3(0.6, 0, 0.6), PI, false, ["charla", "brazos_jarra"])

func _museo() -> void:
	_sala(Vector3(32, 8, 22), Color(0.4, 0.3, 0.25), Color(0.18, 0.18, 0.2))
	## Vitrinas con trofeos dorados y camisetas históricas colgadas.
	var oro := Mini3D.mat(Color(0.95, 0.75, 0.25), 0.25)
	oro.metallic = 0.9
	var vidrio := Mini3D.mat(Color(0.8, 0.9, 1.0, 0.25), 0.05)
	for k in 5:
		var p := Vector3(-10.0 + float(k) * 5.0, 0, -3.0)
		Mini3D.caja(_raiz, p + Vector3(0, 0.5, 0), Vector3(1.6, 1.0, 1.6), Mini3D.mat(Color(0.12, 0.12, 0.14), 0.5))
		Mini3D.caja(_raiz, p + Vector3(0, 1.6, 0), Vector3(1.5, 1.2, 1.5), vidrio)
		Mini3D.cilindro(_raiz, p + Vector3(0, 1.3, 0), 0.12, 0.5, oro)
		Mini3D.esfera(_raiz, p + Vector3(0, 1.7, 0), 0.22, oro)
		var foco := SpotLight3D.new()
		foco.position = p + Vector3(0, 6.5, 0)
		foco.rotation.x = -PI * 0.5
		foco.light_energy = 3.0
		foco.spot_range = 8.0
		foco.spot_angle = 20.0
		_raiz.add_child(foco)
	for k in 6:
		Mini3D.caja(_raiz, Vector3(-12.5 + float(k) * 5.0, 3.5, -10.8), Vector3(1.6, 2.0, 0.05), Mini3D.mat(_c1 if k % 2 == 0 else _c2, 0.7))
	for k in 4:
		var z := 1.5 + float(k) * 1.6
		_caminante([Vector3(-13, 0, z), Vector3(-5, 0, -1.2), Vector3(5, 0, -1.2), Vector3(13, 0, z)])
	_trabajador(Vector3(13.5, 0, 6.0), -PI * 0.5, false, ["charla", "saludo_mano"], [Color(0.15, 0.15, 0.2), Color(0.15, 0.15, 0.2), true])
	_cartel("🏆 MUSEO DEL CLUB", Vector3(0, 6.2, -10.7), 72, Color(1.0, 0.85, 0.4))

func _piscina() -> void:
	_sala(Vector3(32, 8, 22), Color(0.85, 0.88, 0.9), Color(0.75, 0.88, 0.92))
	var agua := Mini3D.caja(_raiz, Vector3(0, 0.02, -2.0), Vector3(20.0, 0.05, 10.0), Mini3D.mat(Color(0.2, 0.6, 0.85, 0.85), 0.05, 0.2))
	agua.name = "Agua"
	for k in 5:
		Mini3D.caja(_raiz, Vector3(0, 0.06, -6.0 + float(k) * 2.0), Vector3(20.0, 0.04, 0.08), Mini3D.mat(Color(0.95, 0.85, 0.2), 0.5))
	## Jugadores en el agua (hasta la cintura) y el fisio en el borde.
	for k in 4:
		var d := Mini3D.persona(_raiz, _rng, Vector3(-7.0 + float(k) * 4.5, -0.9, -2.0 + float(k % 2) * 2.0), [_c1, _c2])
		if not d.is_empty():
			Mini3D.anim(d, ["caminar", "parado", "saltar_inicio", "caminar"][k], "")
	_trabajador(Vector3(0, 0, 4.5), PI, false, ["aplaudir", "charla", "pedir_calma"], [Color.WHITE, Color(0.2, 0.4, 0.7), true])
	for k in 4:
		Mini3D.caja(_raiz, Vector3(-9.0 + float(k) * 6.0, 0.4, 7.5), Vector3(1.8, 0.15, 0.7), Mini3D.mat(Color(0.95, 0.95, 0.95), 0.6))
	_cartel("🏊 PISCINA DE RECUPERACIÓN", Vector3(0, 5.6, -10.7))
