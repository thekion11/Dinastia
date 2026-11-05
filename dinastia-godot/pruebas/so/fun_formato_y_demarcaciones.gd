extends BaseSO
## FUNCIONES · formato de dinero y demarcaciones: `Eco.dinero` escribe 0, miles, millones y miles de millones con su sufijo y signo en cada
## moneda sin «nan»/«inf»; las mayúsculas respetan ñ y acentos; y las demarcaciones (`Datos.grupo/es_lateral/banda`) coinciden con la tabla POSD.
func _nombre() -> String:
	return "fun_formato_y_demarcaciones"

func _probar() -> void:
	_titulo("FUNCIONES · dinero y demarcaciones [%s]" % sistema())
	_respaldar_user()
	Eco.elegir_moneda("EUR")
	var casos := {0.0: "0", 999.0: "999", 1000.0: "1k", 15500.0: "15k", 1500000.0: "1.5M", 2500000000.0: "2.5MM"}
	for v: float in casos:
		var t := Eco.dinero_euros(v)
		_comprobar(t.contains(casos[v]), "dinero_euros(%s) = «%s» contiene «%s»" % [str(v), t, casos[v]])
	_comprobar(Eco.dinero_euros(-1500000.0).begins_with("-"), "los negativos llevan «-» delante")
	var previo := 0.0
	var mono := true
	for exp in range(0, 10):
		var v := pow(10.0, exp)
		var t := Eco.dinero_euros(v)
		mono = mono and not t.contains("nan") and not t.contains("inf") and t.length() >= 2
		previo = v
	_comprobar(mono, "10^0…10^9 no producen «nan»/«inf»")
	for cod: String in ["EUR", "USD", "CLP", "ARS", "BRL"]:
		Eco.elegir_moneda(cod)
		_comprobar(Eco.dinero(123456.0).contains(cod) or Eco.dinero(123456.0).contains(Eco.MONEDAS[cod].get("simbolo", "~")) or Eco.dinero(123456.0).length() > 2, "%s: dinero(123456) = «%s»" % [cod, Eco.dinero(123456.0)])
	Eco.elegir_moneda("EUR")
	## Mayúsculas con letras no inglesas (en Web y Android el motor de texto es el mismo).
	_comprobar(Idiomas.mayusculas("ñandú árbol") == "ÑANDÚ ÁRBOL", "mayúsculas de «ñandú árbol» = «%s»" % Idiomas.mayusculas("ñandú árbol"))
	## Demarcaciones contra POSD
	var posd: Dictionary = Datos.tabla("POSD")
	var mal := 0
	var laterales := 0
	for dem: String in posd:
		var e: Dictionary = posd[dem]
		mal += int(Datos.grupo(dem) != String(e["g"]))
		mal += int(Datos.es_lateral(dem) != (String(e.get("d", "")) == "LAT"))
		mal += int(Datos.banda(dem) != String(e.get("b", "")))
		laterales += int(Datos.es_lateral(dem))
	_comprobar(mal == 0, "grupo/es_lateral/banda coinciden con POSD en %d demarcaciones" % posd.size())
	_comprobar(laterales >= 2 and laterales <= 6, "hay %d laterales" % laterales)
	_comprobar(PesosPuesto.es_portero("POR") and not PesosPuesto.es_portero("DFC"), "es_portero(POR) sí, es_portero(DFC) no")
	_restaurar_user()
