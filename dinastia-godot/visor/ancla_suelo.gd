class_name AnclaSuelo
extends Node
## EL SUELO NO SE ATRAVIESA (P4, 3-11, prueba del dueño: «los personajes atraviesan su propio cuerpo y el suelo»). Medido con
## `pruebas/ideas/p4_hitbox.tscn` sobre los 372 clips del futbolista (nueve instantes de cada uno): **50 clips hunden alguna parte del cuerpo
## bajo el césped**, hasta 43 cm (entrada de tijera, estiradas del portero, caída fea, chilena, barridas…): el hueso del pie, la mano o la
## cadera quedan por debajo del plano del campo y la malla lo atraviesa. Las manos NO se meten en el tronco en ningún clip (0 de 372).
##
## Arreglo: mientras suena uno de esos clips (`CLIPS`, de `datos/clips_bajo_suelo.json`, lo regenera la sonda con P4_GRABAR=1), este nodo
## mira cada fotograma el hueso más hundido (con el margen de grosor de cada parte: la mano no toca el césped con el centro del hueso) y
## SUBE el modelo lo justo para que quede apoyado, con suavizado (sube rápido, baja despacio) para que no dé tirones al cambiar de clip.
## Mueve solo el nodo del modelo (`Superhero_*`), nunca el del motor: la posición, la física y las colisiones del partido no cambian.

## Margen sobre el césped de cada hueso (m): el centro del hueso no puede estar más bajo que esto.
const MARGENES := {
	"ball_l": 0.0, "ball_r": 0.0, "foot_l": 0.0, "foot_r": 0.0,
	"calf_l": 0.04, "calf_r": 0.04, "thigh_l": 0.06, "thigh_r": 0.06,
	"hand_l": 0.03, "hand_r": 0.03, "lowerarm_l": 0.04, "lowerarm_r": 0.04, "upperarm_l": 0.05, "upperarm_r": 0.05,
	"pelvis": 0.09, "spine_02": 0.09, "spine_03": 0.09, "neck_01": 0.09, "Head": 0.10,
}
const RUTA_CLIPS := "res://datos/clips_bajo_suelo.json"
static var CLIPS: Dictionary = {}

var _nodo: Node3D
var _modelo: Node3D
var _esq: Skeleton3D
var _anim: AnimationPlayer
var _ids: Array = []
var _margenes: Array = []
var _base_y := 0.0
var offset := 0.0

static func _cargar() -> void:
	if not CLIPS.is_empty():
		return
	var txt := FileAccess.get_file_as_string(RUTA_CLIPS)
	var lista: Variant = JSON.parse_string(txt) if txt != "" else []
	for c: Variant in (lista as Array if lista is Array else []):
		CLIPS[String(c)] = true

## Se cuelga del nodo de un futbolista (el que crea `PlayerSpawner`). Sin esqueleto o sin modelo conocido, no hace nada.
static func poner(nodo: Node3D, anim: AnimationPlayer) -> AnclaSuelo:
	_cargar()
	var esq := FutbolistaQ.esqueleto_de(nodo)
	if esq == null or anim == null:
		return null
	var modelo: Node3D = esq.get_parent().get_parent() as Node3D if esq.get_parent() != null else null   ## Armature → modelo
	if modelo == null or modelo == nodo:
		return null
	var a := AnclaSuelo.new()
	a._nodo = nodo
	a._modelo = modelo
	a._esq = esq
	a._anim = anim
	a._base_y = modelo.position.y
	for b: String in MARGENES:
		var i := esq.find_bone(b)
		if i >= 0:
			a._ids.append(i)
			a._margenes.append(float(MARGENES[b]))
	a.process_priority = 100   ## después de que la animación haya puesto la pose de este fotograma
	a.name = "AnclaSuelo"
	nodo.add_child(a)
	return a

## Cuánto hay que subir el modelo (m) para que ningún hueso quede por debajo de su margen. Se llama con la pose ya aplicada.
func necesario() -> float:
	var peor := 0.0
	var origen := _nodo.global_position.y + (offset)
	var gt := _esq.global_transform
	for k in _ids.size():
		var y := (gt * _esq.get_bone_global_pose(int(_ids[k])).origin).y - origen
		peor = maxf(peor, float(_margenes[k]) - y)
	return peor

func _process(delta: float) -> void:
	var activo := CLIPS.has(String(_anim.assigned_animation))   ## `assigned`: el clip que acaba sin bucle deja su última pose
	if not activo and offset < 0.002:
		return
	var objetivo := necesario() if activo else 0.0
	## Sube rápido (que el pie no se vea hundido ni un fotograma), baja más despacio.
	offset = lerpf(offset, objetivo, clampf(delta * (30.0 if objetivo > offset else 8.0), 0.0, 1.0))
	if offset < 0.002 and objetivo == 0.0:
		offset = 0.0
	_modelo.position.y = _base_y + offset
