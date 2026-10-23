extends RefCounted
## [Capa 1/5 de `roles.gd`] look_efectivo, aspecto_3d, es_ayudante

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

## El prestigio del entrenador y su vitrina, que son de la CARRERA y no del club:
## `Directiva.trofeos` se queda en el club que abandonas, esto te sigue.
var prestigio: int = PRESTIGIO_INICIAL
## TU REPUTACIÓN POR FACETAS y los niveles del club (26-9-2026, `Reputacion`).
var reputacion: Reputacion = Reputacion.new()
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

## Lo que cuesta un homenaje. Se escala al tamaño del club como cualquier gasto,
## así que en un club chico es una decisión y no un capricho.
const COSTE_HOMENAJE := 45000.0

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

# ---------------------------------------------------------------------------
#  LA LEYENDA VIVA
# ---------------------------------------------------------------------------
#
# Un ex jugador que se queda ligado al club de por vida. No entrena, no fila y no
# aparece en ninguna estadística: viene, habla con los chicos y está. Cada seis
# semanas se sienta con un juvenil, le sube la moral y a veces le sube la media.

var leyenda_viva: Dictionary = {}   ## {nombre, pos, desde, visitas}

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

# ---------------------------------------------------------------------------
#  LA SUCESIÓN
# ---------------------------------------------------------------------------
#
# A quién le dejas el club al retirarte. No cambia tu partida —ya se acabó— y por
# eso importa: es lo único del juego que solo sirve para decidir cómo quieres que
# se recuerde lo que hiciste.

var sucesor: Dictionary = {}

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

## El aspecto de verdad, con los valores por defecto rellenando lo que no se
## ha tocado -mismo merge que `Cara.look_de()` hace con `Jugador.look`, solo
## que la base aquí es un `Dictionary` fijo (`CaraDT.look_por_defecto()`), no
## un hash: el DT no tiene un id de futbolista del que derivar una cara.
func look_efectivo() -> Dictionary:
	var base := CaraDT.look_por_defecto()
	for k: String in look:
		base[k] = look[k]
	return base

## TU PERSONAJE EN 3D (26-9-2026, `CreadorPersonaje`): el aspecto guardado
## (solo lo tocado; `PersonajeDT.aspecto()` rellena el resto). Si nunca se
## tocó, sale del retrato 2D: mismo corte y color de pelo, para que el 3D y
## la ficha no parezcan dos personas distintas.
func aspecto_3d() -> Dictionary:
	var guardado: Variant = look.get("p3d")
	if guardado is Dictionary and not (guardado as Dictionary).is_empty():
		return guardado
	var l := look_efectivo()
	var a := {}
	var corte := String(l.get("pelo", ""))
	if corte in PersonajeDT.CORTES:
		a["pelo"] = corte
	if l.get("pelo_c") != null:
		a["color_pelo"] = String(l["pelo_c"]).trim_prefix("#")
	if l.get("piel") != null:
		a["piel"] = String(l["piel"]).trim_prefix("#")
	a["barba"] = int(l.get("barba", 0)) > 0
	var traje := String(l.get("traje", ""))
	for r: Array in PersonajeDT.ROPAS:
		if String(r[0]) == traje:
			a["ropa"] = traje
	if bool(l.get("gafas", false)):
		a["gafas"] = "ver"
	return a

func es_ayudante() -> bool:
	return rol == AYUDANTE
