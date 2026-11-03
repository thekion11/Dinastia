class_name MotorCarreras
extends RefCounted
## CARRERAS AL ESPACIO CON TEMPORIZADOR (03-11-2026, IA F5 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`; idea de
## League-Soccer `SelectAttackingRunPlayer`/`ApplyAttackingRun`, escrita aparte). Antes TODOS los delanteros se pegaban siempre a
## la línea del fuera de juego: ataque plano y fácil de leer. Ahora, con el equipo atacando y el balón en campo rival o cerca,
## solo UN delantero a la vez hace la carrera: va al hueco más ancho de la defensa rival, durante 2,8-5 s (más corta cuanto más
## urgente la mentalidad), y luego descansa 4-6 s antes de que otro salga. Los demás delanteros mantienen la forma, 3,5 m por
## detrás de la línea, para ofrecer apoyo sin quedar enganchados. La carrera respeta el fuera de juego (nunca pasa de la
## línea). `SIN_CARRERAS=1` = antes (todos a la línea).
const DUR_MIN := 2.8
const DUR_MAX := 5.0
const DESCANSO := 4.0
const FORMA_ATRAS := 3.5
const ROLES := ["DC", "ED", "EI", "SD"]
static var _sin := OS.has_environment("SIN_CARRERAS")

static func _est(m: MotorJugable, local: bool) -> Dictionary:
	var k := "_carrera_%s" % ("l" if local else "v")
	if not m.has_meta(k):
		m.set_meta(k, {"id": "", "hasta": -99.0, "libre": -99.0, "x": 0.0})
	return m.get_meta(k)

static func activo() -> bool:
	return not _sin

## Hueco más ancho (centro en x) entre los defensas rivales y los bordes.
static func hueco(m: MotorJugable, local: bool) -> float:
	var xs: Array = [-m.ANCHO + 4.0, m.ANCHO - 4.0]
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) != local and not bool(q["por"]) and m._rol(q) in ["DFC", "LD", "LI"]:
			xs.append(m.pos(q).x)
	xs.sort()
	var mejor := 0.0
	var cx := 0.0
	for i in xs.size() - 1:
		var w: float = xs[i + 1] - xs[i]
		if w > mejor:
			mejor = w
			cx = (xs[i] + xs[i + 1]) * 0.5
	return cx

## ¿Qué objetivo lleva `p` (delantero atacando)? Devuelve el punto de la carrera, o el de forma si no le toca.
## `linea` = última línea rival (z), `dz` = sentido del ataque.
static func objetivo(m: MotorJugable, p: Dictionary, obj: Vector3, linea: float, dz: float) -> Vector3:
	if _sin or not (m._rol(p) in ROLES):
		return obj
	var local := bool(p["es_local"])
	var e := _est(m, local)
	var yo := String(p["id"])
	if m.t > float(e["hasta"]) and String(e["id"]) != "":
		e["id"] = ""
		e["libre"] = m.t + DESCANSO + fmod(absf(float(hash(yo))), 2.0)
	if String(e["id"]) == "" and m.t >= float(e["libre"]) and not m.poseedor.is_empty() and p != m.poseedor:
		## Elige al delantero (que no lleve el balón) con más campo por delante y más cerca de la línea.
		var mejor := ""
		var ms := -999.0
		for q: Dictionary in m.jugadores:
			if bool(q["es_local"]) == local and q != m.poseedor and m._rol(q) in ROLES:
				var falta := (linea - m.pos(q).z) * dz
				if falta < -2.0 or falta > 28.0:
					continue
				var s := -falta * 0.05 - absf(m.pos(q).x - hueco(m, local)) * 0.03 + fmod(absf(float(hash(String(q["id"]) + str(int(m.t / 8.0))))), 1.0) * 0.4
				if s > ms:
					ms = s
					mejor = String(q["id"])
		if mejor != "":
			var men := float(m._tac(local, "mentalidad") - 1)
			e["id"] = mejor
			e["hasta"] = m.t + lerpf(DUR_MAX, DUR_MIN, clampf((men + 1.0) / 2.0, 0.0, 1.0))
			e["x"] = hueco(m, local)
	if String(e["id"]) == yo:
		p["correr"] = true
		return Vector3(clampf(float(e["x"]), -m.ANCHO + 3.0, m.ANCHO - 3.0), 0, linea - dz * 0.6)
	## Los demás delanteros: forma, algo por detrás de la línea.
	var z := linea - dz * FORMA_ATRAS
	return Vector3(obj.x, 0, z if (z - obj.z) * dz > 0.0 else obj.z)
