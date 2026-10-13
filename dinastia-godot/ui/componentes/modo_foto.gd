class_name ModoFoto
extends Control
## EL MODO FOTO (MEGAPLAN fase 5). En la ciudad, el estadio y la casa: oculta
## la interfaz (la cámara de cada escena sigue respondiendo: arrastrar, rueda,
## WASD), pone un filtro -natural, colores del club, blanco y negro, sepia,
## cine o vintage-, un marco opcional con el escudo y el pie de foto, y
## «📸 Disparar» guarda la imagen en `user://fotos/`, que el móvil enseña en
## su app de Fotos.

const FILTROS := ["Natural", "Club", "Blanco y negro", "Sepia", "Cine", "Vintage"]
const CARPETA := "user://fotos"

var _padre: Control
var _ocultos: Array[CanvasItem] = []
var _filtro: ColorRect
var _mat: ShaderMaterial
var _marco: Control
var _barra: HBoxContainer
var _nombre_filtro: Label
var _aviso: Label
var _i := 0
var _club: Club
var _lugar := ""

static func abrir(padre: Control, club: Club, lugar: String) -> ModoFoto:
	var m := ModoFoto.new()
	m._padre = padre
	m._club = club
	m._lugar = lugar
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for h in padre.get_children():
		if h is CanvasItem and (h as CanvasItem).visible and h is Control:
			(h as CanvasItem).visible = false
			m._ocultos.append(h)
	padre.add_child(m)
	m._montar()
	return m

## Las fotos guardadas, de la más nueva a la más vieja.
static func fotos() -> Array[String]:
	var sal: Array[String] = []
	var d := DirAccess.open(CARPETA)
	if d == null:
		return sal
	for f in d.get_files():
		if f.ends_with(".png"):
			sal.append(CARPETA + "/" + f)
	sal.sort()
	sal.reverse()
	return sal

func _montar() -> void:
	_filtro = ColorRect.new()
	_filtro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://ui/componentes/filtro_foto.gdshader")
	_mat.set_shader_parameter("tinte", Color(_club.color1) if _club != null else Color.WHITE)
	_filtro.material = _mat
	add_child(_filtro)
	_marco = _crear_marco()
	add_child(_marco)
	_barra = HBoxContainer.new()
	_barra.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_barra.offset_top = -64
	_barra.offset_bottom = -16
	_barra.offset_left = -330
	_barra.offset_right = 330
	_barra.alignment = BoxContainer.ALIGNMENT_CENTER
	_barra.add_theme_constant_override("separation", 8)
	add_child(_barra)
	_boton("◀", func() -> void: _cambiar(-1))
	_nombre_filtro = Label.new()
	_nombre_filtro.custom_minimum_size = Vector2(130, 0)
	_nombre_filtro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre_filtro.add_theme_color_override("font_color", Color.WHITE)
	_nombre_filtro.add_theme_color_override("font_outline_color", Color.BLACK)
	_nombre_filtro.add_theme_constant_override("outline_size", 6)
	_barra.add_child(_nombre_filtro)
	_boton("▶", func() -> void: _cambiar(1))
	_boton("🖼 Marco", func() -> void: _marco.visible = not _marco.visible)
	_boton("📸 Disparar", _disparar)
	_boton("Salir", cerrar)
	_aviso = Label.new()
	_aviso.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_aviso.offset_top = 20
	_aviso.offset_left = -300
	_aviso.offset_right = 300
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 18)
	_aviso.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	_aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override("outline_size", 6)
	_aviso.text = "📷 Modo foto · mueve la cámara como siempre y elige un filtro"
	add_child(_aviso)
	_cambiar(0)

func _boton(t: String, f: Callable) -> void:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, 44)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(f)
	_barra.add_child(b)

func _crear_marco() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.visible = false
	for lado in 4:
		var r := ColorRect.new()
		r.color = Color(0.97, 0.96, 0.93)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		match lado:
			0:
				r.set_anchors_preset(Control.PRESET_TOP_WIDE)
				r.offset_bottom = 18
			1:
				r.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
				r.offset_top = -86
			2:
				r.set_anchors_preset(Control.PRESET_LEFT_WIDE)
				r.offset_right = 18
			3:
				r.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
				r.offset_left = -18
		c.add_child(r)
	if _club != null:
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(_club, 64)
		esc.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		esc.offset_left = 26
		esc.offset_top = -80
		esc.offset_right = 90
		esc.offset_bottom = -12
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c.add_child(esc)
	var pie := Label.new()
	pie.text = "%s  ·  %s  ·  %s" % [_club.nombre if _club != null else "Dinastía", _lugar, Time.get_date_string_from_system()]
	pie.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pie.offset_left = 100
	pie.offset_top = -62
	pie.offset_bottom = -30
	pie.add_theme_font_size_override("font_size", 22)
	pie.add_theme_color_override("font_color", Color(0.15, 0.15, 0.17))
	c.add_child(pie)
	return c

func _cambiar(d: int) -> void:
	_i = posmod(_i + d, FILTROS.size())
	_mat.set_shader_parameter("modo", _i)
	_nombre_filtro.text = FILTROS[_i]

func _disparar() -> void:
	_barra.visible = false
	_aviso.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	_barra.visible = true
	_aviso.visible = true
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var nombre := "%s/foto_%s.png" % [CARPETA, Time.get_datetime_string_from_system().replace(":", "-")]
	var err := img.save_png(nombre)
	_aviso.text = "📸 Guardada en tus fotos del móvil" if err == OK else "No se pudo guardar la foto"
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.8)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	create_tween().tween_property(flash, "color:a", 0.0, 0.35).finished.connect(flash.queue_free)

func cerrar() -> void:
	for h in _ocultos:
		if is_instance_valid(h):
			h.visible = true
	queue_free()
