extends Node
## EL MANDO EN LAS PANTALLAS DEL PARTIDO, EN EL BANCO (17-11, Auditoría: «R2 o A confirma, Cuadrado o B vuelve y LB/RB cambian de pestaña», simulando
## eventos de mando). Con clubes de tres países: en la previa, LB/RB pasan de pestaña, R2 pulsa el botón con el foco y Cuadrado / B cierran la
## pestaña abierta; en la pausa R2 elige la fila con el foco y Cuadrado reanuda; en el descanso, en el resultado final y en los momentos, R2
## confirma y Cuadrado / B vuelven. El recorrido entero con la cruceta (sin pantalla, con fotogramas) está en `pruebas/auditoria_foco_partido.tscn`.

var fallos := 0

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

static func boton(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = true
	return e

static func r2(valor: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_TRIGGER_RIGHT
	e.axis_value = valor
	return e

static func cancelar() -> InputEventAction:
	var e := InputEventAction.new()
	e.action = "ui_cancel"
	e.pressed = true
	return e

## R2 apretado y soltado: el oyente de la pantalla `n`.
func _r2_sobre(n: Node) -> bool:
	var m: MandoMenuPartido = n.get_node_or_null("MandoMenuPartido")
	if m == null:
		return false
	var hecho := m.manejar(r2(1.0))
	m.manejar(r2(0.0))
	return hecho

func _cuadrado(n: Node) -> bool:
	var m: MandoMenuPartido = n.get_node_or_null("MandoMenuPartido")
	return m != null and m.manejar(boton(JOY_BUTTON_X))

func correr(padre: Node) -> int:
	for cfg: Array in [["URU", 4], ["NED", 8], ["KOR", 1]]:
		var m := Mundo.new()
		var ps: Array[String] = [String(cfg[0])]
		m.generar(ps, 830 + int(cfg[1]))
		var liga: Liga = m.ligas[0]
		m.tomar_el_mando(liga.clubes[int(cfg[1]) % liga.clubes.size()].id)
		var mio := m.mi_club()
		var rival: Club = liga.clubes[(int(cfg[1]) + 4) % liga.clubes.size()]
		var p := Partido.new(mio, rival)
		var clima := Clima.del_partido(mio.pais, m.semana, m.anio, mio.id + rival.id)
		_previa(padre, p, mio, liga, clima, String(cfg[0]))
		_pausa(padre, p, String(cfg[0]))
		p.preparar()
		while p.minuto < 45:
			p.simular_minuto()
		_descanso(padre, p, mio, String(cfg[0]))
		while not p.terminado_ya:
			p.simular_minuto()
		_final(padre, p, mio, String(cfg[0]))
	return fallos

func _previa(padre: Node, p: Partido, mio: Club, liga: Liga, clima: Dictionary, pais: String) -> void:
	var menu := MenuPartido.mostrar(padre, p, mio, liga, clima)
	_ok(menu.has_node("MandoMenuPartido"), "%s: la previa escucha el mando" % pais)
	menu._abrir("uniforme")
	menu._input(boton(JOY_BUTTON_RIGHT_SHOULDER))
	_ok(menu._abierta == PreviaMenuPartido.vecina("uniforme", 1), "%s: RB pasa a la pestaña siguiente (%s)" % [pais, menu._abierta])
	menu._input(boton(JOY_BUTTON_LEFT_SHOULDER))
	_ok(menu._abierta == "uniforme", "%s: LB vuelve a la anterior" % pais)
	_ok(_cuadrado(menu) and not menu._modal.visible, "%s: Cuadrado cierra la pestaña abierta y vuelve a la previa" % pais)
	menu._abrir("estadio")
	menu._unhandled_input(cancelar())
	_ok(not menu._modal.visible, "%s: B / Esc cierran la pestaña" % pais)
	var pulsado := [false]
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func() -> void: pulsado[0] = true)
	menu.add_child(b)
	b.grab_focus()
	_ok(_r2_sobre(menu) and pulsado[0], "%s: R2 pulsa el botón con el foco en la previa" % pais)
	menu.free()

func _pausa(padre: Node, p: Partido, pais: String) -> void:
	var v := VistaFalsa.new()
	padre.add_child(v)
	p.minuto = 61
	var pausa := MenuPausaPartido.abrir(v, p)
	var est: Button = null
	for bt in pausa.find_children("*", "Button", true, false):
		if String((bt as Button).text).contains(Idiomas.t("Estadísticas")):
			est = bt
	_ok(est != null, "%s: la pausa tiene «Estadísticas»" % pais)
	if est != null:
		est.grab_focus()
		_r2_sobre(pausa)
		_ok(v.llamado == "estadisticas", "%s: R2 elige la fila con el foco en la pausa (%s)" % [pais, v.llamado])
	var otra := MenuPausaPartido.abrir(v, p)
	_ok(_cuadrado(otra) and otra.is_queued_for_deletion(), "%s: Cuadrado reanuda (cierra la pausa)" % pais)
	v.free()

func _descanso(padre: Node, p: Partido, mio: Club, pais: String) -> void:
	DescansoPartido.en_pruebas = true
	var falso := _VivoFalso.new()
	falso.partido = p
	falso.mi_club = mio
	padre.add_child(falso)
	var d := DescansoPartido.mostrar(falso)
	DescansoPartido.en_pruebas = false
	_ok(d != null and d.has_node("MandoMenuPartido"), "%s: el descanso se abre y escucha el mando" % pais)
	if d != null:
		_enfocar_continuar(d)   ## en el juego lo hace `ResumenPartidoCine.botones` al fotograma siguiente; aquí no hay fotogramas
		_r2_sobre(d)
		_ok(falso.segunda, "%s: R2 sobre «Continuar» sale a la segunda parte" % pais)
		DescansoPartido.en_pruebas = true
		var otro := DescansoPartido.mostrar(falso)
		DescansoPartido.en_pruebas = false
		_ok(_cuadrado(otro) and otro.is_queued_for_deletion(), "%s: Cuadrado cierra el resumen del descanso (camarín y cambios)" % pais)
	falso.free()

func _enfocar_continuar(n: Node) -> void:
	for bt in n.find_children("*", "Button", true, false):
		if String((bt as Button).text).to_upper().contains(Idiomas.t("Continuar").to_upper()):
			(bt as Button).grab_focus()
			return
	_ok(false, "hay un botón «Continuar» en %s" % n.get_class())

class _VivoFalso extends Node:
	var partido: Partido
	var mi_club: Club
	var segunda := false
	func _salir_segunda() -> void: segunda = true

func _final(padre: Node, p: Partido, mio: Club, pais: String) -> void:
	var r := ResultadoPartido.mostrar(padre, p, mio)
	var salidas: Array = []
	r.elegido.connect(func(op: String) -> void: salidas.append(op))
	_ok(r.has_node("MandoMenuPartido"), "%s: el final escucha el mando" % pais)
	_enfocar_continuar(r)
	_r2_sobre(r)
	_ok(salidas == ["0"], "%s: R2 sobre «Continuar» sigue (%s)" % [pais, str(salidas)])
	_cuadrado(r)
	r._unhandled_input(cancelar())
	_ok(salidas == ["0", "0", "0"], "%s: Cuadrado y B también siguen desde el final (%s)" % [pais, str(salidas)])
	r.free()
	var mo := MomentosPartido.mostrar(padre, p, mio)
	var vuelta: Array = []
	mo.elegido.connect(func(op: String) -> void: vuelta.append(op))
	_cuadrado(mo)
	mo._unhandled_input(cancelar())
	_ok(vuelta == ["volver", "volver"], "%s: en los momentos, Cuadrado y B vuelven (%s)" % [pais, str(vuelta)])
	mo.free()
