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
	_comprobar(ids.size() == 54, "54 recetas: 22 ligas, 22 copas, 8 continentales, el Mundial y la genérica (%d)" % ids.size())
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
	_comprobar(mal == 0, "todas se arman: tienen copa y una altura razonable (%d mal)" % mal)
	_comprobar(distintas.size() == 54, "ninguna receta repite a otra (%d distintas)" % distintas.size())
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
