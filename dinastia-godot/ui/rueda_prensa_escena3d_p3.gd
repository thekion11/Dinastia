extends "res://ui/rueda_prensa_escena3d_p2.gd"
## [Capa 3/4 de `rueda_prensa_escena3d.gd`] _montar_periodistas, _mat, _rumbo, _montar_persona, _montar_un_periodista, _montar_camara_tv … (+4)
## tras compararla con Football Manager y EA FC).
##
## Lo que más se notaba que faltaba frente a la competencia:
##   - una sala LLENA: periodistas sentados con cabeza, libreta y algo de
##     movimiento (antes eran cápsulas grises sueltas), cámaras de TV al fondo
##     y flashes de fotógrafo;
##   - el plano del PERIODISTA QUE PREGUNTA: levanta la mano y la cámara corta
##     a él mientras se lee la pregunta, y luego vuelve al DT
##     (`enfocar_periodista()`, lo llama la rueda 2D al pintar cada pregunta).

const FILAS_SALA := 3
const POR_LADO := 4
## Tonos de piel y de ropa variados (decorado: no son personas reales).
const PIELES := [Color(0.96, 0.8, 0.66), Color(0.82, 0.62, 0.46), Color(0.6, 0.42, 0.3), Color(0.42, 0.29, 0.2)]
const ROPAS := [Color(0.18, 0.22, 0.32), Color(0.3, 0.3, 0.33), Color(0.42, 0.2, 0.18), Color(0.2, 0.32, 0.26),
	Color(0.55, 0.52, 0.48), Color(0.14, 0.14, 0.16)]
const FOCO_SEG := 2.6

## {raiz, cabeza, brazo, fase}
var _sala: Array[Dictionary] = []
var _flash: OmniLight3D
var _flash_bola: MeshInstance3D
var _t_flash := 1.0
var _rng_sala := RandomNumberGenerator.new()
## Quién pregunta ahora (índice en `_sala`) y cuánto queda de su plano.
var _quien_pregunta := -1
var _t_foco := 0.0
var _hablando := -1

## Sustituye a las cápsulas de antes (capa 1): misma idea, gente sentada a los
## lados del pasillo central para no tapar nunca al DT en el plano de trabajo.
func _montar_periodistas() -> void:
	_rng_sala.seed = 2610
	var mat_silla := StandardMaterial3D.new()
	mat_silla.albedo_color = Color(0.2, 0.2, 0.24)
	mat_silla.roughness = 0.8
	for fila in FILAS_SALA:
		var z := 1.35 + float(fila) * 0.95
		for lado in [-1.0, 1.0]:
			for i in POR_LADO:
				var x: float = float(lado) * (1.25 + float(i) * 0.72)
				## PERSONAS DE VERDAD (26-10): las dos primeras filas, con el
				## mismo modelo que el personal del estadio, sentadas y quietas
				## (14 visibles); la fila del fondo queda en penumbra con
				## siluetas simples, que es lo que se ve de una sala llena.
				var hueco: bool = fila < 2 and i == POR_LADO - 1 and lado > 0.0
				if fila < 2 and not hueco:
					_montar_persona(Vector3(x, 0.0, z), mat_silla)
				else:
					_montar_un_periodista(Vector3(x, 0.0, z), mat_silla)
	for lado in [-1.0, 1.0]:
		_montar_camara_tv(Vector3(lado * 1.0, 0.0, 4.1))
	_flash = OmniLight3D.new()
	_flash.light_color = Color(1, 1, 1)
	_flash.light_energy = 0.0
	_flash.omni_range = 4.0
	add_child(_flash)
	_flash_bola = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	_flash_bola.mesh = sm
	var mb := StandardMaterial3D.new()
	mb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mb.albedo_color = Color(1, 1, 1)
	mb.emission_enabled = true
	mb.emission = Color(1, 1, 1)
	mb.emission_energy_multiplier = 6.0
	_flash_bola.material_override = mb
	_flash_bola.visible = false
	add_child(_flash_bola)

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m

## Rumbo para mirar al atril (los modelos miran a +Z).
static func _rumbo(pos: Vector3) -> float:
	return atan2(-pos.x, -0.8 - pos.z)

## Un periodista con el modelo de persona del juego (`PersonajeDT`), de calle,
## sentado con la pose «sentado» de la directiva y los suplentes.
func _montar_persona(pos: Vector3, mat_silla: Material) -> void:
	var raiz := Node3D.new()
	raiz.position = pos
	raiz.rotation.y = _rumbo(pos)
	add_child(raiz)
	var silla := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.46, 0.44, 0.46)
	silla.mesh = bm
	silla.material_override = mat_silla
	silla.position = Vector3(0, 0.22, -0.04)
	raiz.add_child(silla)
	var asp := PersonajeDT.aleatorio(_rng_sala)
	var ropa: String = ["camisa", "polo", "abrigo", "rayas", "vaqueros"][_rng_sala.randi() % 5]
	asp.merge({"ropa": ropa, "c_ropa": ROPAS[_rng_sala.randi() % ROPAS.size()].to_html(false),
		"c_ropa2": "e8e8e8", "corbata": false, "gorra": false, "auriculares": false}, true)
	var d := PersonajeDT.crear(raiz, asp, Color(0.2, 0.22, 0.3), Color.WHITE)
	if d.is_empty():
		raiz.queue_free()
		_montar_un_periodista(pos, mat_silla)
		return
	var n: Node3D = d["nodo"]
	PeatonQ.calzar(d, "1c1c1e")
	var ap: AnimationPlayer = d.get("anim") as AnimationPlayer
	if ap != null and ap.has_animation("sentado"):
		ap.play("sentado")
		ap.seek(_rng_sala.randf() * 0.6, true)
	var cadera := MetroCiudad.altura_cadera(n)
	if cadera > 0.0:
		n.position.y += 0.44 + 0.04 - cadera * 0.99
	_sala.append({"raiz": raiz, "ap": ap, "esq": d.get("esqueleto"), "fase": _rng_sala.randf() * TAU})

func _montar_un_periodista(pos: Vector3, mat_silla: Material) -> void:
	var raiz := Node3D.new()
	raiz.position = pos
	raiz.rotation.y = _rumbo(pos)
	add_child(raiz)
	var silla := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.44, 0.44, 0.44)
	silla.mesh = bm
	silla.material_override = mat_silla
	silla.position = Vector3(0, 0.22, 0)
	raiz.add_child(silla)
	var ropa := _mat(ROPAS[_rng_sala.randi() % ROPAS.size()])
	var torso := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.15
	cm.height = 0.58
	torso.mesh = cm
	torso.material_override = ropa
	torso.position = Vector3(0, 0.74, 0.02)
	raiz.add_child(torso)
	var cabeza := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.1
	sm.height = 0.22
	cabeza.mesh = sm
	cabeza.material_override = _mat(PIELES[_rng_sala.randi() % PIELES.size()])
	cabeza.position = Vector3(0, 1.13, 0.0)
	raiz.add_child(cabeza)
	## La libreta sobre las rodillas, clara: lo que más dice «prensa».
	var libreta := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.16, 0.02, 0.12)
	libreta.mesh = lm
	libreta.material_override = _mat(Color(0.9, 0.9, 0.86))
	libreta.position = Vector3(0, 0.6, 0.2)
	raiz.add_child(libreta)
	## El brazo que se levanta para preguntar (pivote en el hombro).
	var brazo := Node3D.new()
	brazo.position = Vector3(0.17, 0.92, 0)
	raiz.add_child(brazo)
	var bmesh := MeshInstance3D.new()
	var bc := CapsuleMesh.new()
	bc.radius = 0.045
	bc.height = 0.5
	bmesh.mesh = bc
	bmesh.material_override = ropa
	bmesh.position = Vector3(0, -0.2, 0)
	brazo.add_child(bmesh)
	## Silueta del fondo: en penumbra (no entra en `_sala`: no pregunta).
	for m: MeshInstance3D in [torso, cabeza]:
		(m.material_override as StandardMaterial3D).albedo_color *= 0.45

func _montar_camara_tv(pos: Vector3) -> void:
	var negro := _mat(Color(0.08, 0.08, 0.09))
	for i in 3:
		var pata := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.015
		cm.bottom_radius = 0.015
		cm.height = 1.4
		pata.mesh = cm
		pata.material_override = negro
		var a := TAU * float(i) / 3.0
		pata.position = pos + Vector3(cos(a) * 0.18, 0.68, sin(a) * 0.18)
		add_child(pata)
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.24, 0.26, 0.5)
	cuerpo.mesh = bm
	cuerpo.material_override = negro
	cuerpo.position = pos + Vector3(0, 1.5, 0)
	add_child(cuerpo)
	## El piloto rojo de «en directo».
	var piloto := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.018
	sm.height = 0.036
	piloto.mesh = sm
	var mp := StandardMaterial3D.new()
	mp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mp.albedo_color = Color(1, 0.15, 0.1)
	piloto.material_override = mp
	piloto.position = pos + Vector3(0.08, 1.66, -0.2)
	add_child(piloto)

## Corta al periodista que pregunta (el de la mano levantada) durante `seg`.
## La clave del periodista da siempre el mismo asiento: el mismo medio se
## sienta en el mismo sitio toda la partida.
func enfocar_periodista(clave: String, seg: float = FOCO_SEG) -> void:
	if _sala.is_empty():
		return
	_quien_pregunta = absi(hash(clave)) % _sala.size() if clave != "" else _rng_sala.randi() % _sala.size()
	_t_foco = seg

## Respiración, apuntes, la mano del que pregunta y los flashes.
func _animar_sala(delta: float) -> void:
	_t_foco = maxf(0.0, _t_foco - delta)
	## El que pregunta habla sentado y gesticula («sentado_charla»); los demás,
	## quietos en su pose (barato: no hay nada más que animar).
	var habla := _quien_pregunta if _t_foco > 0.0 else -1
	if habla != _hablando:
		_poner_pose(_hablando, "sentado")
		_poner_pose(habla, "sentado_charla")
		_hablando = habla
	_t_flash -= delta
	if _flash != null:
		_flash.light_energy = maxf(0.0, _flash.light_energy - delta * 40.0)
		_flash_bola.visible = _flash.light_energy > 0.5
		if _t_flash <= 0.0 and not _sala.is_empty():
			_t_flash = _rng_sala.randf_range(0.5, 1.8)
			var r := (_sala[_rng_sala.randi() % _sala.size()]["raiz"] as Node3D)
			_flash.position = r.position + Vector3(0, 1.3, -0.15)
			_flash_bola.position = _flash.position
			_flash.light_energy = 4.0

func _poner_pose(i: int, pose: String) -> void:
	if i < 0 or i >= _sala.size():
		return
	var ap := _sala[i].get("ap") as AnimationPlayer
	if ap == null:
		return
	var lib := ap.get_animation_library("")
	if lib != null and not ap.has_animation(pose) and AnimExtra.UAL.has(pose) and _sala[i].get("esq") != null:
		var clip: Animation = AnimQuaternius.cargar_real(String(AnimExtra.UAL[pose]), str(ap.get_path_to(_sala[i]["esq"])))
		if clip != null:
			clip.loop_mode = Animation.LOOP_LINEAR
			lib.add_animation(pose, clip)
	if ap.has_animation(pose):
		ap.play(pose, 0.4)

## El plano del que pregunta: el contraplano desde detrás del atril, algo
## alto, abierto para que se vea la sala y él con la mano levantada en medio
## (de cerca, la gente de decorado se ve tosca).
func _plano_foco() -> Dictionary:
	if _t_foco <= 0.0 or _quien_pregunta < 0:
		return {}
	var r := _sala[_quien_pregunta]["raiz"] as Node3D
	var cara := r.position + Vector3(0, 1.0, 0)
	return {"pos": Vector3(r.position.x * 0.25, 2.1, -1.2), "mira": cara, "fov": 44.0}
