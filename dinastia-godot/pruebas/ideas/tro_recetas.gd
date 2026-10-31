extends BaseIdea
## LA COPA DE CADA COMPETICIÓN (orden 15 e, 27-10-2026): cada liga, copa y torneo continental tiene su receta de trofeo; el título del juego (con la
## base real y con la ficticia) encuentra la suya; las recetas se arman sobre el modelo base y el museo y el visor las usan.

func _ready() -> void:
	await get_tree().process_frame
	_probar_trofeos()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _probar_trofeos() -> void:
	_titulo("TROFEOS · UNA COPA POR COMPETICIÓN")
	var ids := TrofeosReales.ids()
	_comprobar(ids.size() == 56, "56 recetas: 23 ligas, 23 copas, 8 continentales, el Mundial y la genérica (%d)" % ids.size())
	_comprobar(TrofeoModelo.disponible(), "el modelo base de las copas está")
	var distintas := {}
	var mal := 0
	for id: String in ids:
		var r := TrofeosReales.receta(id)
		distintas[JSON.stringify(r)] = true
		var p := TrofeoModelo.partes(r)
		var tiene_copa := false
		for d: Dictionary in p["partes"]:
			tiene_copa = tiene_copa or bool(d["copa"])
		if (p["partes"] as Array).is_empty() or float(p["alto"]) < 0.3 or not tiene_copa:
			mal += 1
			print("  (receta mal armada: %s)" % id)
	var no_caben := 0
	for id2: String in ids:
		var pz := TrofeoModelo.partes(TrofeosReales.receta(id2))
		var esc := TrofeoModelo.escala_para(pz, SalasClub.ALTO_VITRINA, SalasClub.ANCHO_VITRINA)
		if float(pz["alto"]) * esc > SalasClub.ALTO_VITRINA + 0.001 or float(pz["ancho"]) * esc > SalasClub.ANCHO_VITRINA + 0.001:
			no_caben += 1
	_comprobar(no_caben == 0, "todas caben en su vitrina, también las bandejas anchas (%d se salen)" % no_caben)
	var base_grande := 0
	for id3: String in ids:
		var rr := TrofeosReales.receta(id3)
		var bb: Dictionary = rr.get("base", {})
		if bb.is_empty():
			continue
		var i3 := int(rr.get("copa", 1)) - 1
		var pie_r := float(TrofeoModelo.PIE[i3]) * float(rr.get("pie", 1.0)) * (0.7 if i3 == 1 else 1.0)
		var partes3: Array = TrofeoModelo.partes(rr)["partes"]
		for d3: Dictionary in partes3.slice(0, 2):   ## la base son las primeras piezas (una, o dos si es escalonada)
			var m3: Mesh = d3["mesh"]
			if (m3 is CylinderMesh and (m3 as CylinderMesh).bottom_radius > pie_r * 0.9) or (m3 is BoxMesh and (m3 as BoxMesh).size.x > pie_r * 0.75 * 2.0):
				if not bool(d3["copa"]):
					base_grande += 1
	_comprobar(base_grande == 0, "ninguna base pasa mucho del pie de su copa (%d demasiado anchas)" % base_grande)
	_comprobar(mal == 0, "todas se arman: tienen copa y una altura razonable (%d mal)" % mal)
	_comprobar(distintas.size() == 56, "ninguna receta repite a otra (%d distintas)" % distintas.size())
	for real: bool in [true, false]:
		Datos.usar_base_real(real)
		var etiqueta := "REAL" if real else "FICTICIA"
		var fallos := 0
		var ligas: Dictionary = Datos.tabla("PAISES_LIGAS")
		for p: String in ligas:
			if TrofeosReales.id_de(String(ligas[p]["liga"]), "") != "liga:" + p:
				fallos += 1
		var copas: Dictionary = Datos.tabla("COPA_NOM")
		for p: String in copas:
			if TrofeosReales.id_de(String(copas[p]), "") != "copa:" + p:
				fallos += 1
		var conf: Dictionary = Datos.tabla("CONFED")
		for k: String in conf:
			if TrofeosReales.id_de(String(conf[k]["n"]), "") != "conf:" + k:
				fallos += 1
		_comprobar(fallos == 0, "base %s: cada liga, copa y torneo encuentra su receta (%d sin encontrar)" % [etiqueta, fallos])
	Datos.usar_base_real(false)
	_comprobar(TrofeosReales.id_de("Liga", "ENG") == "liga:ENG", "«Liga» a secas sale por el país del club")
	_comprobar(TrofeosReales.id_de("Primera División", "CHI") == "liga:CHI" and TrofeosReales.receta("liga:CHI") != TrofeosReales.receta("generico"), "la liga de Chile tiene la suya")
	_comprobar(TrofeosReales.id_de("Mundial de Clubes", "") == "mundial", "el Mundial de Clubes tiene la suya")
	_comprobar(TrofeosReales.id_de("Reto: Algo", "ARG") == "generico", "un título sin competición usa la copa genérica")
	## El museo y el visor las usan.
	var raiz := Node3D.new()
	add_child(raiz)
	var hitos := [{"anio": 1999, "titulo": "Liga"}, {"anio": 2001, "titulo": "Mundial de Clubes"}]
	var lote := SalasClub.museo(raiz, Rect2(0.0, 0.0, 3.6, 6.0), 0.0, Color.RED, Color.WHITE, 2, 4, hitos, "ESP")
	_comprobar(lote != null, "el museo se monta con las copas de receta")
	var capa := CanvasLayer.new()
	add_child(capa)
	var v := VisorTrofeo.abrir(capa, {"titulo": "Liga", "anio": 1999, "receta": TrofeosReales.receta("liga:ENG")})
	_comprobar(v != null and v.find_children("*", "MeshInstance3D", true, false).size() >= 4, "el visor de la copa dibuja base, copa y adornos de la receta")
	v.queue_free()
	raiz.queue_free()
