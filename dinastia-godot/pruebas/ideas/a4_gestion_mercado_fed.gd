extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 CRUZADO: MERCADO SATURADO y FEDERACIÓN al límite.
##   1. Mercado: 200 compradores por semana durante 40 semanas (antes 6): nadie duplicado, planteles de la IA entre 19 y 26 (el propio no se toca),
##      ningún cedido traspasado, ningún saldo no entero, y los fichajes pasan (hay mercado).
##   2. Federación: TODAS las mociones votadas en cualquier opción con asambleas de 0, 1 y 20 clubes; casos de disciplina con fechas 0/negativas/enormes y sin jugador;
##      antidopaje con plantel vacío; playoffs con tablas de 0, 3, 4 y con filas rotas. Sin error ni estado roto (pendiente vaciado, casos ≤ MAX_CASOS).

func _probar() -> void:
	_titulo("A4 CRUZADO (gestión): mercado saturado y federación al límite")
	await _mercado(202)
	_federacion(303)

func _nuevo(semilla: int) -> Mundo:
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI", "ARG"]
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	return m

func _mercado(semilla: int) -> void:
	var m := _nuevo(semilla)
	var hechos := 0
	var cedidos: Array[String] = []
	for j: Jugador in m.mi_club().plantilla.slice(0, 3):
		var r: Dictionary = m.cesiones.ceder_canterano(j)
		if not r.has("error") and not r.is_empty():
			cedidos.append(j.id)
	var ubic0 := {}
	for pid in cedidos:
		ubic0[pid] = (m.cesiones._localizar(pid)[1] as Club).id
	for sem in 40:
		hechos += m.mercado.mover(200).size()
		m.avanzar_semana()
		if sem % 10 == 9:
			await get_tree().process_frame
	var vistos := {}
	var dup := 0
	var fuera := 0
	var no_entero := 0
	for c: Club in m.clubes.values():
		if not (c.saldo is int):
			no_entero += 1
		if c.id != m.mi_club_id and (c.plantilla.size() < 19 or c.plantilla.size() > 26):
			fuera += 1
		for j in c.plantilla:
			if vistos.has(j.id):
				dup += 1
			vistos[j.id] = true
	for j in m.libres:
		if vistos.has(j.id):
			dup += 1
	var movidos := 0
	for pid in cedidos:
		if m.cesiones.esta_cedido(pid) and (m.cesiones._localizar(pid)[1] as Club).id != ubic0[pid]:
			movidos += 1
	_comprobar(hechos > 100, "el mercado saturado mueve jugadores (%d traspasos en 40 semanas)" % hechos)
	_comprobar(dup == 0, "nadie duplicado tras el mercado saturado (%d)" % dup)
	_comprobar(fuera == 0, "planteles de la IA entre 19 y 26 (%d clubes fuera de rango)" % fuera)
	_comprobar(movidos == 0, "ningún cedido vivo traspasado a otro club (%d)" % movidos)
	_comprobar(no_entero == 0, "saldos enteros (%d)" % no_entero)

func _federacion(semilla: int) -> void:
	var m := _nuevo(semilla)
	var f := m.federacion
	var mi := m.mi_club()
	var asambleas := [[], [mi], m.clubes.values().slice(0, 20)]
	var n := 0
	var catalogo_n := f.catalogo().size()
	for opcion in ["a", "b", "zzz", ""]:
		for asam in asambleas:
			f.voto_pendiente = {}
			var libres := f.catalogo().filter(func(v: Dictionary) -> bool: return not f.votos.any(func(x: Dictionary) -> bool: return String(x.get("id")) == String(v.get("id"))))
			if libres.is_empty():
				continue
			f.voto_pendiente = (libres[0] as Dictionary).duplicate()
			var r := f.votar(opcion, mi, asam)
			n += 1
			_comprobar(f.voto_pendiente.is_empty(), "votar «%s» con asamblea de %d: la votación queda cerrada (%s)" % [opcion, asam.size(), str(r.get("pasa"))])
	_comprobar(f.votos.size() <= catalogo_n + 4, "el historial de votos no se desborda (%d de %d mociones)" % [f.votos.size(), catalogo_n])
	_comprobar(f.votar("a", null, []).is_empty(), "votar sin club no hace nada")
	var j: Jugador = mi.plantilla[0]
	for fechas in [0, -3, 5, 100000]:
		f.abrir_caso("roja", j, fechas, "prueba", m.anio, 1)
	f.abrir_caso("club", null, 3, "sin jugador", m.anio, 1)
	for i in 80:
		f.abrir_caso("roja", j, 1, "relleno", m.anio, i)
	_comprobar(f.casos.size() <= Federacion.MAX_CASOS, "casos de disciplina acotados (%d)" % f.casos.size())
	_comprobar(j.suspension >= 0, "suspensión no negativa (%d)" % j.suspension)
	var vacio := Club.new()
	_comprobar(f.control_antidopaje(vacio, m.anio, 1).is_empty(), "antidopaje con plantel vacío no hace nada")
	f.control_antidopaje(null, m.anio, 1)
	f.playoffs = true
	var tabla: Array = m.ligas[0].tabla()
	for tam in [0, 3, 4, 8]:
		var t := tabla.slice(0, tam)
		var camp = f.campeon_de_liga(t, m.anio, mi.id)
		_comprobar(tam == 0 or camp != null, "campeón con tabla de %d filas (%s)" % [tam, str(camp.nombre if camp != null else null)])
	var rota: Array = [{"id": "no existe"}, {"id": "no existe"}, {"id": "x"}, {"id": "y"}]
	_comprobar(f.jugar_playoffs(rota, m.anio, mi.id).is_empty(), "playoffs con filas de clubes que no existen: vacío, sin error")
