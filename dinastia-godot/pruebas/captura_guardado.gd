extends Node
## M-301: el indicador «💾 Partida guardada» tras el autoguardado.
##   herramientas/captura.sh res://pruebas/captura_guardado.tscn
var _n := 0
var _p: Node
func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		_p.set("_autoguardado", true)
		_p.call("_autoguardar_si_toca")
	if _n == 16:
		var l: Node = _p.get_node_or_null("IndicadorGuardado")
		print("INDICADOR ", l != null and (l as Label).text.contains("guardada"))
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/indicador_guardado.png")
		get_tree().quit()
