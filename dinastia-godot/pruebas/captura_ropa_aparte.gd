extends Node3D
## LA ROPA APARTE: el mismo jugador con la equipación pintada (izquierda) y con
## camiseta, pantalón y medias como mallas propias (derecha), de frente, de
## lado y corriendo.
var _n := 0
var _ds: Array = []

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.13, 0.32, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.62, 0.66)
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 25, 0)
	sol.light_energy = 1.2
	sol.shadow_enabled = true
	add_child(sol)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.1, 4.2)
	cam.fov = 45
	add_child(cam)
	var kit := {"dis": "raglan_3", "cols": ["0b4ea2", "ffffff", "d0202a", "f2c230", "111111"], "trim": 1, "num": "ffffff",
		"pant": {"dis": "lateral", "c1": "ffffff", "c2": "0b4ea2"}, "med": {"dis": "franja", "c1": "0b4ea2", "c2": "ffffff"},
		"bot": {"mod": "clasico"}, "acc": {}, "cuello": 2,
		"sp": {"pecho": {"marca": "Banco Austral", "color": "#3a7bd5"}}}
	for i in 4:
		var d := FutbolistaQ.crear(1.80, "male")
		var raiz: Node3D = d["nodo"]
		raiz.position = Vector3(-1.8 + i * 1.2, 0, 0)
		raiz.rotation_degrees.y = [0.0, 0.0, 70.0, 70.0][i]
		add_child(raiz)
		FutbolistaQ.terminar(d, true)
		VestidorQ.ropa_aparte = i % 2 == 1
		VestidorQ.vestir_equipacion(d, Color("0b4ea2"), Color.WHITE, "liso", Color("c68d68"), Color(0.15, 0.1, 0.07),
			Color(0, 0, 0, 0), Color(0, 0, 0, 0), false, kit, 7)
		_ds.append(d)
		var r := Label3D.new()
		r.text = "pintada" if i % 2 == 0 else "ropa aparte"
		r.font_size = 30
		r.pixel_size = 0.004
		r.position = Vector3(raiz.position.x, 2.05, 0)
		add_child(r)
	VestidorQ.ropa_aparte = false

func _process(_d: float) -> void:
	_n += 1
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ropa_aparte_parado.png")
		for d: Dictionary in _ds:
			var ap: AnimationPlayer = d["anim"]
			if ap.has_animation("correr"):
				ap.play("correr")
				ap.seek(0.3, true)
				ap.pause()
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ropa_aparte_corriendo.png")
		get_tree().quit()
