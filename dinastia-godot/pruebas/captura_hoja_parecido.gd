extends Node
## HOJA DE COMPARACIÓN «PARECIDO REAL» (17-11): por club, su escudo, su uniforme (local y visita) y las caras de sus 3 jugadores más destacados
## (con los rasgos de `RASGOS_JUG`), de varios países a la vez. Sin fotos: solo lo que dibuja el juego.
##   CLUBES="ENG:3,ESP:7,ITA:4,..." (país:posición en la liga; por defecto 2 de cada uno de ENG, ESP, ITA, ARG, BRA, GER)
##   herramientas/captura.sh res://pruebas/captura_hoja_parecido.tscn   → pruebas/capturas/hoja_parecido.png (JPG si no se pide --png)
var _f := 0

func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED   ## coordenadas reales de 1920x1080
	var paises: Array[String] = ["ENG", "ESP", "ITA", "ARG", "BRA", "GER"]
	var m := Mundo.new()
	var generar: Array[String] = []
	generar.assign(paises if OS.get_environment("NOMBRES") == "" else ["ENG", "ESP", "ITA", "GER", "FRA", "ARG", "BRA", "CHI"])
	m.generar(generar, 1117)
	var fondo := ColorRect.new()
	fondo.color = Color("#24302a")
	fondo.size = Vector2(1920, 1080)
	add_child(fondo)
	var elegidos: Array[Club] = []
	var nombres := OS.get_environment("NOMBRES").split(",", false)   ## NOMBRES="Sevilla Nervión FC,Elba Rauten" (nombre público) en vez de los 2 por país
	for c: Club in m.clubes.values():
		if nombres.has(c.nombre):
			elegidos.append(c)
	for p: String in (paises if elegidos.is_empty() else []):
		var hecho := false
		for l in m.ligas:
			if hecho or l.clubes.is_empty() or l.clubes[0].pais != p:
				continue
			hecho = true   ## solo la primera división de cada país
			var lista: Array = l.clubes.duplicate()
			lista.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
			elegidos.append(lista[0])
			elegidos.append(lista[mini(5, lista.size() - 1)])
	for i in elegidos.size():
		var c: Club = elegidos[i]
		var col := i % 3
		var fila := i / 3
		var x := 14 + col * 636
		var y := 10 + fila * 268
		var tr := TextureRect.new()
		tr.texture = Escudo.textura(c, 128)
		tr.position = Vector2(x, y)
		tr.scale = Vector2.ONE * (96.0 / maxf(1.0, tr.texture.get_height()))
		add_child(tr)
		for k in 2:
			var cam := TextureRect.new()
			cam.texture = Jersey.textura(c, k, 128)
			cam.position = Vector2(x + 110 + k * 112, y)
			cam.scale = Vector2.ONE * (96.0 / maxf(1.0, cam.texture.get_height()))
			add_child(cam)
		var et := Label.new()
		et.text = "%s · %s" % [c.nombre, c.pais]
		et.position = Vector2(x, y + 98)
		et.add_theme_font_size_override("font_size", 18)
		add_child(et)
		var pl: Array = c.plantilla.duplicate()
		pl.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		for k in 3:
			var j: Jugador = pl[k]
			var cara := TextureRect.new()
			cara.texture = Cara.textura_2d(j, c.color_kit1(), c.color_kit2(), 128)
			cara.position = Vector2(x + k * 150, y + 128)
			cara.scale = Vector2.ONE * (110.0 / maxf(1.0, cara.texture.get_height()))
			add_child(cara)
			var nl := Label.new()
			nl.text = "%s (%d)" % [j.nombre, j.ovr]
			nl.position = Vector2(x + k * 150, y + 240)
			nl.add_theme_font_size_override("font_size", 14)
			add_child(nl)

func _process(_d: float) -> void:
	_f += 1
	if _f == 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % (OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "hoja_parecido"))
		print("FIN. 0 fallos")
		get_tree().quit()
