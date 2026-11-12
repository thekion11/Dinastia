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
## `datos/motor_c_piezas.json`. C1 = lo del archivo (League + nuestra decisión con balón); C2 = C1 + locomoción nuestra; C3 = C1 + colocación sin balón nuestra; C4 = C3 + locomoción nuestra (la más barata de CPU: −27 % frente al motor de siempre; es el C4 del líder).
const VARIANTES := {"combinado": [], "combinado_c2": ["locomocion"], "combinado_c3": ["coloca_sin_balon"],
	"combinado_c4": ["coloca_sin_balon", "locomocion"]}

func aplicar_variante(id: String) -> void:
	for k: String in VARIANTES.get(id, []):
		piezas[k] = "siempre"
	if id == "combinado_c4":
		_mejoras_c4 = true
		MejorasC4.preparar(self)

## (11-11, ideas del dueño) desmarques, sprints sin balón y balones largos, SOLO en C4 (`MejorasC4`).
var _mejoras_c4 := false

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
	if _mejoras_c4 and MejorasC4Pared.vuelta(self, p):
		return   ## (12-11) la vuelta de la pared, de primera
	if _mejoras_c4 and t >= _decision_en and (MejorasC4.centro(self, p, _rng) or MejorasC4Pared.ida(self, p, _rng) or MejorasC4.pase_al_mejor(self, p, _rng) or MejorasC4.balon_largo(self, p, _rng)):
		return
	var guardado := equipos
	var antes := _decision_en
	equipos = []
	super(p)
	equipos = guardado
	if _mejoras_c4:
		MejorasC4.encarar_banda(self, p)
		if not is_equal_approx(_decision_en, antes):
			_decision_en = MejorasC4.ritmo_ultimo_tercio(self, p, _decision_en)

## (12-11, sesión 13) con el balón en el aire, el receptor va a donde baja (a la cabeza cerca del área), solo en C4.
func _punto_de_recepcion() -> Vector3:
	if _mejoras_c4:
		var r := MejorasC4.punto_aereo(self)
		if r != Vector3.INF:
			return r
	return super()

func _saque_ensayado(p: Dictionary, tipo: String, lugar: Vector3) -> bool:
	if not _mejoras_c4:
		return false
	if tipo == "falta":
		return MejorasC4.falta_ensayada(self, p, lugar, _rng)
	return tipo == "banda" and MejorasC4.banda_ensayada(self, p, lugar, _rng)

## (12-11, sesión 13) rechaces del portero y goles tras rechace (contadores), solo en C4.
func _parada(p: Dictionary, cruce: Vector3, estirada: bool) -> void:
	super(p, cruce, estirada)
	if _mejoras_c4 and String(poseedor.get("id", "")) != String(p["id"]):
		set_meta("_t_rechace", t)
		_contar("c4_rechace")

func _falta(infractor: Dictionary, victima: Dictionary, prob_tarjeta := 0.25, motivo := "", tipo := "de_pie") -> bool:
	var antes := int(tarjetas_motor[0][0] + tarjetas_motor[0][1] + tarjetas_motor[1][0] + tarjetas_motor[1][1])
	var r := super(infractor, victima, prob_tarjeta, motivo, tipo)
	if _mejoras_c4 and r and String(ultima_falta.get("sancion", "falta")) != "falta":
		for fa: String in ultima_falta.get("factores", []):
			_contar("c4_tarjeta_factor_" + fa)
	if _mejoras_c4 and r:
		var quien := MejorasC4.seguidor_en(self, infractor, victima)
		if quien != "":
			_contar("c4_falta_" + quien)
			if int(tarjetas_motor[0][0] + tarjetas_motor[0][1] + tarjetas_motor[1][0] + tarjetas_motor[1][1]) > antes:
				_contar("c4_tarjeta_" + quien)
	return r

func _gol(en_arco_visita: bool) -> void:
	if _mejoras_c4 and t - float(get_meta("_t_rechace", -99.0)) < 3.0:
		_contar("c4_gol_rechace")
	super(en_arco_visita)

func _radio_entrada(p: Dictionary, victima: Dictionary, base: float) -> float:
	var r := super(p, victima, base)
	if not _mejoras_c4:
		return r
	if MejorasC4.por_detras(self, p, victima):
		return 0.0   ## (12-11) no se entra de pie por detrás (C4_NO_DETRAS)
	return MejorasC4.radio_entrada(self, p, victima, base, r)

func _radio_cabezazo(p: Dictionary) -> float:
	return MejorasC4.RADIO_CABEZA if _mejoras_c4 else super(p)

## (12-11, sesión 13) paciencia ante el tiro lejano, solo en C4.
func _ganas_tiro_extra(p: Dictionary, dist_arco: float, ganas: float, presion: float) -> float:
	return MejorasC4.ganas_tiro(self, p, dist_arco, ganas, presion, _rng) if _mejoras_c4 else ganas

func _forma(p: Dictionary, en_posesion: bool) -> Vector3:
	if not _nuestra("coloca_sin_balon"):
		return super(p, en_posesion)
	var guardado := equipos
	equipos = []
	var r := super(p, en_posesion)
	equipos = guardado
	return r

## HÍBRIDO (11-11, sesión 9, orden 39): las ablaciones de C4 mostraron que NUESTRA colocación sin balón es lo que baja el acierto de pase (84 → 67 %) y
## las cadenas de 5+ (2,3 → 0,5), pero también lo que da el roce (duelos 7,7 → 29, regates 9,7 → 18). Con `C_ATAQUE_LEAGUE=1` el equipo que tiene el balón se
## apoya con el campo de fuerzas de League (triángulos de pase) y el que defiende sigue con la colocación nuestra (marcaje, presión, duelos).
static var ATAQUE_LEAGUE := OS.get_environment("C_ATAQUE_LEAGUE") == "1"

## El apoyo de League se usa hasta el ÚLTIMO TERCIO (fracción del campo, `C_TERCIO`; SIN MEDIR: 0 por defecto = la versión medida): allí vuelve nuestra colocación de ataque (desmarques al área, más
## remates y ocasiones claras). `C_TERCIO=0` = apoyo de League en todo el campo (la primera versión del híbrido).
static var TERCIO := float(OS.get_environment("C_TERCIO")) if OS.get_environment("C_TERCIO") != "" else 0.0
## El estado de League (balón previsto, marcajes, presión) se recalcula cada `CADENCIA_ESTADO` s en el híbrido (SIN MEDIR: 0 por defecto = cada paso, la versión medida; 0,1 es lo que hace League).
static var CADENCIA_ESTADO := float(OS.get_environment("C_CADENCIA_ESTADO")) if OS.get_environment("C_CADENCIA_ESTADO") != "" else 0.0
var _t_estado_liga := 0.0

func _en_ultimo_tercio(p: Dictionary) -> bool:
	var c: Dictionary = poseedor
	if TERCIO <= 0.0 or c.is_empty() or bool(c["es_local"]) != bool(p["es_local"]):
		return false
	return dir_ataque(bool(p["es_local"])) * pos(c).z > LARGO * (1.0 - 2.0 * TERCIO)

func _ia_ataque_sin_balon(p: Dictionary) -> Vector3:
	if ATAQUE_LEAGUE and _nuestra("coloca_sin_balon") and not _en_ultimo_tercio(p):
		return super._ia_ataque_sin_balon(p)
	var r := _sin_flag3(p, true)
	if _mejoras_c4:
		var pared := MejorasC4Pared.desmarque(self, p)
		if pared != Vector3.INF:
			p["correr"] = true
			return pared
		var apoyo := MejorasC4Pared.apoyo(self, p)
		if apoyo != Vector3.INF:
			p["correr"] = pos(p).distance_to(apoyo) > 3.0
			return apoyo
		r = MejorasC4Pared.ancho(self, p, r)
		var sigue := MejorasC4.seguir_tiro(self, p)
		if sigue != Vector3.INF:
			p["correr"] = MejorasC4.SEGUIR_SPRINT or pos(p).distance_to(sigue) > 6.0   ## v2: sin esprintar si ya está cerca
			return sigue
		MejorasC4.sprint(self, p, r)
	return r

func _ia_defensa(p: Dictionary) -> Vector3:
	var r := _sin_flag3(p, false)
	if _mejoras_c4:
		var cont := MejorasC4.contener_colocacion(self, p)
		if cont != Vector3.INF:
			return cont
		MejorasC4.sprint(self, p, r)
	return r

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
		if not ATAQUE_LEAGUE:
			return
		if CADENCIA_ESTADO > 0.0:
			if t < _t_estado_liga:
				return
			_t_estado_liga = t + CADENCIA_ESTADO
	super(delta)

func _estado_league(delta: float) -> void:
	var f3 := MotorLeague.fase3
	if _nuestra("locomocion") and _nuestra("coloca_sin_balon") and not ATAQUE_LEAGUE:
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
	## (11-11, sesión 9, orden 39: mejorar C4) NUESTRA locomoción también con la GUÍA de League: velocidad y rumbo siguen al clip de
	## arranque, frenada o giro y los clips se ven; el portador conserva su «conducir».
	if f3 and _nuestra("locomocion") and LeagueGuia.en_c4:
		LeagueGuia.paso(self, delta)
		LeagueLocomocion.paso(self, delta, false)
