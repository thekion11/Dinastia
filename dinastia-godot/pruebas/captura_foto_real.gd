extends Node
## Comprueba que un futbolista real CON foto encontrada usa su cara de
## verdad -Cara.foto_real()-, no el retrato procedural.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_foto_real.tscn
const ESPERA := 14
var _n := 0
var _pantalla: Node
func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)
func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var mundo: Mundo = _pantalla.get("mundo")
		if mundo.mi_club().nombre != "Colo-Colo":
			for c: Club in mundo.clubes.values():
				if Nombres.limpiar(c.nombre) == "Colo-Colo":
					mundo.tomar_el_mando(c.id)
					break
		_pantalla.call("_refrescar")
		var mio := mundo.mi_club()
		var vidal: Jugador = null
		for j: Jugador in mio.plantilla:
			if Nombres.limpiar(j.nombre) == "Arturo Vidal":
				vidal = j
				break
		if vidal != null:
			_pantalla.call("_ver_ficha", vidal)
	if _n == ESPERA + 4:
		_guardar("res://pruebas/pantalla_foto_real.png")
		get_tree().quit()
func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s" % ruta)
