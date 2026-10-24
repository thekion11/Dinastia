class_name MascotaQ
extends "res://visor/mascota_q_p1.gd"
## [Capa 2/2 de `mascota_q.gd`] crear, _gesto, _ready, _process

## Arma la mascota del club en `root` (ya dentro del árbol) y la devuelve.
static func crear(root: Node3D, c: Club, animal: String, pos: Vector3, giro_y: float) -> Node3D:
	if not root.is_inside_tree():
		return null
	var d := FutbolistaQ.crear(1.9, "male")
	if d.is_empty():
		return null
	var nodo: Node3D = d["nodo"]
	nodo.name = "Mascota"
	nodo.position = pos
	nodo.rotation_degrees.y = giro_y
	root.add_child(nodo)
	FutbolistaQ.terminar(d, true)
	var fila: Array = ANIMALES.get(animal, ANIMALES["oso"])
	var c1 := Color(c.color1)
	var c2 := Color(c.color2)
	var natural: Color = fila[0]
	var pelo: Color = natural.lerp(c1, float(fila[5]))
	## Camiseta del club de manga larga; piernas y "piel" del color del pelaje.
	VestidorQ.vestir_equipacion(d, c1, c2, "liso", pelo, pelo.darkened(0.2), pelo, pelo, true)

	var esq: Skeleton3D = d["esqueleto"]
	var k := 1.0 / maxf((d["modelo"] as Node3D).scale.x, 0.01)
	var mat_pelo := material_pelaje(pelo, animal)
	var claro := pelo.lightened(0.45) if animal != "pinguino" else Color(0.96, 0.96, 0.95)
	var mat_claro := material_pelaje(claro, "")

	## La cabeza, pegada al hueso para que se mueva con él.
	var cab := _pegar(esq, "Head", k)
	cab.position = Vector3(0, 0.13 * k, 0.03 * k)
	cabeza(cab, animal, fila, pelo, mat_pelo, mat_claro, c1, c2)

	## Guantes y patas: lo primero que delata un traje de mascota.
	var mat_guante := material_pelaje(Color(0.97, 0.97, 0.96) if animal in ["perro", "gato", "oso", "conejo", "mono", "leon"] else pelo.darkened(0.15), "")
	var extremidades: Array = []
	for lado in ["l", "r"]:
		var mano := _pegar(esq, "hand_" + lado, k)
		extremidades.append(mano)
		_esf(mano, Vector3(0, 0.075, 0), 0.1, mat_guante, Vector3(1.0, 1.2, 0.9))
		_cil(mano, Vector3(0, -0.01, 0), Vector3.ZERO, 0.07, 0.05, _mat(c2, 0.8))
		var pie := _pegar(esq, "foot_" + lado, k)
		extremidades.append(pie)
		_esf(pie, Vector3(0, 0.02, 0.06), 0.12, mat_pelo, Vector3(1.0, 0.75, 1.35))
		for dedo in [-1.0, 0.0, 1.0]:
			_esf(pie, Vector3(dedo * 0.05, 0.0, 0.17), 0.04, mat_claro)

	## La cola, colgando de la cintura por detrás (el modelo mira a +Z).
	var cola := Node3D.new()
	cola.name = "Cola"
	cola.position = Vector3(0, 0.95, -0.17)
	nodo.add_child(cola)
	_cola_de(cola, String(fila[3]), mat_pelo, mat_claro, c2)

	## UNA MALLA POR PARTE (20-10-2026): cada adorno era una pieza con su
	## llamada de dibujo (y otra para la sombra): la mascota de la banda costaba
	## ~106 llamadas, como cinco jugadores. Se funden por material dentro de
	## cada parte que se mueve junta; se ve igual.
	for raiz_parte: Node3D in [cab, cola] + extremidades:
		fusionar(raiz_parte)
	var ctl := MascotaQ.new()
	ctl.name = "Animador"
	ctl._ap = d["anim"]
	ctl._cuerpo = nodo
	ctl._cola = cola
	ctl._giro0 = nodo.rotation.y
	ctl._rng.seed = hash(c.id + "|mascota_baile")
	nodo.add_child(ctl)
	return nodo

func _gesto() -> void:
	if _ap == null:
		return
	var hay: Array[String] = []
	for g: String in GESTOS:
		if _ap.has_animation(g):
			hay.append(g)
	if hay.is_empty():
		if _ap.has_animation("parado"):
			_ap.play("parado")
		_hasta = 5.0
		return
	var g2: String = hay[_rng.randi() % hay.size()]
	_ap.play(g2, 0.25)
	_hasta = maxf(_ap.current_animation_length, 1.5) * float(_rng.randi_range(1, 2))

func _ready() -> void:
	_gesto()

func _process(delta: float) -> void:
	delta = minf(delta, 0.1)
	_t += delta
	if _cola != null:
		_cola.rotation.y = sin(_t * (9.0 if not _caminando else 5.0)) * 0.45
		_cola.rotation.x = -0.25 + sin(_t * 3.1) * 0.08
	if _caminando and _cuerpo != null:
		## Paseo por la banda, de un lado al otro de su sitio.
		var fwd: Vector3 = _cuerpo.global_transform.basis.z.normalized()
		_cuerpo.position += fwd * 1.1 * delta
	if _t >= _hasta:
		_t = 0.0
		if _caminando:
			_caminando = false
			_cuerpo.rotation.y = _giro0
			_gesto()
		elif _rng.randf() < 0.3 and _ap.has_animation("caminar"):
			## Camina a lo largo de la banda (de lado respecto de la
			## hinchada), una vez hacia cada lado: siempre vuelve a su sitio.
			_caminando = true
			_cuerpo.rotation.y = _giro0 + PI * 0.5 * _dir
			_dir = -_dir
			_ap.play("caminar")
			_hasta = _rng.randf_range(2.5, 4.0)
		else:
			_gesto()
