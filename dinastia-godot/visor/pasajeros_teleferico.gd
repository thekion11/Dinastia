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
## En la estación de ARRIBA la losa acaba a 17 m y el suelo está a −0,1: rampa corta y la gente se va por la losa.
const RAMPA_BAJA_CIMA := Vector3(0.0, -0.1, 16.3)
const PLAZA_CIMA := Vector3(0.0, -0.1, 16.9)

var tele: Teleferico
var estacion: Node3D             ## la estación (su transform orienta puerta y andén)
var es_cima := false
var _hecho := {}                 ## {"b0", "s0", "b1", "s1"} -> ya ocurrió en este ciclo
var _ciclo := -1
var _bajaron := false
var _subieron := false
var _andando: Array = []         ## {d, ruta: Array[Vector3], t, dur}

static func crear(t: Teleferico, est: Node3D, cima := false) -> PasajerosTeleferico:
	var p := PasajerosTeleferico.new()
	p.es_cima = cima
	p.name = "PasajerosTeleferico"
	p.tele = t
	p.estacion = est
	t.add_child(p)
	return p

## Instante (s del ciclo) en que la cabina 0 llega abajo, y desde cuándo salen los que suben.
static func llegada() -> float:
	return 2.0 * Teleferico.VIAJE + Teleferico.ESPERA

## Los dos instantes del ciclo en que una cabina llega a CADA estación: la 0 abajo (2V + E) y la 1 abajo (V); arriba, al revés, a la vez.
static func llegadas() -> Array[float]:
	return [llegada(), Teleferico.VIAJE]

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
		_hecho.clear()
	var u := fposmod(tele._t, Teleferico.CICLO)
	for i in llegadas().size():
		var t_ev: float = llegadas()[i]
		## Ventana de 9 s: si la cámara llega tarde no salen de golpe los de una cabina que ya se fue.
		if not _hecho.has("b%d" % i) and u >= t_ev + 0.5 and u < t_ev + 9.0:
			_hecho["b%d" % i] = true
			for k in _cuantos(_cabina_acoplada(), true):   ## (A4) tantas figuras como viajeros bajan de verdad
				_salir(k, true)
		if not _hecho.has("s%d" % i) and u >= t_ev + 4.5 and u < t_ev + 9.5:
			_hecho["s%d" % i] = true
			for k in _cuantos(_cabina_acoplada(), false):
				_salir(k, false)

## Cuántas figuras salen o entran: los viajeros que cambian de verdad; una cabina sin viajeros modelados (calidad baja) deja los dos de siempre.
static func _cuantos(cab: Node3D, baja: bool) -> int:
	var hay := false
	if cab != null:
		for h in cab.get_children():
			if h.has_meta("viajero"):
				hay = true
	return cambiar_viajeros(cab, baja) if hay else 2

## La cabina que está en esta estación ahora (la más cercana).
func _cabina_acoplada() -> Node3D:
	var mejor: Node3D = null
	var d_mejor := INF
	for c: Node3D in tele.cabinas:
		var d := c.global_position.distance_to(estacion.global_position)
		if d < d_mejor:
			d_mejor = d
			mejor = c
	return mejor

## Los que bajan se quitan de la cabina (`baja`: los dos primeros visibles) y los que suben ocupan su sitio (los dos que faltaban): la gente cambia dentro.
static func cambiar_viajeros(cab: Node3D, baja: bool) -> int:
	if cab == null:
		return 0
	var n := 0
	for h in cab.get_children():
		if not (h is Node3D) or not h.has_meta("viajero"):
			continue
		if baja and (h as Node3D).visible and n < 2:
			(h as Node3D).visible = false
			n += 1
		elif not baja and not (h as Node3D).visible and n < 2:
			(h as Node3D).visible = true
			n += 1
	return n

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
		pts = _ruta([PUERTA + Vector3(lado, 0, 0), ANDEN + Vector3(lado * 0.8, 0, 0), RAMPA_ALTA + Vector3(lado * 0.8, 0, 0), _baja() + Vector3(lado * 0.8, 0, 0), _plaza() + Vector3(lado, 0, 0)])
	else:
		pts = _ruta([_plaza() + Vector3(lado, 0, 0), _baja() + Vector3(lado * 0.8, 0, 0), RAMPA_ALTA + Vector3(lado * 0.8, 0, 0), ANDEN + Vector3(lado * 0.8, 0, 0), PUERTA + Vector3(lado, 0, 0)])
	var largo := 0.0
	for i in pts.size() - 1:
		largo += pts[i].distance_to(pts[i + 1])
	var n: Node3D = d["nodo"]
	n.position = pts[0]
	_andando.append({"d": d, "ruta": pts, "t": 0.0, "dur": maxf(largo / VEL, 0.5), "largo": largo})

func _baja() -> Vector3:
	return RAMPA_BAJA_CIMA if es_cima else RAMPA_BAJA

func _plaza() -> Vector3:
	return PLAZA_CIMA if es_cima else PLAZA

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
