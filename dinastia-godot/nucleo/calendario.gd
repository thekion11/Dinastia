class_name Calendario
extends "res://nucleo/calendario_p1.gd"
## (Parte 2 de 2 de `calendario.gd`.)

## Una vez por semana: noticias, moral y la explicación del mentor. Devuelve las
## fechas de la semana (para las pruebas).
func semana(c: Club, anio: int, sem: int) -> Array:
	if c == null or ultima_semana == anio * 60 + sem:
		return []
	ultima_semana = anio * 60 + sem
	var fechas := de_la_semana(c.pais, anio, sem)
	var hubo_fiesta := false
	var hubo_memoria := false
	for f: Dictionary in fechas:
		var nombre := String(f["nombre"])
		var tipo := String(f["tipo"])
		var cuando := "%d/%d" % [int(f["dia"]), int(f["mes"])]
		match tipo:
			"memoria":
				hubo_memoria = true
				noticia.emit("%s %s" % [icono(tipo), nombre],
					"(%s) Los partidos de esta semana empiezan con un minuto de silencio y los jugadores llevan brazalete negro." % cuando)
			"fiesta":
				hubo_fiesta = true
				noticia.emit("%s %s" % [icono(tipo), nombre], "(%s) Semana de fiesta en el país: se esperan estadios llenos." % cuando)
			"trabajo":
				noticia.emit("%s %s" % [icono(tipo), nombre], "(%s) El personal del club libra. El plantel dedica el partido a los trabajadores del club." % cuando)
			_:
				noticia.emit("%s %s" % [icono(tipo), nombre], "(%s) %s" % [cuando, String(f["texto"])])
		if not explicadas.has(nombre):
			explicadas[nombre] = true
			mentor.emit(nombre, String(f["texto"]))
	## La memoria manda: con duelo no hay fiesta que valga.
	if hubo_fiesta and not hubo_memoria:
		for j: Jugador in c.plantilla:
			j.cambiar_moral(1, "Calendario")
	var t := torneo_en_curso(anio, sem)
	if not t.is_empty():
		var clave := "%s %d" % [String(t["nombre"]), anio]
		if not explicadas.has(clave):
			explicadas[clave] = true
			var sedes: Array = t["sedes"]
			var en_casa := sedes.has(c.pais)
			noticia.emit("🌍 %s %d" % [String(t["nombre"]), anio],
				("¡El torneo se juega en tu país! Las ciudades sede se llenan de visitantes." if en_casa else "Empieza el torneo. Medio mundo está pendiente."))
			mentor.emit(String(t["nombre"]), String(t["texto"]))
	return fechas

## Las próximas fechas desde esta semana, para el calendario.
static func proximas(pais: String, anio: int, semana: int, cuantas: int = 6) -> Array:
	var hoy := unix_de(anio, semana, 0)
	var r: Array = []
	var todas: Array = []
	for a0 in [anio, anio + 1]:
		for x: Dictionary in del_anio(pais, a0):
			var y := x.duplicate()
			y["anio"] = a0
			todas.append(y)
	for f: Dictionary in todas:
		var a := int(f["anio"])
		var u := _unix(a, int(f["mes"]), int(f["dia"]))
		if u >= hoy:
			var g := f.duplicate()
			g["anio"] = a
			g["faltan"] = int((u - hoy) / 86400.0)
			r.append(g)
		if r.size() >= cuantas:
			break
	return r

func a_dic() -> Dictionary:
	return {"exp": explicadas.keys(), "ult": ultima_semana}

func desde_dic(d: Dictionary) -> void:
	explicadas = {}
	for k: Variant in d.get("exp", []):
		explicadas[String(k)] = true
	ultima_semana = int(d.get("ult", -1))
