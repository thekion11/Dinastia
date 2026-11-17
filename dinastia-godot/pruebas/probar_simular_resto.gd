extends Node
## «SIMULAR EL RESTO» CON EL SIMULADOR CALIBRADO, EN EL BANCO (17-11, Auditoría). 30 partidos (3 cruces de 3 países, 10 cada uno) jugados hasta el
## minuto 60, con una roja y un cambio en ese momento (como si vinieran del 3D), y el resto con `SimularResto.simular`: en los 30 minutos que quedan
## la media de goles está entre 0,5 y 1,5 y ninguno pasa de 4; el acta es coherente (los goles de antes se conservan, el expulsado no vuelve, los
## cambios hechos cuentan) y el partido termina.

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func correr(_padre: Node) -> int:
	var goles_tramo: Array = []
	for cfg: Array in [["ESP", 2], ["ARG", 5], ["JPN", 8]]:
		var m := Mundo.new()
		var ps: Array[String] = [String(cfg[0])]
		m.generar(ps, 1300 + int(cfg[1]))
		var liga: Liga = m.ligas[0]
		var a: Club = liga.clubes[int(cfg[1]) % liga.clubes.size()]
		var b: Club = liga.clubes[(int(cfg[1]) + 3) % liga.clubes.size()]
		for k in 10:
			var p := Partido.new(a, b)
			p.preparar()
			while p.minuto < 60:
				p.simular_minuto()
			var expulsado: Jugador = p.once_visita[4]
			p.tarjeta_externa(expulsado.id, true)
			var sale: Jugador = p.once_local[6]
			var entra: Jugador = null
			for j: Jugador in a.plantilla:
				if not p.once_local.has(j) and j.disponible() and j.pos_e != "POR" and not p.ya_salio(j):
					entra = j
					break
			var err := p.cambiar(sale, entra) if entra != null else "sin suplente"
			var antes := p.goles_local + p.goles_visita
			var cronica_antes := p.cronica.filter(func(e: Dictionary) -> bool: return String(e.get("tipo", "")) == "gol").size()
			p.motor_externo = true   ## como si viniera del 3D
			SimularResto.simular(p, false)
			var tramo := p.goles_local + p.goles_visita - antes
			goles_tramo.append(tramo)
			var etiqueta := "%s %d" % [cfg[0], k]
			_ok(p.terminado_ya, "%s: el partido termina" % etiqueta)
			_ok(not p.motor_externo, "%s: el 3D deja de llevar el reloj" % etiqueta)
			_ok(tramo <= 4, "%s: como mucho 4 goles en los 30 minutos que quedan (%d)" % [etiqueta, tramo])
			_ok(p.cronica.filter(func(e: Dictionary) -> bool: return String(e.get("tipo", "")) == "gol").size() == cronica_antes + tramo, "%s: los goles de antes se conservan y los nuevos van al acta" % etiqueta)
			_ok(not p.once_visita.has(expulsado), "%s: el expulsado no vuelve" % etiqueta)
			_ok(err == "" and not p.once_local.has(sale) and p.cambios_local >= 1, "%s: el cambio hecho se respeta (%s)" % [etiqueta, err])
	var media := 0.0
	for g: int in goles_tramo:
		media += float(g)
	media /= maxf(float(goles_tramo.size()), 1.0)
	print("  simular el resto desde el 60': media de goles en el tramo %.2f (%d partidos)" % [media, goles_tramo.size()])
	_ok(media >= 0.5 and media <= 1.5, "la media de goles en los 30 minutos que quedan está entre 0,5 y 1,5 (%.2f)" % media)
	return fallos
