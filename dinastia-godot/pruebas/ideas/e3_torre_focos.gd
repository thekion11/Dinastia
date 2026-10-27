extends BaseIdea
## ESTADIO (27-10-2026): las torres de focos del estadio son el modelo del Drive (`TorreFocos`), giradas al campo, con la emisión del color de luz.

func _probar() -> void:
	_titulo("E3 · TORRE DE FOCOS DEL DRIVE")
	_comprobar(TorreFocos.disponible(), "el recurso torre_focos.glb carga")
	if not TorreFocos.disponible():
		return
	var raiz := Node3D.new()
	add_child(raiz)
	var ok := TorreFocos.montar(raiz, Vector3(50, 0, 40), 30.0, Vector3(10, 0, 8), Color(1.0, 0.9, 0.7))
	var t := raiz.get_node_or_null("TorreFocos") as Node3D
	_comprobar(ok and t != null, "se monta en la base indicada")
	if t == null:
		return
	## Escala: 30 m de alto sobre los 23,2 del modelo.
	_comprobar(absf(t.scale.y - 30.0 / TorreFocos.ALTO) < 0.001, "escalada a 30 m (x%.2f)" % t.scale.y)
	## Los focos miran al campo: el +Z local de la torre apunta hacia el punto de mira.
	var frente := (t.global_transform.basis * Vector3(0, 0, 1)).normalized()
	var hacia := (Vector3(10, 0, 8) - Vector3(50, 0, 40)).normalized()
	_comprobar(frente.dot(Vector3(hacia.x, 0, hacia.z).normalized()) > 0.99, "los focos miran al campo (%.3f)" % frente.dot(Vector3(hacia.x, 0, hacia.z).normalized()))
	var emisivos := 0
	for m: Node in t.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat is StandardMaterial3D and (mat as StandardMaterial3D).emission_enabled and (mat as StandardMaterial3D).emission.is_equal_approx(Color(1.0, 0.9, 0.7)):
				emisivos += 1
	_comprobar(emisivos >= 1, "la emisión de los proyectores lleva el color de luz (%d superficies)" % emisivos)
	## En un estadio de torres hay cuatro.
	var club := Club.new("e3_club", "Club E3")
	club.color1 = "#1f4f9a"
	club.color2 = "#f2f2f2"
	var est := Node3D.new()
	add_child(est)
	StadiumBuilder.build(est, {"forma": "cuenco", "niveles": 2, "techo": "anillo", "focos": "torres", "aforo": 30000}, 30000, 0.4, 7, club)
	var en_estadio := 0
	for n: Node in get_tree().get_nodes_in_group("torres_focos"):
		if est.is_ancestor_of(n):
			en_estadio += 1
	_comprobar(en_estadio == 4, "un estadio con torres lleva 4 (%d)" % en_estadio)
