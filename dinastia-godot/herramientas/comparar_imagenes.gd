extends SceneTree
## Compara imágenes con una base: PSNR (dB; más alto = más parecida) y diferencia media por canal.
##   godot --headless --path . -s res://herramientas/comparar_imagenes.gd -- base.jpg otra1.jpg otra2.jpg
## Se usó (14-11) para ver cuánto cambia la imagen al sustituir el MSAA x4 por TAA/FSR en ULTRA.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("uso: -s comparar_imagenes.gd -- base.jpg otra.jpg [otra2.jpg ...]")
		quit(2)
		return
	var base := Image.load_from_file(args[0])
	base.convert(Image.FORMAT_RGB8)
	for i in range(1, args.size()):
		var otra := Image.load_from_file(args[i])
		otra.convert(Image.FORMAT_RGB8)
		var suma := 0.0
		var abs_sum := 0.0
		var n := 0
		for y in range(0, base.get_height(), 1):
			for x in range(0, base.get_width(), 1):
				var a := base.get_pixel(x, y)
				var b := otra.get_pixel(x, y)
				var d := (a.r - b.r) * 255.0
				var e := (a.g - b.g) * 255.0
				var f := (a.b - b.b) * 255.0
				suma += d * d + e * e + f * f
				abs_sum += absf(d) + absf(e) + absf(f)
				n += 3
		var mse := suma / n
		var psnr := 99.0 if mse < 0.0001 else 10.0 * log(255.0 * 255.0 / mse) / log(10.0)
		print("%s  PSNR=%.2f dB  dif.media=%.2f/255" % [args[i].get_file(), psnr, abs_sum / n])
	quit()
