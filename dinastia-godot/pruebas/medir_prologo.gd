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
	var cam_ := get_viewport().get_camera_3d()
	extra += " far=%s" % (str(snappedf(cam_.far, 1.0)) if cam_ != null else "sin cámara")
	extra += " vram=%.0f MB (texturas %.0f, buffers %.0f) audio_ram=%.0f MB" % [Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0, 0.0]
	print("MEDIDA %-22s nodos %6d  objetos %7d  mem_estatica %6.0f MB  dibujo %5d  prim %8d %s" % [fase,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), extra])

func _medir() -> void:
	Calidad.elegida = Calidad.MINIMO if OS.get_environment("CALIDAD") == "minimo" else Calidad.MEDIO
	Calidad.motor_ligero = OS.get_environment("CALIDAD") == "minimo"
	_foto("inicio (autocargas)")
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
	if OS.get_environment("TEXTURAS") != "":
		_texturas()
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
	if OS.get_environment("DETALLE") != "":
		_dibujado(_p.vista._raiz3d)

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
	if OS.get_environment("GRUPOS") == "2":
		await _grupos_nombre(ciudad, base)

## GRUPOS=2 (3-11): lo mismo por NOMBRE (nodo o, si no tiene nombre propio, su padre): cuántas llamadas quita ocultar cada grupo de mallas/multimallas.
func _llamadas() -> float:
	for i in 3:
		await get_tree().process_frame
	return Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)

func _grupos_nombre(ciudad: Node, base: Vector2) -> void:
	if OS.get_environment("MMHIST") != "":
		var nodos := ciudad.find_children("*", "MultiMeshInstance3D", true, false)
		var por := {}
		var tam := {}
		for n in nodos:
			var mm := (n as MultiMeshInstance3D).multimesh
			if mm == null or mm.mesh == null:
				continue
			var g := n as MultiMeshInstance3D
			var c := g.global_position
			var k := "%d|%d|%d,%d|%d|%d" % [mm.mesh.get_instance_id(), g.material_override.get_instance_id() if g.material_override != null else 0, floori(c.x / 160.0), floori(c.z / 160.0), int(g.visibility_range_end), int(mm.use_colors)]
			por[k] = int(por.get(k, 0)) + 1
			var b2 := "%d" % mini(mm.instance_count, 64)
			tam[b2] = int(tam.get(b2, 0)) + 1
		var mas := 0
		var ahorro := 0
		for k in por:
			if por[k] > 1:
				mas += 1
				ahorro += por[k] - 1
		print("MMHIST nodos=%d grupos=%d grupos_con_varios=%d nodos_que_sobran=%d" % [nodos.size(), por.size(), mas, ahorro])
		var ks2 := tam.keys()
		ks2.sort_custom(func(a, b): return int(a) < int(b))
		var linea := ""
		for k in ks2.slice(0, 12):
			linea += "%s:%d " % [k, tam[k]]
		print("MMHIST instancias->nodos ", linea)
	if OS.get_environment("ESCENAS") != "":
		var ce := {}
		for h in ciudad.get_children():
			if h.get_class() == "Node3D" and String(h.name).begins_with("@"):
				var m := ""
				for g in h.find_children("*", "MeshInstance3D", true, false).slice(0, 1):
					m = String(g.name) + "/" + String((g as MeshInstance3D).mesh.get_class())
				var k := "%s | grupos=%s | script=%s | hijos=%d | %s" % [h.scene_file_path.get_file(), str(h.get_groups()), str(h.get_script() != null), h.get_child_count(), m]
				ce[k] = int(ce.get(k, 0)) + 1
		var kc := ce.keys()
		kc.sort_custom(func(a, b): return ce[a] > ce[b])
		for k in kc.slice(0, 25):
			print("ESCENAS %4d  %s" % [ce[k], k])
	if OS.get_environment("HIJOS") != "":
		var raiz := ciudad if OS.get_environment("HIJOS") == "." else ciudad.find_child(OS.get_environment("HIJOS"), true, false)
		if raiz != null:
			var gr := {}
			for h in raiz.get_children():
				if h is Node3D and (h as Node3D).visible and not (h.get_class() == "Node3D" and h.get_child_count() == 0) and (OS.get_environment("NOMBRADOS") == "" or (h.get_class() == "Node3D" and not String(h.name).begins_with("@"))):
					var kk := "%s:%s" % [h.get_class(), String(h.name).rstrip("0123456789@_").lstrip("@")]
					if kk == "Node3D:Node3D":
						kk = "Node3D:%s%s h=%d" % [h.scene_file_path.get_file() if h.scene_file_path != "" else String(h.name), str(h.get_groups()), mini(h.get_child_count(), 1)]
					if not gr.has(kk):
						gr[kk] = []
					gr[kk].append(h)
			var kg := gr.keys()
			kg.sort_custom(func(a, b): return gr[a].size() > gr[b].size())
			for kk in kg.slice(0, 40):
				var antes: float = await _llamadas()
				for h in gr[kk]:
					(h as Node3D).visible = false
				var m0: float = await _llamadas()
				print("HIJOS %-44s %5d nodos  -%d llamadas" % [kk, gr[kk].size(), antes - m0])
				for h in gr[kk]:
					(h as Node3D).visible = true
				for i in 2:
					await get_tree().process_frame
	if OS.get_environment("RUTAS") != "":
		var cam := get_viewport().get_camera_3d()
		var hist := {}
		for n in ciudad.find_children(OS.get_environment("RUTAS"), "GeometryInstance3D", true, false):
			var dd := cam.global_position.distance_to((n as Node3D).global_position)
			var clave := "d<%d fin=%d" % [int(ceil(dd / 25.0) * 25.0), int((n as GeometryInstance3D).visibility_range_end)]
			hist[clave] = int(hist.get(clave, 0)) + 1
		for k in hist:
			print("RUTAS_DIST %s %d" % [k, hist[k]])
		var cuenta := {}
		for n in ciudad.find_children(OS.get_environment("RUTAS"), "GeometryInstance3D", true, false):
			var r := ""
			var q: Node = n.get_parent()
			for i in 5:
				if q == null or q == ciudad:
					break
				r += String(q.name).rstrip("0123456789@_") + "<"
				q = q.get_parent()
			cuenta[r] = int(cuenta.get(r, 0)) + 1
		for k in cuenta:
			print("RUTAS %s %d" % [k, cuenta[k]])
	var por := {}
	for n in ciudad.find_children("*", "GeometryInstance3D", true, false):
		if n is Label3D or not (n as Node3D).visible:
			continue
		var nm := String(n.name).rstrip("0123456789@_").lstrip("@")
		var pa := n.get_parent()
		while nm == "" or nm.begins_with("Node3D") or nm.begins_with("MeshInstance3D") or nm.begins_with("MultiMeshInstance3D"):
			nm = String(pa.name).rstrip("0123456789@_").lstrip("@")
			pa = pa.get_parent()
			if pa == null:
				break
		nm = "(" + nm + ")"
		if not por.has(nm):
			por[nm] = []
		por[nm].append(n)
	var ks := por.keys()
	ks.sort_custom(func(a, b): return por[a].size() > por[b].size())
	for k in ks.slice(0, 30):
		var lista: Array = por[k]
		var antes: float = await _llamadas()
		for n in lista:
			if is_instance_valid(n):
				(n as Node3D).visible = false
		var despues: float = await _llamadas()
		print("GRUPOS2 %-34s %5d nodos  -%d llamadas" % [k, lista.size(), antes - despues])
		for n in lista:
			if is_instance_valid(n):
				(n as Node3D).visible = true
		for i in 2:
			await get_tree().process_frame

## TEXTURAS=1 (3-11, R4 memoria): las texturas únicas que cuelgan de los materiales de la escena, con tamaño, formato y megas estimados (con mipmaps), de mayor a menor.
func _texturas() -> void:
	var vistas := {}
	var total := 0.0
	for n in _p.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		var mats: Array = []
		if g.material_override != null:
			mats.append(g.material_override)
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			for i in (g as MeshInstance3D).mesh.get_surface_count():
				var m := (g as MeshInstance3D).get_active_material(i)
				if m != null:
					mats.append(m)
		elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null and (g as MultiMeshInstance3D).multimesh.mesh != null:
			var mm := (g as MultiMeshInstance3D).multimesh.mesh
			for i in mm.get_surface_count():
				if mm.surface_get_material(i) != null:
					mats.append(mm.surface_get_material(i))
		for mat in mats:
			var lista: Array = []
			if mat is BaseMaterial3D:
				for k in [BaseMaterial3D.TEXTURE_ALBEDO, BaseMaterial3D.TEXTURE_NORMAL, BaseMaterial3D.TEXTURE_ROUGHNESS, BaseMaterial3D.TEXTURE_METALLIC, BaseMaterial3D.TEXTURE_EMISSION, BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION]:
					var t := (mat as BaseMaterial3D).get_texture(k)
					if t != null:
						lista.append(t)
			elif mat is ShaderMaterial:
				for pr in (mat as ShaderMaterial).shader.get_shader_uniform_list():
					var v: Variant = (mat as ShaderMaterial).get_shader_parameter(String(pr["name"]))
					if v is Texture2D:
						lista.append(v)
			for t: Texture2D in lista:
				if vistas.has(t):
					continue
				var mb := float(t.get_width() * t.get_height()) * 4.0 * 1.33 / 1048576.0
				if t is CompressedTexture2D:
					mb /= 4.0   ## ~1 byte/píxel comprimida en VRAM
				vistas[t] = [mb, "%dx%d %s  (%s)" % [t.get_width(), t.get_height(), t.resource_path.get_file() if t.resource_path != "" else t.get_class(), String(g.get_path()).right(60)] + " mesh=%s mat=%s aabb=%s" % [(g as MeshInstance3D).mesh.resource_name if g is MeshInstance3D and (g as MeshInstance3D).mesh != null else "", String(mat.resource_name), str((g as MeshInstance3D).mesh.get_aabb().size.round()) if g is MeshInstance3D and (g as MeshInstance3D).mesh != null else ""]]
				total += mb
	var l2 := vistas.values()
	l2.sort_custom(func(a, b): return a[0] > b[0])
	print("TEXTURAS únicas=%d total estimado=%.0f MB" % [vistas.size(), total])
	if l2.size() > 0 and vistas.size() > 0:
		for t in vistas:
			if (vistas[t][0] as float) == (l2[0][0] as float):
				var im := (t as Texture2D).get_image()
				if im != null:
					im.decompress() if im.is_compressed() else null
					im.resize(256, 280, Image.INTERPOLATE_BILINEAR)
					im.save_png(OS.get_environment("TEXTURA_PNG") if OS.get_environment("TEXTURA_PNG") != "" else "/tmp/textura_grande.png")
	for e in l2.slice(0, 25):
		print("TEXTURA %7.1f MB  %s" % [e[0], e[1]])

## Con DETALLE=1 (7-11): lo que se DIBUJA de verdad desde la cámara (en el campo de visión y dentro de su distancia de corte) por tipo de malla y distancia.
func _dibujado(raiz: Node) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var por := {}
	for n: Node in raiz.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var c := g.global_transform * g.get_aabb().get_center()
		var d := cam.global_position.distance_to(c)
		if (g.visibility_range_end > 0.0 and d > g.visibility_range_end) or not cam.is_position_in_frustum(c):
			continue
		var mm := g as MultiMeshInstance3D
		var ml: Mesh = mm.multimesh.mesh if mm != null and mm.multimesh != null else (g.get("mesh") as Mesh)
		var k := "%s %s %s" % [g.get_class().replace("Instance3D", ""), (ml.resource_name if ml != null and ml.resource_name != "" else (ml.get_class() if ml != null else "-")), "cerca" if d < 60.0 else ("medio" if d < 200.0 else "lejos")]
		por[k] = int(por.get(k, 0)) + 1
		if g is Label3D:
			var kl := "LABEL en " + String(g.get_parent().name).rstrip("0123456789") + " < " + String(g.get_parent().get_parent().name).rstrip("0123456789")
			por[kl] = int(por.get(kl, 0)) + 1
	var ks := por.keys()
	ks.sort_custom(func(a, b): return por[a] > por[b])
	for k in ks.slice(0, 24):
		print("MEDIDA   DIBUJADO ", por[k], "  ", k)
