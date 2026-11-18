class_name EscaparatePantalla
extends Control
## LA PANTALLA ENTERA DEL ESCAPARATE (17-11-2026, segunda ronda de Auditoría): el menú central del Inicio ya no va dentro del marco con esquinas y la barra de desplazamiento de
## siempre: es una capa a PANTALLA COMPLETA (encima del menú de siempre, que se esconde mientras está) con la barra del club pegada ARRIBA, el cuerpo que ocupa todo el alto
## (las tarjetas se reparten el espacio: nada se corta ni se desplaza) y el pie con las ayudas del aparato activo, los botones de Avanzar / Jugar / Saltar / Partido jugado,
## Mensajes y Ayuda. Las pestañas «Dirección del equipo» e «Información del club» siguen con sus tarjetas de siempre (con el informe de la semana debajo, deslizable).
## `TableroInicio.pintar` la repinta; `EscaparateInicio.sincronizar` la muestra solo en la pestaña Inicio.

var _cuerpo: VBoxContainer
var _busqueda: PopupPanel

## La pantalla de esta partida (se crea la primera vez, justo encima del menú de siempre y debajo de los menús laterales y de todo lo que se abre después).
static func de(p: Principal) -> EscaparatePantalla:
	var e: Variant = (p.get_meta("escaparate") if p.has_meta("escaparate") else null)
	if is_instance_valid(e):
		return e as EscaparatePantalla
	var n := EscaparatePantalla.new()
	n.name = "Escaparate"
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(n)
	var raiz: Node = p._despacho.get_parent() if p._despacho != null else null
	if raiz != null:
		p.move_child(n, raiz.get_index() + 1)
	p.set_meta("escaparate", n)
	return n

## Lo que no se puede liberar con la capa (los botones de Avanzar y el buscador viven en el menú de siempre): se sacan antes de vaciarla.
func _soltar(p: Principal) -> void:
	for n: Control in [p._botones, p._buscador]:
		if n != null and is_instance_valid(n) and n.get_parent() != null and is_ancestor_of(n):
			n.get_parent().remove_child(n)

func repintar(p: Principal, c: Club, liga: Liga, dias: int) -> void:
	_soltar(p)
	for h in get_children():
		if h != _busqueda:
			remove_child(h)
			h.queue_free()
	var fondo := ColorRect.new()
	fondo.color = Color(0.035, 0.05, 0.085, 0.97)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var vb := VBoxContainer.new()
	vb.name = "Mosaico"
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 0)
	add_child(vb)
	var acento := p._con_contraste(p._acento_de(c))
	ColorMundo.aplicar(p.mundo)
	TableroInicio.color_mundo = ColorMundo.acento(p.mundo)
	TableroInicio.fondo_mundo = ColorMundo.fondo_tarjeta(p.mundo)
	var hb := EscaparateBarra.crear(vb, c)
	var margen := MarginContainer.new()
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for lado: String in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 14)
	margen.add_theme_constant_override("margin_top", 8)
	margen.add_theme_constant_override("margin_bottom", 6)
	vb.add_child(margen)
	_cuerpo = VBoxContainer.new()
	_cuerpo.add_theme_constant_override("separation", TableroInicio.SEP)
	margen.add_child(_cuerpo)
	var botones: Array[Button] = []
	for i in TableroInicio.PESTANAS.size():
		var b := EscaparateBarra.boton_pestana(Idiomas.t(String(TableroInicio.PESTANAS[i])), 1.35)
		hb.add_child(b)
		botones.append(b)
		CampanasMenu.marcar_pestana(b, i)
		b.pressed.connect(func() -> void:
			var ya := TableroInicio.pestana == i
			TableroInicio.pestana = i
			TableroInicio._marcar(botones)
			_pintar_cuerpo(p, c, liga, dias, acento)
			if i == 0 and ya:   ## «Avanzar en el tiempo» pulsada estando ya en ella: el desplegable de Avanzar 1 día / Siguiente
				var av: Variant = p._guia.nodos.get("b_avanzar")
				if is_instance_valid(av) and (av as Button).visible:
					BotonesAvance.desplegar(p))
	EscaparateBarra.completar(p, hb, botones, c)
	TableroInicio._marcar(botones)
	_pintar_cuerpo(p, c, liga, dias, acento)
	vb.add_child(EscaparatePie.crear(p))

func _pintar_cuerpo(p: Principal, c: Club, liga: Liga, dias: int, acento: Color) -> void:
	for h in _cuerpo.get_children():
		_cuerpo.remove_child(h)
		h.queue_free()
	if TableroInicio.pestana == 0:
		EscaparateInicio.avanzar(p, _cuerpo, c, liga, acento)
		return
	EscaparateSubs.pintar(p, _cuerpo, c, TableroInicio.EQUIPO if TableroInicio.pestana == 1 else TableroInicio.CLUB, acento)   ## sin desplazamiento y sin el informe de la semana

## «Base de datos»: un cuadro con el buscador global (jugadores y clubes) y la puerta a «Ligas y clubes».
func abrir_busqueda(ancla: Control) -> void:
	var p := get_parent() as Principal
	if _busqueda == null or not is_instance_valid(_busqueda):
		_busqueda = PopupPanel.new()
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		_busqueda.add_child(v)
		add_child(_busqueda)
		var puerta := Button.new()
		puerta.text = Idiomas.t("Abrir Ligas y clubes")
		puerta.pressed.connect(func() -> void:
			_busqueda.hide()
			TableroInicio.abrir(p, "Ligas y clubes"))
		v.add_child(puerta)
	var v2 := _busqueda.get_child(0)
	if p._buscador != null and p._buscador.get_parent() != v2:
		if p._buscador.get_parent() != null:
			p._buscador.get_parent().remove_child(p._buscador)
		v2.add_child(p._buscador)
		v2.move_child(p._buscador, 0)
	p._buscador.custom_minimum_size = Vector2(260, 34)
	var r := ancla.get_global_rect()
	_busqueda.popup(Rect2i(Vector2i(int(r.position.x), int(r.position.y + r.size.y)), Vector2i(280, 0)))
	p._buscador.grab_focus.call_deferred()
