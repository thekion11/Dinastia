class_name Expresion
extends Node
## EXPRESIONES DE CARA (13-10-2026): parpadeo natural y gestos de los ojos
## (alegría, sorpresa, enfado, tristeza) usando la apertura del shader de ojos.
## Los materiales de ojos se comparten en caché: al ponerle expresión a alguien
## se le duplican los suyos para no cambiar los ojos de todo el mundo.
##   Expresion.de(nodo).poner("alegre", 3.0)

const SHADER_OJOS := "res://visor/ojos_q.gdshader"
## Cuánto se abren los ojos respecto a su apertura normal.
const GESTOS := {"neutral": 1.0, "alegre": 0.62, "sorpresa": 1.3, "enfado": 0.55, "triste": 0.72, "concentrado": 0.8}

var _mats: Array[ShaderMaterial] = []
var _base: Array[float] = []
## La apertura que se puso por última vez (leerla del material daba null si el
## shader no la tenía asignada, y además es más lento cada fotograma).
var _actual: Array[float] = []
var _gesto := "neutral"
var _t_gesto := 0.0
var _t_parpadeo := 2.0
var _parpado := 0.0   ## 0 abierto, 1 cerrado
var _rng := RandomNumberGenerator.new()

## La expresión de un personaje (la crea la primera vez).
static func de(nodo: Node) -> Expresion:
	var e := nodo.get_node_or_null("Expresion") as Expresion
	if e == null:
		e = Expresion.new()
		e.name = "Expresion"
		nodo.add_child(e)
		e._buscar(nodo)
	return e

func _buscar(nodo: Node) -> void:
	_rng.randomize()
	_t_parpadeo = _rng.randf_range(1.0, 4.0)
	for mi: MeshInstance3D in nodo.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(s) as ShaderMaterial
			if m == null or m.shader == null or m.shader.resource_path != SHADER_OJOS:
				continue
			var propio := m.duplicate() as ShaderMaterial
			mi.set_surface_override_material(s, propio)
			_mats.append(propio)
			var a: Variant = propio.get_shader_parameter("apertura")
			_base.append(float(a) if a != null else 1.0)
			_actual.append(_base[_base.size() - 1])

func tiene_ojos() -> bool:
	return not _mats.is_empty()

## `segundos` <= 0: se queda hasta otro gesto.
func poner(gesto: String, segundos := 3.0) -> void:
	_gesto = gesto if GESTOS.has(gesto) else "neutral"
	_t_gesto = segundos

func gesto() -> String:
	return _gesto

## El gesto que pega con el ánimo (-1 hundido … 1 eufórico).
static func por_animo(animo: float) -> String:
	if animo > 0.35:
		return "alegre"
	if animo < -0.35:
		return "triste"
	return "neutral"

func _process(delta: float) -> void:
	if _mats.is_empty():
		set_process(false)
		return
	if _t_gesto > 0.0:
		_t_gesto -= delta
		if _t_gesto <= 0.0:
			_gesto = "neutral"
	## Parpadeo: cierra en 0,07 s y abre en 0,1 s, cada 2-6 s (a veces doble).
	_t_parpadeo -= delta
	if _t_parpadeo <= 0.0:
		_parpado = 1.0
		_t_parpadeo = _rng.randf_range(2.0, 6.0) if _rng.randf() > 0.15 else 0.25
	else:
		_parpado = move_toward(_parpado, 0.0, delta * 10.0)
	var k: float = GESTOS[_gesto]
	for i in _mats.size():
		var obj := _base[i] * k * (1.0 - _parpado * 0.95)
		_actual[i] = lerpf(_actual[i], obj, minf(1.0, delta * 14.0)) if _parpado < 0.5 else obj
		_mats[i].set_shader_parameter("apertura", _actual[i])
