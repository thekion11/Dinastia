class_name PuertaVida
extends Node3D
## PEATONES QUE ABREN PUERTAS (calidad visual P3, 27-10-2026). Las entradas de los edificios con fachada modular registran su
## puerta en `CityBuilder.puertas_vida` ({p: suelo ante la puerta, n: hacia la calle}). Cerca del jugador, de vez en cuando un
## vecino llega andando, tiende la mano (clip «Interact» del pack) y la hoja de la puerta gira hacia dentro; entra y la puerta
## se cierra. Otras veces sale: abre, camina hacia la calle y cierra. Máximo 2 a la vez; nada usa el azar de la partida.

const ALCANCE := 70.0
const MAX_ACTIVAS := 2
const ABIERTA := -100.0   ## grados que gira la hoja (hacia dentro)
const ANCHO_HOJA := 1.3

var expl: ExploradorCiudad
var _hojas := {}        ## índice de puerta → {pivote, abierta: float 0..1, objetivo: float}
var _activas: Array = []   ## {i, entra, fase, t, fig, a, b}
var _t := 4.0
var _cuenta := 0

static func crear(v: VidaCiudad) -> PuertaVida:
	var s := PuertaVida.new()
	s.name = "PuertasVivas"
	s.expl = v.expl
	v.add_child(s)
	return s

static func registrar(b: CityBuilder, pos: Vector3, normal: Vector3) -> void:
	b.puertas_vida.append({"p": pos, "n": normal.normalized()})

func _process(delta: float) -> void:
	_mover(delta)
	if expl == null or not is_instance_valid(expl) or expl.cuerpo == null or expl.cb == null:
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = 9.0
	if _activas.size() >= MAX_ACTIVAS:
		return
	var yo: Vector3 = expl.cuerpo.position
	var mejor := -1
	var mejor_d := ALCANCE
	var ps: Array[Dictionary] = expl.cb.puertas_vida
	for i in ps.size():
		var d := Vector2((ps[i]["p"] as Vector3).x - yo.x, (ps[i]["p"] as Vector3).z - yo.z).length()
		if d < mejor_d and d > 6.0 and not _en_uso(i) and ((i + _cuenta) % 3 == 0):
			mejor = i
			mejor_d = d
	_cuenta += 1
	if mejor >= 0:
		iniciar(mejor, (_cuenta % 2) == 0)

func _en_uso(i: int) -> bool:
	for a: Dictionary in _activas:
		if int(a["i"]) == i:
			return true
	return false

## Empieza la escena: entra (llega por la acera) o sale (la puerta se abre y echa a andar hacia la calle).
func iniciar(i: int, entra: bool) -> void:
	var ps: Array[Dictionary] = expl.cb.puertas_vida
	var p: Vector3 = ps[i]["p"]
	var n: Vector3 = ps[i]["n"]
	_hoja(i, p, n)
	var fig := PeatonVida.nuevo(expl.cb, 7000 + i * 13 + _cuenta)
	if fig.is_empty():
		return
	var a := p + n * 8.0 + n.cross(Vector3.UP) * 3.0 if entra else p - n * 0.6
	var b := p + n * 1.0 if entra else p + n * 9.0 + n.cross(Vector3.UP) * 3.0
	(fig["nodo"] as Node3D).position = Vector3(a.x, p.y, a.z)
	(fig["nodo"] as Node3D).rotation.y = atan2(b.x - a.x, b.z - a.z)
	Mini3D.anim(fig, "caminar", "")
	_activas.append({"i": i, "entra": entra, "fase": 0, "t": 0.0, "fig": fig, "a": Vector3(a.x, p.y, a.z), "b": Vector3(b.x, p.y, b.z), "dur": maxf(a.distance_to(b) / 1.4, 1.0)})
	if not entra:
		(_hojas[i] as Dictionary)["objetivo"] = 1.0

## La hoja de la puerta (se crea la primera vez): pivote en la jamba derecha, 1,3 × 2,3 m de vidrio oscuro con marco.
func _hoja(i: int, p: Vector3, n: Vector3) -> void:
	if _hojas.has(i):
		return
	var lado := Vector3.UP.cross(n)
	var pivote := Node3D.new()
	pivote.transform = Transform3D(Basis(lado, Vector3.UP, n), p + lado * ANCHO_HOJA * 0.5 + n * 0.12)
	expl.cb.add_child(pivote)
	var marco := Mini3D.mat(Color(0.16, 0.14, 0.13), 0.5)
	var cristal := Mini3D.mat(Color(0.35, 0.5, 0.58, 0.55), 0.1)
	Mini3D.caja(pivote, Vector3(-ANCHO_HOJA * 0.5, 1.15, 0), Vector3(ANCHO_HOJA, 2.3, 0.05), cristal)
	Mini3D.caja(pivote, Vector3(-0.03, 1.15, 0), Vector3(0.06, 2.3, 0.08), marco)
	Mini3D.caja(pivote, Vector3(-ANCHO_HOJA, 1.15, 0), Vector3(0.06, 2.3, 0.08), marco)
	Mini3D.caja(pivote, Vector3(-ANCHO_HOJA * 0.5, 2.28, 0), Vector3(ANCHO_HOJA, 0.06, 0.08), marco)
	Mini3D.caja(pivote, Vector3(-ANCHO_HOJA * 0.5, 1.05, 0.05), Vector3(0.04, 0.3, 0.04), Mini3D.mat(Color(0.8, 0.78, 0.7), 0.3))
	_hojas[i] = {"pivote": pivote, "abierta": 0.0, "objetivo": 0.0}

func angulo(i: int) -> float:
	return float((_hojas[i] as Dictionary)["abierta"]) * ABIERTA if _hojas.has(i) else 0.0

func _mover(delta: float) -> void:
	for h: Dictionary in _hojas.values():
		h["abierta"] = move_toward(float(h["abierta"]), float(h["objetivo"]), delta * 2.0)
		(h["pivote"] as Node3D).rotation.y = deg_to_rad(float(h["abierta"]) * ABIERTA)
	for k in range(_activas.size() - 1, -1, -1):
		var s: Dictionary = _activas[k]
		var fig: Dictionary = s["fig"]
		var nodo: Node3D = fig["nodo"]
		if not is_instance_valid(nodo):
			_activas.remove_at(k)
			continue
		s["t"] = float(s["t"]) + delta
		var hoja: Dictionary = _hojas[int(s["i"])]
		var u := clampf(float(s["t"]) / float(s["dur"]), 0.0, 1.0)
		var entra: bool = s["entra"]
		match int(s["fase"]):
			0:   ## camina (entra: hasta la puerta; sale: la puerta ya está abierta)
				nodo.position = (s["a"] as Vector3).lerp(s["b"], u)
				if entra and u >= 0.88 and float(hoja["objetivo"]) == 0.0:
					hoja["objetivo"] = 1.0
					Mini3D.anim(fig, "saludo_mano", "")   ## tiende la mano al picaporte (si el clip no está, queda parado)
					PeatonVida.gesto(nodo, "saludo_mano")
				if not entra and u >= 0.25:
					hoja["objetivo"] = 0.0
				if u >= 1.0:
					s["fase"] = 1
					s["t"] = 0.0
			1:   ## entra: cruza el umbral y desaparece; sale: ya está fuera, cierra tras él
				if entra:
					Mini3D.anim(fig, "caminar", "")
					var p: Vector3 = (expl.cb.puertas_vida[int(s["i"])] as Dictionary)["p"]
					var n: Vector3 = (expl.cb.puertas_vida[int(s["i"])] as Dictionary)["n"]
					nodo.position = (s["b"] as Vector3).lerp(p - n * 1.4, clampf(float(s["t"]) / 1.2, 0.0, 1.0))
					if float(s["t"]) >= 1.2:
						nodo.queue_free()
						hoja["objetivo"] = 0.0
						_activas.remove_at(k)
				else:
					nodo.queue_free()
					_activas.remove_at(k)

func _exit_tree() -> void:
	for s: Dictionary in _activas:
		var n: Node = (s["fig"] as Dictionary).get("nodo")
		if n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			n.queue_free()
