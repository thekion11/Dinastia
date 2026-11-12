extends Node
## LLAMADAS DE DIBUJO DEL MANDO TÁCTIL A SOLAS (12-11, sesión 16): dentro del partido la medida del HUD oscila ±6 (el 3D cambia entre
## fotogramas). Aquí solo está `ControlesTactiles` (horizontal 2400×1080, con balón y sin balón) y se cuentan las llamadas de 30 fotogramas.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x720 res://pruebas/medir_mando.tscn
var _ct: ControlesTactiles
var _n := 0
var _suma := {}

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no se mide nada")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	PantallaMovil.ventana_forzada = Vector2i(2400, 1080)
	_ct = ControlesTactiles.new()
	add_child(_ct)
	_ct.visible = OS.get_environment("VACIO") == ""
	_ct.size = Vector2(1600, 720)

func _process(_d: float) -> void:
	if _ct == null:
		return
	_n += 1
	var con := _n < 40
	_ct.set("_con_balon", con)
	_ct.set("_mezcla", 1.0 if con else 0.0)
	_ct.queue_redraw()
	if (_n > 10 and _n < 40) or _n > 50:
		var k := "con balón" if con else "sin balón"
		_suma[k] = int(_suma.get(k, 0)) + RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	if _n == 30 and OS.get_environment("FOTO") != "":
		get_viewport().get_texture().get_image().save_png(OS.get_environment("FOTO"))
	if _n >= 80:
		for k: String in _suma:
			print("MANDO %s: %.1f llamadas por fotograma" % [k, float(_suma[k]) / 29.0])
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
