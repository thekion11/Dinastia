extends Node
## Recuento SIN pantalla de lo que cuelga de `EntornoEstadio` (2-11-2026, rendimiento): cuántas piezas de cada nombre/mesh, con cuántas
## superficies (cada superficie visible = una llamada de dibujo) y cuántas son MultiMesh. Sirve para ver qué falta por agrupar.
##   godot --headless --path . res://pruebas/medir_entorno_nodos.tscn
var _vista: VistaEstadio
var _n := 0
func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
func _process(_d: float) -> void:
	_n += 1
	if _n < 60:
		return
	var env: Node = _vista.find_child("EntornoEstadio", true, false)
	var por := {}
	var total_sup := 0
	for g in env.find_children("*", "GeometryInstance3D", true, false):
		if not (g as Node3D).visible or g is Label3D:
			continue
		var clave := ""
		var sup := 1
		if g is MultiMeshInstance3D:
			clave = "MULTIMESH " + String(g.name).rstrip("0123456789@_")
			sup = 1
		elif g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var m := (g as MeshInstance3D).mesh
			clave = "%s %s" % [m.get_class(), String(g.name).rstrip("0123456789@_")]
			sup = m.get_surface_count()
		else:
			clave = g.get_class()
		var d: Array = por.get(clave, [0, 0])
		d[0] += 1
		d[1] += sup
		por[clave] = d
		total_sup += sup
	var filas: Array = por.keys()
	filas.sort_custom(func(a: String, b: String) -> bool: return int(por[a][1]) > int(por[b][1]))
	print("ENTORNO superficies visibles=%d en %d tipos" % [total_sup, filas.size()])
	for k: String in filas.slice(0, 30):
		print("ENT %-60s piezas=%4d superficies=%4d" % [k, por[k][0], por[k][1]])
	print("===== FIN. 0 fallos =====")
	get_tree().quit()
