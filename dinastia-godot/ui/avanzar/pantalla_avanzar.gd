class_name PantallaAvanzar
extends EventoPantallaCompleta
## LA PANTALLA «AVANZAR» (paso 3, 17-11-2026): reemplaza el avance por semanas. Un calendario de DOS SEMANAS (14 días) por el que corre el cursor con el escudo
## de tu club, día a día, hasta el primer día con eventos (`AvanceDias`). El calendario cambia de mes solo (cada celda trae su fecha). Los adornos salen SOLO
## cuando el cursor está sobre un día de evento, unos segundos: el rótulo con su clase (partido / importante / aviso), un símbolo en la celda (escudo del rival
## en los partidos, ★ en lo importante, 🔔 en los avisos) y el texto de cada evento. Cualquier tecla o clic salta la animación; otra vez cierra.
## Emite `cerrado` con el resultado de `AvanceDias.avanzar`. La pantalla NO corre la semana: eso lo hace `AvanceDiasUI` con `rodar` antes de abrirla.

signal cerrado

const CELDAS := 14
const PASO := 0.16        ## s por día recorrido
const DECORADO := 2.4     ## s que se queda el rótulo en un día de evento

var _m: Mundo
var _res: Dictionary
var _unix0 := 0
var _celdas: Array = []     ## [{panel, num, mes, simbolo, cursor}]
var _rotulo: PanelContainer
var _fecha: Label
var _idx := 0
var _fase := 0              ## 0 = corriendo, 1 = rótulo a la vista, 2 = cerrada
var _tween: Tween

## `unix0`: la fecha de PARTIDA (antes de avanzar); `res`: lo que devolvió `AvanceDias.avanzar`.
static func mostrar(pr: Node, m: Mundo, unix0: int, res: Dictionary) -> PantallaAvanzar:
	var s := PantallaAvanzar.new()
	s.paleta_noche = true
	s.acento = AvanzarTextos.COLOR_PANTALLA
	s._m = m
	s._res = res
	s._unix0 = unix0
	s._montar_base(pr)
	s._rellenar()
	s._correr.call_deferred()
	return s

func _rellenar() -> void:
	_centro.custom_minimum_size = Vector2(ancho_base(1040.0), 0)
	_centro.add_theme_constant_override("separation", 18)
	var club := _m.mi_club()
	var cab := HBoxContainer.new()
	cab.alignment = BoxContainer.ALIGNMENT_CENTER
	cab.add_theme_constant_override("separation", 14)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(club, 56)
	esc.custom_minimum_size = Vector2(56, 56)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab.add_child(esc)
	cab.add_child(etiqueta(Idiomas.t("AVANZANDO EN EL TIEMPO"), 16, Color(1, 1, 1, 0.7), true, false))
	_centro.add_child(cab)
	_fecha = etiqueta("", 40, Color.WHITE, true, false)
	_centro.add_child(_fecha)
	var tira := HBoxContainer.new()
	tira.alignment = BoxContainer.ALIGNMENT_CENTER
	tira.add_theme_constant_override("separation", 6)
	_centro.add_child(tira)
	for i in CELDAS:
		var c := _celda()
		tira.add_child(c["panel"])
		_celdas.append(c)
	_rotulo = PanelContainer.new()
	_rotulo.custom_minimum_size = Vector2(ancho_base(760.0), 120)
	_rotulo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_rotulo.modulate.a = 0.0
	_centro.add_child(_rotulo)
	_pintar_ventana(0)

func _celda() -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(ancho_base(1040.0) / CELDAS - 6.0, 150)
	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 2)
	panel.add_child(caja)
	var dia := etiqueta("", 12, Color(1, 1, 1, 0.55))
	var num := etiqueta("", 26, Color.WHITE)
	var mes := etiqueta("", 11, Color(1, 1, 1, 0.45))
	var simbolo := Control.new()
	simbolo.custom_minimum_size = Vector2(0, 34)
	var hueco := Control.new()   ## el cursor (escudo de tu club) tiene su sitio fijo: las celdas no cambian de alto
	hueco.custom_minimum_size = Vector2(0, 34)
	var cursor := TextureRect.new()
	cursor.texture = Escudo.textura(_m.mi_club(), 40)
	cursor.set_anchors_preset(Control.PRESET_FULL_RECT)
	cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cursor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cursor.visible = false
	hueco.add_child(cursor)
	for n: Control in [dia, num, mes, hueco, simbolo]:
		caja.add_child(n)
	return {"panel": panel, "dia": dia, "num": num, "mes": mes, "simbolo": simbolo, "cursor": cursor}

## Pinta la ventana de 14 días que empieza `inicio` días después de la fecha de partida. El mes se rotula en el primer día de cada mes (cambia solo).
func _pintar_ventana(inicio: int) -> void:
	for j in CELDAS:
		var f := Time.get_datetime_dict_from_unix_time(_unix0 + (inicio + j) * 86400)
		var c: Dictionary = _celdas[j]
		(c["dia"] as Label).text = Idiomas.t(String(Principal.DIAS_LARGOS[(int(f["weekday"]) + 6) % 7])).left(1).to_upper()
		(c["num"] as Label).text = str(int(f["day"]))
		(c["mes"] as Label).text = Idiomas.t(String(Principal.MESES_LARGOS[int(f["month"]) - 1])).left(3) if (j == 0 or int(f["day"]) == 1) else ""
		var panel: PanelContainer = c["panel"]
		var sb := Tema.caja(Color(1, 1, 1, 0.07), 8)
		panel.add_theme_stylebox_override("panel", sb)
		(c["cursor"] as TextureRect).visible = false
		for h in (c["simbolo"] as Control).get_children():
			h.queue_free()

func _correr() -> void:
	var pasados: Array = _res["pasados"]
	if pasados.is_empty():
		_cerrar()
		return
	_tween = create_tween()
	for i in pasados.size():
		_tween.tween_callback(_mover.bind(i + 1))
		_tween.tween_interval(0.0 if Animar.reducidas() else PASO)
	_tween.tween_callback(_llegar)

## El cursor está en el día `i` (1 = el primero que se recorre; 0 sería la fecha de partida).
func _mover(i: int) -> void:
	if _fase != 0:
		return
	_idx = i
	var inicio := maxi(i - 3, 0)
	_pintar_ventana(inicio)
	var j := i - inicio
	var c: Dictionary = _celdas[j]
	(c["cursor"] as TextureRect).visible = true
	(c["panel"] as PanelContainer).add_theme_stylebox_override("panel", _marco(Color(Tema.ORO, 0.9), 3))
	var f := Time.get_datetime_dict_from_unix_time(_unix0 + i * 86400)
	_fecha.text = "%s · %d %s %d" % [Idiomas.t(String(Principal.DIAS_LARGOS[(int(f["weekday"]) + 6) % 7])), int(f["day"]),
		Idiomas.t(String(Principal.MESES_LARGOS[int(f["month"]) - 1])), int(f["year"])]

func _marco(col: Color, grosor: int) -> StyleBoxFlat:
	var sb := Tema.caja(Color(col, 0.16), 8)
	sb.border_color = col
	sb.set_border_width_all(grosor)
	return sb

func _llegar() -> void:
	if _fase != 0:
		return
	_fase = 1
	var evs: Array = _res["eventos"]
	var plan: Dictionary = _res["plan"]
	var j := _idx - maxi(_idx - 3, 0)
	var celda: Dictionary = _celdas[j]
	var sim := celda["simbolo"] as Control
	for h in sim.get_children():
		h.queue_free()
	var clase := EventosDia.PARTIDO if not (plan["partido"] as Dictionary).is_empty() else (EventosDia.PANTALLA if not (plan["pantallas"] as Array).is_empty() else EventosDia.AVISO)
	var col := AvanzarTextos.clase_color(clase)
	(celda["panel"] as PanelContainer).add_theme_stylebox_override("panel", _marco(col, 3))
	if clase == EventosDia.PARTIDO and (plan["partido"] as Dictionary).get("rival") is Club:
		var r := TextureRect.new()
		r.texture = Escudo.textura((plan["partido"] as Dictionary)["rival"] as Club, 40)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.set_anchors_preset(Control.PRESET_FULL_RECT)
		sim.add_child(r)
		(celda["cursor"] as TextureRect).visible = false
	else:
		var l := etiqueta("★" if clase == EventosDia.PANTALLA else "🔔", 22, col)
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		sim.add_child(l)
	_armar_rotulo(evs, clase, col)
	var tw := create_tween()
	tw.tween_property(_rotulo, "modulate:a", 1.0, 0.0 if Animar.reducidas() else 0.35)
	tw.tween_interval(0.0 if Animar.reducidas() else DECORADO)
	tw.tween_callback(_cerrar)
	_tween = tw

func _armar_rotulo(evs: Array, clase: String, col: Color) -> void:
	for h in _rotulo.get_children():
		h.queue_free()
	_rotulo.add_theme_stylebox_override("panel", _marco(col, 2))
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 4)
	_rotulo.add_child(caja)
	var cab: String = {EventosDia.PARTIDO: "DÍA DE PARTIDO", EventosDia.PANTALLA: "EVENTO IMPORTANTE"}.get(clase, "AVISO")
	caja.add_child(etiqueta(Idiomas.t(cab), 13, col))
	for k in mini(evs.size(), 4):
		var ev: Dictionary = evs[k]
		caja.add_child(etiqueta("%s  %s" % [AvanzarTextos.icono(ev), AvanzarTextos.titulo(ev)], 22, Color.WHITE, false))
		var t := AvanzarTextos.texto(ev)
		if t != "":
			caja.add_child(etiqueta(t, 15, Color(1, 1, 1, 0.75), false))

func _input(e: InputEvent) -> void:
	if _fase == 2:
		return
	var pulsa: bool = (e is InputEventKey and e.pressed and not e.echo) or (e is InputEventMouseButton and e.pressed) or e.is_action_pressed("ui_accept") or e.is_action_pressed("ui_cancel")
	if not pulsa:
		return
	get_viewport().set_input_as_handled()
	if _fase == 0:
		if _tween != null:
			_tween.kill()
		_mover((_res["pasados"] as Array).size())
		_llegar()
	else:
		_cerrar()

func _cerrar() -> void:
	if _fase == 2:
		return
	_fase = 2
	if _tween != null:
		_tween.kill()
	cerrado.emit()
