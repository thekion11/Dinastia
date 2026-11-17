class_name EscaparateInicio
extends RefCounted
## EL MENÚ CENTRAL COMO ESCAPARATE (17-11-2026, orden del dueño vía «Auditoría de sesiones»; referencia: la Liga Master del PES 2020, `referencias_del_dueño`). Reforma la PRESENTACIÓN sin
## quitar funciones: una pantalla completa (`EscaparatePantalla`) con la barra del club pegada arriba (`EscaparateBarra`), en «Avanzar en el tiempo» tres tarjetas con IMAGEN (el DT, la
## noticia con escena, la tabla de 10 filas) y abajo la fila de partidos y los seguidores (`EscaparateTarjetas`, `EscaparatePartidos`), y el pie (`EscaparatePie`). Todo se reparte el
## alto de la pantalla: nada se corta ni se desliza. Sigue usando `TableroInicio.tarjeta` (foco de mando, campanas de avisos). Solo en pantalla de PC: en el teléfono (de pie o tumbado)
## queda el mosaico de siempre. Apagar `activo` lo devuelve todo.

static var activo := true
static var _enganchado := false

static func usa() -> bool:
	return activo and not DisenoVertical.activo() and not EscalaMovil.es_tactil()

## `TableroInicio.pintar` en el escaparate: repinta la pantalla y la muestra si el Inicio es la pestaña a la vista.
static func pintar(p: Principal, c: Club, liga: Liga, dias: int) -> void:
	EscaparatePantalla.de(p).repintar(p, c, liga, dias)
	if not _enganchado and p._pestanas != null:
		_enganchado = true
		p._pestanas.tab_changed.connect(func(_i: int) -> void: sincronizar(p))
	sincronizar(p)

## La capa del escaparate solo se ve en el Inicio (el menú de siempre se esconde entonces; en las demás pestañas, al revés). El riel de iconos también.
static func sincronizar(p: Principal) -> void:
	var pant: Variant = (p.get_meta("escaparate") if p.has_meta("escaparate") else null)
	if not is_instance_valid(pant) or p._pestanas == null:
		return
	var en_inicio := p._pestanas.get_tab_title(p._pestanas.current_tab) == "Inicio" and usa()
	(pant as Control).visible = en_inicio
	(pant as Control).offset_left = 0.0 if MenuLateral.abajo() else MenuLateral.ANCHO_RIEL   ## (17-11) la barra lateral SIEMPRE visible: el escaparate le deja su sitio
	var raiz: Node = p._despacho.get_parent() if p._despacho != null else null
	if raiz is Control:
		(raiz as Control).visible = not en_inicio
	var pc := EscaparateBarra.pc_de(p)
	if pc != null:
		pc.boton_flotante_visible(not en_inicio)   ## en el Inicio, «Levantarse del PC» está en el pie
	if p._menu_lateral != null:
		p._menu_lateral.esconder_riel(false)   ## la tira de iconos se ve también en el Inicio (idéntica a la de antes)
	for po in p.find_children("*", "PanelObjetivos", true, false):   ## su chapa plegada pasa al pie mientras se ve el escaparate
		(po as Control).visible = not (en_inicio and bool(po.get("_plegado")))

## La pestaña «Avanzar en el tiempo»: arriba DT, noticia y tabla; abajo los partidos y los seguidores. Las dos filas se REPARTEN el alto que hay (1,5 a 1).
static func avanzar(p: Principal, cuerpo: VBoxContainer, c: Club, liga: Liga, acento: Color) -> void:
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", TableroInicio.SEP)
	arriba.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arriba.size_flags_stretch_ratio = 1.5
	arriba.custom_minimum_size.y = 150
	cuerpo.add_child(arriba)
	for par: Array in [[EscaparateTarjetas.dt(p, c, acento), 1.0], [EscaparateTarjetas.noticia(p, c, liga, acento), 1.7], [EscaparateTarjetas.tabla(p, c, liga, acento), 1.15]]:
		var t: Control = par[0]
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.size_flags_stretch_ratio = float(par[1])
		arriba.add_child(t)
	var abajo := HBoxContainer.new()
	abajo.add_theme_constant_override("separation", TableroInicio.SEP)
	abajo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	abajo.size_flags_stretch_ratio = 1.0
	abajo.custom_minimum_size.y = 130
	cuerpo.add_child(abajo)
	for par: Array in [[EscaparatePartidos.proximos(p, c, liga, acento), 3.6], [EscaparatePartidos.hinchada(p, c, acento), 1.15], [EscaparateTarjetas.despacho(p, c, acento), 0.85]]:
		var t: Control = par[0]
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.size_flags_stretch_ratio = float(par[1])
		abajo.add_child(t)
	cuerpo.add_child(_franja(p, c))

## (17-11) La franja de abajo del Inicio, con los accesorios que vuelven: los ACCESOS RÁPIDOS que se marcan en Ajustes (uno por favorito) y la FORMA (últimos 5 partidos). Una sola fila baja, para que las tarjetas conserven el alto.
static func _ficha(valor: String, rotulo: String, col := Color.WHITE) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -3)
	var n := EstiloAvanzar.etiqueta(valor, 20, col, true)
	n.clip_text = true
	v.add_child(n)
	var r := EstiloAvanzar.etiqueta(rotulo.to_upper(), 11, Color(1, 1, 1, 0.65))
	r.clip_text = true
	v.add_child(r)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v

static func _franja(p: Principal, c: Club) -> Control:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 22)
	f.custom_minimum_size.y = 36
	var relleno := Control.new()
	relleno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_child(relleno)
	var accesos: Array = p._favoritos if not p._favoritos.is_empty() else ["Mi plantel", "Táctica", "Partido", "Calendario"]   ## sin favoritos marcados en Ajustes, los cuatro más usados
	for tab: String in accesos:
		var b := Button.new()
		b.text = "⭐ " + Idiomas.t(tab)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_size_override("font_size", Tema.letra(13))
		b.pressed.connect(func() -> void: p._ir_a_pestana(tab))
		f.add_child(b)
	return f
