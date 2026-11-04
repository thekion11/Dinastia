extends BaseIdea
## «Partido ligero» (4-11, orden 32 del dueño): agregado aparte de la calidad, APAGADO por defecto en todas; encendido quita al estadio
## el ajuste de color, los rótulos 3D y los focos (no el sol), también los que se crean después; se guarda en grafica.cfg.

func _probar() -> void:
	_titulo("A4: PARTIDO LIGERO (agregado aparte de la calidad)")
	_respaldar_user()
	var antes := Calidad.partido_ligero
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Calidad.ARCHIVO))
	Calidad.partido_ligero = false
	Calidad.cargar()
	_comprobar(not Calidad.partido_ligero, "sin ajustes guardados viene APAGADO")
	for nivel in [Calidad.MINIMO, Calidad.MEDIO, Calidad.ALTO, Calidad.ULTRA]:
		Calidad.elegida = nivel
		var r0 := _estadio()
		PartidoLigero.montar(r0)
		await get_tree().process_frame
		_comprobar(r0.get_node_or_null("PartidoLigero") == null and (r0.get_node("Rotulo") as Label3D).visible, "apagado en calidad %d: no toca nada" % nivel)
		r0.queue_free()
	Calidad.elegida = Calidad.MINIMO
	Calidad.partido_ligero = true
	var r := _estadio()
	PartidoLigero.montar(r)
	await get_tree().process_frame
	var we := r.get_node("Entorno") as WorldEnvironment
	_comprobar(not we.environment.adjustment_enabled, "encendido: sin ajuste de color")
	_comprobar(not (r.get_node("Rotulo") as Label3D).visible, "encendido: sin rótulos 3D")
	_comprobar(not (r.get_node("Foco") as Light3D).visible, "encendido: sin focos")
	_comprobar((r.get_node("Sol") as Light3D).visible, "el sol se queda")
	var tarde := Label3D.new()
	r.add_child(tarde)
	await get_tree().process_frame
	await get_tree().process_frame
	_comprobar(not tarde.visible, "un rótulo creado después también se quita")
	Calidad.guardar()
	Calidad.partido_ligero = false
	Calidad.cargar()
	_comprobar(Calidad.partido_ligero, "se guarda y se carga")
	Calidad.elegida = Calidad.ULTRA
	var r2 := _estadio()
	PartidoLigero.montar(r2)
	await get_tree().process_frame
	_comprobar(not (r2.get_node("Rotulo") as Label3D).visible, "se puede encender también en ULTRA")
	r.queue_free()
	r2.queue_free()
	Calidad.partido_ligero = antes
	_restaurar_user()

func _estadio() -> Node3D:
	var r := Node3D.new()
	add_child(r)
	var we := WorldEnvironment.new()
	we.name = "Entorno"
	we.environment = Environment.new()
	we.environment.adjustment_enabled = true
	r.add_child(we)
	var l := Label3D.new()
	l.name = "Rotulo"
	r.add_child(l)
	var f := OmniLight3D.new()
	f.name = "Foco"
	r.add_child(f)
	var s := DirectionalLight3D.new()
	s.name = "Sol"
	r.add_child(s)
	return r
