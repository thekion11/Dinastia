class_name PaqueteReal
extends RefCounted
## MONTA EL PAQUETE PRIVADO `caras_reales.pck` (30-10-2026, ver herramientas/empaquetar_caras.gd).
## Todos los builds son públicos; si junto al ejecutable o en la carpeta del usuario está este
## paquete, sus archivos (fotos, mallas, rasgos y `pack_real.json`) aparecen en `res://` como en el
## proyecto, y el menú ofrece la base real. Sin él, el juego es el público. Lo llama `Datos`.

const NOMBRE := "caras_reales.pck"
static var montado := ""

static func montar() -> void:
	if montado != "" or OS.has_feature("editor"):
		return   ## en el proyecto los archivos ya están
	for ruta in [OS.get_executable_path().get_base_dir().path_join(NOMBRE), "user://" + NOMBRE]:
		if FileAccess.file_exists(ruta) and ProjectSettings.load_resource_pack(ruta, false):
			montado = ruta
			print("Paquete real montado: ", ruta)
			return
