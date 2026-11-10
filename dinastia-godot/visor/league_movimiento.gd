class_name LeagueMovimiento
extends RefCounted
## LA ELECCIÓN DE ARRANQUES, FRENADAS Y GIROS DE LEAGUE-SOCCER (10-11-2026, fase 4c de `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`;
## Apache 2.0, ver `terceros/league_soccer/`). Copia de `HumanoidBase::SelectAnim` para el movimiento: se quedan las animaciones
## cuya velocidad de entrada es la del jugador (consulta estricta de `CrudeSelection`) y gana la de mejor `GetMovementSimilarity`
## (con el sesgo de giro rápido `CalculateBiasForFastCornering` y las direcciones preferidas del original). Datos de cada clip:
## `datos/league_movimiento.json` (`herramientas/league_movimiento.py`); el espejo (`…_espejo`) es el mismo clip con el ángulo
## cambiado de signo. Marco de League: adelante = (0, -1), ángulo positivo = a la izquierda (como nuestro giro en Y).
## Sin la pie de apoyo ni las variantes «angled» (correr de lado mirando a otro punto): eso queda para otra parte.

const IDLE := 0.0
const DRIBBLE := 3.5
const WALK := 5.0
const SPRINT := 8.0
const IDLE_DRIBBLE := 1.8
const DRIBBLE_WALK := 4.4
const WALK_SPRINT := 6.2
## Las direcciones preferidas del original (0, ±20, ±45, ±90, ±135, ±180 grados).
const PREFERIDAS := [0.0, 0.111, -0.111, 0.25, -0.25, 0.5, -0.5, 0.75, -0.75, 0.999, -0.999]

static var _clips: Array = []

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
					_clips.append({"nombre": n + ("_espejo" if espejo else ""), "entra": rango(float(f["entra"])),
						"sale": rango(float(f["sale"])), "ang": float(f["ang"]) * s, "cuerpo": float(f["cuerpo"]) * s,
						"reposo": int(f["reposo"]), "largo": float(f["largo"])})
	return _clips

## `ForceIntoPreferredDirectionVec`: la dirección preferida más cercana (por producto escalar).
static func preferida(ang: float) -> Vector2:
	var dir := Vector2(0, -1).rotated(ang)
	var mejor := Vector2(0, -1)
	var md := -2.0
	for f: float in PREFERIDAS:
		var v := Vector2(0, -1).rotated(f * PI)
		if v.dot(dir) > md:
			md = v.dot(dir)
			mejor = v
	return mejor

## `CalculateBiasForFastCornering(actual, deseado, 1, 0.9)`.
static func sesgo_giro(actual: Vector2, deseado: Vector2) -> float:
	var dn := deseado.normalized() if deseado.length() > 0.0001 else actual.normalized()
	var ang := absf(dn.angle_to(actual)) if actual.length() > 0.0001 else 0.0
	var por_giro := sin(ang - 0.5 * PI) * 0.5 + 0.5
	var por_vel := clampf(actual.length() / (SPRINT - 0.5), 0.0, 1.0)
	return por_vel * por_giro * 0.9

## `GetMovementSimilarity` (menor = mejor). `dir` es la dirección deseada relativa al cuerpo (unitaria, marco League).
static func similitud(c: Dictionary, dir: Vector2, vel_deseada: float, sesgo: float) -> float:
	var deseado := dir * vel_deseada * (1.0 - sesgo)
	var sale_dir := preferida(float(c["ang"]))
	var valor := (deseado - sale_dir * float(c["sale"])).length()
	return valor - absf(dir.dot(sale_dir)) * 4.0

## El clip del original para ir de la velocidad `sp` (cuerpo mirando adelante) a `vel_deseada` hacia `rel` (radianes, + izquierda).
## Devuelve {} si no hay ninguno.
static func elegir(sp: float, rel: float, vel_deseada: float) -> Dictionary:
	var entra := rango(sp)
	var deseada := rango(vel_deseada)
	var dir := Vector2(0, -1).rotated(rel)
	var sesgo := sesgo_giro(Vector2(0, -sp), dir * deseada)
	var mejor := {}
	var mv := INF
	for c: Dictionary in clips():
		if float(c["entra"]) != entra:
			continue
		var v := similitud(c, dir, deseada, sesgo) + (0.0 if int(c["reposo"]) == 1 else 0.001)
		if v < mv:
			mv = v
			mejor = c
	return mejor

## ¿Es un clip de paso estable (misma velocidad, de frente)? Esos ya los cubren nuestros ciclos.
static func estable(c: Dictionary) -> bool:
	return float(c["entra"]) == float(c["sale"]) and absf(float(c["ang"])) < 0.2
