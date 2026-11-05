class_name BenchmarkEscenarios
extends RefCounted
## Las ESCENAS que el banco automático de rendimiento (`BenchmarkManager`) pone a correr SOLAS. Cada una cubre una parte del juego:
##   partido   el partido 3D entero con la cámara de TV real (22 jugadores + árbitros + estadio + público), el motor en piloto automático;
##             se saltan la intro y la ceremonia: se mide el juego (como `medir_partido.gd`)
##   ciudad    la ciudad 3D propia (miles de piezas) con su cámara aérea
##   menu      el menú de inicio, quieto
##   gestion   la pantalla de gestión del club (`Principal`): tras 12 semanas simuladas recorre todas las pestañas una a una
##   museo     la sala del museo con las copas (3D)
##   minijuego el minijuego retro 5 contra 5, con un jugador que juega al azar (pausa el árbol del juego: el gestor sigue en modo SIEMPRE)

var _g: Node            ## el gestor (anfitrión de todo lo que se monta)
var _nombre := ""
var _n := 0
var _t := 0.0
var _vista: VistaEstadio
var _principal: Node
var _pestana_t := 0.0
var _raiz3d: Node3D
var _cam: Camera3D
var _azar := RandomNumberGenerator.new()
var _acciones_t := 0.0
var _listo := false

func _init(gestor: Node) -> void:
	_g = gestor
	_azar.seed = 4711

func montar(nombre: String) -> void:
	_nombre = nombre
	match nombre:
		"partido": _montar_partido()
		"ciudad", "gestion":
			_principal = (load("res://escenas/principal.tscn") as PackedScene).instantiate()
			_g.add_child(_principal)
		"menu": _g.add_child((load("res://escenas/inicio.tscn") as PackedScene).instantiate())
		"museo": _montar_museo()
		"minijuego": _montar_minijuego()
		_:
			push_error("BENCHMARK: escenario desconocido «%s» (partido, ciudad, menu, gestion, museo, minijuego, actual)" % nombre)
			_g.get_tree().quit(2)

func listo() -> bool:
	return _listo

# ---------------------------------------------------------------- partido

func _montar_partido() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], int(BenchmarkManager.ajuste("semilla", "4711")))
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	_g.add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _paso_partido() -> void:
	## La intro y la ceremonia (filas, alineaciones, himno) se saltan: se mide el JUEGO con la cámara de TV.
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
		return
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
		return
	_n += 1
	if _n == 5:
		(_vista.get("_rig") as CameraRig).switch_to(0)   ## la cámara de TV: la del partido de verdad
	_listo = _n >= 40

# ---------------------------------------------------------------- ciudad y gestión

func _paso_ciudad() -> void:
	_n += 1
	if _n == 5:
		_principal.call("_ver_ciudad_propia")
	if _n > 5:
		for h in _principal.get_children():
			if h is VistaCiudad and _n > 45:
				_listo = true

func _paso_gestion(dt: float) -> void:
	_n += 1
	if _n == 8:
		for i in 12:
			_principal.call("_avanzar_semana")
	if _n < 20:
		return
	_listo = true
	var tabs: TabContainer = _principal.get("_pestanas")
	if tabs == null or tabs.get_tab_count() == 0:
		return
	_pestana_t += dt
	if _pestana_t >= 1.0:   ## una pestaña por segundo, en bucle
		_pestana_t = 0.0
		tabs.current_tab = (tabs.current_tab + 1) % tabs.get_tab_count()

# ---------------------------------------------------------------- museo

func _montar_museo() -> void:
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.16, 0.17, 0.2)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.85, 0.85, 0.9)
	ent.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = ent
	_g.add_child(we)
	_raiz3d = Node3D.new()
	_g.add_child(_raiz3d)
	var hitos := [{"anio": 1999, "titulo": "Liga"}, {"anio": 2001, "titulo": "Copa Libertadores"}, {"anio": 2005, "titulo": "Copa Argentina"},
		{"anio": 2008, "titulo": "Mundial de Clubes"}, {"anio": 2010, "titulo": "Copa Sudamericana"}, {"anio": 2012, "titulo": "Supercopa"}]
	SalasClub.museo(_raiz3d, Rect2(0.0, 0.0, 3.6, 6.0), 0.0, Color("#c01020"), Color("#f2f2f2"), 6, 4, hitos, "ARG")
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8.0, 10.0)
	suelo.mesh = pm
	suelo.position = Vector3(1.8, -0.01, 3.0)
	_raiz3d.add_child(suelo)
	_cam = Camera3D.new()
	_cam.fov = 62.0
	_raiz3d.add_child(_cam)
	_cam.current = true
	_cam.position = Vector3(1.8, 1.45, 5.9)
	_cam.look_at(Vector3(1.8, 1.25, 1.2), Vector3.UP)

func _paso_museo(dt: float) -> void:
	_n += 1
	_listo = _n >= 10
	## Paseo suave de lado a lado, como el de un visitante.
	_t += dt
	_cam.position.x = 1.8 + sin(_t * 0.6) * 1.2
	_cam.look_at(Vector3(1.8 + sin(_t * 0.6) * 0.8, 1.25, 1.2), Vector3.UP)

# ---------------------------------------------------------------- minijuego

func _montar_minijuego() -> void:
	Retro5v5.abrir(_g.get_tree())

func _paso_minijuego(dt: float) -> void:
	_n += 1
	_listo = _n >= 30
	## El saque de centro pide un pase; después, direcciones, pase y tiro al azar cada cuarto de segundo.
	if GameManager.current_state is GameStateKickoff:
		Input.action_press("p1_pass")
		return
	Input.action_release("p1_pass")
	_acciones_t -= dt
	if _acciones_t > 0.0:
		return
	_acciones_t = 0.25
	for a: String in ["p1_left", "p1_right", "p1_up", "p1_down", "p1_pass", "p1_shoot"]:
		Input.action_release(a)
	for a: String in ["p1_left", "p1_right", "p1_up", "p1_down"]:
		if _azar.randf() < 0.4:
			Input.action_press(a)
	if _azar.randf() < 0.3:
		Input.action_press("p1_pass")
	elif _azar.randf() < 0.15:
		Input.action_press("p1_shoot")

# ---------------------------------------------------------------- bucle

func paso(dt: float) -> void:
	match _nombre:
		"partido": _paso_partido()
		"ciudad": _paso_ciudad()
		"gestion": _paso_gestion(dt)
		"menu":
			_n += 1
			_listo = _n >= 20
		"museo": _paso_museo(dt)
		"minijuego": _paso_minijuego(dt)
