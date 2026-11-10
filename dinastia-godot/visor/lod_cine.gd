class_name LodCine
extends Node
## MENOS DETALLE LEJANO EN LOS PLANOS DE CELEBRACIÓN Y REPETICIÓN (10-11). Desde el césped mirando a lo largo del campo entran las cuatro
## tribunas a la vez y el partido pasaba de ~420 a ~900 llamadas de dibujo durante esos planos (medido en Mill0narios, plano congelado).
## Mientras la cámara activa es una de esas (`CineGol`, `Repeticion_*`), se apagan las piezas PEQUEÑAS del estadio (< 6 m) que quedan a
## más de 60 m: rótulos, barandas, focos, detalles de la grada. Nunca personas ni el balón (tienen esqueleto o se llaman así). Ensayo:
## −235 llamadas sin diferencia visible en la captura. Bandera: `activo` (apagarla devuelve el comportamiento de antes).
static var activo := true   ## la bandera (las pruebas la apagan para comparar)
const LEJOS := 60.0
const CHICA := 6.0
const MUEVE := 12.0   ## si la cámara del plano se mueve más que esto, se recalcula qué queda lejos

var _apagadas: Array[GeometryInstance3D] = []
var _desde := Vector3.INF
var _cam_id := 0

static func vigilar(estadio: Node3D) -> LodCine:
	var v := LodCine.new()
	v.name = "LodCine"
	estadio.add_child(v)
	return v

static func es_cine(cam: Camera3D) -> bool:
	return cam != null and (String(cam.name) == "CineGol" or String(cam.name).begins_with("Repeticion_"))

func _process(_d: float) -> void:
	if not activo:
		return
	var cam := get_viewport().get_camera_3d()
	if not es_cine(cam):
		if not _apagadas.is_empty() or _cam_id != 0:
			_restaurar()
		return
	if cam.get_instance_id() != _cam_id or cam.global_position.distance_to(_desde) > MUEVE:
		_restaurar()
		_apagar(cam.global_position)
		_cam_id = cam.get_instance_id()

func _apagar(desde: Vector3) -> void:
	_desde = desde
	for g: Node in get_parent().find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if not gi.visible or _es_persona(gi):
			continue
		var caja := gi.global_transform * gi.get_aabb()
		if caja.size.length() < CHICA and caja.get_center().distance_to(desde) > LEJOS:
			gi.visible = false
			_apagadas.append(gi)

func _restaurar() -> void:
	for gi in _apagadas:
		if is_instance_valid(gi):
			gi.visible = true
	_apagadas.clear()
	_cam_id = 0
	_desde = Vector3.INF

func _exit_tree() -> void:
	_restaurar()

static func _es_persona(n: Node) -> bool:
	var p := n
	for _k in 8:
		if p == null:
			return false
		var nombre := String(p.name).to_lower()
		if p is Skeleton3D or nombre.contains("balon") or nombre.contains("ball") or nombre.contains("jugador"):
			return true
		p = p.get_parent()
	return false
