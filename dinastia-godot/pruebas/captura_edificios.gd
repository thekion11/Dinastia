extends Control
## Las instalaciones por dentro, una foto de cada sala.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_interiores.tscn
const CLAVES := ["edificio_vivienda|Casa de la familia Ortega", "edificio_bar|Bar El Rincón", "edificio_panaderia|Panadería La Espiga", "edificio_peluqueria|Peluquería Estilo", "edificio_libreria|Librería El Capítulo", "edificio_taller|Taller Motor"]
var _i := -1
var _t := 0.0
var _int: Control

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)

func _process(d: float) -> void:
	_t += d
	if _int == null or _t > 2.0:
		if _int != null:
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/edificio_%d.png" % _i)
			print("FOTO ", CLAVES[_i])
			_int.queue_free()
			_int = null
		_i += 1
		if _i >= CLAVES.size():
			get_tree().quit()
			return
		_int = InteriorInstalacion.abrir(self, CLAVES[_i])
		_t = 0.0
