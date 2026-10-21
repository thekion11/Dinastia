extends Node
## Los malabares rehechos (21-10-2026): estadio de fondo, jugador con la camiseta
## del club, balón con gajos, chispas y la racha (×2).
##   herramientas/captura.sh res://pruebas/captura_malabares.tscn
var _n := 0
var _j: MinijuegoMalabares

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)
	_j = MinijuegoMalabares.mostrar(raiz, m)

func _process(_d: float) -> void:
	_n += 1
	## Un bot que toca siempre en el punto justo: así sube la racha.
	if _j._y > 0.84 and not _j._fin:
		_j._pie = _j._x
		_j._tocar()
	if _n == 900:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/malabares_nuevo.png")
		print("FOTO malabares racha=", _j._racha, " x", _j.multiplicador(), " puntos=", _j._puntos)
		get_tree().quit()
