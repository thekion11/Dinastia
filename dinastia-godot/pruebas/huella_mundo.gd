extends Node
## PRUEBA DIFERENCIAL (23-10-2026): simula temporadas con semillas fijas y escribe una HUELLA del estado
## completo del mundo (`Partida.instantanea`). Si dos versiones del código dan la misma huella, se
## comportan igual. Se usó para comprobar que partir los scripts en capas no cambió nada.
##   SEMILLAS=11,222 TEMPORADAS=3 godot --headless --path . res://pruebas/huella_mundo.tscn
func _ready() -> void:
	var semillas: Array = [11, 222]
	if OS.get_environment("SEMILLAS") != "":
		semillas = Array(OS.get_environment("SEMILLAS").split(",")).map(func(x: String) -> int: return int(x))
	var temporadas := int(OS.get_environment("TEMPORADAS")) if OS.get_environment("TEMPORADAS") != "" else 3
	for s: int in semillas:
		var m := Mundo.new()
		m.generar(["CHI", "ARG", "ESP"], s)
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
		for t in temporadas:
			m.jugar_temporada()
			m.nueva_temporada()
		var inst: Dictionary = Partida.instantanea(m)
		inst.erase("guardado")      ## la hora del guardado cambia en cada ejecución
		var texto := JSON.stringify(inst, "", true)
		if OS.get_environment("HUELLA_SALIDA") != "":
			var f := FileAccess.open("%s_%d.json" % [OS.get_environment("HUELLA_SALIDA"), s], FileAccess.WRITE)
			f.store_string(JSON.stringify(inst, "\t", true))
			f.close()
		print("HUELLA semilla %d: %s (%d bytes)" % [s, texto.sha256_text().substr(0, 16), texto.length()])
	get_tree().quit()
