extends Node
## Los disparadores del avance por días (paso 2): directiva, crisis de caja, imprevistos y jugador del mes. Solo OBSERVAN: no deben gastar azar ni mover la partida.

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func _mundo(paises: Array, semilla: int) -> Mundo:
	var m := Mundo.new()
	var ps: Array[String] = []
	for p in paises:
		ps.append(String(p))
	m.generar(ps, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[1 + semilla % 3].id)
	return m

func _ready() -> void:
	for cfg: Array in [[["CHI"], 11], [["ARG", "BRA"], 22], [["ESP", "ENG"], 33]]:
		var m := _mundo(cfg[0], int(cfg[1]))
		var e := "%s/%d" % [",".join(cfg[0]), cfg[1]]
		_ok(m.directiva != null and m.roles != null, "%s: hay directiva y roles" % e)
		_directiva(m, e)
		_caja(m, e)
		_imprevistos(m, e)
		_premio(m, e)
		_sin_efectos(m, e)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()

func _directiva(m: Mundo, e: String) -> void:
	var est := DisparadoresDia.nuevo_estado()
	m.directiva.confianza = 60
	_ok(DisparadoresDia.de_directiva(m, est).is_empty(), "%s: con confianza normal no hay ultimátum" % e)
	m.directiva.confianza = 20
	var u := DisparadoresDia.de_directiva(m, est)
	_ok(u.size() == 1 and String(u[0]["tipo"]) == "ultimatum" and String(u[0]["clase"]) == EventosDia.PANTALLA, "%s: confianza 20 = ultimátum (PANTALLA)" % e)
	_ok(DisparadoresDia.de_directiva(m, est).is_empty(), "%s: el ultimátum no se repite de inmediato" % e)
	m.semana += DisparadoresDia.ENFRIAMIENTO_ULTIMATUM
	_ok(DisparadoresDia.de_directiva(m, est).size() == 1, "%s: pasado el enfriamiento, vuelve a salir" % e)
	m.directiva.despedido_ya = true
	var d := DisparadoresDia.de_directiva(m, est)
	_ok(d.size() == 1 and String(d[0]["tipo"]) == "despido" and int(d[0]["causa"]["datos"]["confianza"]) == 20, "%s: despedido_ya = despido con su causa" % e)
	_ok(DisparadoresDia.de_directiva(m, est).is_empty(), "%s: el despido sale una sola vez" % e)
	m.directiva.despedido_ya = false
	m.directiva.confianza = 55

func _caja(m: Mundo, e: String) -> void:
	var est := DisparadoresDia.nuevo_estado()
	_ok(DisparadoresDia.de_crisis_caja(m, est).is_empty(), "%s: sin golpe pendiente no hay aviso" % e)
	m.roles.crisis_pendiente.append({"tipo": "multa", "importe": 500000, "vence": m.anio * 60 + m.semana + 2})
	var a := DisparadoresDia.de_crisis_caja(m, est)
	_ok(a.size() == 1 and String(a[0]["clase"]) == EventosDia.AVISO and String(a[0]["zona"]) == "finanzas", "%s: golpe pendiente = AVISO de finanzas" % e)
	_ok(a.size() == 1 and String(a[0]["titulo"]) != "" and String(a[0]["texto"]) != "" and int(a[0]["causa"]["datos"]["semanas"]) == 2, "%s: usa el texto de CrisisCaja y dice en cuántas semanas se cobra" % e)
	_ok(DisparadoresDia.de_crisis_caja(m, est).is_empty(), "%s: el aviso sale una vez" % e)
	m.roles.crisis_pendiente.clear()

func _imprevistos(m: Mundo, e: String) -> void:
	var est := DisparadoresDia.nuevo_estado()
	_ok(DisparadoresDia.de_imprevistos(m, est).is_empty(), "%s: sin imprevistos no hay evento" % e)
	var sacado := false
	for s in range(1, 200):
		if not m.imprevistos.semana(m, m.mi_club(), m.anio, s, false, 20.0).is_empty():
			sacado = true
			break
	_ok(sacado, "%s: el juego sacó un imprevisto" % e)
	var a := DisparadoresDia.de_imprevistos(m, est)
	_ok(a.size() == 1 and String(a[0]["clase"]) == EventosDia.AVISO and String(a[0]["texto"]) != "" and not String(a[0]["texto"]).contains("%s"), "%s: el imprevisto sale como AVISO con su texto" % e)
	_ok(DisparadoresDia.de_imprevistos(m, est).is_empty(), "%s: el mismo imprevisto sale una sola vez" % e)

func _premio(m: Mundo, e: String) -> void:
	var est := DisparadoresDia.nuevo_estado()
	m.semana = 8
	_ok(DisparadoresDia.de_premio_mensual(m, est).is_empty(), "%s: sin premio esta semana no hay evento" % e)
	var j: Jugador = m.mi_club().plantilla[0]
	j.notas = [9.0, 9.2, 9.4] as Array[float]
	_ok(PremioMensual.revisar(m) == j, "%s: el juego premia al de las mejores notas" % e)
	var a := DisparadoresDia.de_premio_mensual(m, est)
	_ok(a.size() == 1 and String(a[0]["clase"]) == EventosDia.PANTALLA and bool(a[0]["es_mio"]) and String(a[0]["jugador_id"]) == j.id, "%s: jugador del mes tuyo = PANTALLA" % e)
	_ok(DisparadoresDia.de_premio_mensual(m, est).is_empty(), "%s: el premio sale una vez" % e)
	var est2 := DisparadoresDia.nuevo_estado()
	m.semana = 12
	var otro: Jugador = null
	for c: Club in m.liga_de(m.mi_club()).clubes:
		if c != m.mi_club():
			otro = c.plantilla[0]
			break
	j.notas = [5.0, 5.0, 5.0] as Array[float]
	otro.notas = [9.5, 9.5, 9.5] as Array[float]
	PremioMensual.revisar(m)
	var b := DisparadoresDia.de_premio_mensual(m, est2)
	_ok(b.size() == 1 and String(b[0]["clase"]) == EventosDia.AVISO and not bool(b[0]["es_mio"]), "%s: jugador del mes de otro club = AVISO de prensa" % e)

func _sin_efectos(m: Mundo, e: String) -> void:
	var antes := [m.directiva.confianza, m.mi_club().saldo, m.imprevistos.recientes.size(), m.semana]
	var est := DisparadoresDia.nuevo_estado()
	DisparadoresDia.consultar(m, est)
	DisparadoresDia.consultar(m, est)
	_ok(antes == [m.directiva.confianza, m.mi_club().saldo, m.imprevistos.recientes.size(), m.semana], "%s: consultar no cambia el estado de la partida" % e)
