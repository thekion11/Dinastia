extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 del mundo 3D: el ESTADIO PROPIO reformado muchas veces seguidas (CON pantalla: xvfb + OpenGL, que guarda las instancias de los MultiMesh).
##   1. reformas seguidas (`aleatorio`: forma, colores, techo, niveles, pista…, con obras que terminan) y aforos de 5 000 a 90 000: cada una se construye con su césped, sin piezas enterradas, y las butacas visibles crecen con el aforo.
##   2. Reabrir el MISMO estadio en la misma vista 3 veces: el árbol no duplica piezas (mismos nodos y butacas) ni deja huérfanos.
##   3. Nombre del estadio con caracteres raros, vacío o de 200 letras: `renombrar` lo deja limpio y corto.
const SEMANAS_OBRA := 40

func _probar() -> void:
	_titulo("A4 MUNDO_3D: estadio propio, reformas seguidas (con pantalla)")
	if DisplayServer.get_name() == "headless":
		_comprobar(false, "esta prueba necesita pantalla (xvfb + OpenGL)")
		return
	Calidad.elegida = Calidad.MEDIO
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, 321)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var club := m.mi_club()
	club.saldo = 2000000000
	_nombres(m)
	var malas: Array[String] = []
	var puntos: Array[Vector2] = []   ## aforo, butacas visibles
	var huer0 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for i in int(OS.get_environment("ESTADIOS")) if OS.get_environment("ESTADIOS") != "" else 6:
		var d := m.estadio.aleatorio(club, m.obras)
		var r := m.estadio.reformar(club, d, m.obras)
		for s in SEMANAS_OBRA:
			m.estadio.avanzar_semana()
		if i % 4 == 3 and m.obras.nivel("trib") < 5:
			m.obras.niveles["trib"] = m.obras.nivel("trib") + 1
		club.estadio_aforo = [5000, 90000, 22000, 65000, 12000, 40000][i % 6]
		club.saldo = 2000000000
		var perfil: Dictionary = m.perfil_estadio_de(club)
		Azar.sembrar(4242)
		var v := VistaEstadio.new()
		add_child(v)
		await v.abrir(club, 0.5, null, null, perfil)
		for k in 10:
			await get_tree().process_frame
		var raiz: Node3D = v.get("_raiz3d")
		if raiz == null or raiz.get_node_or_null("Cesped") == null:
			malas.append("reforma %d (%s): sin césped/raíz" % [i, r if r != "" else "ok"])
			v.free()
			continue
		var visibles := _butacas(raiz)
		var enterradas := 0
		for h in raiz.get_children():
			if h is MeshInstance3D and (h as MeshInstance3D).mesh != null and (h as MeshInstance3D).visible:
				var c := (h as MeshInstance3D).global_transform * (h as MeshInstance3D).get_aabb()
				if c.end.y < -0.5 and not String(h.name).begins_with("Sombra"):
					enterradas += 1
		if enterradas > 0:
			malas.append("reforma %d: %d piezas enterradas" % [i, enterradas])
		puntos.append(Vector2(float(perfil.get("aforo", club.estadio_aforo)), float(visibles)))
		if i == 5:
			## reabrir el mismo estadio 3 veces en la misma vista: nada se duplica
			var nodos1 := raiz.find_children("*", "Node", true, false).size()
			var mm1 := _butacas(raiz)
			for rep in 3:
				await v.abrir(club, 0.5, null, null, perfil)
				for k in 10:
					await get_tree().process_frame
			var raiz2: Node3D = v.get("_raiz3d")
			var nodos2 := raiz2.find_children("*", "Node", true, false).size()
			var mm2 := _butacas(raiz2)
			print("  (info) reabrir 3 veces: nodos %d → %d, butacas %d → %d" % [nodos1, nodos2, mm1, mm2])
			if nodos2 > nodos1 * 1.2 or mm2 != mm1:
				malas.append("reabrir el estadio 3 veces duplica piezas: nodos %d → %d, butacas %d → %d" % [nodos1, nodos2, mm1, mm2])
		v.free()
		await get_tree().process_frame
	_comprobar(malas.is_empty(), "reformas seguidas: se construye, sin enterradas, sin duplicados (%d fallos%s)" % [malas.size(), "" if malas.is_empty() else ": " + str(malas.slice(0, 4))])
	## las butacas visibles siguen al aforo (no por reforma, sino en general: correlación positiva)
	puntos.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var bajas := 0
	for k in range(1, puntos.size()):
		if puntos[k].x >= puntos[k - 1].x * 1.8 and puntos[k].y < puntos[k - 1].y * 0.5:
			bajas += 1
	print("  (info) aforo → butacas visibles: %s" % str(puntos.slice(0, 24)))
	_comprobar(bajas <= 2, "las butacas visibles siguen al aforo (%d inversiones grandes en %d estadios)" % [bajas, puntos.size()])
	var huer1 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_comprobar(huer1 - huer0 < 100, "las vistas liberadas no dejan nodos huérfanos (%d → %d)" % [huer0, huer1])

func _butacas(raiz: Node3D) -> int:
	var n := 0
	for g in raiz.find_children("Butacas*", "MultiMeshInstance3D", true, false):
		var mm := (g as MultiMeshInstance3D).multimesh
		for q in mm.instance_count:
			if mm.get_instance_color(q).a > 0.5 and mm.get_instance_transform(q).basis.get_scale().y > 0.01:
				n += 1
	return n

func _nombres(m: Mundo) -> void:
	var casos := ["", "   ", "Estadio Ñuñoa 🏟️ ¡Hola! ✓", "[b]negrita[/b] [color=red]x", "línea1\nlínea2\ttab", "%s %d %%", "A".repeat(200), "ÀÉÎÕÜ".repeat(40), "\u202Eabc"]
	var mal: Array[String] = []
	for c in casos:
		m.estadio.renombrar(c)
		var n := m.estadio.nombre_de(m.mi_club())
		if n.length() > 70 or n.contains("\n") or n.contains("\t") or n == "":
			mal.append("«%s…» → %d letras / salto / vacío" % [String(c).left(12), n.length()])
	_comprobar(mal.is_empty(), "nombre del estadio con vacíos, emojis, BBCode, saltos, marcadores y 200 letras: limpio, ≤ 70 letras y nunca vacío (%d fallos%s)" % [mal.size(), "" if mal.is_empty() else ": " + str(mal.slice(0, 3))])
	m.estadio.renombrar("")
