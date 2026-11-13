extends Node
## EL MODO JUGADOR, EN FOTOS (13-11-2026): la creación, la semana recién
## firmada y la semana tras simular unas cuantas. Fuera del repo, en JPG.
##   SALIDA=<carpeta> [PUESTO=MC] [NOMBRE=…] [SEMANAS=6] [PREFIJO=antes_] xvfb-run -a godot --path . \
##     --rendering-driver vulkan --resolution 1280x720 res://pruebas/captura_modo_jugador.tscn
var _n := 0
var _ui: CarreraJugadorUI
var _salida := OS.get_environment("SALIDA")
var _prefijo := OS.get_environment("PREFIJO")
var _semanas := maxi(1, int(OS.get_environment("SEMANAS"))) if OS.get_environment("SEMANAS") != "" else 6
var _hechas := 0

func _ready() -> void:
	CarreraJugadorUI.mundo = null
	CarreraJugadorUI.nombre_pedido = OS.get_environment("NOMBRE")
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)
	if OS.get_environment("PUESTO") != "":
		_ui._puesto = OS.get_environment("PUESTO")

func _foto(nombre: String) -> void:
	if _salida == "":
		return
	var img := get_viewport().get_texture().get_image()
	img.save_jpg("%s/%s%s.jpg" % [_salida, _prefijo, nombre], 0.9)

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		_foto("crear")
		_ui._crear()
	elif _n == 50:
		_foto("semana_1")
	elif _n > 50 and _hechas < _semanas and _n % 6 == 0:
		_ui._cerrar_semana({})
		_hechas += 1
	elif _hechas >= _semanas and _n % 6 == 3:
		_foto("semana_%d" % (_semanas + 1))
		get_tree().quit()
