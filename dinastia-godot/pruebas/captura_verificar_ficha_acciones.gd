extends Node
## Verificación de `FichaJugadorAcciones` (26-9-2026): abre `principal.tscn` de
## verdad y PULSA los botones -no solo confirma que se pintan, confirma que
## el `Callable` que reciben de Principal ejecuta la acción real sobre
## `Mundo`-. Es la lección del bug crítico del 25-9: un botón que se ve pero
## no hace nada no da ningún error, así que hay que probarlo pulsado, no solo
## mirado.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_verificar_ficha_acciones.tscn

const ESPERA := 10

var _pantalla: Node
var _mundo: Mundo
var _jugador: Jugador
var _n := 0
var _fallos := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _mal(txt: String) -> void:
	print("MAL: " + txt)
	_fallos += 1

func _boton_con_texto(ficha: Node, contiene: String) -> Button:
	for n in ficha.get_children():
		if n is Button and String(n.text).contains(contiene):
			return n
	return null

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_mundo = _pantalla.get("mundo")
		var mio: Club = _mundo.mi_club()
		## Un jugador joven (para que salga el botón de desarrollo) y sin
		## cláusula de fidelidad todavía.
		_jugador = null
		for j in mio.plantilla:
			if j.edad < 24:
				_jugador = j
				break
		if _jugador == null:
			_jugador = mio.plantilla[0]
		_pantalla.call("_ver_ficha", _jugador)

	if _n == ESPERA + 2:
		var ficha = _pantalla.get("_ficha")
		## 1) DESARROLLO PRIORITARIO: pulsar y confirmar que el motor lo anota.
		if _jugador.edad < 24 and _mundo.entrenamiento != null:
			var antes := _mundo.entrenamiento.es_prioritario(_jugador)
			var b := _boton_con_texto(ficha, "desarrollo")
			if b == null:
				_mal("no se encontró el botón de desarrollo prioritario")
			else:
				b.pressed.emit()
				var despues := _mundo.entrenamiento.es_prioritario(_jugador)
				if despues == antes:
					_mal("pulsar 'desarrollo prioritario' no cambió el estado real (%s -> %s)" % [antes, despues])
				else:
					print("OK: desarrollo prioritario cambió de %s a %s al pulsar el botón" % [antes, despues])
		else:
			print("(sin jugador joven a mano, se salta la prueba de desarrollo)")

		## 2) RECONVERSIÓN: pulsar un botón de puesto y confirmar el cambio real.
		var pos_antes := _jugador.pos_e
		var boton_pos: Button = null
		for n in ficha.get_children():
			if n is HFlowContainer:
				for hijo in n.get_children():
					if hijo is Button and String(hijo.text) != pos_antes:
						boton_pos = hijo
						break
			if boton_pos != null:
				break
		if boton_pos == null:
			_mal("no se encontró ningún botón de reconversión de puesto")
		else:
			var texto_boton := String(boton_pos.text)
			boton_pos.pressed.emit()
			if _jugador.pos_e == pos_antes:
				_mal("pulsar reconversión ('%s') no cambió pos_e (sigue en %s)" % [texto_boton, pos_antes])
			else:
				print("OK: reconversión cambió el puesto de %s a %s al pulsar '%s'" % [pos_antes, _jugador.pos_e, texto_boton])

		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_ficha_acciones.png")
		print("captura: pantalla_ficha_acciones.png")

	if _n == ESPERA + 4:
		## 3) VENDER: "Poner en venta" -> confirmar mundo.mercado lo lista.
		_pantalla.call("_ver_ficha", _jugador)
	if _n == ESPERA + 6:
		var ficha2 = _pantalla.get("_ficha")
		var b_venta := _boton_con_texto(ficha2, "Poner en venta")
		if b_venta == null:
			_mal("no se encontró el botón 'Poner en venta'")
		else:
			b_venta.pressed.emit()
			if not _jugador.transferible:
				_mal("pulsar 'Poner en venta' no marcó al jugador como transferible")
			else:
				print("OK: 'Poner en venta' marcó transferible=true de verdad")
		print("FIN. %d fallos" % _fallos)
		get_tree().quit(_fallos)
