class_name MotorTiroLimpio
extends RefCounted
## TIRO POR PROBABILIDAD DE LÍNEA LIMPIA (03-11-2026, IA F6 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`; idea de
## League-Soccer `GetOnTheBallCommands`: tres puntos del arco, `odds^0,5 + azar`, escrita aparte). Antes el tiro apuntaba a un
## palo y a una altura AL AZAR, sin mirar al portero ni a los defensas que tapaban la línea. Ahora se puntúan tres puntos del
## arco (palo izquierdo, centro, palo derecho) por la distancia al portero y por los rivales que cruzan la línea de tiro, y se
## apunta al mejor (con algo de azar). Además las ganas de tirar suben con la línea limpia y bajan si está tapada.
## `SIN_TIRO_LIMPIO=1` = el apunte al azar de antes.
const PUNTOS := [-0.82, 0.0, 0.82]       ## fracción del medio arco útil
const RADIO_BLOQUEO := 1.7                ## un rival a menos de esto de la línea de tiro la tapa
const DIST_PORTERO := 3.6                 ## el portero a más de esto del punto = punto libre
const AZAR := 0.18
static var _sin := OS.has_environment("SIN_TIRO_LIMPIO")

static func _portero_rival(m: MotorJugable, p: Dictionary) -> Dictionary:
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) != bool(p["es_local"]) and bool(q["por"]):
			return q
	return {}

## Probabilidad (0-1) de que el tiro a la fracción `f` del arco no sea tapado ni esté al alcance del portero.
static func limpieza(m: MotorJugable, p: Dictionary, f: float, con_portero := true) -> float:
	var arco := m._arco_rival(p)
	var desde := m.pos(p)
	var punto := Vector3(f * (m.PALO - 0.35), 0, arco.z)
	var odds := 1.0
	var por := _portero_rival(m, p) if con_portero else {}
	if not por.is_empty():
		odds *= clampf(absf(m.pos(por).x - punto.x) / DIST_PORTERO, 0.15, 1.0)
	var seg := Vector2(punto.x - desde.x, punto.z - desde.z)
	var largo := seg.length()
	if largo < 0.5:
		return odds
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == bool(p["es_local"]) or bool(q["por"]):
			continue
		var v := Vector2(m.pos(q).x - desde.x, m.pos(q).z - desde.z)
		var t := clampf(v.dot(seg) / (largo * largo), 0.0, 1.0)
		if t <= 0.02 or t >= 0.98:
			continue
		var d := (v - seg * t).length()
		if d < RADIO_BLOQUEO:
			odds *= clampf(d / RADIO_BLOQUEO, 0.1, 1.0)
	return odds

## Mejor punto: devuelve [fracción, limpieza]. Con la bandera apagada: [0, -1].
static func mejor(m: MotorJugable, p: Dictionary) -> Array:
	if _sin:
		return [0.0, -1.0]
	var best_f := 0.0
	var best_s := -999.0
	var best_o := 0.0
	for f: float in PUNTOS:
		var o := limpieza(m, p, f)
		var s := sqrt(o) + m._rng.randf() * AZAR
		if s > best_s:
			best_s = s
			best_f = f
			best_o = o
	return [best_f, best_o]

static func activo() -> bool:
	return not _sin

## Factor sobre las ganas de tirar según la línea más limpia (0,7 tapada .. 1,15 limpia).
static func factor_ganas(limpia: float) -> float:
	return lerpf(0.7, 1.15, clampf(limpia, 0.0, 1.0))

## EL TIRO NO SIEMPRE SALE BIEN (03-11-2026, ciclo 7 de la sesión líder: en el motor el 68 % de los tiros iban a puerta; en el fútbol real, ≈33 %).
## Con la bandera `TIRO_REAL=1` cada remate puede fallar por mala ejecución, con probabilidad creciente con la DISTANCIA y la PRESIÓN, y por BLOQUEO si un
## defensa tapa la línea de tiro. Un tiro fallido se va fuera de los palos o por encima del larguero; cuenta como tiro pero no va a puerta. ENCENDIDO por defecto (`TIRO_REAL=0` lo apaga). Fuente de las cifras objetivo: ≈25 tiros entre los dos equipos y ≈10 % de acierto (Premier League, estadística publicada).
static var FALLO_BASE := float(OS.get_environment("TIRO_FALLO_BASE")) if OS.get_environment("TIRO_FALLO_BASE") != "" else 0.07      ## perillas para barrer (3-11)
static var FALLO_POR_METRO := float(OS.get_environment("TIRO_FALLO_METRO")) if OS.get_environment("TIRO_FALLO_METRO") != "" else 0.008
const FALLO_PRESION := 0.15
const BLOQUEO_MAX := 0.7
static var _real := OS.get_environment("TIRO_REAL") != "0"   ## ENCENDIDO por defecto desde el 3-11 (ciclo 7, medido en 32 partidos); `TIRO_REAL=0` = el motor de antes

static func probabilidad_fallo(m: MotorJugable, p: Dictionary, destino: Vector3, lejos: float, presion: float) -> float:
	var f := clampf(destino.x / maxf(m.PALO - 0.35, 0.1), -1.0, 1.0)
	var bloqueo := (1.0 - limpieza(m, p, f, false)) * BLOQUEO_MAX
	var ejecucion := FALLO_BASE + FALLO_POR_METRO * lejos + (FALLO_PRESION if presion < 1.8 else 0.0)
	return clampf(1.0 - (1.0 - bloqueo) * (1.0 - ejecucion), 0.0, 0.95)

## Devuelve el destino del remate, desviado fuera o por encima si falla (con la bandera apagada, el mismo).
static func fallar(m: MotorJugable, p: Dictionary, destino: Vector3, lejos: float, presion: float) -> Vector3:
	if not _real:
		return destino
	if m._rng.randf() >= probabilidad_fallo(m, p, destino, lejos, presion):
		return destino
	var d := destino
	## Un tiro RASO (LT + B) nunca se va por encima del larguero: si falla, solo hacia los lados (s3p_salida_centros: «el tiro raso no pasa de 0,8 m»).
	if m._mod_tiro == "raso" or m._rng.randf() < 0.6:
		var lado := signf(d.x) if absf(d.x) > 0.3 else (1.0 if m._rng.randf() < 0.5 else -1.0)
		d.x = lado * (m.PALO + m._rng.randf_range(0.4, 3.0))   ## fuera de los palos
	else:
		d.y = m.LARGUERO + m._rng.randf_range(0.4, 2.2)         ## por encima del larguero
	return d

## ALCANCE DEL TIRO (ciclo 7): con `TIRO_REAL=1` la IA tira desde más lejos (el 40 % de los tiros reales vienen de fuera del área; aquí solo el 16 %),
## con la distancia máxima y el divisor de las ganas multiplicados por `TIRO_ALCANCE` (1,2 por defecto). Apagado devuelve `x` tal cual.
static var ALCANCE_K := float(OS.get_environment("TIRO_ALCANCE")) if OS.get_environment("TIRO_ALCANCE") != "" else 1.25

static func alcance(x: float) -> float:
	return x * ALCANCE_K if _real else x

## BONO DE AREA (ciclo 7): con `TIRO_REAL=1`, dentro de `AREA_BONO` m del arco las ganas de tirar suben `TIRO_BONO` (0,25 por defecto), para que el reparto de tiros se
## parezca al real (≈60 % desde dentro del área; el motor tiraba sobre todo de lejos). Apagado suma 0,0.
const AREA_BONO := 18.0
static var BONO_K := float(OS.get_environment("TIRO_BONO")) if OS.get_environment("TIRO_BONO") != "" else 0.25

static func bono_area(dist_arco: float) -> float:
	return BONO_K if (_real and dist_arco < AREA_BONO) else 0.0
