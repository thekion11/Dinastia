extends BaseSO
## ESTÁNDAR · economía: la moneda se escribe bien en cada una, los factores son monótonos (más reputación → más dinero; la curva de edad no
## sube después de los 29), `escalar` nunca baja de 1, el saldo suma lo que debe y 52 semanas simuladas dejan todos los clubes con cifras
## finitas (sin NaN ni desbordes) y la masa de dinero del mundo dentro de un rango.
func _nombre() -> String:
	return "est_economia_invariantes"

func _probar() -> void:
	_titulo("ESTÁNDAR · economía [%s]" % sistema())
	_respaldar_user()
	var textos := {}
	for cod: String in ["EUR", "USD", "CLP", "ARS", "BRL", "GBP"]:
		Eco.elegir_moneda(cod)
		var t := Eco.dinero(1500000)
		textos[cod] = t
		_comprobar(t != "" and (t.contains("1") or t.contains("1,5") or t.contains("1.5")), "%s: 1.500.000 se escribe «%s»" % [cod, t])
		_comprobar(Eco.dinero(-2000).begins_with("-") or Eco.dinero(-2000).contains("-"), "%s: un importe negativo lleva signo" % cod)
	Eco.elegir_moneda("EUR")
	var previo := -1.0
	var creciente := true
	for rep in range(30, 100, 5):
		var f := Eco.factor_club(float(rep))
		creciente = creciente and f > previo
		previo = f
	_comprobar(creciente, "factor_club crece con la reputación")
	var cae := true
	var a_prev := 99.0
	for edad in range(29, 40):
		var fe := Eco.factor_edad(edad, 80, 80)
		cae = cae and fe <= a_prev
		a_prev = fe
	_comprobar(cae, "la curva de edad no sube pasados los 29")
	_comprobar(Eco.factor_edad(19, 60, 90) > Eco.factor_edad(19, 60, 60), "a igual edad, más margen de crecimiento vale más")
	for rep in [10.0, 50.0, 99.0]:
		_comprobar(Eco.escalar(0.0, rep) >= 1 and Eco.escalar(-5.0, rep) >= 1, "escalar() nunca baja de 1 (rep %d)" % int(rep))
	_comprobar(Eco.escalar(1000.0, 90.0) > Eco.escalar(1000.0, 50.0), "escalar crece con la reputación")
	_comprobar(Eco.tier_pais("ENG") > Eco.tier_pais("BOL") and Eco.tier_pais("XXX") > 0.0, "tier por país: Inglaterra > Bolivia y un país desconocido tiene valor por defecto")
	## Saldo
	var c := Club.new("c_t", "Club de prueba")
	c.mover_saldo(1000)
	c.mover_saldo(-250)
	_comprobar(c.saldo == 750, "mover_saldo suma y resta (%d)" % c.saldo)
	## 52 semanas
	var m := _mundo(20261105)
	var antes := 0
	for cl: Club in m.clubes.values():
		antes += cl.saldo
	for i in 52:
		m.avanzar_semana()
	var malos := 0
	var total := 0
	for cl: Club in m.clubes.values():
		total += cl.saldo
		if is_nan(float(cl.saldo)) or absi(cl.saldo) > 1 << 50:
			malos += 1
	_comprobar(malos == 0, "tras 52 semanas ningún club tiene una cifra absurda (%d malos)" % malos)
	_comprobar(m.anio >= 1 or m.semana >= 1, "el reloj avanzó (año %d, semana %d)" % [m.anio, m.semana])
	_comprobar(absf(float(total)) < float(1 << 56), "la masa de dinero sigue acotada")
	Eco.elegir_moneda("EUR")
	_restaurar_user()
