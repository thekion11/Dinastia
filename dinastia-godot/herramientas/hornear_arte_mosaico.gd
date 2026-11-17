extends SceneTree
## EL ARTE DE LAS TARJETAS DEL MOSAICO CENTRAL (16-11, frente 1). Renders PROPIOS de las salas del club (vestuario, oficina del DT,
## despacho del presidente, museo, sala de vídeo; `pruebas/captura_edificio_club.tscn` con COMPLETA=1 SIN_AVATAR=1) y del estadio
## (`pruebas/captura_estadio.tscn`, plano a ras de césped: `estadio_3.png`; el túnel sale del centro del vestuario), siempre con la BASE
## FICTICIA (sin el pack real: `APPDATA=<carpeta vacía>` en Windows, o un user:// sin `ajustes.cfg` con `base_real=true`), y
## convertidos aquí en imágenes MUY pequeñas en escala de grises: la tarjeta las tiñe con el color del mundo de juego
## (`ColorMundo`), así que sirven para cualquier club (no llevan sus colores) y a 192x108 no se lee ningún texto de la escena.
##   godot --headless --path . --script res://herramientas/hornear_arte_mosaico.gd -- <carpeta con sala_0.png…sala_4.png y estadio_3.png>
## Salida: res://assets/ui/mosaico/<nombre>.jpg (~5-9 KB cada una).

## [archivo de origen, nombre, recorte (fracciones x, y, ancho, alto)]: el recorte quita los iconos de la esquina, el aviso «E» de la sala y,
## en el estadio, el cartel de bienvenida de arriba a la derecha.
const PIEZAS := [["sala_0.png", "vestuario", [0.07, 0.07, 0.86, 0.86]], ["sala_1.png", "oficina", [0.07, 0.07, 0.86, 0.86]],
	["sala_2.png", "despacho", [0.07, 0.07, 0.86, 0.86]], ["sala_3.png", "museo", [0.07, 0.07, 0.86, 0.86]],
	["sala_4.png", "video", [0.07, 0.07, 0.86, 0.86]], ["sala_0.png", "tunel", [0.3, 0.25, 0.4, 0.4]],
	["estadio_3.png", "estadio", [0.0, 0.24, 0.7, 0.66]]]
const ANCHO := 192
const ALTO := 108

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("falta la carpeta de origen")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://assets/ui/mosaico")
	for pz: Array in PIEZAS:
		var img := Image.load_from_file(String(args[0]).path_join(String(pz[0])))
		if img == null:
			print("no está %s" % pz[0])
			continue
		var w := img.get_width()
		var h := img.get_height()
		var f: Array = pz[2]
		img = img.get_region(Rect2i(int(w * float(f[0])), int(h * float(f[1])), int(w * float(f[2])), int(h * float(f[3]))))
		img.resize(ANCHO, ALTO, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGB8)
		for y in ALTO:
			for x in ANCHO:
				var c := img.get_pixel(x, y)
				var l := c.get_luminance()
				img.set_pixel(x, y, Color(l, l, l))
		var ruta := "res://assets/ui/mosaico/%s.jpg" % String(pz[1])
		img.save_jpg(ProjectSettings.globalize_path(ruta), 0.72)
		print("%s (%d bytes)" % [ruta, FileAccess.get_file_as_bytes(ruta).size()])
	quit()
