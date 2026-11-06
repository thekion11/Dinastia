extends "res://pruebas/banco/estadio_p1.gd"
## [Capa extra de `estadio.gd`] _probar_fundir_r2

## R2 (3-11): `FundirPiezas.fundir_sueltas` y `fundir_profundo(..., por_firma)` (la grada y el túnel en MÍNIMO).
func _probar_fundir_r2() -> void:
	_titulo("FUNDIR PIEZAS: SUELTAS Y POR FIRMA (R2)")
	## R2 (3-11, MÍNIMO): las piezas SUELTAS sin nombre (cajas, cilindros, placas) en una superficie por material y sombra; lo que tiene nombre, meta o grupo se queda.
	var r2 := Node3D.new()
	add_child(r2)
	var verde := StandardMaterial3D.new()
	var gris := StandardMaterial3D.new()
	gris.albedo_color = Color(0.4, 0.4, 0.4)
	for i in 6:
		var s := MeshInstance3D.new()
		if i % 2 == 0:
			s.mesh = BoxMesh.new()
		else:
			var cil := CylinderMesh.new()
			cil.radial_segments = 8
			cil.rings = 1
			s.mesh = cil
		s.material_override = verde if i < 4 else gris
		s.position = Vector3(i, 0, 0)
		r2.add_child(s)
	var con_nombre := MeshInstance3D.new()
	con_nombre.name = "Bandera"
	con_nombre.mesh = BoxMesh.new()
	con_nombre.material_override = verde
	r2.add_child(con_nombre)
	var con_meta := MeshInstance3D.new()
	con_meta.mesh = BoxMesh.new()
	con_meta.material_override = verde
	con_meta.set_meta("cuerpo", true)
	r2.add_child(con_meta)
	_comprobar(FundirPiezas.fundir_sueltas(r2) == 6, "R2: funde las 6 piezas sueltas sin nombre")
	var fund: MeshInstance3D = r2.get_node("SueltasFundidas")
	_comprobar(fund.mesh.get_surface_count() == 2 and fund.mesh.surface_get_material(0) == verde and fund.mesh.surface_get_material(1) == gris, "R2: una superficie por material, los mismos materiales")
	_comprobar(is_instance_valid(con_nombre) and con_nombre.get_parent() == r2 and is_instance_valid(con_meta) and con_meta.get_parent() == r2, "R2: la pieza con nombre y la que lleva meta se quedan")
	r2.queue_free()
	## Materiales distintos pero iguales en lo que se ve comparten superficie (`por_firma`); si cambia el color, no.
	var r3 := Node3D.new()
	add_child(r3)
	var colores := [Color.RED, Color.RED, Color.BLUE]
	for i in 3:
		var mi := MeshInstance3D.new()
		mi.mesh = BoxMesh.new()
		var mt := StandardMaterial3D.new()
		mt.albedo_color = colores[i]
		mi.material_override = mt
		r3.add_child(mi)
	_comprobar(FundirPiezas._firma_material(StandardMaterial3D.new()) == FundirPiezas._firma_material(StandardMaterial3D.new()), "R2: dos materiales iguales tienen la misma firma")
	FundirPiezas.fundir_profundo(r3, "Fundido", [], true)
	_comprobar((r3.get_node("Fundido") as MeshInstance3D).mesh.get_surface_count() == 2, "R2: 3 materiales (2 iguales) → 2 superficies con `por_firma`")
	r3.queue_free()

## (7-11) El paseo a pie en ULTRA BAJA y BAJA: la niebla de profundidad y la animación que se pausa detrás de la cámara.
func _probar_paseo_optimizado() -> void:
	_titulo("PASEO A PIE OPTIMIZADO: NIEBLA Y ANIMACIÓN DETRÁS DE LA CÁMARA")
	## (7-11) Niebla de profundidad del paseo a pie: se pone (300 a 700 m) y al salir deja el entorno como estaba.
	var nn := Node3D.new()
	add_child(nn)
	var ent := Environment.new()
	ent.fog_enabled = false
	var mundo := nn.get_world_3d()
	var ent0: Environment = mundo.environment
	mundo.environment = ent
	OptimizarGrada.niebla_a_pie(nn, true)
	var puesta := ent.fog_enabled and ent.fog_mode == Environment.FOG_MODE_DEPTH and is_equal_approx(ent.fog_depth_end, 700.0)
	OptimizarGrada.niebla_a_pie(nn, false)
	_comprobar(puesta and not ent.fog_enabled and ent.fog_mode == Environment.FOG_MODE_EXPONENTIAL, "la niebla del paseo a pie se pone de 300 a 700 m y al salir el entorno queda como estaba")
	mundo.environment = ent0
	nn.free()
	## (7-11) Un peatón detrás de la cámara (a más de 3 m) no anima; delante, o pegado, sí.
	var mira_ := Vector3(0, 0, -1)
	_comprobar(not TraficoCiudad.detras(Vector3.ZERO, mira_, Vector3(0, 0, -10)) and TraficoCiudad.detras(Vector3.ZERO, mira_, Vector3(0, 0, 10)) and not TraficoCiudad.detras(Vector3.ZERO, mira_, Vector3(0, 0, 2)),
		"un peatón detrás de la cámara no anima; delante o pegado a ella, sí")
