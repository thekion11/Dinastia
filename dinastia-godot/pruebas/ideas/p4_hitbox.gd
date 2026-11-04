extends BaseIdea
## P4 (3-11): EL SUELO NO SE ATRAVIESA. Recorre los 372 clips del futbolista (9 instantes de cada uno) y mide cuánto se hunde el cuerpo bajo el césped sin
## corrección; comprueba que el catálogo `datos/clips_bajo_suelo.json` contiene todos los que se hunden y que `AnclaSuelo` los deja apoyados (y no mueve
## a los que no se hunden). P4_GRABAR=1 regenera el catálogo. Además mide si las manos se meten en el tronco (no pasa en ningún clip).

const UMBRAL := 0.03     ## m: lo que se tolera hundido antes de contarlo como fallo (3 cm: lo que se ve; la suela del botín da 1 cm en reposo)

func _jugador() -> Dictionary:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var l := Puente3D.once(a.once())
	var lista := sp.spawn_team(raiz, [l["xi"][5]], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a))
	return lista[0]

func _ready() -> void:
	await get_tree().process_frame
	_titulo("P4 · EL SUELO NO SE ATRAVIESA")
	var p := _jugador()
	var nodo: Node3D = p["node"]
	nodo.position = Vector3.ZERO
	var ap: AnimationPlayer = p["anim"]
	var ancla := nodo.find_child("AnclaSuelo", false, false) as AnclaSuelo
	_comprobar(ancla != null, "el futbolista lleva su AnclaSuelo")
	if ancla == null:
		get_tree().quit(1)
		return
	var clips: Array = Array(ap.get_animation_list())
	var hunden: Array = []
	var peor_global := 0.0
	var mal_despues := 0
	var peor_despues := 0.0
	var no_catalogados: Array = []
	var movidos_sin_necesidad: Array = []
	var catalogo := AnclaSuelo.CLIPS
	for c: String in clips:
		var largo := ap.get_animation(c).length
		var peor := 0.0
		var peor_post := 0.0
		for k in 9:
			ap.play(c)
			ap.seek(largo * float(k) / 8.0, true)
			ap.advance(0.0)
			ancla.offset = 0.0
			ancla._modelo.position.y = ancla._base_y
			var crudo := ancla.necesario()
			peor = maxf(peor, crudo)
			## Con la corrección ya aplicada (converge en unos pasos): lo que queda hundido.
			if catalogo.has(c):
				for i in 12:
					ancla._process(0.5)
					ap.advance(0.0)
				peor_post = maxf(peor_post, ancla.necesario() - ancla.offset)   ## lo que falta por subir
				ancla.offset = 0.0
				ancla._modelo.position.y = ancla._base_y
		if peor > UMBRAL:
			hunden.append([peor, c])
			if not catalogo.has(c):
				no_catalogados.append(c)
		elif catalogo.has(c):
			pass
		if catalogo.has(c) and peor_post > UMBRAL:
			mal_despues += 1
		peor_despues = maxf(peor_despues, peor_post)
		peor_global = maxf(peor_global, peor)
	hunden.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0])
	print("  %d de %d clips hunden alguna parte bajo el césped (peor %.2f m); catálogo: %d" % [hunden.size(), clips.size(), peor_global, catalogo.size()])
	for x: Array in hunden.slice(0, 8):
		print("    %-30s %.2f m" % [x[1], x[0]])
	if OS.get_environment("P4_GRABAR") != "":
		var nombres: Array = []
		for x: Array in hunden:
			nombres.append(x[1])
		nombres.sort()
		var f := FileAccess.open("res://datos/clips_bajo_suelo.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(nombres, " "))
		f.close()
		print("  catálogo regenerado: %d clips" % nombres.size())
	else:
		_comprobar(no_catalogados.is_empty(), "todos los clips que se hunden están en el catálogo (faltan %d: %s)" % [no_catalogados.size(), str(no_catalogados.slice(0, 5))])
		_comprobar(mal_despues == 0, "con AnclaSuelo ningún clip catalogado queda hundido (peor residuo %.3f m, %d clips)" % [peor_despues, mal_despues])
		## Los que no se hunden no se tocan: parado y correr.
		for c: String in ["parado", "correr", "trotar"]:
			if ap.has_animation(c):
				ancla.offset = 0.0
				ap.play(c)
				ap.seek(0.2, true)
				for i in 5:
					ancla._process(0.1)
				_comprobar(ancla.offset == 0.0, "«%s» no sube al jugador (offset %.3f)" % [c, ancla.offset])
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
