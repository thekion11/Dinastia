extends Node
## EL MENÚ DEL PARTIDO Y LA PAUSA, EN EL BANCO (17-11, orden de «Auditoría de sesiones»). Con clubes de tres países: el menú monta sus seis pestañas, el
## sorteo del saque es estable por partido y lo que muestra la pestaña es lo que va a `partido.saca_local` al confirmar; la pausa tiene sus seis opciones
## (sin ajustes), cada una llama a lo suyo en la vista y «Simular el resto» pide una segunda pulsación (Cuadrado / Esc la cancelan).
## `correr(padre)` lo usa el banco (grupo «avance»); sin pantalla la previa usa la figura plana.

var fallos := 0

## Una vista de mentira con lo que la pausa llama.
class VistaFalsa extends Control:
	signal cerrado
	var llamado := ""
	func _abrir_panel_dt() -> void: llamado = "tactica"
	func abrir_estadisticas() -> void: llamado = "estadisticas"
	func abrir_controles() -> void: llamado = "controles"
	func _simular_resto_motor() -> void: llamado = "simular"
	func salir() -> void:
		llamado = "salir"
		cerrado.emit()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func correr(padre: Node) -> int:
	for cfg: Array in [["ARG", 2], ["ENG", 6], ["JPN", 9]]:
		var m := Mundo.new()
		var ps: Array[String] = [String(cfg[0])]
		m.generar(ps, 610 + int(cfg[1]))
		var liga: Liga = m.ligas[0]
		m.tomar_el_mando(liga.clubes[int(cfg[1])].id)
		var mio := m.mi_club()
		var rival: Club = liga.clubes[(int(cfg[1]) + 3) % liga.clubes.size()]
		var p := Partido.new(mio, rival)
		var clima := Clima.del_partido(mio.pais, m.semana, m.anio, mio.id + rival.id)
		var menu := MenuPartido.mostrar(padre, p, mio, liga, clima)
		_ok(menu.saca_local == MenuPartido.sorteo(p, "Liga", clima), "%s: el sorteo es estable para el mismo partido" % cfg[0])
		for tab: Array in MenuPartido.PESTANAS:
			menu._abrir(String(tab[0]))
			_ok(menu._cuerpo.get_child_count() > 0, "%s: la pestaña %s tiene contenido" % [cfg[0], tab[0]])
		_ok(PreviaMenuPartido.vecina("uniforme", -1) == "camara" and PreviaMenuPartido.vecina("saque", 1) == "opciones" and PreviaMenuPartido.vecina("", 1) == "uniforme",
			"%s: LB/RB pasan de pestaña en círculo y saltan «Plan de juego»" % cfg[0])
		menu._abrir("estadio")
		_ok(menu._titulo_modal.text != "" and menu._icono_modal.texture != null and menu._modal.visible, "%s: la pestaña a pantalla completa tiene su icono y su título" % cfg[0])
		menu._abrir("saque")
		var rotulo := menu._cuerpo.find_child("SacaClub", true, false) as Label
		var quien: Club = p.local if menu.saca_local else p.visita
		_ok(rotulo != null and rotulo.text == Idiomas.t("SACA %s") % quien.nombre.to_upper(), "%s: la pestaña muestra quién saca según el sorteo" % cfg[0])
		p.saca_local = not menu.saca_local
		menu.opcion = "jugar"
		menu.confirmar()
		_ok(p.saca_local == menu.saca_local, "%s: al confirmar, el partido guarda el sorteo mostrado" % cfg[0])
		menu.free()
		## LA PAUSA
		var v := VistaFalsa.new()
		padre.add_child(v)
		p.minuto = 30 + int(cfg[1])
		var pausa := MenuPausaPartido.abrir(v, p)
		var claves: Array = []
		for op: Array in MenuPausaPartido.OPCIONES:
			claves.append(String(op[0]))
		_ok(claves == ["reanudar", "tactica", "estadisticas", "controles", "simular", "salir"], "%s: la pausa tiene sus seis opciones y ningún ajuste" % cfg[0])
		var sim := pausa.find_child("simular", true, false) as Button
		sim.pressed.emit()
		_ok(v.llamado == "" and is_instance_valid(pausa) and not pausa.is_queued_for_deletion(), "%s: «Simular el resto» pide confirmación" % cfg[0])
		_ok(pausa.cancelar_confirmacion() and sim.text == Idiomas.t("Simular el resto"), "%s: la confirmación se cancela" % cfg[0])
		sim.pressed.emit()
		sim.pressed.emit()
		_ok(v.llamado == "simular" and pausa.is_queued_for_deletion(), "%s: con la segunda pulsación simula y la pausa se cierra" % cfg[0])
		for par: Array in [["tactica", "tactica"], ["estadisticas", "estadisticas"], ["controles", "controles"], ["salir", "salir"], ["reanudar", ""]]:
			v.llamado = ""
			var pz := MenuPausaPartido.abrir(v, p)
			(pz.find_child(String(par[0]), true, false) as Button).pressed.emit()
			_ok(v.llamado == String(par[1]) and pz.is_queued_for_deletion(), "%s: «%s» llama a lo suyo y cierra la pausa" % [cfg[0], par[0]])
		v.free()
	_montar_y_desmontar(padre)
	return fallos

## (17-11, Auditoría) Las fotos del estadio montan el estadio real y lo desmontan: no puede quedar ni un nodo (ni huérfano) de más.
func _montar_y_desmontar(padre: Node) -> void:
	for pais: String in ["ARG", "ESP"]:
		var m := Mundo.new()
		var ps: Array[String] = [pais]
		m.generar(ps, 640)
		var c: Club = m.ligas[0].clubes[1]
		var nodos := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		var huerfanos := _huerfanos_vivos()
		var vp := SubViewport.new()
		vp.own_world_3d = true
		padre.add_child(vp)
		var raiz := Node3D.new()
		vp.add_child(raiz)
		FotosEstadioMenu.montar_estadio(raiz, c, c.perfil_estadio(), pais == "ESP", null)
		var montado := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		vp.free()
		_ok(montado > nodos + 50, "%s: se montó el estadio (%d nodos)" % [pais, int(montado - nodos)])
		_ok(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) == nodos and _huerfanos_vivos() == huerfanos,
			"%s: al desmontar no queda ningún nodo de más (%d) ni huérfano vivo (%d)" % [pais, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) - nodos),
			_huerfanos_vivos() - huerfanos])

## Los nodos fuera del árbol que NO están ya en cola de borrado (las piezas que la mascota funde se quitan con `queue_free`: se van al acabar el cuadro).
func _huerfanos_vivos() -> int:
	var n := 0
	for id in Node.get_orphan_node_ids():
		var o = instance_from_id(id)
		if o is Node and not (o as Node).is_queued_for_deletion():
			n += 1
	return n
