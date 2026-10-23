extends RefCounted
## (Parte 1 de 9 de `ciudad_expansion.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `ciudad_expansion.gd`, conserva la clase.)

## LA CIUDAD GRANDE (7-10-2026). Pedido: «agrandar mínimo por 4 la ciudad…
## carreteras y a futuro metro subterráneo funcional… considera que la ciudad
## será utilizable: conducir, caminar, interactuar con NPC… que el transporte
## público esté bien, que las calles tengan sentido».
##
## Hasta hoy el mapa jugable medía unos 1.200 m de lado: el recinto del club,
## dos anillos de calles y campo hasta el horizonte. Aquí se levanta la ciudad
## que lo rodea hasta ±1.320 m (2.640 m de lado: CINCO veces la superficie de
## antes), y se hace pensando en que algún día se recorra:
##
##  · TODO SALE DE UNA RED VIAL EN DATOS (`nodos` + `tramos`): una rejilla de
##    110 m con avenidas de 4 carriles cada tres calles, un bulevar que rodea
##    el núcleo del club y conectores que lo unen a los anillos de dentro.
##    Las calles, las aceras, los semáforos, el tráfico, los peatones, los
##    autobuses y el metro leen esa misma red: el día que haya un modo a pie o
##    al volante, el grafo ya está (`camino_entre` lo recorre).
##  · ZONAS CON SENTIDO: centro de torres al norte (frente al club), comercio y
##    oficinas al este, viviendas con jardín al sur, industria y puerto al
##    oeste del río, el río con sus paseos y puentes, parques repartidos.
##  · LA CIUDAD QUE UNA CIUDAD NECESITA: ayuntamiento y plaza mayor, estación
##    central, hospital, comisaría, bomberos, escuela, instituto, universidad,
##    mercado, centro comercial, gasolineras, cine, cocheras de autobuses,
##    puerto y un parque con lago.
##  · SEMÁFOROS QUE FUNCIONAN: en cada cruce de avenida, con su ciclo (verde,
##    ámbar, rojo) por ejes; los coches FRENAN en rojo (`TraficoCiudad`).
##  · TRANSPORTE PÚBLICO: dos líneas de autobús con marquesinas, que paran de
##    verdad, y dos líneas de METRO subterráneo con sus estaciones (bocas con
##    escalera y la «M») ya trazadas en datos para hacerlo funcional después.
##  · LUCES DE COLORES: guirnaldas sobre las calles del centro que se
##    encienden de noche.

const CELDA := 110.0
const K := 12                       ## rejilla de -12 a 12 → ±1.320 m
const NUC_X0 := -550.0              ## el núcleo (club, anillos, barrio, karting)
const NUC_X1 := 440.0
const NUC_Z0 := -440.0
const NUC_Z1 := 660.0
const ANCHO_AV := 24.0
const ANCHO_CALLE := 14.0
const ACERA := 4.0
const RIO_MEDIO := 50.0             ## medio ancho del río con sus orillas
const LEJOS := 980.0                ## más allá, edificios baratos (MultiMesh)
const PUENTE_ALTO := 4.2            ## el bote pasa por debajo
## LA CASA GRANDE (7-10-2026): finca de 2x2 manzanas al sur del barrio, sin
## calles por dentro, rodeada por un seto, con portón al bulevar.
const FINCA_GRANDE := Rect2(-220.0, 660.0, 220.0, 220.0)

## Las parcelas especiales: [celda, uso].
const ESPECIALES := {
	Vector2i(-2, 6): "casa_grande", Vector2i(-1, 6): "casa_grande", Vector2i(-2, 7): "casa_grande", Vector2i(-1, 7): "casa_grande",
	Vector2i(1, 8): "escuela",
	Vector2i(-1, -5): "plaza_mayor", Vector2i(0, -5): "ayuntamiento", Vector2i(1, -5): "estacion_central",
	Vector2i(-2, -6): "mercado", Vector2i(2, -7): "cine", Vector2i(5, -1): "hospital",
	Vector2i(5, 1): "comisaria", Vector2i(6, 1): "bomberos",
	Vector2i(2, 7): "instituto", Vector2i(4, 9): "universidad", Vector2i(0, 8): "parque_lago",
	Vector2i(-1, 8): "parque", Vector2i(7, -3): "centro_comercial", Vector2i(-5, -6): "puerto",
	Vector2i(-9, 5): "cocheras", Vector2i(3, -8): "gasolinera", Vector2i(8, 6): "gasolinera",
	Vector2i(-7, -2): "gasolinera", Vector2i(-6, 3): "parque", Vector2i(9, -6): "parque",
	Vector2i(6, 4): "parque", Vector2i(-3, -9): "parque",
	Vector2i(4, 8): "villa_moderna", Vector2i(-8, 1): "desguace", Vector2i(-2, 9): "granja",
	## El parque de atracciones (16-10-2026), junto a la universidad, en las afueras.
	Vector2i(5, 9): "feria",
}

var b: CityBuilder
var nodos := {}            ## Vector2i -> Vector3
var tramos: Array = []     ## {a: Vector3, b: Vector3, av: bool, puente: bool, ancho: float}
var vecinos := {}          ## Vector2i -> Array[Vector2i] (el grafo, para recorrerlo)
var cruces_semaforo: Array = []    ## [Vector3]
## Rótulos de comercio puestos: {pos, ancho, texto}. `ExploradorCiudad.edificio_en`
## los usa para que al entrar por esa puerta la sala sea la del rótulo.
var rotulos: Array = []
var bloques: Array = []    ## {rect: Rect2, celda: Vector2i, zona: String, uso: String}
var lineas_metro: Array = []       ## [{nombre, color, estaciones: [Vector3]}]
var lineas_bus: Array = []         ## [{nombre, puntos: PackedVector3Array, paradas: [Vector3]}]
var semaforos: Semaforos
var metro: MetroCiudad
var cuenta := {}           ## lo que se levantó, para las pruebas y el rótulo

var _rng := RandomNumberGenerator.new()
var _comercial: Array[PackedScene] = []
var _naves: Array[PackedScene] = []
var _altos: Array[PackedScene] = []
var _mat := {}

## Arma el grafo: rejilla, bulevar del núcleo y conectores a los anillos.
## LOS NOMBRES DE LAS CALLES (7-10-2026, «las calles deben tener nombre, los
## parques también»). Ficticios, como toda la ciudad. Las filas (de oeste a
## este, z fija) y las columnas (de norte a sur, x fija) tienen cada una el
## suyo; una de cada tres es avenida.
const NOMBRES_EO := ["de los Almendros", "del Rocío", "de la Alameda", "del Mirador", "de las Acacias", "de la Ribera",
	"del Olivar", "de los Tilos", "de la Fragua", "del Pósito", "de las Moreras", "de la Estación", "Mayor",
	"del Sol", "de los Naranjos", "del Molino", "de la Vega", "de las Huertas", "del Carmen", "de los Arcos",
	"del Lucero", "de la Cantera", "de los Jazmines", "del Prado", "de la Muralla"]
const NOMBRES_NS := ["de los Tejedores", "del Puerto", "de la Cordelería", "de los Plateros", "del Faro", "de la Imprenta",
	"de los Herreros", "del Telégrafo", "de la Seda", "del Navegante", "de los Alfareros", "de la Libertad", "del Estadio",
	"de la Constitución", "de los Canteranos", "del Reloj", "de la Ilustración", "de los Remeros", "del Campeonato",
	"de las Artes", "de la Hinchada", "del Gol", "de los Fundadores", "del Ensanche", "de la Afición"]
const NOMBRES_PARQUE := ["Parque de la Alameda", "Jardines del Mirador", "Parque de los Tilos", "Parque de la Ribera",
	"Parque de los Fundadores", "Jardín Botánico", "Parque del Reloj", "Parque de la Afición", "Pinar del Ensanche"]

## LOS BRAZOS DE CADA CRUCE (16-10-2026). Hasta hoy cada tramo se dibujaba
## mirando solo su propio ancho: las líneas del centro entraban en el cruce y
## pisaban la cebra, las aceras de una calle se metían 5 m en la calzada de la
## avenida que cruzaba y las esquinas entre dos avenidas quedaban sin acera.
## Aquí se anota, por cruce, qué calles salen y de qué ancho: [+X, -X, +Z, -Z].
var brazos := {}
var _con_semaforo := {}
var _punta_puente := {}     ## cruce -> {índice del brazo que es puente: true}

## Desde el centro de un cruce con semáforo: dónde empieza la cebra, cuánto
## mide y dónde va la línea de detención (todo a partir del borde de la calle
## que cruza). Los coches paran DETRÁS de la línea, nunca encima de la cebra.
const CEBRA_HUECO := 1.0
const CEBRA_LARGO := 3.2
const LINEA_DETENCION := 1.0

var _puentes_hechos := {}

## EL PUENTE MÁS BONITO (7-10-2026, «el puente puede quedar más bonito»):
## arcos de piedra entre los pilares, tajamares, cornisa, balaustrada de
## columnillas, aceras sobre el tablero, farolas de forja con banderolas del
## club, pilonos en las cuatro esquinas con el nombre del puente y una fila de
## luces bajo el tablero que se ve de noche.
const NOMBRES_PUENTE := ["Puente de Piedra", "Puente de la Ribera", "Puente del Centenario", "Puente de los Remeros",
	"Puente Nuevo", "Puente del Molino", "Puente de la Afición", "Puente Real", "Puente del Carmen"]

## DETALLE DE EDIFICIO (etapa 4, 12-10-2026). El kit trae fachadas planas: sin
## zócalo, sin cornisa y con la azotea vacía, y desde la calle se leen como
## cajas. Se les pone, con cajas sueltas -que luego `Optimizar.agrupar` junta
## en un MultiMesh, así que casi no cuestan-: un ZÓCALO oscuro y gastado en la
## base, una CORNISA con parapeto arriba y, en la azotea, equipos de aire,
## un depósito y una caseta de escalera. El azar sale de la posición, NO de
## `_rng`, para no mover ni un edificio de sitio.
var _mats_det := {}

## LOS COMERCIOS (7-10-2026, «agrega cosas que tiene una ciudad real»): un
## rótulo sobre la planta baja de las fachadas que dan a la calle. La farmacia
## lleva su cruz verde encendida.
const COMERCIOS := [["💊 Farmacia", Color(0.1, 0.55, 0.25)], ["☕ Cafetería", Color(0.45, 0.28, 0.18)],
	["🥖 Panadería", Color(0.8, 0.55, 0.2)], ["🏦 Banco", Color(0.1, 0.25, 0.5)], ["📮 Correos", Color(0.95, 0.75, 0.1)],
	["💈 Peluquería", Color(0.75, 0.15, 0.2)], ["📚 Librería", Color(0.3, 0.2, 0.45)], ["🛒 Supermercado", Color(0.85, 0.3, 0.1)],
	["🍕 Pizzería", Color(0.75, 0.2, 0.1)], ["🏨 Hotel", Color(0.15, 0.15, 0.2)], ["👟 Deportes", Color(0.2, 0.45, 0.75)],
	["🍺 Bar", Color(0.55, 0.2, 0.15)], ["🌸 Floristería", Color(0.85, 0.4, 0.6)], ["🔑 Ferretería", Color(0.4, 0.4, 0.42)],
	["⚽ Peña del club", Color(0.2, 0.5, 0.3)], ["🍦 Heladería", Color(0.4, 0.75, 0.85)]]

## Viviendas con jardín: se guardan y se dibujan todas juntas (MultiMesh).
## CASAS DE KENNEY (15-10-2026, «a ese nivel debe estar todo en la ciudad»): el
## City Kit Suburban en lugar de las cajas. Se registran en `_casas` y se dibujan
## en `_casas_multimesh`, un MultiMesh por modelo con `casa_kenney.gdshader`. Si los
## modelos no cargan, se dibujan las cajas de antes.
const MODELOS_CASA := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u"]
const ESCALA_CASA := 5.6
var _kenney_casas: Array = []
var _casas_t: Array[Transform3D] = []
var _casas_col: Array[Color] = []
var _techos_t: Array[Transform3D] = []
var _techos_col: Array[Color] = []
var _setos_t: Array[Transform3D] = []
var _puertas_t: Array[Transform3D] = []
var _vidrios_t: Array[Transform3D] = []
var _marcos_t: Array[Transform3D] = []
var _chimeneas_t: Array[Transform3D] = []
var _buzones_t: Array[Transform3D] = []
var _caminos_t: Array[Transform3D] = []
## Fachadas de colores (7-10-2026, «haz que algunas casas sean de diferentes
## colores»): de las claras de siempre a terracota, ocre, azul, menta, rosa y lila.
const COLORES_CASA := [Color(0.93, 0.89, 0.8), Color(0.86, 0.78, 0.66), Color(0.95, 0.95, 0.93),
	Color(0.85, 0.52, 0.38), Color(0.9, 0.74, 0.42), Color(0.6, 0.72, 0.85), Color(0.66, 0.82, 0.7),
	Color(0.93, 0.7, 0.68), Color(0.76, 0.68, 0.84), Color(0.98, 0.88, 0.55), Color(0.55, 0.62, 0.55)]

const APELLIDOS := ["Ortega", "Salas", "Núñez", "Ibarra", "Campos", "Rivas", "Lagos", "Vidal", "Peña", "Soto", "Carrasco", "Herrera", "Molina", "Aguirre", "Duarte", "Bravo", "Rojas", "Marín", "Leal", "Pizarro"]


## DETALLE DE CASA (etapa 6, 13-10-2026). Todo son cajas con color propio que
## `_casas_multimesh` dibuja en UN MultiMesh. `lado` es hacia dónde da la
## fachada (+1 o -1 en Z).
var _det_t: Array[Transform3D] = []
var _det_c: Array[Color] = []

## Mallas de los kits de Kenney, cargadas una vez: {malla, caja}. Vacío si no hay.
var _mallas_kit := {}

# ============================================================================
#  BLOQUES DE PISOS MODULARES (16-10-2026)
# ============================================================================
## Pedido: «bloques de pisos modulares… que cada bloque sea distinto (alturas,
## colores, balcones), con puerta a la calle». Con el kit Modular Buildings de
## Kenney: cada pieza es un cubo de 1 × 0,62 × 1 (un piso) con la fachada en +Z.
## A ×4,8 → módulos de 4,8 m y pisos de 2,98 m. Cada bloque se arma pieza a pieza
## (fachada, laterales y trasera), con su número de módulos, de pisos, color de
## pared y de remates, toldos de los comercios y estilo de ventanas (balcones,
## alféizares, arcos, ventanales), todo sacado de la POSICIÓN (no de `_rng`).
## Se dibujan juntos, un MultiMesh por pieza (`_modular_multimesh`), con
## `bloque_modular.gdshader`, que tiñe la pared, los remates y los toldos de cada
## instancia y oscurece el cristal (el azul cielo del kit parecía de juguete).
const RUTA_MOD := "res://assets/kenney/edificios_modulares/"
const ESC_MOD := 4.8
const PISO_MOD := 0.62 * ESC_MOD
## [pared, remates] de cada bloque (sRGB).
const COLORES_PISOS := [
	[Color(0.84, 0.6, 0.45), Color(0.93, 0.9, 0.84)], [Color(0.93, 0.85, 0.66), Color(0.6, 0.56, 0.5)],
	[Color(0.78, 0.79, 0.8), Color(0.34, 0.35, 0.38)], [Color(0.95, 0.93, 0.88), Color(0.58, 0.4, 0.3)],
	[Color(0.7, 0.47, 0.38), Color(0.92, 0.88, 0.8)], [Color(0.66, 0.74, 0.68), Color(0.94, 0.93, 0.9)],
	[Color(0.9, 0.76, 0.6), Color(0.45, 0.36, 0.3)], [Color(0.62, 0.68, 0.8), Color(0.94, 0.94, 0.93)],
	[Color(0.93, 0.77, 0.7), Color(0.6, 0.34, 0.3)], [Color(0.98, 0.9, 0.62), Color(0.42, 0.4, 0.38)],
]
## Estilos de fachada: la pieza de los módulos pares y la de los impares.
const ESTILOS_MOD := [
	["building-windows-sills", "building-windows-sills"],
	["building-window-balcony", "building-window-sill"],
	["building-windows-sills-round", "building-windows-round"],
	["building-window-wide-sill", "building-window-wide-sill"],
	["building-window-balcony", "building-window-balcony"],
	["building-window-sill", "building-window-large"],
	["building-windows-sills", "building-window-balcony"],
]
## Planta baja: con comercios (toldos o escaparates) o de viviendas.
const PUERTAS_MOD := ["building-door-window", "building-window-door-window", "building-window-door-window-round", "building-door"]

var _mod_t := {}       ## ruta -> {t: Array[Transform3D], c: Array[Color], d: Array[Color]}
var _mod_cajas_t: Array[Transform3D] = []
## Las puertas de los bloques modulares: las farolas se apartan de ellas.
var _puertas_mod: Array[Vector3] = []
var _mod_cajas_c: Array[Color] = []

# ============================================================================
#  EL PARQUE DE ATRACCIONES (16-10-2026)
# ============================================================================
## Pedido: «parque de atracciones pequeño con montaña rusa, puestos, noria,
## vallas, entrada, en un solar libre coherente». En la manzana (5, 9), en las
## afueras junto a la universidad y frente a la avenida z = 990: entrada con el
## pórtico del Coaster Kit de Kenney y su taquilla, valla alrededor, paseo
## central con guirnaldas y puestos (comida, bebidas, información, aseos), la
## NORIA al noroeste, la sala de RECREATIVOS al noreste (se entra: su interior es
## `InteriorInstalacion._recreativos`, con el Mini Arcade) y la MONTAÑA RUSA
## en la mitad sur: un circuito cerrado de piezas de acero del kit (cuesta de
## subida, recta alta, curvas y bajada) sobre pilares, con su estación y un tren
## de tres vagones que da vueltas (animación con la velocidad de la caída).
## Nada usa `_rng`: el azar es de la posición.
const RUTA_FERIA := "res://assets/kenney/montana_rusa/"
const ESC_RUSA := 3.0      ## piezas de vía de 4 unidades → tramos de 12 m
const BASE_RUSA := 1.3     ## altura de la vía en la estación

var feria := {}            ## lo que se levantó (para las pruebas): centro, rect, puerta…

## LA MONTAÑA RUSA. El circuito, en unidades del kit y con `o` como origen
## (sale hacia +X del mundo): cuesta arriba dos tramos (+2 unidades = 6 m),
## recta alta, dos curvas, bajada de dos tramos, recta de la estación y dos
## curvas que cierran el óvalo. Mide 61 × 26 m.
const CIRCUITO_RUSA := ["sube", "sube", "recta", "curva", "curva", "baja", "baja", "recta", "curva", "curva"]

## POLÍGONO (15-10-2026): naves, contenedores y chimeneas del kit industrial de
## Kenney en lugar de la caja con dientes de sierra. Las llamadas a `_rng` son las
## mismas que antes (el resto de la ciudad no se mueve).
const NAVES := ["a", "c", "e", "f", "l", "m", "q", "r", "t"]
const RUTA_IND := "res://assets/kenney/industrial/"

## Giro de los puestos de feria para que el mostrador dé al paseo (+Z del parque).
const GIRO_PUESTO := PI   ## el mostrador del modelo mira a −Z (comprobado en captura)

## Guirnaldas de luces de colores sobre las calles del centro (se encienden
## de noche con `encender`).
var _bombillas: Array[StandardMaterial3D] = []

## LA CARRETERA DE KENNEY EN USO (14-10-2026, «usar la carretera»). El kit City
## Kit Roads (CC0, `assets/ciudad/kenney_roads/`) son piezas de 1 unidad: aquí se
## amplían (×12) y se usan las que le faltaban a la calle: postes de luz con
## cable en las calles de barrio, brazos de farola curva en las avenidas,
## carteles colgantes en los cruces con semáforo y las vallas, luces y conos de
## las obras. Un generador de azar aparte: la ciudad no se mueve de sitio.
const KENNEY := "res://assets/ciudad/kenney_roads/"
const KENNEY_ESC := 12.0

var _kenney_cache := {}

## LAS FAROLAS de la ciudad grande: una cada ~33 m por acera, alternando
## lados. Sin luces de verdad (serían cientos): la cabeza se enciende y un
## charco de luz cálida en el suelo hace el resto, que es lo que se lee de
## noche desde la cámara del mapa.
var _farola_luz: StandardMaterial3D
var _farola_charco: StandardMaterial3D

var _farola_cono: ShaderMaterial = null

## Los edificios lejanos: cajas con ventanas en un solo MultiMesh.
var _lejanos: Array[Rect2] = []
## Manzanas que antes eran lejanas y ahora tienen otra cosa (la feria).
var _sin_lejano: Array[Rect2] = []

var _ventanas_lejanas: ShaderMaterial

## LOTES: las cajas planas que más se repiten (calzadas, aceras, solares,
## césped) se juntan por material en un MultiMesh cada una. Eran miles de
## nodos; así son cuatro.
var _lotes := {}

func _init(builder: CityBuilder) -> void:
	b = builder
	_rng.seed = 13072026

# ============================================================================
#  LA RED (datos)
# ============================================================================

static func dentro_nucleo(x: float, z: float, margen: float = 0.0) -> bool:
	return x > NUC_X0 + margen and x < NUC_X1 - margen and z > NUC_Z0 + margen and z < NUC_Z1 - margen

static func en_borde_nucleo(a: Vector3, c: Vector3) -> bool:
	var m := (a + c) * 0.5
	var en_x := m.x >= NUC_X0 - 1.0 and m.x <= NUC_X1 + 1.0
	var en_z := m.z >= NUC_Z0 - 1.0 and m.z <= NUC_Z1 + 1.0
	if absf(a.x - c.x) < 0.1:   ## vertical
		return (absf(a.x - NUC_X0) < 0.1 or absf(a.x - NUC_X1) < 0.1) and en_z
	return (absf(a.z - NUC_Z0) < 0.1 or absf(a.z - NUC_Z1) < 0.1) and en_x

func nombre_fila(j: int) -> String:
	return ("Avenida " if j % 3 == 0 else "Calle ") + String(NOMBRES_EO[clampi(j + K, 0, NOMBRES_EO.size() - 1)])

func nombre_columna(i: int) -> String:
	return ("Avenida " if i % 3 == 0 else "Calle ") + String(NOMBRES_NS[clampi(i + K, 0, NOMBRES_NS.size() - 1)])

## La calle en la que está un punto («Calle X», o «Calle X con Avenida Y» en
## un cruce). Vacío si no está sobre ninguna (dentro de una manzana).
func nombre_calle_en(p: Vector3) -> String:
	## El núcleo del club tiene sus propios viales (anillo, accesos).
	if dentro_nucleo(p.x, p.z, -1.0):
		return ""
	var i := roundi(p.x / CELDA)
	var j := roundi(p.z / CELDA)
	if absi(i) > K or absi(j) > K:
		return ""
	var dx := absf(p.x - float(i) * CELDA)
	var dz := absf(p.z - float(j) * CELDA)
	var en_col := dx < ((ANCHO_AV if i % 3 == 0 else ANCHO_CALLE) * 0.5 + ACERA)
	var en_fila := dz < ((ANCHO_AV if j % 3 == 0 else ANCHO_CALLE) * 0.5 + ACERA)
	if en_col and en_fila:
		return "%s con %s" % [nombre_fila(j), nombre_columna(i)]
	if en_col:
		return nombre_columna(i)
	if en_fila:
		return nombre_fila(j)
	return ""

static func _cruza_rio(a: Vector3, c: Vector3) -> bool:
	if absf(a.z - c.z) > 0.1:
		return false
	var x0 := minf(a.x, c.x)
	var x1 := maxf(a.x, c.x)
	return x0 < CityBuilder.RIO_X + 45.0 and x1 > CityBuilder.RIO_X - 45.0

func _tramo_rejilla(ka: Vector2i, kb: Vector2i, avenida: bool) -> void:
	var a: Vector3 = nodos[ka]
	var c: Vector3 = nodos[kb]
	var m := (a + c) * 0.5
	if FINCA_GRANDE.grow(-1.0).has_point(Vector2(m.x, m.z)):
		return
	var borde := en_borde_nucleo(a, c)
	if dentro_nucleo(m.x, m.z, -1.0) and not borde:
		return
	if dentro_nucleo(m.x, m.z, 1.0):
		return
	var av := avenida or borde
	tramos.append({"a": a, "b": c, "av": av, "puente": _cruza_rio(a, c),
		"ancho": ANCHO_AV if av else ANCHO_CALLE, "ka": ka, "kb": kb})
	if not vecinos.has(ka):
		vecinos[ka] = []
	if not vecinos.has(kb):
		vecinos[kb] = []
	(vecinos[ka] as Array).append(kb)
	(vecinos[kb] as Array).append(ka)

func _es_borde(p: Vector3) -> bool:
	return absf(p.x - NUC_X0) < 0.1 or absf(p.x - NUC_X1) < 0.1 or absf(p.z - NUC_Z0) < 0.1 or absf(p.z - NUC_Z1) < 0.1

static func clave_cruce(p: Vector3) -> Vector2i:
	return Vector2i(roundi(p.x), roundi(p.z))

static func _indice_brazo(d: Vector3) -> int:
	if absf(d.x) > absf(d.z):
		return 0 if d.x > 0.0 else 1
	return 2 if d.z > 0.0 else 3

func _sumar_brazo(p: Vector3, d: Vector3, ancho: float) -> void:
	var k := clave_cruce(p)
	if not brazos.has(k):
		brazos[k] = [0.0, 0.0, 0.0, 0.0]
	var i := _indice_brazo(d)
	brazos[k][i] = maxf(float(brazos[k][i]), ancho)

func _armar_brazos() -> void:
	brazos.clear()
	_con_semaforo.clear()
	_punta_puente.clear()
	for t: Dictionary in tramos:
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var d := (c - a).normalized()
		if bool(t["puente"]):
			for par: Array in [[a, d], [c, -d]]:
				var kp := clave_cruce(par[0])
				if not _punta_puente.has(kp):
					_punta_puente[kp] = {}
				_punta_puente[kp][_indice_brazo(par[1])] = true
		_sumar_brazo(a, d, float(t["ancho"]))
		_sumar_brazo(c, -d, float(t["ancho"]))
	for p: Vector3 in cruces_semaforo:
		_con_semaforo[clave_cruce(p)] = true
