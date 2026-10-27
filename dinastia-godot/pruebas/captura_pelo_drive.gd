extends Node3D
## Los peinados del Drive sobre cabezas Quaternius. IDS="73,74,..." GIRA=1 (modelo del pack girado 180°) SEXO=male|female. → /tmp/pelo_drive_<SEXO>_<GIRA>_<vista>.png
var _n := 0
var _cabezas: Array[Vector3] = []

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(40, 0.2, 40), Mini3D.mat(Color(0.5, 0.5, 0.48)))
	var ids := OS.get_environment("IDS").split(",") if OS.get_environment("IDS") != "" else PackedStringArray()
	var sexo := OS.get_environment("SEXO") if OS.get_environment("SEXO") != "" else "male"
	var gira := OS.get_environment("GIRA") == "1"
	var colores := [Color(0.1, 0.07, 0.05), Color(0.3, 0.18, 0.1), Color(0.55, 0.38, 0.2), Color(0.15, 0.12, 0.1)]
	for k in ids.size():
		var d := FutbolistaQ.crear(1.78 if sexo == "male" else 1.66, sexo)
		add_child(d["nodo"])
		FutbolistaQ.terminar(d, false)
		var n := d["nodo"] as Node3D
		n.position = Vector3(float(k % 6) * 0.9, 0, -float(k / 6) * 1.2)
		var esq: Skeleton3D = d["esqueleto"]
		var anc := BoneAttachment3D.new()
		anc.bone_name = "Head"
		esq.add_child(anc)
		PeloDrive.poner(esq, anc, int(ids[k]), colores[k % 4], sexo == "female", gira)
		_cabezas.append(n.position + Vector3(0, 1.62, 0))
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 25, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.name = "Cam"
	add_child(cam)
	cam.fov = float(OS.get_environment("FOV")) if OS.get_environment("FOV") != "" else 30.0
	cam.make_current()
	_vista(0)

func _vista(i: int) -> void:
	var cam: Camera3D = get_node("Cam")
	var filas := maxi(1, (_cabezas.size() + 5) / 6)
	var cx := 2.25
	var cz := -float(filas - 1) * 0.6
	if i == 0:    ## de frente
		cam.position = Vector3(cx, 1.7, cz + 6.0 + float(filas))
		cam.look_at(Vector3(cx, 1.62, cz), Vector3.UP)
	else:         ## de perfil
		cam.position = Vector3(cx + 7.0 + float(filas), 1.7, cz)
		cam.look_at(Vector3(cx, 1.6, cz), Vector3.UP)

func _process(_d: float) -> void:
	var sexo := OS.get_environment("SEXO") if OS.get_environment("SEXO") != "" else "male"
	var g := "1" if OS.get_environment("GIRA") == "1" else "0"
	_n += 1
	if _n == 25:
		get_viewport().get_texture().get_image().save_png("/tmp/pelo_drive_%s_%s_0.png" % [sexo, g])
		_vista(1)
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("/tmp/pelo_drive_%s_%s_1.png" % [sexo, g])
		get_tree().quit()
