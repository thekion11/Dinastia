class_name GenteSentada
extends Node
## GENTE SENTADA EN LOS BANCOS (calidad visual P3, pasada 2, 27-10-2026). Plan §2.2e: *«sentarse
## de verdad (butaca, sofá, banquillo)»*. Los bancos de acera (`CiudadExpansion`) y de las paradas de
## bus (`CityBuilder._paradas_bus`) registran sus asientos en `CityBuilder.asientos`; aquí, cada
## segundo, se sientan hasta `MAXIMO` peatones (`PeatonQ`, con el clip «sentado» y la raíz bajada a
## la altura del asiento, como en el metro) en los asientos a menos de `CERCA` metros de ti, y se
## van los que quedan a más de `LEJOS`. Qué asiento está ocupado se decide por hash del asiento y
## de la hora: estable mientras miras, distinto de una hora a otra. Cuelga de `VidaCiudad`.

const MAXIMO := 6
const CERCA := 55.0
const LEJOS := 75.0
const OCUPACION := 0.45   ## fracción de asientos cercanos con alguien

var vida: VidaCiudad
var expl: ExploradorCiudad
var cuerpos: Dictionary = {}   ## índice del asiento → {d: Dictionary (PeatonQ), p: Vector3}
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _parados := {}     ## autobús (id) → segundos que lleva parado en una parada
var _figurantes: Array = []   ## los que suben y bajan del autobús ({d, a, b, t, dur, sube})
var _eventos: Array[Vector3] = []   ## dónde subieron y bajaron pasajeros (a los 3 s de parar el autobús)

static func crear(v: VidaCiudad) -> GenteSentada:
	var s := GenteSentada.new()
	s.name = "Sentados"
	s.vida = v
	s.expl = v.expl
	s._rng.seed = 2710
	v.add_child(s)
	return s

func _process(delta: float) -> void:
	_mover_figurantes(delta)
	if expl == null or not is_instance_valid(expl) or expl.cuerpo == null or expl.cb == null:
		return
	_t -= delta
	if _t <= 0.0:
		_t = 1.0
		revisar()

## ¿Este asiento tiene a alguien a esta hora? (estable por hash)
func ocupado(i: int) -> bool:
	var hora := vida.mundo.reloj.hora() if vida != null and vida.mundo != null and vida.mundo.reloj != null else 12
	## Cada vez que un autobús para junto al asiento, suben y bajan pasajeros: cambia quién está sentado.
	var visitas := 0
	if expl != null and expl.cb != null and i < expl.cb.asientos.size():
		visitas = visitas_cerca(expl.cb.asientos[i]["p"])
	return hay_alguien(i, hora, visitas)

## Cuántas veces ha parado un autobús a menos de 16 m de `p`.
func visitas_cerca(p: Vector3) -> int:
	var n := 0
	for ev: Vector3 in _eventos:
		if Vector2(ev.x - p.x, ev.z - p.z).length() < 16.0:
			n += 1
	return n

static func hay_alguien(i: int, hora: int, visitas: int) -> bool:
	return float(absi(hash([i, hora, visitas])) % 1000) / 1000.0 < OCUPACION   ## (hash de array: mezcla bien; el de cadena solo cambia 1 con un carácter distinto)

## Un autobús que lleva 3 s parado en su parada deja una huella: ahí «suben y bajan» pasajeros.
func vigilar_buses() -> void:
	if expl == null or expl.trafico == null:
		return
	for v: Dictionary in expl.trafico._vehiculos:
		if not v.has("paradas") or not is_instance_valid(v["nodo"]):
			continue
		var id := (v["nodo"] as Node3D).get_instance_id()
		if float(v.get("espera", 0.0)) > 0.0:
			_parados[id] = float(_parados.get(id, 0.0)) + 1.0
			if float(_parados[id]) == 3.0:
				_eventos.append((v["nodo"] as Node3D).global_position)
				embarque(v["nodo"])
				if _eventos.size() > 40:
					_eventos.pop_front()
		else:
			_parados.erase(id)

func revisar() -> void:
	vigilar_buses()
	if String(expl.estado) != "calle":
		_quitar_todos()
		return
	var yo := Vector2(expl.cuerpo.position.x, expl.cuerpo.position.z)
	## Los que quedaron lejos (o cuyo asiento ya no toca) se van.
	for i: int in cuerpos.keys():
		var c: Dictionary = cuerpos[i]
		var p: Vector3 = c["p"]
		if Vector2(p.x, p.z).distance_to(yo) > LEJOS or not ocupado(i):
			_quitar(i)
	## Y se sientan los que faltan, los asientos más cercanos primero.
	var candidatos: Array = []
	var asientos: Array = expl.cb.asientos
	for i in asientos.size():
		if cuerpos.has(i) or not ocupado(i):
			continue
		var p: Vector3 = asientos[i]["p"]
		var d := Vector2(p.x, p.z).distance_to(yo)
		if d < CERCA:
			candidatos.append([d, i])
	candidatos.sort()
	for par: Array in candidatos:
		if cuerpos.size() >= MAXIMO:
			break
		_sentar(int(par[1]), asientos[int(par[1])])

func _sentar(i: int, asiento: Dictionary) -> void:
	_rng.seed = 2710 + i
	var d := PeatonQ.crear(_rng)
	if d.is_empty():
		return
	var n: Node3D = d["nodo"]
	expl.cb.add_child(n)
	PeatonQ.terminar(d)
	var p: Vector3 = asiento["p"]
	n.position = p
	n.rotation.y = float(asiento["giro"])
	var cadera := MetroCiudad.altura_cadera(n)
	if cadera > 0.0:
		n.position.y = p.y + 0.08 - cadera * 0.99
	Mini3D.anim(d, "sentado", "")
	(d["anim"] as AnimationPlayer).seek(_rng.randf() * 0.8, true)
	cuerpos[i] = {"d": d, "p": p}

## A los 3 s de parar, SUBEN dos (los sentados más cercanos, o alguien que llega por la acera) y BAJAN dos: caminan de verdad
## hasta/desde la puerta delantera del autobús (lado derecho) y desaparecen al llegar.
func embarque(bus: Node3D) -> void:
	if expl == null or expl.cb == null or _figurantes.size() >= 6:
		return
	var puerta: Vector3 = bus.global_transform * Vector3(1.5, 0.0, 4.6)
	var der: Vector3 = bus.global_transform.basis.x.normalized()
	var delante: Vector3 = bus.global_transform.basis.z.normalized()
	var suben := 0
	for i: int in cuerpos.keys():
		if suben >= 2:
			break
		var c: Dictionary = cuerpos[i]
		var p: Vector3 = c["p"]
		if Vector2(p.x - puerta.x, p.z - puerta.z).length() < 16.0:
			_quitar(i)
			_figurante(Vector3(p.x, 0.0, p.z), puerta, true)
			suben += 1
	if suben == 0:
		_figurante(puerta + der * 3.5 - delante * 9.0, puerta, true)
	_figurante(puerta, puerta + der * 3.5 + delante * 7.0, false)
	_figurante(puerta, puerta + der * 4.5 - delante * 6.0, false)

func _figurante(a: Vector3, b: Vector3, sube: bool) -> void:
	_rng.seed = 9100 + _figurantes.size() * 31 + int(a.x + a.z)
	var d := PeatonQ.crear(_rng)
	if d.is_empty():
		return
	var n: Node3D = d["nodo"]
	expl.cb.add_child(n)
	PeatonQ.terminar(d)
	a.y = 0.2
	b.y = 0.2
	n.position = a
	n.rotation.y = atan2(b.x - a.x, b.z - a.z)
	Mini3D.anim(d, "caminar", "")
	_figurantes.append({"d": d, "a": a, "b": b, "t": 0.0, "dur": maxf(a.distance_to(b) / 1.4, 0.5), "sube": sube})

func _mover_figurantes(delta: float) -> void:
	for k in range(_figurantes.size() - 1, -1, -1):
		var f: Dictionary = _figurantes[k]
		var n: Node3D = (f["d"] as Dictionary)["nodo"]
		if not is_instance_valid(n):
			_figurantes.remove_at(k)
			continue
		f["t"] = float(f["t"]) + delta
		var u := clampf(float(f["t"]) / float(f["dur"]), 0.0, 1.0)
		n.position = (f["a"] as Vector3).lerp(f["b"], u)
		if u >= 1.0:
			n.queue_free()
			_figurantes.remove_at(k)

func _quitar(i: int) -> void:
	var c: Dictionary = cuerpos.get(i, {})
	if not c.is_empty():
		var n: Node = (c["d"] as Dictionary)["nodo"]
		if is_instance_valid(n):
			n.queue_free()
	cuerpos.erase(i)

func _quitar_todos() -> void:
	for f: Dictionary in _figurantes:
		if is_instance_valid((f["d"] as Dictionary)["nodo"]):
			((f["d"] as Dictionary)["nodo"] as Node).queue_free()
	_figurantes.clear()
	for i: int in cuerpos.keys():
		_quitar(i)
