extends Control
## [Capa 1/2 de `entrada_campeonato.gd`] Las piezas visuales de la pantalla de ENTRADA AL CAMPEONATO:
## tarjetas, cifras, botones y la capa de confirmación. La lógica (qué cifras, qué opción, qué se emite)
## vive en la capa 2; las reglas en `nucleo/entrada_campeonato.gd`.

const COL_FONDO := Tema.FONDO
const COL_PANEL := Tema.PANEL
const COL_TARJETA := Tema.TARJETA
const COL_BORDE := Tema.BORDE
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE
const COL_ORO := Tema.ORO
const COL_ACENTO := Tema.ACENTO
const COL_BIEN := Tema.BIEN
const COL_MAL := Tema.MAL

## Cómo se pinta cada cifra: a favor, en contra o neutra.
enum Tono { NEUTRO, BIEN, MAL }

func _caja(fondo: Color, borde: Color, ancho: int = 1, radio: int = Tema.RADIO_GRANDE, relleno: int = 18) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(ancho)
	e.set_corner_radius_all(radio)
	e.content_margin_left = relleno
	e.content_margin_right = relleno
	e.content_margin_top = relleno - 4
	e.content_margin_bottom = relleno - 4
	return e

func _etq(tam: int, color: Color, texto: String = "", envolver: bool = false) -> Label:
	var l := Tema.etiqueta(tam, color, texto)
	if envolver:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _color_tono(t: Tono) -> Color:
	return COL_BIEN if t == Tono.BIEN else (COL_MAL if t == Tono.MAL else COL_TEXTO)

## Un botón grande con el estilo del juego. `primario` lo pinta con el verde del club DINASTÍA.
func _boton(texto: String, primario: bool) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(220, 52)
	b.add_theme_font_size_override("font_size", Tema.TAM_DESTACADO + 2)
	var base := COL_ACENTO if primario else COL_TARJETA
	var normal := _caja(base, COL_BORDE if not primario else base.lightened(0.15), 1, Tema.RADIO, 16)
	var encima := _caja(base.lightened(0.12), COL_ORO if primario else COL_SUAVE, 1, Tema.RADIO, 16)
	var foco := _caja(base.lightened(0.06), COL_ORO, 2, Tema.RADIO, 16)
	var apagado := _caja(COL_PANEL, COL_BORDE, 1, Tema.RADIO, 16)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", encima)
	b.add_theme_stylebox_override("pressed", encima)
	b.add_theme_stylebox_override("focus", foco)
	b.add_theme_stylebox_override("disabled", apagado)
	b.add_theme_color_override("font_color", Color.WHITE if primario else COL_TEXTO)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", COL_SUAVE)
	return b

## La insignia redonda con la letra de la opción («A» / «B»).
func _insignia(letra: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _caja(color, color.lightened(0.2), 1, 28, 0))
	p.custom_minimum_size = Vector2(56, 56)
	var l := _etq(Tema.TAM_TITULO + 4, Color.WHITE, letra)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

## Una fila de la tabla de consecuencias: rótulo a la izquierda; cifra (y su explicación) a la derecha.
func _fila_cifra(grid: GridContainer, rotulo: String, valor: String, tono: Tono, nota: String = "") -> void:
	var r := _etq(Tema.TAM_CUERPO + 1, COL_SUAVE, rotulo)
	r.custom_minimum_size = Vector2(200, 0)
	r.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	grid.add_child(r)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	v.add_child(_etq(Tema.TAM_DESTACADO + 1, _color_tono(tono), valor, true))
	if nota != "":
		v.add_child(_etq(Tema.TAM_CUERPO - 1, COL_SUAVE, nota, true))
	grid.add_child(v)

func _vaciar(n: Node) -> void:
	for h in n.get_children():
		n.remove_child(h)
		h.queue_free()

## Un club de muestra (no entra en el mundo) para dibujar el escudo con el nombre y los colores elegidos.
func _club_muestra(datos: Dictionary) -> Club:
	var c := Club.new("entrada_muestra", String(datos.get("nombre", "")))
	var c1 := String(datos.get("color1", ""))
	var c2 := String(datos.get("color2", ""))
	c.color1 = c1 if c1 != "" else "#1e4030"
	c.color2 = c2 if c2 != "" else "#c9a227"
	return c

## La capa de confirmación: oscurece la pantalla y pide un sí explícito (no es otra etapa: es el
## «confirmación al rellenar» que pide el guion, dentro de la misma pantalla).
func _capa_confirmacion(titulo: Label, cuerpo: Label, si: Button, no: Button) -> Control:
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.62)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	panel.add_theme_stylebox_override("panel", _caja(COL_PANEL, COL_ORO, 2, Tema.RADIO_GRANDE, 32))
	centro.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	panel.add_child(v)
	v.add_child(titulo)
	v.add_child(cuerpo)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_END
	fila.add_theme_constant_override("separation", 14)
	fila.add_child(no)
	fila.add_child(si)
	v.add_child(fila)
	capa.visible = false
	return capa
