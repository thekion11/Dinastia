extends Node3D
## LA BIBLIOTECA MODULAR (5-10-2026): 12 personajes ficticios armados con caras
## mezcladas y cortes de la biblioteca (`BibliotecaCaras`), luz de retrato.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_biblioteca.tscn
const PIELES := ["#f3d2b8", "#e0b08a", "#c68d68", "#a86b45", "#8a5536", "#4a2c1c"]
const PELOS := ["#1a1411", "#3d2a19", "#7a5230", "#d8b878", "#0e0b09", "#2a1c12"]
var _n := 0

func _ready() -> void:
	var mundo := World3D.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.2, 0.24)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.72, 0.76)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	mundo.environment = e
	var vp0 := SubViewport.new()
	vp0.world_3d = mundo
	vp0.size = Vector2i(8, 8)
	add_child(vp0)
	var raiz := Node3D.new()
	vp0.add_child(raiz)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-25, 20, 0)
	raiz.add_child(luz)
	var capa := CanvasLayer.new()
	add_child(capa)
	var tam := get_viewport().get_visible_rect().size
	var ancho := tam.x / 6.0
	var alto := tam.y / 2.0
	for i in 12:
		var piel := Color(PIELES[i % 6])
		var pc := Color(PELOS[(i * 5) % 6])
		var b := BibliotecaCaras.para("ficticio_%d" % (i * 37 + 11), piel, pc)
		var d := FutbolistaQ.crear(1.8, "male")
		raiz.add_child(d["nodo"])
		FutbolistaQ.terminar(d, true)
		VestidorQ.vestir_equipacion(d, Color("b3261e"), Color.WHITE, "liso", piel, pc)
		PeloQ.poner(d, "corto", pc, false)
		VestidorQ.poner_cara(d, {"look": {"ojos": 0}, "foto": "", "biblio": b}, piel)
		var px := float(i) * 3.0
		(d["nodo"] as Node3D).position = Vector3(px, 0, 0)
		var ap: AnimationPlayer = d["anim"]
		if ap.has_animation("parado"):
			ap.play("parado")
		var cont := SubViewportContainer.new()
		cont.position = Vector2(ancho * (i % 6) + 2, alto * (i / 6) + 2)
		cont.size = Vector2(ancho - 4, alto - 4)
		capa.add_child(cont)
		var vp := SubViewport.new()
		vp.world_3d = mundo
		vp.size = Vector2i(int(ancho) - 4, int(alto) - 4)
		vp.msaa_3d = Viewport.MSAA_4X
		cont.add_child(vp)
		var cam := Camera3D.new()
		cam.fov = 32
		cam.position = Vector3(px + 0.2, 1.7, 0.85)
		vp.add_child(cam)
		cam.look_at(Vector3(px, 1.66, 0), Vector3.UP)
		var et := Label.new()
		et.text = "%s · %s" % [b.get("cara", "?"), BibliotecaCaras.nombre_pelo(String(b.get("pelo", "")))]
		et.add_theme_font_size_override("font_size", 13)
		et.add_theme_constant_override("outline_size", 4)
		et.add_theme_color_override("font_outline_color", Color.BLACK)
		et.position = Vector2(ancho * (i % 6) + 6, alto * (i / 6) + alto - 26)
		capa.add_child(et)

func _process(_d: float) -> void:
	_n += 1
	if _n == 14:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/biblioteca_caras.png")
		get_tree().quit()
