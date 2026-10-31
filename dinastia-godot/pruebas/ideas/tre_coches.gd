extends BaseIdea
## COCHES MENOS INFANTILES Y CON PLACA (27-10-2026): pintura apagada con cristales oscuros, placas «AB 123 CD», faros y retrovisores.

func _probar() -> void:
	_titulo("CIUDAD · COCHES CON PINTURA REAL Y PLACAS")
	var e := load("res://assets/ciudad/kenney_cars/sedan.glb") as PackedScene
	var coche := CityBuilder.instanciar_coche({"esc": e})
	add_child(coche)
	var cuerpo := coche.find_child("body", true, false) as MeshInstance3D
	_comprobar(cuerpo != null and cuerpo.material_override is ShaderMaterial, "el cuerpo lleva la pintura de coche real (shader)")
	var placas := 0
	for mi in coche.get_children():
		if mi is MeshInstance3D and (mi as MeshInstance3D).mesh is QuadMesh:
			placas += 1
	_comprobar(placas == 2, "dos placas: delante y detrás")
	var rx := RegEx.create_from_string("^[A-Z]{2} [0-9]{3} [A-Z]{2}$")
	var distintas := {}
	var bien := true
	for i in CocheDetalle.N_PLACAS:
		var t := CocheDetalle.texto_placa(i)
		distintas[t] = true
		bien = bien and rx.search(t) != null
	_comprobar(bien and distintas.size() >= 20, "las matrículas son «AB 123 CD» y casi todas distintas (%d de %d)" % [distintas.size(), CocheDetalle.N_PLACAS])
	var mat := CocheDetalle.placa(3)
	_comprobar(mat.albedo_texture != null and mat.albedo_texture.get_width() == 128, "cada placa es una textura propia dibujada con la fuente de 5×7")
	var otro := CityBuilder.instanciar_coche({"esc": e})
	var m1 := ((coche.get_children().filter(func(n): return n is MeshInstance3D and (n as MeshInstance3D).mesh is QuadMesh)[0]) as MeshInstance3D).material_override
	var m2 := ((otro.get_children().filter(func(n): return n is MeshInstance3D and (n as MeshInstance3D).mesh is QuadMesh)[0]) as MeshInstance3D).material_override
	_comprobar(m1 != m2, "dos coches seguidos llevan placas distintas")
	otro.free()
	## La cabina por dentro y el tren del metro.
	var cab := Node3D.new()
	add_child(cab)
	var r := CabinaCoche.montar(cab)
	_comprobar(r["volante"] is Node3D and r["kmh"] is Label3D and cab.get_child_count() > 40, "la cabina tiene volante, velocímetro y %d piezas (salpicadero, esferas, pantalla, puertas, techo)" % cab.get_child_count())
	var tren := Node3D.new()
	add_child(tren)
	TrenDetalle.vestir(tren, Color(0.85, 0.15, 0.15), 1.0, "L1")
	var ruedas := 0
	for h in tren.get_children():
		if h is MeshInstance3D and (h as MeshInstance3D).mesh is CylinderMesh:
			ruedas += 1
	_comprobar(ruedas == 3 * 2 * 2 * 2, "tres coches con dos bogies de dos ejes y cuatro ruedas (%d ruedas)" % ruedas)
	_comprobar(TrenDetalle.carroceria().metallic > 0.5, "la carrocería es de acero inoxidable (metálica), no un blanco liso")
