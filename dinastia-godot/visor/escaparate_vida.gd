class_name EscaparateVida
extends Node
## MIRAR ESCAPARATES (P1-P3 «MEJORAR», animaciones de vida, 27-10-2026). Junto a las entradas de los edificios (`CityBuilder.puertas_vida`)
## un vecino llega andando por la acera pegado a la fachada, se detiene a 2,6 m de la puerta, gira el cuerpo hacia el cristal y pasea la
## mirada de un lado a otro unos 6-9 s (la cabeza sigue un punto que se desplaza por el escaparate: el mismo `LookAtModifier3D` que la
## mirada al balón), y sigue su camino. Máximo 2 a la vez; sin azar de la partida (todo sale de hash del hueco y del contador).
const ALCANCE := 60.0
const MAX_ACTIVAS := 2
const PARADA := 2.6   ## metros de la puerta, a lo largo de la fachada
const VEL := 1.3

var expl: ExploradorCiudad
var _activas: Array = []   ## {fig, fase, t, a, b, p, n, mira, dur, quieto}
var _t := 6.0
var _cuenta := 0

static func crear(v: VidaCiudad) -> EscaparateVida:
	var s := EscaparateVida.new()
	s.name = "Escaparates"
	s.expl = v.expl
	v.add_child(s)
	return s

func _process(delta: float) -> void:
	_mover(delta)
	if expl == null or not is_instance_valid(expl) or expl.cuerpo == null or expl.cb == null or String(expl.estado) != "calle":
		return
	_t -= delta
	if _t > 0.0 or _activas.size() >= MAX_ACTIVAS:
		return
	_t = 11.0
	var yo: Vector3 = expl.cuerpo.position
	var mejor := -1
	var mejor_d := ALCANCE
	var ps: Array[Dictionary] = expl.cb.puertas_vida
	for i in ps.size():
		var p: Vector3 = ps[i]["p"]
		var d := Vector2(p.x - yo.x, p.z - yo.z).length()
		if d < mejor_d and d > 5.0 and ((i + _cuenta) % 3 == 1) and not _en_uso(i):
			mejor = i
			mejor_d = d
	_cuenta += 1
	if mejor >= 0:
		iniciar(mejor)

func _en_uso(i: int) -> bool:
	for s: Dictionary in _activas:
		if int(s["i"]) == i:
			return true
	return false

## Hacia dónde mira el cuerpo cuando va de `a` a `b`.
static func rumbo(a: Vector3, b: Vector3) -> float:
	return atan2(b.x - a.x, b.z - a.z)

## Empieza la escena en la puerta `i`: llega por un lado de la fachada, mira el cristal y se va por el otro.
func iniciar(i: int) -> void:
	var ps: Array[Dictionary] = expl.cb.puertas_vida
	var p: Vector3 = ps[i]["p"]
	var n: Vector3 = ps[i]["n"]
	var lado := n.cross(Vector3.UP)
	var signo := 1.0 if absi(hash([i, _cuenta])) % 2 == 0 else -1.0
	var parada := p + lado * signo * PARADA
	var a := p - lado * signo * 9.0 + n * 0.3
	var b := p + lado * signo * 9.0 + n * 0.3
	var fig := PeatonVida.nuevo(expl.cb, 9000 + i * 17 + _cuenta)
	if fig.is_empty():
		return
	var nodo: Node3D = fig["nodo"]
	a.y = p.y
	b.y = p.y
	parada.y = p.y
	nodo.position = a
	nodo.rotation.y = rumbo(a, parada)
	Mini3D.anim(fig, "caminar", "")
	(fig["anim"] as AnimationPlayer).speed_scale = VEL / MovimientoNatural.NATURAL
	## El punto que sigue la mirada: a la altura de los ojos, al otro lado del cristal.
	var mira := Node3D.new()
	expl.cb.add_child(mira)
	mira.position = parada - n * 1.5 + Vector3(0, 1.5, 0)
	MiradaBalon.poner_en(nodo, mira)
	_activas.append({"i": i, "fig": fig, "fase": 0, "t": 0.0, "a": a, "b": b, "p": parada, "n": n, "lado": lado, "mira": mira,
		"dur": maxf(a.distance_to(parada) / VEL, 1.0), "quieto": 6.0 + float(absi(hash([i, 3])) % 4)})

func _mover(delta: float) -> void:
	for k in range(_activas.size() - 1, -1, -1):
		var s: Dictionary = _activas[k]
		var fig: Dictionary = s["fig"]
		var nodo: Node3D = fig["nodo"]
		if not is_instance_valid(nodo):
			_liberar(s)
			_activas.remove_at(k)
			continue
		s["t"] = float(s["t"]) + delta
		match int(s["fase"]):
			0:   ## llega andando y empieza a girarse hacia el cristal unos 0,8 m antes
				var u := clampf(float(s["t"]) / float(s["dur"]), 0.0, 1.0)
				nodo.position = (s["a"] as Vector3).lerp(s["p"], u)
				if u > 0.8:
					nodo.rotation.y = MovimientoNatural.girar(nodo.rotation.y, rumbo(Vector3.ZERO, -(s["n"] as Vector3)), delta)
				if u >= 1.0:
					s["fase"] = 1
					s["t"] = 0.0
					Mini3D.anim(fig, "parado", "")
			1:   ## de cara al cristal, la mirada pasea por el escaparate
				nodo.rotation.y = MovimientoNatural.girar(nodo.rotation.y, rumbo(Vector3.ZERO, -(s["n"] as Vector3)), delta)
				var mira: Node3D = s["mira"]
				var barrido := sin(float(s["t"]) * 0.9) * 1.3
				mira.position = (s["p"] as Vector3) - (s["n"] as Vector3) * 1.5 + (s["lado"] as Vector3) * barrido + Vector3(0, 1.5, 0)
				if float(s["t"]) >= float(s["quieto"]):
					s["fase"] = 2
					s["t"] = 0.0
					s["dur"] = maxf((s["p"] as Vector3).distance_to(s["b"]) / VEL, 1.0)
					Mini3D.anim(fig, "caminar", "")
					(fig["anim"] as AnimationPlayer).speed_scale = VEL / MovimientoNatural.NATURAL
			_:   ## se va por el otro lado de la fachada
				var u2 := clampf(float(s["t"]) / float(s["dur"]), 0.0, 1.0)
				var dest: Vector3 = s["b"]
				nodo.position = (s["p"] as Vector3).lerp(dest, u2)
				nodo.rotation.y = MovimientoNatural.girar(nodo.rotation.y, rumbo(s["p"], dest), delta)
				if u2 >= 1.0:
					nodo.queue_free()
					_liberar(s)
					_activas.remove_at(k)

func _liberar(s: Dictionary) -> void:
	var m: Node = s.get("mira")
	if m != null and is_instance_valid(m):
		m.queue_free()

func _exit_tree() -> void:
	for s: Dictionary in _activas:
		var n: Node = (s["fig"] as Dictionary).get("nodo")
		if n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			n.queue_free()
		_liberar(s)
