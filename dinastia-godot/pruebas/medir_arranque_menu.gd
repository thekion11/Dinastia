extends Node
## CUÁNTO TARDA EL MENÚ DE VERDAD («Continuar»: `principal.tscn` con un club) tras el arranque (10-11-2026): carga y compilado de la escena, montarla, generar el mundo, tomar el mando y refrescar el menú, y el 1.º/30.º fotograma.
##   PAIS=ESP CLUB=5 herramientas/hw_modesto.sh res://pruebas/medir_arranque_menu.tscn   (con el .pck precompilado, ver docs/04_auditorias/rendimiento_movil_2026-11-10.md)
var _t := {}
var _n := 0
var _p: Node

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.NIVEL_DEFECTO)
	_t["motor+autoloads"] = Time.get_ticks_msec()
	var a := Time.get_ticks_msec()
	var esc: PackedScene = load("res://escenas/principal.tscn")
	_t["cargar y compilar principal.tscn"] = Time.get_ticks_msec() - a
	a = Time.get_ticks_msec()
	_p = esc.instantiate()
	add_child(_p)
	_t["instanciar y montar"] = Time.get_ticks_msec() - a
	a = Time.get_ticks_msec()
	var m := Mundo.new()
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	m.generar([pais], 4711)
	_t["generar el mundo (1 país)"] = Time.get_ticks_msec() - a
	a = Time.get_ticks_msec()
	m.tomar_el_mando(m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()].id)
	_p.set("mundo", m)
	_p.call("_refrescar")
	_t["tomar el mando y refrescar"] = Time.get_ticks_msec() - a
	RenderingServer.frame_post_draw.connect(_dibujado)

func _dibujado() -> void:
	_n += 1
	if _n == 1:
		_t["1.er fotograma a los"] = Time.get_ticks_msec()
	if _n == 30:
		var partes: Array[String] = []
		for k: String in _t:
			partes.append("%s=%d ms" % [k, _t[k]])
		print("ARRANQUE_MENU ", " · ".join(partes), " · 30.º fotograma a los %d ms · memoria estática %d MB" % [Time.get_ticks_msec(), OS.get_static_memory_usage() / 1048576])
		get_tree().quit()
