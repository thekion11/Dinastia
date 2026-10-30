extends Node
## La textura del césped con caché (memoria y disco, `StadiumBuilder._make_grass_texture`) es la
## misma, byte a byte, que la de `CespedTextura.nueva` para todos los patrones (30-10-2026).
const PATRONES := ["rayas", "rayasH", "damero", "damGrande", "circular", "circulos", "diagonal",
	"espiga", "cruz", "abanico", "rombos", "mitades", "liso", "otro"]

func _ready() -> void:
	var fallos := 0
	var claro := Color(0.2311, 0.5523, 0.1871)
	var oscuro := Color(0.1702, 0.4419, 0.1373)
	for vuelta in 2:   ## la 2.ª, sin la memoria: sale del disco
		StadiumBuilder._cesped.clear()
		for p: String in PATRONES:
			var ref := CespedTextura.nueva(p, claro, oscuro).get_data()
			if StadiumBuilder._make_grass_texture(p, claro, oscuro).get_image().get_data() != ref:
				fallos += 1
				print("FALLO césped ", p, " vuelta ", vuelta)
		OS.delay_msec(300)   ## que el hilo termine de guardar los PNG
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
