extends Node
## A4 rendimiento (4-11-2026): de qué están hechos los ~50.000 nodos de la ciudad en calidad MÍNIMA (la del móvil).
## Baja por el árbol enseñando, en cada nivel, los hijos con más descendientes y de qué clase/script son.
##   CALIDAD=minimo xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/a4_rend_nodos.tscn
var _p: Node
var _n := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MINIMO if OS.get_environment("CALIDAD") != "medio" else Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _tam(x: Node) -> int:
	var t := 1
	for c in x.get_children():
		t += _tam(c)
	return t

func _etiqueta(x: Node) -> String:
	var sc: Variant = x.get_script()
	var s: String = (sc as Script).resource_path.get_file() if sc != null else "-"
	var extra := ""
	if x is Label3D: extra = " texto=«%s»" % (x as Label3D).text.left(16).replace("\n", "/")
	if x is MultiMeshInstance3D and (x as MultiMeshInstance3D).multimesh != null: extra = " inst=%d" % (x as MultiMeshInstance3D).multimesh.instance_count
	return "%s %s [%s]%s" % [x.get_class(), String(x.name).left(24), s, extra]

func _bajar(x: Node, prof: int, sangria: String) -> void:
	if prof > 4:
		return
	var hs: Array = []
	for c in x.get_children():
		hs.append([_tam(c), c])
	hs.sort_custom(func(a, b): return a[0] > b[0])
	for i in mini(5, hs.size()):
		print("%s%6d  %s  (hijos %d)" % [sangria, hs[i][0], _etiqueta(hs[i][1]), hs[i][1].get_child_count()])
		if hs[i][0] > 600:
			_bajar(hs[i][1], prof + 1, sangria + "    ")

func return_ok() -> void:
	get_tree().quit()

func _process(_d: float) -> void:
	_n += 1
	Engine.max_fps = 0
	if _n == 5:
		_p.call("_ver_ciudad_propia")
	if _n == 60:
		var v: Node = null
		for h in _p.get_children():
			if h is VistaCiudad: v = h
		var raiz: Node = null
		for c in v.find_children("*", "Node3D", true, false):
			if c.get_child_count() > 20000: raiz = c
		var hs := raiz.get_children()
		var vacios := []
		var tipos := {}
		for i in hs.size():
			var c: Node = hs[i]
			tipos[c.get_class()] = int(tipos.get(c.get_class(), 0)) + 1
			if c.get_class() == "Node3D" and c.get_child_count() == 0:
				vacios.append(i)
		print("RAIZ hijos=", hs.size(), " tipos=", tipos, " vacios=", vacios.size())
		for k in [0, 1, 2, 500, 1500, 3000]:
			if k < vacios.size():
				var i: int = vacios[k]
				print("VACIO #", i, " ", _etiqueta(hs[i]), " pos=", (hs[i] as Node3D).position, " metas=", hs[i].get_meta_list(), " grupos=", hs[i].get_groups())
				for d in [-2, -1, 1, 2]:
					if i + d >= 0 and i + d < hs.size(): print("      vecino", d, _etiqueta(hs[i + d]))
		return_ok()
		return
		get_tree().quit()
