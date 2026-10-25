class_name Escudo
extends "res://ui/escudo_p1.gd"
## [Capa 2/2 de `escudo.gd`] textura, limpiar_cache

## El escudo ya rasterizado, listo para meter en un TextureRect.
##
## Se rasteriza a 4x y se deja que el control lo encoja: a 1x los bordes curvos
## salen dentados, y a 4x se ven limpios en cualquier tamaño de la interfaz.
static func textura(c: Club, alto_px: int = 26) -> Texture2D:
	## Especial primero: si el club eligio uno Y sigue desbloqueado, manda por
	## encima del generador procedural. `textura_especial()` ya resuelve el
	## caso "ya no desbloqueado" devolviendo null, así que cae solo al
	## procedural de mas abajo sin ningun chequeo extra aqui.
	if c.esc_especial != "":
		var esp := textura_especial(c.esc_especial)
		if esp != null:
			return esp
	## LA CLAVE LLEVA LOS COLORES Y LA FORMA. Antes era solo el id y el tamaño,
	## asi que cambiar el escudo en la pantalla de identidad no repintaba nada:
	## la cache seguia devolviendo el escudo viejo hasta reiniciar el juego.
	## Y EL NOMBRE: las iniciales del escudo salen de él, y el mismo `c.id`
	## tiene otro nombre según la partida use la base ficticia o el pack real.
	var clave := "%s_%s_%d_%s_%s_%s_%s" % [c.id, c.nombre, alto_px,
		c.color_escudo1(), c.color_escudo2(), forma_de(c), patron_de(c)]
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(c), float(alto_px) * 4.0 / 70.0) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t

## M-066 (25-10-2026): el escudo en UNA tinta -negro y blanco para periódico,
## fotocopia o marcador de un solo color-. Sale del mismo SVG: cada píxel pasa a
## `tinta` o a blanco según su luminosidad, y el contorno (alfa) no cambia.
static func textura_mono(c: Club, alto_px: int = 26, tinta: Color = Color.BLACK) -> Texture2D:
	var clave := "mono_%s_%s_%d_%s_%s_%s_%s" % [c.id, c.nombre, alto_px,
		c.color_escudo1(), c.color_escudo2(), forma_de(c), patron_de(c)] + tinta.to_html()
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(c), float(alto_px) * 4.0 / 70.0) != OK:
		return null
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a <= 0.0:
				continue
			var base := tinta if p.get_luminance() < 0.55 else Color.WHITE
			img.set_pixel(x, y, Color(base.r, base.g, base.b, p.a))
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t

## Se vacía al empezar otra partida: los colores de un club pueden cambiar entre
## mundos y una caché con el id como clave los serviría del mundo anterior.
static func limpiar_cache() -> void:
	_cache.clear()
