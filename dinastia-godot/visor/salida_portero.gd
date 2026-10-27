class_name SalidaPortero
extends RefCounted
## LA SALIDA A LOS CENTROS (semana 3 del plan, «Partido II: porteros», 27-10-2026). Hasta hoy el
## portero solo reaccionaba a tiros que venían a puerta y, con un centro, se quedaba en su
## bisectriz mirando cómo cabeceaba el delantero. Ahora, con el balón en el aire y SIN dueño,
## calcula dónde baja a la altura de sus manos; si cae en su zona (de 0,8 a 11 m de la línea y
## a menos de 14 m del centro del arco) y llega antes que el balón, sale (una decisión por
## patada, según su colocación) y lo atrapa arriba o lo despeja de puño (`_parada`).
## `m` es el `MotorJugable` (sin tipo: el motor está partido en capas y quien llama es una base).

const G := 9.81
const ALTO_MANOS := 2.3
## El aire frena el vuelo: el punto de caída real queda algo más corto que el de la parábola.
const FRENO_AIRE := 0.92
const ZONA_X := 14.0
const ZONA_DESDE := 0.8
const ZONA_HASTA := 11.0

## Adónde va a por el centro (Vector3.INF si no sale).
static func punto(m: Object, gk: Dictionary) -> Vector3:
	if not (m.get("poseedor") as Dictionary).is_empty():
		gk["centro_hasta"] = 0.0
		return Vector3.INF
	var t: float = m.get("t")
	if float(gk.get("centro_hasta", 0.0)) > t:
		return gk["centro_obj"]
	var n_patada: int = m.get("_n_patada")
	var b: Vector3 = (m.get("balon") as Node3D).position
	var v: Vector3 = m.get("vel_balon")
	if b.y < 1.0 or Vector2(v.x, v.z).length() < 6.0 or int(gk.get("_centro_visto", -1)) == n_patada:
		return Vector3.INF
	## Cuándo baja a la altura de las manos: b.y + v.y·t − ½·G·t² = ALTO_MANOS (la raíz de bajada).
	var disc := v.y * v.y - 2.0 * G * (ALTO_MANOS - b.y)
	if disc < 0.0:
		return Vector3.INF
	var tc := (v.y + sqrt(disc)) / G
	if tc < 0.25 or tc > 2.5:
		return Vector3.INF
	var c := b + Vector3(v.x, 0.0, v.z) * tc * FRENO_AIRE
	var arco: Vector3 = m.call("_arco_propio", gk)
	var hondo := (arco.z - c.z) * signf(arco.z)
	if hondo < ZONA_DESDE or hondo > ZONA_HASTA or absf(c.x) > ZONA_X:
		return Vector3.INF
	gk["_centro_visto"] = n_patada
	var a: Dictionary = gk["attr"]
	var vel_salida := 4.8 + float(a.get("rit", 0.5)) * 2.2
	var desde: Vector3 = m.call("pos", gk)
	var llega := Vector2(c.x - desde.x, c.z - desde.z).length() / vel_salida <= tc + 0.1
	var rng: RandomNumberGenerator = m.get("_rng")
	if not llega or rng.randf() > 0.35 + float(a.get("pos", 0.5)) * 0.55:
		return Vector3.INF
	gk["centro_obj"] = Vector3(c.x, 0.0, c.z)
	gk["centro_hasta"] = t + tc + 0.4
	return gk["centro_obj"]

## Ya debajo del balón: lo atrapa arriba (blocaje, según sus manos y su colocación) o lo saca de
## puño hacia fuera, lejos del arco y hacia la banda de la que no vino. No es una «parada» del tiro:
## un centro baja a más de 22 m/s, y `_parada` solo blocaja por debajo de eso.
static func atrapar(m: Object, gk: Dictionary) -> bool:
	if float(gk.get("centro_hasta", 0.0)) <= float(m.get("t")):
		return false
	var b: Vector3 = (m.get("balon") as Node3D).position
	var manos: Vector3 = m.call("pos", gk) + Vector3(0.0, ALTO_MANOS - 0.3, 0.0)
	if b.distance_to(manos) > 1.3:
		return false
	gk["centro_hasta"] = 0.0
	var a: Dictionary = gk["attr"]
	var rng: RandomNumberGenerator = m.get("_rng")
	if rng.randf() < 0.45 + float(a.get("par", 0.5)) * 0.3 + float(a.get("pos", 0.5)) * 0.15:
		m.call("_anim", gk, "blocaje_alto", true)
		m.call("_tomar", gk)
		m.emit_signal("aviso", "¡Atajada!")
		return true
	var arco: Vector3 = m.call("_arco_propio", gk)
	var v: Vector3 = m.get("vel_balon")
	var fuera := Vector3(-signf(v.x + 0.01) * rng.randf_range(4.0, 9.0), rng.randf_range(4.0, 7.0), -signf(arco.z) * rng.randf_range(9.0, 14.0))
	m.set("vel_balon", fuera)
	m.set("penultimo_toque", m.get("ultimo_toque"))
	m.set("ultimo_toque", gk)
	gk["enfriar"] = 0.6
	m.call("_anim", gk, "blocaje_alto", true)
	m.emit_signal("aviso", "¡Despeja de puño!")
	return true
