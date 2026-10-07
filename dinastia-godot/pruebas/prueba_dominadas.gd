extends Node3D
## LAS DOMINADAS Y EL REGATE, COMPROBADOS (25-9-2026).
##   godot --path . --rendering-driver opengl3 --resolution 480x480 res://pruebas/prueba_dominadas.tscn
## (también corre con --headless: sin la hoja de fotos).
## 1. Los tres clips de dominadas encuentran toques, y en CADA toque la pelota
##    está sobre el pie (no a medio metro, no dentro).
## 2. La pelota nunca atraviesa el césped.
## 3. Existen las animaciones de regate y de conducción.
## Deja `pruebas/capturas/dominadas.png`: un jugador en 8 momentos del clip.
var _fallos := 0
var _ap: AnimationPlayer
var _cam: Camera3D
var _k := 0
var _espera := 0
var _imgs: Array[Image] = []

func _ok(c: bool, txt: String) -> void:
	print(("  ok    " if c else "  FALLO ") + txt)
	if not c:
		_fallos += 1

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.1, 0.16, 0.12)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.55, 0.55, 0.55)
	amb.environment = ent
	add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	add_child(luz)
	for clip: String in ["dominadas_1", "dominadas_2", "dominadas_3"]:
		var d := FutbolistaQ.crear(1.8, "male")
		add_child(d["nodo"])
		FutbolistaQ.terminar(d, true)
		VestidorQ.vestir_equipacion(d, Color("1d4fa3"), Color.WHITE, "liso", Color(0.8, 0.62, 0.5), Color(0.15, 0.1, 0.07))
		var ap: AnimationPlayer = d["anim"]
		var dom := Dominadas.montar(d["nodo"], ap, clip)
		_ok(dom != null and dom.cuantos_toques() >= 8, "%s: la pelota encuentra los toques del pie (%d)" % [clip, dom.cuantos_toques() if dom != null else 0])
		if dom == null:
			continue
		var esq: Skeleton3D = d["esqueleto"]
		var bola: MeshInstance3D = dom.get_child(0)
		var peor_toque := 0.0
		var mas_bajo := 9.0
		var largo := ap.get_animation(clip).length
		var t := 0.0
		while t < largo:
			ap.seek(t, true)
			dom._colocar(t)
			mas_bajo = minf(mas_bajo, bola.position.y)
			t += 1.0 / 30.0
		for tq: Array in dom._toques:
			ap.seek(float(tq[0]), true)
			dom._colocar(float(tq[0]))
			var pies := [esq.get_bone_global_pose(esq.find_bone("ball_l")).origin, esq.get_bone_global_pose(esq.find_bone("ball_r")).origin]
			var cerca := 9.0
			for pie: Vector3 in pies:
				cerca = minf(cerca, (bola.position - (d["nodo"] as Node3D).to_local(esq.to_global(pie))).length())
			peor_toque = maxf(peor_toque, cerca)
		_ok(peor_toque < 0.2, "%s: en cada toque la pelota está sobre el pie (peor %.2f m)" % [clip, peor_toque])
		_ok(mas_bajo >= Dominadas.RADIO - 0.01, "%s: la pelota nunca atraviesa el césped (mín %.2f m)" % [clip, mas_bajo])
		if clip == "dominadas_1":
			_ap = ap
			for n: String in ["regate_finta", "regate_pausa", "conducir"]:
				_ok(ap.has_animation(n), "existe la animación " + n)
		else:
			(d["nodo"] as Node3D).queue_free()
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.position = Vector3(2.2, 1.2, 2.6)
	_cam.fov = 45
	_cam.look_at(Vector3(0, 0.8, 0), Vector3.UP)
	_cam.current = true
	if DisplayServer.get_name() == "headless":
		_fin()

func _process(_d: float) -> void:
	if DisplayServer.get_name() == "headless" or _ap == null:
		return
	if _espera > 0:
		_espera -= 1
		if _espera == 0:
			var img := get_viewport().get_texture().get_image()
			img.resize(240, 240)
			_imgs.append(img)
			_k += 1
			if _k >= 8:
				var hoja := Image.create(240 * 8, 240, false, Image.FORMAT_RGBA8)
				for i in _imgs.size():
					hoja.blit_rect(_imgs[i], Rect2i(0, 0, 240, 240), Vector2i(i * 240, 0))
				hoja.save_png("res://pruebas/capturas/dominadas.png")
				_fin()
		return
	_ap.play("dominadas_1")
	_ap.seek(3.0 + _k * 0.37, true)
	_ap.pause()
	_espera = 3

func _fin() -> void:
	print("===== DOMINADAS: %d fallos =====" % _fallos)
	get_tree().quit()
