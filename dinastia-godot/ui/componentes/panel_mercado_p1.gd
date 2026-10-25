extends VBoxContainer
## [Capa 1/2 de `panel_mercado.gd`] _lbl, _pintar_estado_ventana, _dato, _dinero, _pintar_ofertas_recibidas, _objetivos … (+4)

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
## La caja de la lista de objetivos: al cambiar un filtro se rehace SOLO esta.
## Antes se borraban «todos los GridContainer» del panel, y con una mesa abierta
## eso se llevaba también las rejillas de la negociación (Fijo, Cuotas, Ficha…).
var _caja_lista: VBoxContainer = null
## Los objetivos de la semana, guardados (ver `_objetivos()`).
var _obj_clave := ""
var _obj_cache: Array[Jugador] = []

# ── HELPERS DE UI ─────────────────────────────────────────────────────────
## Label con tamaño y color. Se usa la paleta de instancia (no constantes)
## para que el componente herede el tema del club activo.
func _lbl(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

# ── ESTADO DE LA VENTANA DE PASES ─────────────────────────────────────────
func _pintar_estado_ventana() -> void:
	var abierta := _mundo.mercado_abierto()
	var quedan  := _mundo.semanas_de_mercado() if abierta else _mundo.semanas_hasta_mercado()
	var texto   := (Idiomas.t("MERCADO ABIERTO  ·  quedan %d semana(s)") % quedan) if abierta \
		else (Idiomas.t("MERCADO CERRADO  ·  reabre en %d semana(s)") % quedan)
	var col := COL_VERDE if abierta else COL_ROJO
	if abierta and quedan <= 2:
		col = COL_ORO

	var t := _lbl(13, col)
	t.text = texto
	add_child(t)

	if _mundo.roles != null:
		if _mundo.roles.emergencia_activa():
			var e := _lbl(11, COL_ORO)
			e.text = Idiomas.t("📋 Ventana de emergencia: puedes cerrar UN fichaje aunque el mercado esté cerrado.")
			e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(e)
		var bloqueo := _mundo.roles.mercado_bloqueado()
		if bloqueo != "":
			var b := _lbl(11, COL_ROJO)
			if bloqueo == "interinato":
				b.text = Idiomas.t("Estás de interino: no fichas hasta que se resuelva. Te quedan %d fecha(s).") \
					% _mundo.roles.fechas_interinato_restantes()
			else:
				b.text = Idiomas.t("Eres ayudante: los fichajes los firma tu jefe. Puedes proponer, no comprar.")
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(b)

	var nota := _lbl(10, COL_SUAVE)
	nota.text = Idiomas.t("Ventanas de pases: semanas 1–6 y 18–24. Libres y precontratos funcionan todo el año.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(nota)
	add_child(HSeparator.new())

## Fila de dato: etiqueta + valor con color. Equivale a Principal._dato()
## pero sin acceder a ningún nodo externo.
## La etiqueta tiene un ancho fijo y la cifra va alineada a la derecha en una
## columna propia: así «Piden», «Perciben» y «Sale de tu caja» se comparan de
## un vistazo, cifra bajo cifra, en vez de quedar cada una donde acabe su rótulo.
func _dato(etiqueta: String, valor: String, color: Color) -> void:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 8)
	add_child(f)
	var et := _lbl(11, COL_SUAVE)
	et.text = etiqueta
	et.custom_minimum_size = Vector2(190, 0)
	et.clip_text = true
	et.tooltip_text = etiqueta
	f.add_child(et)
	var va := _lbl(12, color)
	va.text = valor
	va.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	va.custom_minimum_size = Vector2(110, 0)
	va.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f.add_child(va)

## Antes: "$" y sin pasar por `ECO` -el mismo jugador valía doce veces menos
## aquí que en su ficha-. Ahora la misma función que todo el juego.
func _dinero(monto: int) -> String:
	return Eco.dinero(monto)

# ── OFERTAS RECIBIDAS ─────────────────────────────────────────────────────
## Una tarjeta por oferta: quién pide a quién, la cifra a la derecha (alineada
## con las demás) y los botones. Sin ofertas se dice en una línea: una sección
## que desaparece sin más hace pensar que la pantalla ha fallado.
func _pintar_ofertas_recibidas(_mio: Club) -> void:
	var t := _lbl(11, COL_SUAVE)
	t.text = Idiomas.t("OFERTAS RECIBIDAS")
	add_child(t)
	if _mundo.mercado.ofertas_recibidas.is_empty():
		var vac := _lbl(11, COL_SUAVE)
		vac.text = Idiomas.t("Nadie ha pujado por tus jugadores esta semana.")
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(vac)
		return

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
		l.text = Idiomas.t("%s — oferta de %s") % [jo.nombre, co.nombre]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(l)
		var lm := _lbl(12, COL_ORO)
		lm.text = _dinero(int(o["monto"]))
		lm.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lm.custom_minimum_size = Vector2(90, 0)
		fila.add_child(lm)

		var idx := i
		if es_clausula or puede_vender:
			var ba := Button.new()
			ba.text = Idiomas.t("Aceptar")
			ba.pressed.connect(func() -> void: oferta_respondida.emit(idx, true))
			fila.add_child(ba)
		if es_clausula:
			var lc := _lbl(10, COL_ORO)
			lc.text = Idiomas.t("Pagan la cláusula: no se puede rechazar.")
			add_child(lc)
		elif puede_vender:
			var br := Button.new()
			br.text = Idiomas.t("Rechazar")
			br.pressed.connect(func() -> void: oferta_respondida.emit(idx, false))
			fila.add_child(br)
		else:
			var bl := _lbl(11, COL_SUAVE)
			bl.text = String(_mundo.roles.motivo_bloqueo("vender_jugadores")) if _mundo.roles != null else ""
			bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(bl)

		# Desglose del neto si hay cesiones
		if _mundo.cesiones != null:
			var neto := _mundo.cesiones.neto_de_venta(jo, int(o["monto"]))
			if neto < int(o["monto"]):
				var ln := _lbl(10, COL_ROJO)
				ln.text = Idiomas.t("   de eso, el club se queda %s: hay un fondo con parte de su pase") % _dinero(neto)
				ln.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				add_child(ln)

## Muestreo sesgado hacia calidad, como `Principal._objetivos()`, pero:
##  · con su PROPIO generador, sembrado con la partida, la semana y el club. Antes
##    tiraba de `Azar`, el azar DETERMINISTA de la partida: con solo mirar la
##    pestaña Mercado (o teclear en el buscador) se gastaban números y la misma
##    semilla daba otra liga. Es la trampa que `Sonido.toca()` documenta;
##  · guardado toda la semana: antes cada repintado (un «+» en la mesa, una letra
##    en el buscador) sorteaba otra lista y el jugador que mirabas desaparecía.
func _objetivos(mio: Club) -> Array[Jugador]:
	var clave := "%d|%d|%d|%s" % [Azar.semilla, _mundo.anio, _mundo.semana, mio.id]
	if clave != _obj_clave:
		_obj_clave = clave
		_obj_cache = _muestrear_objetivos(mio, hash(clave))
	var salida: Array[Jugador] = []
	for j: Jugador in _obj_cache:
		if j.club_id != mio.id and _mundo.clubes.has(j.club_id):
			salida.append(j)
	return salida

func _muestrear_objetivos(mio: Club, semilla: int) -> Array[Jugador]:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var media  := mio.media()
	var vistos: Dictionary = {}
	var salida: Array[Jugador] = []
	var clubes: Array = _mundo.clubes.values()
	for _i in 400:
		if salida.size() >= 30:
			break
		var otro: Club = clubes[rng.randi_range(0, clubes.size() - 1)]
		if otro.id == mio.id or otro.plantilla.is_empty():
			continue
		var j: Jugador = otro.plantilla[rng.randi_range(0, otro.plantilla.size() - 1)]
		if vistos.has(j.id) or float(j.ovr) < media:
			continue
		vistos[j.id] = true
		salida.append(j)
	salida.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	return salida

# ── FILTRADO ──────────────────────────────────────────────────────────────
func _objetivos_filtrados(mio: Club) -> Array:
	var salida: Array = []
	var texto := Nombres.limpiar(_filtro_texto.strip_edges()).to_lower()
	for j: Jugador in _objetivos(mio):
		if _filtro_pos != "" and Datos.grupo(j.pos_e) != _filtro_pos:
			continue
		if texto != "" and not Nombres.limpiar(j.nombre).to_lower().contains(texto):
			continue
		if _filtro_pagables and _mundo.mercado.valor_pedido(j) > mio.saldo:
			continue
		salida.append(j)
	return salida

# ── LISTA DE OBJETIVOS ────────────────────────────────────────────────────
## La tabla cabe en la columna central también a 1280×720: nombre y club se
## recortan (con el texto entero en la ayuda) y las cifras tienen ancho fijo y
## van a la derecha. Antes la rejilla pedía más ancho que la columna y la
## pestaña entera se desplazaba de lado, con PIDEN y GANAS fuera de la vista.
## El nombre es un botón plano: se llega con el teclado o el mando (antes solo
## respondía al clic del ratón sobre una etiqueta).
func _pintar_lista(mio: Club) -> void:
	_caja_lista = VBoxContainer.new()
	_caja_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_caja_lista)
	var filtrados := _objetivos_filtrados(mio)
	if filtrados.is_empty():
		var vac := _lbl(12, COL_SUAVE)
		vac.text = Idiomas.t("Ningún jugador cumple esos filtros. Prueba con otra línea o borra la búsqueda.")
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_caja_lista.add_child(vac)
		return
	var g := GridContainer.new()
	g.columns = 6
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 2)
	_caja_lista.add_child(g)

	## [rótulo, ancho mínimo, a la derecha]
	var columnas := [[Idiomas.t("NOMBRE"), 0, false], [Idiomas.t("CLUB"), 0, false], [Idiomas.t("EDAD"), 34, true],
		[Idiomas.t("MED"), 44, true], [Idiomas.t("PIDEN"), 74, true], [Idiomas.t("GANAS"), 48, true]]
	for col: Array in columnas:
		var h := _lbl(11, COL_SUAVE)
		h.text = String(col[0])
		h.custom_minimum_size = Vector2(float(col[1]), 0)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if bool(col[2]) else HORIZONTAL_ALIGNMENT_LEFT
		g.add_child(h)

	for j: Jugador in filtrados:
		var suyo: Club  = _mundo.clubes.get(j.club_id)
		var pedido      := _mundo.mercado.valor_pedido(j)
		var ganas: float = _mundo.mercado.deseo_de_venir(j, mio)["p"]
		var alcance     := COL_TEXTO if pedido <= mio.saldo else COL_ROJO
		var col_g       := COL_VERDE if ganas > 0.6 else (COL_ORO if ganas > 0.35 else COL_ROJO)
		var med         := _mundo.ojeadores.ovr_texto(j) if _mundo.ojeadores != null else str(j.ovr)

		var nom_b := Button.new()
		nom_b.text = j.nombre
		nom_b.flat = true
		nom_b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nom_b.clip_text = true
		nom_b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nom_b.custom_minimum_size = Vector2(70, 0)
		nom_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom_b.size_flags_stretch_ratio = 1.6
		nom_b.add_theme_font_size_override("font_size", 12)
		nom_b.add_theme_color_override("font_color", alcance)
		nom_b.tooltip_text = Idiomas.t("%s · abrir la mesa de negociación") % j.nombre
		nom_b.pressed.connect(func() -> void: fichar_pedido.emit(j))
		g.add_child(nom_b)

		var club_l := _lbl(12, COL_SUAVE)
		club_l.text = suyo.nombre if suyo else "?"
		club_l.clip_text = true
		club_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		club_l.custom_minimum_size = Vector2(50, 0)
		club_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		club_l.tooltip_text = club_l.text
		club_l.mouse_filter = Control.MOUSE_FILTER_PASS
		g.add_child(club_l)

		for par: Array in [
				[str(j.edad),                   COL_SUAVE],
				[med,                            COL_TEXTO],
				[_dinero(pedido),                alcance  ],
				["%d%%" % int(ganas * 100.0),    col_g    ]]:
			var lbl := _lbl(12, par[1])
			lbl.text = String(par[0])
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			g.add_child(lbl)

## Repinta SOLO la lista de objetivos sin reconstruir el estado ni los
## filtros (no se pierde el foco del buscador mientras se escribe).
func _repintar_lista(mio: Club) -> void:
	if _caja_lista != null and is_instance_valid(_caja_lista):
		var pos := _caja_lista.get_index()
		_caja_lista.queue_free()
		_pintar_lista(mio)
		move_child(_caja_lista, pos)
	else:
		_pintar_lista(mio)
