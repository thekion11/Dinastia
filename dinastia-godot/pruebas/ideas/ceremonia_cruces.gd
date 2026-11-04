extends BaseIdea
## U6 (3-11): ¿se cruzan los cuerpos en la salida de equipos y el sorteo? Avanza la ceremonia REAL a paso de 0,05 s y mide la distancia en planta entre cada par de
## jugadores, árbitro y niños. Dos jugadores a menos de 0,35 m = cuerpos que se atraviesan (un cuerpo mide ~0,5 m de ancho de hombro a hombro).
const MIN_CUERPOS := 0.35

func _ready() -> void:
	await get_tree().process_frame
	_titulo("U6 · CRUCES EN LA CEREMONIA")
	var m := _mundo(4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	var vista := VistaEstadio.new()
	add_child(vista)
	vista.abrir(par[0], 0.85, par[1], partido)
	for i in 40:
		await get_tree().process_frame
	var perfil: Dictionary = vista.get("_perfil")
	var gc := StadiumBuilder.geom_de_forma(String(perfil.get("forma", "oval")))
	var vieja: Variant = vista.get("_ceremonia")
	if vieja is CeremoniaPartido and is_instance_valid(vieja):
		(vieja as CeremoniaPartido).terminar()
	var cer := CeremoniaPartido.iniciar(vista, vista.get("_raiz3d"), vista.get("_en_campo"), partido.local, partido.visita,
		"Estadio", float(gc["dx"]), float(gc["dz"]), StadiumBuilder.tunel_x(perfil))
	vista.set("_ceremonia", cer)
	var peor := 99.0
	var peor_t := 0.0
	var peor_par := ""
	var t := 0.0
	while t < CeremoniaPartido.T_FIN and is_instance_valid(cer) and cer.activa:
		cer._process(0.05)
		t += 0.05
		var cuerpos: Array = []
		for p: Dictionary in cer._jugadores:
			if p["node"].visible:
				cuerpos.append([p["node"] as Node3D, "%s %s" % ["L" if bool(p["es_local"]) else "V", String(p.get("id", ""))]])
		if not cer._arbitro.is_empty():
			cuerpos.append([cer._arbitro["node"] as Node3D, "árbitro"])
		for a in cuerpos.size():
			for b in range(a + 1, cuerpos.size()):
				var d := Vector2((cuerpos[a][0] as Node3D).position.x - (cuerpos[b][0] as Node3D).position.x, (cuerpos[a][0] as Node3D).position.z - (cuerpos[b][0] as Node3D).position.z).length()
				if d < peor:
					peor = d
					peor_t = t
					peor_par = "%s / %s en (%.1f, %.1f) y (%.1f, %.1f); sus caminos: %d y %d tramos" % [cuerpos[a][1], cuerpos[b][1], (cuerpos[a][0] as Node3D).position.x, (cuerpos[a][0] as Node3D).position.z,
						(cuerpos[b][0] as Node3D).position.x, (cuerpos[b][0] as Node3D).position.z, (cer._destinos.get(cuerpos[a][0], []) as Array).size(), (cer._destinos.get(cuerpos[b][0], []) as Array).size()]
	print("   la menor distancia entre dos cuerpos: %.2f m a los %.1f s (%s)" % [peor, peor_t, peor_par])
	_comprobar(peor >= MIN_CUERPOS, "en toda la ceremonia (%.0f s) ningún par de cuerpos baja de %.2f m" % [t, MIN_CUERPOS])
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
