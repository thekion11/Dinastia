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
	Calidad.elegida = Calidad.MINIMO if OS.get_environment("CALIDAD") == "minimo" else Calidad.MEDIO
	Calidad.motor_ligero = OS.get_environment("CALIDAD") == "minimo"
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
		if ahora - anterior > 500:
			print("MEDIDA cuadro largo %d ms en t=%d ms (cuadro %d)" % [ahora - anterior, ahora - t0, i])
		anterior = ahora
		if _p._listo:
			break
	print("MEDIDA carga_prologo_ms %d  (cuadro más largo durante la carga: %d ms)  listo=%s" % [Time.get_ticks_msec() - t0, largo, str(_p._listo)])
	if not _p._listo:
		return
	for i in 30:
		await get_tree().process_frame
	_foto("recién cargado")
	_zonas()
	if OS.get_environment("GRUPOS") != "" and DisplayServer.get_name() != "headless":
		await _grupos()
	var zv := _p.vista.get("_ciudad").get_node_or_null("ZonasVista") as ZonasVista
	if zv != null:
		zv.revisar(_p.explorador.cuerpo.global_position + Vector3(0, 2, 0))
		_zonas()
	print("MEDIDA zonas_vista: %s" % ("apagado" if zv == null else "%d piezas grandes, %d ocultas" % [zv.total(), zv.ocultas()]))
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

## R3 (3-11): de dónde sale el coste de dibujo según la distancia a la cámara: triángulos y objetos por anillo.
func _zonas() -> void:
	var c: Vector3 = _p.explorador.cuerpo.global_position if _p.explorador != null and _p.explorador.cuerpo != null else Vector3.ZERO
	var cortes := [200.0, 400.0, 700.0, 1000.0, 1e9]
	var tris := [0, 0, 0, 0, 0]
	var objs := [0, 0, 0, 0, 0]
	var tmm := [0, 0, 0, 0, 0]   ## triángulos de MultiMesh (instancias × malla)
	for n in _p.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var d := Vector2(g.global_position.x - c.x, g.global_position.z - c.z).length()
		var t := 0
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var m := (g as MeshInstance3D).mesh
			for i in m.get_surface_count():
				var a := m.surface_get_arrays(i)
				var idx = a[Mesh.ARRAY_INDEX]
				t += (idx.size() if idx != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
		elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null and (g as MultiMeshInstance3D).multimesh.mesh != null:
			var mm := (g as MultiMeshInstance3D).multimesh
			var tm := 0
			for i in mm.mesh.get_surface_count():
				var a2 := mm.mesh.surface_get_arrays(i)
				var idx2 = a2[Mesh.ARRAY_INDEX]
				tm += (idx2.size() if idx2 != null else (a2[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
			t = 0
			var kk := 0
			while kk < cortes.size() - 1 and Vector2(g.global_position.x - c.x, g.global_position.z - c.z).length() >= cortes[kk]:
				kk += 1
			tmm[kk] += tm * (mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count)
		for k in cortes.size():
			if d < cortes[k]:
				tris[k] += t
				objs[k] += 1
				break
	print("MEDIDA zonas (triángulos de malla/objetos; triángulos de multimalla) <200 m %d/%d/%d · 200-400 %d/%d/%d · 400-700 %d/%d/%d · 700-1000 %d/%d/%d · >1000 %d/%d/%d" % [tris[0], objs[0], tmm[0], tris[1], objs[1], tmm[1], tris[2], objs[2], tmm[2], tris[3], objs[3], tmm[3], tris[4], objs[4], tmm[4]])

## GRUPOS=1 (con ventana): a pie de calle, apaga por tipo y mide cuántas llamadas/triángulos quita cada tipo.
func _grupos() -> void:
	for i in 6:
		await get_tree().process_frame
	var base := Vector2(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	print("GRUPOS base llamadas=%d tris=%d" % [base.x, base.y])
	var hist := {}
	for n in _p.vista.get("_ciudad").find_children("*", "Label3D", true, false):
		var l := n as Label3D
		var r := "sin límite" if l.visibility_range_end <= 0.0 else "<=%d" % int(ceil(l.visibility_range_end / 25.0) * 25.0)
		var clave := "%s|%s" % [r, String(l.get_parent().name).rstrip("0123456789@_")]
		hist[clave] = int(hist.get(clave, 0)) + 1
	var ks := hist.keys()
	ks.sort_custom(func(a, b): return hist[a] > hist[b])
	for k in ks.slice(0, 14):
		print("GRUPOS label %-40s %d" % [k, hist[k]])
	var tipos := {"MultiMesh": "MultiMeshInstance3D", "Mesh": "MeshInstance3D", "Label3D": "Label3D", "Luces": "Light3D", "Particulas": "GPUParticles3D"}
	var ciudad: Node = _p.vista.get("_ciudad")
	for k: String in tipos:
		var lista: Array = []
		for n in ciudad.find_children("*", String(tipos[k]), true, false):
			if (n as Node3D).visible:
				(n as Node3D).visible = false
				lista.append(n)
		for i in 4:
			await get_tree().process_frame
		var m := Vector2(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		print("GRUPOS sin %-10s (%5d nodos): -%d llamadas  -%d tris" % [k, lista.size(), base.x - m.x, base.y - m.y])
		for n in lista:
			if is_instance_valid(n):
				(n as Node3D).visible = true
		for i in 3:
			await get_tree().process_frame
