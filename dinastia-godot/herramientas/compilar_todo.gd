extends Node
## (20-11) CARGA TODOS LOS .gd DE res:// y dice cuáles no compilan (el banco no compila todo). Lanzar con `herramientas/compilar_todo.sh`.
func _ready() -> void:
	var n := 0
	var malos: Array = []
	var pila: Array = ["res://"]
	while not pila.is_empty():
		var d: String = pila.pop_back()
		for sub in DirAccess.get_directories_at(d):
			if sub.begins_with(".") or sub == "terceros" or sub == "addons" or sub == "bin_nativo" or sub == "nativo":
				continue
			pila.append(d.path_join(sub))
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				var p := d.path_join(f)
				n += 1
				var s := load(p) as GDScript
				if s == null or not s.can_instantiate():
					malos.append(p)
	print("COMPILADOS %d, FALLAN %d" % [n, malos.size()])
	for m in malos:
		print("MALO ", m)
	get_tree().quit()
