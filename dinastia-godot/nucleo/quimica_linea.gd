class_name QuimicaLinea
extends RefCounted
## LA QUÍMICA ENTRE COMPAÑEROS DE LÍNEA (10-11; idea de la «compenetración» del PES: se ve en la alineación). Solo LECTURA para la interfaz: NO toca el
## motor del partido (eso es del dueño y de la sesión del partido; si algún día suma, irá con bandera). Por pareja, 0-100, desde 50:
## +18 si son del mismo clan del vestuario, +10 si son del mismo país (idioma y costumbres), +6 por temporada que llevan juntos en el club (máx. +18),
## y la moral media empuja ±10. La de una línea (DEF, MED, DEL) es la media de sus parejas.
const BASE := 50

## Temporadas que `j` lleva en el club `nombre_club` (las registradas en su historial, más la actual).
static func temporadas_en(j: Jugador, nombre_club: String) -> int:
	var n := 1
	for h: Dictionary in j.historial:
		if String(h.get("club", "")) == nombre_club:
			n += 1
	return n

static func par(m: Mundo, a: Jugador, b: Jugador) -> int:
	var v := float(BASE)
	if m != null and m.vestuario != null:
		var ca: Dictionary = m.vestuario.clan_de(a)
		if not ca.is_empty() and ca == m.vestuario.clan_de(b):
			v += 18.0
	if a.pais == b.pais:
		v += 10.0
	var club_nombre := ""
	if m != null and m.clubes.has(a.club_id):
		club_nombre = (m.clubes[a.club_id] as Club).nombre
	if club_nombre != "" and a.club_id == b.club_id:
		v += 6.0 * float(mini(mini(temporadas_en(a, club_nombre), temporadas_en(b, club_nombre)) - 1, 3))
	v += (float(a.moral + b.moral) / 2.0 - 60.0) * 0.25
	return clampi(int(round(v)), 0, 100)

## {grupo: química media} de las líneas del once (DEF, MED, DEL; el portero no cuenta).
static func lineas(m: Mundo, once: Array) -> Dictionary:
	var por_grupo := {}
	for j: Jugador in once:
		var g := PesosPuesto.grupo(j.pos_e)
		if g in ["DEF", "MED", "DEL"]:
			if not por_grupo.has(g):
				por_grupo[g] = []
			(por_grupo[g] as Array).append(j)
	var out := {}
	for g: String in por_grupo:
		var js: Array = por_grupo[g]
		var suma := 0
		var n := 0
		for i in js.size():
			for k in range(i + 1, js.size()):
				suma += par(m, js[i], js[k])
				n += 1
		out[g] = int(round(float(suma) / n)) if n > 0 else BASE
	return out

static func color(v: int) -> Color:
	if v >= 66:
		return Color(0.35, 0.85, 0.45)
	if v >= 45:
		return Color(0.95, 0.8, 0.3)
	return Color(0.9, 0.35, 0.3)
