extends BaseIdea
## Paradero de la Red como en las fotos del dueño (27-10-2026): techo blanco con costillas rojas, cabecera negra con el texto, panel con póster,
## banca de láminas, papelero y poste con el cartel negro (recorridos por sector, QR y franja roja).

func _probar() -> void:
	_titulo("PARADERO RED · COMO EN LAS FOTOS")
	ParaderoRed.registro.clear()
	var raiz := Node3D.new()
	add_child(raiz)
	ParaderoRed.montar(raiz, 3.8, 1234, "Av. Los Presidentes", 200)
	var textos: Array[String] = []
	for l: Node in raiz.find_children("*", "Label3D", true, false):
		textos.append((l as Label3D).text)
	_comprobar(textos.has("Paradero de Red Movilidad") and textos.any(func(t: String) -> bool: return t.begins_with("Parada ")), "la cabecera dice «Paradero de Red Movilidad | Parada N»")
	_comprobar(textos.has("Red"), "lleva el logo «Red»")
	_comprobar(textos.has("Av. Los Presidentes"), "el cartel lleva el nombre de la parada")
	var rs := ParaderoRed.recorridos(1234, 200)
	_comprobar(rs.size() >= 2 and rs.size() <= 5, "%d recorridos en la cuadrícula (%s)" % [rs.size(), ", ".join(rs)])
	var todos := true
	for r: String in rs:
		todos = todos and textos.has(r)
	_comprobar(todos, "todos salen en el cartel")
	## Los recorridos son los del mapa (`RecorridosMapa`): en cada paradero de un sector, troncales de 3 cifras o locales «C##»,
	## la vuelta con «c» y alguna alternativa «e»; casi todos del propio sector (los del club pasan por el centro, el sur…).
	var mal := 0
	var con_c := 0
	var con_e := 0
	var alim := 0
	var total := 0
	var propios := 0
	var rx := RegEx.create_from_string("^(\\d{3}|C\\d{2})[ce]?$")
	for cod: String in RecorridosMapa.datos()["orden"]:
		for r: String in RecorridosRed.recorridos(cod):
			total += 1
			if rx.search(r) == null:
				mal += 1
			if r.begins_with("C"):
				alim += 1
			elif int(r.substr(0, 1)) * 100 == RecorridosRed.sector_del_codigo(cod):
				propios += 1
			if r.ends_with("c"):
				con_c += 1
			if r.ends_with("e"):
				con_e += 1
	_comprobar(mal == 0 and propios * 2 > total, "%d recorridos en los paraderos con la forma de la Red; %d del propio sector" % [total, propios])
	_comprobar(con_c > con_e * 3 and con_e > 0 and alim > 0, "hay «c» (%d), «e» muy rara (%d) y locales (%d)" % [con_c, con_e, alim])
	_comprobar(ParaderoRed.codigo(1234) == ParaderoRed.codigo(1234) and ParaderoRed.codigo(1) != ParaderoRed.codigo(2) and ParaderoRed.codigo(7).begins_with("PA"), "el código «PA####» es estable por paradero")
	_comprobar(RecorridosRed.sector_del_codigo(ParaderoRed.codigo(1234, 300)) == 300 and RecorridosRed.existe(ParaderoRed.codigo(1234, 300)), "el código es de un paradero real del mapa y lleva su sector delante")
	_comprobar(ParaderoRed.registro.size() == 1 and String(ParaderoRed.registro[0]["codigo"]) == ParaderoRed.codigo(1234, 200), "queda en el registro (para la app del móvil)")
	## Con el código del mapa, el cartel lleva el nombre de su calle y sus recorridos.
	var raiz2 := Node3D.new()
	add_child(raiz2)
	var cod2 := RecorridosRed.paradero_en(Vector3(192, 0, -170))
	ParaderoRed.montar(raiz2, 3.8, 0, "", 0, cod2)
	var t2: Array[String] = []
	for l: Node in raiz2.find_children("*", "Label3D", true, false):
		t2.append((l as Label3D).text)
	var todos2 := t2.has(cod2) and t2.has("Av. Los Hinchas / Estadio")
	for r: String in RecorridosRed.recorridos(cod2):
		todos2 = todos2 and t2.has(r)
	_comprobar(todos2, "el paradero del estadio (%s): «Av. Los Hinchas / Estadio» con %s" % [cod2, ", ".join(RecorridosRed.recorridos(cod2))])
	## La banca queda a la altura de los asientos registrados (tablero a 0,69 sobre el suelo local) y sus asientos caen sobre ella.
	var alto_banca := 0.0
	for m: Node in raiz.find_children("*", "MeshInstance3D", true, false):
		if absf(m.position.z + 0.9) < 0.2 and absf(m.position.y - 0.67) < 0.01:
			alto_banca = m.position.y + 0.02
	_comprobar(absf(alto_banca - 0.69) < 0.001, "la banca tiene el tablero a 0,69 (%.2f) como los asientos de `GenteSentada`" % alto_banca)
	_comprobar(ParaderoRed.asientos_x().size() == 2, "dos asientos en la banca")
