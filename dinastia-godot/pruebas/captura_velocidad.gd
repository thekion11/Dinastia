extends Node
## Prueba de "Velocidad de partido por defecto": que el selector se vea en
## Ajustes y que de verdad cambie con qué velocidad arranca un partido en vivo.

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		_pantalla.set("_secc_ajustes", "juego")
		_pantalla.call("_ir_a_pestana", "Ajustes")
		_pantalla.call("_refrescar")
	if _n == 14:
		_guardar("res://pruebas/pantalla_velocidad_ajustes.png")
		## Elegir "Rápido" (índice 3) y comprobar que un partido nuevo arranca ahí.
		_pantalla.set("_velocidad_partido", 3)
		_pantalla.call("_dirigir")
	if _n == 16:
		var vivo: PartidoVivo = null
		for h in _pantalla.get_children():
			if h is PartidoVivo:
				vivo = h
		print("velocidad guardada=3, velocidad real del partido=%s (Rápido=3)" % (vivo._velocidad if vivo != null else "NO SE ABRIO"))
		_guardar("res://pruebas/pantalla_velocidad_partido.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
