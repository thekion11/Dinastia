class_name EntornoOclusion
extends Node
## EL ENTORNO DEL ESTADIO TAPADO POR SUS GRADAS (3-11-2026, R2 en MÍNIMO): visto desde dentro del recinto y a poca altura, el
## exterior (avenida, aparcamientos, árboles, horizonte) lo tapan las tribunas, pero la gráfica lo dibujaba igual: medido, ocultarlo
## quita ~220 llamadas de dibujo de ~560 (−40 %) y ~85 k triángulos del partido. Solo en calidad MÍNIMA y solo en estadios cerrados
## (sin lado abierto); si la cámara sale del recinto o sube más de `ALTO` m, el entorno vuelve a verse al instante.
const ALTO := 45.0
var entorno: Node3D
var mx := 0.0
var mz := 0.0
var _t := 0.0

static func montar(e: Node3D, hx: float, hz: float, g: Dictionary) -> void:
	if Calidad.elegida > Calidad.MINIMO or not (g.get("abiertas", []) as Array).is_empty() or int(g.get("abierta", -1)) >= 0:
		return
	var o := EntornoOclusion.new()
	o.entorno = e
	o.mx = hx - 10.0
	o.mz = hz - 10.0
	o.name = "EntornoOclusion"
	e.get_parent().add_child(o)

## ¿Está la cámara en `p` (mundo) dentro del recinto, abajo? (el entorno queda tapado)
func tapado(p: Vector3) -> bool:
	var l: Vector3 = p - (entorno.get_parent() as Node3D).global_position
	return absf(l.x) < mx and absf(l.z) < mz and l.y < ALTO

func _process(delta: float) -> void:
	_t += delta
	if _t < 0.2 or not is_instance_valid(entorno):
		return
	_t = 0.0
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		entorno.visible = not tapado(cam.global_position)
