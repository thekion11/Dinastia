extends Node
## TU CASA (28-9-2026): la mansión (casa moderna), la casa con jardín y el
## departamento, cada una en sus tres planos, con el DT mirando el móvil y las
## redes al lado.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_casa.tscn
const CASOS := [["mansion", "deportivo"], ["jardin", "familiar"], ["depto", "micro"]]
const POR_PLANO := 12   ## fotogramas entre cortar y disparar
var _n := 0
var _p: Node
var _pop: Control
var _caso := 0
var _plano := 0
var _espera := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n < 10:
		return
	var m: Mundo = _p.get("mundo")
	if _pop == null:
		if _caso >= CASOS.size():
			get_tree().quit()
			return
		m.vida.vivienda = CASOS[_caso][0]
		m.vida.transporte = CASOS[_caso][1]
		if _caso == 0:
			_p.call("_anotar", "✅ Victoria de visita", "El equipo gana 2-1 y se sube al tercer puesto.")
			_p.call("_anotar", "❌ Eliminados de la copa", "Caída en penales ante un club de Ascenso.")
		_pop = CasaEscena3D.abrir(_p, m, _p.get("_bandeja"))
		_plano = 0
		_espera = POR_PLANO * 2
		return
	var esc: CasaEscena3D = _pop.find_children("*", "CasaEscena3D", true, false)[0]
	## Se congela el reloj de la escena en el plano que toca.
	esc.set("_t", float(_plano) * CasaEscena3D.SEG_PLANO + 0.5)
	_espera -= 1
	if _espera > 0:
		return
	get_viewport().get_texture().get_image().save_png("res://pruebas/casa_%s_%d.png" % [CASOS[_caso][0], _plano + 1])
	_plano += 1
	_espera = POR_PLANO
	if _plano >= CasaEscena3D.PLANOS.size():
		_pop.free()
		_pop = null
		_caso += 1
