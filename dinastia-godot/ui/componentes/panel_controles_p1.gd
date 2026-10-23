extends Control
## [Capa 1/3 de `panel_controles.gd`] abrir, _sonar, _estilo, _mover_pastilla_menu, _mover_pastilla_disp, _pistas … (+15)

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

const CORTOS := ["Movimiento y regates", "Ataque y definición", "Defensa", "Portero y tácticas", "Balón parado", "Saques de banda"]

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

func _estilo(fondo: Color, radio := Tema.RADIO, borde := Tema.BORDE) -> StyleBoxFlat:
	var e := Tema.caja(fondo, radio, borde)
	return e

func _mover_pastilla_menu(b: Control) -> void:
	if _pastilla_menu == null:
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_pastilla_menu, "position:y", b.position.y, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_pastilla_menu, "size:x", _menu.size.x, 0.2)
	var elegido: bool = b == _items_menu.get(_pestana)
	(_pastilla_menu.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Tema.ORO.darkened(0.5) if elegido else Color(1, 1, 1, 0.07)

func _mover_pastilla_disp() -> void:
	var b: Button = _chips_disp.get(dispositivo)
	if b == null or _pastilla_disp == null:
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_pastilla_disp, "position:x", b.position.x + 4.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_pastilla_disp, "size:x", b.size.x - 8.0, 0.22)
	for k: String in _chips_disp:
		(_chips_disp[k] as Button).add_theme_color_override("font_color", Color("ffd23f") if k == dispositivo else Tema.TEXTO)

func _pistas() -> String:
	var acepta := "✖" if dispositivo == "ps" else ("A" if dispositivo == "xbox" else "Enter")
	var vuelve := "◯" if dispositivo == "ps" else ("B" if dispositivo == "xbox" else "Esc")
	var secc := "L1/R1" if dispositivo == "ps" else ("LB/RB" if dispositivo == "xbox" else "Re Pág/Av Pág")
	return Idiomas.t("%s elegir · %s volver · %s sección") % [acepta, vuelve, secc]

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

func _col_disp(k: String) -> bool:
	return dispositivo == k

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

func _titulo_seccion(txt: String) -> void:
	var l := Tema.etiqueta(12, Tema.ORO, Idiomas.t(txt))
	l.custom_minimum_size = Vector2(0, 26)
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_contenido.add_child(l)

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

## Lo que hace cada botón en la sección que se mira (para el dibujo).
## Los nombres de botón dentro de un texto, en el idioma del mando elegido.
func _nombres_disp(txt: String) -> String:
	if dispositivo != "ps":
		return txt
	return txt.replace("RB", "R1").replace("LB", "L1").replace("LT", "L2").replace("RT", "R2")

## Vuelve a pintar sin perder la fila con el foco, y la hace destellar.
func _repintar_conservando(clave: String) -> void:
	var scroll := _scroll.scroll_vertical
	(self as PanelControles)._pintar()
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

func _escuchar(accion: String) -> void:
	_escuchando = accion
	_sonar("menu_aceptar")
	_aviso.text = Idiomas.t("Esperando la tecla o el botón para «%s»…") % Idiomas.t(String(Mando.MAPA[accion][0]))
	_repintar_conservando(accion)

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

func _marcar_cambio(texto: String) -> void:
	_cambios = true
	_aviso.text = texto
	_sonar("menu_cambio")
	if not _sin_guardar.visible:
		_sin_guardar.visible = true
		var tw := _sin_guardar.create_tween().set_loops()
		tw.tween_property(_sin_guardar, "modulate:a", 0.45, 0.6)
		tw.tween_property(_sin_guardar, "modulate:a", 1.0, 0.6)

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
