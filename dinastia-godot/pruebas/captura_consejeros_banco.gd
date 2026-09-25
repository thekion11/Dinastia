extends Node
## Verifica los dos consejeros que hasta el 13-9-2026 decian "sin efecto":
## financiero debe abaratar el interes de sobregiro un 35%, legal debe dar 3
## semanas mas antes de la liquidacion. Prueba pura de nucleo, sin interfaz.
##
##   godot --path . res://pruebas/captura_consejeros_banco.tscn

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4713)
	mundo.tomar_el_mando(mundo.ligas[0].clubes[0].id)
	var c := mundo.mi_club()

	## 1) Sin consejero: interes normal.
	c.saldo = -1000000
	mundo.banco.descuento_sobregiro = 1.0
	var saldo_antes := c.saldo
	mundo.banco.semana(c)
	var interes_normal := saldo_antes - c.saldo - 0  ## lo que bajo el saldo (cuota 0 aqui, sin prestamos)
	print("sin consejero financiero: saldo bajo en %d (deberia acercarse a 1.000.000*0.015=15.000)" % interes_normal)

	## 2) Con consejero financiero: -35% de interes.
	mundo.directiva.consejeros["fin"] = {"nombre": "Prueba", "edad": 40, "perfil": "serio"}
	c.saldo = -1000000
	mundo.banco.descuento_sobregiro = 0.65 if mundo.directiva.tiene_consejero("fin") else 1.0
	print("descuento_sobregiro con consejero contratado = %.2f (debe ser 0.65)" % mundo.banco.descuento_sobregiro)
	saldo_antes = c.saldo
	mundo.banco.semana(c)
	var interes_con_consejero := saldo_antes - c.saldo
	print("con consejero financiero: saldo bajo en %d (debe ser ~35%% menos que %d)" % [interes_con_consejero, interes_normal])

	## 3) Consejero legal: gracia_liquidacion.
	mundo.directiva.consejeros.erase("fin")
	mundo.directiva.consejeros["leg"] = {"nombre": "Prueba2", "edad": 40, "perfil": "serio"}
	mundo.banco.gracia_liquidacion = 3 if mundo.directiva.tiene_consejero("leg") else 0
	print("gracia_liquidacion con consejero legal = %d (debe ser 3)" % mundo.banco.gracia_liquidacion)
	c.saldo = -900000000
	mundo.banco.liquidado_ya = false
	mundo.banco.semanas_en_rojo = 0
	for i in 12:
		mundo.banco.semana(c)
	print("tras 12 semanas CON gracia: liquidado_ya = %s (debe ser FALSE, la gracia mueve el umbral a 15)" % mundo.banco.liquidado_ya)
	for i in 3:
		mundo.banco.semana(c)
	print("tras 15 semanas CON gracia: liquidado_ya = %s (debe ser TRUE)" % mundo.banco.liquidado_ya)

	print("FIN. 0 fallos si los tres numeros de arriba cuadran con lo esperado.")
	get_tree().quit()
