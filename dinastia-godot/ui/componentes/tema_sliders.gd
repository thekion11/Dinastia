class_name TemaSliders
extends RefCounted
## DESLIZADORES MÁS GRUESOS Y FÁCILES DE AGARRAR (3-11-2026, evaluación de la interfaz): pista de 8 px, tirador redondo de 28 px y un área de toque de
## 44 px (el mínimo de un dedo). Todo desde el tema común (`TemaMenu._aplicar_tema`): los HSlider/VSlider de cualquier pantalla lo heredan;
## el alto mínimo se fija en cuanto un deslizador entra al árbol (el `Theme` no puede dar tamaños mínimos).
const GROSOR := 8.0
const TIRADOR := 28
const AREA := 44.0

static func tirador(color: Color) -> ImageTexture:
	var img := Image.create(TIRADOR, TIRADOR, false, Image.FORMAT_RGBA8)
	var c := (TIRADOR - 1) * 0.5
	for y in TIRADOR:
		for x in TIRADOR:
			var d := Vector2(x - c, y - c).length()
			var a := clampf(c + 0.5 - d, 0.0, 1.0)             ## borde suave de 1 px
			var borde := clampf(d - (c - 2.5), 0.0, 1.0)       ## aro más claro de ~2 px
			var col := color.lerp(Color(1, 1, 1), borde * 0.6)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)

static func aplicar(t: Theme, acento: Color, pista: Color, borde: Color, arbol: SceneTree) -> void:
	var pista_h := _caja(pista, borde, GROSOR, true)
	var pista_v := _caja(pista, borde, GROSOR, false)
	var lleno_h := _caja(acento, acento, GROSOR, true)
	var lleno_v := _caja(acento, acento, GROSOR, false)
	var t1 := tirador(acento)
	var t2 := tirador(acento.lightened(0.25))
	for clase: String in ["HSlider", "VSlider"]:
		var h := clase == "HSlider"
		t.set_stylebox("slider", clase, pista_h if h else pista_v)
		t.set_stylebox("grabber_area", clase, lleno_h if h else lleno_v)
		t.set_stylebox("grabber_area_highlight", clase, lleno_h if h else lleno_v)
		t.set_icon("grabber", clase, t1)
		t.set_icon("grabber_highlight", clase, t2)
		t.set_icon("grabber_disabled", clase, t1)
	if arbol != null and not arbol.has_meta("tema_sliders"):
		arbol.set_meta("tema_sliders", true)
		arbol.node_added.connect(_al_entrar)

static func _caja(relleno: Color, borde: Color, grosor: float, horizontal: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = relleno
	s.border_color = borde
	s.set_corner_radius_all(int(grosor * 0.5))
	if horizontal:
		s.content_margin_top = grosor * 0.5
		s.content_margin_bottom = grosor * 0.5
	else:
		s.content_margin_left = grosor * 0.5
		s.content_margin_right = grosor * 0.5
	return s

static func _al_entrar(n: Node) -> void:
	if n is HSlider:
		(n as HSlider).custom_minimum_size.y = maxf((n as HSlider).custom_minimum_size.y, AREA)
	elif n is VSlider:
		(n as VSlider).custom_minimum_size.x = maxf((n as VSlider).custom_minimum_size.x, AREA)
