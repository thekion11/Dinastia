class_name MercadoDT
extends RefCounted
## EL MERCADO DE ENTRENADORES DE LA IA (26-10-2026, fila 19 de la propuesta de la
## s4: «FC 26 Manager Market»; no había nada: cada club tenía el mismo DT para
## siempre, sacado del hash de su id en `Previa.dt_de`). Ahora:
##  · TERMÓMETRO DE PRESIÓN de cada banquillo, con la misma nota que el escalafón
##    de la prensa (`Prensa.ranking_entrenadores`): puesto real contra el esperado
##    por reputación, y puntos contra los que tocaban. Presión = 100 − nota.
##  · Los clubes de la IA ECHAN a su DT cuando la presión aprieta (desde la
##    jornada 8, y no al que acaba de llegar) y CONTRATAN otro: uno de los
##    parados si hay, o uno nuevo. El nuevo trae el «efecto del cambio» (moral +6).
##  · Noticia de cada cambio y un historial; tu club no entra (a ti te juzga tu
##    directiva, que ya existe).
## Vive en el propio Mundo como meta («mercado_dt»), sin tocar sus capas
## (`MercadoDT.de(mundo)`); el DT nuevo se apunta en el club (meta «dt_actual»),
## que es lo que lee `Previa.dt_de`. Se guarda con la partida (`a_dic/desde_dic`).

signal noticia(titulo: String, cuerpo: String)

## Desde qué jornada se juzga (antes, una mala racha es ruido).
const JORNADA_MINIMA := 8
## A partir de qué presión el puesto peligra.
const PRESION_PELIGRO := 78
## Semanas de gracia del recién llegado.
const GRACIA := 12
const MAX_HISTORIAL := 40
const MAX_PARADOS := 12
const EFECTO_CAMBIO := 6

## club_id -> {"nombre", "estilo", "descripcion", "anio", "semana"} (solo los que cambiaron).
var cambios: Dictionary = {}
## Los DT despedidos, que otros clubes pueden fichar.
var parados: Array = []
var historial: Array = []

static func de(m: Mundo) -> MercadoDT:
	if m == null:
		return null
	if not m.has_meta("mercado_dt"):
		m.set_meta("mercado_dt", MercadoDT.new())
	return m.get_meta("mercado_dt")

## La presión del banquillo de un club (0-100), o -1 si aún no se puede juzgar.
static func presion(m: Mundo, c: Club) -> int:
	if m == null or c == null:
		return -1
	var l := m.liga_de(c)
	if l == null:
		return -1
	var por_rep := l.clubes.duplicate()
	por_rep.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	var esperado := por_rep.find(c) + 1
	var puesto := 0
	for f: Dictionary in l.tabla():
		puesto += 1
		if f["club"] == c:
			if int(f["pj"]) < JORNADA_MINIMA:
				return -1
			var nota := clampi(60 + (esperado - puesto) * 7 + int(round(float(int(f["pts"])) - float(int(f["pj"])) * 1.3) * 1.6), 10, 99)
			return clampi(100 - nota, 0, 100)
	return -1

## El termómetro de tu país: {club, dt, presion}, el más caliente primero.
func termometro(m: Mundo) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	if m == null or m.mi_club() == null:
		return salida
	for l: Liga in m.ligas:
		if l.pais != m.mi_club().pais:
			continue
		for c: Club in l.clubes:
			var p := presion(m, c)
			if p >= 0:
				salida.append({"club": c, "dt": Previa.dt_de(c), "presion": p, "mio": c == m.mi_club()})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["presion"]) > int(b["presion"]))
	return salida

## Una vez por semana: los clubes de la IA con el banquillo ardiendo pueden echar
## a su DT. Devuelve los clubes que cambiaron.
func semana(m: Mundo) -> Array[Club]:
	var cambiaron: Array[Club] = []
	if m == null:
		return cambiaron
	var ahora := m.anio * 60 + m.semana
	for l: Liga in m.ligas:
		for c: Club in l.clubes:
			if c.id == m.mi_club_id:
				continue
			var p := presion(m, c)
			if p < PRESION_PELIGRO:
				continue
			var c_dt: Dictionary = cambios.get(c.id, {})
			if not c_dt.is_empty() and ahora - (int(c_dt["anio"]) * 60 + int(c_dt["semana"])) < GRACIA:
				continue
			## Cuanto más aprieta, más probable: de un 2 % a un ~10 % por semana. Con
			## esto salen 3-6 despidos por liga y temporada, como en una liga real.
			if not Azar.suerte(0.02 + float(p - PRESION_PELIGRO) / 280.0):
				continue
			cambiar_dt(m, c)
			cambiaron.append(c)
	return cambiaron

## Echa al DT de un club y trae otro (un parado, si hay, o uno nuevo).
func cambiar_dt(m: Mundo, c: Club) -> Dictionary:
	var sale := Previa.dt_de(c)
	var entra: Dictionary = {}
	if not parados.is_empty() and Azar.suerte(0.5):
		entra = (parados.pop_at(Azar.ent(0, parados.size() - 1)) as Dictionary).duplicate()
	else:
		entra = Previa.dt_con_semilla(c, "%s|%d|%d" % [c.id, m.anio, m.semana])
	entra["anio"] = m.anio
	entra["semana"] = m.semana
	cambios[c.id] = entra
	c.set_meta("dt_actual", _sin_fecha(entra))
	parados.append(_sin_fecha(sale))
	while parados.size() > MAX_PARADOS:
		parados.pop_front()
	historial.append({"anio": m.anio, "semana": m.semana, "club": c.nombre, "sale": String(sale["nombre"]), "entra": String(entra["nombre"])})
	while historial.size() > MAX_HISTORIAL:
		historial.pop_front()
	for j: Jugador in c.plantilla:
		j.moral = clampi(j.moral + EFECTO_CAMBIO, 0, 100)
	noticia.emit("Cambio de entrenador en %s" % c.nombre,
		"%s deja el banquillo tras una racha que la directiva no aguantó. Llega %s (%s)." % [String(sale["nombre"]), String(entra["nombre"]), String(entra.get("estilo", ""))])
	return entra

static func _sin_fecha(d: Dictionary) -> Dictionary:
	var r := d.duplicate()
	r.erase("anio")
	r.erase("semana")
	return r

func a_dic() -> Dictionary:
	return {"cambios": cambios.duplicate(true), "parados": parados.duplicate(true), "historial": historial.duplicate(true)}

## Al cargar, cada club cambiado recupera su DT (la meta que lee `Previa.dt_de`).
func desde_dic(m: Mundo, d: Dictionary) -> void:
	cambios = (d.get("cambios", {}) as Dictionary).duplicate(true)
	parados = (d.get("parados", []) as Array).duplicate(true)
	historial = (d.get("historial", []) as Array).duplicate(true)
	if m == null:
		return
	for id: String in cambios:
		var c: Club = m.clubes.get(id)
		if c != null:
			c.set_meta("dt_actual", _sin_fecha(cambios[id]))
