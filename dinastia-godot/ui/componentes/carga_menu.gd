class_name CargaMenu
extends RefCounted
## LA CARGA ENTRE LA ENTRADA Y EL MENÚ (10-11-2026, arranque). Montar `Principal` (`_ready`: construir la interfaz ~0,85 s y `arrancar_con`/`_refrescar` ~0,96 s con 2 núcleos; medido con
## `pruebas/medir_arranque_menu.tscn`) bloquea el hilo principal 2-4 s en un equipo modesto: el jugador veía un negro o la pantalla anterior congelada. Aquí se reutiliza la `PantallaCarga` de siempre (escudo,
## consejos, barra; la de la ciudad y el estadio) colgada de una capa de la RAÍZ, que sobrevive al cambio de escena: se pinta, la escena se pide en hilo (`ResourceLoader.load_threaded_request`: la barra
## es el progreso REAL de esa carga), se monta (lo que bloquea, con la pantalla ya dibujada encima), se deja unos fotogramas dibujando debajo (shaders y texturas listos) y se quita con un fundido.
## Sin pantalla (banco, `--headless`) o con otra carga en curso, el cambio de escena es el de siempre.

const CAPA := 120
static var _en_curso := false

## Sustituye a `arbol.change_scene_to_file(ruta)` para las escenas pesadas.
## `preparar` (10-11, «Continuar»): lo pesado que hay que hacer ANTES de cambiar (cargar la partida guardada: 0,3 s con 5 países, ~2 s con el mundo entero en PC y varias veces más en un móvil) y que devuelve la ruta de la escena.
## Se llama con la pantalla de carga ya DIBUJADA: antes la entrada se quedaba congelada en su último fotograma mientras se cargaba. Sin pantalla (banco, `--headless`) se llama justo antes del cambio, como siempre.
static func cambiar(arbol: SceneTree, ruta: String, preparar := Callable()) -> void:
	if arbol == null:
		return
	if DisplayServer.get_name() == "headless" or _en_curso or not ResourceLoader.exists(ruta):
		arbol.change_scene_to_file(_ruta_tras(preparar, ruta))
		return
	_en_curso = true
	var capa := CanvasLayer.new()
	capa.name = "CargaMenu"
	capa.layer = CAPA
	arbol.root.add_child(capa)
	var carga := PantallaCarga.mostrar(capa, Idiomas.t("Cargando…"))
	await PantallaCarga.dejar_pintar(arbol)
	ruta = _ruta_tras(preparar, ruta)
	var vieja := arbol.current_scene
	ResourceLoader.load_threaded_request(ruta)
	var prog: Array = []
	var st := ResourceLoader.load_threaded_get_status(ruta, prog)
	while st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if is_instance_valid(carga) and not prog.is_empty():
			carga._destino = maxf(carga._destino, float(prog[0]) * 0.8)
		await arbol.process_frame
		st = ResourceLoader.load_threaded_get_status(ruta, prog)
	var escena: PackedScene = ResourceLoader.load_threaded_get(ruta) as PackedScene if st == ResourceLoader.THREAD_LOAD_LOADED else null
	if is_instance_valid(carga):
		carga._destino = maxf(carga._destino, 0.85)
		carga._etapa.text = Idiomas.t("Preparando tu club…")
	await PantallaCarga.dejar_pintar(arbol)   ## la barra y el texto nuevos, dibujados ANTES del montaje
	PedidoPartida.montaje_en_trozos = OS.get_environment("SIN_TROZOS") == ""   ## (SIN_TROZOS=1: diagnóstico, el montaje de golpe de antes) `Principal._ready` monta la interfaz en trozos (un paso por fotograma) y marca `montaje_listo` al acabar
	PedidoPartida.montaje_avance = 0.0
	if escena != null:
		arbol.change_scene_to_packed(escena)
	else:
		arbol.change_scene_to_file(ruta)
	while arbol.current_scene == vieja or arbol.current_scene == null:
		await arbol.process_frame
	## Con la carga encima, el montaje por trozos se sigue; la carga NO se quita hasta que acaba (la primera vista del menú no sale a medias). Tope de 30 s por si una escena no avisa (no es `Principal`).
	var t0 := Time.get_ticks_msec()
	while not PedidoPartida.montaje_listo and Time.get_ticks_msec() - t0 < 30000:
		if is_instance_valid(carga):
			carga._destino = maxf(carga._destino, 0.85 + 0.14 * PedidoPartida.montaje_avance)
		await arbol.process_frame
	PedidoPartida.montaje_en_trozos = false
	PedidoPartida.montaje_listo = true
	await PantallaCarga.estabilizar(arbol, 4)
	if is_instance_valid(carga):
		carga._destino = 1.0
		carga.cerrar()
	await arbol.create_timer(0.4).timeout
	if is_instance_valid(capa):
		capa.queue_free()
	_en_curso = false

static func _ruta_tras(preparar: Callable, ruta: String) -> String:
	if not preparar.is_valid():
		return ruta
	var r: Variant = preparar.call()
	return String(r) if r is String and String(r) != "" else ruta
