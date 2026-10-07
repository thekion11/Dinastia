extends Node
## Prueba de "Operación, viajes, seguridad e impuestos" (el "oper" del HTML,
## nunca portado): confirma que se cobra de verdad en el cierre de mes y que
## se ve en la pantalla de Finanzas, no solo en el motor.

var _n := 0
var _pantalla: Node
var _probado := false

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	## Si el cierre de mes coincidio con el sorteo de copa -cinematica en 3D
	## que tapa toda la pantalla-, se salta para poder ver Finanzas debajo.
	if _n > 12 and _n < 30:
		for h in _pantalla.get_children():
			if h.has_method("_saltar"):
				h.call("_saltar")
	if _n == 29 and _probado:
		_pantalla.call("_ir_a_pestana", "Finanzas")
		_pantalla.call("_refrescar")
	if _n == 30 and _probado:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_oper.png")
		get_tree().quit()
		return
	if _n != 12 or _probado:
		if _n > 400:
			get_tree().quit()
		return
	_probado = true
	var mundo: Mundo = _pantalla.get("mundo")
	var c: Club = mundo.mi_club()
	print("club=%s rep=%d semana=%d" % [c.nombre, c.rep, mundo.semana])
	print("abarata_operacion=%f" % mundo.obras.abarata_operacion())

	var vio_movimiento := false
	var monto_oper := 0
	## Avanza hasta el proximo cierre de mes (semana % 4 == 0) para ver el cobro.
	for i in 10:
		var antes := mundo.libro_financiero.size()
		mundo.avanzar_semana()
		for j in range(antes, mundo.libro_financiero.size()):
			var m: Dictionary = mundo.libro_financiero[j]
			if String(m["concepto"]) == "Operación, viajes, seguridad e impuestos":
				vio_movimiento = true
				monto_oper = int(m["monto"])
		if vio_movimiento:
			break
	print("se cobro oper=%s monto=%d (debe ser negativo)" % [vio_movimiento, monto_oper])
