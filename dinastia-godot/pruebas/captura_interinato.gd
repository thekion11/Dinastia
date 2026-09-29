extends Node
## Arranca un interinato de verdad dentro de la pantalla y juega ocho semanas,
## para ver el aviso de "Salvaste al club" / "No alcanzo" en el registro.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_interinato.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var mun = _pantalla.get("mundo")
		mun.roles.arrancar_interinato("CHI")
		_pantalla.call("_refrescar")
	if _n == ESPERA + 2:
		var mun = _pantalla.get("mundo")
		for s in 8:
			mun.avanzar_semana()
		_pantalla.call("_refrescar")
	if _n == ESPERA + 8:
		_guardar("res://pruebas/capturas/pantalla_interinato.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
