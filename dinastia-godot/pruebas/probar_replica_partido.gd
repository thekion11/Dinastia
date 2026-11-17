extends Node
## La réplica de un partido («Jugar de nuevo» / «Jugar momento»): clubes CLONADOS (nada de lo que pase toca la partida), con el minuto y el marcador de la jugada.

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func correr(padre: Node = null) -> int:
	var _p := padre
	for cfg: Array in [[["CHI"], 11], [["ESP", "ENG"], 12], [["JPN"], 13]]:
		var m := Mundo.new()
		var ps: Array[String] = []
		for c in cfg[0]:
			ps.append(String(c))
		m.generar(ps, int(cfg[1]))
		var liga: Liga = m.ligas[0]
		var orig := Partido.new(liga.clubes[0], liga.clubes[1])
		orig.preparar()
		orig.cronica.append({"min": 20, "tipo": "gol", "club": liga.clubes[0].id, "autor": "A"})
		orig.cronica.append({"min": 70, "tipo": "gol", "club": liga.clubes[1].id, "autor": "B"})
		var e := "%s/%d" % [",".join(cfg[0]), cfg[1]]
		var r := ReplicaPartido.partido_de(orig, 75)
		_ok(r.local != orig.local and r.visita != orig.visita and r.local.id == orig.local.id, "%s: los clubes están clonados (mismos ids, otros objetos)" % e)
		_ok(r.local.plantilla.size() == orig.local.plantilla.size() and r.local.plantilla[0] != orig.local.plantilla[0], "%s: los jugadores también" % e)
		r.preparar()
		_ok(r.minuto == 74 and r.goles_local == 1 and r.goles_visita == 1, "%s: arranca en el minuto 74 con el 1-1 de entonces (%d, %d-%d)" % [e, r.minuto, r.goles_local, r.goles_visita])
		var antes := orig.local.plantilla[0].goles
		var autor: Jugador = r.local.plantilla[0]
		r.gol_externo(true, autor.id, "", 0)
		_ok(orig.local.plantilla[0].goles == antes, "%s: un gol de la réplica no toca a los jugadores de la partida" % e)
		var r0 := ReplicaPartido.partido_de(orig, 0)
		r0.preparar()
		_ok(r0.minuto == 0 and r0.goles_local == 0 and r0.goles_visita == 0, "%s: «jugar de nuevo» arranca de cero" % e)
	return fallos

func _ready() -> void:
	correr(self)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
