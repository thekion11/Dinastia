class_name PantallaConfigClub
extends "res://ui/entrada/config_club_pasos2.gd"
## [Capa 4/4 de `config_club.gd`] el contrato de la etapa, el resumen y la confirmación.
##
## CONTRATO (orquestador del flujo de entrada):
##   var p := PantallaConfigClub.new()
##   p.configurar({"mundo": m, "club": c, "nombre": "...", "config": anterior})  ## todo opcional
##   p.terminado.connect(func(d): ConfigClubDatos.aplicar_al_club(d["config"], club, mundo)
##                                ConfigClubDatos.aplicar_maquina(d["config"], get_tree()))
##   p.volver.connect(...)        ## «← Volver» en el primer paso: a la etapa anterior
## `terminado` lleva {"config": dict}; las claves están en la cabecera de `ConfigClubDatos`.
## La pantalla NO aplica nada por su cuenta: todo espera a la confirmación.

const TITULOS := [
	["Nombre, estadio y colores", "Lo primero: cómo se llama tu club y de qué colores se viste."],
	["El escudo", "Forma, patrón, colores y símbolo. Cada botón ya es el escudo con esa opción."],
	["La equipación", "La camiseta, el uniforme completo y el color de la interfaz."],
	["La mascota del club", ""],
	["Las instalaciones", ""],
	["Tu casa", ""],
	["Juego y gráficos", "Cómo se ve y cómo va el juego en este equipo."],
	["Repasa y confirma", "Así queda tu club. Puedes volver a cualquier paso antes de confirmar."],
]

var _capa_confirmar: Control = null

## Recibe lo de las etapas anteriores (ver `ConfigClubDatos.desde_estado`).
## Se puede llamar antes o después de entrar al árbol, y más de una vez.
func configurar(estado: Dictionary) -> void:
	datos = ConfigClubDatos.new()
	datos.desde_estado(estado)
	_paso = 0
	_vistos = {0: true}
	if _montada:
		ir_a(0)
		_rehacer_previa()

## Lo elegido hasta ahora, en el formato de `terminado` (para pruebas y para
## guardar el borrador si el orquestador quiere).
func resultado() -> Dictionary:
	return {"config": datos.a_dic()}

func _ready() -> void:
	BotonFx.activar(get_tree())
	_montar()
	ir_a(_paso)
	_rehacer_previa()

func _pintar_paso() -> void:
	if not _montada:
		return
	_limpiar_paso()
	_vista_mascota = null
	_titulo_paso.text = "%s  %s" % [String(PASOS[_paso][0]), Idiomas.t(String(TITULOS[_paso][0]))]
	_ayuda_paso.text = Idiomas.t(String(TITULOS[_paso][1])) if String(TITULOS[_paso][1]) != "" else ""
	_ayuda_paso.visible = _ayuda_paso.text != ""
	match _paso:
		0: _paso_identidad()
		1: _paso_escudo()
		2: _paso_equipacion()
		3: _paso_mascota()
		4: _paso_estadio()
		5: _paso_casa()
		6: _paso_juego()
		7: _paso_resumen()
	Animar.escalonar(_contenido, 0.02, 10)

# ------------------------------------------------------------------- RESUMEN

func _paso_resumen() -> void:
	var c := datos.club
	var rej := GridContainer.new()
	rej.columns = 2
	rej.add_theme_constant_override("h_separation", 10)
	rej.add_theme_constant_override("v_separation", 10)
	_contenido.add_child(rej)
	var est := Idiomas.t("El estadio que ya tiene")
	for p: Dictionary in ConfigClubDatos.presets():
		if String(p["clave"]) == datos.estilo_estadio:
			est = Idiomas.t(String(p["nombre"]))
	var an: Array = ConfigClubDatos.ANIMALES.get(datos.mascota, ["", ""])
	var kit := Idiomas.t(String(DisenosKit.diseno(c.kit_estilo)[1]))
	var den: Array = ConfigClubDatos.DENSIDADES[datos.densidad]
	var filas := [
		[0, Idiomas.t("Club"), "%s\n🏟️ %s%s" % [c.nombre.strip_edges(), c.estadio_nombre.strip_edges() if c.estadio_nombre.strip_edges() != "" \
			else Idiomas.t("Estadio %s") % c.nombre.strip_edges(), ("\n«%s»" % datos.lema.strip_edges()) if datos.lema.strip_edges() != "" else ""]],
		[1, Idiomas.t("Escudo"), (Idiomas.t("Escudo especial (coleccionable)") if c.esc_especial != "" else
			Idiomas.t("Símbolo: %s") % (c.esc_simbolo if c.esc_simbolo != "" else Escudo.iniciales(c))), Escudo.textura(c, 56)],
		[2, Idiomas.t("Equipación"), kit + ("\n" + Idiomas.t("Diseño completo propio") if not c.kit_x.is_empty() else ""),
			DisenosKit.textura_camiseta(c.kit_estilo, DisenosKit.colores(kit_previa()), 1, 56)],
		[3, Idiomas.t("Mascota"), "%s %s" % [String(an[1]), Idiomas.t(String(an[0]))]],
		[4, Idiomas.t("Estadio"), est],
		[5, Idiomas.t("Tu casa"), "%s %s" % [String(VidaDT.VIVIENDAS[datos.vivienda][3]), Idiomas.t(String(VidaDT.VIVIENDAS[datos.vivienda][0]))]],
		[6, Idiomas.t("Juego y gráficos"), "%s · %s · %s %s" % [Idiomas.t(_nombre_calidad(datos.calidad)),
			Idiomas.t("Sin límite") if datos.fps == 0 else "%d FPS" % datos.fps, String(den[3]), Idiomas.t(String(den[0]))]],
	]
	for f: Array in filas:
		rej.add_child(_ficha_resumen(int(f[0]), String(f[1]), String(f[2]), f[3] as Texture2D if f.size() > 3 else null))
	var problemas := datos.validar()
	if problemas.is_empty():
		_contenido.add_child(Tema.etiqueta(14, Tema.BIEN, "✔ " + Idiomas.t("Todo en orden. Pulsa «Confirmar y continuar».")))
		return
	_seccion(Idiomas.t("Antes de confirmar"))
	for p: Dictionary in problemas:
		var grave := bool(p["grave"])
		var paso := int(p["paso"])
		var b := _opcion(("⚠ " if grave else "• ") + String(p["texto"]), false, func() -> void: ir_a(paso), Vector2(0, 34))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", Tema.MAL if grave else Tema.ORO)
		_contenido.add_child(b)

## Una ficha del resumen; `img` (opcional) es la miniatura de lo elegido.
func _ficha_resumen(paso: int, titulo: String, valor: String, img: Texture2D = null) -> Control:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", _caja(Color(0.07, 0.1, 0.08, 0.9), Tema.RADIO, Color(1, 1, 1, 0.08)))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	pc.add_child(fila)
	if img != null:
		var t := _imagen(Vector2(48, 48))
		t.texture = img
		fila.add_child(t)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	fila.add_child(v)
	v.add_child(Tema.etiqueta(11, Tema.ORO, "%s  %s" % [String(PASOS[paso][0]), Idiomas.mayusculas(titulo)]))
	var l := Tema.etiqueta(14, Tema.TEXTO, valor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var b := _opcion("✎", false, func() -> void: ir_a(paso), Vector2(40, 36), Idiomas.t("Cambiar"))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(b)
	return pc

# --------------------------------------------------------------- CONFIRMAR

func _pedir_confirmacion() -> void:
	for p: Dictionary in datos.validar():
		if bool(p["grave"]):
			ir_a(int(p["paso"]))
			_actualizar_estado(true)
			return
	if is_instance_valid(_capa_confirmar):
		return
	_capa_confirmar = Control.new()
	_capa_confirmar.name = "Confirmacion"
	_capa_confirmar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_capa_confirmar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_capa_confirmar)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.62)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_capa_confirmar.add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_capa_confirmar.add_child(centro)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(520, 0)
	pc.add_theme_stylebox_override("panel", _caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.ORO))
	centro.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pc.add_child(v)
	var esc := _imagen(Vector2(0, 110))
	esc.texture = Escudo.textura(datos.club, 110)
	v.add_child(esc)
	var t := Tema.etiqueta(24, Tema.ORO, Idiomas.t("¿Confirmas tu club?"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var n := Tema.etiqueta(18, Tema.TEXTO, datos.club.nombre.strip_edges())
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var ex := Tema.etiqueta(13, Tema.SUAVE, Idiomas.t("Lo visual se puede retocar luego en Identidad, la casa en tu vida personal y los gráficos en Ajustes."))
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ex.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ex)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	v.add_child(fila)
	var no := _boton_grande(Idiomas.t("Seguir editando"), Tema.TARJETA)
	no.pressed.connect(_cerrar_confirmacion)
	fila.add_child(no)
	var si := _boton_grande("✔ " + Idiomas.t("Sí, confirmar"), Tema.ACENTO)
	si.name = "BotonConfirmar"
	si.pressed.connect(_confirmar)
	fila.add_child(si)
	si.call_deferred("grab_focus")
	Animar.aparecer(pc)

func _cerrar_confirmacion() -> void:
	if is_instance_valid(_capa_confirmar):
		_capa_confirmar.queue_free()
	_capa_confirmar = null

func _confirmar() -> void:
	if datos.hay_graves():
		_cerrar_confirmacion()
		return
	_cerrar_confirmacion()
	terminado.emit(resultado())

func _unhandled_input(ev: InputEvent) -> void:
	if not visible or not ev.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if is_instance_valid(_capa_confirmar):
		_cerrar_confirmacion()
	else:
		atras()
