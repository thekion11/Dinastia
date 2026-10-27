extends Node
## La pestaña de táctica con sus presets de pizarra (fila 382). Antes: sin ellos; después: con dos guardados.
##   herramientas/captura.sh res://pruebas/captura_presets_tactica.tscn   (PRESETS=0 → antes; CAPTURA_SALIDA cambia la carpeta)
var _p: Node
var _n := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		var m: Mundo = _p.get("mundo")
		var c := m.mi_club()
		if OS.get_environment("PRESETS") != "0":
			var pr: PresetsTactica = m.roles.presets_tactica
			c.tactica.mentalidad = Tactica.Mentalidad.OFENSIVA
			c.tactica.presion = Tactica.Nivel.ALTO
			pr.guardar("Ir a por el partido", c.tactica)
			c.tactica.mentalidad = Tactica.Mentalidad.DEFENSIVA
			c.tactica.presion = Tactica.Nivel.BAJO
			pr.guardar("Cerrar el partido", c.tactica)
		_p.call("_ir_a_pestana", "Táctica")
		_p.call("_refrescar")
	if _n == 14:
		## Se baja la hoja de táctica hasta los presets (el campo de juego ocupa lo de arriba).
		var n: Node = _p.get("_lista_tactica")
		while n != null and not (n is ScrollContainer):
			n = n.get_parent()
		if n != null:
			(n as ScrollContainer).scroll_vertical = 360
	if _n == 20:
		var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
		get_viewport().get_texture().get_image().save_png("%s/presets_tactica%s.png" % [carpeta, "_antes" if OS.get_environment("PRESETS") == "0" else ""])
		get_tree().quit()
