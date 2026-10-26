class_name FlujoCaja
extends RefCounted
## LA CAJA MES A MES (s3, 26-10-2026). Antes era el resultado del año partido en
## 12 trozos iguales: una rampa recta que no avisaba de nada. Ahora se recorren
## las 48 semanas que vienen como las cobra y paga el motor: la taquilla entra la
## semana que juegas EN CASA según el calendario de tu liga (pasado el final, se
## empieza el de la siguiente, igual que este) y el resto de partidas -televisión, patrocinio,
## socios, tienda, sueldos, estructura, operación- en el cierre de mes, cada
## `Finanzas.SEMANAS_DEL_MES` semanas. Devuelve 13 saldos: hoy y fin de cada mes.
static func saldos_por_mes(c: Club, mundo: Mundo, proy: Dictionary) -> Array[int]:
	var liga: Liga = null
	for l: Liga in mundo.ligas:
		if l.clubes.has(c):
			liga = l
	var ing: Dictionary = proy.get("ingresos", {})
	var gas: Dictionary = proy.get("gastos", {})
	var en_casa_temporada := 0
	if liga != null:
		for jornada: Array in liga.calendario:
			for par: Array in jornada:
				if par[0] == c:
					en_casa_temporada += 1
	var por_partido := int(ing.get("Taquilla", 0)) / maxi(1, en_casa_temporada)
	var cierre := 0
	for k: String in ing:
		if k != "Taquilla":
			cierre += int(ing[k])
	for k: String in gas:
		cierre -= int(gas[k])
	cierre /= Finanzas.MESES_TEMPORADA
	## La temporada dura lo que la liga más larga; después la semana vuelve a 1.
	var semanas := 1
	for l: Liga in mundo.ligas:
		semanas = maxi(semanas, l.jornadas())
	var n := liga.calendario.size() if liga != null else 0
	var saldo := c.saldo
	var saldos: Array[int] = [saldo]
	for w in range(1, 12 * Finanzas.SEMANAS_DEL_MES + 1):
		var sem := (mundo.semana - 1 + w) % semanas + 1
		if n > 0 and sem - 1 < n:
			for par: Array in liga.calendario[sem - 1]:
				if par[0] == c:
					saldo += por_partido
		if sem % Finanzas.SEMANAS_DEL_MES == 0:
			saldo += cierre
		if w % Finanzas.SEMANAS_DEL_MES == 0:
			saldos.append(saldo)
	return saldos
