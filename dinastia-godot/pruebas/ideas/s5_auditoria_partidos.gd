extends BaseIdea
## AUDITORÍA DE PARTIDOS (26-10-2026, sesión 5, pedida por la sesión principal y el dueño): 50 partidos
## simulados y 50 en vivo (la crónica de texto del DT), medidos. Coherencia de resultados y estadísticas,
## narración repetida, silencios largos, textos sin traducir (la crónica en inglés) y ritmo.

const N := 50
const PALABRAS_ES := [" de ", " del ", " el ", " la ", " por ", " con ", "¡", " y ", " se ", " fuera", " Cambio", " entra "]

func _probar() -> void:
	Partido.limpiar_contexto()
	var m := _mundo(7272)
	Partido.ctx_club_id = m.mi_club_id
	_titulo("AUDITORÍA: %d partidos simulados" % N)
	_simulados(m)
	_titulo("AUDITORÍA: %d partidos en vivo (crónica del DT)" % N)
	_en_vivo(m, "es")
	_titulo("AUDITORÍA: la crónica en inglés")
	_en_vivo(m, "en")
	Idiomas.idioma = "es"

func _simulados(m: Mundo) -> void:
	var clubes: Array = m.ligas[0].clubes
	var goles := 0
	var local_gana := 0
	var empates := 0
	var incoherentes: Array = []
	var xg := 0.0
	var remates := 0
	var a_puerta := 0
	var tarjetas := [0]
	var lesiones := [0]
	var por_tramo := [0, 0, 0, 0, 0, 0]
	var goleadores := {}
	var goles_yo := [0]
	for k in N:
		var a: Club = clubes[k % clubes.size()]
		var b: Club = clubes[(k * 7 + 3) % clubes.size()] if k % 2 == 1 else m.mi_club()
		if a == b:
			b = clubes[(k + 1) % clubes.size()]
		var p := Partido.new(a, b)
		p.tarjeta.connect(func(_j: Jugador, _r: bool, _m: int) -> void: tarjetas[0] += 1)
		p.lesion.connect(func(_j: Jugador, _s: int, _m: int) -> void: lesiones[0] += 1)
		p.gol.connect(func(c: Club, autor: Jugador, mi: int, _a: Jugador) -> void:
			por_tramo[clampi((mi - 1) / 15, 0, 5)] += 1
			if c == m.mi_club():
				goles_yo[0] += 1
				if autor != null:
					goleadores[autor.nombre] = int(goleadores.get(autor.nombre, 0)) + 1)
		p.simular()
		goles += p.goles_local + p.goles_visita
		local_gana += 1 if p.goles_local > p.goles_visita else 0
		empates += 1 if p.goles_local == p.goles_visita else 0
		xg += p.xg_local + p.xg_visita
		remates += p.remates_local + p.remates_visita
		a_puerta += p.tiros_puerta_local + p.tiros_puerta_visita
		var en_cronica := [0, 0]
		for e: Dictionary in p.cronica:
			if String(e.get("tipo", "")) == "gol":
				en_cronica[0 if String(e["club"]) == a.id else 1] += 1
		if en_cronica[0] != p.goles_local or en_cronica[1] != p.goles_visita:
			incoherentes.append("%s: crónica %s" % [str(p), str(en_cronica)])
		if p.tiros_puerta_local < p.goles_local or p.tiros_puerta_visita < p.goles_visita:
			incoherentes.append("%s: menos tiros a puerta que goles" % str(p))
		if p.remates_local < p.tiros_puerta_local or p.remates_visita < p.tiros_puerta_visita:
			incoherentes.append("%s: menos remates que tiros a puerta" % str(p))
		if p.posesion_local < 22.0 or p.posesion_local > 78.0:
			incoherentes.append("%s: posesión %.0f" % [str(p), p.posesion_local])
		var suma_notas := 0
		for v: Dictionary in p.valoraciones():
			suma_notas += 1 if float(v["nota"]) >= 3.0 and float(v["nota"]) <= 10.0 else 0
	_linea("  goles/partido %.2f · local gana %d %% · empates %d %% · xG/partido %.2f · remates %.1f · a puerta %.1f · tarjetas %.1f · lesiones %.2f" % [
		float(goles) / N, 100 * local_gana / N, 100 * empates / N, xg / N, float(remates) / N, float(a_puerta) / N, float(tarjetas[0]) / N, float(lesiones[0]) / N])
	var top := 0
	for g: String in goleadores:
		top = maxi(top, int(goleadores[g]))
	_linea("  goles por tramo de 15': %s · tu club: %d goles, el máximo goleador %d (%.0f %%), %d goleadores distintos" % [str(por_tramo), goles_yo[0], top, 100.0 * top / maxf(goles_yo[0], 1), goleadores.size()])
	for x in incoherentes.slice(0, 5):
		_linea("  · " + String(x))
	_comprobar(incoherentes.is_empty(), "marcador, crónica, tiros y posesión cuadran en los %d (%d incoherencias)" % [N, incoherentes.size()])
	_comprobar(float(goles) / N > 1.8 and float(goles) / N < 3.6, "goles por partido en lo razonable (%.2f)" % (float(goles) / N))
	## Antes del 26-10 quedaba un 26 % por debajo (92 frente a 124): todos los informes decían «finísimos».
	_comprobar(absf(xg - goles) / maxf(goles, 1) < 0.15, "el xG total se parece a los goles (%.1f frente a %d)" % [xg, goles])

func _en_vivo(m: Mundo, idioma: String) -> void:
	Idiomas.idioma = idioma
	var yo := m.mi_club()
	var clubes: Array = m.ligas[0].clubes
	var repetidas := 0
	var lineas_total := 0
	var max_silencio := 0
	var silencios_largos := 0
	var en_es := 0
	var narrables := 0
	var incoherentes: Array = []
	var frases := {}
	var ejemplos_es: Array = []
	for k in N:
		var otro: Club = clubes[1 + k % (clubes.size() - 1)]
		var p := Partido.new(yo, otro) if k % 2 == 0 else Partido.new(otro, yo)
		var vivo := PartidoVivo.new()
		vivo.con_3d = false
		add_child(vivo)
		vivo.abrir(p, yo)
		var ultimo_min := 0
		var antes := 0
		while not p.terminado_ya:
			p.simular_minuto()
			var n := vivo._cronica.get_paragraph_count()
			if n > antes + 0:
				## Silencio: minutos sin ninguna línea nueva en la crónica.
				max_silencio = maxi(max_silencio, p.minuto - ultimo_min)
				if p.minuto - ultimo_min >= 20:
					silencios_largos += 1
				ultimo_min = p.minuto
			antes = n
		var texto := vivo._cronica.get_parsed_text()
		var vistas := {}
		for l: String in texto.split("\n"):
			var s := l.strip_edges()
			if s == "":
				continue
			lineas_total += 1
			## Sin el minuto delante: «34'  🧤 Atajada…» y «71'  🧤 Atajada…» son la misma frase.
			var sin_min := s
			var ap := s.find("'  ")
			if ap > 0 and ap < 4:
				sin_min = s.substr(ap + 3)
			if vistas.has(sin_min) and ap > 0 and ap < 4:
				repetidas += 1
			vistas[sin_min] = true
			frases[sin_min] = int(frases.get(sin_min, 0)) + 1
			if idioma != "es" and ap > 0 and ap < 4:
				narrables += 1
				for w: String in PALABRAS_ES:
					if (" " + sin_min + " ").contains(w):
						en_es += 1
						if ejemplos_es.size() < 60 and not ejemplos_es.has(sin_min):
							ejemplos_es.append(sin_min)
						break
		var gl := "%d-%d" % [p.goles_local, p.goles_visita]
		if not texto.contains(gl):
			incoherentes.append("sin el marcador final %s" % gl)
		vivo.queue_free()
	if idioma == "es":
		_linea("  líneas/partido %.1f · repetidas en el mismo partido %d (%.1f %%) · silencio máximo %d' · silencios ≥ 20' %d" % [
			float(lineas_total) / N, repetidas, 100.0 * repetidas / maxf(lineas_total, 1), max_silencio, silencios_largos])
		_comprobar(incoherentes.is_empty(), "la crónica cierra con el marcador real en los %d" % N)
		## Antes: 48 de 50 partidos con 20' o más sin una línea (máximo 38').
		_comprobar(max_silencio <= 10 and silencios_largos == 0, "la crónica nunca se queda callada más de 10' (máximo %d')" % max_silencio)
		_comprobar(float(repetidas) / maxf(lineas_total, 1) < 0.03, "menos de un 3 %% de frases repetidas en el mismo partido (%.1f %%)" % (100.0 * repetidas / maxf(lineas_total, 1)))
		var top: Array = frases.keys()
		top.sort_custom(func(x: String, y: String) -> bool: return int(frases[x]) > int(frases[y]))
		for f: String in top.slice(0, 6):
			_linea("  %4d × %s" % [int(frases[f]), f.substr(0, 90)])
	else:
		_linea("  líneas con minuto: %d · con castellano: %d (%.0f %%)" % [narrables, en_es, 100.0 * en_es / maxf(narrables, 1)])
		for e: String in ejemplos_es.slice(0, 6):
			_linea("    «%s»" % e.substr(0, 100))
		## Antes: el 60 % de la crónica en inglés salía en castellano.
		_comprobar(float(en_es) / maxf(narrables, 1) < 0.03, "la crónica en inglés: menos de un 3 %% de líneas en castellano (%.1f %%)" % (100.0 * en_es / maxf(narrables, 1)))
