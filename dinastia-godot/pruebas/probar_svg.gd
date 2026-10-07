extends Node
## Comprueba si Godot puede rasterizar SVG generado en tiempo de ejecucion.
##
## Si puede, la estetica entera del HTML -escudos, caras, portadas, equipaciones-
## se porta COMO CADENAS, que es lo que ya son, en vez de reimplementarlas
## dibujando a mano. Es la diferencia entre portar y reescribir.
func _ready() -> void:
	var svg := """<svg width="64" height="70" viewBox="0 0 64 70" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="br" x1="0" y1="0" x2="0.3" y2="1">
      <stop offset="0" stop-color="#ffffff" stop-opacity=".32"/>
      <stop offset="1" stop-color="#000000" stop-opacity=".34"/>
    </linearGradient>
  </defs>
  <path d="M4 4 H60 V40 Q60 58 32 66 Q4 58 4 40 Z" fill="#003da5"/>
  <path d="M4 4 H60 V40 Q60 58 32 66 Q4 58 4 40 Z" fill="url(#br)"/>
  <text x="32" y="40" text-anchor="middle" font-family="Arial" font-size="22" font-weight="900" fill="#ffffff">UC</text>
</svg>"""
	var img := Image.new()
	var err := img.load_svg_from_string(svg, 4.0)
	print("carga SVG: error=%d  tamano=%dx%d" % [err, img.get_width(), img.get_height()])
	if err == OK:
		## Se comprueba que hay pixeles de verdad, no un lienzo transparente: un
		## SVG que "carga" pero sale vacio es peor que uno que falla.
		var opacos := 0
		for y in range(0, img.get_height(), 4):
			for x in range(0, img.get_width(), 4):
				if img.get_pixel(x, y).a > 0.5:
					opacos += 1
		print("pixeles opacos muestreados: %d" % opacos)
		img.save_png("res://pruebas/capturas/svg_prueba.png")
		print("guardado en pruebas/svg_prueba.png")
	get_tree().quit()
