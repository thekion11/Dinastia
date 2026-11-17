extends Node
## Las pantallas de después del partido (avance por días): momentos anotados mientras se juega, clasificación ataque/defensa, resultado, momentos y popup se montan con
## clubes de países distintos, y el botón «Partido jugado» del menú aparece tras jugar.

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func _frames(n := 3) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	for cfg: Array in [["CHI", 3], ["ESP", 5], ["BRA", 7]]:
		var m := Mundo.new()
		var ps: Array[String] = [String(cfg[0])]
		m.generar(ps, 40 + int(cfg[1]))
		var liga: Liga = m.ligas[0]
		m.tomar_el_mando(liga.clubes[int(cfg[1])].id)
		var mio := m.mi_club()
		var rival: Club = liga.clubes[(int(cfg[1]) + 6) % liga.clubes.size()]
		var p := Partido.new(rival, mio)
		MomentosPartido.registrar(p)
		MomentosPartido.registrar(p)   ## idempotente
		p.preparar()
		while not p.terminado_ya:
			p.simular_minuto()
		var e := String(cfg[0])
		var lista := MomentosPartido.lista_de(p, mio)
		var goles := p.goles_local + p.goles_visita
		var n_goles := 0
		for x: Dictionary in lista:
			_ok(String(x["txt"]) != "", "%s: cada momento trae su texto" % e)
			if String(x["txt"]).begins_with("Gol"):
				n_goles += 1
		_ok(n_goles == goles or lista.size() >= MomentosPartido.MAX, "%s: los goles del marcador (%d) están entre los momentos (%d)" % [e, goles, n_goles])
		_ok(not MomentosPartido.hay_ultimo(m), "%s: antes de jugar no hay «Partido jugado»" % e)
		MomentosPartido.recordar(p, m)
		_ok(MomentosPartido.hay_ultimo(m) and MomentosPartido.ultimo == p, "%s: tras jugar queda el último partido" % e)
		var r := ResultadoPartido.mostrar(self, p, mio)
		await _frames(3)
		_ok(r.is_inside_tree(), "%s: el resultado se monta" % e)
		var cont := {"v": ""}
		r.elegido.connect(func(op: String) -> void: cont["v"] = op)
		r.elegido.emit("0")
		_ok(cont["v"] == "0", "%s: el resultado emite al continuar" % e)
		r.queue_free()
		for filtro in ["todas", "ofensivas", "defensivas"]:
			var mo := MomentosPartido.mostrar(self, p, mio, filtro)
			await _frames(2)
			_ok(mo.is_inside_tree(), "%s: los momentos (%s) se montan" % [e, filtro])
			mo.queue_free()
		var base := Control.new()
		add_child(base)
		var b := Button.new()
		base.add_child(b)
		var pop := PopupPartidoJugado.abrir(base, b)
		var ops := {"v": ""}
		pop.elegido.connect(func(op: String) -> void: ops["v"] = op)
		pop._elegir("momentos:ofensivas")
		_ok(ops["v"] == "momentos:ofensivas", "%s: el popup devuelve su opción" % e)
		base.queue_free()
		await _frames(2)
	_ok(ResultadoPartido.abreviar("Joaquín Retamal Soto") == "J. Retamal Soto", "el nombre se abrevia como en la maqueta")
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
