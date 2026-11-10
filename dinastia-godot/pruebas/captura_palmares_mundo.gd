extends Node
## Captura del palmarés del mundo (necesita pantalla: xvfb-run). Cierra las copas de todos los países y anota los campeones de liga.
## xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/captura_palmares_mundo.tscn  → /tmp/palmares_mundo.jpg
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n != 12:
		return
	var m: Mundo = _p.mundo
	CopasMundo.cerrar(m)
	CopasMundo.anotar_campeones_liga(m)
	PalmaresMundoUI.abrir(_p)
	await get_tree().create_timer(1.2).timeout
	if DisplayServer.get_name() != "headless":   ## sin pantalla (`especiales.sh`) solo se comprueba que el palmarés se construye sin errores
		get_viewport().get_texture().get_image().save_jpg("/tmp/palmares_mundo.jpg", 0.9)
	print("CAPTURA OK ", m.palmares_mundo.size())
	get_tree().quit()
