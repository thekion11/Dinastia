extends Node
## FOTO DE CUALQUIER ESCENA, sin escribir un script por pantalla.
##
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 \
##         res://pruebas/foto_escena.tscn -- <escena.tscn> <salida.png> [fotogramas]
##
## Instancia la escena, espera los fotogramas pedidos (por defecto 40, para que
## los Control se coloquen y las animaciones de entrada terminen) y guarda la
## imagen del viewport. En Linux sin monitor se corre bajo `xvfb-run`.

var _escena := "res://escenas/inicio.tscn"
var _salida := "user://foto.png"
var _espera := 40
var _n := 0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_escena = args[0]
	if args.size() > 1:
		_salida = args[1]
	if args.size() > 2 and args[2].is_valid_int():
		_espera = int(args[2])
	add_child((load(_escena) as PackedScene).instantiate())

func _process(_d: float) -> void:
	_n += 1
	if _n < _espera:
		return
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(_salida)
	print("foto_escena: %s -> %s (%s)" % [_escena, _salida, error_string(err)])
	get_tree().quit(0 if err == OK else 1)
