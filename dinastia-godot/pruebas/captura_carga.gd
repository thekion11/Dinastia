extends Node
## La pantalla de carga con consejo (informe, 13-10-2026): pulsa el botón de la
## ciudad y fotografía el primer fotograma. Salida: pruebas/capturas/carga.png
var _p: Node
var _n := 0
func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		var m := Mundo.new()
		m.generar(["CHI"], 4711)
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
		_p.set("mundo", m)
		_p.call("_refrescar")
		_p.call("_ver_ciudad_con_carga")
	if _n == 6:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/carga.png")
	if _n == 7:
		get_tree().quit()
