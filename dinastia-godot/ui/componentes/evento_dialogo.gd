class_name EventoDialogo
extends EventoPantallaCompleta
## ESCENA CON DIÁLOGO A PANTALLA COMPLETA (10-11): los eventos del club (`EventosClub`: reunión con la directiva, semana del clásico, balance de
## mitad de liga). Encuadre de «escena»: arriba el LUGAR; a la izquierda, el retrato grande de QUIÉN habla; a la derecha, la CAJA DE DIÁLOGO
## con su nombre en una pestaña y el texto que se escribe solo; debajo, las respuestas en CRUZ (`SelectorDireccional`). Sin voz: todo en texto.
## Paleta noche (azul noche, blanco y el color del club). Emite `elegido(str(i))` con el índice de la respuesta.
var _texto: Label
var selector: SelectorDireccional

static func mostrar(pr: Principal, ev: Dictionary) -> EventoDialogo:
	var e := EventoDialogo.new()
	e.paleta_noche = true
	e.acento = SelectorDireccional.acento_legible(pr.COL_ACENTO)
	e._montar_base(pr)
	e._rellenar(pr, ev)
	return e

func _rellenar(pr: Principal, ev: Dictionary) -> void:
	_centro.custom_minimum_size = Vector2(900, 0)
	_centro.add_theme_constant_override("separation", 18)
	var lugar := etiqueta("▍ " + String(ev.get("lugar", "")).to_upper(), 15, acento.lightened(0.3), false)
	_centro.add_child(lugar)
	var cuerpo := HBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 26)
	_centro.add_child(cuerpo)
	cuerpo.add_child(_retrato(pr, ev))
	var der := VBoxContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.add_theme_constant_override("separation", 16)
	cuerpo.add_child(der)
	der.add_child(_caja_dialogo(ev))
	var textos: Array = []
	for op: Dictionary in ev.get("opciones", []):
		textos.append(String(op.get("txt", "")))
	selector = SelectorDireccional.crear(textos, acento, -1)
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.elegido.connect(func(i: int) -> void: elegido.emit(str(i)))
	der.add_child(selector)
	der.add_child(etiqueta(Idiomas.t("Analógico o flechas para apuntar · R2/A/Enter confirma · clic o toque directo"), 11, Color(SelectorDireccional.BLANCO, 0.55)))
	if selector.get_child_count() > 0:
		(selector.get_child(0) as Control).call_deferred("grab_focus")

## El retrato de quien habla: el busto del jugador (si es uno del plantel) o una cara de directivo/ayudante fija por su nombre.
func _retrato(pr: Principal, ev: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	var marco := PanelContainer.new()
	var sb := Tema.caja(SelectorDireccional.NOCHE_PANEL, Tema.RADIO_GRANDE, Color(acento, 0.8))
	sb.set_border_width_all(2)
	sb.set_content_margin_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 14
	marco.add_theme_stylebox_override("panel", sb)
	col.add_child(marco)
	var j: Jugador = ev.get("jugador", null)
	var tr: TextureRect
	if j != null:
		tr = pr._retrato(j, 200)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		tr = TextureRect.new()
		tr.texture = CaraDT.textura(CaraDT.look_de_nombre(String(ev.get("quien", ""))), 200)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(200, 220)
	marco.add_child(tr)
	col.add_child(etiqueta(String(ev.get("cargo", "")).to_upper(), 12, Color(SelectorDireccional.BLANCO, 0.6)))
	return col

## La caja de diálogo: pestaña con el nombre (color del club) y el texto, que se escribe letra a letra.
func _caja_dialogo(ev: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var pest := PanelContainer.new()
	pest.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sp := Tema.caja(acento.darkened(0.15), 0)
	sp.corner_radius_top_left = 8
	sp.corner_radius_top_right = 8
	sp.content_margin_left = 16; sp.content_margin_right = 16
	sp.content_margin_top = 4; sp.content_margin_bottom = 4
	pest.add_theme_stylebox_override("panel", sp)
	pest.add_child(etiqueta(String(ev.get("quien", "")), 16, SelectorDireccional.BLANCO, false, false))
	v.add_child(pest)
	var caja := PanelContainer.new()
	var sc := Tema.caja(Color(SelectorDireccional.NOCHE_PANEL, 0.95), 0, Color(SelectorDireccional.BLANCO, 0.15))
	sc.corner_radius_top_right = 10; sc.corner_radius_bottom_left = 10; sc.corner_radius_bottom_right = 10
	sc.border_width_top = 3
	sc.border_color = acento
	sc.set_content_margin_all(18)
	caja.add_theme_stylebox_override("panel", sc)
	_texto = etiqueta(String(ev.get("texto", "")), 19, SelectorDireccional.BLANCO, false)
	_texto.custom_minimum_size = Vector2(560, 92)
	caja.add_child(_texto)
	v.add_child(caja)
	if not Animar.reducidas():
		_texto.visible_ratio = 0.0
		create_tween().tween_property(_texto, "visible_ratio", 1.0, clampf(_texto.text.length() * 0.018, 0.5, 2.2))
	return v
