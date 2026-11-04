extends Node
## PARCHES DE ACTUALIZACIÓN (4-11-2026, pedido del dueño: «un exportador actualizador aparte, solo con los cambios»).
## El flujo «Actualizar Dinastia» (.github/workflows/actualizar.yml) genera `parche_<versión>.pck` con SOLO los archivos que
## cambiaron desde una versión dada (`godot --export-patch … --patches base.pck`). Quien ya tiene el juego lo deja:
##   - junto al ejecutable, o
##   - en la carpeta del usuario, subcarpeta `parches/` (Windows: %APPDATA%/Godot/app_userdata/DINASTIA/parches),
## y al arrancar este autoload (el PRIMERO de project.godot) los monta en orden de nombre, cada uno pisando al anterior.
## Va en `_init()` y sin nombrar ninguna clase del juego: así los scripts que se cargan DESPUÉS ya salen del parche
## (documentación de Godot, «Exporting packs, patches, and mods»). Lo que un parche NO puede cambiar (lo avisa el flujo):
## este mismo archivo, `project.godot` (autoloads, ajustes) ni clases nuevas con `class_name` (la lista de clases se lee
## antes): para eso hace falta la instalación completa.

const PREFIJO := "parche_"
static var montados: PackedStringArray = []

func _init() -> void:
	if OS.has_feature("editor") and OS.get_environment("DINASTIA_PARCHES_PRUEBA") == "":
		return   ## en el proyecto no hay nada que parchear
	for ruta in buscar():
		if ProjectSettings.load_resource_pack(ruta, true):
			montados.append(ruta)
			print("Parche montado: ", ruta)
		else:
			push_warning("No se pudo montar el parche %s" % ruta)

## Los parches que hay, ordenados por nombre (parche_0.9.1 antes que parche_0.9.2): junto al ejecutable y en user://parches/.
static func buscar() -> PackedStringArray:
	var carpetas := [OS.get_executable_path().get_base_dir(), "user://parches"]
	var extra := OS.get_environment("DINASTIA_PARCHES_PRUEBA")
	if extra != "":
		carpetas = [extra]
	var out: PackedStringArray = []
	for c: String in carpetas:
		if not DirAccess.dir_exists_absolute(c):
			continue
		var nombres := Array(DirAccess.get_files_at(c)).filter(func(f: String) -> bool:
			return f.begins_with(PREFIJO) and f.ends_with(".pck"))
		nombres.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
		for f: String in nombres:
			out.append(c.path_join(f))
	return out
