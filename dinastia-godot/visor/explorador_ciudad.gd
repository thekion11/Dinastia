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

## EL METRO A PIE (7-10-2026, «que nuestro personaje lo pueda usar… y por
## dentro»): `estado` es "calle", "anden" o "tren".
var estado := "calle"
var metro: MetroCiudad
var _acc: Dictionary = {}       ## el acceso por el que se entró
var _linea := ""
var _idx := -1
var _anden_c := Vector3.ZERO    ## centro del andén
var _anden_lat := Vector3.ZERO
var _anden_lon := Vector3.ZERO
var _anden_medio := Vector2.ZERO   ## medio ancho (lat) y medio largo (lon)
var _tren_k := -1
var _bajar_en_proxima := false
var _ventana := false
var _luz_cam: OmniLight3D
## ESTADIO INTERACTIVO 2.0 (fase 1): el estadio de la ciudad se recorre por
## dentro sin salir del mundo. `_est` son los datos de `TunelVestuario.datos()`
## (en coordenadas del estadio, que está en `CityBuilder.ESTADIO_EN`).
var _est: Dictionary = {}
var _zona_est := ""
var _planta := 0
var _menu_asc: PanelContainer
var _sentado := false
var _hinchas_quitados: Array = []
var _de_pie := Vector3.ZERO
var _mirada := 0.0
var _t_sacudida := 0.0

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
	metro = cb.expansion.metro if cb.expansion != null else null
	obstaculos = construir_obstaculos(cb)
	var perfil: Dictionary = cb.datos.get("perfil_estadio", {})
	if not perfil.is_empty():
		var aforo := int(perfil.get("aforo", 20000))
		_est = TunelVestuario.datos(perfil, StadiumBuilder.niveles_de(perfil, aforo))
	position = Vector3.ZERO
	cuerpo = _crear_cuerpo()
	add_child(cuerpo)
	cuerpo.position = buscar_libre(desde)
	camara = Camera3D.new()
	camara.fov = 65.0
	camara.far = 5000.0
	add_child(camara)
	camara.make_current()
	_luz_cam = OmniLight3D.new()
	_luz_cam.omni_range = 12.0
	_luz_cam.light_energy = 0.45
	_luz_cam.visible = false
	camara.add_child(_luz_cam)
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
	## TU PERSONAJE (estadio 2.0): el DT con el aspecto que elegiste, si hay.
	if not PersonajeDT.del_usuario.is_empty():
		var raiz := Node3D.new()
		add_child(raiz)
		var dt := PersonajeDT.crear(raiz, PersonajeDT.del_usuario, Color(0.12, 0.13, 0.16), Color(0.9, 0.9, 0.92))
		remove_child(raiz)
		if not dt.is_empty():
			_anim = dt.get("anim") as AnimationPlayer
			_es_dt = true
			return raiz
		raiz.queue_free()
	var d := PeatonQ.crear(rng)
	if d.is_empty():
		return Node3D.new()
	var n: Node3D = d["nodo"]
	add_child(n)
	PeatonQ.terminar(d)
	remove_child(n)
	_anim = _buscar_anim(n)
	return n

var _es_dt := false

## Con el cuerpo del DT: «caminar» o «correr» al moverse y «parado» quieto.
func _animar_dt(v: float) -> void:
	if not _es_dt or _anim == null:
		return
	var quiere := "parado"
	if absf(v) > 3.0 and _anim.has_animation("correr"):
		quiere = "correr"
	elif absf(v) > 0.05 and _anim.has_animation("caminar"):
		quiere = "caminar"
	if _anim.current_animation != quiere and _anim.has_animation(quiere):
		_anim.play(quiere, 0.25)
	_anim.speed_scale = 1.0

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
	_tactil(capa)

## CONTROLES TÁCTILES (el juego también va en Android): cruceta abajo a la
## izquierda, «E» y «Salir» abajo a la derecha. Mantener pulsado = tecla.
var _tactil_vec := Vector2.ZERO

func _tactil(capa: CanvasLayer) -> void:
	var tam := 74.0
	var base := Control.new()
	base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	base.offset_left = 24
	base.offset_top = -tam * 3.0 - 24
	capa.add_child(base)
	for d: Array in [["▲", Vector2(1, 0), Vector2(0, 1)], ["▼", Vector2(1, 2), Vector2(0, -1)],
			["◀", Vector2(0, 1), Vector2(-1, 0)], ["▶", Vector2(2, 1), Vector2(1, 0)]]:
		var b := Button.new()
		b.text = String(d[0])
		b.position = (d[1] as Vector2) * tam
		b.size = Vector2(tam - 6, tam - 6)
		b.add_theme_font_size_override("font_size", 28)
		b.modulate = Color(1, 1, 1, 0.7)
		var v: Vector2 = d[2]
		b.button_down.connect(func() -> void: _tactil_vec += v)
		b.button_up.connect(func() -> void: _tactil_vec -= v)
		base.add_child(b)
	var der := HBoxContainer.new()
	der.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	der.offset_left = -260
	der.offset_top = -100
	der.offset_right = -24
	der.offset_bottom = -24
	der.add_theme_constant_override("separation", 12)
	capa.add_child(der)
	var be := Button.new()
	be.text = "E"
	be.custom_minimum_size = Vector2(tam, tam)
	be.add_theme_font_size_override("font_size", 28)
	be.modulate = Color(1, 1, 1, 0.75)
	be.pressed.connect(_usar)
	der.add_child(be)
	var bs := Button.new()
	bs.text = "Salir"
	bs.custom_minimum_size = Vector2(tam * 1.6, tam)
	bs.modulate = Color(1, 1, 1, 0.75)
	bs.pressed.connect(func() -> void: salir.emit())
	der.add_child(bs)

func _entrada() -> Vector2:
	var x := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var y := float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
	var jx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var jy := -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(jx) > 0.2:
		x = jx
	if absf(jy) > 0.2:
		y = jy
	if _tactil_vec != Vector2.ZERO:
		x = clampf(_tactil_vec.x, -1.0, 1.0)
		y = clampf(_tactil_vec.y, -1.0, 1.0)
	return Vector2(x, y)

func _physics_process(delta: float) -> void:
	if cuerpo == null:
		return
	if estado == "anden":
		_mover_en_anden(delta)
		return
	if estado == "tren":
		_viajar(delta)
		return
	if estado == "estadio":
		_mover_en_estadio(delta)
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
		if _es_dt:
			_animar_dt(vel)
		elif _anim != null:
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
	## Dónde estás: el nombre de la calle (o el cruce).
	if cb != null and cb.expansion != null:
		var calle := cb.expansion.nombre_calle_en(cuerpo.position)
		if calle != "":
			_hud.text = "📍 %s\n%s" % [calle, _hud.text]
	if _t_burbuja > 0.0:
		_t_burbuja -= delta
		if _t_burbuja <= 0.0:
			_burbuja.visible = false

func _colocar_camara(delta: float) -> void:
	var atras := 13.0 if modo == "coche" else 5.5
	var alto := 5.5 if modo == "coche" else 2.6
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var deseo := cuerpo.position - adelante * atras + Vector3(0, alto, 0)
	if estado == "anden" and not _acc.is_empty() and not bool(_acc["elevada"]):
		## BAJO TIERRA la cámara no puede salirse del vestíbulo: se queda entre
		## la vía y la pared del fondo, y bajo el techo.
		var rel := deseo - _anden_c
		var l_lat := clampf(rel.dot(_anden_lat), -5.0, 3.0)
		var l_lon := clampf(rel.dot(_anden_lon), -29.0, 29.0)
		deseo = _anden_c + _anden_lat * l_lat + _anden_lon * l_lon
		deseo.y = minf(cuerpo.position.y + alto, MetroCiudad.PROF_TUNEL + 5.6)
	camara.position = camara.position.lerp(deseo, clampf(delta * 5.0, 0.0, 1.0)) if delta < 1.0 else deseo
	camara.look_at(cuerpo.position + Vector3(0, 1.6 if modo == "coche" else 1.4, 0) + adelante * 4.0, Vector3.UP)

## Lo que hay al alcance de la E: un peatón (a pie) o un lugar.
func _buscar_cerca() -> void:
	_cerca = {}
	var p := cuerpo.position
	## La puerta del club del estadio (a pie).
	if modo == "pie" and not _est.is_empty():
		var pu: Vector3 = CityBuilder.ESTADIO_EN + (_est["puerta"] as Vector3)
		if Vector2(pu.x - p.x, pu.z - p.z).length() < 3.5:
			_cerca = {"tipo": "puerta_estadio", "n": "el estadio"}
			_aviso.text = Idiomas.t("E: entrar al estadio por la puerta del club")
			return
	## Una entrada de metro (a pie).
	if modo == "pie" and metro != null:
		for a: Dictionary in metro.accesos:
			var q: Vector3 = a["pie"]
			if Vector2(q.x - p.x, q.z - p.z).length() < 4.0:
				_cerca = {"tipo": "metro", "acc": a, "n": "Ⓜ %s · %s" % [a["linea"], a["nombre"]]}
				_aviso.text = "E: entrar al metro (%s, estación %s)" % [a["linea"], a["nombre"]]
				return
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
	elif k == KEY_C and estado == "tren":
		_ventana = not _ventana

func _usar() -> void:
	if estado == "estadio":
		if is_instance_valid(_menu_asc):
			return
		var loc := cuerpo.position - CityBuilder.ESTADIO_EN
		if _sentado:
			_sentado = false
			cuerpo.visible = true
			RecorridoClub.devolver_hinchas(_hinchas_quitados)
			_hinchas_quitados = []
			cuerpo.position = _de_pie
			_aviso.text = ""
			_zona_est = "?"
			return
		if RecorridoClub.junto_a_la_grada(loc, _planta):
			var b := RecorridoClub.butaca(cb.datos.get("perfil_estadio", {}), signf(loc.x), loc.z)
			_de_pie = cuerpo.position
			cuerpo.position = CityBuilder.ESTADIO_EN + (b["pos"] as Vector3)
			rumbo = float(b["rumbo"])
			cuerpo.rotation.y = rumbo
			_mirada = 0.0
			_sentado = true
			cuerpo.visible = false
			_hinchas_quitados = RecorridoClub.despejar_hinchas(cb, cuerpo.global_position + Vector3(0, 0.5, 0))
			_aviso.text = Idiomas.t("En la grada. A/D: mirar alrededor · E: levantarse")
			return
		var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
		var g: Dictionary = pe.cercano(cuerpo.position - CityBuilder.ESTADIO_EN, _planta) if pe != null else {}
		if not g.is_empty():
			_menu_asc = RecorridoClub.dialogo(_capa, pe, g, cuerpo.position - CityBuilder.ESTADIO_EN)
			return
		if _zona_est == "Acceso":
			_salir_del_estadio()
		elif _zona_est == "Ascensor" and not is_instance_valid(_menu_asc):
			_menu_asc = RecorridoClub.menu_ascensor(_capa, _planta, _ir_a_planta)
		elif RecorridoClub.sala_decorable(_zona_est):
			_menu_asc = RecorridoClub.panel_decorar(_capa, get_tree(), _zona_est)
		return
	if estado == "anden":
		_usar_en_anden()
		return
	if estado == "tren":
		if metro.estacion_del_tren(_linea, _tren_k) >= 0:
			_bajar_del_tren()
		else:
			_bajar_en_proxima = not _bajar_en_proxima
		return
	if _cerca.is_empty():
		return
	if _cerca["tipo"] == "metro":
		_entrar_al_anden(_cerca["acc"])
		return
	if _cerca["tipo"] == "puerta_estadio":
		_entrar_al_estadio()
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


# ============================================================== EL ESTADIO (2.0)

## Cruza la puerta del club: ya dentro, en el vestuario.
func _entrar_al_estadio() -> void:
	estado = "estadio"
	_planta = 0
	## Los rótulos flotantes del mapa se ven a través de las paredes: fuera.
	_rotulos_antes = cb._rotulos.visible if cb._rotulos != null else true
	cb.mostrar_rotulos(false)
	var pu: Vector3 = _est["puerta"]
	cuerpo.position = CityBuilder.ESTADIO_EN + pu + Vector3(0, 0, -2.2)
	rumbo = PI
	_zona_est = ""
	_aviso.text = ""
	Sonido.toca("puerta", Sonido.Bus.EFECTOS)

## El ascensor del edificio del club: misma x y z, otra planta. Los sótanos
## van sin sol ni niebla (como el metro).
func _ir_a_planta(p: int) -> void:
	var antes := _planta
	_planta = p
	cuerpo.position.y = RecorridoClub.y_de(p)
	_zona_est = "?"
	if (antes < 0) != (p < 0):
		_bajo_tierra(p < 0)

## De vuelta a la calle, delante de la puerta del club.
var _rotulos_antes := true

func _salir_del_estadio() -> void:
	estado = "calle"
	cb.mostrar_rotulos(_rotulos_antes)
	var pu: Vector3 = _est["puerta"]
	cuerpo.position = CityBuilder.ESTADIO_EN + pu + Vector3(0, 0, 3.2)
	cuerpo.position.y = altura_suelo(cuerpo.position.x, cuerpo.position.z)
	rumbo = 0.0
	_aviso.text = ""

## Dentro del estadio se camina por las zonas de `TunelVestuario` (vestuario,
## túnel, banda, campo y la puerta). Salir por la puerta devuelve a la calle.
func _mover_en_estadio(delta: float) -> void:
	var e := _entrada()
	if _sentado:
		_mirada = clampf(_mirada - e.x * delta * 1.4, -1.2, 1.2)
		var dir := Vector3(sin(rumbo + _mirada), 0, cos(rumbo + _mirada))
		camara.position = cuerpo.position + Vector3(0, 1.2, 0) + Vector3(sin(rumbo), 0, cos(rumbo)) * 0.1
		camara.look_at(camara.position + dir * 10.0 + Vector3(0, -1.6, 0), Vector3.UP)
		return
	var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	vel = (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
	rumbo -= e.x * delta * 2.6
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var nueva := cuerpo.position + adelante * vel * delta
	var local := nueva - CityBuilder.ESTADIO_EN
	var zonas: Array = _est["zonas"]
	if not TunelVestuario.zona_en(zonas, local, _planta).is_empty():
		cuerpo.position = Vector3(nueva.x, RecorridoClub.y_de(_planta), nueva.z)
	elif _planta == 0 and local.z > float((_est["puerta"] as Vector3).z) + 0.5:
		## Por la puerta, a la calle: sin pulsar nada, como en la vida.
		_salir_del_estadio()
		return
	else:
		vel = 0.0
	cuerpo.rotation.y = rumbo
	_animar_dt(vel)
	var z := TunelVestuario.zona_en(zonas, cuerpo.position - CityBuilder.ESTADIO_EN, _planta)
	var nombre := String(z.get("nombre", ""))
	var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
	var g: Dictionary = pe.cercano(cuerpo.position - CityBuilder.ESTADIO_EN, _planta) if pe != null else {}
	if not g.is_empty():
		_aviso.text = Idiomas.t("E: hablar con %s (%s)") % [String(g["nombre"]), Idiomas.t(String(g["puesto"]))]
		_zona_est = nombre
	elif RecorridoClub.junto_a_la_grada(cuerpo.position - CityBuilder.ESTADIO_EN, _planta):
		_aviso.text = Idiomas.t("E: sentarse en la grada")
		_zona_est = "·grada"
	elif nombre != _zona_est or _aviso.text.begins_with("E: hablar"):
		_zona_est = nombre
		_aviso.text = RecorridoClub.aviso_de(nombre)
		if RecorridoClub.sala_decorable(nombre):
			_aviso.text += "  ·  " + Idiomas.t("E: decorar")
	_hud.text = "📍 %s · %s %d · %s\n🚶 %s" % [Idiomas.t(nombre), Idiomas.t("Planta"), _planta, str(cb.datos.get("club", {}).get("estadioNom", "Estadio")),
		Idiomas.t("W/S/A/D o mando · Mayús: correr · E: usar · Esc: volver al mapa")]
	## Cámara: dentro de una sala no atraviesa paredes ni techo.
	var cerrado := float(z.get("techo", 99.0)) < 50.0
	var atras := 3.2 if cerrado else 5.5
	var alto := 1.9 if cerrado else 2.6
	var deseo := cuerpo.position - adelante * atras + Vector3(0, alto, 0)
	if cerrado:
		var r: Rect2 = z["r"]
		var o := CityBuilder.ESTADIO_EN
		deseo.x = clampf(deseo.x, o.x + r.position.x + 0.15, o.x + r.end.x - 0.15)
		## Solo el túnel deja que la cámara asome por sus extremos (la boca y la
		## puerta del vestuario); en una sala cerrada se queda dentro.
		var holgura := 1.0 if nombre == "Túnel" else -0.15
		deseo.z = clampf(deseo.z, o.z + r.position.y - holgura, o.z + r.end.y + holgura)
		deseo.y = minf(deseo.y, RecorridoClub.y_de(_planta) + float(z["techo"]) - 0.25)
	camara.position = camara.position.lerp(deseo, clampf(delta * 6.0, 0.0, 1.0)) if delta < 1.0 else deseo
	camara.look_at(cuerpo.position + Vector3(0, 1.4, 0) + adelante * 3.0, Vector3.UP)

# ============================================================== EL METRO

## Del pie de la escalera (o de la boca) al andén.
func _entrar_al_anden(a: Dictionary) -> void:
	_acc = a
	_linea = String(a["linea"])
	_idx = int(a["idx"])
	var l := metro.linea(_linea)
	var dir: Vector3 = l["dir"]
	var p: Vector3 = l["estaciones"][_idx]
	_anden_lon = dir.abs()
	_anden_lat = Vector3(dir.z, 0, -dir.x).abs()
	if bool(a["elevada"]):
		var lado := float(a.get("lado", 1.0))
		_anden_c = p + _anden_lat * lado * MetroCiudad.ANDEN_LAT
		_anden_c.y = MetroCiudad.ALTO_VIADUCTO + 0.6 + MetroCiudad.PISO_COCHE
		_anden_medio = Vector2(MetroCiudad.ANDEN_ANCHO * 0.5 - 0.4, MetroCiudad.ANDEN_LARGO * 0.5 - 1.0)
	else:
		_anden_c = p + _anden_lat * MetroCiudad.ANDEN_LAT * 1.6
		_anden_c.y = MetroCiudad.PROF_TUNEL + MetroCiudad.PISO_COCHE
		_anden_medio = Vector2(MetroCiudad.ANDEN_ANCHO * 1.1 - 0.5, MetroCiudad.ANDEN_LARGO * 0.5 - 1.0)
	estado = "anden"
	cuerpo.visible = true
	cuerpo.position = a["anden"] if bool(a["elevada"]) else _anden_c
	cuerpo.position.y = _anden_c.y
	_luz_cam.visible = not bool(a["elevada"])
	_bajo_tierra(not bool(a["elevada"]))
	if not bool(a["elevada"]):
		rumbo = atan2(_anden_lon.x, _anden_lon.z)
	_colocar_camara(1.0)

func _mover_en_anden(delta: float) -> void:
	var e := _entrada()
	var corre := Input.is_physical_key_pressed(KEY_SHIFT)
	vel = (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
	rumbo -= e.x * delta * 2.6
	if _anim != null:
		_anim.speed_scale = absf(vel) / 1.4 if absf(vel) > 0.05 else 0.0
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var p := cuerpo.position + adelante * vel * delta
	## Dentro del andén: ni a la vía ni fuera de la estación.
	var rel := p - _anden_c
	var la := clampf(rel.dot(_anden_lat), -_anden_medio.x, _anden_medio.x)
	var lo := clampf(rel.dot(_anden_lon), -_anden_medio.y, _anden_medio.y)
	cuerpo.position = _anden_c + _anden_lat * la + _anden_lon * lo
	cuerpo.rotation.y = rumbo
	_colocar_camara(delta)
	var k := metro.tren_parado_en(_linea, _idx)
	var eta := metro.eta_minima(_linea, _idx)
	var nombre := String(MetroCiudad.NOMBRES[_linea][_idx])
	_hud.text = "Ⓜ %s · estación %s  ·  W/A/S/D · Mayús: correr · E: %s · Esc: mapa" % [
		_linea, nombre, "subir al tren" if k >= 0 else "salir a la calle"]
	if k >= 0:
		_aviso.text = "🚇 Tren en el andén, puertas abiertas · E para subir"
	else:
		_aviso.text = "Próximo tren: %s · E: salir a la calle" % ("llegando" if eta < 20.0 else "%d s" % int(eta))

func _usar_en_anden() -> void:
	var k := metro.tren_parado_en(_linea, _idx)
	if k >= 0:
		_subir_al_tren(k)
		return
	## Salir a la calle por donde se entró (o por la boca de esta estación).
	estado = "calle"
	_luz_cam.visible = false
	_bajo_tierra(false)
	var pie: Vector3 = _acc.get("pie", cuerpo.position)
	cuerpo.position = Vector3(pie.x, altura_suelo(pie.x, pie.z), pie.z)
	_colocar_camara(1.0)

func _subir_al_tren(k: int) -> void:
	estado = "tren"
	_tren_k = k
	_bajar_en_proxima = false
	_ventana = false
	cuerpo.visible = false
	_luz_cam.visible = true

func _viajar(delta: float) -> void:
	var l := metro.linea(_linea)
	var tren: Node3D = l["nodos"][_tren_k]
	_t_sacudida += delta
	var f := MetroCiudad.PISO_COCHE
	var t: MetroCiudad.Tren = l["trenes"][_tren_k]
	var vaiven := sin(_t_sacudida * 9.0) * 0.012 * clampf(t.v / MetroCiudad.VEL, 0.0, 1.0)
	var local_pos := Vector3(0.45, f + 1.62 + vaiven, -5.0)
	var local_mira := Vector3(0.2, f + 1.45, 10.0)
	if _ventana:
		local_pos = Vector3(-0.6, f + 1.55 + vaiven, 0.0)
		local_mira = Vector3(6.0, f + 1.3, 0.5)
	camara.global_position = tren.global_transform * local_pos
	camara.look_at(tren.global_transform * local_mira, Vector3.UP)
	var parada := metro.estacion_del_tren(_linea, _tren_k)
	if parada >= 0 and _bajar_en_proxima and t.espera < MetroCiudad.PARADA - 1.0:
		_bajar_del_tren()
		return
	var prox := metro.proxima_de(_linea, _tren_k)
	_hud.text = "🚇 %s · %s · %d km/h  ·  C: %s · Esc: mapa" % [_linea,
		("parado en %s" % String(MetroCiudad.NOMBRES[_linea][parada])) if parada >= 0 else ("próxima: %s" % prox),
		int(t.v * 3.6), "mirar al frente" if _ventana else "mirar por la ventana"]
	if parada >= 0:
		_aviso.text = "Puertas abiertas en %s · E: bajar aquí" % String(MetroCiudad.NOMBRES[_linea][parada])
	else:
		_aviso.text = "Próxima estación: %s · E: %s" % [prox, "no bajar" if _bajar_en_proxima else "bajar en la próxima"]

func _bajar_del_tren() -> void:
	var parada := metro.estacion_del_tren(_linea, _tren_k)
	if parada < 0:
		return
	var l := metro.linea(_linea)
	var a := {"linea": _linea, "idx": parada, "elevada": bool(l["elevada"]), "nombre": String(MetroCiudad.NOMBRES[_linea][parada]), "lado": 1.0}
	## La salida a la calle de la estación de llegada.
	for acc: Dictionary in metro.accesos:
		if String(acc["linea"]) == _linea and int(acc["idx"]) == parada and float(acc.get("lado", 1.0)) > 0.0:
			a["pie"] = acc["pie"]
			a["anden"] = acc["anden"]
	if not a.has("anden"):
		a["anden"] = Vector3.ZERO
	_entrar_al_anden(a)
	if bool(a["elevada"]):
		var tren: Node3D = l["nodos"][_tren_k]
		cuerpo.position = Vector3(cuerpo.position.x, _anden_c.y, cuerpo.position.z)
		## Aparece frente a la puerta del coche central.
		var rel := tren.global_position - _anden_c
		var lo := clampf(rel.dot(_anden_lon), -_anden_medio.y, _anden_medio.y)
		cuerpo.position = _anden_c + _anden_lon * lo


## BAJO TIERRA el cielo de la ciudad no puede iluminar ni empañar: sin niebla y
## con poca luz ambiente (se restaura al salir).
var _env_guardado := {}
var _soles_apagados: Array = []

func _bajo_tierra(si: bool) -> void:
	var env: Environment = camara.get_world_3d().environment if camara.get_world_3d() != null else null
	if env == null:
		return
	if si and _env_guardado.is_empty():
		_env_guardado = {"fog": env.fog_enabled, "amb": env.ambient_light_energy, "exp": env.tonemap_exposure,
			"vol": env.volumetric_fog_enabled}
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
		env.ambient_light_energy = 0.25
		env.tonemap_exposure = 0.9
		for n in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
			if (n as DirectionalLight3D).visible:
				(n as DirectionalLight3D).visible = false
				_soles_apagados.append(n)
		get_tree().call_group("rotulo_mapa", "hide")
	elif not si and not _env_guardado.is_empty():
		env.fog_enabled = _env_guardado["fog"]
		env.volumetric_fog_enabled = _env_guardado["vol"]
		env.ambient_light_energy = _env_guardado["amb"]
		env.tonemap_exposure = _env_guardado["exp"]
		for n in _soles_apagados:
			if is_instance_valid(n):
				(n as DirectionalLight3D).visible = true
		_soles_apagados.clear()
		get_tree().call_group("rotulo_mapa", "show")
		_env_guardado = {}

func _exit_tree() -> void:
	_bajo_tierra(false)
