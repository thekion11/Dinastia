extends Control
## Las instalaciones por dentro, una foto de cada sala.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_interiores.tscn
const CLAVES := ["ciudad_ayuntamiento", "ciudad_hospital", "ciudad_comisaria", "ciudad_bomberos", "ciudad_escuela",
	"ciudad_estacion_central", "ciudad_mercado", "ciudad_cine", "ciudad_centro_comercial", "gim", "video", "cocina", "pren", "museo", "piscina"]
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
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/interior_%s.png" % CLAVES[_i])
			print("FOTO ", CLAVES[_i])
			_int.queue_free()
			_int = null
		_i += 1
		if _i >= CLAVES.size():
			get_tree().quit()
			return
		_int = InteriorInstalacion.abrir(self, CLAVES[_i])
		_t = 0.0
