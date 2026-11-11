extends SceneTree
## BIBLIOTECA DE USO (sesión 10, 11-11-2026, orden del líder por el peso de los builds): copia SOLO los clips que referencian los JSON de
## `datos/anims_extra/` desde las bibliotecas completas de `terceros/` (que Godot no importa ni exporta) a una biblioteca pequeña que sí viaja.
## Entrada: `terceros/estilo100/uso_clips.json` y `terceros/ual/uso_clips.json` (los escriben `estilo100_a_anims_extra.py` y `ual_a_anims_extra.py`).
##   godot --headless --path . --script res://herramientas/anims_uso_a_res.gd
const LISTAS := ["res://terceros/estilo100/uso_clips.json", "res://terceros/ual/uso_clips.json"]

func _init() -> void:
	for l: String in LISTAS:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(l))
		var salida := AnimationLibrary.new()
		var abiertas := {}
		for clip: String in d["clips"]:
			var bib: String = d["origen"].get(clip, d["origen"].get(clip.trim_suffix("_espejo"), ""))
			if not abiertas.has(bib):
				abiertas[bib] = load(bib)
			var lib: AnimationLibrary = abiertas[bib]
			if lib.has_animation(clip):
				var a: Animation = lib.get_animation(clip).duplicate()
				a.compress()   # compresión nativa de pistas (rotaciones cuantizadas): mucho menos peso
				salida.add_animation(clip, a)
			else:
				print("FALTA ", clip, " en ", bib)
		DirAccess.make_dir_recursive_absolute(String(d["salida"]).get_base_dir())
		print(d["salida"], " ", salida.get_animation_list().size(), " clips  guardar: ", ResourceSaver.save(salida, d["salida"], ResourceSaver.FLAG_COMPRESS))
	quit(0)
