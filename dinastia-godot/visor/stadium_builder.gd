class_name StadiumBuilder
extends "res://visor/stadium_builder_p10.gd"
## [Capa 12/12 de `stadium_builder.gd`] encender_conos

## `oscuro` 0 (pleno día) a 1 (noche cerrada): lo que se ven los haces.
## M-014 (26-10-2026): los haces son `stadium_builder_haz.gdshader` (antes un
## cono plano casi transparente que no se veía); de día se ocultan.
const FUERZA_HAZ_MAX := 0.07

static func encender_conos(oscuro: float) -> void:
	_fuerza_haz = clampf((oscuro - 0.4) / 0.6, 0.0, 1.0) * FUERZA_HAZ_MAX
	mat_haz().set_shader_parameter("fuerza", _fuerza_haz)
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol == null:
		return
	for n: Node in arbol.get_nodes_in_group("foco_cono"):
		(n as Node3D).visible = _fuerza_haz > 0.0
