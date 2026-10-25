extends BaseIdea
## FASE 0 (M-404/M-279): pruebas directas de lo que rodea al partido en `visor/` y no
## tenía prueba: `Ambience`, `Precipitacion`, `EntornoEstadio`, `FachadaEstadio` y
## `EstadioExtras`. Headless no dibuja, pero sí monta los nodos y las mallas: se
## comprueba la ESTRUCTURA (qué cuelga, cuánto, con qué parámetros) y que al
## liberar la raíz no quede ningún nodo suelto.

func _probar() -> void:
	_titulo("FASE 0 · VISOR: EL ESTADIO Y SU ENTORNO (f0m)")
	_probar_ambience()
	_probar_precipitacion()
	_probar_entorno()
	_probar_fachada()
	_probar_extras()

func _nodos() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) + Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))

func _de_tipo(raiz: Node, clase: String) -> Array:
	return raiz.find_children("*", clase, true, false)

# ------------------------------------------------------------------ Ambience

func _probar_ambience() -> void:
	_linea("· Ambience")
	var n0 := _nodos()
	var dia := Node3D.new()
	Ambience.apply(dia, {"clima": "dia"}, null, Calidad.MEDIO)
	var we: WorldEnvironment = _de_tipo(dia, "WorldEnvironment")[0] if _de_tipo(dia, "WorldEnvironment").size() == 1 else null
	var luces := _de_tipo(dia, "DirectionalLight3D")
	_comprobar(we != null and luces.size() == 1, "de día: un entorno y el sol, sin focos de relleno")
	if we != null and luces.size() == 1:
		var sol: DirectionalLight3D = luces[0]
		_comprobar(not we.environment.fog_enabled and not we.environment.ssao_enabled and we.environment.glow_hdr_threshold > 1.0, "calidad media y despejado: sin niebla ni SSAO; el bloom con umbral")
		_comprobar(is_equal_approx(sol.light_energy, 1.35) and sol.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS and sol.shadow_enabled,
			"el sol a pleno y sombras en 2 cascadas (Medio alivia el partido)")
	var noche := Node3D.new()
	Ambience.apply(noche, {"clima": "noche", "focos": "torres", "luzFocos": "calida"}, ["lluvia"], Calidad.ALTO)
	var we2: WorldEnvironment = _de_tipo(noche, "WorldEnvironment")[0]
	var luces2 := _de_tipo(noche, "DirectionalLight3D")
	_comprobar(luces2.size() == 2 and we2.environment.fog_enabled and we2.environment.ssao_enabled, "de noche y con lluvia en Alto: niebla, SSAO y la luz de los focos")
	if luces2.size() == 2:
		var luna: DirectionalLight3D = luces2[0]
		var focos: DirectionalLight3D = luces2[1]
		_comprobar(is_equal_approx(luna.light_energy, 0.25) and luna.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "la luna floja y 4 cascadas en Alto")
		_comprobar(focos.light_specular == 0.0 and not focos.shadow_enabled and focos.light_color == StadiumBuilder.color_luz({"luzFocos": "calida"}),
			"el relleno de los focos: sin brillo ni sombra, del color elegido")
		_comprobar(is_equal_approx(we2.environment.tonemap_exposure, 1.35), "exposición subida de noche (1,35)")
	var sin_focos := Node3D.new()
	Ambience.apply(sin_focos, {"clima": "noche", "focos": "sin"}, null, Calidad.ALTO)
	_comprobar(_de_tipo(sin_focos, "DirectionalLight3D").size() == 1, "un estadio sin focos no tiene la luz de los focos")
	var raro := Node3D.new()
	Ambience.apply(raro, {"clima": "marciano"}, ["meteoritos"], Calidad.ALTO)
	var we3: WorldEnvironment = _de_tipo(raro, "WorldEnvironment")[0]
	_comprobar((we3.environment.sky.sky_material as ProceduralSkyMaterial).sky_top_color == Color(Ambience.AMBIENTES["dia"]["top"]) and not we3.environment.fog_enabled,
		"un ambiente o un clima desconocidos caen en «día» y «despejado»")
	var claves_ok := true
	for k: String in Ambience.AMBIENTES:
		var a: Dictionary = Ambience.AMBIENTES[k]
		claves_ok = claves_ok and a.has("top") and a.has("hor") and float(a["oscuro"]) >= 0.0 and float(a["oscuro"]) <= 1.0
	for k: String in Ambience.CLIMA_PARTIDO:
		claves_ok = claves_ok and float(Ambience.CLIMA_PARTIDO[k]["oscuro"]) <= 1.0 and float(Ambience.CLIMA_PARTIDO[k]["niebla"]) <= 1.0
	_comprobar(claves_ok, "tablas de ambientes y climas completas y en rango")
	## Todo clima que puede salir en una partida (`Mundo.clima()`, por estación)
	## tiene su fila: uno que falte se ve como «despejado» sin avisar.
	var mw := Mundo.new()
	var climas := {}
	for anio in [2026, 2027, 2028]:
		for sem in range(1, 43):
			mw.anio = anio
			mw.semana = sem
			climas[mw.clima()] = true
	var sin_fila: Array[String] = []
	for k: String in climas:
		if not Ambience.CLIMA_PARTIDO.has(k):
			sin_fila.append(k)
	_comprobar(climas.size() >= 6 and sin_fila.is_empty(), "cada clima de Mundo.clima() tiene su fila en Ambience %s de %s" % [str(sin_fila), str(climas.keys())])
	for n: Node in [dia, noche, sin_focos, raro]:
		n.free()
	_comprobar(_nodos() == n0, "sin nodos sueltos")

# ------------------------------------------------------------- Precipitacion

func _probar_precipitacion() -> void:
	_linea("· Precipitacion")
	var n0 := _nodos()
	var raiz := Node3D.new()
	add_child(raiz)
	var cam := Camera3D.new()
	cam.position = Vector3(12, 30, -40)
	raiz.add_child(cam)
	cam.current = true
	_comprobar(Precipitacion.montar(raiz, "despejado", 40.0, 60.0) == null and raiz.get_child_count() == 1, "despejado: no cae nada (ni se monta nada)")
	var lluvia := Precipitacion.montar(raiz, "lluvia", 40.0, 60.0, Calidad.ALTO)
	var parts := _de_tipo(lluvia, "GPUParticles3D")
	_comprobar(lluvia != null and parts.size() == 2, "lluvia: dos capas (sobre el campo y pegada a la cámara)")
	if parts.size() == 2:
		var lejos: GPUParticles3D = parts[0]
		var pm := lejos.process_material as ParticleProcessMaterial
		_comprobar(pm.emission_box_extents.x >= 40.0 and pm.emission_box_extents.z >= 60.0 and lejos.visibility_aabb.size.x >= 80.0, "la capa lejana cubre todo el campo")
		_comprobar(pm.gravity.y < -10.0 and (lejos.draw_pass_1 as QuadMesh).size.y > (lejos.draw_pass_1 as QuadMesh).size.x * 10.0, "gotas: caen rápido y estiradas")
		_comprobar(is_equal_approx(lejos.preprocess, lejos.lifetime), "nacen ya repartidas (preprocess = vida)")
	var sigue: Node3D = lluvia.get_child(1) if lluvia != null and lluvia.get_child_count() > 1 else null
	if sigue != null:
		sigue._process(0.016)
	_comprobar(sigue != null and sigue.global_position.is_equal_approx(cam.global_position), "la capa cercana se va con la cámara activa")
	var medio := Precipitacion.montar(raiz, "lluvia", 40.0, 60.0, Calidad.MEDIO)
	var ultra := Precipitacion.montar(raiz, "lluvia", 40.0, 60.0, Calidad.ULTRA)
	var a_medio: int = (_de_tipo(medio, "GPUParticles3D")[0] as GPUParticles3D).amount
	var a_alto: int = (parts[0] as GPUParticles3D).amount if parts.size() == 2 else 0
	var a_ultra: int = (_de_tipo(ultra, "GPUParticles3D")[0] as GPUParticles3D).amount
	_comprobar(a_medio < a_alto and a_alto < a_ultra, "la cantidad sigue a la calidad (%d < %d < %d)" % [a_medio, a_alto, a_ultra])
	var tormenta := Precipitacion.montar(raiz, "tormenta", 40.0, 60.0)
	var rel := tormenta.get_node_or_null("Relampagos")
	_comprobar(rel != null and _de_tipo(rel, "DirectionalLight3D").size() == 1 and (_de_tipo(rel, "DirectionalLight3D")[0] as DirectionalLight3D).light_energy == 0.0,
		"tormenta: con relámpagos (una luz apagada hasta el destello)")
	var nieve := Precipitacion.montar(raiz, "nieve", 40.0, 60.0)
	var pn: GPUParticles3D = _de_tipo(nieve, "GPUParticles3D")[0]
	var vel_max := (pn.process_material as ParticleProcessMaterial).initial_velocity_max
	_comprobar(pn.amount >= 900 and vel_max < 5.0 and pn.lifetime >= Precipitacion.ALTO / vel_max, "nieve: muchos copos, lentos, que viven lo que tardan en bajar")
	_comprobar(((pn.draw_pass_1 as QuadMesh).material as StandardMaterial3D).albedo_texture == Precipitacion._copo(), "y redondos (textura de copo compartida)")
	raiz.free()
	_comprobar(_nodos() == n0, "sin nodos sueltos")

# ------------------------------------------------------------ EntornoEstadio

func _probar_entorno() -> void:
	_linea("· EntornoEstadio")
	var n0 := _nodos()
	var raiz := Node3D.new()
	var est := {"forma": "cuenco", "nombre": "Estadio de Prueba", "hincha1": "#c01020", "hincha2": "#ffffff"}
	var e := EntornoEstadio.montar(raiz, est, 2)
	_comprobar(e != null and e.name == "EntornoEstadio" and EntornoEstadio.montar(raiz, est, 2) == null, "se monta una vez (la segunda no duplica)")
	if e == null:
		raiz.free()
		return
	var planos := e.get_children().filter(func(h: Node) -> bool: return h is MeshInstance3D and (h as MeshInstance3D).mesh is PlaneMesh and not ((h as MeshInstance3D).mesh is QuadMesh))
	var multis := _de_tipo(e, "MultiMeshInstance3D")
	_comprobar(planos.size() == 12, "suelos: hierba, plaza, 4 calzadas, 4 aceras y 2 aparcamientos (%d)" % planos.size())
	var instancias := 0
	for mm: MultiMeshInstance3D in multis:
		instancias += mm.multimesh.instance_count
	_comprobar(multis.size() >= 6 and instancias > 100, "rayas, farolas, mástiles y plazas de aparcamiento en MultiMesh (%d piezas en %d llamadas)" % [instancias, multis.size()])
	var g := StadiumBuilder.geom_de_forma("cuenco")
	var fondo := StadiumBuilder.fondo_tribuna(2)
	var cx := float(g["dx"]) + fondo + 10.0 + EntornoEstadio.PLAZA + EntornoEstadio.BANDA
	var cz := float(g["dz"]) + fondo + 10.0 + EntornoEstadio.PLAZA + EntornoEstadio.BANDA
	var edificios := 0
	var dentro := 0
	for h: Node in e.get_children():
		if h is Node3D and String(h.scene_file_path).contains("kenney_") and String(h.scene_file_path).contains("building"):
			edificios += 1
			var p := (h as Node3D).position
			if absf(p.x) < cx + EntornoEstadio.CALLE and absf(p.z) < cz + EntornoEstadio.CALLE:
				dentro += 1
	_comprobar(edificios == 64 and dentro == 0, "64 edificios en el horizonte, todos más allá de la avenida (%d dentro)" % dentro)
	var raiz2 := Node3D.new()
	var e2 := EntornoEstadio.montar(raiz2, est, 2)
	var mismo := e2.get_child_count() == e.get_child_count()
	for i in mini(e.get_child_count(), e2.get_child_count()):
		var a := e.get_child(i) as Node3D
		var b := e2.get_child(i) as Node3D
		mismo = mismo and (a == null or a.transform.is_equal_approx(b.transform))
	_comprobar(mismo, "el mismo estadio sale siempre igual (semilla por nombre y forma)")
	raiz.free()
	raiz2.free()
	_comprobar(_nodos() == n0, "sin nodos sueltos")

# ------------------------------------------------------------ FachadaEstadio

func _probar_fachada() -> void:
	_linea("· FachadaEstadio")
	var casos := [
		[{"fachadaEstilo": "celosia", "fachada": "ladrillo"}, 2, "celosia"], [{"fachada": "ladrillo"}, 2, "clasico"],
		[{"fachada": "membrana"}, 2, "membrana"], [{"fachada": "vidrio"}, 2, "lamas"], [{"fachada": "metal"}, 3, "celosia"],
		[{"fachada": "metal"}, 1, "barrio"], [{"fachada": "hormigon"}, 1, "barrio"], [{"fachadaCol": "#e8e2d0"}, 2, "clasico"],
		[{"fachadaCol": "#303030"}, 2, "porticos"],
	]
	var mal: Array[String] = []
	for cs: Array in casos:
		var es := FachadaEstadio.estilo_de(cs[0], 7, int(cs[1]))
		if es != String(cs[2]):
			mal.append("%s→%s" % [cs[2], es])
	_comprobar(mal.is_empty(), "estilo_de(): forzado, material, bandejas y color de fachada mandan %s" % str(mal))
	var por_semilla := {}
	for s in 60:
		por_semilla[FachadaEstadio.estilo_de({}, s, 2)] = true
	_comprobar(por_semilla.size() >= 4 and FachadaEstadio.estilo_de({}, 33, 2) == FachadaEstadio.estilo_de({}, 33, 2), "con hormigón sin color, la semilla reparte estilos (%d) y siempre igual" % por_semilla.size())
	var c := FachadaEstadio.cara(Vector3(0, 0, -60), Vector3(0, 0, -1), 100.0, 18.0, "tribuna", true, 25.0, 2)
	_comprobar(absf((c["u"] as Vector3).dot(c["n"])) < 1e-5 and (c["u"] as Vector3).y == 0.0 and (c["o"] as Vector3).is_equal_approx(Vector3(0, 0, -60) - (c["u"] as Vector3) * 50.0),
		"cara(): el paño corre perpendicular a su normal, con el pie izquierdo en su sitio")
	var esquina := FachadaEstadio.cara(Vector3(50, 0, -50), Vector3(0.7071, 0, -0.7071), 12.0, 16.0, "esquina", false, 12.0, 2)
	var diminuta := FachadaEstadio.cara(Vector3(0, 0, 60), Vector3(0, 0, 1), 1.5, 18.0, "tribuna", true, 25.0, 2)
	var n0 := _nodos()
	var sin_malla: Array[String] = []
	for estilo: String in FachadaEstadio.ESTILOS:
		var raiz := Node3D.new()
		var f := FachadaEstadio.montar(raiz, {"fachadaEstilo": estilo, "asiento1": "#1f5f3d", "asiento2": "#ffffff", "clima": "noche"}, [c, esquina, diminuta], 11, 2)
		var grande := f.get_node_or_null("FachadaEstructura") as MeshInstance3D
		var detalle := f.get_node_or_null("FachadaDetalle") as MeshInstance3D
		if String(f.get_meta("estilo", "")) != estilo or grande == null or grande.mesh.get_surface_count() < 1 or detalle == null or detalle.visibility_range_end != FachadaEstadio.RANGO_DETALLE:
			sin_malla.append(estilo)
		raiz.free()
	_comprobar(sin_malla.is_empty(), "los 6 estilos funden su fachada en dos mallas (el detalle se apaga lejos) %s" % str(sin_malla))
	_comprobar(_nodos() == n0, "sin nodos sueltos tras montar los 6")
	var raiz_v := Node3D.new()
	var fv := FachadaEstadio.montar(raiz_v, {"fachadaEstilo": "lamas"}, [diminuta], 3, 2)
	_comprobar(fv.get_node_or_null("FachadaEstructura") == null, "un paño de menos de 2 m no se viste")
	raiz_v.free()
	var p_noche := FachadaEstadio._paleta({"clima": "noche"}, "membrana", 1)
	var p_dia := FachadaEstadio._paleta({"clima": "dia"}, "membrana", 1)
	_comprobar(FachadaEstadio._material(FachadaEstadio.K_REVEST, p_noche).emission_enabled and not FachadaEstadio._material(FachadaEstadio.K_REVEST, p_dia).emission_enabled,
		"la membrana se enciende por dentro solo de noche")
	_comprobar(FachadaEstadio._material(FachadaEstadio.K_LUZ, p_noche).emission_energy_multiplier > FachadaEstadio._material(FachadaEstadio.K_LUZ, p_dia).emission_energy_multiplier,
		"la iluminación de fachada brilla más de noche")
	var negro := FachadaEstadio._paleta({"asiento1": "#050505", "asiento2": "#0a0a0a"}, "lamas", 0)
	_comprobar((negro["revest"] as Color).get_luminance() >= 0.12 * 0.65 and absf((negro["revest"] as Color).get_luminance() - (negro["acento"] as Color).get_luminance()) >= 0.08,
		"un club de negro no deja la fachada como un agujero (y el acento contrasta)")

# ------------------------------------------------------------- EstadioExtras

func _probar_extras() -> void:
	_linea("· EstadioExtras")
	var n0 := _nodos()
	var c := Club.new("f0m_club", "Club de Prueba")
	c.color1 = "#c01020"
	c.color2 = "#ffffff"
	var raiz := Node3D.new()
	add_child(raiz)
	EstadioExtras.construir(raiz, {"en_obra": ["cal"], "inst": {"cal": 2, "com": 1, "pren": 1, "museo": 1}, "mascota": false}, 34.0, 52.5, 14.0, 2, c)
	var obras := raiz.get_node_or_null("Obras")
	var inst := raiz.get_node_or_null("Instalaciones")
	_comprobar(obras != null and _de_tipo(obras, "MultiMeshInstance3D").size() >= 1, "en obra: andamio (tubos en MultiMesh) y grúa")
	_comprobar(raiz.get_node_or_null("Mascota") == null, "con «mascota» apagada no sale la mascota")
	var rotulos: Array[String] = []
	for l: Label3D in _de_tipo(inst, "Label3D"):
		rotulos.append(l.text)
	_comprobar(rotulos.has(Idiomas.t("PALCOS VIP")) and rotulos.has(Idiomas.t("PRENSA")) and rotulos.size() == 4, "palcos, cabina de prensa, museo y tienda rotulados %s" % str(rotulos))
	var separadores := 0
	for h: Node in inst.get_children():
		if h is MeshInstance3D and (h as MeshInstance3D).mesh is BoxMesh and ((h as MeshInstance3D).mesh as BoxMesh).size == Vector3(4.4, 2.6, 0.12):
			separadores += 1
	_comprobar(separadores == 6, "palcos: 2 + calidad + comercial = 5, con sus 6 separadores (%d)" % separadores)
	var raiz2 := Node3D.new()
	add_child(raiz2)
	EstadioExtras.construir(raiz2, {"mascota": false}, 34.0, 52.5, 14.0, 2, null)
	var inst2 := raiz2.get_node_or_null("Instalaciones")
	_comprobar(raiz2.get_node_or_null("Obras") == null and _de_tipo(inst2, "Label3D").size() == 1, "sin obras ni instalaciones: solo los dos palcos de base")
	var animales := {}
	for i in 30:
		var ci := Club.new("club_%d" % i, "C")
		animales[EstadioExtras.animal_de(ci)] = true
	_comprobar(EstadioExtras.animal_de(c) == EstadioExtras.animal_de(c) and MascotaQ.ANIMALES.has(EstadioExtras.animal_de(c)) and animales.size() >= 6,
		"la mascota sale del club: siempre la misma, y variada entre clubes (%d animales)" % animales.size())
	raiz.free()
	raiz2.free()
	_comprobar(_nodos() == n0, "sin nodos sueltos")
