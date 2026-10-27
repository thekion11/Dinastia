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
	_comprobar(rs.size() >= 4 and rs.size() <= 6, "%d recorridos en la cuadrícula (%s)" % [rs.size(), ", ".join(rs)])
	var todos := true
	for r: String in rs:
		todos = todos and textos.has(r)
	_comprobar(todos, "todos salen en el cartel")
	## Un sector da números de su centena (o alimentadores «C##») con sufijo «c» o, rarísimo, «e».
	var mal := 0
	var con_c := 0
	var con_e := 0
	var alim := 0
	for s in 300:
		for r: String in ParaderoRed.recorridos(s, 100):
			var base := r.trim_suffix("c").trim_suffix("e")
			if r.begins_with("C"):
				alim += 1
			elif not (base in ParaderoRed.SECTORES[100]):
				mal += 1
			if r.ends_with("c"):
				con_c += 1
			if r.ends_with("e"):
				con_e += 1
	_comprobar(mal == 0, "el sector 100 solo da 1xx (o «C##»)")
	_comprobar(con_c > con_e * 3 and con_e > 0 and alim > 0, "hay «c» (%d), «e» muy rara (%d) y alimentadores (%d)" % [con_c, con_e, alim])
	_comprobar(ParaderoRed.codigo(1234) == ParaderoRed.codigo(1234) and ParaderoRed.codigo(1) != ParaderoRed.codigo(2) and ParaderoRed.codigo(7).begins_with("PA"), "el código «PA####» es estable por paradero")
	_comprobar(ParaderoRed.sector_de(-200, -200) == 100 and ParaderoRed.sector_de(200, 200) == 400 and ParaderoRed.sector_de(0, 0) == 500, "un sector por zona de la ciudad")
	_comprobar(ParaderoRed.registro.size() == 1 and String(ParaderoRed.registro[0]["codigo"]) == ParaderoRed.codigo(1234), "queda en el registro (para la app del móvil)")
	## La banca queda a la altura de los asientos registrados (tablero a 0,69 sobre el suelo local) y sus asientos caen sobre ella.
	var alto_banca := 0.0
	for m: Node in raiz.find_children("*", "MeshInstance3D", true, false):
		if absf(m.position.z + 0.9) < 0.2 and absf(m.position.y - 0.67) < 0.01:
			alto_banca = m.position.y + 0.02
	_comprobar(absf(alto_banca - 0.69) < 0.001, "la banca tiene el tablero a 0,69 (%.2f) como los asientos de `GenteSentada`" % alto_banca)
	_comprobar(ParaderoRed.asientos_x().size() == 2, "dos asientos en la banca")
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://datos/paraderos_red.json"))
	_comprobar(datos is Dictionary and (datos as Dictionary)["sectores"].size() == ParaderoRed.SECTORES.size(), "datos/paraderos_red.json describe los mismos sectores")
