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

## (7-11) `Optimizar.celdas_de` (por tramos del buffer) da lo MISMO que repartir instancia a instancia: mismas celdas, mismo orden y los mismos datos. El formato del buffer (origen en
## 3, 7 y 11; color y datos detrás) se comprobó con renderizador real: en modo sin pantalla un MultiMesh no guarda datos, por eso aquí se arma el buffer a mano.
func _probar_celdas_agrupado() -> void:
	_titulo("TROCEAR AGRUPADOS POR TRAMOS DEL BUFFER: IGUAL QUE INSTANCIA A INSTANCIA")
	## (7-11) `BufferMM`: armar y leer el buffer en bloque da lo mismo que transformación a transformación (el formato real se comprobó con renderizador: filas, origen en 3, 7, 11).
	var rg0 := RandomNumberGenerator.new()
	rg0.seed = 11
	var ts: Array = []
	for i in 40:
		ts.append(Transform3D(Basis.from_euler(Vector3(rg0.randf(), rg0.randf(), rg0.randf())).scaled(Vector3(rg0.randf_range(0.5, 2.0), rg0.randf_range(0.5, 2.0), rg0.randf_range(0.5, 2.0))), Vector3(rg0.randf_range(-9, 9), rg0.randf(), rg0.randf_range(-9, 9))))
	var previa := Transform3D(Basis.from_euler(Vector3(0, 0.4, 0)), Vector3(3, 1, -2))
	var b0 := BufferMM.buffer_de(ts, previa)
	var ok0 := b0.size() == 480
	for i in 40:
		var esp: Transform3D = previa * (ts[i] as Transform3D)
		ok0 = ok0 and BufferMM.transform_de(b0, i * 12).is_equal_approx(esp) and absf(b0[i * 12 + 3] - esp.origin.x) < 0.00001 and absf(b0[i * 12 + 11] - esp.origin.z) < 0.00001
	_comprobar(ok0, "BufferMM.buffer_de y transform_de son inversos y ponen el origen en 3, 7, 11")
	for ordenado: bool in [false, true]:
		var paso := 20
		var n := 600
		var buf := PackedFloat32Array()
		buf.resize(n * paso)
		var rg := RandomNumberGenerator.new()
		rg.seed = 7
		for i in n:
			for q in paso:
				buf[i * paso + q] = rg.randf()   # datos distintos en todas las posiciones
			buf[i * paso + 3] = (float(i) / float(n) * 800.0 - 400.0) if ordenado else rg.randf_range(-400.0, 400.0)
			buf[i * paso + 7] = rg.randf_range(0.0, 5.0)
			buf[i * paso + 11] = rg.randf_range(-400.0, 400.0)
		var gt := Transform3D(Basis.from_euler(Vector3(0, 0.7, 0)), Vector3(30.0, 0.0, -20.0))
		var nuevo := Optimizar.celdas_de(gt, buf, paso, 100.0)
		var ref := {}
		for i in n:
			var o := gt * Vector3(buf[i * paso + 3], buf[i * paso + 7], buf[i * paso + 11])
			var kk := Vector2i(floori(o.x / 100.0), floori(o.z / 100.0))
			if not ref.has(kk):
				ref[kk] = []
			(ref[kk] as Array).append(i)
		var iguales := nuevo.size() == ref.size()
		for kk: Vector2i in ref:
			if not nuevo.has(kk):
				iguales = false
				continue
			var esperado := PackedFloat32Array()
			for i: int in ref[kk]:
				esperado.append_array(buf.slice(i * paso, (i + 1) * paso))
			iguales = iguales and (nuevo[kk] as Array)[1] == esperado and int((nuevo[kk] as Array)[0]) * paso == esperado.size()
		_comprobar(iguales and ref.size() > 20, "partir un agrupado por tramos del buffer da lo mismo que instancia a instancia (%s, %d celdas)" % ["ordenado" if ordenado else "aleatorio", ref.size()])
