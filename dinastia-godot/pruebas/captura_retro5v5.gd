extends Node
## El minijuego retro 5v5 abierto encima (01-11): saca el jugador 1 y, a los 3 s, la foto.
##   herramientas/captura.sh res://pruebas/captura_retro5v5.tscn
var _n := 0
var _pulsada := 0
func _ready() -> void:
	Retro5v5.abrir(get_tree())
func _physics_process(_d: float) -> void:
	_n += 1
	if _pulsada > 0:
		_pulsada -= 1
		if _pulsada == 0:
			Input.action_release("p1_pass")
	elif GameManager.current_state is GameStateKickoff:
		Input.action_press("p1_pass")
		_pulsada = 8
	if _n == 200:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/retro5v5.png")
		get_tree().quit()
