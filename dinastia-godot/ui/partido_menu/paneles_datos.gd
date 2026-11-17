class_name PanelesDatos
extends RefCounted
## LA INFORMACIÓN DE LAS PESTAÑAS DEL MENÚ DEL PARTIDO (17-11-2026, Auditoría: «llena el aire con información útil, no con adorno»).
##   Uniforme → el fabricante y el patrocinador de la camiseta, y la ESPALDA con el dorsal y el apellido del jugador que sale grande.
##   Estadio  → la asistencia esperada (la fórmula de la taquilla, `Finanzas.asistencia`, por el efecto del clima) y los 3 últimos resultados en ese campo.
##   Cámara   → el ajuste fino de la cámara Pro con deslizadores: distancia, altura y ángulo de visión (los lee `VistaEstadio` al empezar).

## Fabricante (los ficticios de `DisenosKit.MARCA_FORMA`) y patrocinador del pecho (`SponsorKit`), y la espalda con el número.
static func uniforme(m: MenuPartido, v: Control) -> void:
	var kit: Dictionary = DisenosKit.kit_de_club(m.mio)
	var datos := GridContainer.new()
	datos.columns = 2
	datos.add_theme_constant_override("h_separation", 18)
	datos.add_theme_constant_override("v_separation", 6)
	var sp: Dictionary = kit.get("sp", {})
	var pecho := String((sp.get("pecho", {}) as Dictionary).get("marca", "")) if sp.get("pecho") is Dictionary else ""
	for par: Array in [["Fabricante", String(kit.get("marca", "propia")).capitalize() if String(kit.get("marca", "propia")) != "propia" else Idiomas.t("Marca propia del club")],
			["Patrocinador", pecho if pecho != "" else Idiomas.t("Sin patrocinador")]]:
		datos.add_child(EstiloAvanzar.etiqueta(Idiomas.t(String(par[0])).to_upper(), 14, PreviaMenuPartido.SUAVE))
		datos.add_child(EstiloAvanzar.etiqueta(String(par[1]), 20, Color.WHITE, true))
	v.add_child(datos)
	var j := m.estrella(m.mio)
	var espalda := TextureRect.new()
	espalda.texture = DisenosKit.textura_completa(kit, true, 120)
	espalda.custom_minimum_size = Vector2(Tema.letra(120), Tema.letra(200))
	espalda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	espalda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var apellido := EstiloAvanzar.etiqueta(Nombres.visible(j.nombre).split(" ")[-1].to_upper() if j != null else "", 14, Color.WHITE, true)
	apellido.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apellido.set_anchors_preset(Control.PRESET_TOP_WIDE)
	apellido.offset_top = Tema.letra(26)
	apellido.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	apellido.add_theme_constant_override("outline_size", 4)
	espalda.add_child(apellido)
	var caja := VBoxContainer.new()
	caja.add_child(EstiloAvanzar.etiqueta(Idiomas.t("La espalda").to_upper(), 14, PreviaMenuPartido.SUAVE))
	caja.add_child(espalda)
	v.add_child(caja)

## Cuánta gente se espera: la taquilla del club local por el efecto del clima (y del techo), sin pasar del aforo.
static func asistencia_esperada(m: MenuPartido, pf: Dictionary) -> int:
	var local := m.partido.local
	var base := Finanzas.new(local).asistencia()
	var techo = pf.get("techo", false)
	var con_techo: bool = (techo is bool and techo) or (techo is String and String(techo) not in ["", "no", "sin"])
	return mini(int(round(float(base) * Clima.factor_publico(m.clima, con_techo))), local.estadio_aforo)

## Los 3 últimos partidos del local EN CASA en esta liga (del historial de jornadas), el más reciente primero.
static func ultimos_en_casa(m: MenuPartido) -> Array:
	var r: Array = []
	if m.liga_rival == null:
		return r
	var local := m.partido.local
	for k in range(m.liga_rival.historial.size() - 1, -1, -1):
		for res: Dictionary in (m.liga_rival.historial[k] as Array):
			var l = res.get("local")
			if (l is Club and l == local) or (l is String and String(l) == local.id):
				r.append(res)
		if r.size() >= 3:
			break
	return r.slice(0, 3)

static func estadio(m: MenuPartido, izq: Control, pf: Dictionary) -> void:
	var asis := asistencia_esperada(m, pf)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Asistencia esperada").to_upper(), 15, PreviaMenuPartido.SUAVE))
	fila.add_child(EstiloAvanzar.etiqueta(Idiomas.t("%d espectadores") % asis, 22, PreviaMenuPartido.ORO, true))
	izq.add_child(fila)
	izq.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Últimos partidos en este campo").to_upper(), 15, PreviaMenuPartido.SUAVE))
	var ult := ultimos_en_casa(m)
	if ult.is_empty():
		izq.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Todavía no se ha jugado aquí esta temporada."), 17, Color(1, 1, 1, 0.7)))
	for res: Dictionary in ult:
		var vis = res.get("visita")
		var nom: String = (vis as Club).nombre if vis is Club else String(vis)
		var gl := int(res.get("gl", 0))
		var gv := int(res.get("gv", 0))
		var col := Color("7fd99a") if gl > gv else (Color("ff8a7a") if gl < gv else Color("e6e6e6"))
		izq.add_child(EstiloAvanzar.etiqueta("%d - %d   %s" % [gl, gv, Nombres.visible(nom)], 19, col, true))

## Distancia, altura y ángulo de la cámara Pro: tres deslizadores que guardan sus preferencias (con mando: la cruceta los mueve; táctil: se arrastran).
const AJUSTES := [["pro_dist", "Distancia (m)", 2.5, 8.0, 0.1], ["pro_altura", "Altura", 0.3, 0.8, 0.01], ["pro_fov", "Ángulo de visión (°)", 50.0, 85.0, 1.0]]
static func camara(v: Control) -> void:
	v.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Ajuste fino de la cámara Pro").to_upper(), 15, PreviaMenuPartido.SUAVE))
	var defecto := {"pro_dist": float(CameraRig.PRO_DISTANCIAS.get(String(OpcionesPartido.leer("pro_camara", "normal")), 4.2)), "pro_altura": 0.52, "pro_fov": 62.0}
	for a: Array in AJUSTES:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 14)
		var l := EstiloAvanzar.etiqueta(Idiomas.t(String(a[1])), 18, Color.WHITE)
		l.custom_minimum_size = Vector2(Tema.letra(230), 0)
		fila.add_child(l)
		var s := HSlider.new()
		s.min_value = float(a[2])
		s.max_value = float(a[3])
		s.step = float(a[4])
		var clave := String(a[0])
		var guardado := float(OpcionesPartido.leer(clave, 0.0))
		s.value = guardado if guardado > 0.0 else float(defecto[clave])
		s.custom_minimum_size = Vector2(Tema.letra(360), Tema.letra(28))
		s.focus_mode = Control.FOCUS_ALL
		var valor := EstiloAvanzar.etiqueta("%.2f" % s.value if float(a[4]) < 1.0 else "%d" % int(s.value), 18, PreviaMenuPartido.ORO, true)
		s.value_changed.connect(func(x: float) -> void:
			OpcionesPartido.guardar(clave, x)
			valor.text = "%.2f" % x if float(a[4]) < 1.0 else "%d" % int(x))
		fila.add_child(s)
		fila.add_child(valor)
		v.add_child(fila)
