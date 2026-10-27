class_name RedesCiudad
extends RefCounted
## LAS REDES DE LA CIUDAD (27-10-2026): electricidad, agua potable, drenaje y gasolineras.
## Lógica pura (sin nodos): el dibujo 3D está en `visor/redes_ciudad_vista.gd`.
##
## La ciudad se parte en SECTORES de 6x6 celdas (660 m). Cada sector tiene su subestación,
## su ramal de agua y su colector. Cada hora de juego:
##  · LUZ: generan el parque eólico (según viento) y la central de respaldo; si falta energía
##    se cortan sectores por turno rotatorio (el hospital nunca: va con generador propio).
##  · AGUA: la potabilizadora llena el depósito y los sectores gastan según la hora; con el
##    depósito vacío o el ramal roto no hay presión. Las bombas necesitan luz.
##  · DRENAJE: la lluvia llena el colector del sector; si supera su capacidad (sumideros
##    atascados, bomba sin luz) el sector se inunda; sin lluvia se vacía y la depuradora trata.
##  · GAS: cada gasolinera tiene su depósito; consume al repostar, y la cisterna lo repone.
## Todo es determinista: lo aleatorio (averías) sale de la semilla + el contador de horas.

const LADO_SECTOR := 6                       ## celdas por sector
const N_SECTORES := 5                        ## 5x5 (la rejilla va de -12 a 12)
const MW_EOLICO := 1.5                       ## por molino con viento pleno (10 molinos)
const MW_CENTRAL := 20.0                     ## central de respaldo
const MW_SECTOR := 0.9                       ## demanda de un sector sin edificios registrados
const MW_CASAS := 0.55                       ## demanda de las casas de un sector (el resto son sus edificios)
## Edificios de verdad: uso → [nombre, kW, m3/h de agua, ¿generador propio?]
const CONSUMO := {"hospital": ["Hospital", 900, 60, true], "estadio": ["Estadio del club", 1800, 40, false],
	"ayuntamiento": ["Ayuntamiento", 250, 8, false], "comisaria": ["Comisaría", 180, 6, true], "bomberos": ["Bomberos", 200, 10, true],
	"escuela": ["Escuela", 150, 12, false], "instituto": ["Instituto", 170, 14, false], "universidad": ["Universidad", 420, 30, false],
	"mercado": ["Mercado", 220, 14, false], "centro_comercial": ["Centro comercial", 700, 25, false], "cine": ["Cine", 240, 5, false],
	"estacion_central": ["Estación central", 500, 12, false], "gasolinera": ["Gasolinera", 90, 3, false], "puerto": ["Puerto", 600, 20, false],
	"cocheras": ["Cocheras de autobuses", 160, 6, false], "feria": ["Parque de atracciones", 550, 18, false], "casa_grande": ["La Casa Grande", 120, 9, false],
	"universidad_lab": ["Laboratorio", 0, 0, false]}
const REGISTRO_MAX := 14
const HISTORIAL_MAX := 24
const SECTOR_PLANTA := Vector2i(0, 2)        ## sector de la potabilizadora (oeste): sin luz allí no hay bombeo
const AGUA_DEPOSITO := 12000.0               ## m3
const AGUA_PRODUCCION := 520.0               ## m3/h de la potabilizadora
const AGUA_SECTOR := 25.0                    ## m3/h de un sector a media mañana
const COLECTOR := 40.0                       ## mm de agua que aguanta un colector antes de desbordar
const SUMIDERO_MM_H := 14.0                  ## lo que evacúa un colector sano por hora
const GAS_DEPOSITO := 30000.0                ## litros por gasolinera
const PRECIO_LITRO := 1.4

var semilla := 1
var horas := 0                               ## horas de juego simuladas
var viento := 0.5                            ## 0..1
var lluvia := 0.0                            ## mm/h
var cortes := {}                             ## red -> {sector: true} averías puestas
var luz := {}                                ## sector -> bool
var presion := {}                            ## sector -> bool
var agua_nivel := AGUA_DEPOSITO * 0.8
var colector := {}                           ## sector -> mm acumulados
var inundado := {}                           ## sector -> bool
var gas := {}                                ## id gasolinera -> litros
var edificios: Array = []                    ## [{id, nombre, uso, sector, pos, kw, m3h, generador, aislado}]
var historial: Array = []                    ## [{gen, dem, agua, lluvia, sin_luz}] una por hora, las últimas 24
var registro: Array = []                     ## líneas «20:00 …» del centro de mando
var evento := EventoApagon.new()
var clima := ""
var _luz_antes := {}
var _aislados_guardados: Array = []
var averias_azar := true                     ## false en las pruebas: solo las averías puestas a mano
var hora_dia := 0                            ## la última hora simulada (0..23)
var generacion := 0.0
var demanda := 0.0

func _init(s: int = 1) -> void:
	semilla = s
	reiniciar()

func reiniciar() -> void:
	horas = 0
	cortes = {"luz": {}, "agua": {}, "drenaje": {}}
	agua_nivel = AGUA_DEPOSITO * 0.8
	for sec in sectores():
		luz[sec] = true
		presion[sec] = true
		colector[sec] = 0.0
		inundado[sec] = false
	for id in 3:
		gas[id] = GAS_DEPOSITO * 0.7
	recalcular()

static func sectores() -> Array[Vector2i]:
	var r: Array[Vector2i] = []
	for x in N_SECTORES:
		for z in N_SECTORES:
			r.append(Vector2i(x, z))
	return r

## El sector de una celda de la rejilla (-12..12).
static func sector_de(celda: Vector2i) -> Vector2i:
	return Vector2i(clampi((celda.x + 12) / LADO_SECTOR, 0, N_SECTORES - 1), clampi((celda.y + 12) / LADO_SECTOR, 0, N_SECTORES - 1))

## El sector de un punto del mundo (x, z en metros; la celda mide 110 m).
static func sector_en(x: float, z: float) -> Vector2i:
	return sector_de(Vector2i(roundi(x / 110.0), roundi(z / 110.0)))

## El hospital (celda 5,-1) tiene generador: su sector nunca se queda sin luz.
static func es_hospital(sec: Vector2i) -> bool:
	return sec == sector_de(Vector2i(5, -1))

# ============================================================================ AVERÍAS

func averiar(red: String, sec: Vector2i) -> void:
	if cortes.has(red):
		(cortes[red] as Dictionary)[sec] = true

func reparar(red: String, sec: Vector2i) -> void:
	if cortes.has(red):
		(cortes[red] as Dictionary).erase(sec)

func esta_averiado(red: String, sec: Vector2i) -> bool:
	return cortes.has(red) and (cortes[red] as Dictionary).has(sec)

## Hash estable 0..1 de (semilla, hora, sector, red).
func _azar(red: String, sec: Vector2i) -> float:
	return float(absi(hash([semilla, horas, sec.x, sec.y, red])) % 10000) / 10000.0

# ============================================================================ CURVAS

## El tiempo de una hora a partir del clima de la semana (`Mundo.clima()`): {viento 0..1, lluvia mm/h}.
static func tiempo_de(clima: String, hora: int) -> Dictionary:
	var h := posmod(hora, 24)
	match clima:
		"lluvia":
			return {"viento": 0.4, "lluvia": 6.0 if h >= 13 and h <= 20 else 1.0}
		"tormenta":
			return {"viento": 0.95, "lluvia": 22.0 if h >= 12 and h <= 22 else 4.0}
		"viento":
			return {"viento": 0.95, "lluvia": 0.0}
		"calor", "despejado":
			return {"viento": 0.3, "lluvia": 0.0}
	return {"viento": 0.5, "lluvia": 0.0}

## Consumo relativo por hora del día (0.4 de madrugada, picos a las 8 y a las 20).
static func curva(hora: int) -> float:
	var h := float(posmod(hora, 24))
	return 0.4 + 0.45 * exp(-pow(h - 8.0, 2.0) / 8.0) + 0.6 * exp(-pow(h - 20.0, 2.0) / 10.0)

# ============================================================================ SIMULACIÓN

## Avanza `n` horas de juego a la hora `hora` del día. `v` viento 0..1 y `ll` lluvia mm/h.
func pasar(n: int, hora: int, v: float, ll: float, clima_: String = "") -> void:
	clima = clima_
	viento = clampf(v, 0.0, 1.0)
	lluvia = maxf(ll, 0.0)
	for k in maxi(n, 1):
		horas += 1
		_hora(posmod(hora + k, 24))

func _hora(h: int) -> void:
	hora_dia = h
	evento.tick(self, h, clima)
	_averias_al_azar()
	_electricidad(h)
	_agua(h)
	_drenaje()
	_gasolineras(h)
	_apuntar()

func _averias_al_azar() -> void:
	for sec in sectores():
		if not averias_azar:
			continue
		if _azar("luz", sec) < 0.0015:
			averiar("luz", sec)
		if _azar("agua", sec) < 0.001:
			averiar("agua", sec)
		## Una avería se repara sola con el tiempo (cuadrillas municipales).
		for red: String in ["luz", "agua", "drenaje"]:
			if esta_averiado(red, sec) and _azar(red + "_rep", sec) < 0.18 and not (red == "luz" and evento.activo and sec in evento.sectores):
				reparar(red, sec)

func _electricidad(h: int) -> void:
	generacion = MW_EOLICO * 10.0 * viento + MW_CENTRAL
	demanda = 0.0
	var pedidos: Array = []
	for sec in sectores():
		var pide := demanda_sector(sec) * curva(h)
		pedidos.append([sec, pide])
		demanda += pide
	## Reparto: primero el hospital, luego por turno rotatorio según la hora.
	pedidos.sort_custom(func(a, c): return _prioridad(a[0], h) < _prioridad(c[0], h))
	var libre := generacion
	for p: Array in pedidos:
		var sec: Vector2i = p[0]
		var ok := not esta_averiado("luz", sec) and (libre >= float(p[1]) or es_hospital(sec))
		luz[sec] = ok
		if ok:
			libre -= float(p[1])

## MW de un sector a media carga: sus casas más los edificios que tiene conectados (y no aislados).
func demanda_sector(sec: Vector2i) -> float:
	if edificios.is_empty():
		return MW_SECTOR
	var mw := MW_CASAS
	for ed: Dictionary in edificios:
		if ed["sector"] == sec and not bool(ed["aislado"]):
			mw += float(ed["kw"]) / 1000.0
	return mw

## Conecta un edificio real a las redes de su sector.
func registrar_edificio(uso: String, pos: Vector3, nombre: String = "") -> void:
	if not CONSUMO.has(uso):
		return
	var c: Array = CONSUMO[uso]
	edificios.append({"id": edificios.size(), "nombre": nombre if nombre != "" else String(c[0]), "uso": uso, "pos": pos,
		"sector": sector_en(pos.x, pos.z), "kw": int(c[1]), "m3h": int(c[2]), "generador": bool(c[3]), "aislado": false})

## Cómo está un edificio: {luz, agua, inundado, aislado, kw}. Con generador propio no depende de la red eléctrica.
func estado_edificio(ed: Dictionary) -> Dictionary:
	var sec: Vector2i = ed["sector"]
	var aislado := bool(ed["aislado"])
	var con_luz := not aislado and (hay_luz(sec) or bool(ed["generador"]))
	return {"luz": con_luz, "agua": not aislado and hay_agua(sec), "inundado": bool(inundado.get(sec, false)), "aislado": aislado,
		"kw": int(ed["kw"]) if con_luz else 0}

func anotar(texto: String) -> void:
	registro.push_front("%02d:00 %s" % [hora_dia, texto])
	if registro.size() > REGISTRO_MAX:
		registro.resize(REGISTRO_MAX)

## Guarda la hora en la gráfica y deja en el registro lo que cambió desde la hora anterior.
func _apuntar() -> void:
	var sin := 0
	for sec in sectores():
		var ok: bool = luz[sec]
		if not ok:
			sin += 1
		if _luz_antes.has(sec) and bool(_luz_antes[sec]) != ok and not es_hospital(sec):
			anotar("Sector %d·%d %s" % [sec.x, sec.y, "recupera la luz" if ok else "SIN LUZ"])
		_luz_antes[sec] = ok
	if sectores_inundados() > 0 and lluvia > 0.0:
		anotar("%d sectores con agua en la calle" % sectores_inundados())
	historial.append({"gen": generacion, "dem": demanda, "agua": agua_nivel / AGUA_DEPOSITO, "lluvia": lluvia, "sin_luz": sin})
	if historial.size() > HISTORIAL_MAX:
		historial.pop_front()

func _prioridad(sec: Vector2i, h: int) -> int:
	if es_hospital(sec):
		return -1
	return (sec.x * N_SECTORES + sec.y + h) % (N_SECTORES * N_SECTORES)

func _agua(h: int) -> void:
	var gasto := 0.0
	for sec in sectores():
		if presion[sec]:
			gasto += AGUA_SECTOR * curva(h)
	var produce := AGUA_PRODUCCION * (1.0 if hay_luz(SECTOR_PLANTA) else 0.0)
	gasto = minf(gasto, agua_nivel + produce)
	agua_nivel = clampf(agua_nivel + produce - gasto, 0.0, AGUA_DEPOSITO)
	_presiones()

func _presiones() -> void:
	for sec in sectores():
		presion[sec] = agua_nivel > AGUA_DEPOSITO * 0.02 and not esta_averiado("agua", sec) and bool(luz[sec])

## Recalcula luz y presión con las averías de ahora, sin avanzar el reloj.
func recalcular() -> void:
	_electricidad(hora_dia)
	_presiones()

## La cuadrilla arregla todo de golpe (lo hace el cuadro de mando del subsuelo). Devuelve cuántas averías había.
func reparar_todo() -> int:
	var n := 0
	for red: String in cortes:
		var d: Dictionary = cortes[red]
		for sec in d.keys():
			## El disyuntor general saltado no se arregla desde el botón: hay que rearmarlo en la galería.
			if red == "luz" and evento.activo and not evento.rearmado and sec in evento.sectores:
				continue
			d.erase(sec)
			n += 1
	recalcular()
	return n

func _drenaje() -> void:
	for sec in sectores():
		var sano := not esta_averiado("drenaje", sec) and bool(luz[sec])
		var capacidad := SUMIDERO_MM_H * (1.0 if sano else 0.25)
		var nivel: float = colector[sec] + lluvia - capacidad
		colector[sec] = clampf(nivel, 0.0, COLECTOR * 1.5)
		inundado[sec] = colector[sec] >= COLECTOR

## Una gasolinera atiende a ~340 l por hora de tráfico (más en hora punta) y la cisterna repone.
func _gasolineras(h: int) -> void:
	for id in gas.keys():
		var v: float = float(gas[id]) - 340.0 * curva(h)
		if v < GAS_DEPOSITO * 0.2:
			v += GAS_DEPOSITO * 0.5          ## llega la cisterna
		gas[id] = clampf(v, 0.0, GAS_DEPOSITO)

# ============================================================================ PARTIDA

func a_dic() -> Dictionary:
	var c := {}
	for red: String in cortes:
		c[red] = (cortes[red] as Dictionary).keys().map(func(s: Vector2i) -> Array: return [s.x, s.y])
	var col: Array = []
	for sec in sectores():
		col.append(snappedf(float(colector[sec]), 0.01))
	var aislados: Array = []
	for ed: Dictionary in edificios:
		if bool(ed["aislado"]):
			aislados.append(int(ed["id"]))
	return {"v": 1, "semilla": semilla, "horas": horas, "hora_dia": hora_dia, "agua": agua_nivel, "cortes": c, "colector": col,
		"gas": [gas[0], gas[1], gas[2]], "historial": historial.duplicate(true), "registro": registro.duplicate(), "aislados": aislados,
		"evento": evento.a_dic(), "clima": clima, "viento": viento, "lluvia": lluvia}

## Carga una instantánea (partida vieja sin redes = `{}`: se queda como nueva). Los edificios no se guardan (salen de la
## ciudad): `recibir_edificios` los vuelve a conectar y aplica los aislados.
func desde_dic(d: Dictionary) -> void:
	if d.is_empty():
		return
	semilla = int(d.get("semilla", semilla))
	horas = int(d.get("horas", 0))
	hora_dia = int(d.get("hora_dia", 0))
	agua_nivel = clampf(float(d.get("agua", agua_nivel)), 0.0, AGUA_DEPOSITO)
	for red: String in ["luz", "agua", "drenaje"]:
		(cortes[red] as Dictionary).clear()
		for p: Variant in (d.get("cortes", {}) as Dictionary).get(red, []):
			if p is Array and (p as Array).size() == 2:
				(cortes[red] as Dictionary)[Vector2i(int(p[0]), int(p[1]))] = true
	var col: Array = d.get("colector", [])
	var i := 0
	for sec in sectores():
		colector[sec] = float(col[i]) if i < col.size() else 0.0
		inundado[sec] = float(colector[sec]) >= COLECTOR
		i += 1
	var g: Array = d.get("gas", [])
	for id in mini(g.size(), 3):
		gas[id] = clampf(float(g[id]), 0.0, GAS_DEPOSITO)
	historial = (d.get("historial", []) as Array).duplicate(true)
	registro = (d.get("registro", []) as Array).duplicate()
	_aislados_guardados = (d.get("aislados", []) as Array).map(func(x: Variant) -> int: return int(x))
	evento.desde_dic(d.get("evento", {}))
	clima = String(d.get("clima", ""))
	viento = float(d.get("viento", viento))
	lluvia = float(d.get("lluvia", 0.0))
	recibir_edificios(edificios)

func recibir_edificios(lista: Array) -> void:
	edificios = lista
	for ed: Dictionary in edificios:
		ed["aislado"] = int(ed["id"]) in _aislados_guardados
	recalcular()

# ============================================================================ CONSULTAS

func hay_luz(sec: Vector2i) -> bool:
	return bool(luz.get(sec, true))

func hay_agua(sec: Vector2i) -> bool:
	return bool(presion.get(sec, true))

func fraccion_luz() -> float:
	var n := 0
	for sec in luz:
		if luz[sec]:
			n += 1
	return float(n) / float(maxi(luz.size(), 1))

func sectores_inundados() -> int:
	var n := 0
	for sec in inundado:
		if inundado[sec]:
			n += 1
	return n

## Echa gasolina: {litros, coste}. Sin luz en el sector del surtidor, no hay bomba.
func repostar(id: int, sec: Vector2i, litros: float) -> Dictionary:
	if not gas.has(id) or not hay_luz(sec):
		return {"litros": 0.0, "coste": 0}
	var l := minf(litros, float(gas[id]))
	gas[id] = float(gas[id]) - l
	return {"litros": l, "coste": roundi(l * PRECIO_LITRO)}

## Resumen para el móvil / el informe: una línea por red.
func resumen() -> Array[String]:
	var r: Array[String] = []
	r.append("Luz: %d%% de la ciudad con corriente (%.0f de %.0f MW)" % [roundi(fraccion_luz() * 100.0), generacion, demanda])
	r.append("Agua: depósito al %d%%" % roundi(agua_nivel / AGUA_DEPOSITO * 100.0))
	r.append("Drenaje: %d sectores inundados" % sectores_inundados())
	var g := 0.0
	for id in gas:
		g += float(gas[id])
	r.append("Gasolineras: %d%% de existencias" % roundi(g / (GAS_DEPOSITO * float(gas.size())) * 100.0))
	return r
