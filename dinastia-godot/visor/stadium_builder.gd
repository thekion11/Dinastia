class_name StadiumBuilder
extends "res://visor/stadium_builder_p10.gd"
## [Capa 3/3 de `stadium_builder.gd`] encender_conos

## `oscuro` 0 (pleno día) a 1 (noche cerrada): lo que se ven los haces.
static func encender_conos(oscuro: float) -> void:
	if _mat_cono != null:
		_mat_cono.albedo_color.a = clampf((oscuro - 0.4) / 0.6, 0.0, 1.0) * 0.035
		## 13-11: con alfa 0 (de día) el haz aditivo no suma nada: no se dibuja (9 conos de hasta 92 m rasterizados para nada; −9 llamadas, −3 % de fotograma en llvmpipe).
		var arbol := Engine.get_main_loop() as SceneTree
		if arbol != null:
			for c: Node in arbol.get_nodes_in_group("foco_cono"):
				(c as MeshInstance3D).visible = _mat_cono.albedo_color.a > 0.0
