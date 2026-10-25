class_name ConfigClubDatos
extends RefCounted
## LO QUE SE ELIGE EN LA CONFIGURACIÓN DEL CLUB (fase 1, etapa 4 del flujo de entrada).
##
## Es el MODELO de `PantallaConfigClub`: la pantalla solo pinta y edita esto. Se
## separa a propósito para que la etapa no toque el mundo ni las preferencias
## mientras el jugador duda: todo se queda aquí hasta la confirmación, y el
## orquestador lo aplica después con `aplicar_al_club()` y `aplicar_maquina()`.
##
## La identidad visual vive en un `Club` de MENTIRA (`club`): así el escudo y la
## camiseta de la vista previa salen de las mismas funciones que pintan el club
## en el resto del juego (`Escudo.textura`, `DisenosKit.kit_de_club`), y lo que
## se ve aquí es exactamente lo que se verá después.
##
## EL DICCIONARIO QUE SALE (`a_dic()`, el que va en `terminado({"config": …})`):
##   version: 1
##   club: {
##     nombre, estadio_nombre (""= «Estadio <nombre>»), color1, color2 ("#rrggbb"), lema,
##     identidad: el mismo formato que `Club.identidad_a_dic()` (kit_c1, kit_c2, kit_est,
##                kit_x, esc_c1, esc_c2, esc_f, esc_p, esc_s, esc_e, ui),
##     mascota: clave de `MascotaQ.ANIMALES` ("oso", "aguila"…),
##     estilo_estadio: clave de `EstadioPropio.presets()` o "" (= el estadio que ya tiene) }
##   vida: { vivienda: clave de `VidaDT.VIVIENDAS` }
##   maquina: { fps (30/60/120/0 = sin límite), contador_fps, calidad (Calidad.MEDIO/ALTO/ULTRA),
##              adaptativa, motor_ligero, densidad ("baja"/"media"/"alta") }

## Las mismas opciones que `Principal.FPS_OPCIONES` (la prueba lo comprueba):
## no se lee de ahí para no cargar el menú central entero en esta etapa.
const FPS := [30, 60, 120, 0]
## La gente por la calle. Ningún sistema la leía hasta hoy: el factor queda en
## `user://ajustes.cfg` [ciudad] densidad / densidad_factor para que el paseo lo use.
const DENSIDADES := {
	"baja": ["Tranquila", "Calles casi vacías: la ciudad más fluida en equipos modestos.", 0.6, "🚶"],
	"media": ["Animada", "El ritmo normal de un barrio con fútbol.", 1.0, "🚶‍♂️🚶"],
	"alta": ["Bulliciosa", "Aceras llenas, sobre todo en día de partido. Pide más equipo.", 1.4, "👥"],
}
const ORDEN_DENSIDAD := ["baja", "media", "alta"]
## El nombre de cada animal de `MascotaQ.ANIMALES`, con su icono.
const ANIMALES := {
	"perro": ["Perro", "🐕"], "gato": ["Gato", "🐈"], "oso": ["Oso", "🐻"], "aguila": ["Águila", "🦅"],
	"leon": ["León", "🦁"], "toro": ["Toro", "🐂"], "zorro": ["Zorro", "🦊"], "lobo": ["Lobo", "🐺"],
	"tigre": ["Tigre", "🐅"], "gallo": ["Gallo", "🐓"], "dragon": ["Dragón", "🐉"], "caballo": ["Caballo", "🐎"],
	"conejo": ["Conejo", "🐇"], "pinguino": ["Pingüino", "🐧"], "cocodrilo": ["Cocodrilo", "🐊"],
	"buho": ["Búho", "🦉"], "mono": ["Mono", "🐒"], "tiburon": ["Tiburón", "🦈"],
}
const NOMBRE_MIN := 3
const NOMBRE_MAX := 32
const ESTADIO_MAX := 40
## Por debajo de esta distancia (0..1.73, en RGB) dos colores casi no se distinguen.
const COLORES_PARECIDOS := 0.16

var club: Club
var lema: String = ""
var mascota: String = "oso"
var estilo_estadio: String = ""
var vivienda: String = "depto"
var fps: int = 60
var contador_fps: bool = false
var calidad: int = Calidad.ALTO
var adaptativa: bool = true
var motor_ligero: bool = false
var densidad: String = "media"

## Para validar que el nombre no repita el de otro club (puede ser null).
var mundo: Mundo = null
## El id del club real que se va a configurar (para no chocar consigo mismo).
var id_real: String = ""
## true = se funda un club nuevo: el nombre lo pone el jugador. false = se toma un
## club que ya existe: su nombre es su historia y no se cambia aquí.
var crea_club: bool = true

func _init() -> void:
	club = Club.new("config_nuevo", "")
	club.color1 = "#1e4030"
	club.color2 = "#c9a227"

## Arranca con lo que traiga el estado del orquestador (`OrquestadorEntrada.estado`).
## Claves que se leen (todas opcionales): mundo, club (un `Club` o su id), club_id,
## pais {club_id, crear}, modo, crear, nombre_club, color1, color2 y config (lo que
## emitió esta misma etapa antes, para volver a ella sin perder nada). «nombre» NO
## se lee: en el estado es el nombre del DT.
func desde_estado(estado: Dictionary) -> void:
	mundo = estado.get("mundo") as Mundo if estado.get("mundo") is Mundo else null
	crea_club = _pide_crear(estado)
	var base: Club = estado.get("club") as Club if estado.get("club") is Club else null
	if base == null and mundo != null and not crea_club:
		var pais_d: Dictionary = estado.get("pais") if estado.get("pais") is Dictionary else {}
		for id: String in [String(estado.get("club_id", "")), String(estado.get("club", "")) if estado.get("club") is String else "",
				String(pais_d.get("club_id", ""))]:
			if id != "" and mundo.clubes.has(id):
				base = mundo.clubes[id]
				break
		if base == null:
			base = mundo.mi_club()
	if base != null:
		id_real = base.id
		club = Club.new(base.id, base.nombre)
		club.color1 = base.color1
		club.color2 = base.color2
		club.estadio_nombre = base.estadio_nombre
		club.rep = base.rep
		club.estadio_aforo = base.estadio_aforo
		club.identidad_desde_dic(base.identidad_a_dic())
		mascota = EstadioExtras.animal_de(base)
		crea_club = false
	if String(estado.get("nombre_club", "")).strip_edges() != "":
		club.nombre = String(estado["nombre_club"]).strip_edges()
	for k: String in ["color1", "color2"]:
		if Color.html_is_valid(String(estado.get(k, ""))):
			club.set(k, String(estado[k]))
	if mundo != null and not crea_club:
		if mundo.comercial != null and mundo.mi_club() == base:
			lema = mundo.comercial.lema
		if mundo.vida != null:
			vivienda = mundo.vida.vivienda
	_leer_maquina()
	_concretar()
	if estado.get("config") is Dictionary:
		desde_dic(estado["config"] as Dictionary)

## ¿Se funda un club (y entonces el nombre se elige aquí)? La misma regla que
## `OrquestadorMundo.crea_club()` sin mirar «config», que es lo que emite esta etapa.
static func _pide_crear(estado: Dictionary) -> bool:
	var modo: Variant = estado.get("modo")
	if (modo is String and String(modo) == "creador") or (modo is Dictionary and
			(String((modo as Dictionary).get("id", (modo as Dictionary).get("modo", ""))) == "creador" or bool((modo as Dictionary).get("crear", false)))):
		return true
	if bool(estado.get("crear", false)):
		return true
	return estado.get("pais") is Dictionary and bool((estado["pais"] as Dictionary).get("crear", false))

## Lo de la máquina arranca con lo que ya tenga guardado este equipo.
func _leer_maquina() -> void:
	Calidad.cargar()
	calidad = Calidad.elegida
	adaptativa = Calidad.adaptativa
	motor_ligero = Calidad.motor_ligero
	var cf := ConfigFile.new()
	if cf.load(PREFS) == OK:
		var f := int(cf.get_value("pantalla", "fps", fps))
		fps = f if f in FPS else 60
		contador_fps = bool(cf.get_value("pantalla", "contador_fps", contador_fps))
	var d := String(AjustesCiudad.valor("densidad", densidad))
	densidad = d if DENSIDADES.has(d) else "media"

## LO QUE SE VE ES LO QUE QUEDA. El escudo y la camiseta «por sorteo» salen del
## hash del id del club, y el id definitivo puede no existir todavía (un club que
## se funda sobre otro): se fijan aquí, explícitos, para que la vista previa no
## mienta.
func _concretar() -> void:
	club.esc_forma = Escudo.forma_de(club)
	club.esc_patron = Escudo.patron_de(club)
	if club.kit_estilo == "":
		club.kit_estilo = DisenosKit._diseno_de(club)
	if club.esc_especial != "" and not Escudo.especial_desbloqueado(club.esc_especial):
		club.esc_especial = ""
	if not ANIMALES.has(mascota):
		mascota = "oso"

const PREFS := "user://preferencias.cfg"

func a_dic() -> Dictionary:
	var d := _dic()
	if crea_club:
		d["nombre_club"] = club.nombre.strip_edges()
	return d

func _dic() -> Dictionary:
	var ident := club.identidad_a_dic().duplicate(true)
	## Lo que `DisenosKit.kit_de_club` recalcula siempre (y una textura no se guarda).
	for k: String in ["escudo_tex", "marca", "sp"]:
		(ident["kit_x"] as Dictionary).erase(k)
	return {
		"version": 1,
		"crea_club": crea_club,
		"club": {
			"nombre": club.nombre.strip_edges(), "estadio_nombre": club.estadio_nombre.strip_edges(),
			"color1": club.color1, "color2": club.color2, "lema": lema.strip_edges().substr(0, 60),
			"identidad": ident,
			"mascota": mascota, "estilo_estadio": estilo_estadio,
		},
		"vida": {"vivienda": vivienda},
		"maquina": {"fps": fps, "contador_fps": contador_fps, "calidad": calidad, "adaptativa": adaptativa,
			"motor_ligero": motor_ligero, "densidad": densidad},
		## LAS CLAVES PLANAS que ya lee `OrquestadorMundo` (crear_club, aplicar_vida,
		## aplicar_preferencias). «nombre_club» solo si se funda: con él, el orquestador
		## entiende que hay que crear un club. «mascota» NO va plana: allí es el nombre
		## de la mascota de la familia del DT, no el animal del club.
		"color1": club.color1, "color2": club.color2, "estadio": club.estadio_nombre.strip_edges(),
		"vivienda": vivienda, "fps": fps, "calidad": calidad,
	}

## Vuelve a cargar un diccionario de `a_dic()`. Lo que no cuadre con los
## catálogos de hoy se ignora (un guardado viejo no puede romper la pantalla).
func desde_dic(d: Dictionary) -> void:
	var c: Dictionary = d.get("club", {})
	if c.has("nombre"):
		club.nombre = String(c["nombre"])
	elif crea_club and String(d.get("nombre_club", "")).strip_edges() != "":
		club.nombre = String(d["nombre_club"]).strip_edges()
	club.estadio_nombre = String(c.get("estadio_nombre", club.estadio_nombre))
	for k: String in ["color1", "color2"]:
		if Color.html_is_valid(String(c.get(k, ""))):
			club.set(k, String(c[k]))
	lema = String(c.get("lema", lema))
	if c.get("identidad") is Dictionary:
		club.identidad_desde_dic(c["identidad"] as Dictionary)
	if ANIMALES.has(String(c.get("mascota", ""))):
		mascota = String(c["mascota"])
	estilo_estadio = String(c.get("estilo_estadio", estilo_estadio))
	var v: Dictionary = d.get("vida", {})
	if VidaDT.VIVIENDAS.has(String(v.get("vivienda", ""))):
		vivienda = String(v["vivienda"])
	var m: Dictionary = d.get("maquina", {})
	if int(m.get("fps", fps)) in FPS:
		fps = int(m.get("fps", fps))
	contador_fps = bool(m.get("contador_fps", contador_fps))
	calidad = clampi(int(m.get("calidad", calidad)), Calidad.MEDIO, Calidad.ULTRA)
	adaptativa = bool(m.get("adaptativa", adaptativa))
	motor_ligero = bool(m.get("motor_ligero", motor_ligero))
	if DENSIDADES.has(String(m.get("densidad", ""))):
		densidad = String(m["densidad"])
	_concretar()

# --------------------------------------------------------------- VALIDACIÓN

## Los problemas de la configuración: [{paso, texto, grave}]. Un problema grave
## impide confirmar; uno leve solo se avisa (son decisiones de gusto).
func validar() -> Array:
	var r: Array = []
	var n := club.nombre.strip_edges()
	if n.length() < NOMBRE_MIN:
		r.append({"paso": 0, "grave": true, "texto": Idiomas.t("El club necesita un nombre de al menos 3 letras.")})
	elif n.length() > NOMBRE_MAX:
		r.append({"paso": 0, "grave": true, "texto": Idiomas.t("El nombre del club es demasiado largo (máximo 32).")})
	elif not _tiene_letra(n):
		r.append({"paso": 0, "grave": true, "texto": Idiomas.t("El nombre del club tiene que llevar letras.")})
	elif _nombre_repetido(n):
		r.append({"paso": 0, "grave": true, "texto": Idiomas.t("Ya hay otro club que se llama así.")})
	var e := club.estadio_nombre.strip_edges()
	if e != "" and (e.length() < NOMBRE_MIN or e.length() > ESTADIO_MAX):
		r.append({"paso": 0, "grave": true, "texto": Idiomas.t("El nombre del estadio debe tener entre 3 y 40 letras (o quedar vacío).")})
	if parecidos(club.color1, club.color2):
		r.append({"paso": 0, "grave": false, "texto": Idiomas.t("Los dos colores del club casi no se distinguen.")})
	if parecidos(club.color_escudo1(), club.color_escudo2()):
		r.append({"paso": 1, "grave": false, "texto": Idiomas.t("El fondo y el borde del escudo se confunden: el patrón no se verá.")})
	if parecidos(club.color_kit1(), club.color_kit2()) and club.kit_estilo != "liso":
		r.append({"paso": 2, "grave": false, "texto": Idiomas.t("Los colores de la camiseta se confunden: el diseño no se verá.")})
	if estilo_estadio != "" and not _preset_existe(estilo_estadio):
		r.append({"paso": 4, "grave": true, "texto": Idiomas.t("Ese estilo de estadio ya no existe.")})
	if calidad == Calidad.ULTRA and fps != 30 and _equipo_modesto():
		r.append({"paso": 6, "grave": false, "texto": Idiomas.t("Ultra en este equipo puede ir lento: prueba Alta.")})
	return r

func hay_graves(paso: int = -1) -> bool:
	for p: Dictionary in validar():
		if bool(p["grave"]) and (paso < 0 or int(p["paso"]) == paso):
			return true
	return false

static func parecidos(a: String, b: String) -> bool:
	if not Color.html_is_valid(a) or not Color.html_is_valid(b):
		return false
	var ca := Color(a)
	var cb := Color(b)
	return Vector3(ca.r - cb.r, ca.g - cb.g, ca.b - cb.b).length() < COLORES_PARECIDOS

static func _tiene_letra(s: String) -> bool:
	for i in s.length():
		var ch := s[i]
		if ch.to_upper() != ch.to_lower():
			return true
	return false

func _nombre_repetido(n: String) -> bool:
	if mundo == null:
		return false
	var baja := n.to_lower()
	for c: Club in mundo.clubes.values():
		if c.id != id_real and Nombres.visible(c.nombre).to_lower() == baja:
			return true
	return false

## Los estilos completos del estadio (`EST_PRESETS` + los de B6), una sola vez.
static var _presets: Array = []
static func presets() -> Array:
	if _presets.is_empty():
		_presets = EstadioPropio.new().presets()
	return _presets

static func _preset_existe(clave: String) -> bool:
	for p: Dictionary in presets():
		if String(p["clave"]) == clave:
			return true
	return false

## Una gráfica integrada o el render por software: lo que el propio juego trata
## como «equipo modesto» al decidir la calidad.
static func _equipo_modesto() -> bool:
	var a := RenderingServer.get_video_adapter_name().to_lower()
	return a.contains("intel") or a.contains("llvmpipe") or a.contains("swiftshader") or a.contains("lavapipe")

## La calidad que se recomienda para este equipo.
static func calidad_recomendada() -> int:
	return Calidad.MEDIO if _equipo_modesto() else Calidad.ALTO

# --------------------------------------------------------------- APLICAR

## Aplica la parte del club al club real (y al mundo, si se pasa). No cobra nada:
## es la fundación, no una reforma. La mascota se guarda en `Club.mascota` si ese
## campo existe y, mientras no exista, como metadato (ver el informe de la etapa).
static func aplicar_al_club(config: Dictionary, c: Club, m: Mundo = null) -> void:
	if c == null:
		return
	var d: Dictionary = config.get("club", {})
	if String(d.get("nombre", "")).strip_edges() != "":
		c.nombre = String(d["nombre"]).strip_edges()
	for k: String in ["color1", "color2"]:
		if Color.html_is_valid(String(d.get(k, ""))):
			c.set(k, String(d[k]))
	c.estadio_nombre = String(d.get("estadio_nombre", c.estadio_nombre)).strip_edges()
	if d.get("identidad") is Dictionary:
		c.identidad_desde_dic(d["identidad"] as Dictionary)
	var masc := String(d.get("mascota", ""))
	if ANIMALES.has(masc):
		if "mascota" in c:
			c.set("mascota", masc)
		else:
			c.set_meta("mascota", masc)
	Escudo.limpiar_cache()
	if m == null:
		return
	if m.estadio != null and c.estadio_nombre != "":
		m.estadio.renombrar(c.estadio_nombre)
	if m.comercial != null:
		m.comercial.escribir_lema(String(d.get("lema", "")))
	var est := String(d.get("estilo_estadio", ""))
	if est != "" and m.estadio != null:
		_estrenar_estilo(m, c, est)
	var viv := String((config.get("vida", {}) as Dictionary).get("vivienda", ""))
	if m.vida != null and VidaDT.VIVIENDAS.has(viv):
		m.vida.vivienda = viv

## El estilo del estadio, ESTRENADO: sin obra ni coste (es el estadio con el que
## se funda el club). Se valida campo a campo como en `EstadioPropio.reformar` y
## se marca `real_de` para que `asegurar_real` no lo pise con el de un club real.
static func _estrenar_estilo(m: Mundo, c: Club, clave: String) -> void:
	var e := m.estadio
	var p := e.preset(clave)
	if p.is_empty():
		return
	var cambios: Dictionary = p["cambios"]
	for campo: String in cambios:
		if not e.ajustes.has(campo) or not e.es_valido(campo, cambios[campo]):
			continue
		var v: Variant = cambios[campo]
		if campo == "niveles":
			v = clampi(int(v), 1, e.niveles_maximos(c, m.obras))
		e.ajustes[campo] = v
	e.obra = {}
	e.real_de = c.id

## Aplica la parte de la máquina: FPS, calidad gráfica y gente por la calle. Se
## guarda donde ya lo leen el juego y el menú central (`Calidad.ARCHIVO`,
## `[pantalla]` de las preferencias y `[ciudad]` de `user://ajustes.cfg`). Con otra
## `ruta_prefs` (las pruebas) solo se escribe ahí: ni la gráfica ni la ciudad.
static func aplicar_maquina(config: Dictionary, ruta_prefs: String = PREFS, arbol: SceneTree = null) -> void:
	var d: Dictionary = config.get("maquina", {})
	var f := int(d.get("fps", 60))
	if not (f in FPS):
		f = 60
	var cf := ConfigFile.new()
	cf.load(ruta_prefs)
	cf.set_value("pantalla", "fps", f)
	cf.set_value("pantalla", "contador_fps", bool(d.get("contador_fps", false)))
	cf.save(ruta_prefs)
	if ruta_prefs != PREFS:
		return
	Engine.max_fps = f
	Calidad.elegida = clampi(int(d.get("calidad", Calidad.ALTO)), Calidad.MEDIO, Calidad.ULTRA)
	Calidad.adaptativa = bool(d.get("adaptativa", true))
	Calidad.motor_ligero = bool(d.get("motor_ligero", false))
	Calidad.guardar()
	if arbol != null:
		ContadorFps.poner(arbol, bool(d.get("contador_fps", false)))
	else:
		ContadorFps.visible_pref = bool(d.get("contador_fps", false))
	var den := String(d.get("densidad", "media"))
	if not DENSIDADES.has(den):
		den = "media"
	AjustesCiudad.guardar("densidad", den)
	AjustesCiudad.guardar("densidad_factor", float(DENSIDADES[den][2]))
