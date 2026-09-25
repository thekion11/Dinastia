extends Node
## Prueba de que el `user://` de las pruebas queda aislado del real
## (`herramientas/run_godot.ps1`, `--user-data-dir`): fuerza inglés y toca
## Ajustes -que es lo que dispara `_guardar_preferencias()`- para comprobar
## que el archivo de verdad del juego no se contamina nunca más.

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		print("idioma real al arrancar: %s" % Idiomas.idioma)
		Idiomas.idioma = "en"
		_pantalla.set("_secc_ajustes", "aspecto")
		_pantalla.call("_ir_a_pestana", "Ajustes")
		_pantalla.call("_refrescar")
	if _n == 14:
		var cf := ConfigFile.new()
		cf.load("user://preferencias.cfg")
		print("en disco tras poner ingles: %s" % cf.get_value("juego", "idioma", "?"))
		## El mismo arreglo que ahora lleva `captura.gd`: devolver el idioma
		## real y forzar el guardado antes de salir.
		Idiomas.idioma = "es"
		_pantalla.call("_aplicar_aspecto")
		_pantalla.call("_refrescar")
	if _n == 16:
		var cf2 := ConfigFile.new()
		cf2.load("user://preferencias.cfg")
		print("en disco tras devolverlo: %s" % cf2.get_value("juego", "idioma", "?"))
		get_tree().quit()
