class_name FutbolistaQ
extends RefCounted
## El modelo de jugador: el pack Quaternius "Universal Base Characters"
## (gratuito, CC0, descargado por el usuario el 17-9-2026). Viene ya de pie,
## orientado hacia adelante y a escala casi humana: solo se escala lo que falta
## para que la altura calce con la ficha del jugador.
## (El modelo anterior, `futbolista_cr7.glb` con esqueleto Mixamo, se borró del
## proyecto el 25-9-2026 a pedido del usuario.)
##
## ESQUELETO DISTINTO. Este modelo usa nombres de hueso estilo Unreal Engine
## (`pelvis`, `spine_01/02/03`, `clavicle_l`, `hand_l`...), NO `mixamorig_*`.
## Las animaciones viven en `visor/anim_quaternius.gd` (`AnimQuaternius`),
## con los ejes medidos con una sonda propia (`pruebas/sonda_ejes_q.gd`).
## Por ahora el catalogo cubre "parado"/"caminar"/"trotar"/"correr" -las que
## mas se ven en un partido-, el resto queda para otra ronda.

const MODELO_MALE := "res://assets/characters/quaternius/Superhero_Male_FullBody.gltf"
const MODELO_FEMALE := "res://assets/characters/quaternius/Superhero_Female_FullBody.gltf"
const ALTURA_BASE := 1.80

## Los 2 cuerpos del tier gratis del pack (de los 6 que anuncia Quaternius en
## total: Superhero/Regular/Teen x M/F -Regular y Teen quedan en el tier
## pagado, $19.99, ver LEEME.md del historial de git). Mismo esqueleto de 65 huesos en los dos, asi
## que `AnimQuaternius` les sirve a ambos sin cambiar una linea.
const MODELOS := {
	"male": MODELO_MALE,
	"female": MODELO_FEMALE,
}

## MODELOS BASE EXTRA (2-11-2026, pedido del dueño: «tenemos otros modelos y no están como opciones
## básicas»): los trajes completos de «Modular Character Outfits - Fantasy» (Quaternius, CC0), que
## comparten el esqueleto de 65 huesos y por eso llevan todas las animaciones. Vienen vestidos: el
## vestidor de equipación y el pelo no se les aplican. Clave → [nombre, hombre, mujer].
const MODELOS_BASE := {
	"campesino": ["Campesino", "res://assets/characters/outfits/Male_Peasant.gltf", "res://assets/characters/outfits/Female_Peasant.gltf"],
	"explorador": ["Explorador", "res://assets/characters/outfits/Male_Ranger.gltf", "res://assets/characters/outfits/Female_Ranger.gltf"],
}
## MODELOS AJENOS (otro esqueleto, con sus propias animaciones dentro del .glb): KayKit (CC0). No pasan
## por el vestidor ni las animaciones de Quaternius; `ajeno()` los arma con su «Idle».
const MODELOS_AJENOS := {
	"kk_barbaro": ["Bárbaro", "res://assets/characters/kaykit/Barbarian.glb"],
	"kk_caballero": ["Caballero", "res://assets/characters/kaykit/Knight.glb"],
	"kk_mago": ["Mago", "res://assets/characters/kaykit/Mage.glb"],
	"kk_picaro": ["Pícaro", "res://assets/characters/kaykit/Rogue.glb"],
	"kk_picaro_capucha": ["Pícaro con capucha", "res://assets/characters/kaykit/Rogue_Hooded.glb"],
	"kk_esq_guerrero": ["Esqueleto guerrero", "res://assets/characters/kaykit/Skeleton_Warrior.glb"],
	"kk_esq_mago": ["Esqueleto mago", "res://assets/characters/kaykit/Skeleton_Mage.glb"],
	"kk_esq_picaro": ["Esqueleto pícaro", "res://assets/characters/kaykit/Skeleton_Rogue.glb"],
	"kk_esq_secuaz": ["Esqueleto secuaz", "res://assets/characters/kaykit/Skeleton_Minion.glb"],
}
## Los «Modular Men/Women» de Quaternius (CC0): civiles sin animaciones; `IdleProcedural` les da vida.
## Clave → [nombre, ruta, cuerpo].
const MODULARES_H := {"Adventurer": "Aventurero", "Beach": "Playa", "Casual": "Casual", "Casual2": "Casual 2", "Farmer": "Granjero",
	"King": "Rey", "Punk": "Punk", "Spacesuit": "Astronauta", "Suit": "Traje", "Swat": "SWAT", "Worker": "Obrero"}
const MODULARES_M := {"Adventurer": "Aventurera", "Casual": "Casual", "Formal": "Formal", "Medieval": "Medieval", "Punk": "Punk",
	"SciFi": "Ciencia ficción", "Soldier": "Soldado", "Suit": "Traje", "Witch": "Bruja", "Worker": "Obrera"}
static var _modulares: Dictionary = {}
## Todos los modelos ajenos: los KayKit y los modulares.
static func todos_ajenos() -> Dictionary:
	if _modulares.is_empty():
		for k: String in MODULARES_H:
			_modulares["mh_" + k.to_lower()] = [MODULARES_H[k], "res://assets/characters/modular/men/%s.glb" % k, "male"]
		for k: String in MODULARES_M:
			_modulares["mm_" + k.to_lower()] = [MODULARES_M[k], "res://assets/characters/modular/women/%s.glb" % k, "female"]
		for k: String in MODELOS_AJENOS:
			var f: Array = MODELOS_AJENOS[k]
			_modulares[k] = [f[0], f[1], ""]
	return _modulares

const ARMAS := ["shield", "sword", "axe", "staff", "knife", "spellbook", "wand", "crossbow", "bow", "arrow", "blade", "mug", "hammer", "dagger", "quiver", "cross"]

## ¿Está el modelo ajeno en el juego?
static func ajeno_disponible(clave: String) -> bool:
	var t := todos_ajenos()
	return t.has(clave) and ResourceLoader.exists(String((t[clave] as Array)[1]))

## Arma un modelo ajeno a `altura` m (medida por sus mallas) con su «Idle» en bucle y sin armas.
## Devuelve {"nodo","modelo","anim","altura","cuerpo","ajeno"} (sin esqueleto Quaternius). `padre` en el árbol.
static func ajeno(padre: Node3D, clave: String, altura: float) -> Dictionary:
	if not ajeno_disponible(clave):
		return {}
	var packed: PackedScene = load(String((todos_ajenos()[clave] as Array)[1]))
	if packed == null:
		return {}
	var modelo: Node3D = packed.instantiate()
	var raiz := Node3D.new()
	raiz.add_child(modelo)
	padre.add_child(raiz)
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		var nom := String(mi.name).to_lower()
		for a: String in ARMAS:
			if nom.contains(a):
				(mi as MeshInstance3D).visible = false
				break
	## Altura: de los pies a la coronilla de las mallas visibles.
	var ymin := 1e9
	var ymax := -1e9
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.visible and m.mesh != null:
			var bb := m.global_transform * m.get_aabb()
			ymin = minf(ymin, bb.position.y)
			ymax = maxf(ymax, bb.end.y)
	var h := ymax - ymin
	if h > 0.1:
		modelo.scale = Vector3.ONE * (altura / h)
		modelo.position.y = -ymin * altura / h
	var ap: AnimationPlayer = null
	var aps := modelo.find_children("*", "AnimationPlayer", true, false)
	if aps.is_empty():
		## Sin clips (los modulares): reposo procedural.
		var sks := modelo.find_children("*", "Skeleton3D", true, false)
		if not sks.is_empty():
			var ip := IdleProcedural.new()
			raiz.add_child(ip)
			ip.configurar(sks[0] as Skeleton3D)
	else:
		ap = aps[0] as AnimationPlayer
		for n: String in ["Idle", "Unarmed_Idle"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
				ap.play(n)
				break
	return {"nodo": raiz, "modelo": modelo, "anim": ap, "altura": altura, "cuerpo": "male", "ajeno": true}

static var _extra: Dictionary = {}

## ¿Existe (y carga) ese modelo base extra para ese cuerpo?
static func base_extra(modelo: String, cuerpo: String) -> PackedScene:
	if not MODELOS_BASE.has(modelo):
		return null
	var ruta := String((MODELOS_BASE[modelo] as Array)[2 if cuerpo == "female" else 1])
	if not _extra.has(ruta):
		_extra[ruta] = load(ruta) if ResourceLoader.exists(ruta) else null
	return _extra[ruta]

static var _packed_male: PackedScene
static var _packed_female: PackedScene

## Huesos de referencia para medir la altura real del modelo -los huesos, no
## el AABB de la
## malla en pose de enlace, que en un modelo con esqueleto no representa lo
## que se ve en pantalla.
const HUESO_CORONILLA := "Head"
const HUESO_PIE := "ball_l"  # la bola del pie -mas estable que el hueso del talon

static func _cargar_male() -> PackedScene:
	if _packed_male == null:
		_packed_male = load(MODELO_MALE)
	return _packed_male

static func _cargar_female() -> PackedScene:
	if _packed_female == null:
		_packed_female = load(MODELO_FEMALE)
	return _packed_female

static func _cargar(cuerpo: String) -> PackedScene:
	return _cargar_female() if cuerpo == "female" else _cargar_male()

static func esqueleto_de(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := esqueleto_de(c)
		if r:
			return r
	return null

## Altura real del modelo en sus propias unidades, midiendo hueso a hueso en
## pose de reposo -no en pantalla, no hace falta que este en el arbol-.
static func _altura_natural(esq: Skeleton3D) -> float:
	var it := esq.find_bone(HUESO_CORONILLA)
	var ip := esq.find_bone(HUESO_PIE)
	if it < 0 or ip < 0:
		return 1.82  # respaldo: el AABB ya medido a mano si algun dia faltan estos huesos
	var y_top: float = esq.get_bone_global_pose(it).origin.y
	var y_pie: float = esq.get_bone_global_pose(ip).origin.y
	return absf(y_top - y_pie) + 0.12  # +12cm: del hueso de la cabeza a la coronilla real

## Instancia un jugador Quaternius listo para plantarse en la cancha, a la
## altura pedida (en metros). `cuerpo` es "male" o "female" -cualquier otro
## valor cae en "male"-. Devuelve {"nodo":Node3D, "esqueleto":Skeleton3D}
## -sin "anim" todavia, ver cabecera-.
static func crear(altura: float = ALTURA_BASE, cuerpo: String = "male", modelo_base: String = "") -> Dictionary:
	var packed := base_extra(modelo_base, cuerpo) if modelo_base != "" else null
	if packed == null:
		packed = _cargar(cuerpo)
	if packed == null:
		push_error("FutbolistaQ: no se pudo cargar el modelo '%s'" % cuerpo)
		return {}
	var modelo: Node3D = packed.instantiate()
	var raiz := Node3D.new()
	raiz.add_child(modelo)
	var esq := esqueleto_de(modelo)
	if esq == null:
		push_error("FutbolistaQ: el modelo no trae Skeleton3D")
		return {}
	var ap := AnimationPlayer.new()
	raiz.add_child(ap)
	ap.root_node = ap.get_path_to(modelo)
	return {"nodo": raiz, "modelo": modelo, "esqueleto": esq, "anim": ap, "altura": altura, "cuerpo": cuerpo}

## Segunda mitad de crear(): llamar cuando el nodo YA esta en el arbol -la
## medida de huesos necesita transformadas actualizadas, que solo existen
## dentro del arbol de la escena.
static func terminar(d: Dictionary, acciones_experimentales: bool = false) -> void:
	var esq: Skeleton3D = d["esqueleto"]
	var altura: float = d["altura"]
	var natural := _altura_natural(esq)
	var k: float = altura / natural
	var modelo: Node3D = d["modelo"]
	modelo.scale = Vector3.ONE * k
	## Los pies al cesped: el origen del modelo ya esta a la altura de los
	## pies (a diferencia del otro modelo, que estaba a media altura) -se
	## confirma midiendo, no se da por hecho.
	modelo.position.y = 0.0
	var ap: AnimationPlayer = d.get("anim")
	if ap != null:
		var AQ = load("res://visor/anim_quaternius.gd")
		if ap.has_animation_library(""):
			ap.remove_animation_library("")
		ap.add_animation_library("", AQ.construir(esq, str(ap.get_path_to(esq)), acciones_experimentales))
