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
	var m := PantallaEvento.montar(capa, "🎖️", Idiomas.t("Partido de despedida"),
		"%s %d %s" % [Idiomas.t("Tu equipo se enfrenta a las Leyendas: los"), leyendas.plantilla.size(),
		Idiomas.t("mejores jugadores que se retiran esta temporada. Es un partido de gala: no cuenta para la liga y no deja lesiones.")])
	## Las Leyendas, a la vista: sus cinco mejores con retrato (caras ficticias del juego).
	var top: Array = leyendas.plantilla.duplicate()
	top.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 22)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	m["cuerpo"].add_child(fila)
	for j: Jugador in top.slice(0, 5):
		var tarjeta := PanelContainer.new()
		var est := Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Color(Tema.oro(), 0.55))
		est.shadow_color = Color(0, 0, 0, 0.45)
		est.shadow_size = 10
		tarjeta.add_theme_stylebox_override("panel", est)
		fila.add_child(tarjeta)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		v.custom_minimum_size = Vector2(150, 0)
		tarjeta.add_child(v)
		var retrato := pr._retrato(j, 104)
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(retrato)
		var n := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, j.nombre)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(n)
		var d := Tema.etiqueta(Tema.TAM_ROTULO, Tema.oro(), "%s %d · %s" % [Idiomas.t("Nota"), j.ovr, Idiomas.t(String(j.pos_e))])
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(d)
	var primero := true
	for par: Array in [["jugar", "▶ " + Idiomas.t("Jugarlo")], ["simular", "⏭ " + Idiomas.t("Simularlo")], ["no", Idiomas.t("Ahora no")]]:
		var b := PantallaEvento.boton(String(par[1]), primero)
		var op := String(par[0])
		b.pressed.connect(func() -> void: capa.elegido.emit(op))
		m["pie"].add_child(b)
		if primero:
			b.call_deferred("grab_focus")
		primero = false
	var elegida: String = await capa.elegido
	capa.queue_free()
	return elegida
