extends Node
## Verifica la sala completa + los 3 planos de cámara + periodistas de la
## rueda de prensa (14-9-2026, pedido "así de abismal debe ser la mejora").
## Fuerza el reloj interno de la escena (`_t`) para capturar los tres planos
## sin esperar 9 s reales de simulación.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_dt_rueda_prensa.tscn

var _n := 0
var _pantalla: Node
var _escena: Node3D

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var mun = _pantalla.get("mundo")
		mun.prensa.abrir_rueda(true, false)
		_pantalla.call("_abrir_rueda_pantalla_completa", mun.prensa.entrevista)
	if _n == 14:
		## La escena 3D vive dentro del SubViewportContainer de la pantalla
		## completa: se busca por tipo, no por ruta fija -más corto que andar
		## repitiendo `get_node` a través de tres contenedores intermedios.
		_escena = _buscar_escena(_pantalla)
	if _n == 18:
		_forzar_plano(1.0)
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/rueda_sala_plano_trabajo.png")
	if _n == 20:
		_forzar_plano(6.0)
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/rueda_sala_plano_general.png")
	if _n == 22:
		_forzar_plano(8.0)
		var img3 := get_viewport().get_texture().get_image()
		img3.save_png("res://pruebas/capturas/rueda_sala_plano_lateral.png")
		print("capturados los 3 planos")
		get_tree().quit()

## Fuerza el reloj Y hace avanzar el lerp de cámara de un salto -con delta
## grande, `clampf(delta*4.0,0,1)` da 1.0-, para no tener que esperar varios
## fotogramas reales a que la interpolación converja al plano pedido.
func _forzar_plano(t: float) -> void:
	if _escena == null:
		return
	## `_process()` empieza con `_t += delta`: se resta el delta que se va a
	## pasar para que el resultado quede exactamente en `t`.
	_escena.set("_t", t - 1.0)
	_escena.call("_process", 1.0)

func _buscar_escena(n: Node) -> Node3D:
	if n is RuedaPrensaEscena3D:
		return n
	for h in n.get_children():
		var r := _buscar_escena(h)
		if r != null:
			return r
	return null
