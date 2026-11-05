extends BaseSO
## INTEGRACIÓN · el recorrido de punta a punta, con el código real y sin atajos de datos: mundo → menú principal real montado → varias
## semanas con sus partidos y resultados → guardar → cargar → mismo estado (tabla de la liga, caja, semana) → la partida cargada sigue
## jugando igual que la que no se guardó (determinismo tras cargar). Es la prueba de que "guardar y seguir" no cambia el futuro.
func _nombre() -> String:
	return "int_flujo_menu_a_guardado"

const RANURA := "prueba_so_flujo"

func _huella(m: Mundo) -> String:
	var partes: Array[String] = []
	for l: Liga in m.ligas:
		for f: Dictionary in l.tabla():
			partes.append("%s:%d:%d:%d" % [(f["club"] as Club).id, f["pts"], f["gf"], f["gc"]])
	partes.append("saldo:%d:semana:%d:%d" % [m.mi_club().saldo, m.anio, m.semana])
	return "\n".join(partes).md5_text()

func _probar() -> void:
	_titulo("INTEGRACIÓN · menú → partidos → guardado → carga [%s]" % sistema())
	_respaldar_user()
	var m := _mundo(20261105)
	PedidoPartida.mundo_pregenerado = m
	var p: Node = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _frames(8)
	for t in get_tree().root.find_children("*", "Tutorial", true, false):
		(t as Tutorial)._terminar(false)
	_comprobar(p.is_inside_tree() and get_tree().root.find_children("*", "Button", true, false).size() > 5, "el menú principal real se monta con botones")
	for i in 6:
		m.avanzar_semana()
	var pj := 0
	for f: Dictionary in m.ligas[0].tabla():
		pj += int(f["pj"])
	_comprobar(pj > 0, "tras 6 semanas la liga tiene partidos jugados (%d)" % pj)
	var h0 := _huella(m)
	Partida.borrar(RANURA)
	var estado_azar := str(Azar._rng.state)
	_comprobar(Partida.guardar(m, RANURA), "guardar")
	for i in 7:
		Azar.f()   ## se gasta azar: el estado guardado ya no es el de ahora
	_comprobar(str(Azar._rng.state) != estado_azar, "gastar azar cambia el estado (la comprobación de abajo no es vacía)")
	var n := Partida.cargar(RANURA)
	_comprobar(str(Azar._rng.state) == estado_azar, "cargar devuelve el ESTADO del azar que había al guardar")
	_comprobar(n != null, "cargar")
	if n != null:
		_comprobar(_huella(n) == h0, "lo cargado es idéntico a lo guardado (tabla, caja, fecha)")
		## El futuro: el azar es uno solo para todo el juego (autoload) y `cargar` lo deja como estaba al guardar; por eso se juega
		## primero la partida que siguió sin guardar y después se vuelve a cargar y se juega la cargada: salen las mismas 4 semanas.
		var h_sigue: Array[String] = []
		for i in 4:
			m.avanzar_semana()
			h_sigue.append(_huella(m))
		n = Partida.cargar(RANURA)
		var h_carga: Array[String] = []
		for i in 4:
			n.avanzar_semana()
			h_carga.append(_huella(n))
		_comprobar(h_sigue[0] != h0, "esas semanas cambian algo (la prueba no es vacía)")
		_comprobar(h_carga == h_sigue, "las 4 semanas siguientes a cargar salen IGUAL que sin guardar (antes del 5-11 divergían desde la 2.ª: la fase de grupos del continental no se guardaba)")
		## La fase de grupos del continental sobrevive al guardado (grupos, tabla y clasificados).
		var con_grupos := 0
		var iguales := 0
		for k: String in m.continentales:
			var t0: Continental = m.continentales[k]
			var t1: Continental = n.continentales.get(k)
			if t1 == null or not t0.por_grupos:
				continue
			con_grupos += 1
			var a0 := t0.grupos_a_dic()
			var a1 := t1.grupos_a_dic()
			iguales += int(JSON.stringify(a0) == JSON.stringify(a1) or (t0.fecha > 0 and JSON.stringify(a0["grupos"]) == JSON.stringify(a1["grupos"])))
		_comprobar(con_grupos >= 1, "el mundo tiene torneos continentales con fase de grupos (%d)" % con_grupos)
		_comprobar(iguales == con_grupos, "los grupos de los continentales cargados son los mismos que los de la partida que siguió (%d de %d)" % [iguales, con_grupos])
	Partida.borrar(RANURA)
	p.queue_free()
	await _frames(3)
	_restaurar_user()
