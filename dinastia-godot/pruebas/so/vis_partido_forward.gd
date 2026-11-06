extends "res://pruebas/so/vis_partido_base.gd"
## VISUALIZACIÓN · partido con la cámara real en Forward+ (el renderizador del PC): foto no vacía, JPG y comparación con la referencia.
func _nombre() -> String:
	return "vis_partido_forward"

func _probar() -> void:
	await _probar_partido("partido_tv", "forward_plus")
