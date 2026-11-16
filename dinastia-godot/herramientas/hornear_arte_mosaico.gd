extends SceneTree
## EL ARTE DE LAS TARJETAS DEL MOSAICO CENTRAL (16-11, frente 1). Renders PROPIOS de las salas del club (vestuario, oficina del DT,
## despacho del presidente, museo, sala de vídeo) sacados con `pruebas/captura_edificio_club.tscn` (COMPLETA=1 SIN_AVATAR=1) y
## convertidos aquí en imágenes MUY pequeñas en escala de grises: la tarjeta las tiñe con el color del mundo de juego
## (`ColorMundo`), así que sirven para cualquier club (no llevan sus colores) y a 192x108 no se lee ningún texto de la escena.
##   godot --headless --path . --script res://herramientas/hornear_arte_mosaico.gd -- <carpeta con sala_0.png…sala_4.png>
## Salida: res://assets/ui/mosaico/<nombre>.jpg (~5-9 KB cada una).

const NOMBRES := ["vestuario", "oficina", "despacho", "museo", "video"]
const ANCHO := 192
const ALTO := 108
const RECORTE := 0.07   ## se quita el borde (los iconos de la esquina y el aviso «E» de la sala)

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("falta la carpeta de origen")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://assets/ui/mosaico")
	for i in NOMBRES.size():
		var img := Image.load_from_file(String(args[0]).path_join("sala_%d.png" % i))
		if img == null:
			print("no está sala_%d.png" % i)
			continue
		var w := img.get_width()
		var h := img.get_height()
		var r := Rect2i(int(w * RECORTE), int(h * RECORTE), int(w * (1.0 - 2.0 * RECORTE)), int(h * (1.0 - 2.0 * RECORTE)))
		img = img.get_region(r)
		img.resize(ANCHO, ALTO, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGB8)
		for y in ALTO:
			for x in ANCHO:
				var c := img.get_pixel(x, y)
				var l := c.get_luminance()
				img.set_pixel(x, y, Color(l, l, l))
		var ruta := "res://assets/ui/mosaico/%s.jpg" % NOMBRES[i]
		img.save_jpg(ProjectSettings.globalize_path(ruta), 0.72)
		print("%s (%d bytes)" % [ruta, FileAccess.get_file_as_bytes(ruta).size()])
	quit()
