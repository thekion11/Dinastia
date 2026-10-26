extends Node
## SONDA (borrar al acabar): la vitrina 3D del legado.
var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var r: Roles = (_pantalla.get("mundo") as Mundo).roles
		for t in ["Liga", "Copa Chile", "Supercopa de Chile", "Copa Cóndor", "Mundial de Clubes", "Copa del Mundo"]:
			r.trofeos.append({"anio": 2027, "titulo": t})
		_pantalla.call("_ir_a_pestana", "Legado")
		_pantalla.call("_ir_a_pestana", Idiomas.t("Legado"))
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/rp_legado.png")
		get_tree().quit()
