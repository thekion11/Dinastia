class_name OlaGrada
extends Node
## LA OLA Y LA ONDA DE LA GRADA (20-10-2026, M-036/044). Todo el movimiento lo
## hace `hinchada.gdshader` (ni un vértice ni una llamada más): este nodo solo
## lleva el reloj y lo escribe en los materiales del público mientras dura;
## al terminar los deja en -1 (apagado) y se borra.
##   OlaGrada.lanzar(raiz, "ola")                → la ola da dos vueltas
##   OlaGrada.lanzar(raiz, "onda", punto_mundo)  → saltos que se abren desde ahí
## La pone la vista del partido (`VistaEstadio`): la onda en cada gol, desde la
## grada del fondo donde se marcó; la ola, alguna vez con el partido decidido.

const DURA_OLA := 2.0 * TAU / 0.55 + 2.0
const DURA_ONDA := 6.0

var tipo := "ola"
var edad := 0.0
var _mats: Array = []
var _dura := DURA_OLA

static func lanzar(raiz: Node, tipo_ := "ola", centro := Vector3.ZERO) -> OlaGrada:
	if raiz == null:
		return null
	var mats := materiales(raiz)
	if mats.is_empty():
		return null
	## Una de cada tipo a la vez.
	var viejo := raiz.get_node_or_null("OlaGrada_" + tipo_)
	if viejo != null:
		viejo.name = "OlaGradaVieja"
		viejo.queue_free()
	var o := OlaGrada.new()
	o.name = "OlaGrada_" + tipo_
	o.tipo = tipo_
	o._mats = mats
	o._dura = DURA_OLA if tipo_ == "ola" else DURA_ONDA
	for m: ShaderMaterial in mats:
		if tipo_ == "ola":
			## Arranca en un sitio distinto cada vez.
			m.set_shader_parameter("ola_inicio", randf() * TAU)
		else:
			m.set_shader_parameter("onda_centro", centro)
	raiz.add_child(o)
	o._escribir(0.0)
	return o

## Los materiales del público (los de `hinchada.gdshader`), sin repetir.
static func materiales(raiz: Node) -> Array:
	var out: Array = []
	for n in raiz.find_children("*", "GeometryInstance3D", true, false):
		var sm := (n as GeometryInstance3D).material_override as ShaderMaterial
		if sm != null and sm.shader != null and sm.shader.resource_path.ends_with("hinchada.gdshader") and not out.has(sm):
			out.append(sm)
	return out

func _escribir(valor: float) -> void:
	var clave := "ola_edad" if tipo == "ola" else "onda_edad"
	for m: ShaderMaterial in _mats:
		if is_instance_valid(m):
			m.set_shader_parameter(clave, valor)

func _process(delta: float) -> void:
	edad += delta
	if edad >= _dura:
		_escribir(-1.0)
		queue_free()
		return
	_escribir(edad)

func _exit_tree() -> void:
	if edad < _dura:
		_escribir(-1.0)
