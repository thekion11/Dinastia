extends "res://pruebas/so/vis_partido_base.gd"
## VISUALIZACIÓN · partido con la cámara real en Compatibilidad (OpenGL: móvil, Web y PC viejo): foto no vacía, JPG y comparación con la referencia.
func _nombre() -> String:
	return "vis_partido_compat"

func _probar() -> void:
	await _probar_partido("partido_tv", "gl_compatibility")
