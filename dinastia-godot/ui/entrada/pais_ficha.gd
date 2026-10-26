class_name PaisFicha
extends PanelContainer
## LA FICHA DEL PAÍS (columna derecha de la pantalla de país): su bandera, la liga con
## su nivel y la capital, y debajo los clubes de su primera división para elegir a cuál
## dirigir.
##
## «SI CREAS UN CLUB, NO SE MUESTRAN LOS DEMÁS» (plan, etapa 3): en el modo de crear
## club la lista de clubes NO se construye -no basta con ocultarla: así ni siquiera
## llega a existir un nodo con un club ajeno- y en su lugar va una nota que explica que
## el tuyo empezará de cero.
##
## Los clubes salen del MUNDO ya generado si lo hay (`estado["mundo"]`, con sus ids: lo
## que se elige aquí es lo que dirigirás); sin mundo -una prueba suelta- se leen de las
## mismas tablas con las que se genera, solo para enseñarlos.

signal club_elegido(club_id: String)

var club_id := ""
## Lo que se ve ahora (lo mira la prueba): nombres de los clubes listados.
var clubes_listados: Array[String] = []
var crear := false

var _bandera: TextureRect
var _liga: Label
var _nivel: Label
var _capital: Label
var _cuerpo: VBoxContainer
var _grupo := ButtonGroup.new()
var _club: Club = null

func _ready() -> void:
	add_theme_stylebox_override("panel", Tema.caja(Color(Tema.PANEL, 0.86), Tema.RADIO_GRANDE, Tema.BORDE))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 12)
	v.add_child(arriba)
	_bandera = TextureRect.new()
	_bandera.custom_minimum_size = Vector2(84, 56)
	_bandera.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bandera.stretch_mode = TextureRect.STRETCH_SCALE
	_bandera.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	arriba.add_child(_bandera)
	var datos := VBoxContainer.new()
	datos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	datos.add_theme_constant_override("separation", 2)
	arriba.add_child(datos)
	_liga = Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO)
	_liga.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	datos.add_child(_liga)
	_nivel = Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO)
	datos.add_child(_nivel)
	_capital = Tema.etiqueta(Tema.TAM_ROTULO + 1, Tema.SUAVE)
	datos.add_child(_capital)
	var linea := ColorRect.new()
	linea.color = Tema.BORDE
	linea.custom_minimum_size = Vector2(0, 1)
	v.add_child(linea)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_cuerpo = VBoxContainer.new()
	_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.add_theme_constant_override("separation", 3)
	scroll.add_child(_cuerpo)

func mostrar(p: String, crear_club: bool, mundo: Mundo) -> void:
	crear = crear_club
	_bandera.texture = Banderas.textura(p)
	var tiene := PaisDatos.tiene_liga(p)
	_liga.text = PaisDatos.nombre_liga(p) if tiene else Idiomas.t("Sin liga profesional")
	var n := PaisDatos.estrellas(p)
	_nivel.text = ("★".repeat(n) + "☆".repeat(5 - n)) if tiene else ""
	_nivel.tooltip_text = Idiomas.t("Nivel de la liga")
	_capital.text = Idiomas.t("Capital: %s") % Idiomas.t(String(Globo3D.CAPITAL.get(p, "?")))
	for h in _cuerpo.get_children():
		_cuerpo.remove_child(h)
		h.queue_free()
	clubes_listados.clear()
	club_id = ""
	_club = null
	if not tiene:
		_nota(Idiomas.t("Este país aún no tiene liga en el juego."), Idiomas.t("Elige otro país para empezar."))
		return
	if crear_club:
		_nota(Idiomas.t("Fundarás tu propio club en %s.") % PaisDatos.nombre(p),
			Idiomas.t("Los clubes que ya existen no se muestran: el tuyo empieza de cero."))
		return
	var rot := Tema.rotulo(Idiomas.t("Elige tu club"))
	rot.add_theme_color_override("font_color", Tema.ORO)
	_cuerpo.add_child(rot)
	var clubes := _clubes_de(p, mundo)
	for c: Club in clubes:
		_cuerpo.add_child(_fila(c))
		clubes_listados.append(c.nombre)
	if not clubes.is_empty():
		_marcar(clubes[0])

func _nota(titulo: String, texto: String) -> void:
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, titulo)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cuerpo.add_child(t)
	var s := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, texto)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cuerpo.add_child(s)

## Los de primera división, en el orden de su liga (el mismo de `club_por_defecto`: el
## primero de la lista es el que se dirige si no se toca nada).
func _clubes_de(p: String, mundo: Mundo) -> Array[Club]:
	var salida: Array[Club] = []
	if mundo != null:
		for l: Liga in mundo.ligas:
			if l.pais == p and l.division() == 1:
				salida.assign(l.clubes)
				return salida
	for fila: Array in PaisDatos.filas_clubes(p):
		var c := Club.new("", Nombres.de_tabla(String(fila[0])))
		c.pais = p
		c.color1 = String(fila[1]) if fila.size() > 1 else "#2b6b45"
		c.color2 = String(fila[2]) if fila.size() > 2 else "#ffffff"
		c.rep = int(fila[3]) if fila.size() > 3 else 70
		salida.append(c)
	return salida

func _fila(c: Club) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = _grupo
	b.custom_minimum_size = Vector2(0, 34)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = c.nombre
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.03)
	normal.set_corner_radius_all(Tema.RADIO_CHICO)
	var encima := normal.duplicate() as StyleBoxFlat
	encima.bg_color = Color(1, 1, 1, 0.08)
	var marcado := normal.duplicate() as StyleBoxFlat
	marcado.bg_color = Color(Tema.ORO, 0.2)
	marcado.border_color = Tema.ORO
	marcado.set_border_width_all(1)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", encima)
	b.add_theme_stylebox_override("pressed", marcado)
	b.add_theme_stylebox_override("hover_pressed", marcado)
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.offset_right = -10
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(c, 26)
	esc.custom_minimum_size = Vector2(24, 26)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(esc)
	var nom := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, c.nombre)
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nom.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nom.clip_text = true
	nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(nom)
	var rep := Tema.etiqueta(Tema.TAM_ROTULO + 1, Tema.SUAVE, str(c.rep))
	rep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(rep)
	b.set_meta("club", c)
	b.pressed.connect(func() -> void: _marcar(c))
	return b

func _marcar(c: Club) -> void:
	club_id = c.id
	_club = c
	## Sin señal, el ButtonGroup no suelta al anterior: se marca uno y se sueltan los demás.
	for b in _cuerpo.get_children():
		if b is Button:
			(b as Button).set_pressed_no_signal(b.get_meta("club", null) == c)
	club_elegido.emit(c.id)

## El club marcado ahora (o null): para el texto de la confirmación.
func club_marcado() -> Club:
	return _club
