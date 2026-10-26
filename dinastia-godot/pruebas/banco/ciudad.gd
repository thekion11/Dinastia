extends "res://pruebas/banco/ciudad_p1.gd"
## [Banco · grupo «ciudad» · capa 2/2] Generado al partir el banco por grupos (26-10).

## ETAPA 3: la optimización por código no cambia lo que se ve y lo elegido en
## gráficos se guarda.
func _probar_optimizacion() -> void:
	_titulo("ETAPA 3: OPTIMIZACIÓN (AGRUPAR, PRIMITIVAS, CALIDAD GUARDADA)")
	var raiz := Node3D.new()
	add_child(raiz)
	for i in 6:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.0 + i, 2.0, 0.5)
		mi.mesh = b
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.3, 0.6, 0.2)
		mi.material_override = m
		mi.position = Vector3(i * 4.0, 0, 0)
		raiz.add_child(mi)
	## Uno que se mueve (cuelga de un nodo con script): no se toca.
	var movil := Node3D.new()
	movil.set_script(GDScript.new())
	raiz.add_child(movil)
	var mi2 := MeshInstance3D.new()
	mi2.mesh = BoxMesh.new()
	movil.add_child(mi2)
	var cil := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.1
	cm.bottom_radius = 0.1
	cil.mesh = cm
	raiz.add_child(cil)
	Optimizar.primitivas(raiz)
	_comprobar(cm.radial_segments <= 8 and cm.rings == 0, "un poste fino baja de 64 lados a %d" % cm.radial_segments)
	var r := Optimizar.agrupar(raiz)
	var mms := raiz.find_children("Agrupado*", "MultiMeshInstance3D", true, false)
	_comprobar(int(r["piezas"]) >= 6 and mms.size() >= 1, "las 6 cajas iguales (distinto tamaño) quedan en un MultiMesh")
	## (Sin gráfica, el servidor de render no guarda las transformaciones del
	## MultiMesh: se comprueba el plegado de tamaño y el número de instancias.)
	var n6 := 0
	for n in mms:
		if (n as MultiMeshInstance3D).multimesh.instance_count == 6:
			n6 += 1
	var cj := MeshInstance3D.new()
	var bj := BoxMesh.new()
	bj.size = Vector3(6.0, 2.0, 0.5)
	cj.mesh = bj
	var pl := Optimizar._plegar(cj, bj)
	cj.free()
	var ok_tam: bool = n6 == 1 and pl.size() == 2 and (pl[0] as BoxMesh).size == Vector3.ONE \
		and (pl[1] as Vector3).is_equal_approx(Vector3(6.0, 2.0, 0.5))
	_comprobar(ok_tam, "cada caja agrupada conserva su tamaño y su sitio")
	_comprobar(is_instance_valid(mi2) and mi2.get_parent() == movil, "lo que cuelga de un nodo con script no se agrupa")
	raiz.queue_free()
	## Lo elegido en gráficos sobrevive a reabrir el juego.
	var previo := [Calidad.elegida, Calidad.adaptativa, Calidad.motor_ligero]
	var existia := FileAccess.file_exists(Calidad.ARCHIVO)
	Calidad.elegida = Calidad.MEDIO
	Calidad.adaptativa = false
	Calidad.motor_ligero = true
	Calidad.guardar()
	Calidad.elegida = Calidad.ULTRA
	Calidad.adaptativa = true
	Calidad.motor_ligero = false
	Calidad.cargar()
	_comprobar(Calidad.elegida == Calidad.MEDIO and not Calidad.adaptativa and Calidad.motor_ligero,
		"calidad, ajuste automático y motor se guardan y se leen")
	Calidad.elegida = previo[0]
	Calidad.adaptativa = previo[1]
	Calidad.motor_ligero = previo[2]
	if existia:
		Calidad.guardar()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Calidad.ARCHIVO))

func _probar_no_atravesar_paredes() -> void:
	_titulo("CIUDAD: NO SE ATRAVIESAN PAREDES")
	var ex := _ExpPared.new()
	ex.cuerpo = Node3D.new()
	ex.modo = "pie"
	ex.cuerpo.position = Vector3(4.0, 0, 0)
	ex.movil_encima = true
	for i in 40:
		ex._mover_un_trozo(Vector3(0.3, 0, 0), 0.4)
	_comprobar(ex.cuerpo.position.x + 0.4 <= ex.pared_x + 0.001, "con un coche encima no se entra en el edificio (x=%.2f, pared en %.1f)" % [ex.cuerpo.position.x, ex.pared_x])
	ex._mover_un_trozo(Vector3(-0.3, 0, 0), 0.4)
	_comprobar(ex.cuerpo.position.x < 4.3, "pero sí se puede salir de debajo del coche hacia la calle")
	ex.movil_encima = false
	ex.cuerpo.position = Vector3(5.5, 0, 0)
	ex._mover_un_trozo(Vector3(-0.3, 0, 0), 0.4)
	_comprobar(ex.cuerpo.position.x < 5.5, "si ya estás dentro de algo fijo (al salir del metro) se te deja salir")
	ex.cuerpo.free()
	ex.free()
