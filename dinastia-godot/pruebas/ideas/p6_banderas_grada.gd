extends BaseIdea
## Banderas grandes sobre la grada en el gol (`BanderasGrada`, conectadas a `FestejoGrada.lanzar`).

func _probar() -> void:
	_titulo("P6: BANDERAS GRANDES EN EL GOL")
	var raiz := Node3D.new()
	add_child(raiz)
	var sitios := [Vector3(60, 8, 0), Vector3(-60, 8, 0), Vector3(0, 8, 40)]
	var ligero := Calidad.motor_ligero
	Calidad.motor_ligero = true
	_comprobar(BanderasGrada.lanzar(raiz, Color.RED, Color.WHITE, sitios) == null, "con el motor ligero no hay banderas")
	Calidad.motor_ligero = false
	_comprobar(BanderasGrada.lanzar(raiz, Color.RED, Color.WHITE, []) == null, "sin sitios en la grada tampoco")
	var b := BanderasGrada.lanzar(raiz, Color.RED, Color.WHITE, sitios, 2.0, 3)
	_comprobar(b != null and b.get_child_count() == 3, "tres banderas sobre la grada")
	var mi: MeshInstance3D = b.get_child(0)
	var m := mi.material_override as ShaderMaterial
	_comprobar(m != null and (m.get_shader_parameter("color1") as Color).is_equal_approx(Color.RED), "la primera lleva el color del club")
	b._process(0.4)
	_comprobar(float(m.get_shader_parameter("subida")) > 0.4 and float(m.get_shader_parameter("subida")) < 0.6, "suben en 0,8 s")
	b._process(3.0)
	_comprobar(b.is_queued_for_deletion(), "y se borran solas al acabar el festejo")
	Calidad.motor_ligero = ligero
	_comprobar(FileAccess.file_exists("res://visor/festejo_grada.gd") and (load("res://visor/festejo_grada.gd") as GDScript).source_code.contains("BanderasGrada.lanzar"), "el festejo del gol las llama")
