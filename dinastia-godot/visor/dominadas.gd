class_name Dominadas
extends Node3D
## LAS DOMINADAS, CON BALÓN DE VERDAD (25-9-2026). Los tres clips de
## "Juggling" del pack de mocap de fútbol (captura real) llevaban meses
## importados sin usarse; sin balón, un jugador pateando al aire no se lee como
## calentamiento. Este nodo le pone la pelota:
##
## 1. Al montarse, recorre el clip en ESE jugador (30 muestras por segundo) y
##    anota cada toque: el momento en que la punta de un pie llega arriba del
##    todo (máximo local por encima de `ALTO_TOQUE`).
## 2. Entre un toque y el siguiente, la pelota hace la parábola que la gravedad
##    exige para salir de un pie y llegar al otro justo en ese intervalo:
##    v0 = (y1 - y0 + g·T²/2) / T. No es una curva a ojo, es física: cuanto
##    más tarda el siguiente toque, más alto sube.
## Así la pelota siempre llega al pie en el instante en que el pie la toca,
## sea cual sea el clip, la estatura del jugador o la velocidad del reloj.

const G := 9.8
const RADIO := 0.11
const ALTO_TOQUE := 0.16      ## metros sobre el suelo del modelo
const SEPARACION_MIN := 0.22  ## dos toques más juntos son el mismo
const PAUSA_EN_SUELO := 2.0   ## un hueco más largo: el balón espera en el césped

var _ap: AnimationPlayer
var _clip := ""
var _largo := 1.0
var _toques: Array = []       ## [t, Vector3 en el espacio del jugador]
var _balon: MeshInstance3D

static func montar(nodo: Node3D, ap: AnimationPlayer, clip: String) -> Dominadas:
	if not is_instance_valid(ap) or not ap.has_animation(clip):
		return null
	var esq := _buscar_esqueleto(nodo)
	if esq == null:
		return null
	var d := Dominadas.new()
	d.name = "Dominadas"
	nodo.add_child(d)
	if not d._iniciar(ap, esq, clip):
		d.queue_free()
		return null
	return d

static func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for h in n.get_children():
		var r := _buscar_esqueleto(h)
		if r != null:
			return r
	return null

func cuantos_toques() -> int:
	return _toques.size()

func _iniciar(ap: AnimationPlayer, esq: Skeleton3D, clip: String) -> bool:
	_ap = ap
	_clip = clip
	_largo = ap.get_animation(clip).length
	var il := esq.find_bone("ball_l")
	var ir := esq.find_bone("ball_r")
	if il < 0 or ir < 0:
		return false
	var nodo := get_parent() as Node3D
	var a_local := nodo.global_transform.affine_inverse() * esq.global_transform
	var serie := {il: [], ir: []}
	ap.play(clip)
	var n := int(_largo * 30.0)
	for k in n + 1:
		var t := minf(float(k) / 30.0, _largo)
		ap.seek(t, true)
		for i: int in serie:
			(serie[i] as Array).append([t, a_local * esq.get_bone_global_pose(i).origin])
	var crudos: Array = []
	for i: int in serie:
		var s: Array = serie[i]
		for k in range(1, s.size() - 1):
			var y: float = (s[k][1] as Vector3).y
			if y > ALTO_TOQUE and y >= (s[k - 1][1] as Vector3).y and y > (s[k + 1][1] as Vector3).y:
				crudos.append(s[k])
	crudos.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for c: Array in crudos:
		if _toques.is_empty() or float(c[0]) - float(_toques[-1][0]) >= SEPARACION_MIN:
			## La pelota se apoya ENCIMA del empeine, no dentro del pie.
			_toques.append([c[0], (c[1] as Vector3) + Vector3(0, RADIO + 0.03, 0)])
	ap.play(clip)
	ap.seek(0.0, true)
	if _toques.size() < 2:
		return false
	_balon = MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = RADIO
	esfera.height = RADIO * 2.0
	esfera.radial_segments = 16
	esfera.rings = 8
	_balon.mesh = esfera
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.96, 0.94)
	mat.roughness = 0.55
	_balon.material_override = mat
	add_child(_balon)
	_colocar(0.0)
	return true

func _process(_delta: float) -> void:
	if not is_instance_valid(_ap) or _balon == null:
		return
	## Si el jugador hace otra cosa (se levanta a festejar un gol), la pelota
	## desaparece; vuelve cuando vuelve a las dominadas.
	_balon.visible = _ap.assigned_animation == _clip
	if _balon.visible:
		_colocar(_ap.current_animation_position)

func _colocar(t: float) -> void:
	## Toque anterior y siguiente, con la vuelta del bucle.
	var i := -1
	for k in _toques.size():
		if float(_toques[k][0]) <= t:
			i = k
	var t0: float
	var p0: Vector3
	var t1: float
	var p1: Vector3
	if i < 0:
		t0 = float(_toques[-1][0]) - _largo
		p0 = _toques[-1][1]
		t1 = float(_toques[0][0])
		p1 = _toques[0][1]
	elif i == _toques.size() - 1:
		t0 = float(_toques[i][0])
		p0 = _toques[i][1]
		t1 = float(_toques[0][0]) + _largo
		p1 = _toques[0][1]
	else:
		t0 = float(_toques[i][0])
		p0 = _toques[i][1]
		t1 = float(_toques[i + 1][0])
		p1 = _toques[i + 1][1]
	_balon.position = posicion(t0, p0, t1, p1, t)

## La posición en el tiempo `t` de un balón que sale de `p0` en `t0` y llega a
## `p1` en `t1` solo por gravedad. Estática para poder probarla sola.
static func posicion(t0: float, p0: Vector3, t1: float, p1: Vector3, t: float) -> Vector3:
	var tt := maxf(0.05, t1 - t0)
	var tau := clampf(t - t0, 0.0, tt)
	if tt > PAUSA_EN_SUELO:
		## Hueco largo (el actor se para a acomodar el balón): sale del pie,
		## cae al césped por gravedad, espera delante del pie siguiente y sube
		## en el último tramo.
		var suelo := Vector3(p1.x, RADIO, p1.z)
		var caida := sqrt(2.0 * maxf(0.0, p0.y - RADIO) / G) + 0.05
		if tau < caida:
			var c := p0.lerp(suelo, tau / caida)
			c.y = maxf(RADIO, p0.y - 0.5 * G * tau * tau)
			return c
		if tau < tt - 0.35:
			return suelo
		return suelo.lerp(p1, (tau - (tt - 0.35)) / 0.35)
	var horiz := p0.lerp(p1, tau / tt)
	var v0 := (p1.y - p0.y + 0.5 * G * tt * tt) / tt
	horiz.y = p0.y + v0 * tau - 0.5 * G * tau * tau
	return horiz
