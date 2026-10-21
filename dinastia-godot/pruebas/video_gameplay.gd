extends Node
## EL VÍDEO DE GAMEPLAY PARA EVALUAR (21-10-2026). Pedido del dueño: «con sonido
## y gameplay real, más largo, más detallado; probar cada mecánica y variable».
## El partido entero va aparte (`video_partido.gd`, el bot que pulsa el mando);
## aquí, el resto del juego, por tramos, con la música y los efectos encendidos:
##   VG_TRAMO=gestion xvfb-run -a godot --path . --rendering-driver vulkan --resolution 960x540 \
##       --fixed-fps 25 --write-movie gestion.avi res://pruebas/video_gameplay.tscn
## Tramos: gestion · estadio · ciudad · carrera · mini. `herramientas/montar_gameplay.py`
## los junta con el partido y las tarjetas de título.

const FPS := 25.0
const TRAMOS := {"gestion": 118.0, "estadio": 80.0, "ciudad": 80.0, "carrera": 120.0, "mini": 32.0}
var _tramo := ""
var _f := 0
var _dur := 10.0
var _p: Node
var _x: Dictionary = {}
var _cap: Label
var _musica_antes := false

func _ready() -> void:
	_tramo = OS.get_environment("VG_TRAMO")
	if not TRAMOS.has(_tramo):
		_tramo = "gestion"
	_dur = float(TRAMOS[_tramo])
	Idiomas.idioma = "es"
	Calidad.elegida = Calidad.ALTO
	AjustesCiudad.guardar("tutorial_visto", true)
	_musica_antes = Musica.encendida
	var capa := CanvasLayer.new()
	capa.layer = 120
	add_child(capa)
	_cap = Label.new()
	_cap.add_theme_font_size_override("font_size", 19)
	_cap.add_theme_color_override("font_color", Color("#c9f24b"))
	_cap.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_cap.add_theme_constant_override("outline_size", 7)
	_cap.anchor_top = 1.0
	_cap.anchor_bottom = 1.0
	_cap.offset_left = 18
	_cap.offset_top = -40
	capa.add_child(_cap)
	call("_montar_" + _tramo)
	## Después de la pantalla principal, que carga las preferencias (música apagada).
	Musica.encendida = true
	Musica.volumen = 0.28
	Musica.ambientar("oficina")

func _t() -> float:
	return float(_f) / FPS

func _process(_d: float) -> void:
	_f += 1
	call("_paso_" + _tramo, _t())
	if _t() >= _dur:
		Musica.encendida = _musica_antes
		Input.parse_input_event(_tecla(KEY_W, false))
		Input.parse_input_event(_tecla(KEY_SHIFT, false))
		get_tree().quit()

func _una(clave: String, t: float, desde: float) -> bool:
	if t >= desde and not _x.has(clave):
		_x[clave] = true
		return true
	return false

func _rotulo(texto: String) -> void:
	_cap.text = "▶ " + texto if texto != "" else ""

func _principal() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _mundo() -> Mundo:
	return _p.get("mundo")

func _ml() -> MenuLateral:
	return _p.get("_menu_lateral")

func _tecla(k: Key, si: bool) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.keycode = k
	e.pressed = si
	return e

func _cerrar_menus() -> void:
	for n in _p.find_children("*", "PantallaMenu", true, false):
		(n as PantallaMenu).cerrar()

# ------------------------------------------------------------------ gestión

func _montar_gestion() -> void:
	_principal()

const PESTANAS := [[8.0, "Mi plantel", "Plantel: fichas con la cara 3D de cada jugador, estado y moral"],
	[15.0, "Táctica", "Táctica: formación, mentalidad, presión, línea y ritmo"],
	[22.0, "Entrenar", "Entrenamiento: árbol de habilidades y maestrías del seleccionado"],
	[28.0, "Camarín", "Camarín: moral explicada, capitán votado, grupos del vestuario"],
	[34.0, "Mercado", "Mercado: ofertas, cláusulas y agentes"],
	[40.0, "Finanzas", "Finanzas: taquilla, sueldos, mantenimiento del estadio"],
	[46.0, "Calendario", "Calendario de la temporada"],
	[51.0, "Clubes", "La liga: tabla, rivales y su historia"]]
const MENUS := [[57.0, "historia", "Historia del club"], [61.0, "gente", "La gente del club"],
	[65.0, "carrera", "Mi carrera de DT"], [69.0, "operaciones", "Operaciones: obras, ciudad, negocios"],
	[73.0, "vida", "Mi vida: casa, minijuegos, familia"], [77.0, "editar", "Editar: mundo, personaje, equipación, estadio"],
	[81.0, "ajustes", "Ajustes: idioma, gráficos, controles, créditos"]]

func _paso_gestion(t: float) -> void:
	if _una("hub", t, 0.2):
		_rotulo("El despacho: tablero, objetivos de la directiva y la próxima jornada")
	if _una("ficha", t, 4.0):
		var c := _mundo().mi_club()
		var mejor: Jugador = c.plantilla[0]
		for j: Jugador in c.plantilla:
			if j.ovr > mejor.ovr:
				mejor = j
		_p.call("_ver_ficha", mejor)
	for f: Array in PESTANAS:
		if _una("p" + String(f[1]), t, float(f[0])):
			_p.call("_ir_a_pestana", String(f[1]))
			_p.call("_refrescar")
			_rotulo(String(f[2]))
	for f: Array in MENUS:
		if _una("m" + String(f[1]), t, float(f[0])):
			_cerrar_menus()
			_ml().abrir_menu(String(f[1]), -1)
			_rotulo("Menú lateral · " + String(f[2]))
	if _una("menu_det", t, 84.5):
		_cerrar_menus()
		_ml().abrir_menu("historia", 0)
		_rotulo("Cada menú abre su pantalla completa con fondo propio")
	if _una("semana", t, 89.0):
		_cerrar_menus()
		_rotulo("Avanzar la semana: se juega la jornada en todo el mundo")
		_p.call("_avanzar_semana")
	if _una("prensa", t, 97.0):
		var m := _mundo()
		m.prensa.abrir_rueda(true, false)
		_p.call("_abrir_rueda_pantalla_completa", m.prensa.entrevista)
		_rotulo("Rueda de prensa: lo que respondes cambia la relación con los medios")
	if _una("tel", t, 107.0):
		for n in _p.find_children("*", "RuedaPrensa*", true, false):
			n.queue_free()
		var m := _mundo()
		m.redes.publicar(m, "hinchada", ["#Hinchada", m.redes.tendencia])
		var pop: Control = Telefono.abrir(_p, m)
		_x["tel"] = pop.find_children("*", "Telefono", true, false)[0]
		_rotulo("El móvil: Tribuna (redes), mensajes, banco, GPS")
	if _x.has("tel") and _una("tribuna", t, 110.0):
		(_x["tel"] as Telefono).abrir_app("tribuna")
	if _x.has("tel") and _una("cal", t, 114.0):
		(_x["tel"] as Telefono).abrir_app("mensajes")

# ------------------------------------------------------------------ estadio a pie

var _vista: VistaEstadio
var _e: ExploradorEstadio
var _meta := 0
var _ruta_pie: Array[Vector3] = []

func _montar_estadio() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	_x["mundo"] = mundo
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(mundo.mi_club(), 0.95)

func _paso_estadio(t: float) -> void:
	if _una("fuera", t, 0.1):
		_rotulo("El estadio por fuera: plaza, avenida, aparcamientos, banderas y la ciudad detrás")
		var cam := Camera3D.new()
		cam.far = 2500.0
		(_vista.get("_raiz3d") as Node3D).add_child(cam)
		cam.current = true
		_x["cam"] = cam
	if _x.has("cam") and t < 11.0:
		var cam: Camera3D = _x["cam"]
		var a := 0.7 + t * 0.12
		cam.global_position = Vector3(cos(a) * 165.0, 60.0 - t * 2.5, sin(a) * 140.0)
		cam.look_at(Vector3(0, 6, 0))
	if _una("pie", t, 11.0):
		(_x["cam"] as Camera3D).queue_free()
		_vista.recorrer()
		_e = _vista.get("_explorador")
		var d := TunelVestuario.datos(_vista.get("_perfil"), StadiumBuilder.niveles_de(_vista.get("_perfil"), 20000))
		var x0: float = d["x0"]
		_ruta_pie = [Vector3(x0, 0, float(d["z_out"]) + 2.5), Vector3(x0, 0, float(d["z_boca"]) - 0.2),
			Vector3(x0, 0, 52.0), Vector3(30.0, 0, 30.0), Vector3(33.5, 0, 8.0)]
		_rotulo("A pie: del edificio del club al vestuario, el túnel y el césped (W/A/S/D, E para usar)")
		Input.parse_input_event(_tecla(KEY_W, true))
	if _e != null and _meta < _ruta_pie.size() and not _e.sentado and _e.get("_ruta").is_empty() and t >= 11.0:
		var meta := _ruta_pie[_meta]
		var dd := meta - _e.cuerpo.position
		dd.y = 0
		if dd.length() < 1.4:
			_meta += 1
			print("VG estadio: punto %d en t=%.1f" % [_meta, t])
			if _meta == 3:
				Input.parse_input_event(_tecla(KEY_SHIFT, true))
				_rotulo("Al salir del túnel: la grada llena, el ruido del estadio (corriendo con Mayús)")
			if _meta >= _ruta_pie.size():
				Input.parse_input_event(_tecla(KEY_W, false))
				Input.parse_input_event(_tecla(KEY_SHIFT, false))
				_e.sentarse()
				_rotulo("E junto a la grada: sube por la escalera y se sienta en su butaca (como el DT sancionado)")
		else:
			## Gira hacia el siguiente punto como lo haría el stick.
			var quiere := atan2(dd.x, dd.z)
			_e.rumbo = lerp_angle(_e.rumbo, quiere, 0.12)
	if _e != null and _e.sentado and _una("sentado", t, 0.0):
		_x["t_sentado"] = t
		print("VG estadio: sentado en t=%.1f" % t)
		_rotulo("Sentado: A/D giran la mirada por el estadio")
	if _x.has("t_sentado"):
		var k := t - float(_x["t_sentado"])
		var izq := k > 1.0 and k < 3.5
		var der := k > 4.5 and k < 9.0
		Input.parse_input_event(_tecla(KEY_A, izq))
		Input.parse_input_event(_tecla(KEY_D, der))

# ------------------------------------------------------------------ ciudad

var _v: VistaCiudad
var _ec: ExploradorCiudad

func _montar_ciudad() -> void:
	_principal()

func _paso_ciudad(t: float) -> void:
	if _una("abrir", t, 0.2):
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 10.5)
		_v.call("_aplicar_hora")
		_rotulo("La ciudad que rodea al club, vista desde el aire")
	if _v == null:
		return
	if t < 8.0:
		_v.set("_ang", 0.3 + t * 0.06)
		return
	if _una("pie", t, 8.0):
		_v.explorar("pie")
		_ec = _v.get("_explorador")
		_ec.cuerpo.position = Vector3(1005.0, 0, -500.0)
		_ec.cuerpo.position.y = _ec.altura_suelo(1005.0, -500.0)
		_ec.set("rumbo", PI)
		Input.parse_input_event(_tecla(KEY_W, true))
		_rotulo("A pie por la avenida comercial: peatones, semáforos, placas con el nombre de la calle")
	if _una("corre", t, 17.0):
		Input.parse_input_event(_tecla(KEY_SHIFT, true))
		_rotulo("Corriendo (Mayús): el móvil en la mano marca la velocidad")
	if _una("fp", t, 23.0):
		Input.parse_input_event(_tecla(KEY_SHIFT, false))
		_ec.primera_persona = true
		_rotulo("Primera persona (V)")
	if _una("coche", t, 30.0):
		Input.parse_input_event(_tecla(KEY_W, false))
		_ec.primera_persona = false
		_v.explorar("coche")
		_ec = _v.get("_explorador")
		_ec.cuerpo.position = Vector3(1005.0, 0, -470.0)
		_ec.cuerpo.position.y = _ec.altura_suelo(1005.0, -470.0)
		_ec.set("rumbo", PI)
		_ec.cam_coche = 0
		Input.parse_input_event(_tecla(KEY_W, true))
		_rotulo("Conducir: curva de potencia, frenada, freno de mano (ESPACIO)")
	if _una("capo", t, 42.0):
		_ec.cam_coche = 1
		_rotulo("Cámara de capó (V)")
	if _una("dentro", t, 49.0):
		_ec.cam_coche = 2
		_rotulo("Cámara interior: volante y cuentakilómetros")
	if _una("noche", t, 57.0):
		_ec.cam_coche = 0
		_v.set("_hora", 21.5)
		_v.call("_aplicar_hora")
		_rotulo("De noche: farolas, ventanas encendidas y los faros y luces de freno de los coches")
	if _una("frena", t, 68.0):
		Input.parse_input_event(_tecla(KEY_W, false))
		Input.parse_input_event(_tecla(KEY_S, true))
		_rotulo("Frenando")
	if _una("suelta", t, 71.0):
		Input.parse_input_event(_tecla(KEY_S, false))
	if t > 72.0 and _una("vuelo", t, 72.0):
		_v.explorar("")
		_rotulo("La ciudad de noche desde el aire")
	if t > 30.0 and t < 68.0 and _ec != null:
		## Un volante suave, como quien sigue la avenida.
		_ec.set("_volante", sin(t * 0.7) * 0.18)

# ------------------------------------------------------------------ carrera de jugador

func _montar_carrera() -> void:
	PartidoJugable.con_ceremonia = true
	CarreraJugadorUI.mundo = null
	var ui: CarreraJugadorUI = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(ui)
	_x["ui"] = ui
	_rotulo("Carrera de Jugador: empiezas con 17 años en un club de segunda")

func _paso_carrera(t: float) -> void:
	var ui: CarreraJugadorUI = _x["ui"]
	if _una("crear", t, 5.0):
		ui._crear()
		_rotulo("Tu jugador creado: atributos, club, contrato")
	if _una("partido", t, 11.0):
		var club := ui.carrera.club(CarreraJugadorUI.mundo)
		var par := ui._partido_de_la_semana(club)
		var pj := PartidoJugable.abrir(ui, CarreraJugadorUI.mundo, ui.carrera, par[0], par[1], 75.0)
		pj.motor.autopiloto = true
		_x["pj"] = pj
		_rotulo("Su partido: la misma ceremonia y el mismo motor que el del DT")
	if not _x.has("pj"):
		return
	var pj: PartidoJugable = _x["pj"]
	if not is_instance_valid(pj):
		return
	var m := pj.motor
	var c: Variant = pj.get("_ceremonia")
	var en_cer := c != null and is_instance_valid(c) and (c as CeremoniaPartido).activa
	if en_cer:
		return
	if _una("juega", t, 0.0):
		_x["t0"] = t
		_rotulo("Juegas solo tu posición: el resto lo decide la IA del equipo")
	var k := t - float(_x["t0"])
	if _una("corner", k, 22.0):
		m.autopiloto = false
		var d := MotorJugable.dir_ataque(bool(m.usuario["es_local"]))
		m._empezar_saque("corner", bool(m.usuario["es_local"]), Vector3(33.7, 0.11, 52.2 * d))
		_rotulo("Tu córner: apuntas y cargas la fuerza")
	if k > 22.5 and k < 25.5 and m.apuntando:
		m.apunte["fuerza"] = clampf((k - 22.5) / 2.5, 0.2, 0.75)
	if _una("lanza", k, 25.5):
		m._lanzar_usuario(0.62)
		m.autopiloto = true
	if _una("penal", k, 36.0):
		m.autopiloto = false
		m.lanza_usuario["penal"] = true
		var d2 := MotorJugable.dir_ataque(bool(m.usuario["es_local"]))
		m._empezar_saque("penal", bool(m.usuario["es_local"]), Vector3(0, 0.11, (52.5 - 11.0) * d2))
		_rotulo("Penal: lo tiras tú")
	if _una("tira", k, 40.0):
		m._lanzar_usuario(0.75)
		m.autopiloto = true

# ------------------------------------------------------------------ minijuegos

var _bot: MinijuegoMalabares

func _montar_mini() -> void:
	_principal()

func _paso_mini(t: float) -> void:
	if _una("sala", t, 0.3):
		SalaMinijuegos.abrir(_p, _mundo())
		_rotulo("Mi Vida → la sala de minijuegos")
	if _una("malabares", t, 5.0):
		for h in _p.get_children():
			if h is SalaMinijuegos:
				h.queue_free()
		_bot = MinijuegoMalabares.mostrar(_p, null)
		_rotulo("Malabares: toques sin que caiga el balón (récord guardado)")
	if _bot != null and is_instance_valid(_bot):
		if _bot._fin:
			_bot._reiniciar()
		if _bot._y > 0.8:
			_bot._pie = _bot._x
			_bot._tocar()
