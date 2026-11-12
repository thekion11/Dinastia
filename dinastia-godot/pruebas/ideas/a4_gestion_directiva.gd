extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 CRUZADO: DIRECTIVA y JUNTA al límite.
##   1. Los 87 países: para cada club de cada liga, el objetivo de la directiva cabe en su liga (1 ≤ meta ≤ clubes de la liga) y «Evitar el descenso» exige algo real.
##   2. Confianza: 1000 derrotas seguidas, victorias sin fin, cierre de temporada con puestos absurdos (0, −3, 500): confianza en 0-100, un solo despido, nada más cambia tras despedirte.
##   3. Junta: 60 trimestres con todas las respuestas (a/b/otra), sin pendiente, con el club en números rojos y a 0 de caja: sin error, historial acotado, humor en 0-100.
var _paises: Array[String] = []

func _probar() -> void:
	_titulo("A4 CRUZADO (gestión): directiva y junta al límite")
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://datos/paises.json"))
	for k: String in (d["paises"] as Dictionary):
		_paises.append(k)
	await _objetivos()
	_confianza()
	_junta()

func _objetivos() -> void:
	var mal: Array[String] = []
	var ligas := 0
	var chicas := 0
	for i in range(0, _paises.size(), 6):
		Partido.limpiar_contexto()
		var m := Mundo.new()
		var grupo: Array[String] = []
		grupo.assign(_paises.slice(i, i + 6))
		m.generar(grupo, 40 + i)
		for l: Liga in m.ligas:
			ligas += 1
			var n := l.clubes.size()
			if n < 16:
				chicas += 1
			var orden := l.clubes.duplicate()
			orden.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
			for k in n:
				var dd := Directiva.new(orden[k] as Club, k + 1, n)   ## (12-11) como la crea el juego (`Mundo`), con el tamaño de su liga
				if dd.meta_puesto < 1 or dd.meta_puesto > n:
					mal.append("%s (%d clubes, puesto %d): meta %d «%s»" % [l.nombre, n, k + 1, dd.meta_puesto, dd.objetivo])
				if dd.objetivo == "Evitar el descenso" and dd.meta_puesto >= n:
					mal.append("%s (%d clubes): «Evitar el descenso» con meta %d no se puede incumplir" % [l.nombre, n, dd.meta_puesto])
		await get_tree().process_frame
	print("  (info) %d ligas revisadas, %d con menos de 16 clubes" % [ligas, chicas])
	_comprobar(mal.is_empty(), "el objetivo de la directiva cabe en la liga y exige algo (%d fallos%s)" % [mal.size(), "" if mal.is_empty() else ": " + str(mal.slice(0, 4))])

func _directiva() -> Directiva:
	var c := Club.new()
	c.id = "x"
	c.nombre = "Club X"
	c.rep = 60
	var rival := Club.new()
	rival.nombre = "Rival"
	rival.rep = 60
	var d := Directiva.new(c, 5)
	d.puede_despedirte = true
	return d

func _confianza() -> void:
	var d := _directiva()
	var rival := Club.new()
	rival.nombre = "Rival"
	rival.rep = 40
	var despidos := [0]
	d.despedido.connect(func(_m: String) -> void: despidos[0] += 1)
	for i in 1000:
		d.tras_partido(0, 3, rival)
	_comprobar(d.confianza >= 0 and d.confianza <= 100, "1000 derrotas: confianza en 0-100 (%d)" % d.confianza)
	_comprobar(despidos[0] == 1, "un solo despido en 1000 derrotas (%d)" % despidos[0])
	var antes := d.confianza
	for i in 50:
		d.tras_partido(5, 0, rival)
	_comprobar(d.confianza == antes, "despedido: ganar ya no mueve la confianza (%d → %d)" % [antes, d.confianza])
	var d2 := _directiva()
	for i in 500:
		d2.tras_partido(4, 0, rival)
	_comprobar(d2.confianza == 100, "victorias sin fin: tope 100 (%d)" % d2.confianza)
	for puesto in [0, -3, 1, 500]:
		var d3 := _directiva()
		var r := d3.tras_temporada(puesto, puesto == 1, puesto == 1)
		_comprobar(d3.confianza >= 0 and d3.confianza <= 100 and not r.is_empty(), "cierre de temporada en el puesto %d: confianza %d, cumplido %s" % [puesto, d3.confianza, str(r.get("cumplido"))])
	var d4 := _directiva()
	d4.puede_despedirte = false
	for i in 300:
		d4.tras_partido(0, 4, rival)
	_comprobar(not d4.despedido_ya and d4.confianza == 0, "quien no puede ser despedido (dueño) se queda sin confianza pero no sale (%d)" % d4.confianza)

func _junta() -> void:
	for caso in ["normal", "números rojos", "caja 0", "sin plantel"]:
		var c := Club.new()
		c.id = "club_j_%s" % caso
		c.nombre = "Club J"
		c.rep = 55
		c.saldo = -5000000 if caso == "números rojos" else (0 if caso == "caja 0" else 10000000)
		if caso != "sin plantel":
			for i in 14:
				var j := Jugador.new()
				j.id = "jj%d" % i
				j.edad = 18 + i
				c.plantilla.append(j)
		var junta := Junta.new()
		var d := Directiva.new(c, 5)
		var hechas := 0
		for t in 60:
			junta.semana(c, 2027 + t / 10, (t % 4 + 1) * Junta.CADA)
			if not junta.pendiente.is_empty():
				var op: String = ["a", "b", "x"][t % 3]
				junta.resolver(op, c, d, null)
				hechas += 1
		junta.resolver("a", c, d, null)   ## sin junta abierta: nada
		var malo := false
		for a: Dictionary in junta.accionistas:
			malo = malo or int(a["humor"]) < 0 or int(a["humor"]) > 100
		_comprobar(caso != "números rojos" or c.saldo >= -5000000, "junta «%s»: no reparte dividendos con la caja en números rojos (saldo %d)" % [caso, c.saldo])
		_comprobar(caso != "caja 0" or c.saldo >= 0, "junta «%s»: la caja no baja de 0 por dividendos (saldo %d)" % [caso, c.saldo])
		_comprobar(not malo and junta.historial.size() <= 12 and hechas > 5, "junta «%s»: %d juntas resueltas, humor 0-100, historial %d ≤ 12, confianza %d, saldo %d" % [caso, hechas, junta.historial.size(), d.confianza, c.saldo])
	var c2 := Club.new()
	c2.id = "k2"
	var j2 := Junta.new()
	j2.semana(null, 2027, 1)
	j2.formar(null)
	_comprobar(j2.presidente.is_empty(), "junta sin club: no se forma nada y no falla")
