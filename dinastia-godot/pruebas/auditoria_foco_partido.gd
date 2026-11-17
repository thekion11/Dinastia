extends "res://pruebas/auditoria_foco_mando.gd"
## AUDITORÍA DEL MANDO EN LAS PANTALLAS DEL PARTIDO (17-11-2026, Auditoría). Con la pantalla principal y un mando simulado (`FocoMando.forzar`), recorre con
## la CRUCETA (pulsaciones reales por `Input.parse_input_event`) la previa, sus pestañas, el plan de juego, la pausa, el descanso, el resultado final y
## los momentos, con las mismas reglas que `auditoria_foco_mando`: al entrar hay foco visible DENTRO de la pantalla, 30 pulsaciones sin perderlo
## (sin trampas de foco) y desde el primero se llega a la mayoría. Además, con eventos reales: LB/RB cambian de pestaña y Cuadrado vuelve.
##   godot --headless --path . res://pruebas/auditoria_foco_partido.tscn

class VistaFalsa extends Control:
	signal cerrado
	func _abrir_panel_dt() -> void: pass
	func abrir_estadisticas() -> void: pass
	func abrir_controles() -> void: pass
	func _simular_resto_motor() -> void: pass
	func salir() -> void: cerrado.emit()

class VivoFalso extends Node:
	var partido: Partido
	var mi_club: Club
	func _salir_segunda() -> void: pass

func _ready() -> void:
	FocoMando.forzar = true
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 90:
		await get_tree().process_frame
	await _cerrar_eventos()
	var mundo: Mundo = _p.mundo
	var mio := mundo.mi_club()
	var liga: Liga = mundo.liga_de(mio) if mundo.has_method("liga_de") else mundo.ligas[0]
	var rival: Club = liga.clubes[0] if liga.clubes[0] != mio else liga.clubes[1]
	var p := Partido.new(mio, rival)
	var clima := Clima.del_partido(mio.pais, mundo.semana, mundo.anio, mio.id + rival.id)
	await _previa(p, mio, liga, clima)
	await _pausa(p)
	p.preparar()
	while p.minuto < 45:
		p.simular_minuto()
	await _descanso(p, mio)
	while not p.terminado_ya:
		p.simular_minuto()
	await _final(p, mio)
	print("RESUMEN")
	for r: String in _resumen:
		print("  " + r)
	print("===== FIN. %d fallos =====" % _fallos)
	FocoMando.forzar = false
	get_tree().quit(0 if _fallos == 0 else 1)

func _previa(p: Partido, mio: Club, liga: Liga, clima: Dictionary) -> void:
	var menu := MenuPartido.mostrar(_p, p, mio, liga, clima)
	await _auditar("previa", menu, true)
	for par: Array in MenuPartido.PESTANAS:
		var tab := String(par[0])
		if tab == "plan":
			continue
		menu._abrir(tab)
		await _auditar("previa: " + tab, menu, true)   ## la pestaña tapa la previa; la barra de pestañas y «Confirmar» siguen a la vista (son de la pantalla)
		_comprobar(_foco() != null and (menu._modal.is_ancestor_of(_foco()) or _foco() is Button), "[previa: %s] el foco cae en la pestaña o en su botón" % tab)
	menu._abrir("uniforme")
	await get_tree().process_frame
	await _pulsar(JOY_BUTTON_RIGHT_SHOULDER)
	_comprobar(menu._abierta == PreviaMenuPartido.vecina("uniforme", 1), "[previa] RB (evento real) pasa a la pestaña siguiente (%s)" % menu._abierta)
	await _pulsar(JOY_BUTTON_LEFT_SHOULDER)
	_comprobar(menu._abierta == "uniforme", "[previa] LB (evento real) vuelve a la anterior")
	await _pulsar(JOY_BUTTON_X)
	_comprobar(not menu._modal.visible, "[previa] Cuadrado (evento real) cierra la pestaña")
	## EL PLAN DE JUEGO: su propia pantalla (espera a los retratos hasta 4 s)
	menu._abrir("plan")
	var t0 := Time.get_ticks_msec()
	var pm: PantallaMenu = null
	while Time.get_ticks_msec() - t0 < 8000 and pm == null:
		await get_tree().process_frame
		for n in _p.find_children("*", "PantallaMenu", true, false):
			if (n as PantallaMenu).is_visible_in_tree() and not (n as PantallaMenu).cerrando():
				pm = n
	_comprobar(pm != null, "[plan] se abre desde la previa")
	if pm != null:
		await _auditar("plan de juego", pm, true)
		await _pulsar(JOY_BUTTON_X)
		await _pulsar(JOY_BUTTON_X)
		for i in 20:
			await get_tree().process_frame
		_comprobar(pm.cerrando() or not pm.is_visible_in_tree(), "[plan] Cuadrado (detalle → portada → previa) vuelve a la previa")
		_comprobar(menu.visible, "[plan] al volver se ve otra vez la previa")
	menu.queue_free()
	await get_tree().process_frame

func _pausa(p: Partido) -> void:
	var v := VistaFalsa.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p.add_child(v)
	p.minuto = 58
	var pausa := MenuPausaPartido.abrir(v, p)
	await _auditar("pausa", pausa, true)
	await _pulsar(JOY_BUTTON_X)
	_comprobar(not is_instance_valid(pausa) or pausa.is_queued_for_deletion(), "[pausa] Cuadrado (evento real) reanuda")
	v.queue_free()
	await get_tree().process_frame

func _descanso(p: Partido, mio: Club) -> void:
	var vivo := VivoFalso.new()
	vivo.partido = p
	vivo.mi_club = mio
	_p.add_child(vivo)
	DescansoPartido.en_pruebas = true
	var d := DescansoPartido.mostrar(vivo)
	DescansoPartido.en_pruebas = false
	await _auditar("descanso", d._raiz, true)
	await _pulsar(JOY_BUTTON_X)
	_comprobar(not is_instance_valid(d) or d.is_queued_for_deletion(), "[descanso] Cuadrado (evento real) cierra el resumen")
	vivo.queue_free()
	await get_tree().process_frame

func _final(p: Partido, mio: Club) -> void:
	var r := ResultadoPartido.mostrar(_p, p, mio)
	var salidas: Array = []
	r.elegido.connect(func(op: String) -> void: salidas.append(op))
	await _auditar("resultado final", r._raiz, true)
	await _pulsar(JOY_BUTTON_X)
	_comprobar(salidas.has("0"), "[final] Cuadrado (evento real) sigue")
	r.queue_free()
	var mo := MomentosPartido.mostrar(_p, p, mio)
	var vuelta: Array = []
	mo.elegido.connect(func(op: String) -> void: vuelta.append(op))
	await _auditar("momentos", mo._raiz, true)
	await _pulsar(JOY_BUTTON_X)
	_comprobar(vuelta.has("volver"), "[momentos] Cuadrado (evento real) vuelve")
	mo.queue_free()
	await get_tree().process_frame
