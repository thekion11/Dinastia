extends Node
## A4 memoria (4-11-2026): qué scripts quedan compilados (en caché) tras abrir el menú de gestión, por carpeta y los mayores. Corre en su propio proceso.
##   godot --headless --path . res://pruebas/a4_mem_cache.tscn
func _scripts(dir: String, salida: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			salida.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		if d.begins_with(".") or d in ["terceros", "addons", "pruebas", "herramientas", "nativo", "bin_nativo", "docs"]:
			continue
		_scripts(dir.path_join(d), salida)

func _ready() -> void:
	var m0 := OS.get_static_memory_usage()
	var antes: Array = []
	var todos: Array = []
	_scripts("res://", todos)
	for r: String in todos:
		if ResourceLoader.has_cached(r):
			antes.append(r)
	var ps := load("res://escenas/principal.tscn") as PackedScene
	var m1 := OS.get_static_memory_usage()
	var pr := ps.instantiate()
	add_child(pr)
	await get_tree().process_frame
	await get_tree().process_frame
	var m2 := OS.get_static_memory_usage()
	var por_dir := {}
	var tam_dir := {}
	var lista: Array = []
	var total_kb := 0
	for r: String in todos:
		if ResourceLoader.has_cached(r):
			var kb := int(FileAccess.get_file_as_bytes(r).size() / 1024)
			total_kb += kb
			var d := r.get_base_dir().trim_prefix("res://")
			por_dir[d] = int(por_dir.get(d, 0)) + 1
			tam_dir[d] = int(tam_dir.get(d, 0)) + kb
			lista.append([kb, r])
	lista.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	print("MEM pantallas perezosas creadas en el primer fotograma: ", pr.get("_perezosas").keys())
	print("MEM scripts totales ", todos.size(), " | en caché tras abrir el menú ", lista.size(), " (", total_kb, " KB de fuente) | ya en caché de las autocargas ", antes.size())
	print("MEM memoria estática: inicio ", int(m0 / 1048576), " MB · tras load(principal.tscn) ", int(m1 / 1048576), " MB · tras instanciar+2 fotogramas ", int(m2 / 1048576), " MB")
	var dirs := tam_dir.keys()
	dirs.sort_custom(func(a: String, b: String) -> bool: return tam_dir[a] > tam_dir[b])
	for d: String in dirs.slice(0, 14):
		print("MEM carpeta ", d, ": ", por_dir[d], " scripts, ", tam_dir[d], " KB")
	for e: Array in lista:
		var d2 := String(e[1]).get_base_dir().trim_prefix("res://")
		if d2 in ["visor", "ui/componentes", "ui", "ui/principal", "ui/competiciones", "ui/menu"]:
			print("MEM ", d2, " ", e[0], " KB ", String(e[1]).get_file())
	get_tree().quit()
