extends Node3D
## LA RECREACIÓN DE LOS JUGADORES REALES (29-9-2026): para cinco reales con
## foto, arriba la foto, en medio el retrato 2D recreado (piel, pelo y barba de
## la foto) y abajo su cara 3D recreada, sin foto.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_recreacion.tscn
const NOMBRES := ["Aaron Wan-Bissaka", "Achraf Hakimi", "Aaron Ramsey", "Abdallah Sima", "Adam Hlozek"]
var _n := 0

func _ready() -> void:
	Datos.base_real = true
	Cara.usar_fotos = OS.get_environment("MODO") == "foto"
	var amb := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.12, 0.18, 0.15)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.5)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	amb.environment = e
	add_child(amb)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-30, -20, 0)
	add_child(sol)
	var capa := CanvasLayer.new()
	add_child(capa)
	var n := NOMBRES.size()
	for i in n:
		var j := Jugador.new()
		j.id = "real_%d" % i
		j.nombre = NOMBRES[i]
		j.real = true
		var lk := Cara.look_de(j)
		var cx := 1600.0 * (i + 0.5) / n
		var foto := TextureRect.new()
		var usar := Cara.usar_fotos
		Cara.usar_fotos = true
		foto.texture = Cara.foto_real(j)
		Cara.usar_fotos = usar
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.size = Vector2(145, 145)
		foto.position = Vector2(cx - 150, 10)
		capa.add_child(foto)
		var ret := TextureRect.new()
		ret.texture = Cara.textura(j, "#1d4fa3", "#ffffff", 170)
		ret.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ret.size = Vector2(145, 145)
		ret.position = Vector2(cx + 3, 10)
		capa.add_child(ret)
		var piel := Color(String(lk["piel"]))
		var pelo := Color(String(lk["peloC"]))
		var d := FutbolistaQ.crear(1.8, "male")
		add_child(d["nodo"])
		FutbolistaQ.terminar(d, true)
		VestidorQ.vestir_equipacion(d, Color("1d4fa3"), Color.WHITE, "liso", piel, pelo)
		PeloQ.poner(d, String(lk["pelo"]), pelo, int(lk["barba"]) in [1, 4, 6])
		VestidorQ.poner_cara(d, {"look": lk, "foto": Cara.ruta_foto(j)}, piel)
		(d["nodo"] as Node3D).position = Vector3((i - (n - 1) * 0.5) * 0.36, 0, 0)
		var ap: AnimationPlayer = d["anim"]
		if ap.has_animation("parado"):
			ap.play("parado")
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.62, 1.25)
	cam.fov = 42
	add_child(cam)
	cam.look_at(Vector3(0, 1.66, 0), Vector3.UP)
	cam.current = true

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		Cara.usar_fotos = true
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % ("fotos_reales_3d" if OS.get_environment("MODO") == "foto" else "recreacion_reales"))
		get_tree().quit()
