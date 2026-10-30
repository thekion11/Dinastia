@tool
extends EditorExportPlugin
## CADA EXPORTACIÓN LLEVA LAS BIBLIOTECAS DE ANIMACIÓN YA HECHAS (30-10-2026, rendimiento).
## Antes de empaquetar, lanza `herramientas/hornear_animaciones.gd` en otro proceso (con el código
## de ESTA exportación: nunca puede ir una caché vieja) y añade los archivos al paquete en
## `res://cache_horneada/`. Si el horneado falla, se exporta igual: el juego las construye la
## primera vez como antes. Lo usa `CacheDisco.cargar_horneada`.

func _get_name() -> String:
	return "CacheHorneada"

func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	var tmp := OS.get_user_data_dir().path_join("cache_horneada_export")
	if DirAccess.dir_exists_absolute(tmp):
		for f in DirAccess.get_files_at(tmp):
			DirAccess.remove_absolute(tmp.path_join(f))
	var salida := []
	var codigo := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", "res://herramientas/hornear_animaciones.gd",
		"--", tmp], salida, true)
	if codigo != 0:
		push_warning("Caché horneada: el horneado falló (%d); se exporta sin ella.\n%s" % [codigo, "".join(salida).right(800)])
		return
	for f in DirAccess.get_files_at(tmp):
		add_file(CacheDisco.HORNEADA + f, FileAccess.get_file_as_bytes(tmp.path_join(f)), false)
	print("Caché horneada: %d archivos al paquete" % DirAccess.get_files_at(tmp).size())
