class_name PanelControles
extends Control
## LA PANTALLA DE CONTROLES (14-10-2026). Segunda versión, tras el veredicto
## del usuario: «sigue siendo muy básica; es muy pequeña, no sigue los colores,
## no hay animación al bajar o subir, no hay sonido, no hay animación al
## modificar algo, no hay un "¿estás seguro de que quieres guardar?", no hay
## un fondo con animación; ¿viste mis mensajes de la nueva estructura de los
## controles? Y que esté ejemplificado cómo se ven los controles y qué parte del
## control es cada una».
##
## Ahora:
##   - A PANTALLA COMPLETA, con los colores del juego (`Tema`) y un FONDO VIVO
##     (franjas de luz que cruzan, líneas de campo que se mueven y chispas).
##   - LA ESTRUCTURA DEL MANUAL que pasó: las 6 partes con sus combinaciones en
##     columnas PlayStation · Xbox · Teclado, y la 7.ª, las filigranas por
##     estrellas; más «Asignar botones» y «Ayudas».
##   - EL MANDO DIBUJADO (`DibujoMando`): PlayStation, Xbox o teclado, con lo
##     que hace cada botón en la sección y la combinación elegida latiendo.
##   - ANIMACIÓN: el selector dorado se DESLIZA de fila en fila al bajar o
##     subir, las filas entran escalonadas al cambiar de sección, el valor que
##     cambias destella y salta, los diálogos aparecen con un pequeño zoom.
##   - SONIDO propio para moverse, aceptar, volver, cambiar y pasar de sección.
##   - Los cambios NO se dan por buenos solos: «Guardar» pregunta si estás
##     seguro, y salir con cambios ofrece guardar, descartar o seguir.
## Se maneja con ratón, teclado o mando (LB/RB o Q/E cambian de sección).

signal cerrado

var _escuchando := ""
var _pestana := "p0"
var dispositivo := "xbox"

var _raiz: Control
var _menu: VBoxContainer
var _pastilla_menu: Panel
var _items_menu := {}
var _titulo: Label
var _subtitulo: Label
var _scroll: ScrollContainer
var _contenido: VBoxContainer
var _selector: Panel
var _mando: DibujoMando
var _aviso: Label
var _sin_guardar: Label
var _chips_disp := {}
var _pastilla_disp: Panel
var _dialogo: Control
var _foto: Dictionary = {}
var _cambios := false
var _fila_activa: Control
var _tw_scroll: Tween
var _tw_selector: Tween

const NOMBRES_AYUDA := {
	"pase": ["Pases", {"asistido": "Asistido (busca al compañero)", "manual": "Manual (al punto que apuntas)"}],
	"tiro": ["Tiros", {"asistido": "Asistido (al palo largo)", "manual": "Manual (apuntas tú)"}],
	"cambio": ["Cambio de jugador", {"auto": "Automático", "semi": "Semi (al recibir)", "manual": "Manual (solo con el botón)"}],
	"direccion": ["Dirección del stick", {"camara": "Según la cámara", "campo": "Según el campo"}],
	"vibracion": ["Vibración del mando", {"normal": "Normal", "suave": "Suave", "no": "Sin vibración"}],
}

## Las acciones reasignables por grupos (sección «Asignar botones»).
const GRUPOS := [
	["Movimiento", ["jugar_arriba", "jugar_abajo", "jugar_izquierda", "jugar_derecha", "jugar_sprint", "jugar_regate"]],
	["Ataque y defensa", ["jugar_pase", "jugar_tiro", "jugar_centro", "jugar_filtrado", "jugar_pase_largo", "jugar_pedir"]],
	["Modificadores", ["jugar_cambiar", "jugar_mod"]],
	["Filigranas (stick derecho)", ["jugar_fili_arriba", "jugar_fili_abajo", "jugar_fili_izquierda", "jugar_fili_derecha", "jugar_sombrero"]],
	["Tácticas rápidas (cruceta)", ["jugar_tac_arriba", "jugar_tac_abajo", "jugar_tac_izquierda", "jugar_tac_derecha"]],
	["Partido", ["jugar_pausa", "jugar_estadisticas", "jugar_repeticion"]],
]

## El fondo vivo: degradado del juego, franjas de luz que cruzan en diagonal,
## líneas de campo que se desplazan muy despacio y viñeta.
const SHADER_FONDO := """
shader_type canvas_item;
uniform vec4 base : source_color = vec4(0.047, 0.082, 0.063, 1.0);
uniform vec4 panel : source_color = vec4(0.08, 0.11, 0.09, 1.0);
uniform vec4 oro : source_color = vec4(0.79, 0.64, 0.15, 1.0);
uniform vec4 verde : source_color = vec4(0.25, 0.63, 0.42, 1.0);
void fragment() {
	vec2 uv = UV;
	vec3 c = mix(panel.rgb, base.rgb, uv.y * 0.8 + 0.1);
	float t = TIME;
	// Franjas de luz en diagonal que cruzan despacio.
	float d = uv.x * 1.2 + uv.y * 0.6;
	float f1 = smoothstep(0.08, 0.0, abs(fract(d * 0.5 - t * 0.035) - 0.5) - 0.18);
	float f2 = smoothstep(0.05, 0.0, abs(fract(d * 0.9 + t * 0.02) - 0.5) - 0.22);
	c += oro.rgb * f1 * 0.05 + verde.rgb * f2 * 0.05;
	// Líneas de campo (un rectángulo y un círculo) que derivan.
	vec2 p = (uv - vec2(0.5 + sin(t * 0.05) * 0.03, 0.55)) * vec2(1.78, 1.0);
	float circ = abs(length(p) - 0.32);
	float lin = min(abs(p.x), min(abs(abs(p.y) - 0.42), abs(abs(p.x) - 0.75)));
	float l = smoothstep(0.004, 0.0, min(circ, lin) - 0.001);
	c += vec3(1.0) * l * 0.035;
	// Viñeta.
	c *= 1.0 - 0.55 * pow(length((uv - 0.5) * vec2(1.1, 1.3)), 2.2);
	COLOR = vec4(c, 1.0);
}
"""

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
		s.call("toca", nombre, 0)

# ------------------------------------------------------------------ montaje

func _montar() -> void:
	Mando.registrar()
	dispositivo = ControlFC.dispositivo_detectado()
	if dispositivo == "teclado":
		dispositivo = "xbox"
	_foto = {"propio": Mando.propio.duplicate(true), "esquema": Mando.esquema, "ayudas": Mando.ayudas.duplicate()}
	## Fondo vivo.
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER_FONDO
	sm.shader = sh
	fondo.material = sm
	add_child(fondo)
	for tipo: String in ["bokeh", "motas"]:
		var fp := FondoParticulas.new(tipo)
		fp.color = Tema.ORO.lerp(Color.WHITE, 0.4) if tipo == "motas" else Tema.ACENTO.lerp(Color.WHITE, 0.2)
		add_child(fp)
		fp.ajustar_area(get_viewport_rect().size)
	## Todo el contenido, con márgenes.
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.offset_left = 28
	_raiz.offset_right = -28
	_raiz.offset_top = 18
	_raiz.offset_bottom = -16
	add_child(_raiz)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	_raiz.add_child(col)
	_montar_cabecera(col)
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 14)
	col.add_child(cuerpo)
	_montar_menu(cuerpo)
	_montar_centro(cuerpo)
	_montar_mando(cuerpo)
	_montar_pie(col)
	_pintar()
	## Entrada: aparece y sube un poco.
	_raiz.modulate.a = 0.0
	_raiz.position.y += 16.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_raiz, "modulate:a", 1.0, 0.28)
	tw.tween_property(_raiz, "position:y", _raiz.position.y - 16.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	(_items_menu[_pestana] as Control).grab_focus.call_deferred()

func _estilo(fondo: Color, radio := Tema.RADIO, borde := Tema.BORDE) -> StyleBoxFlat:
	var e := Tema.caja(fondo, radio, borde)
	return e

func _montar_cabecera(col: VBoxContainer) -> void:
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 16)
	col.add_child(cab)
	var tit := VBoxContainer.new()
	tit.add_theme_constant_override("separation", 0)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(tit)
	var t := Tema.etiqueta(34, Tema.ORO, Idiomas.t("CONTROLES"))
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	t.add_theme_constant_override("shadow_offset_y", 2)
	tit.add_child(t)
	tit.add_child(Tema.etiqueta(14, Tema.SUAVE, Idiomas.t("Configuración clásica (tirar con ◯ / B), como en FC 26 · todo se puede cambiar")))
	## Selector de dispositivo: la pastilla dorada se desliza al elegido.
	var selector := Control.new()
	selector.custom_minimum_size = Vector2(390, 44)
	selector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(selector)
	var marco := Panel.new()
	marco.add_theme_stylebox_override("panel", _estilo(Color(0, 0, 0, 0.35), 22, Color(1, 1, 1, 0.1)))
	marco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selector.add_child(marco)
	_pastilla_disp = Panel.new()
	_pastilla_disp.add_theme_stylebox_override("panel", _estilo(Tema.ORO.darkened(0.35), 18, Tema.ORO))
	_pastilla_disp.size = Vector2(126, 36)
	_pastilla_disp.position = Vector2(4, 4)
	selector.add_child(_pastilla_disp)
	var fila := HBoxContainer.new()
	fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fila.add_theme_constant_override("separation", 0)
	selector.add_child(fila)
	for par: Array in [["ps", "PlayStation"], ["xbox", "Xbox"], ["teclado", "⌨ Teclado"]]:
		var b := Button.new()
		b.text = String(par[1])
		b.flat = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 15)
		b.set_meta("sin_sonido", true)
		var clave: String = par[0]
		b.pressed.connect(func() -> void:
			if dispositivo != clave:
				dispositivo = clave
				_sonar("menu_seccion")
				_pintar()
				_mover_pastilla_disp())
		b.focus_entered.connect(_sonar.bind("menu_mover"))
		fila.add_child(b)
		_chips_disp[clave] = b
	_mover_pastilla_disp.call_deferred()

func _mover_pastilla_disp() -> void:
	var b: Button = _chips_disp.get(dispositivo)
	if b == null or _pastilla_disp == null:
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_pastilla_disp, "position:x", b.position.x + 4.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_pastilla_disp, "size:x", b.size.x - 8.0, 0.22)
	for k: String in _chips_disp:
		(_chips_disp[k] as Button).add_theme_color_override("font_color", Color("ffd23f") if k == dispositivo else Tema.TEXTO)

const CORTOS := ["Movimiento y regates", "Ataque y definición", "Defensa", "Portero y tácticas", "Balón parado", "Saques de banda"]

func _secciones() -> Array:
	var r: Array = []
	for i in ControlFC.MANUAL.size():
		var parte: Array = ControlFC.MANUAL[i]
		r.append(["p%d" % i, str(i + 1), String(parte[1]), CORTOS[i] if i < CORTOS.size() else String(parte[0])])
	r.append(["filigranas", "7", "✨", "Filigranas"])
	r.append(["asignar", "", "🎮", "Asignar botones"])
	r.append(["ayudas", "", "⚙", "Ayudas y esquema"])
	return r

func _montar_menu(cuerpo: HBoxContainer) -> void:
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(214, 0)
	caja.add_theme_stylebox_override("panel", _estilo(Color(Tema.PANEL, 0.82), Tema.RADIO_GRANDE))
	cuerpo.add_child(caja)
	var envoltura := Control.new()
	caja.add_child(envoltura)
	_pastilla_menu = Panel.new()
	_pastilla_menu.add_theme_stylebox_override("panel", _estilo(Tema.ORO.darkened(0.55), Tema.RADIO, Tema.ORO))
	_pastilla_menu.size = Vector2(190, 40)
	envoltura.add_child(_pastilla_menu)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 4)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	envoltura.add_child(_menu)
	var rot := Tema.etiqueta(11, Tema.SUAVE, Idiomas.t("MANUAL DE CONTROLES"))
	_menu.add_child(rot)
	for s: Array in _secciones():
		if String(s[0]) == "asignar":
			var sep := HSeparator.new()
			_menu.add_child(sep)
			_menu.add_child(Tema.etiqueta(11, Tema.SUAVE, Idiomas.t("AJUSTES")))
		var b := Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.add_theme_font_size_override("font_size", 13)
		b.text = ("%s  %s   %s" % [s[2], s[1], Idiomas.t(String(s[3]))]) if String(s[1]) != "" else ("%s   %s" % [s[2], Idiomas.t(String(s[3]))])
		b.clip_text = true
		b.set_meta("sin_sonido", true)
		var clave: String = s[0]
		b.pressed.connect(func() -> void: _ir_a(clave))
		b.focus_entered.connect(func() -> void:
			_sonar("menu_mover")
			_mover_pastilla_menu(b))
		b.mouse_entered.connect(func() -> void: b.grab_focus())
		_menu.add_child(b)
		_items_menu[clave] = b
	_menu.add_child(Control.new())

func _mover_pastilla_menu(b: Control) -> void:
	if _pastilla_menu == null:
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_pastilla_menu, "position:y", b.position.y, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_pastilla_menu, "size:x", _menu.size.x, 0.2)
	var elegido: bool = b == _items_menu.get(_pestana)
	(_pastilla_menu.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Tema.ORO.darkened(0.5) if elegido else Color(1, 1, 1, 0.07)

func _ir_a(clave: String) -> void:
	if clave == _pestana:
		_enfocar_primera_fila()
		return
	_pestana = clave
	_escuchando = ""
	_sonar("menu_seccion")
	_pintar()
	_enfocar_primera_fila.call_deferred()

func _montar_centro(cuerpo: HBoxContainer) -> void:
	var caja := PanelContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_stylebox_override("panel", _estilo(Color(Tema.PANEL, 0.86), Tema.RADIO_GRANDE))
	cuerpo.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	_titulo = Tema.etiqueta(22, Tema.TEXTO, "")
	v.add_child(_titulo)
	_subtitulo = Tema.etiqueta(12, Tema.SUAVE, "")
	_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_subtitulo)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = false
	v.add_child(_scroll)
	var capa := Control.new()
	capa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(capa)
	## El selector dorado que se desliza detrás de la fila con el foco.
	_selector = Panel.new()
	var es := _estilo(Color(Tema.ORO, 0.16), Tema.RADIO, Color(Tema.ORO, 0.9))
	es.set_border_width_all(0)
	es.border_width_left = 4
	_selector.add_theme_stylebox_override("panel", es)
	_selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selector.visible = false
	capa.add_child(_selector)
	_contenido = VBoxContainer.new()
	_contenido.add_theme_constant_override("separation", 2)
	capa.add_child(_contenido)
	_contenido.resized.connect(func() -> void:
		capa.custom_minimum_size = Vector2(0, _contenido.size.y)
		_contenido.size.x = capa.size.x)
	capa.resized.connect(func() -> void: _contenido.size.x = capa.size.x)

func _montar_mando(cuerpo: HBoxContainer) -> void:
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(450, 0)
	caja.add_theme_stylebox_override("panel", _estilo(Color(Tema.PANEL, 0.7), Tema.RADIO_GRANDE))
	cuerpo.add_child(caja)
	var v := VBoxContainer.new()
	caja.add_child(v)
	v.add_child(Tema.etiqueta(11, Tema.SUAVE, Idiomas.t("ASÍ SE VE TU MANDO")))
	_mando = DibujoMando.new()
	_mando.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mando.custom_minimum_size = Vector2(400, 300)
	v.add_child(_mando)
	var leyenda := Tema.etiqueta(12, Tema.SUAVE, Idiomas.t("Gíralo con el ratón. En dorado, los botones de la combinación elegida."))
	leyenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(leyenda)

func _montar_pie(col: VBoxContainer) -> void:
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 10)
	col.add_child(pie)
	_aviso = Tema.etiqueta(13, Tema.SUAVE, "")
	_aviso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_aviso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pie.add_child(_aviso)
	_sin_guardar = Tema.etiqueta(13, Tema.ORO, Idiomas.t("● Cambios sin guardar"))
	_sin_guardar.visible = false
	_sin_guardar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pie.add_child(_sin_guardar)
	var ayuda := Tema.etiqueta(12, Tema.SUAVE, "")
	ayuda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ayuda.set_meta("pistas", true)
	pie.add_child(ayuda)
	for par: Array in [["↺  Restaurar", "restaurar"], ["↩  Volver", "volver"], ["💾  Guardar", "guardar"]]:
		var b := Button.new()
		b.text = Idiomas.t(String(par[0]))
		b.custom_minimum_size = Vector2(140, 40)
		b.add_theme_font_size_override("font_size", 15)
		b.set_meta("sin_sonido", true)
		var que: String = par[1]
		if que == "guardar":
			b.add_theme_stylebox_override("normal", _estilo(Tema.ACENTO.darkened(0.3), Tema.RADIO, Tema.ACENTO))
			b.add_theme_stylebox_override("hover", _estilo(Tema.ACENTO.darkened(0.1), Tema.RADIO, Tema.ACENTO.lightened(0.3)))
		b.focus_entered.connect(_sonar.bind("menu_mover"))
		b.pressed.connect(_pie.bind(que))
		pie.add_child(b)

func _pie(que: String) -> void:
	match que:
		"restaurar": _pedir_restaurar()
		"volver": _volver()
		"guardar": _pedir_guardar()

func _pistas() -> String:
	var acepta := "✖" if dispositivo == "ps" else ("A" if dispositivo == "xbox" else "Enter")
	var vuelve := "◯" if dispositivo == "ps" else ("B" if dispositivo == "xbox" else "Esc")
	var secc := "L1/R1" if dispositivo == "ps" else ("LB/RB" if dispositivo == "xbox" else "Re Pág/Av Pág")
	return Idiomas.t("%s elegir · %s volver · %s sección") % [acepta, vuelve, secc]

# ------------------------------------------------------------------ pintar

func _pintar() -> void:
	for h in _contenido.get_children():
		_contenido.remove_child(h)
		h.queue_free()
	_fila_activa = null
	_selector.visible = false
	for k: String in _items_menu:
		var b: Button = _items_menu[k]
		b.add_theme_color_override("font_color", Color("ffd23f") if k == _pestana else Tema.TEXTO)
		b.add_theme_color_override("font_focus_color", Color("ffd23f") if k == _pestana else Color.WHITE)
	if _items_menu.has(_pestana):
		_mover_pastilla_menu.call_deferred(_items_menu[_pestana])
	_mover_pastilla_disp()
	for n in find_children("*", "Label", true, false):
		if n.has_meta("pistas"):
			(n as Label).text = _pistas()
	_mando.dispositivo = "teclado" if dispositivo == "teclado" else dispositivo
	if _pestana.begins_with("p"):
		_pintar_parte(int(_pestana.substr(1)))
	else:
		match _pestana:
			"filigranas": _pintar_filigranas()
			"asignar": _pintar_asignar()
			"ayudas": _pintar_ayudas()
	_etiquetas_mando()
	_entrada_escalonada()
	_scroll.scroll_vertical = 0

## Las filas entran una detrás de otra, deslizándose.
func _entrada_escalonada() -> void:
	var i := 0
	for h in _contenido.get_children():
		var c := h as Control
		if c == null:
			continue
		c.modulate.a = 0.0
		var tw := c.create_tween()
		tw.tween_interval(0.018 * float(mini(i, 18)))
		tw.tween_property(c, "modulate:a", 1.0, 0.18)
		i += 1

func _cabecera_tabla(cols: Array) -> void:
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	var marg := MarginContainer.new()
	marg.add_theme_constant_override("margin_left", 10)
	marg.add_theme_constant_override("margin_right", 8)
	marg.add_child(cab)
	_contenido.add_child(marg)
	## El hueco de las fichas de color de cada fila.
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(40, 0)
	cab.add_child(hueco)
	for par: Array in cols:
		var l := Tema.etiqueta(11, Color("ffd23f") if bool(par[2]) else Tema.SUAVE, Idiomas.t(String(par[0])))
		l.custom_minimum_size = Vector2(float(par[1]), 0)
		if float(par[1]) <= 0.0:
			l.custom_minimum_size.x = 140
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cab.add_child(l)

## Una fila enfocable con sus columnas: crece con el texto (las largas ocupan
## dos líneas sin pisarse). Se elige con clic, Enter o ✖/A. `fichas`: para
## iluminar el mando cuando tiene el foco.
func _fila(cols: Array, fichas: Array, al_pulsar: Callable = Callable()) -> PanelContainer:
	var b := PanelContainer.new()
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.set_meta("fila", true)
	b.set_meta("fichas", fichas)
	var e := StyleBoxEmpty.new()
	e.content_margin_left = 10
	e.content_margin_right = 8
	e.content_margin_top = 6
	e.content_margin_bottom = 6
	b.add_theme_stylebox_override("panel", e)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	## Los colores de los botones de la fila (los mismos del mando 3D y de sus
	## etiquetas): hasta tres fichas, con un hueco fijo para que las columnas alineen.
	var colores := ControlFC.colores_de(fichas, "ps" if dispositivo == "ps" else "xbox")
	var fichas_color := HBoxContainer.new()
	fichas_color.custom_minimum_size = Vector2(40, 0)
	fichas_color.add_theme_constant_override("separation", 3)
	fichas_color.alignment = BoxContainer.ALIGNMENT_BEGIN
	fichas_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for col: Color in colores.slice(0, 3):
		var punto := Panel.new()
		var es := StyleBoxFlat.new()
		es.bg_color = col
		es.set_corner_radius_all(7)
		punto.add_theme_stylebox_override("panel", es)
		punto.custom_minimum_size = Vector2(13, 13)
		punto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		punto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fichas_color.add_child(punto)
	h.add_child(fichas_color)
	for c: Array in cols:
		var l := Tema.etiqueta(int(c[2]), c[3], String(c[0]))
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.custom_minimum_size = Vector2(absf(float(c[1])), 0)
		if float(c[1]) <= 0.0:
			l.custom_minimum_size.x = 140
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
	var accion := al_pulsar if al_pulsar.is_valid() else func() -> void: _destello(b)
	b.focus_entered.connect(func() -> void:
		_sonar("menu_mover")
		_activar_fila(b))
	b.mouse_entered.connect(func() -> void: b.grab_focus())
	b.gui_input.connect(func(ev: InputEvent) -> void:
		var clic := ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
		if clic or ev.is_action_pressed("ui_accept"):
			b.accept_event()
			accion.call())
	_contenido.add_child(b)
	return b

func _titulo_seccion(txt: String) -> void:
	var l := Tema.etiqueta(12, Tema.ORO, Idiomas.t(txt))
	l.custom_minimum_size = Vector2(0, 26)
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_contenido.add_child(l)

func _col_disp(k: String) -> bool:
	return dispositivo == k

func _pintar_parte(i: int) -> void:
	var parte: Array = ControlFC.MANUAL[i]
	_titulo.text = "%s  %s. %s" % [String(parte[1]), str(i + 1), Idiomas.t(String(parte[0]))]
	_subtitulo.text = Idiomas.t("Comando y botones en PlayStation, Xbox y teclado. Elige una fila para verla en el mando.")
	_cabecera_tabla([["COMANDO / ACCIÓN", 0, false], ["PLAYSTATION", 100, _col_disp("ps")], ["XBOX", 100, _col_disp("xbox")], ["TECLADO", 100, _col_disp("teclado")]])
	for f: Array in parte[2]:
		var fichas: Array = f[1]
		var accion := Idiomas.t(String(f[0]))
		if String(f[2]) != "":
			accion += "  ·  " + Idiomas.t(String(f[2]))
		_fila([[accion, 0, 13, Tema.TEXTO],
			[ControlFC.texto_fichas(fichas, "ps"), 100, 13, Color("ffd23f") if _col_disp("ps") else Color(1, 1, 1, 0.55)],
			[ControlFC.texto_fichas(fichas, "xbox"), 100, 13, Color("ffd23f") if _col_disp("xbox") else Color(1, 1, 1, 0.55)],
			[ControlFC.texto_fichas(fichas, "teclado"), 100, 13, Color("ffd23f") if _col_disp("teclado") else Color(1, 1, 1, 0.55)]], fichas)

func _pintar_filigranas() -> void:
	_titulo.text = "✨  7. " + Idiomas.t("Filigranas (skills)")
	_subtitulo.text = Idiomas.t("Arriba, abajo y los lados son respecto a donde mira tu futbolista. Cada jugador tiene de 1 a 5★ según su regate: si la filigrana pide más estrellas, le sale mal y pierde el balón.")
	var lista: Array = ControlFC.FILIGRANAS.keys()
	lista.sort_custom(func(a: String, b: String) -> bool:
		var ea := int(ControlFC.FILIGRANAS[a][1])
		var eb := int(ControlFC.FILIGRANAS[b][1])
		return ea < eb or (ea == eb and String(ControlFC.FILIGRANAS[a][0]) < String(ControlFC.FILIGRANAS[b][0])))
	var previa := 0
	for id: String in lista:
		var f: Array = ControlFC.FILIGRANAS[id]
		if int(f[1]) != previa:
			previa = int(f[1])
			_titulo_seccion("★".repeat(previa) + "☆".repeat(5 - previa))
		var como := Idiomas.t(String(f[3]))
		## Los modificadores, con los nombres del mando elegido.
		var disp_txt := dispositivo
		for pieza: Array in [["LB", "jugar_cambiar"], ["RB", "jugar_mod"], ["LT", "jugar_regate"]]:
			como = como.replace(String(pieza[0]), ControlFC.texto_ficha(String(pieza[1]), disp_txt))
		if dispositivo == "ps":
			como = como.replace("stick derecho", "joystick derecho").replace("stick izquierdo", "joystick izquierdo")
		elif dispositivo == "teclado":
			como = como.replace("stick derecho", "teclado numérico (8/4/6/2)").replace("stick izquierdo", "WASD")
		_fila([["★".repeat(int(f[1])), 64, 13, Tema.ORO], [Idiomas.t(String(f[0])), 200, 13, Tema.TEXTO], [como, 0, 13, Color(1, 1, 1, 0.78)]], f[2])

## Cuántas filas de acción reasignable tiene la sección «Asignar botones».
func filas_de_acciones() -> int:
	var n := 0
	for g: Array in GRUPOS:
		for a: String in g[1]:
			if Mando.MAPA.has(a):
				n += 1
	return n

func _pintar_asignar() -> void:
	_titulo.text = "🎮  " + Idiomas.t("Asignar botones")
	_subtitulo.text = Idiomas.t("Elige una acción y pulsa la tecla o el botón nuevo (Supr cancela). Si ese botón ya hacía otra cosa, se le quita a la otra.")
	_cabecera_tabla([["ACCIÓN", 0, false], ["TECLADO", 130, _col_disp("teclado")], ["MANDO", 110, dispositivo != "teclado"]])
	var disp_mando := "ps" if dispositivo == "ps" else "xbox"
	for g: Array in GRUPOS:
		_titulo_seccion(String(g[0]).to_upper())
		for accion: String in g[1]:
			if not Mando.MAPA.has(accion):
				continue
			var escucha := _escuchando == accion
			var tec_txt := Mando.texto_de(accion).split("  ·  🎮 ")[0]
			var man_txt := ControlFC.boton_de(accion, disp_mando)
			var b := _fila([[_nombres_disp(Idiomas.t(String(Mando.MAPA[accion][0]))), 0, 13, Tema.TEXTO],
				[Idiomas.t("Pulsa una tecla o un botón…") if escucha else tec_txt, 130, 13, Color("ffd23f") if escucha else Tema.ORO],
				["" if escucha else (man_txt if man_txt != "" else "—"), 110, 13, Color("8fd3ff")]], [accion],
				func() -> void: _escuchar(accion))
			b.set_meta("accion", accion)
			if escucha:
				var tw := b.create_tween().set_loops()
				tw.tween_property(b, "modulate", Color(1.25, 1.15, 0.8), 0.35)
				tw.tween_property(b, "modulate", Color.WHITE, 0.35)

func _escuchar(accion: String) -> void:
	_escuchando = accion
	_sonar("menu_aceptar")
	_aviso.text = Idiomas.t("Esperando la tecla o el botón para «%s»…") % Idiomas.t(String(Mando.MAPA[accion][0]))
	_repintar_conservando(accion)

func _pintar_ayudas() -> void:
	_titulo.text = "⚙  " + Idiomas.t("Ayudas y esquema")
	_subtitulo.text = Idiomas.t("Cuánto te ayuda el juego al pasar, tirar y cambiar de jugador, y qué teclas usa el teclado.")
	_titulo_seccion("ESQUEMA DE TECLADO")
	for e: String in Mando.ESQUEMAS:
		var elegido := e == Mando.esquema
		_fila([[("◉  " if elegido else "○  ") + Idiomas.t(String(Mando.ESQUEMAS[e]["nombre"])), 0, 14, Color("ffd23f") if elegido else Tema.TEXTO]], [],
			func() -> void:
				if Mando.esquema != e:
					Mando.fijar_esquema(e)
					_marcar_cambio(Idiomas.t("Esquema de teclado: %s") % Idiomas.t(String(Mando.ESQUEMAS[e]["nombre"])))
					_repintar_conservando("esq_" + e)).set_meta("clave", "esq_" + e)
	for k: String in Mando.AYUDAS:
		_titulo_seccion(String(NOMBRES_AYUDA[k][0]).to_upper())
		for op: String in Mando.AYUDAS[k]:
			var sel := Mando.ayuda(k) == op
			_fila([[("◉  " if sel else "○  ") + Idiomas.t(String((NOMBRES_AYUDA[k][1] as Dictionary).get(op, op))), 0, 14, Color("ffd23f") if sel else Tema.TEXTO]], [],
				func() -> void:
					if Mando.ayuda(k) != op:
						Mando.fijar_ayuda(k, op)
						_marcar_cambio(Idiomas.t("%s: %s") % [Idiomas.t(String(NOMBRES_AYUDA[k][0])), Idiomas.t(String((NOMBRES_AYUDA[k][1] as Dictionary).get(op, op)))])
						_repintar_conservando("ay_" + k + "_" + op)).set_meta("clave", "ay_" + k + "_" + op)

## Vuelve a pintar sin perder la fila con el foco, y la hace destellar.
func _repintar_conservando(clave: String) -> void:
	var scroll := _scroll.scroll_vertical
	_pintar()
	for h in _contenido.get_children():
		if (h.has_meta("accion") and String(h.get_meta("accion")) == clave) or (h.has_meta("clave") and String(h.get_meta("clave")) == clave):
			h.modulate.a = 1.0
			for x in _contenido.get_children():
				(x as CanvasItem).modulate.a = 1.0
			_scroll.scroll_vertical = scroll
			(h as Control).grab_focus.call_deferred()
			_destello.call_deferred(h)
			return
	_scroll.scroll_vertical = scroll

## El valor cambiado destella en verde y salta un poco.
func _destello(c: Control) -> void:
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "scale", Vector2(1.02, 1.08), 0.08)
	tw.tween_property(c, "self_modulate", Color(0.6, 1.6, 0.8), 0.08)
	tw.chain().tween_property(c, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(c, "self_modulate", Color.WHITE, 0.35)

func _marcar_cambio(texto: String) -> void:
	_cambios = true
	_aviso.text = texto
	_sonar("menu_cambio")
	if not _sin_guardar.visible:
		_sin_guardar.visible = true
		var tw := _sin_guardar.create_tween().set_loops()
		tw.tween_property(_sin_guardar, "modulate:a", 0.45, 0.6)
		tw.tween_property(_sin_guardar, "modulate:a", 1.0, 0.6)

# ------------------------------------------------------------------ foco y mando

## El selector dorado va a la fila con el foco y el scroll la sigue, suave.
func _activar_fila(b: Control) -> void:
	_fila_activa = b
	var fichas: Array = b.get_meta("fichas", [])
	_iluminar(fichas)
	_selector.visible = true
	var destino := Rect2(b.position, b.size)
	if is_instance_valid(_tw_selector):
		_tw_selector.kill()
	if _selector.size.x < 1.0:
		_selector.position = destino.position
		_selector.size = destino.size
	_tw_selector = create_tween().set_parallel(true)
	_tw_selector.tween_property(_selector, "position", destino.position, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tw_selector.tween_property(_selector, "size", destino.size, 0.16)
	var arriba := b.position.y - 30.0
	var abajo := b.position.y + b.size.y + 30.0 - _scroll.size.y
	var objetivo := _scroll.scroll_vertical
	if arriba < _scroll.scroll_vertical:
		objetivo = int(maxf(arriba, 0.0))
	elif abajo > _scroll.scroll_vertical:
		objetivo = int(abajo)
	if objetivo != _scroll.scroll_vertical:
		if is_instance_valid(_tw_scroll):
			_tw_scroll.kill()
		_tw_scroll = create_tween()
		_tw_scroll.tween_property(_scroll, "scroll_vertical", objetivo, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _iluminar(fichas: Array) -> void:
	var piezas: Array = []
	var teclas: Array = []
	for f: String in fichas:
		piezas.append_array(ControlFC.piezas_de(f))
		var ff := f.trim_prefix("mant:").trim_prefix("2x:")
		match ff:
			"LS": teclas.append_array(Mando.teclas_de("jugar_arriba") + Mando.teclas_de("jugar_izquierda") + Mando.teclas_de("jugar_abajo") + Mando.teclas_de("jugar_derecha"))
			"RS", "RS_toque", "RS_giro": teclas.append_array([KEY_KP_8, KEY_KP_4, KEY_KP_6, KEY_KP_2])
			_:
				if Mando.MAPA.has(ff):
					teclas.append_array(Mando.teclas_de(ff))
	_mando.iluminadas = piezas
	_mando.teclas_iluminadas = teclas
	_mando.queue_redraw()

## Lo que hace cada botón en la sección que se mira (para el dibujo).
## Los nombres de botón dentro de un texto, en el idioma del mando elegido.
func _nombres_disp(txt: String) -> String:
	if dispositivo != "ps":
		return txt
	return txt.replace("RB", "R1").replace("LB", "L1").replace("LT", "L2").replace("RT", "R2")

func _etiquetas_mando() -> void:
	var et := {}
	var filas: Array = []
	if _pestana.begins_with("p"):
		filas = (ControlFC.MANUAL[int(_pestana.substr(1))] as Array)[2]
	else:
		## Fuera del manual: lo de cada acción en su forma corta.
		for a: String in Mando.MAPA:
			if a in ["jugar_arriba", "jugar_abajo", "jugar_izquierda", "jugar_derecha"] or a.begins_with("jugar_fili_"):
				continue
			filas.append([_nombres_disp(String(Mando.MAPA[a][0])).get_slice(" · ", 0).get_slice(" (", 0), [a], ""])
	for f: Array in filas:
		var fichas: Array = f[1]
		var nombre := Idiomas.t(String(f[0])).get_slice(" (", 0).get_slice(" / ", 0)
		var ultima: String = fichas[fichas.size() - 1] if not fichas.is_empty() else ""
		if dispositivo == "teclado":
			var ff := ultima.trim_prefix("mant:").trim_prefix("2x:")
			if Mando.MAPA.has(ff):
				for k: int in Mando.teclas_de(ff):
					if not et.has(str(k)):
						et[str(k)] = nombre
			continue
		for pz: String in ControlFC.piezas_de(ultima):
			if pz != "" and not et.has(pz):
				et[pz] = nombre
	## Los botones que no salen en la sección, con su papel general.
	if dispositivo == "teclado":
		for a: String in ["jugar_arriba", "jugar_izquierda", "jugar_abajo", "jugar_derecha"]:
			for k: int in Mando.teclas_de(a):
				if not et.has(str(k)):
					et[str(k)] = Idiomas.t("Moverse")
		for k2: int in [KEY_KP_8, KEY_KP_4, KEY_KP_6, KEY_KP_2]:
			if not et.has(str(k2)):
				et[str(k2)] = Idiomas.t("Filigranas")
	else:
		if not et.has("LS"):
			et["LS"] = Idiomas.t("Moverse")
		if not et.has("RS"):
			et["RS"] = Idiomas.t("Filigranas")
	if dispositivo != "teclado":
		for a: String in Mando.MAPA:
			for pz: String in ControlFC.piezas_de(a):
				if pz != "" and not et.has(pz):
					et[pz] = _nombres_disp(Idiomas.t(String(Mando.MAPA[a][0]))).get_slice(" · ", 0).get_slice(" (", 0)
	## Los sticks hacen dos cosas: moverse / filigranas y, al hundirlos, otra.
	if dispositivo != "teclado":
		if not _pestana.begins_with("p") or not et.has("LS") or String(et["LS"]).begins_with("Pedir"):
			et["LS"] = Idiomas.t("Moverse · hundir: pedir")
		if not _pestana.begins_with("p") or not et.has("RS") or String(et["RS"]).begins_with("Autopase"):
			et["RS"] = Idiomas.t("Filigranas · hundir: sombrero")
	_mando.etiquetas = et
	_mando.iluminadas = []
	_mando.teclas_iluminadas = []
	_mando.queue_redraw()

func _enfocar_primera_fila() -> void:
	for h in _contenido.get_children():
		if h.has_meta("fila"):
			(h as Control).grab_focus()
			return

func _cambiar_seccion(paso: int) -> void:
	var lista := _secciones()
	var i := 0
	for k in lista.size():
		if String(lista[k][0]) == _pestana:
			i = k
	i = wrapi(i + paso, 0, lista.size())
	_ir_a(String(lista[i][0]))
	(_items_menu[_pestana] as Control).grab_focus()

# ------------------------------------------------------------------ entrada

func _input(ev: InputEvent) -> void:
	if _dialogo != null:
		if ev.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_cerrar_dialogo()
		return
	if _escuchando == "":
		if ev.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_volver()
			return
		## Cambiar de sección: LB/RB (o L1/R1) y Re Pág / Av Pág.
		var izq := (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_LEFT_SHOULDER) \
			or (ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_PAGEUP)
		var der := (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_RIGHT_SHOULDER) \
			or (ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_PAGEDOWN)
		if izq or der:
			get_viewport().set_input_as_handled()
			_cambiar_seccion(-1 if izq else 1)
		## Con el foco en el menú, «derecha» entra en la tabla.
		elif ev.is_action_pressed("ui_right") and get_viewport().gui_get_focus_owner() in _items_menu.values():
			get_viewport().set_input_as_handled()
			_enfocar_primera_fila()
		elif ev.is_action_pressed("ui_left") and get_viewport().gui_get_focus_owner() != null and _contenido.is_ancestor_of(get_viewport().gui_get_focus_owner()):
			get_viewport().set_input_as_handled()
			(_items_menu[_pestana] as Control).grab_focus()
		return
	var vale := (ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo) \
		or (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed)
	if not vale:
		return
	get_viewport().set_input_as_handled()
	var accion := _escuchando
	if ev is InputEventKey and (ev as InputEventKey).keycode == KEY_DELETE:
		_escuchando = ""
		_aviso.text = ""
		_sonar("menu_atras")
		_repintar_conservando(accion)
		return
	_escuchando = ""
	Mando.reasignar(accion, ev)
	_marcar_cambio(Idiomas.t("«%s» ahora es: %s") % [Idiomas.t(String(Mando.MAPA[accion][0])), Mando.texto_de(accion)])
	if is_inside_tree():
		_repintar_conservando(accion)

# ------------------------------------------------------------------ guardar

func _pedir_guardar() -> void:
	if not _cambios:
		_sonar("menu_aceptar")
		_aviso.text = Idiomas.t("No hay cambios que guardar.")
		return
	_preguntar(Idiomas.t("¿Guardar los cambios?"), Idiomas.t("¿Seguro que quieres guardar la nueva configuración de controles? Se usará en todos los partidos."),
		[[Idiomas.t("💾  Sí, guardar"), func() -> void: _guardar(false)], [Idiomas.t("Cancelar"), Callable()]])

func _guardar(y_salir: bool) -> void:
	Mando.guardar()
	Mando.aplicar()
	_foto = {"propio": Mando.propio.duplicate(true), "esquema": Mando.esquema, "ayudas": Mando.ayudas.duplicate()}
	_cambios = false
	_sin_guardar.visible = false
	_sonar("guardado")
	_aviso.text = Idiomas.t("✔ Controles guardados.")
	if y_salir:
		cerrar()

func _descartar() -> void:
	Mando.propio = (_foto["propio"] as Dictionary).duplicate(true)
	Mando.esquema = String(_foto["esquema"])
	Mando.ayudas = (_foto["ayudas"] as Dictionary).duplicate()
	Mando.guardar()
	Mando.aplicar()
	_cambios = false
	cerrar()

func _pedir_restaurar() -> void:
	_preguntar(Idiomas.t("¿Restaurar de fábrica?"), Idiomas.t("Se vuelve a la configuración clásica de FC con todas las ayudas por defecto. Después puedes guardar o descartar."),
		[[Idiomas.t("↺  Restaurar"), func() -> void:
			Mando.restaurar()
			_marcar_cambio(Idiomas.t("Controles de fábrica (sin guardar todavía)."))
			_pintar()], [Idiomas.t("Cancelar"), Callable()]])

func _volver() -> void:
	if _cambios:
		_preguntar(Idiomas.t("Tienes cambios sin guardar"), Idiomas.t("¿Qué quieres hacer con ellos?"),
			[[Idiomas.t("💾  Guardar y salir"), func() -> void: _guardar(true)],
			[Idiomas.t("Descartar"), _descartar],
			[Idiomas.t("Seguir editando"), Callable()]])
		return
	cerrar()

## Un diálogo de confirmación con zoom de entrada; el primer botón tiene el foco.
func _preguntar(titulo: String, texto: String, botones: Array) -> void:
	_sonar("aviso")
	_dialogo = Control.new()
	_dialogo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dialogo)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.0)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogo.add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogo.add_child(centro)
	var caja := PanelContainer.new()
	var est := _estilo(Tema.TARJETA, Tema.RADIO_GRANDE, Tema.ORO)
	est.set_border_width_all(2)
	est.shadow_color = Color(0, 0, 0, 0.6)
	est.shadow_size = 18
	est.content_margin_left = 26
	est.content_margin_right = 26
	est.content_margin_top = 20
	est.content_margin_bottom = 20
	caja.add_theme_stylebox_override("panel", est)
	caja.custom_minimum_size = Vector2(520, 0)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	caja.add_child(v)
	v.add_child(Tema.etiqueta(22, Tema.ORO, titulo))
	var t := Tema.etiqueta(14, Tema.TEXTO, texto)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(fila)
	var primero: Button = null
	for par: Array in botones:
		var b := Button.new()
		b.text = String(par[0])
		b.custom_minimum_size = Vector2(0, 40)
		b.add_theme_font_size_override("font_size", 15)
		b.set_meta("sin_sonido", true)
		var accion: Callable = par[1]
		b.focus_entered.connect(_sonar.bind("menu_mover"))
		b.pressed.connect(func() -> void:
			_sonar("menu_aceptar")
			_cerrar_dialogo(false)
			if accion.is_valid():
				accion.call())
		fila.add_child(b)
		if primero == null:
			primero = b
	caja.pivot_offset = Vector2(260, 80)
	caja.scale = Vector2(0.9, 0.9)
	caja.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(velo, "color:a", 0.55, 0.2)
	tw.tween_property(caja, "modulate:a", 1.0, 0.18)
	tw.tween_property(caja, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if primero != null:
		primero.grab_focus.call_deferred()

func _cerrar_dialogo(con_sonido := true) -> void:
	if _dialogo == null:
		return
	if con_sonido:
		_sonar("menu_atras")
	var d := _dialogo
	_dialogo = null
	var tw := d.create_tween()
	tw.tween_property(d, "modulate:a", 0.0, 0.12)
	tw.tween_callback(d.queue_free)
	if _fila_activa != null and is_instance_valid(_fila_activa):
		_fila_activa.grab_focus.call_deferred()

func cerrar() -> void:
	_sonar("menu_atras")
	cerrado.emit()
	set_process_input(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)
