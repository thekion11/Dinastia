class_name CarreraJugador
extends "res://nucleo/carrera_jugador_p1.gd"
## (Parte 2 de 2 de `carrera_jugador.gd`.)

## Lo que pasa cada semana fuera del campo. Devuelve los eventos nuevos.
func semana(m: Mundo) -> Array:
	var nuevos: Array = []
	energia = mini(ENERGIA_MAX, energia + 12)
	relacion_dt = clampi(relacion_dt + (1 if nota_media() >= 6.8 else 0) - (1 if energia < 25 else 0), 0, 100)
	seguidores += int(float(fama) * 3.0) + _rng.randi_range(0, 20)
	var j := jugador(m)
	if j == null:
		return nuevos
	revisar_convocatoria(m)
	var ahora := m.anio * 60 + m.semana
	var pool := _eventos_posibles(m, j).filter(func(e: Dictionary) -> bool:
		return ahora - int(ultima_vez.get(String(e["id"]), -99)) >= 5)
	if not pool.is_empty() and _rng.randf() < 0.45:
		var ev: Dictionary = pool[_rng.randi() % pool.size()]
		eventos.append(ev)
		nuevos.append(ev)
		ultima_vez[String(ev["id"])] = ahora
		if bool(ev.get("unico", false)):
			hitos[String(ev["id"])] = true
	## Ofertas de otros clubes si destacas.
	if fama >= 30 and _rng.randf() < 0.08 + float(fama) / 600.0:
		var destino := _club_interesado(m, j)
		if destino != null:
			ofertas.append({"club_id": destino.id, "sueldo": int(float(j.sueldo) * 1.6), "semanas": 3})
	for o: Dictionary in ofertas:
		o["semanas"] = int(o["semanas"]) - 1
	ofertas = ofertas.filter(func(o: Dictionary) -> bool: return int(o["semanas"]) > 0)
	return nuevos

## Cesión: a un club de su país con 8-20 puntos menos de reputación.
func _ceder(m: Mundo) -> void:
	var j := jugador(m)
	var origen := club(m)
	if j == null or origen == null:
		return
	var candidatos: Array = []
	for c: Club in m.clubes.values():
		if c != origen and c.pais == origen.pais and c.rep <= origen.rep - 8 and c.rep >= origen.rep - 20:
			candidatos.append(c)
	if candidatos.is_empty():
		return
	var destino: Club = candidatos[_rng.randi() % candidatos.size()]
	origen.soltar(j)
	if not clubes_pasados.has(origen.nombre):
		clubes_pasados.append(origen.nombre)
	destino.fichar(j)
	j.dorsal = _dorsal_libre(destino)
	relacion_dt = 62
	historial.append({"anio": m.anio, "semana": m.semana, "titulo": "Cesión", "eleccion": "Cedido a %s" % destino.nombre})

func _club_extranjero(m: Mundo, j: Jugador) -> Club:
	var mio := club(m)
	var mejores: Array = []
	for c: Club in m.clubes.values():
		if mio != null and c.pais != mio.pais and c.rep >= mio.rep:
			mejores.append(c)
	return mejores[_rng.randi() % mejores.size()] if not mejores.is_empty() else null

## Aplica la opción elegida de un evento pendiente.
func resolver(m: Mundo, indice: int, opcion: int) -> String:
	if indice < 0 or indice >= eventos.size():
		return ""
	var ev: Dictionary = eventos[indice]
	var ops: Array = ev["opciones"]
	if opcion < 0 or opcion >= ops.size():
		return ""
	var o: Dictionary = ops[opcion]
	var ef: Dictionary = o["efectos"]
	var j := jugador(m)
	fama = clampi(fama + int(ef.get("fama", 0)), 0, 100)
	relacion_dt = clampi(relacion_dt + int(ef.get("relacion", 0)), 0, 100)
	energia = clampi(energia + int(ef.get("energia", 0)), 0, ENERGIA_MAX)
	seguidores = maxi(0, seguidores + int(ef.get("seguidores", 0)))
	if j != null:
		j.cambiar_moral(int(ef.get("moral", 0)), "Carrera")
		for k: String in ef:
			if k.begins_with("attr_") and j.atributos.has(k.substr(5)):
				j.atributos[k.substr(5)] = mini(99, int(j.atributos[k.substr(5)]) + int(ef[k]))
		if ef.has("contrato"):
			j.anios_contrato = int(ef["contrato"])
			j.sueldo = int(float(j.sueldo) * float(ef.get("sueldo", 1.15)))
		if bool(ef.get("lesion_riesgo", false)) and _rng.randf() < 0.4:
			j.lesionar(2)
	if bool(ef.get("lanzador_penales", false)):
		lanzador["penales"] = true
	if bool(ef.get("lanzador_faltas", false)):
		lanzador["faltas"] = true
	if bool(ef.get("convocado", false)):
		convocatorias += 1
	if String(ef.get("agente", "")) != "":
		agente = "Agente propio"
	if bool(ef.get("capitan", false)):
		capitan = true
	if bool(ef.get("licencia", false)):
		licencia = true
	if bool(ef.get("retiro", false)):
		retiro_anunciado = true
	if j != null and int(ef.get("lesion_menos", 0)) > 0:
		j.lesion = maxi(0, j.lesion - int(ef["lesion_menos"]))
	if bool(ef.get("cesion", false)):
		_ceder(m)
	if bool(ef.get("oferta_fuera", false)) and j != null:
		var fuera := _club_extranjero(m, j)
		if fuera != null:
			ofertas.append({"club_id": fuera.id, "sueldo": int(float(j.sueldo) * 2.2), "semanas": 3})
	historial.append({"anio": m.anio, "semana": m.semana, "titulo": String(ev["titulo"]), "eleccion": String(o["texto"])})
	eventos.remove_at(indice)
	return String(o["texto"])

## Acepta una oferta: te vas a ese club.
func aceptar_oferta(m: Mundo, i: int) -> bool:
	if i < 0 or i >= ofertas.size():
		return false
	var o: Dictionary = ofertas[i]
	var destino: Club = m.clubes.get(String(o["club_id"]))
	var j := jugador(m)
	if destino == null or j == null:
		return false
	var origen := club(m)
	if origen != null:
		origen.soltar(j)
		if not clubes_pasados.has(origen.nombre):
			clubes_pasados.append(origen.nombre)
	destino.fichar(j)
	j.sueldo = int(o["sueldo"])
	j.anios_contrato = 3
	j.dorsal = _dorsal_libre(destino)
	relacion_dt = 50
	fama = mini(100, fama + 5)
	ofertas.clear()
	historial.append({"anio": m.anio, "semana": m.semana, "titulo": "Traspaso", "eleccion": "Fichas por %s" % destino.nombre})
	return true

## Lo que dejó un partido tuyo (jugado en el motor o simulado).
func tras_partido(m: Mundo, d: Dictionary) -> void:
	var j := jugador(m)
	var min_jugados := int(d.get("minutos", 90))
	if min_jugados <= 0:
		return
	stats_temp["pj"] = int(stats_temp["pj"]) + 1
	pj_carrera += 1
	goles_carrera += int(d.get("goles", 0))
	if bool(d.get("titular", true)):
		stats_temp["titular"] = int(stats_temp["titular"]) + 1
	stats_temp["goles"] = int(stats_temp["goles"]) + int(d.get("goles", 0))
	stats_temp["asist"] = int(stats_temp["asist"]) + int(d.get("asist", 0))
	var nota := float(d.get("nota", 6.0))
	(stats_temp["notas"] as Array).append(nota)
	fama = clampi(fama + int(d.get("goles", 0)) * 2 + int(d.get("asist", 0)) + (1 if nota >= 7.5 else 0), 0, 100)
	relacion_dt = clampi(relacion_dt + (3 if nota >= 7.5 else (1 if nota >= 6.5 else -2)), 0, 100)
	energia = maxi(0, energia - int(float(min_jugados) / 3.0))
	seguidores += int(d.get("goles", 0)) * 120
	if j != null:
		for _g in int(d.get("goles", 0)):
			j.anotar()
		j.asistencias += int(d.get("asist", 0))
		j.partidos += 1
		j.anotar_nota(nota)

## Cierra la temporada: la guarda en tu historial y cumples un año.
func fin_de_temporada(m: Mundo) -> void:
	var c := club(m)
	temporadas.append({"anio": m.anio, "club": c.nombre if c != null else "", "pj": int(stats_temp["pj"]),
		"goles": int(stats_temp["goles"]), "asist": int(stats_temp["asist"]), "nota": snappedf(nota_media(), 0.01)})
	stats_temp = {"pj": 0, "titular": 0, "goles": 0, "asist": 0, "notas": []}

## La selección de tu país para el partido (18, por líneas, tú dentro) y la
## rival. Clubes de paso, fuera del mundo: no tocan ninguna liga.
func equipos_seleccion(m: Mundo) -> Array:
	var j := jugador(m)
	if convocatoria.is_empty() or j == null:
		return []
	var mia := Club.new()
	mia.id = "sel_" + String(convocatoria["pais"])
	mia.nombre = String(convocatoria["nombre"])
	mia.pais = String(convocatoria["pais"])
	mia.rep = 80
	mia.color1 = "#c8102e"
	mia.color2 = "#ffffff"
	var todos: Array = []
	for c: Club in m.clubes.values():
		for o: Jugador in c.plantilla:
			if o.pais == j.pais and o.disponible():
				todos.append(o)
	todos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var cupos := CUPOS_SEL.duplicate()
	mia.plantilla.append(j)
	cupos[j.pos] = int(cupos[j.pos]) - 1
	for o: Jugador in todos:
		if o != j and int(cupos.get(o.pos, 0)) > 0:
			mia.plantilla.append(o)
			cupos[o.pos] = int(cupos[o.pos]) - 1
	var rival := Club.new()
	rival.id = "sel_rival"
	rival.nombre = String(convocatoria["rival"])
	## El país de la selección rival por su nombre (antes "XXX": sin bandera ni
	## jugadores de ese país): la tabla del mundo o, si no está, `CODIGO_SELECCION`.
	rival.pais = String(CODIGO_SELECCION.get(rival.nombre, ""))
	var tabla_p := Selecciones._tabla_paises()
	for cod: Variant in tabla_p:
		if Nombres.limpiar(String(tabla_p[cod])) == Nombres.limpiar(rival.nombre):
			rival.pais = String(cod)
			break
	rival.rep = clampi(m.selecciones.fuerza(rival.nombre), 62, 88) if m.selecciones != null else 75
	rival.color1 = "#1d3c8f"
	rival.color2 = "#f2c230"
	## Si en el mundo no hay jugadores de ese país, se generan con su fuerza.
	for g: String in CUPOS_SEL:
		var dem := {"POR": "POR", "DEF": "DFC", "MED": "MC", "DEL": "DC"}[g] as String
		for k in int(CUPOS_SEL[g]):
			var nuevo := m.crear_jugador(rival, g, dem, _rng.randi_range(22, 31), rival.rep + _rng.randi_range(-6, 3))
			rival.plantilla.append(nuevo)
	## Que la mitad de tu plantel no quede sin cupo: si faltan, se completa.
	for g: String in cupos:
		var dem2 := {"POR": "POR", "DEF": "DFC", "MED": "MC", "DEL": "DC"}[g] as String
		for k in int(cupos[g]):
			mia.plantilla.append(m.crear_jugador(mia, g, dem2, _rng.randi_range(22, 31), 70))
	return [mia, rival]

## Lo que deja un partido con la selección.
func tras_seleccion(d: Dictionary) -> void:
	caps += 1
	goles_sel += int(d.get("goles", 0))
	fama = clampi(fama + 4 + int(d.get("goles", 0)) * 4, 0, 100)
	seguidores += 600 + int(d.get("goles", 0)) * 900
	energia = maxi(0, energia - 12)
	convocatoria = {}

# ---------------------------------------------------------------- el retiro

## ¿Toca colgar las botas? Si lo anunciaste o el cuerpo ya no da (38 años).
func toca_retirarse(m: Mundo) -> bool:
	var j := jugador(m)
	return j != null and not retirado and (retiro_anunciado or j.edad >= 38)

## Clubes que le ofrecen el banquillo a un exjugador: de su país, con la
## reputación que da su carrera (más fama, mejores clubes). Hasta tres.
func ofertas_de_banquillo(m: Mundo) -> Array:
	var j := jugador(m)
	var pais := j.pais if j != null else "CHI"
	var techo := 55 + fama / 3
	var lista: Array = []
	for c: Club in m.clubes.values():
		if c.pais == pais and c.rep <= techo and c.rep >= techo - 18:
			lista.append(c)
	lista.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	return lista.slice(0, 3)

## UNA VIDA ENTERA EN UNA PARTIDA (MEGAPLAN fases 3 y 7): te retiras y diriges
## en el mismo mundo. Tu carrera de jugador queda como tu currículum.
func pasar_a_entrenador(m: Mundo, club_dt: Club) -> bool:
	var j := jugador(m)
	if j == null or club_dt == null:
		return false
	retirado = true
	var actual := club(m)
	if actual != null:
		actual.soltar(j)
	m.tomar_el_mando(club_dt.id)
	if m.roles != null:
		m.roles.arrancar("dt", j.nombre)
	## LA DINASTÍA (fase 5): tu jugador queda en el libro de leyendas como
	## «propio»: en unos años su hijo llega a la cantera que dirijas.
	if m.cantera != null:
		m.cantera.leyendas.append({"nombre": j.nombre, "club_id": club_dt.id, "pos": j.pos,
			"nivel": maxi(j.ovr, 70), "anio_hijo": m.anio + 4, "usado": false, "propio": true})
	historial.append({"anio": m.anio, "semana": m.semana, "titulo": "Retiro",
		"eleccion": "Cuelga las botas tras %d partidos y %d goles; dirige a %s" % [pj_carrera, goles_carrera, club_dt.nombre]})
	return true

func _evento_bienvenida(m: Mundo) -> void:
	eventos.append(_ev("debut_firma", "Tu primer contrato profesional",
		"Tienes 17 años y acabas de firmar tu primer contrato. El utilero te da la camiseta con tu dorsal.",
		[_op("Te sacas una foto con ella para tu familia.", {"moral": 5, "seguidores": 50}),
		_op("La guardas y te vas a entrenar.", {"relacion": 3})], true))
	hitos["debut_firma"] = true

# ---------------------------------------------------------------- guardado

func a_dic() -> Dictionary:
	return {"jugador_id": jugador_id, "fama": fama, "relacion_dt": relacion_dt, "energia": energia,
		"seguidores": seguidores, "agente": agente, "foco": foco, "lanzador": lanzador,
		"convocatorias": convocatorias, "partidos_jugables": partidos_jugables, "stats_temp": stats_temp,
		"temporadas": temporadas, "eventos": eventos, "historial": historial, "ofertas": ofertas,
		"hitos": hitos, "ultima_vez": ultima_vez, "semilla": _rng.seed,
		"goles_carrera": goles_carrera, "pj_carrera": pj_carrera, "caps": caps, "goles_sel": goles_sel,
		"convocatoria": convocatoria, "capitan": capitan, "licencia": licencia,
		"retiro_anunciado": retiro_anunciado, "retirado": retirado, "clubes_pasados": clubes_pasados}

static func desde_dic(d: Dictionary) -> CarreraJugador:
	var c := CarreraJugador.new()
	c.jugador_id = String(d.get("jugador_id", ""))
	c.fama = int(d.get("fama", 5))
	c.relacion_dt = int(d.get("relacion_dt", 55))
	c.energia = int(d.get("energia", ENERGIA_MAX))
	c.seguidores = int(d.get("seguidores", 150))
	c.agente = String(d.get("agente", ""))
	c.foco = String(d.get("foco", "tiro"))
	c.lanzador = d.get("lanzador", c.lanzador)
	c.convocatorias = int(d.get("convocatorias", 0))
	c.partidos_jugables = int(d.get("partidos_jugables", 0))
	c.stats_temp = d.get("stats_temp", c.stats_temp)
	c.temporadas = d.get("temporadas", [])
	c.eventos = d.get("eventos", [])
	c.historial = d.get("historial", [])
	c.ofertas = d.get("ofertas", [])
	c.hitos = d.get("hitos", {})
	c.ultima_vez = d.get("ultima_vez", {})
	c._rng.seed = int(d.get("semilla", 1))
	c.goles_carrera = int(d.get("goles_carrera", 0))
	c.pj_carrera = int(d.get("pj_carrera", 0))
	c.caps = int(d.get("caps", 0))
	c.goles_sel = int(d.get("goles_sel", 0))
	c.convocatoria = d.get("convocatoria", {})
	c.capitan = bool(d.get("capitan", false))
	c.licencia = bool(d.get("licencia", false))
	c.retiro_anunciado = bool(d.get("retiro_anunciado", false))
	c.retirado = bool(d.get("retirado", false))
	c.clubes_pasados = d.get("clubes_pasados", [])
	return c
