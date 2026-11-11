class_name MotorCombinado
extends MotorLeague
## EL MOTOR COMBINADO «C» (11-11-2026, sesión 11; encargo del dueño: comparar tres motores a ciegas).
## Por decisión del líder (11-11, según `comparar_tres_motores_2026-11-11.md`) arranca como «League + NUESTRA decisión con balón»; el resto es el de League-Soccer CON nuestros saques, árbitro, cámaras, celebraciones, porteros y ejecución de golpeos (todo eso
## ya lo hereda `MotorLeague`), pero cada PIEZA del núcleo se puede cambiar por la nuestra («siempre») o dejar la de League («league»),
## para ir ajustándolo según lo que gane cada pieza (`pruebas/comparar_tres_motores.tscn` mide cada pieza por separado, `PIEZA_C=`):
##   decide_con_balon  quién decide con balón (pase, tiro, regate, pánico)        league: `_ia_portador` de League
##   coloca_sin_balon  colocación y movimiento sin balón (formación, marcaje…)    league: `_forma` + estrategias de la fase 3
##   fisica_balon      el balón suelto (gravedad, arrastre, roce de césped)        league: paso fijo de 10 ms
##   locomocion        el cuerpo: toque de conducción, ciclos de animación, robos  league: fase 4 (`LeagueLocomocion`, `_interferir`)
## Cómo se elige «lo nuestro» SIN tocar los archivos de League (los edita la sesión 9): sus ganchos devuelven a `super` cuando
## `equipos` está vacío o la bandera estática `fase3` está apagada; aquí se apagan SOLO durante esa llamada y se restauran al salir.
## Las piezas por defecto: `datos/motor_c_piezas.json`; `MOTOR_C_PIEZAS="locomocion=siempre,fisica_balon=siempre"` las cambia al vuelo.

const PIEZAS: Array[String] = ["decide_con_balon", "coloca_sin_balon", "fisica_balon", "locomocion"]
const RUTA_PIEZAS := "res://datos/motor_c_piezas.json"

var piezas := {"decide_con_balon": "siempre", "coloca_sin_balon": "league", "fisica_balon": "league", "locomocion": "league"}

## Piezas por defecto: el archivo y, encima, la variable de entorno.
static func piezas_por_defecto() -> Dictionary:
	var r := {"decide_con_balon": "siempre", "coloca_sin_balon": "league", "fisica_balon": "league", "locomocion": "league"}
	if FileAccess.file_exists(RUTA_PIEZAS):
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_PIEZAS))
		if j is Dictionary:
			for k: String in PIEZAS:
				if (j as Dictionary).has(k):
					r[k] = _valida(String((j as Dictionary)[k]))
	for par in OS.get_environment("MOTOR_C_PIEZAS").split(",", false):
		var kv := String(par).split("=")
		if kv.size() == 2 and PIEZAS.has(kv[0].strip_edges()):
			r[kv[0].strip_edges()] = _valida(kv[1].strip_edges())
	return r

static func _valida(v: String) -> String:
	return v if v == "siempre" or v == "league" else "league"

func _init() -> void:
	piezas = piezas_por_defecto()

## Las candidatas a C que se prueban a ciegas (informe `comparar_tres_motores_2026-11-11.md`): piezas que se cambian por las nuestras ENCIMA de las de
## `datos/motor_c_piezas.json`. C1 = lo del archivo (League + nuestra decisión con balón); C2 = C1 + locomoción nuestra; C3 = C1 + colocación sin balón nuestra.
const VARIANTES := {"combinado": [], "combinado_c2": ["locomocion"], "combinado_c3": ["coloca_sin_balon"]}

func aplicar_variante(id: String) -> void:
	for k: String in VARIANTES.get(id, []):
		piezas[k] = "siempre"

func _nuestra(pieza: String) -> bool:
	return String(piezas[pieza]) == "siempre"

## Resumen legible: «decide=league, coloca=siempre, …».
func descripcion_piezas() -> String:
	var r: PackedStringArray = []
	for k: String in PIEZAS:
		r.append("%s=%s" % [k, piezas[k]])
	return ", ".join(r)

# ------------------------------------------------------------------ las piezas

func _ia_portador(p: Dictionary) -> void:
	if not _nuestra("decide_con_balon"):
		super(p)
		return
	var guardado := equipos
	equipos = []
	super(p)
	equipos = guardado

func _forma(p: Dictionary, en_posesion: bool) -> Vector3:
	if not _nuestra("coloca_sin_balon"):
		return super(p, en_posesion)
	var guardado := equipos
	equipos = []
	var r := super(p, en_posesion)
	equipos = guardado
	return r

func _ia_ataque_sin_balon(p: Dictionary) -> Vector3:
	return _sin_flag3(p, true)

func _ia_defensa(p: Dictionary) -> Vector3:
	return _sin_flag3(p, false)

## COLOCACIÓN NUESTRA MÁS BARATA (11-11, perfil en `pruebas/perfil_colocacion.tscn`): nuestra colocación sin balón recalculaba el destino de los 20 jugadores de campo
## en CADA paso (~750 µs/paso de los 1 350 del motor). League lo recalcula cada 0,1 s por jugador (`CADENCIA`); aquí igual: el destino de cada jugador se guarda
## `cadencia_coloca` s (escalonado por jugador, para no concentrar el coste en un solo paso) y se recalcula antes si cambia de «ataca/defiende».
## `C_CADENCIA_COLOCA=0` lo apaga (el cálculo de siempre en cada paso). Solo vale para el combinado: el motor de siempre no se toca.
static var CADENCIA_COLOCA := float(OS.get_environment("C_CADENCIA_COLOCA")) if OS.get_environment("C_CADENCIA_COLOCA") != "" else 0.1
var cadencia_coloca := CADENCIA_COLOCA
var _cache_col: Dictionary = {}   ## id del jugador → {t: caduca, ataque, obj, correr}

func _sin_flag3(p: Dictionary, ataque: bool) -> Vector3:
	var f3 := MotorLeague.fase3
	var nuestra := _nuestra("coloca_sin_balon")
	var id := String(p["id"])
	if nuestra and cadencia_coloca > 0.0:
		var c: Dictionary = _cache_col.get(id, {})
		if not c.is_empty() and bool(c["ataque"]) == ataque and float(c["t"]) > t and float(c["t"]) - t <= cadencia_coloca + 0.001:
			p["correr"] = c["correr"]
			return c["obj"]
	if nuestra:
		MotorLeague.fase3 = false
	var r := super._ia_ataque_sin_balon(p) if ataque else super._ia_defensa(p)
	MotorLeague.fase3 = f3
	if nuestra and cadencia_coloca > 0.0:
		var fase := cadencia_coloca if _cache_col.has(id) else cadencia_coloca * (1.0 - float(hash(id) % 3) / 3.0)
		_cache_col[id] = {"t": t + fase, "ataque": ataque, "obj": r, "correr": bool(p["correr"])}
	return r

## La predicción y los marcajes de League solo hacen falta si juega alguna pieza de League que los usa.
func _estado_sin_balon(delta: float) -> void:
	if _nuestra("coloca_sin_balon") and _nuestra("locomocion"):
		return
	super(delta)

func _estado_league(delta: float) -> void:
	var f3 := MotorLeague.fase3
	if _nuestra("locomocion") and _nuestra("coloca_sin_balon"):
		MotorLeague.fase3 = false   ## sin robos por alcance ni estrategias
	super(delta)
	MotorLeague.fase3 = f3

func _interferir() -> void:
	if not _nuestra("locomocion"):
		super()

func _mover_balon(delta: float) -> void:
	var eq := equipos
	var f3 := MotorLeague.fase3
	if _nuestra("fisica_balon"):
		equipos = []   ## el balón suelto lo mueve la física de siempre (el gancho de League devuelve a `super`)
	if _nuestra("locomocion"):
		MotorLeague.fase3 = false   ## sin el toque de conducción de League
	super(delta)
	equipos = eq
	MotorLeague.fase3 = f3

func _mover_jugadores(delta: float) -> void:
	var f3 := MotorLeague.fase3
	if _nuestra("locomocion"):
		MotorLeague.fase3 = false   ## sin los ciclos de animación de League
	super(delta)
	MotorLeague.fase3 = f3
