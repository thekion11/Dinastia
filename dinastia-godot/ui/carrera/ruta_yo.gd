class_name RutaYo
extends RefCounted
## «YO»: tu cromo (media, cara, atributos) y el árbol de talentos.

const E := preload("res://ui/carrera/ruta_estilo.gd")
const NOMBRES := {"rit": "Velocidad", "tir": "Tiro", "pas": "Pase", "reg": "Regate", "def": "Defensa", "fis": "Físico"}

static func pintar(ui: Variant, j: Jugador, club: Club) -> Control:
	var cols := E.fila(14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(cromo(ui, j, club))
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(sc)
	var der := E.columna(12)
	sc.add_child(der)
	der.add_child(_atributos(ui, j))
	der.add_child(_talentos(ui))
	return cols

## El cromo: tu media en grande sobre el color del club.
static func cromo(ui: Variant, j: Jugador, club: Club) -> Control:
	var c: CarreraJugador = ui.carrera
	var tono := E.de_club(club)
	var p := E.tarjeta(tono, E.TINTA.lerp(tono, 0.16))
	p.custom_minimum_size = Vector2(300, 0)
	var v := E.columna(4)
	p.add_child(v)
	var arriba := E.fila(6)
	v.add_child(arriba)
	var med := E.columna(-8)
	med.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	arriba.add_child(med)
	med.add_child(E.titulo(84, E.ORO, str(j.ovr)))
	med.add_child(E.titulo(28, E.TEXTO, j.pos_e))
	var cara := E.imagen(Cara.textura(j, club.color1, club.color2, 170), 170)
	cara.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(cara)
	var nombre := E.titulo(32, E.TEXTO, j.nombre.to_upper())
	nombre.clip_text = true
	v.add_child(nombre)
	var f := E.fila(6)
	v.add_child(f)
	f.add_child(E.escudo(club, 26))
	f.add_child(E.lbl(13, E.SUAVE, "%s · #%d" % [Nombres.visible(club.nombre), j.dorsal], true))
	var sube := CarreraAgenda.progreso(c, j)
	var chips := E.flujo()
	v.add_child(chips)
	chips.add_child(E.chip(Idiomas.t("%+d esta temporada") % sube, E.MENTA if sube > 0 else E.SUAVE))
	chips.add_child(E.chip(Idiomas.t("techo %d") % j.pot, E.ORO))
	chips.add_child(E.chip(Idiomas.t("zurdo") if String(j.look.get("pie", "")) == "zurdo" else Idiomas.t("diestro"), E.CIELO))
	if c.capitan:
		chips.add_child(E.chip(Idiomas.t("capitán"), E.CORAL))
	v.add_child(E.lbl(12, E.SUAVE, Idiomas.t("Contrato: %d año(s) · %s/sem") % [j.anios_contrato, Eco.dinero(j.sueldo)], true))
	v.add_child(E.lbl(12, E.SUAVE, c.agente if c.agente != "" else "Sin agente", true))
	return p

static func _atributos(ui: Variant, j: Jugador) -> Control:
	var c: CarreraJugador = ui.carrera
	var p := E.tarjeta()
	var h := E.fila(18)
	p.add_child(h)
	var a := E.columna(5)
	h.add_child(a)
	a.add_child(E.rotulo("TU JUEGO", E.CIELO))
	var foco_attr := String((CarreraPortero.focos_para(j).get(c.foco, ["", ""]) as Array)[1])
	for k: String in j.atributos:
		var nombre := Idiomas.t(String(NOMBRES.get(k, k.capitalize())))
		a.add_child(E.medidor(("▸ " if k == foco_attr else "") + nombre, int(j.atributos[k]), 99, E.ORO if k == foco_attr else E.CIELO))
	var b := E.columna(5)
	h.add_child(b)
	b.add_child(E.rotulo("TU MOMENTO", E.CORAL))
	b.add_child(E.medidor("⚡ " + Idiomas.t("Energía"), c.energia, 100, E.MENTA, 140))
	b.add_child(E.medidor("🤝 " + Idiomas.t("Relación con el DT"), c.relacion_dt, 100, E.CORAL, 140))
	b.add_child(E.medidor("⭐ " + Idiomas.t("Fama"), c.fama, 100, E.ORO, 140))
	b.add_child(E.medidor("🙂 " + Idiomas.t("Ánimo"), j.moral, 100, E.CIELO, 140))
	var s: Dictionary = c.stats_temp
	var cif := E.fila(6)
	b.add_child(cif)
	cif.add_child(E.cifra(str(int(s["pj"])), "partidos", E.TEXTO, 28))
	cif.add_child(E.cifra(str(int(s["goles"])), "goles", E.ORO, 28))
	cif.add_child(E.cifra(str(int(s["asist"])), "asist.", E.TEXTO, 28))
	cif.add_child(E.cifra(("%.1f" % c.nota_media()) if c.nota_media() > 0.0 else "—", "nota", E.MENTA, 28))
	return p

## El árbol: tres ramas de tres talentos en cadena.
static func _talentos(ui: Variant) -> Control:
	var c: CarreraJugador = ui.carrera
	var r := CarreraRuta.asegurar(c)
	var p := E.tarjeta(E.ORO if int(r["puntos"]) > 0 else Color(0, 0, 0, 0))
	var v := E.columna(8)
	p.add_child(v)
	var cab := E.fila(8)
	v.add_child(cab)
	var rot := E.rotulo("TALENTOS", E.ORO)
	rot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(rot)
	cab.add_child(E.chip(Idiomas.t("%d punto(s) por gastar") % int(r["puntos"]), E.ORO if int(r["puntos"]) > 0 else E.SUAVE))
	var ramas := E.fila(10)
	v.add_child(ramas)
	for rama: String in CarreraRuta.RAMAS:
		var def: Array = CarreraRuta.RAMAS[rama]
		var col := Color(String(def[2]))
		var cv := E.columna(6)
		ramas.add_child(cv)
		cv.add_child(E.titulo(22, col, "%s %s" % [String(def[1]), Idiomas.t(String(def[0])).to_upper()]))
		var orden: Array = []
		for id: String in CarreraRuta.TALENTOS:
			if String(CarreraRuta.TALENTOS[id][0]) == rama:
				orden.append(id)
		orden.sort_custom(func(x: String, y: String) -> bool: return int(CarreraRuta.TALENTOS[x][1]) < int(CarreraRuta.TALENTOS[y][1]))
		for id2: String in orden:
			cv.add_child(_talento(ui, id2, col))
	v.add_child(E.lbl(12, E.SUAVE, "Cada nivel da un punto. Dentro de una rama se aprenden en orden."))
	return p

static func _talento(ui: Variant, id: String, col: Color) -> Control:
	var c: CarreraJugador = ui.carrera
	var def: Array = CarreraRuta.TALENTOS[id]
	var lo_tiene := CarreraRuta.tiene(c, id)
	var puede := CarreraRuta.puede_aprender(c, id)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", E.caja(Color(col, 0.20) if lo_tiene else E.TINTA2, 12, Color(col, 0.8 if lo_tiene or puede else 0.15), 10))
	var v := E.columna(2)
	caja.add_child(v)
	v.add_child(E.lbl(15, col if lo_tiene or puede else E.SUAVE, ("✔ " if lo_tiene else "") + Idiomas.t(String(def[2])), true))
	var d := E.lbl(12, E.TEXTO if lo_tiene else E.SUAVE, String(def[3]))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	if puede:
		v.add_child(E.boton("Aprender", col, func() -> void:
			CarreraRuta.aprender(c, ui.mundo, id)
			ui._msg = Idiomas.t("Talento nuevo: %s.") % Idiomas.t(String(def[2]))
			ui._pintar_semana(), 34, true))
	return caja
