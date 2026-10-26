extends Node
## SONDA pmov (26-10-2026): piezas altas de la ciudad (apoyadas en el suelo) cuyo
## centro se puede pisar a pie. Lista los tipos y FALLA si un edificio (del kit
## o la casa grande) se puede atravesar: antes había 12 rascacielos del borde y
## la casa grande del barrio sin huella (`ExploradorCiudad._huellas_de_torres`).

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	var p: Node = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	for i in 6:
		await get_tree().process_frame
	p.call("_ver_ciudad_propia")
	var v: VistaCiudad = null
	for h in p.get_children():
		if h is VistaCiudad:
			v = h
	v.explorar("pie")
	for i in 3:
		await get_tree().process_frame
	var e: ExploradorCiudad = v.get("_explorador")
	var cb: CityBuilder = e.cb
	var huecos := {}
	var ejemplo := {}
	var re := RegEx.create_from_string("[0-9@]+")
	var total := 0
	for n in cb.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or e.trafico.is_ancestor_of(mi):
			continue
		var caja := mi.global_transform * mi.get_aabb()
		if caja.size.y < 1.2 or caja.position.y > 1.0:
			continue
		var c := caja.get_center()
		var q := Vector3(c.x, 0, c.z)
		total += 1
		if e.libre_obst(q, 0.3) and not e._choca_circulos(q, 0.3):
			var clave := re.sub("%s <- %s <- %s" % [mi.name, mi.get_parent().name, mi.get_parent().get_parent().name], "", true) + " (%s)" % mi.mesh.resource_name
			huecos[clave] = int(huecos.get(clave, 0)) + 1
			ejemplo[clave] = "(%.0f, %.0f) tam %.1fx%.1f" % [c.x, c.z, caja.size.x, caja.size.z]
	for n in cb.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		var mm := mmi.multimesh
		if mm == null or mm.mesh == null or not mmi.is_visible_in_tree():
			continue
		var base := mm.mesh.get_aabb()
		for i in mm.instance_count:
			var caja := mmi.global_transform * mm.get_instance_transform(i) * base
			if caja.size.y < 1.2 or caja.position.y > 1.0:
				continue
			var c := caja.get_center()
			var q := Vector3(c.x, 0, c.z)
			total += 1
			if e.libre_obst(q, 0.3) and not e._choca_circulos(q, 0.3):
				var clave := re.sub("MM %s <- %s" % [mmi.name, mmi.get_parent().name], "", true)
				huecos[clave] = int(huecos.get(clave, 0)) + 1
				ejemplo[clave] = "(%.0f, %.0f) tam %.1fx%.1f" % [c.x, c.z, caja.size.x, caja.size.z]
	print("SONDA piezas altas: %d · atravesables: %d tipos" % [total, huecos.size()])
	var claves := huecos.keys()
	claves.sort_custom(func(a, b) -> bool: return int(huecos[a]) > int(huecos[b]))
	for k in claves.slice(0, 80):
		print("  %4d  %s  ej %s" % [int(huecos[k]), k, ejemplo[k]])
	var edificios := 0
	for k: String in claves:
		if k.contains("building-") or k.contains("CasaGigante") or k.contains("complejo"):
			edificios += int(huecos[k])
	print("  %s edificios que se atraviesan: %d" % ["ok   " if edificios == 0 else "FALLO", edificios])
	print("===== FIN. %d fallos =====" % (0 if edificios == 0 else 1))
	get_tree().quit(0 if edificios == 0 else 1)
