class_name EstiloMundoPantalla
extends Control
## ESTILO DEL MUNDO (15-11-2026, pedido del dueño): etapa de la entrada, después del idioma y antes de crear el mundo. Dos tarjetas
## grandes, «Mundo clásico» y «Mundo suave» (ver `EstiloMundo`); se elige con ratón, dedo, teclado o mando (izquierda/derecha,
## aceptar, volver). Contrato de las etapas (`OrquestadorEntrada`): `terminado(datos)`, `volver()`, `configurar(estado)`.
## Devuelve {"estilo": "clasico" | "suave"} y deja la elección guardada en la máquina.
signal terminado(datos: Dictionary)
signal volver()

const OPCIONES := [
	["clasico", "MUNDO CLÁSICO", "El Dinastía de siempre, con menos partículas y menos movimiento.",
		["Fondos con clima (lluvia, motas, confeti), a la mitad", "El globo gira más despacio", "Todos los menús como hasta ahora"]],
	["suave", "MUNDO SUAVE", "Pantallas quietas y limpias: solo se dibuja lo que cambia.",
		["Sin partículas: fondos quietos", "Más fluido y gasta menos batería", "Primer paso del estilo nuevo, con un color por modo de juego"]],
]

var elegido := "clasico"
var _tarjetas: Dictionary = {}   ## clave -> Button

func configurar(estado: Dictionary) -> void:
	var e: Variant = estado.get("estilo")
	if e is String and String(e) in ["clasico", "suave"]:
		elegido = String(e)
	elif EstiloMundo.elegido_antes():
		elegido = "suave" if EstiloMundo.suave else "clasico"
	if is_node_ready():
		_marcar()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 32)
	add_child(margen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	margen.add_child(v)
	v.add_child(Tema.etiqueta(EscalaTipografica.ROTULO, Tema.SUAVE, Idiomas.t("NUEVO JUEGO · ESTILO")))
	v.add_child(Tema.etiqueta(Tema.TAM_TITULO + 10, Tema.ORO, Idiomas.t("¿CÓMO QUIERES VER TU MUNDO?")))
	var nota := Tema.etiqueta(EscalaTipografica.CUERPO, Tema.TEXTO, Idiomas.t("Se puede cambiar después en Ajustes. No cambia cómo se juega, solo cómo se ve y cuánto se mueve."))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nota)
	var fila := HBoxContainer.new()
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_theme_constant_override("separation", 20)
	v.add_child(fila)
	for o: Array in OPCIONES:
		fila.add_child(_tarjeta(o))
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 12)
	v.add_child(pie)
	var atras := Button.new()
	atras.text = Idiomas.t("Volver")
	atras.custom_minimum_size = Vector2(160, 48)
	atras.pressed.connect(func() -> void: volver.emit())
	pie.add_child(atras)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(hueco)
	var seguir := Button.new()
	seguir.text = Idiomas.t("Continuar ▶")
	seguir.custom_minimum_size = Vector2(240, 48)
	seguir.pressed.connect(confirmar)
	pie.add_child(seguir)
	_marcar()
	(_tarjetas[elegido] as Button).grab_focus.call_deferred()

func _tarjeta(o: Array) -> Button:
	var clave := String(o[0])
	var b := Button.new()
	b.toggle_mode = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(280, 260)
	b.focus_mode = Control.FOCUS_ALL
	var acento := Tema.ORO if clave == "clasico" else Color("7fc8c2")
	b.add_theme_stylebox_override("normal", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.BORDE))
	b.add_theme_stylebox_override("hover", Tema.caja(Tema.TARJETA, Tema.RADIO_GRANDE, Color(acento, 0.5)))
	var marcado := Tema.caja(Tema.TARJETA, Tema.RADIO_GRANDE, acento)
	marcado.set_border_width_all(3)
	for e: String in ["pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(e, marcado)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado: String in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 22)
	b.add_child(m)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 10)
	m.add_child(col)
	col.add_child(_muestra(clave, acento))
	col.add_child(Tema.etiqueta(Tema.TAM_TITULO + 4, acento, Idiomas.t(String(o[1]))))
	var lema := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, Idiomas.t(String(o[2])))
	lema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(lema)
	for linea: String in o[3]:
		var l := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "· " + Idiomas.t(linea))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(l)
	for c: Node in col.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.pressed.connect(func() -> void:
		if elegido == clave and b.has_focus():
			confirmar()   ## con mando: A sobre la tarjeta ya elegida confirma
			return
		elegido = clave
		_marcar())
	_tarjetas[clave] = b
	return b

## Una muestra quieta de cada estilo (dibujada, sin partículas: esta pantalla no se mueve en ninguno de los dos).
func _muestra(clave: String, acento: Color) -> Control:
	var caja := Panel.new()
	caja.custom_minimum_size = Vector2(0, 96)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_theme_stylebox_override("panel", Tema.caja(Color("0c1510") if clave == "clasico" else Color("10291f"), Tema.RADIO, Tema.BORDE))
	if clave == "clasico":
		for i in 14:   ## las motas del fondo de siempre, quietas
			var d := ColorRect.new()
			d.color = Color(1, 1, 1, 0.35)
			d.size = Vector2(4, 4)
			d.position = Vector2(18 + (i * 53) % 300, 14 + (i * 37) % 64)
			d.mouse_filter = Control.MOUSE_FILTER_IGNORE
			caja.add_child(d)
	else:
		for i in 3:   ## los bloques limpios de la maqueta, un color por modo
			var r := ColorRect.new()
			r.color = [Color("b8e05a"), Color("d9b44a"), Color("ff5c8a")][i]
			r.size = Vector2(64, 8)
			r.position = Vector2(18 + i * 80, 70)
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			caja.add_child(r)
	var franja := ColorRect.new()
	franja.color = Color(acento, 0.85)
	franja.size = Vector2(120, 10)
	franja.position = Vector2(18, 20)
	franja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(franja)
	return caja

func _marcar() -> void:
	for k: String in _tarjetas:
		(_tarjetas[k] as Button).set_pressed_no_signal(k == elegido)

func confirmar() -> void:
	EstiloMundo.elegir(elegido == "suave")
	terminado.emit({"estilo": elegido})

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		volver.emit()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		elegido = "suave" if elegido == "clasico" else "clasico"
		_marcar()
		(_tarjetas[elegido] as Button).grab_focus()
	elif event.is_action_pressed("ui_accept"):
		confirmar()
	else:
		return
	get_viewport().set_input_as_handled()
