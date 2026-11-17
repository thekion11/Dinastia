class_name PantallaMaqueta
extends CanvasLayer
## LA BASE DE LAS PANTALLAS DE LA MAQUETA (17-11-2026): una capa a pantalla completa (encima de todo, nada de lo de abajo recibe clics ni foco), con su fondo
## (`FondoCine`), el fundido de entrada y los ayudantes para botones y rótulos con el estilo de la maqueta (`EstiloAvanzar`). Las pantallas de evento, el menú del
## partido, el resultado y los momentos heredan de aquí y rellenan `_raiz`. `elegido(op)` es la señal de salida; `terminado` para las que no eligen nada.

signal elegido(op: String)
signal terminado

var _raiz: Control
var fondo: FondoCine

func _init() -> void:
	layer = 58

## Monta la capa dentro de `pr` y devuelve el fondo. `modo`/`color` son los de `FondoCine`.
func montar(pr: Node, modo: FondoCine.Modo, color: Color, color_b := Color("1f8a4c"), bokeh := false) -> FondoCine:
	pr.add_child(self)
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_raiz)
	FocoMando.aislar_mientras(_raiz, pr)
	fondo = FondoCine.new()
	fondo.modo = modo
	fondo.color = color
	fondo.color_b = color_b
	fondo.bokeh = bokeh
	_raiz.add_child(fondo)
	if not Animar.reducidas():
		_raiz.modulate.a = 0.0
		create_tween().tween_property(_raiz, "modulate:a", 1.0, 0.35)
	return fondo

## Un botón de la maqueta: texto en mayúsculas condensado y en negrita; `rojo` = el principal (rojo del club), si no, azul marino.
static func boton(texto: String, rojo := false, tam := 22) -> Button:
	var b := Button.new()
	b.text = texto.to_upper()
	b.add_theme_font_override("font", EstiloAvanzar.fuente_titulo())
	b.add_theme_font_size_override("font_size", Tema.letra(tam))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.custom_minimum_size = Vector2(0, 54)
	var base := Color("c8102e") if rojo else Color("243656")
	var n := StyleBoxFlat.new()
	n.bg_color = base
	n.set_content_margin_all(0)
	n.content_margin_left = 26
	n.content_margin_right = 26
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = base.lightened(0.14)
	var f := h.duplicate() as StyleBoxFlat
	f.border_color = Color.WHITE
	f.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", f)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

## «A Confirmar · B Volver», la ayuda de mando de la maqueta, abajo a la izquierda.
func ayuda_mando(confirmar := "Confirmar", volver := "Volver") -> Control:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 22)
	for par: Array in [["A", confirmar, Color("27a35a")], ["B", volver, Color("e0592a")]]:
		var g := HBoxContainer.new()
		g.add_theme_constant_override("separation", 8)
		var c := Label.new()
		c.text = String(par[0])
		c.custom_minimum_size = Vector2(26, 26)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_theme_font_size_override("font_size", Tema.letra(13))
		c.add_theme_stylebox_override("normal", Tema.caja(par[2], 13))
		g.add_child(c)
		g.add_child(EstiloAvanzar.etiqueta(Idiomas.t(String(par[1])), 14, Color(1, 1, 1, 0.75)))
		f.add_child(g)
	return f

func cerrar() -> void:
	terminado.emit()
