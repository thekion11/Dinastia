class_name EntornoOclusion
extends Node
## EL ENTORNO DEL ESTADIO TAPADO POR SUS GRADAS (3-11-2026, R2 en MÍNIMO; 4-11 también en MEDIO, orden 32 del dueño: −33 % de dibujo sin cambio visible): visto desde dentro del recinto y a poca altura, el
## exterior (avenida, aparcamientos, árboles, horizonte) lo tapan las tribunas, pero la gráfica lo dibujaba igual: medido, ocultarlo
## quita ~220 llamadas de dibujo de ~560 (−40 %) y ~85 k triángulos del partido. Solo en calidad MÍNIMA y MEDIA y solo en estadios cerrados
## (sin lado abierto); si la cámara sale del recinto o sube más de `ALTO` m, el entorno vuelve a verse al instante. El HORIZONTE (edificios lejanos, grupo `sin_agrupar`) no se oculta nunca: se ve sobre las gradas.
const ALTO := 45.0
var entorno: Node3D
var ocultables: Array[Node3D] = []   ## todo el entorno MENOS el horizonte (grupo `sin_agrupar`): los edificios lejanos asoman sobre las gradas desde las cámaras altas (revisión 3-11)
var mx := 0.0
var mz := 0.0
var _t := 0.0

static func montar(e: Node3D, hx: float, hz: float, g: Dictionary) -> void:
	if Calidad.elegida > Calidad.MEDIO or not (g.get("abiertas", []) as Array).is_empty() or int(g.get("abierta", -1)) >= 0:
		return
	var o := EntornoOclusion.new()
	o.entorno = e
	o.mx = hx - 10.0
	o.mz = hz - 10.0
	o.name = "EntornoOclusion"
	for c in e.get_children():
		if c is Node3D and not c.is_in_group("sin_agrupar"):
			o.ocultables.append(c as Node3D)
	e.get_parent().add_child(o)

## ¿Está la cámara en `p` (mundo) dentro del recinto, abajo? (el entorno queda tapado)
func tapado(p: Vector3) -> bool:
	var l: Vector3 = p - (entorno.get_parent() as Node3D).global_position
	return absf(l.x) < mx and absf(l.z) < mz and l.y < ALTO

## Muestra u oculta lo ocultable (el horizonte se queda siempre).
func fijar(visible_: bool) -> void:
	## (6-11) Se recorren los hijos de AHORA, no la lista de `montar`: `Optimizar.agrupar` crea los MultiMesh «Agrupado» y los suyos (95 en el
	## estadio de prueba) DESPUÉS de montar la oclusión, y quedaban siempre visibles (medido: ocultarlos quita ~66 llamadas de dibujo en ULTRA BAJA).
	for c in entorno.get_children():
		if c is Node3D and not c.is_in_group("sin_agrupar"):
			(c as Node3D).visible = visible_

func _process(delta: float) -> void:
	_t += delta
	if _t < 0.2 or not is_instance_valid(entorno):
		return
	_t = 0.0
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		fijar(not tapado(cam.global_position))
