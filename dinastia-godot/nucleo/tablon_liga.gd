class_name TablonLiga
extends RefCounted
## EL TABLÓN DE NECESIDADES DE LA LIGA (26-10-2026, fila 20 de la propuesta de la
## s4: «FM26 Requirements y Pitch Opportunities»). Cada club de la IA de tu país
## publica qué le falta -la línea más floja o más corta de su plantilla-, con la
## media mínima que acepta, la edad máxima y lo que puede pagar. Y tú puedes
## OFRECERLE a uno de los tuyos: si encaja, el club manda una oferta de verdad a
## tu bandeja (`Mercado.ofertas_recibidas`, la misma que usan las ofertas de la IA),
## que aceptas o rechazas como cualquier otra.
## Solo lee el mundo y usa las mismas reglas del mercado de la IA: no compra un
## jugador que le haga pasar del máximo de una línea (`Mercado.MAXIMO_LINEA`) ni
## gasta más de lo que tiene.
##   TablonLiga.necesidades(mundo) -> Array[Dictionary]
##   TablonLiga.ofrecer(mundo, jugador, club) -> {"ok": bool, "motivo": String, "monto": int}

const LINEAS := ["POR", "DEF", "MED", "DEL"]
## Titulares por línea (4-3-3): la media de la línea es la de sus mejores N.
const TITULARES := {"POR": 1, "DEF": 4, "MED": 3, "DEL": 3}
## Parte de la caja que un club dedica a un fichaje que necesita.
const PARTE_CAJA := 0.6
## Cuánto por debajo de su media acepta a alguien para la línea que le falta.
const HOLGURA_MEDIA := 3
## Lo que paga sobre el valor del jugador (lo necesita, pero regatea).
const PAGO_MIN := 0.9
const PAGO_MAX := 1.15

## Media de los N mejores de una línea (0 si no hay nadie).
static func media_linea(c: Club, g: String) -> float:
	var ovrs: Array[int] = []
	for j: Jugador in c.plantilla:
		if j.pos == g:
			ovrs.append(j.ovr)
	if ovrs.is_empty():
		return 0.0
	ovrs.sort()
	ovrs.reverse()
	var n := mini(int(TITULARES[g]), ovrs.size())
	var s := 0
	for i in n:
		s += ovrs[i]
	return float(s) / float(n)

## Lo que necesita un club: la línea con menos gente respecto al mínimo del
## mercado y, si ninguna está corta, la que más baja su media. Vacío si no se
## puede permitir a nadie que le mejore.
static func necesidad(c: Club) -> Dictionary:
	if c == null or c.plantilla.is_empty():
		return {}
	var media := c.media()
	var peor := ""
	var motivo := ""
	var hueco := -999.0
	for g: String in LINEAS:
		var n := Mercado._cuenta_linea(c, g)
		var corto := float(int(Mercado.MINIMO_LINEA[g]) + 1 - n)
		if corto > 0.0 and corto * 10.0 > hueco:
			hueco = corto * 10.0
			peor = g
			motivo = "corto"
	if peor == "":
		for g2: String in LINEAS:
			var d := media - media_linea(c, g2)
			if d > hueco:
				hueco = d
				peor = g2
				motivo = "flojo"
	if peor == "" or Mercado._cuenta_linea(c, peor) >= int(Mercado.MAXIMO_LINEA[peor]):
		return {}
	var presupuesto := maxi(0, int(float(c.saldo) * PARTE_CAJA))
	return {
		"club": c, "grupo": peor, "motivo": motivo,
		"media_min": int(round(maxf(media_linea(c, peor), media - float(HOLGURA_MEDIA)))),
		"edad_max": 29 if c.rep >= 80 else 33,
		"presupuesto": presupuesto,
	}

## El tablón de la liga: las necesidades de los clubes de la IA de tu país, las de
## más dinero primero.
static func necesidades(m: Mundo, cuantos: int = 30) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	if m == null or m.mi_club() == null:
		return salida
	var mio := m.mi_club()
	for l: Liga in m.ligas:
		if l.pais != mio.pais:
			continue
		for c: Club in l.clubes:
			if c == mio:
				continue
			var n := necesidad(c)
			if not n.is_empty() and int(n["presupuesto"]) > 0:
				salida.append(n)
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["presupuesto"]) > int(b["presupuesto"]))
	return salida.slice(0, cuantos)

## Por qué un club no querría a este jugador ("" si encaja).
static func motivo_rechazo(n: Dictionary, j: Jugador) -> String:
	if n.is_empty():
		return "no busca a nadie"
	if j.pos != String(n["grupo"]):
		return "busca otra línea"
	if j.ovr < int(n["media_min"]):
		return "le falta nivel"
	if j.edad > int(n["edad_max"]):
		return "lo ve mayor"
	if int(round(float(j.valor) * PAGO_MIN)) > int(n["presupuesto"]):
		return "no le llega el dinero"
	return ""

## Le ofreces un jugador tuyo a un club. Si encaja, manda una oferta real a tu
## bandeja; si ya tenía una oferta pendiente por él, no repite.
static func ofrecer(m: Mundo, j: Jugador, c: Club) -> Dictionary:
	if m == null or j == null or c == null or m.mercado == null or j.club_id != m.mi_club_id:
		return {"ok": false, "motivo": "no se puede", "monto": 0}
	for o: Dictionary in m.mercado.ofertas_recibidas:
		if o["jugador"] == j and o["club"] == c:
			return {"ok": false, "motivo": "ya hay una oferta suya", "monto": 0}
	var n := necesidad(c)
	var mot := motivo_rechazo(n, j)
	if mot != "":
		return {"ok": false, "motivo": mot, "monto": 0}
	## Paga más cuanto más le sobra sobre lo que pedía, sin pasar de su presupuesto.
	var exceso := clampf(float(j.ovr - int(n["media_min"])) / 10.0, 0.0, 1.0)
	var monto := mini(int(n["presupuesto"]), int(round(float(j.valor) * lerpf(PAGO_MIN, PAGO_MAX, exceso))))
	m.mercado.ofertas_recibidas.append({"jugador": j, "club": c, "monto": monto,
		"semana": m.semana, "abs": m.anio * 60 + m.semana, "clausula": false, "tablon": true})
	m.mercado.oferta_recibida.emit(j, c, monto)
	return {"ok": true, "motivo": "", "monto": monto}
