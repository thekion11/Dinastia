class_name CasillaClara
extends RefCounted
## CASILLAS QUE SE VEN SOBRE FONDO OSCURO (12-11). La casilla del tema (un cuadro gris oscuro) casi desaparece sobre la paleta azul noche de
## los eventos a pantalla completa: en la convocatoria de la selección no se distinguía la sin marcar. `estilar(cb)` le pone dos iconos
## propios, dibujados una vez: sin marcar = marco claro; marcada = cuadro dorado con la palomita oscura.
const LADO := 22
static var _iconos := {}

static func estilar(cb: CheckBox, color := Color("d9b23a")) -> void:
	cb.add_theme_icon_override("unchecked", _icono(false, color))
	cb.add_theme_icon_override("checked", _icono(true, color))
	cb.add_theme_constant_override("h_separation", 8)

static func _icono(marcada: bool, color: Color) -> ImageTexture:
	var k := "%s|%s" % [marcada, color.to_html(false)]
	if _iconos.has(k):
		return _iconos[k]
	var img := Image.create(LADO, LADO, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in LADO:
		for x in LADO:
			var borde := mini(mini(x, y), mini(LADO - 1 - x, LADO - 1 - y))
			var esquina := (x < 2 or x > LADO - 3) and (y < 2 or y > LADO - 3)
			if esquina:
				continue
			if marcada:
				img.set_pixel(x, y, color)
			elif borde < 2:
				img.set_pixel(x, y, Color(1, 1, 1, 0.75))
			else:
				img.set_pixel(x, y, Color(1, 1, 1, 0.06))
	if marcada:   ## la palomita: dos trazos de 3 px
		var tinta := Color(0.08, 0.07, 0.03)
		for i in 5:
			for g in 3:
				img.set_pixel(5 + i, 11 + i + g - 1, tinta)
		for i in 9:
			for g in 3:
				img.set_pixel(9 + i, 15 - i + g - 1, tinta)
	var tex := ImageTexture.create_from_image(img)
	_iconos[k] = tex
	return tex
