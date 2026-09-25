class_name RetargetFutbolQ
extends RefCounted
## Retarget en tiempo real para el mocap UE5 -> el cuerpo Quaternius.
##
## NO copia pistas locales ni intenta recomponer quaternion por quaternion.
## Los dos rigs comparten nombres, pero no el mismo reposo ni la misma
## orientacion del root. Esta clase toma la pose GLOBAL de cada hueso respecto
## a SU propio reposo y la aplica sobre el reposo GLOBAL del destino. Es el
## mismo principio del RetargetModifier3D nativo de Godot, adaptado para poder
## normalizar el root FBX que trae una rotacion de importacion de -90 grados.

const MAPA_HUESO := {"head": "Head"}

var origen: Skeleton3D
var destino: Skeleton3D
var _raiz_origen := -1
var _raiz_destino := -1
var _reposo_raiz_origen := Transform3D.IDENTITY
var _reposo_raiz_destino := Transform3D.IDENTITY
var _pares: Array[Dictionary] = []

static func crear(esq_origen: Skeleton3D, esq_destino: Skeleton3D) -> RetargetFutbolQ:
	var r := RetargetFutbolQ.new()
	r.origen = esq_origen
	r.destino = esq_destino
	r._preparar()
	return r

func _preparar() -> void:
	if origen == null or destino == null:
		return
	_raiz_origen = origen.find_bone("root")
	_raiz_destino = destino.find_bone("root")
	_reposo_raiz_origen = origen.get_bone_global_rest(_raiz_origen) if _raiz_origen >= 0 else Transform3D.IDENTITY
	_reposo_raiz_destino = destino.get_bone_global_rest(_raiz_destino) if _raiz_destino >= 0 else Transform3D.IDENTITY
	for i_origen in origen.get_bone_count():
		var nombre_origen := origen.get_bone_name(i_origen)
		var nombre_destino: String = MAPA_HUESO.get(nombre_origen, nombre_origen)
		## El root del FBX trae una correccion de importacion que no pertenece
		## al gesto humano. Se normaliza abajo, nunca se aplica al modelo.
		if nombre_destino == "root":
			continue
		var i_destino := destino.find_bone(nombre_destino)
		if i_destino < 0:
			continue
		_pares.append({
			"origen": i_origen,
			"destino": i_destino,
			"reposo_origen": origen.get_bone_global_rest(i_origen),
			"reposo_destino": destino.get_bone_global_rest(i_destino),
		})

## Debe llamarse DESPUES de que AnimationPlayer haya actualizado `origen`.
## `get_bone_global_pose()` se expresa dentro del Skeleton, no en el mundo.
func aplicar() -> void:
	if origen == null or destino == null:
		return
	var raiz_animada := origen.get_bone_global_pose(_raiz_origen) if _raiz_origen >= 0 else Transform3D.IDENTITY
	var inv_raiz_animada := raiz_animada.affine_inverse()
	var inv_raiz_reposo := _reposo_raiz_origen.affine_inverse()
	for par in _pares:
		var pose_origen: Transform3D = origen.get_bone_global_pose(int(par["origen"]))
		var reposo_origen: Transform3D = par["reposo_origen"]
		## Se quita la correccion de root antes de medir el gesto.
		var pose_modelo := inv_raiz_animada * pose_origen
		var reposo_modelo := inv_raiz_reposo * reposo_origen
		var desvio: Transform3D = pose_modelo * reposo_modelo.affine_inverse()
		var reposo_destino: Transform3D = par["reposo_destino"]
		var reposo_destino_modelo := _reposo_raiz_destino.affine_inverse() * reposo_destino
		var nueva_pose: Transform3D = _reposo_raiz_destino * (desvio * reposo_destino_modelo)
		destino.set_bone_global_pose(int(par["destino"]), nueva_pose)
