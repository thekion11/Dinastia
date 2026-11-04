extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): la CARRERA DEL JUGADOR llevada al límite, en el núcleo (sin pantalla).
##   godot --headless --path . res://pruebas/auditoria_carrera_limite.tscn
## Nombres vacíos o larguísimos, todos los puestos, atributos extremos (1 y 99), lesión grave en el primer partido, 60 semanas con eventos resueltos al azar
## (también opciones y eventos que no existen), ofertas a un club sin plantel o inexistente, retiro (a mano y por edad) y paso a entrenador (con un club
## inexistente), guardado y carga a mitad, y partidos con datos absurdos (0 minutos, notas negativas, goles enormes). Nada debe romperse ni salir NaN.
var _fallos := 0

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _mundo(semilla := 4711) -> Mundo:
	var m := Mundo.new()
	m.generar(["CHI"], semilla)
	return m

func _sano(c: CarreraJugador, m: Mundo) -> String:
	var j := c.jugador(m)
	if j == null:
		return "el jugador desapareció"
	for v in [c.fama, c.relacion_dt, c.energia, c.seguidores]:
		if int(v) < 0:
			return "valor negativo %s" % str(v)
	if c.fama > 100 or c.relacion_dt > 100:
		return "fama o relación fuera de 0-100 (%d, %d)" % [c.fama, c.relacion_dt]
	if j.ovr < 0 or j.ovr > 99:
		return "ovr fuera de rango (%d)" % j.ovr
	if is_nan(c.nota_media()) or is_inf(c.nota_media()):
		return "nota media no finita"
	return ""

func _ready() -> void:
	_nombres_y_puestos()
	_atributos_extremos()
	_primer_partido_lesion_grave()
	_semanas_al_azar()
	_ofertas_raras()
	_retiro_y_entrenador()
	_guardar_y_cargar()
	_partidos_absurdos()
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

func _nombres_y_puestos() -> void:
	var m := _mundo()
	var posd: Dictionary = Datos.tabla("POSD")
	var n := 0
	for pe: String in posd:
		var c := CarreraJugador.crear(m, "" if n % 3 == 0 else ("X".repeat(300) if n % 3 == 1 else "Ñandú Ç"), pe, n % 2 == 0, n)
		var e := _sano(c, m)
		if e != "":
			_comprobar(false, "puesto %s: %s" % [pe, e])
		n += 1
	_comprobar(n > 5, "crear una carrera en los %d puestos, con nombre vacío, de 300 letras y con acentos, no rompe nada" % n)

func _atributos_extremos() -> void:
	for valor in [1, 99]:
		var m := _mundo(100 + valor)
		var c := CarreraJugador.crear(m, "Extremo", "DC", false, 7)
		var j := c.jugador(m)
		for k: String in j.atributos:
			j.atributos[k] = valor
		j.ovr = j.media_en(j.pos_e)
		for i in 12:
			c.semana(m)
			c.entrenar(m)
		var e := _sano(c, m)
		_comprobar(e == "", "atributos al %d: 12 semanas de entreno y eventos (ovr %d) sin romper: %s" % [valor, j.ovr, e])
		var titular := c.es_titular(m)
		var once := c.once_para_partido(m)
		_comprobar(once.size() == 11, "atributos al %d: el once para el partido tiene 11 (%d, titular %s)" % [valor, once.size(), str(titular)])

func _primer_partido_lesion_grave() -> void:
	var m := _mundo(5)
	var c := CarreraJugador.crear(m, "Frágil", "MC", true, 3)
	var j := c.jugador(m)
	j.lesionar(80)
	_comprobar(not j.disponible(), "lesión grave (80 semanas) antes del primer partido: no disponible")
	var once := c.once_para_partido(m)
	_comprobar(not once.has(j), "un lesionado no está en el once")
	_comprobar(not c.es_titular(m), "un lesionado no es titular")
	c.tras_partido(m, {"minutos": 90, "nota": 5.0})   ## (un partido que juega aunque esté lesionado: no rompe)
	for i in 30:
		c.semana(m)
	_comprobar(_sano(c, m) == "", "30 semanas lesionado: %s" % _sano(c, m))
	c.fin_de_temporada(m)
	_comprobar(c.temporadas.size() == 1, "cierra la temporada con la lesión")

func _semanas_al_azar() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var m := _mundo(9)
	var c := CarreraJugador.crear(m, "Azar", "EI", false, 11)
	var resueltos := 0
	for s in 60:
		var nuevos := c.semana(m)
		for e in nuevos:
			if not (e is Dictionary):
				_comprobar(false, "semana %d: un evento no es un diccionario" % s)
		while not c.eventos.is_empty():
			var ev: Dictionary = c.eventos[0]
			var ops: Array = ev.get("opciones", [])
			var r := c.resolver(m, 0, rng.randi_range(-1, ops.size()))   ## incluye opciones que no existen
			if r == "":
				c.eventos.remove_at(0)
			else:
				resueltos += 1
		c.resolver(m, 99, 0)   ## evento que no existe
		c.tras_partido(m, {"minutos": 90, "goles": rng.randi_range(0, 4), "asist": rng.randi_range(0, 3), "nota": rng.randf_range(3.0, 10.0), "titular": rng.randf() < 0.7})
		m.semana += 1
		if m.semana > 52:
			m.semana = 1
			m.anio += 1
			c.fin_de_temporada(m)
		var e2 := _sano(c, m)
		if e2 != "":
			_comprobar(false, "semana %d: %s" % [s, e2])
			return
	_comprobar(true, "60 semanas con eventos al azar (%d eventos resueltos, %d temporadas) sin romper nada" % [resueltos, c.temporadas.size()])

func _ofertas_raras() -> void:
	var m := _mundo(21)
	var c := CarreraJugador.crear(m, "Fichaje", "DC", false, 5)
	_comprobar(not c.aceptar_oferta(m, 0), "aceptar una oferta que no existe devuelve falso")
	c.ofertas.append({"club_id": "no_existe", "sueldo": 1000, "semanas": 3})
	_comprobar(not c.aceptar_oferta(m, 0), "una oferta de un club que no existe devuelve falso")
	var vacio: Club = null
	for cl: Club in m.clubes.values():
		if cl != c.club(m):
			vacio = cl
			break
	vacio.plantilla.clear()
	c.ofertas.clear()
	c.ofertas.append({"club_id": vacio.id, "sueldo": 5000, "semanas": 3})
	_comprobar(c.aceptar_oferta(m, 0), "fichar por un club SIN plantel funciona")
	_comprobar(c.club(m) == vacio and vacio.plantilla.size() == 1, "el club vacío tiene ahora solo al jugador (%d)" % vacio.plantilla.size())
	var once := c.once_para_partido(m)
	_comprobar(once.size() <= 11, "el once de un club con un solo jugador no revienta (%d)" % once.size())
	for i in 6:
		c.semana(m)
	_comprobar(_sano(c, m) == "", "seis semanas en un club con un solo jugador: %s" % _sano(c, m))
	var par := CarreraJugador.partido_de_la_semana(m, vacio)
	_comprobar(par is Array, "el partido de la semana de un club vacío no rompe (%d datos)" % par.size())

func _retiro_y_entrenador() -> void:
	var m := _mundo(33)
	var c := CarreraJugador.crear(m, "Veterano", "MC", false, 8)
	var j := c.jugador(m)
	j.edad = 39
	_comprobar(c.toca_retirarse(m), "a los 39 toca retirarse")
	var ofertas := c.ofertas_de_banquillo(m)
	_comprobar(ofertas.size() <= 3, "las ofertas de banquillo son como mucho tres (%d)" % ofertas.size())
	_comprobar(not c.pasar_a_entrenador(m, null), "pasar a entrenador con un club inexistente devuelve falso")
	_comprobar(not c.retirado, "…y no deja la carrera a medias (retirado sigue en falso)")
	var destino: Club = ofertas[0] if not ofertas.is_empty() else m.ligas[0].clubes[2]
	_comprobar(c.pasar_a_entrenador(m, destino), "pasar a entrenador de %s" % destino.nombre)
	_comprobar(c.retirado and m.mi_club() == destino, "retirado y al mando del club nuevo")
	_comprobar(not c.pasar_a_entrenador(m, destino) or true, "repetirlo no rompe")
	for i in 5:
		c.semana(m)
	var j2 := _mundo(34)
	var c2 := CarreraJugador.crear(j2, "Anuncio", "DC", false, 9)
	c2.retiro_anunciado = true
	_comprobar(c2.toca_retirarse(j2), "un retiro anunciado toca aunque sea joven")

func _guardar_y_cargar() -> void:
	var m := _mundo(44)
	var c := CarreraJugador.crear(m, "Guardado", "MP", true, 12)
	for s in 25:
		c.semana(m)
		c.tras_partido(m, {"minutos": 80, "goles": s % 2, "nota": 6.5})
	var d := c.a_dic()
	var texto := JSON.stringify(d)
	var de_vuelta: Variant = JSON.parse_string(texto)
	_comprobar(de_vuelta is Dictionary, "la carrera sobrevive a JSON")
	var c2 := CarreraJugador.desde_dic(de_vuelta as Dictionary)
	_comprobar(c2.jugador_id == c.jugador_id and c2.fama == c.fama and c2.pj_carrera == c.pj_carrera, "cargar da lo mismo (pj %d, fama %d)" % [c2.pj_carrera, c2.fama])
	var viejo := CarreraJugador.desde_dic({})
	_comprobar(viejo.fama >= 0, "cargar un guardado vacío da una carrera con valores por omisión")
	var roto := CarreraJugador.desde_dic({"jugador_id": "x", "stats_temp": "roto", "eventos": 5, "lanzador": [], "hitos": "x", "temporadas": {"a": 1}})
	_comprobar(roto != null and roto.stats_temp.has("notas") and roto.eventos is Array and roto.hitos is Dictionary, "un guardado con tipos rotos no revienta al cargar (usa los valores por omisión)")
	_comprobar(not is_nan(roto.nota_media()), "…y la nota media de esa carrera es un número")
	var parcial := CarreraJugador.desde_dic({"jugador_id": "x", "stats_temp": {"pj": 3}})
	_comprobar(int(parcial.stats_temp["pj"]) == 3 and parcial.stats_temp.has("notas"), "un stats_temp incompleto se completa (pj 3 conservado)")

func _partidos_absurdos() -> void:
	var m := _mundo(55)
	var c := CarreraJugador.crear(m, "Absurdo", "POR", false, 13)
	c.tras_partido(m, {"minutos": 0})
	c.tras_partido(m, {"minutos": -5, "goles": 3})
	c.tras_partido(m, {"minutos": 90, "goles": 1000000, "asist": -4, "nota": -50.0, "paradas": 999999, "encajados": 0})
	c.tras_partido(m, {"minutos": 90, "nota": 9999.0})
	c.tras_partido(m, {})
	var e := _sano(c, m)
	_comprobar(e == "", "partidos con datos absurdos (0 minutos, notas negativas, un millón de goles): %s" % e)
	_comprobar(c.fama <= 100 and c.energia >= 0, "fama %d y energía %d siguen en rango" % [c.fama, c.energia])
