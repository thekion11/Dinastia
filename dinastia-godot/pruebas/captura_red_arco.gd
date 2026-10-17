extends Node3D
## LA RED QUE SE ONDULA (17-10-2026, M-149): un arco suelto, de cerca, con la
## onda congelada en tres momentos (0 / 0,2 / 0,8 s) desde dentro del campo.
##   herramientas/captura.sh res://pruebas/captura_red_arco.tscn
## Salida: pruebas/capturas/red_arco_<edad>.png (JPG con captura.sh).
var _n := 0
var _red: RedArco
const EDADES := [-1.0, 0.2, 0.8]

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.72, 0.75)
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.2, 0.5, 0.25)
	suelo.material_override = ms
	suelo.position = Vector3(0, 0, 50)
	add_child(suelo)
	var poste := StandardMaterial3D.new()
	poste.albedo_color = Color(0.95, 0.95, 0.95)
	StadiumBuilder._add_goal(self, 52.5, poste, Color(0.95, 0.95, 0.95))
	for r in find_children("RedArco*", "", true, false):
		_red = r as RedArco
	var cam := Camera3D.new()
	cam.fov = 50
	add_child(cam)
	cam.global_position = Vector3(6.5, 1.9, 46.5)
	cam.look_at(Vector3(0.5, 1.1, 53.6), Vector3.UP)
	cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	if _n < 4 or _n % 3 != 0:
		return
	var i := _n / 3 - 2
	if i >= EDADES.size():
		get_tree().quit()
		return
	var edad: float = EDADES[i]
	if edad >= 0.0 and _red != null:
		RedArco.golpe(self, Vector3(1.4, 1.3, 53.3))
		_red.set_process(false)
		for m in _red.panos:
			(m.material_override as ShaderMaterial).set_shader_parameter("edad", edad)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/red_arco_%s.png" % ("quieta" if edad < 0.0 else str(edad).replace(".", "_")))
