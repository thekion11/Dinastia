class_name EscudoTexto
extends RefCounted
## EL ESCUDO CON SU SÍMBOLO O SUS INICIALES YA PINTADOS (2-11-2026, queja del dueño: «los símbolos del
## escudo no aparecen»). El rasterizador de SVG de Godot no dibuja `<text>`, así que `Escudo.textura`
## sale sin símbolo ni letras y las pantallas lo ponen con una etiqueta encima. Donde no se puede poner
## una etiqueta (la camiseta, la pantalla de carga, las miniaturas, la vista previa de configuración)
## el escudo salía vacío. Aquí se hornea el texto en la propia imagen, con los glifos del TextServer.
##   EscudoTexto.textura(club, alto)  → Texture2D con símbolo o iniciales dentro.
## NO usar donde ya se superpone una etiqueta (saldría doble).

static var _cache: Dictionary = {}

static func textura(c: Club, alto_px: int = 64) -> Texture2D:
	var simbolo := Escudo.simbolo_de(c)
	var texto := simbolo if simbolo != "" else Escudo.iniciales(c)
	if c.esc_especial != "" and Escudo.textura_especial(c.esc_especial) != null:
		return Escudo.textura(c, alto_px)   ## los especiales ya traen su dibujo
	## Sin símbolo elegido, el escudo ya trae su figura y sus letras (`EscudoEmblemas`): se deja como está.
	if simbolo == "":
		return Escudo.textura(c, alto_px)
	var tinta := Color.WHITE if Color(c.color_escudo1()).get_luminance() < 0.5 else Color("1a1a1a")
	var clave := "%s|%s|%d|%s|%s|%s|%s|%s" % [c.id, texto, alto_px, c.color_escudo1(), c.color_escudo2(),
		Escudo.forma_de(c), Escudo.patron_de(c), c.nombre]
	if _cache.has(clave):
		return _cache[clave]
	## El símbolo REEMPLAZA a la figura: se rasteriza el escudo sin ella y el símbolo va en el centro.
	var img := Image.new()
	var antes := EscudoEmblemas.activo
	EscudoEmblemas.activo = false
	var ok := img.load_svg_from_string(Escudo.svg_de(c), float(alto_px) * 4.0 / 70.0)
	EscudoEmblemas.activo = antes
	if ok != OK:
		return Escudo.textura(c, alto_px)
	img.convert(Image.FORMAT_RGBA8)
	var px := int(img.get_height() * 0.42)
	var centro := Vector2(img.get_width() * 0.5, img.get_height() * 0.5)
	pintar_texto(img, texto, px, centro, tinta)
	var t := ImageTexture.create_from_image(img)
	if _cache.size() > 300:
		_cache.clear()
	_cache[clave] = t
	return t

## Dibuja `texto` centrado en `centro` sobre `img`, con la fuente del tema (y la de reserva del sistema
## para los emojis). Los glifos en color (emoji) se copian tal cual; los monocromos se tiñen con `tinta`.
static func pintar_texto(img: Image, texto: String, tam: int, centro: Vector2, tinta: Color) -> void:
	var ts := TextServerManager.get_primary_interface()
	var fuente: Font = ThemeDB.get_default_theme().default_font if ThemeDB.get_default_theme().has_default_font() else ThemeDB.fallback_font
	var sid := ts.create_shaped_text()
	ts.shaped_text_add_string(sid, texto, fuente.get_rids(), tam)
	ts.shaped_text_shape(sid)
	var glifos: Array = ts.shaped_text_get_glyphs(sid)
	var ancho := 0.0
	for g: Dictionary in glifos:
		ancho += float(g["advance"])
	var asc := ts.shaped_text_get_ascent(sid)
	var desc := ts.shaped_text_get_descent(sid)
	var piezas: Array = []
	var x := centro.x - ancho * 0.5
	var y := centro.y - (asc + desc) * 0.5 + asc
	for g: Dictionary in glifos:
		var rid: RID = g["font_rid"]
		var idx := int(g["index"])
		var tam_f := Vector2i(int(g.get("font_size", tam)), 0)
		if idx != 0 and rid.is_valid():
			ts.font_render_glyph(rid, tam_f, idx)
			var ti := ts.font_get_glyph_texture_idx(rid, tam_f, idx)
			if ti >= 0:
				var atlas := ts.font_get_texture_image(rid, tam_f, ti)
				var uv := ts.font_get_glyph_uv_rect(rid, tam_f, idx)
				var off := ts.font_get_glyph_offset(rid, tam_f, idx)
				if atlas != null and not atlas.is_empty() and uv.size.x > 0.0:
					var color_real := atlas.get_format() == Image.FORMAT_RGBA8 and ts.font_is_multichannel_signed_distance_field(rid) == false and _es_color(atlas, uv)
					var origen := Vector2(x + float(g["offset"].x) + off.x, y + float(g["offset"].y) - (-off.y))
					piezas.append([atlas, Rect2i(uv), origen, color_real])
		x += float(g["advance"])
	ts.free_rid(sid)
	## Se centra por lo que de verdad se ve (la caja de los glifos), no por las métricas de la fuente.
	if piezas.is_empty():
		return
	var caja := Rect2((piezas[0][2] as Vector2), Vector2((piezas[0][1] as Rect2i).size))
	for pz: Array in piezas:
		caja = caja.merge(Rect2(pz[2] as Vector2, Vector2((pz[1] as Rect2i).size)))
	## Se compone en una imagen aparte y se ESCALA al tamaño pedido (los emojis de color vienen con un
	## tamaño fijo de la fuente y no obedecen al tamaño del texto).
	var tmp := Image.create(maxi(int(ceil(caja.size.x)), 1), maxi(int(ceil(caja.size.y)), 1), false, Image.FORMAT_RGBA8)
	for pz: Array in piezas:
		_copiar(tmp, pz[0] as Image, pz[1] as Rect2i, Vector2i((pz[2] as Vector2) - caja.position), tinta, bool(pz[3]), true)
	var k := float(tam) / float(maxi(tmp.get_width(), tmp.get_height()))
	tmp.resize(maxi(int(tmp.get_width() * k), 1), maxi(int(tmp.get_height() * k), 1), Image.INTERPOLATE_LANCZOS)
	var dest := Vector2i(centro - Vector2(tmp.get_size()) * 0.5)
	for j in tmp.get_height():
		for i in tmp.get_width():
			var dx := dest.x + i
			var dy := dest.y + j
			if dx < 0 or dy < 0 or dx >= img.get_width() or dy >= img.get_height():
				continue
			var p := tmp.get_pixel(i, j)
			if p.a > 0.0 and img.get_pixel(dx, dy).a > 0.0:
				img.set_pixel(dx, dy, img.get_pixel(dx, dy).blend(p))

## ¿El glifo trae color propio (un emoji) o solo cobertura? Un monocromo tiene R=G=B en todo el glifo.
static func _es_color(atlas: Image, uv: Rect2) -> bool:
	var r := Rect2i(uv)
	for j in range(r.position.y, r.end.y, 2):
		for i in range(r.position.x, r.end.x, 2):
			if i < atlas.get_width() and j < atlas.get_height():
				var p := atlas.get_pixel(i, j)
				if p.a > 0.2 and (absf(p.r - p.g) > 0.06 or absf(p.g - p.b) > 0.06):
					return true
	return false

static func _copiar(img: Image, atlas: Image, fuente: Rect2i, destino: Vector2i, tinta: Color, en_color: bool, libre := false) -> void:
	for j in fuente.size.y:
		for i in fuente.size.x:
			var sx := fuente.position.x + i
			var sy := fuente.position.y + j
			var dx := destino.x + i
			var dy := destino.y + j
			if sx >= atlas.get_width() or sy >= atlas.get_height() or dx < 0 or dy < 0 or dx >= img.get_width() or dy >= img.get_height():
				continue
			var p := atlas.get_pixel(sx, sy)
			if p.a <= 0.0:
				continue
			var c := p if en_color else Color(tinta.r, tinta.g, tinta.b, p.a)
			var d := img.get_pixel(dx, dy)
			if d.a <= 0.0 and not libre:
				continue   ## solo dentro del escudo
			img.set_pixel(dx, dy, c if libre else d.blend(c))
