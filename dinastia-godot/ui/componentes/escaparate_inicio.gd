class_name EscaparateInicio
extends RefCounted
## EL MENÚ CENTRAL COMO ESCAPARATE (17-11-2026, orden del dueño vía «Auditoría de sesiones»; referencia: la Liga Master del PES 2020, `referencias_del_dueño`). Reforma la PRESENTACIÓN
## sin quitar funciones: una sola barra arriba (`EscaparateBarra`); en «Avanzar en el tiempo», tres tarjetas con IMAGEN (el DT, la noticia con escena, la tabla de 10 filas) y abajo la fila
## de partidos y los seguidores (`EscaparateTarjetas`, `EscaparatePartidos`). Sigue usando `TableroInicio.tarjeta` (foco de mando, campanas de avisos). El botón Avanzar / Jugar / Saltar /
## Partido jugado (`BotonesAvance`) baja al pie, a la derecha. Solo en pantalla de PC: en el teléfono (de pie o tumbado) se queda el mosaico de siempre. Apagar `activo` lo devuelve todo.

static var activo := true
static var _enganchado := false

static func usa() -> bool:
	return activo and not DisenoVertical.activo() and not EscalaMovil.es_tactil()

## Lo que se esconde o se mueve en la vista del escaparate. Idempotente: se llama cada vez que se pinta.
static func preparar(p: Principal) -> void:
	if p._fila_dias != null:
		p._fila_dias.visible = false   ## la tira de días vive ahora en la pantalla «Avanzar»
	if p._escudo_cabecera != null and p._escudo_cabecera.get_parent() != null:
		(p._escudo_cabecera.get_parent() as Control).visible = false   ## escudo, club, caja y fecha: ahora van en la barra
	if p._sub != null:
		p._sub.visible = false
	var raiz: Node = p._despacho.get_parent() if p._despacho != null else null
	if raiz != null and p._botones != null and p._botones.get_parent() == raiz:
		var ayuda := raiz.get_node_or_null("BarraAyudas")
		raiz.move_child(p._botones, raiz.get_child_count() - 1)   ## Avanzar / Jugar / Saltar abajo a la derecha...
		if ayuda != null:
			raiz.move_child(ayuda, raiz.get_child_count() - 1)   ## ...justo encima de la barra de ayudas, que va la última
	_botones_grandes(p)
	p._botones.alignment = BoxContainer.ALIGNMENT_END   ## abajo a la derecha, como en la maqueta
	_riel(p)
	if not _enganchado and p._pestanas != null:
		_enganchado = true
		p._pestanas.tab_changed.connect(func(_i: int) -> void: _riel(p))

## El riel de iconos solo se oculta en el Inicio; en cualquier otra pestaña vuelve.
static func _riel(p: Principal) -> void:
	if p._menu_lateral == null or p._pestanas == null:
		return
	var en_inicio := p._pestanas.get_tab_title(p._pestanas.current_tab) == "Inicio"
	p._menu_lateral.esconder_riel(en_inicio and usa())

## Avanzar / Jugar / Saltar / Partido jugado como botones grandes de la maqueta (rojo el principal).
static func _botones_grandes(p: Principal) -> void:
	for clave: String in ["b_avanzar", "b_jugar", "b_saltar", "b_temporada", "b_jugado"]:
		var b: Variant = p._guia.nodos.get(clave)
		if not is_instance_valid(b):
			continue
		var bt := b as Button
		bt.custom_minimum_size = Vector2(220, 52)
		bt.size_flags_horizontal = Control.SIZE_SHRINK_END
		bt.add_theme_font_size_override("font_size", Tema.letra(22))
		var rojo := clave in ["b_avanzar", "b_jugar"]
		var n := StyleBoxFlat.new()
		n.bg_color = Color("c8102e") if rojo else Color("243656")
		n.content_margin_left = 22; n.content_margin_right = 22
		var h := n.duplicate() as StyleBoxFlat
		h.bg_color = n.bg_color.lightened(0.14)
		for estado: String in ["normal", "pressed"]:
			bt.add_theme_stylebox_override(estado, n)
		for estado: String in ["hover", "focus", "hover_pressed"]:
			bt.add_theme_stylebox_override(estado, h)

## La pestaña «Avanzar en el tiempo»: arriba DT, noticia y tabla; abajo los partidos y los seguidores. Las alturas siguen a la pantalla (sin recortes a 1080 ni a 720).
static func avanzar(p: Principal, cuerpo: VBoxContainer, c: Club, liga: Liga, acento: Color) -> void:
	var alto := p.get_viewport_rect().size.y
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", TableroInicio.SEP)
	arriba.custom_minimum_size.y = alto * 0.35
	cuerpo.add_child(arriba)
	var dt := EscaparateTarjetas.dt(p, c, acento)
	dt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dt.size_flags_stretch_ratio = 1.0
	arriba.add_child(dt)
	var noticia := EscaparateTarjetas.noticia(p, c, liga, acento)
	noticia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	noticia.size_flags_stretch_ratio = 1.7
	arriba.add_child(noticia)
	var tabla := EscaparateTarjetas.tabla(p, c, liga, acento)
	tabla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabla.size_flags_stretch_ratio = 1.15
	arriba.add_child(tabla)
	var abajo := HBoxContainer.new()
	abajo.add_theme_constant_override("separation", TableroInicio.SEP)
	abajo.custom_minimum_size.y = alto * 0.25
	cuerpo.add_child(abajo)
	var prox := EscaparatePartidos.proximos(p, c, liga, acento)
	prox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prox.size_flags_stretch_ratio = 3.2
	abajo.add_child(prox)
	var hin := EscaparatePartidos.hinchada(p, c, acento)
	hin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hin.size_flags_stretch_ratio = 1.4
	abajo.add_child(hin)
