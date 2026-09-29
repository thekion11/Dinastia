extends Node
## LOS CINCO ESCALONES DE `RendimientoAdaptativo` (25-9-2026).
##
##   godot --headless --path . res://pruebas/probar_rendimiento_adaptativo.tscn
##
## En un servidor sin GPU los FPS no dicen nada, así que se fuerzan los
## escalones con `bajar()` y se comprueba que cada uno toca lo que dice, en
## orden, y que al cerrar el estadio la resolución del 3D vuelve a ser la de
## siempre. Sale con código 1 si algo falla.

var _fallos := 0

func _comprobar(c: bool, que: String) -> void:
	print(("  ok    " if c else "  FALLO ") + que)
	if not c:
		_fallos += 1

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var club: Club = m.ligas[0].clubes[0]
	var vista := VistaEstadio.new()
	add_child(vista)
	vista.abrir(club, 0.8, m.ligas[0].clubes[1])
	var raiz: Node3D = vista.get("_raiz3d")
	var ra := RendimientoAdaptativo.new()
	ra.raiz3d = raiz
	vista.add_child(ra)
	var env: Environment = (RendimientoAdaptativo._todos(raiz, "WorldEnvironment")[0] as WorldEnvironment).environment
	var sol: DirectionalLight3D = null
	for l in RendimientoAdaptativo._todos(raiz, "DirectionalLight3D"):
		if (l as DirectionalLight3D).shadow_enabled:
			sol = l
	_comprobar(env != null and sol != null, "el estadio tiene entorno y sol con sombra")
	var avisos: Array[String] = []
	ra.escalon_aplicado.connect(func(_e: int, que: String) -> void: avisos.append(que))
	ra.bajar()
	_comprobar(not env.ssao_enabled, "escalón 1: sin oclusión ambiental")
	ra.bajar()
	_comprobar(sol.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS \
		and sol.directional_shadow_max_distance <= 120.0, "escalón 2: dos cascadas y sombra hasta 120 m")
	ra.bajar()
	var livianas := true
	var cuantas := 0
	for n in raiz.find_children("ButacasCerca*", "MultiMeshInstance3D", true, false):
		cuantas += 1
		livianas = livianas and (n as MultiMeshInstance3D).multimesh.mesh == StadiumBuilder._malla_butaca_lejos()
	_comprobar(cuantas > 0 and livianas, "escalón 3: butacas cercanas con la malla liviana (%d tribunas)" % cuantas)
	ra.bajar()
	_comprobar(is_equal_approx(get_viewport().scaling_3d_scale, 0.8) \
		and get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR, "escalón 4: 3D al 80% con FSR")
	ra.bajar()
	_comprobar(is_equal_approx(get_viewport().scaling_3d_scale, 0.67), "escalón 5: 3D al 67%")
	ra.bajar()
	_comprobar(ra.escalon == 5 and avisos.size() == 5, "no hay sexto escalón, y avisó de los cinco")
	vista.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_comprobar(is_equal_approx(get_viewport().scaling_3d_scale, 1.0), "al cerrar el estadio el 3D vuelve al 100%")
	print("probar_rendimiento_adaptativo: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
