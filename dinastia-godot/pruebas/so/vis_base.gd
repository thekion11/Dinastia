extends BaseSO
## BASE DE LAS PRUEBAS DE VISUALIZACIÓN (5-11-2026). Fotografía el viewport REAL (con el renderizador que se pidió: Forward+ o Compatibilidad),
## comprueba que no está vacío (no es todo un color, tiene contraste y variedad), lo guarda en JPG y lo compara por cuadrículas con su
## referencia `pruebas/so/referencias/<nombre>_<método>.jpg` (hechas con `VISUAL=referencias`). La referencia es por método de render porque
## Forward+ y Compatibilidad no pintan igual; la comparación es burda a propósito (la GPU, el driver y el antialiasing mueven el detalle).
const REFS := "res://pruebas/so/referencias/"
const CUADRICULA := Vector2i(16, 9)
const TOLERANCIA_CELDA := 0.14      ## diferencia media (0..1) de una celda para darla por cambiada
const MAX_CELDAS_CAMBIADAS := 0.25  ## fracción de celdas que pueden cambiar antes de FALLO

func _metodo() -> String:
	return String(RenderingServer.get_current_rendering_method())   ## forward_plus · mobile · gl_compatibility

func _salida() -> String:
	var d := "user://so_capturas"
	DirAccess.make_dir_recursive_absolute(d)
	return d

func _foto() -> Image:
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	return img

## Estadísticas de una imagen: {desv: desviación típica de la luminancia 0..1, colores: colores distintos (cuantizados a 4 bits por canal), dominante: fracción del color más común}.
func _estadisticas(img: Image) -> Dictionary:
	var p := img.duplicate() as Image
	p.resize(96, 54, Image.INTERPOLATE_BILINEAR)
	var n := 96 * 54
	var suma := 0.0
	var suma2 := 0.0
	var cubos := {}
	for y in 54:
		for x in 96:
			var c := p.get_pixel(x, y)
			var l := c.get_luminance()
			suma += l
			suma2 += l * l
			var k := (int(c.r * 15.0) << 8) | (int(c.g * 15.0) << 4) | int(c.b * 15.0)
			cubos[k] = int(cubos.get(k, 0)) + 1
	var media := suma / n
	var mayor := 0
	for k in cubos:
		mayor = maxi(mayor, int(cubos[k]))
	return {"desv": sqrt(maxf(0.0, suma2 / n - media * media)), "colores": cubos.size(), "dominante": float(mayor) / n, "media": media}

func _no_vacia(img: Image, que: String) -> void:
	var e := _estadisticas(img)
	_comprobar(img.get_width() >= 320 and img.get_height() >= 180, "%s: la imagen mide %dx%d" % [que, img.get_width(), img.get_height()])
	_comprobar(float(e["desv"]) > 0.03, "%s: tiene contraste (desviación %.3f)" % [que, e["desv"]])
	_comprobar(int(e["colores"]) >= 25, "%s: tiene variedad de color (%d tonos)" % [que, e["colores"]])
	_comprobar(float(e["dominante"]) < 0.8, "%s: ningún color ocupa más del 80 %% (el mayor, %.0f %%)" % [que, float(e["dominante"]) * 100.0])

## Guarda la captura en JPG; con VISUAL=referencias guarda además la referencia (solo desde el proyecto, no desde un export).
func _guardar(img: Image, nombre: String) -> String:
	var ruta := _salida().path_join("%s_%s_%s.jpg" % [nombre, _metodo(), sistema()])
	img.save_jpg(ruta, 0.85)
	_comprobar(FileAccess.file_exists(ruta) and FileAccess.get_file_as_bytes(ruta).size() > 1500, "%s: captura JPG guardada (%s)" % [nombre, ruta.get_file()])
	if OS.get_environment("VISUAL") == "referencias" and OS.has_feature("editor"):
		var r := img.duplicate() as Image
		r.resize(320, 180, Image.INTERPOLATE_LANCZOS)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REFS))
		r.save_jpg(ProjectSettings.globalize_path(REFS + "%s_%s.jpg" % [nombre, _metodo()]), 0.85)
		print("  REFERENCIA nueva: %s_%s.jpg" % [nombre, _metodo()])
	return ruta

func _celdas(img: Image) -> Array:
	var p := img.duplicate() as Image
	p.convert(Image.FORMAT_RGB8)
	p.resize(CUADRICULA.x * 8, CUADRICULA.y * 8, Image.INTERPOLATE_BILINEAR)
	var out: Array = []
	for cy in CUADRICULA.y:
		for cx in CUADRICULA.x:
			var s := Vector3.ZERO
			for y in 8:
				for x in 8:
					var c := p.get_pixel(cx * 8 + x, cy * 8 + y)
					s += Vector3(c.r, c.g, c.b)
			out.append(s / 64.0)
	return out

func _comparar(img: Image, nombre: String) -> void:
	var ruta := REFS + "%s_%s.jpg" % [nombre, _metodo()]
	if OS.get_environment("VISUAL") == "referencias":
		return
	if not FileAccess.file_exists(ruta):
		_comprobar(false, "%s: falta la referencia %s (hazla con VISUAL=referencias herramientas/pruebas_so.py %s)" % [nombre, ruta.get_file(), _nombre()])
		return
	var ref := Image.load_from_file(ruta)
	var a := _celdas(img)
	var b := _celdas(ref)
	var cambiadas := 0
	for i in a.size():
		if (a[i] - b[i]).abs().length() / 1.7320508 > TOLERANCIA_CELDA:
			cambiadas += 1
	var fr := float(cambiadas) / a.size()
	_comprobar(fr <= MAX_CELDAS_CAMBIADAS, "%s: igual que su referencia (%d de %d celdas cambiaron, %.0f %%; tope %.0f %%)" % [nombre, cambiadas, a.size(), fr * 100.0, MAX_CELDAS_CAMBIADAS * 100.0])
