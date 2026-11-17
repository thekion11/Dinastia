class_name EscaparateTarjetas
extends RefCounted
## LAS TRES TARJETAS GRANDES DE ARRIBA DEL ESCAPARATE (17-11-2026; Liga Master del PES 2020): el DT con su frase táctica, la NOTICIA con escena (dos futbolistas del club) y la
## TABLA de diez filas con escudo. Son `TableroInicio.tarjeta` (botón entero, foco de mando, campana de avisos): lo que cambia es que la IMAGEN manda y el texto es grande y corto.

static func _imagen(b: Control, tex: Texture2D, anclas: Vector4, atras := true) -> TextureRect:
	var t := TextureRect.new()
	var recorte := AtlasTexture.new()   ## el busto cuadrado entra en una tarjeta apaisada: se enseña su parte de arriba (cabeza y hombros), no el centro
	recorte.atlas = tex
	recorte.region = Rect2(0, 0, 256, 186)
	t.texture = recorte if tex is ImageTexture else tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.anchor_left = anclas.x; t.anchor_top = anclas.y; t.anchor_right = anclas.z; t.anchor_bottom = anclas.w
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(t)
	if atras:
		b.move_child(t, 0)
	return t

## Un degradado negro de abajo hacia arriba para que el texto se lea sobre la imagen.
static func _velo(b: Control, imagenes := 1, desde := 0.35) -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.94)])
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
	b.move_child(v, imagenes)   ## justo encima de las imágenes y debajo del texto

static func _cara(j: Jugador, c: Club) -> Texture2D:
	return Cara.textura(j, c.color1, c.color2, 256)

## El DT en 3D como cualquier cara del juego (lo mismo que la portada del periódico); sin pantalla, el retrato de siempre.
static func _cara_dt(p: Principal, c: Club) -> Texture2D:
	var r := p.mundo.roles
	if r == null:
		return Escudo.textura(c, 256)
	if Retrato3D.disponible():
		var asp: Dictionary = r.aspecto_3d()
		if not r.dt_empleado.is_empty():
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(r.dt_nombre())
			asp = load("res://visor/personaje_dt.gd").aleatorio(rng)   ## por ruta: el menú no nombra clases del 3D (memoria del menú)
		return Retrato3D.textura_dt(asp, c.color1, c.color2, 256)
	var look: Dictionary = CaraDT.look_de_nombre(r.dt_nombre()) if not r.dt_empleado.is_empty() else r.look_efectivo()
	return CaraDT.textura(look, 256)

static func _al_fondo(v: VBoxContainer) -> void:
	var hueco := Control.new()
	hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(hueco)

static func dt(p: Principal, c: Club, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Oficina del DT"), acento, func() -> void: TableroInicio.abrir(p, "Mi carrera"), Color(0.93, 0.94, 0.96, 1.0))
	var b: Button = tc[0]
	var v: VBoxContainer = tc[1]
	_imagen(b, _cara_dt(p, c), Vector4(0, 0, 1, 0.74))
	_velo(b, 1, 0.5)
	_al_fondo(v)
	var estilo: Dictionary = Previa.dt_de(c)
	var frase := String(estilo.get("descripcion", ""))
	var nombre := p.mundo.roles.dt_nombre() if p.mundo.roles != null else ""
	if nombre.length() <= 1:
		nombre = String(estilo.get("nombre", ""))
	var l := EstiloAvanzar.etiqueta(Idiomas.t("%s: %s") % [nombre, frase] if frase != "" else nombre, 17, Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.max_lines_visible = 2
	v.add_child(l)
	var dir := p.mundo.directiva
	if dir != null and String(dir.objetivo) != "":
		var o := EstiloAvanzar.etiqueta("%s · %s %d" % [Idiomas.t(String(dir.objetivo)), Idiomas.t("confianza"), c.confianza], 13, Color(1, 1, 1, 0.78))
		o.clip_text = true
		v.add_child(o)
	TableroInicio.cerrar(b)
	return b

static func noticia(p: Principal, c: Club, liga: Liga, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Noticias"), acento, func() -> void: TableroInicio.abrir(p, "Correo"), Color(c.color1).darkened(0.7))
	var b: Button = tc[0]
	var v: VBoxContainer = tc[1]
	var n := EscaparateNoticia.de(p, c, liga)
	var js: Array = n.get("jugadores", [])
	if js.size() >= 2:   ## la escena: dos futbolistas del club con la chaqueta del club, uno a cada lado, mirándose
		_imagen(b, _cara(js[1], c), Vector4(0.0, 0.0, 0.58, 0.74))
		_imagen(b, _cara(js[0], c), Vector4(0.42, 0.0, 1.0, 0.74))
	elif js.size() == 1:
		_imagen(b, _cara(js[0], c), Vector4(0.3, 0.0, 0.8, 0.74))
	_velo(b, mini(js.size(), 2), 0.45)
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
	var tc := TableroInicio.tarjeta(Idiomas.t("Tabla de posiciones"), acento, func() -> void: TableroInicio.abrir(p, "Ligas y clubes"))
	var b: Button = tc[0]
	var v: VBoxContainer = tc[1]
	v.add_theme_constant_override("separation", 0)
	if liga == null:
		TableroInicio.cerrar(b)
		return b
	var t: Array = liga.tabla()
	var filas: Array = range(mini(10, t.size()))
	var mio := 0
	for i in t.size():
		if t[i]["club"] == c:
			mio = i
	if mio >= 10 and not filas.is_empty():
		filas[filas.size() - 1] = mio
	for i: int in filas:
		var club: Club = t[i]["club"]
		var col := acento.lightened(0.35) if club == c else Color.WHITE
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		h.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
		v.add_child(h)
	TableroInicio.cerrar(b)
	return b
