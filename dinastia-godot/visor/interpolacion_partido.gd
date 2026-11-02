class_name InterpolacionPartido
extends Node
## INTERPOLACIÓN DE LA FÍSICA DEL PARTIDO (H-01, 2-11-2026): el motor mueve el balón y a los 22 en `_physics_process` a 60 Hz; sin interpolación, a 120 FPS cada
## posición se dibuja DOS veces y el partido se ve a 60. Con `physics/common/physics_interpolation` el motor dibuja entre el paso anterior y el actual. Este nodo
## cuelga del 3D del partido y se ocupa de lo que la interpolación no sabe solo:
##   · la raíz del 3D del partido es la ÚNICA con la interpolación encendida (el resto de la aplicación, que se mueve en `_process`, la tiene apagada: `Cierre`);
##   · la cámara del partido se mueve en el paso de física (después del motor), para ir al mismo ritmo que los jugadores;
##   · los saltos (saque de centro, cambios, saque de banda, tanda…) reinician la interpolación del nodo que salta, para que no cruce el campo en un fotograma;
##   · durante el gol (`CineGol`) y las repeticiones (`Repeticion`), que mueven sus cámaras y los jugadores en `_process`, se apaga.
## `activar := false` lo apaga todo (vuelve al comportamiento de antes).

const SALTO_M := 4.0   ## más de 4 m en un paso (240 m/s) no es correr ni un tiro: es un salto

static var activar := true

var activa := false
var _pj: Node
var _raiz: Node3D
var _ultima: Dictionary = {}

static func montar(pj: Node, raiz: Node3D) -> InterpolacionPartido:
	var n := InterpolacionPartido.new()
	n.name = "InterpolacionPartido"
	n._pj = pj
	n._raiz = raiz
	raiz.add_child(n)
	return n

func _ready() -> void:
	_poner(activar)

func _poner(si: bool) -> void:
	if si == activa:
		return
	activa = si
	_raiz.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON if si else Node.PHYSICS_INTERPOLATION_MODE_OFF
	if si:
		_raiz.reset_physics_interpolation()
		_ultima.clear()

func _process(_d: float) -> void:
	var cine: Variant = _pj.get("_cine")
	var repe: Variant = _pj.get("_repe")
	var libre: bool = not is_instance_valid(cine) and not (is_instance_valid(repe) and bool(repe.get("reproduciendo")))
	_poner(activar and libre)

func _physics_process(delta: float) -> void:
	if not activa:
		return
	var motor: Variant = _pj.get("motor")
	if motor == null:
		return
	for p: Dictionary in motor.jugadores:
		_vigilar(p.get("node"))
	_vigilar(motor.balon)
	_pj.call("_actualizar_camara", delta)

## Si el nodo se ha movido más de `SALTO_M` desde el paso anterior, es un salto: se reinicia su interpolación.
func _vigilar(n: Variant) -> void:
	if not is_instance_valid(n):
		return
	var nodo := n as Node3D
	var id := nodo.get_instance_id()
	if _ultima.has(id) and (nodo.position - (_ultima[id] as Vector3)).length() > SALTO_M:
		nodo.reset_physics_interpolation()
	_ultima[id] = nodo.position
