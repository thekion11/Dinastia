class_name Partida
extends RefCounted
## Guardar y cargar una partida.
##
## En el HTML esto fue un problema serio: el estado ocupaba 8,8 MB contra los
## 5,2 MB de cuota de localStorage, así que el juego sencillamente no podía
## guardar hasta que se comprimió con deflate. Aquí el fichero va al disco y no
## hay cuota, pero el tamaño sigue importando -son 8.448 jugadores- así que se
## guarda comprimido igual: no cuesta nada y un guardado de 400 KB se copia y se
## comparte, uno de 6 MB no.
##
## QUÉ SE GUARDA Y QUÉ NO. No se guardan las tablas de datos: son las mismas 212
## que trae el juego y meterlas en cada partida sería duplicar 412 KB por
## fichero. Tampoco se guarda el calendario: se vuelve a armar solo, porque es
## determinista. Se guarda lo que no se puede recalcular: la semilla, el
## almanaque, los clubes con su caja, los jugadores con su historia y la tabla.

const CARPETA := "user://partidas"
const EXTENSION := ".dinastia"
## Sube cuando el formato deje de ser compatible hacia atrás. Se comprueba al
## cargar y se avisa en vez de reventar a mitad, que es lo que hace un juego
## cuando lee un guardado viejo sin mirar.
const VERSION := 1

static func carpeta() -> String:
	if not DirAccess.dir_exists_absolute(CARPETA):
		DirAccess.make_dir_recursive_absolute(CARPETA)
	return CARPETA

static func ruta_de(nombre: String) -> String:
	return "%s/%s%s" % [carpeta(), nombre.validate_filename(), EXTENSION]

## Lista los guardados con su resumen, para poder pintar un menú de carga sin
## abrir cada fichero entero.
static func listar() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var d := DirAccess.open(carpeta())
	if d == null:
		return salida
	for f in d.get_files():
		if not f.ends_with(EXTENSION):
			continue
		var cab := _leer_cabecera(carpeta() + "/" + f)
		if not cab.is_empty():
			cab["fichero"] = f.trim_suffix(EXTENSION)
			salida.append(cab)
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("guardado", 0)) > int(b.get("guardado", 0)))
	return salida

# ---------------------------------------------------------------------------

## LA PARTIDA ENTERA COMO DICCIONARIO. Sale aparte de `guardar()` porque el
## mismo retrato sirve para dos cosas distintas: escribirlo a disco y
## guardarlo en memoria para poder DESHACER. Antes solo existia dentro de
## `guardar()`, asi que deshacer habria obligado a escribir un archivo por cada
## decision reversible.
static func instantanea(m: Mundo) -> Dictionary:
	var datos := {
		"version": VERSION,
		"guardado": int(Time.get_unix_time_from_system()),
		"semilla": m.semilla,
		"anio": m.anio,
		"semana": m.semana,
		"horario": m.horario,
		"mi_club": m.mi_club_id,
		## Con qué base se creó el mundo: la ficticia o el pack real. Al cargar
		## se vuelve a poner la misma, para que lo que se busca por nombre de
		## club (equipaciones reales, plantillas) siga cuadrando.
		"base_real": Datos.base_real,
		"desafios": m.desafios,
		"reto": m.reto,
		"fondo": m.fondo.a_dic() if m.fondo != null else {},
		"clubes": [],
		"ligas": [],
		"copa": _copa_a_dic(m.copa),
		## Los sistemas que solo existen para TU club. Sin esto, guardar y cargar
		## te devolvia con la confianza a 55, sin cuerpo tecnico, sin parte medico,
		## sin logros y sin torneos continentales — y sin una sola queja.
		"directiva": _directiva_a_dic(m.directiva),
		"staff": m.staff.a_dic(),
		"obras": m.obras.a_dic(),
		"roles": m.roles.a_dic() if m.roles != null else {},
		"federacion": m.federacion.a_dic(),
		"estadio": m.estadio.a_dic(),
		"entrenamiento": m.entrenamiento.a_dic() if m.entrenamiento != null else {},
		"vestuario": m.vestuario.a_dic() if m.vestuario != null else {},
		"hinchada": m.hinchada.a_dic() if m.hinchada != null else {},
		"gente": m.gente.a_dic() if m.gente != null else {},
		"club_dentro": m.club_dentro.a_dic() if m.club_dentro != null else {},
		"junta": m.junta.a_dic() if m.junta != null else {},
		"charlas": m.charlas.a_dic() if m.charlas != null else {},
		"licencia": m.licencia.a_dic() if m.licencia != null else {},
		"eventos_cantera": m.eventos_cantera.a_dic() if m.eventos_cantera != null else {},
		"trabajadores": m.trabajadores.a_dic() if m.trabajadores != null else {},
		"redes": m.redes.a_dic() if m.redes != null else {},
		"movil": m.movil.a_dic() if m.movil != null else {},
		"mercado_av": m.mercado_av.a_dic() if m.mercado_av != null else {},
		"calendario": m.calendario.a_dic() if m.calendario != null else {},
		"politica": m.politica.a_dic() if m.politica != null else {},
		"contratos": m.contratos.a_dic() if m.contratos != null else {},
		"vida": m.vida.a_dic() if m.vida != null else {},
		"maestria": m.maestria.a_dic() if m.maestria != null else {},
		"banco": m.banco.a_dic() if m.banco != null else {},
		"auspicio": m.auspicio.a_dic() if m.auspicio != null else {},
		"eras": m.eras.a_dic() if m.eras != null else {},
		"era_tactica": m.era_tactica, "era_hasta": m.era_hasta,
		"eficacia_tactica": m.eficacia_tactica.duplicate(true),
		"amistoso": m.amistoso_hecho,
		"comercial": m.comercial.a_dic() if m.comercial != null else {},
		"ciudad": m.ciudad.a_dic() if m.ciudad != null else {},
		"campana": m.campana.duplicate(),
		"selecciones": m.selecciones.a_dic() if m.selecciones != null else {},
		"cantera": m.cantera.a_dic() if m.cantera != null else {},
		"academia": m.academia.a_dic() if m.academia != null else {},
		"ojeadores": m.ojeadores.a_dic() if m.ojeadores != null else {},
		"cesiones_datos": m.cesiones.a_dic() if m.cesiones != null else {},
		"mercado": m.mercado.a_dic() if m.mercado != null else {},
		"prensa": _prensa_a_dic(m.prensa),
		"medico": m.medico.a_dic() if m.medico != null else {},
		"logros": m.logros.a_dic() if m.logros != null else {},
		"ojeados": m.ojeados,
		"libro_financiero": m.libro_financiero,
		"continentales": _continentales_a_dic(m.continentales),
		"libres": [],
		"tienda": m.tienda,
		"normas": m.normas,
	}
	for c: Club in m.clubes.values():
		datos["clubes"].append(_club_a_dic(c))
	for l in m.ligas:
		datos["ligas"].append(_liga_a_dic(l))
	for j: Jugador in m.libres:
		datos["libres"].append(_jugador_a_dic(j))

	return datos

static func guardar(m: Mundo, nombre: String) -> bool:
	var datos := instantanea(m)
	var crudo := JSON.stringify(datos).to_utf8_buffer()
	var f := FileAccess.open(ruta_de(nombre), FileAccess.WRITE)
	if f == null:
		push_error("Partida: no puedo escribir %s (error %d)" % [ruta_de(nombre), FileAccess.get_open_error()])
		return false
	## El tamaño sin comprimir va delante porque `decompress` lo necesita: sin
	## él no hay forma de saber cuánto reservar y la carga falla en silencio.
	f.store_32(crudo.size())
	f.store_buffer(crudo.compress(FileAccess.COMPRESSION_DEFLATE))
	f.close()
	return true

static func cargar(nombre: String) -> Mundo:
	return desde_instantanea(_leer_todo(ruta_de(nombre)))

## Reconstruye un Mundo desde el retrato. Lo usan la carga de disco y el
## deshacer, que son la misma operacion con distinto origen.
static func desde_instantanea(datos: Dictionary) -> Mundo:
	if datos.is_empty():
		return null
	if int(datos.get("version", 0)) > VERSION:
		push_error("Partida: el guardado es de una versión más nueva (%d) que el juego (%d)" % [
			int(datos["version"]), VERSION])
		return null

	## Un guardado anterior a la base ficticia (sin la clave) se jugó siempre
	## con los datos reales. Si esta instalación no tiene el pack, se queda en
	## la ficticia: los nombres del propio guardado se ven igual, solo se
	## pierden las equipaciones reales.
	Datos.usar_base_real(bool(datos.get("base_real", true)))

	var m := Mundo.new()
	## Se siembra con la semilla guardada para que lo que pase a partir de aquí
	## siga la misma línea que seguía la partida. Sin esto, cargar y seguir
	## jugando daba un futuro distinto cada vez que se cargaba.
	m.semilla = Azar.sembrar(int(datos["semilla"]))
	m.mercado = Mercado.new(m)
	m.roles = Roles.new(m)
	## `Cesiones` es del MUNDO, no solo de tu club -un préstamo puede ser entre
	## dos clubes de la IA-, así que se crea aquí como mercado y roles, y no
	## dentro de `_restaurar_lo_tuyo()`. Sin esto ni siquiera existía: cada carga
	## empezaba con las cesiones y las cláusulas en blanco, calladamente, porque
	## todo lo que lo usa ya comprueba `!= null` antes de tocarlo.
	m.cesiones = Cesiones.new(m)
	## Las epocas doradas son del mundo y `desde_instantanea()` no pasa por
	## `generar()`: sin esto se quedaban con la referencia al mundo en null y
	## dejaban de sortearse en cuanto se cargaba una partida.
	m.eras = Eras.new(m)
	m.anio = int(datos["anio"])
	m.semana = int(datos["semana"])
	m.horario = String(datos.get("horario", "tarde"))
	m.campana = (datos.get("campana", {}) as Dictionary).duplicate()
	m.mi_club_id = String(datos["mi_club"])
	m.desafios.clear()
	m.reto = (datos.get("reto", {}) as Dictionary).duplicate()
	var df: Dictionary = datos.get("fondo", {})
	if not df.is_empty():
		m.fondo = FondoInversion.new()
		m.fondo.desde_dic(df)
	for k in datos.get("desafios", []):
		m.desafios.append(String(k))

	for d: Dictionary in datos["clubes"]:
		var c := _dic_a_club(d)
		m.clubes[c.id] = c
	for d: Dictionary in datos["ligas"]:
		m.ligas.append(_dic_a_liga(d, m))
	m.copa = _dic_a_copa(datos.get("copa", {}), m)
	m.mercado.desde_dic(datos.get("mercado", {}))
	for d: Dictionary in datos.get("libres", []):
		m.libres.append(_dic_a_jugador(d))
	m.tienda = datos.get("tienda", {})
	var n_guardadas: Dictionary = datos.get("normas", {})
	for k in m.normas:
		if n_guardadas.has(k):
			m.normas[k] = bool(n_guardadas[k])
	_restaurar_lo_tuyo(datos, m)
	return m

static func borrar(nombre: String) -> void:
	DirAccess.remove_absolute(ruta_de(nombre))

# --- conversión -------------------------------------------------------------

static func _club_a_dic(c: Club) -> Dictionary:
	var js: Array = []
	for j in c.plantilla:
		js.append(_jugador_a_dic(j))
	return {
		"id": c.id, "nombre": c.nombre, "pais": c.pais, "rep": c.rep,
		"saldo": c.saldo, "aforo": c.estadio_aforo, "division": c.division,
		"est_nombre": c.estadio_nombre,
		## Los colores del club: no se guardaban, así que cambiarlos duraba hasta
		## cerrar el juego. Van al guardado porque son IDENTIDAD, no un ajuste de
		## pantalla: tiñen escudo, equipación y el acento de toda la interfaz.
		"c1": c.color1, "c2": c.color2,
		## Y la identidad separada: uniforme, escudo y acento de la interfaz. Vacio
		## significa "heredado del club", asi que un guardado viejo carga sin nada
		## puesto y todo sigue tinendose del color institucional, igual que antes.
		"ident": c.identidad_a_dic(),
		"precio": c.precio_entrada, "confianza": c.confianza, "socios": c.socios,
		"formacion": c.tactica.formacion, "ment": c.tactica.mentalidad,
		"pres": c.tactica.presion, "ritmo": c.tactica.ritmo, "linea": c.tactica.linea,
		"ampl": c.tactica.amplitud,
		## Los cuatro interruptores se quedaban fuera del guardado: se podían
		## activar, movían el partido de verdad -`Tactica` los usa en sus
		## multiplicadores- y al cargar la partida volvían todos a `false` sin
		## una sola queja. Cuatro decisiones tácticas perdidas en cada carga.
		"corta": c.tactica.salida_corta, "hombre": c.tactica.marca_al_hombre,
		"fjuego": c.tactica.fuera_de_juego, "lejano": c.tactica.tiro_lejano,
		"corner": c.tactica.corner, "libre": c.tactica.libre,
		"plan_p": c.tactica.plan_perdiendo, "plan_g": c.tactica.plan_ganando,
		## El once elegido a mano tampoco se guardaba: armabas tu equipo, salvabas
		## la partida y al volver el automatico decidia por ti.
		"once": c.once_elegido,
		"jugadores": js,
	}

static func _dic_a_club(d: Dictionary) -> Club:
	var c := Club.new(String(d["id"]), String(d["nombre"]))
	c.pais = String(d["pais"])
	c.rep = int(d["rep"])
	c.saldo = int(d["saldo"])
	c.estadio_aforo = int(d["aforo"])
	c.estadio_nombre = String(d.get("est_nombre", ""))
	c.color1 = String(d.get("c1", c.color1))
	c.color2 = String(d.get("c2", c.color2))
	c.identidad_desde_dic(d.get("ident", {}))
	c.division = int(d.get("division", 1))
	c.precio_entrada = float(d.get("precio", 6.0))
	c.confianza = int(d.get("confianza", 50))
	c.socios = int(d.get("socios", 0))
	c.tactica.formacion = String(d.get("formacion", "4-3-3"))
	c.tactica.mentalidad = int(d.get("ment", Tactica.Mentalidad.EQUILIBRADA))
	c.tactica.presion = int(d.get("pres", Tactica.Nivel.MEDIO))
	c.tactica.ritmo = int(d.get("ritmo", Tactica.Nivel.MEDIO))
	c.tactica.linea = int(d.get("linea", Tactica.Nivel.MEDIO))
	c.tactica.amplitud = int(d.get("ampl", Tactica.Nivel.MEDIO))
	c.tactica.salida_corta = bool(d.get("corta", false))
	c.tactica.corner = String(d.get("corner", "area"))
	c.tactica.libre = String(d.get("libre", "directo"))
	c.tactica.plan_perdiendo = String(d.get("plan_p", "nada"))
	c.tactica.plan_ganando = String(d.get("plan_g", "nada"))
	c.tactica.marca_al_hombre = bool(d.get("hombre", false))
	c.tactica.fuera_de_juego = bool(d.get("fjuego", false))
	c.tactica.tiro_lejano = bool(d.get("lejano", false))
	c.once_elegido.clear()
	for id_j in d.get("once", []):
		c.once_elegido.append(String(id_j))
	for dj: Dictionary in d["jugadores"]:
		c.plantilla.append(_dic_a_jugador(dj))
	return c

## Las claves son cortas a propósito. Con 8.448 jugadores, escribir "atributos"
## en vez de "at" son 60 KB de más en cada guardado sin que nadie lo lea nunca.
static func _jugador_a_dic(j: Jugador) -> Dictionary:
	return {
		"i": j.id, "n": j.nombre, "p": j.pais, "rg": j.region, "c": j.club_id, "cf": j.club_formacion,
		"g": j.pos, "pe": j.pos_e, "e": j.edad, "o": j.ovr, "t": j.pot,
		"at": j.atributos, "r": j.rasgo,
		"f": j.forma, "m": j.moral, "fi": j.fisico,
		"l": j.lesion, "s": j.suspension, "a": j.amarillas,
		"go": j.goles, "as": j.asistencias, "pj": j.partidos,
		"v": j.valor, "su": j.sueldo, "an": j.anios_contrato,
		"d": j.dorsal, "cap": j.capitan, "ps": j.pide_salir, "tr": j.transferible,
		"nn": j.no_negociar_hasta, "re": j.real,
		"ml": j.motivo_libre, "rl": j.rechazos_libre,
		## Solo lo que el editor haya tocado de su cara. Casi siempre esta vacio y
		## no pesa nada: diez mil jugadores con quince rasgos cada uno serian dos
		## megas de guardado para nada.
		"lk": j.look, "oe": j.ovr_al_empezar, "hs": j.historial, "pr": j.premios,
	}

static func _dic_a_jugador(d: Dictionary) -> Jugador:
	var j := Jugador.new()
	j.id = String(d["i"]); j.nombre = String(d["n"]); j.pais = String(d["p"])
	j.region = String(d.get("rg", ""))
	j.club_id = String(d["c"]); j.club_formacion = String(d["cf"])
	j.pos = String(d["g"]); j.pos_e = String(d["pe"])
	j.edad = int(d["e"]); j.ovr = int(d["o"]); j.pot = int(d["t"])
	j.atributos = d["at"]; j.rasgo = String(d["r"])
	j.forma = int(d["f"]); j.moral = int(d["m"]); j.fisico = int(d["fi"])
	j.lesion = int(d["l"]); j.suspension = int(d["s"]); j.amarillas = int(d["a"])
	j.goles = int(d["go"]); j.asistencias = int(d["as"]); j.partidos = int(d["pj"])
	j.valor = int(d["v"]); j.sueldo = int(d["su"]); j.anios_contrato = int(d["an"])
	j.dorsal = int(d["d"]); j.capitan = bool(d["cap"]); j.pide_salir = bool(d["ps"])
	j.transferible = bool(d.get("tr", false))
	j.no_negociar_hasta = int(d.get("nn", 0))
	j.real = bool(d.get("re", false))
	j.motivo_libre = String(d.get("ml", ""))
	j.rechazos_libre = int(d.get("rl", 0))
	j.look = (d.get("lk", {}) as Dictionary).duplicate()
	j.ovr_al_empezar = int(d.get("oe", 0))
	var hs: Variant = d.get("hs", [])
	j.historial = (hs as Array).duplicate() if hs is Array else []
	j.premios = (d.get("pr", []) as Array).duplicate(true)
	return j

static func _liga_a_dic(l: Liga) -> Dictionary:
	var ids: Array = []
	for c in l.clubes:
		ids.append(c.id)
	## OJO con `div`: de él dependen los derechos de televisión y quién sube y
	## baja. Sin guardarlo, al cargar una partida todas las ligas volvían a ser
	## primera división y el club que acababa de descender cobraba otra vez
	## como si estuviera arriba.
	return {
		"nombre": l.nombre, "pais": l.pais, "div": l.div, "clubes": ids,
		"jornada": l.jornada_actual, "tabla": l.tabla_puntos,
	}

## La copa. Solo hacen falta tres cosas: el nombre, quiénes siguen vivos y en qué
## orden. El cuadro se reconstruye emparejando de dos en dos esa lista, que es
## exactamente como lo hace `Copa.jugar_ronda()`; guardar el árbol entero sería
## guardar algo que ya se puede deducir.
static func _copa_a_dic(c: Copa) -> Dictionary:
	if c == null:
		return {}
	var vivos: Array = []
	for k in c.vivos:
		vivos.append(k.id)
	var inscritos: Array = []
	for k in c.participantes:
		inscritos.append(k.id)
	return {
		"nombre": c.nombre, "ronda": c.ronda, "vivos": vivos,
		"inscritos": inscritos, "campeon": c.campeon.id if c.campeon else "",
	}

static func _dic_a_copa(d: Dictionary, m: Mundo) -> Copa:
	if d.is_empty():
		return null
	var c := Copa.new(String(d.get("nombre", "Copa")))
	for id: String in d.get("inscritos", []):
		var k: Club = m.clubes.get(id)
		if k != null:
			c.participantes.append(k)
	for id: String in d.get("vivos", []):
		var k: Club = m.clubes.get(id)
		if k != null:
			c.vivos.append(k)
	c.ronda = int(d.get("ronda", 0))
	c.campeon = m.clubes.get(String(d.get("campeon", "")))
	return c

## El calendario NO se guarda: se vuelve a armar con `preparar()`, que es
## determinista a partir del orden de los clubes. Guardarlo serían 480 pares por
## liga para nada, y encima habría que resolver las referencias a mano.
static func _dic_a_liga(d: Dictionary, m: Mundo) -> Liga:
	var l := Liga.new(String(d["nombre"]), String(d["pais"]), int(d.get("div", 1)))
	for id: String in d["clubes"]:
		var c: Club = m.clubes.get(id)
		if c != null:
			l.clubes.append(c)
	l.preparar()
	l.jornada_actual = int(d["jornada"])
	## La tabla se pisa DESPUÉS de preparar(), porque preparar() la deja a cero.
	for id: String in d["tabla"]:
		if l.tabla_puntos.has(id):
			var fila: Dictionary = d["tabla"][id]
			for k: String in fila:
				l.tabla_puntos[id][k] = int(fila[k])
	return l

# --- lectura ----------------------------------------------------------------

static func _leer_todo(ruta: String) -> Dictionary:
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return {}
	var tam := f.get_32()
	var comprimido := f.get_buffer(f.get_length() - 4)
	f.close()
	var crudo := comprimido.decompress(tam, FileAccess.COMPRESSION_DEFLATE)
	if crudo.is_empty():
		push_error("Partida: no puedo descomprimir %s" % ruta)
		return {}
	var j := JSON.new()
	if j.parse(crudo.get_string_from_utf8()) != OK:
		push_error("Partida: JSON inválido en %s: %s" % [ruta, j.get_error_message()])
		return {}
	return j.data

## Para el menú de carga solo hacen falta cuatro datos, pero el fichero está
## comprimido entero, así que hay que abrirlo igual. Se separa en su propia
## función para que quede claro qué se está pagando.
static func _leer_cabecera(ruta: String) -> Dictionary:
	var d := _leer_todo(ruta)
	if d.is_empty():
		return {}
	var nombre_club := ""
	for c: Dictionary in d.get("clubes", []):
		if String(c.get("id", "")) == String(d.get("mi_club", "")):
			nombre_club = String(c.get("nombre", ""))
			break
	return {
		"version": int(d.get("version", 0)),
		"guardado": int(d.get("guardado", 0)),
		"anio": int(d.get("anio", 0)),
		"semana": int(d.get("semana", 0)),
		"club": nombre_club,
	}

# --- los sistemas que solo existen para TU club ----------------------------

static func _directiva_a_dic(d: Directiva) -> Dictionary:
	if d == null:
		return {}
	return {
		"confianza": d.confianza, "meta": d.meta_puesto, "objetivo": d.objetivo,
		"temporadas": d.temporadas, "trofeos": d.trofeos, "despedido": d.despedido_ya,
		"consejeros": d.a_dic(),
	}

## De la prensa se guardan los campos de estado, no los catalogos: las 13
## decisiones y los tres guiones de rueda son constantes del codigo y meterlos en
## cada guardado seria duplicarlos por nada.
const _CAMPOS_PRENSA := [
	"pendiente", "entrevista", "cuerpo", "animo", "funa", "semanas_documental",
	"dato_del_rival", "presion_prometida", "enojo_arbitral", "primas_activas",
	"rep_entrenador", "clausulas", "cesiones", "arbitro_polemico",
	"oferta_forzada", "abogado_en_directorio", "posts", "seguidores",
	"relaciones", "medios", "vocero", "tv_individual", "portadas",
	"impuesto_pid", "impuesto_hasta", "efectos", "memoria", "titular_pendiente", "identidad", "cambio_identidad",
]

static func _prensa_a_dic(p: Prensa) -> Dictionary:
	if p == null:
		return {}
	var d := {}
	for k: String in _CAMPOS_PRENSA:
		d[k] = p.get(k)
	return d

## Los torneos continentales: la clave, quien sigue vivo y en que ronda van. El
## cuadro se reconstruye emparejando de dos en dos esa lista, igual que la copa.
static func _continentales_a_dic(torneos: Dictionary) -> Dictionary:
	var d := {}
	for k: String in torneos:
		var t: Continental = torneos[k]
		var vivos: Array = []
		for c in t.vivos:
			vivos.append(c.id)
		var inscritos: Array = []
		for c in t.participantes:
			inscritos.append(c.id)
		d[k] = {
			"vivos": vivos, "inscritos": inscritos, "ronda": t.ronda,
			"fecha": t.fecha, "por_grupos": t.por_grupos,
			"campeon": t.campeon.id if t.campeon else "",
		}
	return d

static func _restaurar_lo_tuyo(datos: Dictionary, m: Mundo) -> void:
	var mio := m.mi_club()
	if mio == null:
		return
	## `tomar_el_mando` crea los sistemas "solo tuyos" de cero y vuelve a sortear los
	## continentales. Se llama primero y DESPUES se pisan sus valores con los del
	## guardado: asi no hay que duplicar aqui la construccion de cada uno, y si
	## manana se anade un sistema nuevo, cargar una partida vieja lo estrena en
	## limpio en vez de dejarlo en null.
	m.tomar_el_mando(m.mi_club_id)

	var dd: Dictionary = datos.get("directiva", {})
	if not dd.is_empty() and m.directiva != null:
		m.directiva.confianza = int(dd.get("confianza", Directiva.INICIAL))
		m.directiva.meta_puesto = int(dd.get("meta", 8))
		m.directiva.objetivo = String(dd.get("objetivo", m.directiva.objetivo))
		m.directiva.temporadas = int(dd.get("temporadas", 0))
		m.directiva.despedido_ya = bool(dd.get("despedido", false))
		m.directiva.desde_dic(dd.get("consejeros", {}))
		m.directiva.trofeos.clear()
		for t: String in dd.get("trofeos", []):
			m.directiva.trofeos.append(t)

	m.staff.desde_dic(datos.get("staff", {}))
	## Y hay que volver a aplicarlo: los niveles solos no mueven nada, el motor de
	## partido lee `Club.bonus_ataque` y `bonus_defensa`. Sin este `aplicar`, un
	## staff de nivel 5 cargado de disco no hacia absolutamente nada.
	m.staff.aplicar(mio)
	## Las obras van DESPUES de fijar el aforo base, y hay que volver a aplicarlas:
	## el aforo del club que viene del guardado ya trae las tribunas construidas,
	## asi que si se aplicara sobre el, cada carga lo multiplicaria otra vez.
	var do_: Dictionary = datos.get("obras", {})
	if not do_.is_empty():
		m.obras.desde_dic(do_)
		if int(do_.get("aforo_base", 0)) <= 0:
			## Guardado viejo, sin aforo base: se deduce quitando las tribunas.
			m.obras.fijar_aforo_base(int(round(float(mio.estadio_aforo) / (1.0 + 0.15 * float(m.obras.nivel("trib"))))))
		m.obras.aplicar(mio)
	if m.roles != null:
		m.roles.desde_dic(datos.get("roles", {}))
		## `desde_dic()` no emite `rol_cambiado` -no es un cambio de rol, es
		## restaurar uno ya vivido-, así que `Directiva.puede_despedirte` no se
		## entera solo: `tomar_el_mando()`, arriba, lo calculó con el rol por
		## defecto de antes de cargar. Se recalcula aquí, ya con el rol real.
		if m.directiva != null:
			m.directiva.puede_despedirte = m.roles.le_pueden_echar()
	m.federacion.desde_dic(datos.get("federacion", {}))
	m.estadio.desde_dic(datos.get("estadio", {}))
	if m.entrenamiento != null:
		m.entrenamiento.desde_dic(datos.get("entrenamiento", {}))
	## El vestuario tenia a_dic()/desde_dic() escritos pero nadie los llamaba: la
	## ansiedad de cada jugador se sortea al crear su ficha mental (Azar.ent), asi
	## que sin restaurarla una partida cargada barajaba la cabeza de todo el
	## plantel de nuevo. Eso cambiaba factor_animo() y por tanto bonus_ataque -el
	## sintoma que cazaba el banco, aunque el rastro llevaba aqui y no a Staff.
	if m.vestuario != null:
		m.vestuario.desde_dic(datos.get("vestuario", {}))
	if m.hinchada != null:
		m.hinchada.desde_dic(datos.get("hinchada", {}))
	if m.gente != null:
		m.gente.desde_dic(datos.get("gente", {}))
	if m.club_dentro != null:
		m.club_dentro.desde_dic(datos.get("club_dentro", {}))
	if m.charlas != null:
		m.charlas.desde_dic(datos.get("charlas", {}))
	if m.licencia != null:
		m.licencia.desde_dic(datos.get("licencia", {}))
	if m.eventos_cantera != null:
		m.eventos_cantera.desde_dic(datos.get("eventos_cantera", {}))
	if m.trabajadores != null:
		m.trabajadores.desde_dic(datos.get("trabajadores", {}))
	if m.redes != null:
		m.redes.desde_dic(datos.get("redes", {}))
	if m.movil != null:
		m.movil.desde_dic(datos.get("movil", {}))
	if m.mercado_av != null:
		m.mercado_av.desde_dic(datos.get("mercado_av", {}))
	if m.calendario != null:
		m.calendario.desde_dic(datos.get("calendario", {}))
	if m.politica != null:
		m.politica.desde_dic(datos.get("politica", {}))
	if m.contratos != null:
		m.contratos.desde_dic(datos.get("contratos", {}))
	if m.vida != null:
		m.vida.desde_dic(datos.get("vida", {}))
	if m.maestria != null:
		m.maestria.desde_dic(datos.get("maestria", {}))
	if m.junta != null:
		m.junta.desde_dic(datos.get("junta", {}))
		m.junta.formar(m.mi_club())
	if m.banco != null:
		m.banco.desde_dic(datos.get("banco", {}))
	if m.auspicio != null:
		m.auspicio.desde_dic(datos.get("auspicio", {}))
	if m.eras != null:
		m.eras.desde_dic(datos.get("eras", {}))
	m.era_tactica = int(datos.get("era_tactica", 0))
	m.era_hasta = int(datos.get("era_hasta", 0))
	m.eficacia_tactica = (datos.get("eficacia_tactica", {}) as Dictionary).duplicate(true)
	m.amistoso_hecho = bool(datos.get("amistoso", false))
	if m.comercial != null:
		m.comercial.desde_dic(datos.get("comercial", {}))
	if m.ciudad != null:
		m.ciudad.desde_dic(datos.get("ciudad", {}))
		m.gente.armar()
	if m.selecciones != null:
		m.selecciones.desde_dic(datos.get("selecciones", {}))
	if m.cantera != null:
		m.cantera.desde_dic(datos.get("cantera", {}))
	if m.academia != null:
		m.academia.desde_dic(datos.get("academia", {}))
	if m.ojeadores != null:
		m.ojeadores.desde_dic(datos.get("ojeadores", {}))
	if m.cesiones != null:
		m.cesiones.desde_dic(datos.get("cesiones_datos", {}))
	## Y se recalculan los bonificadores del motor con el staff, el arbol del DT
	## y el vestuario ya cargados: los niveles solos no mueven nada.
	m.aplicar_bonificadores()

	var dp: Dictionary = datos.get("prensa", {})
	if not dp.is_empty() and m.prensa != null:
		for k: String in _CAMPOS_PRENSA:
			if dp.has(k):
				m.prensa.set(k, dp[k])
	if m.medico != null:
		m.medico.desde_dic(datos.get("medico", {}))
	if m.logros != null:
		m.logros.desde_dic(datos.get("logros", {}))
	m.ojeados = datos.get("ojeados", {})
	m.libro_financiero.clear()
	for x: Dictionary in datos.get("libro_financiero", []):
		m.libro_financiero.append(x)

	var dc: Dictionary = datos.get("continentales", {})
	if dc.is_empty():
		return
	m.continentales.clear()
	for k: String in dc:
		var t := Continental.crear(k)
		var fila: Dictionary = dc[k]
		for id: String in fila.get("inscritos", []):
			var c: Club = m.clubes.get(id)
			if c != null:
				t.participantes.append(c)
		for id: String in fila.get("vivos", []):
			var c2: Club = m.clubes.get(id)
			if c2 != null:
				t.vivos.append(c2)
		t.ronda = int(fila.get("ronda", 0))
		t.fecha = int(fila.get("fecha", 0))
		t.por_grupos = bool(fila.get("por_grupos", false))
		t.campeon = m.clubes.get(String(fila.get("campeon", "")))
		m.continentales[k] = t
