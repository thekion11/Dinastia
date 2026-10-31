class_name ImagenEnDisco
extends RefCounted
## TEXTURAS HECHAS POR CÓDIGO, GUARDADAS EN DISCO (30-10-2026, rendimiento). Para las que se pintan
## píxel a píxel en GDScript y salen siempre iguales para los mismos parámetros (el asfalto de la
## ciudad: 3 ruidos de 512² y 262.144 píxeles por tono, en cada sesión). La primera vez se crea y se
## guarda (PNG sin pérdida); las siguientes se lee y se le rehacen los mipmaps con el mismo algoritmo
## (bytes idénticos, ver `pruebas/probar_imagen_en_disco.tscn`). La clave lleva la huella del script
## que la pinta: si cambia el código, se vuelve a crear.

## `crear` devuelve la textura como siempre (con mipmaps).
static func textura(clave: String, script: String, crear: Callable) -> ImageTexture:
	var en_disco := "%s|%s" % [clave, CacheDisco.huella("img|" + script, PackedStringArray([script]))]
	var img := CacheDisco.cargar_imagen(en_disco)
	if img != null:
		img.generate_mipmaps()
		return ImageTexture.create_from_image(img)
	var tex: ImageTexture = crear.call()
	CacheDisco.guardar_imagen(en_disco, tex.get_image())
	return tex
