extends BaseIdea
## BANCO ESPECIALIZADO «mercado_contratos», FASE 2 (4-11-2026, megarreforma de los bancos): fichajes y contratos.
##   1. INTEGRIDAD durante una temporada y el cambio de año: cada jugador está en UN solo plantel y su `club_id` es ese club;
##      los libres no están en ningún plantel; nadie está dos veces en el mismo.
##   2. TRASPASOS (señal `traspaso`): comprador ≠ vendedor, monto ≥ 0, el jugador queda en el comprador y fuera del vendedor,
##      con contrato de 1-5 años (3 para los menores) y sueldo > 0.
##   3. PLANTELES razonables: 16-34 jugadores y al menos 1 portero en cada club, en todo momento mirado.
##   4. CONTRATOS: 0-5 años (menores 0-3), sueldo > 0; al cerrar el año vencen y nadie queda con contrato negativo.
##   5. REGLAS del trato: `ajustar_anios` respeta FIFA (5 años; 3 los menores); un jugador no firma por menos del 92 % de lo que
##      pide; un club de la IA no gasta más del 45 % de su caja; `fichar` mueve el dinero exacto de un club al otro.

var _malos: Array[String] = []
var _traspasos := 0

func _probar() -> void:
	_titulo("BANCO MERCADO_CONTRATOS (fase 2): integridad, traspasos, planteles, contratos y reglas del trato")
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI", "ARG"]
	m.generar(paises, 7171)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_mi_id = m.mi_club_id
	m.mercado.traspaso.connect(_al_traspaso)
	_integridad(m, "al empezar")
	var anio0 := m.anio
	var semanas := 0
	while m.temporada_en_curso() and semanas < 80:
		m.avanzar_semana()
		semanas += 1
		if semanas % 10 == 0:
			_integridad(m, "semana %d" % semanas)
	m.cerrar_temporada_simulada()
	_integridad(m, "al cerrar la temporada")
	m.nueva_temporada()
	_comprobar(m.anio > anio0, "la temporada se cierra y empieza otra (%d semanas, año %d → %d)" % [semanas, anio0, m.anio])
	for i in 4:
		m.avanzar_semana()
	_integridad(m, "tras el cambio de año")
	var vencidos: Array[String] = []
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			if j.anios_contrato <= 0:
				vencidos.append("%s (%s)" % [j.nombre, c.nombre])
	_comprobar(vencidos.is_empty(), "tras el cambio de año nadie sigue en un plantel con el contrato vencido (%d)%s" % [vencidos.size(), "" if vencidos.is_empty() else " — " + str(vencidos.slice(0, 6))])
	_comprobar(m.libres.size() > 0, "  algunos contratos vencidos dejaron jugadores libres (%d)" % m.libres.size())
	_comprobar(_malos.is_empty(), "una temporada entera: planteles, traspasos y contratos sin incoherencias%s" % ("" if _malos.is_empty() else " — " + str(_malos)))
	_comprobar(_traspasos > 10, "  hubo traspasos que mirar (%d)" % _traspasos)
	_reglas(m)

func _malo(t: String) -> void:
	if _malos.size() < 12:
		_malos.append(t)

func _al_traspaso(j: Jugador, de: Club, a: Club, monto: int) -> void:
	_traspasos += 1
	if a == null or de == a:
		_malo("traspaso de %s sin comprador o al mismo club" % j.nombre)
		return
	if monto < 0:
		_malo("traspaso de %s por %d" % [j.nombre, monto])
	if a.id != _mi_id and monto > 0:
		var caja_antes := a.saldo + monto
		if float(monto) > 0.45 * float(caja_antes) + 1.0:
			_caja_ok = false
			_peor_gasto = "%s pagó %d por %s con %d en caja" % [a.nombre, monto, j.nombre, caja_antes]
	if j.club_id != a.id or not a.plantilla.has(j):
		_malo("%s no queda en %s tras ficharlo" % [j.nombre, a.nombre])
	if de != null and de.plantilla.has(j):
		_malo("%s sigue en %s tras venderlo" % [j.nombre, de.nombre])
	if j.anios_contrato < 1 or j.anios_contrato > Contratos.max_anios(j) or j.sueldo <= 0:
		_malo("%s firma %d años con sueldo %d" % [j.nombre, j.anios_contrato, j.sueldo])

func _integridad(m: Mundo, cuando: String) -> void:
	var visto := {}
	for c: Club in m.clubes.values():
		var porteros := 0
		for j: Jugador in c.plantilla:
			if visto.has(j.id):
				_malo("%s: %s está en %s y en %s" % [cuando, j.nombre, visto[j.id], c.nombre])
			visto[j.id] = c.nombre
			if j.club_id != c.id:
				_malo("%s: %s está en %s pero su club_id es «%s»" % [cuando, j.nombre, c.nombre, j.club_id])
			if j.anios_contrato < 0 or j.anios_contrato > Contratos.max_anios(j):
				_malo("%s: %s con %d años de contrato (edad %d)" % [cuando, j.nombre, j.anios_contrato, j.edad])
			if j.sueldo <= 0:
				_malo("%s: %s sin sueldo" % [cuando, j.nombre])
			porteros += 1 if j.pos == "POR" else 0
		if c.plantilla.size() < 16 or c.plantilla.size() > 34:
			_malo("%s: %s tiene %d jugadores" % [cuando, c.nombre, c.plantilla.size()])
		if porteros < 1:
			_malo("%s: %s sin portero" % [cuando, c.nombre])
	for j: Jugador in m.libres:
		if visto.has(j.id):
			_malo("%s: %s está libre y en %s" % [cuando, j.nombre, visto[j.id]])
		if j.club_id != "":
			_malo("%s: el libre %s tiene club_id «%s»" % [cuando, j.nombre, j.club_id])

func _reglas(m: Mundo) -> void:
	## FIFA RSTP art. 18.2: 5 años; 3 los menores de 18.
	var j: Jugador = m.ligas[1].clubes[2].plantilla[4]
	var edad := j.edad
	j.edad = 17
	var menor := Contratos.ajustar_anios(j, 5)
	j.edad = 25
	var mayor := Contratos.ajustar_anios(j, 9)
	var cero := Contratos.ajustar_anios(j, 0)
	j.edad = edad
	_comprobar(menor == 3 and mayor == 5 and cero >= 1, "ajustar_anios: menor 5 → %d (3), mayor 9 → %d (5), 0 → %d (≥ 1)" % [menor, mayor, cero])
	## Por debajo del 92 % de lo que pide, nunca firma (40 intentos: no es suerte).
	var destino: Club = m.ligas[1].clubes[5]
	var pide := m.mercado.ficha_que_pide(j, destino)
	var firmas := 0
	for i in 40:
		Azar.sembrar(100 + i)
		firmas += 1 if m.mercado.jugador_firma(j, destino, int(pide * 0.9), 3) else 0
	_comprobar(pide > 0 and firmas == 0, "nadie firma por el 90 %% de lo que pide (%d de 40; pide %d)" % [firmas, pide])
	var firmas_bien := 0
	for i in 40:
		Azar.sembrar(200 + i)
		firmas_bien += 1 if m.mercado.jugador_firma(j, destino, int(pide * 1.3), 3) else 0
	_comprobar(firmas_bien > 0, "pagando el 130 %% alguna vez firma (%d de 40)" % firmas_bien)
	## La IA no gasta más del 45 % de su caja (se decide aquí, antes del fichaje a mano de abajo).
	_comprobar(_caja_ok, "ningún club de la IA pagó un traspaso por encima del 45 %% de su caja (%s)" % _peor_gasto)
	m.mercado.traspaso.disconnect(_al_traspaso)
	## `fichar` mueve el dinero exacto y al jugador, sin estados a medias.
	var vendedor: Club = m.clubes[j.club_id]
	var cv := vendedor.saldo
	var cd := destino.saldo
	m.mercado.fichar(j, destino, 1_234_567, maxi(1, j.sueldo), 4)
	_comprobar(vendedor.saldo - cv == 1_234_567 and cd - destino.saldo == 1_234_567, "fichar: el vendedor cobra y el comprador paga exactamente el monto")
	_comprobar(j.club_id == destino.id and destino.plantilla.has(j) and not vendedor.plantilla.has(j) and j.anios_contrato == 4, "fichar: el jugador pasa entero al comprador con su contrato nuevo")

var _mi_id := ""
var _caja_ok := true
var _peor_gasto := "—"
