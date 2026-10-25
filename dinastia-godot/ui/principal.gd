class_name Principal
extends "res://ui/principal_p17.gd"
## [Capa 17/17 de `principal.gd`] _input, _pintar_identidad, _al_paso_nuevo, _portada_nueva

func _input(evento: InputEvent) -> void:
	## CON EL PANEL LATERAL ENCIMA (mapa de metas 23) los mismos botones
	## navegan ESE menú y no el central de detrás: L1/R1 pasan de submenú,
	## L2/R2 de menú, y el desliz con el dedo no cambia páginas escondidas.
	if _menu_lateral != null and _menu_lateral.ocupado():
		var pm: PantallaMenu = _menu_lateral.pantalla_abierta if is_instance_valid(_menu_lateral.pantalla_abierta) else null
		if pm != null and evento.is_action_pressed("dinastia_tab_siguiente"):
			pm.submenu_vecino(1)
			get_viewport().set_input_as_handled()
		elif pm != null and evento.is_action_pressed("dinastia_tab_anterior"):
			pm.submenu_vecino(-1)
			get_viewport().set_input_as_handled()
		elif evento.is_action_pressed("dinastia_bloque_siguiente"):
			_menu_lateral.menu_vecino(1)
			get_viewport().set_input_as_handled()
		elif evento.is_action_pressed("dinastia_bloque_anterior"):
			_menu_lateral.menu_vecino(-1)
			get_viewport().set_input_as_handled()
		_arrastre_x = 0.0
		_arrastre_y = 0.0
		return
	## Un desliz que empieza sobre el riel es del panel (abrirlo), no del menú.
	if evento is InputEventScreenDrag and (evento as InputEventScreenDrag).position.x < MenuLateral.ANCHO_RIEL + 30.0:
		return
	## Los gatillos cambian de pestaña. Se mira aquí y no en `_unhandled_input`
	## porque los contenedores de la interfaz se comen los eventos de navegación
	## antes de que lleguen abajo.
	if evento.is_action_pressed("dinastia_tab_siguiente"):
		_saltar_pestana(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("dinastia_tab_anterior"):
		_saltar_pestana(-1)
		get_viewport().set_input_as_handled()
	## L2/R2 y Ctrl+Q/E cambian de BLOQUE MAESTRO, no de chip: es el nivel de
	## arriba. NO son L1/R1 -esos ya los toma `dinastia_tab_siguiente`/
	## `anterior`, dos líneas más arriba, para el chip- porque un mismo botón
	## físico no puede disparar dos acciones a la vez: con L1/R1 aquí también,
	## esta rama nunca se habría alcanzado (quedó comprobado: era justo el bug
	## que tenía este bloque antes de corregirlo).
	elif evento.is_action_pressed("dinastia_bloque_siguiente"):
		_bloque_vecino(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("dinastia_bloque_anterior"):
		_bloque_vecino(-1)
		get_viewport().set_input_as_handled()
	elif evento is InputEventKey and evento.pressed and not evento.echo:
		var k := evento as InputEventKey
		if k.keycode == KEY_E and k.ctrl_pressed:
			_bloque_vecino(1)
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_Q and k.ctrl_pressed:
			_bloque_vecino(-1)
			get_viewport().set_input_as_handled()
	## EL ARRASTRE CON EL DEDO (Android). Un desliz horizontal largo pasa de
	## bloque, como en FC26. El umbral de 90 px y el 1,6 de proporción están
	## para que un scroll vertical con el pulgar torcido no cambie de página
	## sin querer: tiene que ser un gesto claramente lateral.
	elif evento is InputEventScreenDrag:
		var dr := evento as InputEventScreenDrag
		_arrastre_x += dr.relative.x
		_arrastre_y += absf(dr.relative.y)
		if absf(_arrastre_x) > 90.0 and absf(_arrastre_x) > _arrastre_y * 1.6:
			_bloque_vecino(-1 if _arrastre_x > 0.0 else 1)
			_arrastre_x = 0.0
			_arrastre_y = 0.0
	elif evento is InputEventScreenTouch and not (evento as InputEventScreenTouch).pressed:
		_arrastre_x = 0.0
		_arrastre_y = 0.0

func _pintar_identidad(c: Club) -> void:

	## EL DISEÑADOR DE EQUIPACIÓN (26-9-2026): 70 diseños, 5 colores, pantalón,
	## medias, 30 botines, accesorios y color de números, con vista 3D.
	var bd := Button.new()
	bd.text = Idiomas.t("🎽  Abrir el diseñador de equipación")
	bd.custom_minimum_size = Vector2(0, 44)
	bd.add_theme_font_size_override("font_size", 16)
	bd.pressed.connect(func() -> void:
		var dz := DisenadorKit.abrir(self, mundo)
		dz.cerrado.connect(_refrescar))
	_lista_gente.add_child(bd)
	_lista_gente.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("🎨 IDENTIDAD VISUAL")
	_lista_gente.add_child(t)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = Idiomas.t("Cada cosa se pinta por separado: el uniforme no arrastra el color del menú ni el del escudo. Lo que no toques, lo hereda del club.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_gente.add_child(ex)

	## LA VISTA PREVIA. Escudo y camiseta juntos, con lo que hay puesto ahora
	## mismo: sin esto hay que salir de la pantalla para ver si acertaste.
	var previa := HBoxContainer.new()
	previa.add_theme_constant_override("separation", 14)
	previa.alignment = BoxContainer.ALIGNMENT_CENTER
	_lista_gente.add_child(previa)
	var esc_img := TextureRect.new()
	esc_img.texture = Escudo.textura(c, 54)
	esc_img.custom_minimum_size = Vector2(54, 54)
	## SIN ESTO EL ESCUDO SALÍA GIGANTE. `Escudo.textura()` rasteriza a 4x -para
	## que las curvas no salgan dentadas al escalar, ver su propio comentario-,
	## así que la textura real mide unos 220 px de lado aunque se pidan 54. Sin
	## `expand_mode = EXPAND_IGNORE_SIZE` -el que SÍ lleva el resto de usos de
	## `Escudo.textura()` en este mismo archivo, por ejemplo `_escudo()`-, el
	## `TextureRect` reporta como tamaño mínimo el de la textura real, no el de
	## `custom_minimum_size`, y esa fila entera se inflaba a esa altura -se
	## llevaba con ella el color de acento de al lado, que salía como un
	## rectángulo blanco altísimo por simple herencia de la altura de la fila-.
	esc_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	previa.add_child(esc_img)
	var kit_img := TextureRect.new()
	kit_img.texture = Jersey.textura_procedural(c.color_kit1(), c.color_kit2(),
		Jersey.kit_de(c, c.kit_estilo), 58)
	kit_img.custom_minimum_size = Vector2(58, 58)
	kit_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kit_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	previa.add_child(kit_img)
	var muestra_ui := ColorRect.new()
	muestra_ui.color = _acento_de(c)
	muestra_ui.custom_minimum_size = Vector2(46, 46)
	previa.add_child(muestra_ui)

	_ui_identidad._fila_color_identidad(c, "1 · Color principal del club", "color1")
	_ui_identidad._fila_color_identidad(c, "1 · Color secundario del club", "color2")

	var tk := _texto(11, COL_ACENTO)
	tk.text = Idiomas.t("2 · UNIFORME%s") % ("" if c.kit_color1 == "" and c.kit_color2 == "" else Idiomas.t("  ·  propio"))
	_lista_gente.add_child(tk)
	_ui_identidad._fila_color_identidad(c, "Color 1 de la camiseta", "kit_color1")
	_ui_identidad._fila_color_identidad(c, "Color 2 de la camiseta", "kit_color2")
	_ui_identidad._rejilla_identidad(c, "kit_estilo", Jersey.KITS, "Diseño")
	_ui_identidad._boton_heredar(c, ["kit_color1", "kit_color2"], "Volver a los colores del club")

	var te := _texto(11, COL_ACENTO)
	te.text = Idiomas.t("3 · ESCUDO%s") % ("" if c.esc_color1 == "" and c.esc_color2 == "" else Idiomas.t("  ·  propio"))
	_lista_gente.add_child(te)
	_ui_identidad._fila_color_identidad(c, "Fondo del escudo", "esc_color1")
	_ui_identidad._fila_color_identidad(c, "Borde y patrón", "esc_color2")
	_ui_identidad._rejilla_identidad(c, "esc_forma", Escudo.FORMAS, "Forma")
	_ui_identidad._rejilla_identidad(c, "esc_patron", Escudo.PATRONES, "Patrón interior")
	## "ESC_SIM" del HTML: un emoji en vez de las iniciales. El campo llevaba
	## semanas guardándose -`Club.esc_simbolo` ya viaja en el guardado- sin que
	## `Escudo` lo leyera ni hubiera dónde elegirlo. `Datos.tabla("ESC_SIM")`
	## trae un "" propio en el índice 0 -el mismo "por sorteo" que ya antepone
	## `_rejilla_identidad`-, así que se recorta para no duplicar ese botón.
	var lista_sim: Array = Datos.tabla("ESC_SIM")
	_ui_identidad._rejilla_identidad(c, "esc_simbolo",
		lista_sim.slice(1) if lista_sim != null and lista_sim.size() > 1 else [], "Símbolo (reemplaza las iniciales)")
	if not _modo_experto:
		var ee := _texto(10, COL_SUAVE)
		ee.text = Idiomas.t("Veintiseis formas × treinta patrones × dos colores: miles de escudos distintos.")
		ee.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_gente.add_child(ee)
	_ui_identidad._boton_heredar(c, ["esc_color1", "esc_color2"], "Volver a los colores del club")
	_ui_identidad._rejilla_especiales(c)

	var tu := _texto(11, COL_ACENTO)
	tu.text = Idiomas.t("4 · INTERFAZ%s") % ("" if c.ui_acento == "" else Idiomas.t("  ·  propia"))
	_lista_gente.add_child(tu)
	_ui_identidad._fila_color_identidad(c, "Color de acento (botones y menú)", "ui_acento")
	_ui_identidad._boton_heredar(c, ["ui_acento"], "Usar el color del club")

	var b_todo := Button.new()
	b_todo.text = Idiomas.t("🎨 Igualar todo a los colores del club")
	b_todo.add_theme_font_size_override("font_size", 11)
	b_todo.pressed.connect(func() -> void:
		c.igualar_identidad()
		Escudo.limpiar_cache()
		_refrescar())
	_lista_gente.add_child(b_todo)

	## LAS TRES CAMISETAS. Vivían dentro del chip "Comercial" -Club→Equipación
	## solo tenía una VISTA PREVIA sin controles, y el editor de verdad estaba
	## enterrado junto a proveedor/zonas/naming, sin relación temática-. Un
	## editor de camiseta es identidad visual, así que se pinta aquí, donde ya
	## está el resto del escudo y los colores del club.
	if mundo.comercial != null:
		_lista_gente.add_child(HSeparator.new())
		_ui_identidad._pintar_kits(mundo.comercial, c)

## EL ARCHIVO DE PORTADAS. Se escribían después de cada partido grande y se
## perdían al cambiar de pantalla. Juntas se leen como la hemeroteca del ciclo:
## de un vistazo se ve si el año fue de titulares buenos o de titulares malos.
## LA ENTREVISTA AL PASO (C6): si esta semana te paró un medio nuevo.
func _al_paso_nuevo() -> void:
	if mundo == null or mundo.prensa == null or mundo.prensa.al_paso.is_empty():
		return
	## Si hay un periódico abierto (de esta semana o de otra que pasó de
	## corrido), la entrevista espera a que se cierre.
	for h in get_children():
		if h is PortadaPeriodico and not h.is_queued_for_deletion():
			if not h.cerrado.is_connected(_al_paso_nuevo):
				h.cerrado.connect(_al_paso_nuevo)
			return
	for h in get_children():
		if h is PieDeCampo and not h.is_queued_for_deletion():
			return
	var n := PieDeCampo.mostrar_al_paso(self, mundo.prensa)
	if n != null:
		n.cerrado.connect(_refrescar)

func _portada_nueva() -> void:
	if mundo == null or mundo.prensa == null or mundo.prensa.portadas.is_empty():
		_al_paso_nuevo()
		return
	var d: Dictionary = mundo.prensa.portadas[0]
	var nueva := bool(d.get("nueva", false))
	for x: Dictionary in mundo.prensa.portadas:
		x.erase("nueva")
	if nueva and PortadaPeriodico.auto():
		PortadaPeriodico.mostrar(self, mundo, d)
	_al_paso_nuevo()
