extends Node3D
## Sonda temporal: variantes de «brazos en jarra» (giro del brazo, abducción, codo).
const SAL := "/tmp/claude-0/-home-user-Dinastia/d7998c33-2989-56a5-a16b-60a65d203ee0/scratchpad/capturas/"
var VAR: Array = []

func _ready() -> void:
	VAR = JSON.parse_string(OS.get_environment("VARJ"))
	var luz := DirectionalLight3D.new(); luz.rotation_degrees = Vector3(-40, 25, 0); add_child(luz)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.55, 0.6, 0.65)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.7, 0.7, 0.72)
	env.environment = e; add_child(env)
	var ds: Array = []
	for i in VAR.size():
		var r := Node3D.new(); add_child(r); r.position.x = i * 0.9
		var d := PersonajeDT.crear(r, {"ropa": "traje", "c_ropa": "333333"}) if OS.get_environment("FUT") == "" else _fut(r)
		ds.append(d)
	for i in 3: await get_tree().process_frame
	for i in VAR.size():
		var v: Array = VAR[i]; var d: Dictionary = ds[i]
		var esq: Skeleton3D = d["esqueleto"]; var ap: AnimationPlayer = d["anim"]
		var pre := str(ap.get_path_to(esq))
		var a := AnimQuaternius._nueva(2.0, true)
		for lado: String in ["i", "d"]:
			var s := 1.0 if lado == "i" else -1.0
			AnimExtra._p(a, esq, "brazo_" + lado, [[0.0, Vector3(v[0], -v[1] * s, v[2] * s)], [2.0, Vector3(v[0], -v[1] * s, v[2] * s)]], pre)
			AnimExtra._p(a, esq, "antebrazo_" + lado, [[0.0, Vector3(v[3], v[4] * s, 0)], [2.0, Vector3(v[3], v[4] * s, 0)]], pre)
			if v.size() > 5: AnimExtra._p(a, esq, "mano_" + lado, [[0.0, Vector3(v[5], v[6] * s, v[7] * s)], [2.0, Vector3(v[5], v[6] * s, v[7] * s)]], pre)
		AnimExtra._completar(a, esq, pre)
		PersonajeVida.piernas_de_persona(a, esq)
		var lib := AnimationLibrary.new(); lib.add_animation("j", a); ap.add_animation_library("sonda", lib)
		ap.play("sonda/j"); ap.seek(0.5, true); ap.pause()
	var cam := Camera3D.new(); add_child(cam); cam.current = true; cam.fov = 40
	var cx := (VAR.size() - 1) * 0.45
	cam.look_at_from_position(Vector3(cx, 1.15, 4.2), Vector3(cx, 1.0, 0))
	await _foto(OS.get_environment("PREF") + "_frente.jpg")
	for d in ds: (d["nodo"] as Node3D).rotation_degrees.y = 70
	await _foto(OS.get_environment("PREF") + "_lado.jpg")
	get_tree().quit()

func _fut(r: Node3D) -> Dictionary:
	var d := FutbolistaQ.crear(1.8, "male"); r.add_child(d["nodo"]); FutbolistaQ.terminar(d, true); return d

func _foto(n: String) -> void:
	for i in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_jpg(SAL + n, 0.9)
	print("foto ", n)
