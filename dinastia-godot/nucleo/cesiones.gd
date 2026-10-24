class_name Cesiones
extends "res://nucleo/cesiones_p2.gd"
## [Capa 3/3 de `cesiones.gd`] revisar_bonos, fondos_a_dic, a_dic, fondos_desde_dic, desde_dic, oferta_de_fondo … (+4)

## Los bonos por objetivos. Se revisa cada semana sobre los partidos jugados: el
## día que llega a la marca pactada, el club anterior cobra.
func revisar_bonos(mio: Club) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	if bonos.is_empty() or mio == null:
		return salida
	var m := _mundo()
	for j in mio.plantilla:
		if not bonos.has(j.id):
			continue
		var b: Dictionary = bonos[j.id]
		if j.partidos < int(b["meta"]):
			continue
		var monto := int(b["monto"])
		mio.mover_saldo(-monto)
		var otro: Club = m.clubes.get(String(b["club"])) if m != null else null
		if otro != null:
			otro.mover_saldo(monto)
		movimiento.emit("Bono por objetivos: %s" % j.nombre, -monto)
		noticia.emit("Bono activado: %s" % j.nombre,
			"Llegó a %d partidos y se gatilla el bono de %s para su club anterior." % [
				int(b["meta"]), dinero(monto)])
		salida.append({"jugador": j, "monto": monto})
		bonos.erase(j.id)
	return salida

func fondos_a_dic() -> Dictionary:
	return {"participaciones": participaciones.duplicate(true), "ultima": _ultima_presion}


# ===========================================================================
#  GUARDAR Y CARGAR
# ===========================================================================

## Todo va indexado por id de jugador, nunca por referencia: un guardado tiene
## que sobrevivir a que el cedido cambie de club, se retire o desaparezca, y
## `resolver()` ya sabe qué hacer cuando no encuentra a nadie.
func a_dic() -> Dictionary:
	return {
		"cesiones": cesiones,
		"clausulas": clausulas,
		"porcentajes": porcentajes,
		"plusvalias": plusvalias,
		"cuotas": cuotas,
		"bonos": bonos,
		"opaco": riesgo_opaco,
		"fondos": fondos_a_dic(),
	}

func fondos_desde_dic(d: Dictionary) -> void:
	participaciones = (d.get("participaciones", {}) as Dictionary).duplicate(true)
	_ultima_presion = int(d.get("ultima", 0))

func desde_dic(d: Dictionary) -> void:
	cesiones = d.get("cesiones", {})
	clausulas = d.get("clausulas", {})
	porcentajes = d.get("porcentajes", {})
	riesgo_opaco = int(d.get("opaco", 0))
	bonos = d.get("bonos", {})
	## Las dos listas se copian elemento a elemento porque salen del guardado
	## como Array sin tipar y aquí están declaradas Array[Dictionary]: asignarlas
	## de golpe revienta al cargar, no al guardar, que es cuando peor viene.
	plusvalias.clear()
	for x: Dictionary in d.get("plusvalias", []):
		plusvalias.append(x)
	cuotas.clear()
	for x: Dictionary in d.get("cuotas", []):
		cuotas.append(x)
	fondos_desde_dic(d.get("fondos", {}))

## Lo que un fondo pone hoy por un porcentaje del futuro traspaso. Se paga por
## debajo del valor proporcional -un 62%- porque el fondo asume el riesgo de que
## el chico no llegue: si pagaran lo mismo, vender sería gratis.
func oferta_de_fondo(j: Jugador, clave: String, pct: int) -> int:
	var mult := 1.0
	for f: Array in FONDOS:
		if String(f[0]) == clave:
			mult = float(f[2])
	return int(round(float(j.valor) * float(pct) / 100.0 * 0.62 * mult))

## Vender un porcentaje. Devuelve "" si se hizo, o el motivo.
func vender_participacion(j: Jugador, clave: String, pct: int, c: Club) -> String:
	var m := _mundo()
	if j == null or c == null:
		return "no hay a quién vender"
	if j.club_id != c.id:
		return "solo puedes vender derechos de los tuyos"
	if j.edad > 23:
		return "los fondos solo compran derechos de futbolistas jóvenes"
	var ya := participacion_de(j)
	if ya + pct > PCT_MAX:
		return "no se puede pasar del %d%% de un mismo jugador (ya hay un %d%% vendido)" % [PCT_MAX, ya]
	var monto := oferta_de_fondo(j, clave, pct)
	c.mover_saldo(monto)
	movimiento.emit("Venta de derechos: %s" % j.nombre, monto)
	participaciones[j.id] = {
		"fondo": clave, "pct": ya + pct, "cobrado": monto,
		"anio": m.anio if m != null else 0,
	}
	noticia.emit("Entra dinero de un fondo",
		"Vendiste el %d%% del próximo traspaso de %s por %s. El club respira hoy; el día que lo vendas, ese porcentaje no es tuyo." % [
			pct, j.nombre, Cesiones.dinero(monto)])
	return ""

## Lo que el club se queda de verdad al venderlo. Lo consulta el mercado antes
## de aceptar una oferta: enseñar el precio bruto cuando la mitad se la lleva un
## fondo sería mentir en la pantalla donde más duele.
func neto_de_venta(j: Jugador, bruto: int) -> int:
	var pct := participacion_de(j)
	if pct <= 0:
		return bruto
	return int(round(float(bruto) * (1.0 - float(pct) / 100.0)))

## El fondo aparece a presionar. Devuelve el evento, o vacío.
func presion_de_fondo() -> Dictionary:
	var m := _mundo()
	if m == null or participaciones.is_empty():
		return {}
	if m.semana - _ultima_presion < SEMANAS_PRESION:
		return {}
	var mio := m.mi_club()
	if mio == null:
		return {}
	var candidatos: Array[Jugador] = []
	for j: Jugador in mio.plantilla:
		if participaciones.has(j.id):
			candidatos.append(j)
	if candidatos.is_empty():
		return {}
	_ultima_presion = m.semana
	var j2: Jugador = candidatos[Azar.ent(0, candidatos.size() - 1)]
	var p: Dictionary = participaciones[j2.id]
	var nombre_fondo := "el fondo"
	for f: Array in FONDOS:
		if String(f[0]) == String(p["fondo"]):
			nombre_fondo = String(f[1])
	return {
		"jugador": j2, "fondo": nombre_fondo, "pct": int(p["pct"]),
		"texto": "%s tiene el %d%% de %s y quiere cobrar: pide que lo pongas en el mercado esta temporada." % [
			nombre_fondo, int(p["pct"]), j2.nombre],
	}

## Decirle que no al fondo. No es gratis: bajan la moral del chico -su entorno
## le come la cabeza- y el fondo no vuelve a poner un peso en este club.
func rechazar_presion(j: Jugador) -> String:
	if j == null:
		return "no hay a quién retener"
	j.cambiar_moral(-(Azar.ent(5, 12)), "Cesiones")
	if participaciones.has(j.id):
		(participaciones[j.id] as Dictionary)["enfadado"] = true
	noticia.emit("El fondo se lo toma mal",
		"Te niegas a vender a %s. Su entorno lleva semanas diciéndole que el club le está frenando la carrera." % j.nombre)
	return ""
