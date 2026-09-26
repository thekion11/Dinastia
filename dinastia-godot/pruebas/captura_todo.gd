extends Node
## RECORRIDO VISUAL (26-9-2026, D4): una captura por cada chip del menú, para
## cazar fallas visuales. Deja `pruebas/recorrido/NN_grupo_chip.png`.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_todo.tscn
var _n := 0
var _p: Node
var _cola: Array = []
var _i := 0
var _espera := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/recorrido"))
	for g: Dictionary in _p.get("GRUPOS"):
		for chip: Dictionary in g["tabs"]:
			_cola.append([String(g["id"]), chip])

func _process(_d: float) -> void:
	_n += 1
	if _n < 12:
		return
	if _espera > 0:
		_espera -= 1
		if _espera == 0:
			var par: Array = _cola[_i]
			var nombre := "%02d_%s_%s" % [_i, String(par[0]), String((par[1] as Dictionary)["label"]).to_lower().replace(" ", "_")]
			get_viewport().get_texture().get_image().save_png("res://pruebas/recorrido/%s.png" % nombre)
			_i += 1
		return
	if _i >= _cola.size():
		get_tree().quit()
		return
	var par2: Array = _cola[_i]
	_p.call("_elegir_grupo", String(par2[0]))
	_p.call("_ir_a_chip", par2[1])
	_espera = 22
