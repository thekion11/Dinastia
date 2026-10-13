extends Node
## Sonda: cómo salen traducidos los titulares del periódico.
func _ready() -> void:
	for idi in ["en", "de", "es"]:
		Idiomas.idioma = idi
		for t in ["CLÁSICO: \"Una máquina\": el equipo pisa fuerte y la ciudad sueña", "SUPERCLÁSICO: Golpe de autoridad", "Noche para el olvido"]:
			print(idi, ": ", PortadaPeriodico.titular_traducido(t))
	Idiomas.idioma = "es"
	get_tree().quit()
