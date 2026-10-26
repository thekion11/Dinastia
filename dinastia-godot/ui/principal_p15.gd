extends "res://ui/principal_p14.gd"
## [Capa 14/17 de `principal.gd`] _construir, abrir_tutorial, tutorial_objetivo, tutorial_hecho, tutorial_accion

# --- construcción -----------------------------------------------------------

func _construir() -> void:
	## El fondo. Debajo va el color plano de siempre -si la textura fallara al
	## rasterizar, la pantalla sigue siendo legible en vez de quedarse en negro-
	## y encima la escena elegida en Ajustes.
	var fondo := ColorRect.new()
	fondo.color = _pal_fondo()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_fondo_raiz = fondo
	## El tema de la paleta se cuelga de la raiz ANTES de crear ningun control:
	## lo que se pinte despues ya nace con los colores elegidos.
	_aplicar_tema()
	_fondo_escena = TextureRect.new()
	_fondo_escena.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo_escena.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	## COVERED y no SCALE: los fondos son 16:9 igual que la ventana, así que no
	## recorta casi nada, pero si alguien juega en 21:9 es mejor perder un poco
	## de borde que deformar la escena entera.
	_fondo_escena.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fondo_escena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo_escena)
	## Y encima del dibujo, el clima: lluvia, nieve, confeti. Va aparte del fondo
	## porque son dos catalogos que se combinan, no uno con veinticuatro entradas
	## multiplicadas por diez.
	_clima = FondoAnimado.new()
	_clima.modo = _clima_elegido
	_clima.interactivo = _clima_interactivo
	add_child(_clima)
	resized.connect(func() -> void:
		if _clima != null:
			_clima.ajustar_area(size))
	_aplicar_fondo()
	## VELO DE LECTURA DE LA CABECERA (25-9-2026). El análisis externo: "el
	## texto de cabecera sobre el fondo de focos se lee mal". La línea gris de
	## la jornada, los sueldos y la confianza cae justo sobre los focos del
	## fondo de estadio -puntos casi blancos-. Un degradado negro que se apaga
	## hacia la mitad de la pantalla oscurece solo la franja de arriba, sirve
	## para los 24 fondos elegibles y no tapa nada: ignora el ratón.
	var velo := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0.62))
	grad.set_color(1, Color(0, 0, 0, 0.0))
	var tex_velo := GradientTexture2D.new()
	tex_velo.gradient = grad
	tex_velo.fill_from = Vector2(0.5, 0.0)
	tex_velo.fill_to = Vector2(0.5, 1.0)
	tex_velo.width = 4
	tex_velo.height = 64
	velo.texture = tex_velo
	velo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	velo.stretch_mode = TextureRect.STRETCH_SCALE
	velo.anchor_right = 1.0
	velo.anchor_bottom = 0.48
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 10)
	raiz.offset_left = 18; raiz.offset_top = 14
	raiz.offset_right = -18; raiz.offset_bottom = -14
	add_child(raiz)

	## La cabecera con el escudo del club al lado del nombre. Es lo primero que se
	## ve al abrir el juego y es lo que hace que sea TU club y no "el club".
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	raiz.add_child(cab)
	_escudo_cabecera = Control.new()
	_escudo_cabecera.custom_minimum_size = Vector2(44, 44)
	cab.add_child(_escudo_cabecera)
	_cabecera = _texto(26, COL_TEXTO)
	_cabecera.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(_cabecera)
	## LA DERECHA DE LA CABECERA, como en el HTML del usuario: la plata en
	## grande y la fecha debajo, separadas del nombre del club por todo el
	## ancho. Antes esos dos datos vivían perdidos en la línea de texto
	## corrido de abajo, entre la jornada y la media del plantel.
	var empuje := Control.new()
	empuje.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(empuje)
	var caja_plata := VBoxContainer.new()
	caja_plata.alignment = BoxContainer.ALIGNMENT_CENTER
	caja_plata.add_theme_constant_override("separation", 0)
	cab.add_child(caja_plata)
	_lbl_caja = _texto(20, COL_VERDE)
	_lbl_caja.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caja_plata.add_child(_lbl_caja)
	_lbl_fecha = _texto(11, COL_SUAVE)
	_lbl_fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caja_plata.add_child(_lbl_fecha)
	## EL BUSCADOR GLOBAL, de `vQoL()`. Va en la cabecera y no escondido en una
	## pestaña porque su gracia es estar SIEMPRE a mano: son ~9.000 jugadores en
	## 384 clubes, y buscar a uno por nombre yendo de pestaña en pestaña es
	## imposible. Escribes, Enter, y se abre su ficha o la de su club.
	## Un gris más claro que COL_SUAVE: es la línea que dice cómo vas -objetivo
	## y confianza-, y sobre los fondos con focos no se leía.
	_sub = _texto(13, COL_SUAVE.lightened(0.35))
	raiz.add_child(_sub)
	_despacho = VBoxContainer.new()
	_despacho.add_theme_constant_override("separation", 4)
	raiz.add_child(_despacho)

	_botones = HBoxContainer.new()
	_botones.add_theme_constant_override("separation", 8)
	raiz.add_child(_botones)
	_selector = OptionButton.new()
	## 250 y no más: el selector, los siete botones de acción y sus separaciones
	## sumaban más que la ventana, y como esta fila vive en la RAÍZ, ese exceso
	## empujaba TODO lo de abajo -incluidas las tres columnas- fuera del borde
	## derecho. Se veía en captura: la ficha del jugador cortada por la mitad.
	## 208 y no 250: el boton del mapa que se añadio al lado ocupa 34 mas 8 de
	## separacion, y esta fila vive en la RAIZ -lo que se pase de ancho empuja
	## TODO lo de abajo fuera del borde derecho y corta la ficha del jugador por
	## la mitad-. Se descuentan exactamente esos 42 pixeles.
	_selector.custom_minimum_size = Vector2(208, 34)
	_selector.clip_text = true
	## Y `fit_to_longest_item = false`, que es lo que de verdad lo arregla.
	##
	## `clip_text` deja que el TEXTO se recorte, pero un OptionButton sigue
	## PIDIENDO de ancho minimo lo que mide su item mas largo -aqui «Colo-Colo ·
	## Primera Division» y compañia-: pedia 386 px con un minimo declarado de 208,
	## la fila entera sumaba 1.286 sobre un viewport logico de 1.280 y todo lo de
	## abajo se salia por la derecha. Se veia como la ficha del jugador cortada.
	_selector.fit_to_longest_item = false
	_selector.item_selected.connect(_al_elegir_club)
	_botones.add_child(_selector)
	## Y el boton que abre el selector DE VERDAD: mapa del pais, escudos y datos
	## del club. El desplegable de al lado se queda para cambiar rapido entre dos
	## que ya conoces, que es para lo unico que servia.
	var b_mapa := Button.new()
	b_mapa.text = "🌎"
	b_mapa.tooltip_text = Idiomas.t("Elegir club con el mapa: países, escudos y datos de cada equipo")
	b_mapa.custom_minimum_size = Vector2(34, 34)
	b_mapa.pressed.connect(_abrir_elegir_club)
	_botones.add_child(b_mapa)
	## EL MENÚ DE CALENDARIO. Antes estos cuatro eran botones sueltos en la
	## fila, y con el buscador al lado la fila entera ya no entraba ni
	## recortada: cada botón se veía a media palabra ("Dirigir el parti",
	## "Temporada sig"...) -lo notó el usuario jugando-. Agruparlos en un
	## desplegable libera cuatro anchos de golpe y de paso les da la casa que
	## pedía: "un menú que sea el de calendario".
	var menu_calendario := MenuButton.new()
	menu_calendario.text = Idiomas.t("📅 Calendario")
	menu_calendario.custom_minimum_size = Vector2(0, 32)
	menu_calendario.clip_text = true
	menu_calendario.tooltip_text = Idiomas.t("Jugar el partido, avanzar semana, jugar la temporada o pasar a la siguiente")
	menu_calendario.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_calendario.size_flags_stretch_ratio = 1.3
	var pop_calendario := menu_calendario.get_popup()
	pop_calendario.add_item("Jugar el partido", 0)
	pop_calendario.add_item("Avanzar semana", 1)
	pop_calendario.add_item("Jugar la temporada", 2)
	pop_calendario.add_item("Temporada siguiente", 3)
	pop_calendario.id_pressed.connect(_al_elegir_calendario)
	_botones.add_child(menu_calendario)
	## "Un día" tiene botón PROPIO y no una entrada más del desplegable: es la
	## acción que más se repite en un manager -pasar el rato hasta el sábado-
	## y esconderla tras dos clics la volvería incómoda. Pedido del usuario.
	var b_dia := Button.new()
	b_dia.text = Idiomas.t("⏭ Un día")
	b_dia.tooltip_text = Idiomas.t("Avanza un día del calendario. Al pasar el domingo corre la semana entera.")
	b_dia.custom_minimum_size = Vector2(84, 32)
	b_dia.pressed.connect(_avanzar_dia)
	_botones.add_child(b_dia)
	_guia.nodos["un_dia"] = b_dia
	_guia.nodos["calendario"] = menu_calendario
	## Las otras dos puertas contextuales, como iconos: el partido de esta
	## semana y la plata. Van aquí y no en la cabecera porque la cabecera es
	## un solo Label y partirla en zonas clicables habría costado más de lo
	## que da.
	var b_hub_partido := Button.new()
	b_hub_partido.text = "⚽"
	b_hub_partido.tooltip_text = Idiomas.t("Partido y calendario")
	b_hub_partido.custom_minimum_size = Vector2(34, 32)
	b_hub_partido.pressed.connect(func() -> void: _abrir_hub("partido"))
	_botones.add_child(b_hub_partido)
	_guia.nodos["partido"] = b_hub_partido
	var b_hub_dinero := Button.new()
	b_hub_dinero.text = "💰"
	b_hub_dinero.tooltip_text = Idiomas.t("Finanzas, mercado y agentes libres")
	b_hub_dinero.custom_minimum_size = Vector2(34, 32)
	b_hub_dinero.pressed.connect(func() -> void: _abrir_hub("dinero"))
	_botones.add_child(b_hub_dinero)
	_guia.nodos["dinero"] = b_hub_dinero
	_guia.nodos["guardar"] = _boton("Guardar", _guardar)
	_boton("Cargar", _partida.cargar)
	_boton("Otro mundo", _partida.nueva)
	## El buscador va en la fila de acciones, no en la cabecera: ahí arriba lo
	## tapaba el aviso de mercado, que flota en la esquina derecha.
	_buscador = LineEdit.new()
	## "Buscar jugador o club…" no entraba en 150 px y se leía "Buscar jugador
	## o clu" (lo notó el análisis externo). El texto largo va al tooltip.
	_buscador.placeholder_text = Idiomas.t("🔎 Buscar…")
	_buscador.tooltip_text = Idiomas.t("Buscar un jugador o un club por nombre (Enter para abrir su ficha)")
	## 150 y no 210: cada píxel de esta fila sale del ancho de las tres columnas
	## de abajo, y a 210 volvía a cortarse la ficha del jugador por el borde.
	_buscador.custom_minimum_size = Vector2(150, 32)
	_buscador.add_theme_font_size_override("font_size", 12)
	_buscador.text_submitted.connect(_buscar_global)
	_botones.add_child(_buscador)

	## EL MENÚ CENTRAL, A ANCHO COMPLETO (10-9-2026). Vivía dentro de la
	## columna del medio -unos 620 px- y por eso TODO se recortaba: "CENTRA",
	## "HISTORI", "OPERACI". El usuario mandó la captura de su propio HTML,
	## donde el menú cruza la ventana entera y los rótulos entran enteros; esa
	## es la diferencia, no el tamaño de la fuente. Ahora cuelga de `raiz`,
	## encima de las tres columnas, con el ancho de la pantalla.
	_fila_grupos = HBoxContainer.new()
	_fila_grupos.add_theme_constant_override("separation", 6)
	raiz.add_child(_fila_grupos)
	## EL CARRIL DE CHIPS (nivel 2), en un `ScrollContainer` horizontal: en
	## Android se arrastra con el dedo y en PC se desplaza con L2/R2. Vertical
	## apagado, o al primer chip alto la barra empieza a crecer hacia abajo.
	var carril := ScrollContainer.new()
	carril.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	carril.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	carril.custom_minimum_size = Vector2(0, 36)
	carril.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raiz.add_child(carril)
	_fila_sub = HBoxContainer.new()
	_fila_sub.add_theme_constant_override("separation", 6)
	carril.add_child(_fila_sub)

	## LA TIRA DE DÍAS, calcada de la del HTML del usuario: los siete días con
	## el de hoy encendido y el del partido marcado. Es lo que convierte
	## "semana 12" en una fecha que uno entiende sin pensar.
	_fila_dias = HBoxContainer.new()
	_fila_dias.add_theme_constant_override("separation", 4)
	raiz.add_child(_fila_dias)

	var columnas := HBoxContainer.new()
	columnas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.add_theme_constant_override("separation", 12)
	raiz.add_child(columnas)

	## Columna 1: la tabla de lo que se juega esta semana -liga, copa o el grupo
	## continental-. El título cambia con ella, por eso se guarda.
	_lista_tabla = _columna(columnas, "TABLA DE POSICIONES", 1.9)
	_titulo_tabla = _ultimo_titulo_columna
	## Pulsar la columna abre la ficha completa de la competición. Es la columna
	## que menos sitio tiene -comparte pantalla con el plantel y la ficha- y la
	## que más gente quiere mirar con calma, así que se le da una salida.
	var abrir_comp := Button.new()
	abrir_comp.flat = true
	abrir_comp.text = Idiomas.t("Ver la competición  ▸")
	abrir_comp.add_theme_font_size_override("font_size", 11)
	abrir_comp.add_theme_color_override("font_color", _color_de_paleta(COL_ACENTO))
	abrir_comp.pressed.connect(_abrir_competicion)
	_ultima_caja_columna.add_child(abrir_comp)
	## Y EL HUB DE COMPETICIONES, estilo FC26: la tabla no lleva solo a SU
	## competición, lleva a todas las del club -liga, copa, continental,
	## selección, federación-. Es una de las cuatro puertas contextuales que
	## permiten que el nivel 1 se quede en seis bloques.
	var abrir_hub_comp := Button.new()
	abrir_hub_comp.flat = true
	abrir_hub_comp.text = Idiomas.t("🏆 Todas las competiciones  ▸")
	abrir_hub_comp.add_theme_font_size_override("font_size", 11)
	abrir_hub_comp.add_theme_color_override("font_color", _color_de_paleta(COL_ORO))
	abrir_hub_comp.pressed.connect(func() -> void: _abrir_hub("competiciones"))
	_ultima_caja_columna.add_child(abrir_hub_comp)

	## Columna 2: plantel y mercado, en pestañas. Son la misma lista de jugadores
	## mirada de dos maneras, así que comparten el mismo pintado y el mismo clic.
	var caja := _panel()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = 2.6
	columnas.add_child(caja)
	var caja_v := VBoxContainer.new()
	caja_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja_v.offset_left = 6; caja_v.offset_top = 4
	caja_v.offset_right = -6; caja_v.offset_bottom = -6
	caja_v.add_theme_constant_override("separation", 4)
	caja.add_child(caja_v)

	## EL MARCO DE PÁGINAS. `_pestanas` no se puede mover a mano -es hijo de un
	## Container y este le reimpone la posición en cada `sort_children`-, así
	## que el desliz se hace con los MÁRGENES de este marco, que sí se
	## respetan. Es lo que permite que cambiar de bloque se sienta como pasar
	## una página y no como un corte seco.
	_marco_paginas = MarginContainer.new()
	_marco_paginas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja_v.add_child(_marco_paginas)
	_pestanas = TabContainer.new()
	_pestanas.tabs_visible = false
	_pestanas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_marco_paginas.add_child(_pestanas)
	_lista_plantel = _hoja(_pestanas, "Mi plantel")
	## ── PESTAÑA MERCADO ─────────────────────────────────────────────────────
	## El componente se instancia aquí y se engancha por señales. Principal no
	## vuelve a llamar a ninguna función interna del mercado: todo el pintado
	## lo hace PanelMercado, y lo que afecta al mundo lo recibe Principal.
	var _hoja_mercado := _hoja(_pestanas, "Mercado")
	_panel_mercado = PanelMercado.new()
	_panel_mercado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_mercado.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hoja_mercado.add_child(_panel_mercado)
	_panel_mercado.fichar_pedido.connect(_ui_plantel._abrir_negociacion)
	_panel_mercado.oferta_respondida.connect(_responder_oferta_mercado)
	_panel_mercado.oferta_enviada.connect(_enviar_oferta_negociacion)
	_panel_mercado.negociacion_cancelada.connect(_ui_plantel._cancelar_negociacion)
	_panel_mercado.rol_ajustado.connect(_al_ajustar_rol_neg)
	_panel_mercado.campo_ajustado.connect(_al_ajustar_campo_neg)
	_panel_mercado.intercambio_elegido.connect(func(j: Jugador) -> void:
		if mundo.mercado.negociacion != null:
			mundo.mercado.negociacion.poner_intercambio(j)
			_refrescar())
	_panel_mercado.refrescar_pedido.connect(_refrescar)
	_panel_mercado.escrito.connect(_escribir)
	_lista_copa = _hoja(_pestanas, "Copa")
	_lista_club = _hoja(_pestanas, "Club")
	_lista_conti = _hoja(_pestanas, "Continental")
	_lista_medico = _hoja(_pestanas, "Enfermería")
	_lista_logros = _hoja(_pestanas, "Logros")
	_lista_entren = _hoja(_pestanas, "Entrenar")
	_lista_fed = _hoja(_pestanas, "Federación")
	_lista_estadio = _hoja(_pestanas, "Estadio")
	_lista_seleccion = _hoja(_pestanas, "Selección")
	_lista_cantera = _hoja(_pestanas, "Cantera")
	_lista_contratos = _hoja(_pestanas, "Contratos")
	_lista_comparar = _hoja(_pestanas, "Comparar")
	_lista_inicio = _hoja(_pestanas, "Inicio")
	_lista_gente = _hoja(_pestanas, "Gente")
	_lista_records = _hoja(_pestanas, "Récords")
	_lista_legado = _hoja(_pestanas, "Legado")
	_lista_finanzas = _hoja(_pestanas, "Finanzas")
	_lista_camarin = _hoja(_pestanas, "Camarín")
	_lista_ciudad = _hoja(_pestanas, "Ciudad")
	_lista_editor = _hoja(_pestanas, "Editor")
	_lista_glosario = _hoja(_pestanas, "Glosario")
	_lista_ajustes = _hoja(_pestanas, "Ajustes")
	_lista_correo = _hoja(_pestanas, "Correo")
	_lista_redes = _hoja(_pestanas, "Redes")
	_lista_vida = _hoja(_pestanas, "Vida")
	_lista_habilidades = _hoja(_pestanas, "Habilidades")
	_lista_libres = _hoja(_pestanas, "Libres")
	_lista_premios = _hoja(_pestanas, "Premios")
	_lista_clubes = _hoja(_pestanas, "Clubes")
	_lista_desafios = _hoja(_pestanas, "Desafíos")
	_lista_tactica = _hoja(_pestanas, "Táctica")
	## `partido:['partido']` del HTML. Hasta esta tanda era un atajo de dos
	## líneas al botón de arriba; ahora es la PREVIA (`vPrevia()`): con quién
	## juegas, quién pita, quién dirige enfrente, cómo se miden las plantillas y
	## qué dicen las casas de apuestas. Se repinta en `_pintar_partido()`.
	_lista_partido = _hoja(_pestanas, "Partido")
	## `vCalendario` no existe en el HTML -esto es una pantalla nueva, pedida
	## por el usuario con una captura de referencia de otro manager (grilla de
	## partidos marcados con el escudo del rival, desde la que se simula de
	## corrido o se salta el partido sin dirigirlo)-. Se apoya en datos que ya
	## existen (`Liga.calendario`) en vez de inventar un sistema de fechas
	## nuevo.
	_lista_calendario = _hoja(_pestanas, "Calendario")

	_construir_grupos()
	_pestanas.tab_changed.connect(_al_cambiar_pestana)
	_elegir_grupo("central")

	## Columna 3: la ficha del jugador seleccionado, y debajo lo que va pasando.
	var der := VBoxContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.size_flags_stretch_ratio = 1.9
	der.add_theme_constant_override("separation", 12)
	columnas.add_child(der)
	_col_derecha = der
	_ficha = _bloque(der, "FICHA DEL JUGADOR", 2.0)
	## CON SCROLL PROPIO (25-9-2026). La ficha completa -atributos, contrato,
	## cabeza, habilidades, notas- pide unos 1.060 px de alto y la columna no
	## tenía scroll: estiraba la fila entera y, con la ventana a 1280x720
	## lógicos, todo lo de abajo de las tres columnas quedaba fuera de la
	## pantalla sin forma de llegar (el botón "Jugar el partido", el final de la
	## tabla). Medido con `pruebas/captura_modos_partido.gd`.
	_ficha = _con_scroll(_ficha)
	## LA PUERTA AL PLANTEL. Tocar la zona del jugador lleva al hub con todo
	## lo que se hace con futbolistas -plantel, táctica, entrenar, enfermería,
	## camarín, cantera, contratos-, en vez de tener siete pestañas más
	## arriba. Es la idea que pidió el usuario mirando FC26.
	var b_plantel := Button.new()
	b_plantel.text = Idiomas.t("👔 Plantel y cuerpo del equipo  ▸")
	b_plantel.flat = true
	b_plantel.add_theme_font_size_override("font_size", 11)
	b_plantel.add_theme_color_override("font_color", _color_de_paleta(COL_ACENTO))
	b_plantel.pressed.connect(func() -> void: _abrir_hub("plantel"))
	_ultima_caja_columna.add_child(b_plantel)
	_guia.nodos["plantel"] = b_plantel
	var caja_reg := _bloque(der, "LO QUE VA PASANDO", 1.0)
	_registro = RichTextLabel.new()
	_registro.bbcode_enabled = true
	_registro.scroll_following = true
	_registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_registro.add_theme_font_size_override("normal_font_size", 12)
	caja_reg.add_child(_registro)

	## EL PANEL LATERAL (mapa de metas 23): a la izquierda y por encima del menú
	## central; el contenido se corre lo que mide el riel para no quedar tapado.
	raiz.offset_left = 18.0 + MenuLateral.ANCHO_RIEL
	_menu_lateral = MenuLateral.crear(self)
	add_child(_menu_lateral)
	_reloj_diseno = Timer.new()
	_reloj_diseno.wait_time = ROTAR_CADA
	_reloj_diseno.autostart = true
	_reloj_diseno.timeout.connect(_siguiente_diseno)
	add_child(_reloj_diseno)

## EL TUTORIAL vive en `ui/principal/guia_tutorial.gd` (fase 0). Estos cuatro
## puentes son el contrato con `ui/componentes/tutorial.gd`, que los llama por
## nombre (con `has_method` delante), y con Ajustes y el panel de objetivos.
func abrir_tutorial(modo: String = "") -> void:
	_guia.abrir(modo)

func tutorial_objetivo(clave: String) -> Control:
	return _guia.objetivo(clave)

func tutorial_hecho(clave: String) -> bool:
	return _guia.hecho(clave)

func tutorial_accion(clave: String) -> void:
	_guia.accion(clave)
