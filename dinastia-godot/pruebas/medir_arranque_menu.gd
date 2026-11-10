extends Node
## CUÁNTO TARDA EL MENÚ DE VERDAD («Continuar»: `principal.tscn` con un club) tras el arranque (10-11-2026): carga y compilado de la escena, montarla, generar el mundo, tomar el mando y refrescar el menú, y el 1.º/30.º fotograma.
##   PAIS=ESP CLUB=5 herramientas/hw_modesto.sh res://pruebas/medir_arranque_menu.tscn   (con el .pck precompilado, ver docs/04_auditorias/rendimiento_movil_2026-11-10.md)
var _t := {}
var _n := 0
var _p: Node

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.NIVEL_DEFECTO)
	_t["motor+autoloads"] = Time.get_ticks_msec()
	## Como la entrada real: el mundo se genera ANTES (`OrquestadorMundo`), `tomar_el_mando` sobre el club, y `Principal` lo recibe en `PedidoPartida.mundo_pregenerado` (hace el resto en `_arrancar_con`).
	var a := Time.get_ticks_msec()
	var m := Mundo.new()
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	m.generar([pais], 4711)
	m.tomar_el_mando(m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()].id)
	PedidoPartida.mundo_pregenerado = m
	_t["generar el mundo (1 país) y tomar el mando"] = Time.get_ticks_msec() - a
	a = Time.get_ticks_msec()
	var esc: PackedScene = load("res://escenas/principal.tscn")
	_t["cargar principal.tscn"] = Time.get_ticks_msec() - a
	a = Time.get_ticks_msec()
	_p = esc.instantiate()
	_t["instanciar (_init de las capas)"] = Time.get_ticks_msec() - a
	a = Time.get_ticks_msec()
	add_child(_p)
	_t["montar el menú (_ready: construir la interfaz y arrancar la partida)"] = Time.get_ticks_msec() - a
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
