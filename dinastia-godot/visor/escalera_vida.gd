class_name EscaleraVida
extends Node3D
## PEATONES QUE SUBEN Y BAJAN ESCALERAS (calidad visual P3, 27-10-2026). Cada escalera registra en `CityBuilder.escaleras`
## {pie: Vector3 (suelo del primer peldaño), cima: Vector3 (suelo del último), n: peldaños}. Cerca del jugador, alguien la sube o
## la baja con los pasos SINCRONIZADOS: el cuerpo avanza peldaño a peldaño (sube de golpe en la mitad de cada paso) y el ciclo de
## «caminar» se ajusta para que cada pie caiga en un peldaño. Las bocas del metro se tragan al que baja y escupen al que sube.

const ALCANCE := 60.0
const MAX_ACTIVAS := 2
const V_PASO := 0.55   ## s por peldaño

var expl: ExploradorCiudad
var _activas: Array = []   ## {i, sube, t, fig, dur}
var _t := 5.0
var _cuenta := 0

static func crear(v: VidaCiudad) -> EscaleraVida:
	var s := EscaleraVida.new()
	s.name = "EscalerasVivas"
	s.expl = v.expl
	v.add_child(s)
	return s

static func registrar(b: CityBuilder, pie: Vector3, cima: Vector3, peldanos: int) -> void:
	b.escaleras.append({"pie": pie, "cima": cima, "n": peldanos})

## Altura del cuerpo con el avance `u` (0..1): escalonada y suavizada, un salto por peldaño.
static func altura(u: float, n: int, h0: float, h1: float) -> float:
	var k := clampf(u, 0.0, 1.0) * float(n)
	var peldano := floorf(minf(k, float(n) - 0.001))
	var fr := k - peldano
	var sube := smoothstep(0.25, 0.65, fr)
	return lerpf(h0, h1, (peldano + sube) / float(n))

func _process(delta: float) -> void:
	_mover(delta)
	if expl == null or not is_instance_valid(expl) or expl.cuerpo == null or expl.cb == null:
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = 7.0
	if _activas.size() >= MAX_ACTIVAS:
		return
	var yo: Vector3 = expl.cuerpo.position
	var mejor := -1
	var mejor_d := ALCANCE
	var es: Array[Dictionary] = expl.cb.escaleras
	for i in es.size():
		var q: Vector3 = es[i]["cima"]
		var d := Vector2(q.x - yo.x, q.z - yo.z).length()
		if d < mejor_d and d > 4.0 and not _en_uso(i) and ((i + _cuenta) % 2 == 0):
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

func iniciar(i: int, sube: bool) -> void:
	var e: Dictionary = expl.cb.escaleras[i]
	var fig := PeatonVida.nuevo(expl.cb, 8100 + i * 17 + _cuenta)
	if fig.is_empty():
		return
	var pie: Vector3 = e["pie"]
	var cima: Vector3 = e["cima"]
	var n := int(e["n"])
	## Un ciclo de «caminar» son dos pasos: dura 2 × V_PASO s.
	var ap: AnimationPlayer = fig["anim"]
	var clip := ap.get_animation("caminar") if ap.has_animation("caminar") else null
	var vel := clip.length / (2.0 * V_PASO) if clip != null and clip.length > 0.0 else 1.0
	Mini3D.anim(fig, "caminar", "", 0.2, vel)
	var nodo: Node3D = fig["nodo"]
	var dir := Vector3(cima.x - pie.x, 0.0, cima.z - pie.z)
	var d := dir.normalized() * (1.0 if sube else -1.0)
	nodo.rotation.y = atan2(d.x, d.z)
	nodo.position = pie if sube else cima
	_activas.append({"i": i, "sube": sube, "t": 0.0, "fig": fig, "dur": float(n) * V_PASO})

## Posición del cuerpo en la escalera `i` con el avance `u` (0 = abajo, 1 = arriba).
func posicion(i: int, u: float) -> Vector3:
	var e: Dictionary = expl.cb.escaleras[i]
	var pie: Vector3 = e["pie"]
	var cima: Vector3 = e["cima"]
	var p := pie.lerp(cima, clampf(u, 0.0, 1.0))
	p.y = altura(u, int(e["n"]), pie.y, cima.y)
	return p

func _mover(delta: float) -> void:
	for k in range(_activas.size() - 1, -1, -1):
		var s: Dictionary = _activas[k]
		var nodo: Node3D = (s["fig"] as Dictionary)["nodo"]
		if not is_instance_valid(nodo):
			_activas.remove_at(k)
			continue
		s["t"] = float(s["t"]) + delta
		var u := clampf(float(s["t"]) / float(s["dur"]), 0.0, 1.0)
		var sube: bool = s["sube"]
		nodo.position = posicion(int(s["i"]), u if sube else 1.0 - u)
		if u >= 1.0:
			nodo.queue_free()
			_activas.remove_at(k)

func _exit_tree() -> void:
	for s: Dictionary in _activas:
		var n: Node = (s["fig"] as Dictionary).get("nodo")
		if n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			n.queue_free()
