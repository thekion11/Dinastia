extends Node3D
## Mira la tunica "Peasant" recoloreada -ronda 2, con el cuero tambien
## retenido (no cafe)- en las dos variantes de color, para comparar.

var _n: Node3D
var _variantes := ["blanco", "azul"]
var _idx := 0
var _frame := 0

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.05, 0.06, 0.07)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.3, 0.3, 0.32)
	ent.ambient_light_energy = 0.6
	add_child(amb)
	amb.environment = ent
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.2
	add_child(luz)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 2.2)
	cam.fov = 40
	add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true

	var packed: PackedScene = load("res://assets/characters/quaternius/ropa_temp/Male_Peasant_Body.gltf")
	_n = packed.instantiate()
	add_child(_n)
	_aplicar_variante(_variantes[0])

func _aplicar_variante(nombre: String) -> void:
	var recol := Image.load_from_file("res://assets/characters/quaternius/ropa_temp/T_Peasant_recoloreada_%s.png" % nombre)
	if recol == null:
		return
	var tex := ImageTexture.create_from_image(recol)
	for hijo in _mallas(_n):
		var mi := hijo as MeshInstance3D
		for s in range(mi.mesh.get_surface_count()):
			var m := mi.get_active_material(s)
			if m is StandardMaterial3D:
				var sm: StandardMaterial3D = (m as StandardMaterial3D).duplicate()
				sm.albedo_texture = tex
				mi.set_surface_override_material(s, sm)

func _mallas(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_mallas(c))
	return out

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 3:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pieza_ropa_%s.png" % _variantes[_idx])
		_idx += 1
		if _idx >= _variantes.size():
			get_tree().quit(0)
			return
		_aplicar_variante(_variantes[_idx])
		_frame = 0
