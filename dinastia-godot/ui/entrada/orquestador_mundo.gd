class_name OrquestadorMundo
extends RefCounted
## LO QUE SE ELIGIÓ EN LA ENTRADA → UNA PARTIDA (25-10-2026). La parte sin pantallas de
## `OrquestadorEntrada`: leer el estado acumulado (sea cual sea la forma exacta en que lo
## devuelva cada pantalla: texto suelto o diccionario) y crear la partida por el MISMO
## camino que ya usaban `ui/inicio.gd` y `ui/eleccion_club.gd`: el mundo entero generado,
## `tomar_el_mando()` sobre el club, y `Principal.mundo_pregenerado` + modo, nombre,
## dificultad y desafíos en las variables estáticas de Principal, que hace el resto en
## `_arrancar_con()`. Aquí no hay reglas de juego nuevas salvo las de la entrada al
## campeonato (§9.1 del plan, cifras validadas por el dueño el 24-10).

const PRINCIPAL := "res://escenas/principal.tscn"
const CARRERA_JUGADOR := "res://escenas/carrera_jugador.tscn"
const PERSONAJE_DATOS := "res://ui/entrada/personaje_datos.gd"
const CONFIG_DATOS := "res://ui/entrada/config_club_datos.gd"

## Llama a una función estática de otra pieza de la entrada, cargada por ruta: si esa pieza
## falta o no carga, no rompe el orquestador (devuelve false).
static func _llamar(ruta: String, funcion: String, args: Array) -> bool:
	if not ResourceLoader.exists(ruta):
		return false
	var s: Variant = load(ruta)
	if not (s is Script) or not (s as Script).get_script_method_list().any(func(f: Dictionary) -> bool: return String(f["name"]) == funcion):
		return false
	(s as Script).callv(funcion, args)
	return true
## Las pruebas apuntan aquí un archivo propio para no tocar los ajustes de verdad.
static var ruta_preferencias := "user://preferencias.cfg"
## Lo último elegido (sin el mundo), para las fases siguientes (prólogo 3D: densidad,
## estilo de instalaciones…), que todavía no tienen dónde guardarse en `Mundo`.
static var ultima_eleccion: Dictionary = {}

## §9.1 (entrar al campeonato): las reglas y cifras viven en `EntradaCampeonato` (núcleo); aquí
## solo se usa su vocabulario.
const REEMPLAZAR := EntradaCampeonato.MODO_REEMPLAZAR
const PAGAR := EntradaCampeonato.MODO_CONFEDERACION

# --- leer el estado, venga como venga -------------------------------------------

## Un texto del estado: `estado[clave]` si es texto, o `estado[clave][sub]` (o la primera
## de `subs` que exista) si es un diccionario.
static func _texto(estado: Dictionary, clave: String, subs: Array = []) -> String:
	var v: Variant = estado.get(clave)
	if v is String or v is StringName:
		return String(v)
	if v is Dictionary:
		for s: String in subs:
			var w: Variant = (v as Dictionary).get(s)
			if w is String or w is StringName:
				return String(w)
	return ""

static func _dic(estado: Dictionary, clave: String) -> Dictionary:
	var v: Variant = estado.get(clave)
	return v if v is Dictionary else {}

static func modo_id(estado: Dictionary) -> String:
	var m := _texto(estado, "modo", ["id", "modo"])
	return m if m != "" else "dt"

static func crea_club(estado: Dictionary) -> bool:
	if modo_id(estado) == "creador" or bool(_dic(estado, "modo").get("crear", false)):
		return true
	if bool(estado.get("crear", false)) or bool(_dic(estado, "pais").get("crear", false)):
		return true
	var cfg := config(estado)
	return String(cfg.get("nombre_club", "")).strip_edges() != ""

static func pais(estado: Dictionary) -> String:
	var p := _texto(estado, "pais", ["pais", "codigo", "id"])
	return p if p != "" else "CHI"

static func config(estado: Dictionary) -> Dictionary:
	return _dic(estado, "config")

static func personaje(estado: Dictionary) -> Dictionary:
	return _dic(estado, "personaje")

static func nombre_dt(estado: Dictionary) -> String:
	var per := personaje(estado)
	var n := String(per.get("nombre_completo", "")).strip_edges()
	if n == "":
		n = ("%s %s" % [String(per.get("nombre", "")), String(per.get("apellido", ""))]).strip_edges()
	if n == "":
		n = _texto(estado, "personaje", ["nombre"]).strip_edges()
	if n == "":
		n = String(estado.get("nombre", "")).strip_edges()
	return n if n != "" else "Míster"

static func dificultad(estado: Dictionary) -> String:
	for v: String in [String(estado.get("dificultad", "")), _texto(estado, "modo", ["dificultad"]),
			String(config(estado).get("dificultad", "")), _texto(estado, "personaje", ["dificultad"])]:
		if v != "" and (Datos.tabla("DIF") as Dictionary).has(v):
			return v
	return "normal"

static func tipo_entrada(estado: Dictionary) -> String:
	var t := _texto(estado, "entrada", ["tipo", "modo", "entrada", "id"])
	return PAGAR if t in [PAGAR, "confederacion"] else REEMPLAZAR

## El club elegido a mano (en el globo o en la entrada), o "" si no hay.
static func club_elegido_id(estado: Dictionary, m: Mundo) -> String:
	var candidatos: Array[String] = [String(estado.get("club_id", "")), String(estado.get("club", "")),
		String(_dic(estado, "pais").get("club_id", "")), String(_dic(estado, "entrada").get("club_id", "")),
		String(_dic(estado, "entrada").get("reemplaza", ""))]
	for id: String in candidatos:
		if id != "" and m.clubes.has(id):
			return id
	return ""

## Lo que emite el sustituto de cada etapa: lo mínimo para que el flujo siga.
static func por_defecto(clave: String, estado: Dictionary) -> Dictionary:
	match clave:
		"idioma": return {"idioma": Idiomas.idioma}
		"modo": return {"modo": "dt"}
		"pais": return {"pais": "CHI"}
		"config": return {"config": {"nombre_club": "Club Dinastía"} if crea_club(estado) else {}}
		"entrada": return {"entrada": REEMPLAZAR}
		"personaje": return {"personaje": {"nombre": nombre_dt(estado)}}
	return {}

# --- preferencias de la máquina (no de la partida) -------------------------------

## El idioma, al momento y guardado donde lo lee Principal (`[juego] idioma`).
static func aplicar_idioma(estado: Dictionary) -> void:
	var idi := _texto(estado, "idioma", ["idioma", "codigo", "id"])
	if idi != "es" and not Idiomas.NOMBRES.has(idi):
		return
	Idiomas.idioma = idi
	_guardar_pref("juego", "idioma", idi)

static func _guardar_pref(seccion: String, clave: String, valor: Variant) -> void:
	var cf := ConfigFile.new()
	cf.load(ruta_preferencias)
	cf.set_value(seccion, clave, valor)
	cf.save(ruta_preferencias)

## FPS (`[pantalla] fps`, 0 = sin límite), contador de FPS y nivel gráfico (`Calidad`), planos en
## la configuración o dentro de su «maquina».
static func aplicar_preferencias(estado: Dictionary) -> void:
	aplicar_idioma(estado)
	_llamar(CONFIG_DATOS, "aplicar_maquina", [config(estado), ruta_preferencias])
	var cfg := config(estado).duplicate()
	var maq: Variant = cfg.get("maquina")
	if maq is Dictionary:
		for k: Variant in maq:
			if not cfg.has(k):
				cfg[k] = (maq as Dictionary)[k]
	if cfg.has("fps"):
		var f := int(cfg["fps"])
		_guardar_pref("pantalla", "fps", 0 if f == 0 else clampi(f, 30, 240))
	if cfg.has("contador_fps"):
		_guardar_pref("pantalla", "contador_fps", bool(cfg["contador_fps"]))
	var real := ruta_preferencias == "user://preferencias.cfg"
	var toca_calidad := false
	if cfg.has("adaptativa"):
		Calidad.adaptativa = bool(cfg["adaptativa"])
		toca_calidad = true
	if cfg.has("motor_ligero"):
		## Se guarda y vale desde el próximo arranque (el motor no cambia en caliente).
		Calidad.motor_ligero = bool(cfg["motor_ligero"])
		toca_calidad = true
	if toca_calidad and real:
		Calidad.guardar()
	var vis: Variant = cfg.get("visual", cfg.get("calidad"))
	var niveles := {"medio": Calidad.MEDIO, "alto": Calidad.ALTO, "ultra": Calidad.ULTRA}
	if vis is String and niveles.has(String(vis).to_lower()):
		vis = niveles[String(vis).to_lower()]
	if vis is int or vis is float:
		Calidad.elegida = clampi(int(vis), Calidad.MEDIO, Calidad.ULTRA)
		if real:
			Calidad.guardar()

# --- crear la partida ------------------------------------------------------------

static func generar_mundo() -> Mundo:
	Escudo.limpiar_cache()
	Cara.limpiar_cache()
	var m := Mundo.new()
	m.generar([], 0)
	return m

## Aplica todo lo elegido y deja Principal listo. Devuelve {"escena", "mundo"}.
static func preparar(estado: Dictionary) -> Dictionary:
	var modo := modo_id(estado)
	aplicar_preferencias(estado)
	ultima_eleccion = estado.duplicate(true)
	ultima_eleccion.erase("mundo")
	if modo == "continuar":
		var guardado := Partida.cargar("partida")
		if guardado != null:
			Principal.mundo_a_cargar = guardado
			return {"escena": PRINCIPAL, "mundo": guardado}
		modo = "dt"
	if modo == "carrera-m":
		CarreraJugadorUI.mundo = null
		CarreraJugadorUI.nombre_pedido = nombre_dt(estado)
		return {"escena": CARRERA_JUGADOR, "mundo": null}
	var m: Mundo = estado.get("mundo") if estado.get("mundo") is Mundo else generar_mundo()
	Principal.tutorial_pedido = modo == "tutorial"
	Principal.fundar_pedido = false
	Principal.reto_pedido = ""
	var montado := false
	if modo == "retos":
		var reto := _texto(estado, "modo", ["reto"])
		if reto == "":
			reto = String(estado.get("reto", ""))
		if reto == "":
			reto = String(Retos.LISTA[0][0])
		montado = Retos.montar(m, reto) != null
	if not montado:
		if crea_club(estado):
			if crear_club(m, estado) == null:
				m.tomar_el_mando(club_por_defecto(m, pais(estado)).id)
		else:
			var id := club_elegido_id(estado, m)
			m.tomar_el_mando(id if id != "" else club_por_defecto(m, pais(estado)).id)
	aplicar_club_config(m, estado)
	_llamar(CONFIG_DATOS, "aplicar_al_club", [config(estado), m.mi_club(), m])
	aplicar_vida(m, estado)
	aplicar_personaje(m, estado)
	Principal.mundo_pregenerado = m
	## «Crear tu Club», el tutorial y los retos son carreras de entrenador (como antes).
	Principal.modo_elegido = "dt" if modo in ["creador", "tutorial", "retos"] else modo
	Principal.dt_nombre_elegido = nombre_dt(estado)
	Principal.dificultad_elegida = dificultad(estado)
	var desafios: Array[String] = []
	if modo != "retos":
		var lista: Variant = estado.get("desafios", config(estado).get("desafios", []))
		if lista is Array:
			for d: Variant in lista:
				desafios.append(String(d))
	Principal.desafios_elegidos = desafios
	return {"escena": PRINCIPAL, "mundo": m}

## Sin club elegido: el primero de la primera división del país (lo que hacía siempre
## `Principal._nuevo_mundo()` con Chile).
static func club_por_defecto(m: Mundo, p: String) -> Club:
	for l: Liga in m.ligas:
		if l.pais == p and l.division() == 1 and not l.clubes.is_empty():
			return l.clubes[0]
	return m.ligas[0].clubes[0]

## El club propio de quien crea uno: entra al campeonato como se eligió en la etapa 5 con
## `EntradaCampeonato.aplicar()` (reemplazar a un club o pagar la afiliación, §9.1), salvo que la
## propia pantalla ya la haya aplicado (trae `club_id` y ya diriges ese club). Si la entrada no se
## puede aplicar (p. ej. sin nombre), se funda como siempre (`Mundo.fundar_club`).
static func crear_club(m: Mundo, estado: Dictionary) -> Club:
	var datos := EntradaCampeonato.datos_de_config(config(estado))
	if String(datos["nombre"]) == "":
		datos["nombre"] = "Club Dinastía"
	var p := pais(estado)
	var ent := _dic(estado, "entrada")
	if ent.is_empty():
		ent = {"tipo": tipo_entrada(estado)}
	var ya := String(ent.get("club_id", ""))
	if ya != "" and m.mi_club_id == ya and m.mi_club() != null:
		return m.mi_club()
	ent = ent.duplicate()
	ent["pais"] = p
	if tipo_entrada(estado) == REEMPLAZAR and EntradaCampeonato.normalizar(ent, p)["club_reemplazado"] == "":
		var sug := EntradaCampeonato.candidato_sugerido(m, p)
		if sug != null:
			ent["club_reemplazado"] = sug.id
	var c := EntradaCampeonato.aplicar(m, ent, datos)
	if c == null:
		c = m.fundar_club(String(datos["nombre"]), p, String(datos["color1"]), String(datos["color2"]), String(datos["estadio"]))
	return c

## Lo que la configuración cambió del club que diriges (creado o existente): identidad visual
## (escudo, equipación), colores, estadio y lema. Lo que todavía no tiene sitio en `Club`
## (mascota del club, estilo de las instalaciones) queda en `ultima_eleccion`.
static func aplicar_club_config(m: Mundo, estado: Dictionary) -> void:
	var c := m.mi_club()
	if c == null:
		return
	var cfg := config(estado)
	var sub: Dictionary = cfg.get("club") if cfg.get("club") is Dictionary else {}
	var ident: Variant = sub.get("identidad")
	if ident is Dictionary and not (ident as Dictionary).is_empty():
		c.identidad_desde_dic(ident as Dictionary)
	for k: String in ["color1", "color2"]:
		var v := String(cfg.get(k, sub.get(k, "")))
		if v != "" and Color.html_is_valid(v):
			c.set(k, v if v.begins_with("#") else "#" + v)
	var est := String(cfg.get("estadio", sub.get("estadio_nombre", ""))).strip_edges()
	if est != "":
		c.estadio_nombre = est
	var lema := String(sub.get("lema", "")).strip_edges()
	if lema != "" and m.comercial != null:
		m.comercial.lema = lema

## La vida fuera del club: la casa y la mascota que se eligieron en la configuración.
static func aplicar_vida(m: Mundo, estado: Dictionary) -> void:
	var cfg := config(estado)
	if m.vida == null:
		return
	var vida: Dictionary = cfg.get("vida") if cfg.get("vida") is Dictionary else {}
	var casa := String(cfg.get("casa", cfg.get("vivienda", vida.get("vivienda", ""))))
	if VidaDT.VIVIENDAS.has(casa):
		m.vida.vivienda = casa
	if cfg.has("mascota") and m.mi_club() != null:
		m.vida.crear_perfil(m.mi_club().id)
		var masc: Variant = cfg["mascota"]
		if masc is bool:
			if not masc:
				m.vida.perfil["mascota"] = ""
			elif String(m.vida.perfil.get("mascota", "")) == "":
				m.vida.perfil["mascota"] = String(VidaDT._MASCOTAS[0])
		elif masc is Dictionary:
			m.vida.perfil["mascota"] = String((masc as Dictionary).get("nombre", ""))
		else:
			m.vida.perfil["mascota"] = String(masc)

## El aspecto del personaje: el 3D (`look["p3d"]`) y el retrato 2D que lo sigue, igual
## que `CreadorPersonaje._guardar()`.
static func aplicar_personaje(m: Mundo, estado: Dictionary) -> void:
	var per := personaje(estado)
	## La etapa 6 trae su propio «aplicar» (nombre, edad, nacionalidad, estilo y aspecto): se usa
	## ese, cargado por ruta para no depender de él si un día no está.
	if per.has("aspecto") and per.has("apellido") and ResourceLoader.exists(PERSONAJE_DATOS):
		var pd: Variant = load(PERSONAJE_DATOS)
		if pd is Script and (pd as Script).get_script_method_list().any(func(f: Dictionary) -> bool: return String(f["name"]) == "aplicar"):
			(pd as Script).call("aplicar", per, m.roles, m.anio)
			return
	var asp: Variant = per.get("aspecto", per.get("p3d"))
	## También vale el aspecto suelto en el propio diccionario (`{"nombre", "pelo", "piel"…}`).
	if not (asp is Dictionary):
		var suelto := {}
		for k: String in PersonajeDT.BASE:
			if per.has(k):
				suelto[k] = per[k]
		asp = suelto
	if not (asp is Dictionary) or (asp as Dictionary).is_empty():
		return
	var a := PersonajeDT.aspecto(asp as Dictionary)
	var l: Dictionary = m.roles.look
	l["p3d"] = a.duplicate()
	if String(a.get("pelo", "")) in CaraDT.CORTES:
		l["pelo"] = String(a["pelo"])
	l["pelo_c"] = "#" + String(a.get("color_pelo", "3b2a20"))
	l["piel"] = "#" + String(a.get("piel", "c68863"))
	l["barba"] = 1 if bool(a.get("barba", false)) and String(a.get("cuerpo", "male")) == "male" else 0
	l["gafas"] = String(a.get("gafas", "")) != ""
	Genero.fijar(String(a.get("cuerpo", "male")) == "female")
