class_name ConstruirMenu
extends RefCounted
## (fase 6, paso 7 del plan §7.1: sale de `Principal`, ui/principal_p15.gd, el 27-10-2026). `p` es la pantalla principal;
## sus miembros se usan como `p.x` y `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

## Monta la pantalla entera en cuatro partes (fase 6, §4: era una sola función de 403 líneas).
func _construir() -> void:
	_montar_fondo()
	var raiz := _montar_cabecera()
	_montar_carril(raiz)
	ConstruirColumnas.montar(p, raiz)

## (10-11-2026, arranque) Lo mismo en trozos: un paso por fotograma para que la pantalla de carga que hay encima se siga animando (`CargaMenu`; solo con pantalla). El resultado es idéntico al de `_construir()`.
func _construir_en_trozos() -> void:
	var arbol := p.get_tree()
	_montar_fondo()
	PedidoPartida.montaje_avance = 0.2
	await arbol.process_frame
	var raiz := _montar_cabecera()
	PedidoPartida.montaje_avance = 0.4
	await arbol.process_frame
	_montar_carril(raiz)
	PedidoPartida.montaje_avance = 0.5
	await arbol.process_frame
	ConstruirColumnas.montar(p, raiz)
	PedidoPartida.montaje_avance = 0.8

## El fondo, el tema de la paleta, el clima y el velo de lectura de la cabecera.
func _montar_fondo() -> void:
	## El fondo. Debajo va el color plano de siempre -si la textura fallara al
	## rasterizar, la pantalla sigue siendo legible en vez de quedarse en negro-
	## y encima la escena elegida en Ajustes.
	var fondo := ColorRect.new()
	fondo.color = p._pal_fondo()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(fondo)
	p._fondo_raiz = fondo
	## El tema de la paleta se cuelga de la raiz ANTES de crear ningun control:
	## lo que se pinte despues ya nace con los colores elegidos.
	p._aplicar_tema()
	p._fondo_escena = TextureRect.new()
	p._fondo_escena.set_anchors_preset(Control.PRESET_FULL_RECT)
	p._fondo_escena.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	## COVERED y no SCALE: los fondos son 16:9 igual que la ventana, así que no
	## recorta casi nada, pero si alguien juega en 21:9 es mejor perder un poco
	## de borde que deformar la escena entera.
	p._fondo_escena.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	p._fondo_escena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(p._fondo_escena)
	## Y encima del dibujo, el clima: lluvia, nieve, confeti. Va aparte del fondo
	## porque son dos catalogos que se combinan, no uno con veinticuatro entradas
	## multiplicadas por diez.
	p._clima = FondoAnimado.new()
	p._clima.modo = p._clima_elegido
	p._clima.interactivo = p._clima_interactivo
	p.add_child(p._clima)
	var ahorro := AhorroMenu.new()   ## (3-11) en MÍNIMA, sin 3D a la vista: bajo consumo y partículas en pausa
	ahorro.principal = p
	p.add_child(ahorro)
	p.resized.connect(func() -> void:
		if p._clima != null:
			p._clima.ajustar_area(p.size))
	p._aplicar_fondo()
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
	p.add_child(velo)


## La raíz vertical, la cabecera (escudo, club, dinero, fecha) y la barra de botones.
func _montar_cabecera() -> VBoxContainer:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 10)
	raiz.offset_left = 18; raiz.offset_top = 14
	raiz.offset_right = -76 if EscalaMovil.es_tactil() and not DisenoVertical.activo() else -18; raiz.offset_bottom = -14   ## (10-11) táctil: hueco para el cajón 🎯, que tapaba «⤢»
	p.add_child(raiz)

	## La cabecera con el escudo del club al lado del nombre. Es lo primero que se
	## ve al abrir el juego y es lo que hace que sea TU club y no "el club".
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	raiz.add_child(cab)
	p._escudo_cabecera = Control.new()
	p._escudo_cabecera.custom_minimum_size = Vector2(44, 44)
	cab.add_child(p._escudo_cabecera)
	p._cabecera = p._texto(26, p.COL_TEXTO)
	p._cabecera.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p._cabecera.clip_text = true   ## con la letra grande el nombre del club se recorta (…) en vez de empujar el dinero fuera de la pantalla
	p._cabecera.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cab.add_child(p._cabecera)
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
	p._lbl_caja = p._texto(20, p.COL_VERDE)
	p._lbl_caja.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caja_plata.add_child(p._lbl_caja)
	p._lbl_fecha = p._texto(11, p.COL_SUAVE)
	p._lbl_fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caja_plata.add_child(p._lbl_fecha)
	## EL BUSCADOR GLOBAL, de `vQoL()`. Va en la cabecera y no escondido en una
	## pestaña porque su gracia es estar SIEMPRE a mano: son ~9.000 jugadores en
	## 384 clubes, y buscar a uno por nombre yendo de pestaña en pestaña es
	## imposible. Escribes, Enter, y se abre su ficha o la de su club.
	## Un gris más claro que COL_SUAVE: es la línea que dice cómo vas -objetivo
	## y confianza-, y sobre los fondos con focos no se leía.
	p._sub = p._texto(13, p.COL_SUAVE.lightened(0.35))
	if DisenoVertical.activo():   ## de pie la línea de estado (liga, jornada, sueldos…) baja de renglón en vez de salirse
		p._sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(p._sub)
	p._despacho = VBoxContainer.new()
	p._despacho.add_theme_constant_override("separation", 4)
	raiz.add_child(p._despacho)

	p._botones = HBoxContainer.new()
	p._botones.add_theme_constant_override("separation", 8)
	DisenoVertical.fila_deslizable(raiz, p._botones)
	p._selector = OptionButton.new()
	## 250 y no más: el selector, los siete botones de acción y sus separaciones
	## sumaban más que la ventana, y como esta fila vive en la RAÍZ, ese exceso
	## empujaba TODO lo de abajo -incluidas las tres columnas- fuera del borde
	## derecho. Se veía en captura: la ficha del jugador cortada por la mitad.
	## 208 y no 250: el boton del mapa que se añadio al lado ocupa 34 mas 8 de
	## separacion, y esta fila vive en la RAIZ -lo que se pase de ancho empuja
	## TODO lo de abajo fuera del borde derecho y corta la ficha del jugador por
	## la mitad-. Se descuentan exactamente esos 42 pixeles.
	p._selector.custom_minimum_size = Vector2(208, 34)
	p._selector.clip_text = true
	## Y `fit_to_longest_item = false`, que es lo que de verdad lo arregla: `clip_text` recorta el TEXTO, pero un OptionButton sigue
	## PIDIENDO de ancho minimo lo que mide su item mas largo -aqui «Colo-Colo ·
	## Primera Division» y compañia-: pedia 386 px con un minimo declarado de 208,
	## la fila entera sumaba 1.286 sobre un viewport logico de 1.280 y todo lo de
	## abajo se salia por la derecha. Se veia como la ficha del jugador cortada.
	p._selector.fit_to_longest_item = false
	p._selector.item_selected.connect(p._al_elegir_club)
	## (3-11, rediseño del menú central) El selector y el 🌎 dejan la barra: elegir otro club se hace en
	## Competiciones → «Ver otro club» (el mapa). El desplegable sigue existiendo (se llena igual), oculto.
	p._selector.visible = false
	p._botones.add_child(p._selector)
	## EL MENÚ DE CALENDARIO. Antes estos cuatro eran botones sueltos en la
	## fila, y con el buscador al lado la fila entera ya no entraba ni
	## recortada: cada botón se veía a media palabra ("Dirigir el parti",
	## "Temporada sig"...) -lo notó el usuario jugando-. Agruparlos en un
	## desplegable libera cuatro anchos de golpe y de paso les da la casa que
	## pedía: "un menú que sea el de calendario".
	var menu_calendario := MenuButton.new()
	menu_calendario.text = Idiomas.t("📅 Calendario")
	menu_calendario.custom_minimum_size = Vector2(150 if DisenoVertical.activo() else 0, 32)
	menu_calendario.clip_text = true
	menu_calendario.tooltip_text = Idiomas.t("El calendario: jugar el partido y avanzar semana; al terminar la liga, pasar a la temporada siguiente")
	menu_calendario.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_calendario.size_flags_stretch_ratio = 1.3
	var pop_calendario := menu_calendario.get_popup()
	## (9-11) Las opciones las pone `AvanceSemana.actualizar_calendario` según la fecha: durante la liga, «Jugar el partido» y «Avanzar semana»; SOLO al
	## terminarla, «Temporada siguiente» (antes no existe). Sin «Jugar la temporada» (orden del dueño, como PES 2020).
	AvanceSemana.rellenar_calendario(pop_calendario, true)
	pop_calendario.id_pressed.connect(p._al_elegir_calendario)
	p._botones.add_child(menu_calendario)
	## "Un día" tuvo botón PROPIO (la acción más repetida); hoy lo reemplaza «Avanzar» (`BotonesAvance`).
	var b_dia := Button.new()
	b_dia.text = Idiomas.t("⏭ Un día")
	b_dia.tooltip_text = Idiomas.t("Avanza un día del calendario. Al pasar el domingo corre la semana entera.")
	b_dia.custom_minimum_size = Vector2(84, 32)
	b_dia.pressed.connect(p._avanzar_dia)
	p._botones.add_child(b_dia)
	p._guia.nodos["un_dia"] = b_dia
	## (9-11, idea del PES 2020) «Hito»: avanza hasta lo siguiente que importa (tu partido, el cierre del mercado, la semana).
	var b_hito := Button.new()
	b_hito.text = Idiomas.t("⏩ Hito")
	b_hito.custom_minimum_size = Vector2(84, 32)
	b_hito.pressed.connect(p._avanzar_hasta_hito)
	p._botones.add_child(b_hito)
	p._guia.nodos["hito"] = b_hito
	p._guia.nodos["calendario"] = menu_calendario
	BotonesAvance.montar(p, [menu_calendario, b_dia, b_hito])   ## (17-11, orden del dueño) el botón «Avanzar» nuevo reemplaza a estos tres
	## (3-11, rediseño) El ⚽ y el 💰 tienen su menú en el panel lateral (Partido, Dinero); Guardar, Cargar y Otro mundo
	## viven en Ajustes → Partida y guardado. La guía del tutorial señala sus botones del riel (abajo, al crear el panel).
	## El buscador va en la fila de acciones, no en la cabecera: ahí arriba lo
	## tapaba el aviso de mercado, que flota en la esquina derecha.
	p._buscador = LineEdit.new()
	## El texto largo va al tooltip ("Buscar jugador o club…" no entraba en 150 px).
	p._buscador.placeholder_text = Idiomas.t("🔎 Buscar…")
	p._buscador.tooltip_text = Idiomas.t("Buscar un jugador o un club por nombre (Enter para abrir su ficha)")
	## 150 px y no más: cada píxel de esta fila sale del ancho de las columnas de abajo.
	p._buscador.custom_minimum_size = Vector2(150, 32)
	p._buscador.add_theme_font_size_override("font_size", Tema.letra(12))
	p._buscador.text_submitted.connect(p._buscar_global)
	p._botones.add_child(p._buscador)

	## EL MENÚ CENTRAL, A ANCHO COMPLETO (10-9-2026). Vivía dentro de la
	## columna del medio -unos 620 px- y por eso TODO se recortaba: "CENTRA",
	## "HISTORI", "OPERACI". El usuario mandó la captura de su propio HTML,
	## donde el menú cruza la ventana entera y los rótulos entran enteros; esa
	## es la diferencia, no el tamaño de la fuente. Ahora cuelga de `raiz`,
	## encima de las tres columnas, con el ancho de la pantalla.
	p._fila_grupos = HBoxContainer.new()
	p._fila_grupos.add_theme_constant_override("separation", 6)
	## (3-11, rediseño del menú central) Sin fila de bloques ni de pestañas: cada sección se abre en su menú del
	## panel lateral. Siguen existiendo (la navegación por chips y las pruebas los usan), ocultas.
	p._fila_grupos.visible = false
	raiz.add_child(p._fila_grupos)
	return raiz

## El carril de chips y la fila de días.
func _montar_carril(raiz: VBoxContainer) -> void:
	## EL CARRIL DE CHIPS (nivel 2), en un `ScrollContainer` horizontal: en
	## Android se arrastra con el dedo y en PC se desplaza con L2/R2. Vertical
	## apagado, o al primer chip alto la barra empieza a crecer hacia abajo.
	var carril := ScrollContainer.new()
	carril.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	carril.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	carril.custom_minimum_size = Vector2(0, 36)
	carril.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	carril.visible = false   ## (3-11, rediseño) ver `_fila_grupos`
	raiz.add_child(carril)
	p._fila_sub = HBoxContainer.new()
	p._fila_sub.add_theme_constant_override("separation", 6)
	carril.add_child(p._fila_sub)

	## LA TIRA DE DÍAS, calcada de la del HTML del usuario: los siete días con
	## el de hoy encendido y el del partido marcado. Es lo que convierte
	## "semana 12" en una fecha que uno entiende sin pensar.
	p._fila_dias = HBoxContainer.new()
	p._fila_dias.add_theme_constant_override("separation", 4)
	DisenoVertical.fila_deslizable(raiz, p._fila_dias)
	## (9-11, idea del PES 2020) La fila de los próximos partidos con el escudo del rival, justo debajo de la tira de días.
	var fila_prox := HBoxContainer.new()
	fila_prox.add_theme_constant_override("separation", 6)
	DisenoVertical.fila_deslizable(raiz, fila_prox)
	p._guia.nodos["fila_proximos"] = fila_prox
