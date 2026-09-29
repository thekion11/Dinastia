extends Node
## LA RUEDA DE PRENSA NUEVA Y LA ENTREVISTA A PIE DE CAMPO (25-9-2026, plan
## maestro B5): el periodista con nombre, el reloj, la repregunta tras titubear
## y la pregunta a pie de campo.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_entrevista.tscn
## Por fotogramas: sin tarjeta gráfica cada uno tarda casi medio segundo.
const ESPERA := 12
var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _pantalla.get("mundo") if _n >= ESPERA else null
	if _n == ESPERA:
		m.prensa.abrir_rueda(false, false)
		_pantalla.call("_refrescar")
	if _n == ESPERA + 10:
		_foto("entrevista_rueda")
		## Contestar como si hubiera tardado: llega la repregunta.
		_pantalla.set("_rueda_desde", Time.get_ticks_msec() - 15000)
		_pantalla.call("_responder", 0)
	if _n == ESPERA + 14:
		_foto("entrevista_repregunta")
		_pantalla.call("_responder", 0)
		PieDeCampo.mostrar(_pantalla, m.prensa, true, false, 3, 1)
	if _n == ESPERA + 18:
		_foto("entrevista_pie_de_campo")
		get_tree().quit()
