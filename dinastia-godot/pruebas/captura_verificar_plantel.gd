extends Node
## Verificación de `PanelPlantel` (26-9-2026): abre `principal.tscn`, entra a
## "Mi plantel" y PULSA una cabecera de columna para confirmar que el orden
## cambia de verdad -no solo que la rejilla se pinta- y que tocar el nombre de
## un jugador sigue saltando a su ficha (la navegación que se pasó como
## `Callable` en vez de duplicarla).
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_verificar_plantel.tscn

const ESPERA := 12

var _pantalla: Node
var _fallos := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _mal(txt: String) -> void:
	print("MAL: " + txt)
	_fallos += 1

func _boton_con_texto(raiz: Node, contiene: String) -> Button:
	for n in raiz.get_children():
		if n is Button and String(n.text).contains(contiene):
			return n
		var enc := _boton_con_texto(n, contiene)
		if enc != null:
			return enc
	return null

func _primer_nombre_pintado(lista: VBoxContainer) -> String:
	## La rejilla es un solo GridContainer de 6 columnas: el primer botón
	## (columna NOMBRE) de la segunda fila en adelante es el primer jugador.
	var g: GridContainer = lista.get_child(0)
	for n in g.get_children():
		if n is HBoxContainer:
			for hijo in n.get_children():
				if hijo is Button:
					return String(hijo.text)
	return ""

func _process(_d: float) -> void:
	_n_tick()

var _n := 0
func _n_tick() -> void:
	_n += 1
	if _n == ESPERA:
		_pantalla.call("_ir_a_pestana", "Mi plantel")

	if _n == ESPERA + 3:
		var lista = _pantalla.get("_lista_plantel")
		if lista == null or lista.get_child_count() == 0:
			_mal("_lista_plantel está vacía")
			get_tree().quit(1)
			return
		var antes := _primer_nombre_pintado(lista)
		print("orden inicial (por media): primero es %s" % antes)
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_plantel.png")
		print("captura: pantalla_plantel.png")

		## Pulsar la cabecera NOMBRE: pasa a orden alfabético.
		var b := _boton_con_texto(lista, "NOMBRE")
		if b == null:
			_mal("no se encontró la cabecera NOMBRE")
		else:
			b.pressed.emit()

	if _n == ESPERA + 5:
		var lista2 = _pantalla.get("_lista_plantel")
		var despues := _primer_nombre_pintado(lista2)
		var orden: String = _pantalla.get("_orden_plantel")
		if orden != "nombre":
			_mal("pulsar la cabecera NOMBRE no cambió _orden_plantel (sigue en %s)" % orden)
		else:
			print("OK: _orden_plantel pasó a 'nombre' al pulsar la cabecera")
		print("orden tras pulsar NOMBRE: primero es %s" % despues)

		## Pulsar el nombre de ese primer jugador: debe abrir su ficha Y saltar
		## de pestaña -la navegación que sigue viviendo en Principal.
		var b2 := _boton_con_texto(lista2, despues)
		if b2 == null:
			_mal("no se encontró el botón del jugador '%s' para probar la navegación" % despues)
		else:
			b2.pressed.emit()

	if _n == ESPERA + 7:
		var pestana_activa: int = _pantalla.get("_pestanas").current_tab
		var titulo := String(_pantalla.get("_pestanas").get_tab_title(pestana_activa))
		if titulo != "Mi plantel":
			_mal("pulsar el nombre del jugador no dejó la pestaña en 'Mi plantel' (quedó en '%s')" % titulo)
		else:
			print("OK: pulsar el nombre navegó a la ficha y volvió a dejar 'Mi plantel' al frente")
		var ficha = _pantalla.get("_ficha")
		if ficha == null or ficha.get_child_count() == 0:
			_mal("la ficha no quedó pintada tras pulsar el nombre")
		else:
			print("OK: la ficha del jugador quedó pintada (%d hijos)" % ficha.get_child_count())
		print("FIN. %d fallos" % _fallos)
		get_tree().quit(_fallos)
