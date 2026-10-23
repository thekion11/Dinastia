extends RefCounted
## [Capa 1/4 de `vestuario.gd`] _init, _mundo, _club, _jugador, _montar_clan, agente_de … (+8)

## El camarín: los grupos que se forman solos, la cabeza de cada jugador y el
## papel que le prometiste a cada uno.
##
## Son tres mecanismos distintos que comparten la misma materia prima —el humor
## del plantel— y por eso viven juntos:
##
##   1. LAS CAMARILLAS. Los jugadores se agrupan por nacionalidad minoritaria,
##      por edad y por representante. Cada grupo tiene un líder, y sentar al
##      líder tres semanas seguidas le baja el ánimo al grupo entero.
##   2. LA CABEZA. Ansiedad y confianza por jugador. La ansiedad sube con las
##      lesiones y la mala racha, y si se dispara el jugador pide ayuda y se
##      pierde un par de semanas.
##   3. EL ROL EN EL PLANTEL. Le prometes ser intocable o le dices que es
##      prescindible, y cada semana se comprueba si le estás cumpliendo.
##
## POR QUÉ ESTO NO ES DECORACIÓN. Todo lo de aquí termina en un número que el
## motor de partido ya lee:
##
##   · La moral entra en `Partido._media_linea()` como `0.9 + 0.002 * moral`.
##     Un vestuario roto pierde puntos de fuerza en cada línea, todas las
##     semanas. Es la vía principal, y la mueven las camarillas, el rol
##     incumplido y la deriva de satisfacción.
##   · `factor_ataque()` y `factor_defensa()` entran por `Club.bonus_ataque` /
##     `Club.bonus_defensa`, la puerta que el simulador consulta desde el primer
##     día. Ahí van la química de los hermanos, los roles tácticos del once y el
##     ánimo del vestuario.
##
## Un menú de camarín precioso que no toca ninguno de esos dos números sería el
## error que este proyecto ya ha pagado varias veces.
##
## POR QUÉ LLEVA SUS PROPIAS FICHAS. `Jugador` no tiene —ni va a tener— campos
## de ansiedad, clan, rol prometido ni hermano. En el HTML todo eso colgaba del
## jugador (`j.mente`, `j.clan`, `j.rolClub`, `j.rolPJ`, `j.hermanoDe`) y
## cualquiera de sus 847 funciones podía pisarlo. Aquí vive indexado por id de
## jugador, exactamente como hace `Medico` con el historial de lesiones.
##
## El azar sale SIEMPRE de `Azar`: una crisis de ansiedad puede costar un
## partido importante, y si no es repetible no se puede reproducir la partida
## que reporte el usuario.

## Lo que sale en el diario. La interfaz se engancha aquí; el simulador no sabe
## que hay una interfaz.
signal noticia(titulo: String, cuerpo: String)
## Un grupo del vestuario se ha hartado de que su líder no juegue.
signal clan_enfadado(clan: Dictionary, lider: Jugador)
## El jugador se rompió por dentro y pide ayuda: semanas de baja psicológica.
signal crisis_mental(j: Jugador, semanas: int)
## Le prometiste un papel y no se lo estás dando. `ratio` es su porcentaje real
## de titularidades.
signal rol_incumplido(j: Jugador, ratio: float)
## Dinero que sale por una terapia, para el libro de movimientos.
signal gasto(concepto: String, monto: int)
## Aparece un hermano (o un gemelo) de alguien del plantel.
signal hermanos_nuevos(nuevo: Jugador, base: Jugador, gemelos: bool)

# ---------------------------------------------------------------------------
#  NÚMEROS DEL HTML
# ---------------------------------------------------------------------------

## Cada cuántas semanas se vuelven a dibujar los grupos (`G.sem%6===0`).
const CADA_CUANTAS_SEMANAS := 6
## Un grupo necesita tres para existir. Con dos no es una camarilla, son dos
## que se sientan juntos.
const MIEMBROS_MINIMOS := 3
## Semanas seguidas con el líder fuera del once antes de que el grupo estalle.
const PACIENCIA_LIDER := 3
## Semanas de rol cumplido que hacen falta antes de juzgar nada. Con menos, un
## lesionado de dos semanas ya "incumplía" su promesa de titular.
const ROL_MINIMO_SEMANAS := 6
## Y a partir de aquí la ventana se cierra sola aunque todo vaya bien, para que
## la cuenta mire el mes que viene y no la temporada pasada.
const ROL_VENTANA_MAX := 12
## Ansiedad a partir de la cual el jugador puede quebrarse.
const ANSIEDAD_CRISIS := 82
## Ansiedad "de fábrica" del mundo: es la media de `R(4,34)`, el sorteo con el
## que nace todo el mundo en `initMente()`. Se usa como cero del factor de
## ánimo — ver `factor_animo()`.
const ANSIEDAD_NEUTRA := 19.0
## Cuánto pesa un punto de ansiedad en la fuerza del jugador. Sale tal cual de
## `fuerzaJug()`: `(1 - ansiedad * 0.0018)`.
const PESO_ANSIEDAD := 0.0018

## OJO: referencia DÉBIL al mundo, no fuerte.
##
## El mundo guarda su vestuario y el vestuario necesita ver el mundo (el club
## propio, el mercado de nombres, el cuerpo técnico). Con dos referencias
## normales eso es un ciclo, y RefCounted no recoge ciclos: al salir del banco
## de pruebas se quedaban 19.000 objetos sin liberar, porque un Mundo que no
## muere se lleva consigo sus 384 clubes y sus miles de jugadores. Ya han caído
## cuatro clases en esta trampa.
var _ref: WeakRef

## Los grupos del vestuario. Cada uno es un diccionario con: id, tipo, nombre,
## miembros (ids), lider (id), humor (-100..100) y fuera (semanas seguidas con
## el líder en el banco).
var camarillas: Array[Dictionary] = []

var _clan_de: Dictionary = {}      ## id de jugador -> id de camarilla
var _mente: Dictionary = {}        ## id de jugador -> ficha mental
var _rol: Dictionary = {}          ## id de jugador -> clave de ROL_PLANTEL
var _rol_cuenta: Dictionary = {}   ## id de jugador -> {"pj": int, "min": int}
var _rol_tactico: Dictionary = {}  ## id de jugador -> clave de ROLES
var _hermano: Dictionary = {}      ## id de jugador -> id de su hermano

# ---------------------------------------------------------------------------
#  3B · LAS SOLICITUDES DEL PLANTEL
# ---------------------------------------------------------------------------
## `SOLICITUDES` del HTML: un jugador viene a hablar contigo con una petición
## concreta -"podrán hacer exigencias y solicitudes"-, y hay que decirle que sí
## o que no, cada una con su propia consecuencia. Vivía en el HTML como una
## función suelta (`solicitudDeJugador()`/`resolverSolicitud()`) sin clase que
## la contuviera; aquí entra en `Vestuario` porque es exactamente la misma
## materia prima que el resto del fichero -moral, rol, ánimo del plantel-.
##
## Clave, título, texto si aceptas, texto si rechazas.
const SOLICITUDES := [
	["minutos", "Pide más minutos", "Le prometes subirle el rol un escalón.", "Se lo niegas y lo asume como puede."],
	["sueldo", "Pide mejora de sueldo", "Le subes un 12% la ficha.", "Le dices que no hay presupuesto."],
	["salida", "Pide salir del club", "Lo pones en la lista de transferibles.", "Le dices que cuentas con él."],
	["compa", "Pide que fiches a un compatriota", "Le prometes buscar a alguien de su país.", "Le dices que el mercado no da para eso."],
	["descanso", "Pide días libres", "Le das dos días de descanso.", "Le recuerdas que se entrena igual."],
	["instal", "Se queja de las instalaciones", "Le prometes que hay obras en camino.", "Le dices que se aguante."],
	["capitan", "Quiere ser capitán", "Le das la cinta.", "Mantienes al capitán actual."],
]

## Solo una activa a la vez -igual que `G.solicitud`-: {"pid", "k"}, o vacío.
var solicitud: Dictionary = {}

# ---------------------------------------------------------------------------
#  LA CHARLA DEL ENTRETIEMPO
# ---------------------------------------------------------------------------
#
# `charla()` del HTML. Vive aquí y no en la pantalla del partido porque toca lo
# mismo que todo este archivo -moral y ansiedad, jugador a jugador- y porque así
# el banco puede comprobar que sacudir al equipo cuando va ganando es mala idea.
#
# La gracia del sistema es que **no hay un tono bueno**. Cada tono tiene un
# margen de efecto (`ef`), y los de más recorrido son también los que más pueden
# hundirte: "Sacudir" va de -9 a +14. Y el rasgo del jugador decide si le sienta
# bien: a un líder o a una muralla les va la exigencia, a un frágil o a un
# cerebro el elogio. Gritarle al frágil le sube la ansiedad y le baja la moral.

## clave -> [nombre, icono, efecto mínimo, efecto máximo, delta de ansiedad,
##           qué clase de jugador lo agradece]
const TONOS := {
	"calma":   ["Calmar", "🧘", 0, 5, -8, "elogio"],
	"animar":  ["Elogiar", "👏", 2, 7, -5, "elogio"],
	"exigir":  ["Exigir", "☝️", -3, 9, 2, "exigencia"],
	"furia":   ["Sacudir", "🔥", -9, 14, 9, "exigencia"],
	"tactico": ["Pizarra", "📋", 1, 5, -3, ""],
	"senalar": ["Señalar a uno", "🎯", -6, 10, 6, "exigencia"],
}

## Qué prefiere oír cada perfil. Los que no están en la tabla se lo toman igual
## venga como venga: no todo el mundo tiene carácter marcado.
const PREFIERE := {
	"lider": "exigencia", "muralla": "exigencia",
	"fragil": "elogio", "cerebro": "elogio",
}

# ---------------------------------------------------------------------------
#  EL SUCESO DE LA SEMANA (`eventoSemanal()` del HTML)
# ---------------------------------------------------------------------------
#
# Una cosa pequeña por semana en el camarín. Ninguna decide un partido y juntas
# son lo que hace que un plantel se sienta un grupo de personas: el polémico se
# va de fiesta, el líder reúne a todos, el killer se queda practicando, alguien
# cumple años y la joya golpea la puerta.
#
# CADA SUCESO NACE DE UN RASGO REAL de alguien de tu plantilla. Si nadie tiene el
# rasgo, ese suceso no puede pasar, y por eso fichar a un polémico se nota en el
# vestuario aunque no juegue: es lo que separa un rasgo de una etiqueta.
#
# AQUÍ SE COBRA LA NORMA «MULTAS», que estaba en el menú desde el porte y no la
# leía nadie: se podía encender el reglamento interno y no se aplicaba una sola
# multa en toda una carrera. Y aquí se cobra el nodo «Duro» del árbol del
# entrenador (`multas_dobles()`), que estaba escrito y tampoco se llamaba.

## LA MULTA SON DOS SEMANAS DE SUELDO DEL MULTADO (25-9-2026). Antes era una
## base fija de 300.000 puntos INTERNOS escalada por la reputación: en un club
## grande salían 14,6 millones de euros por una noche de fiesta -más que la
## caja que entra en un mes-, y como la multa la COBRA el club, tener un
## polémico en el plantel era una mina de oro. Dos semanas de sueldo es lo que
## se ve en el fútbol de verdad, y escala solo con el jugador.
const MULTA_SEMANAS := 2

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

func _club() -> Club:
	var m := _mundo()
	return m.mi_club() if m != null else null

# ---------------------------------------------------------------------------
#  AYUDAS
# ---------------------------------------------------------------------------

func _jugador(id: String) -> Jugador:
	var c := _club()
	if c == null or id == "":
		return null
	for j in c.plantilla:
		if j.id == id:
			return j
	return null

func _montar_clan(cid: String, tipo: String, nombre: String, ids: Array,
		orden: Dictionary, por_potencial: bool, previos: Dictionary) -> Dictionary:
	var m := _mundo()
	var lista := ids.duplicate()
	lista.sort_custom(func(a: String, b: String) -> bool:
		var ja := _jugador(a)
		var jb := _jugador(b)
		var va := 0
		var vb := 0
		if ja != null:
			va = ja.pot if por_potencial else ja.ovr
		if jb != null:
			vb = jb.pot if por_potencial else jb.ovr
		if va != vb:
			return va > vb
		return int(orden.get(a, 0)) < int(orden.get(b, 0)))
	var viejo: Dictionary = previos.get(cid, {})
	return {
		"id": cid,
		"tipo": tipo,
		"nombre": nombre,
		"miembros": lista,
		"lider": (String(lista[0]) if not lista.is_empty() else ""),
		"humor": int(viejo.get("humor", 0)),
		"fuera": int(viejo.get("fuera", 0)),
	}

## El agente que representa a un jugador. Es una elección ESTABLE, no un sorteo:
## sale del hash de su id, igual que en el HTML, para que el mismo jugador tenga
## siempre el mismo representante partida tras partida. Si se sorteara, las
## camarillas por agencia se rehicieran solas cada seis semanas.
func agente_de(j: Jugador) -> String:
	var lista: Array = Datos.tabla("AGENTES")
	if lista == null or lista.is_empty():
		return "sin agente"
	## El mismo hash del HTML: `s*17 + código`, truncado a 32 bits sin signo.
	var h := 3
	for i in j.id.length():
		h = (h * 17 + j.id.unicode_at(i)) & 0xFFFFFFFF
	var fila: Array = lista[h % lista.size()]
	return Nombres.de_tabla(String(fila[0]))

# ---------------------------------------------------------------------------
#  1 · LAS CAMARILLAS
# ---------------------------------------------------------------------------

## Vuelve a dibujar los grupos del vestuario.
##
## La regla que hace que esto no sea un listado de nacionalidades: el país
## MAYORITARIO no forma camarilla, porque ese no es un grupo, es "el equipo".
## Solo las minorías se juntan. Y si una supuesta minoría pasa de la mitad del
## plantel tampoco cuenta, que es el caso del club con dos colonias grandes.
##
## TRAMPA QUE SE ARREGLA AQUÍ: el HTML creaba los grupos con `humor:0` cada vez
## que llamaba a esta función, y la llamaba en diecinueve sitios (tras cada
## fichaje, cada cambio de once, cada carga de partida). El resultado es que el
## enfado de un grupo se borraba antes de llegar a nada y `chequeo_clanes()` no
## se notaba nunca. Aquí el humor y la cuenta de paciencia SOBREVIVEN al
## redibujado si el grupo sigue existiendo con el mismo id. Las fórmulas no se
## tocan; lo que se arregla es que lleguen a aplicarse.
func armar() -> Array[Dictionary]:
	var previos := {}
	for cl in camarillas:
		previos[String(cl["id"])] = cl
	camarillas.clear()
	_clan_de.clear()
	var c := _club()
	if c == null or c.plantilla.is_empty():
		return camarillas
	var pl := c.plantilla

	## Índice de posición en la plantilla. Sirve para romper empates SIEMPRE
	## igual: `sort_custom` de Godot no es estable y sin esto dos partidas con
	## la misma semilla podían elegir líderes distintos.
	var orden := {}
	for i in pl.size():
		orden[pl[i].id] = i

	## --- Colonias por nacionalidad ---
	var por_pais: Dictionary = {}
	for j in pl:
		if not por_pais.has(j.pais):
			por_pais[j.pais] = []
		(por_pais[j.pais] as Array).append(j.id)
	var mayor := ""
	var mayor_n := -1
	for p: String in por_pais:
		var n: int = (por_pais[p] as Array).size()
		if n > mayor_n:
			mayor_n = n
			mayor = p
	var bandera: Dictionary = Datos.tabla("BANDERA")
	if bandera == null:
		bandera = {}
	for p: String in por_pais:
		if p == mayor:
			continue
		var ids: Array = por_pais[p]
		if float(ids.size()) > float(pl.size()) * 0.5:
			continue
		if ids.size() < MIEMBROS_MINIMOS:
			continue
		var nom := "Colonia %s %s" % [String(bandera.get(p, "")), p]
		camarillas.append(_montar_clan("n_" + p, "nacion", nom.strip_edges(), ids, orden, false, previos))

	## --- Veteranos y camada joven ---
	var vets: Array = []
	var jov: Array = []
	for j in pl:
		if j.edad >= 30:
			vets.append(j.id)
		if j.edad <= 21:
			jov.append(j.id)
	if vets.size() >= MIEMBROS_MINIMOS:
		camarillas.append(_montar_clan("vets", "veterania", "Los históricos", vets, orden, false, previos))
	## A los jóvenes los lidera el de más POTENCIAL, no el de más media: en ese
	## grupo el que manda es al que todos ven llegando, no el que hoy juega.
	if jov.size() >= MIEMBROS_MINIMOS:
		camarillas.append(_montar_clan("jov", "cantera", "La camada joven", jov, orden, true, previos))

	## --- Representados por el mismo agente ---
	var por_agente: Dictionary = {}
	for j in pl:
		var a := agente_de(j)
		if not por_agente.has(a):
			por_agente[a] = []
		(por_agente[a] as Array).append(j.id)
	for a: String in por_agente:
		var ids_ag: Array = por_agente[a]
		if ids_ag.size() >= MIEMBROS_MINIMOS:
			camarillas.append(_montar_clan("ag_" + a, "agencia", "Representados por " + a, ids_ag, orden, false, previos))

	## Cada jugador pertenece al PRIMER grupo que lo contiene, no a todos. Si se
	## repartiera el mismo enfado por tres vías, un extranjero veterano con
	## agente conocido cobraría el triple que su compañero de al lado.
	for j in pl:
		for cl in camarillas:
			if (cl["miembros"] as Array).has(j.id):
				_clan_de[j.id] = cl["id"]
				break
	return camarillas

func clan_por_id(cid: String) -> Dictionary:
	for cl in camarillas:
		if String(cl["id"]) == cid:
			return cl
	return {}

func clan_de(j: Jugador) -> Dictionary:
	var cid: String = String(_clan_de.get(j.id, ""))
	return clan_por_id(cid)

func _mover_moral(j: Jugador, d: int) -> void:
	j.cambiar_moral(d, "Vida del vestuario")

func ansiedad(j: Jugador) -> int:
	return int(mente(j)["ansiedad"])

func confianza(j: Jugador) -> int:
	return int(mente(j)["confianza"])

# ---------------------------------------------------------------------------
#  2 · LA CABEZA
# ---------------------------------------------------------------------------

## La ficha mental de un jugador, creándola si es la primera vez que se pregunta
## por él. Nace con el sorteo del HTML: los chicos llegan más nerviosos, los
## frágiles arrastran el miedo a romperse otra vez y los líderes tienen más
## confianza de salida.
func mente(j: Jugador) -> Dictionary:
	if not _mente.has(j.id):
		var ansiedad := Azar.ent(4, 34)
		if j.edad < 20:
			ansiedad += 10
		if j.rasgo == "fragil":
			ansiedad += 8
		var confianza := Azar.ent(45, 80)
		if j.rasgo == "lider":
			confianza += 10
		_mente[j.id] = {
			"ansiedad": clampi(ansiedad, 0, 100),
			"confianza": clampi(confianza, 0, 100),
			"terapia": 0,
			"descanso": 0,
			"baja": 0,
		}
	return _mente[j.id]
func _mover_ansiedad(j: Jugador, d: int) -> void:
	var f := mente(j)
	f["ansiedad"] = clampi(int(f["ansiedad"]) + d, 0, 100)
