class_name MedirPartidoModos
extends RefCounted
## MODOS DE MEDIDA DEL PARTIDO JUGABLE (13-11-2026, orden del dueño: +15 FPS): sacados de `medir_partido_jugable.gd` (norma de 450 líneas). Cada uno se activa con su variable de entorno
## y trabaja sobre la MISMA escena congelada: MESH_LOD, MULTI, LOD_BARRIDO, ROTULOS, PIEZAS, PELO, TRANSP, VIEWPORTS, CONOS y CAPTURA (ver `docs/04_auditorias/rendimiento_120fps.md`, sesión 16).
var raiz: Node
var _pj: PartidoJugable

func _init(r: Node, pj: PartidoJugable) -> void:
	raiz = r
	_pj = pj

func _llamadas() -> int:
	for i in 3:
		await raiz.get_tree().process_frame
	return int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))

func _conteos(etiqueta: String) -> void:
	await raiz.get_tree().process_frame
	await raiz.get_tree().process_frame
	print("MEDIDA %s: llamadas=%d triangulos=%d objetos=%d nodos=%d video=%.0fMB" % [etiqueta,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])

func _ms_pared() -> float:
	for i in 6:
		await raiz.get_tree().process_frame
	var v: Array = []
	for i in 40:
		var t0 := Time.get_ticks_usec()
		await raiz.get_tree().process_frame
		v.append(float(Time.get_ticks_usec() - t0) / 1000.0)
	v.sort()
	return v[v.size() / 2]

func _distintos(a: Image, b: Image) -> int:
	var n := 0
	for y in a.get_height():
		for x in a.get_width():
			var p := a.get_pixel(x, y)
			var q := b.get_pixel(x, y)
			if maxf(absf(p.r - q.r), maxf(absf(p.g - q.g), absf(p.b - q.b))) > 3.0 / 255.0:
				n += 1
	return n

## Milisegundos de pared de los `n` fotogramas siguientes.
func _fotogramas(n: int) -> Array:
	var v: Array = []
	for i in n:
		var t0 := Time.get_ticks_usec()
		await raiz.get_tree().process_frame
		v.append(float(Time.get_ticks_usec() - t0) / 1000.0)
	return v

## (13-11) EFECTOS=1|2: el PRIMER uso de cada efecto del partido (la primera vez que se dibuja el driver compila el sombreador). Para cada efecto: mediana de 20 fotogramas
## de la escena en marcha, y el peor de los 8 siguientes al lanzarlo. EFECTOS=2 hace antes el calentamiento (`CalentamientoEfectos`).
func _efectos() -> void:
	if OS.get_environment("EFECTOS") == "2":
		var t0 := Time.get_ticks_usec()
		CalentamientoEfectos.calentar(_pj._raiz)
		print("CALENTAMIENTO cuesta %.1f ms de CPU al montar" % (float(Time.get_ticks_usec() - t0) / 1000.0))
		await _fotogramas(40)
	var r: Node3D = _pj._raiz
	var c1 := Color(_pj.motor.local_color1) if "local_color1" in _pj.motor else Color(0.8, 0.1, 0.1)
	var lanzamientos := {
		"confeti y bengalas": func() -> void: FestejoGrada.lanzar(r, c1, Color.WHITE, "calentamiento"),
		"confeti y bengalas (2.ª)": func() -> void: FestejoGrada.lanzar(r, c1, Color.WHITE, "calentamiento"),
		"confeti y bengalas (3.ª)": func() -> void: FestejoGrada.lanzar(r, c1, Color.WHITE, "calentamiento"),
		"banderas del gol": func() -> void: BanderasGrada.lanzar(r, c1, Color.WHITE, FestejoGrada._sitios_de_grada(r), 8.0),
		"red del arco": func() -> void:
			for ra in r.find_children("RedArco*", "", true, false):
				if (ra as RedArco).panos.size() > 0 and is_instance_valid((ra as RedArco).panos[0]):
					RedArco.golpe(r, (ra as RedArco).panos[0].global_position)
					break,
		"ola de la grada": func() -> void: OlaGrada.lanzar(r, "ola"),
		"onda de la grada": func() -> void: OlaGrada.lanzar(r, "onda", Vector3.ZERO),
		"protesta de la grada": func() -> void: OlaGrada.lanzar(r, "protesta"),
		"lluvia": func() -> void: Precipitacion.montar(r, "lluvia", 60.0, 100.0, Calidad.elegida)}
	for k in lanzamientos:
		var antes: Array = await _fotogramas(20)
		antes.sort()
		(lanzamientos[k] as Callable).call()
		var despues: Array = await _fotogramas(8)
		var peor := 0.0
		for m: float in despues:
			peor = maxf(peor, m)
		var serie := ""
		for m: float in despues:
			serie += "%.0f " % m
		print("SERIE %-26s %s" % [k, serie])
		print("EFECTO %-26s mediana antes %6.1f ms · peor de los 8 siguientes %6.1f ms · pico %+6.1f ms" % [k, antes[antes.size() / 2], peor, peor - float(antes[antes.size() / 2])])

## true si corrió algún modo (el llamador debe terminar).
func correr() -> bool:
	if OS.get_environment("CALENTAR") != "":
		## (13-11) CALENTAR=1: el calentamiento de efectos es INVISIBLE: misma escena con tiempo parado, con los efectos del calentamiento vivos y dibujándose, y sin ellos.
		Engine.time_scale = 0.0
		CalentamientoEfectos.calentar(_pj._raiz)
		for i in 4:
			await raiz.get_tree().process_frame
		var vivos := _pj._raiz.find_children("FestejoGrada*", "", true, false) + _pj._raiz.find_children("BanderasGrada*", "", true, false)
		var con := raiz.get_viewport().get_texture().get_image()
		for v in vivos:
			v.visible = false if v is Node3D else true
			v.queue_free()
		for i in 4:
			await raiz.get_tree().process_frame
		var sin := raiz.get_viewport().get_texture().get_image()
		print("CALENTAR efectos vivos: %d · píxeles distintos (tolerancia 3/255) con/sin calentamiento: %d de %d" % [vivos.size(), _distintos(con, sin), con.get_width() * con.get_height()])
		raiz.get_tree().quit()
		return true
	if OS.get_environment("EFECTOS") != "":
		await _efectos()
		raiz.get_tree().quit()
		return true
	if OS.get_environment("MESH_LOD") != "":
		_pj._vp.mesh_lod_threshold = float(OS.get_environment("MESH_LOD"))   ## (13-11) umbral de LOD del viewport del partido, para comparar
	if OS.get_environment("CAPTURA") != "":
		## (13-11) CAPTURA=ruta.jpg: la imagen de la cámara real del partido (con pantalla), para comparar antes/después de un cambio visual.
		await raiz.get_tree().process_frame
		raiz.get_viewport().get_texture().get_image().save_jpg(OS.get_environment("CAPTURA"), 0.92)
		raiz.get_tree().quit()
		return true
	if OS.get_environment("CONOS") != "":
		## (13-11) CONOS=1: tiempo de pared por fotograma con los conos de luz de los focos (alfa 0 de día) encendidos y apagados, ALTERNADOS en la misma ejecución (así el ruido de la máquina se reparte entre los dos).
		var conos := raiz.get_tree().get_nodes_in_group("foco_cono")
		print("CONOS %d nodos, alfa del material %.3f" % [conos.size(), ((conos[0] as MeshInstance3D).material_override as StandardMaterial3D).albedo_color.a if conos.size() > 0 else -1.0])
		if OS.get_environment("CONOS") == "2":
			Engine.time_scale = 0.0   ## para que nada (animaciones, sombreadores con TIME) cambie entre capturas
			await raiz.get_tree().process_frame
			## CONOS=2: la MISMA escena congelada con los conos mostrados y con los conos ocultos: píxeles distintos (debe ser 0 si su alfa es 0).
			for n in conos:
				(n as MeshInstance3D).visible = true
			await raiz.get_tree().process_frame
			await raiz.get_tree().process_frame
			var img_a := raiz.get_viewport().get_texture().get_image()
			for n in conos:
				(n as MeshInstance3D).visible = false
			await raiz.get_tree().process_frame
			await raiz.get_tree().process_frame
			var img_b := raiz.get_viewport().get_texture().get_image()
			for n in conos:
				(n as MeshInstance3D).visible = false
			await raiz.get_tree().process_frame
			await raiz.get_tree().process_frame
			var img_c := raiz.get_viewport().get_texture().get_image()   ## CONTROL: la misma configuración (conos ocultos) otra vez, para ver el ruido de la escena
			var dif_conos := _distintos(img_a, img_b)
			var dif_control := _distintos(img_b, img_c)
			print("CONOS píxeles distintos (tolerancia 3/255, de %d): con/sin conos %d, CONTROL (sin conos dos veces) %d" % [img_a.get_width() * img_a.get_height(), dif_conos, dif_control])
			raiz.get_tree().quit()
			return true
		var con: Array = []
		var sin: Array = []
		for ronda in 8:
			for estado in [true, false]:
				for n in conos:
					(n as MeshInstance3D).visible = estado
				var m := await _ms_pared()
				(con if estado else sin).append(m)
		con.sort()
		sin.sort()
		print("CONOS con=%.1f ms  sin=%.1f ms  (medianas de %d rondas alternadas; llamadas con/sin: ver base)" % [con[con.size() / 2], sin[sin.size() / 2], con.size()])
		raiz.get_tree().quit()
		return true
	if OS.get_environment("VIEWPORTS") != "":
		## (13-11) VIEWPORTS=1: todos los SubViewport vivos del árbol (también fuera del partido), su tamaño, modo de actualización y si se ven.
		for sv in raiz.get_tree().root.find_children("*", "SubViewport", true, false):
			var v := sv as SubViewport
			var c := v.get_parent()
			var vis := c is CanvasItem and (c as CanvasItem).is_visible_in_tree()
			print("VIEWPORT %-28s %4dx%-4d modo=%d contenedor_visible=%s padre=%s" % [str(v.get_path()).right(40), v.size.x, v.size.y, v.render_target_update_mode, str(vis), c.get_class()])
		raiz.get_tree().quit()
		return true
	if OS.get_environment("TRANSP") != "":
		## (13-11) TRANSP=1: mallas visibles con transparencia o mezcla (sobredibujo), por nombre: cuántas y el área mayor de su caja (m²).
		var tr := {}
		for mi in _pj.find_children("*", "GeometryInstance3D", true, false):
			var g := mi as GeometryInstance3D
			if not g.is_visible_in_tree() or g is Label3D:
				continue
			var mats: Array = []
			if g.material_override != null:
				mats.append(g.material_override)
			if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
				for si in (g as MeshInstance3D).mesh.get_surface_count():
					var mt: Material = (g as MeshInstance3D).get_active_material(si)
					if mt != null:
						mats.append(mt)
			var trans := false
			for mt in mats:
				if mt is BaseMaterial3D and (mt as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					trans = true
				elif mt is ShaderMaterial and (mt as ShaderMaterial).shader != null and (mt as ShaderMaterial).shader.code.contains("blend_"):
					trans = true
			if not trans:
				continue
			var det := ""
			for mt in mats:
				if mt is BaseMaterial3D:
					var bm := mt as BaseMaterial3D
					det = " modo=%d alfa=%.2f tex=%s scissor=%.2f cull=%d prof=%d" % [bm.transparency, bm.albedo_color.a, str(bm.albedo_texture != null), bm.alpha_scissor_threshold, bm.cull_mode, bm.depth_draw_mode]
					break
				elif mt is ShaderMaterial:
					det = " shader=" + String((mt as ShaderMaterial).shader.resource_path).get_file()
					break
			var k := String(g.name).rstrip("0123456789@_") + " <" + String(g.get_parent().name).rstrip("0123456789@_") + ">" + det
			var ab := g.get_aabb().size
			if OS.get_environment("TRANSP") == "2" and det.contains("alfa=0.00"):
				print("ALFA0 %s mesh=%s aabb=%s pos=%s abuelo=%s script=%s" % [str(g.get_path()).right(70), (g as MeshInstance3D).mesh.get_class() if g is MeshInstance3D else "-", str(g.get_aabb().size.snapped(Vector3.ONE * 0.1)), str(g.global_position.snapped(Vector3.ONE)), g.get_parent().get_parent().name if g.get_parent().get_parent() != null else "-", str(g.get_parent().get_script().resource_path if g.get_parent().get_script() != null else "")])
			var f: Array = tr.get(k, [0, 0.0])
			f[0] += 1; f[1] = maxf(f[1], maxf(ab.x * ab.z, maxf(ab.x * ab.y, ab.y * ab.z)))
			tr[k] = f
		for k in tr:
			print("TRANSP x%-3d área máx %7.0f m²  %s" % [tr[k][0], tr[k][1], k])
		raiz.get_tree().quit()
		return true
	if OS.get_environment("PELO") != "":
		## (13-11) PELO=1: sobre la MISMA escena congelada, triángulos al cambiar la distancia a la que el pelo pasa de `Cuero` (cerca) a `CueroLejos`.
		for d in [22.0, 15.0, 10.0, 6.0, 3.0]:
			for j in _pj.motor.jugadores:
				for mi in ((j as Dictionary)["node"] as Node3D).find_children("*", "MeshInstance3D", true, false):
					var kn := String(mi.name).rstrip("0123456789@_")
					if kn == "Cuero":
						(mi as MeshInstance3D).visibility_range_end = d
					elif kn == "CueroLejos":
						(mi as MeshInstance3D).visibility_range_begin = d
			await _conteos("pelo_lejos_desde=%.0f m" % d)
		raiz.get_tree().quit()
		return true
	if OS.get_environment("PIEZAS") != "":
		## (13-11) PIEZAS=1: sobre la MISMA escena congelada, lo que baja ocultar cada pieza de los jugadores (por nombre de malla): llamadas y triángulos.
		var base_c: int = await _llamadas()
		var base_t := int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		print("PIEZA base %d llamadas %d triángulos" % [base_c, base_t])
		var nombres := {}
		for j in _pj.motor.jugadores:
			for mi in ((j as Dictionary)["node"] as Node3D).find_children("*", "MeshInstance3D", true, false):
				var kn := String(mi.name).rstrip("0123456789@_")
				if not nombres.has(kn):
					nombres[kn] = []
				(nombres[kn] as Array).append(mi)
		for kn in nombres:
			for mi in nombres[kn]:
				(mi as MeshInstance3D).visible = false
			var c2: int = await _llamadas()
			var t2 := int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
			for mi in nombres[kn]:
				(mi as MeshInstance3D).visible = true
			print("PIEZA -%3d llamadas  -%6d triángulos  %s (x%d)" % [base_c - c2, base_t - t2, kn, (nombres[kn] as Array).size()])
		raiz.get_tree().quit()
		return true
	if OS.get_environment("ROTULOS") != "":
		## (13-11) ROTULOS=1: distancia de cada Label3D a la cámara del partido, por padre (mínima y máxima) y cuántos hay.
		var dist := {}
		for l in _pj.find_children("*", "Label3D", true, false):
			var lab := l as Label3D
			if not lab.is_visible_in_tree():
				continue
			var d := _pj._cam.global_position.distance_to(lab.global_position)
			var kp := String(lab.get_parent().name).rstrip("0123456789@_-") + (" [con rango %.0f]" % lab.visibility_range_end if lab.visibility_range_end > 0.0 else "")
			var f: Array = dist.get(kp, [0, 1e9, 0.0])
			f[0] += 1; f[1] = minf(f[1], d); f[2] = maxf(f[2], d)
			dist[kp] = f
		for k in dist:
			print("ROTULO x%-3d dist %5.0f–%5.0f m  %s" % [dist[k][0], dist[k][1], dist[k][2], k])
		raiz.get_tree().quit()
		return true
	if OS.get_environment("MULTI") != "":
		## (13-11) MULTI=1: triángulos de cada MultiMesh del partido (instancias dibujadas × triángulos de su malla), por nombre.
		var por := {}
		for mm in _pj.find_children("*", "MultiMeshInstance3D", true, false):
			var m := mm as MultiMeshInstance3D
			if m.multimesh == null or m.multimesh.mesh == null or not m.is_visible_in_tree():
				continue
			var n_i := m.multimesh.visible_instance_count if m.multimesh.visible_instance_count >= 0 else m.multimesh.instance_count
			var tri := 0
			for si in m.multimesh.mesh.get_surface_count():
				var arr := m.multimesh.mesh.surface_get_arrays(si)
				tri += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if arr[Mesh.ARRAY_INDEX] != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
			var k := String(m.name).rstrip("0123456789@_")
			var f: Array = por.get(k, [0, 0, 0])
			f[0] += 1; f[1] += n_i; f[2] += n_i * tri
			por[k] = f
		var ks := por.keys()
		ks.sort_custom(func(x, y) -> bool: return por[x][2] > por[y][2])
		for k in ks.slice(0, 20):
			print("MULTI x%-3d instancias=%-7d triángulos=%-8d %s" % [por[k][0], por[k][1], por[k][2], k])
		raiz.get_tree().quit()
		return true
	if OS.get_environment("LOD_BARRIDO") != "":
		## (13-11) LOD_BARRIDO=1: sobre la MISMA escena congelada, triángulos y llamadas para cada umbral de LOD (cámara y momento fijos, sin ruido).
		for u in [1.0, 3.0, 6.0, 12.0, 24.0, 48.0, 96.0, 200.0]:
			_pj._vp.mesh_lod_threshold = u
			await _conteos("LOD=%.0f" % u)
		raiz.get_tree().quit()
		return true
	return false
