extends Node
## Coches con pintura real y placas (y el autobús con su número). NO corre con --headless:
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/captura_coches.tscn   → /tmp/captura_coches_N.png
## ANTES=1 los deja como eran (sin `CocheDetalle`), para la comparación antes/después.

var _n := 0
var _cam: Camera3D
const VISTAS := [[Vector3(-9, 3.5, 12), Vector3(0, 0.8, 0)], [Vector3(9, 3, -12), Vector3(0, 0.8, 0)], [Vector3(-6, 2.2, 20), Vector3(4, 1.0, 12)]]

func _ready() -> void:
	var suelo := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(200, 200)
	suelo.mesh = pl
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.3, 0.3, 0.31)
	suelo.material_override = ms
	add_child(suelo)
	var nombres := ["sedan", "taxi", "suv", "van", "hatchback-sports", "police", "sedan-sports", "suv-luxury"]
	for k in nombres.size():
		var e := load("res://assets/ciudad/kenney_cars/%s.glb" % nombres[k]) as PackedScene
		var c := CityBuilder.instanciar_coche({"esc": e})
		c.position = Vector3(-10.0 + float(k % 4) * 6.5, 0.0, float(k / 4) * 6.0)
		c.rotation.y = 0.3 if k % 2 == 0 else -0.3
		add_child(c)
		if OS.get_environment("ANTES") == "1":
			for mi in c.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = null
				if (mi as MeshInstance3D).mesh is QuadMesh or (mi as MeshInstance3D).mesh is BoxMesh:
					(mi as MeshInstance3D).visible = false
	var bus := CityBuilder.autobus(Color(0.85, 0.15, 0.12), "10 · CENTRO", "10")
	bus.position = Vector3(4, 0, 12)
	bus.rotation.y = -0.5
	add_child(bus)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 35, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.6, 0.72, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.7)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_cam = Camera3D.new()
	_cam.far = 400.0
	add_child(_cam)
	_cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	var i := _n / 6
	var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
	if _n % 6 == 0 and i >= 1 and i <= VISTAS.size():
		get_viewport().get_texture().get_image().save_png("%s/captura_coches_%d.png" % [carpeta, i - 1])
	if _n % 6 == 1:
		var k := clampi(_n / 6, 0, VISTAS.size() - 1)
		_cam.position = VISTAS[k][0]
		_cam.look_at(VISTAS[k][1], Vector3.UP)
	if _n > 6 * (VISTAS.size() + 2):
		get_tree().quit()
