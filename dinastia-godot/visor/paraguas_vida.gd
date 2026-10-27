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
const ALTO_COPA := 0.75   ## del puño a la copa (mango y copa en el eje de los dedos)
const POSE_BRAZO := Vector3(35.0, -14.0, 105.0)   ## brazo derecho: adelante, costado; codo (grados): el antebrazo casi vertical

static var _canopy: CylinderMesh = null
static var _mango: CylinderMesh = null
static var _mats: Array[StandardMaterial3D] = []

var expl: ExploradorCiudad
var vista   ## VistaCiudad (sin tipar: dependencia circular)
var mundo   ## Mundo (sin tipar: evita una dependencia circular con VidaCiudad)
var _lluvia: Node3D = null   ## la lluvia de la ciudad (`PrecipitacionCiudad`), montada mientras el clima es lluvioso
var _t := 2.0
var _cuenta := 0

static func crear(v: VidaCiudad) -> ParaguasVida:
	var s := ParaguasVida.new()
	s.name = "ParaguasVivos"
	s.expl = v.expl
	s.vista = v.vista
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
	var clima: String = mundo.clima()
	tick(trafico.get("_vehiculos"), llueve(clima), cb.get("puertas_vida"), _cuenta)
	_actualizar_lluvia(clima, cb)
	_actualizar_clima_y_sonido(clima)

## El tiempo de la semana llega al cielo y al sol (`ClimaCiudad`) y la lluvia suena en la calle (ruido de lluvia cada 3 s por el bus de ambiente).
var _sonido_en := 0.0
func _actualizar_clima_y_sonido(clima: String) -> void:
	if vista != null and is_instance_valid(vista) and String(vista.get("clima_actual")) != clima:
		vista.set("clima_actual", clima)
		vista.call("_aplicar_hora")
	if llueve(clima):
		_sonido_en -= 1.5
		if _sonido_en <= 0.0:
			_sonido_en = 3.0
			Sonido.toca("lluvia_fuerte" if clima == "tormenta" else "lluvia_ambiente", Sonido.Bus.AMBIENTE)

## Monta la lluvia (y moja el suelo) cuando el clima es lluvioso y la quita al escampar.
func _actualizar_lluvia(clima: String, cb: Object) -> void:
	if llueve(clima) and (_lluvia == null or not is_instance_valid(_lluvia)):
		_lluvia = PrecipitacionCiudad.montar(self, clima)
		CityBuilder.mojar(true)
	elif not llueve(clima) and _lluvia != null:
		if is_instance_valid(_lluvia):
			_lluvia.queue_free()
		_lluvia = null
		CityBuilder.mojar(false)

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
		if quiere and nodo.find_child(NOMBRE, true, false) == null:
			abrir(nodo, posmod(hash([i, 3]), COLORES.size()))
		elif not quiere and nodo.find_child(NOMBRE, true, false) != null:
			cerrar(nodo)
		if nodo.find_child(NOMBRE, true, false) != null:
			abiertos += 1
			_pose(nodo, true)   ## tras una parada el tráfico vuelve a «caminar»: se repone la pose del brazo
	return abiertos

static func _cerca_de_entrada(p: Vector3, puertas: Array) -> bool:
	for d: Dictionary in puertas:
		var q: Vector3 = d["p"]
		if Vector2(p.x - q.x, p.z - q.z).length() < RADIO_RESGUARDO:
			return true
	return false

## El paraguas va EN LA MANO derecha (BoneAttachment3D a hand_r): el mango sigue el eje de los dedos (+Y del hueso, como el móvil) y
## con el antebrazo levantado queda vertical, con la copa sobre la cabeza. Mallas y materiales compartidos. Sin esqueleto (pruebas),
## cae a un paraguas suelto sobre la cabeza.
static func abrir(nodo: Node3D, color_i: int) -> Node3D:
	_preparar_mallas()
	var raiz: Node3D
	var esq: Skeleton3D = FutbolistaQ.esqueleto_de(nodo)
	if esq != null and esq.find_bone("hand_r") >= 0:
		var anc := BoneAttachment3D.new()
		anc.bone_name = "hand_r"
		raiz = anc
		raiz.name = NOMBRE
		esq.add_child(raiz)
		_pose(nodo, true)
	else:
		raiz = Node3D.new()
		raiz.name = NOMBRE
		raiz.position = Vector3(0.14, 1.98, 0.0)
		nodo.add_child(raiz)
	## El eje del paraguas se endereza respecto al hueso de la mano (el eje de los dedos no queda vertical con el codo flexionado).
	var eje: Node3D
	if raiz is BoneAttachment3D:
		## En la mano pero SIEMPRE derecho (27-10-2026, «inclinados 45°»): el eje del hueso se inclina con el brazo, así que el mango
		## sale de la mano y apunta hacia arriba por el aire (`Sigue`), con la copa casi sobre la cabeza.
		var sg := Sigue.new()
		sg.cuerpo = nodo
		sg.top_level = true
		eje = sg
	else:
		eje = Node3D.new()
	eje.name = "Eje"
	raiz.add_child(eje)
	var copa := MeshInstance3D.new()
	copa.mesh = _canopy
	copa.material_override = _mats[clampi(color_i, 0, _mats.size() - 1)]
	copa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	copa.position = Vector3(0, ALTO_COPA if raiz is BoneAttachment3D else 0.0, 0)
	eje.add_child(copa)
	var mango := MeshInstance3D.new()
	mango.mesh = _mango
	mango.material_override = Mini3D.mat(Color(0.08, 0.08, 0.09), 0.6)
	mango.position = Vector3(0, ALTO_COPA * 0.5 - 0.05 if raiz is BoneAttachment3D else -0.45, 0)
	mango.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	eje.add_child(mango)
	return raiz

static func _preparar_mallas() -> void:
	if _canopy != null:
		return
	_canopy = CylinderMesh.new()
	_canopy.top_radius = 0.03
	_canopy.bottom_radius = 0.62
	_canopy.height = 0.2
	_canopy.radial_segments = 10
	_canopy.rings = 1
	_mango = CylinderMesh.new()
	_mango.top_radius = 0.012
	_mango.bottom_radius = 0.012
	_mango.height = ALTO_COPA + 0.1
	_mango.radial_segments = 5
	for c: Color in COLORES:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.55
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats.append(m)

static func cerrar(nodo: Node3D) -> void:
	var p := nodo.find_child(NOMBRE, true, false)
	if p != null:
		p.get_parent().remove_child(p)
		p.queue_free()
	_pose(nodo, false)

## Pone o quita la pose del brazo con el paraguas: «caminar_paraguas» es el «caminar» con el brazo derecho levantado (el antebrazo
## casi vertical). La animación se arma una vez por reproductor y se comparte entre todos los peatones (las rutas son las mismas).
static func _pose(nodo: Node3D, con: bool) -> void:
	var esq: Skeleton3D = FutbolistaQ.esqueleto_de(nodo)
	if esq == null:
		return
	for ap: AnimationPlayer in nodo.find_children("*", "AnimationPlayer", true, false):
		var lib := ap.get_animation_library("")
		if lib == null or not ap.has_animation("caminar"):
			continue
		if con:
			if not ap.has_animation("caminar_paraguas"):
				lib.add_animation("caminar_paraguas", _animacion_paraguas(ap, esq))
			if ap.current_animation == "caminar":
				var t := ap.current_animation_position
				ap.play("caminar_paraguas", 0.25)
				ap.seek(t, true)
		elif ap.current_animation == "caminar_paraguas":
			var t2 := ap.current_animation_position
			ap.play("caminar", 0.25)
			ap.seek(t2, true)

static func _animacion_paraguas(ap: AnimationPlayer, esq: Skeleton3D) -> Animation:
	var a: Animation = ap.get_animation("caminar").duplicate(true)
	var pre := str(ap.get_path_to(esq))
	for clave: String in ["brazo_d", "antebrazo_d"]:
		var idx := a.find_track(NodePath("%s:%s" % [pre, String(AnimQuaternius.HUESOS[clave])]), Animation.TYPE_ROTATION_3D)
		if idx >= 0:
			a.remove_track(idx)
	var v_brazo := AnimExtra._brazo("d", POSE_BRAZO.x, POSE_BRAZO.y)
	var v_codo := AnimExtra._codo("d", POSE_BRAZO.z)
	AnimQuaternius._pista(a, esq, "brazo_d", [[0.0, v_brazo], [a.length, v_brazo]], pre)
	AnimQuaternius._pista(a, esq, "antebrazo_d", [[0.0, v_codo], [a.length, v_codo]], pre)
	return a

## El mango vertical: sale de la mano y sube hacia un punto del eje del cuerpo (60 % del camino de la mano al eje): como mucho unos 12° de
## inclinación, y la copa queda casi centrada sobre la cabeza. Un nodo por paraguas abierto (solo mientras llueve).
class Sigue:
	extends Node3D
	var cuerpo: Node3D
	const AFINAR := 0.6

	func _process(_d: float) -> void:
		var mano := get_parent() as Node3D
		if mano == null or cuerpo == null or not is_instance_valid(cuerpo):
			return
		var p := mano.global_position
		var c := cuerpo.global_position
		var arriba := Vector3(lerpf(p.x, c.x, AFINAR) - p.x, ParaguasVida.ALTO_COPA, lerpf(p.z, c.z, AFINAR) - p.z).normalized()
		var x := Vector3.UP.cross(arriba)
		x = x.normalized() if x.length() > 0.001 else Vector3.RIGHT
		global_transform = Transform3D(Basis(x, arriba, x.cross(arriba).normalized()), p)
