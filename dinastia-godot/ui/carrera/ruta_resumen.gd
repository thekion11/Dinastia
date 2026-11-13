class_name RutaResumen
extends RefCounted
## EL RESUMEN TRAS EL PARTIDO: tu nota en grande, la experiencia que dejó, los
## retos cumplidos y si subiste de nivel. Se muestra una vez, encima de «Hoy».

const E := preload("res://ui/carrera/ruta_estilo.gd")

## ¿Hay un partido de esta semana (o de la que acaba de cerrar) sin enseñar?
static func pendiente(ui: Variant) -> bool:
	var u: Dictionary = CarreraRuta.asegurar(ui.carrera)["ultimo"]
	return not u.is_empty() and not bool(u.get("visto", false))

static func pintar(ui: Variant, texto_semana: String) -> Control:
	var c: CarreraJugador = ui.carrera
	var r := CarreraRuta.asegurar(c)
	var u: Dictionary = r["ultimo"]
	u["visto"] = true
	var velo := ColorRect.new()
	velo.color = Color(0.01, 0.02, 0.06, 0.88)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	## Con desplazamiento: en un teléfono tumbado no cabe entero.
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	velo.add_child(sc)
	var centro := CenterContainer.new()
	centro.custom_minimum_size = ui.get_viewport_rect().size
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(centro)
	var nota := float(u.get("nota", 6.0))
	var tono := E.MENTA if nota >= 7.0 else (E.ORO if nota >= 6.0 else E.CORAL)
	var p := E.tarjeta(tono)
	p.custom_minimum_size = Vector2(minf(720.0, ui.get_viewport_rect().size.x - 32.0), 0)
	centro.add_child(p)
	var v := E.columna(10)
	p.add_child(v)
	v.add_child(E.rotulo("FINAL DEL PARTIDO", tono))
	var arriba := E.fila(18)
	v.add_child(arriba)
	var n := E.columna(-10)
	n.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	arriba.add_child(n)
	var grande := E.titulo(60 if E.bajo(ui) else 96, tono, "%.1f" % nota)
	E.contar(grande, nota, "%.1f")
	n.add_child(grande)
	n.add_child(E.lbl(13, E.SUAVE, "tu nota", true))
	var d := E.columna(8)
	arriba.add_child(d)
	var frase := "Partidazo." if nota >= 8.0 else ("Buen partido." if nota >= 7.0 else ("Cumpliste." if nota >= 6.0 else "Un día para olvidar."))
	d.add_child(E.titulo(34, E.TEXTO, Idiomas.t(frase).to_upper()))
	var cif := E.fila(6)
	d.add_child(cif)
	cif.add_child(E.cifra(str(int(u.get("goles", 0))), "goles", E.ORO))
	cif.add_child(E.cifra(str(int(u.get("asist", 0))), "asist."))
	cif.add_child(E.cifra("%d'" % int(u.get("minutos", 0)), "minutos"))
	if int(u.get("racha", 0)) >= 2:
		cif.add_child(E.cifra("🔥 %d" % int(u["racha"]), "racha", E.CORAL))
	## Los retos.
	for reto: Dictionary in u.get("retos", []):
		var def: Array = CarreraRuta.RETOS.get(String(reto.get("id", "")), ["", 0, []])
		var hecho := bool(reto.get("hecho", false))
		var f := E.fila(8)
		v.add_child(f)
		f.add_child(E.lbl(16, E.MENTA if hecho else E.SUAVE, "✔" if hecho else "✖", true))
		var l := E.lbl(15, E.TEXTO if hecho else E.SUAVE, String(def[0]), true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f.add_child(l)
		f.add_child(E.titulo(20, E.ORO if hecho else E.SUAVE, ("+%d XP" % int(reto.get("xp", 0))) if hecho else "—"))
	## La experiencia y el nivel.
	var xp := E.fila(12)
	v.add_child(xp)
	xp.add_child(RutaAnillo.crear(float(r["xp"]) / float(CarreraRuta.xp_para(int(r["nivel"]))), str(int(r["nivel"])), E.ORO, 60))
	var xv := E.columna(2)
	xp.add_child(xv)
	var subio := int(u.get("niveles", 0))
	xv.add_child(E.titulo(26, E.ORO, Idiomas.t("+%d de experiencia") % int(u.get("xp", 0)) + ("   ·   " + Idiomas.t("¡NIVEL %d!") % int(r["nivel"]) if subio > 0 else "")))
	var bx := E.barra(float(r["xp"]), float(CarreraRuta.xp_para(int(r["nivel"]))), E.ORO, 10)
	E.llenar(bx, 0.5)
	xv.add_child(bx)
	if subio > 0:
		Sonido.toca("menu_seccion", Sonido.Bus.INTERFAZ, 3.0)
		xv.add_child(E.lbl(13, E.MENTA, Idiomas.t("Tienes %d punto(s) de talento por gastar en «Yo».") % int(r["puntos"]), true))
	if texto_semana != "":
		var t := E.lbl(13, E.SUAVE, texto_semana)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t)
	E.entrada(velo)
	var b := E.boton("SEGUIR  ▸", tono, func() -> void: ui._pintar_semana(), 52, true)
	v.add_child(b)
	return velo
