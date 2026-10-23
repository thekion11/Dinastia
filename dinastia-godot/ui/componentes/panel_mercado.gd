class_name PanelMercado
extends "res://ui/componentes/panel_mercado_p1.gd"
## (Parte 2 de 2 de `panel_mercado.gd`.)

# ── FILTROS ───────────────────────────────────────────────────────────────
func _pintar_filtros(mio: Club) -> void:
	var t := _lbl(11, COL_SUAVE)
	t.text = Idiomas.t("FILTRAR")
	add_child(t)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	add_child(fila)

	# Buscador por nombre
	var buscar := LineEdit.new()
	buscar.placeholder_text = Idiomas.t("Buscar por nombre…")
	buscar.text = _filtro_texto
	buscar.custom_minimum_size = Vector2(190, 0)
	buscar.add_theme_font_size_override("font_size", 11)
	buscar.text_changed.connect(func(v: String) -> void:
		_filtro_texto = v
		_repintar_lista(mio))
	fila.add_child(buscar)

	# Selector de línea
	var op := OptionButton.new()
	op.add_theme_font_size_override("font_size", 11)
	op.clip_text = true
	op.custom_minimum_size = Vector2(130, 0)
	op.add_item("Todas las líneas", 0)
	var grupos := ["POR", "DEF", "MED", "DEL"]
	for i in grupos.size():
		op.add_item(grupos[i], i + 1)
		if grupos[i] == _filtro_pos:
			op.selected = i + 1
	op.item_selected.connect(func(i: int) -> void:
		_filtro_pos = "" if i == 0 else grupos[i - 1]
		_repintar_lista(mio))
	fila.add_child(op)

	# Filtro de presupuesto
	var bp := Button.new()
	bp.text = Idiomas.t("Solo lo que puedo pagar")
	bp.toggle_mode = true
	bp.button_pressed = _filtro_pagables
	bp.add_theme_font_size_override("font_size", 11)
	bp.clip_text = true
	bp.custom_minimum_size = Vector2(150, 0)
	bp.pressed.connect(func() -> void:
		_filtro_pagables = not _filtro_pagables
		_repintar_lista(mio))
	fila.add_child(bp)

	add_child(HSeparator.new())

## Repinta todo el panel desde cero. Se llama desde Principal cada vez
## que cambia el mundo (avanzar semana, enviar oferta, etc.).
func pintar() -> void:
	for n in get_children():
		n.queue_free()
	if _mundo == null:
		return
	var mio := _mundo.mi_club()

	_pintar_estado_ventana()

	# ── Negociación activa (va antes de la lista de objetivos) ────────────
	if _mundo.mercado.negociacion != null:
		_pintar_mesa_negociacion(_mundo.mercado.negociacion)
		add_child(HSeparator.new())

	# ── Ofertas recibidas ─────────────────────────────────────────────────
	if not _mundo.mercado.ofertas_recibidas.is_empty():
		_pintar_ofertas_recibidas(mio)
		add_child(HSeparator.new())

	# ── Filtros + lista ───────────────────────────────────────────────────
	_pintar_filtros(mio)
	_pintar_lista(mio)

# ──────────────────────────────────────────────────────────────────────────
func inicializar(mundo: Mundo, paleta: Dictionary, ultimo: Dictionary = {}) -> void:
	_mundo          = mundo
	_ultimo_resultado = ultimo
	# Aplicar paleta del club activo
	if paleta.has("acento"): COL_ACENTO = paleta["acento"]
	if paleta.has("texto"):  COL_TEXTO  = paleta["texto"]
	if paleta.has("suave"):  COL_SUAVE  = paleta["suave"]
	if paleta.has("verde"):  COL_VERDE  = paleta["verde"]
	if paleta.has("rojo"):   COL_ROJO   = paleta["rojo"]
	if paleta.has("oro"):    COL_ORO    = paleta["oro"]
	pintar()
