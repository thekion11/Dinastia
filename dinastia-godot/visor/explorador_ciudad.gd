class_name ExploradorCiudad
extends Node3D
## RECORRER LA CIUDAD (7-10-2026, pedido: «la ciudad debe ser real,
## interactiva… conducir, caminar, interactuar con NPC»). Dos modos:
##
##  · CONDUCIR: un coche del kit con conducción arcade (W/S o flechas para
##    acelerar y frenar, A/D para girar, o el mando). Choca con las manzanas y
##    con el río, y sube a los puentes por sus rampas.
##  · A PIE: un peatón animado del paquete Quaternius (W/A/S/D, Mayús para
##    correr). Puede entrar en parques y plazas, no atravesar edificios.
##
## En los dos: cámara de seguimiento detrás, «E» para HABLAR con el peatón
## más cercano (te dice algo según cómo va el club) o para ENTRAR en el lugar
## que tengas delante (instalaciones, estadio, Casa Grande, minijuegos de la
## ciudad), y «Esc» para volver al mapa. La lógica de colisión es pura
## (`libre`) para poder probarla sin dibujar nada.

signal salir
signal interactuar(k: String)

const RADIO_COCHE := 2.2
const RADIO_PIE := 0.5
const VEL_COCHE := 26.0
const VEL_PIE := 1.7
const VEL_CORRER := 5.0
const LIMITE := 1480.0

var modo := "coche"
var cb: CityBuilder
var trafico: TraficoCiudad
var club_nombre := ""
var animo := "normal"
var cuerpo: Node3D
var camara: Camera3D
var rumbo := 0.0        ## ángulo en Y (0 = mirando a +Z)
var vel := 0.0
var obstaculos: Array[Rect2] = []
var _anim: AnimationPlayer
var _hud: Label
var _aviso: Label
var _cerca := {}        ## lo que hay delante para la E: {tipo, k, n, peaton}
var _burbuja: Label3D
var _t_burbuja := 0.0

const FRASES := {
	"euforia": ["¡Campeones! ¡Esta ciudad es de %s!", "No me lo creo todavía… ¡qué temporada!", "Mi abuelo lloró con el último gol. Gracias, míster."],
	"bien": ["Vamos bien, míster. Que no se nos suba.", "El sábado voy con mis hijos al estadio.", "Ese chico de la cantera va a ser crack."],
	"normal": ["Ni fu ni fa. A ver si fichamos a alguien.", "¿Usted es el entrenador de %s? ¡Una foto!", "El tráfico los días de partido es un horror."],
	"mal": ["Así no, míster. Así no.", "Mi cuñado dice que lo van a echar…", "Hay que meter más carácter."],
	"crisis": ["¡Fuera! Bueno… perdón, es la rabia.", "Esto es una vergüenza para %s.", "Ni regalando entradas se llena el estadio."],
}

func iniciar(builder: CityBuilder, modo_: String, desde: Vector3, club: String, estado_animo: String) -> void:
	cb = builder
	modo = modo_
	club_nombre = club
	animo = estado_animo
	trafico = cb.get_node_or_null("Trafico") as TraficoCiudad
	obstaculos = construir_obstaculos(cb)
	position = Vector3.ZERO
	cuerpo = _crear_cuerpo()
	add_child(cuerpo)
	cuerpo.position = buscar_libre(desde)
	camara = Camera3D.new()
	camara.fov = 65.0
	camara.far = 5000.0
	add_child(camara)
	camara.make_current()
	_burbuja = Label3D.new()
	_burbuja.font_size = 40
	_burbuja.pixel_size = 0.012
	_burbuja.outline_size = 8
	_burbuja.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_burbuja.visible = false
	add_child(_burbuja)
	_montar_hud()
	_colocar_camara(1.0)

## Las huellas sólidas: manzanas edificadas, edificios del núcleo e
## instalaciones (todo lo que `CityBuilder` apunta en `_frentes`).
static func construir_obstaculos(b: CityBuilder) -> Array[Rect2]:
	var sal: Array[Rect2] = []
	for r: Rect2 in b._frentes:
		sal.append(r)
	for r2: Rect2 in b.huellas:
		sal.append(r2)
	return sal

## ¿Puede estar aquí algo de este radio? (manzanas, río sin puente, límites).
static func libre(p: Vector3, radio: float, obst: Array[Rect2]) -> bool:
	if absf(p.x) > LIMITE or absf(p.z) > LIMITE:
		return false
	if en_rio(p.x, p.z) and not en_puente(p.x, p.z):
		return false
	for r: Rect2 in obst:
		if p.x > r.position.x - radio and p.x < r.end.x + radio and p.z > r.position.y - radio and p.z < r.end.y + radio:
			return false
	return true

static func en_rio(x: float, z: float) -> bool:
	return absf(x - CityBuilder.RIO_X) < 50.0 and absf(z) < 1360.0

## Sobre el tablero o las rampas de un puente (calles horizontales de la rejilla).
static func en_puente(x: float, z: float) -> bool:
	var linea := snappedf(z, CiudadExpansion.CELDA)
	return absf(z - linea) < CiudadExpansion.ANCHO_AV * 0.5 - 1.0 and absf(x - CityBuilder.RIO_X) < 66.0

## La altura del suelo (sube por las rampas de los puentes).
static func altura_suelo(x: float, z: float) -> float:
	if not en_puente(x, z):
		return 0.2
	var dx := absf(x - CityBuilder.RIO_X)
	if dx <= 44.0:
		return CiudadExpansion.PUENTE_ALTO + 0.3
	if dx >= 64.0:
		return 0.2
	return lerpf(CiudadExpansion.PUENTE_ALTO + 0.3, 0.2, (dx - 44.0) / 20.0)

func buscar_libre(desde: Vector3) -> Vector3:
	var r := RADIO_COCHE if modo == "coche" else RADIO_PIE
	for k in 400:
		var ang := float(k) * 0.7
		var d := float(k) * 2.0
		var p := desde + Vector3(cos(ang) * d, 0, sin(ang) * d)
		if libre(p, r, obstaculos):
			return Vector3(p.x, altura_suelo(p.x, p.z), p.z)
	return desde

func _crear_cuerpo() -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	if modo == "coche":
		var esc := load("res://assets/ciudad/kenney_cars/sedan-sports.glb") as PackedScene
		var raiz := Node3D.new()
		if esc != null:
			var c: Node3D = esc.instantiate()
			c.scale = Vector3.ONE * 1.65
			raiz.add_child(c)
		return raiz
	var d := PeatonQ.crear(rng)
	if d.is_empty():
		return Node3D.new()
	var n: Node3D = d["nodo"]
	add_child(n)
	PeatonQ.terminar(d)
	remove_child(n)
	_anim = _buscar_anim(n)
	return n

func _buscar_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for h in n.get_children():
		var a := _buscar_anim(h)
		if a != null:
			return a
	return null

var _capa: CanvasLayer

## Pausa el paseo (minijuego abierto): sin moverse, sin cartel, sin teclas.
func pausar(si: bool) -> void:
	set_physics_process(not si)
	set_process_unhandled_input(not si)
	if _capa != null:
		_capa.visible = not si

func _montar_hud() -> void:
	var capa := CanvasLayer.new()
	_capa = capa
	add_child(capa)
	_hud = Label.new()
	_hud.position = Vector2(18, 14)
	_hud.add_theme_font_size_override("font_size", 16)
	_hud.add_theme_color_override("font_color", Color.WHITE)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 6)
	capa.add_child(_hud)
	_aviso = Label.new()
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.offset_top = -90
	_aviso.offset_left = -300
	_aviso.offset_right = 300
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 20)
	_aviso.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	_aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override("outline_size", 8)
	capa.add_child(_aviso)

func _entrada() -> Vector2:
	var x := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var y := float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
	var jx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var jy := -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(jx) > 0.2:
		x = jx
	if absf(jy) > 0.2:
		y = jy
	return Vector2(x, y)

func _physics_process(delta: float) -> void:
	if cuerpo == null:
		return
	var e := _entrada()
	if modo == "coche":
		var acel := e.y * 14.0
		if e.y == 0.0:
			vel = move_toward(vel, 0.0, 6.0 * delta)
		else:
			vel = clampf(vel + acel * delta, -8.0, VEL_COCHE)
		rumbo -= e.x * delta * 1.9 * clampf(absf(vel) / 8.0, 0.0, 1.0) * signf(vel if vel != 0.0 else 1.0)
	else:
		var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
		vel = (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
		rumbo -= e.x * delta * 2.6
		if _anim != null:
			_anim.speed_scale = absf(vel) / 1.4 if absf(vel) > 0.05 else 0.0
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var nueva := cuerpo.position + adelante * vel * delta
	var r := RADIO_COCHE if modo == "coche" else RADIO_PIE
	if libre(nueva, r, obstaculos):
		cuerpo.position = Vector3(nueva.x, altura_suelo(nueva.x, nueva.z), nueva.z)
	else:
		vel *= -0.25
	cuerpo.rotation.y = rumbo
	_colocar_camara(delta)
	_buscar_cerca()
	_hud.text = ("🚗 Conduciendo" if modo == "coche" else "🚶 A pie") + "  ·  %d km/h  ·  W/S/A/D o mando · %sE: interactuar · Esc: volver al mapa" % [
		int(absf(vel) * 3.6), "" if modo == "coche" else "Mayús: correr · "]
	if _t_burbuja > 0.0:
		_t_burbuja -= delta
		if _t_burbuja <= 0.0:
			_burbuja.visible = false

func _colocar_camara(delta: float) -> void:
	var atras := 13.0 if modo == "coche" else 5.5
	var alto := 5.5 if modo == "coche" else 2.6
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var deseo := cuerpo.position - adelante * atras + Vector3(0, alto, 0)
	camara.position = camara.position.lerp(deseo, clampf(delta * 5.0, 0.0, 1.0)) if delta < 1.0 else deseo
	camara.look_at(cuerpo.position + Vector3(0, 1.6 if modo == "coche" else 1.4, 0) + adelante * 4.0, Vector3.UP)

## Lo que hay al alcance de la E: un peatón (a pie) o un lugar.
func _buscar_cerca() -> void:
	_cerca = {}
	var p := cuerpo.position
	if modo == "pie" and trafico != null:
		for v: Dictionary in trafico._vehiculos:
			var n: Node3D = v["nodo"]
			if not is_instance_valid(n) or float(v["alto"]) < 0.1 or float(v["alto"]) > 0.3:
				continue
			if n.global_position.distance_to(p) < 3.5:
				_cerca = {"tipo": "peaton", "v": v, "n": "un vecino"}
				break
	if _cerca.is_empty():
		var alcance := 30.0 if modo == "coche" else 14.0
		var mejor := alcance
		for pc: Dictionary in cb.puntos_clic:
			var q: Vector3 = pc["pos"]
			var d := Vector2(q.x - p.x, q.z - p.z).length()
			if d < mejor:
				mejor = d
				_cerca = {"tipo": "lugar", "k": String(pc["k"]), "n": String(pc["n"])}
	if _cerca.is_empty():
		_aviso.text = ""
	elif _cerca["tipo"] == "peaton":
		_aviso.text = "E: hablar con %s" % _cerca["n"]
	else:
		_aviso.text = "E: %s" % _cerca["n"]

func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not (ev as InputEventKey).pressed or (ev as InputEventKey).echo:
		if ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_X:
			_usar()
		return
	var k := (ev as InputEventKey).keycode
	if k == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		salir.emit()
	elif k == KEY_E:
		get_viewport().set_input_as_handled()
		_usar()

func _usar() -> void:
	if _cerca.is_empty():
		return
	if _cerca["tipo"] == "peaton":
		var v: Dictionary = _cerca["v"]
		v["espera"] = 5.0
		var lista: Array = FRASES.get(animo, FRASES["normal"])
		var frase := String(lista[randi() % lista.size()])
		if frase.contains("%s"):
			frase = frase % club_nombre
		_burbuja.text = "💬 " + frase
		_burbuja.position = (v["nodo"] as Node3D).global_position + Vector3(0, 2.4, 0)
		_burbuja.visible = true
		_t_burbuja = 5.0
	else:
		interactuar.emit(String(_cerca["k"]))
