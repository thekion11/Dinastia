extends SceneTree
## La caché horneada del build (`herramientas/hornear_animaciones.gd`, `CacheDisco.cargar_horneada`)
## da bibliotecas idénticas (cada pista, cada clave y las fases de los pies) a las construidas
## en el juego, y se usa de verdad (sin construir). Cada paso en su propio proceso (30-10-2026).
## Los tiempos de clave se comparan en float32: el formato de recurso de Godot los guarda así (el
## juego los calcula en double); medido: valores idénticos y tiempos a menos de 0,9 µs (un
## fotograma son 16.667 µs). Igual que la caché de disco de `CacheDisco` desde el 30-10.

const CARPETA := "user://prueba_horneada"

func _init() -> void:
	if "hijo" in OS.get_cmdline_user_args():
		_hijo.call_deferred()
		return
	var fallos := 0
	var salida := []
	var cod := OS.execute(OS.get_executable_path(), ["--headless", "--path", ".", "--script",
		"res://herramientas/hornear_animaciones.gd", "--", CARPETA], salida, true)
	if cod != 0:
		fallos += 1
		print("FALLO el horneado: ", str(salida[0]).right(400))
	var huellas := []
	for modo in ["construida", "horneada"]:
		OS.set_environment("DINASTIA_SIN_CACHE", "1")
		OS.set_environment("DINASTIA_HORNEADA_DIR", CARPETA if modo == "horneada" else "")
		salida = []
		OS.execute(OS.get_executable_path(), ["--headless", "--path", ".", "--script",
			"res://pruebas/probar_cache_horneada.gd", "--", "hijo"], salida, true)
		var h := ""
		for linea in str(salida[0]).split("\n"):
			if linea.begins_with("HUELLA "):
				h = linea
		print(modo, ": ", h)
		huellas.append(h)
	if huellas[0] == "" or huellas[0].get_slice(" ", 2) != huellas[1].get_slice(" ", 2):
		fallos += 1
		print("FALLO las bibliotecas no son iguales")
	if not huellas[1].ends_with("construidas 0"):
		fallos += 1
		print("FALLO con la caché horneada se construyó alguna")
	print("FIN. %d fallos" % fallos)
	quit()

func _hijo() -> void:
	for exp: bool in [false, true]:
		for cuerpo in ["male", "female"]:
			var d := FutbolistaQ.crear(FutbolistaQ.ALTURA_BASE, cuerpo)
			root.add_child(d["nodo"])
			FutbolistaQ.terminar(d, exp)
	var claves := AnimQuaternius._bibliotecas.keys()
	claves.sort()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	for c in claves:
		ctx.update(str(c).to_utf8_buffer())
		var lib: AnimationLibrary = AnimQuaternius._bibliotecas[c]
		var nombres: Array = Array(lib.get_animation_list()).map(func(x: StringName) -> String: return str(x))
		nombres.sort()   ## como texto: un StringName se ordena por puntero, distinto en cada proceso
		for n in nombres:
			var a := lib.get_animation(n)
			ctx.update(var_to_bytes([n, PackedFloat32Array([a.length]), a.loop_mode, a.get_track_count()]))
			for t in a.get_track_count():
				ctx.update(var_to_bytes([a.track_get_path(t), a.track_get_type(t), a.track_get_key_count(t)]))
				for k in a.track_get_key_count(t):
					ctx.update(var_to_bytes([PackedFloat32Array([a.track_get_key_time(t, k)]), a.track_get_key_value(t, k)]))
	var fases := AnimPasos.fases.keys()
	fases.sort()
	for f in fases:
		ctx.update(var_to_bytes([f, PackedFloat32Array([AnimPasos.fases[f]])]))
	## Construidas: las que no traen la marca de cargadas (el recorte de 1 s no existe sin construir).
	print("HUELLA %d %s construidas %d" % [claves.size(), ctx.finish().hex_encode(), AnimQuaternius._cache_recortes.size()])
	quit()
