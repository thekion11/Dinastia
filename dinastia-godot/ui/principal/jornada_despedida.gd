class_name JornadaDespedida
extends RefCounted
## LA INTERFAZ DEL PARTIDO DE DESPEDIDA (9-11): al pulsar «Temporada siguiente», con la liga terminada, se ofrece el partido de gala contra las Leyendas
## (los que se retiran esta temporada): JUGARLO en directo, SIMULARLO o dejarlo. La lógica (quién se retira, taquilla, ánimo, restaurar a tus jugadores) está
## en `PartidoDespedida`. Sin pantalla (banco) no se ofrece. Después el cierre de temporada sigue como siempre y respeta quién se retira.

## Pregunta (jugar / simular / no) y, según se elija, lo juega. Termina cuando el partido (o la decisión) ha terminado.
static func ofrecer(pr: Principal) -> void:
	if DisplayServer.get_name() == "headless" or pr.mundo == null or pr.mundo.mi_club() == null:
		return
	if pr.mundo.prensa != null and pr.mundo.prensa.despedida_anio == pr.mundo.anio:
		return   ## ya se jugó esta temporada (p. ej. se guardó y se cargó antes del cierre)
	var leyendas := PartidoDespedida.preparar(pr.mundo)
	if leyendas == null:
		PartidoDespedida.limpiar(pr.mundo)   ## sin once con portero: no hay partido y el cierre sortea los retiros como siempre
		return
	var op := await _preguntar(pr, leyendas)
	if op == "no":
		return   ## los retiros ya decididos se respetan igual: solo falta el partido
	var mio := pr.mundo.mi_club()
	var foto := PartidoDespedida.foto(mio)
	var p := Partido.new(mio, leyendas)
	p.fijar_clima(Clima.del_partido(mio.pais, pr.mundo.semana, pr.mundo.anio, mio.id + leyendas.id))
	if op == "simular":
		p.simular()
	else:
		await _jugar_en_directo(pr, p)
	var res := PartidoDespedida.cerrar(pr.mundo, p, leyendas, foto)
	if DisplayServer.get_name() != "headless":
		var cer := CeremoniaDespedida.mostrar(pr, res["homenajeados"], leyendas)
		await cer.terminado
	Aviso.mostrar(pr, "vida", "🎖️", Idiomas.t("Partido de despedida"),
		"%s %d-%d · %s %d" % [Idiomas.t("Resultado:"), int(res["gf"]), int(res["gc"]), Idiomas.t("taquilla"), int(res["ingreso"])])

## El modo de mirar un partido de liga elegido en Ajustes ("completo" por defecto = con el estadio en 3D).
static func modo_elegido() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return "completo"
	return String(cfg.get_value(Principal.SECCION_SIMULACION, "liga", "completo"))

static func _jugar_en_directo(pr: Principal, p: Partido) -> void:
	var vivo := PartidoVivo.new()
	var modo := modo_elegido()   ## como un partido de liga: el modo de mirar que tengas puesto (vivo en texto, destacados o 3D)
	vivo.con_3d = modo != "vivo"
	vivo.destacados = modo == "destacados"
	vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pr.add_child(vivo)
	vivo.datos_pantalla = pr._datos_pantalla_estadio(p.local, "liga")
	pr._fundido_entrada()
	var perfil := pr.mundo.perfil_estadio_de(p.local).duplicate()
	vivo.abrir(p, pr.mundo.mi_club(), pr.mundo.vestuario, false, pr.mundo.roles, pr._velocidad_partido, perfil,
		Comercial.color_balon(pr.mundo.comercial.balon, pr.mundo.mi_club()))
	await vivo.cerrado
	vivo.queue_free()

class Eleccion extends CanvasLayer:
	signal elegido(op: String)

static func _preguntar(pr: Principal, leyendas: Club) -> String:
	var capa := Eleccion.new()
	capa.layer = 58
	pr.add_child(capa)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.7)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tema.PANEL
	sb.border_color = Tema.ORO
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	centro.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size = Vector2(420, 0)
	panel.add_child(col)
	var t := Label.new()
	t.text = "🎖️ " + Idiomas.t("Partido de despedida")
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Tema.ORO)
	col.add_child(t)
	var d := Label.new()
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.text = "%s %d %s" % [Idiomas.t("Tu equipo se enfrenta a las Leyendas: los"), leyendas.plantilla.size(),
		Idiomas.t("mejores jugadores que se retiran esta temporada. Es un partido de gala: no cuenta para la liga y no deja lesiones.")]
	col.add_child(d)
	for par: Array in [["jugar", "▶ " + Idiomas.t("Jugarlo")], ["simular", "⏭ " + Idiomas.t("Simularlo")], ["no", Idiomas.t("Ahora no")]]:
		var b := Button.new()
		b.text = String(par[1])
		var op := String(par[0])
		b.pressed.connect(func() -> void: capa.elegido.emit(op))
		col.add_child(b)
	var elegida: String = await capa.elegido
	capa.queue_free()
	return elegida
