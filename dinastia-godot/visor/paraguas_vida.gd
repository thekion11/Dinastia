class_name ParaguasVida
extends Node
## NPC CON PARAGUAS CUANDO LLUEVE (S6, 27-10-2026). Cuando el clima de la semana es lluvia o tormenta (`Mundo.clima()`), los peatones de la
## ciudad abren un paraguas (de colores apagados, sobre la cabeza), caminan un 25 % más rápido y, de vez en cuando, uno que pasa a menos de
## 4,5 m de una entrada con marquesina se resguarda bajo ella unos segundos (con el paraguas cerrado). Al escampar, todo se recoge.
## `tick` es estático y trabaja sobre la lista de peatones (`TraficoCiudad._vehiculos`), así se prueba sin escena.

const CLIMAS := ["lluvia", "tormenta"]
const FACTOR_PRISA := 1.25
const RADIO_RESGUARDO := 4.5
const MAX_RESGUARDADOS := 5
const COLORES := [Color(0.16, 0.2, 0.34), Color(0.5, 0.12, 0.14), Color(0.1, 0.1, 0.12), Color(0.18, 0.38, 0.3), Color(0.8, 0.62, 0.15), Color(0.55, 0.55, 0.58)]
const NOMBRE := "Paraguas"

static var _canopy: CylinderMesh = null
static var _mango: CylinderMesh = null
static var _mats: Array[StandardMaterial3D] = []

var expl: ExploradorCiudad
var mundo   ## Mundo (sin tipar: evita una dependencia circular con VidaCiudad)
var _t := 2.0
var _cuenta := 0

static func crear(v: VidaCiudad) -> ParaguasVida:
	var s := ParaguasVida.new()
	s.name = "ParaguasVivos"
	s.expl = v.expl
	s.mundo = v.mundo
	v.add_child(s)
	return s

static func llueve(clima: String) -> bool:
	return clima in CLIMAS

func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0 or expl == null or not is_instance_valid(expl) or mundo == null:
		return
	var trafico: Object = expl.get("trafico")   ## sin tipar (dependencia circular con VidaCiudad)
	var cb: Object = expl.get("cb")
	if trafico == null or cb == null:
		return
	_t = 1.5
	_cuenta += 1
	tick(trafico.get("_vehiculos"), llueve(mundo.clima()), cb.get("puertas_vida"), _cuenta)

## Un repaso a todos los peatones. Devuelve cuántos llevan el paraguas abierto.
static func tick(vehiculos: Array, lluvia: bool, puertas: Array, cuenta: int) -> int:
	var abiertos := 0
	var resguardados := 0
	for v: Dictionary in vehiculos:
		if bool(v.get("resguardo", false)) and bool(v.get("pausa", false)):
			resguardados += 1
	var i := -1
	for v: Dictionary in vehiculos:
		i += 1
		if not bool(v.get("peaton", false)):
			continue
		var nodo := v.get("nodo") as Node3D
		if nodo == null or not is_instance_valid(nodo):
			continue
		## Velocidad: con lluvia, más prisa; al escampar, la de siempre.
		if lluvia and not v.has("vel0"):
			v["vel0"] = float(v["vel"])
			v["vel"] = float(v["vel"]) * FACTOR_PRISA
		elif not lluvia and v.has("vel0"):
			v["vel"] = float(v["vel0"])
			v.erase("vel0")
		var parado := bool(v.get("pausa", false))
		if not parado:
			v.erase("resguardo")
		## Resguardo: pasa junto a una entrada con marquesina; cuenta y azar por hash estable del peatón y del repaso.
		if lluvia and not parado and resguardados < MAX_RESGUARDADOS and _cerca_de_entrada(nodo.position, puertas) and posmod(hash([i, cuenta]), 100) < 12:
			v["espera"] = 6.0 + float(posmod(hash([i, 7]), 5))
			v["pausa"] = true
			v["resguardo"] = true
			resguardados += 1
			parado = true
			Mini3D.anim(v, "parado")
		var quiere := lluvia and not parado
		if quiere and nodo.get_node_or_null(NOMBRE) == null:
			abrir(nodo, posmod(hash([i, 3]), COLORES.size()))
		elif not quiere and nodo.get_node_or_null(NOMBRE) != null:
			cerrar(nodo)
		if nodo.get_node_or_null(NOMBRE) != null:
			abiertos += 1
	return abiertos

static func _cerca_de_entrada(p: Vector3, puertas: Array) -> bool:
	for d: Dictionary in puertas:
		var q: Vector3 = d["p"]
		if Vector2(p.x - q.x, p.z - q.z).length() < RADIO_RESGUARDO:
			return true
	return false

## El paraguas: copa cónica sobre la cabeza y un mango; mallas y materiales compartidos.
static func abrir(nodo: Node3D, color_i: int) -> Node3D:
	if _canopy == null:
		_canopy = CylinderMesh.new()
		_canopy.top_radius = 0.03
		_canopy.bottom_radius = 0.62
		_canopy.height = 0.2
		_canopy.radial_segments = 10
		_canopy.rings = 1
		_mango = CylinderMesh.new()
		_mango.top_radius = 0.012
		_mango.bottom_radius = 0.012
		_mango.height = 0.75
		_mango.radial_segments = 5
		for c: Color in COLORES:
			var m := StandardMaterial3D.new()
			m.albedo_color = c
			m.roughness = 0.55
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			_mats.append(m)
	var raiz := Node3D.new()
	raiz.name = NOMBRE
	raiz.position = Vector3(0.14, 1.98, 0.0)
	var copa := MeshInstance3D.new()
	copa.mesh = _canopy
	copa.material_override = _mats[clampi(color_i, 0, _mats.size() - 1)]
	copa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(copa)
	var mango := MeshInstance3D.new()
	mango.mesh = _mango
	mango.material_override = Mini3D.mat(Color(0.08, 0.08, 0.09), 0.6)
	mango.position = Vector3(0, -0.45, 0)
	mango.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(mango)
	nodo.add_child(raiz)
	return raiz

static func cerrar(nodo: Node3D) -> void:
	var p := nodo.get_node_or_null(NOMBRE)
	if p != null:
		p.queue_free()
		nodo.remove_child(p)
