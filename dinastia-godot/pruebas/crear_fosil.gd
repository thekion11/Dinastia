extends Node
## Guarda una partida "fósil" con el código de HOY en `pruebas/partidas_viejas/` (ver el final de `ideas/sav_fosiles.gd`): un mundo CHI+ARG de semilla fija
## con N semanas jugadas. Sirve para que el guardado de dentro de unas versiones tenga más casos que abrir (media temporada con el continental en curso, varios años de historia…).
##   FOSIL_SEMANAS=15 FOSIL_ETIQUETA=media_temporada godot --headless --path . res://pruebas/crear_fosil.tscn
func _ready() -> void:
	var semanas := int(OS.get_environment("FOSIL_SEMANAS")) if OS.get_environment("FOSIL_SEMANAS") != "" else 15
	var etiqueta := OS.get_environment("FOSIL_ETIQUETA") if OS.get_environment("FOSIL_ETIQUETA") != "" else "fosil"
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 20261106)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for i in semanas:
		m.avanzar_semana()
	var d := Partida.instantanea(m)
	var ruta := "res://pruebas/partidas_viejas/v%d_2026-11-06_%s.json.gz" % [Partida.VERSION, etiqueta]
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_buffer(JSON.stringify(d).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))
	f.close()
	print("FOSIL guardado: %s · año %d semana %d · %d bytes" % [ruta, m.anio, m.semana, FileAccess.get_file_as_bytes(ruta).size()])
	get_tree().quit()
