class_name StadiumBuilder
extends "res://visor/stadium_builder_p10.gd"
## [Capa 12/12 de `stadium_builder.gd`] encender_conos

## `oscuro` 0 (pleno día) a 1 (noche cerrada): lo que se ven los haces.
static func encender_conos(oscuro: float) -> void:
	if _mat_cono != null:
		_mat_cono.albedo_color.a = clampf((oscuro - 0.4) / 0.6, 0.0, 1.0) * 0.035
