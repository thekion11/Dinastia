class_name TemaMenuSecciones
extends RefCounted
## Secciones del tema de los menús (sacadas de `tema_menu.gd` para no pasar de 450 líneas).
## Cada una recibe el Theme `t`, la pantalla `p` y la paleta `m` ({panel, texto, suave, borde, radio, reposo}).

## Bloque del tema (ver `_aplicar_tema`): _tema_botones.
static func _tema_botones(t: Theme, p, m: Dictionary) -> void:
	var panel: Color = m["panel"]
	var texto: Color = m["texto"]
	var suave: Color = m["suave"]
	var borde: Color = m["borde"]
	var radio: int = m["radio"]
	var reposo: Color = m["reposo"]
	## (10-11, estética) Con RELIEVE (`ProfundidadUI`): sombra en reposo, más al pasar por encima, y pulsado se hunde.
	t.set_stylebox("normal", "Button", ProfundidadUI.relieve(p._caja(reposo, borde, radio, 1)))
	t.set_stylebox("hover", "Button", ProfundidadUI.relieve(p._caja(p._mezcla(panel, texto, 0.24), borde, radio, 1), true))
	t.set_stylebox("pressed", "Button", ProfundidadUI.hundido(p._caja(p._mezcla(panel, p.col_acento, 0.45), p.col_acento, radio, 1)))
	t.set_stylebox("focus", "Button", p._caja(Color(0, 0, 0, 0), p.col_acento, radio, 2))
	t.set_stylebox("disabled", "Button", p._caja(p._mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_color("font_color", "Button", texto)
	t.set_color("font_hover_color", "Button", texto)
	t.set_color("font_pressed_color", "Button", texto)
	t.set_color("font_disabled_color", "Button", p._mezcla(suave, panel, 0.5))
	## (9-11, estética) Letra base de los botones = 13 (con la escala de texto de Ajustes): sin esto usaban los 16 de fábrica y
	## desentonaban con las etiquetas (14) y los botones con tamaño propio (12-13) de la misma fila.
	for clase_b: String in ["Button", "OptionButton", "MenuButton", "CheckBox", "CheckButton"]:
		t.set_font_size("font_size", clase_b, Tema.letra(13))


## Bloque del tema (ver `_aplicar_tema`): _tema_desplegables.
static func _tema_desplegables(t: Theme, p, m: Dictionary) -> void:
	var panel: Color = m["panel"]
	var texto: Color = m["texto"]
	var borde: Color = m["borde"]
	var radio: int = m["radio"]
	var reposo: Color = m["reposo"]
	## Los desplegables y las casillas heredan del botón: en Godot son clases
	## distintas y si no se les dice nada se quedan con el tema oscuro de fábrica.
	for clase: String in ["OptionButton", "MenuButton", "CheckBox", "CheckButton"]:
		t.set_stylebox("normal", clase, ProfundidadUI.relieve(p._caja(reposo, borde, radio, 1)))
		t.set_stylebox("hover", clase, ProfundidadUI.relieve(p._caja(p._mezcla(panel, texto, 0.24), borde, radio, 1), true))
		t.set_stylebox("pressed", clase, ProfundidadUI.hundido(p._caja(p._mezcla(panel, p.col_acento, 0.45), p.col_acento, radio, 1)))
		## (10-11, estética) el mismo FOCO y DESACTIVADO que el botón: los desplegables y casillas usaban los de fábrica (otro color y grosor)
		t.set_stylebox("focus", clase, p._caja(Color(0, 0, 0, 0), p.col_acento, radio, 2))
		t.set_stylebox("disabled", clase, p._caja(p._mezcla(panel, texto, 0.05), borde, radio, 1))
		t.set_color("font_color", clase, texto)
		t.set_color("font_hover_color", clase, texto)


## Bloque del tema (ver `_aplicar_tema`): _tema_pestanas.
static func _tema_pestanas(t: Theme, p, m: Dictionary) -> void:
	var panel: Color = m["panel"]
	var texto: Color = m["texto"]
	var suave: Color = m["suave"]
	var borde: Color = m["borde"]
	var radio: int = m["radio"]
	## Las pestañas. El fondo de la hoja es EL panel, sin borde: encima van las
	## tarjetas, y dos bordes pegados uno dentro de otro se ven como un error.
	var hoja: StyleBoxFlat = p._caja(panel, borde, radio, 0)
	hoja.content_margin_left = 6
	hoja.content_margin_right = 6
	hoja.content_margin_top = 6
	hoja.content_margin_bottom = 6
	t.set_stylebox("panel", "TabContainer", hoja)
	t.set_stylebox("tabbar_background", "TabContainer", p._caja(Color(0, 0, 0, 0), borde, 0, 0))
	t.set_stylebox("tab_selected", "TabContainer", p._caja(p._mezcla(panel, p.col_acento, 0.30), p.col_acento, radio, 1))
	t.set_stylebox("tab_unselected", "TabContainer", p._caja(p._mezcla(panel, texto, 0.06), borde, radio, 1))
	t.set_stylebox("tab_hovered", "TabContainer", p._caja(p._mezcla(panel, texto, 0.18), borde, radio, 1))
	t.set_color("font_selected_color", "TabContainer", texto)
	t.set_color("font_unselected_color", "TabContainer", suave)
	t.set_color("font_hovered_color", "TabContainer", texto)


## Bloque del tema (ver `_aplicar_tema`): _tema_paneles.
static func _tema_paneles(t: Theme, p, m: Dictionary) -> void:
	var panel: Color = m["panel"]
	var texto: Color = m["texto"]
	var borde: Color = m["borde"]
	var radio: int = m["radio"]
	t.set_stylebox("panel", "Panel", p._caja(panel, borde, radio, 1))
	t.set_stylebox("panel", "PanelContainer", p._caja(panel, borde, radio, 1))
	t.set_stylebox("panel", "PopupPanel", p._caja(p._mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_stylebox("panel", "PopupMenu", p._caja(p._mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_color("font_color", "PopupMenu", texto)
	t.set_color("font_hover_color", "PopupMenu", texto)


## Bloque del tema (ver `_aplicar_tema`): _tema_campos.
static func _tema_campos(t: Theme, p, m: Dictionary) -> void:
	var panel: Color = m["panel"]
	var texto: Color = m["texto"]
	var suave: Color = m["suave"]
	var borde: Color = m["borde"]
	var radio: int = m["radio"]
	## Los campos de texto. El fondo va al REVÉS que el botón -hacia el fondo, no
	## hacia el texto- porque un cuadro donde se escribe tiene que verse hundido.
	var hueco: StyleBoxFlat = p._caja(p._mezcla(panel, p._pal_fondo(), 0.55), borde, radio, 1)
	for clase2: String in ["LineEdit", "TextEdit", "SpinBox"]:
		t.set_stylebox("normal", clase2, hueco)
		t.set_color("font_color", clase2, texto)
		t.set_color("font_placeholder_color", clase2, suave)
		t.set_color("caret_color", clase2, p.col_acento)
	t.set_stylebox("focus", "LineEdit", p._caja(p._mezcla(panel, p._pal_fondo(), 0.55), p.col_acento, radio, 2))


## Bloque del tema (ver `_aplicar_tema`): _tema_barras.
static func _tema_barras(t: Theme, p, m: Dictionary) -> void:
	var panel: Color = m["panel"]
	var texto: Color = m["texto"]
	var borde: Color = m["borde"]
	var radio: int = m["radio"]
	## Barras y deslizadores.
	TemaSliders.aplicar(t, p.col_acento, p._mezcla(panel, p._pal_fondo(), 0.5), borde, p.get_tree())   ## deslizadores gruesos (pista 8, tirador 28, área 44)
	t.set_stylebox("background", "ProgressBar", p._caja(p._mezcla(panel, p._pal_fondo(), 0.5), borde, 3, 0))
	t.set_stylebox("fill", "ProgressBar", p._caja(p.col_acento, p.col_acento, 3, 0))

	t.set_color("default_color", "RichTextLabel", texto)
	t.set_color("font_color", "Label", texto)
	t.set_color("font_color", "ItemList", texto)
	t.set_stylebox("panel", "ItemList", p._caja(p._mezcla(panel, p._pal_fondo(), 0.4), borde, radio, 1))
	t.set_color("font_color", "Tree", texto)
	t.set_stylebox("panel", "Tree", p._caja(p._mezcla(panel, p._pal_fondo(), 0.4), borde, radio, 1))
