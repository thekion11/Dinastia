class_name MejorasC4Cabeza
extends RefCounted
## EL REMATE DE CABEZA EN C4 (12-11-2026, sesión 15). Casi no hay goles de cabeza (0-1 cada 12 partidos) y la sesión 13 vio que ir a por
## el centro de cabeza (`C4_AEREO`) quitaba goles porque el cabezazo convierte menos que el control y tiro con el pie. Causa: el cabezazo
## a puerta sale a 14-20 m/s (el portero llega con tiempo) y a un palo al azar (la mitad de las veces al del portero) y a media altura.
## Con `C4_CABEZA=1` el rematador, si el portero está cargado a un palo, cabecea al otro (`P_CONTRARIO`), hacia ABAJO (el bote engaña al
## portero) y con más fuerza (`C4_CABEZA_V` m/s más). Los cabezazos que ya van fuera (`MotorCorner.cabeza`) no se tocan.
## Solo en C4 (`_mejoras_c4`); `motor_jugable_p6._cabezazo` llama aquí y, fuera de C4 o con la bandera apagada, nada cambia (ni el azar).

static var ACTIVO := OS.get_environment("C4_CABEZA") == "1"
static var MAS_V := float(OS.get_environment("C4_CABEZA_V")) if OS.get_environment("C4_CABEZA_V") != "" else 4.0
const P_CONTRARIO := 0.7
static var solo_c4 := true   ## el banco lo apaga para probarlo con un MotorJugable

static func _activo(m: Object) -> bool:
	return ACTIVO and (m.get("_mejoras_c4") == true or not solo_c4)

## A dónde va el cabezazo a puerta.
static func destino(m: Object, p: Dictionary, d: Vector3) -> Vector3:
	if not _activo(m):
		return d
	var palo: float = m.PALO
	if absf(d.x) > palo or d.y > float(m.LARGUERO):
		return d   ## ya va fuera
	var gk := _portero_rival(m, p)
	var r := d
	if not gk.is_empty():
		var gx: float = m.pos(gk).x
		if signf(r.x) == signf(gx) and (m._rng as RandomNumberGenerator).randf() < P_CONTRARIO:
			r.x = -r.x
	r.y = clampf(r.y * 0.5, 0.15, 1.2)
	_contar(m, "c4_cabeza_ajustada")
	return r

## Con qué fuerza sale.
static func velocidad(m: Object, base: float) -> float:
	return base + MAS_V if _activo(m) else base

static func _portero_rival(m: Object, p: Dictionary) -> Dictionary:
	for q: Dictionary in m.jugadores:
		if bool(q["por"]) and bool(q["es_local"]) != bool(p["es_local"]):
			return q
	return {}

static func _contar(m: Object, clave: String) -> void:
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)[clave] = int((m.diag as Dictionary).get(clave, 0)) + 1
