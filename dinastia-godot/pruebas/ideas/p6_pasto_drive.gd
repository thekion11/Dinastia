extends BaseIdea
## Pasto del Drive (27-10-2026): matas con MultiMesh en celdas, ocultas a distancia, deterministas y fuera de la cancha.

func _probar() -> void:
	_titulo("P6: PASTO DEL DRIVE EN LOS PARQUES")
	var raiz := Node3D.new()
	add_child(raiz)
	var pts: Array = []
	for i in 200:
		pts.append(Vector3(float(i % 20) * 3.0, 0.1, float(i / 20) * 3.0))   ## 60 × 30 m: varias celdas de 24 m
	var n := PastoCiudad.sembrar(raiz, pts, 5)
	_comprobar(n == 200, "se siembran las 200 matas (%d)" % n)
	var celdas := 0
	var ocultan := true
	var instancias := 0
	for h in raiz.get_children():
		if h is MultiMeshInstance3D:
			celdas += 1
			instancias += (h as MultiMeshInstance3D).multimesh.instance_count
			if (h as MultiMeshInstance3D).visibility_range_end != PastoCiudad.DISTANCIA or (h as MultiMeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				ocultan = false
	_comprobar(celdas >= 6, "van en varios MultiMesh por celdas (%d nodos), no en uno solo" % celdas)
	_comprobar(ocultan, "cada celda se oculta a %.0f m y no proyecta sombra" % PastoCiudad.DISTANCIA)
	_comprobar(instancias >= 200, "las instancias suman al menos las matas (%d)" % instancias)
	## Un parque de 100 × 80 m: matas en el borde, ninguna sobre la cancha ni en los paseos en cruz.
	var r := Rect2(0, 0, 100, 80)
	var c := Vector3(50, 0, 40)
	var raiz2 := Node3D.new()
	add_child(raiz2)
	var antes := PastoCiudad.total_sembradas
	var cancha := Rect2(30, 20, 40, 40)
	var m := PastoCiudad.parque(raiz2, r, c, func(p: Vector3) -> bool: return cancha.has_point(Vector2(p.x, p.z)))
	_comprobar(m > 60, "el parque recibe matas (%d)" % m)
	_comprobar(PastoCiudad.total_sembradas == antes + m, "el contador cuenta las sembradas")
	var malo := 0
	for h in raiz2.get_children():
		if h is MultiMeshInstance3D:
			var mm := (h as MultiMeshInstance3D).multimesh
			for i in mm.instance_count:
				var o := mm.get_instance_transform(i).origin
				if cancha.grow(-1.0).has_point(Vector2(o.x, o.z)):
					malo += 1
	_comprobar(malo == 0, "ninguna mata dentro de la cancha")
	var raiz3 := Node3D.new()
	add_child(raiz3)
	PastoCiudad.parque(raiz3, r, c, func(p: Vector3) -> bool: return cancha.has_point(Vector2(p.x, p.z)))
	_comprobar(raiz3.get_child_count() == raiz2.get_child_count(), "reparto determinista (mismos nodos con la misma semilla)")
	## Flores (M-193): una de cada dos matas lleva un ramillete de 9; las cabezas llevan color por instancia.
	var raiz4 := Node3D.new()
	add_child(raiz4)
	var pts4: Array = []
	for i in 200:
		pts4.append(Vector3(float(i % 20) * 3.0, 0.1, float(i / 20) * 3.0))
	var nf := PastoCiudad.flores(raiz4, pts4, 5)
	_comprobar(nf > 700 and nf < 1100, "una de cada dos matas lleva su ramillete de 9 flores (%d flores de 200 matas)" % nf)
	var con_color := 0
	for h in raiz4.get_children():
		if h is MultiMeshInstance3D and (h as MultiMeshInstance3D).multimesh.use_colors:
			con_color += 1
			_comprobar((h as MultiMeshInstance3D).visibility_range_end == PastoCiudad.DISTANCIA_FLORES, "las flores se ocultan a %.0f m" % PastoCiudad.DISTANCIA_FLORES)
	_comprobar(con_color >= 2, "las cabezas llevan color propio (%d celdas)" % con_color)
