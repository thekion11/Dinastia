class_name PeatonVida
extends RefCounted
## LA ESPERA CON VIDA DE LOS PEATONES (calidad visual P3, pasada 3, 27-10-2026). Plan §2.2e: *«esperar
## (3 variantes)»*. Cuando un peatón se detiene por su cuenta (`TraficoCiudad`), ya no se queda siempre
## en «parado»: la mitad mira el móvil (clip «Idle_Torch» del pack, el brazo levantado delante, con un
## móvil en la mano derecha), un cuarto habla por teléfono (31-10: clip «telefono» de la UAL2, el móvil a la
## oreja; antes era el de charla) y el resto espera: la mitad quieto y la otra mitad con los brazos cruzados
## (UAL2). Al reanudar la marcha el móvil se guarda. Todo estático: no guarda estado.

const PROB_MOVIL := 0.5
const PROB_LLAMADA := 0.25
const PROB_CRUZADOS := 0.125
const NOMBRE_MOVIL := "Movil"

## Elige y pone la variante de espera: 0 = mira el móvil, 1 = llamada, 2 = quieto, 3 = brazos cruzados.
static func variante(r: float) -> int:
	if r < PROB_MOVIL:
		return 0
	if r < PROB_MOVIL + PROB_LLAMADA:
		return 1
	if r < PROB_MOVIL + PROB_LLAMADA + PROB_CRUZADOS:
		return 3
	return 2

static func esperar(trafico: Object, v: Dictionary, r: float) -> int:
	var k := variante(r)
	match k:
		0:
			trafico._gesto(v, "mirar_movil")
			movil(v, true)
		1:
			trafico._gesto(v, "telefono")
			movil(v, true)
		3:
			trafico._gesto(v, "brazos_cruzados")
		_:
			trafico._animar(v, "parado")
	return k

## En los andenes del metro: quien espera de pie mira el móvil, llama o se queda quieto (`variante(r)`).
static func en_anden(d: Dictionary, r: float) -> int:
	var k := variante(r)
	if k == 2:
		Mini3D.anim(d, "parado", "")
		return k
	if k == 3:
		gesto(d["nodo"], "brazos_cruzados")
		return k
	gesto(d["nodo"], "mirar_movil" if k == 0 else "telefono")
	movil(d, true)
	return k

## Un peatón suelto del pack (vestido, con pelo y andando) hijo de `padre`; `semilla` lo hace estable. {} si no hay modelo.
static func nuevo(padre: Node, semilla: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var d := PeatonQ.crear(rng)
	if d.is_empty():
		return d
	padre.add_child(d["nodo"])
	PeatonQ.terminar(d)
	Mini3D.anim(d, "caminar", "")
	return d

## Pone un clip del pack de gestos (lo carga la primera vez), como `TraficoCiudad._gesto`.
static func gesto(nodo: Node3D, g: String) -> void:
	for ap: AnimationPlayer in nodo.find_children("*", "AnimationPlayer", true, false):
		var lib := ap.get_animation_library("")
		if lib == null:
			continue
		AnimExtra.asegurar(ap, FutbolistaQ.esqueleto_de(nodo), g)   ## (con la variante sin «_Loop» del pack: la «charla» nunca se cargaba)
		if lib.has_animation(g):
			ap.play(g, 0.3)

## Un móvil (caja oscura con pantalla clara) colgado del hueso de la mano derecha, o quitado.
static func movil(v: Dictionary, poner: bool) -> void:
	var nodo: Node3D = v.get("nodo")
	if nodo == null or not is_instance_valid(nodo):
		return
	var esq: Skeleton3D = FutbolistaQ.esqueleto_de(nodo)
	if esq == null:
		return
	var viejo := esq.find_child(NOMBRE_MOVIL, false, false)
	if not poner:
		if viejo != null:
			viejo.queue_free()
		return
	if viejo != null or esq.find_bone("hand_r") < 0:
		return
	var anc := BoneAttachment3D.new()
	anc.name = NOMBRE_MOVIL
	anc.bone_name = "hand_r"
	esq.add_child(anc)
	var mi := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.07, 0.14, 0.008)
	mi.mesh = caja
	mi.material_override = Mini3D.mat(Color(0.08, 0.08, 0.09), 0.35)
	## En la palma (medido en el esqueleto: los dedos salen por +Y del hueso de la mano a 0,115 m; el
	## pulgar hacia −X/+Z, así que la palma mira a +Z): el móvil a media mano, pantalla hacia la palma.
	mi.position = Vector3(-0.01, 0.075, 0.03)
	anc.add_child(mi)
	var pantalla := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.06, 0.12, 0.002)
	pantalla.mesh = pm
	pantalla.material_override = Mini3D.mat(Color(0.75, 0.85, 0.95), 0.2, 0.6)
	pantalla.position = Vector3(-0.01, 0.075, 0.035)
	anc.add_child(pantalla)

const NOMBRE_MALETIN := "Maletin"

## Un maletín en la mano izquierda (caja de cuero con asa), o quitado. Lo lleva quien va o vuelve del trabajo en hora punta (`RutinaPeatones`).
static func maletin(v: Dictionary, poner: bool) -> void:
	var nodo: Node3D = v.get("nodo")
	if nodo == null or not is_instance_valid(nodo):
		return
	var esq: Skeleton3D = FutbolistaQ.esqueleto_de(nodo)
	if esq == null:
		return
	var viejo := esq.find_child(NOMBRE_MALETIN, false, false)
	if not poner:
		if viejo != null:
			viejo.queue_free()
		return
	if viejo != null or esq.find_bone("hand_l") < 0:
		return
	var anc := BoneAttachment3D.new()
	anc.name = NOMBRE_MALETIN
	anc.bone_name = "hand_l"
	esq.add_child(anc)
	var cuero := Mini3D.mat(Color(0.22, 0.13, 0.08) if posmod(hash(v.get("id", 0)), 2) == 0 else Color(0.08, 0.08, 0.1), 0.55)
	var caja := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1, 0.3, 0.4)
	caja.mesh = bm
	caja.material_override = cuero
	caja.position = Vector3(0.0, 0.34, 0.02)   ## colgando de la mano, el lado largo hacia delante
	anc.add_child(caja)
	var asa := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(0.025, 0.2, 0.2)
	asa.mesh = am
	asa.material_override = cuero
	asa.position = Vector3(0.0, 0.14, 0.02)
	anc.add_child(asa)

## Mochila a la espalda puesta o quitada (visible/oculta). Si el peatón no traía ninguna y hay que ponérsela, se le cuelga una de `MochilaQ`.
static func mochila(v: Dictionary, poner: bool) -> void:
	var nodo: Node3D = v.get("nodo")
	if nodo == null or not is_instance_valid(nodo):
		return
	var esq: Skeleton3D = FutbolistaQ.esqueleto_de(nodo)
	if esq == null:
		return
	for c in esq.get_children():
		if c is BoneAttachment3D and (c as BoneAttachment3D).bone_name == "spine_03" and c.get_child_count() > 0:
			(c as Node3D).visible = poner
			return
	if not poner or esq.find_bone("spine_03") < 0:
		return
	var h := PeatonQ._en_hueso(esq, "spine_03", 1.0 / maxf(esq.global_transform.basis.get_scale().y, 0.01))
	if h != null:
		var cols: Array[Color] = [Color(0.2, 0.3, 0.6), Color(0.7, 0.2, 0.2), Color(0.15, 0.15, 0.18), Color(0.2, 0.5, 0.35), Color(0.85, 0.6, 0.15)]
		MochilaQ.poner(h, cols[posmod(hash(v.get("id", 0)), cols.size())])
