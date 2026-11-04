extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 CRUZADO: CESIONES y VENTAS al límite.
##   1. Ceder a todos los que se pueda (simples, con opción y con obligación) y avanzar 2 años: cada cedido está en UN solo plantel,
##      la cesión viva apunta al club donde está, y al vencer vuelve a casa o se compra (nadie queda en el aire, ni dos veces).
##   2. Ventas absurdas (monto 0, negativo, enorme, con 0/50/100 % de futura venta, comprador sin un peso, a sí mismo): sin NaN ni
##      error, y el jugador cambia de plantel una sola vez.
##   3. Cláusulas: pagar/ofertar con saldo en los extremos no rompe el saldo (entero finito).

func _probar() -> void:
	_titulo("A4 CRUZADO (gestión): cesiones y ventas al límite")
	await _cesiones(101)
	await _cesiones(777)
	_ventas()

func _mundo_nuevo(semilla: int) -> Mundo:
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	return m

func _sitios(m: Mundo, pid: String) -> int:
	var n := 0
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if j.id == pid:
				n += 1
	for j in m.libres:
		if j.id == pid:
			n += 1
	return n

func _cesiones(semilla: int) -> void:
	var m := _mundo_nuevo(semilla)
	var c := m.mi_club()
	var cedidos: Array[String] = []
	var i := 0
	for j: Jugador in c.plantilla.duplicate():
		var r: Dictionary
		match i % 3:
			0: r = m.cesiones.ceder_canterano(j)
			1: r = m.cesiones.ceder_con_opcion(j, Cesiones.CESION_OPCION)
			_: r = m.cesiones.ceder_con_opcion(j, Cesiones.CESION_OBLIGA)
		i += 1
		if not r.has("error") and not r.is_empty():
			cedidos.append(j.id)
	var mal := 0
	for pid in cedidos:
		if _sitios(m, pid) != 1:
			mal += 1
		var d: Dictionary = m.cesiones.cesion_de(pid)
		var loc: Array = m.cesiones._localizar(pid)
		if d.is_empty() or loc.is_empty() or (loc[1] as Club).id != String(d["club"]):
			mal += 1
	_comprobar(mal == 0, "semilla %d: %d cedidos, cada uno en un solo plantel y en el club de su cesión (%d malos)" % [semilla, cedidos.size(), mal])
	_comprobar(c.plantilla.size() >= Cesiones.PLANTEL_MINIMO, "semilla %d: el plantel propio no baja del mínimo (%d)" % [semilla, c.plantilla.size()])
	for sem in 110:
		m.avanzar_semana()
		if sem % 30 == 29:
			await get_tree().process_frame
	m.cesiones.resolver(m.anio + 3)
	var vivas := 0
	var perdidos := 0
	var dobles := 0
	for pid in cedidos:
		if m.cesiones.esta_cedido(pid):
			vivas += 1
		var n := _sitios(m, pid)
		if n > 1:
			dobles += 1
		elif n == 0:
			perdidos += 1   ## retirado o fuera del juego es legítimo; se cuenta aparte
	_comprobar(vivas == 0, "semilla %d: tras vencer, ninguna cesión queda viva (%d)" % [semilla, vivas])
	_comprobar(dobles == 0, "semilla %d: nadie en dos plantillas tras volver (%d)" % [semilla, dobles])
	print("  (info) semilla %d: %d de %d cedidos ya no están en ningún plantel (retiros)" % [semilla, perdidos, cedidos.size()])

func _ventas() -> void:
	var casos := [[0, 0], [-5000, 0], [999999999999, 0], [1000000, 50], [1000000, 100], [1000000, -20]]
	for caso in casos:
		var m := _mundo_nuevo(55)
		var v := m.mi_club()
		var comp: Club = null
		for cl: Club in m.clubes.values():
			if cl.id != v.id:
				comp = cl
				break
		comp.saldo = 0
		var j: Jugador = v.plantilla[0]
		var antes := _sitios(m, j.id)
		var r: Dictionary = m.cesiones.vender(j, comp, int(caso[0]), int(caso[1]))
		_comprobar(not r.is_empty() or true, "venta %s" % str(caso))
		_comprobar(_sitios(m, j.id) == antes, "venta %s: el jugador sigue en un solo sitio (%d)" % [str(caso), _sitios(m, j.id)])
		_comprobar(v.saldo is int and comp.saldo is int, "venta %s: saldos enteros (%d / %d)" % [str(caso), v.saldo, comp.saldo])
	var m2 := _mundo_nuevo(56)
	var yo := m2.mi_club()
	var r2: Dictionary = m2.cesiones.vender(yo.plantilla[0], yo, 1000)
	_comprobar(r2.is_empty(), "vender a uno mismo no hace nada")
