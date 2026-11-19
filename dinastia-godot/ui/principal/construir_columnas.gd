class_name ConstruirColumnas
extends RefCounted
## Las columnas del menú central (la tabla, el centro y la derecha), partidas de `ConstruirMenu` el 17-11-2026 para que éste no pase de 450 líneas. Mismo código, ahora estático con `p`.

## Las tres columnas: clasificación, pestañas (plantel, mercado...) y ficha con el registro.
static func montar(p: Principal, raiz: VBoxContainer) -> void:
	var columnas := HBoxContainer.new()
	columnas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.add_theme_constant_override("separation", 12)
	raiz.add_child(columnas)

	## Columna 1: la tabla de lo que se juega esta semana -liga, copa o el grupo
	## continental-. El título cambia con ella, por eso se guarda.
	p._lista_tabla = p._columna(columnas, "TABLA DE POSICIONES", 1.9)
	p._titulo_tabla = p._ultimo_titulo_columna
	## Pulsar la columna abre la ficha completa de la competición. Es la columna
	## que menos sitio tiene -comparte pantalla con el plantel y la ficha- y la
	## que más gente quiere mirar con calma, así que se le da una salida.
	var abrir_comp := Button.new()
	abrir_comp.flat = true
	abrir_comp.text = Idiomas.t("Ver la competición  ▸")
	abrir_comp.add_theme_font_size_override("font_size", Tema.letra(11))
	abrir_comp.add_theme_color_override("font_color", p._color_de_paleta(p.COL_ACENTO))
	abrir_comp.pressed.connect(p._abrir_competicion)
	p._ultima_caja_columna.add_child(abrir_comp)
	## Y EL HUB DE COMPETICIONES, estilo FC26: la tabla no lleva solo a SU
	## competición, lleva a todas las del club -liga, copa, continental,
	## selección, federación-. Es una de las cuatro puertas contextuales que
	## permiten que el nivel 1 se quede en seis bloques.
	var abrir_hub_comp := Button.new()
	abrir_hub_comp.flat = true
	abrir_hub_comp.text = Idiomas.t("🏆 Todas las competiciones  ▸")
	abrir_hub_comp.add_theme_font_size_override("font_size", Tema.letra(11))
	abrir_hub_comp.add_theme_color_override("font_color", p._color_de_paleta(p.COL_ORO))
	abrir_hub_comp.pressed.connect(func() -> void: p._abrir_hub("competiciones"))
	p._ultima_caja_columna.add_child(abrir_hub_comp)

	## Columna 2: plantel y mercado, en pestañas. Son la misma lista de jugadores
	## mirada de dos maneras, así que comparten el mismo pintado y el mismo clic.
	var caja := p._panel()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = 2.6
	columnas.add_child(caja)
	var margen_v := MarginContainer.new()   ## (9-11, estética) margen real dentro del PanelContainer
	margen_v.add_theme_constant_override("margin_left", 12)
	margen_v.add_theme_constant_override("margin_right", 12)
	margen_v.add_theme_constant_override("margin_top", 10)
	margen_v.add_theme_constant_override("margin_bottom", 10)
	caja.add_child(margen_v)
	var caja_v := VBoxContainer.new()
	caja_v.add_theme_constant_override("separation", 4)
	margen_v.add_child(caja_v)

	## EL MARCO DE PÁGINAS. `_pestanas` no se puede mover a mano -es hijo de un
	## Container y este le reimpone la posición en cada `sort_children`-, así
	## que el desliz se hace con los MÁRGENES de este marco, que sí se
	## respetan. Es lo que permite que cambiar de bloque se sienta como pasar
	## una página y no como un corte seco.
	p._marco_paginas = MarginContainer.new()
	p._marco_paginas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja_v.add_child(p._marco_paginas)
	p._pestanas = TabContainer.new()
	p._pestanas.tabs_visible = false
	p._pestanas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p._marco_paginas.add_child(p._pestanas)
	caja_v.add_child(PieMando.crear(func() -> bool: return p._menu_lateral != null and p._menu_lateral.ocupado()))   ## (12-11, PES) ayudas del mando abajo
	p._lista_plantel = p._hoja(p._pestanas, "Mi plantel")
	## ── PESTAÑA MERCADO ─────────────────────────────────────────────────────
	## El componente se instancia aquí y se engancha por señales. Principal no
	## vuelve a llamar a ninguna función interna del mercado: todo el pintado
	## lo hace PanelMercado, y lo que afecta al mundo lo recibe Principal.
	var hoja_mercado := p._hoja(p._pestanas, "Mercado")
	p._panel_mercado = PanelMercado.new()
	p._panel_mercado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p._panel_mercado.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hoja_mercado.add_child(p._panel_mercado)
	p._panel_mercado.fichar_pedido.connect(func(j: Jugador) -> void: p._ui_plantel._abrir_negociacion(j))   ## (A4 memoria) el plantel se crea al usarlo
	p._panel_mercado.oferta_respondida.connect(p._responder_oferta_mercado)
	p._panel_mercado.oferta_enviada.connect(p._enviar_oferta_negociacion)
	p._panel_mercado.negociacion_cancelada.connect(func() -> void: p._ui_plantel._cancelar_negociacion())
	p._panel_mercado.rol_ajustado.connect(p._al_ajustar_rol_neg)
	p._panel_mercado.campo_ajustado.connect(p._al_ajustar_campo_neg)
	p._panel_mercado.intercambio_elegido.connect(func(j: Jugador) -> void:
		if p.mundo.mercado.negociacion != null:
			p.mundo.mercado.negociacion.poner_intercambio(j)
			p._refrescar())
	p._panel_mercado.refrescar_pedido.connect(p._refrescar)
	p._panel_mercado.escrito.connect(p._escribir)
	p._lista_copa = p._hoja(p._pestanas, "Copa")
	p._lista_club = p._hoja(p._pestanas, "Club")
	p._lista_conti = p._hoja(p._pestanas, "Continental")
	p._lista_medico = p._hoja(p._pestanas, "Enfermería")
	p._lista_logros = p._hoja(p._pestanas, "Logros")
	p._lista_entren = p._hoja(p._pestanas, "Entrenar")
	p._lista_fed = p._hoja(p._pestanas, "Federación")
	p._lista_estadio = p._hoja(p._pestanas, "Estadio")
	p._lista_seleccion = p._hoja(p._pestanas, "Selección")
	p._lista_cantera = p._hoja(p._pestanas, "Cantera")
	p._lista_contratos = p._hoja(p._pestanas, "Contratos")
	p._lista_comparar = p._hoja(p._pestanas, "Comparar")
	p._lista_inicio = p._hoja(p._pestanas, "Inicio")
	p._lista_gente = p._hoja(p._pestanas, "Gente")
	p._lista_records = p._hoja(p._pestanas, "Récords")
	p._lista_legado = p._hoja(p._pestanas, "Legado")
	p._lista_finanzas = p._hoja(p._pestanas, "Finanzas")
	p._lista_camarin = p._hoja(p._pestanas, "Camarín")
	p._lista_ciudad = p._hoja(p._pestanas, "Ciudad")
	p._lista_editor = p._hoja(p._pestanas, "Editor")
	p._lista_glosario = p._hoja(p._pestanas, "Glosario")
	p._lista_ajustes = p._hoja(p._pestanas, "Ajustes")
	p._lista_correo = p._hoja(p._pestanas, "Correo")
	p._lista_redes = p._hoja(p._pestanas, "Redes")
	p._lista_vida = p._hoja(p._pestanas, "Vida")
	p._lista_habilidades = p._hoja(p._pestanas, "Habilidades")
	p._lista_libres = p._hoja(p._pestanas, "Libres")
	p._lista_premios = p._hoja(p._pestanas, "Premios")
	p._lista_clubes = p._hoja(p._pestanas, "Clubes")
	p._lista_desafios = p._hoja(p._pestanas, "Desafíos")
	p._lista_tactica = p._hoja(p._pestanas, "Táctica")
	## `partido:['partido']` del HTML. Hasta esta tanda era un atajo de dos
	## líneas al botón de arriba; ahora es la PREVIA (`vPrevia()`): con quién
	## juegas, quién pita, quién dirige enfrente, cómo se miden las plantillas y
	## qué dicen las casas de apuestas. Se repinta en `_pintar_partido()`.
	p._lista_partido = p._hoja(p._pestanas, "Partido")
	## `vCalendario` no existe en el HTML -esto es una pantalla nueva, pedida
	## por el usuario con una captura de referencia de otro manager (grilla de
	## partidos marcados con el escudo del rival, desde la que se simula de
	## corrido o se salta el partido sin dirigirlo)-. Se apoya en datos que ya
	## existen (`Liga.calendario`) en vez de inventar un sistema de fechas
	## nuevo.
	p._lista_calendario = p._hoja(p._pestanas, "Calendario")

	p._construir_grupos()
	p._pestanas.tab_changed.connect(p._al_cambiar_pestana)
	p._elegir_grupo("central")

	## Columna 3: la ficha del jugador seleccionado, y debajo lo que va pasando.
	var der := VBoxContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.size_flags_stretch_ratio = 1.9
	der.add_theme_constant_override("separation", 12)
	columnas.add_child(der)
	p._col_derecha = der
	p._ficha = p._bloque(der, "FICHA DEL JUGADOR", 2.0)
	## CON SCROLL PROPIO (25-9-2026). La ficha completa -atributos, contrato,
	## cabeza, habilidades, notas- pide unos 1.060 px de alto y la columna no
	## tenía scroll: estiraba la fila entera y, con la ventana a 1280x720
	## lógicos, todo lo de abajo de las tres columnas quedaba fuera de la
	## pantalla sin forma de llegar (el botón "Jugar el partido", el final de la
	## tabla). Medido con `pruebas/captura_modos_partido.gd`.
	p._ficha = p._con_scroll(p._ficha)
	## (3-11, rediseño del menú central, pedido del dueño) La ficha del jugador ya no está en el central: se ve en su
	## pantalla completa (menú Plantel, al lado del plantel). Debajo queda «Lo que va pasando», que crece.
	p._bloque_ficha = der.get_child(0) as Control
	p._bloque_ficha.visible = false
	## LA PUERTA AL PLANTEL. Tocar la zona del jugador lleva al hub con todo
	## lo que se hace con futbolistas -plantel, táctica, entrenar, enfermería,
	## camarín, cantera, contratos-, en vez de tener siete pestañas más
	## arriba. Es la idea que pidió el usuario mirando FC26.
	var b_plantel := Button.new()
	## (10-11) táctil: el rótulo corto; con la letra legible del móvil, el largo cortaba el título de la columna («ERSTE LI»)
	b_plantel.text = ("👔 " + Idiomas.t("Plantel") + "  ▸") if EscalaMovil.es_tactil() else Idiomas.t("👔 Plantel y cuerpo del equipo  ▸")
	b_plantel.flat = true
	b_plantel.add_theme_font_size_override("font_size", Tema.letra(11))
	b_plantel.add_theme_color_override("font_color", p._color_de_paleta(p.COL_ACENTO))
	b_plantel.pressed.connect(func() -> void: p._abrir_hub("plantel"))
	## (10-11) En la fila del TÍTULO de su columna (junto a «⤢»), no al pie: en el móvil (2400x1080 = 480 px lógicos de alto) cada botón del pie sube
	## a 49 px por el margen táctil y este quedaba 30-37 px por debajo de la pantalla (prueba especial `aud4_movil_partido`). La fila ya mide eso.
	var cab_col := p._ultima_caja_columna.get_child(0) as HBoxContainer
	cab_col.add_child(b_plantel)
	cab_col.move_child(b_plantel, cab_col.get_child_count() - 2)
	p._guia.nodos["plantel"] = b_plantel
	var caja_reg := p._bloque(der, "LO QUE VA PASANDO", 1.0)
	p._registro = RichTextLabel.new()
	p._registro.bbcode_enabled = true
	p._registro.scroll_following = true
	p._registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p._registro.add_theme_font_size_override("normal_font_size", 12)
	caja_reg.add_child(p._registro)

	DisenoVertical.apilar(columnas, [720.0, 560.0, 380.0])   ## (vertical) de pie, las tres columnas van una debajo de otra
	## EL PANEL LATERAL (mapa de metas 23): a la izquierda y por encima del menú
	## central; el contenido se corre lo que mide el riel para no quedar tapado.
	raiz.offset_left = 18.0 + MenuLateral.reserva().x
	raiz.offset_bottom = -14.0 - MenuLateral.reserva().y
	p._menu_lateral = MenuLateral.crear(p)
	p.add_child(p._menu_lateral)
	p._guia.nodos["partido"] = p._menu_lateral.boton_de("partido")
	p._guia.nodos["dinero"] = p._menu_lateral.boton_de("dinero")
	p._guia.nodos["guardar"] = p._menu_lateral.boton_de("ajustes")
	p._estilos.montar_reloj()
