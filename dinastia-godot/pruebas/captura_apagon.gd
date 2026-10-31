extends Node
## Antes/después del apagón por sector: las farolas de noche, con y sin corriente en el sector (2,2).
## Solo farolas sobre fondo negro (sin ciudad entera). NO corre con --headless:
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/captura_apagon.tscn
## Sale en /tmp/captura_apagon_0.png (con luz) y _1.png (sector 2·2 sin luz); CAPTURA_SALIDA cambia la carpeta.

var _n := 0
var _ex: CiudadExpansion
var _v: RedesCiudadVista

func _ready() -> void:
	var b := CityBuilder.new()
	add_child(b)
	_ex = CiudadExpansion.new(b)
	_ex.armar_red()
	_ex.armar_bloques()
	_ex.armar_transporte()
	_ex._farolas()
	_v = RedesCiudadVista.crear(_ex, 5)
	_v.modelo.averias_azar = false
	_ex.redes = _v
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.015, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.25, 0.35)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.fov = 60.0
	cam.position = Vector3(-55.0, 650.0, 420.0)
	add_child(cam)
	cam.make_current()
	cam.look_at(Vector3(-55.0, 0.0, 300.0), Vector3.UP)
	_ex.encender(1.0)

func _process(_d: float) -> void:
	_n += 1
	var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
	if _n == 10:
		get_viewport().get_texture().get_image().save_png("%s/captura_apagon_0.png" % carpeta)
		_v.modelo.averiar("luz", Vector2i(2, 2))
		_v.modelo.recalcular()
		_ex.encender(1.0)
	elif _n == 20:
		get_viewport().get_texture().get_image().save_png("%s/captura_apagon_1.png" % carpeta)
		get_tree().quit()
