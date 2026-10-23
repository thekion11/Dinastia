extends RefCounted
## (Parte 1 de 2 de `partida.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `partida.gd`, conserva la clase.)

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
const TEMPORAL := ".tmp"
const RESPALDO := ".bak"
## Sube cuando el formato deje de ser compatible hacia atrás. Se comprueba al
## cargar y se avisa en vez de reventar a mitad, que es lo que hace un juego
## cuando lee un guardado viejo sin mirar.
const VERSION := 1

## Si la última carga tuvo que tirar del temporal o de la copia (el principal
## estaba roto o faltaba). La interfaz puede avisar al jugador.
static var cargada_de_respaldo := false

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

static func carpeta() -> String:
	if not DirAccess.dir_exists_absolute(CARPETA):
		DirAccess.make_dir_recursive_absolute(CARPETA)
	return CARPETA

static func ruta_de(nombre: String) -> String:
	return "%s/%s%s" % [carpeta(), nombre.validate_filename(), EXTENSION]

static func _cabecera_de(d: Dictionary) -> Dictionary:
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

# --- lectura ----------------------------------------------------------------

static func _leer_todo(ruta: String) -> Dictionary:
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return {}
	## Un archivo truncado o con basura no debe colgar ni reservar memoria
	## absurda: tamaño mínimo y tope de 512 MB sin comprimir.
	if f.get_length() < 5:
		f.close()
		return {}
	var tam := f.get_32()
	if tam <= 0 or tam > 512 * 1024 * 1024:
		f.close()
		push_error("Partida: cabecera inválida en %s" % ruta)
		return {}
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
	return j.data if j.data is Dictionary else {}

## Lee el principal; si falta o está roto, el temporal (un guardado que llegó
## a escribirse entero pero no a moverse) y por último la copia anterior.
static func _leer_con_respaldo(ruta: String) -> Dictionary:
	cargada_de_respaldo = false
	for r in [ruta, ruta + TEMPORAL, ruta + RESPALDO]:
		if not FileAccess.file_exists(r):
			continue
		var d := _leer_todo(r)
		if not d.is_empty():
			if r != ruta:
				cargada_de_respaldo = true
				push_warning("Partida: %s estaba roto o faltaba; se cargó %s" % [ruta, r])
			return d
	return {}

## Lista los guardados con su resumen, para poder pintar un menú de carga sin
## abrir cada fichero entero.
static func listar() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var d := DirAccess.open(carpeta())
	if d == null:
		return salida
	## Cada ranura aparece aunque solo quede su temporal o su copia: si el
	## principal se rompió, la partida no debe «desaparecer» del menú.
	var nombres := {}
	for f in d.get_files():
		for suf in [EXTENSION, EXTENSION + TEMPORAL, EXTENSION + RESPALDO]:
			if f.ends_with(suf):
				nombres[f.trim_suffix(suf)] = true
	for n: String in nombres:
		var cab := _cabecera_de(_leer_con_respaldo(carpeta() + "/" + n + EXTENSION))
		if not cab.is_empty():
			cab["fichero"] = n
			salida.append(cab)
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("guardado", 0)) > int(b.get("guardado", 0)))
	return salida

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

# --- los sistemas que solo existen para TU club ----------------------------

static func _directiva_a_dic(d: Directiva) -> Dictionary:
	if d == null:
		return {}
	return {
		"confianza": d.confianza, "meta": d.meta_puesto, "objetivo": d.objetivo,
		"temporadas": d.temporadas, "trofeos": d.trofeos, "despedido": d.despedido_ya,
		"consejeros": d.a_dic(),
	}

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

static func _jugador_a_dic_base(j: Jugador) -> Dictionary:
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

## Las claves son cortas a propósito. Con 8.448 jugadores, escribir "atributos"
## en vez de "at" son 60 KB de más en cada guardado sin que nadie lo lea nunca.
static func _jugador_a_dic(j: Jugador) -> Dictionary:
	var d := _jugador_a_dic_base(j)
	if not j.historial_moral.is_empty():
		d["hm"] = j.historial_moral
	return d

# --- conversión -------------------------------------------------------------

static func _club_a_dic(c: Club) -> Dictionary:
	var js: Array = []
	for j in c.plantilla:
		js.append(_jugador_a_dic(j))
	return {
		"id": c.id, "nombre": c.nombre, "pais": c.pais, "rep": c.rep, "fcupo": c.fichajes_cupo, "lpol": c.ley_politica,
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
		"jornada": l.jornada_actual, "tabla": l.tabla_puntos, "h2h": l.h2h,
		"desc": l.plazas_descenso, "pv": l.puntos_victoria,
	}

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
		"interiores": m.interiores.a_dic(),
		"club_dentro": m.club_dentro.a_dic() if m.club_dentro != null else {},
		"junta": m.junta.a_dic() if m.junta != null else {},
		"charlas": m.charlas.a_dic() if m.charlas != null else {},
		"licencia": m.licencia.a_dic() if m.licencia != null else {},
		"eventos_cantera": m.eventos_cantera.a_dic() if m.eventos_cantera != null else {},
		"trabajadores": m.trabajadores.a_dic() if m.trabajadores != null else {},
		"redes": m.redes.a_dic() if m.redes != null else {},
		"carrera_jugador": m.carrera_jugador.a_dic() if m.carrera_jugador != null else {},
		"movil": m.movil.a_dic() if m.movil != null else {},
		"mercado_av": m.mercado_av.a_dic() if m.mercado_av != null else {},
		"insolvencia": m.insolvencia.a_dic() if m.insolvencia != null else {},
		"ajustes_competicion": m.ajustes_competicion.duplicate(),
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
	var ruta := ruta_de(nombre)
	## GUARDADO SEGURO (20-10-2026): antes se escribía encima del archivo; un
	## cierre o un corte de luz a mitad dejaba la partida rota y sin copia.
	## Ahora se escribe en un temporal, se comprueba, la versión anterior pasa
	## a ser la copia (.bak) y el temporal ocupa su sitio.
	var tmp := ruta + TEMPORAL
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Partida: no puedo escribir %s (error %d)" % [tmp, FileAccess.get_open_error()])
		return false
	## El tamaño sin comprimir va delante porque `decompress` lo necesita: sin
	## él no hay forma de saber cuánto reservar y la carga falla en silencio.
	var comprimido := crudo.compress(FileAccess.COMPRESSION_DEFLATE)
	f.store_32(crudo.size())
	f.store_buffer(comprimido)
	var ok := f.get_error() == OK
	f.close()
	if not ok or FileAccess.get_file_as_bytes(tmp).size() != comprimido.size() + 4:
		push_error("Partida: el guardado temporal %s salió incompleto" % tmp)
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ruta + RESPALDO)
		DirAccess.rename_absolute(ruta, ruta + RESPALDO)
	if DirAccess.rename_absolute(tmp, ruta) != OK:
		push_error("Partida: no puedo mover %s a su sitio" % tmp)
		return false
	return true

static func _dic_a_jugador(d: Dictionary) -> Jugador:
	var j := Jugador.new()
	j.id = String(d["i"]); j.nombre = String(d["n"]); j.pais = String(d["p"])
	j.region = String(d.get("rg", ""))
	j.club_id = String(d["c"]); j.club_formacion = String(d["cf"])
	j.pos = String(d["g"]); j.pos_e = String(d["pe"])
	j.edad = int(d["e"]); j.ovr = int(d["o"]); j.pot = int(d["t"])
	j.atributos = d["at"]; j.rasgo = String(d["r"])
	j.forma = int(d["f"]); j.moral = int(d["m"]); j.fisico = int(d["fi"])
	j.historial_moral = (d.get("hm", []) as Array).duplicate(true)
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
