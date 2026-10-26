extends BaseIdea
## FASE 0 (M-404/M-279): pruebas directas de los módulos de PERSONAS de `visor/` que
## no tenían ninguna: `PeatonQ`, `PeloQ.poner`, `CaraMalla.poner`, `PeloCapas.poner`,
## `MascotaQ`, `Mini3D.persona`, `RetargetFutbolQ` y `RopaSeparada` sobre el cuerpo
## de verdad. Con los modelos Quaternius reales (headless crea nodos y mallas).
## Esta prueba espera fotogramas (`fusionar` y los vestidos usan `queue_free`): por
## eso lleva su propio `_ready` en vez del síncrono de `BaseIdea`.

func _ready() -> void:
	await get_tree().process_frame
	await _probar_todo()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _nodos() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) + Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))

## Libera y espera a que se vacíe la cola de borrado.
func _soltar(n: Node) -> void:
	n.free()
	await get_tree().process_frame
	await get_tree().process_frame

func _probar_todo() -> void:
	_titulo("FASE 0 · VISOR: PERSONAS 3D (f0m)")
	await _probar_peatones()
	await _probar_pelo_y_cara()
	await _probar_mascota()
	await _probar_mini3d_persona()
	await _probar_retarget()

## Un futbolista Quaternius terminado, colgado de `raiz`.
func _cuerpo(raiz: Node3D, cuerpo := "male") -> Dictionary:
	var d := FutbolistaQ.crear(1.8, cuerpo)
	raiz.add_child(d["nodo"])
	FutbolistaQ.terminar(d, false)
	return d

# ------------------------------------------------------------------ PeatonQ

func _probar_peatones() -> void:
	_linea("· PeatonQ")
	var n0 := _nodos()
	var raiz := Node3D.new()
	add_child(raiz)
	var suelto := PeatonQ.crear(_rng(3))
	PeatonQ.terminar(suelto)
	_comprobar(not suelto.is_empty() and (suelto["nodo"] as Node3D).find_children("Pelo", "", true, false).is_empty(), "fuera del árbol, terminar() no hace nada (necesita las medidas)")
	(suelto["nodo"] as Node).free()
	var mujeres := 0
	var barba_mujer := false
	var cortes_ok := true
	var vistas_ok := true
	var caminan := true
	var cejas_ok := true
	var hechos: Array = []
	for s in 14:
		var d := PeatonQ.crear(_rng(100 + s))
		raiz.add_child(d["nodo"])
		(d["nodo"] as Node3D).position = Vector3(float(s) * 2.0, 0, 0)
		PeatonQ.terminar(d)
		hechos.append(d)
		var mujer: bool = d["mujer"]
		mujeres += 1 if mujer else 0
		var esq: Skeleton3D = d["esqueleto"]
		var pelo := esq.get_node_or_null("Pelo")
		cortes_ok = cortes_ok and pelo != null and bool((d["nodo"] as Node).get_meta("mujer")) == mujer
		if mujer and pelo != null and pelo.get_node_or_null("Hair_Beard") != null:
			barba_mujer = true
		for mi: MeshInstance3D in (d["nodo"] as Node3D).find_children("*", "MeshInstance3D", true, false):
			vistas_ok = vistas_ok and mi.visibility_range_end > 0.0 and mi.visibility_range_end <= 120.0
			if String(mi.name).begins_with("Eyebrows"):
				cejas_ok = cejas_ok and mi.visibility_range_end <= PeloQ.DIST_CEJAS
		var ap: AnimationPlayer = d["anim"]
		caminan = caminan and ap.current_animation == "caminar" and ap.speed_scale >= 0.9 and ap.speed_scale <= 1.1
	_comprobar(mujeres >= 2 and mujeres <= 12, "hombres y mujeres por la calle (%d mujeres de 14)" % mujeres)
	_comprobar(cortes_ok and not barba_mujer, "todos con su peinado, y ninguna mujer con barba")
	_comprobar(vistas_ok, "lejos de la cámara no se dibujan (alcance ≤ 120 m)")
	_comprobar(cejas_ok, "y las cejas 3D se apagan antes, a %d m, como en los jugadores" % PeloQ.DIST_CEJAS)
	_comprobar(caminan, "caminando, cada uno a su paso (0,9-1,1)")
	var d0: Dictionary = hechos[0]
	var otro := PeatonQ.crear(_rng(100))
	raiz.add_child(otro["nodo"])
	PeatonQ.terminar(otro)
	_comprobar(String(otro["zapatilla"]) == String(d0["zapatilla"]) and (otro["modelo"] as Node3D).scale.is_equal_approx((d0["modelo"] as Node3D).scale),
		"la misma semilla da el mismo peatón (zapatillas y complexión)")
	PeatonQ.calzar(d0)
	PeatonQ.calzar(d0)
	var zap := (d0["esqueleto"] as Node).get_children().filter(func(h: Node) -> bool: return String(h.name).begins_with("Zapatilla_"))
	_comprobar(zap.size() == 2 and bool(d0.get("calzado", false)), "calzar(): una zapatilla por pie, y calzar dos veces no duplica")
	var malla_z: Mesh = (zap[0] as Node).get_child(0).mesh if zap.size() == 2 else null
	_comprobar(malla_z != null and malla_z.get_surface_count() == 1 and malla_z.surface_get_format(0) & Mesh.ARRAY_FORMAT_COLOR, "cada zapatilla es UNA malla con su color por vértice")
	PeatonQ.calzar(otro)
	var zap2: Array = (otro["esqueleto"] as Node).get_children().filter(func(h: Node) -> bool: return String(h.name) == String(zap[0].name))
	_comprobar(zap2.size() == 1 and (zap2[0] as Node).get_child(0).mesh == malla_z, "y la malla se comparte entre peatones iguales (caché)")
	await _soltar(raiz)
	_comprobar(_nodos() == n0, "sin nodos sueltos al quitar 15 peatones (%d → %d)" % [n0, _nodos()])

func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

# -------------------------------------------- PeloQ, CaraMalla y PeloCapas

func _probar_pelo_y_cara() -> void:
	_linea("· PeloQ.poner, CaraMalla.poner y PeloCapas.poner")
	var n0 := _nodos()
	var raiz := Node3D.new()
	add_child(raiz)
	var d := _cuerpo(raiz)
	var esq: Skeleton3D = d["esqueleto"]
	var ancla := PeloQ.poner(d, "tupe", Color(0.3, 0.2, 0.1), true)
	var piezas: Array[String] = []
	for h: Node in ancla.get_children():
		piezas.append(String(h.name))
	_comprobar(ancla != null and ancla.bone_name == "Head" and piezas == ["Hair_SimpleParted", "Hair_Beard", "Eyebrows_Regular"], "tupé con barba: peinado, barba y cejas en el hueso de la cabeza %s" % str(piezas))
	var cejas := ancla.get_node_or_null("Eyebrows_Regular") as MeshInstance3D
	_comprobar(cejas != null and cejas.visibility_range_end == PeloQ.DIST_CEJAS, "las cejas 3D solo de cerca (%d m)" % PeloQ.DIST_CEJAS)
	## Puesto en reposo, cada peinado tiene que caer SOBRE la cabeza (el moño venía
	## en centímetros y girado: salía flotando al costado).
	var cabeza := esq.get_bone_global_rest(esq.find_bone("Head"))
	var lejos: Array[String] = []
	for corte: String in ["tupe", "largo", "coleta", "corto", "afro"]:
		var a2 := PeloQ.poner(d, corte, Color(0.3, 0.2, 0.1), false)
		var mi := a2.get_child(0) as MeshInstance3D
		var centro := cabeza * (mi.transform * mi.mesh.get_aabb().get_center())
		if centro.distance_to(cabeza.origin + Vector3(0, 0.1, 0)) > 0.2:
			lejos.append("%s a %.2f m" % [corte, centro.distance_to(cabeza.origin)])
		a2.free()
	_comprobar(lejos.is_empty(), "cada peinado cae sobre la cabeza en reposo %s" % str(lejos))
	var calvo := PeloQ.poner(d, "calvo", Color.BLACK, false)
	_comprobar(calvo.get_child_count() == 1 and calvo.get_child(0).name == "Eyebrows_Regular", "calvo: solo las cejas")
	_comprobar(PeloQ.poner({}, "tupe", Color.BLACK, false) == null, "sin esqueleto: null")
	var dm := _cuerpo(raiz, "female")
	var am := PeloQ.poner(dm, "melena", Color(0.4, 0.25, 0.1), false)
	_comprobar(am.get_child_count() == 1 and am.get_child(0).name == "Hair_Long", "el cuerpo de mujer trae sus cejas: solo el peinado")
	## La cara de la biblioteca sobre el cuerpo.
	var nombre := "cara_000"
	var foto := CaraMalla.foto(nombre)
	var cara := CaraMalla.poner(d, nombre, foto, Color(0.8, 0.6, 0.45))
	_comprobar(cara != null and cara.mesh != null and cara.mesh.surface_get_array_len(0) == CaraMalla._n, "la malla de la cara (%d vértices) colgada de la cabeza" % CaraMalla._n)
	var d2 := _cuerpo(raiz)
	var cara2 := CaraMalla.poner(d2, nombre, foto, Color(0.8, 0.6, 0.45))
	_comprobar(cara2 != null and cara2.mesh == cara.mesh, "la malla se arma una vez por cara y cuerpo (caché)")
	_comprobar(CaraMalla.poner({}, nombre, foto, Color.WHITE) == null and CaraMalla.poner(d, nombre, null, Color.WHITE) == null, "sin esqueleto o sin foto: null")
	## El pelo por capas, con un corte de la biblioteca.
	var corte_n := ""
	for p: String in BibliotecaCaras.pelos():
		var hp := BibliotecaCaras.pelo(p, Color(0.2, 0.12, 0.08))
		if PeloCapas.corte_de(hp) in ["normal", "degradado"] and not bool(hp.get("calvo", false)):
			corte_n = p
			break
	var g := CaraMalla.geometria(nombre)
	var medida := CaraMalla.entrada(nombre).duplicate()
	medida["h"] = BibliotecaCaras.pelo(corte_n, Color(0.2, 0.12, 0.08))
	var puso := PeloCapas.poner(d, medida, foto, g[0], g[1], g[2], g[3])
	var pc := esq.get_node_or_null("PeloCapas")
	var cuero: MeshInstance3D = pc.get_node_or_null("Cuero") as MeshInstance3D if pc != null else null
	var cuero_l: MeshInstance3D = pc.get_node_or_null("CueroLejos") as MeshInstance3D if pc != null else null
	_comprobar(puso and pc != null and pc.get_node_or_null("Pestanas") != null, "pelo por capas (%s) y pestañas" % corte_n)
	_comprobar(cuero != null and cuero_l != null and cuero.visibility_range_end == PeloCapas.DIST_CUERO and cuero_l.visibility_range_begin == PeloCapas.DIST_CUERO,
		"de cerca todas las capas; desde %d m, la versión de %d capas" % [PeloCapas.DIST_CUERO, PeloCapas.CAPAS_LEJOS])
	var esq2: Skeleton3D = d2["esqueleto"]
	PeloCapas.poner(d2, medida, foto, g[0], g[1], g[2], g[3])
	var cuero2 := esq2.get_node_or_null("PeloCapas/Cuero") as MeshInstance3D
	_comprobar(cuero2 != null and cuero2.mesh == cuero.mesh, "el cuero cabelludo, en caché por cuerpo y medidas")
	var sin_h := CaraMalla.entrada(nombre).duplicate()
	sin_h.erase("h")
	var calva := medida.duplicate()
	calva["h"] = (medida["h"] as Dictionary).duplicate()
	calva["h"]["calvo"] = true
	var d3 := _cuerpo(raiz)
	_comprobar(not PeloCapas.poner(d3, sin_h, foto, g[0], g[1], g[2], g[3]), "sin pelo medido: no pone cuero (y quien llama deja el peinado)")
	var d4 := _cuerpo(raiz)
	_comprobar(PeloCapas.poner(d4, calva, foto, g[0], g[1], g[2], g[3]) and (d4["esqueleto"] as Node).get_node_or_null("PeloCapas/Cuero") == null, "calvo: sin capas, pero esconde el peinado del pack")
	## La ropa aparte, sobre la malla de verdad del cuerpo.
	var cuerpo_mi: MeshInstance3D = null
	var sup := -1
	for mv in VestidorQ._mallas(d["modelo"]):
		var mi2: MeshInstance3D = mv
		for s in (mi2.mesh.get_surface_count() if mi2.mesh != null else 0):
			var mt := mi2.mesh.surface_get_material(s)
			if mt != null and mt.resource_name.begins_with("MI_Superhero"):
				cuerpo_mi = mi2
				sup = s
	var ms: Dictionary = RopaSeparada.mallas(cuerpo_mi.mesh as ArrayMesh, sup) if cuerpo_mi != null else {}
	var tri_cuerpo: int = cuerpo_mi.mesh.surface_get_array_index_len(sup) / 3 if cuerpo_mi != null else 0
	var tri_prendas := 0
	var prendas_ok := ms.size() == 3
	for k: int in ms:
		var t: int = (ms[k] as ArrayMesh).surface_get_array_index_len(0) / 3
		tri_prendas += t
		prendas_ok = prendas_ok and t > 200
	_comprobar(prendas_ok and tri_prendas < tri_cuerpo, "camiseta, pantalón y medias sacados del cuerpo real (%d de %d triángulos)" % [tri_prendas, tri_cuerpo])
	await _soltar(raiz)
	_comprobar(_nodos() == n0, "sin nodos sueltos (%d → %d)" % [n0, _nodos()])

# ------------------------------------------------------------------ MascotaQ

func _probar_mascota() -> void:
	_linea("· MascotaQ")
	var n0 := _nodos()
	var c := Club.new("f0m_mascota", "Club Mascota")
	c.color1 = "#1f5fa8"
	c.color2 = "#ffffff"
	var fuera := Node3D.new()
	_comprobar(MascotaQ.crear(fuera, c, "oso", Vector3.ZERO, 0.0) == null, "fuera del árbol no se arma")
	fuera.free()
	var raiz := Node3D.new()
	add_child(raiz)
	var filas_ok := true
	for a: String in MascotaQ.ANIMALES:
		var f: Array = MascotaQ.ANIMALES[a]
		filas_ok = filas_ok and f.size() == 6 and f[0] is Color and float(f[5]) >= 0.0 and float(f[5]) <= 1.0
	_comprobar(filas_ok and MascotaQ.ANIMALES.size() >= 17, "%d animales, cada uno con su color, orejas, hocico, cola, rasgo y tinte" % MascotaQ.ANIMALES.size())
	var m := EstadioExtras.mascota(raiz, c)
	_comprobar(m != null and m.name == "Mascota" and m.position == Vector3(-35.6, 0, -12.0) and is_equal_approx(m.rotation_degrees.y, 90.0), "EstadioExtras.mascota(): en la banda, mirando a la grada")
	var ctl := m.get_node_or_null("Animador") as MascotaQ
	var cola := m.get_node_or_null("Cola") as Node3D
	_comprobar(ctl != null and cola != null, "con su animador y su cola")
	var fundidas := m.find_children("Fundida", "MeshInstance3D", true, false)
	_comprobar(fundidas.size() >= 3, "los adornos fundidos en una malla por parte (%d partes)" % fundidas.size())
	var de_otro := MascotaQ.crear(raiz, c, "animal_inventado", Vector3(5, 0, 0), 0.0)
	_comprobar(de_otro != null, "un animal desconocido sale de oso (no revienta)")
	## Diez minutos de partido: mueve la cola, gesticula, pasea por la banda y
	## vuelve a su sitio.
	## Los paseos van de dos en dos (uno hacia cada lado): tras cada par, tiene que
	## estar otra vez donde empezó.
	var inicio := m.position
	var giro_cola := cola.rotation.y
	var paseos := 0
	var andando := false
	var deriva := 0.0
	for i in 6000:
		ctl._process(0.1)
		if andando and not ctl._caminando:
			paseos += 1
			if paseos % 2 == 0:
				deriva = maxf(deriva, Vector2(m.position.x - inicio.x, m.position.z - inicio.z).length())
		andando = ctl._caminando
	_comprobar(cola.rotation.y != giro_cola and paseos >= 4, "mueve la cola y pasea (%d paseos en 10 min)" % paseos)
	_comprobar(deriva < 0.5, "y tras cada ida y vuelta está en su sitio (se aleja como mucho %.2f m)" % deriva)
	await _soltar(raiz)
	_comprobar(_nodos() == n0, "sin nodos sueltos (%d → %d)" % [n0, _nodos()])

# ------------------------------------------------------- Mini3D.persona

func _probar_mini3d_persona() -> void:
	_linea("· Mini3D.persona")
	var n0 := _nodos()
	var raiz := Node3D.new()
	add_child(raiz)
	var p := Mini3D.persona(raiz, _rng(77), Vector3(1, 0, 2))
	var nodo: Node3D = p["nodo"]
	var ap: AnimationPlayer = p["anim"]
	_comprobar(nodo.get_parent() == raiz and nodo.position == Vector3(1, 0, 2) and bool(p.get("calzado", false)), "un vecino en su sitio y con zapatillas de verdad")
	_comprobar(ap.get_animation_list().size() > 40 and ap.current_animation == "parado", "con TODAS las animaciones (%d) y en reposo" % ap.get_animation_list().size())
	## Cada clip que el juego le pide a `Mini3D.anim` existe de verdad: uno que
	## falte cae en «parado» sin avisar (la escena se queda quieta).
	var re := RegEx.new()
	re.compile("Mini3D\\.anim\\([^,]+,\\s*\"([a-z_]+)\"")
	var pedidos := {}
	for dir: String in ["res://ui", "res://ui/componentes", "res://ui/pantallas", "res://visor"]:
		for f: String in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				for r in re.search_all(FileAccess.get_file_as_string(dir.path_join(f))):
					pedidos[r.get_string(1)] = true
	var faltan: Array[String] = []
	for clip: String in pedidos:
		if not ap.has_animation(clip):
			faltan.append(clip)
	_comprobar(pedidos.size() >= 10 and faltan.is_empty(), "los %d clips que piden los minijuegos e interiores existen %s" % [pedidos.size(), str(faltan)])
	var lejos := true
	for mi: MeshInstance3D in nodo.find_children("*", "MeshInstance3D", true, false):
		lejos = lejos and mi.visibility_range_end == 0.0
	_comprobar(lejos, "de cerca siempre (sin corte por distancia: es una escena chica)")
	var dep := Mini3D.persona(raiz, _rng(78), Vector3.ZERO, [Color.RED, Color.WHITE])
	var trab := Mini3D.persona(raiz, _rng(79), Vector3.ZERO, [Color.BLUE, Color.BLACK, true])
	_comprobar(not dep.is_empty() and not trab.is_empty() and not bool((dep["nodo"] as Node).get_meta("mujer", true)) and (dep["esqueleto"] as Node).get_node_or_null("Pelo") != null,
		"de corto (deportista) y de trabajo: armados, con pelo")
	await _soltar(raiz)
	_comprobar(_nodos() == n0, "sin nodos sueltos (%d → %d)" % [n0, _nodos()])

# --------------------------------------------------------- RetargetFutbolQ

## Dos esqueletos de juguete: el de origen con el root girado -90° (la corrección
## de importación del FBX) y la cabeza en minúscula; el de destino, recto.
func _esqueleto(raiz_girada: bool, cabeza: String, alto_pelvis: float) -> Skeleton3D:
	var s := Skeleton3D.new()
	var r := s.add_bone("root")
	var p := s.add_bone("pelvis")
	var h := s.add_bone(cabeza)
	var solo := s.add_bone("solo_origen" if raiz_girada else "solo_destino")
	s.set_bone_parent(p, r)
	s.set_bone_parent(h, p)
	s.set_bone_parent(solo, r)
	s.set_bone_rest(r, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5) if raiz_girada else Basis(), Vector3.ZERO))
	s.set_bone_rest(p, Transform3D(Basis(), Vector3(0, alto_pelvis, 0)))
	s.set_bone_rest(h, Transform3D(Basis(), Vector3(0, 0.6, 0)))
	s.set_bone_rest(solo, Transform3D(Basis(), Vector3(1, 0, 0)))
	s.reset_bone_poses()
	return s

func _probar_retarget() -> void:
	_linea("· RetargetFutbolQ")
	var n0 := _nodos()
	var o := _esqueleto(true, "head", 1.0)
	var d := _esqueleto(false, "Head", 0.9)
	add_child(o)
	add_child(d)
	var rt := RetargetFutbolQ.crear(o, d)
	_comprobar(rt._pares.size() == 2, "empareja pelvis y cabeza («head» → «Head»); ni el root ni los huesos sin pareja")
	rt.aplicar()
	var quieto := d.get_bone_global_pose(1).is_equal_approx(d.get_bone_global_rest(1)) and d.get_bone_global_pose(2).is_equal_approx(d.get_bone_global_rest(2))
	_comprobar(quieto, "en reposo, el destino queda en SU reposo (la corrección del root no se cuela)")
	## La pelvis gira 30° sobre la vertical del modelo: lo mismo en el destino.
	var giro := Basis(Vector3.UP, deg_to_rad(30.0))
	var pose_modelo := Transform3D(giro, Vector3(0, 1.0, 0))
	o.set_bone_global_pose(1, o.get_bone_global_rest(0) * pose_modelo)
	rt.aplicar()
	var pd := d.get_bone_global_pose(1)
	var hd := d.get_bone_global_pose(2)
	_comprobar(pd.basis.is_equal_approx(giro) and pd.origin.is_equal_approx(Vector3(0, 0.9, 0)), "el giro de la pelvis pasa al destino, a SU altura (%s)" % str(pd.origin))
	_comprobar(hd.basis.is_equal_approx(giro) and hd.origin.is_equal_approx(Vector3(0, 1.5, 0)), "y la cabeza la acompaña (%s)" % str(hd.origin))
	_comprobar(d.get_bone_pose(0).is_equal_approx(d.get_bone_rest(0)), "el root del destino no se toca")
	_comprobar(RetargetFutbolQ.crear(null, d)._pares.is_empty(), "sin origen no empareja nada (y aplicar no falla)")
	RetargetFutbolQ.crear(null, d).aplicar()
	o.free()
	d.free()
	_comprobar(_nodos() == n0, "sin nodos sueltos")
