class_name PasajerosBus
extends Node
## PEATONES QUE SUBEN AL AUTOBÚS, VIAJAN Y BAJAN (27-10-2026, orden del dueño). Antes, al parar el autobús, aparecían figurantes que subían y
## otros que bajaban sin relación. Ahora hay CONTINUIDAD: en cada parada con marquesina esperan 2 personas (de pie, con el móvil) mientras el jugador
## está cerca; cuando el autobús para (a los 3 s, `GenteSentada.vigilar_buses`), los que esperan CAMINAN hasta la puerta y SUBEN: su «semilla»
## (la persona: cara, ropa, paso) se anota en el autobús (`meta "pasajeros"`). En otra parada BAJAN los que llevan más tiempo dentro: la misma
## persona (misma semilla) sale por la puerta y se va andando. Se reutiliza `PeatonQ`/`CargaCiudad.de("PeatonVida").nuevo` y sus clips; no hay nodos de más:
## solo existen los que esperan o andan, y se borran al llegar. Los trenes y el teleférico los hace otra sesión.

const ESPERAN := 2
const ALCANCE := 70.0
const MAX_ABORDO := 10
const BAJAN := 2

var expl
var _esperando := {}   ## índice de la parada → [{d, semilla}]
var _andando: Array = []   ## {d, semilla, a, b, t, dur, sube, bus}
var _t := 1.0
var _ronda := 0

static func crear(v) -> PasajerosBus:
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
				var fig := _persona(sem, sitio_espera(p, k))
				if fig.is_empty():
					break
				CargaCiudad.de("PeatonVida").en_anden(fig["d"], float(posmod(hash([sem, 5]), 100)) / 100.0)
				lista.append(fig)
		elif d > ALCANCE + 30.0 and _esperando.has(i):
			for fig: Dictionary in _esperando[i]:
				_liberar(fig)
			_esperando.erase(i)

## Dónde espera la persona `k` de la parada en `p`: BAJO EL TECHO del paradero (en su sistema local, entre la banca y el frente), no en medio
## de la acera. Sin paradero a menos de 3 m (las pruebas, paradas sueltas), el sitio de siempre.
func sitio_espera(p: Vector3, k: int) -> Vector3:
	var mejor: Node3D = null
	var dm := 3.0
	for n: Node in get_tree().get_nodes_in_group("paradero_red") if is_inside_tree() else []:
		var d := Vector2((n as Node3D).global_position.x - p.x, (n as Node3D).global_position.z - p.z).length()
		if d < dm:
			dm = d
			mejor = n as Node3D
	if mejor == null:
		return p + Vector3(-0.9 + 1.8 * float(k), 0.0, 0.6)
	return mejor.global_transform * Vector3(-1.3 + 0.9 * float(k), 0.0, 0.2)

static func semilla(parada: int, k: int, ronda: int) -> int:
	return 6100 + posmod(hash([parada, k, ronda]), 90000)

func _persona(sem: int, pos: Vector3) -> Dictionary:
	var d = CargaCiudad.de("PeatonVida").nuevo(expl.cb, sem)
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
	var puerta: Vector3 = bus.global_transform * Vector3(lado_puerta() * 1.5, 0.0, 4.6)   ## puerta del lado de la acera (derecha del bus, −X)
	var dentro1: Vector3 = bus.global_transform * Vector3(lado_puerta() * 0.9, 0.55, 4.6)   ## el escalón y el pasillo, ya dentro
	var dentro2: Vector3 = bus.global_transform * Vector3(lado_puerta() * 0.3, 0.55, 3.7)
	var der: Vector3 = bus.global_transform.basis.x.normalized() * lado_puerta()   ## hacia la acera
	var delante: Vector3 = bus.global_transform.basis.z.normalized()
	var abordo: Array = bus.get_meta("pasajeros", [])
	## BAJAN: la misma persona que subió antes (misma semilla), por la puerta, y se va andando por la acera.
	for k in mini(BAJAN, abordo.size()):
		var sem := int(abordo.pop_front())
		var fig := _persona(sem, puerta)
		if not fig.is_empty():
			var destino := puerta + der * (3.5 + 1.2 * float(k)) + delante * (7.0 - 12.0 * float(k))
			_andar(fig, [dentro2, dentro1, puerta, destino], false, bus)   ## baja: del pasillo al escalón, a la acera y se va
	## SUBEN: los de la marquesina más cercana a la puerta; si allí no esperaba nadie, llega alguien por la acera.
	var subir: Array = []
	var esperas: Array[Vector3] = expl.cb.esperas_bus
	## (A4-M3D-X12) Solo suben los que CABEN: a bordo + los que ya van hacia la puerta de este bus no pasan de `MAX_ABORDO`; el resto sigue esperando en la acera.
	var libres := MAX_ABORDO - abordo.size()
	for f: Dictionary in _andando:
		if bool(f["sube"]) and f["bus"] == bus:
			libres -= 1
	for i in esperas.size():
		var p: Vector3 = esperas[i]
		if Vector2(p.x - puerta.x, p.z - puerta.z).length() < 16.0 and _esperando.has(i):
			var lista: Array = _esperando[i]
			while not lista.is_empty() and subir.size() < mini(2, libres):
				var fig: Dictionary = lista.pop_front()
				fig["de"] = i
				subir.append(fig)
	if subir.is_empty() and libres > 0:
		_ronda += 1
		var sem2 := semilla(int(puerta.x), int(puerta.z), _ronda)
		var llega := _persona(sem2, puerta + der * 3.5 - delante * 9.0)
		if not llega.is_empty():
			subir.append(llega)
	for fig: Dictionary in subir:
		var n: Node3D = (fig["d"] as Dictionary)["nodo"]
		_andar(fig, [n.position, puerta, dentro1, dentro2], true, bus)   ## sube: a la puerta, el escalón y se adentra en el pasillo
	bus.set_meta("pasajeros", abordo)
	CargaCiudad.de("InteriorBus").actualizar(bus)

func _andar(fig: Dictionary, pts: Array, sube: bool, bus: Node3D) -> void:
	var d: Dictionary = fig["d"]
	var n: Node3D = d["nodo"]
	var largo := 0.0
	var ruta: Array[Vector3] = []
	for i in pts.size():
		var p: Vector3 = pts[i]
		if absf(p.y - 0.55) > 0.01:
			p.y = 0.2
		ruta.append(p)
		if i > 0:
			largo += ruta[i - 1].distance_to(p)
	n.position = ruta[0]
	n.rotation.y = atan2(ruta[1].x - ruta[0].x, ruta[1].z - ruta[0].z)
	Mini3D.anim(d, "caminar", "")
	_andando.append({"d": d, "semilla": int(fig["semilla"]), "ruta": ruta, "t": 0.0, "dur": maxf(largo / 1.4, 0.5), "largo": largo, "sube": sube, "bus": bus, "ancla": bus.global_position, "de": int(fig.get("de", -1))})

## Lado de la puerta en el modelo del autobús (−1: el de la acera; BUS_PUERTA_ANTIGUA=1 pone el de antes, +1, para las capturas «antes»).
static func lado_puerta() -> float:
	return 1.0 if OS.get_environment("BUS_PUERTA_ANTIGUA") != "" else -1.0

func _mover(delta: float) -> void:
	for k in range(_andando.size() - 1, -1, -1):
		var f: Dictionary = _andando[k]
		var n: Node3D = (f["d"] as Dictionary)["nodo"]
		if not is_instance_valid(n):
			_andando.remove_at(k)
			continue
		## (A4-M3D-X12) El bus se fue (o desapareció) mientras subían o bajaban: antes seguían andando hacia el hueco a la altura del escalón, flotando.
		var bus = f["bus"]
		var bus_ok: bool = bus != null and is_instance_valid(bus) and (bus as Node3D).is_inside_tree()
		if not bool(f.get("libre", false)) and (not bus_ok or (bus as Node3D).global_position.distance_to(f["ancla"]) > 1.5):
			if _bus_se_fue(f, n, bus if bus_ok else null):
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
			if bool(f["sube"]) and bus_ok:
				var abordo: Array = (bus as Node3D).get_meta("pasajeros", [])
				if abordo.size() < MAX_ABORDO:
					abordo.append(int(f["semilla"]))
				(bus as Node3D).set_meta("pasajeros", abordo)
				CargaCiudad.de("InteriorBus").actualizar(bus)
			n.queue_free()
			_andando.remove_at(k)

## El bus de `f` ya no está donde paró. true si la figura se da por terminada (y se borró o volvió a la parada).
## · Sube y aún está fuera: vuelve a su sitio en la marquesina (o se aleja y desaparece si llegó por la acera).
## · Sube y ya estaba dentro: queda anotado a bordo (si el bus existe) y desaparece (iba dentro).
## · Baja y aún está dentro: se coloca en la puerta, a pie de acera, y sigue su camino desde ahí (sin flotar).
func _bus_se_fue(f: Dictionary, n: Node3D, bus: Node3D) -> bool:
	var dentro := n.position.y > 0.3
	if bool(f["sube"]):
		if dentro and bus != null:
			var abordo: Array = bus.get_meta("pasajeros", [])
			if abordo.size() < MAX_ABORDO:
				abordo.append(int(f["semilla"]))
			bus.set_meta("pasajeros", abordo)
		elif not dentro and int(f["de"]) >= 0 and _esperando.has(int(f["de"])) and (_esperando[int(f["de"])] as Array).size() < ESPERAN:
			var ruta0: Vector3 = (f["ruta"] as Array)[0]
			n.position = ruta0
			CargaCiudad.de("PeatonVida").en_anden(f["d"], 0.5)
			(_esperando[int(f["de"])] as Array).append({"d": f["d"], "semilla": int(f["semilla"]), "de": int(f["de"])})
			return true
		n.queue_free()
		return true
	f["libre"] = true   ## baja: ya no depende del bus
	if dentro:
		var resto: Array = (f["ruta"] as Array).slice(2)   ## de la puerta en adelante
		var largo := 0.0
		for i in resto.size() - 1:
			largo += (resto[i] as Vector3).distance_to(resto[i + 1])
		f["ruta"] = resto
		f["largo"] = largo
		f["t"] = 0.0
		f["dur"] = maxf(largo / 1.4, 0.5)
		n.position = resto[0]
	return false

func _exit_tree() -> void:
	for f: Dictionary in _andando:
		_liberar(f)
	for i in _esperando:
		for fig: Dictionary in _esperando[i]:
			_liberar(fig)
