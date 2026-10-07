extends Node
## Verificación de `PanelFinanzas` (26-9-2026): abre `principal.tscn` de verdad,
## va a la pestaña Finanzas y PULSA botones reales -"Firmar" auspicio, lanzar
## una campaña, tomar un crédito- para confirmar que el `Callable` que reciben
## de Principal ejecuta la mutación real sobre `Mundo`, no solo que se pintan.
## Misma disciplina que `captura_verificar_ficha_acciones.gd` el mismo día.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_verificar_finanzas.tscn

const ESPERA := 12

var _pantalla: Node
var _mundo: Mundo
var _n := 0
var _fallos := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _mal(txt: String) -> void:
	print("MAL: " + txt)
	_fallos += 1

## Recursivo: los botones de Finanzas viven dentro de HBoxContainer/
## GridContainer anidados, a diferencia de la ficha del jugador donde son
## hijos directos.
func _boton_con_texto(raiz: Node, contiene: String) -> Button:
	for n in raiz.get_children():
		if n is Button and String(n.text).contains(contiene):
			return n
		var enc := _boton_con_texto(n, contiene)
		if enc != null:
			return enc
	return null

## El botón de una campaña es SOLO el precio (`_dinero()`, p.ej. "700k EUR"),
## a diferencia del de la tienda ("Lanzar  700k EUR") o el crédito ("Tomar").
## Se distingue por empezar con un dígito.
func _boton_precio_puro(raiz: Node) -> Button:
	for n in raiz.get_children():
		if n is Button and String(n.text).length() > 0 and String(n.text)[0].is_valid_int():
			return n
		var enc := _boton_precio_puro(n)
		if enc != null:
			return enc
	return null

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_mundo = _pantalla.get("mundo")
		_pantalla.call("_ir_a_pestana", "Finanzas")

	if _n == ESPERA + 3:
		var lista = _pantalla.get("_lista_finanzas")
		if lista == null or lista.get_child_count() == 0:
			_mal("_lista_finanzas está vacía tras ir a la pestaña")
			get_tree().quit(1)
			return

		## 1) FIRMAR AUSPICIO: si hay ofertas sobre la mesa, pulsar la primera.
		if _mundo.auspicio != null and _mundo.auspicio.contrato.is_empty() and not _mundo.auspicio.ofertas.is_empty():
			var b := _boton_con_texto(lista, "Firmar")
			if b == null:
				_mal("no se encontró el botón 'Firmar' del auspicio")
			else:
				b.pressed.emit()
				if _mundo.auspicio.contrato.is_empty():
					_mal("pulsar 'Firmar' no dejó ningún contrato de auspicio")
				else:
					print("OK: 'Firmar' auspicio dejó un contrato real (%s)" % String(_mundo.auspicio.contrato.get("marca", "")))
		else:
			print("(auspicio ya firmado o sin ofertas, se salta esa prueba)")

		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_finanzas.png")
		print("captura: pantalla_finanzas.png")

	if _n == ESPERA + 5:
		_pantalla.call("_ir_a_pestana", "Finanzas")

	if _n == ESPERA + 7:
		var lista2 = _pantalla.get("_lista_finanzas")

		## 2) LANZAR CAMPAÑA: si no se ha lanzado ninguna este año.
		if not _mundo.campana_lanzada_este_anio():
			var antes := _mundo.campana_lanzada_este_anio()
			var bc := _boton_precio_puro(lista2)
			if bc == null:
				_mal("no se encontró ningún botón de campaña con coste en EUR")
			else:
				bc.pressed.emit()
				if _mundo.campana_lanzada_este_anio() == antes:
					_mal("pulsar la campaña no cambió campana_lanzada_este_anio()")
				else:
					print("OK: lanzar campaña cambió campana_lanzada_este_anio() a true")
		else:
			print("(campaña ya lanzada, se salta esa prueba)")

		## 3) TOMAR CRÉDITO: siempre hay líneas disponibles al empezar.
		var antes_prestamos := _mundo.banco.prestamos.size() if _mundo.banco != null else -1
		var bt := _boton_con_texto(lista2, "Tomar")
		if bt == null:
			_mal("no se encontró ningún botón 'Tomar' de crédito")
		else:
			bt.pressed.emit()
			var despues_prestamos := _mundo.banco.prestamos.size()
			if despues_prestamos <= antes_prestamos:
				_mal("pulsar 'Tomar' no aumentó mundo.banco.prestamos (%d -> %d)" % [antes_prestamos, despues_prestamos])
			else:
				print("OK: 'Tomar' crédito aumentó los préstamos reales (%d -> %d)" % [antes_prestamos, despues_prestamos])

		print("FIN. %d fallos" % _fallos)
		get_tree().quit(_fallos)
