extends Node
## ESCUDOS (10-11): una hoja con el escudo de varios clubes de varios países para revisar su parecido con el real (regla 34: varios clubes y países).
##   REAL=1 usa la base real (solo en local: con nombres reales se compara a ojo) · CLUBES="Real Madrid,Barcelona,…" · PAISES=ESP,ENG,… (sin REAL, 2 clubes por país)
##   godot --headless --path . res://pruebas/captura_escudos.tscn   → `pruebas/capturas/escudos.png`
func _figuras() -> void:   ## FIGURAS=1: todas las figuras del vocabulario sobre un círculo, para revisarlas sueltas
	var celdas: Array[Image] = []
	for k: String in EscudoEmblemas.FIGURAS:
		var svg := '<svg width="120" height="120" viewBox="-4 -4 48 48" xmlns="http://www.w3.org/2000/svg"><circle cx="20" cy="20" r="23" fill="#1d3f6e"/>%s</svg>' % String(EscudoEmblemas.FIGURAS[k]).replace("{F}", "#ffffff").replace("{D}", "#f2c200")
		var im := Image.new()
		im.load_svg_from_string(svg)
		im.convert(Image.FORMAT_RGBA8)
		celdas.append(im)
	var cols := 8
	var hoja := Image.create(120 * cols, 120 * int(ceil(float(celdas.size()) / float(cols))), false, Image.FORMAT_RGBA8)
	hoja.fill(Color(0.93, 0.93, 0.93))
	for i in celdas.size():
		hoja.blend_rect(celdas[i], Rect2i(0, 0, 120, 120), Vector2i((i % cols) * 120, (i / cols) * 120))
	hoja.save_png("res://pruebas/capturas/figuras.png")
	print("FIGURAS OK ", celdas.size())
	get_tree().quit()

func _ready() -> void:
	if OS.get_environment("FIGURAS") == "1":
		_figuras()
		return
	var real := OS.get_environment("REAL") == "1"
	if real:
		Datos.usar_base_real(true)
	var paises := (OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "ESP,ENG,ITA,GER,FRA,ARG").split(",")
	var m := Mundo.new()
	var g: Array[String] = []
	g.assign(paises)
	m.generar(g, 61)
	var pedidos := OS.get_environment("CLUBES").split(",") if OS.get_environment("CLUBES") != "" else PackedStringArray()
	var elegidos: Array[Club] = []
	if not pedidos.is_empty():
		for n: String in pedidos:
			for c: Club in m.clubes.values():
				if Nombres.limpiar(c.nombre) == n:
					elegidos.append(c)
					break
	else:
		for p: String in paises:
			for l: Liga in m.ligas:
				if l.pais == p:
					elegidos.append(l.clubes[0])
					elegidos.append(l.clubes[mini(5, l.clubes.size() - 1)])
	var celdas: Array[Image] = []
	var nombres: Array[String] = []
	for c: Club in elegidos:
		var im := Escudo.textura(c, 200).get_image()
		im.convert(Image.FORMAT_RGBA8)
		celdas.append(im)
		nombres.append(c.nombre)
	if celdas.is_empty():
		print("SIN CELDAS")
		get_tree().quit()
		return
	var w := celdas[0].get_width()
	var h := celdas[0].get_height()
	var cols := 4
	var filas := int(ceil(float(celdas.size()) / float(cols)))
	var hoja := Image.create(w * cols, h * filas, false, Image.FORMAT_RGBA8)
	hoja.fill(Color(0.93, 0.93, 0.93))
	for i in celdas.size():
		hoja.blend_rect(celdas[i], Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	hoja.save_png("res://pruebas/capturas/escudos.png")
	print("HOJA OK ", ", ".join(nombres))
	get_tree().quit()
