class_name Portada
extends "res://ui/portada_p1.gd"
## [Capa 2/2 de `portada.gd`] svg_de, textura

static func svg_de(k: String) -> String:
	var clave := k
	var r_svg_de_1: Variant = _svg_de_1(clave)
	if r_svg_de_1 != null:
		return r_svg_de_1
	var r_svg_de_2: Variant = _svg_de_2(clave)
	if r_svg_de_2 != null:
		return r_svg_de_2
	var r_svg_de_3: Variant = _svg_de_3(clave)
	if r_svg_de_3 != null:
		return r_svg_de_3
	return _clasica()

static func _svg_de_1(clave: String) -> Variant:
	match clave:
		"nocturna": return _nocturna()
		"retro": return _retro()
		"prensa": return _prensa()
		"neon": return _neon()
		"tifo": return _tifo()
		"trofeo": return _trofeo()
		"pizarra": return _pizarra()
		"minimal": return _minimal()
	return null

static func _svg_de_2(clave: String) -> Variant:
	match clave:
		"andino": return _andino()
		"vestuario": return _vestuario()
		"cabina": return _cabina()
		"ejecutiva": return _ejecutiva()
		"tunel": return _tunel()
		"lluvia": return _lluvia()
		"datos": return _datos()
		"graffiti": return _graffiti()
	return null

static func _svg_de_3(clave: String) -> Variant:
	match clave:
		"marmol": return _marmol()
	return null


## La portada rasterizada. Se cachea: son 430 círculos en la nocturna y no hay
## que volver a dibujarlos cada vez que se repinta el menú.
static func textura(k: String, ancho_px: int = 1200) -> Texture2D:
	var clave := "%s_%d" % [k, ancho_px]
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(k), float(ancho_px) / float(W)) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t
