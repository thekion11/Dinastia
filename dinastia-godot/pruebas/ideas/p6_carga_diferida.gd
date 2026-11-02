extends BaseIdea
## Carga diferida del prólogo: al terminar, la ciudad tiene las mismas piezas que construida de seguida (misma suma de instancias de MultiMesh y mismas mallas por clase).

func _huella(diferir: bool, prologo := true) -> Dictionary:
	CityBuilder.modo_prologo = prologo
	CityBuilder.diferir = diferir
	var m := Mundo.new()
	m.generar(["CHI"], 4713)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var club := m.mi_club()
	var vista := VistaCiudad.new()
	vista.por_partes = true
	add_child(vista)
	var t0 := Time.get_ticks_msec()
	await vista.abrir(club, m.obras, m.ciudad, m.perfil_estadio_de(club))
	var ms_visible := Time.get_ticks_msec() - t0
	var cb := vista.get("_ciudad") as CityBuilder
	var espera := 0
	while not cb.completa and espera < 4000:
		await get_tree().process_frame
		espera += 1
	for i in 40:   ## los trabajos «para el siguiente fotograma» (zapatillas de los peatones…) terminan igual en los dos modos
		await get_tree().process_frame
	var d := {"ms_visible": ms_visible, "completa": cb.completa, "circulos": cb.circulos.size(), "frames": espera}
	var instancias := 0
	var mallas := 0
	var multis := 0
	for n in cb.find_children("*", "MultiMeshInstance3D", true, false):
		multis += 1
		instancias += (n as MultiMeshInstance3D).multimesh.instance_count
	for n in cb.find_children("*", "MeshInstance3D", true, false):
		mallas += 1
	var nombres := {}
	for n in cb.find_children("*", "", true, false):
		var k := "%s:%s" % [n.get_class(), String(n.name).rstrip("0123456789@")]
		nombres[k] = int(nombres.get(k, 0)) + 1
	d["nombres"] = nombres
	d["multimesh"] = multis
	d["instancias"] = instancias
	d["mallas"] = mallas
	d["trafico"] = cb.get_node_or_null("Trafico") != null
	d["vehiculos"] = (cb.get_node("Trafico") as TraficoCiudad)._vehiculos.size() if cb.get_node_or_null("Trafico") != null else 0
	d["edificios"] = int(cb.expansion.cuenta.get("edificios", 0)) if cb.expansion != null else 0
	vista.queue_free()
	CityBuilder.modo_prologo = false
	CityBuilder.diferir = false
	await get_tree().process_frame
	return d

## Iguales con un 1 % de margen.
func _casi(x: Variant, y: Variant) -> bool:
	return absf(float(x) - float(y)) <= maxf(float(x), float(y)) * 0.01

func _probar() -> void:
	_titulo("P6: CARGA DIFERIDA = MISMAS PIEZAS")
	var a: Dictionary = await _huella(false)
	var b: Dictionary = await _huella(true)
	var na: Dictionary = a["nombres"]
	var nb: Dictionary = b["nombres"]
	var dif: Array = []
	for k: String in na:
		if int(na[k]) != int(nb.get(k, 0)):
			dif.append("%s %d -> %d" % [k, int(na[k]), int(nb.get(k, 0))])
	for k: String in nb:
		if not na.has(k):
			dif.append("%s 0 -> %d" % [k, int(nb[k])])
	dif.sort()
	print("DIFERENCIAS POR NOMBRE: ", dif.slice(0, 25))
	a.erase("nombres")
	b.erase("nombres")
	print("DE SEGUIDA ", a)
	print("DIFERIDA   ", b)
	_comprobar(bool(a["completa"]) and bool(b["completa"]), "las dos terminan (la diferida en %d fotogramas)" % int(b["frames"]))
	## (Dos construcciones idénticas ya difieren en ±0,1 % —azar global de los peatones y de los edificios lejanos—: se compara con 1 % de margen, y exacto lo que es del código.)
	_comprobar(_casi(a["instancias"], b["instancias"]) and _casi(a["multimesh"], b["multimesh"]), "mismas instancias de MultiMesh (%d / %d) y MultiMesh (%d / %d)" % [int(a["instancias"]), int(b["instancias"]), int(a["multimesh"]), int(b["multimesh"])])
	_comprobar(_casi(a["mallas"], b["mallas"]), "mismas mallas sueltas (%d / %d)" % [int(a["mallas"]), int(b["mallas"])])
	_comprobar(a["vehiculos"] == b["vehiculos"] and bool(b["trafico"]), "mismo tráfico (%d vehículos)" % int(b["vehiculos"]))
	_comprobar(_casi(a["circulos"], b["circulos"]), "mismos obstáculos de colisión (%d / %d)" % [int(a["circulos"]), int(b["circulos"])])
	_comprobar(a["edificios"] == b["edificios"], "mismos edificios contados (%d / %d)" % [int(a["edificios"]), int(b["edificios"])])

	## La ciudad ENTERA (la de «Ver ciudad»): lo mismo, y se mide cuánto tarda en verse.
	var c: Dictionary = await _huella(false, false)
	var e: Dictionary = await _huella(true, false)
	print("CIUDAD ENTERA: de seguida %d ms hasta verla; diferida %d ms" % [int(c["ms_visible"]), int(e["ms_visible"])])
	_comprobar(bool(c["completa"]) and bool(e["completa"]), "la ciudad entera termina en los dos modos")
	_comprobar(int(e["ms_visible"]) < int(c["ms_visible"]) * 0.7, "y se ve en %d ms en vez de %d ms" % [int(e["ms_visible"]), int(c["ms_visible"])])
	_comprobar(_casi(c["instancias"], e["instancias"]) and _casi(c["mallas"], e["mallas"]) and _casi(c["multimesh"], e["multimesh"]), "con las mismas piezas (instancias %d / %d, mallas %d / %d)" % [int(c["instancias"]), int(e["instancias"]), int(c["mallas"]), int(e["mallas"])])
	_comprobar(c["vehiculos"] == e["vehiculos"] and c["edificios"] == e["edificios"], "mismo tráfico (%d) y mismos edificios (%d)" % [int(e["vehiculos"]), int(e["edificios"])])
