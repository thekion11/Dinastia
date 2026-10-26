extends "res://ui/principal_p12.gd"
## [Capa 12/17 de `principal.gd`] _nueva_temporada, _al_elegir_calendario, _abrir_hub, _buscar_global, _textura_brillo_panel, _panel … (+5)

func _nueva_temporada() -> void:
	if mundo.temporada_en_curso():
		_escribir("[color=#e05555]Todavía queda calendario por jugar.[/color]")
		return
	## EL DOCUMENTAL (fase 5): se arma ANTES del cierre, que reinicia la tabla
	## y las estadísticas; se proyecta al final del cierre.
	var guion_doc := DocumentalTemporada.guion(mundo)
	if mundo.mercado != null:
		mundo.mercado.fichajes_temporada.clear()
	var resumen := mundo.nueva_temporada()
	if not guion_doc.is_empty():
		(func() -> void: DocumentalTemporada.abrir(self, guion_doc, _retrato)).call_deferred()
	## `mundo.nueva_temporada()` resortea los continentales por dentro
	## (`_sortear_continentales()`, instancias NUEVAS cada vez): sin esta llamada,
	## el sorteo y el aviso de campeón/ronda de Champions-Libertadores solo
	## funcionaban en la primera temporada de la partida. Ver el comentario de
	## `_conectar_sorteos()`.
	_conectar_sorteos()
	_seleccionado = null
	## El cierre de temporada es el momento más importante del año y tiene que
	## contarse entero: quién ganó, quién sube y quién baja. Sin esto la
	## temporada acababa y no pasaba nada.
	for c: Dictionary in resumen["campeones"]:
		var l: Liga = c["liga"]
		var club: Club = c["club"]
		if l.division() == 1 and l.pais == mundo.mi_club().pais:
			_escribir("[color=#c9a227]CAMPEÓN de %s: [b]%s[/b].[/color]  Premio %s" % [
				l.nombre, club.nombre, _dinero(Mundo.PREMIO_LIGA)])
	if not resumen["suben"].is_empty():
		_escribir("[color=#4caf6d]Ascienden:[/color] %s" % _nombres(resumen["suben"]))
		if (resumen["suben"] as Array).has(mundo.mi_club()):
			Sonido.toca("ascenso")
			Aviso.mostrar(self, "titulo", "⬆️", "¡ASCENSO!",
				"Subes de categoría. Otra liga, otros rivales y otros derechos de televisión.")
	if not resumen["bajan"].is_empty():
		_escribir("[color=#e05555]Descienden:[/color] %s  [color=#8ea595](la televisión les pasa de 300.000 a 58.000)[/color]" % _nombres(resumen["bajan"]))
		if (resumen["bajan"] as Array).has(mundo.mi_club()):
			Sonido.toca("descenso")
			Aviso.mostrar(self, "alerta", "⬇️", "DESCENSO",
				"Bajas de categoría. La televisión pasa de 300.000 a 58.000 y habrá que rehacer el plantel.")
	## El veredicto de la directiva. Es lo unico del cierre que puede acabar con
	## la partida, asi que va lo ultimo y con su propio color.
	var v: Dictionary = resumen.get("directiva", {})
	if not v.is_empty():
		if v["cumplido"]:
			_escribir("[color=#4caf6d]Objetivo CUMPLIDO:[/color] %s. Acabaste %d.º (te pedían %d.º). Confianza %d." % [
				v["objetivo"], v["puesto"], v["meta"], v["confianza"]])
		else:
			_escribir("[color=#e05555]Objetivo FALLADO:[/color] %s. Acabaste %d.º y te pedían %d.º. Confianza %d." % [
				v["objetivo"], v["puesto"], v["meta"], v["confianza"]])
		if v["despedido"]:
			_escribir("[color=#e05555][b]ESTÁS DESPEDIDO.[/b][/color] Elige otro club en la lista de arriba para empezar de nuevo.")
	if resumen.get("trotamundos", false):
		_escribir("[color=#c9a227][b]🧳 Toca hacer las maletas.[/b][/color] Dos temporadas cumplidas: el desafío trotamundos te obliga a cambiar de club. Elige tu próximo destino en la lista de arriba.")
	_escribir("[color=#8ea595]Empieza la %d. Todos cumplen un año, algunos se retiran y sube gente de la cantera.[/color]" % mundo.anio)
	## LOS CONTRATOS QUE VENCEN. Es el aviso más útil de todo el cierre de
	## temporada y el que más fácil se pasa por alto: un contrato que se acaba y
	## no se renueva es un jugador que se pierde gratis. Se avisa aquí, con la
	## pretemporada por delante para hacer algo al respecto.
	var acaban: Array[Jugador] = []
	for j: Jugador in mundo.mi_club().plantilla:
		if j.anios_contrato <= 1:
			acaban.append(j)
	if not acaban.is_empty():
		acaban.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		var cuerpo_c := "%s%s. Renuévalos en Contratos o los pierdes gratis." % [
			acaban[0].nombre,
			" y %d más" % (acaban.size() - 1) if acaban.size() > 1 else ""]
		Aviso.mostrar(self, "contrato", "📄", "Terminan contrato: %d" % acaban.size(), cuerpo_c, "contrato_vence")
		_escribir("[color=#c9a227][b]📄 Terminan contrato %d jugador(es):[/b][/color] %s." % [
			acaban.size(), _nombres_jugadores(acaban)])
		_anotar("📄 Terminan contrato: %d" % acaban.size(), cuerpo_c)
	_partida.autoguardar_si_toca()
	_refrescar()

## El menú "📅 Calendario" -antes cuatro botones sueltos que ya no entraban en
## la fila-. `match` dentro de un lambda pasado como argumento le rompía el
## parser a `principal.gd` entero -"Expected expression for match pattern",
## y de ahí en cascada TODAS las demás llamadas de la pantalla fallaban con
## "Nonexistent function"-, así que el manejador vive aquí, con nombre propio.
func _al_elegir_calendario(id: int) -> void:
	match id:
		0: _dirigir()
		1: _avanzar_semana()
		2: _jugar_temporada()
		3: _nueva_temporada()

## UN HUB CONTEXTUAL. Se abre tocando la zona de la pantalla que ya habla de
## eso -el plantel, el marcador, la caja, la tabla- y ofrece sus pestañas como
## botones grandes. No es una pestaña más: es una puerta, y por eso se cierra
## sola en cuanto eliges.
func _abrir_hub(clave: String) -> void:
	var hub: Dictionary = HUBS.get(clave, {})
	if hub.is_empty():
		return
	var capa := PanelContainer.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(COL_FONDO.r, COL_FONDO.g, COL_FONDO.b, 0.93)
	capa.add_theme_stylebox_override("panel", estilo)
	add_child(capa)

	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 10)
	capa.add_child(caja)
	var t := _texto(20, COL_ORO)
	t.text = String(hub["titulo"])
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(t)
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	caja.add_child(flow)
	for titulo: String in (hub["tabs"] as Array):
		var b := Button.new()
		b.text = titulo
		b.custom_minimum_size = Vector2(180, 44)
		b.add_theme_font_size_override("font_size", 14)
		var destino := titulo
		b.pressed.connect(func() -> void:
			capa.queue_free()
			_ir_a_pestana(destino)
			_refrescar())
		flow.add_child(b)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("✕  Cerrar")
	cerrar.custom_minimum_size = Vector2(0, 34)
	cerrar.pressed.connect(func() -> void: capa.queue_free())
	caja.add_child(cerrar)
	## La entrada con un desliz corto hacia arriba: es lo que hace que el hub
	## se sienta una capa que sube y no un cambio de pantalla seco.
	caja.modulate.a = 0.0
	caja.position.y += 18.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(caja, "modulate:a", 1.0, 0.16)
	tw.tween_property(caja, "position:y", caja.position.y - 18.0, 0.16).set_trans(Tween.TRANS_CUBIC)

# --- acciones ---------------------------------------------------------------

func _buscar_global(texto: String) -> void:
	## Se compara limpio por los dos lados: con la cubierta activa "Fernand0"
	## tiene que salir buscando "fernando" (y también buscando "fernand0").
	var q := Nombres.limpiar(texto.strip_edges()).to_lower()
	if q.length() < 2:
		return
	var mejor: Jugador = null
	var mejor_empieza := false
	for c: Club in mundo.clubes.values():
		for j in c.plantilla:
			var n := Nombres.limpiar(j.nombre).to_lower()
			if not n.contains(q):
				continue
			var empieza := n.begins_with(q)
			if mejor == null or (empieza and not mejor_empieza) or (empieza == mejor_empieza and j.ovr > mejor.ovr):
				mejor = j
				mejor_empieza = empieza
	if mejor != null:
		_escribir("[color=#3fa06a]Encontrado:[/color] %s, de %s." % [
			mejor.nombre, (mundo.clubes.get(mejor.club_id) as Club).nombre if mundo.clubes.has(mejor.club_id) else "sin club"])
		_ver_ficha(mejor)
		_buscador.text = ""
		return
	for c2: Club in mundo.clubes.values():
		if Nombres.limpiar(c2.nombre).to_lower().contains(q):
			_clubes_ficha = c2
			_ir_a_pestana("Clubes")
			_refrescar()
			_buscador.text = ""
			return
	_escribir("[color=#8ea595]No hay ningún jugador ni club que se llame así.[/color]")
static func _textura_brillo_panel() -> Texture2D:
	if _brillo_panel != null:
		return _brillo_panel
	## OJO: `Gradient.set_color(i, ...)` indexa por PUNTO, no por offset -y
	## `add_point()` desplaza los índices de los puntos que venían después-.
	## `set_color(1, ...)` tras un `add_point()` de en medio no toca el punto
	## final: se queda en su blanco opaco de fábrica, y el "brillo" salía
	## opaco de arriba abajo en vez de apagarse a los 2/5. Se fijan las tres
	## paradas de una vez, sin el índice cambiante de por medio.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_LINEAR
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	t.width = 4
	t.height = 128
	_brillo_panel = t
	return t

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var e := StyleBoxFlat.new()
	## La paleta y la forma elegidas en Ajustes. Se leen aqui, en el unico sitio
	## por el que pasan todas las tarjetas del juego, para que cambiarlas repinte
	## la interfaz entera sin tocar ni una pantalla.
	e.bg_color = _pal_panel()
	e.border_color = _ui_ajustes._pal_borde()
	var forma: Array = FORMAS_TARJETA.get(_forma_tarjeta, ["", 8, 1])
	e.set_border_width_all(int(forma[2]))
	e.set_corner_radius_all(int(forma[1]))
	p.add_theme_stylebox_override("panel", e)
	## Marcada como tarjeta del juego. Media interfaz -las columnas, la cabecera,
	## la ficha- se construye UNA vez y luego solo se le cambia el contenido, asi
	## que cambiar de paleta no la tocaba: se queda esta marca para poder ir a
	## buscarlas y repintarlas sin reconstruir la pantalla entera.
	p.set_meta("tarjeta", true)
	## El adorno del borde -escuadras, filete, cinta-. Va aqui y no en el
	## StyleBox porque un StyleBox solo sabe pintar un borde entero y uniforme.
	if _marca_tarjeta != "ninguno":
		var mk := MarcaPanel.new()
		mk.poner(_marca_tarjeta, COL_ACENTO)
		p.add_child(mk)
	if not _brillo_tarjetas:
		return p
	var brillo := TextureRect.new()
	brillo.texture = _textura_brillo_panel()
	brillo.set_anchors_preset(Control.PRESET_FULL_RECT)
	brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## SIN esto, TextureRect pide como mínimo el tamaño NATIVO de la textura
	## (128px de alto) y estira el panel entero para dárselo -el brillo
	## crecía la tarjeta en vez de solo pintarla-.
	brillo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brillo.stretch_mode = TextureRect.STRETCH_SCALE
	p.add_child(brillo)
	return p

func _con_scroll(padre: VBoxContainer) -> VBoxContainer:
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	## AUTO y no DISABLED (etapa 1, 2.ª pasada): desactivado, una fila más ancha
	## que la columna AGRANDABA la columna entera y sacaba la ficha del jugador
	## de la pantalla (Editor, Libres). Ahora lo que no cabe se desplaza dentro.
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	padre.add_child(s)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 2)
	s.add_child(lista)
	return lista

func _columna(padre: HBoxContainer, titulo: String, ratio: float) -> VBoxContainer:
	var caja := _panel()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = ratio
	padre.add_child(caja)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12; v.offset_top = 10; v.offset_right = -12; v.offset_bottom = -10
	caja.add_child(v)
	var t := _texto(11, COL_SUAVE); t.text = titulo
	t.clip_text = true
	v.add_child(t)
	## Se deja a mano el último título creado para las columnas cuyo encabezado
	## cambia solo -la de la izquierda dice "PRIMERA DIVISION" o "COPA
	## LIBERTADORES · CUARTOS" según lo que se juegue el domingo-.
	_ultimo_titulo_columna = t
	## `v` es la caja entera de la columna, por debajo del scroll: quien quiera
	## poner algo FIJO al pie -un botón que no se vaya con el desplazamiento-
	## lo cuelga de aquí.
	_ultima_caja_columna = v
	return _con_scroll(v)

## La ficha completa de la competición, encima de todo. Sale de `principal.gd`
## para no engordar más este archivo, que ya pasa de las cinco mil líneas.
func _abrir_competicion() -> void:
	var v := Competicion.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(v)
	v.abrir(mundo, _liga_de(mundo.mi_club()))
	v.cerrado.connect(func() -> void:
		v.queue_free()
		_refrescar())

func _hoja(tabs: TabContainer, titulo: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = titulo
	tabs.add_child(v)
	return _con_scroll(v)

## Responde a una oferta de compra RECIBIDA (otro club quiere a uno de los
## tuyos). Nombre distinto al de la negociación saliente para no colisionar
## con la firma de `_abrir_negociacion()`.
func _responder_oferta_mercado(indice: int, aceptar: bool) -> void:
	if mundo == null:
		return
	if indice < 0 or indice >= mundo.mercado.ofertas_recibidas.size():
		return
	var o: Dictionary = mundo.mercado.ofertas_recibidas[indice]
	var j: Jugador    = o["jugador"]
	var co: Club      = o.get("club")
	if aceptar:
		## `responder_oferta()`: `aceptar_oferta()` no existió nunca y el botón
		## del panel de mercado rompía (lo encontró el recorrido de pantallas).
		mundo.mercado.responder_oferta(indice, true)
		_escribir("[color=#4caf6d]Venta cerrada:[/color] %s a %s por %s." % [
			j.nombre,
			co.nombre if co else "?",
			_dinero(int(o["monto"]))])
	else:
		mundo.mercado.responder_oferta(indice, false)
		_escribir("Oferta por %s rechazada." % j.nombre)
	_refrescar()
