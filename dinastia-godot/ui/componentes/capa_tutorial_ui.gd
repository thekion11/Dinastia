class_name CapaTutorialUI
extends RefCounted
## La tarjeta del tutorial por capas (`CapasTutorial`, fila 1040): sale abajo a la derecha la primera vez que se abre una pantalla, con las líneas de
## su «?», «Entendido» y «No mostrar más ayudas». No bloquea nada: se puede seguir jugando con ella abierta.

## Lo llama `Principal._al_cambiar_pestana` con el título de la pestaña recién abierta.
static func al_cambiar_pestana(p: Principal, titulo: String) -> void:
	if p.get("mundo") == null or not CapasTutorial.debe_mostrar(titulo, bool(p.get("_modo_experto"))):
		return
	var guia: Object = p.get("_guia")
	if guia != null and is_instance_valid(guia.get("_tutorial")):
		return   ## el recorrido guiado ya está explicando
	mostrar(p, titulo)

## Pone la tarjeta de `clave` en `padre` (sustituye la que hubiera). Devuelve el panel.
static func mostrar(padre: Control, clave: String) -> PanelContainer:
	var vieja := padre.get_node_or_null("CapaTutorial")
	if vieja != null:
		vieja.free()
	var tarjeta := PanelContainer.new()
	tarjeta.name = "CapaTutorial"
	tarjeta.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tarjeta.offset_left = -486.0
	tarjeta.offset_right = -72.0   ## deja libre el cajón de objetivos del borde derecho
	tarjeta.offset_top = -260.0
	tarjeta.offset_bottom = -16.0
	tarjeta.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tarjeta.z_index = 40
	tarjeta.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.ORO))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	tarjeta.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, "💡 " + Idiomas.t(clave)))
	for l: String in AyudaPestana.lineas(clave):
		var e := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "• " + l)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(e)
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 8)
	v.add_child(fila)
	var ok := Button.new()
	ok.text = Idiomas.t("Entendido")
	ok.name = "Entendido"
	ok.pressed.connect(func() -> void:
		CapasTutorial.marcar_vista(clave)
		tarjeta.queue_free())
	fila.add_child(ok)
	var no := Button.new()
	no.text = Idiomas.t("No mostrar más ayudas")
	no.name = "NoMostrar"
	no.tooltip_text = Idiomas.t("Se pueden volver a encender en Ajustes.")
	no.pressed.connect(func() -> void:
		CapasTutorial.marcar_vista(clave)
		CapasTutorial.poner_activas(false)
		tarjeta.queue_free())
	fila.add_child(no)
	padre.add_child(tarjeta)
	return tarjeta
