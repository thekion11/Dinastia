extends Node
## Prueba del símbolo del escudo ("ESC_SIM" del HTML): que `Escudo.simbolo_de()`
## reemplaza a las iniciales cuando se elige uno, que el picker nuevo en
## Gente → Identidad no revienta, y que se ve de verdad en pantalla.

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var mundo: Mundo = _pantalla.get("mundo")
		var c: Club = mundo.mi_club()
		print("iniciales antes = '%s'" % Escudo.iniciales(c))
		print("simbolo antes (sin elegir) = '%s'" % Escudo.simbolo_de(c))
		var lista: Array = Datos.tabla("ESC_SIM")
		print("tabla ESC_SIM: %d entradas, primera='%s'" % [lista.size(), String(lista[0])])
		var elegido: String = String(lista[3])
		c.esc_simbolo = elegido
		print("elegido = '%s'" % elegido)
		print("simbolo_de() tras elegir = '%s' (coincide=%s)" % [Escudo.simbolo_de(c), Escudo.simbolo_de(c) == elegido])
		_pantalla.set("_secc_gente", "identidad")
		_pantalla.call("_ir_a_pestana", "Gente")
		_pantalla.call("_refrescar")
		print("pantalla de identidad pintada sin reventar con simbolo elegido")
	if _n == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_simbolo_escudo.png")
		get_tree().quit()
