class_name ExamenLicencia
extends Control
## EL EXAMEN DE LA LICENCIA (26-9-2026, plan maestro C7): una pregunta cada vez,
## tres respuestas, y al final la nota. Las preguntas y la corrección son de
## `Licencia`; esto solo las presenta.

signal cerrado

var _mundo: Mundo
var _preguntas: Array = []
var _respuestas: Array = []
var _i := 0
var _caja: VBoxContainer

static func mostrar(padre: Control, mundo: Mundo) -> ExamenLicencia:
	var n := ExamenLicencia.new()
	n._mundo = mundo
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

func _montar() -> void:
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.8)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.ACENTO))
	panel.custom_minimum_size = Vector2(620, 0)
	centro.add_child(panel)
	_caja = VBoxContainer.new()
	_caja.add_theme_constant_override("separation", Tema.ESPACIO)
	panel.add_child(_caja)
	_preguntas = _mundo.licencia.examen()
	_pintar()

func _pintar() -> void:
	for h in _caja.get_children():
		h.queue_free()
	var objetivo: String = Licencia.NIVELES[_mundo.licencia.nivel + 1]
	if _i >= _preguntas.size():
		var r := _mundo.licencia.corregir(_preguntas, _respuestas, _mundo.anio, _mundo.semana, _mundo.roles, _mundo.prensa)
		_caja.add_child(Tema.rotulo("🎓 Examen · %s" % objetivo))
		var t := Tema.etiqueta(Tema.TAM_TITULO, Tema.BIEN if bool(r["aprobado"]) else Tema.MAL,
			"%s: %d de %d" % ["¡Aprobado!" if bool(r["aprobado"]) else "Suspendido", int(r["bien"]), int(r["total"])])
		_caja.add_child(t)
		## Las que fallaste, con la respuesta buena: un examen también enseña.
		for k in _preguntas.size():
			var q: Array = _preguntas[k]
			if int(_respuestas[k]) != int(q[2]):
				var f := Tema.etiqueta(Tema.TAM_ROTULO + 1, Tema.SUAVE, "✗ %s → %s" % [String(q[0]), String((q[1] as Array)[int(q[2])])])
				f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				f.custom_minimum_size = Vector2(580, 0)
				_caja.add_child(f)
		var b := Button.new()
		b.text = "Cerrar"
		b.pressed.connect(func() -> void:
			cerrado.emit()
			queue_free())
		_caja.add_child(b)
		return
	var q: Array = _preguntas[_i]
	_caja.add_child(Tema.rotulo("🎓 Examen · %s · pregunta %d de %d" % [objetivo, _i + 1, _preguntas.size()]))
	var enun := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.TEXTO, String(q[0]))
	enun.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enun.custom_minimum_size = Vector2(580, 0)
	_caja.add_child(enun)
	for k in (q[1] as Array).size():
		var b := Button.new()
		b.text = String((q[1] as Array)[k])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(_responder.bind(k))
		_caja.add_child(b)
	Animar.aparecer(_caja)

func _responder(k: int) -> void:
	_respuestas.append(k)
	_i += 1
	_pintar()
