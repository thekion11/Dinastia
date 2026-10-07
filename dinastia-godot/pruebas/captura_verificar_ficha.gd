extends Node
## Verificación visual de la extracción de `FichaJugadorInfo` (25-9-2026):
## abre `principal.tscn` de verdad, mira la ficha de un jugador PROPIO -que
## ejerce las 8 funciones movidas: estadísticas, cabeza, promesa,
## habilidades, historial médico, vida personal, historial de crecimiento- y
## de un jugador AJENO -que ejerce la ruta de `bio_de()` llamada directo
## desde `_ver_ficha()`, el segundo punto de enganche que había que
## actualizar-.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_verificar_ficha.tscn

const ESPERA := 10

var _pantalla: Node
var _n := 0
var _fallos := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _mal(txt: String) -> void:
	print("MAL: " + txt)
	_fallos += 1

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var mundo = _pantalla.get("mundo")
		var mio = mundo.mi_club()
		## Un jugador PROPIO con historial y estadísticas, si lo hay; si no,
		## el primero de la plantilla sirve igual -las funciones se blindan
		## solas cuando no hay datos (parten devolviendo temprano).
		var jugador = mio.plantilla[0]
		_pantalla.call("_ver_ficha", jugador)
	if _n == ESPERA + 2:
		var ficha = _pantalla.get("_ficha")
		if ficha == null or ficha.get_child_count() < 3:
			_mal("la ficha de un jugador propio pintó muy poco (%s hijos)" % [
				ficha.get_child_count() if ficha != null else "null"])
		else:
			print("OK: ficha propia con %d hijos pintados" % ficha.get_child_count())
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_ficha_propia.png")
		print("captura: pantalla_ficha_propia.png")

		## Ahora un jugador AJENO -ejercita la rama que llama a bio_de()
		## directo, sin pasar por pintar_vida_personal().
		var mundo2 = _pantalla.get("mundo")
		var otro_club = null
		for c in mundo2.clubes.values():
			if c.id != mundo2.mi_club_id:
				otro_club = c
				break
		var ajeno = otro_club.plantilla[0]
		_pantalla.call("_ver_ficha", ajeno)
	if _n == ESPERA + 4:
		var ficha2 = _pantalla.get("_ficha")
		if ficha2 == null or ficha2.get_child_count() < 3:
			_mal("la ficha de un jugador ajeno pintó muy poco")
		else:
			print("OK: ficha ajena con %d hijos pintados" % ficha2.get_child_count())
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/pantalla_ficha_ajena.png")
		print("captura: pantalla_ficha_ajena.png")
		print("FIN. %d fallos" % _fallos)
		get_tree().quit(_fallos)
