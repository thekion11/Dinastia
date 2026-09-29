extends Node
## LA INTERFAZ EN OTROS IDIOMAS (29-9-2026, mapa de metas 25): la pantalla
## principal y un menú a pantalla completa en francés y en alemán.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_idiomas.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/%s.png" % nombre)

func _process(_d: float) -> void:
	_n += 1
	var ml: MenuLateral = _p.get("_menu_lateral")
	## Como el botón de idioma de Ajustes: después de cargar las preferencias.
	if _n == 10:
		Idiomas.idioma = "fr"
		_p._refrescar()
	if _n == 40:
		_foto("idioma_fr_principal")
		ml.abrir_menu("historia", -1)
	if _n == 70:
		_foto("idioma_fr_historia")
		Idiomas.idioma = "de"
		_p._refrescar()
		ml.abrir_menu("ajustes", -1)
	if _n == 100:
		_foto("idioma_de_ajustes")
		get_tree().quit()
