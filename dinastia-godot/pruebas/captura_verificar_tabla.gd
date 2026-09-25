extends Node
## Verificación visual de la extracción de `TablaCompeticion` (25-9-2026):
## abre `principal.tscn` de verdad -la pantalla CENTRAL, que es donde vive la
## columna "TABLA DE POSICIONES"- y confirma que sigue pintando datos reales
## después de mover las cinco funciones que la dibujaban a su propio archivo.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_verificar_tabla.tscn

const ESPERA := 10

var _n := 0
var _pantalla: Node
var _fallos := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var titulo = _pantalla.get("_titulo_tabla")
		if titulo == null:
			print("MAL: _titulo_tabla es null")
			_fallos += 1
		else:
			print("OK: titulo de la tabla = '%s'" % titulo.text)
			if titulo.text == "":
				_fallos += 1
		var lista = _pantalla.get("_lista_tabla")
		if lista == null or lista.get_child_count() == 0:
			print("MAL: _lista_tabla vacia (%s)" % [lista])
			_fallos += 1
		else:
			print("OK: _lista_tabla tiene %d hijos pintados" % lista.get_child_count())
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_tabla_verificada.png")
		print("captura: pantalla_tabla_verificada.png")
		print("FIN. %d fallos" % _fallos)
		get_tree().quit(_fallos)
