class_name PreguntaPlan
extends Control
## ¿HACER HABITUAL EL PLAN? (25-10-2026, pedido del dueño). Cuando el mismo
## cambio del plan según el marcador salta seis partidos seguidos
## (`Tactica.toca_preguntar_plan()`), al volver del partido se le pregunta al
## usuario si quiere que sea su táctica de siempre. Tres salidas, sin «cerrar»:
## las tres reinician la cuenta (`Tactica.responder_plan()`).

signal cerrado

var _tactica: Tactica

## Abre la pregunta si toca y devuelve el nodo; null si no toca (y entonces
## no hay que esperar a `cerrado`).
static func mostrar_si_toca(padre: Control, c: Club) -> PreguntaPlan:
	if padre == null or c == null or c.tactica == null or not c.tactica.toca_preguntar_plan():
		return null
	## Si ya hay una abierta (se avanzó otra semana sin contestar), no se apila otra.
	var abierta := padre.get_node_or_null("PreguntaPlan")
	if abierta != null and not abierta.is_queued_for_deletion():
		return null
	var n := PreguntaPlan.new()
	n.name = "PreguntaPlan"
	n._tactica = c.tactica
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

## El cambio contado en palabras, para que se sepa de qué costumbre se habla.
static func describir(clave: String) -> String:
	match clave:
		"perdiendo:ofensivo":
			return Idiomas.t("ir a por el partido (mentalidad ofensiva y línea alta) cuando vas perdiendo")
		"ganando:cerrojo":
			return Idiomas.t("cerrar el partido (mentalidad defensiva y línea baja) cuando vas ganando")
		"perdiendo:cerrojo":
			return Idiomas.t("cerrar el partido (mentalidad defensiva y línea baja) cuando vas perdiendo")
		"ganando:ofensivo":
			return Idiomas.t("ir a por el partido (mentalidad ofensiva y línea alta) cuando vas ganando")
	return clave

func _montar() -> void:
	## SIEMPRE ENCIMA (26-10, captura con la pantalla real): el panel de
	## objetivos se cuelga de Principal al refrescar, DESPUÉS del diálogo, y
	## salía sin oscurecer y recibiendo clics por encima del velo. Se dibuja
	## arriba (z) y vuelve al frente del árbol (entrada) si entra otro hermano.
	z_index = 100
	add_to_group(MentorVoz.GRUPO_TAPA)
	var padre := get_parent()
	if padre != null:
		padre.child_entered_tree.connect(_al_frente)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.72)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(640, 0)
	var sb := Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.ACENTO)
	## Más aire dentro: en la captura el texto casi tocaba el borde.
	sb.content_margin_left = 28; sb.content_margin_right = 28
	sb.content_margin_top = 22; sb.content_margin_bottom = 24
	caja.add_theme_stylebox_override("panel", sb)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACIO + 4)
	caja.add_child(v)
	var tit := Tema.etiqueta(20, Tema.ORO, Idiomas.t("📋 ¿Hacer habitual el plan?"))
	v.add_child(tit)
	var txt := Idiomas.t("En los últimos %d partidos tu plan saltó siempre igual: %s. ¿Quieres que esa sea tu táctica habitual?") % [
		_tactica.racha_plan_n, describir(_tactica.racha_plan_clave)]
	var q := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, txt)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.custom_minimum_size = Vector2(584, 0)
	v.add_child(q)
	var ops := VBoxContainer.new()
	ops.add_theme_constant_override("separation", 8)
	v.add_child(ops)
	var n := 0
	for o: Array in [["siempre", Idiomas.t("Siempre, todo el partido")],
			["desde_60", Idiomas.t("Solo desde el minuto 60")], ["no", Idiomas.t("No, gracias")]]:
		n += 1
		var b := Button.new()
		b.name = "Opcion_" + String(o[0])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 44)
		## Mismo estilo que la rueda de prensa y los diálogos, numerado: las
		## teclas 1-3 y el mando (foco) contestan sin ratón.
		CuadroDialogo.respuesta(b)
		b.text = "%d.  %s" % [n, String(o[1])]
		b.pressed.connect(elegir.bind(String(o[0])))
		ops.add_child(b)
	(ops.get_child(0) as Control).grab_focus.call_deferred()
	Animar.aparecer(caja, 0.0, 0.3)

func _al_frente(_n: Node) -> void:
	_subir.call_deferred()

func _subir() -> void:
	if get_parent() != null and not is_queued_for_deletion():
		get_parent().move_child(self, -1)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var i := ["siempre", "desde_60", "no"]
		var k := (ev as InputEventKey).keycode - KEY_1
		if k >= 0 and k < 3:
			get_viewport().set_input_as_handled()
			elegir(String(i[k]))

## Público para que la prueba pueda pulsar sin ratón.
func elegir(respuesta: String) -> void:
	if _tactica != null:
		_tactica.responder_plan(respuesta)
	cerrado.emit()
	## Fuera del padre ya: si no, la de la semana siguiente chocaría de nombre.
	if get_parent() != null:
		if get_parent().child_entered_tree.is_connected(_al_frente):
			get_parent().child_entered_tree.disconnect(_al_frente)
		get_parent().remove_child(self)
	queue_free()
