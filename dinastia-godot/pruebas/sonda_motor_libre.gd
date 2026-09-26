extends Node
## Sonda del motor libre: estadísticas de varios partidos (no es parte del banco).
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var cl: Array = m.ligas[0].clubes.duplicate()
	cl.sort_custom(func(a: Club, b: Club) -> bool: return a.media() > b.media())
	var fuerte: Club = cl[0]
	var debil: Club = cl[cl.size() - 1]
	print("medias ", fuerte.media(), " vs ", debil.media())
	for s2 in 3:
		var mm := MotorLibre.new(fuerte.once(), fuerte.once(), 1.0, 1.0, 50 + s2)
		print("iguales: ", str(mm.simular()).left(160))
		var hist := {}
		var xgs := [0.0, 0.0]
		for e: Dictionary in mm.eventos:
			var b := int(float(e["dist"]) / 5.0) * 5
			hist[b] = int(hist.get(b, 0)) + 1
			xgs[e["eq"]] += float(e["xg"])
		print("   tiros por distancia ", hist, " xG ", xgs)
	var t0 := Time.get_ticks_msec()
	var tot := {}
	for s in 6:
		var ml := MotorLibre.new(fuerte.once(), debil.once(), 1.0, 1.0, s) if s < 3 else MotorLibre.new(debil.once(), fuerte.once(), 1.0, 1.0, s)
		var r := ml.simular()
		print(r)
	print("ms por partido: ", (Time.get_ticks_msec() - t0) / 6)
	get_tree().quit()
