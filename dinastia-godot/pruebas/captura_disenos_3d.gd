extends Node3D
## LOS DISEÑOS NUEVOS EN 3D (26-9-2026): doce jugadores con diseños, cinco
## colores, pantalón, medias, botines, accesorios y dorsal. Frente y espalda.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_disenos_3d.tscn
const DISENOS := ["puntos_degradados", "curvas_nivel", "marmol", "fragmentos", "mangas_canesu", "diagonal_partida",
	"relampago", "cuadricula", "estrellas", "franjas_degradadas", "faja_rayas", "resplandor"]
const PALETAS := [
	["0b4ea2", "ffffff", "d0202a", "f2c230", "111111"], ["111111", "f2c230", "d0202a", "ffffff", "0b7a3b"],
	["6a1b9a", "f2c230", "ffffff", "111111", "0b4ea2"], ["ffffff", "d0202a", "0b4ea2", "111111", "f2c230"],
	["3b5323", "6b8e23", "2f2f2f", "c2b280", "111111"], ["e53935", "fb8c00", "fdd835", "43a047", "1e88e5"],
	["0b7a3b", "d0202a", "f2c230", "ffffff", "111111"], ["1f3a93", "ffffff", "d0202a", "f2c230", "111111"],
	["00897b", "ffffff", "004d40", "111111", "f2c230"], ["d0202a", "ffffff", "111111", "f2c230", "0b4ea2"],
	["111111", "c9a227", "ffffff", "d0202a", "0b4ea2"], ["e53935", "ffffff", "1e88e5", "fdd835", "43a047"],
]
var _n := 0

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.13, 0.32, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.62, 0.66)
	e.ambient_light_energy = 0.9
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 20, 0)
	sol.light_energy = 1.2
	add_child(sol)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 6.4)
	cam.fov = 62
	add_child(cam)
	for i in DISENOS.size():
		var d := FutbolistaQ.crear(1.80, "male")
		var raiz: Node3D = d["nodo"]
		raiz.position = Vector3(-6.05 + i * 1.1, 0, 0)
		add_child(raiz)
		FutbolistaQ.terminar(d, true)
		var pal: Array = PALETAS[i]
		var kit := {"dis": DISENOS[i], "cols": pal, "trim": 1, "num": pal[3],
			"pant": {"dis": ["lateral", "ribete", "bicolor", "degrade", "doble_lateral", "liso"][i % 6], "c1": pal[0], "c2": pal[1]},
			"med": {"dis": ["aros", "franja", "dos_franjas", "bicolor", "rombos", "lisas"][i % 6], "c1": pal[1], "c2": pal[0]},
			"bot": {"mod": String(DisenosKit.BOTINES[(i * 5) % 30][0])},
			"acc": {}}
		var acc_k: Array = ["cintillo", "manguitos", "guantes", "munequeras", "brazalete", "cuello", "tobilleras"]
		kit["acc"][acc_k[i % 7]] = pal[2]
		VestidorQ.vestir_equipacion(d, Color(pal[0]), Color(pal[1]), "liso", Color("c68d68"), Color(0.15, 0.1, 0.07),
			Color(0, 0, 0, 0), Color(0, 0, 0, 0), false, kit, 3 + i * 7)
		var ap: AnimationPlayer = d["anim"]
		if ap.has_animation("parado"):
			ap.play("parado")
		var r := Label3D.new()
		r.text = DisenosKit.diseno(DISENOS[i])[1]
		r.font_size = 26
		r.pixel_size = 0.004
		r.position = Vector3(raiz.position.x, 2.0, 0)
		add_child(r)

func _process(_d: float) -> void:
	_n += 1
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/disenos_3d_frente.png")
		for h in get_children():
			if h is Node3D and not (h is Camera3D) and not (h is Label3D) and not (h is DirectionalLight3D) and not (h is WorldEnvironment):
				(h as Node3D).rotation.y = PI
	elif _n == 45:
		get_viewport().get_texture().get_image().save_png("res://pruebas/disenos_3d_espalda.png")
		for h in get_children():
			if h is Node3D and not (h is Camera3D) and not (h is Label3D) and not (h is DirectionalLight3D) and not (h is WorldEnvironment):
				(h as Node3D).rotation.y = 0.0
			if h is Camera3D:
				(h as Camera3D).position = Vector3(-1.1, 1.25, 1.9)
				(h as Camera3D).fov = 45
	elif _n == 60:
		get_viewport().get_texture().get_image().save_png("res://pruebas/disenos_3d_cerca.png")
		get_tree().quit()
