class_name TarjetaEvento
extends RefCounted
## LA TARJETA DE UN EVENTO DEL CALENDARIO (10-11): escudo del rival (o el icono del evento), una etiqueta chica (J12, COPA, MERCADO…) y el texto.
## La usan la fila «PRÓXIMOS» y la vista de varias semanas. `e` es un evento de `EventosFecha`. `siguiente` = el que viene primero (borde dorado).
## `ancho` > 0 fija el ancho mínimo y deja que el texto baje de línea (columnas del calendario); 0 = recortado en una línea (fila).

static func crear(e: Dictionary, siguiente: bool, ancho := 0) -> PanelContainer:
	var rival: Variant = e.get("rival")
	var probable := bool(e.get("probable", false))
	var tarjeta := PanelContainer.new()
	var est := Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.oro() if siguiente else Tema.BORDE)
	est.bg_color = Color("1d2c22") if siguiente else Tema.TARJETA
	est.set_border_width_all(2 if siguiente else 1)
	est.border_width_left = 4 if (e["tipo"] == "liga" and bool(e.get("local", true)) and not Tema.contraste) else est.border_width_left
	est.content_margin_left = 8
	est.content_margin_right = 10
	est.content_margin_top = 4
	est.content_margin_bottom = 4
	est.shadow_color = Color(0, 0, 0, 0.35)
	est.shadow_size = 4
	est.shadow_offset = Vector2(0, 2)
	tarjeta.add_theme_stylebox_override("panel", est)
	if ancho > 0:
		tarjeta.custom_minimum_size = Vector2(ancho, 0)
	if probable:
		tarjeta.modulate.a = 0.72   ## aún no es seguro: depende de seguir vivo en el torneo
	var celda := HBoxContainer.new()
	celda.add_theme_constant_override("separation", 6)
	tarjeta.add_child(celda)
	if rival is Club:
		var tr := TextureRect.new()
		tr.texture = Escudo.textura(rival, 28)
		tr.custom_minimum_size = Vector2(28, 28)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		celda.add_child(tr)
	else:
		var ico := Tema.etiqueta(Tema.TAM_TITULO, Tema.TEXTO, String(e["icono"]))
		ico.custom_minimum_size = Vector2(28, 28)
		ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ico.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		celda.add_child(ico)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	celda.add_child(col)
	var tipo_copa: bool = e["tipo"] == "copa" or e["tipo"] == "conti"
	var color_arriba := Tema.oro() if (siguiente or tipo_copa) else Tema.SUAVE
	col.add_child(Tema.etiqueta(Tema.TAM_ROTULO, color_arriba, String(e["etiqueta"]).to_upper() if e["tipo"] != "liga" else String(e["etiqueta"])))
	var texto := String(e["texto"])
	## (10-11, auditoría de gestión en el móvil) En el móvil no hay tooltip con el texto entero: en vez de recortarlo («Kondor-Pokal · Gru…»)
	## baja a una segunda línea, con un ancho fijo para que la fila no se estire.
	var movil := ancho <= 0 and EscalaMovil.es_tactil() and texto.length() > LARGO_FILA
	var abajo := Tema.etiqueta(Tema.TAM_ROTULO + 1, Tema.TEXTO, texto if (ancho > 0 or movil) else _corto(texto))
	if ancho > 0 or movil:
		abajo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if movil:
		abajo.max_lines_visible = 2
		abajo.custom_minimum_size.x = ANCHO_MOVIL
	col.add_child(abajo)
	tarjeta.tooltip_text = texto + ("\n" + Idiomas.t("Si sigues en el torneo") if probable else "")
	return tarjeta

## Texto recortado para que la fila quepa en pantallas angostas.
const LARGO_FILA := 18
const ANCHO_MOVIL := 132.0
static func _corto(texto: String) -> String:
	return texto if texto.length() <= LARGO_FILA else texto.substr(0, LARGO_FILA - 1) + "…"
