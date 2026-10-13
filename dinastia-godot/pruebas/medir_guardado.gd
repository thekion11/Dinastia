extends Node
## TAMAÑO DEL GUARDADO A 20 TEMPORADAS (informe de diseño §18: «inflación del
## historial»). Simula 52 semanas × 20 años con 4 ligas y mide el archivo cada
## 5 temporadas (comprimido) y el JSON crudo.
##   godot --headless --path . res://pruebas/medir_guardado.tscn
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP", "ENG"], 31)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var t0 := Time.get_ticks_msec()
	for anio in range(1, 21):
		for s in 52:
			m.avanzar_semana()
		if anio % 5 == 0 or anio == 1:
			Partida.guardar(m, "_medida")
			var f := FileAccess.open(Partida.ruta_de("_medida"), FileAccess.READ)
			var comp := f.get_length()
			var crudo := JSON.stringify(Partida.instantanea(m)).length()
			print("GUARDADO año %2d  comprimido %.2f MB  crudo %.2f MB  (%d s de simulación)" % [anio, comp / 1048576.0, crudo / 1048576.0, (Time.get_ticks_msec() - t0) / 1000])
	DirAccess.remove_absolute(Partida.ruta_de("_medida"))
	get_tree().quit()
