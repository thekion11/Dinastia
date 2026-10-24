extends "res://nucleo/prensa_p2.gd"
## [Capa 3/8 de `prensa.gd`] _fatigar_por_viaje, _mover_funa, _pagar, _ceder

## El precio de un viaje largo: los que vinieron de fuera llegan sin piernas.
func _fatigar_por_viaje(mio: Club) -> void:
	var m := _mundo()
	for j: Jugador in mio.plantilla:
		if j.pais == mio.pais:
			continue
		var golpe := Azar.ent(4, 9)
		## Las instalaciones y el preparador fisico amortiguan el viaje: es para
		## lo que sirven, y sin esto seria un castigo que no se puede prevenir.
		## "fisico" y no "pf": `Staff.PUESTOS` llama así al preparador físico. Con
		## "pf" -la clave del HTML, `G.staff.pf`- el nivel salía siempre 0 y el
		## preparador no aliviaba ningún viaje, sin un solo error.
		if m != null and m.staff != null:
			golpe -= m.staff.nivel("fisico")
		j.fisico = clampi(j.fisico - maxi(1, golpe), 10, 100)

## El HTML sumaba funa sin acotar por arriba (solo la restaba con clamp), así que
## podía pasar de 100 y quedarse ahí para siempre. Aquí se acota por los dos
## lados: es una escala 0-100 y todo lo que la lea espera esa escala.
## EL MEDIATICO APAGA EL FUEGO AL DOBLE DE VELOCIDAD.
##
## `Entrenamiento.factor_apagar_funa()` devolvia un 2,0 que no leia nadie: se
## podia gastar un punto del arbol en «Mediatico» y la funa bajaba exactamente
## igual de despacio. Solo se aplica cuando la funa BAJA -apagar un incendio es
## lo que la habilidad promete-; encenderlo cuesta lo mismo para todos.
func _mover_funa(d: int) -> void:
	if d < 0:
		var m := _mundo()
		if m != null and m.entrenamiento != null:
			d = int(round(float(d) * m.entrenamiento.factor_apagar_funa()))
	funa = clampi(funa + d, 0, 100)
	humor_hinchada.emit(animo, funa)

func _pagar(c: Club, monto: int, concepto: String) -> void:
	if monto == 0:
		return
	c.mover_saldo(monto)
	movimiento.emit(concepto, monto)

## La cesión de un canterano. Las tres condiciones son las del HTML: solo hasta
## los 21, solo si no está ya cedido, y solo si te queda plantel para jugar
## (más de 18). El destino es un club que no sea mejor que el tuyo por más de
## cuatro puntos de reputación: a un chico se le presta para que juegue, no para
## que se siente en un banco mejor.
func _ceder(m: Mundo, mio: Club, j: Jugador) -> bool:
	if j.edad > 21 or cesiones.has(j.id) or mio.plantilla.size() <= 18:
		return false
	var candidatos: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.id != mio.id and c.rep <= mio.rep + 4:
			candidatos.append(c)
	if candidatos.is_empty():
		return false
	var destino: Club = Azar.uno(candidatos)
	cesiones[j.id] = {"de": mio.id, "vuelve": m.anio + 1}
	mio.soltar(j)
	destino.fichar(j)
	return true
