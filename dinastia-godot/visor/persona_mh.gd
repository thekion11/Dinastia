class_name PersonaMH
extends RefCounted
## LA PERSONA REALISTA SIN LICENCIA DUDOSA (26-10-2026, fila 7 de la propuesta de
## la s4). `persona_realista.glb` es el escaneo de una persona real bajado de
## Sketchfab sin licencia en el zip (🟡 en LICENCIAS, y además derecho de imagen).
## Este es su relevo: el humano de MakeHuman (CC0) que genera, sin Blender,
## `herramientas/makehuman/mh_generar.py` sobre el esqueleto Quaternius de 65
## huesos del juego, con traje (camisa, corbata, chaqueta, pantalón, zapatos).
## A diferencia del escaneo, TIENE esqueleto: respira con el clip «Idle» de la
## Universal Animation Library (`AnimQuaternius.cargar_real`), sin retargeting.
##
## Los dos .glb (cuerpo 4,9 MB y ropa 5,7 MB) van por LFS y desde el contenedor
## no se pueden subir: hasta que el dueño los suba (o los regenere con el script,
## ver `herramientas/makehuman/README.md`), `disponible()` es falso y
## `PersonaRealista` sigue con el escaneo. Mismo «aspecto» que `PersonaRealista`:
## ropa (chaqueta), pantalón, pelo, piel, alto y ancho.
##   PersonaMH.crear(aspecto) -> Node3D (pies en y=0, mirando a +Z)

const CUERPO := "res://assets/personas/persona_mh_cuerpo.glb"
const ROPA := "res://assets/personas/persona_mh_ropa.glb"
## Lo que tapa el traje: se ocultan para que no asome la piel a través de la ropa.
const OCULTAS_VESTIDO := ["Cuerpo_Torso", "Cuerpo_Brazos", "Cuerpo_Piernas", "Cuerpo_Pies"]
## Prendas del traje de presentador; el resto del armario (abrigo, polo) se quita.
const PRENDAS := ["Tr_Camisa", "Tr_Corbata", "Tr_Chaqueta", "Tr_Chaqueta_solapa", "Tr_Chaqueta_botones",
	"Tr_Pantalon", "Tr_Zapatos", "Tr_Suela"]
const PELOS := {"canoso": "Pelo_canoso", "rubio": "Pelo_corto", "negro": "Pelo_corto", "castaño": "Pelo_corto", "pelirrojo": "Pelo_corto"}

static var _cuerpo: PackedScene
static var _ropa: PackedScene

static func disponible() -> bool:
	return ResourceLoader.exists(CUERPO) and ResourceLoader.exists(ROPA)

static func crear(asp: Dictionary) -> Node3D:
	if not disponible():
		return null
	if _cuerpo == null:
		_cuerpo = load(CUERPO)
		_ropa = load(ROPA)
	if _cuerpo == null or _ropa == null:
		return null
	var raiz := Node3D.new()
	raiz.name = "PersonaMH"
	var modelo: Node3D = _cuerpo.instantiate()
	modelo.name = "Modelo"
	raiz.add_child(modelo)
	var esq := modelo.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if esq == null:
		raiz.free()
		return null
	## La ropa se vuelve a colgar del esqueleto del cuerpo (mismo esqueleto).
	var ropa: Node3D = _ropa.instantiate()
	for mi in ropa.find_children("*", "MeshInstance3D", true, false):
		if not PRENDAS.has(String(mi.name)):
			continue
		mi.get_parent().remove_child(mi)
		mi.owner = null
		esq.add_child(mi)
		(mi as MeshInstance3D).skeleton = NodePath("..")
	ropa.free()
	var pelo := String(PELOS.get(String(asp.get("pelo", "negro")), "Pelo_corto"))
	for mi2 in esq.find_children("*", "MeshInstance3D", false, false):
		var mi := mi2 as MeshInstance3D
		var n := String(mi.name)
		if OCULTAS_VESTIDO.has(n) or (n.begins_with("Pelo_") and n != pelo):
			mi.visible = false
			continue
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_tenir(mi, asp)
	## Escala por estatura (el modelo se mide: sus pies quedan en y=0).
	var caja := _caja(esq)
	var alto := float(asp.get("alto", 1.80))
	var s := alto / maxf(caja.size.y, 0.5)
	var ancho := float(asp.get("ancho", 1.0))
	modelo.scale = Vector3(s * ancho, s, s * ancho)
	modelo.position.y = -caja.position.y * s
	## Respira: el «Idle» de la UAL, en bucle.
	var ap := AnimationPlayer.new()
	ap.name = "Anim"
	raiz.add_child(ap)
	var idle := AnimQuaternius.cargar_real("Idle", "Modelo/Armature/Skeleton3D")
	if idle != null:
		var lib := AnimationLibrary.new()
		lib.add_animation("idle", idle)
		ap.add_animation_library("", lib)
		ap.autoplay = "idle"
	return raiz

## Color por prenda; la piel y el pelo, multiplicando su textura.
static func _tenir(mi: MeshInstance3D, asp: Dictionary) -> void:
	var original := mi.get_active_material(0) as StandardMaterial3D
	if original == null:
		return
	var n := String(mi.name)
	## Los ojos llevan el iris en el color por vértice (README del convertidor):
	## sin esto salen en blanco.
	if n == "Ojos":
		var mo := original.duplicate() as StandardMaterial3D
		mo.vertex_color_use_as_albedo = true
		mi.material_override = mo
		return
	var col := Color.WHITE
	var multiplica := false
	if n.begins_with("Tr_Chaqueta") and not n.ends_with("botones"):
		col = PersonaRealista._de(PersonaRealista.ROPAS, asp.get("ropa"), PersonaRealista.ROPAS["marino"])
	elif n == "Tr_Pantalon":
		col = PersonaRealista._de(PersonaRealista.PANTALONES, asp.get("pantalon"), PersonaRealista.PANTALONES["marino"])
	elif n.begins_with("Pelo_"):
		col = PersonaRealista._de(PersonaRealista.PELOS, asp.get("pelo"), PersonaRealista.PELOS["negro"])
	elif n.begins_with("Cuerpo_"):
		## La piel lleva su tono en la textura: el tinte multiplica.
		var t: Vector3 = PersonaRealista.PIELES.get(String(asp.get("piel", "media")), Vector3.ONE)
		col = Color(clampf(t.x, 0, 1.2), clampf(t.y, 0, 1.2), clampf(t.z, 0, 1.2))
		multiplica = true
	else:
		return
	var m := original.duplicate() as StandardMaterial3D
	## La ropa y el pelo toman el color tal cual (su albedo de fábrica es oscuro y,
	## multiplicado, todas las chaquetas salían negras).
	m.albedo_color = original.albedo_color * col if multiplica else col
	mi.material_override = m

static func _caja(esq: Skeleton3D) -> AABB:
	var caja := AABB()
	var primera := true
	for mi in esq.find_children("*", "MeshInstance3D", false, false):
		if not (mi as MeshInstance3D).visible:
			continue
		var a := (mi as MeshInstance3D).get_aabb()
		caja = a if primera else caja.merge(a)
		primera = false
	return caja
