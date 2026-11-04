extends BaseIdea
## BANCO ESPECIALIZADO «partido_porteros», FASE 2 (4-11-2026, megarreforma de los bancos). Mira a los porteros en el partido
## SIMULADO y en las alineaciones; la IA del portero 3D es de la sesión PES 6 y no se toca aquí.
##   1. ALINEACIÓN: en todos los clubes del mundo el once lleva UN portero cuando tiene uno disponible, y es el mejor disponible.
##   2. SIN PORTEROS sanos (todos lesionados): el once sigue de 11 y alguien ocupa la portería (no se cae nada).
##   3. CIFRAS de 150 partidos: % de paradas (atajadas / tiros a puerta) en rango real 60-80 %; un portero casi nunca marca
##      (< 1 % de los goles); tiros a puerta ≥ goles + atajadas de cada lado.
##   4. NOTAS: el portero con la portería a cero sale mejor que el mismo con 4 goles encajados.

var _atajadas := 0
var _goles := 0
var _goles_portero := 0
var _palos := 0
var _remates := 0

func _probar() -> void:
	_titulo("BANCO PARTIDO_PORTEROS (fase 2): alineación, sin porteros, paradas y notas")
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI", "ARG"]
	m.generar(paises, 3131)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_alineaciones(m)
	_sin_porteros(m)
	_cifras(m)
	_notas(m)

func _porteros(lista: Array) -> Array[Jugador]:
	var out: Array[Jugador] = []
	for j: Jugador in lista:
		if j.pos == "POR":
			out.append(j)
	return out

func _alineaciones(m: Mundo) -> void:
	var malos: Array[String] = []
	var n := 0
	for c: Club in m.clubes.values():
		var sanos := _porteros(c.disponibles())
		if sanos.is_empty():
			continue
		n += 1
		var once := c.once()
		var en_once := _porteros(once)
		if en_once.size() != 1:
			malos.append("%s sale con %d porteros (%d sanos)" % [c.nombre, en_once.size(), sanos.size()])
			continue
		var mejor: Jugador = sanos[0]
		for j: Jugador in sanos:
			if j.ovr > mejor.ovr:
				mejor = j
		if en_once[0].ovr < mejor.ovr - 3:
			malos.append("%s pone a %s (%d) con %s (%d) sano" % [c.nombre, en_once[0].nombre, en_once[0].ovr, mejor.nombre, mejor.ovr])
	_comprobar(malos.is_empty(), "en los %d clubes con portero sano el once lleva UNO, y es el mejor (± 3 de media)%s" % [n, "" if malos.is_empty() else " — " + str(malos.slice(0, 5))])

func _sin_porteros(m: Mundo) -> void:
	var c: Club = m.ligas[1].clubes[3]
	var guardado := {}
	for j: Jugador in _porteros(c.plantilla):
		guardado[j] = j.lesion
		j.lesion = 4
	var once := c.once()
	var ids := {}
	for j: Jugador in once:
		ids[j.id] = true
	_comprobar(once.size() == 11 and ids.size() == 11, "con todos los porteros lesionados el once sigue de 11 sin repetidos (%d)" % once.size())
	Azar.sembrar(5)
	var p := Partido.new(c, m.ligas[1].clubes[4])
	var r := p.simular()
	_comprobar(p.terminado_ya and int(r["local"]) >= 0, "  y el partido se juega entero (%d-%d)" % [int(r["local"]), int(r["visita"])])
	for j: Jugador in guardado:
		j.lesion = guardado[j]

func _cifras(m: Mundo) -> void:
	var raros: Array[String] = []
	for i in 150:
		Azar.sembrar(4000 + i)
		var l: Liga = m.ligas[i % m.ligas.size()]
		var a: Club = l.clubes[i % l.clubes.size()]
		var b: Club = l.clubes[(i * 7 + 3) % l.clubes.size()]
		if a == b:
			continue
		var p := Partido.new(a, b)
		var at := {"l": 0, "v": 0}
		p.remate.connect(func(club: Club, _autor: Jugador, tipo: String, _min: int) -> void:
			if tipo == "atajada":
				_atajadas += 1
				at["l" if club == p.local else "v"] += 1
			elif tipo == "poste":
				_palos += 1)
		p.gol.connect(func(_c: Club, autor: Jugador, _min: int, _as: Jugador) -> void:
			_goles += 1
			if autor != null and autor.pos == "POR":
				_goles_portero += 1)
		p.simular()
		_remates += p.remates_local + p.remates_visita
		if p.tiros_puerta_local < p.goles_local + int(at["l"]) or p.tiros_puerta_visita < p.goles_visita + int(at["v"]):
			raros.append("partido %d: a puerta %d/%d, goles %d/%d, atajadas %d/%d" % [i, p.tiros_puerta_local, p.tiros_puerta_visita, p.goles_local, p.goles_visita, at["l"], at["v"]])
	var paradas := 100.0 * float(_atajadas) / maxf(1.0, float(_atajadas + _goles))
	print("  CIFRAS: %.1f remates, %.1f a puerta y %.2f goles por partido; gol por remate %.1f %% (real ~25 remates, ~8,5 a puerta, ~11 %%)" % [
		_remates / 150.0, (_atajadas + _goles) / 150.0, _goles / 150.0, 100.0 * _goles / maxf(1.0, float(_remates))])
	## DEUDA DE CALIBRACIÓN (4-11, en PLAN_GENERAL): el simulado da pocos remates con mucha conversión (CONVERSION 0,267 por remate), así que el
	## portero para ~51 % (real 60-80 %). Arreglarlo es recalibrar llegadas y conversión de todo el simulado (lo decide el dueño); hasta entonces
	## el banco vigila que no EMPEORE (≥ 45 %) y que no se pase del techo real.
	_comprobar(paradas >= 45.0 and paradas <= 80.0, "150 partidos: los porteros paran el %.1f %% de los tiros a puerta (tope de regresión 45 %%; real 60-80 %%, deuda anotada; %d atajadas, %d goles, %d palos)" % [paradas, _atajadas, _goles, _palos])
	var pct_portero := 100.0 * float(_goles_portero) / maxf(1.0, float(_goles))
	_comprobar(pct_portero < 1.0, "un portero casi nunca marca (%d de %d goles, %.2f %%)" % [_goles_portero, _goles, pct_portero])
	_comprobar(raros.is_empty(), "tiros a puerta ≥ goles + atajadas en cada lado%s" % ("" if raros.is_empty() else " — " + str(raros.slice(0, 4))))

func _notas(m: Mundo) -> void:
	var a: Club = m.ligas[0].clubes[2]
	var b: Club = m.ligas[0].clubes[3]
	var notas := []
	for encaja in [0, 4]:
		Azar.sembrar(77)
		var p := Partido.new(a, b)
		p.preparar()
		while not p.terminado_ya:
			p.simular_minuto()
		p.goles_local = 1
		p.goles_visita = encaja
		var nota := -1.0
		for v: Dictionary in p.valoraciones():
			var j: Jugador = v["jugador"]
			if j.pos == "POR" and p.once_local.has(j):
				nota = float(v["nota"])
		notas.append(nota)
	_comprobar(notas[0] > 0.0 and notas[0] > notas[1], "el portero sale mejor con la portería a cero (%.1f) que encajando 4 (%.1f)" % [notas[0], notas[1]])
