class_name LeagueMovimiento
extends RefCounted
## LA ELECCIÓN DE ARRANQUES, FRENADAS Y GIROS DE LEAGUE-SOCCER (10-11-2026, fase 4c de `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`;
## Apache 2.0, ver `terceros/league_soccer/`). Copia de `HumanoidBase::SelectAnim` para el movimiento: se quedan las animaciones
## cuya velocidad de entrada y cuyo ángulo del cuerpo de entrada son los del jugador (consulta estricta de `CrudeSelection`), gana
## el mejor «cuadrante» de movimiento (`_KeepBestDirectionAnims`: `GetMovementSimilarity` con `CalculateBiasForFastCornering` y
## las direcciones preferidas) y, dentro de él, la que deja el cuerpo mirando más cerca de donde quiere mirar
## (`_KeepBestBodyDirectionAnims` / `CompareBodyDirectionSimilarity`). Datos: `datos/league_movimiento.json`
## (`herramientas/league_movimiento.py`); el espejo (`…_espejo`) es el mismo clip con los ángulos cambiados de signo.
## Marco de League: adelante = la marcha (0, -1); ángulo positivo = a la izquierda (como nuestro giro en Y).
## El CUERPO puede ir girado respecto a la marcha (las «angled»): 0, ±45 o ±135 grados (`allowedBodyDirAngles`).

const IDLE := 0.0
const DRIBBLE := 3.5
const WALK := 5.0
const SPRINT := 8.0
const IDLE_DRIBBLE := 1.8
const DRIBBLE_WALK := 4.4
const WALK_SPRINT := 6.2
## Las direcciones preferidas del original (0, ±20, ±45, ±90, ±135, ±180 grados) y las del cuerpo (0, ±45, ±135).
const PREFERIDAS := [0.0, 0.111, -0.111, 0.25, -0.25, 0.5, -0.5, 0.75, -0.75, 0.999, -0.999]
const CUERPOS := [0.0, 0.25, -0.25, 0.75, -0.75]
const CONTRABANDO := 0.1 * PI   ## `maxAngleSmuggle`

static var _clips: Array = []
static var _plantillas: Dictionary = {}
static var _por_entrada: Dictionary = {}   ## "velocidad|cuerpo" de entrada → clips (la consulta estricta, precalculada)

## `RangeVelocity`: la velocidad escalonada (0 / 3,5 / 5 / 8).
static func rango(v: float) -> float:
	if v >= WALK_SPRINT:
		return SPRINT
	if v >= DRIBBLE_WALK:
		return WALK
	if v >= IDLE_DRIBBLE:
		return DRIBBLE
	return IDLE

static func clips() -> Array:
	if _clips.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://datos/league_movimiento.json"))
		if d is Dictionary:
			for n: String in d:
				var f: Dictionary = d[n]
				for espejo in [false, true]:
					var s := -1.0 if espejo else 1.0
					var c := {"nombre": n + ("_espejo" if espejo else ""), "entra": rango(float(f["entra"])),
						"sale": rango(float(f["sale"])), "ang": float(f["ang"]) * s, "cuerpo": float(f["cuerpo"]) * s,
						"cuerpo_ini": float(f["cuerpo_ini"]) * s, "reposo": int(f["reposo"]), "largo": float(f["largo"])}
					## `GetOutgoingBodyAngle`: el cuerpo al salir, respecto a la marcha de salida (parado, 0).
					c["cuerpo_sale"] = wrapf(float(c["cuerpo"]) - float(c["ang"]), -PI, PI) if float(c["sale"]) >= IDLE_DRIBBLE else 0.0
					c["pref"] = preferida(float(c["ang"]))
					c["cuerpo_ini_q"] = cuerpo_permitido(float(c["cuerpo_ini"]))
					if bool(f.get("plantilla", false)):
						_plantillas[c["nombre"]] = c
					else:
						_clips.append(c)
						var k := _clave(float(c["entra"]), float(c["cuerpo_ini_q"]))
						if not _por_entrada.has(k):
							_por_entrada[k] = []
						(_por_entrada[k] as Array).append(c)
	return _clips

static func _clave(vel: float, cuerpo: float) -> String:
	return "%d|%d" % [roundi(vel * 10.0), roundi(cuerpo / PI * 180.0)]

## La plantilla (paso estable) de una clase de velocidad con el cuerpo a `cuerpo` (rad), o "" si el original no la tiene.
## El ciclo es el paso con el pie derecho y, para el izquierdo, el espejo de la plantilla con el cuerpo al otro lado.
static var _cache_plantilla := {}

static func plantilla(vel: float, cuerpo: float) -> Array:
	var k := roundi(vel * 10.0) * 1000 + roundi(cuerpo / PI * 180.0)
	if not _cache_plantilla.has(k):
		_cache_plantilla[k] = _plantilla(vel, cuerpo)
	return _cache_plantilla[k]

static func _plantilla(vel: float, cuerpo: float) -> Array:
	clips()
	var clase: String = {DRIBBLE: "dribble", WALK: "walk"}.get(vel, "")
	var g := roundi(absf(cuerpo) / PI * 180.0)
	if clase == "" or g == 0:
		return []
	var nombre := "ls_templates__%sD%03d" % [clase, g]
	var derecha := nombre + ("" if cuerpo < 0.0 else "_left")
	var otra := nombre + ("_left" if cuerpo < 0.0 else "") + "_espejo"
	if not _plantillas.has(derecha) or not _plantillas.has(otra):
		return []
	return [derecha, otra]

## `ForceIntoPreferredDirectionVec`: la dirección preferida más cercana (por producto escalar).
static func preferida(ang: float) -> Vector2:
	return Vector2(0, -1).rotated(_cercana(ang, PREFERIDAS))

## `ForceIntoAllowedBodyDirectionAngle`: el ángulo de cuerpo permitido más cercano (0, ±45, ±135; las fronteras son los puntos
## medios, 22,5° y 90°: lo mismo que buscar el de mayor producto escalar, sin recorrer la lista).
static func cuerpo_permitido(ang: float) -> float:
	var a := wrapf(ang, -PI, PI)
	if absf(a) < 0.125 * PI:
		return 0.0
	return (0.25 * PI if absf(a) < 0.5 * PI else 0.75 * PI) * (1.0 if a > 0.0 else -1.0)

static func _cercana(ang: float, lista: Array) -> float:
	var dir := Vector2(0, -1).rotated(ang)
	var mejor := 0.0
	var md := -2.0
	for f: float in lista:
		var dt := Vector2(0, -1).rotated(f * PI).dot(dir)
		if dt > md:
			md = dt
			mejor = f * PI
	return mejor

## El cuerpo que admite cada velocidad (L `CalculateFactualSpatialState`): a toda carrera casi de frente (< 22,5°), al trote rápido
## de lado pero no hacia atrás (< 90°); parado, de frente.
static func cuerpo_posible(vel: float, cuerpo: float) -> float:
	if vel == IDLE:
		return 0.0
	if vel == SPRINT and absf(cuerpo) >= 0.125 * PI:
		return 0.0
	if vel == WALK and absf(cuerpo) >= 0.5 * PI:
		return 0.25 * PI * signf(cuerpo)
	return cuerpo_permitido(cuerpo)

## La mirada del jugador sin balón (L `PlayerController::_MovementCommand`, `defaultLookDirection`): la marcha girada hacia el
## balón, menos cuanto más rápido va. `hacia_balon` = ángulo del balón respecto a la marcha (rad). Devuelve el ángulo de la mirada.
static func mirada(hacia_balon: float, vel_deseada: float, vel_actual: float) -> float:
	var t := clampf((minf(vel_deseada, vel_actual) - IDLE_DRIBBLE) / (SPRINT - IDLE_DRIBBLE), 0.0, 1.0)
	var factor := 1.0 - pow(t, 0.5) * 0.3
	return hacia_balon * pow(factor, 0.7)

## `CalculateBiasForFastCornering(actual, deseado, 1, 0.9)`.
static func sesgo_giro(actual: Vector2, deseado: Vector2) -> float:
	var dn := deseado.normalized() if deseado.length() > 0.0001 else actual.normalized()
	var ang := absf(dn.angle_to(actual)) if actual.length() > 0.0001 else 0.0
	var por_giro := sin(ang - 0.5 * PI) * 0.5 + 0.5
	var por_vel := clampf(actual.length() / (SPRINT - 0.5), 0.0, 1.0)
	return por_vel * por_giro * 0.9

## `GetMovementSimilarity` (menor = mejor). `dir` es la dirección deseada relativa a la marcha (unitaria, marco League).
static func similitud(c: Dictionary, dir: Vector2, vel_deseada: float, sesgo: float) -> float:
	var deseado := dir * vel_deseada * (1.0 - sesgo)
	var sale_dir: Vector2 = c["pref"]
	var valor := (deseado - sale_dir * float(c["sale"])).length()
	return valor - absf(dir.dot(sale_dir)) * 4.0

## `CompareBodyDirectionSimilarity` (menor = mejor): dónde acabará mirando el cuerpo (con el «contrabando» de giro hacia la
## dirección deseada, ±18°) frente a donde quiere mirar; un poco de castigo a los cuerpos girados.
static func similitud_cuerpo(c: Dictionary, dir: Vector2, mirar: float) -> float:
	var sale_dir := Vector2(0, -1).rotated(float(c["ang"]))
	var sale := float(c["ang"]) + clampf(sale_dir.angle_to(dir), -CONTRABANDO, CONTRABANDO)
	return absf(angle_difference(mirar, float(c["cuerpo_sale"]) + sale)) + absf(float(c["cuerpo_sale"])) * 0.05

## El clip del original para ir de la velocidad `sp` (con el cuerpo a `cuerpo` de la marcha) a `vel_deseada` hacia `rel`
## (radianes respecto a la marcha, + izquierda), queriendo mirar a `mirar` (NAN: sin preferencia). Devuelve {} si no hay ninguno.
static func elegir(sp: float, rel: float, vel_deseada: float, cuerpo := 0.0, mirar := NAN) -> Dictionary:
	var entra := rango(sp)
	var deseada := rango(vel_deseada)
	var cuerpo_q := cuerpo_permitido(cuerpo) if entra != IDLE else 0.0
	var dir := Vector2(0, -1).rotated(rel)
	var sesgo := sesgo_giro(Vector2(0, -sp), dir * deseada)
	var candidatos: Array = []   ## (los de la consulta estricta: misma velocidad y mismo cuerpo de entrada)
	var mejor := {}
	var mv := INF
	clips()
	for c: Dictionary in _por_entrada.get(_clave(entra, cuerpo_q), []):
		var v := similitud(c, dir, deseada, sesgo) + (0.0 if int(c["reposo"]) == 1 else 0.001)
		candidatos.append(c)
		if v < mv:
			mv = v
			mejor = c
	if mejor.is_empty() or is_nan(mirar):
		return mejor
	## El mismo cuadrante de movimiento (velocidad de salida y dirección preferida) y, dentro, el mejor cuerpo.
	var q_ang: Vector2 = mejor["pref"]
	var mc := INF
	var elegido := mejor
	for c: Dictionary in candidatos:
		if float(c["sale"]) != float(mejor["sale"]) or (c["pref"] as Vector2).dot(q_ang) < 0.999:
			continue
		var r := similitud_cuerpo(c, dir, mirar)
		if r < mc:
			mc = r
			elegido = c
	return elegido

## ¿Es un clip de paso estable (misma velocidad, de frente, el cuerpo igual)? Esos ya los cubren los ciclos.
static func estable(c: Dictionary) -> bool:
	return float(c["entra"]) == float(c["sale"]) and absf(float(c["ang"])) < 0.2 \
		and absf(angle_difference(float(c["cuerpo_ini"]), float(c["cuerpo_sale"]))) < 0.2
