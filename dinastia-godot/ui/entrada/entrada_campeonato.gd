class_name PantallaEntradaCampeonato
extends "res://ui/entrada/entrada_campeonato_p1.gd"
## [Capa 2/2 de `entrada_campeonato.gd`] ETAPA 5 DEL FLUJO: ENTRADA AL CAMPEONATO (MEGAPLAN, fase 1).
## Pantalla completa, obligatoria y con confirmación: explica las dos maneras de meter tu club recién
## creado en la liga -reemplazar un club existente o pagar a la confederación- con las consecuencias en
## CIFRAS REALES de tu país (las calcula `EntradaCampeonato.previsualizar`, la misma función que luego
## las aplica: lo que se enseña es exactamente lo que pasa).
##
## Contrato de etapa (igual para todas las del flujo nuevo):
##   configurar(estado) -> {"mundo": Mundo, "pais": "CHI" (o {pais}), "config": {nombre_club, color1,
##                          color2, estadio} (o "club": {nombre, …}), "entrada": la elegida antes (opcional),
##                          "aplicar": false}
##   terminado(datos)   -> {"entrada": {modo/tipo ("reemplazar" | "pagar"), pais, club_reemplazado/reemplaza,
##                         …todas las cifras de `previsualizar`…, "club": {…}}}; con "aplicar": true la propia
##                         pantalla aplica la entrada (`EntradaCampeonato.aplicar`) y añade "club_id".
##   volver()           -> el jugador quiere revisar la etapa anterior (Esc o «Volver»).

signal terminado(datos: Dictionary)
signal volver()

var _mundo: Mundo = null
var _pais := "CHI"
var _datos_club: Dictionary = {}
var _aplicar := false
var _modo := EntradaCampeonato.MODO_REEMPLAZAR
var _club_id := ""
var _hecho := false

var _tarjeta := {}        ## modo -> PanelContainer
var _grid := {}           ## modo -> GridContainer
var _elegir_btn := {}     ## modo -> Button
var _selector: OptionButton
var _ids_selector: Array[String] = []
var _aviso: Label
var _confirmar_btn: Button
var _capa: Control
var _conf_cuerpo: Label

func configurar(estado: Dictionary) -> void:
	_mundo = estado.get("mundo") as Mundo
	## El club que se está creando: de «club» si viene así, o de lo que dejó la configuración del club
	## («config»: nombre_club, color1/col1, color2/col2, estadio), que es como lo guarda el orquestador.
	var club: Variant = estado.get("club")
	_datos_club = EntradaCampeonato.datos_de_config(club if club is Dictionary else estado.get("config", {}) as Dictionary)
	var mio := _mundo.mi_club() if _mundo != null else null
	_pais = mio.pais if mio != null else "CHI"
	var pv: Variant = estado.get("pais")
	if pv is String and String(pv) != "":
		_pais = String(pv)
	elif pv is Dictionary:
		for k: String in ["pais", "codigo", "id"]:
			if String((pv as Dictionary).get(k, "")) != "":
				_pais = String((pv as Dictionary)[k])
				break
	_aplicar = bool(estado.get("aplicar", false))
	## Si se vuelve a esta etapa desde la siguiente, sale marcada la opción que ya se había elegido.
	var previa: Variant = estado.get("entrada")
	var e := EntradaCampeonato.normalizar(previa if previa is Dictionary else {}, _pais)
	_modo = String(e["modo"])
	_club_id = String(e["club_reemplazado"])
	if (_club_id == "" or _mundo == null or not _mundo.clubes.has(_club_id)) and _mundo != null:
		var sug := EntradaCampeonato.candidato_sugerido(_mundo, _pais)
		_club_id = sug.id if sug != null else ""
	_hecho = false
	if is_inside_tree():
		_construir()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	## Colgada de un Node (no de un Control) los anclajes no tienen a qué agarrarse: toma la ventana.
	if not (get_parent() is Control):
		position = Vector2.ZERO
		size = get_viewport_rect().size
		get_viewport().size_changed.connect(func() -> void: size = get_viewport_rect().size)
	if _mundo != null:
		_construir()

## Lo que se emitirá al confirmar con la opción elegida ahora mismo (lo leen también las pruebas).
func entrada_actual() -> Dictionary:
	if _mundo == null:
		return {"error": "sin mundo"}
	var p := EntradaCampeonato.previsualizar(_mundo, _modo, _pais, _club_id)
	p["club"] = _datos_club.duplicate()
	return p

func elegir_modo(modo: String) -> void:
	if modo != EntradaCampeonato.MODO_REEMPLAZAR and modo != EntradaCampeonato.MODO_CONFEDERACION:
		return
	_modo = modo
	_pintar()

func elegir_club(id: String) -> void:
	_club_id = id
	var i := _ids_selector.find(id)
	if _selector != null and i >= 0:
		_selector.select(_selector.get_item_index(i))
	_pintar()

# --- construcción -------------------------------------------------------------------------------

func _construir() -> void:
	_vaciar(self)
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	## Un velo con el color del club nuevo, arriba: la pantalla ya es «suya».
	var velo := TextureRect.new()
	var g := GradientTexture2D.new()
	g.gradient = Gradient.new()
	g.gradient.set_color(0, Color.from_string(_club_muestra(_datos_club).color1, Color("1e4030")) * Color(1, 1, 1, 0.38))
	g.gradient.set_color(1, Color(0, 0, 0, 0))
	g.fill_from = Vector2(0.5, 0.0)
	g.fill_to = Vector2(0.5, 1.0)
	velo.texture = g
	velo.stretch_mode = TextureRect.STRETCH_SCALE
	velo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	velo.offset_bottom = 360
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 56)
	margen.add_theme_constant_override("margin_top", 28)
	margen.add_theme_constant_override("margin_bottom", 24)
	add_child(margen)
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 16)
	margen.add_child(raiz)
	raiz.add_child(_cabecera())

	var fila := HBoxContainer.new()
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_theme_constant_override("separation", 28)
	raiz.add_child(fila)
	fila.add_child(_construir_tarjeta(EntradaCampeonato.MODO_REEMPLAZAR, "A",
		Idiomas.t("Reemplazar un club existente"),
		Idiomas.t("Ocupas la plaza de un club que desaparece. Gratis, pero con coste moral y de plantilla.")))
	fila.add_child(_construir_tarjeta(EntradaCampeonato.MODO_CONFEDERACION, "B",
		Idiomas.t("Pagar a la confederación"),
		Idiomas.t("Entras como club nuevo en la división más baja. Limpio con el resto de la liga, pero empiezas peor.")))

	raiz.add_child(_pie())
	var titulo := _etq(Tema.TAM_TITULO + 6, COL_ORO, Idiomas.t("¿Confirmas la entrada?"))
	_conf_cuerpo = _etq(Tema.TAM_DESTACADO + 1, COL_TEXTO, "", true)
	var si := _boton(Idiomas.t("Sí, entrar así"), true)
	si.pressed.connect(_confirmar)
	var no := _boton(Idiomas.t("Revisar"), false)
	no.pressed.connect(_cancelar_confirmacion)
	_capa = _capa_confirmacion(titulo, _conf_cuerpo, si, no)
	add_child(_capa)
	_pintar()
	(_elegir_btn[_modo] as Button).call_deferred("grab_focus")

func _cabecera() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(_club_muestra(_datos_club), 96)
	esc.custom_minimum_size = Vector2(70, 80)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(esc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	v.add_child(_etq(Tema.TAM_ROTULO + 2, COL_ORO, Idiomas.t("ENTRADA AL CAMPEONATO")))
	v.add_child(_etq(Tema.TAM_TITULO + 6, COL_TEXTO, Idiomas.t("¿Cómo entra %s en el campeonato?") % String(_datos_club.get("nombre", ""))))
	v.add_child(_etq(Tema.TAM_DESTACADO, COL_SUAVE, Idiomas.t("Dos caminos con sus cifras reales. Los dos se recuperan jugando: ninguno es un castigo definitivo."), true))
	h.add_child(v)
	return h

func _construir_tarjeta(modo: String, letra: String, titulo: String, sub: String) -> PanelContainer:
	var t := PanelContainer.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_stretch_ratio = 1.0
	## Mismo ancho para las dos aunque un idioma alargue un título: el ancho lo reparte la fila, no el texto.
	t.custom_minimum_size = Vector2(0, 0)
	t.clip_contents = true
	t.mouse_filter = Control.MOUSE_FILTER_STOP
	t.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			elegir_modo(modo))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	t.add_child(v)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 16)
	cab.add_child(_insignia(letra, COL_ACENTO if modo == EntradaCampeonato.MODO_REEMPLAZAR else COL_ORO.darkened(0.25)))
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(_etq(Tema.TAM_TITULO + 2, COL_TEXTO, titulo, true))
	tv.add_child(_etq(Tema.TAM_CUERPO + 1, COL_SUAVE, sub, true))
	cab.add_child(tv)
	v.add_child(cab)
	if modo == EntradaCampeonato.MODO_REEMPLAZAR:
		var fs := HBoxContainer.new()
		fs.add_theme_constant_override("separation", 12)
		fs.add_child(_etq(Tema.TAM_CUERPO + 1, COL_ORO, Idiomas.t("Club que reemplazas")))
		_selector = OptionButton.new()
		_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_selector.custom_minimum_size = Vector2(0, 40)
		_selector.add_theme_font_size_override("font_size", Tema.TAM_DESTACADO)
		_llenar_selector()
		_selector.item_selected.connect(func(i: int) -> void:
			var id_lista := _selector.get_item_id(i)
			if id_lista >= 0 and id_lista < _ids_selector.size():
				_modo = EntradaCampeonato.MODO_REEMPLAZAR
				elegir_club(_ids_selector[id_lista]))
		fs.add_child(_selector)
		v.add_child(fs)
	v.add_child(HSeparator.new())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## Con letra grande o pantallas bajas las ocho cifras no caben siempre: se desplazan, no se cortan.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	v.add_child(scroll)
	var b := _boton(Idiomas.t("Elegir esta opción"), false)
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(190, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func() -> void: elegir_modo(modo))
	## El botón va en la cabecera de la tarjeta: deja toda la altura a las ocho cifras.
	cab.add_child(b)
	_tarjeta[modo] = t
	_grid[modo] = grid
	_elegir_btn[modo] = b
	return t

## Los clubes del país por división (con su reputación), separados por un rótulo de división.
func _llenar_selector() -> void:
	_selector.clear()
	_ids_selector.clear()
	var div_actual := -1
	for c: Club in EntradaCampeonato.candidatos(_mundo, _pais):
		if c.division != div_actual:
			div_actual = c.division
			_selector.add_separator(Idiomas.t("División %d") % div_actual)
		_selector.add_item("%s  ·  %s %d" % [c.nombre, Idiomas.t("rep."), c.rep], _ids_selector.size())
		_ids_selector.append(c.id)
	var i := _ids_selector.find(_club_id)
	if i >= 0:
		_selector.select(_selector.get_item_index(i))

func _pie() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	var atras := _boton(Idiomas.t("Volver"), false)
	atras.pressed.connect(func() -> void: volver.emit())
	h.add_child(atras)
	var ayuda := _etq(Tema.TAM_CUERPO, COL_SUAVE, Idiomas.t("Esc: volver · 1 / 2: elegir opción · Enter: confirmar"))
	ayuda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(ayuda)
	_aviso = _etq(Tema.TAM_CUERPO + 1, COL_MAL, "")
	h.add_child(_aviso)
	_confirmar_btn = _boton(Idiomas.t("Confirmar la entrada"), true)
	_confirmar_btn.custom_minimum_size = Vector2(300, 56)
	_confirmar_btn.pressed.connect(_pedir_confirmacion)
	h.add_child(_confirmar_btn)
	return h

# --- pintar las cifras --------------------------------------------------------------------------

func _pintar() -> void:
	if _grid.is_empty():
		return
	for modo: String in _tarjeta:
		var sel := modo == _modo
		(_tarjeta[modo] as PanelContainer).add_theme_stylebox_override("panel",
			_caja(COL_TARJETA if sel else COL_PANEL, COL_ACENTO if sel else COL_BORDE, 3 if sel else 1))
		(_tarjeta[modo] as PanelContainer).modulate = Color.WHITE if sel else Color(1, 1, 1, 0.78)
		var b: Button = _elegir_btn[modo]
		b.set_pressed_no_signal(sel)
		b.text = ("✓ " + Idiomas.t("Elegida")) if sel else Idiomas.t("Elegir esta opción")
	var pa := EntradaCampeonato.previsualizar(_mundo, EntradaCampeonato.MODO_REEMPLAZAR, _pais, _club_id)
	var pb := EntradaCampeonato.previsualizar(_mundo, EntradaCampeonato.MODO_CONFEDERACION, _pais)
	_pintar_reemplazo(_grid[EntradaCampeonato.MODO_REEMPLAZAR], pa)
	_pintar_confederacion(_grid[EntradaCampeonato.MODO_CONFEDERACION], pb)
	var p := pa if _modo == EntradaCampeonato.MODO_REEMPLAZAR else pb
	_aviso.text = Idiomas.t(String(p["error"])) if p.has("error") else ""
	_confirmar_btn.disabled = p.has("error") or String(_datos_club.get("nombre", "")).strip_edges() == ""

func _pintar_reemplazo(g: GridContainer, p: Dictionary) -> void:
	_vaciar(g)
	if p.has("error"):
		_fila_cifra(g, Idiomas.t("Club que reemplazas"), Idiomas.t(String(p["error"])), Tono.MAL)
		return
	var otro := String(p["club_reemplazado_nombre"])
	_fila_cifra(g, Idiomas.t("Coste"), Idiomas.t("Ninguno"), Tono.BIEN)
	_fila_cifra(g, Idiomas.t("Presupuesto de partida"), Eco.dinero(int(p["presupuesto"])), Tono.NEUTRO,
		Idiomas.t("El de un club típico de %s") % String(p["liga"]))
	_fila_cifra(g, Idiomas.t("Reputación inicial"), str(int(p["rep"])), Tono.MAL,
		Idiomas.t("La de %s (%d) − 10: «recién llegado»") % [otro, int(p["rep_reemplazado"])])
	_fila_cifra(g, Idiomas.t("División"), String(p["liga"]), Tono.NEUTRO,
		Idiomas.t("División %d: ocupas su plaza, su estadio y su calendario") % int(p["division"]))
	_fila_cifra(g, Idiomas.t("Confianza de la directiva"), "%d / 100" % int(p["confianza"]), Tono.BIEN)
	_fila_cifra(g, Idiomas.t("Ánimo de la afición"), Idiomas.t("Normal"), Tono.NEUTRO)
	_fila_cifra(g, Idiomas.t("El otro club"), Idiomas.t("%s desaparece de la liga") % otro, Tono.MAL,
		Idiomas.t("Sus %d futbolistas quedan libres (puedes ficharlos). De sus socios, %d se quedan contigo y %d se reparten entre los demás clubes.") % [
			int(p["jugadores_libres"]), int(p["socios"]), int(p["socios_repartidos"])])
	_fila_cifra(g, Idiomas.t("Prensa"), Idiomas.t("«Nace un club sobre las cenizas de %s»") % otro, Tono.NEUTRO)

func _pintar_confederacion(g: GridContainer, p: Dictionary) -> void:
	_vaciar(g)
	if p.has("error"):
		_fila_cifra(g, Idiomas.t("División"), Idiomas.t(String(p["error"])), Tono.MAL)
		return
	_fila_cifra(g, Idiomas.t("Coste"), Eco.dinero(int(p["cuota"])), Tono.MAL,
		Idiomas.t("Cuota de afiliación: 25 %% de %s, al contado") % Eco.dinero(int(p["presupuesto_base"])))
	_fila_cifra(g, Idiomas.t("Presupuesto de partida"), Eco.dinero(int(p["presupuesto"])), Tono.MAL,
		Idiomas.t("75 %% del de un club típico de %s") % String(p["liga"]))
	_fila_cifra(g, Idiomas.t("Reputación inicial"), str(int(p["rep"])), Tono.MAL,
		Idiomas.t("La de un club recién creado (%d) − 20: «compró su plaza»") % Mundo.REP_FUNDACION)
	var nota := Idiomas.t("Siempre la más baja: la liga pasa a tener %d clubes") % int(p["clubes_liga"])
	if bool(p["descansos"]):
		nota += " · " + Idiomas.t("calendario con descansos")
	_fila_cifra(g, Idiomas.t("División"), String(p["liga"]), Tono.NEUTRO, nota)
	_fila_cifra(g, Idiomas.t("Confianza de la directiva"), "%d / 100" % int(p["confianza"]), Tono.MAL)
	_fila_cifra(g, Idiomas.t("Ánimo de la afición"), "−%d" % absi(int(p["animo_delta"])), Tono.MAL,
		Idiomas.t("Al empezar; se recupera en una temporada con buenos resultados"))
	_fila_cifra(g, Idiomas.t("El otro club"), Idiomas.t("No se toca ninguno"), Tono.BIEN)
	_fila_cifra(g, Idiomas.t("Prensa"), Idiomas.t("«Un club compra su plaza»"), Tono.MAL,
		Idiomas.t("Preguntas duras en la primera rueda de prensa"))

# --- confirmar ----------------------------------------------------------------------------------

func _pedir_confirmacion() -> void:
	var p := entrada_actual()
	if p.has("error") or _confirmar_btn.disabled:
		return
	var nombre := String(_datos_club.get("nombre", ""))
	if _modo == EntradaCampeonato.MODO_REEMPLAZAR:
		var otro := String(p["club_reemplazado_nombre"])
		_conf_cuerpo.text = Idiomas.t("%s ocupa la plaza de %s en %s. %s desaparece y sus futbolistas quedan libres. No se puede deshacer.") % [
			nombre, otro, String(p["liga"]), otro]
	else:
		_conf_cuerpo.text = Idiomas.t("%s paga %s a la confederación y entra en %s con %s de presupuesto. No se puede deshacer.") % [
			nombre, Eco.dinero(int(p["cuota"])), String(p["liga"]), Eco.dinero(int(p["presupuesto"]))]
	_capa.visible = true
	(_capa.find_children("*", "Button", true, false).back() as Button).call_deferred("grab_focus")

func _cancelar_confirmacion() -> void:
	_capa.visible = false
	_confirmar_btn.call_deferred("grab_focus")

func confirmacion_abierta() -> bool:
	return _capa != null and _capa.visible

func _confirmar() -> void:
	if _hecho:
		return
	var p := entrada_actual()
	if p.has("error"):
		_capa.visible = false
		return
	if _aplicar:
		var c := EntradaCampeonato.aplicar(_mundo, p, _datos_club)
		if c == null:
			_capa.visible = false
			_aviso.text = Idiomas.t("No se pudo aplicar la entrada")
			return
		p["club_id"] = c.id
	_hecho = true
	_capa.visible = false
	terminado.emit({"entrada": p})

func _unhandled_key_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k == null or not k.pressed or k.echo or _mundo == null:
		return
	match k.keycode:
		KEY_ESCAPE:
			if confirmacion_abierta():
				_cancelar_confirmacion()
			else:
				volver.emit()
		KEY_1, KEY_KP_1:
			if not confirmacion_abierta():
				elegir_modo(EntradaCampeonato.MODO_REEMPLAZAR)
		KEY_2, KEY_KP_2:
			if not confirmacion_abierta():
				elegir_modo(EntradaCampeonato.MODO_CONFEDERACION)
		KEY_ENTER, KEY_KP_ENTER:
			if confirmacion_abierta():
				_confirmar()
			else:
				_pedir_confirmacion()
		_:
			return
	get_viewport().set_input_as_handled()
