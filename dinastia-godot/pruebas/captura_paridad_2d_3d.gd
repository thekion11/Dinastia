extends Node3D
## PARIDAD 2D/3D (17-11): 6 clubes de 3 países (ITA, GER, BRA, 2 de cada uno); por club, arriba su uniforme local 2D y su escudo (las hojas de comparación) y debajo
## el jugador más conocido (con rasgos propios si tiene) en el MODELO 3D del partido con el mismo uniforme: franjas, mitades, banda, pantalón, medias, dorsal.
##   herramientas/captura.sh res://pruebas/captura_paridad_2d_3d.tscn   → pruebas/capturas/paridad_2d_3d.png (JPG si no se pide --png)
var _n := 0

func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var tonos := OS.get_environment("TONOS") != ""   ## TONOS=1: en vez de 6 clubes, 6 jugadores de piel muy distinta (comprueba que el modelo 3D respeta el tono)
	var paises: Array[String] = []
	paises.assign(["ENG", "ESP", "ITA", "BRA"] if tonos else ["ITA", "GER", "BRA"])
	var m := Mundo.new()
	m.generar(paises, 1117)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.14, 0.19, 0.16)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.9)
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-30, 20, 0)
	add_child(sol)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.25, 6.4)
	cam.fov = 38
	add_child(cam)
	var capa := CanvasLayer.new()
	add_child(capa)
	var elegidos: Array[Club] = []
	var por_tono: Array[Jugador] = []
	if tonos:
		var vistos := {}
		for c: Club in m.clubes.values():
			for cand: Jugador in c.plantilla:
				var r: Variant = Cara.rasgos_conocido(cand)
				if r is Dictionary and not vistos.has(String(r["piel"])) and vistos.size() < 6:
					vistos[String(r["piel"])] = true
					por_tono.append(cand)
					elegidos.append(m.clubes[cand.club_id])
	for p: String in ([] if tonos else paises):
		var hecho := false
		for l in m.ligas:
			if hecho or l.clubes.is_empty() or l.clubes[0].pais != p:
				continue
			hecho = true
			var lista: Array = l.clubes.duplicate()
			lista.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
			elegidos.append(lista[0])
			elegidos.append(lista[1])
	var sp := PlayerSpawner.new()
	for i in elegidos.size():
		var c: Club = elegidos[i]
		var kit := Puente3D.kit(c)
		sp._kit_x = kit["x"]
		var pl: Array = c.plantilla.duplicate()
		pl.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		var j: Jugador = pl[0]
		for cand: Jugador in pl:
			if Cara.rasgos_conocido(cand) is Dictionary:
				j = cand
				break
		if tonos:
			j = por_tono[i]
		var datos := Puente3D.jugador(j)
		var look: Array = PlayerSpawner._look_de(datos)
		var nodo := sp._crear_jugador(self, j.id, "DEL", "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 10, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
		var pos := Vector3(-3.25 + i * 1.3, 0, 0)
		(nodo["nodo"] as Node3D).position = pos
		(nodo["nodo"] as Node3D).rotation_degrees.y = 0
		var px := cam.unproject_position(pos + Vector3(0, 1.0, 0))
		var kit2d := TextureRect.new()
		kit2d.texture = Jersey.textura(c, 0, 256)
		kit2d.scale = Vector2.ONE * (200.0 / maxf(1.0, kit2d.texture.get_height()))
		kit2d.position = Vector2(px.x - 110, 24)
		capa.add_child(kit2d)
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(c, 128)
		esc.scale = Vector2.ONE * (70.0 / maxf(1.0, esc.texture.get_height()))
		esc.position = Vector2(px.x - 35, 232)
		capa.add_child(esc)
		var et := Label.new()
		et.text = "%s (%s)\n%s\npiel %s" % [c.nombre, c.pais, j.nombre, String(Cara.look_de(j)["piel"])]
		et.position = Vector2(px.x - 100, 985)
		et.add_theme_font_size_override("font_size", 18)
		capa.add_child(et)

func _process(_d: float) -> void:
	_n += 1
	if _n == 14:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/paridad_2d_3d.png")
		print("FIN. 0 fallos")
		get_tree().quit()
