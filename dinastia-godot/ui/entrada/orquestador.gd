class_name OrquestadorEntrada
extends Control
## LA ENTRADA AL JUEGO (fase 1 del MEGAPLAN, 25-10-2026). Encadena las etapas 0-6 de
## `docs/PLAN_DEL_LUNES.md` §2.1 («El flujo»): intro → idioma → menú de modos → país →
## configuración del club → entrada al campeonato → personaje. Cada etapa es una pantalla
## PROPIA a pantalla completa (`ui/entrada/*.gd`, las construyen otros); aquí solo se
## decide cuál toca, se funde de una a otra (nunca dos a la vez: la anterior se libera
## antes de enseñar la siguiente), se guarda lo elegido y se puede volver atrás.
## Al final, `OrquestadorMundo.preparar()` crea la partida con el MISMO camino de siempre
## (`Principal.mundo_pregenerado`, como `ui/eleccion_club.gd`) y se pasa a Principal.
##
## CONTRATO de cada pantalla (no cambiarlo: lo cumplen siete pantallas hechas en paralelo):
##   extends Control, a pantalla completa
##   signal terminado(datos: Dictionary)   ## confirmada; `datos` es lo que eligió
##   signal volver()                       ## quiere la etapa anterior
##   func configurar(estado: Dictionary) -> void   ## el estado acumulado del flujo
## CÓMO SE GUARDA `datos`: si trae la clave de su etapa (p. ej. la de país emite
## `{"pais": "ARG", "club_id": "c40"}`), todas sus claves pasan al estado tal cual (así una
## pantalla puede dar más de un dato); si no la trae, se guarda entero bajo esa clave
## (`{"casa": "depto", "fps": 60}` → `estado["config"]`). Claves: idioma, modo, pais,
## config, entrada, personaje (+ «mundo»: el mundo ya generado, para que país y entrada
## puedan enseñar clubes reales).
## Si una pantalla todavía no existe o no carga, va un sustituto mínimo
## (`orquestador_sustituto.gd`) con los valores por defecto: el flujo funciona siempre.

## Una etapa terminó y el estado ya tiene lo suyo (para pruebas y capturas).
signal etapa_cambiada(clave: String)
## Se creó la partida: `resultado` = {"escena": ruta, "mundo": Mundo o null}.
signal partida_lista(resultado: Dictionary)
## Se volvió atrás desde la primera etapa (sin `cambiar_escena`, no se sale al menú).
signal cancelado()

const ETAPAS := [
	{"clave": "intro", "ruta": "res://ui/entrada/intro.gd", "titulo": "Intro"},
	{"clave": "idioma", "ruta": "res://ui/entrada/idioma.gd", "titulo": "Idioma"},
	{"clave": "modo", "ruta": "res://ui/entrada/menu_modos.gd", "titulo": "Modo de juego"},
	{"clave": "pais", "ruta": "res://ui/entrada/pais.gd", "titulo": "País"},
	{"clave": "config", "ruta": "res://ui/entrada/config_club.gd", "titulo": "Configuración del club"},
	{"clave": "entrada", "ruta": "res://ui/entrada/entrada_campeonato.gd", "titulo": "Entrada al campeonato"},
	{"clave": "personaje", "ruta": "res://ui/entrada/personaje.gd", "titulo": "Personaje"},
]
const SUSTITUTO := "res://ui/entrada/orquestador_sustituto.gd"
const MENU_VIEJO := "res://escenas/inicio.tscn"

## La intro se ve la primera vez; después se salta (pedido del plan, etapa 0). Archivo
## propio: `preferencias.cfg` lo reescribe Principal entero y borraría la marca.
static var ruta_prefs := "user://entrada.cfg"
## Lo que el menú viejo ya sabía (dificultad, nombre tecleado) para empezar con eso.
static var estado_inicial: Dictionary = {}

## Las pruebas lo apagan: sin cambio de escena al final ni al cancelar.
var cambiar_escena := true
## Segundos de cada medio fundido (a negro y desde negro). 0 = cambio inmediato, síncrono.
var duracion_fundido := 0.25
## Forzar la intro aunque ya se haya visto (atajo de desarrollo y capturas).
var forzar_intro := false

var estado: Dictionary = {}
var _indice := -1
var _historial: Array[int] = []
var _pantalla: Control = null
var _velo: ColorRect
var _aviso_velo: Label
var _en_transicion := false
var _terminado := false

func _ready() -> void:
	## Con offsets: dentro del árbol, `set_anchors_preset` solo conservaría el tamaño (0) de un nodo nuevo.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	_velo = ColorRect.new()
	_velo.color = Color.BLACK
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo.modulate.a = 0.0
	add_child(_velo)
	_aviso_velo = Tema.etiqueta(Tema.TAM_TITULO, Tema.SUAVE, "")
	_aviso_velo.set_anchors_preset(Control.PRESET_CENTER)
	_aviso_velo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_aviso_velo.grow_vertical = Control.GROW_DIRECTION_BOTH
	_aviso_velo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_velo.add_child(_aviso_velo)
	estado = estado_inicial.duplicate(true)
	estado_inicial = {}
	if not estado.has("idioma"):
		estado["idioma"] = Idiomas.idioma
	## La intro lo lee para ofrecer «saltar» desde el primer momento si ya se vio.
	estado["intro_vista"] = intro_vista()
	## A/B del mando para toda la entrada (lo define la pantalla de idioma).
	OrquestadorMundo._llamar("res://ui/entrada/idioma.gd", "preparar_mando", [])
	## Primera etapa en el frame siguiente: quien lo instancia (prueba, escena) puede
	## ajustar `duracion_fundido`/`forzar_intro` antes de que arranque.
	_empezar.call_deferred()

func _empezar() -> void:
	if _indice >= 0 or _terminado:
		return
	var primera := _siguiente_desde(-1)
	_ir_a(primera, true)

# --- qué etapa toca -------------------------------------------------------------

func indice_de(clave: String) -> int:
	for i in ETAPAS.size():
		if String(ETAPAS[i]["clave"]) == clave:
			return i
	return -1

func etapa_actual() -> String:
	return String(ETAPAS[_indice]["clave"]) if _indice >= 0 and _indice < ETAPAS.size() else ""

func pantalla_actual() -> Control:
	return _pantalla if is_instance_valid(_pantalla) else null

func historial() -> Array[int]:
	return _historial.duplicate()

## ¿Se enseña esta etapa con lo que ya se eligió? Las reglas del plan:
## la intro solo la primera vez; la entrada al campeonato solo si creas un club (si
## diriges uno que ya existe, ya está en su liga); un reto pone él club y liga.
func etapa_aplica(i: int) -> bool:
	match String(ETAPAS[i]["clave"]):
		"intro":
			return forzar_intro or not intro_vista()
		"pais":
			return OrquestadorMundo.modo_id(estado) != "retos"
		"entrada":
			return OrquestadorMundo.crea_club(estado) and OrquestadorMundo.modo_id(estado) != "retos"
	return true

func _siguiente_desde(i: int) -> int:
	var j := i + 1
	while j < ETAPAS.size() and not etapa_aplica(j):
		j += 1
	return j

## Tras elegir modo, algunos no siguen por aquí: la Carrera de Jugador tiene su propia
## creación y «continuar» carga la partida guardada.
func _sale_del_flujo() -> bool:
	return etapa_actual() == "modo" and OrquestadorMundo.modo_id(estado) in ["carrera-m", "continuar"]

# --- avanzar y volver -------------------------------------------------------------

func _al_terminar(datos: Dictionary, quien: Control) -> void:
	if quien != _pantalla or _en_transicion or _terminado:
		return
	var clave := etapa_actual()
	guardar_datos(clave, datos)
	match clave:
		"intro":
			marcar_intro_vista()
		"idioma":
			## Al momento: las pantallas siguientes ya se pintan en el idioma elegido.
			OrquestadorMundo.aplicar_idioma(estado)
	etapa_cambiada.emit(clave)
	if _sale_del_flujo():
		_finalizar()
		return
	var sig := _siguiente_desde(_indice)
	if sig >= ETAPAS.size():
		_finalizar()
	else:
		_ir_a(sig, true)

## Guarda lo que devolvió una pantalla según la regla de la cabecera.
func guardar_datos(clave: String, datos: Dictionary) -> void:
	if datos.has(clave):
		for k: Variant in datos:
			estado[k] = datos[k]
	else:
		estado[clave] = datos.duplicate(true)
	_normalizar(clave)

## «modo» y «pais» quedan SIEMPRE como texto (el id del modo, el código del país): así
## las pantallas siguientes pueden hacer `String(estado["modo"])` sin mirar la forma. Si
## llegaron como diccionario, sus otros datos (crear, reto, dificultad, club_id) pasan al
## estado y el diccionario entero queda en «modo_datos»/«pais_datos».
func _normalizar(clave: String) -> void:
	if not clave in ["modo", "pais"] or not (estado.get(clave) is Dictionary):
		return
	var d: Dictionary = estado[clave]
	estado[clave + "_datos"] = d.duplicate(true)
	estado[clave] = String(d.get("id", d.get(clave, d.get("codigo", ""))))
	for k: String in ["crear", "reto", "dificultad", "club_id"]:
		if d.has(k) and not estado.has(k):
			estado[k] = d[k]

func _al_volver(quien: Control) -> void:
	if quien != _pantalla or _en_transicion or _terminado:
		return
	volver_atras()

func volver_atras() -> void:
	## La intro no se repite al volver: se busca la última etapa del historial que no sea ella.
	while not _historial.is_empty():
		var previa: int = _historial.pop_back()
		if String(ETAPAS[previa]["clave"]) != "intro":
			_ir_a(previa, false)
			return
	_cancelar()

func _cancelar() -> void:
	_terminado = true
	cancelado.emit()
	if cambiar_escena and is_inside_tree():
		get_tree().change_scene_to_file(MENU_VIEJO)

# --- montar cada pantalla ---------------------------------------------------------

## Instancia la pantalla de la etapa i, o el sustituto si no existe o no cumple el contrato.
func crear_pantalla(i: int) -> Control:
	var ruta := String(ETAPAS[i]["ruta"])
	var n: Control = null
	if ResourceLoader.exists(ruta):
		var s: Variant = load(ruta)
		if s is Script and (s as Script).can_instantiate():
			var o: Variant = (s as Script).new()
			if o is Control and (o as Control).has_signal("terminado") and (o as Control).has_signal("volver") \
					and (o as Control).has_method("configurar"):
				n = o
			elif o is Node:
				(o as Node).free()
	if n == null:
		var sus: Control = (load(SUSTITUTO) as Script).new()
		sus.set("clave", String(ETAPAS[i]["clave"]))
		sus.set("titulo", String(ETAPAS[i]["titulo"]))
		sus.set("por_defecto", OrquestadorMundo.por_defecto(String(ETAPAS[i]["clave"]), estado))
		n = sus
	n.set_meta("sustituto", n.get_script() != null and (n.get_script() as Script).resource_path == SUSTITUTO)
	return n

func _montar(i: int) -> void:
	if is_instance_valid(_pantalla):
		## Nunca dos pantallas a la vez: la anterior se va antes de que entre la nueva.
		remove_child(_pantalla)
		_pantalla.queue_free()
	_pantalla = null
	_indice = i
	var clave := String(ETAPAS[i]["clave"])
	if clave in ["pais", "config", "entrada", "personaje"]:
		asegurar_mundo()
	var n := crear_pantalla(i)
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.connect("terminado", _al_terminar.bind(n))
	n.connect("volver", _al_volver.bind(n))
	estado["paso"] = i
	estado["intro_vista"] = intro_vista()
	if clave == "intro" and Musica.encendida:
		## La intro trae su propio sonido: la música no se le monta encima.
		Musica.parar()
	## Se configura ANTES de entrar al árbol: su `_ready` ya ve lo elegido.
	n.call("configurar", estado)
	add_child(n)
	move_child(_velo, -1)
	_pantalla = n

## Cambia a la etapa i con fundido. `avanza` = se apila la actual para poder volver.
func _ir_a(i: int, avanza: bool) -> void:
	if avanza and _indice >= 0:
		_historial.append(_indice)
	if duracion_fundido <= 0.0 or not is_inside_tree():
		_montar(i)
		return
	_en_transicion = true
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_velo, "modulate:a", 1.0, duracion_fundido if _indice >= 0 else 0.0)
	tw.tween_callback(func() -> void:
		var clave := String(ETAPAS[i]["clave"])
		if not (estado.get("mundo") is Mundo) and clave in ["pais", "config", "entrada", "personaje"]:
			## La generación del mundo (24 ligas) tarda: se avisa sobre el negro y se
			## deja pintar ese aviso antes de bloquear.
			_aviso_velo.text = Idiomas.t("Generando el mundo…")
			await get_tree().process_frame
			await get_tree().process_frame
		_montar(i)
		_aviso_velo.text = ""
		var tw2 := create_tween()
		tw2.tween_property(_velo, "modulate:a", 0.0, duracion_fundido)
		tw2.tween_callback(func() -> void:
			_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_en_transicion = false))

# --- el mundo y el final ----------------------------------------------------------

## El mundo se genera una vez, al llegar a la primera etapa que enseña clubes; volver
## atrás y cambiar de modo no lo regenera (son ~10.000 jugadores).
func asegurar_mundo() -> Mundo:
	if estado.get("mundo") is Mundo:
		return estado["mundo"]
	var m := OrquestadorMundo.generar_mundo()
	estado["mundo"] = m
	return m

func _finalizar() -> void:
	_terminado = true
	var res := OrquestadorMundo.preparar(estado)
	partida_lista.emit(res)
	if not cambiar_escena or not is_inside_tree():
		return
	var escena := String(res.get("escena", MENU_VIEJO))
	if duracion_fundido <= 0.0:
		get_tree().change_scene_to_file(escena)
		return
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_velo, "modulate:a", 1.0, duracion_fundido)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(escena))

# --- la intro, solo la primera vez --------------------------------------------------

static func intro_vista() -> bool:
	var cf := ConfigFile.new()
	if cf.load(ruta_prefs) != OK:
		return false
	return bool(cf.get_value("entrada", "intro_vista", false))

static func marcar_intro_vista(si: bool = true) -> void:
	var cf := ConfigFile.new()
	cf.load(ruta_prefs)
	cf.set_value("entrada", "intro_vista", si)
	cf.save(ruta_prefs)
