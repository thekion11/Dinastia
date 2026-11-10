class_name LigasActivasPantalla
extends Control
## LIGAS ACTIVAS (10-11-2026, encargo del dueño «como Football Manager»): etapa de la entrada, entre el modo y el país. El jugador marca qué países se cargan; el resto no se genera (la partida
## arranca antes y pesa menos, sobre todo en el móvil). PC: todas marcadas; móvil: el país del juego y los cinco grandes. Se pueden AÑADIR más al cerrar cada temporada, no quitarlas.
## Contrato de las etapas (ver `OrquestadorEntrada`): `terminado(datos)`, `volver()`, `configurar(estado)`. Devuelve {"ligas": {"paises": [...]}} y deja la elección en `LigasActivas`.
signal terminado(datos: Dictionary)
signal volver()

const NOMBRES_CONFED := {"ucl": "Europa (UEFA)", "lib": "Sudamérica (CONMEBOL)", "conc": "Norte y Centroamérica (CONCACAF)", "afr": "África (CAF)", "asia": "Asia (AFC)", "oce": "Oceanía (OFC)", "otros": "Otros"}

## Modo «añadir» (al cerrar una temporada): se enseñan solo los países que faltan y se devuelve {"ligas": {"paises": [...]}} (vacío = «ahora no»); se aplica con `LigasActivas.agregar`.
var mundo_agregar: Mundo = null
var _estado: Dictionary = {}
var _casillas: Dictionary = {}   ## código de país → botón de dos estados
var _resumen: Label
var _continuar: Button

func configurar(estado: Dictionary) -> void:
	_estado = estado

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE   ## (10-11) para el guardián del foco no es una «capa»: el fondo, nada más
	add_child(fondo)
	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 16)
	add_child(margen)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.BORDE))
	margen.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	caja.add_child(v)
	var agregando := mundo_agregar != null
	v.add_child(Tema.etiqueta(EscalaTipografica.ROTULO, Tema.SUAVE, Idiomas.t("FIN DE TEMPORADA · LIGAS") if agregando else Idiomas.t("NUEVO JUEGO · LIGAS")))
	v.add_child(Tema.etiqueta(Tema.TAM_TITULO + 6, Tema.ORO, Idiomas.t("AÑADIR LIGAS") if agregando else Idiomas.t("LIGAS ACTIVAS")))
	var nota := Tema.etiqueta(EscalaTipografica.CUERPO, Tema.TEXTO, Idiomas.t("Añade países a tu partida: sus ligas y clubes entran en la temporada que empieza. Una vez añadidos no se pueden quitar.") if agregando else Idiomas.t("Elige qué ligas se cargan en la partida. Con menos ligas arranca antes y pesa menos (útil en el móvil). Podrás añadir más al cerrar cada temporada, pero no quitarlas."))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nota)
	var atajos := HBoxContainer.new()
	atajos.add_theme_constant_override("separation", 8)
	v.add_child(atajos)
	for a: Array in [["Por defecto", "defecto"], ["Mundo entero", "todas"], ["Ninguna", "ninguna"]] if not agregando else [["Todas", "todas"], ["Ninguna", "ninguna"]]:
		var b := Button.new()
		b.text = Idiomas.t(String(a[0]))
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(_atajo.bind(String(a[1])))
		atajos.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true   ## (10-11) con mando, la lista larga sigue al foco
	v.add_child(scroll)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 8)
	scroll.add_child(lista)
	var nombres: Dictionary = Datos.tabla("PAIS_SELECCION") as Dictionary
	var marcados: Array[String] = []
	var faltan: Array[String] = []
	if agregando:
		faltan = LigasActivas.faltan(mundo_agregar)
	else:
		marcados = LigasActivas.cargar_eleccion()
		faltan = LigasActivas.todos()
	for g: Array in LigasActivas.por_confederacion():
		if agregando and not (g[1] as Array).any(func(x: String) -> bool: return faltan.has(x)):
			continue
		lista.add_child(Tema.etiqueta(EscalaTipografica.ROTULO, Tema.ORO, Idiomas.mayusculas(Idiomas.t(String(NOMBRES_CONFED[g[0]])))))
		var flujo := HFlowContainer.new()
		flujo.add_theme_constant_override("h_separation", 12)
		lista.add_child(flujo)
		for p: String in g[1]:
			if not faltan.has(p):
				continue
			var c := Button.new()   ## botón de dos estados: la casilla vacía del tema no se ve sobre el fondo oscuro
			c.toggle_mode = true
			c.custom_minimum_size = Vector2(0, 44)
			c.set_meta("etiqueta", "%s (%d)" % [Idiomas.t(String(nombres.get(p, p))), LigasActivas.clubes_de(p)])
			c.set_pressed_no_signal(marcados.has(p))
			_rotular(c)
			c.toggled.connect(func(_on: bool) -> void:
				_rotular(c)
				_actualizar())
			flujo.add_child(c)
			_casillas[p] = c
	## (10-11) Con la cruceta, izquierda/derecha van a la casilla anterior/siguiente en el orden en que se ven: la búsqueda de vecinos de Godot, en
	## filas de anchos distintos, mandaba «derecha» desde Belgien a Spanien (la de encima, 5 px más ancha) y la lista no se podía recorrer.
	var orden: Array = _casillas.values()
	for i in orden.size():
		var b := orden[i] as Button
		if i > 0:
			b.focus_neighbor_left = b.get_path_to(orden[i - 1])
		if i < orden.size() - 1:
			b.focus_neighbor_right = b.get_path_to(orden[i + 1])
	_resumen = Tema.etiqueta(EscalaTipografica.CUERPO, Tema.TEXTO, "")
	_resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_resumen)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(fila)
	var bv := Button.new()
	bv.text = Idiomas.t("Ahora no") if agregando else Idiomas.t("Volver")
	bv.custom_minimum_size = Vector2(130, 44)
	bv.pressed.connect(func() -> void: terminado.emit({"ligas": {"paises": []}}) if mundo_agregar != null else volver.emit())
	fila.add_child(bv)
	_continuar = Button.new()
	_continuar.text = Idiomas.t("Añadir") if agregando else Idiomas.t("Continuar ▶")
	_continuar.custom_minimum_size = Vector2(160, 44)
	_continuar.pressed.connect(confirmar)
	fila.add_child(_continuar)
	_actualizar()
	## (10-11, pulido con mando) Foco al entrar (la primera casilla marcada o «Continuar»), lo de detrás aislado (al añadir, la pantalla va encima
	## de la principal) y el guardián del foco: a la vista en la lista y sin quedarse clavado en la última fila visible.
	add_child(GuardianFoco.new(self))
	if get_parent() is Control:
		FocoMando.aislar_mientras(self)
	FocoMando.enfocar.call_deferred(self)

## Los países marcados, en el orden de `LigasActivas.todos()`.
func marcados() -> Array[String]:
	var l: Array[String] = []
	for p: String in LigasActivas.todos():
		if _casillas.has(p) and (_casillas[p] as BaseButton).button_pressed:
			l.append(p)
	return l

func _atajo(que: String) -> void:
	var lista: Array[String] = []
	match que:
		"todas":
			lista.assign(_casillas.keys())
		"defecto":
			lista = LigasActivas.por_defecto(EscalaMovil.es_movil())
	for p: String in _casillas:
		(_casillas[p] as BaseButton).set_pressed_no_signal(lista.has(p))
		_rotular(_casillas[p] as Button)
	_actualizar()

func _rotular(b: Button) -> void:
	b.text = "%s %s" % ["☑" if b.button_pressed else "☐", String(b.get_meta("etiqueta", ""))]

func _actualizar() -> void:
	var m := marcados()
	var clubes := 0
	for p: String in m:
		clubes += LigasActivas.clubes_de(p)
	var movil := EscalaMovil.es_movil()
	var c := LigasActivas.coste(m, movil)
	_resumen.text = Idiomas.t("%d países · %d clubes · ≈ %.1f s por semana · ≈ %.1f GB de memoria") % [m.size(), clubes, float(c["s_semana"]), float(c["gb"])] if not m.is_empty() else Idiomas.t("Elige al menos un país.")
	if not m.is_empty() and ((movil and clubes > 400) or (not movil and clubes > 1200)):
		_resumen.text += "\n" + Idiomas.t("⚠ Mucho contenido para este dispositivo: la partida irá más lenta y puede cerrarse por falta de memoria.")
	_continuar.disabled = m.is_empty() and mundo_agregar == null   ## al añadir, sin nada marcado «Añadir» equivale a «Ahora no»

## Lo que haría «Continuar» (las pruebas lo llaman directo). Sin nada marcado, no sigue.
func confirmar() -> void:
	var m := marcados()
	if mundo_agregar != null:   ## añadir: no se guarda como elección de la máquina; se aplica quien la abrió
		terminado.emit({"ligas": {"paises": m}})
		return
	if m.is_empty():
		return
	LigasActivas.guardar_eleccion(m)
	terminado.emit({"ligas": {"paises": m}})

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if mundo_agregar != null:
			terminado.emit({"ligas": {"paises": []}})   ## «ahora no»
		else:
			volver.emit()
