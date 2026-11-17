extends Node
## Las decisiones con opciones del avance por días: salen de los sistemas del juego y su elección tiene el EFECTO REAL de siempre (guerra de agentes y asuntos de la
## academia). Tres mundos de países distintos.

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func correr(_padre: Node = null) -> int:
	for cfg: Array in [[["CHI"], 61], [["ENG", "ESP"], 62], [["JPN"], 63]]:
		var m := Mundo.new()
		var ps: Array[String] = []
		for c in cfg[0]:
			ps.append(String(c))
		m.generar(ps, int(cfg[1]))
		m.tomar_el_mando(m.ligas[0].clubes[2 + int(cfg[1]) % 3].id)
		var e := "%s/%d" % [",".join(cfg[0]), cfg[1]]
		var mio := m.mi_club()
		var ev_ag := {"tipo": "guerra_agentes", "causa": {"id": "guerra_agentes", "datos": {}}}
		var ev_ca := {"tipo": "evento_cantera", "causa": {"id": "evento_cantera", "datos": {}}}
		_ok(DecisionesDia.opciones(m, ev_ag).is_empty() and DecisionesDia.opciones(m, ev_ca).is_empty(), "%s: sin decisión abierta no hay opciones" % e)
		## GUERRA DE AGENTES: «mejorar el contrato» sube el sueldo y la moral del jugador; «aguantar» no cambia el contrato
		var j: Jugador = mio.plantilla[0]
		var sueldo0 := j.sueldo
		m.cantera.exigencia = {"tipo": "mejora", "agente": "Agente X", "pid": j.id, "ids": [j.id], "perfil": "discreto", "txt": "Exige mejorar un contrato.",
			"opcion_a": "Mejorar el contrato", "opcion_b": "Aguantar la presión"}
		var ops := DecisionesDia.opciones(m, ev_ag)
		_ok(ops.size() == 2 and String(ops[0]["titulo"]) == "Mejorar el contrato" and String(ops[1]["id"]) == "b", "%s: la guerra de agentes ofrece sus dos opciones" % e)
		var r := DecisionesDia.resolver(m, ev_ag, "a")
		_ok(not r.is_empty() and j.sueldo > sueldo0 and m.cantera.exigencia.is_empty(), "%s: «mejorar el contrato» sube el sueldo (%d → %d) y cierra el asunto" % [e, sueldo0, j.sueldo])
		_ok(DecisionesDia.resolver(m, ev_ag, "a").is_empty(), "%s: no se puede decidir dos veces" % e)
		var sueldo1 := j.sueldo
		m.cantera.exigencia = {"tipo": "mejora", "agente": "Agente X", "pid": j.id, "ids": [j.id], "perfil": "discreto", "txt": "x", "opcion_a": "A", "opcion_b": "B"}
		DecisionesDia.resolver(m, ev_ag, "b")
		_ok(j.sueldo == sueldo1 and m.cantera.exigencia.is_empty(), "%s: «aguantar la presión» no toca el contrato y cierra el asunto" % e)
		## ACADEMIA: el torneo cuesta dinero si vas y nada si declinas
		m.eventos_cantera.pendiente = {"tipo": "torneo", "id": "x", "nombre": "Chico", "tema": "Invitan a la academia.", "a": "Ir al torneo (viaje y alojamiento)", "b": "Declinar la invitación"}
		var ops2 := DecisionesDia.opciones(m, ev_ca)
		_ok(ops2.size() == 2 and String(ops2[1]["titulo"]) == "Declinar la invitación", "%s: la academia ofrece sus dos opciones" % e)
		var caja0 := mio.saldo
		var r2 := DecisionesDia.resolver(m, ev_ca, "a")
		_ok(not r2.is_empty() and mio.saldo < caja0 and m.eventos_cantera.pendiente.is_empty(), "%s: ir al torneo cuesta dinero (%d → %d)" % [e, caja0, mio.saldo])
		m.eventos_cantera.pendiente = {"tipo": "torneo", "id": "x", "nombre": "Chico", "tema": "t", "a": "A", "b": "B"}
		var caja1 := mio.saldo
		DecisionesDia.resolver(m, ev_ca, "b")
		_ok(mio.saldo == caja1 and m.eventos_cantera.pendiente.is_empty(), "%s: declinar no cuesta nada" % e)
	return fallos

func _ready() -> void:
	correr(self)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
