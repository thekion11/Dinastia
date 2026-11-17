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
	var pant: Variant = p.get_meta("escaparate", null)
	if not is_instance_valid(pant) or p._pestanas == null:
		return
	var en_inicio := p._pestanas.get_tab_title(p._pestanas.current_tab) == "Inicio" and usa()
	(pant as Control).visible = en_inicio
	var raiz: Node = p._despacho.get_parent() if p._despacho != null else null
	if raiz is Control:
		(raiz as Control).visible = not en_inicio
	if p._menu_lateral != null:
		p._menu_lateral.esconder_riel(en_inicio)
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
	for par: Array in [[EscaparatePartidos.proximos(p, c, liga, acento), 2.7], [EscaparatePartidos.hinchada(p, c, acento), 1.35], [EscaparateTarjetas.despacho(p, c, acento), 1.0]]:
		var t: Control = par[0]
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.size_flags_stretch_ratio = float(par[1])
		abajo.add_child(t)
