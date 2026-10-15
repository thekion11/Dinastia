extends Node
## PERFIL POR ÁRBOL (14-10-2026): apaga cada grupo de la escena del partido, de uno
## en uno, y mide cuántos triángulos y llamadas de dibujo se ahorran con la cámara
## de TV (espera varios fotogramas tras cada cambio: el contador va retrasado).
##   godot --path . --rendering-driver vulkan --resolution 1280x720 res://pruebas/perfil_arbol.tscn
func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	var vista := VistaEstadio.new()
	add_child(vista)
	vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	for i in 45:
		await get_tree().process_frame
	(vista.get("_rig") as CameraRig).switch_to(0)
	for i in 10:
		await get_tree().process_frame
	var raiz: Node3D = vista.get("_raiz3d")
	var base := await _medir()
	print("PERFIL base: %d tris, %d llamadas" % [base.x, base.y])
	var filas: Array = []
	for c in raiz.get_children():
		if not (c is Node3D) or c is Light3D:
			continue
		var grupos: Array = [c]
		for g in c.get_children():
			if g is Node3D and c.get_child_count() > 8 and c.get_child_count() < 200:
				grupos.append(g)
		for g: Node3D in grupos:
			var v0 := g.visible
			g.visible = false
			var m := await _medir()
			g.visible = v0
			var ahorro := base.x - m.x
			if ahorro > 20000:
				filas.append([ahorro, base.y - m.y, String(g.get_parent().name) + "/" + String(g.name)])
	filas.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for f: Array in filas.slice(0, 25):
		print("PERFIL %8d tris  %4d llamadas  %s" % [f[0], f[1], f[2]])
	get_tree().quit()

func _medir() -> Vector2:
	for i in 5:
		await get_tree().process_frame
	return Vector2(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
