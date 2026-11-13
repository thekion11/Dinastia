class_name LogrosSimulado
extends RefCounted
## LA MEMORIA DEL CLUB CUANDO NO DIRIGES (13-11-2026, decisión del dueño: «la
## Vitrina sí se llena simulando»). Un partido simulado no trae su crónica, así
## que los partidos jugados y los goles de cada futbolista se sacan de lo que
## subieron sus contadores desde la última vez (`rec["visto"]`, que se guarda
## con la partida). Tras un partido DIRIGIDO solo se pone al día la foto, porque
## ese ya lo anotó `Logros._anotar_participaciones` con su crónica.

static func _visto(lg: Variant) -> Dictionary:
	if not lg.rec.get("visto") is Dictionary:
		lg.rec["visto"] = {}
	return lg.rec["visto"]

## Guarda los contadores de hoy sin sumar nada.
static func poner_al_dia(lg: Variant) -> void:
	var mio: Club = lg.mundo.mi_club() if lg.mundo != null else null
	if mio == null:
		return
	var v := _visto(lg)
	v.clear()
	for j: Jugador in mio.plantilla:
		v[j.id] = [j.partidos, j.goles]

## Suma a los históricos lo que cada uno jugó y marcó desde la última foto.
static func anotar_plantel(lg: Variant) -> void:
	var mio: Club = lg.mundo.mi_club() if lg.mundo != null else null
	if mio == null:
		return
	var v := _visto(lg)
	var primera := v.is_empty()
	var pj: Dictionary = lg.rec["pj"]
	var goles: Dictionary = lg.rec["goles"]
	for j: Jugador in mio.plantilla:
		var antes: Array = v.get(j.id, [0 if primera else j.partidos, 0 if primera else j.goles]) if v.get(j.id) is Array or not v.has(j.id) else [j.partidos, j.goles]
		## Contadores que bajan = temporada nueva: se cuenta desde cero.
		var d_pj := j.partidos - int(antes[0]) if j.partidos >= int(antes[0]) else j.partidos
		var d_g := j.goles - int(antes[1]) if j.goles >= int(antes[1]) else j.goles
		var nombre := Nombres.visible(j.nombre)
		if d_pj > 0:
			if not pj.has(j.id):
				pj[j.id] = {"nombre": nombre, "n": 0}
			pj[j.id]["n"] = int(pj[j.id]["n"]) + d_pj
		if d_g > 0 and nombre != "":
			goles[nombre] = int(goles.get(nombre, 0)) + d_g
	poner_al_dia(lg)
