extends "res://ui/principal_p16.gd"
## [Capa 16/17 de `principal.gd`] _abrir_rueda_pantalla_completa, _repintar_posturas, _responder, _pintar_museo, _marca, _ver_ciudad_explorando … (+5)

## LA RUEDA DE PRENSA, DE PANTALLA COMPLETA, vive en `ui/principal/rueda_prensa.gd`
## (fase 0, paso 6b). Principal solo la abre; estos tres son puentes.

## Puente: cuándo salió la pregunta de la rueda abierta (lo ajustan capturas).
var _rueda_desde: int:
	get:
		return (_rueda_pop as _PrincipalRuedaPrensa).desde if is_instance_valid(_rueda_pop) else 0
	set(v):
		if is_instance_valid(_rueda_pop):
			(_rueda_pop as _PrincipalRuedaPrensa).desde = v

func _abrir_rueda_pantalla_completa(e: Dictionary) -> void:
	var r := _PrincipalRuedaPrensa.new(self)
	add_child(r)
	_rueda_pop = r
	r.abrir(e)

func _repintar_posturas() -> void:
	if is_instance_valid(_rueda_pop):
		(_rueda_pop as _PrincipalRuedaPrensa).repintar_posturas()

func _responder(i: int) -> void:
	if is_instance_valid(_rueda_pop):
		(_rueda_pop as _PrincipalRuedaPrensa).responder(i)

# --- las tres pestañas nuevas ----------------------------------------------

## EL MUSEO DEL CLUB. `Instalaciones` deja construirlo y cobra ingresos por él
## desde el porte, pero no tenía CONTENIDO: se pagaba un edificio cuyo interior
## no existía en ninguna pantalla.
##
## Las piezas no se guardan aparte: se deducen de lo que el club ya tiene
## anotado —trofeos, récords, goleadores— igual que el salón de la fama. Una
## lista paralela sería otro sitio más que mantener al día.
func _pintar_museo(lg: Logros) -> void:
	if mundo.obras == null or mundo.obras.nivel("museo") <= 0:
		return
	var piezas := lg.piezas_del_museo()
	_lista_logros.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("🏛️ MUSEO DEL CLUB  ·  nivel %d  ·  %d pieza(s)") % [mundo.obras.nivel("museo"), piezas.size()]
	_lista_logros.add_child(t)
	if piezas.is_empty():
		var vac := _texto(11, COL_SUAVE)
		vac.text = Idiomas.t("El museo está construido pero las vitrinas están vacías. Gana algo y se irán llenando solas.")
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_logros.add_child(vac)
	else:
		for p: Dictionary in piezas:
			var l := _texto(12, COL_ORO)
			l.text = "%s  %s" % [String(p["icono"]), String(p["titulo"])]
			_lista_logros.add_child(l)
			var d := _texto(10, COL_SUAVE)
			d.text = "     %s" % String(p["detalle"])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_logros.add_child(d)

	## EL COMPARADOR DE GENERACIONES. No compara jugadores uno a uno —eso sería
	## inventarse datos de gente retirada— sino la media del mejor plantel que
	## has tenido contra la del de ahora, que es la pregunta de verdad.
	var comp: Dictionary = lg.comparador_de_generaciones()
	if comp.is_empty():
		return
	var tc := _texto(11, COL_SUAVE)
	tc.text = Idiomas.t("⚖️ AQUEL EQUIPO Y ESTE")
	_lista_logros.add_child(tc)
	_dato("Tu mejor plantilla", "%d  ·  quedó %d.º  ·  figura: %s" % [
		int(comp["anio"]), int(comp["puesto"]), String(comp["mvp"])], COL_ORO, _lista_logros)
	_dato("Media del plantel de hoy", "%.1f" % float(comp["media_actual"]), COL_TEXTO, _lista_logros)

## EL LOGO DE UN SPONSOR, mismo patrón que `_escudo()` de arriba: la textura
## de `Marca` debajo y las iniciales encima con el color de contraste que
## corresponda. Antes de esto un sponsor era solo una palabra pintada del
## color de la tabla -ver la nota de `Marca` para el porqué-.
func _marca(nombre: String, color_hex: String, alto: int = 28) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	var t := TextureRect.new()
	t.texture = Marca.textura(nombre, color_hex, alto)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := Label.new()
	l.text = Marca.iniciales(nombre)
	l.add_theme_font_size_override("font_size", maxi(8, alto / 2 - 2))
	l.add_theme_color_override("font_color", _tinta(Color(color_hex)))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(l)
	return caja

## Abre la ciudad y arranca directamente el paseo ("pie") o la conducción ("coche").
func _ver_ciudad_explorando(modo: String) -> void:
	await _ver_ciudad_con_carga()
	for h in get_children():
		if h is VistaCiudad:
			(h as VistaCiudad).explorar(modo)

func _pintar_tipografia() -> void:
	var lt := _texto(10, COL_SUAVE)
	lt.text = Idiomas.t("Tipografia")
	_lista_ajustes.add_child(lt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_ajustes.add_child(flow)
	for k: String in TIPOGRAFIAS:
		var clave := k
		var b := Button.new()
		b.text = String((TIPOGRAFIAS[k] as Array)[0])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = _tipografia == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(132, 24)
		## Cada boton se escribe CON su fuente: se elige mirando, igual que las
		## paletas. Un nombre de fuente no dice nada; verla, si.
		var f := _fuente_de(clave)
		if f != null:
			b.add_theme_font_override("font", f)
		b.pressed.connect(func() -> void:
			_tipografia = clave
			_aplicar_aspecto()
			_refrescar())
		flow.add_child(b)

func _aplicar_vista_compacta() -> void:
	var sep := SEPARACION_COMPACTA if _vista_compacta else SEPARACION_NORMAL
	var t := theme if theme != null else Theme.new()
	for clase: String in ["BoxContainer", "VBoxContainer", "HBoxContainer"]:
		t.set_constant("separation", clase, sep)
	t.set_constant("margin_top", "MarginContainer", sep)
	t.set_constant("margin_bottom", "MarginContainer", sep)
	theme = t

func _alternar_favorito(tab: String) -> void:
	if _favoritos.has(tab):
		_favoritos.erase(tab)
	elif _favoritos.size() < FAVORITOS_MAX:
		_favoritos.append(tab)
	_refrescar()

func _pintar_ranuras() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("RANURAS DE GUARDADO")
	_lista_ajustes.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = Idiomas.t("Aparte del autoguardado. Sirven para dejar una copia antes de una decisión de la que no se vuelve.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(ex)
	## Se lista una vez y se busca en memoria: `Partida.listar()` abre y lee la
	## cabecera de cada fichero, y llamarlo tres veces sería leer el disco tres
	## veces para pintar tres filas.
	var guardadas := {}
	for f: Dictionary in Partida.listar():
		guardadas[String(f.get("fichero", ""))] = f
	for i in RANURAS.size():
		var nombre := String(RANURAS[i])
		var hay: Dictionary = guardadas.get(nombre, {})
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_ajustes.add_child(fila)
		var et := _texto(12, COL_TEXTO if not hay.is_empty() else COL_SUAVE)
		et.text = Idiomas.t("Ranura %d") % (i + 1)
		et.custom_minimum_size = Vector2(70, 0)
		fila.add_child(et)
		var desc := _texto(11, COL_SUAVE)
		desc.text = Idiomas.t("%s · %d, semana %d") % [String(hay.get("club", "")), int(hay.get("anio", 0)), int(hay.get("semana", 0))] if not hay.is_empty() else Idiomas.t("vacía")
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.clip_text = true
		fila.add_child(desc)
		var bg := Button.new()
		bg.text = Idiomas.t("Guardar")
		bg.add_theme_font_size_override("font_size", 11)
		bg.pressed.connect(func() -> void: _partida.guardar_en(nombre))
		fila.add_child(bg)
		var bc := Button.new()
		bc.text = Idiomas.t("Cargar")
		bc.add_theme_font_size_override("font_size", 11)
		bc.disabled = hay.is_empty()
		bc.pressed.connect(func() -> void: _partida.cargar_de(nombre))
		fila.add_child(bc)
	_lista_ajustes.add_child(HSeparator.new())

## Salta al chip de al lado dentro del bloque actual (los gatillos de
## siempre). Ahora los chips son diccionarios {tab, secc, label}, así que la
## posición se busca comparando pestaña Y sección, no el título a secas.
func _saltar_pestana(d: int) -> void:
	var chips: Array = _grupo_por_id(_grupo_actual).get("tabs", [])
	if chips.is_empty():
		return
	var titulo := _pestanas.get_tab_title(_pestanas.current_tab)
	var i := 0
	for k in chips.size():
		var chip: Dictionary = chips[k]
		if String(chip["tab"]) == titulo and _seccion_activa(chip):
			i = k
			break
	_ir_a_chip(chips[(i + d + chips.size()) % chips.size()])
