class_name AnimacionCercana
extends Node
## LA ANIMACIÓN DE CERCA DEL PARTIDO (H1 del informe AAA, punto 3, 16-11-2026). Un solo nodo por partido que decide, cada fotograma,
## qué jugadores llevan los retoques de esqueleto que solo se ven de cerca, para no gastar CPU en los 22:
##  · CABEZA AL BALÓN (`MiradaBalon`, el `LookAtModifier3D` de M-098 con topes de 65°/30° y medio segundo de suavizado): ahora solo
##    en los que están a menos de `MIRA_CAMARA` m de la cámara y `MIRA_BALON` m del balón; la influencia sube y baja en ~0,4 s
##    (`RITMO_MIRA`) para que el cuello no salte, y con influencia 0 el modificador queda apagado (no cuesta).
##  · PIE AL BALÓN (`PieBalonIK`): solo el que lleva el balón (o el más cercano a menos de `PIE_LEJOS` m si está suelto) y solo si
##    el balón va bajo y el jugador está a menos de `MIRA_CAMARA` m de la cámara; peso suave según la distancia.
## Solo cambia lo que se ve: no escribe nada del motor (lee `jugadores`, `poseedor`, `balon` y `t`); la huella de
## `pruebas/igualdad_motor.gd` no cambia (lo comprueba `banco/partido` → «H1: IK sin tocar el motor»).
## CALIDAD: encendido de MEDIA hacia arriba. En ULTRA BAJA, BAJA y MEDIA BAJA y con «Partido ligero» no se monta nada y la mirada
## de M-098 (que antes iba en los 22 en todas las calidades) queda APAGADA: menos coste en las calidades bajas, nunca más.
##  · LA INERCIA (`InerciaCuerpo`, 17-11): ladeo en las curvas, cabeceo al arrancar y frenar, el torso que se adelanta al giro y el
##    control orientado, en los que están a menos de `MIRA_CAMARA` m de la cámara (peso suave, `RITMO_INERCIA`).
## `H1_IK=0` (o `encendida = false`) lo deja todo como antes del 16-11 (para capturas «antes»); `INERCIA=0`, solo la inercia.

static var encendida: bool = OS.get_environment("H1_IK") != "0"
const MIRA_CAMARA := 33.0      ## m: más lejos, el cuerpo es la silueta de `ImpostorLejano` (30 m) y su animación va a saltos (`AnimLejana`)
const MIRA_BALON := 22.0       ## m: los que están lejos de la jugada no la siguen con la cabeza (y así se reparte el coste)
const MIRA_FUERZA := 0.85      ## la influencia de M-098
const RITMO_MIRA := 2.2        ## 1/s
const PIE_LEJOS := 1.3         ## m (horizontal, del jugador al balón): desde aquí empieza a acercar el pie
const PIE_CERCA := 0.6         ## m: aquí el peso es el máximo
const PIE_MAX := 0.85
const PIE_MAX_GESTO := 0.45    ## durante un golpeo el clip ya lleva el pie: el IK solo corrige un poco
const PIE_ALTO := 0.45         ## m: con el balón más alto, nada (lo resuelven las animaciones de cabeza/pecho/volea)
const RITMO_PIE := 6.0         ## 1/s
const RITMO_INERCIA := 3.0     ## 1/s
## Ciclos en los que el pecho no se tuerce hacia la marcha (va de espaldas, de lado o en guardia).
const SIN_TORSO := ["trotar_atras", "marcar", "portero_listo", "portero_lateral_der", "portero_lateral_izq"]

var motor: Node
var balon: Node3D
## Por nodo de jugador (id de instancia): [nodo, LookAtModifier3D o null, PieBalonIK o null, InerciaCuerpo o null]. Se llena al vuelo: los que entran
## de cambio también miran (antes no llevaban la mirada); los que salen o son expulsados se apagan.
var _por_nodo: Dictionary = {}
## Medida del coste (`pruebas/medir_h1_animacion.gd`): microsegundos acumulados en `actualizar` y llamadas.
var us_total := 0
var llamadas := 0
## El control orientado: quién se hizo con el balón y cuándo (tiempo del motor), y la velocidad del balón medida aquí.
var _control_id: Variant = null
var _control_t := -10.0
var _bp_ant := Vector3.INF
var _bvel := Vector3.ZERO

## ¿Van los retoques en esta calidad? (sin coste en las bajas).
static func activa_en(calidad: int, ligero: bool) -> bool:
	return encendida and calidad >= Calidad.MEDIA and not ligero

## Lo llama `MiradaBalon.poner(jugadores, balon, motor)` tras `motor.preparar`. Devuelve el nodo, o null si la calidad no lo lleva.
static func poner(m: Node, b: Node3D) -> AnimacionCercana:
	if not encendida or m == null or b == null:
		return null
	if not activa_en(Calidad.elegida, Calidad.partido_ligero):
		apagar_miradas(m.get("jugadores"))
		return null
	if m.get_node_or_null("AnimacionCercana") != null:
		return m.get_node("AnimacionCercana")
	var o := AnimacionCercana.new()
	o.name = "AnimacionCercana"
	o.motor = m
	o.balon = b
	for p: Dictionary in m.get("jugadores"):
		o._entrada(p.get("node"))
	m.add_child(o)
	return o

## Calidades bajas: la mirada de M-098 apagada (influencia 0, sin proceso).
static func apagar_miradas(jugadores: Array) -> void:
	for p: Dictionary in jugadores:
		var nodo: Node = p.get("node")
		var esq := FutbolistaQ.esqueleto_de(nodo) if is_instance_valid(nodo) else null
		var mira: LookAtModifier3D = esq.get_node_or_null("MiradaBalon") if esq != null else null
		if mira != null:
			mira.influence = 0.0
			mira.active = false

## Los modificadores de un jugador (los pone si faltan), apagados hasta que `actualizar` les dé peso.
func _entrada(nodo: Variant) -> Array:
	if not is_instance_valid(nodo):
		return []
	var clave := (nodo as Node).get_instance_id()
	if _por_nodo.has(clave):
		return _por_nodo[clave]
	var esq := FutbolistaQ.esqueleto_de(nodo)
	var mira: LookAtModifier3D = null
	var pie: PieBalonIK = null
	if esq != null:
		MiradaBalon.poner_en(nodo, balon)
		mira = esq.get_node_or_null("MiradaBalon")
		if mira != null:
			mira.influence = 0.0
			mira.active = false
		pie = esq.get_node_or_null("PieBalonIK")
		if pie == null and esq.find_bone("thigh_l") >= 0 and esq.find_bone("foot_r") >= 0:
			pie = PieBalonIK.new()
			pie.name = "PieBalonIK"
			pie.balon = balon
			pie.cuerpo = nodo
			pie.active = false
			esq.add_child(pie)   ## el último: después de la postura y de la mirada
	var iner: InerciaCuerpo = esq.get_node_or_null("InerciaCuerpo") if esq != null else null
	if esq != null and iner == null and InerciaCuerpo.encendida and esq.find_bone("pelvis") >= 0:
		iner = InerciaCuerpo.new()
		iner.name = "InerciaCuerpo"
		iner.cuerpo = nodo
		iner.active = false
		esq.add_child(iner)
		## El primero de los modificadores: justo después de la animación (antes de la postura, la mirada y el pie).
		for h in esq.get_children():
			if h is SkeletonModifier3D and h != iner:
				esq.move_child(iner, h.get_index())
				break
	var e := [nodo, mira, pie, iner]
	_por_nodo[clave] = e
	return e

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	actualizar(delta, cam.global_position if cam != null else Vector3(0, 30, 0))

## Un fotograma: quién mira y quién pone el pie. Público para las pruebas (con una cámara inventada).
func actualizar(delta: float, cam: Vector3) -> void:
	if not is_instance_valid(balon) or not is_instance_valid(motor):
		return
	var t0 := Time.get_ticks_usec()
	var jugadores: Array = motor.get("jugadores")
	var bp := balon.global_position
	var lejos_cam2 := MIRA_CAMARA * MIRA_CAMARA
	var mira_bal2 := MIRA_BALON * MIRA_BALON
	## El del pie: el que lleva el balón o, suelto, el más cercano (siempre bajo y cerca).
	var del_pie := -1
	var d_pie := INF
	if bp.y < PIE_ALTO:
		var pos_d: Dictionary = motor.get("poseedor")
		var id_pos: Variant = pos_d.get("id") if not pos_d.is_empty() else null
		for i in jugadores.size():
			var n: Node3D = (jugadores[i] as Dictionary).get("node")
			if not is_instance_valid(n):
				continue
			var dh := Vector2(n.global_position.x - bp.x, n.global_position.z - bp.z).length()
			if id_pos != null and (jugadores[i] as Dictionary).get("id") == id_pos:
				del_pie = i
				d_pie = dh
				break
			if dh < d_pie:
				d_pie = dh
				del_pie = i
		if d_pie > PIE_LEJOS:
			del_pie = -1
	var k_mira := maxf(clampf(delta * RITMO_MIRA, 0.0, 1.0) * MIRA_FUERZA, 0.002)
	var k_pie := maxf(clampf(delta * RITMO_PIE, 0.0, 1.0), 0.01)
	var t_motor := float(motor.get("t"))
	_seguir_control(delta, bp, t_motor)
	var k_iner := clampf(delta * RITMO_INERCIA, 0.0, 1.0)
	var vistos := {}
	for i in jugadores.size():
		var p: Dictionary = jugadores[i]
		var e := _entrada(p.get("node"))
		if e.is_empty():
			continue
		var n: Node3D = e[0]
		vistos[n.get_instance_id()] = true
		var gp := n.global_position
		var cerca_cam := gp.distance_squared_to(cam) < lejos_cam2 and n.visible
		var meta := MIRA_FUERZA if cerca_cam and gp.distance_squared_to(bp) < mira_bal2 else 0.0
		var meta_p := 0.0
		if i == del_pie and n.visible:   ## un solo jugador: sin tope de cámara (de lejos `AnimLejana` ya pausa su esqueleto)
			var tope := PIE_MAX_GESTO if float(p.get("gesto_hasta", 0.0)) > t_motor else PIE_MAX
			meta_p = tope * clampf((PIE_LEJOS - d_pie) / (PIE_LEJOS - PIE_CERCA), 0.0, 1.0)
		_llevar(e, meta, k_mira, meta_p, k_pie)
		_inercia(e[3], p, delta, 1.0 if cerca_cam else 0.0, k_iner, bp, t_motor)
	## Los que ya no juegan (cambio, expulsión): todo apagado.
	for clave: int in _por_nodo:
		if not vistos.has(clave):
			_llevar(_por_nodo[clave], 0.0, 1.0, 0.0, 1.0)
			_inercia(_por_nodo[clave][3], {}, delta, 0.0, 1.0, bp, t_motor)
	us_total += Time.get_ticks_usec() - t0
	llamadas += 1

## Lleva la influencia de la mirada y el peso del pie hacia su meta (suavizado) y apaga el modificador que se queda en 0.
static func _llevar(e: Array, meta: float, k_mira: float, meta_p: float, k_pie: float) -> void:
	var mira: LookAtModifier3D = e[1]
	if is_instance_valid(mira) and not is_equal_approx(mira.influence, meta):
		mira.influence = move_toward(mira.influence, meta, k_mira)
		mira.active = mira.influence > 0.001
	var pie: PieBalonIK = e[2]
	if is_instance_valid(pie) and not is_equal_approx(pie.peso, meta_p):
		pie.peso = move_toward(pie.peso, meta_p, k_pie)
		if pie.peso < 0.001:
			pie.peso = 0.0
		pie.active = pie.peso > 0.0

## Quién acaba de hacerse con el balón (para el control orientado) y hacia dónde va el balón.
func _seguir_control(delta: float, bp: Vector3, t_motor: float) -> void:
	if _bp_ant != Vector3.INF and delta > 0.0 and bp.distance_to(_bp_ant) < InerciaCuerpo.SALTO:
		_bvel = _bvel.lerp((bp - _bp_ant) / delta, clampf(delta * 10.0, 0.0, 1.0))
	_bp_ant = bp
	var pos_d: Dictionary = motor.get("poseedor")
	var id_pos: Variant = pos_d.get("id") if not pos_d.is_empty() else null
	if id_pos != _control_id:
		_control_id = id_pos
		_control_t = t_motor

## La inercia de un jugador: peso suave hacia su meta; con peso, mide y se aplica; sin él, apagada (no cuesta).
func _inercia(iner: InerciaCuerpo, p: Dictionary, delta: float, meta: float, k: float, bp: Vector3, t_motor: float) -> void:
	if not is_instance_valid(iner):
		return
	iner.peso = move_toward(iner.peso, meta, k)
	if iner.peso < 0.001:
		if iner.active:
			iner.peso = 0.0
			iner.active = false
			iner.olvidar()
		return
	iner.active = true
	var hacia := Vector3.INF
	if _control_id != null and p.get("id") == _control_id and t_motor - _control_t < InerciaCuerpo.CONTROL:
		hacia = bp + _bvel * 0.3
	var girar := not bool(p.get("por", false)) and not (String(p.get("anim_actual", "")) in SIN_TORSO)
	iner.seguir(delta, hacia, girar)
