extends BaseIdea
## MEDIDOR DEL PRÓLOGO (2-11-2026, orden urgente del dueño: el prólogo se congela, se pasa de memoria y se cierra; debe ir el
## triple de rápido y no cargar toda la ciudad). Arranca `escenas/prologo.tscn` como lo hace el juego y apunta, de cada fase:
## tiempo, nodos, objetos, memoria estática y (con ventana) llamadas de dibujo. Después camina por la ciudad y mide el coste
## por cuadro y lo que crece la memoria. Imprime una línea `MEDIDA …` por fase para comparar antes/después.
##   godot --headless --path . res://pruebas/medir_prologo.tscn           (CPU: construcción, nodos, memoria)
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/medir_prologo.tscn   (+ dibujo)

var _p: PrologoDT

func _ready() -> void:
	await get_tree().process_frame
	await _medir()
	get_tree().quit(0)

func _foto(fase: String, extra := "") -> void:
	print("MEDIDA %-22s nodos %6d  objetos %7d  mem_estatica %6.0f MB  dibujo %5d  prim %8d %s" % [fase,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), extra])

func _medir() -> void:
	Calidad.elegida = Calidad.MEDIO
	var m := _mundo(4242)
	_foto("antes del prólogo")
	PedidoPartida.mundo_pregenerado = m
	PedidoPartida.modo_elegido = "dt"
	PedidoPartida.dt_nombre_elegido = "Míster Prueba"
	PrologoDT.rapido = true
	var t0 := Time.get_ticks_msec()
	_p = (load("res://escenas/prologo.tscn") as PackedScene).instantiate()
	add_child(_p)
	var largo := 0
	var anterior := Time.get_ticks_msec()
	for i in 1800:
		await get_tree().process_frame
		var ahora := Time.get_ticks_msec()
		largo = maxi(largo, ahora - anterior)
		anterior = ahora
		if _p._listo:
			break
	print("MEDIDA carga_prologo_ms %d  (cuadro más largo durante la carga: %d ms)  listo=%s" % [Time.get_ticks_msec() - t0, largo, str(_p._listo)])
	if not _p._listo:
		return
	for i in 30:
		await get_tree().process_frame
	_foto("recién cargado")
	var e: ExploradorCiudad = _p.explorador
	## Camina 40 s de juego a ~6 m/s hacia el centro de la ciudad, midiendo el coste por cuadro.
	var cuadros := 0
	var suma := 0
	var peor := 0
	var mem0 := Performance.get_monitor(Performance.MEMORY_STATIC)
	var dir := Vector3(1, 0, -0.3).normalized()
	anterior = Time.get_ticks_msec()
	var n_paseo := 1200 if DisplayServer.get_name() == "headless" else 150   ## con ventana (render por software) cada cuadro cuesta mucho
	for i in n_paseo:
		if e != null and e.cuerpo != null:
			e.cuerpo.position += dir * (0.1 if n_paseo > 200 else 0.8)
		await get_tree().process_frame
		var ahora2 := Time.get_ticks_msec()
		var dt := ahora2 - anterior
		anterior = ahora2
		if i > 20:
			cuadros += 1
			suma += dt
			peor = maxi(peor, dt)
	_foto("tras caminar 120 m", "media %.1f ms/cuadro, peor %d ms, mem +%.0f MB" % [float(suma) / maxf(cuadros, 1), peor, (Performance.get_monitor(Performance.MEMORY_STATIC) - mem0) / 1048576.0])
	## ENTRAR AL ESTADIO a pie (el paso que pide moverse al personaje: aquí se construye el interior y vuelven las butacas buenas).
	e.cuerpo.position = _p.puerta
	await get_tree().process_frame
	var mem1 := Performance.get_monitor(Performance.MEMORY_STATIC)
	var t1 := Time.get_ticks_msec()
	e._entrar_al_estadio()
	await get_tree().process_frame
	var primer := Time.get_ticks_msec() - t1
	var peor2 := primer
	anterior = Time.get_ticks_msec()
	for i in 90 if DisplayServer.get_name() == "headless" else 20:
		await get_tree().process_frame
		var ahora3 := Time.get_ticks_msec()
		peor2 = maxi(peor2, ahora3 - anterior)
		anterior = ahora3
	_foto("dentro del estadio", "entrar: %d ms en el primer cuadro, peor cuadro %d ms, mem +%.0f MB, estado %s" % [primer, peor2, (Performance.get_monitor(Performance.MEMORY_STATIC) - mem1) / 1048576.0, String(e.estado)])
	_desglose(_p.vista._raiz3d)

## Dónde están las llamadas de dibujo (estimadas: una por superficie de cada malla visible y una por MultiMesh), agrupadas
## por el nombre del hijo directo de la raíz 3D y, dentro de la ciudad, de su constructor. Para saber qué recortar.
func _desglose(raiz: Node) -> void:
	var por: Dictionary = {}
	for n: Node in raiz.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var calls := 1
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			calls = maxi(1, (g as MeshInstance3D).mesh.get_surface_count())
		var camino := raiz.get_path_to(g)
		var clave := String(camino.get_name(0)) if camino.get_name_count() > 0 else "?"
		if camino.get_name_count() > 1 and clave.begins_with("CityBuilder"):
			clave += "/" + String(camino.get_name(1)).rstrip("0123456789")
		por[clave] = int(por.get(clave, 0)) + calls
	var claves := por.keys()
	claves.sort_custom(func(a: String, b: String) -> bool: return int(por[a]) > int(por[b]))
	for k: String in claves.slice(0, 14):
		print("MEDIDA   dibujo≈%5d  %s" % [int(por[k]), k])
