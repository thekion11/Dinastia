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
static func cambiar(arbol: SceneTree, ruta: String) -> void:
	if arbol == null:
		return
	if DisplayServer.get_name() == "headless" or _en_curso or not ResourceLoader.exists(ruta):
		arbol.change_scene_to_file(ruta)
		return
	_en_curso = true
	var capa := CanvasLayer.new()
	capa.name = "CargaMenu"
	capa.layer = CAPA
	arbol.root.add_child(capa)
	var carga := PantallaCarga.mostrar(capa, Idiomas.t("Cargando…"))
	await PantallaCarga.dejar_pintar(arbol)
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
	await PantallaCarga.dejar_pintar(arbol)   ## la barra y el texto nuevos, dibujados ANTES de que el montaje bloquee el hilo
	if escena != null:
		arbol.change_scene_to_packed(escena)
	else:
		arbol.change_scene_to_file(ruta)
	while arbol.current_scene == vieja or arbol.current_scene == null:
		await arbol.process_frame
	await PantallaCarga.estabilizar(arbol, 4)
	if is_instance_valid(carga):
		carga._destino = 1.0
		carga.cerrar()
	await arbol.create_timer(0.4).timeout
	if is_instance_valid(capa):
		capa.queue_free()
	_en_curso = false
