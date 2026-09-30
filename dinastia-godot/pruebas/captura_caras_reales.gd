extends Node3D
## REVISIÓN DE LAS CARAS REALES EN 3D (30-9-2026): por jugador, su foto, su
## personaje de frente y de tres cuartos, en primer plano, con la luz del
## estadio (sol alto de lado + cielo). Para las pasadas de mejora.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_caras_reales.tscn
## CARAS="Nombre A,Nombre B,..." cambia los jugadores (4).
const POR_DEFECTO := ["Achraf Hakimi", "Aaron Ramsey", "Abdallah Sima", "Adam Hlozek"]
var _n := 0

func _ready() -> void:
	Datos.base_real = true
	Cara.usar_fotos = true
	var nombres: Array = POR_DEFECTO
	if OS.get_environment("CARAS") != "":
		nombres = OS.get_environment("CARAS").split(",")
	var mundo := World3D.new()
	## La luz del partido de verdad: el cielo, el sol y la exposición de
	## `Calidad` (MOMENTO=dia|tarde|noche; por defecto, de día).
	## MOMENTO=estudio: luz suave de retrato (para juzgar el parecido).
	var momento := Calidad.DIA
	var estudio := OS.get_environment("MOMENTO") == "estudio"
	match OS.get_environment("MOMENTO"):
		"tarde": momento = Calidad.TARDE
		"noche": momento = Calidad.NOCHE
	mundo.environment = Calidad.entorno(Calidad.MEDIO, momento).environment
	if estudio:
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0.16, 0.2, 0.24)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.7, 0.72, 0.76)
		e.ambient_light_energy = 0.7
		e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		mundo.environment = e
	## El mundo con los jugadores vive en un viewport propio (no se ve); las
	## cámaras de los cuadros lo miran con `world_3d`.
	var vp0 := SubViewport.new()
	vp0.world_3d = mundo
	vp0.size = Vector2i(8, 8)
	add_child(vp0)
	var raiz := Node3D.new()
	vp0.add_child(raiz)
	if estudio:
		var luz := DirectionalLight3D.new()
		luz.rotation_degrees = Vector3(-25, 20, 0)
		luz.light_energy = 1.0
		raiz.add_child(luz)
	else:
		raiz.add_child(Calidad.sol(Calidad.MEDIO, momento))
	var capa := CanvasLayer.new()
	add_child(capa)
	var ancho := 1600.0 / nombres.size()
	for i in nombres.size():
		var j := Jugador.new()
		j.id = "revision_%d" % i
		j.nombre = String(nombres[i]).strip_edges()
		j.real = true
		var lk := Cara.look_de(j)
		var foto := TextureRect.new()
		foto.texture = Cara.foto_real(j)
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		foto.size = Vector2(ancho - 10, 250)
		foto.position = Vector2(ancho * i + 5, 5)
		capa.add_child(foto)
		var piel := Color(String(lk["piel"]))
		var pelo := Color(String(lk["peloC"]))
		var d := FutbolistaQ.crear(1.8, "male")
		raiz.add_child(d["nodo"])
		FutbolistaQ.terminar(d, true)
		VestidorQ.vestir_equipacion(d, Color("1d4fa3"), Color.WHITE, "liso", piel, pelo)
		PeloQ.poner(d, String(lk["pelo"]), pelo, int(lk["barba"]) in [1, 4, 6])
		VestidorQ.poner_cara(d, {"look": lk, "foto": Cara.ruta_foto(j)}, piel)
		var x := float(i) * 3.0
		(d["nodo"] as Node3D).position = Vector3(x, 0, 0)
		var ap: AnimationPlayer = d["anim"]
		if ap.has_animation("parado"):
			ap.play("parado")
		for k in 2:
			var cont := SubViewportContainer.new()
			cont.stretch = false
			cont.size = Vector2(ancho - 10, 315)
			cont.position = Vector2(ancho * i + 5, 262 + k * 320)
			capa.add_child(cont)
			var vp := SubViewport.new()
			vp.world_3d = mundo
			vp.msaa_3d = Viewport.MSAA_4X
			vp.size = Vector2i(int(ancho) - 10, 315)
			cont.add_child(vp)
			var cam := Camera3D.new()
			cam.fov = 30
			var ang := 0.0 if k == 0 else 0.6
			cam.position = Vector3(x + sin(ang) * 0.62, 1.68, cos(ang) * 0.62)
			vp.add_child(cam)
			cam.look_at(Vector3(x, 1.65, 0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 14:
		var salida := OS.get_environment("SALIDA")
		if salida == "":
			salida = "caras_reales_revision"
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % salida)
		get_tree().quit()
