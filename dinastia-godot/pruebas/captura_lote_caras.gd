extends Node3D
## AUDITORÍA POR LOTES DE LAS CARAS REALES (30-9-2026, pedido: «implementarlo a
## todos los jugadores y revisar que quede bien, por lote vas haciendo
## auditorías»). Cada hoja: 12 jugadores (en orden alfabético), cada uno con su
## foto pequeña, su nombre y su cara 3D con luz de retrato.
##   LOTE=0 xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_lote_caras.tscn
## Salida: pruebas/capturas/lotes/lote_NNN.png (no se sube al repositorio).
const POR_HOJA := 12
const COLUMNAS := 6
var _n := 0
var _salida := ""

func _ready() -> void:
	Datos.base_real = true
	Cara.usar_fotos = true
	CaraMalla._cargar()
	var nombres: Array = CaraMalla._mallas.keys()
	nombres.sort()
	var lote := int(OS.get_environment("LOTE"))
	var desde := lote * POR_HOJA
	var elegidos := nombres.slice(desde, mini(desde + POR_HOJA, nombres.size()))
	_salida = "res://pruebas/capturas/lotes/lote_%03d.png" % lote
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas/lotes"))
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
	var ancho := tam.x / COLUMNAS
	var alto := tam.y / 2.0
	for i in elegidos.size():
		var nombre := String(elegidos[i])
		var j := Jugador.new()
		j.id = "lote_%d" % i
		j.nombre = nombre
		j.real = true
		var lk := Cara.look_de(j)
		var col := i % COLUMNAS
		var fila := i / COLUMNAS
		var x0 := ancho * col
		var y0 := alto * fila
		var cont := SubViewportContainer.new()
		cont.position = Vector2(x0 + 2, y0 + 2)
		cont.size = Vector2(ancho - 4, alto - 4)
		capa.add_child(cont)
		var vp := SubViewport.new()
		vp.world_3d = mundo
		vp.size = Vector2i(int(ancho) - 4, int(alto) - 4)
		vp.msaa_3d = Viewport.MSAA_4X
		cont.add_child(vp)
		var foto := TextureRect.new()
		foto.texture = Cara.foto_real(j)
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.size = Vector2(ancho * 0.36, ancho * 0.36)
		foto.position = Vector2(x0 + 4, y0 + 4)
		capa.add_child(foto)
		var et := Label.new()
		et.text = nombre + ("  [RECREACIÓN]" if not CaraMalla.tiene(nombre) else "")
		et.add_theme_font_size_override("font_size", 13)
		et.add_theme_color_override("font_outline_color", Color.BLACK)
		et.add_theme_constant_override("outline_size", 4)
		et.position = Vector2(x0 + 6, y0 + alto - 26)
		capa.add_child(et)
		var piel := Color(String(lk["piel"]))
		var pelo := Color(String(lk["peloC"]))
		var d := FutbolistaQ.crear(1.8, "male")
		raiz.add_child(d["nodo"])
		FutbolistaQ.terminar(d, true)
		VestidorQ.vestir_equipacion(d, Color("1d4fa3"), Color.WHITE, "liso", piel, pelo)
		PeloQ.poner(d, String(lk["pelo"]), pelo, int(lk["barba"]) in [1, 4, 6])
		VestidorQ.poner_cara(d, {"look": lk, "foto": Cara.ruta_foto(j)}, piel)
		var px := float(i) * 3.0
		(d["nodo"] as Node3D).position = Vector3(px, 0, 0)
		var ap: AnimationPlayer = d["anim"]
		if ap.has_animation("parado"):
			ap.play("parado")
		var cam := Camera3D.new()
		cam.fov = 30
		cam.position = Vector3(px + 0.22, 1.67, 0.85)
		vp.add_child(cam)
		cam.look_at(Vector3(px, 1.64, 0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 14:
		get_viewport().get_texture().get_image().save_png(_salida)
		get_tree().quit()
