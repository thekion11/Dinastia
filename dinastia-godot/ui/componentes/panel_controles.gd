class_name PanelControles
extends Control
## LA PANTALLA DE CONTROLES (14-10-2026, pedidos: «el control debe ser
## configurable» y, con el manual de FC 26, «así debe estar; agrega las
## combinaciones; mejora el menú, que sea mejor y que al ir bajando o aceptando
## tenga sonido»). Cuatro pestañas:
##   - BOTONES: cada acción con su tecla y su botón del mando; «Cambiar» y se
##     pulsa la tecla o el botón nuevo.
##   - AYUDAS: esquema de teclado y ayudas de pase, tiro, cambio y dirección.
##   - COMBINACIONES: todas las del manual (ataque, defensa, balón parado,
##     tácticas rápidas) escritas con TUS botones.
##   - FILIGRANAS: las del catálogo, con sus estrellas y cómo se hacen.
## Se maneja con ratón, teclado o mando (foco visible, sonido al recorrer y al
## aceptar -`BotonFx`-; Esc o B cierra). Se guarda en `Mando`.

signal cerrado

var _escuchando := ""
var _aviso: Label
var _contenido: VBoxContainer
var _scroll: ScrollContainer
var _pestanas := {}
var _pestana := "botones"
var _primero: Control

const NOMBRES_AYUDA := {
	"pase": ["Pases", {"asistido": "Asistido (busca al compañero)", "manual": "Manual (al punto que apuntas)"}],
	"tiro": ["Tiros", {"asistido": "Asistido (al palo largo)", "manual": "Manual (apuntas tú)"}],
	"cambio": ["Cambio de jugador", {"auto": "Automático", "semi": "Semi (al recibir)", "manual": "Manual (solo con el botón)"}],
	"direccion": ["Dirección del stick", {"camara": "Según la cámara", "campo": "Según el campo"}],
}

## Las acciones por grupos, en el orden del manual.
const GRUPOS := [
	["MOVIMIENTO", ["jugar_arriba", "jugar_abajo", "jugar_izquierda", "jugar_derecha", "jugar_sprint", "jugar_regate"]],
	["ATAQUE Y DEFENSA", ["jugar_pase", "jugar_tiro", "jugar_centro", "jugar_filtrado", "jugar_pase_largo", "jugar_pedir"]],
	["MODIFICADORES", ["jugar_cambiar", "jugar_mod"]],
	["FILIGRANAS (stick derecho)", ["jugar_fili_arriba", "jugar_fili_abajo", "jugar_fili_izquierda", "jugar_fili_derecha", "jugar_sombrero"]],
	["TÁCTICAS RÁPIDAS (cruceta)", ["jugar_tac_arriba", "jugar_tac_abajo", "jugar_tac_izquierda", "jugar_tac_derecha"]],
	["PARTIDO", ["jugar_pausa"]],
]

static func abrir(padre: Node) -> PanelControles:
	var n := PanelControles.new()
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	n.z_index = 160
	padre.add_child(n)
	n._montar()
	n._sonar("abrir")
	return n

func _sonar(nombre: String) -> void:
	var s := get_tree().root.get_node_or_null("Sonido") if is_inside_tree() else null
	if s != null:
		s.call("toca", nombre, 2)

func _montar() -> void:
	Mando.registrar()
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.62)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	caja.custom_minimum_size = Vector2(980, minf(get_viewport_rect().size.y - 40.0, 660.0))
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	caja.add_child(v)
	## Cabecera: título y si hay mando.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)
	cab.add_child(CuadroDialogo.placa(Idiomas.t("🎮 Controles")))
	var disp := Tema.etiqueta(13, Tema.SUAVE, Idiomas.t("Mando conectado · configuración clásica de FC") if Mando.hay_mando() else Idiomas.t("Teclado (el mando se detecta solo al enchufarlo; usa la configuración clásica de FC)"))
	disp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	disp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(disp)
	## Pestañas.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	v.add_child(tabs)
	for par: Array in [["botones", "🎮 Botones"], ["ayudas", "⚙ Ayudas y esquema"], ["combinaciones", "🔗 Combinaciones"], ["filigranas", "✨ Filigranas"]]:
		var b := Button.new()
		b.text = Idiomas.t(String(par[1]))
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 15)
		b.custom_minimum_size = Vector2(0, 34)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_marcar(b)
		var clave: String = par[0]
		b.pressed.connect(func() -> void:
			_pestana = clave
			_pintar())
		tabs.add_child(b)
		_pestanas[clave] = b
		if _primero == null:
			_primero = b
	v.add_child(HSeparator.new())
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	v.add_child(_scroll)
	_contenido = VBoxContainer.new()
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_theme_constant_override("separation", 3)
	_scroll.add_child(_contenido)
	_aviso = Tema.etiqueta(13, Tema.SUAVE, "")
	v.add_child(_aviso)
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 8)
	v.add_child(pie)
	var rest := Button.new()
	rest.text = Idiomas.t("↺ Restaurar de fábrica")
	rest.custom_minimum_size = Vector2(0, 36)
	rest.pressed.connect(func() -> void:
		Mando.restaurar()
		_aviso.text = Idiomas.t("Controles de fábrica.")
		_pintar())
	pie.add_child(rest)
	var listo := Button.new()
	listo.text = Idiomas.t("✔ Listo")
	listo.custom_minimum_size = Vector2(0, 36)
	listo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listo.pressed.connect(cerrar)
	pie.add_child(listo)
	_pintar()
	if _primero != null:
		_primero.grab_focus.call_deferred()

## La opción elegida se lee de un vistazo: letra dorada y borde.
func _marcar(b: Button) -> void:
	b.add_theme_color_override("font_pressed_color", Color("ffd23f"))
	b.add_theme_color_override("font_hover_pressed_color", Color("ffe27a"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.25, 0.2, 0.05, 0.9)
	sb.border_color = Color("c9a227")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	## Los mismos márgenes que el botón normal, para que no se recorte.
	var normal := b.get_theme_stylebox("normal")
	if normal != null:
		for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			sb.set_content_margin(lado, normal.get_content_margin(lado))
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("hover_pressed", sb)

func _pintar() -> void:
	for k: String in _pestanas:
		(_pestanas[k] as Button).button_pressed = k == _pestana
	for h in _contenido.get_children():
		_contenido.remove_child(h)
		h.queue_free()
	match _pestana:
		"botones": _pintar_botones()
		"ayudas": _pintar_ayudas()
		"combinaciones": _pintar_combinaciones()
		"filigranas": _pintar_filigranas()

## Cuántas filas de acción reasignable hay en la pestaña de botones.
func filas_de_acciones() -> int:
	var n := 0
	for h in _contenido.get_children():
		if h is HBoxContainer and h.has_meta("accion"):
			n += 1
	return n

func _titulo_seccion(txt: String) -> void:
	_contenido.add_child(Tema.etiqueta(13, Tema.ORO, Idiomas.t(txt)))

func _pintar_botones() -> void:
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	_contenido.add_child(cab)
	for par: Array in [["ACCIÓN", 380], ["TECLADO", 200], ["MANDO", 200]]:
		var l := Tema.etiqueta(12, Tema.SUAVE, Idiomas.t(String(par[0])))
		l.custom_minimum_size = Vector2(float(par[1]), 0)
		cab.add_child(l)
	for g: Array in GRUPOS:
		_titulo_seccion(String(g[0]))
		for accion: String in g[1]:
			if not Mando.MAPA.has(accion):
				continue
			var fila := HBoxContainer.new()
			fila.set_meta("accion", accion)
			fila.add_theme_constant_override("separation", 8)
			_contenido.add_child(fila)
			var nom := Tema.etiqueta(13, Tema.TEXTO, Idiomas.t(String(Mando.MAPA[accion][0])))
			nom.custom_minimum_size = Vector2(380, 0)
			nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fila.add_child(nom)
			var escucha := _escuchando == accion
			var partes := Mando.texto_de(accion).split("  ·  🎮 ")
			var tec := Tema.etiqueta(13, Color("ffd23f") if escucha else Tema.ORO,
				Idiomas.t("Pulsa una tecla o un botón… (Supr cancela)") if escucha else String(partes[0]))
			tec.custom_minimum_size = Vector2(200, 0)
			fila.add_child(tec)
			var man := Tema.etiqueta(13, Color("8fd3ff"), "" if escucha else ("🎮 " + String(partes[1]) if partes.size() > 1 else "—"))
			man.custom_minimum_size = Vector2(200, 0)
			man.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(man)
			var b := Button.new()
			b.text = Idiomas.t("Cambiar")
			b.add_theme_font_size_override("font_size", 12)
			b.custom_minimum_size = Vector2(90, 26)
			b.pressed.connect(func() -> void:
				_escuchando = accion
				_pintar()
				_aviso.text = Idiomas.t("Esperando la tecla o el botón para «%s»…") % Idiomas.t(String(Mando.MAPA[accion][0])))
			fila.add_child(b)

func _pintar_ayudas() -> void:
	_titulo_seccion("ESQUEMA DE TECLADO")
	var fe := HBoxContainer.new()
	fe.add_theme_constant_override("separation", 6)
	_contenido.add_child(fe)
	for e: String in Mando.ESQUEMAS:
		var b := Button.new()
		b.text = Idiomas.t(String(Mando.ESQUEMAS[e]["nombre"]))
		b.toggle_mode = true
		b.button_pressed = e == Mando.esquema
		b.add_theme_font_size_override("font_size", 13)
		_marcar(b)
		b.pressed.connect(func() -> void:
			Mando.fijar_esquema(e)
			_pintar())
		fe.add_child(b)
	_titulo_seccion("AYUDAS")
	var rej := GridContainer.new()
	rej.columns = 2
	rej.add_theme_constant_override("h_separation", 12)
	rej.add_theme_constant_override("v_separation", 6)
	_contenido.add_child(rej)
	for k: String in Mando.AYUDAS:
		rej.add_child(Tema.etiqueta(13, Tema.TEXTO, Idiomas.t(String(NOMBRES_AYUDA[k][0]))))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 4)
		rej.add_child(fila)
		for op: String in Mando.AYUDAS[k]:
			var b2 := Button.new()
			b2.text = Idiomas.t(String((NOMBRES_AYUDA[k][1] as Dictionary).get(op, op)))
			b2.toggle_mode = true
			b2.button_pressed = Mando.ayuda(k) == op
			b2.add_theme_font_size_override("font_size", 12)
			_marcar(b2)
			b2.pressed.connect(func() -> void:
				Mando.fijar_ayuda(k, op)
				_pintar())
			fila.add_child(b2)

func _pintar_combinaciones() -> void:
	for c: Array in ControlFC.COMBINACIONES:
		var acciones: Array = c[1]
		if acciones.is_empty():
			_titulo_seccion(String(c[0]))
			continue
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		_contenido.add_child(fila)
		var nom := Tema.etiqueta(13, Tema.TEXTO, Idiomas.t(String(c[0])))
		nom.custom_minimum_size = Vector2(430, 0)
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(nom)
		var combo := Tema.etiqueta(14, Color("ffd23f"), ControlFC.texto_combinacion(acciones))
		combo.custom_minimum_size = Vector2(230, 0)
		fila.add_child(combo)
		var cuando := Tema.etiqueta(12, Tema.SUAVE, Idiomas.t(String(c[2])))
		cuando.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(cuando)
	_enfocable_al_final()

func _pintar_filigranas() -> void:
	var intro := Tema.etiqueta(12, Tema.SUAVE, Idiomas.t("Arriba, abajo y los lados son respecto a donde mira tu jugador. Cada jugador tiene de 1 a 5★ según su regate: si la filigrana pide más estrellas de las que tiene, le sale mal y pierde el balón."))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenido.add_child(intro)
	var lista: Array = ControlFC.FILIGRANAS.keys()
	lista.sort_custom(func(a: String, b: String) -> bool:
		var ea := int(ControlFC.FILIGRANAS[a][1])
		var eb := int(ControlFC.FILIGRANAS[b][1])
		return ea < eb or (ea == eb and a < b))
	var previa := 0
	for id: String in lista:
		var f: Array = ControlFC.FILIGRANAS[id]
		if int(f[1]) != previa:
			previa = int(f[1])
			_titulo_seccion("★".repeat(previa) + "☆".repeat(5 - previa))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		_contenido.add_child(fila)
		var nom := Tema.etiqueta(13, Tema.TEXTO, Idiomas.t(String(f[0])))
		nom.custom_minimum_size = Vector2(300, 0)
		fila.add_child(nom)
		var como_txt := Idiomas.t(String(f[2])).replace("LB", Mando.corto_de("jugar_cambiar")).replace("RB", Mando.corto_de("jugar_mod")).replace("LT", Mando.corto_de("jugar_regate"))
		var como := Tema.etiqueta(13, Color("ffd23f"), como_txt)
		como.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		como.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(como)
	_enfocable_al_final()

## Un botón al final de las listas de solo lectura: con el mando, bajar por
## la lista mueve el foco y el scroll la sigue.
func _enfocable_al_final() -> void:
	var b := Button.new()
	b.text = Idiomas.t("↑ Volver arriba")
	b.flat = true
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(func() -> void:
		_scroll.scroll_vertical = 0
		if _pestanas.has(_pestana):
			(_pestanas[_pestana] as Button).grab_focus())
	_contenido.add_child(b)

func _input(ev: InputEvent) -> void:
	if _escuchando == "":
		## Esc o B (ui_cancel) cierra.
		if ev.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			cerrar()
		## Con el mando, en una lista de solo lectura arriba/abajo desplaza.
		elif _pestana in ["combinaciones", "filigranas"] and (ev.is_action_pressed("ui_down") or ev.is_action_pressed("ui_up")) \
				and get_viewport().gui_get_focus_owner() == _pestanas.get(_pestana):
			_scroll.scroll_vertical += 60 if ev.is_action_pressed("ui_down") else -60
			_sonar("clic_suave")
			get_viewport().set_input_as_handled()
		return
	var vale := (ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo) \
		or (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed)
	if not vale:
		return
	get_viewport().set_input_as_handled()
	if ev is InputEventKey and (ev as InputEventKey).keycode == KEY_DELETE:
		_escuchando = ""
		_aviso.text = ""
		_pintar()
		return
	var accion := _escuchando
	_escuchando = ""
	Mando.reasignar(accion, ev)
	_aviso.text = Idiomas.t("«%s» ahora es: %s") % [Idiomas.t(String(Mando.MAPA[accion][0])), Mando.texto_de(accion)]
	_sonar("guardado")
	_pintar()

func cerrar() -> void:
	_sonar("cerrar")
	cerrado.emit()
	queue_free()
