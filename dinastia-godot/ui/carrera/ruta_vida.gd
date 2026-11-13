class_name RutaVida
extends RefCounted
## «TU VIDA», en pantalla (dentro de «Yo»): tus ahorros y en qué gastarlos.

const E := preload("res://ui/carrera/ruta_estilo.gd")

static func pintar(ui: Variant) -> Control:
	var c: CarreraJugador = ui.carrera
	var m: Mundo = ui.mundo
	var j := c.jugador(m)
	var p := E.tarjeta()
	var v := E.columna(8)
	p.add_child(v)
	var cab := E.fila(8)
	v.add_child(cab)
	var rot := E.rotulo("TU VIDA", E.MENTA)
	rot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(rot)
	cab.add_child(E.chip(Idiomas.t("ahorros: %s") % Eco.dinero(CarreraVida.ahorros(c)), E.MENTA))
	v.add_child(E.lbl(12, E.SUAVE, Idiomas.t("Cobras %s cada semana. Lo que compres es para siempre.") % Eco.dinero(j.sueldo if j != null else 0), true))
	var g := GridContainer.new()
	g.columns = 1 if E.estrecho(ui) else 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	for id: String in CarreraVida.COSAS:
		g.add_child(_cosa(ui, id))
	return p

static func _cosa(ui: Variant, id: String) -> Control:
	var c: CarreraJugador = ui.carrera
	var m: Mundo = ui.mundo
	var def: Array = CarreraVida.COSAS[id]
	var la_tiene := CarreraVida.tiene(c, id)
	var puede := CarreraVida.puede_comprar(c, m, id)
	var caja := PanelContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_stylebox_override("panel", E.caja(Color(E.MENTA, 0.14) if la_tiene else E.TINTA2, 12, Color(E.MENTA, 0.7 if la_tiene or puede else 0.12), 10))
	var h := E.fila(10)
	caja.add_child(h)
	h.add_child(E.titulo(28, E.TEXTO, String(def[0])))
	var t := E.columna(1)
	h.add_child(t)
	t.add_child(E.lbl(15, E.MENTA if la_tiene else E.TEXTO, ("✔ " if la_tiene else "") + Idiomas.t(String(def[1])), true))
	var d := E.lbl(12, E.SUAVE, String(def[2]))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_child(d)
	if la_tiene:
		return caja
	var precio := Eco.dinero(CarreraVida.precio(c, m, id))
	var b := E.boton(precio, E.MENTA, func() -> void:
		if CarreraVida.comprar(c, m, id):
			E.son("dinero_sale")
			ui._msg = Idiomas.t("Comprado: %s.") % Idiomas.t(String(def[1])).to_lower()
		ui._pintar_semana(), 36, puede)
	b.disabled = not puede
	b.set_meta("principal", null)
	b.remove_meta("principal")
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.tooltip_text = Idiomas.t("%d semanas de tu sueldo") % int(def[3])
	h.add_child(b)
	return caja
