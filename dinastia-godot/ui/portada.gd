class_name Portada
extends "res://ui/portada_p1.gd"
## [Capa 2/2 de `portada.gd`] svg_de, textura

static func svg_de(k: String) -> String:
	match k:
		"nocturna": return _nocturna()
		"retro": return _retro()
		"prensa": return _prensa()
		"neon": return _neon()
		"tifo": return _tifo()
		"trofeo": return _trofeo()
		"pizarra": return _pizarra()
		"minimal": return _minimal()
		"andino": return _andino()
		"vestuario": return _vestuario()
		"cabina": return _cabina()
		"ejecutiva": return _ejecutiva()
		"tunel": return _tunel()
		"lluvia": return _lluvia()
		"datos": return _datos()
		"graffiti": return _graffiti()
		"marmol": return _marmol()
	return _clasica()

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
