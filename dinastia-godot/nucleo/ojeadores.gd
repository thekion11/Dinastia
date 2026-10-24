class_name Ojeadores
extends "res://nucleo/ojeadores_p1.gd"
## [Capa 2/2 de `ojeadores.gd`] mejorar_analitica, semana_analitica, hallazgos_vivos, tiene_academia, alternar_academia, mantencion_academias … (+1)

func mejorar_analitica(c: Club) -> String:
	if analitica_nivel >= ANALITICA_MAX:
		return "el departamento ya está al máximo"
	var coste := coste_analitica(c)
	if c.saldo < coste:
		return "ampliarlo cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento_ojeo.emit("Departamento de análisis nivel %d" % (analitica_nivel + 1), -coste)
	analitica_nivel += 1
	noticia_ojeo.emit("Crece el departamento de datos",
		"Contrataste más analistas. El modelo propio del club ya cruza minutos, duelos y kilómetros de %d futbolistas. %s" % [
			analitica_nivel * 4000,
			"Tus ojeadores de la vieja escuela miran las pantallas con desconfianza." if analitica_nivel >= 2 \
				else "De momento conviven bien con los ojeadores."])
	return ""

## El pulso semanal del modelo. Cuanto mejor el departamento, más veces encuentra
## a alguien; y cuanto más encuentra, peor se lleva con el ojeo de siempre.
func semana_analitica(nivel_jefe_ojeadores: int) -> void:
	if analitica_nivel <= 0:
		return
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return
	if not Azar.suerte(0.10 * float(analitica_nivel)):
		return
	var mio := m.mi_club()
	var techo_valor := int(Eco.ref_caja(float(mio.rep)) * 0.25)
	var pool: Array[Jugador] = []
	for c: Club in m.clubes.values():
		if c == mio:
			continue
		for j: Jugador in c.plantilla:
			## Joven, con mucho recorrido por delante y barato: exactamente lo
			## que el ojo no ve y los números sí.
			if j.edad <= 24 and j.pot - j.ovr >= 10 and j.valor < techo_valor:
				pool.append(j)
	if pool.is_empty():
		return
	var j: Jugador = pool[Azar.ent(0, pool.size() - 1)]
	hallazgos.append({"pid": j.id, "nombre": j.nombre, "anio": m.anio, "semana": m.semana})
	while hallazgos.size() > 8:
		hallazgos.pop_front()
	var suyo: Club = m.clubes.get(j.club_id)
	noticia_ojeo.emit("El modelo señala un nombre",
		"El departamento de datos destaca a %s (%d años, %s). No aparece en ningún informe de ojeo, pero sus números por noventa minutos están muy por encima de lo que cuesta. El jefe de ojeadores ya dijo en la reunión que «los números no ven la cara del chico cuando va perdiendo»." % [
			j.nombre, j.edad, suyo.nombre if suyo != null else "?"])

	if nivel_jefe_ojeadores >= 2:
		analitica_tension = clampi(analitica_tension + Azar.ent(6, 14), 0, 100)
		if analitica_tension >= TENSION_CRITICA and not analitica_avisado:
			analitica_avisado = true
			noticia_ojeo.emit("Guerra en la sala de fichajes",
				"El jefe de ojeadores y el jefe de analistas se cruzaron a gritos en el pasillo. Uno dice que el modelo ficha planillas de Excel; el otro, que el ojeo es superstición cara. Antes o después hay que decidir quién manda.")

## Los hallazgos que todavía existen, con el jugador resuelto. Un chico fichado
## por otro club o retirado deja de ser un hallazgo aprovechable.
func hallazgos_vivos() -> Array[Dictionary]:
	var m := _mundo()
	var salida: Array[Dictionary] = []
	if m == null:
		return salida
	for h: Dictionary in hallazgos:
		var j := m.jugador_por_id(String(h.get("pid", "")))
		if j == null:
			continue
		salida.append({"jugador": j, "anio": int(h.get("anio", 0)), "semana": int(h.get("semana", 0))})
	salida.reverse()
	return salida

func tiene_academia(pais: String) -> bool:
	return academias.has(pais)

func alternar_academia(pais: String, c: Club) -> String:
	if tiene_academia(pais):
		academias.erase(pais)
		var vuelta := Eco.escalar(VENTA_ACADEMIA, float(c.rep))
		c.mover_saldo(vuelta)
		movimiento_ojeo.emit("Venta de sede: academia de %s" % pais, vuelta)
		noticia_ojeo.emit("Academia cerrada",
			"La sede de %s se vende. Los proyectos vuelven a casa." % pais)
		return ""
	if academias.size() >= ACADEMIAS_MAX:
		return "no se pueden tener más de %d academias internacionales" % ACADEMIAS_MAX
	var coste := Eco.escalar(COSTE_ACADEMIA, float(c.rep))
	if c.saldo < coste:
		return "construirla cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento_ojeo.emit("Academia internacional en %s" % pais, -coste)
	academias.append(pais)
	noticia_ojeo.emit("Bandera plantada en %s" % pais,
		"Tu academia abre en %s: cada pretemporada llegará una joya local con proyección de verdad. Mantención: %s a la semana." % [
			pais, Cesiones.dinero(Eco.escalar(MANTENCION_ACADEMIA, float(c.rep)))])
	return ""

func mantencion_academias(c: Club) -> int:
	return Eco.escalar(MANTENCION_ACADEMIA, float(c.rep)) * academias.size()

## Las joyas de la pretemporada: una por sede. Nacen con la media de un juvenil
## normal y con MUCHO más techo -de 12 a 30 puntos-, que es a lo que se le paga.
func joyas_de_academia(c: Club) -> Array[Jugador]:
	var m := _mundo()
	var salida: Array[Jugador] = []
	if m == null or c == null:
		return salida
	for p: String in academias:
		if c.plantilla.size() >= Cantera.TOPE_PLANTEL:
			break
		var grupo := String(Azar.uno(["DEF", "MED", "MED", "DEL"]))
		var j := m.crear_jugador(c, grupo, m.cantera.demarcacion_de(grupo),
			Azar.ent(16, 17), c.rep - 20 + Azar.ent(0, 8))
		j.pot = clampi(j.ovr + Azar.ent(12, 30), j.ovr, 97)
		j.pais = p if Azar.suerte(0.85) else c.pais
		## Y con nombre del sitio: una joya que llega de tu sede en Brasil y se
		## llama como todos los demas no se siente venida de ninguna parte.
		if j.pais != c.pais:
			var ext: Variant = Datos.tabla("NOMBRES_EXT")
			var ape: Variant = Datos.tabla("APELLIDOS_EXT")
			if ext is Array and ape is Array and not (ext as Array).is_empty() and not (ape as Array).is_empty():
				j.nombre = Nombres.sin_vetar(func() -> String:
					return "%s %s" % [String(Azar.uno(ext as Array)), String(Azar.uno(ape as Array))])
		j.generar_atributos()
		j.tasar()
		salida.append(j)
		noticia_ojeo.emit("Joya de la academia de %s" % p,
			"%s (%s, %d años) llega desde tu sede en %s con proyección %d." % [
				j.nombre, j.pos_e, j.edad, p, j.pot])
	return salida
