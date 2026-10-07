extends Node
## Verificación visual, tras el bug crítico del 24/25-9-2026: `principal.gd`
## NO COMPILABA -código muerto (`_pintar_mercado()`, `_pintar_mesa_negociacion()`
## y compañía) que citaba `_lista_mercado`, una variable que ya no existía desde
## que `PanelMercado` la reemplazó-. El juego entero no arrancaba
## (`ui/inicio.gd` fallaba al depender de `principal.gd`), y ningún banco lo
## veía porque `pruebas/banco.gd` no carga `principal.tscn`.
##
## Y de paso, tras el pedido de "coherencia visual 2D/3D": `PanelMercado`
## recibía verde/rojo/oro SIN pasar por `_color_accesible()` -el modo
## daltónico de Ajustes no le llegaba-. Esta prueba comprueba las dos cosas:
## que la pantalla real pinta, y que el modo daltónico SÍ cambia los colores
## de la pestaña Mercado.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_verificar_mercado.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node
var _fallos := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_pantalla.call("_ir_a_pestana", "Mercado")
	if _n == ESPERA + 3:
		var panel = _pantalla.get("_panel_mercado")
		if panel == null:
			print("MAL: _panel_mercado es null")
			_fallos += 1
		else:
			print("OK: _panel_mercado existe, %d hijos pintados" % panel.get_child_count())
			var verde_normal: Color = panel.COL_VERDE
			print("  verde sin modo daltonico: %s" % verde_normal)
			if verde_normal != Color("4caf6d"):
				print("MAL: el verde normal no es el esperado")
				_fallos += 1
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_mercado_verificado.png")
		print("captura: pantalla_mercado_verificado.png")

		## Ahora se activa el modo daltonico y se refresca, como haria el
		## propio checkbox de Ajustes.
		_pantalla.set("_daltonico", true)
		_pantalla.call("_refrescar")
	if _n == ESPERA + 5:
		var panel = _pantalla.get("_panel_mercado")
		var verde_dalt: Color = panel.COL_VERDE
		print("  verde CON modo daltonico: %s" % verde_dalt)
		if verde_dalt == Color("56b4e9"):
			print("OK: PanelMercado recibe el verde accesible (Okabe-Ito) cuando el modo esta activo")
		else:
			print("MAL: PanelMercado sigue con el verde de siempre en modo daltonico (%s)" % verde_dalt)
			_fallos += 1
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/pantalla_mercado_daltonico.png")
		print("captura: pantalla_mercado_daltonico.png")
		print("FIN. %d fallos" % _fallos)
		get_tree().quit(_fallos)
