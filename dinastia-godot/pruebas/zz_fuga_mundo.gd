extends Node
## ¿SE LIBERA UN MUNDO AL SOLTARLO? (10-11-2026): memoria estática tras generar, tras soltar la referencia y (si hace falta) tras cada paso de la limpieza. Herramienta, no prueba del banco.
##   MODO=nada|mando|guardar  godot --headless --path . res://pruebas/zz_fuga_mundo.tscn
func _est() -> float:
	return float(OS.get_static_memory_usage()) / 1048576.0

func _ready() -> void:
	var modo := OS.get_environment("MODO")
	print("FUGA base: %.0f MB" % _est())
	var m := Mundo.new()
	m.generar([], 4711)
	var ref: WeakRef = weakref(m)
	print("FUGA generado: %.0f MB" % _est())
	if modo == "mando" or modo == "guardar":
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
	if modo == "guardar":
		Partida.guardar(m, "zz_fuga")
		Partida.borrar("zz_fuga")
	print("FUGA tras %s: %.0f MB" % [modo, _est()])
	m = null
	await get_tree().process_frame
	await get_tree().process_frame
	print("FUGA mundo soltado: %.0f MB  (weakref vivo: %s)" % [_est(), str(ref.get_ref() != null)])
	get_tree().quit()
