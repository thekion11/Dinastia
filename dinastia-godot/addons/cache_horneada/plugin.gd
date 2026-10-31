@tool
extends EditorPlugin
## Registra el exportador de `exportar.gd` (ver allí).

var _exp: EditorExportPlugin

func _enter_tree() -> void:
	_exp = preload("res://addons/cache_horneada/exportar.gd").new()
	add_export_plugin(_exp)

func _exit_tree() -> void:
	remove_export_plugin(_exp)
	_exp = null
