class_name EscaparateTarjetas
extends RefCounted
## LAS TRES TARJETAS GRANDES DE ARRIBA DEL ESCAPARATE (17-11-2026; Liga Master del PES 2020): el DT con su frase táctica, la NOTICIA con escena (dos futbolistas del club) y la
## TABLA de diez filas con escudo. Son `TableroInicio.tarjeta` (botón entero, foco de mando, campana de avisos): lo que cambia es que la IMAGEN manda y el texto es grande y corto.

## La escena de fondo de una tarjeta (el despacho para el DT; el vestuario o el túnel para los jugadores), oscurecida, y encima los retratos 3D con fondo transparente.
static func _escena(b: Control, _fondo_jpg: String, tinte: Color) -> void:
	## (17-11) Fondo de ESTUDIO en lugar de la foto de la sala (traía una figura negra al fondo): un foco radial del color del club detrás de los retratos y viñeta oscura en los bordes.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([tinte.lightened(0.28), tinte.darkened(0.45), tinte.darkened(0.8)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.42)
	gt.fill_to = Vector2(1.0, 1.0)
	gt.width = 128
	gt.height = 128
	var t := TextureRect.new()
	t.texture = gt
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(t)
	b.move_child(t, 0)

## Un retrato (con fondo transparente) en la zona `anclas` de la tarjeta: se enseña de la cabeza a la cintura (arriba 78 % del cuadro), entero y sin deformar.
static func _imagen(b: Control, tex: Texture2D, anclas: Vector4, orden: int) -> TextureRect:
	var t := TextureRect.new()
	var recorte := AtlasTexture.new()
	recorte.atlas = tex
	recorte.region = Rect2(0, 0, tex.get_width(), tex.get_height() * 0.78)
	t.texture = recorte if tex is ImageTexture else tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.anchor_left = anclas.x; t.anchor_top = anclas.y; t.anchor_right = anclas.z; t.anchor_bottom = anclas.w
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(t)
	b.move_child(t, orden)
	return t

## Un degradado negro de abajo hacia arriba para que el texto se lea sobre la imagen.
static func _velo(b: Control, indice: int, desde := 0.35) -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.96)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, desde)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 4
	gt.height = 64
	var v := TextureRect.new()
	v.texture = gt
	v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	v.stretch_mode = TextureRect.STRETCH_SCALE
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	b.move_child(v, indice)

## Los colores de la ropa: el de la barra del club (nunca la camiseta blanca de un club de blanco) y su segundo color.
static func _ropa(c: Club) -> Array:
	return [EscaparateBarra.color_de(c).to_html(false), c.color2]

static func _cara(j: Jugador, c: Club) -> Texture2D:
	var r := _ropa(c)
	return Cara.textura(j, String(r[0]), String(r[1]), 512)

## El DT en 3D como cualquier cara del juego (lo mismo que la portada del periódico); sin pantalla, el retrato de siempre.
## Con `true` la tarjeta enseña el avatar del jugador cuando él es el DT (por defecto, el DT propio de cada club: no repetir la misma cara en todos).
static var dt_propio := false

static func _cara_dt(p: Principal, c: Club) -> Texture2D:
	var r := p.mundo.roles
	if r == null:
		return Escudo.textura(c, 256)
	var col := _ropa(c)
	if Retrato3D.disponible():
		## CADA CLUB TIENE SU DT (cara, barba, edad y aspecto propios, estables por club: la semilla es el club). El avatar propio del jugador (`dt_propio`) vive en su ficha.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("dt|" + c.id)
		var asp: Dictionary = load("res://visor/personaje_dt.gd").aleatorio(rng)   ## por ruta: el menú no nombra clases del 3D (memoria del menú)
		if dt_propio and r.dt_empleado.is_empty():
			asp = r.aspecto_3d()
		return Retrato3D.textura_dt(asp, String(col[0]), String(col[1]), 512)
	var look: Dictionary = CaraDT.look_de_nombre(r.dt_nombre()) if not r.dt_empleado.is_empty() else r.look_efectivo()
	return CaraDT.textura(look, 256)

static func _al_fondo(v: VBoxContainer) -> void:
	var hueco := Control.new()
	hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(hueco)

static func dt(p: Principal, c: Club, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Oficina del DT"), acento, func() -> void: TableroInicio.abrir(p, "Mi carrera"), Color(0.06, 0.08, 0.1, 1.0))
	var b: Button = tc[0]
	var v: VBoxContainer = tc[1]
	_escena(b, "despacho", Color(EscaparateBarra.color_de(c)))
	_imagen(b, _cara_dt(p, c), Vector4(0.04, 0.0, 0.96, 1.0), 1)
	_velo(b, 2, 0.5)
	_al_fondo(v)
	var estilo: Dictionary = Previa.dt_de(c)
	var nombre := p.mundo.roles.dt_nombre() if p.mundo.roles != null else ""
	if nombre.length() <= 1:
		nombre = String(estilo.get("nombre", ""))
	var l := EstiloAvanzar.etiqueta(EscaparateFrase.de(p, c, nombre), 16, Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.max_lines_visible = 2
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	v.add_child(l)
	TableroInicio.cerrar(b)
	return b

static func noticia(p: Principal, c: Club, liga: Liga, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Noticias y correo"), acento, func() -> void: TableroInicio.abrir(p, "Correo"), Color(c.color1).darkened(0.7))
	var b: Button = tc[0]
	var v: VBoxContainer = tc[1]
	var n := EscaparateNoticia.de(p, c, liga)
	## (17-11, veredicto del dueño) Sin futbolistas en primer plano con la cara grande: el estadio dibujado en los colores del club y su escudo grande.
	EscaparateArte.poner(b, "estadio", c)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(c, 200)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	esc.anchor_left = 0.62; esc.anchor_right = 0.96; esc.anchor_top = 0.04; esc.anchor_bottom = 0.64
	esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(esc)
	b.move_child(esc, 1)
	_velo(b, 2, 0.45)
	_al_fondo(v)
	var t := EstiloAvanzar.etiqueta(String(n["titulo"]), 24, Color.WHITE, true)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.max_lines_visible = 2
	v.add_child(t)
	var autor := n.get("autor") as Jugador
	var cita := "«%s»%s" % [String(n["cita"]), (" — %s" % Nombres.visible(autor.nombre)) if autor != null else ""]
	var q := EstiloAvanzar.etiqueta(cita, 15, Color(1, 1, 1, 0.85))
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.max_lines_visible = 2
	v.add_child(q)
	TableroInicio.cerrar(b)
	var bandeja: Array = p.get("_bandeja") if p.get("_bandeja") != null else []
	var sin_leer := 0
	for x: Dictionary in bandeja:
		if not bool(x.get("leida", false)):
			sin_leer += 1
	if sin_leer > 0:
		var chip := EstiloAvanzar.etiqueta(Idiomas.t("%d sin leer") % sin_leer, 12, Color.WHITE)
		chip.anchor_left = 1.0; chip.anchor_right = 1.0
		chip.offset_left = -110; chip.offset_right = -14; chip.offset_top = 8; chip.offset_bottom = 26
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.add_child(chip)
	return b

## La tabla de diez filas: posición, escudo, club y puntos, en letra grande y con aire. Si vas por debajo del 10.º, tu fila sustituye a la última.
static func tabla(p: Principal, c: Club, liga: Liga, acento: Color) -> Control:
	var base := EscaparateZonas.color_liga(liga)
	var tc := TableroInicio.tarjeta(Idiomas.t("Tabla de posiciones"), acento, func() -> void: TableroInicio.abrir(p, "Ligas y clubes"), base.darkened(0.35))
	var b: Button = tc[0]
	var v: VBoxContainer = tc[1]
	v.add_theme_constant_override("separation", 0)
	if liga == null:
		TableroInicio.cerrar(b)
		return b
	var cab := HBoxContainer.new()   ## arriba: el símbolo recreado de la liga, su nombre y la leyenda mínima de las zonas
	cab.add_theme_constant_override("separation", 8)
	cab.add_child(EscaparateZonas.simbolo(liga, 26))
	var nl := EstiloAvanzar.etiqueta(liga.nombre, 17, Color.WHITE, true)
	nl.clip_text = true
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.custom_minimum_size.x = 60
	cab.add_child(nl)
	var t: Array = liga.tabla()
	var zonas := EscaparateZonas.de(liga, t.size())
	for z: Dictionary in EscaparateZonas.leyenda(zonas):
		var pt := ColorRect.new()
		pt.color = z["color"]
		pt.custom_minimum_size = Vector2(9, 9)
		pt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cab.add_child(pt)
		var lg := EstiloAvanzar.etiqueta(String(z["nombre"]), 11, Color(1, 1, 1, 0.85))
		lg.tooltip_text = String(z["largo"])
		cab.add_child(lg)
	v.add_child(cab)
	var mio := 0
	for i in t.size():
		if t[i]["club"] == c:
			mio = i
	var filas: Array = range(mini(9, t.size()))
	for i: int in filas:
		_fila(v, t, i, c, acento, zonas[i])
	if mio >= 9:   ## fuera de las primeras: una línea fina y tu fila, resaltada
		var linea := ColorRect.new()
		linea.color = Color(1, 1, 1, 0.3)
		linea.custom_minimum_size = Vector2(0, 1)
		v.add_child(linea)
		_fila(v, t, mio, c, acento, zonas[mio])
	elif t.size() > 9:
		_fila(v, t, 9, c, acento, zonas[9])
	TableroInicio.cerrar(b)
	return b

static func _fila(v: VBoxContainer, t: Array, i: int, c: Club, acento: Color, zona: Dictionary = {}) -> void:
	var club: Club = t[i]["club"]
	var col := acento.lightened(0.35) if club == c else Color.WHITE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if club == c:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(acento, 0.16)
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", sb)
		pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pc.add_child(h)
		v.add_child(pc)
	else:
		v.add_child(h)
	var barra := ColorRect.new()   ## la barrita de la zona (continental con el color de su torneo, rojo en el descenso) y, para el líder, el oro
	barra.color = zona.get("color", Color(0, 0, 0, 0))
	barra.custom_minimum_size = Vector2(4, 0)
	h.add_child(barra)
	h.move_child(barra, 0)
	if i == 0:
		col = EscaparateZonas.ORO
	elif String(zona.get("clave", "")) == "descenso":
		col = EscaparateZonas.ROJO.lightened(0.25)
	var pos := EstiloAvanzar.etiqueta("%d" % (i + 1), 15, col, true)
	pos.custom_minimum_size.x = 30
	pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pos)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(club, 22)
	esc.custom_minimum_size = Vector2(22, 22)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	esc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(esc)
	var n := EstiloAvanzar.etiqueta(club.nombre, 15, col, true)
	n.clip_text = true
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	var pts := EstiloAvanzar.etiqueta("%d" % int(t[i]["pts"]), 16, col, true)
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pts)

## «Despacho»: los asuntos que esperan una decisión del DT (un jugador que te busca, la prensa, el personal, la zona gris, una crisis económica, lo que pasa en casa…), con ALERTA si hay.
## Abre la pantalla completa del despacho (`EscaparatePantalla.abrir_despacho`).
static func despacho(p: Principal, c: Club, acento: Color) -> Control:
	var n: int = p._ui_despacho.asuntos_pendientes().size() if p._ui_despacho != null else 0
	var tc := TableroInicio.tarjeta(Idiomas.t("Despacho"), acento, func() -> void: EscaparatePantalla.de(p).abrir_despacho(p), Color(0.05, 0.07, 0.09, 1.0))
	var b: Button = tc[0]
	var v: VBoxContainer = tc[1]
	EscaparateArte.poner(b, "despacho_%d" % (0 if n == 0 else (1 if n <= 2 else 2)), c)   ## tres estados del escritorio
	_velo(b, 1, 0.3)
	_al_fondo(v)
	var cont := EstiloAvanzar.etiqueta(("● %d" % n) if n > 0 else "0", 44, Color("ffc857") if n > 0 else Color.WHITE, true)
	cont.add_theme_constant_override("outline_size", 6)
	cont.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	v.add_child(cont)
	var t := EstiloAvanzar.etiqueta(Idiomas.t("asuntos por decidir") if n > 0 else Idiomas.t("Sin asuntos pendientes"), 15, Color.WHITE)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.max_lines_visible = 2
	t.add_theme_constant_override("outline_size", 4)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	v.add_child(t)
	if n == 0:   ## sin asuntos, la tarjeta sirve: el próximo hito del calendario y los accesos rápidos (favoritos de Ajustes)
		var hito := EventosFecha.hito(p.mundo, p._dia_semana)
		var h := EstiloAvanzar.etiqueta("▸ " + String(hito.get("texto", "")), 13, Color(1, 1, 1, 0.85))
		h.clip_text = true
		v.add_child(h)
		if not p._favoritos.is_empty():
			var fv := EstiloAvanzar.etiqueta("⭐ " + " · ".join(PackedStringArray(p._favoritos.map(func(x: String) -> String: return Idiomas.t(x)))), 13, Color(1, 1, 1, 0.85))
			fv.clip_text = true
			v.add_child(fv)
	TableroInicio.cerrar(b)
	return b
