class_name MenuPausaPartido
extends Control
## LA PAUSA DEL PARTIDO (17-11-2026, orden del dueño: «distinta y corta»), como la de la maqueta (`j_pausa`): un velo sobre el partido congelado y una
## tarjeta blanca con «PAUSA», el marcador con los dos escudos y el minuto, y SEIS opciones: Reanudar · Táctica y cambios · Estadísticas · Controles ·
## Simular el resto · Salir del partido. Los AJUSTES ya no están aquí: viven solo en el menú de antes del partido (`MenuPartido`).
## La abre `VistaEstadio` con su botón de pausa; mientras está abierta el motor no da pasos (`VistaEstadio._pausa_menu`). Esc / B = Reanudar.

signal cerrado

const TINTA := Color("14213d")
const FILA := Color("e6ebf5")
const ROJO := Color("c8102e")

var vista: Control
var partido: Partido
var _primera: Button

## Las opciones: [clave, texto, acción de la vista (o "" para cerrar), atajo]
const OPCIONES := [
	["reanudar", "Reanudar", "", "jugar_pausa"],
	["tactica", "Táctica y cambios", "_abrir_panel_dt", ""],
	["estadisticas", "Estadísticas", "abrir_estadisticas", "jugar_estadisticas"],
	["controles", "Controles", "abrir_controles", ""],
	["simular", "Simular el resto", "_simular_resto_motor", ""],
	["salir", "Salir del partido", "salir", ""],
]

static func abrir(v: Control, p: Partido) -> MenuPausaPartido:
	var m := MenuPausaPartido.new()
	m.vista = v
	m.partido = p
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_STOP
	m.z_index = 120
	v.add_child(m)
	m._montar()
	Sonido.toca("clic")
	return m

func _montar() -> void:
	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.03, 0.08, 0.62)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 24
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 26
	sb.content_margin_bottom = 26
	caja.add_theme_stylebox_override("panel", sb)
	caja.custom_minimum_size = Vector2(Tema.letra(460), 0)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	caja.add_child(v)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)
	var titulo := EstiloAvanzar.etiqueta(Idiomas.t("Pausa"), 46, TINTA, true, true)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(titulo)
	if partido != null:
		cab.add_child(_marcador())
	var raya := ColorRect.new()
	raya.color = ROJO
	raya.custom_minimum_size = Vector2(56, 4)
	raya.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(raya)
	for op: Array in OPCIONES:
		var b := _fila(Idiomas.t(String(op[1])), String(op[3]))
		b.name = String(op[0])
		b.pressed.connect(_elegir.bind(String(op[2])))
		v.add_child(b)
		if _primera == null:
			_primera = b
	_primera.grab_focus.call_deferred()

## Los dos escudos con el marcador y el minuto.
func _marcador() -> Control:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 8)
	f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in 3:
		if i == 1:
			var g := VBoxContainer.new()
			g.add_theme_constant_override("separation", -4)
			var r := EstiloAvanzar.etiqueta("%d - %d" % [partido.goles_local, partido.goles_visita], 28, TINTA, true)
			r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			g.add_child(r)
			var m := EstiloAvanzar.etiqueta("%d'" % partido.minuto, 15, ROJO, true)
			m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			g.add_child(m)
			f.add_child(g)
			continue
		var t := TextureRect.new()
		t.texture = Escudo.textura(partido.local if i == 0 else partido.visita, 64)
		t.custom_minimum_size = Vector2(Tema.letra(38), Tema.letra(38))
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		f.add_child(t)
	return f

func _fila(texto: String, accion: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, Tema.letra(48))
	b.add_theme_font_override("font", EstiloAvanzar.fuente_titulo())
	b.add_theme_font_size_override("font_size", Tema.letra(22))
	b.add_theme_stylebox_override("normal", _estilo(FILA, false))
	b.add_theme_stylebox_override("pressed", _estilo(FILA.darkened(0.06), true))
	for k in ["hover", "focus"]:
		b.add_theme_stylebox_override(k, _estilo(Color.WHITE, true))
	b.add_theme_color_override("font_color", TINTA)
	for k in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, ROJO)
	if accion != "":
		var atajo := EstiloAvanzar.etiqueta(Mando.corto_de(accion), 14, Color(TINTA, 0.5))
		atajo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		atajo.offset_left = -90
		atajo.offset_right = -14
		atajo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		atajo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(atajo)
	b.mouse_entered.connect(b.grab_focus)
	return b

## La fila elegida: blanca, con un filo rojo a la izquierda y el borde fino (la de la maqueta al pasar por encima).
static func _estilo(fondo: Color, marcada: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.content_margin_left = 16
	s.content_margin_right = 16
	if marcada:
		s.border_width_left = 5
		s.border_color = ROJO
		s.shadow_color = Color(0.08, 0.13, 0.24, 0.18)
		s.shadow_size = 6
	return s

func _elegir(accion: String) -> void:
	Sonido.toca("clic")
	cerrar()
	match accion:
		"":
			pass
		_:
			if vista.has_method(accion):
				vista.call(accion)

func cerrar() -> void:
	if is_queued_for_deletion():
		return
	cerrado.emit()
	queue_free()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") or e.is_action_pressed("jugar_pausa"):
		get_viewport().set_input_as_handled()
		cerrar()
