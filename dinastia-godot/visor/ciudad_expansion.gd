class_name CiudadExpansion
extends RefCounted
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
}

var b: CityBuilder
var nodos := {}            ## Vector2i -> Vector3
var tramos: Array = []     ## {a: Vector3, b: Vector3, av: bool, puente: bool, ancho: float}
var vecinos := {}          ## Vector2i -> Array[Vector2i] (el grafo, para recorrerlo)
var cruces_semaforo: Array = []    ## [Vector3]
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

func armar_red() -> void:
	nodos.clear()
	tramos.clear()
	vecinos.clear()
	for i in range(-K, K + 1):
		for j in range(-K, K + 1):
			nodos[Vector2i(i, j)] = Vector3(float(i) * CELDA, 0, float(j) * CELDA)
	for i in range(-K, K + 1):
		for j in range(-K, K + 1):
			var a: Vector3 = nodos[Vector2i(i, j)]
			if i < K:
				_tramo_rejilla(Vector2i(i, j), Vector2i(i + 1, j), j % 3 == 0)
			if j < K:
				## Ninguna calle a lo largo del cauce del río.
				if absf(a.x - CityBuilder.RIO_X) >= RIO_MEDIO + 10.0:
					_tramo_rejilla(Vector2i(i, j), Vector2i(i, j + 1), i % 3 == 0)
	## Conectores con los anillos del núcleo (el tráfico entra y sale).
	for par: Array in [
			[Vector3(CityBuilder.RING_X + 187.0, 0, 0), Vector3(NUC_X1, 0, 0)],
			[Vector3(-CityBuilder.RING_X - 187.0, 0, 0), Vector3(NUC_X0, 0, 0)],
			[Vector3(330, 0, CityBuilder.EX_N), Vector3(330, 0, NUC_Z0)],
			[Vector3(-330, 0, CityBuilder.EX_N), Vector3(-330, 0, NUC_Z0)],
			[Vector3(330, 0, CityBuilder.EX_S), Vector3(330, 0, NUC_Z1)],
			[Vector3(-330, 0, CityBuilder.EX_S), Vector3(-330, 0, NUC_Z1)],
		]:
		var p0: Vector3 = par[0]
		var p1: Vector3 = par[1]
		tramos.append({"a": p0, "b": p1, "av": true, "puente": _cruza_rio(p0, p1),
			"ancho": ANCHO_AV, "conector": true})
	## Semáforos: cada cruce con al menos una avenida y tres o más brazos.
	cruces_semaforo.clear()
	for k: Vector2i in vecinos:
		var lista: Array = vecinos[k]
		if lista.size() < 3:
			continue
		var p: Vector3 = nodos[k]
		if dentro_nucleo(p.x, p.z, -1.0):
			continue
		if k.x % 3 == 0 or k.y % 3 == 0 or _es_borde(p):
			cruces_semaforo.append(p)
	cuenta["tramos"] = tramos.size()
	cuenta["semaforos"] = cruces_semaforo.size()

func _es_borde(p: Vector3) -> bool:
	return absf(p.x - NUC_X0) < 0.1 or absf(p.x - NUC_X1) < 0.1 or absf(p.z - NUC_Z0) < 0.1 or absf(p.z - NUC_Z1) < 0.1

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

static func _cruza_rio(a: Vector3, c: Vector3) -> bool:
	if absf(a.z - c.z) > 0.1:
		return false
	var x0 := minf(a.x, c.x)
	var x1 := maxf(a.x, c.x)
	return x0 < CityBuilder.RIO_X + 45.0 and x1 > CityBuilder.RIO_X - 45.0

## El camino más corto entre dos cruces de la rejilla (BFS sobre el grafo):
## la base para que un NPC, un coche o el jugador vayan de un sitio a otro.
func camino_entre(desde: Vector2i, hasta: Vector2i) -> Array:
	if not vecinos.has(desde) or not vecinos.has(hasta):
		return []
	var previo := {desde: desde}
	var cola: Array = [desde]
	while not cola.is_empty():
		var k: Vector2i = cola.pop_front()
		if k == hasta:
			break
		for v: Vector2i in vecinos[k]:
			if not previo.has(v):
				previo[v] = k
				cola.append(v)
	if not previo.has(hasta):
		return []
	var camino: Array = [hasta]
	var k2: Vector2i = hasta
	while k2 != desde:
		k2 = previo[k2]
		camino.push_front(k2)
	return camino

## Uso y zona de cada manzana.
func armar_bloques() -> void:
	bloques.clear()
	for i in range(-K, K):
		for j in range(-K, K):
			var x0 := float(i) * CELDA
			var z0 := float(j) * CELDA
			var c := Vector2(x0 + CELDA * 0.5, z0 + CELDA * 0.5)
			if dentro_nucleo(c.x, c.y):
				continue
			var medio_av := ANCHO_AV * 0.5 + ACERA
			var medio_c := ANCHO_CALLE * 0.5 + ACERA
			var izq := medio_av if i % 3 == 0 or absf(x0 - NUC_X1) < 0.1 else medio_c
			var der := medio_av if (i + 1) % 3 == 0 or absf(x0 + CELDA - NUC_X0) < 0.1 else medio_c
			var arr := medio_av if j % 3 == 0 or absf(z0 - NUC_Z1) < 0.1 else medio_c
			var aba := medio_av if (j + 1) % 3 == 0 or absf(z0 + CELDA - NUC_Z0) < 0.1 else medio_c
			var r := Rect2(x0 + izq, z0 + arr, CELDA - izq - der, CELDA - arr - aba)
			var celda := Vector2i(i, j)
			var uso := ""
			var zona := _zona(c)
			if r.position.x < CityBuilder.RIO_X + RIO_MEDIO and r.end.x > CityBuilder.RIO_X - RIO_MEDIO:
				uso = "puerto" if ESPECIALES.get(celda, "") == "puerto" else "rio"
			elif ESPECIALES.has(celda):
				uso = String(ESPECIALES[celda])
			else:
				uso = _uso_de_zona(zona, c)
			bloques.append({"rect": r, "celda": celda, "zona": zona, "uso": uso})
	cuenta["manzanas"] = bloques.size()

func _zona(c: Vector2) -> String:
	if c.x < CityBuilder.RIO_X - RIO_MEDIO:
		return "oeste"
	if c.y < NUC_Z0 and absf(c.x) < 700.0:
		return "centro"
	if c.x > NUC_X1:
		return "este"
	if c.y > NUC_Z1:
		return "sur"
	return "norte"

func _uso_de_zona(zona: String, c: Vector2) -> String:
	var lejos := maxf(absf(c.x), absf(c.y)) > LEJOS
	match zona:
		"centro":
			if absf(c.x) < 340.0 and c.y > -1000.0:
				return "torres"
			return "lejano" if lejos else "comercial"
		"este":
			if lejos:
				return "lejano"
			return "comercial" if c.x < 800.0 else "pisos"
		"sur":
			return "casas"
		"oeste":
			return "industrial" if c.y > -700.0 and c.y < 700.0 else ("lejano" if lejos else "pisos")
		_:
			return "lejano" if lejos else "pisos"

## Dos líneas de metro (en datos: estaciones en cruces) y dos de autobús.
func armar_transporte() -> void:
	## Mismas líneas que dibuja y mueve `MetroCiudad`: la 1 elevada por la
	## avenida x = 660 y la 2 subterránea bajo z = -660 (transbordo en el cruce).
	var l1: Array = []
	var l2: Array = []
	for k in [-9, -6, -3, 0, 3, 6, 9]:
		l1.append(Vector3(6.0 * CELDA, 0, float(k) * CELDA))
		l2.append(Vector3(float(k) * CELDA, 0, -6.0 * CELDA))
	lineas_metro = [
		{"nombre": "Línea 1", "color": Color(0.85, 0.15, 0.15), "estaciones": l1, "elevada": true},
		{"nombre": "Línea 2", "color": Color(0.15, 0.4, 0.9), "estaciones": l2, "elevada": false},
	]
	## Autobuses: recorridos cerrados por avenidas, por el carril derecho.
	lineas_bus = [
		_linea_bus("Bus 10", [Vector2(NUC_X0, NUC_Z0), Vector2(NUC_X1, NUC_Z0), Vector2(NUC_X1, NUC_Z1), Vector2(NUC_X0, NUC_Z1)]),
		_linea_bus("Bus 22", [Vector2(-660, -990), Vector2(990, -990), Vector2(990, 990), Vector2(-660, 990)]),
	]

func _linea_bus(nombre: String, esquinas: Array) -> Dictionary:
	var pts := PackedVector3Array()
	var carril := ANCHO_AV * 0.25
	for e: Vector2 in esquinas:
		pts.append(Vector3(e.x, 0.3, e.y))
	## Desplazado al carril derecho (sentido horario visto desde arriba).
	var n := pts.size()
	var sal := PackedVector3Array()
	for k in n:
		var prev := pts[(k - 1 + n) % n]
		var act := pts[k]
		var sig := pts[(k + 1) % n]
		var d1 := (act - prev).normalized()
		var d2 := (sig - act).normalized()
		var off := (Vector3(-d1.z, 0, d1.x) + Vector3(-d2.z, 0, d2.x)).normalized() * carril
		sal.append(act + off)
	var paradas: Array = []
	for k in n:
		var a := sal[k]
		var c := sal[(k + 1) % n]
		var largo := a.distance_to(c)
		var cuantas := int(largo / 330.0)
		for q in range(1, cuantas + 1):
			paradas.append(a.lerp(c, float(q) / float(cuantas + 1)))
	return {"nombre": nombre, "puntos": sal, "paradas": paradas}

# ============================================================================
#  EL DIBUJO
# ============================================================================

func construir() -> void:
	armar_red()
	armar_bloques()
	armar_transporte()
	_cargar_modelos()
	_materiales()
	_dibujar_calles()
	semaforos = Semaforos.new()
	semaforos.name = "Semaforos"
	b.add_child(semaforos)
	semaforos.montar(cruces_semaforo, self)
	cuenta["edificios"] = 0
	for bl: Dictionary in bloques:
		_dibujar_bloque(bl)
	_edificios_lejanos()
	_casas_multimesh()
	metro = MetroCiudad.new()
	metro.name = "Metro"
	b.add_child(metro)
	metro.montar(self)
	_bocas_metro()
	_marquesinas_bus()
	_guirnaldas()
	_farolas()
	_mobiliario_urbano()
	_placas_de_calle()
	_orillas_nucleo()
	_obras_en_calle()
	cuenta["autopista"] = Autopista.montar(b)
	_parque_eolico()
	_deposito_agua()
	_volcar_lotes()

func _cargar_modelos() -> void:
	for ruta in CityBuilder.RUTAS_COMERCIAL:
		var e: PackedScene = load(ruta)
		if e != null:
			_comercial.append(e)
	for ruta in CityBuilder.RUTAS_NAVES:
		var e2: PackedScene = load(ruta)
		if e2 != null:
			_naves.append(e2)
	for ruta in CityBuilder.RUTAS_HORIZONTE:
		var e3: PackedScene = load(ruta)
		if e3 != null:
			_altos.append(e3)

func _materiales() -> void:
	var asf: StandardMaterial3D = Texturas.asfalto(Color(0.15, 0.15, 0.16)).duplicate()
	asf.roughness = 0.5
	_mat["asfalto"] = asf
	_mat["acera"] = b._mat_simple(Color(0.5, 0.49, 0.47), 0.9)
	_mat["solar"] = b._mat_simple(Color(0.4, 0.4, 0.39), 0.92)
	_mat["linea"] = b._mat_simple(Color(0.92, 0.9, 0.82), 0.7)
	_mat["cesped"] = b._mat_simple(Color(0.27, 0.48, 0.24), 0.95)
	_mat["hoja"] = b._mat_simple(Color(0.18, 0.4, 0.2), 0.9)
	_mat["tronco"] = b._mat_simple(Color(0.35, 0.26, 0.18), 0.9)
	_mat["claro"] = b._mat_simple(Color(0.9, 0.89, 0.86), 0.7)
	_mat["vidrio"] = b._vidrio_oscuro()
	_mat["piedra"] = b._mat_simple(Color(0.84, 0.8, 0.7), 0.8)
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.12, 0.4, 0.55)
	agua.roughness = 0.08
	agua.metallic = 0.3
	_mat["agua"] = agua

## Calzadas, aceras, marcas viales y puentes.
func _dibujar_calles() -> void:
	var marcas: Array[Transform3D] = []
	for t: Dictionary in tramos:
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var ancho: float = t["ancho"]
		var vertical := absf(a.x - c.x) < 0.1
		var largo := a.distance_to(c)
		var m := (a + c) * 0.5
		var tam := Vector3(ancho, 0.12, largo + ancho) if vertical else Vector3(largo + ancho, 0.12, ancho)
		if bool(t["puente"]):
			_puente(a, c, ancho)
			continue
		_lote("asfalto", Vector3(m.x, 0.07, m.z), tam)
		## Aceras a los dos lados (más altas que la calzada).
		for lado: float in [-1.0, 1.0]:
			var off := (ancho * 0.5 + ACERA * 0.5) * lado
			var p := Vector3(m.x + off, 0.12, m.z) if vertical else Vector3(m.x, 0.12, m.z + off)
			var ta := Vector3(ACERA, 0.24, largo - ancho) if vertical else Vector3(largo - ancho, 0.24, ACERA)
			_lote("acera", p, ta)
		## Línea discontinua al centro (doble y continua en las avenidas).
		var paso := 9.0
		var n := int((largo - ancho) / paso)
		for q in n:
			var f := (float(q) + 0.5) / float(maxi(1, n))
			var p2 := a.lerp(c, f)
			if absf(p2.distance_to(a)) < ancho * 0.6 or absf(p2.distance_to(c)) < ancho * 0.6:
				continue
			var esc := Vector3(0.25, 1.0, 4.0) if vertical else Vector3(4.0, 1.0, 0.25)
			if bool(t["av"]):
				for dl: float in [-0.35, 0.35]:
					var pp := p2 + (Vector3(dl, 0, 0) if vertical else Vector3(0, 0, dl))
					marcas.append(Transform3D(Basis.from_scale(esc * Vector3(1, 1, 2.2) if vertical else esc * Vector3(2.2, 1, 1)), pp + Vector3(0, 0.14, 0)))
			else:
				marcas.append(Transform3D(Basis.from_scale(esc), p2 + Vector3(0, 0.14, 0)))
	## Pasos de cebra en los cruces con semáforo.
	for p: Vector3 in cruces_semaforo:
		for eje in 4:
			var dir := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)][eje] as Vector3
			var base := p + dir * (ANCHO_AV * 0.5 + 2.5)
			for s in 6:
				var lat := (float(s) - 2.5) * 1.6
				var pos := base + (Vector3(0, 0, lat) if absf(dir.x) > 0.5 else Vector3(lat, 0, 0))
				var esc2 := Vector3(3.2, 1.0, 0.8) if absf(dir.x) > 0.5 else Vector3(0.8, 1.0, 3.2)
				marcas.append(Transform3D(Basis.from_scale(esc2), pos + Vector3(0, 0.14, 0)))
	_multimesh(BoxMesh.new(), _mat["linea"], marcas, Vector3(1, 0.02, 1))
	cuenta["marcas"] = marcas.size()

## Un puente: tablero sobre pilares, con barandillas, más alto sobre el agua
## para que pase el bote, y rampas hasta las orillas.
func _puente(a: Vector3, c: Vector3, ancho: float) -> void:
	var x0 := minf(a.x, c.x) - ancho * 0.5
	var x1 := maxf(a.x, c.x) + ancho * 0.5
	var z := a.z
	var rx := CityBuilder.RIO_X
	var agua0 := rx - 44.0
	var agua1 := rx + 44.0
	var rampa := 20.0
	var hormigon := b._mat_simple(Color(0.7, 0.69, 0.66), 0.8)
	## Tramos a nivel fuera de las rampas.
	if agua0 - rampa > x0:
		_lote("asfalto", Vector3((x0 + agua0 - rampa) * 0.5, 0.07, z), Vector3(agua0 - rampa - x0, 0.12, ancho))
	if x1 > agua1 + rampa:
		_lote("asfalto", Vector3((agua1 + rampa + x1) * 0.5, 0.07, z), Vector3(x1 - agua1 - rampa, 0.12, ancho))
	## Rampas inclinadas.
	for lado: float in [-1.0, 1.0]:
		var xa := agua0 - rampa if lado < 0.0 else agua1
		var cx := xa + rampa * 0.5
		var r := b._caja_en(Vector3(cx, PUENTE_ALTO * 0.5, z), Vector3(sqrt(rampa * rampa + PUENTE_ALTO * PUENTE_ALTO), 0.5, ancho), _mat["asfalto"])
		r.rotation.z = atan2(PUENTE_ALTO, rampa) * (-lado)
	## Tablero sobre el agua.
	_lote("asfalto", Vector3(rx, PUENTE_ALTO, z), Vector3(agua1 - agua0, 0.6, ancho))
	b._caja_en(Vector3(rx, PUENTE_ALTO - 0.8, z), Vector3(agua1 - agua0, 1.0, ancho + 1.0), hormigon)
	for px: float in [agua0 + 6.0, rx, agua1 - 6.0]:
		b._caja_en(Vector3(px, PUENTE_ALTO * 0.5 - 0.6, z), Vector3(2.2, PUENTE_ALTO, ancho * 0.7), hormigon)
	_adornar_puente(rx, z, ancho, agua0, agua1, rampa)
	cuenta["puentes"] = int(cuenta.get("puentes", 0)) + 1

## EL PUENTE MÁS BONITO (7-10-2026, «el puente puede quedar más bonito»):
## arcos de piedra entre los pilares, tajamares, cornisa, balaustrada de
## columnillas, aceras sobre el tablero, farolas de forja con banderolas del
## club, pilonos en las cuatro esquinas con el nombre del puente y una fila de
## luces bajo el tablero que se ve de noche.
const NOMBRES_PUENTE := ["Puente de Piedra", "Puente de la Ribera", "Puente del Centenario", "Puente de los Remeros",
	"Puente Nuevo", "Puente del Molino", "Puente de la Afición", "Puente Real", "Puente del Carmen"]

func _adornar_puente(rx: float, z: float, ancho: float, agua0: float, agua1: float, rampa: float) -> void:
	var piedra := b._mat_simple(Color(0.78, 0.7, 0.58), 0.85)
	var piedra_osc := b._mat_simple(Color(0.6, 0.53, 0.44), 0.9)
	var forja := b._mat_simple(Color(0.1, 0.11, 0.12), 0.4)
	forja.metallic = 0.5
	var nombre := String(NOMBRES_PUENTE[absi(int(z / CELDA)) % NOMBRES_PUENTE.size()])
	var dovelas: Array[Transform3D] = []
	var timpanos: Array[Transform3D] = []
	var balaustres: Array[Transform3D] = []
	## Los arcos: dos vanos (entre los tres pilares), con su rosca de dovelas.
	var pilares := [agua0 + 6.0, rx, agua1 - 6.0]
	for v in 2:
		var xa: float = pilares[v] + 1.1
		var xb: float = pilares[v + 1] - 1.1
		var cx := (xa + xb) * 0.5
		var semi := (xb - xa) * 0.5
		var alto := PUENTE_ALTO - 1.4
		var n := 18
		for k in n:
			var t0 := PI * float(k) / float(n)
			var t1 := PI * float(k + 1) / float(n)
			var p0 := Vector3(cx - cos(t0) * semi, 0.3 + sin(t0) * alto, z)
			var p1 := Vector3(cx - cos(t1) * semi, 0.3 + sin(t1) * alto, z)
			var m := (p0 + p1) * 0.5
			var d := p1 - p0
			var ang := atan2(d.y, d.x)
			for lado: float in [-1.0, 1.0]:
				dovelas.append(Transform3D(Basis(Vector3(0, 0, 1), ang) * Basis.from_scale(Vector3(d.length() + 0.15, 0.9, 0.7)),
					m + Vector3(0, 0, lado * (ancho * 0.5 + 0.2))))
				## El tímpano: piedra maciza entre la rosca y el tablero.
				var y_arco := maxf(p0.y, p1.y) + 0.4
				var alto_t := PUENTE_ALTO - 0.3 - y_arco
				if alto_t > 0.05:
					timpanos.append(Transform3D(Basis.from_scale(Vector3(absf(d.x) + 0.05, alto_t, 0.55)),
						Vector3(m.x, y_arco + alto_t * 0.5, z + lado * (ancho * 0.5 + 0.2))))
	_multimesh(BoxMesh.new(), piedra_osc, dovelas, Vector3.ONE)
	_multimesh(BoxMesh.new(), piedra, timpanos, Vector3.ONE)
	## Tajamares: proas de piedra en los pilares, río arriba y río abajo.
	for px: float in pilares:
		for lado: float in [-1.0, 1.0]:
			var t := b._caja_en(Vector3(px, PUENTE_ALTO * 0.35, z + lado * (ancho * 0.35 + 0.8)), Vector3(1.6, PUENTE_ALTO * 0.7, 1.6), piedra)
			t.rotation.y = PI * 0.25
	## Cornisa a lo largo del tablero.
	for lado: float in [-1.0, 1.0]:
		b._caja_en(Vector3(rx, PUENTE_ALTO - 0.2, z + lado * (ancho * 0.5 + 0.55)), Vector3(agua1 - agua0, 0.35, 0.5), piedra)
	## Aceras sobre el tablero (los peatones van por los lados).
	for lado: float in [-1.0, 1.0]:
		b._caja_en(Vector3(rx, PUENTE_ALTO + 0.38, z + lado * (ancho * 0.5 - 1.1)), Vector3(agua1 - agua0, 0.18, 2.2), b._mat_simple(Color(0.72, 0.68, 0.62), 0.8))
	## La balaustrada: columnillas bajo un pasamanos de piedra (sustituye al
	## muro liso de hormigón).
	var largo := agua1 - agua0 + rampa * 2.0
	var cuantos := int(largo / 0.7)
	for lado: float in [-1.0, 1.0]:
		var zb := z + lado * (ancho * 0.5 + 0.2)
		for k in cuantos:
			var x := rx - largo * 0.5 + (float(k) + 0.5) * largo / float(cuantos)
			var y_base := _altura_puente(x, rx, agua0, agua1, rampa)
			balaustres.append(Transform3D(Basis.from_scale(Vector3(0.22, 0.85, 0.22)), Vector3(x, y_base + 0.75, zb)))
		b._caja_en(Vector3(rx, PUENTE_ALTO + 1.25, zb), Vector3(agua1 - agua0, 0.2, 0.42), piedra)
	var torno := CylinderMesh.new()
	torno.height = 1.0
	torno.top_radius = 0.38
	torno.bottom_radius = 0.5
	torno.radial_segments = 8
	_multimesh(torno, piedra, balaustres, Vector3.ONE)
	## Farolas de forja con banderolas del club, cada 11 m por lado.
	var c1 := b._color_club("c1", Color(0.2, 0.5, 0.3))
	var c2 := b._color_club("c2", Color(1, 1, 1))
	var postes: Array[Transform3D] = []
	var faroles: Array[Transform3D] = []
	var banderolas: Array[Transform3D] = []
	var band_col: Array[Color] = []
	var nf := int((agua1 - agua0) / 11.0)
	for lado: float in [-1.0, 1.0]:
		for k in nf + 1:
			var x := agua0 + float(k) * (agua1 - agua0) / float(nf)
			var base := Vector3(x, PUENTE_ALTO + 1.35, z + lado * (ancho * 0.5 + 0.2))
			postes.append(Transform3D(Basis.from_scale(Vector3(0.14, 4.2, 0.14)), base + Vector3(0, 2.1, 0)))
			faroles.append(Transform3D(Basis.from_scale(Vector3(0.45, 0.6, 0.45)), base + Vector3(0, 4.45, 0)))
			if k % 2 == 1:
				banderolas.append(Transform3D(Basis.from_scale(Vector3(0.05, 1.5, 0.7)), base + Vector3(0, 3.0, -lado * 0.45)))
				band_col.append(c1 if k % 4 == 1 else c2)
	var cil := CylinderMesh.new()
	cil.height = 1.0
	cil.top_radius = 0.5
	cil.bottom_radius = 0.5
	_multimesh(cil, forja, postes, Vector3.ONE)
	_multimesh(BoxMesh.new(), _mat_luz_farola(), faroles, Vector3.ONE)
	_multimesh(BoxMesh.new(), null, banderolas, Vector3.ONE, band_col)
	## Pilonos en las cuatro esquinas, con el nombre del puente.
	for xe: float in [agua0 - rampa - 1.0, agua1 + rampa + 1.0]:
		for lado: float in [-1.0, 1.0]:
			var pz := z + lado * (ancho * 0.5 + 0.9)
			b._caja_en(Vector3(xe, 2.0, pz), Vector3(1.6, 4.0, 1.6), piedra)
			b._caja_en(Vector3(xe, 4.15, pz), Vector3(2.0, 0.3, 2.0), piedra_osc)
			b._caja_en(Vector3(xe, 4.8, pz), Vector3(0.6, 1.0, 0.6), _mat_luz_farola())
		var l := Label3D.new()
		l.text = nombre
		l.font_size = 44
		l.pixel_size = 0.01
		l.modulate = Color(0.25, 0.2, 0.15)
		l.outline_size = 0
		l.position = Vector3(xe + (-0.82 if xe < rx else 0.82), 2.4, z + ancho * 0.5 + 0.9)
		l.rotation.y = -PI * 0.5 if xe < rx else PI * 0.5
		l.visibility_range_end = 120.0
		b.add_child(l)
	b._rotulo(Vector3(rx, PUENTE_ALTO + 9.0, z), "🌉 " + nombre, Color(0.95, 0.9, 0.75), 16)
	## Luces bajo el tablero, reflejadas en el agua de noche.
	var luces: Array[Transform3D] = []
	for k in 16:
		for lado: float in [-1.0, 1.0]:
			luces.append(Transform3D(Basis.from_scale(Vector3(0.6, 0.15, 0.3)), Vector3(agua0 + (float(k) + 0.5) * (agua1 - agua0) / 16.0, PUENTE_ALTO - 0.45, z + lado * (ancho * 0.5 + 0.85))))
	_multimesh(BoxMesh.new(), _mat_luz_farola(), luces, Vector3.ONE)

## Altura del suelo del puente en x (rampas y tablero), para la balaustrada.
func _altura_puente(x: float, rx: float, agua0: float, agua1: float, rampa: float) -> float:
	if x >= agua0 and x <= agua1:
		return PUENTE_ALTO
	if x < agua0:
		return clampf((x - (agua0 - rampa)) / rampa, 0.0, 1.0) * PUENTE_ALTO
	return clampf(((agua1 + rampa) - x) / rampa, 0.0, 1.0) * PUENTE_ALTO

# ---------------------------------------------------------------- manzanas

func _dibujar_bloque(bl: Dictionary) -> void:
	var r: Rect2 = bl["rect"]
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var uso := String(bl["uso"])
	match uso:
		"rio":
			_paseo_rio(r)
		"puerto":
			_puerto(r)
		"casa_grande":
			if bl["celda"] == Vector2i(-2, 6):
				var rr := Rect2(FINCA_GRANDE.position + Vector2(ANCHO_CALLE * 0.5 + ACERA, ANCHO_AV * 0.5 + ACERA),
					FINCA_GRANDE.size - Vector2(ANCHO_CALLE * 0.5 + ACERA + ANCHO_AV * 0.5 + ACERA, ANCHO_AV * 0.5 + ACERA + ANCHO_CALLE * 0.5 + ACERA))
				_casa_grande(rr)
		"parque", "parque_lago":
			_parque(r, uso == "parque_lago")
		"torres":
			_acera_bloque(r)
			_torres(r)
		"comercial":
			_acera_bloque(r)
			_comercial_bloque(r)
		"pisos":
			_acera_bloque(r)
			_pisos(r)
		"industrial":
			_industrial(r)
		"casas":
			_casas(r)
		"lejano":
			_lejanos.append(r)
		_:
			_acera_bloque(r)
			_instalacion(uso, r)
	cuenta[uso] = int(cuenta.get(uso, 0)) + 1
	## Para que el resto de la ciudad (árboles, ánimo) sepa que aquí hay algo.
	if not (uso in ["rio", "parque", "parque_lago", "lejano"]):
		b._frentes.append(r)

func _acera_bloque(r: Rect2) -> void:
	_lote("solar", Vector3(r.get_center().x, 0.12, r.get_center().y), Vector3(r.size.x, 0.24, r.size.y))

## Un bloque alto hecho con el mismo modelo apilado planta sobre planta (en
## vez de estirarlo): crece en pisos y las ventanas conservan su forma.
func _kit_apilado(esc: PackedScene, pos: Vector3, s: float, pisos: int, giro: float) -> void:
	var tmp: Node3D = esc.instantiate()
	var alto := b._caja_de(tmp).size.y * s
	tmp.free()
	for k in pisos:
		_kit(esc, pos + Vector3(0, float(k) * alto * 0.98, 0), Vector3.ONE * s, giro)

func _kit(esc: PackedScene, pos: Vector3, escala: Vector3, giro: float) -> Node3D:
	var n: Node3D = esc.instantiate()
	if _rng.randf() < 0.45:
		b.tenir(n, _rng.randi())
	n.scale = escala
	n.rotation.y = giro
	n.position = pos
	b.add_child(n)
	cuenta["edificios"] = int(cuenta.get("edificios", 0)) + 1
	return n

func _comercial_bloque_borde(r: Rect2) -> void:
	_fachadas(r, false)

func _comercial_bloque(r: Rect2) -> void:
	_fachadas(r, true)

## Fachadas del kit por los cuatro lados, mirando a la calle (`con_nave`: un
## bloque alto en el centro de la manzana).
func _fachadas(r: Rect2, con_nave: bool) -> void:
	if _comercial.is_empty():
		return
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	for lado in 4:
		var n := [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)][lado] as Vector3
		var dir := Vector3(-n.z, 0, n.x)
		var largo := (r.size.x if absf(n.z) > 0.5 else r.size.y) - 10.0
		var fondo_b := r.size.y if absf(n.z) > 0.5 else r.size.x
		var u := -largo * 0.5
		var giro := atan2(n.x, n.z)
		while u < largo * 0.5 - 6.0:
			var esc: PackedScene = _comercial[_rng.randi() % _comercial.size()]
			var s := 5.6 * _rng.randf_range(0.9, 1.1)
			var tmp: Node3D = esc.instantiate()
			var caja := b._caja_de(tmp)
			tmp.free()
			var ancho := maxf(caja.size.x * s, 6.0)
			var fondo := maxf(caja.size.z * s, 6.0)
			if u + ancho > largo * 0.5:
				break
			var p := c + dir * (u + ancho * 0.5) + n * (fondo_b * 0.5 - fondo * 0.5 - 0.3)
			## Escala UNIFORME (7-10-2026): estirarlos en vertical alargaba puertas
			## y ventanas, y los edificios se veían deformados.
			_kit(esc, Vector3(p.x, 0.2, p.z), Vector3.ONE * s, giro)
			if _rng.randf() < 0.4:
				_rotulo_comercio(p + n * (fondo * 0.5 + 0.35), giro, ancho)
			u += ancho + _rng.randf_range(0.3, 1.5)
	if con_nave and not _naves.is_empty():
		_patio_de_manzana(r, c)
		var s2 := 6.5 * _rng.randf_range(0.9, 1.2)
		## El bloque interior: un rascacielos del kit (pensado alto), uniforme.
		if not _altos.is_empty() and _rng.randf() < 0.6:
			_kit(_altos[_rng.randi() % _altos.size()], c + Vector3(0, 0.2, 0), Vector3.ONE * _rng.randf_range(3.2, 4.4), float(_rng.randi() % 4) * PI * 0.5)
		else:
			_kit(_naves[_rng.randi() % _naves.size()], c + Vector3(0, 0.2, 0), Vector3.ONE * s2 * 1.2, float(_rng.randi() % 4) * PI * 0.5)

## LOS COMERCIOS (7-10-2026, «agrega cosas que tiene una ciudad real»): un
## rótulo sobre la planta baja de las fachadas que dan a la calle. La farmacia
## lleva su cruz verde encendida.
const COMERCIOS := [["💊 Farmacia", Color(0.1, 0.55, 0.25)], ["☕ Cafetería", Color(0.45, 0.28, 0.18)],
	["🥖 Panadería", Color(0.8, 0.55, 0.2)], ["🏦 Banco", Color(0.1, 0.25, 0.5)], ["📮 Correos", Color(0.95, 0.75, 0.1)],
	["💈 Peluquería", Color(0.75, 0.15, 0.2)], ["📚 Librería", Color(0.3, 0.2, 0.45)], ["🛒 Supermercado", Color(0.85, 0.3, 0.1)],
	["🍕 Pizzería", Color(0.75, 0.2, 0.1)], ["🏨 Hotel", Color(0.15, 0.15, 0.2)], ["👟 Deportes", Color(0.2, 0.45, 0.75)],
	["🍺 Bar", Color(0.55, 0.2, 0.15)], ["🌸 Floristería", Color(0.85, 0.4, 0.6)], ["🔑 Ferretería", Color(0.4, 0.4, 0.42)],
	["⚽ Peña del club", Color(0.2, 0.5, 0.3)], ["🍦 Heladería", Color(0.4, 0.75, 0.85)]]

func _rotulo_comercio(frente: Vector3, giro: float, ancho: float) -> void:
	var com: Array = COMERCIOS[_rng.randi() % COMERCIOS.size()]
	var col: Color = com[1]
	if String(com[0]).contains("Peña"):
		col = b._color_club("c1", col)
	var basis := Basis(Vector3.UP, giro)
	var centro := frente + Vector3(0, 4.1, 0)
	var placa := b._caja_en(centro, Vector3(minf(ancho * 0.8, 7.0), 0.9, 0.18), b._mat_simple(col, 0.5, 0.25))
	placa.rotation.y = giro
	var l := Label3D.new()
	l.text = String(com[0])
	l.font_size = 48
	l.pixel_size = 0.012
	l.outline_size = 8
	l.outline_modulate = col.darkened(0.6)
	l.position = centro + basis * Vector3(0, 0, 0.12)
	l.rotation.y = giro
	l.visibility_range_end = 110.0
	b.add_child(l)
	if String(com[0]).contains("Farmacia"):
		var cruz := b._mat_simple(Color(0.2, 1.0, 0.4), 0.4, 2.0)
		var pc := frente + basis * Vector3(minf(ancho * 0.4, 3.5) + 0.6, 0, 0.5) + Vector3(0, 5.2, 0)
		var h := b._caja_en(pc, Vector3(0.9, 0.3, 0.12), cruz)
		h.rotation.y = giro
		var v := b._caja_en(pc, Vector3(0.3, 0.9, 0.12), cruz)
		v.rotation.y = giro

func _torres(r: Rect2) -> void:
	if _altos.is_empty():
		return
	## Comercios en la planta baja por los cuatro lados (como una manzana
	## comercial) y, dentro, dos o tres torres gruesas sobre un patio verde.
	_comercial_bloque_borde(r)
	var c := Vector3(r.get_center().x, 0.2, r.get_center().y)
	_lote("cesped", Vector3(c.x, 0.26, c.z), Vector3(r.size.x * 0.55, 0.06, r.size.y * 0.5))
	var offs := [Vector3(-r.size.x * 0.14, 0, -r.size.y * 0.1), Vector3(r.size.x * 0.14, 0, r.size.y * 0.1), Vector3(r.size.x * 0.14, 0, -r.size.y * 0.12)]
	var empuje := b._empuje_club()
	for k in offs.size():
		if k == 2 and _rng.randf() < 0.5:
			continue
		var s := 6.2 * _rng.randf_range(0.9, 1.25) * lerpf(0.9, 1.3, empuje)
		_kit(_altos[_rng.randi() % _altos.size()], c + (offs[k] as Vector3), Vector3(s * 1.25, s, s * 1.25), float(_rng.randi() % 4) * PI * 0.5)
	_arboles_en([c + Vector3(-r.size.x * 0.2, -0.2, r.size.y * 0.16), c + Vector3(r.size.x * 0.02, -0.2, -r.size.y * 0.2)], 0.9)

func _pisos(r: Rect2) -> void:
	## Bloques de viviendas: el kit «de poco detalle» alto, en dos hileras con
	## patio en medio.
	if _naves.is_empty():
		return
	var c := Vector3(r.get_center().x, 0.2, r.get_center().y)
	for fila: float in [-1.0, 1.0]:
		for k in 3:
			var x := c.x + (float(k) - 1.0) * r.size.x * 0.3
			var s := 5.6 * _rng.randf_range(0.9, 1.1)
			var pos_p := Vector3(x, 0.2, c.z + fila * r.size.y * 0.27)
			if not _altos.is_empty() and (k + int(fila > 0.0)) % 2 == 0:
				_kit(_altos[_rng.randi() % _altos.size()], pos_p, Vector3.ONE * _rng.randf_range(2.8, 3.6), 0.0 if fila > 0.0 else PI)
			else:
				_kit(_naves[_rng.randi() % _naves.size()], pos_p, Vector3.ONE * s * 1.15, 0.0 if fila > 0.0 else PI)
	## El patio entre las dos hileras: césped, un camino y árboles.
	_lote("cesped", Vector3(c.x, 0.27, c.z), Vector3(r.size.x * 0.82, 0.06, r.size.y * 0.2))
	_lote("solar", Vector3(c.x, 0.3, c.z), Vector3(r.size.x * 0.82, 0.06, 2.4))
	var pts: Array = []
	for k in 5:
		pts.append(c + Vector3((float(k) - 2.0) * r.size.x * 0.17, -0.2, (5.5 if k % 2 == 0 else -5.5)))
	_arboles_en(pts, 0.8)

## EL PATIO DE MANZANA (7-10-2026, «¿qué le pasó a los edificios?»): visto
## desde arriba, el interior de las manzanas comerciales era una explanada
## gris vacía detrás de las fachadas. Ahora es un patio como los del
## ensanche: césped, dos caminos en cruz y árboles alrededor de la torre.
func _patio_de_manzana(r: Rect2, c: Vector3) -> void:
	var lado := Vector2(maxf(r.size.x - 36.0, 10.0), maxf(r.size.y - 36.0, 10.0))
	_lote("cesped", Vector3(c.x, 0.27, c.z), Vector3(lado.x, 0.06, lado.y))
	_lote("solar", Vector3(c.x, 0.3, c.z), Vector3(lado.x, 0.06, 2.6))
	_lote("solar", Vector3(c.x, 0.3, c.z), Vector3(2.6, 0.06, lado.y))
	var pts: Array = []
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			pts.append(c + Vector3(sx * lado.x * 0.36, 0.0, sz * lado.y * 0.36))
			pts.append(c + Vector3(sx * lado.x * 0.18, 0.0, sz * lado.y * 0.4))
	_arboles_en(pts, 0.85)

## Viviendas con jardín: se guardan y se dibujan todas juntas (MultiMesh).
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

func _casas(r: Rect2) -> void:
	_lote("cesped", Vector3(r.get_center().x, 0.05, r.get_center().y), Vector3(r.size.x, 0.1, r.size.y))
	var cols := 4
	var filas := 2
	var paso_x := r.size.x / float(cols)
	for fi in filas:
		var lado := -1.0 if fi == 0 else 1.0
		for ci in cols:
			var x := r.position.x + paso_x * (float(ci) + 0.5)
			var z := r.get_center().y + lado * r.size.y * 0.22
			var ancho := paso_x * 0.62
			var fondo := r.size.y * 0.24
			var alto := _rng.randf_range(5.0, 7.5)
			var col := COLORES_CASA[_rng.randi() % COLORES_CASA.size()] as Color
			_casas_t.append(Transform3D(Basis.from_scale(Vector3(ancho, alto, fondo)), Vector3(x, alto * 0.5, z)))
			_casas_col.append(col)
			var tejado := [Color(0.62, 0.28, 0.2), Color(0.35, 0.33, 0.33), Color(0.5, 0.36, 0.26)][_rng.randi() % 3] as Color
			_techos_t.append(Transform3D(Basis.from_scale(Vector3(ancho + 1.0, 3.0, fondo + 1.0)), Vector3(x, alto + 1.5, z)))
			_techos_col.append(tejado)
			## Seto del jardín delantero, hacia la calle.
			var zs := z + lado * (fondo * 0.5 + 5.0)
			_setos_t.append(Transform3D(Basis.from_scale(Vector3(paso_x * 0.9 * 0.42, 1.3, 0.9)), Vector3(x - paso_x * 0.26, 0.65, zs)))
			_setos_t.append(Transform3D(Basis.from_scale(Vector3(paso_x * 0.9 * 0.42, 1.3, 0.9)), Vector3(x + paso_x * 0.26, 0.65, zs)))
			## La fachada que da a la calle: puerta, ventanas con marco, el
			## camino hasta la acera con su buzón, y la chimenea.
			var zf := z + lado * (fondo * 0.5 + 0.06)
			_puertas_t.append(Transform3D(Basis.from_scale(Vector3(1.3, 2.3, 0.12)), Vector3(x, 1.15, zf)))
			for k: float in [-1.0, 1.0]:
				for piso in (2 if alto > 6.2 else 1):
					var pv := Vector3(x + k * ancho * 0.3, 1.6 + float(piso) * 2.8, zf)
					_marcos_t.append(Transform3D(Basis.from_scale(Vector3(1.7, 1.5, 0.1)), pv))
					_vidrios_t.append(Transform3D(Basis.from_scale(Vector3(1.4, 1.2, 0.12)), pv + Vector3(0, 0, lado * 0.02)))
			var largo_c := absf(zs - zf)
			_caminos_t.append(Transform3D(Basis.from_scale(Vector3(1.6, 0.06, largo_c)), Vector3(x, 0.13, (zs + zf) * 0.5)))
			_buzones_t.append(Transform3D(Basis.from_scale(Vector3(0.45, 1.2, 0.35)), Vector3(x + 1.6, 0.6, zs)))
			if _rng.randf() < 0.6:
				_chimeneas_t.append(Transform3D(Basis.from_scale(Vector3(0.8, 2.6, 0.8)), Vector3(x + ancho * 0.28, alto + 2.0, z - lado * fondo * 0.15)))
	cuenta["casas"] = int(cuenta.get("casas", 0)) + cols * filas

func _casas_multimesh() -> void:
	if _casas_t.is_empty():
		return
	_multimesh(BoxMesh.new(), null, _casas_t, Vector3.ONE, _casas_col)
	var prisma := PrismMesh.new()
	_multimesh(prisma, null, _techos_t, Vector3.ONE, _techos_col)
	_multimesh(BoxMesh.new(), _mat["hoja"], _setos_t, Vector3.ONE)
	_multimesh(BoxMesh.new(), b._mat_simple(Color(0.36, 0.22, 0.14), 0.7), _puertas_t, Vector3.ONE)
	_multimesh(BoxMesh.new(), b._mat_simple(Color(0.96, 0.96, 0.94), 0.6), _marcos_t, Vector3.ONE)
	var vid := b._mat_simple(Color(0.2, 0.28, 0.36), 0.12)
	vid.metallic = 0.6
	_multimesh(BoxMesh.new(), vid, _vidrios_t, Vector3.ONE)
	_multimesh(BoxMesh.new(), b._mat_simple(Color(0.7, 0.66, 0.6), 0.9), _caminos_t, Vector3.ONE)
	_multimesh(BoxMesh.new(), b._mat_simple(Color(0.15, 0.3, 0.55), 0.5), _buzones_t, Vector3.ONE)
	_multimesh(BoxMesh.new(), b._mat_simple(Color(0.55, 0.3, 0.24), 0.8), _chimeneas_t, Vector3.ONE)

func _industrial(r: Rect2) -> void:
	b._caja_en(Vector3(r.get_center().x, 0.06, r.get_center().y), Vector3(r.size.x, 0.12, r.size.y), b._mat_simple(Color(0.42, 0.42, 0.41), 0.9))
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	## Una nave grande con cubierta en diente de sierra y contenedores.
	var nave := b._mat_simple([Color(0.62, 0.64, 0.66), Color(0.55, 0.5, 0.42), Color(0.5, 0.56, 0.6)][_rng.randi() % 3], 0.6)
	var w := r.size.x * 0.62
	var f := r.size.y * 0.55
	b._caja_en(c + Vector3(-r.size.x * 0.12, 5.0, -r.size.y * 0.1), Vector3(w, 10.0, f), nave)
	for k in 5:
		var d := b._caja_en(c + Vector3(-r.size.x * 0.12 - w * 0.4 + float(k) * w * 0.2, 11.2, -r.size.y * 0.1), Vector3(w * 0.18, 2.4, f), b._mat_simple(Color(0.4, 0.42, 0.45), 0.5))
		d.rotation.z = 0.35
	var cont: Array[Transform3D] = []
	var colc: Array[Color] = []
	for k in 10:
		var p := c + Vector3(r.size.x * 0.32, 1.3 + float(k % 3) * 2.6, -r.size.y * 0.35 + float(k / 3) * 6.5)
		cont.append(Transform3D(Basis.from_scale(Vector3(2.5, 2.6, 6.0)), p))
		colc.append([Color(0.75, 0.2, 0.15), Color(0.15, 0.35, 0.7), Color(0.2, 0.55, 0.3), Color(0.85, 0.6, 0.15)][_rng.randi() % 4])
	_multimesh(BoxMesh.new(), null, cont, Vector3.ONE, colc)
	if _rng.randf() < 0.5:
		b._cil_en(c + Vector3(-r.size.x * 0.38, 14.0, r.size.y * 0.3), 1.4, 28.0, b._mat_simple(Color(0.55, 0.3, 0.25), 0.8))
	cuenta["edificios"] = int(cuenta.get("edificios", 0)) + 1

func _paseo_rio(r: Rect2) -> void:
	## Las orillas son paseo arbolado; el agua la pone `_rio_largo` de una vez.
	var rx := CityBuilder.RIO_X
	for lado: float in [-1.0, 1.0]:
		var x0 := rx + lado * 50.0
		var x1 := r.end.x if lado > 0.0 else r.position.x
		if (x1 - x0) * lado <= 2.0:
			continue
		var cx := (x0 + x1) * 0.5
		_lote("cesped", Vector3(cx, 0.05, r.get_center().y), Vector3(absf(x1 - x0), 0.1, r.size.y))
		_lote("acera", Vector3(x0 + lado * 4.0, 0.1, r.get_center().y), Vector3(5.0, 0.2, r.size.y))
		var pts: Array = []
		for k in 5:
			pts.append(Vector3(x0 + lado * 10.0, 0, r.position.y + r.size.y * (float(k) + 0.5) / 5.0))
		_arboles_en(pts, 0.9)

func _puerto(r: Rect2) -> void:
	_paseo_rio(r)
	var rx := CityBuilder.RIO_X
	var madera := b._mat_simple(Color(0.45, 0.34, 0.22), 0.85)
	## Muelles que entran en el agua y barcos amarrados.
	for k in 3:
		var z := r.position.y + r.size.y * (float(k) + 0.5) / 3.0
		b._caja_en(Vector3(rx - 30.0, 0.6, z), Vector3(26.0, 0.4, 4.0), madera)
		var barco := b._hacer_velero()
		if barco != null:
			barco.position = Vector3(rx - 22.0, 0.1, z + 6.0)
			barco.rotation.y = PI * 0.5
			b.add_child(barco)
	## Grúa portuaria.
	b._grua(Vector3(rx - 62.0, 0, r.get_center().y), 26.0)
	var alm := b._mat_simple(Color(0.6, 0.45, 0.32), 0.8)
	b._caja_en(Vector3(r.position.x + 22.0, 5.0, r.get_center().y), Vector3(30.0, 10.0, r.size.y * 0.6), alm)
	b._rotulo(Vector3(rx - 40.0, 22.0, r.get_center().y), "⚓ Puerto fluvial", Color(0.8, 0.9, 1.0), 22)
	b.puntos_clic.append({"k": "ciudad_puerto", "n": "Puerto · pescar", "pos": Vector3(rx - 30.0, 0, r.get_center().y), "estado": "ciudad"})

func _parque(r: Rect2, lago: bool) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	_lote("cesped", Vector3(c.x, 0.05, c.z), Vector3(r.size.x, 0.1, r.size.y))
	## Caminos en cruz.
	_lote("acera", Vector3(c.x, 0.1, c.z), Vector3(r.size.x, 0.1, 4.0))
	_lote("acera", Vector3(c.x, 0.1, c.z), Vector3(4.0, 0.1, r.size.y))
	if lago:
		var l := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = minf(r.size.x, r.size.y) * 0.3
		cm.bottom_radius = cm.top_radius
		cm.height = 0.2
		cm.radial_segments = 32
		l.mesh = cm
		l.material_override = _mat["agua"]
		l.position = c + Vector3(r.size.x * 0.18, 0.18, r.size.y * 0.18)
		l.scale = Vector3(1.4, 1, 1)
		b.add_child(l)
	var pts: Array = []
	for k in 40:
		var p := c + Vector3(_rng.randf_range(-0.46, 0.46) * r.size.x, 0, _rng.randf_range(-0.46, 0.46) * r.size.y)
		## Lejos de los paseos, los parterres y la zona de juegos.
		if absf(p.x - c.x) < 6.0 or absf(p.z - c.z) < 6.0 or (absf(p.x - c.x) < 11.0 and absf(p.z - c.z) < 11.0):
			continue
		if p.x < c.x - r.size.x * 0.1 and p.z < c.z - r.size.y * 0.1 and not lago:
			continue
		pts.append(p)
	_arboles_en(pts, 1.0)
	var nombre := "Parque del Lago" if lago else String(NOMBRES_PARQUE[absi(int(c.x * 7.0 + c.z * 13.0)) % NOMBRES_PARQUE.size()])
	_detalles_parque(r, c, nombre, lago)
	b._rotulo(c + Vector3(0, 14, 0), "🌳 " + nombre, Color(0.7, 1.0, 0.7), 20)
	b.puntos_clic.append({"k": "ciudad_parque_lago" if lago else "ciudad_parque", "n": "Parque · penales con los chicos", "pos": c, "estado": "ciudad"})

## LOS DETALLES DEL PARQUE (7-10-2026): el portón con su nombre, una fuente
## en la cruz de los caminos, parterres de flores, bancos y farolas a lo largo
## de los paseos y una zona de juegos (columpios, tobogán y arenero).
func _detalles_parque(r: Rect2, c: Vector3, nombre: String, lago: bool) -> void:
	var piedra: Material = _mat["piedra"] if _mat.has("piedra") else b._mat_simple(Color(0.75, 0.72, 0.66), 0.8)
	var hierro := b._mat_simple(Color(0.12, 0.13, 0.12), 0.5)
	## El portón de entrada (lado sur) con el nombre.
	var puerta := c + Vector3(0, 0, r.size.y * 0.5 - 1.5)
	for lado: float in [-1.0, 1.0]:
		b._caja_en(puerta + Vector3(lado * 3.2, 1.8, 0), Vector3(0.7, 3.6, 0.7), piedra)
	b._caja_en(puerta + Vector3(0, 3.9, 0), Vector3(7.4, 0.7, 0.5), hierro)
	for cara: float in [1.0, -1.0]:
		var l := Label3D.new()
		l.text = nombre
		l.font_size = 48
		l.pixel_size = 0.009
		l.modulate = Color(0.95, 0.88, 0.6)
		l.outline_size = 8
		l.outline_modulate = Color(0.1, 0.12, 0.1)
		l.position = puerta + Vector3(0, 3.9, 0.3 * cara)
		l.rotation.y = 0.0 if cara > 0.0 else PI
		l.visibility_range_end = 160.0
		b.add_child(l)
	## La fuente en el cruce (si no hay lago ocupando el centro).
	if not lago:
		b._cil_en(c + Vector3(0, 0.45, 0), 3.0, 0.9, piedra)
		b._cil_en(c + Vector3(0, 0.88, 0), 2.7, 0.08, _mat["agua"])
		b._cil_en(c + Vector3(0, 1.6, 0), 0.3, 2.2, piedra)
		b._cil_en(c + Vector3(0, 2.8, 0), 1.1, 0.2, piedra)
	## Parterres de flores en las cuatro esquinas de la cruz.
	var flores: Array[Transform3D] = []
	var flores_col: Array[Color] = []
	var paleta := [Color(0.9, 0.2, 0.3), Color(0.98, 0.8, 0.2), Color(0.6, 0.3, 0.8), Color(1.0, 0.55, 0.7), Color(1, 1, 1)]
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var q := c + Vector3(sx * 7.0, 0, sz * 7.0)
			b._caja_en(q + Vector3(0, 0.2, 0), Vector3(5.0, 0.4, 5.0), b._mat_simple(Color(0.35, 0.25, 0.18), 0.9))
			for k in 12:
				flores.append(Transform3D(Basis.from_scale(Vector3(0.5, 0.45, 0.5)), q + Vector3(_rng.randf_range(-2.1, 2.1), 0.55, _rng.randf_range(-2.1, 2.1))))
				flores_col.append(paleta[_rng.randi() % paleta.size()])
	var esf := SphereMesh.new()
	esf.radial_segments = 8
	esf.rings = 4
	_multimesh(esf, null, flores, Vector3.ONE, flores_col)
	## Bancos y farolas a lo largo de los paseos.
	var bancos: Array[Transform3D] = []
	var faroles: Array[Transform3D] = []
	var globos: Array[Transform3D] = []
	for k in 6:
		var u := (float(k) - 2.5) / 6.0
		for paseo in 2:
			var pp := c + (Vector3(u * r.size.x, 0, 3.4) if paseo == 0 else Vector3(3.4, 0, u * r.size.y))
			if absf(u) < 0.12:
				continue
			bancos.append(Transform3D(Basis(Vector3.UP, 0.0 if paseo == 0 else PI * 0.5) * Basis.from_scale(Vector3(1.9, 0.5, 0.6)), pp + Vector3(0, 0.5, 0)))
			if k % 2 == 0:
				var pf := pp - (Vector3(0, 0, 6.8) if paseo == 0 else Vector3(6.8, 0, 0))
				faroles.append(Transform3D(Basis.from_scale(Vector3(0.12, 3.6, 0.12)), pf + Vector3(0, 1.8, 0)))
				globos.append(Transform3D(Basis.from_scale(Vector3(0.5, 0.5, 0.5)), pf + Vector3(0, 3.8, 0)))
	_multimesh(BoxMesh.new(), _mat["tronco"], bancos, Vector3.ONE)
	var cil := CylinderMesh.new()
	cil.height = 1.0
	cil.top_radius = 0.5
	cil.bottom_radius = 0.5
	_multimesh(cil, hierro, faroles, Vector3.ONE)
	_multimesh(SphereMesh.new(), b._mat_simple(Color(1.0, 0.95, 0.8), 0.3, 0.8), globos, Vector3.ONE)
	## La zona de juegos: arenero, columpios y tobogán.
	var zj := c + Vector3(-r.size.x * 0.27, 0, -r.size.y * 0.27)
	if lago:
		zj = c + Vector3(-r.size.x * 0.27, 0, r.size.y * 0.27)
	b._caja_en(zj + Vector3(0, 0.12, 0), Vector3(14.0, 0.24, 10.0), b._mat_simple(Color(0.86, 0.78, 0.58), 0.95))
	var rojo := b._mat_simple(Color(0.85, 0.2, 0.15), 0.5)
	var amarillo := b._mat_simple(Color(0.98, 0.8, 0.15), 0.5)
	var azul := b._mat_simple(Color(0.2, 0.45, 0.85), 0.5)
	## Columpios: pórtico en A y dos asientos.
	for lado: float in [-1.0, 1.0]:
		var pa := b._caja_en(zj + Vector3(-3.5 + lado * 1.8, 1.4, -2.5), Vector3(0.14, 3.0, 0.14), rojo)
		pa.rotation.z = lado * 0.18
	b._caja_en(zj + Vector3(-3.5, 2.85, -2.5), Vector3(3.8, 0.14, 0.14), rojo)
	for k: float in [-0.7, 0.7]:
		b._caja_en(zj + Vector3(-3.5 + k, 1.75, -2.5), Vector3(0.03, 2.2, 0.03), hierro)
		b._caja_en(zj + Vector3(-3.5 + k, 0.65, -2.5), Vector3(0.5, 0.06, 0.25), azul)
	## Tobogán: escalera, plataforma y la rampa.
	b._caja_en(zj + Vector3(3.0, 1.0, 1.5), Vector3(1.0, 2.0, 1.0), amarillo)
	b._caja_en(zj + Vector3(3.0, 2.05, 1.5), Vector3(1.3, 0.1, 1.3), azul)
	var rampa := b._caja_en(zj + Vector3(3.0, 1.05, -0.4), Vector3(0.8, 0.08, 3.0), rojo)
	rampa.rotation.x = -0.62
	## Un balancín.
	var bal := b._caja_en(zj + Vector3(0.5, 0.55, 2.8), Vector3(3.0, 0.12, 0.3), amarillo)
	bal.rotation.z = 0.15
	b._caja_en(zj + Vector3(0.5, 0.3, 2.8), Vector3(0.3, 0.5, 0.3), azul)

## La finca de la Casa Grande: césped, seto alrededor con portón al norte
## (al bulevar), la casa en el centro, camino de entrada, fuente y jardín.
func _casa_grande(r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	_lote("cesped", Vector3(c.x, 0.05, c.z), Vector3(r.size.x, 0.1, r.size.y))
	b._finca_enredadera(c, r.size)
	b._casa_gigante(c, Vector2(r.size.x - 70.0, r.size.y - 70.0))
	## Camino del portón (norte) a la casa, y una fuente en medio.
	b._caja_en(Vector3(c.x, 0.08, r.position.y + r.size.y * 0.18), Vector3(8.0, 0.1, r.size.y * 0.36), b._mat_simple(Color(0.78, 0.74, 0.66), 0.85))
	b._cil_en(Vector3(c.x, 0.6, r.position.y + r.size.y * 0.2), 5.0, 1.0, _mat["piedra"])
	b._cil_en(Vector3(c.x, 1.05, r.position.y + r.size.y * 0.2), 4.3, 0.2, _mat["agua"])
	var pts: Array = []
	for k in 18:
		var ang := TAU * float(k) / 18.0
		pts.append(c + Vector3(cos(ang) * r.size.x * 0.42, 0, sin(ang) * r.size.y * 0.42))
	_arboles_en(pts, 1.1)

## Las instalaciones de la ciudad, cada una con su forma y su rótulo.
func _instalacion(uso: String, r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0.2, r.get_center().y)
	var w := r.size.x
	var f := r.size.y
	var nombre := ""
	match uso:
		"plaza_mayor":
			nombre = "Plaza Mayor"
			b._caja_en(Vector3(c.x, 0.26, c.z), Vector3(w - 4.0, 0.1, f - 4.0), b._mat_simple(Color(0.62, 0.57, 0.5), 0.85))
			var fuente := b._cil_en(c + Vector3(0, 0.7, 0), 7.0, 1.0, _mat["piedra"])
			fuente.name = "Fuente"
			b._cil_en(c + Vector3(0, 1.1, 0), 6.0, 0.3, _mat["agua"])
			_estatua_idolo(c + Vector3(0, 0, -f * 0.3))
			_mural(c + Vector3(-w * 0.5 + 1.0, 0, 0), PI * 0.5)
			var esquinas: Array = []
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					esquinas.append(c + Vector3(sx * w * 0.36, -0.2, sz * f * 0.36))
			_arboles_en(esquinas, 1.0)
		"ayuntamiento":
			nombre = "Ayuntamiento"
			b._caja_en(c + Vector3(0, 9.0, -6.0), Vector3(w * 0.8, 18.0, f * 0.55), _mat["piedra"])
			b._caja_en(c + Vector3(0, 26.0, -6.0), Vector3(9.0, 16.0, 9.0), _mat["piedra"])
			b._cil_en(c + Vector3(0, 36.0, -6.0), 4.0, 4.0, b._mat_simple(Color(0.35, 0.5, 0.45), 0.4), 0.2)
			for k in 8:
				b._cil_en(c + Vector3(-w * 0.34 + float(k) * w * 0.097, 7.0, f * 0.24), 0.8, 14.0, _mat["piedra"])
			_bandera_mastil(c + Vector3(0, 0, f * 0.4))
		"estacion_central":
			nombre = "Estación Central"
			b._caja_en(c + Vector3(0, 6.0, 0), Vector3(w * 0.85, 12.0, f * 0.7), _mat["claro"])
			b._boveda(c + Vector3(0, 12.0, 0), w * 0.85, f * 0.7, b._mat_simple(Color(0.5, 0.62, 0.7), 0.3), 0.3)
			b._caja_en(c + Vector3(0, 5.0, f * 0.35 + 0.1), Vector3(w * 0.6, 7.0, 0.2), _mat["vidrio"])
			_cartel_m(c + Vector3(w * 0.4, 0, f * 0.45), Color(0.85, 0.15, 0.15))
		"mercado":
			nombre = "Mercado"
			b._caja_en(c + Vector3(0, 4.5, 0), Vector3(w * 0.8, 9.0, f * 0.7), b._mat_simple(Color(0.7, 0.4, 0.3), 0.8))
			b._boveda(c + Vector3(0, 9.0, 0), w * 0.8, f * 0.7, b._mat_simple(Color(0.35, 0.45, 0.4), 0.5), 0.25)
		"cine":
			nombre = "Cine"
			b._caja_en(c + Vector3(0, 9.0, 0), Vector3(w * 0.7, 18.0, f * 0.7), b._mat_simple(Color(0.25, 0.22, 0.3), 0.5))
			var neon := b._mat_simple(Color(1.0, 0.3, 0.6), 0.3, 2.0)
			b._caja_en(c + Vector3(0, 14.0, f * 0.35 + 0.3), Vector3(w * 0.5, 3.0, 0.3), neon)
		"hospital":
			nombre = "Hospital"
			var blanco := b._mat_simple(Color(0.96, 0.96, 0.97), 0.5)
			b._caja_en(c + Vector3(0, 12.0, -8.0), Vector3(w * 0.8, 24.0, f * 0.4), blanco)
			b._caja_en(c + Vector3(-w * 0.25, 5.0, f * 0.15), Vector3(w * 0.35, 10.0, f * 0.4), blanco)
			var rojo := b._mat_simple(Color(0.85, 0.1, 0.1), 0.5, 0.4)
			b._caja_en(c + Vector3(0, 20.0, -8.0 + f * 0.2 + 0.3), Vector3(7.0, 2.0, 0.3), rojo)
			b._caja_en(c + Vector3(0, 20.0, -8.0 + f * 0.2 + 0.3), Vector3(2.0, 7.0, 0.3), rojo)
			b._cil_en(c + Vector3(w * 0.2, 24.2, -8.0), 5.0, 0.3, b._mat_simple(Color(0.3, 0.3, 0.32), 0.6))
		"comisaria":
			nombre = "Comisaría"
			b._caja_en(c + Vector3(0, 6.0, 0), Vector3(w * 0.7, 12.0, f * 0.6), b._mat_simple(Color(0.75, 0.78, 0.84), 0.6))
			b._caja_en(c + Vector3(0, 9.5, f * 0.3 + 0.2), Vector3(w * 0.5, 1.6, 0.3), b._mat_simple(Color(0.15, 0.3, 0.75), 0.5, 0.3))
		"bomberos":
			nombre = "Bomberos"
			b._caja_en(c + Vector3(0, 6.0, 0), Vector3(w * 0.7, 12.0, f * 0.6), b._mat_simple(Color(0.75, 0.2, 0.15), 0.6))
			for k in 3:
				b._caja_en(c + Vector3(-w * 0.22 + float(k) * w * 0.22, 3.5, f * 0.3 + 0.1), Vector3(w * 0.17, 6.0, 0.2), b._mat_simple(Color(0.85, 0.85, 0.85), 0.4))
			b._caja_en(c + Vector3(w * 0.3, 11.0, -f * 0.2), Vector3(5.0, 22.0, 5.0), b._mat_simple(Color(0.75, 0.2, 0.15), 0.6))
		"escuela", "instituto":
			nombre = "Escuela" if uso == "escuela" else "Instituto"
			var lad := b._mat_simple(Color(0.7, 0.42, 0.32), 0.85)
			b._caja_en(c + Vector3(0, 6.0, -f * 0.2), Vector3(w * 0.8, 12.0, f * 0.3), lad)
			b._caja_en(c + Vector3(-w * 0.3, 6.0, f * 0.05), Vector3(w * 0.2, 12.0, f * 0.3), lad)
			## Patio con su cancha.
			b._caja_en(c + Vector3(w * 0.12, 0.25, f * 0.2), Vector3(w * 0.45, 0.1, f * 0.35), b._mat_simple(Color(0.3, 0.5, 0.35), 0.8))
		"universidad":
			nombre = "Universidad"
			b._caja_en(c + Vector3(0, 10.0, -f * 0.15), Vector3(w * 0.85, 20.0, f * 0.35), _mat["piedra"])
			b._cil_en(c + Vector3(0, 22.0, -f * 0.15), 9.0, 6.0, b._mat_simple(Color(0.4, 0.5, 0.6), 0.4), 2.0)
			_lote("cesped", c + Vector3(0, 0.25, f * 0.25), Vector3(w * 0.7, 0.1, f * 0.3))
		"centro_comercial":
			nombre = "Centro Comercial"
			b._caja_en(c + Vector3(0, 8.0, -f * 0.1), Vector3(w * 0.9, 16.0, f * 0.55), _mat["claro"])
			b._caja_en(c + Vector3(0, 7.0, -f * 0.1 + f * 0.275 + 0.2), Vector3(w * 0.7, 10.0, 0.2), _mat["vidrio"])
			_lote("asfalto", c + Vector3(0, 0.25, f * 0.32), Vector3(w * 0.9, 0.1, f * 0.3))
		"gasolinera":
			nombre = "Gasolinera"
			b._caja_en(c + Vector3(0, 6.0, 0), Vector3(w * 0.5, 0.6, f * 0.4), b._mat_simple(Color(0.9, 0.9, 0.9), 0.5))
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					b._cil_en(c + Vector3(sx * w * 0.18, 3.0, sz * f * 0.12), 0.3, 6.0, _mat["claro"])
			b._caja_en(c + Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 2.0), b._mat_simple(Color(0.85, 0.2, 0.15), 0.5))
			b._caja_en(c + Vector3(-w * 0.35, 2.5, -f * 0.3), Vector3(10.0, 5.0, 8.0), _mat["claro"])
		"villa_moderna":
			nombre = "Villa moderna"
			_lote("cesped", Vector3(c.x, 0.27, c.z), Vector3(w, 0.06, f))
			var esc := load(CityBuilder.RUTA_OFICINA_DT) as PackedScene
			if esc != null:
				var n0: Node3D = esc.instantiate()
				var raiz := Node3D.new()
				b.add_child(raiz)
				raiz.add_child(n0)
				var caja := b._caja_de(n0)
				n0.position = -Vector3(caja.position.x + caja.size.x * 0.5, caja.position.y, caja.position.z + caja.size.z * 0.5)
				var s := minf((w - 12.0) / maxf(caja.size.x, 0.01), (f - 12.0) / maxf(caja.size.z, 0.01))
				raiz.scale = Vector3.ONE * s
				raiz.position = c
				cuenta["edificios"] = int(cuenta.get("edificios", 0)) + 1
		"desguace":
			nombre = "Desguace"
			_lote("solar", Vector3(c.x, 0.26, c.z), Vector3(w, 0.05, f))
			b._desguace(c, 404)
			var ex := load("res://assets/ciudad/kenney_cars/tractor-shovel.glb") as PackedScene
			if ex != null:
				_kit(ex, c + Vector3(w * 0.3, 0, -f * 0.25), Vector3.ONE * 2.6, 0.6)
			var caja2 := load("res://assets/ciudad/kenney_cars/box.glb") as PackedScene
			if caja2 != null:
				for k in 6:
					_kit(caja2, c + Vector3(-w * 0.35 + float(k % 3) * 3.0, float(k / 3) * 2.2, -f * 0.3), Vector3.ONE * 2.2, 0.0)
		"granja":
			nombre = "Granja urbana"
			_lote("cesped", Vector3(c.x, 0.27, c.z), Vector3(w, 0.06, f))
			var tierra := b._mat_simple(Color(0.36, 0.26, 0.18), 0.95)
			var verde := b._mat_simple(Color(0.3, 0.55, 0.22), 0.9)
			for k in 8:
				b._caja_en(c + Vector3(-w * 0.4 + float(k) * w * 0.11, 0.35, 0), Vector3(w * 0.07, 0.3, f * 0.7), tierra)
				b._caja_en(c + Vector3(-w * 0.4 + float(k) * w * 0.11, 0.7, 0), Vector3(w * 0.05, 0.5, f * 0.65), verde)
			var tra := load("res://assets/ciudad/kenney_cars/tractor.glb") as PackedScene
			if tra != null:
				_kit(tra, c + Vector3(w * 0.38, 0, f * 0.35), Vector3.ONE * 2.4, PI * 0.5)
			b._caja_en(c + Vector3(-w * 0.3, 5.0, -f * 0.38), Vector3(14.0, 10.0, 9.0), b._mat_simple(Color(0.65, 0.2, 0.15), 0.8))
		"cocheras":
			nombre = "Cocheras de autobuses"
			b._caja_en(c + Vector3(0, 5.0, -f * 0.15), Vector3(w * 0.85, 10.0, f * 0.5), b._mat_simple(Color(0.6, 0.62, 0.6), 0.7))
			for k in 4:
				var n := CityBuilder.autobus([Color(0.85, 0.15, 0.12), Color(0.15, 0.4, 0.8)][k % 2], "")
				n.position = c + Vector3(-w * 0.3 + float(k) * w * 0.2, 0.2, f * 0.3)
				n.name = "Bus"
				b.add_child(n)
		_:
			b._caja_en(c + Vector3(0, 6.0, 0), Vector3(w * 0.7, 12.0, f * 0.6), _mat["claro"])
	if nombre != "":
		b._rotulo(c + Vector3(0, 30.0, 0), nombre, Color(1, 1, 1), 22)
		b.puntos_clic.append({"k": "ciudad_" + uso, "n": nombre, "pos": c, "estado": "ciudad"})
	cuenta["instalaciones"] = int(cuenta.get("instalaciones", 0)) + 1

## LA ESTATUA DEL ÍDOLO (originalidad): en la Plaza Mayor, un futbolista de
## bronce de 5 m sobre su pedestal, con la placa del ídolo del club (su última
## leyenda, o su capitán). Cambia con la historia de tu partida.
func _estatua_idolo(p: Vector3) -> void:
	var nombre := String(b.datos.get("idolo", ""))
	b._caja_en(p + Vector3(0, 1.5, 0), Vector3(5.0, 3.0, 5.0), _mat["piedra"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(nombre)
	## Un cuerpo de futbolista sin ropa aparte ni pelo: en bronce no se ven, y
	## el peatón completo (prendas en mallas sueltas) hacía que el motor avisara
	## «material is null» al reconstruir la ciudad.
	var d := FutbolistaQ.crear(1.8, "male")
	if not d.is_empty():
		var n: Node3D = d["nodo"]
		b.add_child(n)
		FutbolistaQ.terminar(d, false)
		if (d["anim"] as AnimationPlayer).has_animation("celebrar"):
			(d["anim"] as AnimationPlayer).play("celebrar")
		elif (d["anim"] as AnimationPlayer).has_animation("parado"):
			(d["anim"] as AnimationPlayer).play("parado")
		n.position = p + Vector3(0, 3.0, 0)
		n.scale = Vector3.ONE * 2.9
		n.rotation.y = 0.0
		var bronce := StandardMaterial3D.new()
		bronce.albedo_color = Color(0.55, 0.38, 0.2)
		bronce.metallic = 0.85
		bronce.roughness = 0.35
		_bronce(n, bronce)
	if nombre != "":
		var l := Label3D.new()
		l.text = "A %s\nídolo de %s" % [nombre, String(b.datos.get("club", {}).get("nombre", ""))]
		l.font_size = 48
		l.pixel_size = 0.02
		l.modulate = Color(0.95, 0.85, 0.55)
		l.outline_size = 6
		l.position = p + Vector3(0, 1.6, 2.6)
		b.add_child(l)
	cuenta["estatua"] = nombre

## Todo el cuerpo en bronce y quieto (sin animación: es una estatua).
func _bronce(n: Node, m: Material) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = m
	if n is AnimationPlayer:
		(n as AnimationPlayer).seek(0.35, true)
		(n as AnimationPlayer).speed_scale = 0.0
	for h in n.get_children():
		_bronce(h, m)

## UN MURAL DEL CLUB en una medianera: franjas de sus colores y su nombre.
func _mural(p: Vector3, giro: float) -> void:
	var c1 := b._color_club("c1", Color(0.2, 0.5, 0.3))
	var c2 := b._color_club("c2", Color(1, 1, 1))
	var muro := b._caja_en(p + Vector3(0, 9.0, 0), Vector3(1.0, 18.0, 30.0), _mat["claro"], giro)
	muro.rotation.y = 0.0
	for k in 5:
		var franja := b._caja_en(p + Vector3(0.55, 3.0 + float(k) * 3.4, 0), Vector3(0.1, 2.6, 28.0), b._mat_simple(c1 if k % 2 == 0 else c2, 0.7))
		franja.rotation.x = 0.18
	var l := Label3D.new()
	l.text = String(b.datos.get("club", {}).get("nombre", "")).to_upper()
	l.font_size = 96
	l.pixel_size = 0.05
	l.modulate = Color.WHITE
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0, 0.8)
	l.position = p + Vector3(0.7, 15.0, 0)
	l.rotation.y = PI * 0.5
	b.add_child(l)

func _bandera_mastil(p: Vector3) -> void:
	b._cil_en(p + Vector3(0, 7.0, 0), 0.15, 14.0, _mat["claro"])
	StadiumBuilder._bandera_ondeante(b, p + Vector3(1.6, 12.6, 0), Vector2(3.2, 2.0),
		b._color_club("c1", Color(0.2, 0.5, 0.3)), 0.0, 0.3)

## Cartel de metro: poste con la «M» en un disco del color de la línea.
func _cartel_m(p: Vector3, col: Color) -> void:
	b._cil_en(p + Vector3(0, 2.0, 0), 0.12, 4.0, b._mat_simple(Color(0.3, 0.3, 0.32), 0.5))
	var d := b._cil_en(p + Vector3(0, 4.3, 0), 0.9, 0.15, b._mat_simple(col, 0.4, 0.6))
	d.rotation.x = PI * 0.5
	var l := Label3D.new()
	l.text = "M"
	l.font_size = 96
	l.pixel_size = 0.012
	l.modulate = Color.WHITE
	l.position = p + Vector3(0, 4.3, 0.1)
	l.double_sided = true
	b.add_child(l)

## Las bocas del metro: escalera que baja, barandilla y la «M».
func _bocas_metro() -> void:
	var n := 0
	for linea: Dictionary in lineas_metro:
		if bool(linea.get("elevada", false)):
			continue   ## la elevada tiene sus escaleras al andén
		var col: Color = linea["color"]
		for e: Vector3 in linea["estaciones"]:
			var p := e + Vector3(ANCHO_AV * 0.5 + ACERA + 3.0, 0, ANCHO_AV * 0.5 + ACERA + 3.0)
			b._caja_en(p + Vector3(0, 0.15, 0), Vector3(3.2, 0.3, 7.0), b._mat_simple(Color(0.2, 0.2, 0.22), 0.6))
			for s in 6:
				_lote("acera", p + Vector3(0, -0.2 - float(s) * 0.35, -2.5 + float(s) * 0.9), Vector3(2.6, 0.2, 0.9))
			for lado: float in [-1.0, 1.0]:
				b._caja_en(p + Vector3(lado * 1.7, 0.6, 0), Vector3(0.12, 1.0, 7.0), b._mat_simple(Color(0.55, 0.56, 0.58), 0.3))
			_cartel_m(p + Vector3(2.4, 0, -3.0), col)
			n += 1
	cuenta["bocas_metro"] = n

## Las marquesinas de las paradas de autobús.
func _marquesinas_bus() -> void:
	var n := 0
	for l: Dictionary in lineas_bus:
		for p: Vector3 in l["paradas"]:
			var q := p
			## A la acera más cercana: se aparta del eje de la avenida.
			var dir := Vector3(signf(p.x - snappedf(p.x, CELDA)), 0, signf(p.z - snappedf(p.z, CELDA)))
			if absf(p.x - snappedf(p.x, CELDA)) < absf(p.z - snappedf(p.z, CELDA)):
				q = Vector3(snappedf(p.x, CELDA) + signf(dir.x if dir.x != 0.0 else 1.0) * (ANCHO_AV * 0.5 + ACERA * 0.6), 0, p.z)
			else:
				q = Vector3(p.x, 0, snappedf(p.z, CELDA) + signf(dir.z if dir.z != 0.0 else 1.0) * (ANCHO_AV * 0.5 + ACERA * 0.6))
			b._caja_en(q + Vector3(0, 2.6, 0), Vector3(3.5, 0.15, 1.6), _mat["claro"])
			b._caja_en(q + Vector3(0, 1.3, -0.7), Vector3(3.5, 2.4, 0.08), _mat["vidrio"])
			b._caja_en(q + Vector3(0, 0.55, -0.3), Vector3(2.8, 0.15, 0.5), _mat["tronco"])
			n += 1
	cuenta["paradas_bus"] = n

## Guirnaldas de luces de colores sobre las calles del centro (se encienden
## de noche con `encender`).
var _bombillas: Array[StandardMaterial3D] = []

func _guirnaldas() -> void:
	var colores := [Color(1, 0.3, 0.3), Color(1, 0.85, 0.3), Color(0.3, 0.8, 1), Color(0.4, 1, 0.5), Color(1, 0.45, 0.9)]
	var por_color: Array = []
	for _c in colores:
		por_color.append([] as Array[Transform3D])
	var n := 0
	for t: Dictionary in tramos:
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var m := (a + c) * 0.5
		if not (m.z < NUC_Z0 and absf(m.x) < 450.0) or bool(t["av"]):
			continue
		var vertical := absf(a.x - c.x) < 0.1
		var ancho: float = t["ancho"]
		## Cuatro guirnaldas cruzando la calle a lo largo del tramo.
		for q in 4:
			var p := a.lerp(c, (float(q) + 0.5) / 4.0)
			var e0 := p + (Vector3(-ancho * 0.5 - 1.0, 0, 0) if vertical else Vector3(0, 0, -ancho * 0.5 - 1.0))
			var e1 := p + (Vector3(ancho * 0.5 + 1.0, 0, 0) if vertical else Vector3(0, 0, ancho * 0.5 + 1.0))
			for s in 12:
				var f := float(s) / 11.0
				var pos := e0.lerp(e1, f) + Vector3(0, 7.5 - 1.6 * sin(f * PI), 0)
				(por_color[s % colores.size()] as Array).append(Transform3D(Basis.from_scale(Vector3.ONE * 0.35), pos))
				n += 1
	for k in colores.size():
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colores[k]
		mat.emission_enabled = true
		mat.emission = colores[k]
		mat.emission_energy_multiplier = 0.2
		_bombillas.append(mat)
		var esf := SphereMesh.new()
		esf.radial_segments = 6
		esf.rings = 3
		var lista: Array[Transform3D] = []
		lista.assign(por_color[k])
		_multimesh(esf, mat, lista, Vector3.ONE)
	cuenta["bombillas"] = n

## 0 de día, 1 de noche: guirnaldas, farolas y ventanas lejanas.
func encender(noche: float) -> void:
	for m in _bombillas:
		m.emission_energy_multiplier = lerpf(0.15, 1.4, noche)
	if _farola_luz != null:
		_farola_luz.emission_energy_multiplier = lerpf(0.0, 2.6, noche)
	if _farola_charco != null:
		_farola_charco.albedo_color.a = lerpf(0.0, 0.55, noche)
	if _ventanas_lejanas != null:
		_ventanas_lejanas.emission_energy_multiplier = lerpf(0.0, 0.35, noche)

## OBRAS EN LA CALLE: media calzada cortada con conos, vallas y una zanja.
## Una ciudad de verdad siempre tiene alguna calle levantada.
func _obras_en_calle() -> void:
	var cono := load("res://assets/ciudad/kenney_cars/cone.glb") as PackedScene
	if cono == null:
		return
	var n := 0
	var zanja := b._mat_simple(Color(0.35, 0.27, 0.2), 0.95)
	var valla := b._mat_simple(Color(0.95, 0.55, 0.1), 0.6)
	for t: Dictionary in tramos:
		if bool(t["av"]) or bool(t["puente"]) or _rng.randf() > 0.012:
			continue
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var vertical := absf(a.x - c.x) < 0.1
		var m := (a + c) * 0.5
		var lado := ANCHO_CALLE * 0.25
		var centro := m + (Vector3(lado, 0, 0) if vertical else Vector3(0, 0, lado))
		b._caja_en(centro + Vector3(0, 0.14, 0), Vector3(3.0, 0.06, 16.0) if vertical else Vector3(16.0, 0.06, 3.0), zanja)
		for k in 7:
			var f := float(k) / 6.0 - 0.5
			var p := centro + (Vector3(-lado * 0.9, 0, f * 20.0) if vertical else Vector3(f * 20.0, 0, -lado * 0.9))
			_kit(cono, p + Vector3(0, 0.14, 0), Vector3.ONE * 2.0, 0.0)
		b._caja_en(centro + Vector3(0, 0.6, 0) + (Vector3(0, 0, 10.5) if vertical else Vector3(10.5, 0, 0)), Vector3(3.2, 1.0, 0.2) if vertical else Vector3(0.2, 1.0, 3.2), valla)
		n += 1
	cuenta["obras_calle"] = n

## EL PARQUE EÓLICO en las lomas del noroeste, fuera de la autopista: diez
## molinos de 45 m con las aspas girando (cada uno a su ritmo).
func _parque_eolico() -> void:
	var blanco := b._mat_simple(Color(0.93, 0.94, 0.95), 0.4)
	for k in 10:
		var ang := -2.3 + float(k) * 0.12
		var r := 1750.0 + float(k % 3) * 120.0
		var p := Vector3(cos(ang) * r, 0, sin(ang) * r)
		p.y = b.altura_en(p.x, p.z)
		b._cil_en(p + Vector3(0, 22.5, 0), 1.2, 45.0, blanco, 0.7)
		b._caja_en(p + Vector3(0, 45.5, 0.8), Vector3(2.2, 2.2, 5.0), blanco)
		var g := Girador.new()
		g.vel = 0.8 + float(k % 4) * 0.15
		g.position = p + Vector3(0, 45.5, 3.6)
		g.rotation.y = 0.0
		b.add_child(g)
		for a in 3:
			var pala := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(1.2, 20.0, 0.3)
			pala.mesh = bm
			pala.material_override = blanco
			pala.rotation.z = TAU * float(a) / 3.0
			pala.position = Vector3(sin(TAU * float(a) / 3.0) * -10.0, cos(TAU * float(a) / 3.0) * 10.0, 0)
			g.add_child(pala)
	cuenta["molinos"] = 10

## El depósito de agua de la ciudad: una torre con su tanque, en el oeste.
func _deposito_agua() -> void:
	var p := Vector3(-990, 0, 440)
	var gris := b._mat_simple(Color(0.62, 0.64, 0.66), 0.6)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b._cil_en(p + Vector3(sx * 5.0, 14.0, sz * 5.0), 0.6, 28.0, gris)
	b._cil_en(p + Vector3(0, 33.0, 0), 9.0, 10.0, b._mat_simple(Color(0.85, 0.87, 0.9), 0.4))
	var l := Label3D.new()
	l.text = String(b.datos.get("club", {}).get("nombre", "")).to_upper()
	l.font_size = 72
	l.pixel_size = 0.04
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = b._color_club("c1", Color(0.2, 0.5, 0.3))
	l.outline_size = 10
	l.position = p + Vector3(0, 33.0, 0)
	b.add_child(l)

## Las orillas del río a su paso por el núcleo: paseo y árboles en las dos
## márgenes, entre el anillo exterior y el bulevar.
func _orillas_nucleo() -> void:
	var rx := CityBuilder.RIO_X
	var pts: Array = []
	var z := NUC_Z0 + 20.0
	while z < NUC_Z1 - 20.0:
		if absf(z) > 30.0:   ## el puente del conector
			pts.append(Vector3(rx - 56.0, 0, z))
			pts.append(Vector3(rx + 56.0, 0, z))
		z += 26.0
	_arboles_en(pts, 0.9)
	for lado: float in [-1.0, 1.0]:
		_lote("acera", Vector3(rx + lado * 51.5, 0.1, (NUC_Z0 + NUC_Z1) * 0.5), Vector3(4.0, 0.2, NUC_Z1 - NUC_Z0))

## LAS FAROLAS de la ciudad grande: una cada ~33 m por acera, alternando
## lados. Sin luces de verdad (serían cientos): la cabeza se enciende y un
## charco de luz cálida en el suelo hace el resto, que es lo que se lee de
## noche desde la cámara del mapa.
var _farola_luz: StandardMaterial3D
var _farola_charco: StandardMaterial3D

## El material de las luces de farola: uno solo para toda la ciudad (los
## puentes también lo usan), que la noche enciende.
func _mat_luz_farola() -> StandardMaterial3D:
	if _farola_luz == null:
		_farola_luz = StandardMaterial3D.new()
		_farola_luz.albedo_color = Color(1.0, 0.85, 0.6)
		_farola_luz.emission_enabled = true
		_farola_luz.emission = Color(1.0, 0.78, 0.45)
		_farola_luz.emission_energy_multiplier = 0.0
	return _farola_luz

func _farolas() -> void:
	var postes: Array[Transform3D] = []
	var cabezas: Array[Transform3D] = []
	var charcos: Array[Transform3D] = []
	for t: Dictionary in tramos:
		if bool(t["puente"]):
			continue
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var ancho: float = t["ancho"]
		var vertical := absf(a.x - c.x) < 0.1
		var largo := a.distance_to(c)
		var n := maxi(1, int(largo / 33.0))
		for q in n:
			var p := a.lerp(c, (float(q) + 0.5) / float(n))
			var lado := 1.0 if q % 2 == 0 else -1.0
			var off := (ancho * 0.5 + 0.8) * lado
			var base := p + (Vector3(off, 0, 0) if vertical else Vector3(0, 0, off))
			postes.append(Transform3D(Basis.from_scale(Vector3(0.16, 8.0, 0.16)), base + Vector3(0, 4.0, 0)))
			var hacia := (Vector3(-lado, 0, 0) if vertical else Vector3(0, 0, -lado)) * 1.4
			cabezas.append(Transform3D(Basis.from_scale(Vector3(0.9, 0.3, 0.9)), base + Vector3(0, 8.0, 0) + hacia))
			charcos.append(Transform3D(Basis.from_scale(Vector3(13.0, 1.0, 13.0)), base + hacia * 2.0 + Vector3(0, 0.3, 0)))
	var gris := b._mat_simple(Color(0.25, 0.26, 0.27), 0.5)
	_multimesh(CylinderMesh.new(), gris, postes, Vector3.ONE)
	_multimesh(BoxMesh.new(), _mat_luz_farola(), cabezas, Vector3.ONE)
	_farola_charco = StandardMaterial3D.new()
	_farola_charco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_farola_charco.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_farola_charco.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_farola_charco.albedo_texture = _textura_charco()
	_farola_charco.albedo_color = Color(1.0, 0.75, 0.45, 0.0)
	var pl := PlaneMesh.new()
	pl.size = Vector2(1, 1)
	_multimesh(pl, _farola_charco, charcos, Vector3.ONE)
	cuenta["farolas"] = postes.size()

func _textura_charco() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(float(x) - 31.5, float(y) - 31.5).length() / 32.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(img)

## Los edificios lejanos: cajas con ventanas en un solo MultiMesh.
var _lejanos: Array[Rect2] = []

func _edificios_lejanos() -> void:
	if _lejanos.is_empty():
		return
	var ts: Array[Transform3D] = []
	var cs: Array[Color] = []
	for r in _lejanos:
		_lote("acera", Vector3(r.get_center().x, 0.12, r.get_center().y), Vector3(r.size.x, 0.24, r.size.y))
		for k in 4:
			var o := Vector2((float(k % 2) - 0.5) * r.size.x * 0.5, (float(k / 2) - 0.5) * r.size.y * 0.5)
			var w := r.size.x * _rng.randf_range(0.32, 0.42)
			var f := r.size.y * _rng.randf_range(0.32, 0.42)
			var h := _rng.randf_range(14.0, 48.0)
			ts.append(Transform3D(Basis.from_scale(Vector3(w, h, f)), Vector3(r.get_center().x + o.x, h * 0.5, r.get_center().y + o.y)))
			cs.append([Color(0.85, 0.83, 0.8), Color(0.75, 0.78, 0.82), Color(0.88, 0.8, 0.7), Color(0.7, 0.72, 0.75)][_rng.randi() % 4])
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _textura_ventanas()
	mat.vertex_color_use_as_albedo = true
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(1.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0)
	mat.roughness = 0.7
	## De noche se encienden las ventanas (la misma rejilla, en cálido).
	mat.emission_enabled = true
	mat.emission_texture = _textura_ventanas(true)
	mat.emission = Color(1.0, 0.82, 0.5)
	mat.emission_energy_multiplier = 0.0
	_ventanas_lejanas = mat
	_multimesh(BoxMesh.new(), mat, ts, Vector3.ONE, cs)
	cuenta["edificios"] = int(cuenta.get("edificios", 0)) + ts.size()

var _ventanas_lejanas: StandardMaterial3D

## `luz`: la máscara de las ventanas encendidas (blanco = ventana, unas sí y
## otras no) para la emisión nocturna.
func _textura_ventanas(luz: bool = false) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(Color(0, 0, 0) if luz else Color(1, 1, 1))
	if luz:
		var rr := RandomNumberGenerator.new()
		rr.seed = 99
		for vy in 4:
			for vx in 4:
				if rr.randf() < 0.35:
					for y in range(vy * 16 + 4, vy * 16 + 12):
						for x in range(vx * 16 + 4, vx * 16 + 13):
							img.set_pixel(x, y, Color(1, 1, 1))
		return ImageTexture.create_from_image(img)
	for y in 64:
		for x in 64:
			var vx := (x % 16) >= 4 and (x % 16) < 13
			var vy := (y % 16) >= 4 and (y % 16) < 12
			if vx and vy:
				img.set_pixel(x, y, Color(0.35, 0.45, 0.55))
	return ImageTexture.create_from_image(img)

func _arboles_en(puntos: Array, escala: float) -> void:
	var tr: Array[Transform3D] = []
	var co: Array[Transform3D] = []
	for p: Vector3 in puntos:
		var s := escala * _rng.randf_range(0.8, 1.2)
		tr.append(Transform3D(Basis.from_scale(Vector3(0.35, 4.0, 0.35) * s), p + Vector3(0, 2.0 * s, 0)))
		co.append(Transform3D(Basis.from_scale(Vector3(3.2, 3.6, 3.2) * s), p + Vector3(0, 5.6 * s, 0)))
	_multimesh(CylinderMesh.new(), _mat["tronco"], tr, Vector3.ONE)
	var esf := SphereMesh.new()
	esf.radial_segments = 8
	esf.rings = 5
	_multimesh(esf, _mat["hoja"], co, Vector3.ONE)

## LOTES: las cajas planas que más se repiten (calzadas, aceras, solares,
## césped) se juntan por material en un MultiMesh cada una. Eran miles de
## nodos; así son cuatro.
var _lotes := {}

func _lote(mat: String, pos: Vector3, tam: Vector3) -> void:
	if not _lotes.has(mat):
		_lotes[mat] = [] as Array[Transform3D]
	(_lotes[mat] as Array).append(Transform3D(Basis.from_scale(tam), pos))

func _volcar_lotes() -> void:
	for clave: String in _lotes:
		var lista: Array[Transform3D] = []
		lista.assign(_lotes[clave])
		_multimesh(BoxMesh.new(), _mat[clave], lista, Vector3.ONE)
	_lotes.clear()

## EL MOBILIARIO URBANO (7-10-2026, «agrega cosas que tiene una ciudad real…
## me gustan los detalles, el alcantarillado»): tapas de alcantarilla en los
## carriles, sumideros junto al bordillo, papeleras, bancos, hidrantes,
## contenedores de reciclaje, bolardos en las esquinas, señales de STOP y
## ceda el paso en las calles sin semáforo, kioscos y aparcabicis en las
## avenidas. Todo en lotes (MultiMesh): miles de piezas, pocas llamadas.
func _mobiliario_urbano() -> void:
	var cil := CylinderMesh.new()
	cil.height = 1.0
	cil.top_radius = 0.5
	cil.bottom_radius = 0.5
	cil.radial_segments = 12
	var octo := CylinderMesh.new()
	octo.height = 1.0
	octo.top_radius = 0.5
	octo.bottom_radius = 0.5
	octo.radial_segments = 8
	var caja := BoxMesh.new()
	var tapas: Array[Transform3D] = []
	var sumideros: Array[Transform3D] = []
	var papeleras: Array[Transform3D] = []
	var tapas_pap: Array[Transform3D] = []
	var hidrantes: Array[Transform3D] = []
	var bancos_a: Array[Transform3D] = []
	var bancos_p: Array[Transform3D] = []
	var contenedores: Array[Transform3D] = []
	var cont_col: Array[Color] = []
	var bolardos: Array[Transform3D] = []
	var postes: Array[Transform3D] = []
	var stops: Array[Transform3D] = []
	var cedas: Array[Transform3D] = []
	var kioscos: Array[Transform3D] = []
	var techos_k: Array[Transform3D] = []
	var bicis: Array[Transform3D] = []
	var mesas: Array[Transform3D] = []
	var patas: Array[Transform3D] = []
	var sombrillas: Array[Transform3D] = []
	var somb_col: Array[Color] = []
	var sillas_t: Array[Transform3D] = []
	var vallas: Array[Transform3D] = []
	var valla_col: Array[Color] = []
	var k_tramo := 0
	for t: Dictionary in tramos:
		k_tramo += 1
		if bool(t["puente"]):
			continue
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var ancho: float = t["ancho"]
		var largo := a.distance_to(c)
		if largo < 30.0:
			continue
		var dir := (c - a).normalized()
		var lat := Vector3(-dir.z, 0, dir.x)
		var giro := atan2(dir.x, dir.z)
		var rot := Basis(Vector3.UP, giro)
		var acera := ancho * 0.5 + 2.6
		## Alcantarillas: en el centro de cada carril, cada ~45 m.
		var n := int(largo / 45.0)
		for q in n:
			var p := a + dir * (largo * (float(q) + 0.5) / float(n))
			var carril := ancho * 0.25 * (1.0 if q % 2 == 0 else -1.0)
			tapas.append(Transform3D(Basis.from_scale(Vector3(0.9, 0.05, 0.9)), p + lat * carril + Vector3(0, 0.33, 0)))
		## Sumideros junto a los dos bordillos, cada 25 m.
		n = int(largo / 25.0)
		for q in n:
			var p := a + dir * (largo * (float(q) + 0.5) / float(n))
			for lado: float in [-1.0, 1.0]:
				sumideros.append(Transform3D(rot * Basis.from_scale(Vector3(0.45, 0.04, 1.0)), p + lat * lado * (ancho * 0.5 - 0.35) + Vector3(0, 0.32, 0)))
		## En la acera: papelera, banco e hidrante, alternando lados.
		n = int(largo / 55.0)
		for q in n:
			var f := (float(q) + 0.25) / float(maxi(n, 1))
			var lado := 1.0 if (q + k_tramo) % 2 == 0 else -1.0
			var p := a + dir * (largo * f) + lat * lado * acera
			papeleras.append(Transform3D(Basis.from_scale(Vector3(0.5, 0.95, 0.5)), p + Vector3(0, 0.75, 0)))
			tapas_pap.append(Transform3D(Basis.from_scale(Vector3(0.56, 0.08, 0.56)), p + Vector3(0, 1.26, 0)))
			if q % 2 == 1:
				var pb := a + dir * (largo * (f + 0.12)) + lat * lado * (acera + 0.6)
				var rb := Basis(Vector3.UP, giro + (PI * 0.5 if lado > 0.0 else -PI * 0.5))
				bancos_a.append(Transform3D(rb * Basis.from_scale(Vector3(1.9, 0.08, 0.5)), pb + Vector3(0, 0.75, 0)))
				bancos_a.append(Transform3D(rb * Basis.from_scale(Vector3(1.9, 0.45, 0.07)), pb + Vector3(0, 1.0, 0) + lat * lado * 0.25))
				bancos_p.append(Transform3D(rb * Basis.from_scale(Vector3(0.08, 0.45, 0.45)), pb + Vector3(0, 0.5, 0) + dir * 0.8))
				bancos_p.append(Transform3D(rb * Basis.from_scale(Vector3(0.08, 0.45, 0.45)), pb + Vector3(0, 0.5, 0) - dir * 0.8))
			if q % 3 == 0:
				var ph := a + dir * (largo * (f + 0.06)) + lat * -lado * (ancho * 0.5 + 0.7)
				hidrantes.append(Transform3D(Basis.from_scale(Vector3(0.3, 0.75, 0.3)), ph + Vector3(0, 0.62, 0)))
				hidrantes.append(Transform3D(Basis.from_scale(Vector3(0.42, 0.12, 0.42)), ph + Vector3(0, 1.02, 0)))
				hidrantes.append(Transform3D(rot * Basis.from_scale(Vector3(0.62, 0.12, 0.12)), ph + Vector3(0, 0.8, 0)))
		## Contenedores de reciclaje (vidrio, envases, papel, resto), uno por tramo.
		if k_tramo % 2 == 0:
			var lado2 := 1.0 if k_tramo % 4 == 0 else -1.0
			var pc := a + dir * (largo * 0.62) + lat * lado2 * (ancho * 0.5 - 1.2)
			var colores := [Color(0.2, 0.55, 0.25), Color(0.95, 0.8, 0.15), Color(0.15, 0.35, 0.75), Color(0.35, 0.35, 0.35)]
			for i in 4:
				contenedores.append(Transform3D(rot * Basis.from_scale(Vector3(1.5, 1.5, 1.4)), pc + dir * (float(i) - 1.5) * 1.7 + Vector3(0, 1.05, 0)))
				cont_col.append(colores[i])
		## Las esquinas: bolardos en el borde de la acera.
		for extremo: Vector3 in [a + dir * (ancho * 0.5 + 9.0), c - dir * (ancho * 0.5 + 9.0)]:
			for lado: float in [-1.0, 1.0]:
				for i in 3:
					bolardos.append(Transform3D(Basis.from_scale(Vector3(0.22, 0.9, 0.22)), extremo + lat * lado * (ancho * 0.5 + 0.45) + dir * (float(i) - 1.0) * 1.3 + Vector3(0, 0.75, 0)))
		## Señal al final de las calles sin semáforo: STOP o ceda el paso.
		if not bool(t["av"]):
			var ps := c - dir * (ancho * 0.5 + 12.0) + lat * (ancho * 0.5 + 0.9)
			postes.append(Transform3D(Basis.from_scale(Vector3(0.08, 2.6, 0.08)), ps + Vector3(0, 1.6, 0)))
			var placa := Transform3D(Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(0.75, 0.05, 0.75)), ps + Vector3(0, 2.95, 0) - dir * 0.06)
			if k_tramo % 3 == 0:
				stops.append(placa)
			else:
				cedas.append(placa)
		## Terrazas de bar en las avenidas: mesas con sombrilla en la acera.
		if bool(t["av"]) and largo > 90.0 and k_tramo % 3 == 0:
			for i in 4:
				var pt := a + dir * (largo * 0.2 + float(i) * 3.2) - lat * (ancho * 0.5 + 2.6)
				mesas.append(Transform3D(Basis.from_scale(Vector3(0.9, 0.05, 0.9)), pt + Vector3(0, 0.95, 0)))
				patas.append(Transform3D(Basis.from_scale(Vector3(0.08, 0.7, 0.08)), pt + Vector3(0, 0.6, 0)))
				sombrillas.append(Transform3D(Basis.from_scale(Vector3(2.6, 0.5, 2.6)), pt + Vector3(0, 2.6, 0)))
				somb_col.append([Color(0.85, 0.2, 0.15), Color(0.95, 0.95, 0.9), Color(0.2, 0.45, 0.3), Color(0.95, 0.75, 0.2)][(k_tramo + i) % 4])
				for q in 2:
					sillas_t.append(Transform3D(Basis.from_scale(Vector3(0.45, 0.5, 0.45)), pt + dir * (0.9 if q == 0 else -0.9) + Vector3(0, 0.55, 0)))
		## Vallas publicitarias en algunos cruces de avenida.
		if bool(t["av"]) and k_tramo % 7 == 0:
			var pv := c - dir * (ancho * 0.5 + 20.0) + lat * (ancho * 0.5 + 5.0)
			postes.append(Transform3D(Basis.from_scale(Vector3(0.3, 6.0, 0.3)), pv + Vector3(0, 3.0, 0)))
			vallas.append(Transform3D(rot * Basis.from_scale(Vector3(0.3, 3.2, 7.0)), pv + Vector3(0, 7.2, 0)))
			valla_col.append(Color.from_hsv(fmod(float(k_tramo) * 0.13, 1.0), 0.6, 0.85))
		## En las avenidas: un kiosco y un aparcabicis por tramo largo.
		if bool(t["av"]) and largo > 90.0:
			var pk := a + dir * (largo * 0.4) + lat * (ancho * 0.5 + 2.4)
			kioscos.append(Transform3D(rot * Basis.from_scale(Vector3(2.4, 2.6, 2.0)), pk + Vector3(0, 1.6, 0)))
			techos_k.append(Transform3D(rot * Basis.from_scale(Vector3(3.2, 0.25, 2.8)), pk + Vector3(0, 3.05, 0)))
			for i in 5:
				bicis.append(Transform3D(rot * Basis.from_scale(Vector3(0.06, 0.8, 0.9)), a + dir * (largo * 0.7 + float(i) * 0.7) - lat * (ancho * 0.5 + 1.6) + Vector3(0, 0.7, 0)))
	var hierro := b._mat_simple(Color(0.14, 0.14, 0.15), 0.45)
	hierro.metallic = 0.6
	_multimesh(cil, hierro, tapas, Vector3.ONE)
	_multimesh(caja, b._mat_simple(Color(0.1, 0.1, 0.11), 0.5), sumideros, Vector3.ONE)
	_multimesh(cil, b._mat_simple(Color(0.2, 0.42, 0.25), 0.5), papeleras, Vector3.ONE)
	_multimesh(cil, b._mat_simple(Color(0.12, 0.12, 0.12), 0.5), tapas_pap, Vector3.ONE)
	_multimesh(cil, b._mat_simple(Color(0.85, 0.12, 0.1), 0.4), hidrantes, Vector3.ONE)
	_multimesh(caja, _mat["tronco"], bancos_a, Vector3.ONE)
	_multimesh(caja, hierro, bancos_p, Vector3.ONE)
	_multimesh(caja, null, contenedores, Vector3.ONE, cont_col)
	_multimesh(cil, b._mat_simple(Color(0.2, 0.2, 0.22), 0.5), bolardos, Vector3.ONE)
	_multimesh(cil, b._mat_simple(Color(0.6, 0.62, 0.64), 0.4), postes, Vector3.ONE)
	_multimesh(octo, b._mat_simple(Color(0.8, 0.08, 0.08), 0.5), stops, Vector3.ONE)
	var ceda_m := b._mat_simple(Color(0.95, 0.95, 0.95), 0.5)
	_multimesh(cil, ceda_m, cedas, Vector3.ONE)
	_multimesh(caja, b._mat_simple(Color(0.15, 0.4, 0.3), 0.6), kioscos, Vector3.ONE)
	_multimesh(caja, b._mat_simple(Color(0.1, 0.28, 0.22), 0.6), techos_k, Vector3.ONE)
	_multimesh(caja, hierro, bicis, Vector3.ONE)
	_multimesh(cil, b._mat_simple(Color(0.92, 0.92, 0.9), 0.4), mesas, Vector3.ONE)
	_multimesh(cil, hierro, patas, Vector3.ONE)
	var cono := CylinderMesh.new()
	cono.top_radius = 0.02
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 8
	_multimesh(cono, null, sombrillas, Vector3.ONE, somb_col)
	_multimesh(caja, b._mat_simple(Color(0.35, 0.25, 0.18), 0.6), sillas_t, Vector3.ONE)
	_multimesh(caja, b._mat_simple(Color(0.95, 0.95, 0.95), 0.4, 0.3), vallas, Vector3.ONE)
	if not vallas.is_empty():
		## El cartel de la valla: el color de cada anuncio, encima del marco.
		var anuncios: Array[Transform3D] = []
		for tv in vallas:
			anuncios.append(Transform3D(tv.basis * Basis.from_scale(Vector3(1.4, 0.88, 0.94)), tv.origin))
		_multimesh(caja, null, anuncios, Vector3.ONE, valla_col)
	cuenta["mobiliario"] = tapas.size() + sumideros.size() + papeleras.size() + hidrantes.size() / 3 + bancos_a.size() / 2 \
		+ contenedores.size() + bolardos.size() + postes.size() + kioscos.size() + bicis.size()

## Placas de calle en las esquinas: un poste con dos placas azules (una por
## calle), como en cualquier ciudad. Solo se dibujan de cerca.
func _placas_de_calle() -> void:
	var postes: Array[Transform3D] = []
	var placas: Array[Transform3D] = []
	var cuantas := 0
	for k: Vector2i in vecinos:
		var p: Vector3 = nodos[k]
		if dentro_nucleo(p.x, p.z, 20.0):
			continue
		var lista: Array = vecinos[k]
		var hay_fila := false
		var hay_col := false
		for v: Vector2i in lista:
			if v.y == k.y:
				hay_fila = true
			if v.x == k.x:
				hay_col = true
		var ax := (ANCHO_AV if k.x % 3 == 0 else ANCHO_CALLE) * 0.5 + 1.0
		var az := (ANCHO_AV if k.y % 3 == 0 else ANCHO_CALLE) * 0.5 + 1.0
		var esquina := p + Vector3(ax, 0, az)
		postes.append(Transform3D(Basis.from_scale(Vector3(0.09, 3.4, 0.09)), esquina + Vector3(0, 1.9, 0)))
		for cual in 2:
			if (cual == 0 and not hay_fila) or (cual == 1 and not hay_col):
				continue
			var texto := nombre_fila(k.y) if cual == 0 else nombre_columna(k.x)
			## La placa de la fila mira a lo largo de la fila (se lee desde la calle).
			var giro := 0.0 if cual == 0 else PI * 0.5
			var alto := 3.3 if cual == 0 else 2.75
			var centro := esquina + Vector3(0, alto, 0) + (Vector3(-1.2, 0, 0) if cual == 0 else Vector3(0, 0, -1.2))
			placas.append(Transform3D(Basis(Vector3.UP, giro) * Basis.from_scale(Vector3(2.4, 0.46, 0.05)), centro))
			for cara: float in [1.0, -1.0]:
				var l := Label3D.new()
				l.text = texto
				l.font_size = 34
				l.pixel_size = 0.0055
				l.modulate = Color.WHITE
				l.outline_size = 0
				l.width = 420.0
				l.autowrap_mode = TextServer.AUTOWRAP_OFF
				l.position = centro + Basis(Vector3.UP, giro) * Vector3(0, 0, 0.035 * cara)
				l.rotation.y = giro + (0.0 if cara > 0.0 else PI)
				l.visibility_range_end = 70.0
				b.add_child(l)
				cuantas += 1
	_multimesh(CylinderMesh.new(), b._mat_simple(Color(0.25, 0.27, 0.3), 0.5), postes, Vector3(1, 0.5, 1))
	var azul := b._mat_simple(Color(0.08, 0.22, 0.55), 0.4)
	_multimesh(BoxMesh.new(), azul, placas, Vector3.ONE)
	cuenta["placas_calle"] = cuantas / 2

func _multimesh(malla: Mesh, mat: Material, ts: Array[Transform3D], _esc: Vector3, colores: Array[Color] = []) -> void:
	if ts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colores.is_empty()
	mm.mesh = malla
	mm.instance_count = ts.size()
	for i in ts.size():
		var t := ts[i]
		if _esc != Vector3.ONE:
			t.basis = t.basis * Basis.from_scale(_esc)
		mm.set_instance_transform(i, t)
		if mm.use_colors:
			mm.set_instance_color(i, colores[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	if mat != null:
		mi.material_override = mat
	elif mm.use_colors:
		var m2 := StandardMaterial3D.new()
		m2.vertex_color_use_as_albedo = true
		m2.roughness = 0.8
		mi.material_override = m2
	b.add_child(mi)

# ============================================================================
#  EL TRÁFICO DE LA CIUDAD GRANDE
# ============================================================================

## Circuitos por avenidas (dos sentidos, carril derecho), con sus líneas de
## detención en cada semáforo; las dos líneas de autobús con sus paradas; y
## peatones por las aceras del centro y del este.
func trafico(t: TraficoCiudad, coches: Array, rng: RandomNumberGenerator) -> void:
	t.semaforos = semaforos
	var circuitos := [
		[Vector2(-660, -990), Vector2(660, -990), Vector2(660, -660), Vector2(-660, -660)],
		[Vector2(660, -660), Vector2(990, -660), Vector2(990, 660), Vector2(660, 660)],
		[Vector2(-660, 660), Vector2(660, 660), Vector2(660, 990), Vector2(-660, 990)],
		[Vector2(-990, -660), Vector2(-660, -660), Vector2(-660, 660), Vector2(-990, 660)],
		[Vector2(-1320, -1320), Vector2(1320, -1320), Vector2(1320, 1320), Vector2(-1320, 1320)],
		[Vector2(NUC_X0, NUC_Z0), Vector2(NUC_X1, NUC_Z0), Vector2(NUC_X1, NUC_Z1), Vector2(NUC_X0, NUC_Z1)],
	]
	var por_sentido := int(round(lerpf(4.0, 9.0, b._empuje_club())))
	var n_coches := 0
	for esq: Array in circuitos:
		for sentido in [1.0, -1.0]:
			var pts := _carril(esq, sentido)
			pts = _subir_puentes(pts)
			var id := t.agregar_ruta(b._redondear(pts, 12.0))
			_controles_de(t, id)
			if coches.is_empty():
				continue
			var largo := t.largo_de(id)
			for i in por_sentido:
				var nodo: Node3D = CityBuilder.instanciar_coche(coches[rng.randi() % coches.size()], rng)
				t.agregar_vehiculo(nodo, id, largo * (float(i) + rng.randf() * 0.5) / float(por_sentido), rng.randf_range(10.0, 15.0), 0.0, 0.0)
				t.marcar_cola_al_ultimo()
				n_coches += 1
	cuenta["coches"] = n_coches
	## La autopista: tráfico más rápido, sin semáforos.
	for pts_a: PackedVector3Array in Autopista.rutas():
		var ida := t.agregar_ruta(b._redondear(pts_a, 30.0))
		if coches.is_empty():
			continue
		var largo_a := t.largo_de(ida)
		for i in 12:
			var na: Node3D = CityBuilder.instanciar_coche(coches[rng.randi() % coches.size()], rng)
			t.agregar_vehiculo(na, ida, largo_a * float(i) / 12.0 + rng.randf() * 40.0, rng.randf_range(22.0, 30.0), 0.0, 0.0)
			t.marcar_cola_al_ultimo()
	## Los autobuses.
	var n_bus := 0
	for l: Dictionary in lineas_bus:
		var pts2: PackedVector3Array = _subir_puentes(l["puntos"])
		var id2 := t.agregar_ruta(b._redondear(pts2, 12.0))
		_controles_de(t, id2)
		var paradas: Array = []
		for p: Vector3 in l["paradas"]:
			paradas.append(t.s_mas_cercano(id2, p))
		var largo2 := t.largo_de(id2)
		var col_bus := Color(0.85, 0.15, 0.12) if String(l["nombre"]).contains("10") else Color(0.15, 0.4, 0.8)
		for k in 2:
			var nb: Node3D = CityBuilder.autobus(col_bus, String(l["nombre"]).to_upper())
			t.agregar_vehiculo(nb, id2, largo2 * float(k) * 0.5, 9.0, 0.0, 0.0)
			t.agregar_paradas_al_ultimo(paradas, 7.0)
			t.marcar_cola_al_ultimo()
			n_bus += 1
	cuenta["autobuses"] = n_bus
	## Peatones: la vuelta a varias manzanas por su acera.
	var n_p := 0
	var elegidos := 0
	for bl: Dictionary in bloques:
		if not (String(bl["zona"]) in ["centro", "este"]) or String(bl["uso"]) in ["lejano", "rio"]:
			continue
		if rng.randf() > 0.25:
			continue
		var r: Rect2 = bl["rect"]
		var m := 1.6
		var pts3 := PackedVector3Array([
			Vector3(r.position.x - m, 0.3, r.position.y - m), Vector3(r.end.x + m, 0.3, r.position.y - m),
			Vector3(r.end.x + m, 0.3, r.end.y + m), Vector3(r.position.x - m, 0.3, r.end.y + m)])
		var id3 := t.agregar_ruta(b._redondear(pts3, 3.0))
		for q in 2:
			b._un_peaton(t, rng, id3, rng.randf() * 300.0)
			n_p += 1
		elegidos += 1
		if elegidos >= 16:
			break
	cuenta["peatones"] = n_p

## El recorrido por el carril derecho de un circuito de esquinas.
func _carril(esquinas: Array, sentido: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for e: Vector2 in esquinas:
		pts.append(Vector3(e.x, 0.25, e.y))
	if sentido < 0.0:
		pts.reverse()
	var n := pts.size()
	var sal := PackedVector3Array()
	var carril := ANCHO_AV * 0.25
	for k in n:
		var prev := pts[(k - 1 + n) % n]
		var act := pts[k]
		var sig := pts[(k + 1) % n]
		var d1 := (act - prev).normalized()
		var d2 := (sig - act).normalized()
		var off := (Vector3(-d1.z, 0, d1.x) + Vector3(-d2.z, 0, d2.x)).normalized() * carril * 1.414
		sal.append(act + off)
	return sal

## Mete las rampas y el tablero de cada puente en un recorrido llano.
func _subir_puentes(pts: PackedVector3Array) -> PackedVector3Array:
	var sal := PackedVector3Array()
	var rx := CityBuilder.RIO_X
	var n := pts.size()
	for k in n:
		var a := pts[k]
		var c := pts[(k + 1) % n]
		sal.append(a)
		if absf(a.z - c.z) > 0.5:
			continue
		if not (minf(a.x, c.x) < rx - 64.0 and maxf(a.x, c.x) > rx + 64.0):
			continue
		var dir := signf(c.x - a.x)
		for x: float in [rx - dir * 64.0, rx - dir * 44.0, rx + dir * 44.0, rx + dir * 64.0]:
			var y := 0.25 if absf(x - rx) > 50.0 else PUENTE_ALTO + 0.35
			sal.append(Vector3(x, y, a.z))
	return sal

## Una línea de detención antes de cada semáforo por el que pasa la ruta.
func _controles_de(t: TraficoCiudad, id: int) -> void:
	if semaforos == null:
		return
	for p: Vector3 in cruces_semaforo:
		var s := t.s_mas_cercano(id, p + Vector3(0, 0.25, 0))
		var r_en: Array = t._rutas[id].en(s)
		var q: Vector3 = r_en[0]
		if Vector2(q.x - p.x, q.z - p.z).length() > ANCHO_AV:
			continue
		var dir: Vector3 = r_en[1]
		var eje := 0 if absf(dir.z) > absf(dir.x) else 1
		t.agregar_control(id, s - (ANCHO_AV * 0.5 + 3.0), eje)
