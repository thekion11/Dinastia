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
	for lado2: float in [-1.0, 1.0]:
		b._caja_en(Vector3(rx, PUENTE_ALTO + 0.7, z + lado2 * (ancho * 0.5 + 0.2)), Vector3(agua1 - agua0 + rampa * 2.0, 0.9, 0.3), hormigon)
	for px: float in [agua0 + 6.0, rx, agua1 - 6.0]:
		b._caja_en(Vector3(px, PUENTE_ALTO * 0.5 - 0.6, z), Vector3(2.2, PUENTE_ALTO, ancho * 0.7), hormigon)
	cuenta["puentes"] = int(cuenta.get("puentes", 0)) + 1

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

func _kit(esc: PackedScene, pos: Vector3, escala: Vector3, giro: float) -> Node3D:
	var n: Node3D = esc.instantiate()
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
			_kit(esc, Vector3(p.x, 0.2, p.z), Vector3(s, s * _rng.randf_range(1.0, 2.0), s), giro)
			u += ancho + _rng.randf_range(0.3, 1.5)
	if con_nave and not _naves.is_empty():
		var s2 := 6.5 * _rng.randf_range(0.9, 1.2)
		_kit(_naves[_rng.randi() % _naves.size()], c + Vector3(0, 0.2, 0), Vector3(s2, s2 * _rng.randf_range(2.0, 3.6), s2), float(_rng.randi() % 4) * PI * 0.5)

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
			_kit(_naves[_rng.randi() % _naves.size()], Vector3(x, 0.2, c.z + fila * r.size.y * 0.27),
				Vector3(s, s * _rng.randf_range(1.6, 2.8), s), 0.0 if fila > 0.0 else PI)
	_arboles_en([c + Vector3(-12, -0.2, 0), c + Vector3(12, -0.2, 0)], 0.8)

## Viviendas con jardín: se guardan y se dibujan todas juntas (MultiMesh).
var _casas_t: Array[Transform3D] = []
var _casas_col: Array[Color] = []
var _techos_t: Array[Transform3D] = []
var _techos_col: Array[Color] = []
var _setos_t: Array[Transform3D] = []

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
			var col := [Color(0.93, 0.89, 0.8), Color(0.86, 0.78, 0.66), Color(0.78, 0.82, 0.86), Color(0.92, 0.84, 0.74), Color(0.8, 0.7, 0.62)][_rng.randi() % 5] as Color
			_casas_t.append(Transform3D(Basis.from_scale(Vector3(ancho, alto, fondo)), Vector3(x, alto * 0.5, z)))
			_casas_col.append(col)
			var tejado := [Color(0.62, 0.28, 0.2), Color(0.35, 0.33, 0.33), Color(0.5, 0.36, 0.26)][_rng.randi() % 3] as Color
			_techos_t.append(Transform3D(Basis.from_scale(Vector3(ancho + 1.0, 3.0, fondo + 1.0)), Vector3(x, alto + 1.5, z)))
			_techos_col.append(tejado)
			## Seto del jardín delantero, hacia la calle.
			var zs := z + lado * (fondo * 0.5 + 5.0)
			_setos_t.append(Transform3D(Basis.from_scale(Vector3(paso_x * 0.9, 1.3, 0.9)), Vector3(x, 0.65, zs)))
	cuenta["casas"] = int(cuenta.get("casas", 0)) + cols * filas

func _casas_multimesh() -> void:
	if _casas_t.is_empty():
		return
	_multimesh(BoxMesh.new(), null, _casas_t, Vector3.ONE, _casas_col)
	var prisma := PrismMesh.new()
	_multimesh(prisma, null, _techos_t, Vector3.ONE, _techos_col)
	_multimesh(BoxMesh.new(), _mat["hoja"], _setos_t, Vector3.ONE)

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
	for k in 14:
		var p := c + Vector3(_rng.randf_range(-0.45, 0.45) * r.size.x, 0, _rng.randf_range(-0.45, 0.45) * r.size.y)
		if absf(p.x - c.x) < 4.0 or absf(p.z - c.z) < 4.0:
			continue
		pts.append(p)
	_arboles_en(pts, 1.0)
	b._rotulo(c + Vector3(0, 14, 0), "🌳 Parque" + (" del Lago" if lago else ""), Color(0.7, 1.0, 0.7), 20)
	b.puntos_clic.append({"k": "ciudad_parque_lago" if lago else "ciudad_parque", "n": "Parque · penales con los chicos", "pos": c, "estado": "ciudad"})

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
			var bus := load(CityBuilder.RUTA_BUS) as PackedScene
			if bus != null:
				for k in 4:
					var n := _kit(bus, c + Vector3(-w * 0.3 + float(k) * w * 0.2, 0.2, f * 0.3), Vector3.ONE * 3.6, 0.0)
					n.name = "Bus"
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
	var d := PeatonQ.crear(rng)
	if not d.is_empty():
		var n: Node3D = d["nodo"]
		b.add_child(n)
		PeatonQ.terminar(d)
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
	_farola_luz = StandardMaterial3D.new()
	_farola_luz.albedo_color = Color(1.0, 0.85, 0.6)
	_farola_luz.emission_enabled = true
	_farola_luz.emission = Color(1.0, 0.78, 0.45)
	_farola_luz.emission_energy_multiplier = 0.0
	_multimesh(BoxMesh.new(), _farola_luz, cabezas, Vector3.ONE)
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
	var bus := load(CityBuilder.RUTA_BUS) as PackedScene
	var n_bus := 0
	for l: Dictionary in lineas_bus:
		var pts2: PackedVector3Array = _subir_puentes(l["puntos"])
		var id2 := t.agregar_ruta(b._redondear(pts2, 12.0))
		_controles_de(t, id2)
		var paradas: Array = []
		for p: Vector3 in l["paradas"]:
			paradas.append(t.s_mas_cercano(id2, p))
		if bus == null:
			continue
		var largo2 := t.largo_de(id2)
		for k in 2:
			var nb: Node3D = bus.instantiate()
			nb.scale = Vector3.ONE * 3.6
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
