class_name LeagueToques
extends RefCounted
## EL FILTRO DE ALCANCE DE LAS ANIMACIONES DE LEAGUE-SOCCER (10-11-2026, fase 4a de `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`).
## En el original (L `player/humanoid/humanoid.cpp`, GetBestCheatableAnimation y GetBodyBallDistanceAdvantage) una orden de
## interferir, barrer, controlar, pasar o tirar solo se ejecuta si alguna animación de ese tipo TOCA el balón: en su cuadro de
## toque, el balón previsto tiene que estar cerca del punto de toque de la animación (girado a donde mira el jugador). El
## catálogo sale de las animaciones originales con `herramientas/league_toques.py` → `datos/league_toques.json`.
## SIMPLIFICADO (anotado en el plan): el radio usa el factor por tipo, el del cuadro de toque y la bonificación por velocidad
## del original, pero las bonificaciones por cercanía cuerpo-balón se toman fijas (+1,6, su valor típico) y no se deforma el
## área según la dirección del balón que entra. Marco de `LeagueNucleo` (x largo, y ancho, z arriba).

const RUTA := "res://datos/league_toques.json"
## [factor del radio, desplazamiento fijo] por tipo (L humanoid.cpp: radiusFactor 0,3 × factor; radiusCheatOffset).
const RADIO := {"interfere": [1.4, 0.2], "sliding": [0.2, 0.0], "pass": [1.3, 0.15], "highpass": [1.3, 0.15],
	"shot": [1.3, 0.15], "trap": [1.0, 0.0], "ballcontrol": [1.0, 0.0], "deflect": [1.8, 0.4]}
const ORDEN_VEL := ["idle", "dribble", "walk", "sprint"]

static var _cat: Dictionary = {}

static func catalogo() -> Dictionary:
	if _cat.is_empty() and FileAccess.file_exists(RUTA):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
		if d is Dictionary:
			_cat = d
	return _cat

## Clase de velocidad del original (L velocitystate: 1,8 · 4,4 · 6,2 m/s).
static func clase(v: float) -> int:
	if v < LeagueNucleo.CAMBIO_PARADO_CONDUCE:
		return 0
	if v < LeagueNucleo.CAMBIO_CONDUCE_TROTE:
		return 1
	if v < LeagueNucleo.CAMBIO_TROTE_SPRINT:
		return 2
	return 3

## Radio de toque de una animación (simplificado, ver cabecera).
static func radio(tipo: String, cuadro: int, vel: float) -> float:
	var r: Array = RADIO.get(tipo, [1.0, 0.0])
	var bono_vel := 1.0 - LeagueNucleo.normalizado(vel, LeagueNucleo.V_PARADO, LeagueNucleo.V_SPRINT)
	var por_cuadro := pow(float(cuadro) / 24.0, 0.7)
	return 0.3 * float(r[0]) * por_cuadro * (1.0 + 1.6 + bono_vel) + float(r[1])

## ¿Alguna animación de `tipo` toca el balón? `pred` = balón previsto cada 10 ms (marco League, Vector3 con z arriba; índice 0 =
## ahora). Devuelve {anim, ms, punto} de la que toca antes, o {} si ninguna. Se miran la clase de velocidad del jugador y las vecinas.
static func alcanza(tipo: String, pos: Vector2, mirada: Vector2, vel: float, pred: PackedVector3Array) -> Dictionary:
	var por_tipo: Dictionary = catalogo().get(tipo, {})
	if por_tipo.is_empty() or pred.is_empty():
		return {}
	var f := mirada.normalized() if mirada.length() > 0.0 else Vector2(1, 0)
	var izq := Vector2(-f.y, f.x)
	var c := clase(vel)
	var mejor := {}
	for dc: int in [0, -1, 1]:
		var k := c + dc
		if k < 0 or k > 3:
			continue
		for a: Dictionary in por_tipo.get(ORDEN_VEL[k], []):
			var cuadro := int(a["cuadro"])
			if cuadro >= pred.size():
				continue
			if not mejor.is_empty() and cuadro >= int(mejor["ms"]) / 10:
				continue
			var bal: Array = a["balon"]
			var b := pred[cuadro]
			var dz := absf(b.z - float(bal[2]))
			if b.z < 0.5:
				dz = maxf(dz - 0.15, 0.0)   ## L: los balones bajos se pueden hacer con animaciones a ras de suelo
			if dz >= 0.22:
				continue
			## La animación mira a −Y y su izquierda es +X.
			var punto := pos + f * -float(bal[1]) + izq * float(bal[0])
			if Vector2(b.x, b.y).distance_to(punto) < radio(tipo, cuadro, vel):
				mejor = {"anim": a["nombre"], "ms": cuadro * 10, "punto": punto}
	return mejor
