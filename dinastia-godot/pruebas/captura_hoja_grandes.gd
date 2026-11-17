extends Node
## HOJA DE LOS 40 GRANDES (17-11): los 5 clubes de mayor reputación de cada una de las 8 ligas (ENG, ESP, ITA, GER, FRA, ARG, BRA, CHI), uno por fila y
## una liga por columna: escudo, uniforme local y nombre. Para señalar los escudos y uniformes flojos uno a uno. Sin fotos.
##   herramientas/captura.sh res://pruebas/captura_hoja_grandes.tscn   → pruebas/capturas/hoja_grandes.png (JPG si no se pide --png)
var _f := 0

func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var paises: Array[String] = ["ENG", "ESP", "ITA", "GER", "FRA", "ARG", "BRA", "CHI"]
	var m := Mundo.new()
	m.generar(paises, 1117)
	var fondo := ColorRect.new()
	fondo.color = Color("#24302a")
	fondo.size = Vector2(1920, 1080)
	add_child(fondo)
	for col in paises.size():
		var elegido := false
		for l in m.ligas:
			if elegido or l.clubes.is_empty() or l.clubes[0].pais != paises[col]:
				continue
			elegido = true   ## solo la primera división de cada país
			var lista: Array = l.clubes.duplicate()
			lista.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
			for fila in mini(5, lista.size()):
				var c: Club = lista[fila]
				var x := 8 + col * 238
				var y := 8 + fila * 208
				var esc := TextureRect.new()
				esc.texture = Escudo.textura(c, 160)
				esc.position = Vector2(x + 6, y)
				esc.scale = Vector2.ONE * (110.0 / maxf(1.0, esc.texture.get_height()))
				add_child(esc)
				var cam := TextureRect.new()
				cam.texture = Jersey.textura(c, 0, 160)
				cam.position = Vector2(x + 126, y)
				cam.scale = Vector2.ONE * (110.0 / maxf(1.0, cam.texture.get_height()))
				add_child(cam)
				var et := Label.new()
				et.text = c.nombre
				et.position = Vector2(x + 4, y + 118)
				et.custom_minimum_size = Vector2(228, 0)
				et.clip_text = true
				et.add_theme_font_size_override("font_size", 17)
				add_child(et)
				var pa := Label.new()
				pa.text = "%s · rep %d" % [paises[col], c.rep]
				pa.position = Vector2(x + 4, y + 144)
				pa.add_theme_font_size_override("font_size", 13)
				pa.modulate = Color(1, 1, 1, 0.6)
				add_child(pa)

func _process(_d: float) -> void:
	_f += 1
	if _f == 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/hoja_grandes.png")
		print("FIN. 0 fallos")
		get_tree().quit()
