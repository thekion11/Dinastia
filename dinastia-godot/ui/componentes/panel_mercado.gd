class_name PanelMercado
extends "res://ui/componentes/panel_mercado_p1.gd"
## [Capa 2/2 de `panel_mercado.gd`] _pintar_filtros, _fila_ajuste, _pintar_mesa_negociacion, _pintar_termometro, _pintar_resultado_ronda, pintar, inicializar

## El botón que tenía el foco antes de repintar (su meta «foco»). Cada «+» de la
## mesa repinta el panel entero; sin esto, con teclado o mando el foco se perdía
## en cada pulsación y había que volver a bajar hasta el campo.
var _foco := ""

# ── FILTROS ───────────────────────────────────────────────────────────────
## En un `HFlowContainer` y no en una fila: a 1280×720 los tres controles no
## caben en la columna central y el último se salía por la derecha.
func _pintar_filtros(mio: Club) -> void:
	var t := _lbl(11, COL_SUAVE)
	t.text = Idiomas.t("FILTRAR")
	add_child(t)

	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 6)
	fila.add_theme_constant_override("v_separation", 4)
	add_child(fila)

	# Buscador por nombre
	var buscar := LineEdit.new()
	buscar.placeholder_text = Idiomas.t("Buscar por nombre…")
	buscar.text = _filtro_texto
	buscar.custom_minimum_size = Vector2(180, 0)
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
	op.add_item(Idiomas.t("Todas las líneas"), 0)
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
	bp.pressed.connect(func() -> void:
		_filtro_pagables = not _filtro_pagables
		_repintar_lista(mio))
	fila.add_child(bp)

	add_child(HSeparator.new())

## Marca un botón para devolverle el foco tras el repintado que provoca.
func _con_foco(b: Button, clave: String) -> void:
	b.set_meta("foco", clave)
	b.pressed.connect(func() -> void: _foco = clave)

func _fila_ajuste(g: GridContainer, etiqueta: String, valor_txt: String, campo: String) -> void:
	var et := _lbl(11, COL_SUAVE)
	et.text = etiqueta
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(et)
	var signos := {"−": -1, "+": 1}
	for s: String in signos:
		var b := Button.new()
		b.text = s
		b.custom_minimum_size = Vector2(30, 26)
		b.add_theme_font_size_override("font_size", 13)
		b.tooltip_text = (Idiomas.t("Bajar: %s") if signos[s] < 0 else Idiomas.t("Subir: %s")) % etiqueta
		var d: int = signos[s]
		_con_foco(b, campo + s)
		b.pressed.connect(func() -> void: campo_ajustado.emit(campo, d))
		g.add_child(b)
		if s == "−":
			var va := _lbl(12, COL_TEXTO)
			va.text = valor_txt
			va.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			va.custom_minimum_size = Vector2(96, 0)
			g.add_child(va)

func _rejilla_ajustes() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 3)
	add_child(g)
	return g

# ── MESA DE NEGOCIACIÓN ───────────────────────────────────────────────────
func _pintar_mesa_negociacion(n: Negociacion) -> void:
	var vendedor: Club = _mundo.clubes.get(n.club_vendedor_id)
	var t := _lbl(12, COL_ORO)
	t.text = Idiomas.t("MESA DE NEGOCIACIÓN  ·  %s  (%s)  ·  ronda %d") % [
		n.jugador.nombre if n.jugador else "—", vendedor.nombre if vendedor else "?", n.ronda]
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(t)

	if n.rival_id != "":
		var av := _lbl(11, COL_ROJO)
		av.text = Idiomas.t("Otro club anda detrás de él: cuanto más se alargue la mesa, más riesgo de perderlo.")
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(av)

	_pintar_resultado_ronda(n)
	_dato(Idiomas.t("Piden"), _dinero(n.pedido), COL_SUAVE)
	_dato(Idiomas.t("Perciben con tu oferta actual"), _dinero(n.valor_percibido()), COL_TEXTO)
	var col_costo := COL_TEXTO if n.costo_inmediato() <= _mundo.mi_club().saldo else COL_ROJO
	_dato(Idiomas.t("Sale de tu caja hoy"), _dinero(n.costo_inmediato()), col_costo)
	_pintar_termometro(n)

	# ── CON EL CLUB ───────────────────────────────────────────────────────
	var tc := _lbl(11, COL_SUAVE)
	tc.text = Idiomas.t("CON EL CLUB")
	add_child(tc)
	var gc := _rejilla_ajustes()
	_fila_ajuste(gc, Idiomas.t("Fijo"), _dinero(n.fijo), "fijo")
	_fila_ajuste(gc, Idiomas.t("Cuotas"), _dinero(n.cuotas), "cuotas")
	_fila_ajuste(gc, Idiomas.t("Bonos por objetivos"), _dinero(n.bonos), "bonos")
	_fila_ajuste(gc, Idiomas.t("% de venta futura"), "%d%%" % n.pct, "pct")
	_fila_ajuste(gc, Idiomas.t("Pago bajo cuerda"), _dinero(n.opaco), "opaco")
	var pista := _lbl(10, COL_SUAVE)
	pista.text = Idiomas.t("Para el club pesa más el fijo: lo aplazado vale algo menos, los bonos mucho menos y lo opaco algo más.")
	pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(pista)

	# ── PARTE DE PAGO: uno de los tuyos ──────────────────────────────────
	var ti := _lbl(11, COL_SUAVE)
	ti.text = Idiomas.t("PARTE DE PAGO: UNO DE LOS TUYOS")
	add_child(ti)
	var mio_neg := _mundo.mi_club()
	if mio_neg != null:
		var candidatos: Array[Jugador] = []
		for x: Jugador in mio_neg.plantilla:
			if x.ovr >= n.jugador.ovr - 18:
				candidatos.append(x)
		candidatos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.valor > b.valor)
		var flow_ic := HFlowContainer.new()
		flow_ic.add_theme_constant_override("h_separation", 6)
		flow_ic.add_theme_constant_override("v_separation", 6)
		add_child(flow_ic)
		if candidatos.is_empty():
			var vac := _lbl(11, COL_SUAVE)
			vac.text = Idiomas.t("Nadie de tu plantel se acerca a su nivel.")
			flow_ic.add_child(vac)
		for x: Jugador in candidatos.slice(0, 8):
			var bi := Button.new()
			bi.text = "%s  (%s)" % [x.nombre, _dinero(x.valor)]
			bi.toggle_mode = true
			bi.button_pressed = (n.intercambio == x)
			bi.add_theme_font_size_override("font_size", 11)
			_con_foco(bi, "ic_" + x.id)
			bi.pressed.connect(func() -> void: intercambio_elegido.emit(x))
			flow_ic.add_child(bi)

	# ── CON ÉL (rol prometido + condiciones) ─────────────────────────────
	var tj := _lbl(11, COL_SUAVE)
	tj.text = Idiomas.t("CON ÉL")
	add_child(tj)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	add_child(flow)
	for rol in Negociacion.ORDEN_ROLES:
		var br := Button.new()
		var def: Array = _mundo.vestuario.def_rol(rol) if _mundo.vestuario != null else []
		br.text = String(def[1]) if def.size() > 1 else rol
		br.toggle_mode = true
		br.button_pressed = (rol == n.rol)
		br.add_theme_font_size_override("font_size", 11)
		_con_foco(br, "rol_" + rol)
		br.pressed.connect(func() -> void: rol_ajustado.emit(rol))
		flow.add_child(br)

	var gj := _rejilla_ajustes()
	_fila_ajuste(gj, Idiomas.t("Ficha/semana"), _dinero(n.sueldo), "sueldo")
	_fila_ajuste(gj, Idiomas.t("Años de contrato"), str(n.anios), "anios")
	_fila_ajuste(gj, Idiomas.t("Prima de fichaje"), _dinero(n.firma), "firma")

	var bcl := Button.new()
	bcl.text = Idiomas.t("Cláusula: sí") if n.clausula else Idiomas.t("Cláusula: no")
	bcl.add_theme_font_size_override("font_size", 11)
	_con_foco(bcl, "clausula")
	bcl.pressed.connect(func() -> void: rol_ajustado.emit("__clausula__"))
	add_child(bcl)

	# Botones de acción
	var fbot := HFlowContainer.new()
	fbot.add_theme_constant_override("h_separation", 8)
	fbot.add_theme_constant_override("v_separation", 6)
	add_child(fbot)
	var benv := Button.new()
	benv.text = Idiomas.t("Enviar oferta")
	benv.custom_minimum_size = Vector2(150, 34)
	_con_foco(benv, "enviar")
	benv.pressed.connect(func() -> void: oferta_enviada.emit())
	fbot.add_child(benv)
	var bcan := Button.new()
	bcan.text = Idiomas.t("Levantarse de la mesa")
	bcan.custom_minimum_size = Vector2(0, 34)
	bcan.pressed.connect(func() -> void: negociacion_cancelada.emit())
	fbot.add_child(bcan)

## CUÁNTO CUBRE TU OFERTA: lo que el club percibe frente a lo que pide, en una
## barra que se mueve con cada «+» y «−». Es la respuesta a «¿qué cambia si
## subo esto?» sin tener que enviar la oferta para enterarse. Debajo, la
## paciencia que les queda a los dos lados: la mesa no es infinita.
func _pintar_termometro(n: Negociacion) -> void:
	var pct := int(round(float(n.valor_percibido()) * 100.0 / float(maxi(1, n.pedido))))
	var col := COL_VERDE if pct >= 97 else (COL_ORO if pct >= 80 else COL_ROJO)
	if n.acuerdo_club:
		col = COL_VERDE
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	add_child(fila)
	var et := _lbl(11, COL_SUAVE)
	et.text = Idiomas.t("Cubre lo que piden")
	et.custom_minimum_size = Vector2(190, 0)
	fila.add_child(et)
	var barra := ProgressBar.new()
	barra.max_value = 120
	barra.value = mini(pct, 120)
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(80, 12)
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = col
	relleno.set_corner_radius_all(4)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(COL_SUAVE, 0.18)
	fondo.set_corner_radius_all(4)
	barra.add_theme_stylebox_override("fill", relleno)
	barra.add_theme_stylebox_override("background", fondo)
	fila.add_child(barra)
	var va := _lbl(12, col)
	va.text = "%d %%" % pct
	va.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	va.custom_minimum_size = Vector2(52, 0)
	fila.add_child(va)
	var pac := _lbl(11, COL_ROJO if mini(n.paciencia, n.paciencia_jugador) <= 1 else COL_SUAVE)
	if n.acuerdo_club:
		pac.text = Idiomas.t("✔ Con el club ya hay acuerdo: falta convencerle a él (paciencia: %d ronda(s)).") % n.paciencia_jugador
		pac.add_theme_color_override("font_color", COL_VERDE if n.paciencia_jugador > 1 else COL_ROJO)
	else:
		pac.text = Idiomas.t("Paciencia del club: %d ronda(s)  ·  la de él: %d") % [n.paciencia, n.paciencia_jugador]
	pac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(pac)

## LO QUE CONTESTARON a tu última oferta, en la propia mesa y con su color.
## Antes solo se contaba la negativa del jugador; la contraoferta del club (la
## respuesta más habitual) o el «no te alcanza» se iban al registro de la
## derecha y la mesa se quedaba igual, como si no hubiera pasado nada.
func _pintar_resultado_ronda(n: Negociacion) -> void:
	var tipo := String(_ultimo_resultado.get("tipo", ""))
	var titulo := ""
	var cuerpo := ""
	var col := COL_ORO
	match tipo:
		"club_pide_mas":
			titulo = Idiomas.t("↩️ CONTRAOFERTA DEL CLUB")
			cuerpo = Idiomas.t("Faltan unos %s para que acepten. Prefieren %s.") % [
				_dinero(int(_ultimo_resultado.get("falta", 0))), Idiomas.t(String(_ultimo_resultado.get("prefiere", "")))]
		"sin_caja":
			titulo = Idiomas.t("💸 NO TE ALCANZA")
			col = COL_ROJO
			cuerpo = Idiomas.t("Hoy saldrían %s de tu caja (fijo, opaco, prima y comisión) y tienes %s.") % [
				_dinero(int(_ultimo_resultado.get("hace_falta", 0))), _dinero(_mundo.mi_club().saldo)]
		"jugador_no":
			titulo = Idiomas.t("🤝 EL CLUB ACEPTA · FALTA ÉL")
			var pide := int(_ultimo_resultado.get("pide", 0))
			var motivo := String(_ultimo_resultado.get("motivo", ""))
			if motivo != "":
				cuerpo = Idiomas.t(motivo)
			elif pide > 0 and n.sueldo < int(round(float(pide) * 0.92)):
				cuerpo = Idiomas.t("Pide una ficha de al menos %s/semana.") % _dinero(int(round(float(pide) * 0.92)))
			else:
				cuerpo = Idiomas.t("Todavía no lo ve claro: más años, una prima o un rol mejor pueden convencerle.")
		_:
			return
	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(col, 0.10)
	e.border_color = col
	e.set_border_width_all(1)
	e.border_width_left = 4
	e.set_corner_radius_all(6)
	e.content_margin_left = 10
	e.content_margin_right = 10
	e.content_margin_top = 6
	e.content_margin_bottom = 6
	caja.add_theme_stylebox_override("panel", e)
	add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	caja.add_child(v)
	var lt := _lbl(12, col)
	lt.text = titulo
	v.add_child(lt)
	var lc := _lbl(12, COL_TEXTO)
	lc.text = cuerpo
	lc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(lc)

## Repinta todo el panel desde cero. Se llama desde Principal cada vez
## que cambia el mundo (avanzar semana, enviar oferta, etc.).
func pintar() -> void:
	for n in get_children():
		n.queue_free()
	_caja_lista = null
	if _mundo == null:
		return
	var mio := _mundo.mi_club()

	_pintar_estado_ventana()

	# ── Negociación activa (va antes de la lista de objetivos) ────────────
	if _mundo.mercado.negociacion != null:
		_pintar_mesa_negociacion(_mundo.mercado.negociacion)
		add_child(HSeparator.new())

	# ── Ofertas recibidas ─────────────────────────────────────────────────
	_pintar_ofertas_recibidas(mio)
	add_child(HSeparator.new())

	# ── Filtros + lista ───────────────────────────────────────────────────
	_pintar_filtros(mio)
	_pintar_lista(mio)
	_devolver_foco()

func _devolver_foco() -> void:
	if _foco == "":
		return
	var clave := _foco
	_foco = ""
	var b := _buscar_foco(self, clave)
	if b != null:
		b.grab_focus.call_deferred()

func _buscar_foco(raiz: Node, clave: String) -> Control:
	for h in raiz.get_children():
		if h.is_queued_for_deletion():
			continue
		if String(h.get_meta("foco", "")) == clave:
			return h as Control
		var r := _buscar_foco(h, clave)
		if r != null:
			return r
	return null

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
