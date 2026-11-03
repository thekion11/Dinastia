class_name EleccionPartido
extends Control
## CÓMO JUGAR ESTE PARTIDO (3-11-2026, orden 22 del dueño: «al iniciar un partido, una pantalla completa con la opción
## de simular, jugar o jugar solo las jugadas importantes»). Antes el modo vivía escondido en un panel de Ajustes y
## «Controlar a mi equipo» era un interruptor dentro del partido. Tres tarjetas grandes (táctiles y con mando):
##   🎮 JUGAR                 3D completo y tú manejas a tu equipo (como en FC).
##   🎯 SOLO LAS IMPORTANTES   el partido corre solo a x4 y se para en las llegadas claras de tu equipo: ahí decides tú.
##   ⏩ SIMULAR               sin jugar: al instante, en resumen o en vivo por radio (sin 3D).
## «No volver a preguntar» guarda la elección (se cambia en Ajustes → Juego → «Preguntar antes de cada partido»).

signal elegido(eleccion: Dictionary)   ## {"modo": clave de MODOS_SIMULACION, "control": bool, "ocasiones": bool}

const PREF_PREGUNTAR := "preguntar_partido"
const PREF_ULTIMA := "ultima_eleccion_partido"
const SIMULAR := [["instantaneo", "⚡ Al instante"], ["resumen", "📋 Resumen"], ["vivo", "📻 En vivo"]]

var titulo := ""
var _sim := "resumen"
var _recordar: CheckBox
var _primera: Button

static func preguntar() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(CajonAjustes.RUTA) != OK or bool(cfg.get_value(CajonAjustes.SECCION, PREF_PREGUNTAR, true))

static func fijar_preguntar(si: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, PREF_PREGUNTAR, si)
	cfg.save(CajonAjustes.RUTA)

## La última elección guardada (la que se usa sin preguntar), o {} si no hay.
static func ultima() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return {}
	return cfg.get_value(CajonAjustes.SECCION, PREF_ULTIMA, {})

## Lo que significa cada opción, y lo deja guardado para el partido (control del equipo y ocasiones jugables).
static func eleccion(opcion: String, sim: String = "resumen") -> Dictionary:
	match opcion:
		"jugar":
			return {"modo": "completo", "control": true, "ocasiones": false}
		"importantes":
			return {"modo": "destacados", "control": false, "ocasiones": true}
	return {"modo": sim if sim in ["instantaneo", "resumen", "vivo"] else "resumen", "control": false, "ocasiones": false}

static func aplicar(e: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "control_equipo", bool(e.get("control", false)))
	cfg.set_value(CajonAjustes.SECCION, OcasionJugable.PREF, bool(e.get("ocasiones", false)))
	cfg.set_value(CajonAjustes.SECCION, PREF_ULTIMA, e)
	cfg.save(CajonAjustes.RUTA)

func _ready() -> void:
	## Siempre a pantalla completa, aunque el padre no tenga tamaño (misma trampa que la pantalla de carga del móvil).
	top_level = true
	_ajustar()
	get_viewport().size_changed.connect(_ajustar)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fondo := ColorRect.new()
	fondo.color = Color(Tema.FONDO, 0.97)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	centro.add_child(col)
	var t := Tema.etiqueta(Tema.TAM_TITULO + 6, Tema.ORO, Idiomas.t("¿Cómo quieres este partido?"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	if titulo != "":
		var s := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, titulo)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(s)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 18)
	col.add_child(fila)
	_primera = _tarjeta(fila, "🎮", Idiomas.t("JUGAR"), Idiomas.t("El partido entero en 3D y tú manejas a tu equipo."), "jugar")
	_tarjeta(fila, "🎯", Idiomas.t("SOLO LAS IMPORTANTES"), Idiomas.t("Corre solo y se para en las llegadas claras de tu equipo: ahí decides tú."), "importantes")
	var sim := _tarjeta(fila, "⏩", Idiomas.t("SIMULAR"), Idiomas.t("Sin jugar. Elige cómo verlo:"), "simular")
	var sub := HFlowContainer.new()
	sub.alignment = FlowContainer.ALIGNMENT_CENTER
	(sim.get_child(0) as VBoxContainer).add_child(sub)
	var grupo := ButtonGroup.new()
	for par: Array in SIMULAR:
		var b := Button.new()
		b.text = Idiomas.t(String(par[1]))
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = String(par[0]) == _sim
		var clave := String(par[0])
		b.pressed.connect(func() -> void: _sim = clave)
		sub.add_child(b)
	_recordar = CheckBox.new()
	_recordar.text = Idiomas.t("No volver a preguntar (se cambia en Ajustes)")
	_recordar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_recordar)
	Animar.entrar(col)
	_primera.grab_focus.call_deferred()

func _ajustar() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size

func _tarjeta(padre: Node, icono: String, nombre: String, texto: String, opcion: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(260, 230)
	b.name = "Opcion_" + opcion
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = 14
	v.offset_bottom = -14
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 8)
	b.add_child(v)
	for par: Array in [[icono, 48, Tema.TEXTO], [nombre, Tema.TAM_DESTACADO + 2, Tema.ORO], [texto, Tema.TAM_CUERPO, Tema.SUAVE]]:
		var l := Tema.etiqueta(int(par[1]), par[2], String(par[0]))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	b.pressed.connect(_elegir.bind(opcion))
	padre.add_child(b)
	return b

func _elegir(opcion: String) -> void:
	var e := eleccion(opcion, _sim)
	aplicar(e)
	if _recordar.button_pressed:
		fijar_preguntar(false)
	Sonido.toca("clic")
	elegido.emit(e)
