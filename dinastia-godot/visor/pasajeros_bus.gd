class_name PasajerosBus
extends Node
## PEATONES QUE SUBEN AL AUTOBÚS, VIAJAN Y BAJAN (27-10-2026, orden del dueño). Antes, al parar el autobús, aparecían figurantes que subían y
## otros que bajaban sin relación. Ahora hay CONTINUIDAD: en cada parada con marquesina esperan 2 personas (de pie, con el móvil) mientras el jugador
## está cerca; cuando el autobús para (a los 3 s, `GenteSentada.vigilar_buses`), los que esperan CAMINAN hasta la puerta y SUBEN: su «semilla»
## (la persona: cara, ropa, paso) se anota en el autobús (`meta "pasajeros"`). En otra parada BAJAN los que llevan más tiempo dentro: la misma
## persona (misma semilla) sale por la puerta y se va andando. Se reutiliza `PeatonQ`/`PeatonVida.nuevo` y sus clips; no hay nodos de más:
## solo existen los que esperan o andan, y se borran al llegar. Los trenes y el teleférico los hace otra sesión.

const ESPERAN := 2
const ALCANCE := 70.0
const MAX_ABORDO := 10
const BAJAN := 2

var expl: ExploradorCiudad
var _esperando := {}   ## índice de la parada → [{d, semilla}]
var _andando: Array = []   ## {d, semilla, a, b, t, dur, sube, bus}
var _t := 1.0
var _ronda := 0

static func crear(v: VidaCiudad) -> PasajerosBus:
	var s := PasajerosBus.new()
	s.name = "PasajerosBus"
	s.expl = v.expl
	v.add_child(s)
	return s

func _process(delta: float) -> void:
	_mover(delta)
	_t -= delta
	if _t > 0.0 or expl == null or not is_instance_valid(expl) or expl.cuerpo == null or expl.cb == null:
		return
	_t = 2.0
	_poblar()

## Quien espera en cada parada cercana (2 personas), y se retira quien queda lejos.
func _poblar() -> void:
	var esperas: Array[Vector3] = expl.cb.esperas_bus
	var yo := Vector2(expl.cuerpo.position.x, expl.cuerpo.position.z)
	for i in esperas.size():
		var p: Vector3 = esperas[i]
		var d := yo.distance_to(Vector2(p.x, p.z))
		if d < ALCANCE and String(expl.estado) == "calle":
			if not _esperando.has(i):
				_esperando[i] = []
			var lista: Array = _esperando[i]
			while lista.size() < ESPERAN:
				var k := lista.size()
				var sem := semilla(i, k, _ronda)
				var fig := _persona(sem, p + Vector3(-0.9 + 1.8 * float(k), 0.0, 0.6))
				if fig.is_empty():
					break
				PeatonVida.en_anden(fig["d"], float(posmod(hash([sem, 5]), 100)) / 100.0)
				lista.append(fig)
		elif d > ALCANCE + 30.0 and _esperando.has(i):
			for fig: Dictionary in _esperando[i]:
				_liberar(fig)
			_esperando.erase(i)

static func semilla(parada: int, k: int, ronda: int) -> int:
	return 6100 + posmod(hash([parada, k, ronda]), 90000)

func _persona(sem: int, pos: Vector3) -> Dictionary:
	var d := PeatonVida.nuevo(expl.cb, sem)
	if d.is_empty():
		return {}
	var n: Node3D = d["nodo"]
	pos.y = 0.2
	n.position = pos
	return {"d": d, "semilla": sem}

func _liberar(fig: Dictionary) -> void:
	var n: Node = (fig["d"] as Dictionary).get("nodo")
	if n != null and is_instance_valid(n):
		n.queue_free()

## El autobús `bus` lleva 3 s parado en una parada: bajan los que llevan más tiempo dentro y suben los que esperan.
func parada(bus: Node3D) -> void:
	if expl == null or expl.cb == null or _andando.size() >= 8:
		return
	var puerta: Vector3 = bus.global_transform * Vector3(-1.5, 0.0, 4.6)   ## puerta del lado de la acera (derecha del bus, −X)
	var der: Vector3 = -bus.global_transform.basis.x.normalized()   ## hacia la acera
	var delante: Vector3 = bus.global_transform.basis.z.normalized()
	var abordo: Array = bus.get_meta("pasajeros", [])
	## BAJAN: la misma persona que subió antes (misma semilla), por la puerta, y se va andando por la acera.
	for k in mini(BAJAN, abordo.size()):
		var sem := int(abordo.pop_front())
		var fig := _persona(sem, puerta)
		if not fig.is_empty():
			var destino := puerta + der * (3.5 + 1.2 * float(k)) + delante * (7.0 - 12.0 * float(k))
			_andar(fig, puerta, destino, false, bus)
	## SUBEN: los de la marquesina más cercana a la puerta; si allí no esperaba nadie, llega alguien por la acera.
	var subir: Array = []
	var esperas: Array[Vector3] = expl.cb.esperas_bus
	for i in esperas.size():
		var p: Vector3 = esperas[i]
		if Vector2(p.x - puerta.x, p.z - puerta.z).length() < 16.0 and _esperando.has(i):
			var lista: Array = _esperando[i]
			while not lista.is_empty() and subir.size() < 2:
				subir.append(lista.pop_front())
	if subir.is_empty():
		_ronda += 1
		var sem2 := semilla(int(puerta.x), int(puerta.z), _ronda)
		var llega := _persona(sem2, puerta + der * 3.5 - delante * 9.0)
		if not llega.is_empty():
			subir.append(llega)
	for fig: Dictionary in subir:
		var n: Node3D = (fig["d"] as Dictionary)["nodo"]
		_andar(fig, n.position, puerta, true, bus)
	bus.set_meta("pasajeros", abordo)
	InteriorBus.actualizar(bus)

func _andar(fig: Dictionary, a: Vector3, b: Vector3, sube: bool, bus: Node3D) -> void:
	var d: Dictionary = fig["d"]
	var n: Node3D = d["nodo"]
	a.y = 0.2
	b.y = 0.2
	n.position = a
	n.rotation.y = atan2(b.x - a.x, b.z - a.z)
	Mini3D.anim(d, "caminar", "")
	_andando.append({"d": d, "semilla": int(fig["semilla"]), "a": a, "b": b, "t": 0.0, "dur": maxf(a.distance_to(b) / 1.4, 0.5), "sube": sube, "bus": bus})

func _mover(delta: float) -> void:
	for k in range(_andando.size() - 1, -1, -1):
		var f: Dictionary = _andando[k]
		var n: Node3D = (f["d"] as Dictionary)["nodo"]
		if not is_instance_valid(n):
			_andando.remove_at(k)
			continue
		f["t"] = float(f["t"]) + delta
		var u := clampf(float(f["t"]) / float(f["dur"]), 0.0, 1.0)
		n.position = (f["a"] as Vector3).lerp(f["b"], u)
		if u >= 1.0:
			var bus := f["bus"] as Node3D
			if bool(f["sube"]) and bus != null and is_instance_valid(bus):
				var abordo: Array = bus.get_meta("pasajeros", [])
				if abordo.size() < MAX_ABORDO:
					abordo.append(int(f["semilla"]))
				bus.set_meta("pasajeros", abordo)
				InteriorBus.actualizar(bus)
			n.queue_free()
			_andando.remove_at(k)

func _exit_tree() -> void:
	for f: Dictionary in _andando:
		_liberar(f)
	for i in _esperando:
		for fig: Dictionary in _esperando[i]:
			_liberar(fig)
