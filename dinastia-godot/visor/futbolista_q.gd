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

## MODELOS BASE ELEGIBLES (11-11, sesión 12): SOLO REALISTAS. Se quitaron los de fantasía (campesino, explorador,
## KayKit: bárbaro, caballero, mago, pícaro, esqueletos), los VRM de anime/maniquí y los civiles modulares de
## aventura/granja/rey/astronauta/medieval/ciencia ficción/bruja (informe `docs/04_auditorias/avatares_2026-11-11.md`).
## Los «Modular Men/Women» de Quaternius (CC0) que quedan son civiles sin animaciones; `IdleProcedural` les da vida.
## Clave → [nombre, ruta, cuerpo].
const MODULARES_H := {"Beach": "Playa", "Casual": "Casual", "Casual2": "Casual 2", "Punk": "Punk", "Suit": "Traje", "Swat": "SWAT", "Worker": "Obrero"}
const MODULARES_M := {"Casual": "Casual", "Formal": "Formal", "Punk": "Punk", "Soldier": "Soldado", "Suit": "Traje", "Worker": "Obrera"}
static var _modulares: Dictionary = {}
## Todos los modelos ajenos elegibles: los modulares y, si está en el proyecto (no va en los builds públicos), el avatar regalo.
static func todos_ajenos() -> Dictionary:
	if _modulares.is_empty():
		for k: String in MODULARES_H:
			_modulares["mh_" + k.to_lower()] = [MODULARES_H[k], "res://assets/characters/modular/men/%s.glb" % k, "male"]
		for k: String in MODULARES_M:
			_modulares["mm_" + k.to_lower()] = [MODULARES_M[k], "res://assets/characters/modular/women/%s.glb" % k, "female"]
	return _modulares

const ARMAS := ["shield", "sword", "axe", "staff", "knife", "spellbook", "wand", "crossbow", "bow", "arrow", "blade", "mug", "hammer", "dagger", "quiver", "cross"]

## ¿Es una clave de modelo base que el juego todavía acepta? (las partidas viejas pueden traer una quitada: caen al atleta)
static func modelo_valido(clave: String) -> bool:
	return clave == "" or todos_ajenos().has(clave) or AvatarRegalo.es_clave(clave)

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
	## Un AnimationPlayer sin clips (los VRM lo traen vacío) cuenta como «sin animaciones».
	aps = aps.filter(func(n: Node) -> bool: return not (n as AnimationPlayer).get_animation_list().is_empty())
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
static func crear(altura: float = ALTURA_BASE, cuerpo: String = "male") -> Dictionary:
	var packed := _cargar(cuerpo)
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
