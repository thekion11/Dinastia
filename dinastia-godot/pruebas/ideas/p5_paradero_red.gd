extends BaseIdea
## Paradero como los de Santiago (27-10-2026): marquesina gris con franja «Red», pósters de recorridos, banca de láminas y poste con el código «PA…».

func _probar() -> void:
	_titulo("PARADERO RED · COMO LOS DE SANTIAGO")
	var raiz := Node3D.new()
	add_child(raiz)
	ParaderoRed.montar(raiz, 7.5, 1234)
	var textos: Array[String] = []
	for l: Node in raiz.find_children("*", "Label3D", true, false):
		textos.append((l as Label3D).text)
	_comprobar(textos.has("Red") and textos.has("PARADERO"), "lleva el rótulo «Red» y el cartel «PARADERO»")
	var cod := ParaderoRed.codigo(1234)
	_comprobar(textos.has(cod) and cod.begins_with("PA") and cod.length() >= 5, "el cartel lleva su código (%s)" % cod)
	var rs := ParaderoRed.recorridos(1234)
	_comprobar(rs.size() >= 3 and rs.size() <= 5, "y %d recorridos" % rs.size())
	for r: String in rs:
		_comprobar(textos.has(r), "recorrido %s en el cartel" % r)
	_comprobar(ParaderoRed.codigo(1234) == ParaderoRed.codigo(1234) and ParaderoRed.codigo(1) != ParaderoRed.codigo(2), "el código es estable y distinto por paradero")
	## La banca queda a la altura de los asientos registrados (tablero a 0,69 sobre el suelo local).
	var alto_banca := 0.0
	for m: Node in raiz.find_children("*", "MeshInstance3D", true, false):
		if absf(m.position.z + 0.9) < 0.2 and absf(m.position.y - 0.67) < 0.01:
			alto_banca = m.position.y + 0.02
	_comprobar(absf(alto_banca - 0.69) < 0.001, "la banca tiene el tablero a 0,69 (%.2f) como los asientos de `GenteSentada`" % alto_banca)
	var qr := ParaderoRed.qr()
	_comprobar(qr.get_width() == 25, "el QR es de 25 × 25")
