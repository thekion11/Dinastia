class_name ZonasVista
extends Node
## LA CIUDAD POR ZONAS DE VISTA (3-11-2026, R3 de la prueba del dueño en su teléfono: «que se limite la visión y las cosas del fondo no se
## carguen hasta acercarte»). La geometría GRANDE (edificios, manzanas fusionadas: la que `OptimizarGrada.limitar_vista` deja sin límite por ser
## grande) se oculta cuando su caja queda a más de `OCULTAR` m del jugador y reaparece al bajar de `MOSTRAR` (histéresis: no parpadea en el borde).
## Solo se OCULTA (`visible = false`): nada se crea ni se destruye, así que la semilla del mundo, las colisiones y la igualdad de piezas no cambian.
## APAGADA por defecto: medido en el prólogo (MÍNIMO, opengl3) solo quita ~4 % de llamadas de dibujo y ~0 % de triángulos (docs/04_auditorias/rendimiento_120fps.md,
## «R3»): el coste está cerca, en el estadio, no en lo lejano. Se enciende con el ajuste `zonas_vista` de Ajustes de ciudad. Desde las alturas (vista aérea, cámara > 120 m) se ve todo.
const OCULTAR := 640.0
const MOSTRAR := 560.0
const GRANDE := 90.0        ## diagonal desde la que una pieza es «grande» (el resto ya lo limita `limitar_vista`)
const ALTURA_AEREA := 120.0
const CADA := 0.4           ## s entre revisiones
const MOVER := 18.0         ## m que debe moverse la cámara para volver a revisar

var _piezas: Array[GeometryInstance3D] = []
var _centros := PackedVector3Array()   ## centro de la caja en el mundo
var _mitades := PackedVector3Array()
var _ocultas := PackedByteArray()
var _t := 0.0
var _ultima := Vector3(1e9, 0, 0)

static func activa() -> bool:
	return bool(AjustesCiudad.valor("zonas_vista", false)) and OS.get_environment("SIN_ZONAS") == ""

static func montar(cb: Node3D) -> ZonasVista:
	if not activa():
		return null
	var z := cb.get_node_or_null("ZonasVista") as ZonasVista
	if z != null:
		z.queue_free()
	z = ZonasVista.new()
	z.name = "ZonasVista"
	cb.add_child(z)
	z.reunir(cb)
	return z

func reunir(cb: Node3D) -> void:
	var fuera := {}
	for r in cb.find_children("*", "Node3D", true, false):
		if r.has_meta("sin_corte"):   ## el estadio se ve desde el mapa y desde fuera: nunca se oculta
			for x in r.find_children("*", "GeometryInstance3D", true, false):
				fuera[x] = true
	for n in cb.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if fuera.has(g) or g is Label3D or not g.visible:
			continue
		var caja := g.get_aabb()
		if caja.size.length() <= GRANDE or caja.size.length() > 3000.0:   ## las enormes (suelo, agua) contienen al jugador casi siempre
			continue
		var mundo: AABB = g.global_transform * caja
		_piezas.append(g)
		_centros.append(mundo.get_center())
		_mitades.append(mundo.size * 0.5)
	_ocultas.resize(_piezas.size())
	_ocultas.fill(0)

func _process(delta: float) -> void:
	_t += delta
	if _t < CADA:
		return
	_t = 0.0
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var p := cam.global_position
	if p.distance_to(_ultima) < MOVER:
		return
	_ultima = p
	revisar(p)

## Distancia en planta del punto a la caja (0 si está dentro).
func _lejos(i: int, p: Vector3) -> float:
	var c := _centros[i]
	var m := _mitades[i]
	var dx := maxf(absf(c.x - p.x) - m.x, 0.0)
	var dz := maxf(absf(c.z - p.z) - m.z, 0.0)
	return sqrt(dx * dx + dz * dz)

func revisar(p: Vector3) -> void:
	var aereo := p.y > ALTURA_AEREA
	for i in _piezas.size():
		var g := _piezas[i]
		if not is_instance_valid(g):
			continue
		var d := _lejos(i, p)
		if _ocultas[i] == 0 and not aereo and d > OCULTAR:
			g.visible = false
			_ocultas[i] = 1
		elif _ocultas[i] == 1 and (aereo or d < MOSTRAR):
			g.visible = true
			_ocultas[i] = 0

func ocultas() -> int:
	var n := 0
	for b in _ocultas:
		n += b
	return n

func total() -> int:
	return _piezas.size()
