extends Node
## Que textura(s) especificas estan inflando los 980MB de video_mem medidos
## en el partido real -no vale la pena optimizar a ciegas sin saber cual es
## la culpable.

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _frame := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 40:
		_reportar()
		get_tree().quit(0)

func _reportar() -> void:
	## Recorre todos los MeshInstance3D vivos y suma el tamaño (ancho*alto*4
	## bytes, sin contar mipmaps) de cada textura de albedo unica -aproximado,
	## pero suficiente para encontrar a el/los culpables grandes.
	var vistos := {}
	var total := 0
	var lista: Array = []
	_recorrer(get_tree().root, vistos, lista)
	lista.sort_custom(func(a, b): return a["bytes"] > b["bytes"])
	print("--- TEXTURAS UNICAS EN MEMORIA, DE MAYOR A MENOR ---")
	for item in lista.slice(0, 30):
		total += 0  # ya sumado abajo
		print("%6.1f MB  %dx%d  %s" % [item["bytes"] / 1048576.0, item["w"], item["h"], item["nombre"]])
	var suma := 0
	for item in lista:
		suma += item["bytes"]
	print("TOTAL (unicas, sin mipmaps): %.1f MB en %d texturas" % [suma / 1048576.0, lista.size()])
	print("FIN. 0 fallos")

func _recorrer(n: Node, vistos: Dictionary, lista: Array) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for s in range(mi.get_surface_override_material_count()):
			_de_material(mi.get_active_material(s), vistos, lista)
		if mi.mesh:
			for s in range(mi.mesh.get_surface_count()):
				_de_material(mi.mesh.surface_get_material(s), vistos, lista)
	for c in n.get_children():
		_recorrer(c, vistos, lista)

func _de_material(m: Material, vistos: Dictionary, lista: Array) -> void:
	if not (m is StandardMaterial3D):
		return
	var sm := m as StandardMaterial3D
	var texturas: Array = [sm.albedo_texture, sm.normal_texture, sm.roughness_texture, sm.ao_texture]
	for tex_v in texturas:
		var tex: Texture2D = tex_v
		if tex == null:
			continue
		if vistos.has(tex):
			continue
		vistos[tex] = true
		var w: int = tex.get_width()
		var h: int = tex.get_height()
		lista.append({"bytes": w * h * 4, "w": w, "h": h, "nombre": tex.resource_path if tex.resource_path != "" else tex.resource_name})
