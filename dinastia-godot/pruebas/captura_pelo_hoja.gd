extends Node3D
## Hoja comparativa de UN peinado del Drive: a la izquierda el corte de Quaternius al que sustituye, a la derecha el del Drive, a 1,5 m, de frente,
## 3/4 y de perfil. ID=73 SEXO=male|female. → /tmp/hoja_<ID>_<0|1|2>.png
var _n := 0
var _cuerpos: Array[Node3D] = []

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(40, 0.2, 40), Mini3D.mat(Color(0.5, 0.5, 0.48)))
	var id := int(OS.get_environment("ID"))
	var sexo := OS.get_environment("SEXO") if OS.get_environment("SEXO") != "" else "male"
	var color := Color(0.30, 0.18, 0.10)
	if OS.get_environment("COLOR") != "":
		color = Color(OS.get_environment("COLOR"))
	for k in 2:
		var d := FutbolistaQ.crear(1.78 if sexo == "male" else 1.66, sexo)
		add_child(d["nodo"])
		FutbolistaQ.terminar(d, false)
		var n := d["nodo"] as Node3D
		n.position = Vector3(-0.3 if k == 0 else 0.3, 0, 0)
		_cuerpos.append(n)
		if k == 0:
			PeloQ.poner(d, "tupe" if sexo == "male" else "largo", color, false)
		else:
			PeloQ.poner(d, "tupe" if sexo == "male" else "largo", color, false, id)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, 25, 0)
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
	add_child(cam)
	cam.fov = 22.0
	cam.make_current()
	var alto := 1.62 if sexo == "male" else 1.52
	cam.position = Vector3(0, alto + 0.12, 1.5)
	cam.look_at(Vector3(0, alto + 0.05, 0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	var id := OS.get_environment("ID")
	for v in 3:
		if _n == 12 + v * 8:
			get_viewport().get_texture().get_image().save_png("/tmp/hoja_%s_%d.png" % [id, v])
			for c in _cuerpos:
				c.rotation.y += deg_to_rad(45.0)
	if _n > 40:
		get_tree().quit()
