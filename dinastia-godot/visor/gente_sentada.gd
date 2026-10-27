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
const SE_VE := 38.0     ## a menos de esto, quien deja el asiento se levanta y se va andando
## En «Sitting_Idle» la pelvis queda a 1,05 m de la raíz y en «Sitting_Enter/Exit» a 0,60 (medido con la sonda de raíz del 27-10): para que no se
## hunda en el banco al sentarse o levantarse, la raíz sube COMPENSA durante esos clips (y vuelve a la altura de sentado o de suelo al acabar).
const COMPENSA := 0.45
const OCUPACION := 0.45   ## fracción de asientos cercanos con alguien

var vida: VidaCiudad
var expl: ExploradorCiudad
var cuerpos: Dictionary = {}   ## índice del asiento → {d: Dictionary (PeatonQ), p: Vector3}
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _parados := {}     ## autobús (id) → segundos que lleva parado en una parada
var _visto := {}      ## asiento → si estaba ocupado la última vez que lo miré de cerca (solo quien llega MIENTRAS miras camina hasta el banco)
var _saliendo: Array = []   ## {d, t, fase, a, b}: quien deja el asiento a la vista se levanta («levantarse») y se va andando
var _llegando: Array = []   ## {i, d, a, b, t, dur, fase}: quien llega andando, se vuelve y se sienta
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
	_llegadas(delta)
	_salidas(delta)
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
		var dist := Vector2(p.x, p.z).distance_to(yo)
		if dist > LEJOS:
			_quitar(i)
		elif not ocupado(i):
			## A la vista: se levanta y se va andando (el clip «levantarse» del pack); lejos o de lado, desaparece sin más.
			if dist < SE_VE and not _llegando.any(func(l: Dictionary) -> bool: return int(l["i"]) == i):
				_levantar(i)
			else:
				_quitar(i)
	## Y se sientan los que faltan, los asientos más cercanos primero.
	var candidatos: Array = []
	var asientos: Array = expl.cb.asientos
	for i in asientos.size():
		var p: Vector3 = asientos[i]["p"]
		var d := Vector2(p.x, p.z).distance_to(yo)
		if d >= CERCA:
			_visto.erase(i)
			continue
		if cuerpos.has(i):
			_visto[i] = true
			continue
		var occ := ocupado(i)
		var estaba = _visto.get(i)
		_visto[i] = occ
		if occ:
			candidatos.append([d, i, estaba == false and d > 6.0])
	candidatos.sort()
	for par: Array in candidatos:
		if cuerpos.size() >= MAXIMO:
			break
		_sentar(int(par[1]), asientos[int(par[1])], bool(par[2]))

func _sentar(i: int, asiento: Dictionary, llegando := false) -> void:
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
	cuerpos[i] = {"d": d, "p": p}
	if llegando:
		## LLEGA ANDANDO (P3 «MEJORAR»): desde 3,2 m por delante del banco, de cara al asiento; al llegar se vuelve y se sienta.
		var fuera := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
		var a := p + fuera * 3.2
		var raiz := n.position.y
		var suelo := ExploradorCiudad.altura_suelo(p.x, p.z)
		a.y = suelo
		n.position = a
		n.rotation.y = atan2(-fuera.x, -fuera.z)
		Mini3D.anim(d, "caminar", "")
		_llegando.append({"i": i, "d": d, "a": a, "raiz": raiz, "suelo": suelo, "b": Vector3(p.x, a.y, p.z) + fuera * 0.15, "t": 0.0, "dur": 3.2 / 1.3, "fase": 0, "giro": float(asiento["giro"])})
		return
	Mini3D.anim(d, "sentado", "")
	(d["anim"] as AnimationPlayer).seek(_rng.randf() * 0.8, true)

## Quien llega al banco: camina hasta él, se vuelve (el cuerpo gira con suavidad) y el clip «sentarse» encadena «sentado».
func _llegadas(delta: float) -> void:
	for k in range(_llegando.size() - 1, -1, -1):
		var s: Dictionary = _llegando[k]
		var d: Dictionary = s["d"]
		var n: Node3D = d["nodo"]
		if not is_instance_valid(n) or not cuerpos.has(int(s["i"])):
			_llegando.remove_at(k)
			continue
		s["t"] = float(s["t"]) + delta
		if int(s["fase"]) == 0:
			var u := clampf(float(s["t"]) / float(s["dur"]), 0.0, 1.0)
			n.position = (s["a"] as Vector3).lerp(s["b"], u)
			n.rotation.y = MovimientoNatural.girar(n.rotation.y, atan2(-sin(float(s["giro"])), -cos(float(s["giro"]))), delta * 2.0)
			if u >= 1.0:
				s["fase"] = 1
				s["t"] = 0.0
				var ap: AnimationPlayer = d["anim"]
				AnimExtra.asegurar(ap, FutbolistaQ.esqueleto_de(n), "sentarse")
				Mini3D.anim(d, "sentarse" if ap.has_animation("sentarse") else "sentado", "sentado")
		else:
			n.rotation.y = MovimientoNatural.girar(n.rotation.y, float(s["giro"]), delta)
			var ts := float(s["t"])
			n.position.y = raiz_sentarse(ts / 1.3, float(s["raiz"]), float(s["suelo"])) if ts < 1.3 else float(s["raiz"])
			if ts > 1.6:
				_llegando.remove_at(k)

## A los 3 s de parar el autobús, sube y baja gente de verdad (`PasajerosBus`); los sentados cercanos a la puerta se levantan y suben.
func embarque(bus: Node3D) -> void:
	if vida != null and vida.pasajeros != null:
		vida.pasajeros.parada(bus)

## El que está en el asiento `i` se levanta (clip «levantarse», 1 s) y camina 9 m por la acera; el asiento queda libre ya.
func _levantar(i: int) -> void:
	var c: Dictionary = cuerpos.get(i, {})
	cuerpos.erase(i)
	_visto.erase(i)
	if c.is_empty():
		return
	var d: Dictionary = c["d"]
	var n: Node3D = d["nodo"]
	var ap: AnimationPlayer = d["anim"]
	if not is_instance_valid(n) or not AnimExtra.asegurar(ap, FutbolistaQ.esqueleto_de(n), "levantarse"):
		if is_instance_valid(n):
			n.queue_free()
		return
	Mini3D.anim(d, "levantarse", "")
	var lado := Vector3(cos(n.rotation.y), 0, -sin(n.rotation.y)) * (1.0 if i % 2 == 0 else -1.0)
	var fuera := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
	var suelo := ExploradorCiudad.altura_suelo(n.position.x, n.position.z)
	var a := Vector3(n.position.x, suelo, n.position.z)
	_saliendo.append({"d": d, "t": 0.0, "fase": 0, "a": a, "b": a + fuera * 1.5 + lado * 8.0, "raiz": n.position.y, "suelo": suelo})

## Quien se levanta: tras el clip se vuelve hacia la acera y camina; al llegar a su destino desaparece.
func _salidas(delta: float) -> void:
	for k in range(_saliendo.size() - 1, -1, -1):
		var s: Dictionary = _saliendo[k]
		var d: Dictionary = s["d"]
		var n: Node3D = d["nodo"]
		if not is_instance_valid(n):
			_saliendo.remove_at(k)
			continue
		s["t"] = float(s["t"]) + delta
		if int(s["fase"]) == 0:
			n.position.y = raiz_levantarse(float(s["t"]) / 1.03, float(s["raiz"]), float(s["suelo"]))
			if float(s["t"]) >= 1.0:
				s["fase"] = 1
				s["t"] = 0.0
				n.position.y = float(s["suelo"])
				Mini3D.anim(d, "caminar", "")
				(d["anim"] as AnimationPlayer).speed_scale = 1.3 / MovimientoNatural.NATURAL
		else:
			var a: Vector3 = s["a"]
			var b: Vector3 = s["b"]
			var u := clampf(float(s["t"]) * 1.3 / a.distance_to(b), 0.0, 1.0)
			n.position = a.lerp(b, u)
			n.rotation.y = MovimientoNatural.girar(n.rotation.y, atan2(b.x - a.x, b.z - a.z), delta * 1.5)
			if u >= 1.0:
				n.queue_free()
				_saliendo.remove_at(k)

## Altura de la raíz a lo largo de «levantarse» (u 0→1): de la altura de sentado (+compensación) al suelo.
static func raiz_levantarse(u: float, raiz_sentado: float, suelo: float) -> float:
	return lerpf(raiz_sentado + COMPENSA, suelo, smoothstep(0.0, 1.0, u))

## Y a lo largo de «sentarse»: del suelo a la altura de sentado (+compensación).
static func raiz_sentarse(u: float, raiz_sentado: float, suelo: float) -> float:
	return lerpf(suelo, raiz_sentado + COMPENSA, smoothstep(0.0, 1.0, u))

func _quitar(i: int) -> void:
	_visto.erase(i)
	var c: Dictionary = cuerpos.get(i, {})
	if not c.is_empty():
		var n: Node = (c["d"] as Dictionary)["nodo"]
		if is_instance_valid(n):
			n.queue_free()
	cuerpos.erase(i)

func _quitar_todos() -> void:
	for s: Dictionary in _saliendo:
		var ns: Node = (s["d"] as Dictionary).get("nodo")
		if ns != null and is_instance_valid(ns):
			ns.queue_free()
	_saliendo.clear()
	for i: int in cuerpos.keys():
		_quitar(i)
