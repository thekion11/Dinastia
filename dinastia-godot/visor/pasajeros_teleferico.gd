class_name PasajerosTeleferico
extends Node
## LA GENTE DEL TELEFÉRICO (28-10-2026, orden del líder: «trenes y teleférico que suban y bajen gente, como el bus»). Cuando la cabina llega a la
## estación de abajo (`Teleferico.avance`, al final del ciclo, y espera `ESPERA` s) BAJAN dos personas: salen por la puerta de la estación y
## cruzan el andén cubierto hasta la plaza; unos segundos después SUBEN otras dos: vienen de la plaza por el andén, entran por la puerta y
## desaparecen dentro. Solo se montan si la cámara está a menos de `ALCANCE` m. Mismo recurso que el bus: `PeatonVida.nuevo` (la misma persona
## por semilla), sin nodos de más: las figuras se borran al llegar. El reloj es el del teleférico (`tele._t`), así que los tiempos salen de él.

const ALCANCE := 170.0
const VEL := 1.4
const PUERTA := Vector3(0.0, 0.5, 4.7)      ## puerta de la estación, local (+Z = hacia el andén)
const ANDEN := Vector3(0.0, 0.5, 12.5)      ## borde exterior del andén
const RAMPA_ALTA := Vector3(0.0, 0.5, 13.9)  ## entrada de la barandilla, arriba de la rampa
const RAMPA_BAJA := Vector3(0.0, -0.2, 18.2) ## pie de la rampa, sobre el camino
const PLAZA := Vector3(0.0, -0.2, 29.0)      ## fin del camino, hacia donde se van los que bajan

var tele: Teleferico
var estacion: Node3D             ## la estación de abajo (su transform orienta puerta y andén)
var _ciclo := -1
var _bajaron := false
var _subieron := false
var _andando: Array = []         ## {d, ruta: Array[Vector3], t, dur}

static func crear(t: Teleferico, est: Node3D) -> PasajerosTeleferico:
	var p := PasajerosTeleferico.new()
	p.name = "PasajerosTeleferico"
	p.tele = t
	p.estacion = est
	t.add_child(p)
	return p

## Instante (s del ciclo) en que la cabina 0 llega abajo, y desde cuándo salen los que suben.
static func llegada() -> float:
	return 2.0 * Teleferico.VIAJE + Teleferico.ESPERA

static func _mundo(est: Node3D, local: Vector3) -> Vector3:
	return est.global_transform * local

func _process(delta: float) -> void:
	_mover(delta)
	if tele == null or estacion == null or not is_instance_valid(estacion):
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null or cam.global_position.distance_to(estacion.global_position) > ALCANCE:
		return
	var ciclo := floori(tele._t / Teleferico.CICLO)
	if ciclo != _ciclo:
		_ciclo = ciclo
		_bajaron = false
		_subieron = false
	var u := fposmod(tele._t, Teleferico.CICLO)
	if not _bajaron and u >= llegada() + 0.5:
		_bajaron = true
		for k in 2:
			_salir(k, true)
	if not _subieron and u >= llegada() + 4.5:
		_subieron = true
		for k in 2:
			_salir(k, false)

func _persona(sem: int) -> Dictionary:
	return PeatonVida.nuevo(tele.get_parent(), sem)

## k-ésima persona: `baja` = sale por la puerta a la plaza; si no, viene de la plaza y entra.
func _salir(k: int, baja: bool) -> void:
	var sem := 7300 + posmod(hash([_ciclo, k, baja]), 90000)
	var d := _persona(sem)
	if d.is_empty():
		return
	var lado := -0.9 + 1.8 * float(k)
	var pts: Array[Vector3] = []
	if baja:
		pts = _ruta([PUERTA + Vector3(lado, 0, 0), ANDEN + Vector3(lado * 0.8, 0, 0), RAMPA_ALTA + Vector3(lado * 0.8, 0, 0), RAMPA_BAJA + Vector3(lado * 0.8, 0, 0), PLAZA + Vector3(lado, 0, 0)])
	else:
		pts = _ruta([PLAZA + Vector3(lado, 0, 0), RAMPA_BAJA + Vector3(lado * 0.8, 0, 0), RAMPA_ALTA + Vector3(lado * 0.8, 0, 0), ANDEN + Vector3(lado * 0.8, 0, 0), PUERTA + Vector3(lado, 0, 0)])
	var largo := 0.0
	for i in pts.size() - 1:
		largo += pts[i].distance_to(pts[i + 1])
	var n: Node3D = d["nodo"]
	n.position = pts[0]
	_andando.append({"d": d, "ruta": pts, "t": 0.0, "dur": maxf(largo / VEL, 0.5), "largo": largo})

## Los puntos locales de la estación pasados a mundo.
func _ruta(locales: Array) -> Array[Vector3]:
	var r: Array[Vector3] = []
	for l: Vector3 in locales:
		r.append(_mundo(estacion, l))
	return r

func _mover(delta: float) -> void:
	for k in range(_andando.size() - 1, -1, -1):
		var f: Dictionary = _andando[k]
		var n: Node3D = (f["d"] as Dictionary)["nodo"]
		if not is_instance_valid(n):
			_andando.remove_at(k)
			continue
		f["t"] = float(f["t"]) + delta
		var u := clampf(float(f["t"]) / float(f["dur"]), 0.0, 1.0)
		var ruta: Array = f["ruta"]
		var resto := u * float(f["largo"])
		for i in ruta.size() - 1:
			var seg: float = (ruta[i] as Vector3).distance_to(ruta[i + 1])
			if resto <= seg or i == ruta.size() - 2:
				var q := clampf(resto / maxf(seg, 0.001), 0.0, 1.0)
				n.position = (ruta[i] as Vector3).lerp(ruta[i + 1], q)
				if seg > 0.05:
					var dir: Vector3 = (ruta[i + 1] as Vector3) - (ruta[i] as Vector3)
					n.rotation.y = lerp_angle(n.rotation.y, atan2(dir.x, dir.z), 0.25)
				break
			resto -= seg
		if u >= 1.0:
			n.queue_free()
			_andando.remove_at(k)

func _exit_tree() -> void:
	for f: Dictionary in _andando:
		var n: Node = (f["d"] as Dictionary).get("nodo")
		if n != null and is_instance_valid(n):
			n.queue_free()
