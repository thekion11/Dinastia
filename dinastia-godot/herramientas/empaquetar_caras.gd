extends SceneTree
## EL PAQUETE PRIVADO DE CARAS Y DATOS REALES (30-10-2026, «opción B» del dueño). Los builds son
## TODOS públicos (sin nada real); lo real va aparte en `caras_reales.pck`, que el juego monta al
## arrancar si lo encuentra junto al ejecutable o en la carpeta del usuario (`PaqueteReal`).
## NO SE PUBLICA: es para el dueño (Drive privado).
##   godot --headless --path . --script res://herramientas/empaquetar_caras.gd -- <destino.pck>

const CARPETAS := ["res://recursos/caras_reales_256", "res://recursos/caras_reales_cara",
	"res://recursos/caras_reales_albedo", "res://recursos/caras_biblioteca"]
const ARCHIVOS := ["res://datos/pack_real.json", "res://datos/caras_reales_reporte.json",
	"res://datos/caras_reales_recortes.json", "res://datos/caras_reales_puntos.json",
	"res://datos/caras_reales_rasgos.json", "res://datos/caras_reales_mallas.json",
	"res://datos/biblioteca_caras.json", "res://datos/creditos_fotos.txt"]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var destino: String = args[0] if args.size() > 0 else "caras_reales.pck"
	var lista := PackedStringArray(ARCHIVOS)
	for c in CARPETAS:
		for f in DirAccess.get_files_at(c):
			if not f.ends_with(".import") and not f.ends_with(".uid"):
				lista.append(c.path_join(f))
	var pck := PCKPacker.new()
	if pck.pck_start(destino) != OK:
		push_error("No se pudo crear " + destino)
		quit(1)
		return
	var n := 0
	for r in lista:
		if not FileAccess.file_exists(r):
			continue
		n += _sumar(pck, r)
		## Si se importó (no está en modo `keep`), también su `.import` y lo importado.
		if FileAccess.file_exists(r + ".import"):
			n += _sumar(pck, r + ".import")
			for linea in FileAccess.get_file_as_string(r + ".import").split("\n"):
				if linea.begins_with("path") and "res://.godot/imported/" in linea:
					var importado := linea.get_slice("\"", 1)
					if FileAccess.file_exists(importado):
						n += _sumar(pck, importado)
	pck.flush()
	print("PAQUETE REAL: %d archivos en %s (%.1f MB)" % [n, destino,
		FileAccess.get_file_as_bytes(destino).size() / 1048576.0 if FileAccess.file_exists(destino) else 0.0])
	quit(0 if n > 0 else 1)

func _sumar(pck: PCKPacker, ruta: String) -> int:
	return 1 if pck.add_file(ruta, ProjectSettings.globalize_path(ruta)) == OK else 0
