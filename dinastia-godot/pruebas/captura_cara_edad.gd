extends Node
## ANTES/DESPUÉS de la edad en la cara 2D (10-11): 12 jugadores de 6 países (distintos), todos con 38-44 años.
##   SIN_EDAD_CARA=1 godot --headless --path . res://pruebas/captura_cara_edad.tscn -- /ruta/antes.png
##   godot --headless --path . res://pruebas/captura_cara_edad.tscn -- /ruta/despues.png
const GENTE := [["ESP", 41], ["ESP", 38], ["ARG", 43], ["ARG", 39], ["JPN", 40], ["JPN", 44], ["NGA", 42], ["NGA", 38], ["GER", 41], ["GER", 44], ["BRA", 39], ["BRA", 43]]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var salida := String(args[0]) if args.size() > 0 else "res://pruebas/captura_cara_edad.png"
	var lienzo := Image.create(6 * 128, 2 * 128, false, Image.FORMAT_RGBA8)
	lienzo.fill(Color(0.16, 0.2, 0.24))
	for i in GENTE.size():
		var j := Jugador.new()
		j.id = "cara_edad_%s_%d" % [GENTE[i][0], i]
		j.nombre = "Muestra %d" % i
		j.pais = GENTE[i][0]
		j.edad = GENTE[i][1]
		j.real = true
		var img := Image.new()
		img.load_svg_from_string(Cara.svg_de(j, "#2b6b45", "#ffffff"), 128.0 / 64.0)   ## (svg_de, no textura_2d: esa busca fotos reales)
		img.convert(Image.FORMAT_RGBA8)
		lienzo.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((i % 6) * 128, (i / 6) * 128))
	lienzo.save_png(salida)
	print("guardado ", salida)
	get_tree().quit()
