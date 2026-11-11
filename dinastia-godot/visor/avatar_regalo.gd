class_name AvatarRegalo
extends RefCounted
## EL AVATAR REGALO DEL DUEÑO (11-11, sesión 12): `assets/characters/avatar_regalo/avatar_regalo.fbx`, un avatar
## de cuerpo entero hecho por un creador de avatares a partir de una foto (cabeza, cuerpo, ojos, dientes,
## camiseta de manga larga, vaqueros y zapatillas; esqueleto Mixamo de 73 huesos, 1,82 m).
##
## LICENCIA (11-11): el dueño tiene la licencia y la cara NO es de una persona real: va en los builds y es elegible como
## avatar del jugador («Modelo base», cuerpo hombre). Si el archivo no está, `disponible()` es falso y no se ofrece.
##
## Se anima con el MISMO cuerpo y las MISMAS animaciones del juego: se crea el cuerpo Quaternius de siempre (con sus
## mallas ocultas, sirve de motor de huesos) y `AvatarRegaloRetarget` copia sus rotaciones al esqueleto del avatar.
## Devuelve el mismo diccionario que `FutbolistaQ.crear()` (nodo, modelo, esqueleto, anim, altura, cuerpo), de modo
## que gestos, banda, paso y celebraciones funcionan igual.

const CLAVE := "avatar_regalo"
const NOMBRE := "Avatar regalo"
const RUTA := "res://assets/characters/avatar_regalo/avatar_regalo.fbx"

static func es_clave(clave: String) -> bool:
	return clave == CLAVE

static func disponible() -> bool:
	return ResourceLoader.exists(RUTA)

## `padre` ya debe estar en el árbol. `altura` en metros (de los pies a la coronilla).
static func crear(padre: Node3D, altura: float) -> Dictionary:
	if not disponible():
		return {}
	var packed: PackedScene = load(RUTA)
	if packed == null:
		return {}
	var d := FutbolistaQ.crear(altura, "male")
	if d.is_empty():
		return {}
	padre.add_child(d["nodo"])
	FutbolistaQ.terminar(d, false)
	## El cuerpo Quaternius solo mueve huesos: sus mallas (y los accesorios que se le pongan) no se ven.
	for mi in (d["modelo"] as Node).find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = false
	var avatar: Node3D = packed.instantiate()
	(d["nodo"] as Node3D).add_child(avatar)
	## El avatar trae su carrera en bucle: se quita (la manda el cuerpo del juego).
	for ap in avatar.find_children("*", "AnimationPlayer", true, false):
		ap.queue_free()
	var ymin := 1e9
	var ymax := -1e9
	for mi in avatar.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.visible:
			continue
		var bb := m.global_transform * m.get_aabb()
		ymin = minf(ymin, bb.position.y)
		ymax = maxf(ymax, bb.end.y)
	var alto := ymax - ymin
	if alto > 0.1:
		avatar.scale = Vector3.ONE * (altura / alto)
		avatar.position.y = -ymin * altura / alto
	var esq_av := FutbolistaQ.esqueleto_de(avatar)
	if esq_av != null:
		var rt := AvatarRegaloRetarget.new()
		rt.name = "AvatarRegaloRetarget"
		esq_av.add_child(rt)
		rt.configurar(d["esqueleto"] as Skeleton3D)
		rt.active = true
	d["avatar"] = avatar
	d["ajeno"] = false
	return d
