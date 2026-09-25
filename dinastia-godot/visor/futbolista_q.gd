class_name FutbolistaQ
extends RefCounted
## Segundo modelo de jugador: el pack Quaternius "Universal Base Characters"
## (gratuito, CC0, descargado por el usuario el 17-9-2026). A diferencia de
## `Futbolista.gd` (el modelo único reutilizado hasta hoy, `futbolista_cr7.glb`),
## este viene YA de pie, ya orientado hacia adelante, a escala casi humana
## real -no hace falta "enderezar" nada, solo escalar el pelín que falta para
## que la altura calce con la ficha del jugador, igual que hace `Futbolista`-.
##
## ESQUELETO DISTINTO. Este modelo usa nombres de hueso estilo Unreal Engine
## (`pelvis`, `spine_01/02/03`, `clavicle_l`, `hand_l`...), NO `mixamorig_*`.
## Las animaciones viven en `visor/anim_quaternius.gd` (`AnimQuaternius`),
## escritas y calibradas aparte de `AnimMixamo` -mismo principio, ejes
## distintos, medidos con una sonda propia (`pruebas/sonda_ejes_q.gd`)-.
## Por ahora el catalogo cubre "parado"/"caminar"/"trotar"/"correr" -las que
## mas se ven en un partido-, el resto queda para otra ronda.

const MODELO_MALE := "res://assets/characters/quaternius/Superhero_Male_FullBody.gltf"
const MODELO_FEMALE := "res://assets/characters/quaternius/Superhero_Female_FullBody.gltf"
const ALTURA_BASE := 1.80

## Los 2 cuerpos del tier gratis del pack (de los 6 que anuncia Quaternius en
## total: Superhero/Regular/Teen x M/F -Regular y Teen quedan en el tier
## pagado, $19.99, ver LEEME.md). Mismo esqueleto de 65 huesos en los dos, asi
## que `AnimQuaternius` les sirve a ambos sin cambiar una linea.
const MODELOS := {
	"male": MODELO_MALE,
	"female": MODELO_FEMALE,
}

static var _packed_male: PackedScene
static var _packed_female: PackedScene

## Huesos de referencia para medir la altura real del modelo -mismo criterio
## que `Futbolista.HUESO_CORONILLA`/`HUESO_PIE`: los huesos, no el AABB de la
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
	return {"nodo": raiz, "modelo": modelo, "esqueleto": esq, "anim": ap, "altura": altura}

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
