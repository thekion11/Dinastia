class_name PrologoCine
extends RefCounted
## LAS HERRAMIENTAS DE CINE DEL PRÓLOGO (10-11, «puedes hacerlo muchísimo mejor», el dueño). El prólogo deja de ser una diapositiva por plano y pasa a
## ser cine dibujado por el motor: CAPAS pintadas una sola vez en texturas (`capa`) que la cámara mueve con paralaje, LUCES con mezcla aditiva
## (`material_luz`, `brillo`, `cono`), figuras con articulaciones que caminan y gesticulan (`figura`), banderas que ondean (`bandera`), y el acabado:
## viñeta, grano de película y bandas panorámicas (`acabado`). Todo procedural (0 bytes de arte) y barato: lo fijo no se repinta.
const MARGEN := 0.14   ## lo que sobra de cada capa por lado para que la cámara pueda moverse sin enseñar el borde

static var _tex_brillo: GradientTexture2D
static var _tex_grano: ImageTexture

## Una capa fija: `dibujar.call(ci, w, h)` se pinta UNA vez en una textura (SubViewport con UPDATE_ONCE) algo mayor que la pantalla.
## Devuelve el TextureRect, ya centrado y con su `pivot_offset`, para que la cámara lo mueva y escale.
static func capa(padre: Control, tam: Vector2, dibujar: Callable, transparente := true) -> TextureRect:
	var grande := (tam * (1.0 + 2.0 * MARGEN)).ceil()
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = transparente
	vp.size = Vector2i(grande)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var lienzo := Control.new()
	lienzo.size = grande
	lienzo.draw.connect(func() -> void: dibujar.call(lienzo, grande.x, grande.y))
	vp.add_child(lienzo)
	padre.add_child(vp)
	var tr := TextureRect.new()
	tr.texture = vp.get_texture()
	tr.size = grande
	tr.position = -tam * MARGEN
	tr.pivot_offset = grande * 0.5
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(tr)
	return tr

## Material de mezcla ADITIVA (luces: suman, no tapan).
static func material_luz() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

## Textura de brillo radial (blanco en el centro, nada en el borde), compartida.
static func tex_brillo() -> GradientTexture2D:
	if _tex_brillo == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
		_tex_brillo = GradientTexture2D.new()
		_tex_brillo.gradient = g
		_tex_brillo.fill = GradientTexture2D.FILL_RADIAL
		_tex_brillo.fill_from = Vector2(0.5, 0.5)
		_tex_brillo.fill_to = Vector2(1.0, 0.5)
		_tex_brillo.width = 128
		_tex_brillo.height = 128
	return _tex_brillo

## Un brillo suave (en un lienzo con `material_luz`): centro, radio, color e intensidad.
static func brillo(ci: CanvasItem, centro: Vector2, radio: float, c: Color, fuerza := 1.0) -> void:
	ci.draw_texture_rect(tex_brillo(), Rect2(centro - Vector2(radio, radio), Vector2(radio, radio) * 2.0), false, Color(c, c.a * fuerza))

## Un cono de luz desde `origen` hacia `destino` (abre `ancho` al llegar), que se desvanece hacia el final.
static func cono(ci: CanvasItem, origen: Vector2, destino: Vector2, ancho: float, c: Color, fuerza := 1.0) -> void:
	var dir := (destino - origen).normalized()
	var lado := Vector2(-dir.y, dir.x) * ancho * 0.5
	var a := Color(c, 0.55 * fuerza)
	var b := Color(c, 0.0)
	ci.draw_polygon(PackedVector2Array([origen - lado * 0.06, origen + lado * 0.06, destino + lado, destino - lado]), PackedColorArray([a, a, b, b]))

## Degradado vertical en un rectángulo.
static func degradado(ci: CanvasItem, r: Rect2, arriba: Color, abajo: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([arriba, arriba, abajo, abajo]))

## Una figura humana con articulaciones (silueta con contorno de luz opcional). `paso` (radianes) mueve piernas y brazos al caminar;
## `brazo` (-1..1) levanta el brazo derecho (gesto del DT, celebración). `pie` = punto entre los pies; `alto` en píxeles.
static func figura(ci: CanvasItem, pie: Vector2, alto: float, cuerpo: Color, paso := 0.0, brazo := 0.0, contorno := Color(0, 0, 0, 0), cabeza := Color(0, 0, 0, -1)) -> void:
	if contorno.a > 0.0:   ## contraluz: un halo suave detrás (no una figura duplicada)
		brillo(ci, pie + Vector2(0, -alto * 0.55), alto * 0.5, contorno, 0.6)
	_figura(ci, pie, alto, cuerpo, paso, brazo, cuerpo if cabeza.a < 0.0 else cabeza)

static func _figura(ci: CanvasItem, pie: Vector2, alto: float, c: Color, paso: float, brazo: float, c_cabeza: Color) -> void:
	var g := alto * 0.052   ## grosor base (fino: una silueta humana, no un muñeco)
	var cadera := pie + Vector2(0, -alto * 0.48)
	var hombro := pie + Vector2(0, -alto * 0.81)
	var oscila := sin(paso) * 0.38
	for lado: float in [-1.0, 1.0]:   ## piernas: muslo y pierna; la rodilla se dobla al dar el paso
		var ang := oscila * lado
		var rodilla := cadera + Vector2(lado * g * 0.7 + sin(ang) * alto * 0.24, cos(ang) * alto * 0.24)
		var dobla := maxf(0.0, -ang) * 0.9
		var tobillo := rodilla + Vector2(sin(ang - dobla) * alto * 0.23, cos(ang - dobla) * alto * 0.23)
		ci.draw_line(cadera + Vector2(lado * g * 0.8, 0), rodilla, c, g * 1.7)
		ci.draw_circle(rodilla, g * 0.8, c)
		ci.draw_line(rodilla, tobillo, c, g * 1.35)
		ci.draw_line(tobillo + Vector2(-g * 0.3, 0), tobillo + Vector2(g * 1.2, g * 0.2), c, g * 0.9)
	## Torso: hombros más anchos que la cadera, con los hombros redondeados y una cintura.
	var cintura := cadera + Vector2(0, -alto * 0.1)
	ci.draw_colored_polygon(PackedVector2Array([hombro + Vector2(-alto * 0.115, g * 0.4), hombro + Vector2(-alto * 0.06, -g * 0.5), hombro + Vector2(alto * 0.06, -g * 0.5),
		hombro + Vector2(alto * 0.115, g * 0.4), cintura + Vector2(alto * 0.07, 0), cadera + Vector2(alto * 0.075, 0), cadera + Vector2(-alto * 0.075, 0), cintura + Vector2(-alto * 0.07, 0)]), c)
	for lado2: float in [-1.0, 1.0]:   ## brazos: el derecho puede levantarse (gesto)
		var base := hombro + Vector2(lado2 * alto * 0.105, g * 0.6)
		var ang2 := -oscila * lado2 * 0.7 + lado2 * 0.08
		if lado2 > 0.0 and brazo != 0.0:
			ang2 = PI * 0.15 + brazo * 2.3
		var codo := base + Vector2(sin(ang2), cos(ang2)) * alto * 0.17
		var mano := codo + Vector2(sin(ang2 + 0.25 * lado2), cos(ang2 + 0.25 * lado2)) * alto * 0.16
		ci.draw_line(base, codo, c, g * 1.2)
		ci.draw_circle(codo, g * 0.55, c)
		ci.draw_line(codo, mano, c, g * 1.0)
		ci.draw_circle(mano, g * 0.6, c)
	ci.draw_line(hombro + Vector2(0, -g * 0.3), hombro + Vector2(0, -alto * 0.05), c, g * 1.3)   ## cuello
	ci.draw_circle(hombro + Vector2(0, -alto * 0.105), alto * 0.06, c_cabeza)

## Una bandera que ondea (mástil desde `base`, paño de `tam`) con dos colores en franjas.
static func bandera(ci: CanvasItem, base: Vector2, tam: Vector2, c1: Color, c2: Color, t: float, fase := 0.0) -> void:
	var tope := base + Vector2(0, -tam.y * 1.9)
	ci.draw_line(base, tope, Color(0.12, 0.12, 0.12), 3.0)
	var n := 10
	for franja in 2:
		var pts := PackedVector2Array()
		for k in n + 1:
			var x := float(k) / n
			var y0 := float(franja) / 2.0
			pts.append(tope + Vector2(x * tam.x, y0 * tam.y + sin(t * 5.0 + x * 5.0 + fase) * tam.y * 0.12 * x))
		for k in range(n, -1, -1):
			var x2 := float(k) / n
			var y1 := float(franja + 1) / 2.0
			pts.append(tope + Vector2(x2 * tam.x, y1 * tam.y + sin(t * 5.0 + x2 * 5.0 + fase) * tam.y * 0.12 * x2))
		ci.draw_colored_polygon(pts, c1 if franja == 0 else c2)

## El acabado de cine encima de todo: viñeta, grano de película (que se mueve) y las bandas panorámicas (`bandas` 0..1, para animarlas).
static func acabado(ci: CanvasItem, w: float, h: float, t: float, bandas := 1.0) -> void:
	for k in 5:   ## viñeta: bordes oscuros
		var m := float(k) * w * 0.035
		ci.draw_rect(Rect2(m, m * h / w, w - 2.0 * m, h - 2.0 * m * h / w), Color(0, 0, 0, 0.07), false, w * 0.035)
	if _tex_grano == null:
		var img := Image.create(160, 160, false, Image.FORMAT_LA8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 2026
		for y in 160:
			for x in 160:
				img.set_pixel(x, y, Color(1, 1, 1, rng.randf() * 0.09))
		_tex_grano = ImageTexture.create_from_image(img)
	var desfase := Vector2(fmod(t * 997.0, 160.0), fmod(t * 613.0, 160.0))
	ci.draw_texture_rect(_tex_grano, Rect2(-desfase, Vector2(w, h) + Vector2(160, 160)), true)
	var banda := h * 0.085 * clampf(bandas, 0.0, 1.0)
	ci.draw_rect(Rect2(0, 0, w, banda), Color.BLACK)
	ci.draw_rect(Rect2(0, h - banda, w, banda), Color.BLACK)
