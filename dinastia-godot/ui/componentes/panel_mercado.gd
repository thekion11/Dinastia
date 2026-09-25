class_name PanelMercado
extends VBoxContainer
## Pantalla del mercado de traspasos: estado de ventana, filtros,
## lista de objetivos, mesa de negociación y ofertas recibidas.
##
## Este componente NO llama a `mundo` para escribir ni para navegar;
## todo lo que afecta al mundo lo delega hacia Principal mediante
## señales. Principal escucha esas señales y toma la decisión.
##
## La paleta se recibe en `inicializar()` para que siempre coincida
## con el color del club activo sin duplicar las constantes de Principal.

# ── PALETA (valores por defecto = los de Principal si no se sobrescriben) ──
var COL_TEXTO  := Color("e9eeea")
var COL_SUAVE  := Color("8ea595")
var COL_ACENTO := Color("3fa06a")
var COL_VERDE  := Color("4caf6d")
var COL_ROJO   := Color("e05555")
var COL_ORO    := Color("c9a227")

# ── SEÑALES ────────────────────────────────────────────────────────────────
## El usuario pulsó el nombre de un jugador → Principal abre la negociación.
signal fichar_pedido(jugador: Jugador)
## El usuario aceptó o rechazó una oferta recibida.
signal oferta_respondida(indice: int, aceptar: bool)
## El usuario envió una ronda de la negociación activa.
signal oferta_enviada()
## El usuario cancela la negociación.
signal negociacion_cancelada()
## El usuario ajustó el rol prometido en la negociación.
signal rol_ajustado(rol: String)
## El usuario ajustó un campo numérico de la negociación.
signal campo_ajustado(campo: String, delta: int)
## El usuario eligió un jugador de intercambio.
signal intercambio_elegido(j: Jugador)
## Pide que se refresque la pantalla entera (p.ej. tras cerrar negociación).
signal refrescar_pedido()
## Mensaje de texto para la columna del registro.
signal escrito(bbcode: String)

# ── ESTADO PROPIO ──────────────────────────────────────────────────────────
var _filtro_pos:      String = ""
var _filtro_texto:    String = ""
var _filtro_pagables: bool   = false
## Referencia al mundo; se actualiza en cada llamada a pintar().
var _mundo: Mundo = null
## Resultado de la última ronda enviada (para mostrarlo bajo la mesa).
var _ultimo_resultado: Dictionary = {}

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

# ── ESTADO DE LA VENTANA DE PASES ─────────────────────────────────────────
func _pintar_estado_ventana() -> void:
	var abierta := _mundo.mercado_abierto()
	var quedan  := _mundo.semanas_de_mercado() if abierta else _mundo.semanas_hasta_mercado()
	var texto   := ("MERCADO ABIERTO  ·  quedan %d semana(s)" % quedan) if abierta \
		else ("MERCADO CERRADO  ·  reabre en %d semana(s)" % quedan)
	var col := COL_VERDE if abierta else COL_ROJO
	if abierta and quedan <= 2:
		col = COL_ORO

	var t := _lbl(13, col)
	t.text = texto
	add_child(t)

	if _mundo.roles != null:
		if _mundo.roles.emergencia_activa():
			var e := _lbl(11, COL_ORO)
			e.text = "📋 Ventana de emergencia: puedes cerrar UN fichaje aunque el mercado esté cerrado."
			e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(e)
		var bloqueo := _mundo.roles.mercado_bloqueado()
		if bloqueo != "":
			var b := _lbl(11, COL_ROJO)
			if bloqueo == "interinato":
				b.text = "Estás de interino: no fichas hasta que se resuelva. Te quedan %d fecha(s)." \
					% _mundo.roles.fechas_interinato_restantes()
			else:
				b.text = "Eres ayudante: los fichajes los firma tu jefe. Puedes proponer, no comprar."
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(b)

	var nota := _lbl(10, COL_SUAVE)
	nota.text = "Ventanas de pases: semanas 1–6 y 18–24. Libres y precontratos funcionan todo el año."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(nota)
	add_child(HSeparator.new())

# ── MESA DE NEGOCIACIÓN ───────────────────────────────────────────────────
func _pintar_mesa_negociacion(n: Negociacion) -> void:
	var vendedor: Club = _mundo.clubes.get(n.club_vendedor_id)
	var t := _lbl(11, COL_ORO)
	t.text = "MESA DE NEGOCIACIÓN  ·  %s  (%s)  ·  ronda %d" % [
		n.jugador.nombre if n.jugador else "—",
		vendedor.nombre if vendedor else "?",
		n.ronda
	]
	add_child(t)

	if n.rival_id != "":
		var av := _lbl(11, COL_ROJO)
		av.text = "Otro club anda detrás de él: cuanto más se alargue la mesa, más riesgo de perderlo."
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(av)

	_dato("Piden",                        _dinero(n.pedido),           COL_SUAVE)
	_dato("Perciben con tu oferta actual", _dinero(n.valor_percibido()), COL_TEXTO)
	var col_costo := COL_TEXTO if n.costo_inmediato() <= _mundo.mi_club().saldo else COL_ROJO
	_dato("Sale de tu caja hoy",           _dinero(n.costo_inmediato()), col_costo)

	# ── CON EL CLUB ───────────────────────────────────────────────────────
	var tc := _lbl(11, COL_SUAVE)
	tc.text = "CON EL CLUB"
	add_child(tc)
	var gc := GridContainer.new()
	gc.columns = 4
	gc.add_theme_constant_override("h_separation", 8)
	add_child(gc)
	_fila_ajuste(gc, "Fijo",                _dinero(n.fijo),   n, "fijo")
	_fila_ajuste(gc, "Cuotas",              _dinero(n.cuotas), n, "cuotas")
	_fila_ajuste(gc, "Bonos por objetivos", _dinero(n.bonos),  n, "bonos")
	_fila_ajuste(gc, "% de venta futura",   "%d%%" % n.pct,    n, "pct")
	_fila_ajuste(gc, "Pago bajo cuerda",    _dinero(n.opaco),  n, "opaco")

	# ── PARTE DE PAGO: uno de los tuyos ──────────────────────────────────
	var ti := _lbl(11, COL_SUAVE)
	ti.text = "PARTE DE PAGO: UNO DE LOS TUYOS"
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
			vac.text = "Nadie de tu plantel se acerca a su nivel."
			flow_ic.add_child(vac)
		for x: Jugador in candidatos.slice(0, 8):
			var bi := Button.new()
			bi.text = "%s  (%s)" % [x.nombre, _dinero(x.valor)]
			bi.toggle_mode = true
			bi.button_pressed = (n.intercambio == x)
			bi.add_theme_font_size_override("font_size", 11)
			bi.pressed.connect(func() -> void: intercambio_elegido.emit(x))
			flow_ic.add_child(bi)

	# ── CON ÉL (rol prometido + condiciones) ─────────────────────────────
	var tj := _lbl(11, COL_SUAVE)
	tj.text = "CON ÉL"
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
		br.pressed.connect(func() -> void: rol_ajustado.emit(rol))
		flow.add_child(br)

	var gj := GridContainer.new()
	gj.columns = 4
	gj.add_theme_constant_override("h_separation", 8)
	add_child(gj)
	_fila_ajuste(gj, "Ficha/semana",      _dinero(n.sueldo),  n, "sueldo")
	_fila_ajuste(gj, "Años de contrato",  str(n.anios),       n, "anios")
	_fila_ajuste(gj, "Prima de fichaje",  _dinero(n.firma),   n, "firma")

	var bcl := Button.new()
	bcl.text = "Cláusula: sí" if n.clausula else "Cláusula: no"
	bcl.add_theme_font_size_override("font_size", 11)
	bcl.pressed.connect(func() -> void: rol_ajustado.emit("__clausula__"))
	add_child(bcl)

	# Resultado de la última ronda (si hay)
	if not _ultimo_resultado.is_empty():
		var tipo := String(_ultimo_resultado.get("tipo", ""))
		if tipo == "jugador_no":
			var lr := _lbl(12, COL_SUAVE)
			lr.text = "Le quedan reuniones de paciencia. %s" % String(_ultimo_resultado.get("motivo", ""))
			lr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(lr)

	# Botones de acción
	var fbot := HBoxContainer.new()
	fbot.add_theme_constant_override("separation", 8)
	add_child(fbot)

	var benv := Button.new()
	benv.text = "Enviar oferta"
	benv.pressed.connect(func() -> void: oferta_enviada.emit())
	fbot.add_child(benv)

	var bcan := Button.new()
	bcan.text = "Levantarse de la mesa"
	bcan.pressed.connect(func() -> void: negociacion_cancelada.emit())
	fbot.add_child(bcan)

func _fila_ajuste(g: GridContainer, etiqueta: String, valor_txt: String,
		n: Negociacion, campo: String) -> void:
	var et := _lbl(11, COL_SUAVE)
	et.text = etiqueta
	g.add_child(et)

	var bm := Button.new()
	bm.text = "−"
	bm.add_theme_font_size_override("font_size", 11)
	bm.pressed.connect(func() -> void: campo_ajustado.emit(campo, -1))
	g.add_child(bm)

	var va := _lbl(12, COL_TEXTO)
	va.text = valor_txt
	va.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	va.custom_minimum_size = Vector2(90, 0)
	g.add_child(va)

	var bs := Button.new()
	bs.text = "+"
	bs.add_theme_font_size_override("font_size", 11)
	bs.pressed.connect(func() -> void: campo_ajustado.emit(campo, 1))
	g.add_child(bs)

# ── OFERTAS RECIBIDAS ─────────────────────────────────────────────────────
func _pintar_ofertas_recibidas(mio: Club) -> void:
	var t := _lbl(11, COL_SUAVE)
	t.text = "OFERTAS RECIBIDAS"
	add_child(t)

	var puede_vender := _mundo.roles == null or _mundo.roles.puede_vender_jugadores()

	for i in _mundo.mercado.ofertas_recibidas.size():
		var o: Dictionary = _mundo.mercado.ofertas_recibidas[i]
		var jo: Jugador  = o["jugador"]
		var co: Club     = o["club"]
		var es_clausula: bool = bool(o.get("clausula", false))

		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		add_child(fila)

		var l := _lbl(12, COL_TEXTO)
		l.text = "%s — %s ofrece %s%s" % [
			jo.nombre,
			co.nombre,
			_dinero(int(o["monto"])),
			"  (cláusula: no se puede rechazar)" if es_clausula else ""
		]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(l)

		# Desglose del neto si hay cesiones
		if _mundo.cesiones != null:
			var neto := _mundo.cesiones.neto_de_venta(jo, int(o["monto"]))
			if neto < int(o["monto"]):
				var ln := _lbl(10, COL_ROJO)
				ln.text = "   de eso, el club se queda %s: hay un fondo con parte de su pase" % _dinero(neto)
				add_child(ln)

		var idx := i
		if es_clausula:
			var ba := Button.new()
			ba.text = "Aceptar"
			ba.pressed.connect(func() -> void: oferta_respondida.emit(idx, true))
			fila.add_child(ba)
		elif puede_vender:
			var ba := Button.new()
			ba.text = "Aceptar"
			ba.pressed.connect(func() -> void: oferta_respondida.emit(idx, true))
			fila.add_child(ba)
			var br := Button.new()
			br.text = "Rechazar"
			br.pressed.connect(func() -> void: oferta_respondida.emit(idx, false))
			fila.add_child(br)
		else:
			var bl := _lbl(11, COL_SUAVE)
			bl.text = String(_mundo.roles.motivo_bloqueo("vender_jugadores")) if _mundo.roles != null else ""
			fila.add_child(bl)

# ── FILTROS ───────────────────────────────────────────────────────────────
func _pintar_filtros(mio: Club) -> void:
	var t := _lbl(11, COL_SUAVE)
	t.text = "FILTRAR"
	add_child(t)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	add_child(fila)

	# Buscador por nombre
	var buscar := LineEdit.new()
	buscar.placeholder_text = "Buscar por nombre…"
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
	bp.text = "Solo lo que puedo pagar"
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

## Repinta SOLO la cuadrícula de objetivos sin reconstruir el estado ni los
## filtros. Se usa al cambiar filtros para no parpadear la pantalla entera.
func _repintar_lista(mio: Club) -> void:
	# Buscar y borrar solo el GridContainer de la lista
	for n in get_children():
		if n is GridContainer:
			n.queue_free()
	_pintar_lista(mio)

# ── LISTA DE OBJETIVOS ────────────────────────────────────────────────────
func _pintar_lista(mio: Club) -> void:
	var g := GridContainer.new()
	g.columns = 6
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 3)
	add_child(g)

	# Encabezados
	for enc: String in ["NOMBRE", "CLUB", "EDAD", "MED", "PIDEN", "GANAS"]:
		var h := _lbl(11, COL_SUAVE)
		h.text = enc
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT \
			if enc in ["EDAD","MED","PIDEN","GANAS"] else HORIZONTAL_ALIGNMENT_LEFT
		g.add_child(h)

	for j: Jugador in _objetivos_filtrados(mio):
		var suyo: Club  = _mundo.clubes.get(j.club_id)
		var pedido      := _mundo.mercado.valor_pedido(j)
		var ganas: float = _mundo.mercado.deseo_de_venir(j, mio)["p"]
		var alcance     := COL_TEXTO if pedido <= mio.saldo else COL_ROJO
		var col_g       := COL_VERDE if ganas > 0.6 else (COL_ORO if ganas > 0.35 else COL_ROJO)
		var med         := _mundo.ojeadores.ovr_texto(j) if _mundo.ojeadores != null else str(j.ovr)

		var nombre_j    := j.nombre
		var nombre_club := suyo.nombre if suyo else "?"

		var nom_l := _lbl(12, alcance)
		nom_l.text = nombre_j
		nom_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom_l.mouse_filter = Control.MOUSE_FILTER_STOP
		# Pulsar el nombre abre la negociación (la acción la ejecuta Principal)
		nom_l.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed \
					and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				fichar_pedido.emit(j))
		g.add_child(nom_l)

		for par: Array in [
				[nombre_club,                   COL_SUAVE],
				[str(j.edad),                   COL_SUAVE],
				[med,                            COL_TEXTO],
				[_dinero(pedido),                alcance  ],
				["%d%%" % int(ganas * 100.0),    col_g    ]]:
			var lbl := _lbl(12, par[1])
			lbl.text = String(par[0])
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			g.add_child(lbl)

# ── FILTRADO ──────────────────────────────────────────────────────────────
func _objetivos_filtrados(mio: Club) -> Array:
	var salida: Array = []
	var texto := _filtro_texto.strip_edges().to_lower()
	for j: Jugador in _objetivos(mio):
		if _filtro_pos != "" and Datos.grupo(j.pos_e) != _filtro_pos:
			continue
		if texto != "" and not j.nombre.to_lower().contains(texto):
			continue
		if _filtro_pagables and _mundo.mercado.valor_pedido(j) > mio.saldo:
			continue
		salida.append(j)
	return salida

func _objetivos(mio: Club) -> Array[Jugador]:
	## Misma lógica que Principal._objetivos(): muestreo sesgado hacia calidad.
	## Se mantiene aquí para no depender de acceso al estado de Principal.
	var media  := mio.media()
	var vistos: Dictionary = {}
	var salida: Array[Jugador] = []
	var clubes: Array = _mundo.clubes.values()
	for _i in 400:
		if salida.size() >= 30:
			break
		var otro: Club = clubes[Azar.ent(0, clubes.size() - 1)]
		if otro.id == mio.id or otro.plantilla.is_empty():
			continue
		var j: Jugador = otro.plantilla[Azar.ent(0, otro.plantilla.size() - 1)]
		if vistos.has(j.id) or float(j.ovr) < media:
			continue
		vistos[j.id] = true
		salida.append(j)
	salida.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	return salida

# ── HELPERS DE UI ─────────────────────────────────────────────────────────
## Label con tamaño y color. Se usa la paleta de instancia (no constantes)
## para que el componente herede el tema del club activo.
func _lbl(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

## Fila de dato: etiqueta + valor con color. Equivale a Principal._dato()
## pero sin acceder a ningún nodo externo.
func _dato(etiqueta: String, valor: String, color: Color) -> void:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 8)
	add_child(f)
	var et := _lbl(11, COL_SUAVE)
	et.text = etiqueta
	f.add_child(et)
	var va := _lbl(12, color)
	va.text = valor
	f.add_child(va)

func _dinero(monto: int) -> String:
	if monto >= 1_000_000:
		return "%.1fM" % (float(monto) / 1_000_000.0)
	if monto >= 1_000:
		return "%dK" % (monto / 1_000)
	return "$%d" % monto
