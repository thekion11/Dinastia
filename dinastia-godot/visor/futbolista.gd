class_name Futbolista
extends RefCounted

## Prepara el modelo humano realista para usarlo como jugador.
##
## El .glb viene tal y como lo exporto su autor: **tumbado** (Blender gira el eje
## al exportar a glTF) y con una escala cualquiera — medido, unos 4,8 unidades de
## alto y 6,4 de brazo a brazo. Un futbolista mide 1,80 sobre un campo de 105 m,
## asi que hay que enderezarlo y escalarlo o sale un gigante de rodillas.
##
## Nada de esto se corrige tocando el fichero: se hace al instanciarlo, para que
## el .glb siga siendo exactamente lo que mando el usuario y el dia que traiga
## otro modelo funcione igual sin retocarlo a mano.

const MODELO := "res://assets/characters/futbolista_cr7.glb"
const ALTURA_BASE := 1.80

static var _packed: PackedScene
## escala original de cada modelo, para poder reescalar sin ir acumulando
static var _base := {}

## Caja envolvente de todas las mallas, medida EN EL ESPACIO LOCAL de `raiz`.
##
## Ojo con la version ingenua: subir desde cada malla hasta la raiz del arbol
## acumulando transformadas mete tambien la del propio nodo que se esta midiendo
## y las de sus padres, asi que en cuanto le pones escala al modelo la medida
## cambia con el, la escala no converge nunca y el jugador se queda gigante.
## Aqui se baja desde la raiz componiendo hacia abajo, y la transformada de la
## propia raiz se deja fuera a proposito.
## `incluir_raiz`: si se cuenta tambien la transformada del propio nodo raiz.
## Para enderezar y escalar hay que contarla (la rotacion vive ahi); para saber
## el tamano "de fabrica" del modelo, no.
static func caja_de(raiz: Node, incluir_raiz: bool = true) -> AABB:
	var acc: Array = [AABB(), true]
	_medir(raiz, Transform3D.IDENTITY, acc, not incluir_raiz)
	return acc[0]

static func _medir(n: Node, t: Transform3D, acc: Array, es_raiz: bool) -> void:
	var tt := t
	if not es_raiz and n is Node3D:
		tt = t * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var a: AABB = tt * (n as MeshInstance3D).get_aabb()
		if acc[1]:
			acc[0] = a
			acc[1] = false
		else:
			acc[0] = (acc[0] as AABB).merge(a)
	for c in n.get_children():
		_medir(c, tt, acc, false)

## OJO: `get_aabb()` NO sirve para medir a este personaje. En una malla con
## esqueleto devuelve las cotas del recurso en pose de enlace, que aqui salen
## unas 400 veces mas pequenas que lo que se ve; con eso el escalado daba 1,80
## "de caja" y en pantalla seguia saliendo un gigante con la camara metida
## dentro de la camiseta. Lo que si es fiable son los HUESOS: la distancia de la
## punta de la cabeza a la punta del pie es la altura de verdad.
const HUESO_CORONILLA := "mixamorig_HeadTop_End"
const HUESO_PIE := "mixamorig_LeftToeBase"

## Coronilla y punta del pie, en coordenadas del mundo.
static func _extremos(esq: Skeleton3D) -> Array:
	var it := esq.find_bone(HUESO_CORONILLA)
	var ip := esq.find_bone(HUESO_PIE)
	if it < 0 or ip < 0:
		return []
	var t := esq.global_transform
	return [t * esq.get_bone_global_pose(it).origin, t * esq.get_bone_global_pose(ip).origin]

## POR QUE ESTO SON CONSTANTES Y NO UNA MEDIDA
##
## Con este modelo NO hay forma fiable de medir por codigo cuanto ocupa en
## pantalla, y se intentaron las dos que parecian obvias:
##   · `get_aabb()` de las mallas -> daba 0,065 (las cotas del recurso en pose de
##     enlace, con la escala 0,01 del nodo Armature encima). Escalando por ahi
##     salia un gigante con la camara metida dentro de la camiseta.
##   · la distancia entre los huesos de la coronilla y del pie -> daba 1,55, que
##     tampoco es lo que se ve, porque las matrices de enlace de la piel llevan
##     su propia escala y el dibujo no sigue a los huesos en tamano.
## Lo que SI se pudo hacer es medirlo mirando: se renderizo el modelo entero
## desde 30 m con campo de 40 grados y sale de unos 4,83 unidades de largo. De
## ahi el factor. Si algun dia se cambia de modelo hay que repetir esa medida
## (el modo crudo de debug_animacion.gd la hace: `-- parado 1 frente 30`).
const ESCALA_A_METRO := 1.80 / 4.83
## Donde cae el origen del modelo respecto a su altura. BUG REAL ENCONTRADO Y
## CORREGIDO (21-9-2026): este 0.5 ("a media altura") era una suposicion, no
## una medida -y estaba mal-. El usuario reporto jugadores "hundidos en el
## suelo"; confirmado con captura real de cerca (sin zapato visible, la media
## se corta justo en el pasto) y medido de verdad con la posicion GLOBAL del
## hueso `mixamorig_LeftToeBase` en pose de reposo (`pruebas/
## diagnostico_pivote_pies.gd`): con el offset viejo (0.5) el dedo del pie
## quedaba en Y=-0.42, unos 42 cm bajo el cesped. El origen real de este
## modelo cae mucho mas cerca de la cabeza que del centro geometrico -no es
## un cubo simetrico-, asi que el pivote correcto es 0.73, no 0.5. Si el dia
## de mañana se usa `Futbolista` con otro modelo, hay que remedir esto igual
## que `ESCALA_A_METRO`, no asumir 0.5 de nuevo.
const ALTO_PIVOTE := 0.73
## El modelo sale TUMBADO, con el eje largo del cuerpo a lo largo de X: la cabeza
## en -X y los pies en +X. Por eso girarlo en X no lo levantaba — se probaron 0,
## 90, -90 y 180 grados y en las cuatro seguia acostado, que fue lo que costo
## verlo. El giro bueno es en **Z**: -90 lleva +X a -Y, o sea los pies al suelo y
## la cabeza arriba.
const GIRO_DE_PIE := Vector3(0, 0, -90)

static func enderezar(modelo: Node3D, _esq: Skeleton3D = null) -> void:
	modelo.rotation_degrees = GIRO_DE_PIE
	modelo.force_update_transform()

## Deja al jugador de la altura pedida (en metros) y con los pies en el cesped.
## `altura` sale del propio jugador cuando el juego la manda: asi un central de
## 1,93 se ve mas alto que un extremo de 1,70, que es justo lo que pidio el
## usuario ("con el tamano correspondiente del jugador").
static func escalar(modelo: Node3D, _esq: Skeleton3D = null, altura: float = ALTURA_BASE) -> void:
	var k: float = ESCALA_A_METRO * (altura / ALTURA_BASE)
	# Se MULTIPLICA la escala que ya trae el fichero en vez de asignarle una
	# nueva, por lo mismo que con la rotacion: la del .glb es parte de como esta
	# armado el modelo, no basura que se pueda pisar.
	if not _base.has(modelo):
		_base[modelo] = modelo.scale
	modelo.scale = (_base[modelo] as Vector3) * k
	# El origen del modelo esta a media altura del cuerpo, no en los pies: sin
	# subirlo, el jugador queda enterrado hasta la cintura en el cesped.
	modelo.position.y = altura * ALTO_PIVOTE
	modelo.force_update_transform()

static func esqueleto_de(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := esqueleto_de(c)
		if r:
			return r
	return null

## Instancia un jugador listo para animar: de pie, a escala y con su
## AnimationPlayer ya cargado con todo el catalogo de animaciones.
## Devuelve {"nodo":Node3D, "anim":AnimationPlayer, "esqueleto":Skeleton3D}.
static func crear(altura: float = ALTURA_BASE) -> Dictionary:
	if _packed == null:
		_packed = load(MODELO)
	if _packed == null:
		push_error("Futbolista: no se pudo cargar " + MODELO)
		return {}
	var modelo: Node3D = _packed.instantiate()
	# Hay que meterlo en el arbol ANTES de medirlo: fuera del arbol las
	# transformadas no se actualizan y la caja sale a cero.
	var raiz := Node3D.new()
	raiz.add_child(modelo)

	var esq := esqueleto_de(modelo)
	var ap := AnimationPlayer.new()
	raiz.add_child(ap)
	ap.root_node = ap.get_path_to(modelo)
	return {"nodo": raiz, "modelo": modelo, "anim": ap, "esqueleto": esq, "altura": altura}

## Segunda mitad de crear(): hay que llamarla cuando el nodo YA esta en el arbol.
static func terminar(d: Dictionary) -> void:
	var modelo: Node3D = d["modelo"]
	var esq: Skeleton3D = d["esqueleto"]
	enderezar(modelo, esq)
	escalar(modelo, esq, float(d.get("altura", ALTURA_BASE)))
	var ap: AnimationPlayer = d["anim"]
	if esq == null or ap == null:
		return
	var AM = load("res://visor/anim_mixamo.gd")
	if ap.has_animation_library(""):
		ap.remove_animation_library("")
	ap.add_animation_library("", AM.construir(esq, str(ap.get_path_to(esq))))
	## LA "GARRA" (18-9-2026): el dedo indice existe en el modelo pero ninguna
	## animacion lo toca, asi que se queda en la pose de fabrica -asimetrica y
	## rara- para siempre. Se fija una pose relajada una sola vez aqui -no es
	## una animacion, no la pisa nada porque nada mas toca estos huesos-. Ver
	## el comentario de `AnimMixamo.aplicar_pose_relajada()`.
	AM.aplicar_pose_relajada(esq)
