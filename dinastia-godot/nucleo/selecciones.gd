class_name Selecciones
extends RefCounted
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

## El `G.dt.rep` del HTML, que en Godot vive en `Roles`. Cincuenta es el valor de
## arranque: sin carrera empezada, el entrenador no suma ni resta.
func prestigio_dt() -> int:
	var m := _mundo()
	if m == null or m.roles == null:
		return 50
	return m.roles.prestigio

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

## El pulso semanal de la selección. Se llama siempre; decide ella si toca algo.
func semana(anio: int, semana_n: int) -> void:
	if _mundo() == null:
		return
	if hay_prenomina(semana_n):
		_prenomina()
	if hay_fecha_fifa(semana_n):
		_fecha_fifa(anio, semana_n)

## Los 30 preseleccionados: los mejores elegibles sanos del mundo entero.
func _prenomina() -> void:
	var m := _mundo()
	var lista := _elegibles_sanos(m)
	lista.sort_custom(_mejor_media)
	if lista.size() > TOPE_PRENOMINA:
		lista.resize(TOPE_PRENOMINA)
	prenomina_ids.clear()
	var mios: Array[String] = []
	for j in lista:
		prenomina_ids.append(j.id)
		if j.club_id == m.mi_club_id:
			mios.append(j.nombre)
	var sel := nombre_seleccion()
	noticia.emit("Prenómina de " + sel,
		"La selección de %s publica una lista preliminar de %d jugadores rumbo a la próxima fecha FIFA." % [sel, lista.size()]
		+ (" De tu club: %s." % ", ".join(mios) if not mios.is_empty() else " Sin jugadores de tu club en el corte inicial."))
	prenomina_publicada.emit(lista)

## La nómina de 18 y el partido. Aquí es donde la selección se lleva a los tuyos.
func _fecha_fifa(anio: int, semana_n: int) -> void:
	var m := _mundo()
	var mio := m.mi_club()
	var sel := nombre_seleccion()

	## Primero el filtro, con el pedido de descanso resuelto dentro: la
	## federación decide una sola vez por jugador y por fecha, gane o pierda.
	var candidatos: Array[Jugador] = []
	for j in _elegibles_sanos(m):
		if mio != null and j.club_id == mio.id and _descanso.has(j.id):
			_descanso.erase(j.id)
			var figura := j.ovr >= mio.rep + MARGEN_FIGURA
			if Azar.suerte(RESPETA_A_LA_FIGURA if figura else RESPETA_AL_SUPLENTE):
				_racha[j.id] = 0
				noticia.emit("La federación respeta el pedido",
					"El cuerpo técnico de %s decide no citar a %s esta fecha FIFA, atendiendo el pedido de descanso del club." % [sel, j.nombre])
				continue
			noticia.emit("La federación ignora el pedido",
				"Pediste que %s descansara y la federación lo citó igual. Vuelve el lunes, y verás cómo." % j.nombre)
		candidatos.append(j)
	candidatos.sort_custom(_mejor_media)

	## Los 18, por líneas. Se recorre la lista ya ordenada, así que cada línea se
	## queda con sus mejores: es lo que impide que la nómina sean once medios.
	var cupos := CUPOS.duplicate()
	var convocados: Array[Jugador] = []
	for j in candidatos:
		if int(cupos.get(j.pos, 0)) > 0:
			convocados.append(j)
			cupos[j.pos] = int(cupos[j.pos]) - 1
		if convocados.size() >= TOPE_NOMINA:
			break
	nomina_ids.clear()
	for j in convocados:
		nomina_ids.append(j.id)

	## Los que estaban en la prenómina y no llegaron. Es la mitad de para lo que
	## sirve publicar una lista preliminar.
	var cortados: Array[String] = []
	for j in prenominados():
		if mio != null and j.club_id == mio.id and not convocados.has(j):
			cortados.append(j.nombre)
	if not cortados.is_empty():
		noticia.emit("Quedaron fuera de la nómina final",
			"Estaban en la prenómina pero no llegaron a la lista definitiva: %s. El cuerpo técnico prefirió otras variantes." % ", ".join(cortados))

	## Al que no va se le corta la racha: el sobreuso castiga fechas SEGUIDAS.
	for j in candidatos:
		if mio != null and j.club_id == mio.id and not convocados.has(j):
			_racha[j.id] = 0

	var mios: Array[Jugador] = []
	for j in convocados:
		_caps[j.id] = caps_de(j) + 1
		j.moral = clampi(j.moral + MORAL_CONVOCADO, 10, 99)
		if mio == null or j.club_id != mio.id:
			continue
		mios.append(j)
		_desgastar(j, mio, anio, semana_n)

	_jugar_amistoso(sel)
	if not mios.is_empty():
		var nombres: Array[String] = []
		for j in mios:
			nombres.append(j.nombre)
		noticia.emit("Convocados de tu club",
			"Se van con %s: %s. Vuelven con la moral arriba y con el depósito vacío." % [sel, ", ".join(nombres)])
	convocatoria.emit(convocados, mios)

## Lo que le cuesta a TU club la gira. Solo a los tuyos: el físico de los
## jugadores de la IA no lo recupera nadie (`Entrenamiento` solo procesa tu
## plantel), así que restárselo sería una sangría permanente que no se ve en
## ninguna pantalla. En el HTML pasa lo mismo y por el mismo motivo.
func _desgastar(j: Jugador, mio: Club, anio: int, semana_n: int) -> void:
	var racha := racha_de(j) + 1
	_racha[j.id] = racha
	var sobreuso := racha >= FECHAS_PARA_SOBREUSO
	j.fisico = clampi(j.fisico - DESGASTE_FIFA - (DESGASTE_SOBREUSO if sobreuso else 0), 10, 100)
	if not Azar.suerte(RIESGO_GIRA + (RIESGO_EXTRA_SOBREUSO if sobreuso else 0.0)):
		return

	var m := _mundo()
	var sev := Medico.MEDIA if Azar.suerte(PROB_LESION_MEDIA) else Medico.LEVE
	var sem := 0
	var tipo := "molestia"
	if m.medico != null:
		sem = m.medico.lesionar(j, sev, "jugando con su selección", anio, semana_n)
		tipo = m.medico.diagnostico(j)
	else:
		## Sin parte médico (todavía no has tomado un club) no hay diagnóstico,
		## pero la baja existe igual: el jugador vuelve roto de la gira.
		sem = Azar.ent(1, 3)
		j.lesionar(sem)
	if sem <= 0:
		return

	## El programa de protección de clubes de la FIFA: te paga el sueldo del
	## lesionado. Se escala al tamaño de tu club como cualquier ingreso
	## operativo, que es lo que hace `esc$` en el HTML.
	var compensacion := Eco.escalar(float(j.sueldo) * float(COMPENSACION_BASE + sem), float(mio.rep))
	if compensacion > 0:
		mio.mover_saldo(compensacion)
		movimiento.emit("Compensación FIFA por lesión en gira: " + j.nombre, compensacion)
	noticia.emit(
		("⚠️ Sobrecarga en la selección: " if sobreuso else "Lesionado en la selección: ") + j.nombre,
		"%s vuelve tocado de la gira: %s (%d sem)." % [j.nombre, tipo.to_lower(), sem]
		+ (" Es su %dª convocatoria seguida sin descanso: la selección lo exprime y el club paga las consecuencias." % racha if sobreuso else "")
		+ (" El club recibe la ayuda del programa de protección de clubes de la FIFA." if compensacion > 0 else ""))
	vuelve_tocado.emit(j, sem, sobreuso)

## El partido de la fecha FIFA. El rival sale del escalafón mundial evitando que
## te enfrentes a ti mismo, y el marcador es un sorteo puro: la selección no
## tiene plantilla que simular, y fingir un partido de verdad con jugadores que
## no están en ningún club sería inventar un motor entero para una línea de texto.
func _jugar_amistoso(sel: String) -> void:
	var rivales: Array = []
	for n: String in _tabla_selecciones():
		if _txt(n) != sel:
			rivales.append(_txt(n))
	if rivales.is_empty():
		return
	var rival := String(Azar.uno(rivales))
	var g1 := Azar.ent(0, 3)
	var g2 := Azar.ent(0, 3)
	var linea := "%s %d - %d %s" % [sel, g1, g2, rival]
	_anotar_resultado(linea)
	noticia.emit("Fecha FIFA: " + linea,
		"Cierra la ventana internacional. Los que fueron vuelven con %s." % ("el ánimo arriba" if g1 >= g2 else "la mochila pesada"))

func _anotar_resultado(linea: String) -> void:
	resultados.push_front(linea)
	while resultados.size() > MAX_RESULTADOS:
		resultados.remove_at(resultados.size() - 1)

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

# ---------------------------------------------------------------------------
#  LO QUE PUEDE HACER EL ENTRENADOR
# ---------------------------------------------------------------------------

func caps_de(j: Jugador) -> int:
	return int(_caps.get(j.id, 0)) if j != null else 0

func racha_de(j: Jugador) -> int:
	return int(_racha.get(j.id, 0)) if j != null else 0

func temporadas_en_el_pais(j: Jugador) -> int:
	return int(_residencia.get(j.id, 0)) if j != null else 0

func nacionalidad_deportiva(j: Jugador) -> String:
	return String(_nacionalizados.get(j.id, "")) if j != null else ""

func pidio_descanso(j: Jugador) -> bool:
	return j != null and _descanso.has(j.id)

## Lo que cuesta el trámite: un fijo escalado al tamaño del club más diez semanas
## de su sueldo. Nacionalizar a un crack es una inversión; a un suplente, casi gratis.
func costo_nacionalizacion(j: Jugador) -> int:
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	var rep := float(mio.rep) if mio != null else Eco.REP_PIVOTE
	return Eco.escalar(COSTE_NACIONALIZACION, rep) + int(round(float(j.sueldo) * MULTIPLO_SUELDO_NACIONALIZACION))

## Tramita la nacionalidad deportiva. Devuelve "" si se hizo, o el motivo por el
## que no, como el resto de acciones del proyecto.
func nacionalizar(j: Jugador) -> String:
	var m := _mundo()
	if m == null or j == null:
		return "no hay partida"
	var mio := m.mi_club()
	if mio == null or j.club_id != mio.id:
		return "solo puedes nacionalizar a los tuyos"
	if elegible(j):
		return "ya puede jugar por " + nombre_seleccion()
	if temporadas_en_el_pais(j) < TEMPORADAS_PARA_NACIONALIZAR:
		return "necesita %d temporadas jugando en el país" % TEMPORADAS_PARA_NACIONALIZAR
	var costo := costo_nacionalizacion(j)
	if costo > mio.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [costo, mio.saldo]
	mio.mover_saldo(-costo)
	movimiento.emit("Trámite de nacionalización: " + j.nombre, -costo)
	_nacionalizados[j.id] = pais_seleccion()
	noticia.emit("Carta de nacionalización",
		"%s (nacido en %s) obtiene la nacionalidad de %s tras %d temporadas en el país. Ya puede ser convocado a la selección."
		% [j.nombre, j.pais, nombre_seleccion(), temporadas_en_el_pais(j)])
	return ""

## Pide a la federación que no lo citen en la próxima fecha. No es un botón de
## "no va": la federación decide, y a una figura casi nunca te la perdona. Ese
## reparto es lo que convierte el pedido en una apuesta y no en un interruptor.
func pedir_descanso(j: Jugador) -> String:
	var m := _mundo()
	if m == null or j == null:
		return "no hay partida"
	var mio := m.mi_club()
	if mio == null or j.club_id != mio.id:
		return "solo puedes pedirlo por los tuyos"
	if _descanso.has(j.id):
		return "ya hay un pedido en curso"
	_descanso[j.id] = true
	return ""

# ---------------------------------------------------------------------------
#  LISTAS PARA LA PANTALLA
# ---------------------------------------------------------------------------

func convocados() -> Array[Jugador]:
	return _resolver(nomina_ids)

func prenominados() -> Array[Jugador]:
	return _resolver(prenomina_ids)

## Los más internacionales del mundo: [{jugador, caps}].
func mas_convocados(tope: int = 12) -> Array[Dictionary]:
	var m := _mundo()
	if m == null:
		return []
	var filas: Array[Dictionary] = []
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			var n := caps_de(j)
			if n > 0:
				filas.append({"jugador": j, "caps": n})
	filas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["caps"]) != int(b["caps"]):
			return int(a["caps"]) > int(b["caps"])
		return (a["jugador"] as Jugador).id < (b["jugador"] as Jugador).id)
	if tope > 0 and filas.size() > tope:
		filas.resize(tope)
	return filas

## Tus extranjeros camino del pasaporte: [{jugador, temporadas}].
func candidatos_a_nacionalizar(tope: int = 6) -> Array[Dictionary]:
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	if mio == null:
		return []
	var filas: Array[Dictionary] = []
	for j in mio.plantilla:
		if elegible(j) or temporadas_en_el_pais(j) <= 0:
			continue
		filas.append({"jugador": j, "temporadas": temporadas_en_el_pais(j)})
	filas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["temporadas"]) != int(b["temporadas"]):
			return int(a["temporadas"]) > int(b["temporadas"])
		return (a["jugador"] as Jugador).id < (b["jugador"] as Jugador).id)
	if tope > 0 and filas.size() > tope:
		filas.resize(tope)
	return filas

## Ids a jugadores en UNA pasada por el mundo. Buscar cada id por separado sería
## recorrer los miles de jugadores dieciocho veces: es exactamente el error que
## le costó al HTML el 93% de su tiempo de ejecución con `plantelDe()`.
func _resolver(ids: Array[String]) -> Array[Jugador]:
	var salida: Array[Jugador] = []
	var m := _mundo()
	if m == null or ids.is_empty():
		return salida
	var quiero := {}
	for id in ids:
		quiero[id] = null
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if quiero.has(j.id):
				quiero[j.id] = j
	for id in ids:
		var j: Jugador = quiero[id]
		if j != null:
			salida.append(j)
	return salida

# ---------------------------------------------------------------------------
#  CIERRE DE TEMPORADA
# ---------------------------------------------------------------------------

## Todo lo que la selección hace al acabar el año, en el orden del HTML.
##
## OJO: hay que llamarlo ANTES de volver a sortear los torneos continentales. El
## Mundial de Clubes lo juegan los campeones de ESTA temporada, y si el sorteo
## nuevo ya pasó, `Mundo.continentales` tiene ocho torneos sin campeón y el
## Mundial de Clubes se queda sin participantes en silencio.
func cierre_de_temporada(anio: int) -> Dictionary:
	var resumen := {}
	residencias()
	resumen["torneo"] = torneo_continental(anio)
	resumen["clubes"] = mundial_de_clubes(anio)
	resumen["mundial"] = copa_del_mundo(anio) if toca_copa_del_mundo(anio) else {}
	return resumen

## Residencia de los extranjeros: cada temporada jugando en el país suma, y a las
## cuatro se les puede tramitar el pasaporte. Cambiar de país la reinicia — es lo
## que hace que un extranjero al que cedes fuera pierda el camino andado.
func residencias() -> void:
	var m := _mundo()
	if m == null:
		return
	var p := pais_seleccion()
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if elegible(j, p):
				continue
			if c.pais != p:
				_residencia.erase(j.id)
				continue
			var n := temporadas_en_el_pais(j) + 1
			_residencia[j.id] = n
			if n == TEMPORADAS_PARA_NACIONALIZAR and c.id == m.mi_club_id:
				noticia.emit("Puede nacionalizarse: " + j.nombre,
					"%s cumple %d temporadas jugando en el país. Desde su ficha puedes tramitar la nacionalización deportiva y habilitarlo con la selección."
					% [j.nombre, TEMPORADAS_PARA_NACIONALIZAR])

## El torneo continental de selecciones del verano: Copa América, Eurocopa, Copa
## África, Copa de Asia, Copa Oro o Copa de Oceanía, según dónde dirijas.
##
## Cada dos años, los pares. Y no se juega: se SORTEA el puesto con una bolsa
## sesgada, igual que en el HTML. Es una decisión de diseño, no una pieza a
## medio hacer: la selección no tiene plantilla ni rivales con plantilla, así que
## un cuadro de verdad sería un torneo inventado entre nombres. Lo que sí es real
## es la consecuencia: si sale campeón, tus internacionales vuelven en una nube y
## se les nota en la moral.
func torneo_continental(anio: int) -> Dictionary:
	if anio % 2 != 0:
		return {}
	var puesto := int(Azar.uno(BOLSA_PUESTOS))
	var clave := Continental.confed_de(pais_seleccion())
	var torneo := String(TORNEO_POR_CONFED.get(clave, "Copa América"))
	var sel := nombre_seleccion()
	_anotar_resultado("%s %d: %s %s" % [torneo, anio, sel, PUESTOS_TORNEO[puesto]])
	noticia.emit("%s: %s %s" % [torneo, sel, PUESTOS_TORNEO[puesto]],
		"¡Título continental! Tus seleccionados vuelven en una nube." if puesto == 0
		else "Cierra el torneo de selecciones del verano.")
	if puesto == 0:
		for j in convocados():
			j.moral = clampi(j.moral + MORAL_TITULO_CONTINENTAL, 10, 99)
	torneo_de_selecciones.emit(torneo, puesto)
	return {"torneo": torneo, "puesto": puesto, "seleccion": sel, "anio": anio}

func toca_copa_del_mundo(anio: int) -> bool:
	return (anio - ANIO_BASE) % CICLO_MUNDIAL == RESTO_MUNDIAL

## La Copa del Mundo, cada cuatro años: 32 selecciones a eliminación directa.
##
## POR QUÉ ESTA ELIMINATORIA NO PASA POR `Copa`: `Copa` hace jugar `Partido`
## entre `Club`, y aquí los participantes son nombres de países que no tienen
## plantilla, ni estadio, ni saldo. No hay nada que hacer jugar. El duelo es una
## comparación de fuerzas con ±9 de ruido, tal cual el HTML, y ocupa seis líneas:
## montar clubes falsos para poder reutilizar la copa sería mucho peor negocio.
##
## Lo que sí es real es lo que le pasa a TU plantel. Van tus seis mejores —los
## convoca su propio país, no el tuyo, por eso da igual que sean elegibles— y
## vuelven con más media y más caros, o rotos.
func copa_del_mundo(anio: int) -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	var vivos: Array = []
	for n: String in _tabla_selecciones():
		vivos.append(_txt(n))
	if vivos.size() < 2:
		return {}
	Azar.barajar(vivos)
	if vivos.size() > PLAZAS_COPA_DEL_MUNDO:
		vivos.resize(PLAZAS_COPA_DEL_MUNDO)
	while vivos.size() > 1:
		var siguiente: Array = []
		for i in range(0, vivos.size(), 2):
			var a := String(vivos[i])
			if i + 1 >= vivos.size():
				siguiente.append(a)      ## impar: el último pasa sin jugar
				continue
			var b := String(vivos[i + 1])
			var fa := fuerza(a) + Azar.ent(-RUIDO_DUELO, RUIDO_DUELO)
			var fb := fuerza(b) + Azar.ent(-RUIDO_DUELO, RUIDO_DUELO)
			siguiente.append(a if fa >= fb else b)
		vivos = siguiente
	var campeon := String(vivos[0])
	mundial = {"anio": anio, "campeon": campeon}

	var mios := _mejores_del_plantel(m, 6)
	var nombres: Array[String] = []
	for j in mios:
		nombres.append("%s (%s)" % [j.nombre, j.pais])
	noticia.emit("🏆 MUNDIAL %d: campeón %s" % [anio, campeon],
		"Se jugó la Copa del Mundo. %s levantó el trofeo. " % campeon
		+ ("De tu plantel fueron convocados: %s." % ", ".join(nombres) if not nombres.is_empty() else "Ningún jugador tuyo fue convocado."))
	for j in mios:
		_vitrina_mundialista(j, anio)
	copa_del_mundo_jugada.emit(anio, campeon)
	return {"anio": anio, "campeon": campeon, "convocados": mios}

## Lo que se lleva de vuelta el que jugó un Mundial: escaparate, desgaste y,
## uno de cada cuatro, una lesión. El orden importa: primero sube, después se
## rompe, y el físico se descuenta siempre. Así el que vuelve lesionado vuelve
## además revalorizado, que es exactamente la frustración que se busca.
func _vitrina_mundialista(j: Jugador, anio: int) -> void:
	var m := _mundo()
	if Azar.suerte(PROB_VITRINA):
		var d := Azar.ent(1, 3)
		j.ajustar_media(d)
		_caps[j.id] = caps_de(j) + Azar.ent(3, 7)
		noticia.emit("🌍 Vitrina mundialista: " + j.nombre,
			"Jugó el Mundial y volvió con %d punto(s) de media más. Su valor de mercado se disparó: espera ofertas." % d)
	if Azar.suerte(PROB_LESION_MUNDIAL):
		var sem := 0
		if m != null and m.medico != null:
			sem = m.medico.lesionar(j, Medico.MEDIA, "en el Mundial", anio, 0)
		else:
			sem = Azar.ent(1, 4)
			j.lesionar(sem)
		if sem > 0:
			noticia.emit("Vuelve tocado del Mundial",
				"🩹 %s llega lesionado de la Copa (%d sem)." % [j.nombre, sem])
			vuelve_tocado.emit(j, sem, false)
	j.fisico = clampi(j.fisico - Azar.ent(10, 25), 10, 100)

func _mejores_del_plantel(m: Mundo, cuantos: int) -> Array[Jugador]:
	var mio := m.mi_club()
	if mio == null:
		return []
	var lista := mio.plantilla.duplicate()
	lista.sort_custom(_mejor_media)
	if lista.size() > cuantos:
		lista.resize(cuantos)
	return lista

# ---------------------------------------------------------------------------
#  EL MUNDIAL DE CLUBES
# ---------------------------------------------------------------------------

## Corona a los campeones continentales del año y los hace jugar entre ellos.
##
## Ya no es una lista inventada, como decía el propio HTML: lo disputan los
## campeones REALES de las seis confederaciones que sortea `Continental`, y si el
## tuyo está ahí, lo juegas de verdad. La lista de confederaciones sale de
## `Continental.PRINCIPALES` y no se vuelve a escribir aquí: son las mismas seis
## copas grandes, y la segunda copa de un continente (Sudamericana, Europa
## League) no da plaza.
func mundial_de_clubes(anio: int) -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	var campeones: Array[Club] = []
	var lineas: Array[String] = []
	for k: String in Continental.PRINCIPALES:
		var t: Continental = m.continentales.get(k)
		if t == null or t.campeon == null:
			continue
		campeones.append(t.campeon)
		var nombre_torneo := Continental.nombre_conti(k)
		lineas.append("%s: %s" % [nombre_torneo, t.campeon.nombre])
		campeones_continentales.push_front({
			"torneo": nombre_torneo, "campeon": t.campeon.nombre,
			"club_id": t.campeon.id, "clave": k, "anio": anio,
		})
	while campeones_continentales.size() > MAX_CAMPEONES_GUARDADOS:
		campeones_continentales.remove_at(campeones_continentales.size() - 1)
	if not lineas.is_empty():
		noticia.emit("🌍 Campeones continentales %d" % anio,
			" · ".join(lineas) + ". Todos ellos disputan el Mundial de Clubes.")
	if campeones.size() < 2:
		mundial_clubes = {}
		return {}

	var torneo := MundialClubes.new()
	torneo.preparar(campeones)
	var mio := m.mi_club()
	var entro := torneo.participa(mio)
	var relato: Array[String] = []
	while torneo.en_curso():
		for r: Dictionary in torneo.jugar_ronda():
			if r["local"] != mio and r["visita"] != mio:
				continue
			var l: Club = r["local"]
			var v: Club = r["visita"]
			var penales: Array = r.get("penales", [])
			relato.append("%s: %s %d-%d %s%s" % [
				r["ronda"], l.nombre, int(r["gl"]), int(r["gv"]), v.nombre,
				(" (pen %d-%d)" % [int(penales[0]), int(penales[1])]) if penales.size() == 2 else "",
			])
	var campeon: Club = torneo.campeon
	if campeon == null:
		mundial_clubes = {}
		return {}

	var eres_tu := mio != null and campeon == mio
	mundial_clubes = {
		"anio": anio, "campeon": campeon.nombre, "club_id": campeon.id,
		"mio": eres_tu, "relato": relato,
	}
	if eres_tu:
		## El premio ya lo cobró el club dentro del torneo. Aquí solo queda lo que
		## no es dinero: la vitrina de la carrera y el prestigio. `sumar_trofeo`
		## ya suma 3 de prestigio, así que se completan los 10 del HTML con 7.
		if m.roles != null:
			m.roles.sumar_trofeo("Mundial de Clubes")
			m.roles.sumar_prestigio(PRESTIGIO_MUNDIAL_CLUBES - 3)
		noticia.emit("🏆🌍 ¡CAMPEONES DEL MUNDO!",
			"Ganaste el Mundial de Clubes %d.\n\n%s\n\nNo hay techo por encima de esto: tu club entra en la historia grande del fútbol mundial."
			% [anio, "\n".join(relato)])
	else:
		noticia.emit("🌍 Mundial de Clubes %d" % anio,
			"Lo ganó %s (%s)." % [campeon.nombre, campeon.pais]
			+ ("\n\nTu camino:\n" + "\n".join(relato) if entro and not relato.is_empty() else ""))
	mundial_de_clubes_jugado.emit(anio, campeon, eres_tu)
	return mundial_clubes.duplicate()

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

# ---------------------------------------------------------------------------
#  GUARDAR
# ---------------------------------------------------------------------------

## Los diccionarios por jugador se guardan enteros porque son pequeños de verdad:
## solo tienen fila los que han sido internacionales o llevan residencia. En un
## mundo de miles de jugadores la inmensa mayoría no aparece nunca, que es la
## misma razón por la que `Medico` guarda solo las fichas con algo dentro.
func a_dic() -> Dictionary:
	return {
		"pre": prenomina_ids,
		"nomina": nomina_ids,
		"resultados": resultados,
		"caps": _caps,
		"racha": _racha,
		"nacionalizados": _nacionalizados,
		"residencia": _residencia,
		"descanso": _descanso.keys(),
		"mundial": mundial,
		"mundial_clubes": mundial_clubes,
		"continentales": campeones_continentales,
	}

func desde_dic(d: Dictionary) -> void:
	prenomina_ids = _ids(d.get("pre", []))
	nomina_ids = _ids(d.get("nomina", []))
	resultados = _ids(d.get("resultados", []))
	_caps = d.get("caps", {}).duplicate()
	_racha = d.get("racha", {}).duplicate()
	_nacionalizados = d.get("nacionalizados", {}).duplicate()
	_residencia = d.get("residencia", {}).duplicate()
	_descanso.clear()
	for id in d.get("descanso", []):
		_descanso[String(id)] = true
	mundial = d.get("mundial", {}).duplicate()
	mundial_clubes = d.get("mundial_clubes", {}).duplicate()
	campeones_continentales.clear()
	for f in d.get("continentales", []):
		campeones_continentales.append((f as Dictionary).duplicate())

## El JSON devuelve arrays sin tipo y estos campos son `Array[String]`: asignar
## el crudo revienta al guardar la partida siguiente.
static func _ids(crudo: Variant) -> Array[String]:
	var salida: Array[String] = []
	if crudo is Array:
		for x in crudo:
			salida.append(String(x))
	return salida

func _to_string() -> String:
	return "Selección de %s (fuerza %d)" % [nombre_seleccion(), fuerza(nombre_seleccion())]
