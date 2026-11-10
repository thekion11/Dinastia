class_name LigasActivasPantalla
extends Control
## LIGAS ACTIVAS (10-11-2026, encargo del dueño «como Football Manager»): etapa de la entrada, entre el modo y el país. El jugador marca qué países se cargan; el resto no se genera (la partida
## arranca antes y pesa menos, sobre todo en el móvil). PC: todas marcadas; móvil: el país del juego y los cinco grandes. Se pueden AÑADIR más al cerrar cada temporada, no quitarlas.
## Contrato de las etapas (ver `OrquestadorEntrada`): `terminado(datos)`, `volver()`, `configurar(estado)`. Devuelve {"ligas": {"paises": [...]}} y deja la elección en `LigasActivas`.
signal terminado(datos: Dictionary)
signal volver()

const NOMBRES_CONFED := {"ucl": "Europa (UEFA)", "lib": "Sudamérica (CONMEBOL)", "conc": "Norte y Centroamérica (CONCACAF)", "afr": "África (CAF)", "asia": "Asia (AFC)", "oce": "Oceanía (OFC)", "otros": "Otros"}

var _estado: Dictionary = {}
var _casillas: Dictionary = {}   ## código de país → CheckBox
var _resumen: Label
var _continuar: Button

func configurar(estado: Dictionary) -> void:
	_estado = estado

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, Idiomas.t("NUEVO JUEGO · LIGAS")))
	v.add_child(Tema.etiqueta(Tema.TAM_TITULO + 6, Tema.ORO, Idiomas.t("LIGAS ACTIVAS")))
	var nota := Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, Idiomas.t("Elige qué ligas se cargan en la partida. Con menos ligas arranca antes y pesa menos (útil en el móvil). Podrás añadir más al cerrar cada temporada, pero no quitarlas."))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nota)
	var atajos := HBoxContainer.new()
	atajos.add_theme_constant_override("separation", 8)
	v.add_child(atajos)
	for a: Array in [["Todas", "todas"], ["Mi país y los 5 grandes", "grandes"], ["Ninguna", "ninguna"]]:
		var b := Button.new()
		b.text = Idiomas.t(String(a[0]))
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(_atajo.bind(String(a[1])))
		atajos.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 8)
	scroll.add_child(lista)
	var nombres: Dictionary = Datos.tabla("PAIS_SELECCION") as Dictionary
	var marcados := LigasActivas.cargar_eleccion()
	for g: Array in LigasActivas.por_confederacion():
		lista.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, Idiomas.t(String(NOMBRES_CONFED[g[0]]))))
		var flujo := HFlowContainer.new()
		flujo.add_theme_constant_override("h_separation", 12)
		lista.add_child(flujo)
		for p: String in g[1]:
			var c := CheckBox.new()
			c.text = "%s (%d)" % [Idiomas.t(String(nombres.get(p, p))), LigasActivas.clubes_de(p)]
			c.custom_minimum_size = Vector2(0, 40)
			c.button_pressed = marcados.has(p)
			c.toggled.connect(func(_on: bool) -> void: _actualizar())
			flujo.add_child(c)
			_casillas[p] = c
	_resumen = Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "")
	v.add_child(_resumen)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(fila)
	var bv := Button.new()
	bv.text = Idiomas.t("Volver")
	bv.custom_minimum_size = Vector2(130, 44)
	bv.pressed.connect(func() -> void: volver.emit())
	fila.add_child(bv)
	_continuar = Button.new()
	_continuar.text = Idiomas.t("Continuar ▶")
	_continuar.custom_minimum_size = Vector2(160, 44)
	_continuar.pressed.connect(confirmar)
	fila.add_child(_continuar)
	_actualizar()

## Los países marcados, en el orden de `LigasActivas.todos()`.
func marcados() -> Array[String]:
	var l: Array[String] = []
	for p: String in LigasActivas.todos():
		if _casillas.has(p) and (_casillas[p] as CheckBox).button_pressed:
			l.append(p)
	return l

func _atajo(que: String) -> void:
	var lista: Array[String] = []
	match que:
		"todas":
			lista = LigasActivas.todos()
		"grandes":
			lista = LigasActivas.por_defecto(true)
	for p: String in _casillas:
		(_casillas[p] as CheckBox).set_pressed_no_signal(lista.has(p))
	_actualizar()

func _actualizar() -> void:
	var m := marcados()
	var clubes := 0
	for p: String in m:
		clubes += LigasActivas.clubes_de(p)
	_resumen.text = Idiomas.t("%d países · %d clubes · unos %d jugadores") % [m.size(), clubes, clubes * 25] if not m.is_empty() else Idiomas.t("Elige al menos un país.")
	_continuar.disabled = m.is_empty()

## Lo que haría «Continuar» (las pruebas lo llaman directo). Sin nada marcado, no sigue.
func confirmar() -> void:
	var m := marcados()
	if m.is_empty():
		return
	LigasActivas.guardar_eleccion(m)
	terminado.emit({"ligas": {"paises": m}})

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		volver.emit()
