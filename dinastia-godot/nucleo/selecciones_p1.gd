extends RefCounted
## (Parte 1 de 3 de `selecciones.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `selecciones.gd`, conserva la clase.)

## La selección nacional y el Mundial de Clubes.
##
## Son los dos torneos que el club no juega pero que le pasan por encima. La
## selección se lleva a tus mejores cuatro veces por temporada y te los devuelve
## fundidos; el Mundial de Clubes es el techo al que solo se llega ganando antes
## el continente.
##
## QUÉ SELECCIÓN ES LA TUYA
## La del país donde diriges, no Chile. En el HTML esto era Chile siempre —la
## pestaña te enseñaba a La Roja aunque estuvieras en el Milan— y se arregló a
## medias: `paisSel()` ya miraba tu club, pero `fuerzaSeleccion()` seguía con el
## nombre "Chile" escrito a mano. Aquí la fuerza extra del prestigio del
## entrenador va a la selección que de verdad sigues; dirigiendo en Chile sale
## exactamente el mismo número que en el HTML, que es lo que importa.
##
## POR QUÉ UNA CONVOCATORIA SE NOTA
## No es una noticia decorativa. Al convocado se le restan 12 puntos de físico
## (20 si es su tercera fecha seguida), y el físico entra directo en la fuerza
## del once en `Partido.fuerza()`: un titular que vuelve de gira rinde menos el
## domingo. Por debajo de 55 de físico se enciende además el chequeo de fatiga de
## `Medico`, así que exprimir a un internacional acaba costando semanas de baja.
## Y en la propia gira hay un 5% de lesión (12% con sobreuso) que te lo quita de
## verdad. Llevarte a tres titulares a la selección tiene que doler, o el sistema
## sobra.
##
## LO QUE NECESITA DEL MUNDO (no se lo inventa)
##  - `semana(anio, semana)` cada semana, desde `Mundo.avanzar_semana()`.
##  - `cierre_de_temporada(anio)` al cerrar el año, ANTES de volver a sortear los
##    continentales: el Mundial de Clubes lee sus campeones.
##  - Del `Mundo` lee `clubes`, `mi_club()`, `mi_club_id`, `continentales`,
##    `medico` y `roles`. Solo escribe en el saldo de los clubes (premios y
##    compensaciones FIFA), en el físico y la moral de los jugadores, y en el
##    prestigio del entrenador.
##  - Quien lo llame conecta `noticia` y `movimiento`: esta clase no sabe pintar
##    ni llevar la contabilidad, solo dice qué pasó y cuánto se movió.
##
## Todo lo que es POR JUGADOR (partidos con la selección, racha de convocatorias,
## nacionalidad deportiva, temporadas de residencia) vive aquí indexado por id,
## como las fichas de `Medico`. `Jugador` no se toca: al HTML se le colgaron seis
## campos sueltos (`caps`, `convStreak`, `nacionalizado`, `tempExt`,
## `pideDescansoSel`) que cualquiera podía pisar.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)
## La prenómina de 30 y la nómina final de 18. Van por separado porque son dos
## momentos distintos: en la primera ves venir el golpe, en la segunda lo recibes.
signal prenomina_publicada(lista: Array)
signal convocatoria(convocados: Array, mios: Array)
signal vuelve_tocado(j: Jugador, semanas: int, sobreuso: bool)
signal torneo_de_selecciones(torneo: String, puesto: int)
signal copa_del_mundo_jugada(anio: int, campeon: String)
signal mundial_de_clubes_jugado(anio: int, campeon: Club, mio: bool)

# ---------------------------------------------------------------------------
#  NÚMEROS DEL HTML. No son redondeos bonitos: están equilibrados.
# ---------------------------------------------------------------------------

## La semana ANTES de cada fecha FIFA sale la prenómina. Sirve para que veas
## venir la convocatoria y el desgaste en vez de enterarte cuando ya se te fueron.
const SEMANAS_PRENOMINA := [6, 15, 25, 33]
const SEMANAS_FIFA := [7, 16, 26, 34]

const TOPE_PRENOMINA := 30
const TOPE_NOMINA := 18
## Los 18 de la nómina, por línea. Suman exactamente 18: si se tocan, se toca el
## tope, o el seleccionador se queda sin delanteros.
const CUPOS := {"POR": 2, "DEF": 6, "MED": 6, "DEL": 4}

const MAX_RESULTADOS := 10
const MORAL_CONVOCADO := 6
const MORAL_TITULO_CONTINENTAL := 10

## El desgaste de la gira y el castigo por exprimir al mismo tres fechas seguidas.
const DESGASTE_FIFA := 12
const DESGASTE_SOBREUSO := 8
const FECHAS_PARA_SOBREUSO := 3
const RIESGO_GIRA := 0.05
const RIESGO_EXTRA_SOBREUSO := 0.07
## Reparto de gravedad de la lesión de gira: 15% media, el resto leve.
const PROB_LESION_MEDIA := 0.15
## Semanas de sueldo que paga la FIFA por cada semana de baja, más un fijo de 4.
const COMPENSACION_BASE := 4

## Nacionalización deportiva: cuatro temporadas jugando en el país.
const TEMPORADAS_PARA_NACIONALIZAR := 4
const COSTE_NACIONALIZACION := 6000.0
const MULTIPLO_SUELDO_NACIONALIZACION := 10.0

## Que la federación respete tu pedido de descanso depende de quién sea: a una
## figura casi nunca te la perdonan, a un suplente sí.
const RESPETA_A_LA_FIGURA := 0.25
const RESPETA_AL_SUPLENTE := 0.70
## De aquí para arriba (sobre la reputación de tu club) el jugador es "figura".
const MARGEN_FIGURA := 8

## La Copa del Mundo: 32 de las 37 selecciones, cada cuatro años. El resto (2028,
## 2032...) sale de la cuenta del HTML: `(año - 2026) % 4 === 2`.
const PLAZAS_COPA_DEL_MUNDO := 32
const ANIO_BASE := 2026
const CICLO_MUNDIAL := 4
const RESTO_MUNDIAL := 2
## Ruido del duelo entre selecciones: ±9 sobre la fuerza. Es lo que permite que
## una selección de 70 elimine a una de 88 de vez en cuando, y solo de vez en cuando.
const RUIDO_DUELO := 9
## Lo que se lleva de la vitrina mundialista el que juega el Mundial.
const PROB_VITRINA := 0.60
const PROB_LESION_MUNDIAL := 0.25

## Cuántos campeones continentales se recuerdan. Treinta son diez temporadas
## largas de historia: más no cabe en ninguna pantalla.
const MAX_CAMPEONES_GUARDADOS := 30

## El escalafón de selecciones, tal cual el HTML. Las de arriba no dependen del
## hash: son las que tienen que ser favoritas siempre.
const SELECCIONES_TOP := ["Brasil", "Argentina", "Francia", "España", "Inglaterra", "Alemania"]
const SELECCIONES_BUENAS := ["Portugal", "Holanda", "Italia", "Bélgica", "Croacia", "Uruguay", "Colombia"]
const FUERZA_TOP := 88
const FUERZA_BUENA := 82
## Chile vale 76 por decreto del HTML: es la selección de referencia del juego y
## tiene que quedar por encima del montón sin llegar a las grandes.
const FUERZA_CHILE := 76
const FUERZA_BASE := 70
const DIVISOR_PRESTIGIO := 25.0

## El torneo continental de selecciones, por confederación. Se juega cada dos
## años (los pares) y cuál es depende de dónde dirijas: la clave la da
## `Continental.confed_de`, que es la misma tabla que reparte las copas de clubes.
const TORNEO_POR_CONFED := {
	"lib": "Copa América", "ucl": "Eurocopa", "asia": "Copa de Asia",
	"afr": "Copa África", "conc": "Copa Oro", "oce": "Copa de Oceanía",
}
## Cómo termina el torneo. La bolsa está sesgada a propósito: el campeonato es
## raro, la fase de grupos también, y lo normal es caer por el medio.
const PUESTOS_TORNEO := ["campeón", "finalista", "semifinalista", "eliminado en cuartos", "eliminado en fase de grupos"]
const BOLSA_PUESTOS := [0, 1, 1, 2, 2, 3, 3, 4]

# ---------------------------------------------------------------------------
#  ESTADO
# ---------------------------------------------------------------------------

## Ids de la última prenómina de 30 y de la última nómina de 18.
var prenomina_ids: Array[String] = []
var nomina_ids: Array[String] = []
## Los últimos diez resultados de la selección, ya escritos para pintar.
var resultados: Array[String] = []

## El último campeón del mundo: {anio, campeon}.
var mundial: Dictionary = {}
## El último Mundial de Clubes: {anio, campeon, club_id, mio, relato}.
var mundial_clubes: Dictionary = {}
## Los campeones continentales de clubes, el más reciente primero:
## {torneo, campeon, club_id, clave, anio}.
var campeones_continentales: Array[Dictionary] = []

## Todo lo que es de un jugador, por id. Ver la nota de la cabecera.
var _caps: Dictionary = {}            ## id -> partidos con la selección
var _racha: Dictionary = {}           ## id -> convocatorias seguidas sin descanso
var _nacionalizados: Dictionary = {}  ## id -> código de país que le dio el pasaporte
var _residencia: Dictionary = {}      ## id -> temporadas seguidas jugando en el país
var _descanso: Dictionary = {}        ## id -> true mientras el pedido esté en curso

## Referencia DÉBIL al mundo, como en `Mercado`, `Prensa` y `Roles`. El mundo
## guarda esto y esto necesita ver el mundo: con dos referencias normales es un
## ciclo, y `RefCounted` no recoge ciclos. Un `Mundo` que no muere se lleva
## consigo sus 384 clubes y sus miles de jugadores; ya han caído cuatro clases
## por aquí.
var _ref: WeakRef

## Lo que suma al prestigio del entrenador ganarlo. Es el número más alto que
## reparte el juego por un título, y con motivo.
const PRESTIGIO_MUNDIAL_CLUBES := 10

## El torneo en sí. Hereda de `Continental`, que a su vez hereda de `Copa`: los
## cruces, la tanda de penales, el "este partido ya lo dirigió el entrenador" y
## el pago al campeón ya están escritos ahí y no se vuelven a escribir. Lo único
## suyo son el sorteo (siembra, sin barajar y sin recortar) y el premio.
class MundialClubes extends Continental:

	## El premio del HTML, y es una cifra FIJA como todas las de este juego: no
	## se escala al tamaño del club. 1.800.000 le cambian la década a un campeón
	## de Oceanía y a uno de Europa le vienen bien. Esa asimetría es el punto.
	const PREMIO_CAMPEON := 1800000

	## Los que pasan de ronda sin jugar. Con seis campeones continentales el
	## cuadro no es potencia de dos, así que en alguna ronda sobra uno: en el
	## HTML es el último de la lista (`if(!b){sig.push(a);continue;}`) y aquí
	## también.
	var _esperan: Array[Club] = []

	func _init(nombre_torneo: String = "Mundial de Clubes") -> void:
		super(nombre_torneo)
		clave = "mundialclubes"
		premio = PREMIO_CAMPEON

	## Siembra real: el cabeza de serie contra el más débil, no los dos mejores
	## entre sí en la primera ronda.
	##
	## Por eso NO se llama a `Copa.preparar`, que hace justo lo contrario de lo
	## que hace falta aquí: baraja (rompería la siembra) y recorta a la potencia
	## de dos más cercana por abajo (con seis campeones dejaría fuera a dos, y uno
	## de ellos podría ser el tuyo, que se habría clasificado ganando una copa
	## continental entera).
	func preparar(clubes: Array[Club]) -> void:
		por_grupos = false
		grupos.clear()
		marcador.clear()
		fecha = 0
		ronda = 0
		campeon = null
		historial.clear()
		_esperan.clear()
		var orden := clubes.duplicate()
		orden.sort_custom(_mas_grande)
		participantes = orden.duplicate()
		vivos.clear()
		var i := 0
		var j := orden.size() - 1
		while i <= j:
			vivos.append(orden[i])
			if i != j:
				vivos.append(orden[j])
			i += 1
			j -= 1

	## Reputación, y el id como desempate. La misma regla que usa `Continental`
	## para ordenar países, y por el mismo motivo: `sort_custom` no es estable y
	## sin un criterio final la misma semilla podría dar dos cuadros distintos.
	static func _mas_grande(a: Club, b: Club) -> bool:
		if a.rep != b.rep:
			return a.rep > b.rep
		return a.id < b.id

	## Los que esperan cuentan para saber en qué ronda estamos. Sin ellos, una
	## semifinal con un club sentado se anunciaría como la final.
	func nombre_de_ronda() -> String:
		var n := vivos.size() + _esperan.size()
		if n <= 2:
			return "Final"
		if n <= 4:
			return "Semifinales"
		if n <= 8:
			return "Cuartos de final"
		return super.nombre_de_ronda()

	func jugar_ronda(ya_jugado: Partido = null) -> Array:
		if not en_curso():
			return []
		## El impar se sienta antes de que la eliminatoria empiece a emparejar.
		## Si no se saca, `Copa.jugar_ronda` empareja de dos en dos y al que sobra
		## lo TIRA del torneo en silencio: no es un bye, es una eliminación sin
		## jugar.
		if vivos.size() > 1 and vivos.size() % 2 == 1:
			_esperan.append(vivos[vivos.size() - 1])
			vivos.remove_at(vivos.size() - 1)
		var resultados := super.jugar_ronda(ya_jugado)
		if not _esperan.is_empty():
			## TRAMPA, y es la razón de que esta clase exista. `Copa.jugar_ronda`
			## proclama campeón en cuanto `vivos` queda en uno, y en una ronda de
			## un solo cruce eso pasa con un club todavía sentado esperando la
			## final. Se deshace aquí, premio de copa incluido, antes de juntar
			## los dos grupos. Es el precio de reutilizar la eliminatoria en vez
			## de escribir otra, y sale barato: son cuatro líneas contra un motor
			## de cuadros duplicado.
			if campeon != null:
				campeon.mover_saldo(-Copa.PREMIO)
				campeon = null
			vivos.append_array(_esperan)
			_esperan.clear()
		return resultados

	## Este torneo no paga por rondas: el HTML abona una sola cifra y solo al que
	## levanta la copa. `Copa` ya le ha dado su premio de copa nacional al
	## campeón, así que aquí se abona la diferencia; se resta la constante y no el
	## número para que siga cuadrando si algún día `Copa` sube su premio.
	func _pagar_eliminatoria(vivos_antes: int) -> void:
		if not _esperan.is_empty():
			return                        ## la ronda con byes todavía no ha acabado
		if vivos_antes <= 2 and campeon != null:
			campeon.mover_saldo(premio - Copa.PREMIO)

	func premio_de_ronda(_vivos_antes: int) -> int:
		return 0

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

# ---------------------------------------------------------------------------
#  QUIÉN ES TU SELECCIÓN
# ---------------------------------------------------------------------------

static func _tabla_selecciones() -> Array:
	var t: Variant = Datos.tabla("SELECCIONES")
	return t if t is Array else []

static func _tabla_paises() -> Dictionary:
	var t: Variant = Datos.tabla("PAIS_SELECCION")
	return t if t is Dictionary else {}

## Los nombres de las tablas pasan por `Nombres.limpiar` aunque estos dos vengan
## ya en claro. No es paranoia: la regla del proyecto es limpiar SIEMPRE los dos
## lados de una comparación, y aquí se compara el nombre de tu selección contra
## los de la lista mundial. Limpiar solo uno es cómo se rompió la carga de los
## 813 jugadores reales en el HTML.
static func _txt(s: String) -> String:
	return Nombres.limpiar(s)

## El código de país de la selección que sigues, o CHI si diriges en un país sin
## selección en la tabla.
func pais_seleccion() -> String:
	var m := _mundo()
	var c: Club = m.mi_club() if m != null else null
	if c != null and _tabla_paises().has(c.pais):
		return c.pais
	return "CHI"

func nombre_seleccion() -> String:
	var t := _tabla_paises()
	return _txt(String(t.get(pais_seleccion(), "Chile")))

## Elegible para la selección del país donde diriges: o nació allí, o se
## nacionalizó allí. El pasaporte guarda el CÓDIGO de país, no un simple sí: un
## jugador nacionalizado chileno no sirve para la selección española.
func elegible(j: Jugador, pais_dado: String = "") -> bool:
	if j == null:
		return false
	var p := pais_dado if pais_dado != "" else pais_seleccion()
	if j.pais == p:
		return true
	return String(_nacionalizados.get(j.id, "")) == p

# ---------------------------------------------------------------------------
#  EL RANKING MUNDIAL
# ---------------------------------------------------------------------------

## El `hashStr` del HTML: `h = (h * 31 + código) | 0`, y el valor absoluto al
## final. El `| 0` de JavaScript trunca a entero de 32 bits CON signo, y aquí los
## enteros son de 64: sin el `wrapi` el hash se dispara y las selecciones del
## montón dejan de repartirse el 70-79 como deben.
static func _hash_txt(s: String) -> int:
	var h := 0
	for i in s.length():
		h = wrapi(h * 31 + s.unicode_at(i), -2147483648, 2147483648)
	return absi(h)

## El `G.dt.rep` del HTML, que en Godot vive en `Roles`. Cincuenta es el valor de
## arranque: sin carrera empezada, el entrenador no suma ni resta.
func prestigio_dt() -> int:
	var m := _mundo()
	if m == null or m.roles == null:
		return 50
	return m.roles.prestigio

## Cuánto vale una selección. Las seis grandes valen 88, las siete buenas 82,
## Chile 76 y el resto entre 70 y 79 según su nombre: el hash da un número
## estable, así que Senegal vale siempre lo mismo en todas las partidas.
##
## El punto extra por prestigio del entrenador va a TU selección. En el HTML
## estaba escrito "Chile" a mano y se lo llevaba La Roja aunque dirigieras en
## Alemania; dirigiendo en Chile el resultado es idéntico.
func fuerza(n: String) -> int:
	var limpio := _txt(n)
	var base := 0
	if SELECCIONES_TOP.has(limpio):
		base = FUERZA_TOP
	elif SELECCIONES_BUENAS.has(limpio):
		base = FUERZA_BUENA
	elif limpio == "Chile":
		base = FUERZA_CHILE
	else:
		base = FUERZA_BASE + _hash_txt(limpio) % 10
	if limpio == nombre_seleccion():
		base += int(round(float(prestigio_dt()) / DIVISOR_PRESTIGIO))
	return base

## El escalafón mundial, ya ordenado: [{nombre, fuerza}].
func ranking(tope: int = 14) -> Array[Dictionary]:
	var filas: Array[Dictionary] = []
	for n: String in _tabla_selecciones():
		filas.append({"nombre": _txt(n), "fuerza": fuerza(n)})
	## El nombre como desempate: `sort_custom` no es estable y sin un criterio
	## final dos ejecuciones de la MISMA semilla podrían ordenar distinto a dos
	## selecciones empatadas, y ahí se acaba la repetibilidad del banco de pruebas.
	filas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["fuerza"]) != int(b["fuerza"]):
			return int(a["fuerza"]) > int(b["fuerza"])
		return String(a["nombre"]) < String(b["nombre"]))
	if tope > 0 and filas.size() > tope:
		filas.resize(tope)
	return filas

# ---------------------------------------------------------------------------
#  LA SEMANA: PRENÓMINA Y FECHA FIFA
# ---------------------------------------------------------------------------

func hay_prenomina(semana_n: int) -> bool:
	return SEMANAS_PRENOMINA.has(semana_n)

func hay_fecha_fifa(semana_n: int) -> bool:
	return SEMANAS_FIFA.has(semana_n)

## Todos los elegibles sanos del mundo. Se recorre el mundo entero y no solo tu
## plantel a propósito: la selección la forman los mejores del país jueguen donde
## jueguen, y ver en la lista al que no pudiste fichar es parte de la gracia.
func _elegibles_sanos(m: Mundo) -> Array[Jugador]:
	var p := pais_seleccion()
	var salida: Array[Jugador] = []
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if j.lesion > 0:
				continue
			if elegible(j, p):
				salida.append(j)
	return salida

## Media y, si empatan, el id: `sort_custom` no es estable y dos jugadores con la
## misma media podrían entrar y salir de la nómina en dos ejecuciones de la misma
## semilla.
static func _mejor_media(a: Jugador, b: Jugador) -> bool:
	if a.ovr != b.ovr:
		return a.ovr > b.ovr
	return a.id < b.id
