extends "res://pruebas/banco/varios_p11_p1.gd"
## (Parte 2 de 2 de `varios_p11.gd`.)

## FORMACIONES PROPIAS (10-11, pedido del dueño, «Editar posición» del PES 2020): el puesto cambia solo según la zona, el portero no
## se mueve, quedan al menos 3 defensas, se guarda con ★ en la tabla y vuelve al cargar la partida.
func _probar_formacion_propia() -> void:
	_titulo("TÁCTICA: FORMACIONES PROPIAS")
	_comprobar(FormacionPropia.puesto_de(50, 80) == "DFC" and FormacionPropia.puesto_de(88, 75) == "LD" and FormacionPropia.puesto_de(50, 62) == "MCD" and FormacionPropia.puesto_de(12, 60) == "CAI" and FormacionPropia.puesto_de(50, 33) == "MCO" and FormacionPropia.puesto_de(82, 22) == "ED" and FormacionPropia.puesto_de(50, 18) == "DC", "el puesto sale de la zona (DFC, LD, MCD, CAI, MCO, ED, DC)")
	var f := FormacionPropia.desde("4-4-2")
	_comprobar(int(f["DEF"]) == 4 and int(f["MED"]) == 4 and int(f["DEL"]) == 2, "parte de la base 4-4-2")
	_comprobar(FormacionPropia.mover(f, 0, 50, 60) == "portero", "el portero no se mueve")
	var mc := -1
	for i in (f["s"] as Array).size():
		if String(f["s"][i][0]) == "MC":
			mc = i
			break
	_comprobar(FormacionPropia.mover(f, mc, 50, 32) == "" and String(f["s"][mc][0]) == "MCO" and int(f["MED"]) == 4, "un mediocentro que sube pasa a mediapunta (4-4-2 con rombo)")
	var g := FormacionPropia.desde("3-5-2")
	var dfc := -1
	for i in (g["s"] as Array).size():
		var pu := String(g["s"][i][0])
		if pu == "CAD" or pu == "CAI":
			FormacionPropia.mover(g, i, float(g["s"][i][1]), 45.0)   ## los carrileros suben a interiores
		elif pu == "DFC" and dfc < 0:
			dfc = i
	_comprobar(int(g["DEF"]) == 3 and FormacionPropia.mover(g, dfc, 50, 45) == "defensas" and String(g["s"][dfc][0]) == "DFC", "con 3 defensas no se puede subir a otro")
	var c := Club.new()
	c.tactica = Tactica.new()
	var n := FormacionPropia.guardar(c.tactica, "Mi rombo", f)
	_comprobar(n == "★ Mi rombo" and Datos.tabla("FORMS").has(n) and Puente3D.formacion(n)["s"].size() == 11, "se guarda con ★ y la usa el partido (Puente3D)")
	var copia := c.tactica.duplicar()
	_comprobar(copia.propias.has(n), "viaja con la táctica (duplicar)")
	FormacionPropia.borrar(c.tactica, n)
	_comprobar(not Datos.tabla("FORMS").has(n) and c.tactica.propias.is_empty(), "borrar la quita de la pizarra")
	FormacionPropia.registrar_todas(copia.tactica if copia.has_method("tactica") else copia)
	_comprobar(Datos.tabla("FORMS").has(n), "al cargar la partida se vuelven a registrar")
	FormacionPropia.borrar(copia, n)
	var ed := EditorFormacion.crear(c)
	add_child(ed)
	_comprobar(ed.forma.has("s") and (ed.forma["s"] as Array).size() == 11, "el editor abre con la formación actual")
	ed.queue_free()
