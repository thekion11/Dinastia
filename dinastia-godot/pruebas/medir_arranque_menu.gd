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
	if OS.get_environment("PRECARGA") != "":
		## PRECARGA=1: lo que ocurre con el jugador un rato en la portada y la entrada: `Precarga` compila en su hilo los scripts del menú; se espera a que acabe (`_t["portada: espera de la precarga"]`) y se monta DESPUÉS.
		var a0 := Time.get_ticks_msec()
		Precarga.empezar(get_tree())
		while not Precarga.menu_listo:
			await get_tree().process_frame
		_t["portada: la precarga de scripts del menú tardó"] = Time.get_ticks_msec() - a0
	var antes := _en_cache()
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
	if OS.get_environment("NUEVOS") != "":
		var nuevos: Array[String] = []
		var kb := 0
		for r: String in _en_cache():
			if not antes.has(r):
				nuevos.append(r)
				kb += FileAccess.get_file_as_string(r).length() / 1024 if FileAccess.file_exists(r) else 0
		nuevos.sort()
		print("NUEVOS_EN_EL_MONTAJE %d scripts (~%d KB de fuente): %s" % [nuevos.size(), kb, " ".join(nuevos)])
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

## Los .gd del proyecto que ya están en la caché de recursos (para ver cuáles carga el montaje).
func _en_cache() -> Dictionary:
	var r := {}
	var pila: Array[String] = ["res://"]
	while not pila.is_empty():
		var d: String = pila.pop_back()
		for f: String in DirAccess.get_files_at(d):
			if f.ends_with(".gd") or f.ends_with(".gdc"):
				var ruta := d.path_join(f.trim_suffix("c"))
				if ResourceLoader.has_cached(ruta):
					r[ruta] = true
		for sub: String in DirAccess.get_directories_at(d):
			if sub != ".godot" and sub != "terceros" and sub != "addons":
				pila.append(d.path_join(sub))
	return r
