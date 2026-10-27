class_name PrologoDT
extends Control
## EL PRÓLOGO 3D (fase 2 del plan del lunes, 26-10-2026): de «Nuevo juego» a tu
## primer día. Apareces en la acera frente a la puerta del club, en la ciudad
## real de tu club; el mentor de tu modo (`Tutorial.mentor_de`) te enseña a
## moverte, te lleva por el edificio (vestuario, campo, enfermería), te
## presenta a la directiva, te sienta ante la prensa y te entrega tu oficina,
## donde el PC enciende el menú central de siempre (`PcOficina`).
##
## Reutiliza el mundo que ya existe (`VistaCiudad` + `ExploradorCiudad`): aquí
## solo se decide QUÉ TOCA (el paso del guion de `PrologoPasos`), dónde espera
## el mentor y cuándo hablas. Esta escena la abre `OrquestadorMundo.preparar()`
## con `Principal.mundo_pregenerado` ya listo, y NO lo consume: lo necesita
## `Principal` cuando enciendas el PC.

signal terminado

const ESCENA_PRINCIPAL := "res://escenas/principal.tscn"
const SEG_PRESENTACION := 4.0
const RADIO_LLEGADA := 1.8
## Las pruebas lo ponen: sin plano de presentación ni esperas del mentor.
static var rapido := false
## Partida cargada (fase 3, bloque 7): "" = el guion entero; "oficina" o "casa" = sin
## guion, aparecer ahí con el PC listo (lo pone `Inicio` según `VidaCiudad.arranque_3d`).
static var directo := ""

var mundo: Mundo
var club: Club
var vista: VistaCiudad
var explorador: ExploradorCiudad
var mentor: PrologoMentor
var hud: PrologoHud
var dialogo: CuadroDialogo
var pc: PcOficina
var prensa: PrologoPrensa
var vida: VidaCiudad
var est: Dictionary = {}        ## `TunelVestuario.datos` del estadio del club
var puerta := Vector3.ZERO      ## la puerta del club, en el mundo
var paso_i := -1
var frases: Array[String] = []
var frase_i := -1
var destino := Vector3.INF
var destino_planta := 0
var esperando_llegada := false
var esperando_entrada := false
var _aro: MeshInstance3D
var _directivos: Array[PrologoMentor] = []
var _directiva_hecha := false
var _guardado_al_encender := false
var _listo := false

func _ready() -> void:
	mundo = Principal.mundo_pregenerado if Principal.mundo_pregenerado != null else Principal.mundo_a_cargar
	club = mundo.mi_club() if mundo != null else null
	if club == null or mundo.obras == null or mundo.ciudad == null:
		## Sin mundo que recorrer (una prueba vieja, un guardado raro): al menú de siempre.
		_a_principal()
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	PantallaCarga.club = club
	var carga := PantallaCarga.mostrar(self, Idiomas.t("Construyendo la ciudad…"))
	await get_tree().process_frame
	await get_tree().process_frame
	_construir_mundo()
	if is_instance_valid(carga):
		carga.cerrar()
	hud = PrologoHud.new()
	add_child(hud)
	hud.saltar_confirmado.connect(_saltar)
	hud.directiva_respondida.connect(_responder_directiva)
	dialogo = CuadroDialogo.new()
	add_child(dialogo)
	dialogo.visible = false
	if not rapido and directo == "":
		hud.presentacion(PaisDatos.nombre(club.pais), Nombres.visible(club.nombre), SEG_PRESENTACION)
		await get_tree().create_timer(SEG_PRESENTACION).timeout
	_empezar_a_pie()
	_listo = true
	if directo != "":
		_arrancar_directo(directo)
	else:
		_ir_al_paso(0)

## La ciudad del club (misma semilla y estadio que la ciudad de siempre).
func _construir_mundo() -> void:
	vista = VistaCiudad.new()
	add_child(vista)
	vista.animo = CiudadAnimo.de(mundo, club)
	var perfil := mundo.perfil_estadio_de(club)
	vista.abrir(club, mundo.obras, mundo.ciudad, perfil)
	est = TunelVestuario.datos(perfil, StadiumBuilder.niveles_de(perfil, int(perfil.get("aforo", 20000))))
	puerta = CityBuilder.ESTADIO_EN + (est["puerta"] as Vector3)
	## La cámara aérea mira al estadio mientras dura la presentación.
	vista._objetivo_deseado = CityBuilder.ESTADIO_EN
	vista._dist = 220.0
	vista._girando = true
	## Sin los rótulos flotantes del mapa (nombres de plazas y puentes): es un plano
	## de presentación, no el mapa de gestión (captura f2p_1 del 26-10).
	vista._ciudad.mostrar_rotulos(false)
	## Tu primer día empieza a media mañana y la luz no corre sola (la ciudad da una
	## vuelta de 24 h cada 2 min): la fase 3 atará esta hora al reloj de la partida.
	vista._ciclo_activo = false
	vista._hora = 10.0
	vista._aplicar_hora()

func _empezar_a_pie() -> void:
	vista.explorar("pie", puerta + Vector3(0, 0, 7.0))
	explorador = vista._explorador
	## Esc en el paseo cerraría el explorador: aquí pregunta si saltar el prólogo.
	if explorador.salir.is_connected(vista._dejar_de_explorar):
		explorador.salir.disconnect(vista._dejar_de_explorar)
	explorador.salir.connect(hud.pedir_saltar)
	explorador.rumbo = PI
	explorador.cuerpo.rotation.y = PI
	var ctx := Tutorial.contexto(mundo, club.nombre)
	var modo := mundo.roles.modo_actual() if mundo.roles != null else "dt"
	mentor = PrologoMentor.new()
	vista._raiz3d.add_child(mentor)
	mentor.crear(Tutorial.mentor_de(modo, ctx), Color(club.color1), Color(club.color2))
	mentor.colocar(puerta + Vector3(0.8, 0.02, 3.0), 0.0)
	_aro = PcOficina.crear_aro(vista._raiz3d, Color(1.0, 0.82, 0.3))
	_aro.visible = false
	vida = VidaCiudad.enganchar(explorador, vista, mundo)

## Partida cargada: sin guion. El PC queda en la oficina; apareces allí o, el lunes a
## las 08:00, en tu casa (y vas al club como quieras).
func _arrancar_directo(d: String) -> void:
	directo = ""
	paso_i = PrologoPasos.indice("oficina")
	destino = _centro_zona("Oficina del DT", 1)
	destino_planta = 1
	_entregar_oficina()
	mentor.visible = false
	if d == "casa" and vida != null:
		vida.entrar_casa()
		return
	explorador._entrar_al_estadio()
	explorador._ir_a_planta(1)
	explorador.cuerpo.position = destino + Vector3(0, 0, 2.2)
	explorador.rumbo = PI
	explorador.cuerpo.rotation.y = PI
	explorador._colocar_camara(1.0)

# ---------------------------------------------------------------- el guion

func _ir_al_paso(i: int) -> void:
	if i >= PrologoPasos.PASOS.size():
		return
	paso_i = i
	var p: Dictionary = PrologoPasos.PASOS[i]
	frases = PrologoPasos.frases_de(p, mentor.nombre)
	frase_i = -1
	hud.tarjeta(PrologoPasos.tarjeta_controles(p))
	esperando_entrada = false
	match String(p["clave"]):
		"llegada":
			## Habla al momento; el objetivo es acercarse a él.
			destino = mentor.position
			destino_planta = 0
			esperando_llegada = false
			_hablar()
		"puerta":
			destino = puerta + Vector3(0, 0, 1.6)
			destino_planta = 0
			esperando_llegada = true
		_:
			destino = _centro_zona(String(p["zona"]), int(p["planta"]))
			destino_planta = int(p["planta"])
			esperando_llegada = true
			if rapido:
				mentor.colocar(destino, PI)
			else:
				## Se adelanta desde donde estaba y aparece esperando en la sala.
				mentor.adelantarse(destino)
				get_tree().create_timer(2.2).timeout.connect(func() -> void:
					if is_instance_valid(mentor) and paso_i == i:
						mentor.colocar(destino, PI))
	_aro.position = destino + Vector3(0, 0.04, 0)

## El centro de la sala `zona` en la planta dada (la zona más grande con ese
## nombre: las salas tienen además la zona de su puerta), en el mundo.
func _centro_zona(zona: String, planta: int) -> Vector3:
	var mejor: Rect2 = Rect2()
	for z: Dictionary in est["zonas"]:
		if String(z["nombre"]) == zona and int(z.get("planta", 0)) == planta:
			var r: Rect2 = z["r"]
			if r.get_area() > mejor.get_area():
				mejor = r
	var c := mejor.get_center()
	return CityBuilder.ESTADIO_EN + Vector3(c.x, RecorridoClub.y_de(planta), c.y)

func _hablar() -> void:
	frase_i += 1
	if frase_i >= frases.size():
		dialogo.cerrar()
		mentor.hablar(false)
		explorador._t_burbuja = 0.0
		explorador.pausar(false)
		_tras_hablar()
		return
	explorador.pausar(true)
	## Plano de conversación del paseo (tras tu hombro, encuadrando su cara): en
	## las salas del edificio la cámara normal se salía por la pared (toma 6).
	explorador._hablando_con = mentor
	explorador._t_burbuja = 120.0
	explorador._colocar_camara(1.0)
	mentor.mirar_a(explorador.cuerpo.position)
	if frase_i == 0:
		mentor.hablar(true)
	dialogo.decir(mentor.nombre, frases[frase_i], Color(club.color1).lerp(Color.WHITE, 0.35), frase_i, frases.size())

## Lo que pasa cuando el mentor termina de hablar en este paso.
func _tras_hablar() -> void:
	var p: Dictionary = PrologoPasos.PASOS[paso_i]
	match String(p["clave"]):
		"llegada":
			esperando_llegada = true
		"puerta":
			esperando_entrada = true
		_:
			if bool(p.get("directiva", false)) and not _directiva_hecha:
				_abrir_directiva()
			elif bool(p.get("prensa", false)):
				_abrir_prensa()
			elif bool(p.get("pc", false)):
				_entregar_oficina()
			else:
				_ir_al_paso(paso_i + 1)

func _process(_delta: float) -> void:
	if not _listo or explorador == null or not is_instance_valid(explorador):
		return
	var yo := explorador.cuerpo.position
	var dentro := String(explorador.estado) == "estadio"
	var planta := int(explorador._planta)
	if esperando_entrada and dentro:
		esperando_entrada = false
		_ir_al_paso(paso_i + 1)
		return
	var fuera := bool(PrologoPasos.PASOS[paso_i].get("fuera", false)) if paso_i >= 0 else true
	var misma_planta := (fuera and not dentro) or (not fuera and dentro and planta == destino_planta)
	var d := Vector2(yo.x - destino.x, yo.z - destino.z).length() if destino != Vector3.INF else 0.0
	_aro.visible = destino != Vector3.INF and misma_planta and not dialogo.visible
	if destino != Vector3.INF and not dialogo.visible and not (pc != null and pc.abierto):
		var adelante := -explorador.camara.global_transform.basis.z
		var hacia := Vector3(destino.x - yo.x, 0, destino.z - yo.z)
		var ang := atan2(hacia.x, hacia.z) - atan2(adelante.x, adelante.z)
		var otra := "" if misma_planta else (Idiomas.t("planta %+d · usa el ascensor") % destino_planta if dentro else Idiomas.t("entra al estadio"))
		hud.flecha(true, ang, d, otra)
	else:
		hud.flecha(false)
	if esperando_llegada and misma_planta and d < RADIO_LLEGADA:
		esperando_llegada = false
		if String(PrologoPasos.PASOS[paso_i]["clave"]) == "llegada":
			_ir_al_paso(paso_i + 1)
		else:
			_hablar()

func _input(ev: InputEvent) -> void:
	if not dialogo.visible:
		return
	var sigue := (ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo \
			and (ev as InputEventKey).keycode in [KEY_E, KEY_ENTER, KEY_SPACE]) \
		or (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed \
			and (ev as InputEventJoypadButton).button_index in [JOY_BUTTON_X, JOY_BUTTON_A]) \
		or (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed)
	if not sigue:
		return
	get_viewport().set_input_as_handled()
	if dialogo.escribiendo():
		dialogo.completar()
	else:
		_hablar()

# ------------------------------------------------------- directiva y prensa

func _abrir_directiva() -> void:
	var q := PrologoPasos.PREGUNTA_DIRECTIVA
	var quien := String(mundo.junta.presidente.get("nombre", "")) if mundo.junta != null else ""
	if quien == "":
		quien = Idiomas.t("Presidente")
	## Dos directivos de carne y hueso acompañan al presidente (los accionistas de la junta).
	if mundo.junta != null and _directivos.is_empty():
		var k := 0
		for a: Dictionary in mundo.junta.accionistas:
			if k >= 2:
				break
			var dir := PrologoMentor.new()
			vista._raiz3d.add_child(dir)
			dir.crear({"nombre": String(a.get("nombre", "")), "cargo": Idiomas.t("Directivo"), "semilla": "dir_" + String(a.get("nombre", "")), "canas": k == 1}, Color(club.color1), Color(club.color2))
			dir.colocar(destino + Vector3(-1.2 + 2.4 * k, 0, -1.4), PI)
			_directivos.append(dir)
			k += 1
	var opciones: Array[String] = []
	for o: Dictionary in q["opciones"]:
		opciones.append(Idiomas.t(String(o["texto"])))
	explorador.pausar(true)
	hud.pregunta_directiva(quien, Color(club.color1), Idiomas.t(String(q["pregunta"])), opciones)

func _responder_directiva(i: int) -> void:
	_directiva_hecha = true
	var o: Dictionary = PrologoPasos.PREGUNTA_DIRECTIVA["opciones"][i]
	if mundo.directiva != null:
		mundo.directiva.confianza = clampi(mundo.directiva.confianza + int(o["confianza"]), 0, 100)
	var quien := String(mundo.junta.presidente.get("nombre", "")) if mundo.junta != null else Idiomas.t("Presidente")
	frases = [Idiomas.t(String(o["respuesta"]))]
	frase_i = -1
	## La respuesta del presidente sale por el mismo cuadro; al cerrarla sigue el guion.
	frase_i = 0
	dialogo.decir(quien, frases[0], Color(0.75, 0.62, 0.25), 0, 1)

func _abrir_prensa() -> void:
	explorador.pausar(true)
	prensa = PrologoPrensa.new()
	add_child(prensa)
	var look: Dictionary = mundo.roles.look_efectivo() if mundo.roles != null else {}
	prensa.montar(mundo, club, Color(club.color1), look)
	prensa.terminado.connect(func(_r: Dictionary) -> void:
		prensa = null
		explorador.pausar(false)
		_ir_al_paso(paso_i + 1))

# ------------------------------------------------------------ la oficina

func _entregar_oficina() -> void:
	pc = PcOficina.new()
	add_child(pc)
	pc.mundo = mundo
	pc.mundo_3d = vista
	pc.explorador = explorador
	## El punto de uso: delante del escritorio (la mesa está 0,6 m al fondo de la sala).
	pc.montar(vista._raiz3d, destino + Vector3(0, 0, 0.9), destino_planta)
	destino = pc.punto
	_aro.visible = false
	_aro.queue_free()
	_aro = pc._aro
	pc.encendido.connect(_al_encender_pc)
	mentor.adelantarse(destino + Vector3(3.0, 0, 2.0))

## La primera vez que enciendes el PC el prólogo queda hecho y la partida se guarda.
func _al_encender_pc() -> void:
	if _guardado_al_encender:
		return
	_guardado_al_encender = true
	mundo.prologo_visto = true
	var pr := pc.principal()
	if pr != null and pr.get("_partida") != null:
		pr.get("_partida").guardar_en("partida")
	terminado.emit()

# ----------------------------------------------------------------- salir

func _saltar() -> void:
	if mundo != null:
		mundo.prologo_visto = true
	_a_principal()

func _a_principal() -> void:
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file(ESCENA_PRINCIPAL)
