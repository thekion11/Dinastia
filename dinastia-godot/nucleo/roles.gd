class_name Roles
extends RefCounted
## Los roles de carrera: qué puesto ocupas en el club y, por tanto, qué te dejan
## tocar y cómo se sube de uno al siguiente.
##
## En el HTML esto vivía desparramado entre `G.rol`, `rolSel`, `mando()`,
## `esAyudante()`, `enInterinato()`, `mercadoBloqueado()` y una veintena de
## `if(G.rol==='...')` sueltos por las 17.900 líneas. El resultado era el fallo
## clásico del proyecto: la pantalla del director de cantera te dejaba armar la
## alineación aunque el propio juego acabara de decirte "no diriges al primer
## equipo: eso es cosa de X". El permiso existía en la cabeza del que escribió
## el texto, no en el código.
##
## Aquí el permiso se PREGUNTA, no se recuerda: una tabla de permisos y unos
## métodos `puede_*()` sin efectos secundarios, para que la interfaz apague el
## botón en vez de dejar que se pulse y no pase nada. Un botón que no hace nada
## es peor que un botón apagado: el jugador no sabe si el juego está roto o si
## es él quien no entiende las reglas.
##
## ESTO NO DUPLICA A `Directiva`. La directiva es quien te exige un puesto y
## quien te echa; el rol es lo que te dejan hacer mientras estás. Se apoyan uno
## en el otro: el interino lleva otro objetivo y una fecha de término escrita en
## el contrato, y al dueño y al ayudante no los juzga el directorio (al dueño no
## hay quien lo eche; al ayudante lo juzga su jefe, que es otra cosa).
##
## Y guarda el PRESTIGIO del entrenador (`G.dt.rep` del HTML), que no vivía en
## ninguna clase de este puerto —`Logros` dejó anotado que le faltaba— y que es
## justo lo que abre las dos puertas de ascenso.

## El rol cambió: de ayudante a entrenador, de entrenador a director, etc.
signal rol_cambiado(antes: String, ahora: String)
## Un titular y un texto para la bandeja de noticias. Es el `noticia()` del HTML:
## el rol no sabe pintar nada, solo cuenta lo que ha pasado.
signal aviso(titulo: String, texto: String)
signal ascenso(nuevo_rol: String)
signal interinato_resuelto(salvado: bool)
signal fuera_del_cuerpo_tecnico(jefe: String)
signal sin_banco(club: String)
## Las tres de `vLegado()`: la escuela que nace sola, el homenaje a una leyenda
## y el punto final de la carrera.
signal escuela_nacida(nombre: String, formacion: String)
signal homenaje_hecho(nombre: String)
signal carrera_cerrada(anio: int, puntaje: int)

## --- LOS ROLES --------------------------------------------------------------
## Seis roles para ocho modos de menú: "jeque" y "imperio" son los dos el dueño
## (uno con la caja llena desde el minuto uno), y "creador" es un entrenador que
## además funda su club. El menú no es la lista de roles, y confundirlos fue lo
## que hizo que en el HTML hubiera tarjetas sin destino.
const DT := "dt"
const DIR := "dir"
const AYUDANTE := "ayudante"
const CANTERA := "cantera"
const DUENO := "dueño"

## OJO: "interino" es una opción del MENÚ, no un valor de `rol`. El interinato es
## un estado que se monta ENCIMA del entrenador (el HTML hace `G.rol='dt'` y
## `G.interino={...}` en la misma función). Se porta igual a propósito: si fuera
## un rol aparte habría que repetir los permisos del entrenador en otra fila de
## la tabla y mantener las dos a la vez.
const MODO_INTERINO := "interino"

## Qué puede tocar cada rol. Se lee, no se calcula: añadir un rol es una fila
## más, y quitarle un permiso a uno es cambiar un `true` por un `false` sin
## tocar ninguna pantalla.
##
## `manda` es el `mando()` del HTML y está mal llamado a propósito, porque así se
## llama allí: no significa "tiene poder", significa "el once NO lo pone él".
## Agrupa al despacho (director, dueño, cantera) con el ayudante, que están en
## las antípodas del organigrama pero comparten esa consecuencia.
##
## Al AYUDANTE se le cierran además el cuerpo técnico y las obras. El HTML no lo
## hacía —dejaba los botones vivos—, pero el propio texto del modo promete otra
## cosa: "No fichas, no vendes y no pones el once. Lo tuyo son los entrenamientos,
## el camarín y la cantera". Contratar al jefe médico del club no es de un
## ayudante de campo. Es la única línea de esta tabla que aprieta más que el
## original, y está aquí, en un sitio, por si hay que soltarla.
const PERMISOS := {
	DT: {
		"cargo": "entrenador", "manda": false,
		"fichar": true, "alinear": true, "staff": true, "construir": true,
		"vender_jugadores": true, "rescindir": true,
		"contratar_dt": false, "capital": false, "vender_club": false,
		"lo_echan": true,
	},
	DIR: {
		"cargo": "director deportivo", "manda": true,
		"fichar": true, "alinear": false, "staff": true, "construir": true,
		"vender_jugadores": true, "rescindir": true,
		"contratar_dt": true, "capital": false, "vender_club": false,
		"lo_echan": true,
	},
	DUENO: {
		"cargo": "dueño", "manda": true,
		"fichar": true, "alinear": false, "staff": true, "construir": true,
		"vender_jugadores": true, "rescindir": true,
		"contratar_dt": true, "capital": true, "vender_club": true,
		"lo_echan": false,
	},
	CANTERA: {
		"cargo": "director de cantera", "manda": true,
		"fichar": true, "alinear": false, "staff": true, "construir": true,
		"vender_jugadores": true, "rescindir": true,
		"contratar_dt": true, "capital": false, "vender_club": false,
		"lo_echan": true,
	},
	AYUDANTE: {
		"cargo": "ayudante de campo", "manda": true,
		"fichar": false, "alinear": false, "staff": false, "construir": false,
		"vender_jugadores": false, "rescindir": false,
		"contratar_dt": false, "capital": false, "vender_club": false,
		"lo_echan": false,
	},
}

## Las dos puertas de ascenso, portadas de `puedeAscenderRol()`. Piden trofeos Y
## prestigio: solo trofeos lo abriría un ciclo ganador en un club grande, y solo
## prestigio lo abriría aguantando muchos años sin ganar nada.
const ASCENSOS := {
	DT: {"a": DIR, "trofeos": 6, "prestigio": 72},
	DIR: {"a": DUENO, "trofeos": 12, "prestigio": 82},
}

## El interinato dura cinco fechas. No es un número redondo puesto por gusto: es
## lo que hace que cada partido pese un 20% del contrato.
const FECHAS_INTERINATO := 5

## Lo que el jefe le pide al ayudante para dejarle el banco, y lo que aguanta
## antes de echarlo del cuerpo técnico.
const JEFE_CONFIANZA_INICIAL := 45
const JEFE_ASCIENDE := 88
const JEFE_ECHA := 8
const PRESTIGIO_PARA_EL_BANCO := 55

## El prestigio arranca en 50 (`dt:{rep:50}` del HTML) y nunca llega a 0 ni a
## 100: un entrenador sin ningún crédito no encontraría club, y uno intocable
## dejaría de tener carrera.
const PRESTIGIO_INICIAL := 50
const PRESTIGIO_MIN := 1
const PRESTIGIO_MAX := 99

## Lo que cuesta cambiar de entrenador empleado: finiquito del que se va más
## contrato del que llega. Se escala al tamaño del club como cualquier gasto
## operativo, así que en un club chico es una decisión de verdad.
const COSTE_CAMBIAR_DT := 300000.0

## El sueldo del entrenador empleado -o de tu jefe, si eres ayudante-, que en
## el HTML se cobra semana a semana (`mov(-esc$(25000),...)` con
## `G.rol!=='dt'&&G.dtEmp`) y aquí se pliega al cierre de mes, igual que ya
## hace `Staff.sueldo_semanal()`: es Mundo quien lo cobra, no esta clase, para
## no repetir la lógica de "solo si es TU club" que ya vive allí.
const SUELDO_SEMANAL_DT_EMPLEADO := 25000

## --- ESTADO -----------------------------------------------------------------

var rol: String = DT
var nombre: String = "Míster"
## EL ASPECTO DEL DT. `CaraDT.look_por_defecto()` cuando está vacío -mismo
## patrón que `Jugador.look` con `Cara.look_de()`: solo se guardan los rasgos
## que el usuario tocó a mano, no los 552 combinables enteros por cada
## partida-. Es dato de presentación, vive aquí y no en `Mundo` porque es de
## la CARRERA del entrenador, no del club: si cambias de club, tu cara no
## cambia con él.
var look: Dictionary = {}

## El aspecto de verdad, con los valores por defecto rellenando lo que no se
## ha tocado -mismo merge que `Cara.look_de()` hace con `Jugador.look`, solo
## que la base aquí es un `Dictionary` fijo (`CaraDT.look_por_defecto()`), no
## un hash: el DT no tiene un id de futbolista del que derivar una cara.
func look_efectivo() -> Dictionary:
	var base := CaraDT.look_por_defecto()
	for k: String in look:
		base[k] = look[k]
	return base

## El prestigio del entrenador y su vitrina, que son de la CARRERA y no del club:
## `Directiva.trofeos` se queda en el club que abandonas, esto te sigue.
var prestigio: int = PRESTIGIO_INICIAL
var trofeos: Array[Dictionary] = []      ## {anio, titulo}
var historial: Array[Dictionary] = []    ## {club, hasta} — los clubes por donde pasaste
var temporadas: int = 0
var sin_club: bool = false               ## el `G.fase==='despedido'` del HTML

## `G.filosofia` del HTML: si repites el MISMO dibujo y la misma mentalidad
## durante casi dos temporadas seguidas, la prensa le pone tu apellido y nace
## una escuela. Es el único premio del juego que no se persigue: se cae encima
## del que es fiel a una idea. Claves: nombre, formacion, mentalidad.
var filosofia: Dictionary = {}
var _estilos_contados: Dictionary = {}   ## "3-4-3|2" -> semanas con ese modelo

## `G.retirado`: el punto final voluntario. Vacío mientras sigas en activo.
var retirado: Dictionary = {}            ## {anio, puntaje}

## Cuántas semanas fiel al mismo modelo hacen falta para que la escuela nazca.
## En el HTML son 90 chequeos semanales: casi dos temporadas enteras.
const SEMANAS_PARA_ESCUELA := 90

## El entrenador que dirige cuando tú no diriges: el empleado del despacho o,
## si eres ayudante, tu jefe. En el HTML son el MISMO objeto (`G.dtEmp=G.jefe`),
## y aquí también: `jefe` y `dt_empleado` apuntan al mismo diccionario, que es lo
## que hace que el motor de partido no tenga que saber quién de los dos es.
## Claves: nombre, estilo, sintonia, y además confianza y malos si es un jefe.
var dt_empleado: Dictionary = {}

## `G.directrices` del HTML: lo que le PIDES al entrenador cuando el banco no es
## tuyo (director deportivo, dueño, o de ayudante). No son órdenes: te hace caso
## según la sintonía, y **meterte en su trabajo la desgasta**. Ese es el juego —
## puedes dirigir sin dirigir, pero cada indicación cuesta relación.
var directrices := {"estilo": "equilibrio", "cantera": false, "rotacion": false, "cuidar": true}

const DIRECTRICES_DEF := [
	["cantera", "Dale minutos a la cantera",
		"Meterá a un chico de 20 o menos en el once, sacando al más flojo."],
	["rotacion", "Rota a los cansados",
		"Cambiará a un titular por debajo de 70 de físico por alguien fresco."],
	["cuidar", "Cuida a los tocados",
		"Evitará sacar a quien venga con el físico justo, aunque sea mejor."],
]
const ESTILOS_DEF := [
	["equilibrio", "Como él quiera", "Sin indicaciones: monta el equipo a su manera."],
	["ofensivo", "Juega al ataque", "Mentalidad ofensiva y un dibujo con más gente arriba."],
	["defensivo", "Juega replegado", "Mentalidad defensiva y cinco atrás."],
]

## Cambiar una directriz.
##
## `dt_obedece()` y `desgastar_relacion()` ya estaban portadas más abajo en este
## mismo archivo -sistema escrito antes y todavía sin pantalla-, así que aquí
## solo se guarda la decisión y se llama a la que ya existía. El texto de queja
## sale por la señal `aviso`, que la pantalla ya escucha.
func fijar_directriz(clave: String, valor: Variant) -> void:
	directrices[clave] = valor
	desgastar_relacion()

## Aplica al club lo que el entrenador decide, con tus indicaciones si te hace
## caso. Se llama antes de jugar cuando el banco no es tuyo.
func aplicar_directrices(c: Club) -> void:
	if dt_empleado.is_empty() or c == null:
		return
	var estilo := String(directrices.get("estilo", "equilibrio"))
	if estilo != "equilibrio" and dt_obedece():
		if estilo == "ofensivo":
			c.tactica.mentalidad = Tactica.Mentalidad.OFENSIVA
			c.tactica.formacion = "3-4-3"
		elif estilo == "defensivo":
			c.tactica.mentalidad = Tactica.Mentalidad.DEFENSIVA
			c.tactica.formacion = "5-3-2"
	## Las tres que tocan la LISTA, no el dibujo. Se arma el once desde cero y
	## se sustituye a mano: es lo que hace el HTML, y así el cambio se nota.
	if bool(directrices.get("cantera", false)) and dt_obedece():
		_meter_canterano(c)
	if bool(directrices.get("rotacion", false)) and dt_obedece():
		_rotar_cansado(c)

func _meter_canterano(c: Club) -> void:
	var once := c.once()
	if once.size() < 11:
		return
	var joven: Jugador = null
	for j in c.disponibles():
		if j.edad <= 20 and not once.has(j) and (joven == null or j.ovr > joven.ovr):
			joven = j
	if joven == null:
		return
	## Sale el más flojo, pero nunca el portero: cambiar de arquero por dar
	## minutos a un chico es otra decisión, y bastante más gorda.
	var fuera: Jugador = null
	for j in once:
		if not j.es_portero() and (fuera == null or j.ovr < fuera.ovr):
			fuera = j
	if fuera == null:
		return
	var nuevo := once.duplicate()
	nuevo[nuevo.find(fuera)] = joven
	c.fijar_once(nuevo)

func _rotar_cansado(c: Club) -> void:
	var once := c.once()
	if once.size() < 11:
		return
	var cansado: Jugador = null
	for j in once:
		if not j.es_portero() and j.fisico < 70:
			cansado = j
			break
	if cansado == null:
		return
	var fresco: Jugador = null
	for j in c.disponibles():
		if not once.has(j) and j.fisico > 85 and (fresco == null or j.ovr > fresco.ovr):
			fresco = j
	if fresco == null:
		return
	var nuevo := once.duplicate()
	nuevo[nuevo.find(cansado)] = fresco
	c.fijar_once(nuevo)

## Estado de cada modo. Vacíos si no estás en ese modo.
var ayudante: Dictionary = {}   ## {desde, ascendido}
var interino: Dictionary = {}   ## {cumplido, salvado, desde_jornada}
var cantera: Dictionary = {}    ## {meta, subidos, anio_inicio, total}

## La ventana de emergencia de la asociación: si pierdes a un titular por una
## lesión larga con el mercado cerrado, te dejan firmar UN libre. Vive aquí
## porque es la otra mitad de `puedoFichar()`; quien lleve las lesiones la abre
## llamando a `abrir_emergencia()`.
var emergencia: Dictionary = {}   ## {anio, hasta, jugador_id, usada}

## Modo caja ilimitada (la tarjeta "jeque" del menú). Es un sandbox declarado, no
## un truco: se marca en la partida para que al cargarla siga siéndolo.
var sandbox: bool = false

## El objetivo que la directiva te puso por reputación, guardado antes de que un
## modo especial lo pise, para poder devolverlo cuando el modo termine.
var _objetivo_club: String = ""

## Igual que `Mercado`: se mira el mundo sin sujetarlo. Un Mundo son 384 clubes y
## 8.448 jugadores; que un objeto pequeño impida liberarlos es el peor de los
## intercambios.
var _ref: WeakRef

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

# ---------------------------------------------------------------------------
# EL MENÚ: de tarjeta a rol
# ---------------------------------------------------------------------------

## Las tarjetas del menú que llevan a una carrera de verdad, con su rol.
## Sale de MODOS_JUEGO, la tabla que ya trae el HTML: escribir la lista otra vez
## aquí garantizaría que un día el menú ofrezca un modo que el rol no conoce.
static func modos_con_rol() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var t: Variant = Datos.tabla("MODOS_JUEGO")
	if t == null:
		return salida
	for m: Dictionary in t:
		if String(m.get("rol", "")) != "":
			salida.append(m)
	return salida

## El rol al que lleva una tarjeta del menú, o "" si esa tarjeta no es una
## carrera (los retos y el tutorial no lo son).
static func rol_de_modo(modo_id: String) -> String:
	var t: Variant = Datos.tabla("MODOS_JUEGO")
	if t == null:
		return ""
	for m: Dictionary in t:
		if String(m.get("id", "")) == modo_id:
			return String(m.get("rol", ""))
	return ""

# ---------------------------------------------------------------------------
# ARRANQUE: el `rolSel` del HTML aplicado sobre una partida ya generada
# ---------------------------------------------------------------------------

## Monta el modo elegido en el menú. `modo_id` es el id de MODOS_JUEGO
## ("dt", "dir", "ayudante", "interino", "cantera", "imperio", "jeque"...).
##
## OJO CON EL ORDEN: esto va DESPUÉS de `Mundo.tomar_el_mando()`, porque varios
## modos pisan el objetivo, la confianza y la caja que la directiva acaba de
## fijar. Es exactamente el fallo que el HTML pagó con el modo jeque: ponía los
## 999.999.999 al crear la partida y la función que elegía club los sobrescribía
## acto seguido con el presupuesto real, así que el modo se anunciaba con un
## aviso y no hacía absolutamente nada. El interinato es la única excepción: elige
## club él mismo, así que se llama ANTES de tomar el mando (lo hace por dentro).
func arrancar(modo_id: String, dt_nombre: String = "Míster") -> void:
	nombre = dt_nombre
	var destino := rol_de_modo(modo_id)
	if destino == "":
		destino = DT
	if modo_id == MODO_INTERINO:
		arrancar_interinato()
		return
	rol = destino
	## Si no diriges tú, hay alguien que dirige. Es la línea del HTML que evita
	## el estado imposible "nadie pone el once".
	if rol != DT:
		_contratar_dt_empleado()
	if modo_id == AYUDANTE:
		arrancar_ayudante()
	elif modo_id == CANTERA:
		arrancar_cantera()
	elif bool(_modo(modo_id).get("sandbox", false)):
		_arrancar_sandbox()
	rol_cambiado.emit("", rol)

## El modo de menú que corresponde al rol de ahora -el camino inverso de
## `rol_de_modo()`-. Lo usa el tutorial al repetirse desde Ajustes, cuando el
## modo con el que se empezó la carrera ya no está en ninguna parte.
func modo_actual() -> String:
	if en_interinato():
		return MODO_INTERINO
	match rol:
		DIR: return "dir"
		AYUDANTE: return "ayudante"
		CANTERA: return "cantera"
		DUENO: return "jeque" if sandbox else "imperio"
	return "dt"

static func _modo(modo_id: String) -> Dictionary:
	var t: Variant = Datos.tabla("MODOS_JUEGO")
	if t == null:
		return {}
	for m: Dictionary in t:
		if String(m.get("id", "")) == modo_id:
			return m
	return {}

func _arrancar_sandbox() -> void:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return
	sandbox = true
	var caja: Variant = Datos.tabla("CAJA_JEQUE")
	var tope := int(caja) if caja != null else 999999999
	m.mi_club().saldo = tope
	aviso.emit("Modo jeque",
		"Un fondo soberano compra el club y te pone al frente sin límite de gasto. " +
		"No hay excusas: con esta caja, lo que salga mal es cosa tuya.")

## Empiezas abajo, de ayudante de un entrenador jefe. No fichas, no vendes y no
## pones el once: lo tuyo son los entrenamientos, el camarín y la cantera, y tu
## carrera consiste en ganarte el banco que ocupa otro.
func arrancar_ayudante() -> void:
	var m := _mundo()
	rol = AYUDANTE
	_contratar_dt_empleado()
	## El jefe ES el entrenador empleado: el mismo diccionario, no una copia. Así
	## el motor de partido sigue leyendo `dt_empleado` sin enterarse de que quien
	## está en el banco además te puede echar.
	dt_empleado["confianza"] = JEFE_CONFIANZA_INICIAL
	dt_empleado["malos"] = 0
	ayudante = {"desde": m.anio if m != null else 0, "ascendido": false}
	_fijar_objetivo("AYUDANTE: ganarte el banco")
	var club := m.mi_club().nombre if m != null and m.mi_club() != null else "el club"
	aviso.emit("Ayudante de campo",
		"Entras al cuerpo técnico de %s como ayudante de %s. No fichas, no vendes y no pones el once: eso es cosa suya. %s" % [
			club, jefe_nombre(),
			"Lo tuyo son los entrenamientos, el camarín y la cantera. Si te ganas su confianza y el equipo responde, el banco acabará siendo tuyo."])

## Solo la cantera: captas chicos, los formas y decides cuándo están listos. El
## primer equipo no es tuyo, y por eso el club te recorta la caja: tu presupuesto
## es el de una academia, no el de un plantel profesional.
func arrancar_cantera() -> void:
	var m := _mundo()
	rol = CANTERA
	_contratar_dt_empleado()
	var meta := Azar.ent(3, 5)
	cantera = {"meta": meta, "subidos": [], "anio_inicio": m.anio if m != null else 0, "total": 0}
	if m != null and m.mi_club() != null:
		m.mi_club().saldo = int(round(float(m.mi_club().saldo) * 0.35))
	_fijar_objetivo("CANTERA: subir %d juveniles al primer equipo esta temporada" % meta)
	aviso.emit("Director de cantera",
		"No diriges al primer equipo: eso es cosa de %s. Tu trabajo es captar chicos, elegir su plan de trabajo, cuidarles la cabeza y decidir cuándo están listos. El club te pide %d debutantes esta temporada." % [
			dt_nombre(), meta])

## Llegas como bombero: te contratan para las últimas cinco fechas con un solo
## objetivo. Ni fichajes ni proyecto, solo motivación y urgencia táctica.
##
## Elige el club él mismo —"el club te lo elige el juego"— entre los cinco peores
## de la primera división del país, y le monta una temporada hundida: sin eso el
## modo se jugaba como una carrera normal empezada tarde, que es exactamente lo
## que le pasaba al HTML antes de cerrarle el mercado.
func arrancar_interinato(pais: String = "CHI") -> void:
	var m := _mundo()
	if m == null:
		return
	var candidatos: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.pais == pais and c.division == 1:
			candidatos.append(c)
	if candidatos.is_empty():
		return
	candidatos.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
	var club: Club = candidatos[Azar.ent(0, mini(4, candidatos.size() - 1))]

	m.tomar_el_mando(club.id)
	rol = DT   ## el interino DIRIGE: lo suyo es el banquillo, no el despacho
	interino = {"cumplido": false, "salvado": false, "desde_jornada": 0}
	sandbox = false
	club.saldo = int(round(Eco.ref_caja(float(club.rep)) * 0.18))

	var l := m.liga_de(club)
	if l != null:
		_montar_liga_hundida(l, club)
		interino["desde_jornada"] = l.jornada_actual
		## La semana del almanaque se pone a la par de la jornada: si no, el
		## calendario y la tabla contarían dos historias distintas, y el mercado
		## —que abre por número de semana— creería que estamos en pretemporada.
		m.semana = l.jornada_actual + 1

	## El vestuario llega hundido. Es la mitad del modo: un plantel con la moral
	## por los suelos rinde por debajo de su media, así que salvarlo no es
	## cuestión de dibujar otro 4-4-2.
	for j in club.plantilla:
		j.moral = Azar.ent(14, 32)
		j.forma = clampi(j.forma - Azar.ent(6, 14), 20, 99)

	_fijar_objetivo("INTERINATO: salvar al club del descenso en %d fechas" % FECHAS_INTERINATO)
	if m.directiva != null:
		## Salvarse es no acabar en los dos últimos, que son los dos que bajan.
		m.directiva.meta_puesto = maxi(1, l.clubes.size() - 2) if l != null else 14
		m.directiva.mover_confianza(28 - m.directiva.confianza, "llegas con el incendio declarado")
	rol_cambiado.emit("", rol)
	aviso.emit("Te llaman para apagar el incendio",
		"%s está en zona de descenso a cinco fechas del final. Echaron al técnico y te firman solo hasta el último partido. %s" % [
			club.nombre,
			"No hay mercado, no hay proyecto y el vestuario está hundido: tienes cinco partidos para salvarlos. Si lo consigues, te lloverán las ofertas."])

## Rellena la tabla como si la temporada estuviera a cinco fechas del final y tú
## fueras el que se va a Segunda.
##
## Primero la liga y DESPUÉS tú, en ese orden: hay que mirar cuántos puntos tiene
## el antepenúltimo para ponerte por debajo. Al revés te quedabas en descenso solo
## de casualidad, y el modo prometía una cosa y planteaba otra.
func _montar_liga_hundida(l: Liga, mio: Club) -> void:
	l.jornada_actual = maxi(0, l.jornadas() - FECHAS_INTERINATO)
	var pj := l.jornada_actual
	var rivales: Array[int] = []
	for c: Club in l.clubes:
		if c == mio:
			continue
		var base := int(round(22.0 + float(c.rep - 60) * 1.4))
		var pts := mini(clampi(base + Azar.ent(-4, 6), 18, 58), pj * 3)
		_anotar_fila(l, c, pj, pts, Azar.ent(20, 44), Azar.ent(20, 40))
		rivales.append(pts)
	rivales.sort()
	## Los puntos del antepenúltimo: el listón que hay que superar para salvarse.
	var corte: int = rivales[mini(2, rivales.size() - 1)] if not rivales.is_empty() else 20
	_anotar_fila(l, mio, pj, maxi(6, corte - Azar.ent(3, 6)), 19, 44)

## Escribe una fila coherente en la tabla: los partidos ganados, empatados y
## perdidos tienen que sumar los jugados y dar los puntos que se le ponen, o la
## pantalla de clasificación enseña una fila imposible.
func _anotar_fila(l: Liga, c: Club, pj: int, pts: int, gf: int, gc: int) -> void:
	var g := mini(pj, pts / 3)
	var e := mini(pj - g, pts - g * 3)
	var p := maxi(0, pj - g - e)
	l.tabla_puntos[c.id] = {
		"pts": g * 3 + e, "pj": pj, "gf": gf, "gc": gc, "g": g, "e": e, "p": p,
	}

# ---------------------------------------------------------------------------
# PERMISOS: lo único que la interfaz necesita preguntar
# ---------------------------------------------------------------------------

func _permiso(clave: String) -> bool:
	var p: Dictionary = PERMISOS.get(rol, PERMISOS[DT])
	return bool(p.get(clave, false))

## El once no lo pones tú. Es el `mando()` del HTML, con su nombre y su rareza:
## agrupa al despacho con el ayudante porque comparten la consecuencia.
func manda() -> bool:
	return _permiso("manda")

func es_ayudante() -> bool:
	return rol == AYUDANTE

func en_interinato() -> bool:
	return not interino.is_empty() and not bool(interino.get("cumplido", false))

func es_cantera() -> bool:
	return rol == CANTERA

## Cómo se llama tu puesto, para los textos de pantalla.
func nombre_del_cargo() -> String:
	var p: Dictionary = PERMISOS.get(rol, PERMISOS[DT])
	if en_interinato():
		return "entrenador interino"
	return String(p.get("cargo", "entrenador"))

## Por qué está cerrado el mercado, o "" si no lo está por culpa del rol.
## Devuelve la misma clave que el HTML ("interinato" / "ayudante") para que se
## pueda comprobar igual desde el banco de pruebas.
func mercado_bloqueado() -> String:
	if en_interinato():
		return "interinato"
	if es_ayudante():
		return "ayudante"
	return ""

## La ventana de pases: semanas 1 a 6 y 18 a 24. Es del calendario, no del rol,
## pero vive aquí porque es la otra mitad de la respuesta a "¿puedo fichar?".
func ventana_abierta() -> bool:
	var m := _mundo()
	if m == null:
		return false
	return m.semana <= 6 or (m.semana >= 18 and m.semana <= 24)

## ¿Puedo fichar AHORA MISMO? Tres cosas a la vez, y las tres tienen que darse:
## que el rol te lo permita, que el mercado esté abierto (o tengas el permiso de
## emergencia) y que el modo no lo tenga cerrado por decreto.
func puede_fichar() -> bool:
	if not _permiso("fichar"):
		return false
	if mercado_bloqueado() != "":
		return false
	return ventana_abierta() or emergencia_activa()

## Poner el once y tocar el pizarrón. Falso para todo el que no dirige: es la
## incoherencia que el HTML arrastró durante versiones (el director de cantera
## armaba la alineación del primer equipo).
func puede_alinear() -> bool:
	return _permiso("alinear")

func puede_contratar_staff() -> bool:
	return _permiso("staff")

func puede_construir() -> bool:
	return _permiso("construir")

func puede_vender_jugadores() -> bool:
	return _permiso("vender_jugadores") and mercado_bloqueado() == ""

func puede_rescindir() -> bool:
	return _permiso("rescindir")

## Contratar y echar al entrenador empleado. El director deportivo manda en el
## despacho, y mandar en el despacho es, sobre todo, elegir quién se sienta en el
## banco.
func puede_contratar_dt() -> bool:
	return _permiso("contratar_dt")

func puede_inyectar_capital() -> bool:
	return _permiso("capital")

func puede_vender_club() -> bool:
	return _permiso("vender_club")

## ¿Te puede echar el directorio? Al dueño no hay quien lo eche —el club es
## suyo—, al ayudante lo juzga su jefe y no el directorio, y al interino no,
## porque su contrato ya trae fecha de término escrita.
##
## Quien conecte `Directiva.despedido` tiene que preguntar esto ANTES de actuar:
## la directiva sigue contando la confianza para todos, es este permiso el que
## decide si esa cuenta tiene consecuencias.
func le_pueden_echar() -> bool:
	if en_interinato():
		return false
	return _permiso("lo_echan")

## La frase que explica por qué el botón está apagado. Un botón gris sin motivo
## se lee como un fallo del juego.
func motivo_bloqueo(accion: String) -> String:
	match accion:
		"fichar":
			if en_interinato():
				return "Interinato: la ventana de pases está cerrada. Con estos te toca."
			if es_ayudante():
				return "Los fichajes no son cosa del ayudante de campo."
			if not _permiso("fichar"):
				return "Tu cargo no firma jugadores."
			if not ventana_abierta() and not emergencia_activa():
				return "Mercado cerrado: las ventanas son las semanas 1-6 y 18-24."
		"alinear":
			if es_ayudante():
				return "El once lo pone %s. Tú propones." % jefe_nombre()
			if manda():
				return "El once lo pone %s, que para eso es el entrenador." % dt_nombre()
		"vender_jugadores":
			if es_ayudante():
				return "Vender no es cosa del ayudante de campo."
			if mercado_bloqueado() != "":
				return "Con el mercado cerrado no se puede vender a nadie."
		"rescindir":
			if es_ayudante():
				return "Rescindir contratos no es cosa del ayudante de campo."
		"staff", "construir":
			if es_ayudante():
				return "El despacho no es tuyo: eso lo decide el club."
		"capital":
			return "Solo el dueño mete dinero de su bolsillo."
		"vender_club":
			return "No se vende lo que no es tuyo."
	return ""

# ---------------------------------------------------------------------------
# LA VENTANA DE EMERGENCIA
# ---------------------------------------------------------------------------

## La asociación te habilita a firmar UN libre con el mercado cerrado porque has
## perdido a un titular por una lesión larga. Una por temporada y una sola bala:
## quien lleve las lesiones llama aquí, y `puede_fichar()` se entera solo.
func abrir_emergencia(jugador_id: String) -> bool:
	var m := _mundo()
	if m == null or ventana_abierta():
		return false
	if int(emergencia.get("anio", -1)) == m.anio:
		return false
	emergencia = {"anio": m.anio, "hasta": m.semana + 3, "jugador_id": jugador_id, "usada": false}
	aviso.emit("Te abren una ventana de emergencia",
		"La asociación acepta el parte médico y te habilita a firmar UN jugador libre durante las próximas tres semanas, con el mercado cerrado para todos los demás. Es una sola bala: elige bien.")
	return true

func emergencia_activa() -> bool:
	var m := _mundo()
	if m == null or emergencia.is_empty():
		return false
	return int(emergencia.get("anio", -1)) == m.anio \
		and not bool(emergencia.get("usada", false)) \
		and m.semana <= int(emergencia.get("hasta", 0))

## Se gasta al cerrar el traspaso, no al abrir la pantalla: la bala se consume
## cuando se dispara.
func usar_emergencia() -> void:
	if not ventana_abierta() and emergencia_activa():
		emergencia["usada"] = true
		aviso.emit("Ventana de emergencia consumida",
			"Usaste el permiso especial de la asociación. Hasta que se abra el mercado de verdad, no puedes fichar a nadie más.")

# ---------------------------------------------------------------------------
# EL ENTRENADOR EMPLEADO (y el jefe, que es el mismo con otro sombrero)
# ---------------------------------------------------------------------------

func dt_nombre() -> String:
	return String(dt_empleado.get("nombre", "—"))

func jefe_nombre() -> String:
	return dt_nombre()

func jefe_confianza() -> int:
	return int(dt_empleado.get("confianza", JEFE_CONFIANZA_INICIAL))

## Cuánto caso te hace el que dirige.
##
## Con poca sintonía hace lo que le da la gana, y ese es el precio de no estar en
## el banco. Como ayudante te hace bastante menos caso todavía: tú propones, no
## ordenas, y la escala depende de lo que tu jefe confíe en ti.
func dt_obedece() -> bool:
	if dt_empleado.is_empty():
		return false
	if es_ayudante():
		return Azar.f() * 100.0 < 10.0 + float(jefe_confianza()) * 0.55
	return Azar.f() * 100.0 < 30.0 + float(dt_empleado.get("sintonia", 60)) * 0.7

## Meterse en su trabajo desgasta la relación: mandar tiene un precio. Lo llama
## quien aplique una directriz.
func desgastar_relacion() -> void:
	if dt_empleado.is_empty():
		return
	if es_ayudante():
		dt_empleado["confianza"] = clampi(jefe_confianza() - 1, 0, 100)
		if jefe_confianza() < 20 and Azar.suerte(0.3):
			aviso.emit("Tu jefe te corta",
				"%s te recuerda delante del grupo quién arma el equipo. Conviene bajar el perfil una temporada." % jefe_nombre())
	else:
		dt_empleado["sintonia"] = clampi(int(dt_empleado.get("sintonia", 60)) - 2, 0, 100)
		if int(dt_empleado["sintonia"]) < 25 and Azar.suerte(0.35):
			aviso.emit("Tu entrenador está incómodo",
				"%s dejó caer en rueda de prensa que «cada uno debería ocuparse de lo suyo». La relación se está deteriorando." % dt_nombre())

## Cambia de entrenador empleado. Devuelve "" si se hizo, o el motivo si no.
## Los métodos que gastan dinero devuelven el motivo en vez de un bool: así la
## pantalla puede decir cuánto falta en vez de un "no se puede" a secas.
func cambiar_dt() -> String:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return "no hay club"
	if not puede_contratar_dt():
		return "el banco no lo eliges tú"
	var c := m.mi_club()
	var coste := Eco.escalar(COSTE_CAMBIAR_DT, float(c.rep))
	if c.saldo < coste:
		return "finiquito y contrato: hacen falta %d y tienes %d" % [coste, c.saldo]
	c.mover_saldo(-coste)
	var viejo := dt_nombre()
	_contratar_dt_empleado()
	aviso.emit("Cambio en el banco",
		"Sale %s, asume %s (%s). La cancha dirá si fue buena idea." % [viejo, dt_nombre(), estilo_dt()])
	return ""

func estilo_dt() -> String:
	var e := String(dt_empleado.get("estilo", "motivador"))
	var t: Variant = Datos.tabla("DT_ESTILOS")
	if t == null:
		return e
	return String(t.get(e, e))

func _contratar_dt_empleado() -> void:
	var estilos: Array = ["ofensivo", "defensivo", "motivador", "pizarron"]
	var t: Variant = Datos.tabla("DT_ESTILOS")
	if t != null and not (t as Dictionary).is_empty():
		estilos = (t as Dictionary).keys()
	dt_empleado = {
		"nombre": _nombre_de_persona(),
		"estilo": String(Azar.uno(estilos)),
		## La sintonía arranca a 60: te hace caso más veces que no, pero no
		## siempre. Un empleado que obedece siempre no es un personaje, es un
		## mando a distancia.
		"sintonia": 60,
	}

## Nombre de persona con el mismo reparto que el HTML: tres de cada diez son
## extranjeros. Se limpia el leetspeak porque las tablas lo llevan.
func _nombre_de_persona() -> String:
	var extranjero := Azar.suerte(0.3)
	var n: Variant = Datos.tabla("NOMBRES_EXT" if extranjero else "NOMBRES")
	var a: Variant = Datos.tabla("APELLIDOS_EXT" if extranjero else "APELLIDOS")
	if n == null or a == null or (n as Array).is_empty() or (a as Array).is_empty():
		return "Míster"
	return Nombres.limpiar("%s %s" % [Azar.uno(n), Azar.uno(a)])

# ---------------------------------------------------------------------------
# EL PULSO DE LA CARRERA: partido, jornada y temporada
# ---------------------------------------------------------------------------

## Después de TU partido. Mueve el prestigio (±1, que es lo que lo mueve de
## verdad a lo largo de una carrera) y, si eres ayudante, pasa la cuenta a tu
## jefe, que es quien te juzga.
func tras_partido(goles_propios: int, goles_rival: int) -> void:
	var gane := goles_propios > goles_rival
	var empate := goles_propios == goles_rival
	sumar_prestigio(1 if gane else (0 if empate else -1))
	if es_ayudante():
		_chequeo_ayudante(gane, empate)

## Después de cada jornada. Solo mira una cosa: si al interino se le acabaron las
## cinco fechas.
func tras_jornada() -> void:
	if en_interinato() and fechas_interinato_restantes() <= 0:
		_resolver_interinato()

## Al cerrar la temporada. `resumen` es lo que devuelve `Directiva.tras_temporada()`.
##
## El prestigio se mueve AQUÍ y no en cuarenta sitios. El HTML lo tocaba en 26
## funciones distintas y por eso nadie sabía nunca por qué había subido; aquí se
## concentra lo que de verdad marca una carrera —cumplir, ganar, fracasar— y el
## resto entra por `sumar_prestigio()` desde donde corresponda.
func tras_temporada(resumen: Dictionary = {}) -> Dictionary:
	temporadas += 1
	if bool(resumen.get("cumplido", false)):
		sumar_prestigio(3)
	elif not resumen.is_empty():
		sumar_prestigio(-2)
	if int(resumen.get("puesto", 0)) == 1:
		sumar_trofeo("Liga")
	if es_cantera():
		_chequeo_cantera()
	var siguiente := puede_ascender()
	return {
		"rol": rol, "prestigio": prestigio, "trofeos": trofeos.size(),
		"temporadas": temporadas, "puede_ascender_a": siguiente,
	}

func sumar_prestigio(delta: int) -> void:
	prestigio = clampi(prestigio + delta, PRESTIGIO_MIN, PRESTIGIO_MAX)

## Un título a la vitrina de la CARRERA. `Directiva.trofeos` se queda en el club
## que dejas; esta lista te sigue de club en club y es la que abre los ascensos.
func sumar_trofeo(titulo: String) -> void:
	var m := _mundo()
	trofeos.append({"anio": m.anio if m != null else 0, "titulo": titulo})
	sumar_prestigio(3)

# ---------------------------------------------------------------------------
# AYUDANTE: ganarte el banco de tu jefe
# ---------------------------------------------------------------------------

## El jefe te evalúa partido a partido: confía más si el equipo gana, menos si
## pierde. Con mucha confianza y prestigio propio, te acaba dejando el banco; con
## muy poca, te saca del cuerpo técnico.
##
## Las dos condiciones del ascenso son a propósito: solo con la confianza del
## jefe, un ayudante recién llegado heredaría el banco de un club grande sin
## haber hecho nada; solo con prestigio, lo heredaría alguien a quien su jefe no
## quiere ni ver.
func _chequeo_ayudante(gane: bool, empate: bool) -> void:
	if ayudante.is_empty() or dt_empleado.is_empty():
		return
	dt_empleado["confianza"] = clampi(jefe_confianza() + (3 if gane else (1 if empate else -2)), 0, 100)
	dt_empleado["malos"] = 0 if gane else (int(dt_empleado.get("malos", 0)) + (0 if empate else 1))
	if jefe_confianza() >= JEFE_ASCIENDE and prestigio >= PRESTIGIO_PARA_EL_BANCO \
			and not bool(ayudante.get("ascendido", false)):
		_ascender_de_ayudante()
		return
	if jefe_confianza() <= JEFE_ECHA:
		_echar_del_cuerpo_tecnico()

func _ascender_de_ayudante() -> void:
	var m := _mundo()
	var jefe := jefe_nombre()
	## Se conserva `ayudante` con la marca puesta en vez de borrarlo: el HTML lo
	## dejaba a null y entonces no había forma de distinguir "ascendió" de "nunca
	## fue ayudante". Se pregunta con `ayudante_ascendido()`.
	ayudante["ascendido"] = true
	var antes := rol
	rol = DT
	dt_empleado = {}
	sumar_prestigio(8)
	_restaurar_objetivo()   ## vuelve el objetivo que el club te pedía
	if m != null and m.directiva != null:
		m.directiva.mover_confianza(62 - m.directiva.confianza, "asciendes a entrenador principal")
	## El XP del perfil de gestor: "el día que dejas de ser el ayudante de
	## alguien". Lleva hito propio porque es un ÚNICO hito en la vida del
	## perfil, no algo que farmear ascendiendo en carrera tras carrera.
	if m != null and m.logros != null:
		m.logros.sumar_xp(Logros.XP_ASCENSO_AYUDANTE, "ascenso_ayudante")
	rol_cambiado.emit(antes, rol)
	ascenso.emit(rol)
	var club := m.mi_club().nombre if m != null and m.mi_club() != null else "el club"
	aviso.emit("El banco es tuyo",
		"%s deja el club y te recomienda como sucesor. El directorio acepta: pasas de ayudante a entrenador principal de %s. Ahora el once, la charla y los fichajes son cosa tuya." % [jefe, club])

func _echar_del_cuerpo_tecnico() -> void:
	var jefe := jefe_nombre()
	var antes := rol
	rol = DT
	ayudante = {}
	dt_empleado = {}
	sumar_prestigio(-3)
	sin_club = true
	rol_cambiado.emit(antes, rol)
	fuera_del_cuerpo_tecnico.emit(jefe)
	aviso.emit("Fuera del cuerpo técnico",
		"%s rehace su equipo de trabajo y tú no entras. Se acabó la etapa de ayudante: te toca buscar banco." % jefe)

func ayudante_ascendido() -> bool:
	return bool(ayudante.get("ascendido", false))

# ---------------------------------------------------------------------------
# INTERINATO: cinco fechas
# ---------------------------------------------------------------------------

## Fechas que te quedan de contrato. Sale del calendario de la liga, no de un
## contador propio: un contador propio se desincroniza en cuanto alguien aplace
## una jornada, y entonces el modo dura seis partidos o cuatro.
func fechas_interinato_restantes() -> int:
	if not en_interinato():
		return 0
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return 0
	var l := m.liga_de(m.mi_club())
	if l == null:
		return 0
	return maxi(0, l.jornadas() - l.jornada_actual)

func _resolver_interinato() -> void:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return
	var l := m.liga_de(m.mi_club())
	if l == null:
		return
	var t := l.tabla()
	var puesto := 0
	for i in t.size():
		if t[i]["club"] == m.mi_club():
			puesto = i + 1
			break
	## Salvarse es no acabar en los dos últimos, que son los dos que descienden.
	var salvado := puesto > 0 and puesto <= t.size() - 2
	interino["cumplido"] = true
	interino["salvado"] = salvado
	if salvado:
		sumar_prestigio(14)
		trofeos.append({"anio": m.anio, "titulo": "Permanencia (interinato)"})
		if m.directiva != null:
			m.directiva.mover_confianza(92 - m.directiva.confianza, "salvaste al club")
		aviso.emit("Misión cumplida",
			"Salvaste al club del descenso en cinco fechas. La hinchada te saca en andas y el teléfono no para de sonar: tu prestigio se dispara y varios clubes te quieren para un proyecto de verdad.")
	else:
		sumar_prestigio(-4)
		if m.directiva != null:
			m.directiva.mover_confianza(30 - m.directiva.confianza, "el club descendió")
		aviso.emit("No alcanzó",
			"El club se fue a Ascenso. Nadie te culpa del todo —llegaste con el incendio declarado— pero el descenso queda en tu ficha.")
	## Se acabó el contrato de bombero: el objetivo vuelve a ser el del club. El
	## puesto que exige la directiva se queda como está a propósito —salvarse es
	## lo que se le pide a un club que venía de zona de descenso— y lo recoloca
	## el cierre de temporada, que es de quien es esa cuenta.
	_restaurar_objetivo()
	interinato_resuelto.emit(salvado)

# ---------------------------------------------------------------------------
# CANTERA: subir chicos al primer equipo
# ---------------------------------------------------------------------------

## Sube un juvenil al primer equipo. Devuelve "" si se pudo, o el motivo.
##
## Subirlo antes de tiempo tiene precio: le queda grande y se le nota. Es lo que
## convierte la decisión en una decisión — si subir siempre fuera gratis, el modo
## sería pulsar un botón cuatro veces cada temporada.
func subir_al_primer_equipo(j: Jugador) -> String:
	var m := _mundo()
	if m == null or not es_cantera():
		return "no eres director de cantera"
	if j == null or j.club_id != m.mi_club_id:
		return "ese chico no es del club"
	if j.edad > 21:
		return "ya no cuenta como canterano"
	var subidos: Array = cantera.get("subidos", [])
	if subidos.has(j.id):
		return "ya lo promoviste"
	subidos.append(j.id)
	cantera["subidos"] = subidos
	cantera["total"] = int(cantera.get("total", 0)) + 1
	var listo := j.ovr >= m.mi_club().rep - 14
	if listo:
		j.moral = 99
		sumar_prestigio(2)
		aviso.emit("Debuta un canterano: %s" % j.nombre,
			"%s (%d años, %s, media %d con proyección %d) sube al primer equipo. Es el %dº debutante de tu gestión. La grada canta su nombre antes de que toque la pelota." % [
				j.nombre, j.edad, j.pos_e, j.ovr, j.pot, subidos.size()])
	else:
		## El HTML le disparaba la ansiedad, que es un sistema que aquí no está
		## portado. La moral es lo más parecido que existe hoy: un chico quemado
		## rinde por debajo de su media, que es justo el castigo que tocaba.
		j.moral = clampi(j.moral - Azar.ent(14, 26), 10, 99)
		aviso.emit("Debut prematuro: %s" % j.nombre,
			"Lo subiste antes de tiempo. Le queda grande y se le nota. A veces un año más abajo vale oro.")
	return ""

func _chequeo_cantera() -> void:
	var m := _mundo()
	var subidos: Array = cantera.get("subidos", [])
	var meta := int(cantera.get("meta", 4))
	if subidos.size() >= meta:
		sumar_prestigio(8)
		if m != null and m.directiva != null:
			m.directiva.mover_confianza(18, "objetivo de cantera cumplido")
		aviso.emit("Objetivo de cantera cumplido",
			"Subiste %d juveniles al primer equipo (pedían %d). El club renueva tu proyecto formativo." % [subidos.size(), meta])
	else:
		if m != null and m.directiva != null:
			m.directiva.mover_confianza(-14, "objetivo de cantera incumplido")
		aviso.emit("Objetivo de cantera incumplido",
			"Solo %d debutantes de los %d comprometidos. El directorio pregunta para qué paga la academia." % [subidos.size(), meta])
	var nueva := Azar.ent(3, 5)
	cantera["meta"] = nueva
	cantera["subidos"] = []
	_fijar_objetivo("CANTERA: subir %d juveniles al primer equipo esta temporada" % nueva)

# ---------------------------------------------------------------------------
# ASCENSO DE ROL: del banquillo al despacho, del despacho a la propiedad
# ---------------------------------------------------------------------------

## El rol al que puedes subir ahora mismo, o "". El dueño no asciende: por encima
## de ser dueño del club no hay nada.
func puede_ascender() -> String:
	if not ASCENSOS.has(rol):
		return ""
	if es_ayudante() or en_interinato():
		return ""   ## esos dos tienen su propia salida, no esta escalera
	var puerta: Dictionary = ASCENSOS[rol]
	if trofeos.size() >= int(puerta["trofeos"]) and prestigio >= int(puerta["prestigio"]):
		return String(puerta["a"])
	return ""

## Sube de rol. Devuelve "" si se hizo, o el motivo por el que no.
func ascender() -> String:
	var nuevo := puede_ascender()
	if nuevo == "":
		return "todavía no tienes el prestigio para dar ese salto"
	var antes := rol
	rol = nuevo
	if dt_empleado.is_empty():
		_contratar_dt_empleado()
	rol_cambiado.emit(antes, rol)
	ascenso.emit(rol)
	if nuevo == DIR:
		aviso.emit("Asciendes a Director Deportivo",
			"El directorio te sube al despacho: dejas el banquillo a %s y pasas a mandar en mercado, cuerpo técnico y finanzas." % dt_nombre())
	else:
		aviso.emit("Asciendes a Dueño del club",
			"Compras el paquete de control. Ya nadie te puede echar: el club es tuyo, con todo lo que eso implica.")
	return ""

## Lo que te falta para el siguiente escalón, en una frase. La escalera solo
## motiva si se ve el peldaño.
func siguiente_escalon() -> String:
	if not ASCENSOS.has(rol):
		return ""
	var puerta: Dictionary = ASCENSOS[rol]
	var faltan_t: int = maxi(0, int(puerta["trofeos"]) - trofeos.size())
	var faltan_p: int = maxi(0, int(puerta["prestigio"]) - prestigio)
	if faltan_t == 0 and faltan_p == 0:
		return "Puedes dar el salto a %s" % PERMISOS[puerta["a"]]["cargo"]
	return "Para llegar a %s: %d trofeo(s) y %d punto(s) de prestigio" % [
		PERMISOS[puerta["a"]]["cargo"], faltan_t, faltan_p]

# ---------------------------------------------------------------------------
# LA ESCUELA TÁCTICA, EL HOMENAJE Y LA RETIRADA: `vLegado()` del HTML
# ---------------------------------------------------------------------------

## `chequeoFilosofia()`: se llama UNA VEZ POR SEMANA con la táctica que sacaste.
## No hay nada que pulsar; la escuela nace sola si eres fiel a un modelo. Por
## eso cuenta semanas y no partidos: cambiar de dibujo para un rival puntual
## también rompe la racha, que es exactamente lo que se quiere premiar.
func chequeo_filosofia(t: Tactica) -> void:
	if t == null or not filosofia.is_empty():
		return
	var clave := "%s|%d" % [t.formacion, t.mentalidad]
	_estilos_contados[clave] = int(_estilos_contados.get(clave, 0)) + 1
	if int(_estilos_contados[clave]) < SEMANAS_PARA_ESCUELA:
		return
	## El apellido del entrenador con el sufijo que le pega a su mentalidad. Un
	## "Durantismo" ofensivo y una "Durantística" de equilibrio no suenan igual,
	## y esa es la gracia: el nombre delata cómo juegas.
	var partes := nombre.strip_edges().split(" ", false)
	var apellido := partes[partes.size() - 1] if partes.size() > 0 else "DT"
	var sufijo := "ística"
	if t.mentalidad == Tactica.Mentalidad.OFENSIVA:
		sufijo = "ismo"
	elif t.mentalidad == Tactica.Mentalidad.DEFENSIVA:
		sufijo = "anismo"
	filosofia = {"nombre": "El %s%s" % [apellido, sufijo], "formacion": t.formacion, "mentalidad": t.mentalidad}
	prestigio = clampi(prestigio + 6, PRESTIGIO_MIN, PRESTIGIO_MAX)
	escuela_nacida.emit(String(filosofia["nombre"]), t.formacion)
	aviso.emit("Nace una escuela: %s" % String(filosofia["nombre"]),
		"Llevas casi dos temporadas fiel a un mismo modelo (%s). La prensa bautizó tu estilo como «%s». Los entrenadores de tu cantera ya lo replican y otros clubes buscan fichar a tus ayudantes." % [t.formacion, String(filosofia["nombre"])])

## Lo que cuesta un homenaje. Se escala al tamaño del club como cualquier gasto,
## así que en un club chico es una decisión y no un capricho.
const COSTE_HOMENAJE := 45000.0

## `homenajear()`: placa, camiseta enmarcada y vuelta al campo. Devuelve "" si
## se hizo, o el motivo por el que no.
func homenajear(nombre_leyenda: String) -> String:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return "no hay club"
	var c := m.mi_club()
	var coste := Eco.escalar(COSTE_HOMENAJE, c.rep)
	if c.saldo < coste:
		return "el club no tiene los %s que cuesta" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	if m.prensa != null:
		m.prensa.animo = clampi(m.prensa.animo + Azar.ent(5, 11), 0, 100)
	c.socios += Azar.ent(150, 600)
	for j in c.plantel():
		j.moral = clampi(j.moral + 3, 10, 99)
	homenaje_hecho.emit(nombre_leyenda)
	aviso.emit("Homenaje a %s" % nombre_leyenda,
		"Placa en el acceso principal, camiseta enmarcada y vuelta al campo antes del partido. La grada cantó su nombre durante diez minutos. El club recuerda de dónde viene.")
	return ""

## `retirarse()`: el punto final voluntario. No se puede deshacer -por eso la
## pantalla pide confirmar dos veces-, pero tampoco borra la partida: deja el
## balance a la vista y el juego sigue si quieres mirarlo.
func retirarse() -> String:
	if not retirado.is_empty():
		return "ya anunciaste tu retirada"
	var m := _mundo()
	if m == null:
		return "no hay partida"
	var p: Dictionary = m.puntaje_carrera()
	retirado = {"anio": m.anio, "puntaje": int(p["total"])}
	carrera_cerrada.emit(m.anio, int(p["total"]))
	aviso.emit("Se acaba una carrera",
		"Anuncias tu retirada tras %d temporadas, con %d título(s) y %d puntos de carrera." % [
			m.anio - 2026 + 1, trofeos.size(), int(p["total"])])
	return ""

## El veredicto de `epilogoHTML()`: la frase con la que el juego te resume. Va
## aparte de la pantalla porque el banco tiene que poder comprobar que un
## historial de quince títulos no devuelve la frase del que no ganó nada.
func veredicto_carrera() -> Dictionary:
	var t := trofeos.size()
	if t >= 15:
		return {"texto": "Uno de los grandes nombres que ha dado este fútbol. Tu nombre ya está en la puerta del estadio.", "tono": "oro"}
	if t >= 6:
		return {"texto": "Una carrera sólida y con vitrina. Cuando te retires, la hinchada va a recordar estos años.", "tono": "verde"}
	if t >= 1:
		return {"texto": "Un camino con altibajos y alguna alegría grande. Todavía tienes tiempo de escribir el capítulo bueno.", "tono": "ambar"}
	return {"texto": "Todavía sin títulos. Hay entrenadores que tardaron quince años en levantar el primero.", "tono": "suave"}

## El palmarés agrupado por competición: "Liga ×3, Copa ×1". El año se le quita
## al título porque si no cada temporada es una fila distinta y no se ve nada.
func palmares_por_tipo() -> Array[Dictionary]:
	var cuenta := {}
	for t: Dictionary in trofeos:
		var k := String(t.get("titulo", "")).strip_edges()
		if k == "":
			continue
		cuenta[k] = int(cuenta.get(k, 0)) + 1
	var salida: Array[Dictionary] = []
	for k2: String in cuenta:
		salida.append({"titulo": k2, "veces": int(cuenta[k2])})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["veces"]) > int(b["veces"]))
	return salida

# ---------------------------------------------------------------------------
# EL DUEÑO: capital propio y la puerta de salida
# ---------------------------------------------------------------------------

## Aporte de capital del dueño. Dos por temporada como mucho: sin tope, el modo
## dueño convierte la economía del juego en un adorno.
const INYECCIONES_POR_TEMPORADA := 2
const INYECCION := 1000000.0
var _inyecciones: int = 0
## Las inyecciones de TODA la carrera, no las de la temporada. `_inyecciones` se
## reinicia cada año -es el cupo-, así que sin este contador el logro oculto
## "El mecenas" (diez aportes) solo podría caer si se hicieran diez el mismo
## año, y el cupo anual son dos: era imposible por construcción.
var inyecciones_totales: int = 0
var _anio_inyecciones: int = 0

## Cuántos aportes de capital te quedan esta temporada -para que el botón se
## pueda apagar antes de intentarlo, en vez de fallar y explicarse-.
func inyecciones_restantes() -> int:
	var m := _mundo()
	if m != null and _anio_inyecciones != m.anio:
		return INYECCIONES_POR_TEMPORADA
	return maxi(0, INYECCIONES_POR_TEMPORADA - _inyecciones)

func inyectar_capital() -> String:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return "no hay club"
	if not puede_inyectar_capital():
		return "solo el dueño mete dinero de su bolsillo"
	if _anio_inyecciones != m.anio:
		_anio_inyecciones = m.anio
		_inyecciones = 0
	if _inyecciones >= INYECCIONES_POR_TEMPORADA:
		return "máximo dos aportes de capital por temporada"
	_inyecciones += 1
	inyecciones_totales += 1
	var monto := Eco.escalar(INYECCION, float(m.mi_club().rep))
	m.mi_club().mover_saldo(monto)
	aviso.emit("El dueño mete la mano al bolsillo",
		"Inyección desde tu patrimonio personal (%d/%d esta temporada). Los acreedores respiran." % [
			_inyecciones, INYECCIONES_POR_TEMPORADA])
	return ""

## Vender el club es el final de una carrera, no una operación más: te vas por la
## puerta ancha y vuelves al mercado como entrenador libre.
func vender_club() -> String:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return "no hay club"
	if not puede_vender_club():
		return "no se vende lo que no es tuyo"
	var c := m.mi_club()
	var precio := int(round(Eco.ref_caja(float(c.rep)) * 5.5 + float(c.saldo) * 0.5))
	historial.append({"club": "%s (vendido)" % c.nombre, "hasta": m.anio})
	sumar_prestigio(6)
	var antes := rol
	rol = DT
	sin_club = true
	rol_cambiado.emit(antes, rol)
	aviso.emit("Operación histórica",
		"Vendiste %s por %d. Te vas por la puerta ancha, con la vitrina llena y el bolsillo también. Tu prestigio te abre todas las puertas del continente." % [c.nombre, precio])
	sin_banco.emit(c.nombre)
	return ""

# ---------------------------------------------------------------------------
# SIN CLUB: las ofertas y el club nuevo
# ---------------------------------------------------------------------------

## Te quedas sin banco. Lo llama quien atienda `Directiva.despedido`, DESPUÉS de
## comprobar `le_pueden_echar()`.
func quedar_sin_banco() -> void:
	var m := _mundo()
	var c := m.mi_club() if m != null else null
	if c != null:
		historial.append({"club": c.nombre, "hasta": m.anio})
	sin_club = true
	sin_banco.emit(c.nombre if c != null else "")

## Los clubes que te quieren. Tres como mucho, y siempre al menos uno.
##
## Nunca puedes quedarte sin nada: si tu prestigio se hundió, siempre habrá algún
## club modesto dispuesto a darte una última oportunidad. Sin esa red, una racha
## mala terminaba la partida sin que el juego lo dijera en ninguna parte.
func ofertas_trabajo() -> Array[Club]:
	var salida: Array[Club] = []
	var m := _mundo()
	if m == null:
		return salida
	var todos: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.division > 0 and c.id != m.mi_club_id:
			todos.append(c)
	if todos.is_empty():
		return salida
	var alcanzables: Array[Club] = []
	for c in todos:
		if c.rep <= prestigio + 18:
			alcanzables.append(c)
	Azar.barajar(alcanzables)
	for c in alcanzables:
		if salida.size() >= 3:
			break
		salida.append(c)
	if salida.size() < 2:
		var humildes := todos.duplicate()
		humildes.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
		var seis: Array[Club] = []
		for c: Club in humildes:
			if seis.size() >= 6:
				break
			seis.append(c)
		Azar.barajar(seis)
		for c in seis:
			if salida.size() >= 3:
				break
			if not salida.has(c):
				salida.append(c)
	return salida

## Firmas por un club nuevo. Devuelve "" si se hizo, o el motivo.
##
## Guarda de la casa: si llega un id que no existe, en el HTML la línea siguiente
## dejaba el club apuntando a la nada y la partida quedaba irrecuperable —sin
## club, sin tabla y sin plantel—. Mejor no hacer nada que romper el guardado.
##
## Y OJO CON EL ORDEN: el cuerpo técnico y las obras se renuevan ANTES de tomar
## el mando. Lo que construiste en el club anterior se queda allí (es suyo, no
## tuyo), y `Mundo.tomar_el_mando()` crea el parte médico atado al `Staff` que
## encuentre: si se reemplazara después, el médico seguiría leyendo el cuerpo
## técnico del club que acabas de dejar.
func aceptar_trabajo(club_id: String) -> String:
	var m := _mundo()
	if m == null:
		return "no hay partida"
	if club_id.is_empty() or not m.clubes.has(club_id):
		return "ese club ya no está disponible"
	var anterior := m.mi_club()
	if anterior != null and anterior.id != club_id:
		historial.append({"club": anterior.nombre, "hasta": m.anio})
	m.staff = Staff.new()
	m.obras = Instalaciones.new()
	m.tomar_el_mando(club_id)
	sin_club = false
	## Ni el interinato ni el ayudantazgo se heredan: son contratos del club que
	## dejaste. Al nuevo llegas de entrenador, que es lo que firmaste.
	interino = {}
	ayudante = {}
	emergencia = {}
	## La directiva es OTRA y ya trae su propio objetivo: conservar el del club
	## anterior aquí lo resucitaría el día que termine un modo especial.
	_objetivo_club = ""
	if rol != DT and dt_empleado.is_empty():
		_contratar_dt_empleado()
	var c := m.mi_club()
	aviso.emit("Nuevo desafío",
		"Asumes en %s. Objetivo: %s." % [c.nombre, m.directiva.objetivo if m.directiva != null else "el que te pongan"])
	return ""

# ---------------------------------------------------------------------------

## Pisa el objetivo que la directiva acaba de fijar por reputación, guardando el
## que había.
##
## Guardarlo importa: cuando el modo especial termina —el ayudante hereda el
## banco, el interino cumple sus cinco fechas— hay que devolver el objetivo del
## club. Sin esto, un entrenador principal con quince años de carrera seguía
## teniendo escrito en pantalla "AYUDANTE: ganarte el banco", que ya se ganó.
func _fijar_objetivo(texto: String) -> void:
	var m := _mundo()
	if m == null or m.directiva == null or texto.is_empty():
		return
	if _objetivo_club.is_empty():
		_objetivo_club = m.directiva.objetivo
	m.directiva.objetivo = texto

func _restaurar_objetivo() -> void:
	var m := _mundo()
	if m == null or m.directiva == null or _objetivo_club.is_empty():
		return
	m.directiva.objetivo = _objetivo_club
	_objetivo_club = ""

## Todo lo que una pantalla necesita saber del rol, de una vez. Evita que la
## interfaz llame a doce métodos y se olvide del decimotercero.
func resumen() -> Dictionary:
	return {
		"rol": rol, "cargo": nombre_del_cargo(), "manda": manda(),
		"prestigio": prestigio, "trofeos": trofeos.size(), "temporadas": temporadas,
		"sin_club": sin_club,
		"mercado_bloqueado": mercado_bloqueado(),
		"puede_fichar": puede_fichar(), "puede_alinear": puede_alinear(),
		"puede_contratar_staff": puede_contratar_staff(), "puede_construir": puede_construir(),
		"le_pueden_echar": le_pueden_echar(),
		"dt_empleado": dt_nombre() if not dt_empleado.is_empty() else "",
		"jefe_confianza": jefe_confianza() if es_ayudante() else -1,
		"interinato": fechas_interinato_restantes(),
		"siguiente": siguiente_escalon(),
	}

# ---------------------------------------------------------------------------
# GUARDADO
# ---------------------------------------------------------------------------

func a_dic() -> Dictionary:
	return {
		"rol": rol, "nombre": nombre, "prestigio": prestigio,
		"trofeos": trofeos.duplicate(true),
		"historial": historial.duplicate(true),
		"temporadas": temporadas, "sin_club": sin_club, "sandbox": sandbox,
		"dt_empleado": dt_empleado.duplicate(),
		"directrices": directrices.duplicate(),
		"ayudante": ayudante.duplicate(),
		"interino": interino.duplicate(),
		"cantera": cantera.duplicate(true),
		"emergencia": emergencia.duplicate(),
		"inyecciones": _inyecciones, "anio_inyecciones": _anio_inyecciones,
		"inyecciones_totales": inyecciones_totales,
		"patrimonio": patrimonio, "licencia": licencia,
		"bienes": bienes.duplicate(), "sem_trabajadas": semanas_trabajadas,
		"filosofia": filosofia.duplicate(),
		"estilos": _estilos_contados.duplicate(),
		"retirado": retirado.duplicate(),
		"rival_dt": rival_dt.duplicate(),
		"leyenda_viva": leyenda_viva.duplicate(),
		"filiales": filiales.duplicate(),
		"sucesor": sucesor.duplicate(),
		"desgaste": desgaste, "curriculum": curriculum.duplicate(true),
		"oferta_club": oferta_de_club.duplicate(), "ult_oferta": _ultima_oferta,
		"look": look.duplicate(),
	}

func desde_dic(d: Dictionary) -> void:
	rol = String(d.get("rol", DT))
	if not PERMISOS.has(rol):
		rol = DT   ## un guardado viejo con un rol que ya no existe no rompe nada
	nombre = String(d.get("nombre", "Míster"))
	look = (d.get("look", {}) as Dictionary).duplicate()
	var dg: Dictionary = d.get("directrices", {})
	for k in directrices:
		if dg.has(k):
			directrices[k] = dg[k]
	prestigio = clampi(int(d.get("prestigio", PRESTIGIO_INICIAL)), PRESTIGIO_MIN, PRESTIGIO_MAX)
	trofeos.clear()
	for t: Dictionary in d.get("trofeos", []):
		trofeos.append(t)
	historial.clear()
	for h: Dictionary in d.get("historial", []):
		historial.append(h)
	temporadas = int(d.get("temporadas", 0))
	sin_club = bool(d.get("sin_club", false))
	sandbox = bool(d.get("sandbox", false))
	dt_empleado = (d.get("dt_empleado", {}) as Dictionary).duplicate()
	ayudante = (d.get("ayudante", {}) as Dictionary).duplicate()
	interino = (d.get("interino", {}) as Dictionary).duplicate()
	cantera = (d.get("cantera", {}) as Dictionary).duplicate(true)
	emergencia = (d.get("emergencia", {}) as Dictionary).duplicate()
	_inyecciones = int(d.get("inyecciones", 0))
	_anio_inyecciones = int(d.get("anio_inyecciones", 0))
	inyecciones_totales = int(d.get("inyecciones_totales", 0))
	patrimonio = int(d.get("patrimonio", 0))
	licencia = int(d.get("licencia", 0))
	bienes = (d.get("bienes", {}) as Dictionary).duplicate()
	semanas_trabajadas = int(d.get("sem_trabajadas", 0))
	filosofia = (d.get("filosofia", {}) as Dictionary).duplicate()
	_estilos_contados = (d.get("estilos", {}) as Dictionary).duplicate()
	retirado = (d.get("retirado", {}) as Dictionary).duplicate()
	rival_dt = (d.get("rival_dt", {}) as Dictionary).duplicate()
	leyenda_viva = (d.get("leyenda_viva", {}) as Dictionary).duplicate()
	filiales = (d.get("filiales", []) as Array).duplicate()
	sucesor = (d.get("sucesor", {}) as Dictionary).duplicate()
	desgaste = int(d.get("desgaste", 0))
	curriculum = (d.get("curriculum", []) as Array).duplicate(true)
	oferta_de_club = (d.get("oferta_club", {}) as Dictionary).duplicate()
	_ultima_oferta = int(d.get("ult_oferta", 0))

# ---------------------------------------------------------------------------
#  EL PATRIMONIO DEL ENTRENADOR (`vCarrera()`)
# ---------------------------------------------------------------------------
#
# Hasta ahora el entrenador no cobraba: el club pagaba sueldos y él no tenía
# bolsillo. Y sin bolsillo no hay carrera personal, solo gestión de un club.
#
# El sueldo es TUYO y va aparte de la caja del club: son dos dineros distintos y
# esa separación es el punto. Lo que se compra con él no mejora al equipo,
# mejora al ENTRENADOR —licencias, un agente, un analista— y eso te sigue
# cuando cambias de banquillo.

## Lo que se puede comprar. clave, nombre, coste, qué da.
const COMPRAS_DT := [
	["licB", "Licencia B de entrenador", 30000,
		"Primer escalón oficial. Un punto de habilidad y un 5% más de sueldo."],
	["licA", "Licencia A de entrenador", 90000,
		"Requiere la B. Un punto de habilidad y otro 5% de sueldo."],
	["licPro", "Licencia PRO", 250000,
		"Requiere la A. Dos puntos de habilidad y otro 5% de sueldo."],
	["agente", "Contratar tu propio agente", 120000,
		"Te consigue mejores ofertas de trabajo y mejor indemnización."],
	["analista", "Analista de datos personal", 100000,
		"Un punto de habilidad y ves los puntos débiles del rival."],
	["curso", "Curso de oratoria y medios", 60000,
		"Un punto de habilidad; las ruedas de prensa te salen mejor."],
]

var patrimonio: int = 0
var licencia: int = 0            ## 0 ninguna, 1 B, 2 A, 3 PRO
var bienes: Dictionary = {}      ## clave -> true, para lo que no es licencia
var semanas_trabajadas: int = 0

## Lo que cobras a la semana. Sale de la reputación del club y del prestigio que
## tengas, más un 5% por cada licencia: la formación se paga sola.
func sueldo_semanal() -> int:
	var m := _mundo()
	var c := m.mi_club() if m != null else null
	if c == null:
		return 0
	## `sueldoDT()` DEL HTML, TAL CUAL (corregido el 10-9-2026). La versión
	## anterior era otra fórmula -multiplicativa, con el exponente 0,62 de
	## `Eco.escalar()`- que nadie había declarado rediseño y que daba unas TRES
	## VECES más: 9.900 por semana contra 3.509 con club y DT en el promedio.
	## No era un detalle: el sueldo del DT es lo que llena su patrimonio, y con
	## él se compran las licencias -la B cuesta 30.000-. Con la fórmula vieja
	## se pagaba en 3 semanas; en el HTML, en casi 9. Todo el ritmo de la
	## carrera del entrenador iba al triple sin que ninguna prueba lo notara.
	##
	## La del HTML es ADITIVA: una parte crece con el tamaño del club
	## (`ref_caja`, sin exponente) y otra con el prestigio del propio DT.
	var base := int(round(Eco.ref_caja(float(c.rep)) * 0.0022 + float(prestigio) * 40.0))
	## EL CARISMA DEL ARBOL SE COBRA AQUI. `Entrenamiento.factor_sueldo_dt()`
	## estaba escrita desde el porte y no la llamaba nadie: se podia gastar un
	## punto en «Carisma» y el sueldo no se movia un peso. Mismo orden de
	## redondeos que el HTML: primero el carisma, después la licencia.
	var fama := m.entrenamiento.factor_sueldo_dt() if m != null and m.entrenamiento != null else 1.0
	base = int(round(float(base) * fama))
	return int(round(float(base) * (1.0 + 0.05 * float(licencia))))

## `bonusReputacion()` DEL HTML, LAS DOS PARTES QUE FALTABAN (10-9-2026).
## La de cantera ya estaba portada (`Cantera.multiplicador_de_reputacion()`,
## `1+(rep-50)*0.005`); estas dos no existían en ningún sitio, así que el
## prestigio del entrenador no ayudaba a fichar ni a vender la camiseta, que
## es justo lo que la card "⭐ BONUS POR REPUTACIÓN" del HTML promete.
## La cuarta parte del HTML (`.sueldo`) no se porta: allí es código muerto,
## se calcula y se muestra pero nada la usa.

## Lo que el prestigio suma a las ganas de venir de un jugador: `fichajes-1`
## del HTML, que `deseoDeVenir()` SUMA a la probabilidad. A prestigio 99 son
## +0,29; a prestigio 20, -0,18.
func bono_reputacion_fichajes() -> float:
	return float(prestigio - 50) * 0.006

## Lo que el prestigio multiplica en las ofertas de marcas y de zonas
## publicitarias -`generarSponsorOfertas()` y `generarOfertasZona()` del
## HTML-. NO toca el patrocinio semanal genérico de `Finanzas`: en el HTML
## tampoco lo toca.
func multiplicador_sponsor() -> float:
	return 1.0 + float(prestigio - 50) * 0.004

func tiene(clave: String) -> bool:
	if clave == "licB":
		return licencia >= 1
	if clave == "licA":
		return licencia >= 2
	if clave == "licPro":
		return licencia >= 3
	return bienes.has(clave)

## Compra algo para ti. Devuelve "" si se hizo, o el motivo por el que no.
func comprar_dt(clave: String) -> String:
	var it: Array = []
	for f: Array in COMPRAS_DT:
		if String(f[0]) == clave:
			it = f
	if it.is_empty():
		return "eso no existe"
	if tiene(clave):
		return "ya lo tienes"
	## Las licencias van en orden: no hay atajo a la PRO.
	if clave == "licA" and licencia < 1:
		return "primero necesitas la licencia B"
	if clave == "licPro" and licencia < 2:
		return "primero necesitas la licencia A"
	var coste := int(it[2])
	if patrimonio < coste:
		return "tu patrimonio no alcanza: cuesta %s" % Cesiones.dinero(coste)
	patrimonio -= coste
	var m := _mundo()
	match clave:
		"licB": licencia = 1
		"licA": licencia = 2
		"licPro": licencia = 3
		_: bienes[clave] = true
	## Los puntos del árbol: es lo que convierte invertir en ti en algo que se
	## nota en el campo la semana siguiente.
	var puntos := 2 if clave == "licPro" else 1
	if m != null and m.entrenamiento != null:
		m.entrenamiento.dt_sumar_puntos(puntos)
	aviso.emit("Inversión en tu carrera", "%s. %s" % [String(it[1]), String(it[3])])
	return ""

## El pulso semanal del bolsillo: cobras, y cada diez semanas de trabajo ganas un
## punto de habilidad. Lo llama `Mundo`.
func semana_patrimonio() -> void:
	patrimonio += sueldo_semanal()
	semanas_trabajadas += 1
	if semanas_trabajadas % 10 == 0:
		var m := _mundo()
		if m != null and m.entrenamiento != null:
			m.entrenamiento.dt_sumar_puntos(1)

# ===========================================================================
#  LA CARRERA POR DENTRO (`vCarrera()`): RIVAL, LEYENDA, FILIALES Y SUCESIÓN
# ===========================================================================
#
# Cuatro cosas que no cambian una alineación y que son toda la diferencia entre
# llevar un club y tener una carrera: alguien con quien picarte, alguien que se
# queda para siempre, algo que es tuyo de verdad y alguien a quien dejárselo.

signal noticia_carrera(titulo: String, cuerpo: String)

# ---------------------------------------------------------------------------
#  EL RIVAL PERSONAL
# ---------------------------------------------------------------------------
#
# No se elige: nace del club con el que más te has picado. A partir de ahí, cada
# cruce se cuenta aparte y la tensión sube; pasada de noventa, la cosa se sale de
# la cancha y tu prestigio se mueve con el resultado.

## Con cuánto calor de rivalidad aparece. Por debajo de 55 no hay historia que
## contar: es un rival más del calendario.
const CALOR_PARA_RIVAL := 55
const TENSION_QUE_ESTALLA := 90

var rival_dt: Dictionary = {}   ## {club_id, nombre, estilo, pj, g, e, p, tension, desde}

## Busca rival si todavía no hay. Lo llama el pulso semanal: la rivalidad la
## calienta `Logros`, aquí solo se le pone cara y nombre al de enfrente.
func buscar_rival_dt() -> void:
	if not rival_dt.is_empty():
		return
	var m := _mundo()
	if m == null or m.logros == null or m.mi_club() == null:
		return
	var mejor_id := ""
	var mejor_calor := 0
	for f: Dictionary in m.logros.rivalidades():
		var c: Club = f.get("club")
		if c == null or c == m.mi_club():
			continue
		if int(f.get("valor", 0)) > mejor_calor:
			mejor_calor = int(f.get("valor", 0))
			mejor_id = c.id
	if mejor_id == "" or mejor_calor < CALOR_PARA_RIVAL:
		return
	var c2: Club = m.clubes.get(mejor_id)
	if c2 == null:
		return
	var d := Previa.dt_de(c2)
	rival_dt = {
		"club_id": c2.id, "nombre": String(d.get("nombre", "")),
		"estilo": String(d.get("descripcion", "")),
		"pj": 0, "g": 0, "e": 0, "p": 0, "tension": 50, "desde": m.anio,
	}
	noticia_carrera.emit("Tienes un rival personal",
		"La prensa ya lo llama duelo: %s contra %s. Cada vez que se crucen, se hablará más de ustedes dos que del partido." % [
			nombre, String(rival_dt["nombre"])])

## Un cruce contra él. Devuelve true si el duelo se salió de la cancha.
func registrar_duelo(rival_id: String, gane: bool, empate: bool) -> bool:
	if rival_dt.is_empty() or String(rival_dt["club_id"]) != rival_id:
		return false
	rival_dt["pj"] = int(rival_dt["pj"]) + 1
	if gane:
		rival_dt["g"] = int(rival_dt["g"]) + 1
		rival_dt["tension"] = clampi(int(rival_dt["tension"]) + 8, 0, 100)
	elif empate:
		rival_dt["e"] = int(rival_dt["e"]) + 1
		rival_dt["tension"] = clampi(int(rival_dt["tension"]) + 3, 0, 100)
	else:
		rival_dt["p"] = int(rival_dt["p"]) + 1
		rival_dt["tension"] = clampi(int(rival_dt["tension"]) + 10, 0, 100)
	if int(rival_dt["tension"]) < TENSION_QUE_ESTALLA or not Azar.suerte(0.4):
		return false
	## Y cuando estalla, se paga en prestigio: ganar el duelo caliente vale el
	## triple que ganar un partido, y perderlo también se nota.
	prestigio = clampi(prestigio + (3 if gane else -1), 0, 100)
	rival_dt["tension"] = 60
	noticia_carrera.emit("El duelo se sale de la cancha",
		"Tú y %s os cruzasteis en el túnel. Los micrófonos lo cogieron todo y mañana no se hablará de otra cosa." % String(rival_dt["nombre"]))
	return true

# ---------------------------------------------------------------------------
#  LA LEYENDA VIVA
# ---------------------------------------------------------------------------
#
# Un ex jugador que se queda ligado al club de por vida. No entrena, no fila y no
# aparece en ninguna estadística: viene, habla con los chicos y está. Cada seis
# semanas se sienta con un juvenil, le sube la moral y a veces le sube la media.

var leyenda_viva: Dictionary = {}   ## {nombre, pos, desde, visitas}

func nombrar_leyenda_viva(j: Jugador) -> String:
	if not leyenda_viva.is_empty():
		return "%s ya es la leyenda viva del club" % String(leyenda_viva["nombre"])
	if j == null:
		return "no hay a quién nombrar"
	var m := _mundo()
	leyenda_viva = {
		"nombre": Nombres.visible(j.nombre), "pos": j.pos_e,
		"desde": m.anio if m != null else 0, "visitas": 0,
	}
	if m != null and m.prensa != null:
		m.prensa.mover_animo(8)
	noticia_carrera.emit("Leyenda viva del club",
		"%s queda ligado al club de por vida. Vendrá a los entrenamientos, hablará con los chicos y estará en cada acto. La gente lo va a agradecer." % String(leyenda_viva["nombre"]))
	return ""

## Cada seis semanas se sienta con un chico. Es de los pocos sistemas del juego
## cuyo efecto es tan pequeño que casi no se ve en la ficha, y esa es la idea:
## "estas cosas no salen en ninguna estadística".
func semana_leyenda_viva() -> void:
	if leyenda_viva.is_empty():
		return
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return
	leyenda_viva["visitas"] = int(leyenda_viva["visitas"]) + 1
	if int(leyenda_viva["visitas"]) % 6 != 0:
		return
	var jovenes: Array[Jugador] = []
	for j: Jugador in m.mi_club().plantilla:
		if j.edad <= 21:
			jovenes.append(j)
	if not jovenes.is_empty():
		var chico: Jugador = jovenes[Azar.ent(0, jovenes.size() - 1)]
		chico.moral = clampi(chico.moral + Azar.ent(4, 9), 10, 99)
		if Azar.suerte(0.25) and chico.ovr < chico.pot:
			chico.ajustar_media(1)
		if Azar.suerte(0.3):
			noticia_carrera.emit("Charla de la leyenda",
				"%s se quedó una hora hablando con %s después del entrenamiento. Estas cosas no salen en ninguna estadística." % [
					String(leyenda_viva["nombre"]), chico.nombre])
	if m.prensa != null:
		m.prensa.mover_animo(1)

# ---------------------------------------------------------------------------
#  LOS CLUBES FILIALES (habilidad «Magnate»)
# ---------------------------------------------------------------------------
#
# Comprar un club con TU dinero, no con el del club que diriges. `Entrenamiento`
# tenía escrita `puede_comprar_filiales()` desde el porte y no la llamaba nadie:
# la habilidad se podía comprar en el árbol y no servía para nada.
#
# Cuesta tres veces la caja de referencia del club, y devuelve dividendos cada
# tres meses. Es la única forma de que el dinero personal haga algo más que
# comprar coches.

const PRECIO_FILIAL := 3.0
const SEMANAS_DIVIDENDO := 12

var filiales: Array = []   ## ids de club

func precio_filial(c: Club) -> int:
	return int(round(Eco.ref_caja(float(c.rep)) * PRECIO_FILIAL))

func comprar_filial(c: Club) -> String:
	var m := _mundo()
	if m == null or m.entrenamiento == null or not m.entrenamiento.puede_comprar_filiales():
		return "hace falta la habilidad «Magnate» del árbol de entrenador"
	if c == null:
		return "ese club no existe"
	if c.id == mi_club_id_actual():
		return "no puedes comprar el club que diriges"
	if filiales.has(c.id):
		return "ya es tuyo"
	var precio := precio_filial(c)
	if patrimonio < precio:
		return "te faltan %s de patrimonio personal" % Cesiones.dinero(precio - patrimonio)
	patrimonio -= precio
	filiales.append(c.id)
	noticia_carrera.emit("Compraste un club",
		"Adquiriste el control de %s por %s. Ahora es tu club filial: recibes dividendos cada tres meses." % [
			c.nombre, Cesiones.dinero(precio)])
	return ""

func mi_club_id_actual() -> String:
	var m := _mundo()
	return m.mi_club_id if m != null else ""

## Los dividendos, cada doce semanas. Salen del tamaño del club: un filial grande
## renta mucho más, que es exactamente por lo que se paga por él.
func semana_filiales() -> void:
	if filiales.is_empty():
		return
	var m := _mundo()
	if m == null or m.semana % SEMANAS_DIVIDENDO != 0:
		return
	var total := 0
	for cid: String in filiales:
		var c: Club = m.clubes.get(cid)
		if c != null:
			total += c.rep * c.rep * 40
	if total <= 0:
		return
	patrimonio += total
	noticia_carrera.emit("Dividendos de tus clubes",
		"Tus participaciones te dejaron %s de patrimonio personal." % Cesiones.dinero(total))

# ---------------------------------------------------------------------------
#  LA SUCESIÓN
# ---------------------------------------------------------------------------
#
# A quién le dejas el club al retirarte. No cambia tu partida —ya se acabó— y por
# eso importa: es lo único del juego que solo sirve para decidir cómo quieres que
# se recuerde lo que hiciste.

var sucesor: Dictionary = {}

func candidatos_sucesion() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var m := _mundo()
	if m == null:
		return salida
	## Tu ayudante: conoce el vestuario mejor que nadie y por eso le dan el
	## margen más largo.
	if m.staff != null and m.staff.nivel("at") > 0:
		salida.append({"tipo": "ayudante", "nombre": "Tu ayudante técnico",
			"desc": "Conoce el vestuario mejor que nadie.", "margen": 14})
	if not leyenda_viva.is_empty():
		salida.append({"tipo": "leyenda", "nombre": String(leyenda_viva["nombre"]),
			"desc": "Leyenda del club. La gente lo idolatra, pero nunca ha dirigido.", "margen": 8})
	## Un canterano tuyo ya retirado.
	if m.cantera != null and not m.cantera.leyendas.is_empty():
		var ultima: Dictionary = m.cantera.leyendas[m.cantera.leyendas.size() - 1]
		salida.append({"tipo": "exjugador", "nombre": String(ultima.get("nombre", "")),
			"desc": "Ex jugador de tu era. Quiere devolver lo que recibió.", "margen": 10})
	salida.append({"tipo": "externo", "nombre": _nombre_de_persona(),
		"desc": "Nombre de fuera con cartel. Traerá su propia gente y su propia idea.", "margen": 18})
	return salida

func elegir_sucesor(i: int) -> String:
	var lista := candidatos_sucesion()
	if i < 0 or i >= lista.size():
		return "ese candidato no existe"
	sucesor = lista[i]
	noticia_carrera.emit("Sucesión resuelta",
		"Dejas el club en manos de %s. %s El directorio le da un margen de %d partidos." % [
			String(sucesor["nombre"]), String(sucesor["desc"]), int(sucesor["margen"])])
	return ""

# ---------------------------------------------------------------------------
#  EL DESGASTE DEL ENTRENADOR Y SU CURRÍCULUM
# ---------------------------------------------------------------------------
#
# Ideas 53 y 55: «currículum del personaje (clubes anteriores)» y «nivel de
# estrés/desgaste del personaje en el cargo».
#
# EL DESGASTE NO ES UNA BARRA MÁS. Sube con las derrotas, la funa y las semanas
# seguidas en el mismo banquillo, y baja con las victorias y con el parón de
# temporada. Cuando pasa de 80, empiezan a pasar cosas: duermes mal, la rueda de
# prensa te sale peor y la directiva lo nota. Es lo que hace que un ciclo largo
# tenga un coste que no es deportivo.
#
# NO TE ECHA. Un entrenador quemado no se despide solo: sigue trabajando peor.
# Quitarle el control al jugador por una barra sería castigarlo dos veces.

const DESGASTE_ALTO := 80
var desgaste: int = 0

## El currículum: cada club por el que has pasado, con lo que hiciste allí.
## {club, nombre, desde, hasta, trofeos, motivo}
var curriculum: Array = []

func mover_desgaste(d: int) -> void:
	desgaste = clampi(desgaste + d, 0, 100)

func quemado() -> bool:
	return desgaste >= DESGASTE_ALTO

## Cuánto le resta el desgaste a lo que consigues en una rueda de prensa. Con la
## cabeza fundida, lo que dices sale peor: es el único efecto y es suficiente.
func factor_desgaste() -> float:
	if not quemado():
		return 1.0
	return 0.6

## El pulso semanal del desgaste. Lo llama `Mundo` junto al resto.
func semana_desgaste(gano_algo: bool, funa: int) -> void:
	## Una semana en el cargo cansa un poco. Ganar descansa; la funa quema.
	var d := 1
	if gano_algo:
		d -= 3
	d += 1 if funa > 50 else 0
	d += 1 if funa > 75 else 0
	mover_desgaste(d)

## Se cierra el capítulo de un club y se abre otro. Lo llama `tomar_el_mando()`
## cuando ya había un club antes: es lo que convierte una partida larga en una
## CARRERA y no en una sucesión de clubes sin memoria.
func cerrar_capitulo(club_id: String, nombre_club: String, anio: int, motivo: String) -> void:
	if club_id == "":
		return
	for c: Dictionary in curriculum:
		if String(c.get("club", "")) == club_id and int(c.get("hasta", 0)) == 0:
			c["hasta"] = anio
			c["motivo"] = motivo
			c["trofeos"] = trofeos.size()
			return

func abrir_capitulo(club_id: String, nombre_club: String, anio: int) -> void:
	if club_id == "":
		return
	curriculum.append({
		"club": club_id, "nombre": nombre_club, "desde": anio, "hasta": 0,
		"trofeos": 0, "motivo": "",
	})
	## El parón entre clubes descansa: llegar a un sitio nuevo con la cabeza
	## despejada es de las pocas cosas buenas de que te echen.
	desgaste = maxi(0, desgaste - 35)

# ---------------------------------------------------------------------------
#  QUE TE QUIERA OTRO CLUB
# ---------------------------------------------------------------------------
#
# «Propuesta de otro club para el DT/presidente» (idea 193). Es lo único del
# juego que te ofrece IRTE, y hace falta por una razón concreta: sin ella, la
# única forma de cambiar de club es que te echen, y una carrera en la que solo
# te mueves fracasando no es una carrera.
#
# LLAMAN CUANDO VALES. Hace falta prestigio y que el club que llama sea mejor
# que el tuyo -o que estés a punto de que te echen, y entonces llama uno peor,
# que es como funciona de verdad-.

const PRESTIGIO_PARA_OFERTA := 58
const SEMANAS_ENTRE_OFERTAS := 20

var oferta_de_club: Dictionary = {}   ## {club_id, nombre, mejora, sueldo}
var _ultima_oferta: int = 0

## Sortea si alguien llama. Devuelve la oferta, o vacío.
func sortear_oferta_de_club() -> Dictionary:
	var m := _mundo()
	if m == null or not oferta_de_club.is_empty():
		return {}
	if m.semana - _ultima_oferta < SEMANAS_ENTRE_OFERTAS:
		return {}
	var mio := m.mi_club()
	if mio == null or prestigio < PRESTIGIO_PARA_OFERTA:
		return {}
	if not Azar.suerte(0.06):
		return {}
	## Los que podrían quererte: mejores que el tuyo, pero no tanto como para
	## que sea absurdo. Un 96 no llama a un entrenador de 60 de prestigio.
	var candidatos: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.id == mio.id:
			continue
		if c.rep > mio.rep and c.rep <= mio.rep + 14 and c.rep <= prestigio + 30:
			candidatos.append(c)
	if candidatos.is_empty():
		return {}
	_ultima_oferta = m.semana
	var elegido: Club = candidatos[Azar.ent(0, candidatos.size() - 1)]
	oferta_de_club = {
		"club_id": elegido.id, "nombre": elegido.nombre,
		"mejora": elegido.rep - mio.rep,
		"sueldo": Eco.escalar(9000.0 * (0.6 + float(prestigio) / 100.0), float(elegido.rep)),
	}
	return oferta_de_club

## Aceptar es irse: se cierra el capítulo de este club y se abre el del otro.
## Rechazar tampoco es gratis —la directiva se entera de que te llamaron— pero
## sube la confianza: quedarse habiendo podido irse se agradece.
func responder_oferta_de_club(acepta: bool) -> String:
	if oferta_de_club.is_empty():
		return "no hay ninguna oferta sobre la mesa"
	var m := _mundo()
	var nombre := String(oferta_de_club["nombre"])
	var destino := String(oferta_de_club["club_id"])
	oferta_de_club = {}
	if not acepta:
		if m != null and m.directiva != null:
			m.directiva.mover_confianza(4, "rechazar una oferta de otro club")
		return "Dices que no a %s. En el club se enteran, y se agradece." % nombre
	if m != null:
		m.tomar_el_mando(destino)
	return "Te vas a %s. Capítulo cerrado; empieza otro." % nombre
