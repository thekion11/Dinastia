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
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.72)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(560, 0)
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.ACENTO))
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACIO)
	caja.add_child(v)
	v.add_child(Tema.rotulo(Idiomas.t("📋 ¿Hacer habitual el plan?")))
	var txt := Idiomas.t("En los últimos %d partidos tu plan saltó siempre igual: %s. ¿Quieres que esa sea tu táctica habitual?") % [
		_tactica.racha_plan_n, describir(_tactica.racha_plan_clave)]
	var q := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, txt)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(q)
	for o: Array in [["siempre", Idiomas.t("Siempre, todo el partido")],
			["desde_60", Idiomas.t("Solo desde el minuto 60")], ["no", Idiomas.t("No, gracias")]]:
		var b := Button.new()
		b.name = "Opcion_" + String(o[0])
		b.text = String(o[1])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(elegir.bind(String(o[0])))
		v.add_child(b)
	Animar.aparecer(caja, 0.0, 0.3)

## Público para que la prueba pueda pulsar sin ratón.
func elegir(respuesta: String) -> void:
	if _tactica != null:
		_tactica.responder_plan(respuesta)
	cerrado.emit()
	## Fuera del padre ya: si no, la de la semana siguiente chocaría de nombre.
	if get_parent() != null:
		get_parent().remove_child(self)
	queue_free()
