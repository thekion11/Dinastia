extends Node3D
## Un hincha de la malla VAT por clip (0-12), en fila, para ver cuáles se deforman. NIVEL=cerca|medio|lejos (por defecto cerca), T=segundos.
##   → /tmp/vat_<NIVEL>.png
var _n := 0

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	var nivel := OS.get_environment("NIVEL") if OS.get_environment("NIVEL") != "" else "cerca"
	var mallas := StadiumBuilder._hinchas_horneados(nivel)
	var malla: Mesh = mallas[0]
	var col := Color(0.9, 0.9, 0.95)
	for c in 13:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://visor/hinchada.gdshader")
		mat.set_shader_parameter("cuello_desde", float(malla.get_meta("cuello_desde", 0.70)))
		mat.set_shader_parameter("cuello_hasta", float(malla.get_meta("cuello_hasta", 0.73)))
		mat.set_shader_parameter("pelo_desde", float(malla.get_meta("pelo_desde", 0.86)))
		mat.set_shader_parameter("lado_max", 0.14)
		mat.set_shader_parameter("amplitud", 0.0)
		PublicoVat.configurar(mat, malla, "quieto")
		mat.set_shader_parameter("vat_reposo", c)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = malla
		mm.instance_count = 1
		mm.set_instance_transform(0, Transform3D(Basis(), Vector3(float(c % 7) * 1.1, 0, float(c / 7) * -1.4)))
		mm.set_instance_color(0, col)
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = mat
		add_child(mi)
	Mini3D.caja(self, Vector3(3.3, -0.05, -0.7), Vector3(12, 0.1, 6), Mini3D.mat(Color(0.4, 0.4, 0.42)))
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 20, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.4, 0.5)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 40.0
	cam.position = Vector3(3.3, 1.6, 4.0)
	cam.look_at(Vector3(3.3, 0.5, -0.7), Vector3.UP)
	cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	var nivel := OS.get_environment("NIVEL") if OS.get_environment("NIVEL") != "" else "cerca"
	if _n in [30, 90, 150]:
		get_viewport().get_texture().get_image().save_png("/tmp/vat_%s_%d.png" % [nivel, _n])
	if _n > 150:
		get_tree().quit()
