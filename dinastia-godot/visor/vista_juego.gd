class_name VistaJuego
extends RefCounted
## LA CÁMARA DEL JUEGO (12-11-2026, decisión del dueño): al mover al personaje (el avatar) por el club, el estadio y la casa, SOLO existe
## la visión en PRIMERA PERSONA. Las demás vistas (tercera persona, planos lejanos) quedan para las capturas, los vídeos y las herramientas
## fuera del juego: se encienden con la variable de entorno `DINASTIA_CAMARAS=1` (o poniendo `primera_persona = false` desde una prueba).
## Sin ella, la tecla V ya no cambia de vista.

static func solo_primera_persona() -> bool:
	return OS.get_environment("DINASTIA_CAMARAS") != "1"

## La vista con la que se empieza a caminar.
static func inicial() -> bool:
	return solo_primera_persona()

## ¿Se puede cambiar de vista con V? Solo fuera del juego.
static func puede_cambiar() -> bool:
	return not solo_primera_persona()
