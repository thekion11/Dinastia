extends Node
## QUÉ CARGA LA PRIMERA CIUDAD Y EL PRIMER PARTIDO (etapa 3, 8-10-2026).
## Construye la ciudad y abre un partido, y lista los recursos importados
## (modelos, texturas, sonidos) que quedaron en caché, con lo que pesan en
## disco. Con eso se arma la lista de `Precarga`.
##   godot --headless --path . res://pruebas/lista_precarga.tscn
var _n := 0
var _antes := {}
var _todos: Array[String] = []

func _ready() -> void:
	_recorrer("res://assets")
	_recorrer("res://recursos")
	_recorrer("res://visor")
	for r in _todos:
		if ResourceLoader.has_cached(r):
			_antes[r] = true

func _recorrer(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		var ruta := dir + "/" + f
		if f.ends_with(".import"):
			_todos.append(ruta.trim_suffix(".import"))
		elif f.ends_with(".gdshader") or f.ends_with(".tres") or f.ends_with(".tscn"):
			_todos.append(ruta)
	for s in d.get_directories():
		_recorrer(dir + "/" + s)

func _process(_d: float) -> void:
	_n += 1
	if _n == 3:
		var p: Node = load("res://escenas/principal.tscn").instantiate()
		add_child(p)
		p.call("_ver_ciudad_propia")
	if _n == 30:
		var m := Mundo.new()
		m.generar(["CHI"], 4711)
		var par := m.proximo_partido()
		var v := VistaEstadio.new()
		add_child(v)
		v.abrir(par[0], 0.9, par[1], Partido.new(par[0], par[1]))
	if _n == 60:
		var lista := []
		for r in _todos:
			if ResourceLoader.has_cached(r) and not _antes.has(r):
				var tam := FileAccess.get_file_as_bytes(r).size() if FileAccess.file_exists(r) else 0
				lista.append([tam, r])
		lista.sort_custom(func(a, b): return a[0] > b[0])
		var total := 0
		for x in lista:
			total += int(x[0])
			print("PRECARGA %8d  %s" % [x[0], x[1]])
		print("PRECARGA_TOTAL %d recursos, %.1f MB" % [lista.size(), total / 1048576.0])
		get_tree().quit()
