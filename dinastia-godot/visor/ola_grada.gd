class_name OlaGrada
extends Node
## LA OLA Y LA ONDA DE LA GRADA (20-10-2026, M-036/044). Todo el movimiento lo
## hace `hinchada.gdshader` (ni un vértice ni una llamada más): este nodo solo
## lleva el reloj y lo escribe en los materiales del público mientras dura;
## al terminar los deja en -1 (apagado) y se borra.
##   OlaGrada.lanzar(raiz, "ola")                → la ola da dos vueltas
##   OlaGrada.lanzar(raiz, "onda", punto_mundo)  → saltos que se abren desde ahí
##   OlaGrada.lanzar(raiz, "protesta")           → de pie agitando los brazos (M-045)
##   OlaGrada.mirar(raiz, balon)                 → siguen el balón con la cabeza (M-049)
##   OlaGrada.piel_de_pais(raiz, "BRA")          → tonos de piel del país (M-034)
## La pone la vista del partido (`VistaEstadio`): la onda en cada gol, desde la
## grada del fondo donde se marcó; la ola, alguna vez con el partido decidido.

const DURA_OLA := 2.0 * TAU / 0.55 + 2.0
const DURA_ONDA := 6.0
const DURA_PROTESTA := 3.0

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
	o._dura = {"ola": DURA_OLA, "onda": DURA_ONDA}.get(tipo_, DURA_PROTESTA)
	for m: ShaderMaterial in mats:
		if tipo_ == "ola":
			## Arranca en un sitio distinto cada vez.
			m.set_shader_parameter("ola_inicio", randf() * TAU)
		elif tipo_ == "onda":
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
	var clave := tipo + "_edad"
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

## Los materiales, guardados unos segundos por raíz (`mirar` va cada pocos
## fotogramas y recorrer el árbol del estadio cada vez costaría; si el estadio se
## rehace, en 5 s se vuelven a buscar).
static var _cache: Dictionary = {}
static func _mats_de(raiz: Node) -> Array:
	var clave := raiz.get_instance_id()
	var ahora := Time.get_ticks_msec()
	var c: Array = _cache.get(clave, [])
	if c.is_empty() or ahora - int(c[0]) > 5000:
		c = [ahora, materiales(raiz)]
		_cache[clave] = c
	return c[1]

## Las cabezas del público hacia el balón (M-049).
static func mirar(raiz: Node, balon: Vector3, cuanto := 1.0) -> void:
	if raiz == null:
		return
	for m: ShaderMaterial in _mats_de(raiz):
		m.set_shader_parameter("balon_pos", balon)
		m.set_shader_parameter("mira_balon", cuanto)

## Tonos de piel de la grada según el país del club de casa (M-034): la potencia
## con que se mezcla piel clara → oscura (más alta = más pieles claras). Es una
## aproximación a la población de cada país, no un dato por persona.
const PIEL_SESGO := {
	"ARG": 2.4, "URU": 2.2, "CHI": 1.8, "PAR": 1.5, "BOL": 1.0, "PER": 1.0,
	"ECU": 1.0, "COL": 0.9, "VEN": 0.9, "MEX": 1.2, "BRA": 0.75, "USA": 1.0,
	"ESP": 2.0, "ITA": 2.2, "GER": 2.2, "ENG": 1.4, "FRA": 1.0,
	"JPN": 2.6, "KOR": 2.6, "AUS": 2.0, "KSA": 0.9, "EGY": 0.8, "MAR": 0.9, "RSA": 0.5,
}
static func piel_de_pais(raiz: Node, pais: String) -> void:
	if raiz == null:
		return
	var s := float(PIEL_SESGO.get(pais, 1.5))
	for m: ShaderMaterial in materiales(raiz):
		m.set_shader_parameter("piel_sesgo", s)
