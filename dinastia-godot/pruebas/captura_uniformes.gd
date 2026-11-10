extends Node
## UNIFORMES (10-11): una hoja con el primer y el segundo uniforme (camiseta, pantalón y medias) de 2 clubes de cada país pedido (regla 34: varios clubes y países).
##   PAISES=ESP,ENG,BRA,JPN,MEX,CHI godot --headless --path . res://pruebas/captura_uniformes.tscn   → `pruebas/capturas/uniformes.png`
func _ready() -> void:
	var paises := (OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "ESP,ENG,BRA,JPN,MEX,CHI").split(",")
	var m := Mundo.new()
	var g: Array[String] = []
	g.assign(paises)
	m.generar(g, 61)
	var celdas: Array[Image] = []
	var nombres: Array[String] = []
	for p: String in paises:
		var liga: Liga = null
		for l: Liga in m.ligas:
			if l.pais == p:
				liga = l
		if liga == null:
			continue
		for idx in [1, 7]:
			var c: Club = liga.clubes[idx % liga.clubes.size()]
			for visita in [false, true]:
				var kit := DisenosKit.kit_de_club_visita(c) if visita else DisenosKit.kit_de_club(c)
				if kit.is_empty():
					kit = DisenosKit.kit_de_club(c)
				celdas.append(DisenosKit.textura_completa(kit, false, 160).get_image())
				nombres.append("%s %s" % [c.nombre, "(2.º)" if visita else "(1.º)"])
	if celdas.is_empty():
		print("SIN CELDAS")
		get_tree().quit()
		return
	var w := celdas[0].get_width()
	var h := celdas[0].get_height()
	var cols := 4
	var filas := int(ceil(float(celdas.size()) / float(cols)))
	var hoja := Image.create(w * cols, h * filas, false, Image.FORMAT_RGBA8)
	hoja.fill(Color(0.13, 0.14, 0.15))
	for i in celdas.size():
		var im := celdas[i]
		if im.get_format() != Image.FORMAT_RGBA8:
			im.convert(Image.FORMAT_RGBA8)
		hoja.blend_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	hoja.save_png("res://pruebas/capturas/uniformes.png")
	print("HOJA OK ", celdas.size(), " ", ", ".join(nombres))
	get_tree().quit()
