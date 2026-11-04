extends Node
## A4 memoria (4-11-2026): qué RECURSOS (texturas, sonidos, fuentes, mallas, escenas) quedan cargados tras el 1.er fotograma del menú de gestión, con su tamaño en disco y (texturas) en memoria.
##   godot --headless --path . res://pruebas/a4_mem_recursos.tscn
const EXT := ["png", "jpg", "jpeg", "webp", "svg", "ogg", "wav", "mp3", "ttf", "otf", "woff2", "glb", "gltf", "tres", "res", "tscn", "obj", "json", "cfg"]
func _buscar(dir: String, salida: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.get_extension().to_lower() in EXT and not f.ends_with(".import"):
			salida.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		if d.begins_with(".") or d in ["terceros", "pruebas", "herramientas", "nativo", "bin_nativo", "docs", "addons"]:
			continue
		_buscar(dir.path_join(d), salida)

func _ready() -> void:
	var m0 := OS.get_static_memory_usage()
	var pr := (load("res://escenas/principal.tscn") as PackedScene).instantiate()
	add_child(pr)
	for i in 3:
		await get_tree().process_frame
	var espera := float(OS.get_environment("ESPERA_S")) if OS.get_environment("ESPERA_S") != "" else 0.0
	if espera > 0.0:
		await get_tree().create_timer(espera).timeout
	var m1 := OS.get_static_memory_usage()
	var todos: Array = []
	_buscar("res://", todos)
	var filas: Array = []
	var por_tipo := {}
	for r: String in todos:
		var ruta := r
		if not ResourceLoader.has_cached(ruta):
			continue
		var kb := int(FileAccess.get_file_as_bytes(ruta).size() / 1024)
		var mem := kb
		var res: Resource = ResourceLoader.load(ruta)
		var tipo: String = res.get_class() if res != null else "?"
		if res is Texture2D:
			var t := res as Texture2D
			mem = int(t.get_width() * t.get_height() * 4 / 1024)
		elif res is AudioStreamWAV:
			mem = int((res as AudioStreamWAV).data.size() / 1024)
		filas.append([mem, kb, tipo, ruta])
		por_tipo[tipo] = [int((por_tipo.get(tipo, [0, 0]) as Array)[0]) + mem, int((por_tipo.get(tipo, [0, 0]) as Array)[1]) + 1]
	filas.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	print("REC estática: tras instanciar ", int(m0 / 1048576), " → tras 3 fotogramas ", int(m1 / 1048576), " MB")
	print("REC recursos en caché (de ", todos.size(), " archivos): ", filas.size())
	for t: String in por_tipo:
		print("REC tipo ", t, ": ", (por_tipo[t] as Array)[1], " recursos, ", int((por_tipo[t] as Array)[0] / 1024), " MB estimados")
	for i in mini(35, filas.size()):
		print("REC mayor ", filas[i][0], " KB (disco ", filas[i][1], ") ", filas[i][2], " ", filas[i][3])
	print("REC textura vídeo MB: ", int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576), " · objetos ", int(Performance.get_monitor(Performance.OBJECT_COUNT)), " · nodos ", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	var son := get_node_or_null("/root/Sonido")
	if son != null:
		var bancos: Variant = son.get("_bancos")
		if bancos is Dictionary:
			var total := 0
			var n := 0
			for k in bancos:
				var v: Variant = bancos[k]
				if v is Array:
					for s in v:
						if s is AudioStreamWAV:
							total += (s as AudioStreamWAV).data.size()
							n += 1
				elif v is AudioStreamWAV:
					total += (v as AudioStreamWAV).data.size()
					n += 1
			print("REC Sonido: ", bancos.size(), " bancos, ", n, " flujos, ", int(total / 1048576), " MB de datos sintetizados")
	var mus := get_node_or_null("/root/Musica")
	if mus != null:
		var c: Variant = mus.get("_cache")
		if c is Dictionary:
			var tm := 0
			for k in c:
				if c[k] is AudioStreamWAV:
					tm += (c[k] as AudioStreamWAV).data.size()
			print("REC Musica: ", (c as Dictionary).size(), " piezas, ", int(tm / 1048576), " MB de datos compuestos")
	get_tree().quit()
