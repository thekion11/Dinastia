class_name PieDeCampo
extends Control
## LA ENTREVISTA A PIE DE CAMPO (25-9-2026, plan maestro B5). Al terminar el
## partido que dirigiste, antes de volver al despacho: una periodista con el
## micrófono, una pregunta con el partido todavía caliente y tres salidas -o
## pasar de largo-. Es corta a propósito: la rueda de prensa larga llega
## después. Las cifras y la frase las pone `Prensa.pie_de_campo()`; esto solo
## las enseña.

signal cerrado

var _prensa: Prensa

static func mostrar(padre: Control, prensa: Prensa, gane: bool, empate: bool, gf: int, gc: int) -> PieDeCampo:
	var n := PieDeCampo.new()
	n._prensa = prensa
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar(prensa.pie_de_campo(gane, empate, gf, gc), gane, empate)
	return n

func _montar(e: Dictionary, gane: bool, empate: bool) -> void:
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.72)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var acento: Color = Tema.BIEN if gane else (Tema.NEUTRO if empate else Tema.MAL)
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(560, 0)
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, acento))
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACIO)
	caja.add_child(v)
	v.add_child(Tema.rotulo("🎤 A pie de campo"))
	v.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO, String(e.get("quien", ""))))
	var q := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.TEXTO, "«%s»" % String(e.get("pregunta", "")))
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(q)
	var ops: Array = e.get("opciones", [])
	for i in ops.size():
		var o: Dictionary = ops[i]
		var b := Button.new()
		b.text = "%s  %s" % [{"calma": "🙂", "soberbia": "😤", "evasiva": "🤐"}.get(String(o.get("tono", "")), "💬"), String(o["txt"])]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(_elegir.bind(i))
		v.add_child(b)
	var saltar := Button.new()
	saltar.text = "Pasar de largo"
	saltar.flat = true
	saltar.add_theme_color_override("font_color", Tema.SUAVE)
	saltar.pressed.connect(_elegir.bind(-1))
	v.add_child(saltar)
	Animar.aparecer(caja, 0.0, 0.3)

func _elegir(i: int) -> void:
	if _prensa != null:
		_prensa.responder_pie(i)
	cerrado.emit()
	queue_free()
