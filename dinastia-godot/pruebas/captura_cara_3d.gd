extends Node3D
## LA CARA 2D MOLDEADA SOBRE EL MODELO 3D (29-9-2026): cinco jugadores de
## cerca -cuatro con los rasgos de su retrato y uno con retrato real calzado-,
## y debajo el retrato 2D de cada uno para comparar.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_cara_3d.tscn
const IDS := ["cara_a", "cara_b7", "cara_c12", "cara_d3"]
const FOTO := "res://recursos/caras_reales_256/Aaron_Long.jpg"
var _n := 0

func _ready() -> void:
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
	var n := IDS.size() + 1
	var capa := CanvasLayer.new()
	add_child(capa)
	for i in n:
		var lk: Dictionary
		var ruta := ""
		if i < IDS.size():
			lk = Cara._look_base(IDS[i])
			if i == 1:
				lk["barba"] = 3
			if i == 2:
				lk["pecas"] = true
				lk["barba"] = 0
		else:
			lk = Cara._look_base("real")
			ruta = FOTO
		var piel := Color(String(lk["piel"]))
		var pelo := Color(String(lk["peloC"]))
		var d := FutbolistaQ.crear(1.8, "male")
		add_child(d["nodo"])
		FutbolistaQ.terminar(d, true)
		VestidorQ.vestir_equipacion(d, Color("c8102e"), Color.WHITE, "liso", piel, pelo)
		PeloQ.poner(d, String(lk["pelo"]), pelo, int(lk["barba"]) in [1, 4, 6])
		print("cara ", i, " -> ", VestidorQ.poner_cara(d, {"look": lk, "foto": ruta}, piel))
		(d["nodo"] as Node3D).position = Vector3((i - (n - 1) * 0.5) * 0.36, 0, 0)
		var ap: AnimationPlayer = d["anim"]
		if ap.has_animation("parado"):
			ap.play("parado")
		## El retrato 2D (rasgos) de referencia.
		var tr := TextureRect.new()
		tr.texture = Cara.foto_de_ruta(ruta) if ruta != "" else Cara.textura_rasgos(lk)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.size = Vector2(150, 150)
		tr.position = Vector2(1600.0 * (i + 0.5) / n - 75.0, 730)
		capa.add_child(tr)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.66, 1.25)
	cam.fov = 42
	add_child(cam)
	cam.look_at(Vector3(0, 1.64, 0), Vector3.UP)
	cam.current = true

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/cara_3d.png")
		get_tree().quit()
