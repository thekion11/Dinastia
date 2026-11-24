extends Node3D
## HOJA DE COMPARACIÓN CON LOS JUGADORES EN 3D (17-11): por club, escudo y uniforme 2D arriba y, debajo, sus 3 jugadores más destacados en el MODELO 3D del partido
## (mismo uniforme, pelo, barba y tono). Sin fotos.
##   PAISES="ITA,GER,BRA" CLUBES_POR_PAIS=1 GRUPO=0 SALIDA=hoja3d_a herramientas/captura.sh res://pruebas/captura_hoja_3d.tscn
##   GRUPO = qué trozo de la lista (de 3 clubes) se dibuja; la lista son los 2 de mayor reputación de cada país de PAISES.
var _n := 0

func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var paises: Array[String] = []
	paises.assign((OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "ITA,GER,BRA").split(",", false))
	var grupo := int(OS.get_environment("GRUPO")) if OS.get_environment("GRUPO") != "" else 0
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
	cam.position = Vector3(0, 1.05, 7.6)
	cam.fov = 38
	add_child(cam)
	var capa := CanvasLayer.new()
	add_child(capa)
	var todos: Array[Club] = []
	for p: String in paises:
		var hecho := false
		for l in m.ligas:
			if hecho or l.clubes.is_empty() or l.clubes[0].pais != p:
				continue
			hecho = true
			var lista: Array = l.clubes.duplicate()
			lista.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
			todos.append(lista[0])
			todos.append(lista[1])
	var elegidos := todos.slice(grupo * 3, grupo * 3 + 3)
	var sp := PlayerSpawner.new()
	for i in elegidos.size():
		var c: Club = elegidos[i]
		var kit := Puente3D.kit(c)
		sp._kit_x = kit["x"]
		var pl: Array = c.plantilla.duplicate()
		pl.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		var centro_x := -3.3 + i * 3.3
		for k in 3:
			var j: Jugador = pl[k]
			var datos := Puente3D.jugador(j)
			var look: Array = PlayerSpawner._look_de(datos)
			var nodo := sp._crear_jugador(self, j.id, "DEL", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 7 + k * 2, look, Color(0, 0, 0, 0), datos)
			var pos := Vector3(centro_x + (k - 1) * 0.95, 0, 0)
			(nodo["nodo"] as Node3D).position = pos
			(nodo["nodo"] as Node3D).rotation_degrees.y = (k - 1) * -14.0
			var px := cam.unproject_position(pos + Vector3(0, 2.0, 0))
			var nl := Label.new()
			nl.text = "%s (%d)" % [j.nombre, j.ovr]
			nl.position = Vector2(px.x - 70, 950)
			nl.add_theme_font_size_override("font_size", 15)
			capa.add_child(nl)
		var px0 := cam.unproject_position(Vector3(centro_x, 2.2, 0))
		var kit2d := TextureRect.new()
		kit2d.texture = Jersey.textura(c, 0, 256)
		kit2d.scale = Vector2.ONE * (130.0 / maxf(1.0, kit2d.texture.get_height()))
		kit2d.position = Vector2(px0.x - 130, 10)
		capa.add_child(kit2d)
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(c, 128)
		esc.scale = Vector2.ONE * (110.0 / maxf(1.0, esc.texture.get_height()))
		esc.position = Vector2(px0.x + 10, 10)
		capa.add_child(esc)
		var et := Label.new()
		et.text = "%s · %s" % [c.nombre, c.pais]
		et.position = Vector2(px0.x - 130, 150)
		et.add_theme_font_size_override("font_size", 22)
		capa.add_child(et)

func _process(_d: float) -> void:
	_n += 1
	if _n == 16:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % (OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "hoja_3d"))
		print("FIN. 0 fallos")
		get_tree().quit()
