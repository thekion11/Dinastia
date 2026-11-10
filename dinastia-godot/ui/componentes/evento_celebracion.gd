class_name EventoCelebracion
extends EventoPantallaCompleta
## EL FESTEJO DE UN TÍTULO A PANTALLA COMPLETA (10-11): sale al ganarlo (su fecha es la del título; nunca al abrir un menú). Arriba la
## competición y el año, el escudo y el rótulo según el tipo (`TipoTitulo`); en medio la escena 2D del festejo (`EscenaFestejo`) y debajo
## un botón por festejo (el principal y los extras: foto, manteo, champán, desfile, pasillo del rival). En la liga, además, «Ver la vuelta
## olímpica» (la 3D de siempre). Emite `elegido("vuelta")` o `elegido("seguir")`.
var tipo := "copa"
var escena: EscenaFestejo
var _botones: HBoxContainer
var vista3d: Control = null   ## (10-11) el festejo con modelos reales (`FestejoCampo3D`), si la escena lo tiene y la calidad lo permite
var _marco: PanelContainer
var _club: Club
var _titulo := ""

static func mostrar(pr: Principal, titulo: String, tipo_titulo: String, rival: Club = null) -> EventoCelebracion:
	var e := EventoCelebracion.new()
	e.tipo = tipo_titulo
	e.paleta_noche = true
	e.acento = SelectorDireccional.acento_legible(pr.COL_ACENTO)
	e._montar_base(pr)
	e._rellenar(pr, titulo, rival)
	return e

## Todas las escenas que se pueden ver: la principal y los extras.
func escenas() -> Array[String]:
	var r: Array[String] = [String(TipoTitulo.ESCENA.get(tipo, "palco"))]
	r.append_array(TipoTitulo.extras(tipo))
	return r

func _rellenar(pr: Principal, titulo: String, rival: Club) -> void:
	var club := pr.mundo.mi_club()
	_club = club
	_titulo = titulo
	_centro.custom_minimum_size = Vector2(800, 0)
	var cab := HBoxContainer.new()
	cab.alignment = BoxContainer.ALIGNMENT_CENTER
	cab.add_theme_constant_override("separation", 18)
	_centro.add_child(cab)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(club, 72)
	esc.custom_minimum_size = Vector2(72, 72)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab.add_child(esc)
	var tx := VBoxContainer.new()
	tx.add_theme_constant_override("separation", 0)
	cab.add_child(tx)
	tx.add_child(etiqueta("%s · %d" % [titulo.to_upper(), pr.mundo.anio], 14, Color(SelectorDireccional.BLANCO, 0.7), false))
	tx.add_child(etiqueta(Idiomas.t(TipoTitulo.rotulo(tipo)), 40, Tema.ORO if tipo not in ["ascenso", "salvacion"] else acento.lightened(0.3), false, false))
	tx.add_child(etiqueta(club.nombre, 18, SelectorDireccional.BLANCO, false, false))
	var marco := PanelContainer.new()
	var sb := Tema.caja(SelectorDireccional.NOCHE, Tema.RADIO_GRANDE, Color(acento, 0.8))
	sb.set_border_width_all(2)
	sb.set_content_margin_all(0)
	marco.add_theme_stylebox_override("panel", sb)
	marco.clip_contents = true
	_centro.add_child(marco)
	escena = EscenaFestejo.new()
	escena.colores(club, rival)
	marco.add_child(escena)
	_marco = marco
	ver.call_deferred(escenas()[0])
	_botones = HBoxContainer.new()
	_botones.alignment = BoxContainer.ALIGNMENT_CENTER
	_botones.add_theme_constant_override("separation", 8)
	_centro.add_child(_botones)
	for e: String in escenas():
		var b := boton(Idiomas.t(TipoTitulo.nombre_escena(e)))
		b.add_theme_font_size_override("font_size", Tema.letra(13))
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(ver.bind(e))
		_botones.add_child(b)
	var fin := HBoxContainer.new()
	fin.alignment = BoxContainer.ALIGNMENT_CENTER
	fin.add_theme_constant_override("separation", 14)
	_centro.add_child(fin)
	if tipo == "liga":
		var v := boton("🏟️ " + Idiomas.t("Ver la vuelta olímpica"))
		v.pressed.connect(func() -> void: elegido.emit("vuelta"))
		fin.add_child(v)
	var seguir := boton(Idiomas.t("Continuar"), true)
	seguir.pressed.connect(func() -> void: elegido.emit("seguir"))
	fin.add_child(seguir)

## Cambia la escena (un botón por festejo) con un fundido corto.
## (10-11) Si la escena tiene versión 3D y la calidad lo permite, se monta con los modelos reales (`FestejoCampo3D`); si no, la 2D.
func ver(e: String) -> void:
	if escena == null:
		return
	if vista3d != null:
		vista3d.queue_free()
		vista3d = null
	var visible_ahora: Control = escena
	if e in FestejoCampo3D.MODOS and FestejoCampo3D.con_3d():
		vista3d = FestejoCampo3D.crear(e, _club, _titulo, tipo in ["ascenso", "salvacion"])
	if vista3d != null:
		escena.visible = false
		escena.set_process(false)
		_marco.add_child(vista3d)
		visible_ahora = vista3d
	else:
		escena.visible = true
		escena.set_process(true)
		escena.poner(e)
	if not Animar.reducidas():
		visible_ahora.modulate.a = 0.0
		create_tween().tween_property(visible_ahora, "modulate:a", 1.0, 0.25)
