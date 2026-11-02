extends BaseIdea
## M-404 (2-11-2026): LOS MÓDULOS DEL VISOR QUE NINGUNA PRUEBA NOMBRABA. Se arma la ciudad una vez y se comprueba que cada
## uno deja sus piezas o responde: mirador y paisaje del teleférico, subsuelo con su sala de mando (PanelMando dibujando), el
## PC de la oficina, el HUD y la sala de prensa del prólogo y la multa del atropello.
##   herramientas/ideas.sh vis_sueltos   (~1 min, en especiales)

func _probar() -> void:
	_titulo("MÓDULOS DEL VISOR SIN PRUEBA (M-404)")
	var m := Mundo.new()
	m.generar(["CHI"], 4040)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var b := CityBuilder.new()
	add_child(b)
	b.build({"club": {"nombre": "Andino FC", "c1": Color(0.8, 0.1, 0.1), "c2": Color.WHITE, "cap": 30000, "rep": 60, "socios": 20000,
		"estadioNom": "Estadio"}, "inst": {}, "obras": [], "terrenos": [], "negocios": {}, "perfil_estadio": {}, "dia_partido": true, "vecinos": 30})
	var ex: CiudadExpansion = b.expansion
	## Teleférico: el mirador de la cima (MiradorCerro) y el paisaje de la ladera (TelefericoPaisaje, MultiMesh).
	var tele: Teleferico = ex.tele_nodo if ex != null else null
	_comprobar(tele != null and tele.mirador != null and tele.mirador.get_child_count() > 10, "el mirador del cerro deja losa, barandilla y bancos (%d piezas)" % (tele.mirador.get_child_count() if tele != null and tele.mirador != null else 0))
	if tele != null and tele.mirador != null:
		var c := tele.mirador.centro
		_comprobar(not tele.mirador.libre(Vector2(c.x + 500.0, c.z)), "fuera del mirador no se camina por él")
	var mm := tele.find_children("*", "MultiMeshInstance3D", true, false) if tele != null else []
	_comprobar(mm.size() > 0, "la ladera del teleférico tiene su paisaje en lotes (%d)" % mm.size())
	## Subsuelo: SubsueloMando (sala de control con pantallas PanelMando) y SubsueloDetalle (peligro, abrazaderas).
	var s := SubsueloCiudad.crear(b, ex.redes)
	var paneles := s.find_children("*", "PanelMando", true, false)
	_comprobar(paneles.size() > 0, "el subsuelo monta la sala de mando con %d pantallas" % paneles.size())
	_comprobar(s.get_child_count() > 100, "y sus detalles (%d piezas)" % s.get_child_count())
	if not paneles.is_empty():
		var pm := paneles[0] as PanelMando
		pm.queue_redraw()
		await get_tree().process_frame
		_comprobar(pm.modelo != null, "la pantalla de mando lee el modelo de redes")
	## PC de la oficina: aro en el suelo y sin explorador no está «cerca».
	var raiz := Node3D.new()
	add_child(raiz)
	var pc := PcOficina.new()
	add_child(pc)
	pc.montar(raiz, Vector3(3, 0, 4), 1)
	_comprobar(raiz.get_child_count() == 1 and not pc.cerca() and not pc.abierto, "el PC pone su aro y, sin nadie encima, no se enciende")
	## HUD del prólogo: tarjeta, flecha y saltar con confirmación.
	var hud := PrologoHud.new()
	add_child(hud)
	await get_tree().process_frame
	hud.tarjeta(["Línea uno", "Línea dos"] as Array[String])
	hud.flecha(true, 0.5, 12.0)
	hud.pedir_saltar()
	_comprobar(hud.confirmando_salto(), "el HUD del prólogo pide confirmar antes de saltarse el prólogo")
	hud.presentacion("Santiago", "Andino FC", 0.1)
	## Sala de prensa del prólogo.
	var prensa := PrologoPrensa.new()
	add_child(prensa)
	prensa.montar(m, m.mi_club(), Color(0.8, 0.1, 0.1), {})
	await get_tree().process_frame
	_comprobar(prensa.get_child_count() > 0, "la sala de prensa del prólogo se monta")
	## Atropello: multa (150) y titular una sola vez por semana.
	var vida := VidaCiudad.new()
	vida.mundo = m
	var aviso := AtropelloCiudad.multar(vida)
	var titular := m.prensa.titular_pendiente.duplicate() if m.prensa != null else {}
	m.prensa.titular_pendiente = {}
	AtropelloCiudad.multar(vida)
	_comprobar(aviso.contains("150") and not titular.is_empty() and m.prensa.titular_pendiente.is_empty(), "el atropello multa y sale en prensa una vez por semana")
	vida.free()
	for n: Node in [hud, prensa, pc, raiz, b]:
		n.queue_free()
