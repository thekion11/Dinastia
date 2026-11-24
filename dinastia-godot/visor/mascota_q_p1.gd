extends "res://visor/mascota_q_p0.gd"
## [Capa 2/3 de `mascota_q.gd`] la cabeza (ojos, hocico, orejas y rasgos propios de cada animal)
# -----------------------------------------------------------------------------
#  LA CABEZA
# -----------------------------------------------------------------------------

static func cabeza(cab: Node3D, animal: String, fila: Array, pelo: Color, mat_pelo: Material,
		mat_claro: Material, _c1: Color, c2: Color) -> void:
	var hocico := String(fila[2])
	var extra := String(fila[4])
	## El cráneo: un poco más ancho que alto, como los trajes.
	_esf(cab, Vector3.ZERO, 0.34, mat_pelo, Vector3(1.06, 0.97, 0.94))
	_cabeza_ojos(cab, animal, hocico, extra, pelo, mat_claro)
	_cabeza_hocico(cab, animal, hocico, mat_claro, mat_pelo)
	_cabeza_orejas_a(cab, String(fila[1]), pelo, mat_pelo)
	_cabeza_orejas_b(cab, String(fila[1]), pelo, mat_pelo)
	_cabeza_propio_a(cab, extra, pelo, c2)
	_cabeza_propio_b(cab, extra, c2)
	_cabeza_propio_c(cab, extra, mat_pelo, mat_claro)

static func _cabeza_ojos(
		cab: Node3D, animal: String, hocico: String, extra: String, pelo: Color, mat_claro: Material) -> void:
	var oscuro := _mat(Color(0.06, 0.05, 0.05), 0.35)
	var ojo_y := 0.08
	var ojo_z := 0.27
	var sep := 0.125
	if hocico == "cocodrilo":
		ojo_y = 0.2
		ojo_z = 0.2
	var iris_col := Color(0.35, 0.22, 0.1) if animal not in ["aguila", "buho", "tigre", "gato", "lobo", "dragon"] else Color(0.95, 0.72, 0.1)
	if extra == "anteojos":
		for s in [-1.0, 1.0]:
			_esf(cab, Vector3(sep * s * 1.1, ojo_y, ojo_z - 0.02), 0.14, mat_claro, Vector3(1, 1, 0.45))
	if extra == "antifaz":
		_esf(cab, Vector3(0, -0.02, 0.12), 0.27, mat_claro, Vector3(1.05, 0.95, 0.85))
	for s in [-1.0, 1.0]:
		var o := Vector3(sep * s, ojo_y, ojo_z)
		_esf(cab, o, 0.09, _mat(Color(0.98, 0.98, 0.97), 0.25), Vector3(1.0, 1.18, 0.62))
		_esf(cab, o + Vector3(0.008 * s, -0.005, 0.045), 0.052, _mat(iris_col, 0.3), Vector3(1, 1.1, 0.5))
		_esf(cab, o + Vector3(0.01 * s, -0.005, 0.062), 0.03, oscuro, Vector3(1, 1.15, 0.5))
		var brillo := _mat(Color.WHITE, 0.1, 1.2)
		_esf(cab, o + Vector3(0.022 * s + 0.01, 0.02, 0.078), 0.012, brillo)
		## Cejas: expresivas, del segundo color del club (el ceño del águila
		## las inclina hacia adentro).
		var ceja := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.014
		cm.height = 0.1
		ceja.mesh = cm
		ceja.material_override = _mat(pelo.darkened(0.55), 0.8)
		ceja.position = o + Vector3(0, 0.11, 0.0)
		ceja.rotation_degrees = Vector3(0, 0, 90.0 + (-22.0 if extra == "ceño" else 12.0) * s)
		cab.add_child(ceja)
		## Mejillas.
		if hocico != "pico" and hocico != "cocodrilo" and hocico != "tiburon":
			_esf(cab, Vector3(0.2 * s, -0.06, 0.22), 0.05, _mat(Color(1.0, 0.55, 0.55), 0.9, 0.0, 0.55))

static func _cabeza_hocico(
		cab: Node3D, animal: String, hocico: String, mat_claro: Material, mat_pelo: Material) -> void:
	var oscuro := _mat(Color(0.06, 0.05, 0.05), 0.35)
	var punta := Vector3(0, -0.07, 0.4)
	match hocico:
		"redondo":
			_esf(cab, Vector3(0, -0.09, 0.25), 0.15, mat_claro, Vector3(1.2, 0.85, 0.9))
			punta = Vector3(0, -0.04, 0.385)
		"ancho":
			_esf(cab, Vector3(0, -0.1, 0.26), 0.17, mat_claro, Vector3(1.4, 0.85, 0.9))
			punta = Vector3(0, -0.06, 0.41)
			for s in [-1.0, 1.0]:
				_esf(cab, Vector3(0.06 * s, -0.08, 0.41), 0.025, oscuro)
			var aro := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.035
			tm.outer_radius = 0.05
			aro.mesh = tm
			aro.material_override = _mat(Color(0.85, 0.75, 0.3), 0.25)
			aro.position = Vector3(0, -0.16, 0.41)
			aro.rotation_degrees = Vector3(90, 0, 0)
			cab.add_child(aro)
		"largo":
			_esf(cab, Vector3(0, -0.07, 0.3), 0.14, mat_claro if animal in ["perro", "lobo", "zorro"] else mat_pelo, Vector3(0.85, 0.75, 1.55))
			punta = Vector3(0, -0.03, 0.51)
		"pico":
			var col_pico := Color(1.0, 0.72, 0.1) if animal != "pinguino" else Color(1.0, 0.5, 0.1)
			var pico := _mat(col_pico, 0.4)
			_cono(cab, Vector3(0, -0.04, 0.37), Vector3(80, 0, 0), 0.075, 0.22 if animal != "buho" else 0.12, pico)
			if animal == "aguila":
				_esf(cab, Vector3(0, -0.1, 0.44), 0.035, pico)
			punta = Vector3.ZERO
		"cocodrilo":
			_esf(cab, Vector3(0, -0.06, 0.34), 0.17, mat_pelo, Vector3(0.95, 0.45, 2.0))
			punta = Vector3(0, 0.0, 0.66)
		"tiburon":
			_esf(cab, Vector3(0, -0.02, 0.2), 0.2, mat_pelo, Vector3(1.0, 0.7, 1.4))
			_esf(cab, Vector3(0, -0.12, 0.22), 0.18, mat_claro, Vector3(1.0, 0.45, 1.3))
			punta = Vector3.ZERO
	if punta != Vector3.ZERO:
		_esf(cab, punta, 0.045 if hocico != "cocodrilo" else 0.025, oscuro, Vector3(1.3, 0.9, 1.0))
		## Sonrisa: un arco de puntos bajo la nariz.
		if hocico != "cocodrilo":
			for i in range(-3, 4):
				var x := float(i) * 0.028
				_esf(cab, Vector3(x, punta.y - 0.075 + x * x * 2.2, punta.z - 0.05 - absf(x) * 0.25), 0.013, oscuro)

static func _cabeza_orejas_a(cab: Node3D, forma: String, pelo: Color, mat_pelo: Material) -> void:
	var rosa := _mat(Color(0.95, 0.58, 0.62), 0.8)
	match forma:
		"puntiagudas":
			for s in [-1.0, 1.0]:
				_cono(cab, Vector3(0.19 * s, 0.31, -0.02), Vector3(-8, 0, -22 * s), 0.1, 0.24, mat_pelo)
				_cono(cab, Vector3(0.19 * s, 0.3, 0.025), Vector3(-8, 0, -22 * s), 0.055, 0.15, rosa)
		"redondas":
			for s in [-1.0, 1.0]:
				_esf(cab, Vector3(0.24 * s, 0.26, -0.02), 0.1, mat_pelo, Vector3(1, 1, 0.5))
				_esf(cab, Vector3(0.24 * s, 0.26, 0.02), 0.06, rosa, Vector3(1, 1, 0.4))
		"caidas":
			for s in [-1.0, 1.0]:
				var oreja := _esf(cab, Vector3(0.33 * s, -0.02, -0.02), 0.13, _pelaje_oscuro(pelo), Vector3(0.45, 1.25, 0.75))
				oreja.rotation_degrees.z = 14.0 * s
		"largas":
			for s in [-1.0, 1.0]:
				var o2 := _caps(cab, Vector3(0.11 * s, 0.52, -0.03), Vector3(0, 0, -9 * s), 0.07, 0.5, mat_pelo)
				o2.scale = Vector3(1, 1, 0.5)
				var o3 := _caps(cab, Vector3(0.11 * s, 0.52, 0.0), Vector3(0, 0, -9 * s), 0.04, 0.4, rosa)
				o3.scale = Vector3(1, 1, 0.4)

static func _cabeza_orejas_b(cab: Node3D, forma: String, pelo: Color, mat_pelo: Material) -> void:
	var rosa := _mat(Color(0.95, 0.58, 0.62), 0.8)
	match forma:
		"laterales":
			for s in [-1.0, 1.0]:
				_esf(cab, Vector3(0.37 * s, 0.02, -0.02), 0.12, mat_pelo, Vector3(0.4, 1, 1))
				_esf(cab, Vector3(0.39 * s, 0.02, 0.0), 0.075, rosa, Vector3(0.3, 1, 1))
		"caballo":
			for s in [-1.0, 1.0]:
				_cono(cab, Vector3(0.13 * s, 0.34, -0.04), Vector3(0, 0, -12 * s), 0.06, 0.18, mat_pelo)
		"penachos":
			for s in [-1.0, 1.0]:
				_cono(cab, Vector3(0.2 * s, 0.3, 0.0), Vector3(0, 0, -30 * s), 0.07, 0.2, _pelaje_oscuro(pelo))

static func _cabeza_propio_a(cab: Node3D, extra: String, pelo: Color, c2: Color) -> void:
	var oscuro := _mat(Color(0.06, 0.05, 0.05), 0.35)
	match extra:
		"melena":
			var mat_melena := material_pelaje(pelo.lerp(c2, 0.25).darkened(0.35), "")
			for i in range(16):
				var a := TAU * float(i) / 16.0
				_esf(cab, Vector3(cos(a) * 0.35, sin(a) * 0.33, -0.06), 0.13, mat_melena)
			_esf(cab, Vector3(0, 0.02, -0.14), 0.36, mat_melena)
		"cuernos":
			var hueso := _mat(Color(0.95, 0.9, 0.8), 0.45)
			for s in [-1.0, 1.0]:
				_cil(cab, Vector3(0.3 * s, 0.2, 0), Vector3(0, 0, -70 * s), 0.05, 0.16, hueso)
				_cono(cab, Vector3(0.42 * s, 0.3, 0), Vector3(0, 0, -20 * s), 0.05, 0.2, hueso)
		"cuernos_dragon":
			var cuerno := _mat(Color(0.95, 0.85, 0.55), 0.5)
			for s in [-1.0, 1.0]:
				_cono(cab, Vector3(0.15 * s, 0.3, -0.12), Vector3(-45, 0, -10 * s), 0.06, 0.3, cuerno)
			for i in range(4):
				_cono(cab, Vector3(0, 0.32 - i * 0.1, -0.2 - i * 0.07), Vector3(-40 - i * 15, 0, 0), 0.05, 0.14, _mat(c2, 0.6))
			for s in [-1.0, 1.0]:
				_esf(cab, Vector3(0.04 * s, 0.0, 0.52), 0.018, oscuro)

static func _cabeza_propio_b(cab: Node3D, extra: String, c2: Color) -> void:
	var oscuro := _mat(Color(0.06, 0.05, 0.05), 0.35)
	var rosa := _mat(Color(0.95, 0.58, 0.62), 0.8)
	match extra:
		"cresta":
			var rojo := _mat(Color(0.88, 0.1, 0.12), 0.6)
			for i in range(4):
				_esf(cab, Vector3(0, 0.34 + (0.03 if i % 2 == 1 else 0.0), 0.12 - i * 0.1), 0.075, rojo, Vector3(0.5, 1, 1))
			_esf(cab, Vector3(0, -0.2, 0.36), 0.05, rojo, Vector3(0.7, 1.4, 0.7))
		"crin":
			var crin := material_pelaje(c2.darkened(0.2), "")
			for i in range(6):
				_esf(cab, Vector3(0, 0.33 - i * 0.04, 0.12 - i * 0.1), 0.06, crin, Vector3(0.5, 1.4, 1))
		"lengua":
			_esf(cab, Vector3(0.03, -0.2, 0.43), 0.05, rosa, Vector3(1, 0.4, 1.3))
		"bigotes":
			for s in [-1.0, 1.0]:
				for j in range(3):
					_cil(cab, Vector3(0.14 * s, -0.08 + j * 0.02, 0.36), Vector3(0, 0, 90 + (j - 1) * 12 * s), 0.004, 0.2, oscuro)

static func _cabeza_propio_c(
		cab: Node3D, extra: String, mat_pelo: Material, mat_claro: Material) -> void:
	match extra:
		"dientes":
			var blanco := _mat(Color(0.98, 0.98, 0.96), 0.3)
			for s in [-0.5, 0.5]:
				var dnt := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.035, 0.05, 0.015)
				dnt.mesh = bm
				dnt.material_override = blanco
				dnt.position = Vector3(0.02 * s * 2.0, -0.16, 0.37)
				cab.add_child(dnt)
		"dientes_cocodrilo", "aleta_dorsal":
			var blanco2 := _mat(Color(0.98, 0.98, 0.96), 0.3)
			var z0 := 0.3 if extra == "dientes_cocodrilo" else 0.25
			for s in [-1.0, 1.0]:
				for j in range(5):
					_cono(cab, Vector3(0.12 * s, -0.12, z0 + j * 0.06), Vector3(180, 0, 0), 0.018, 0.045, blanco2)
			if extra == "aleta_dorsal":
				var aleta := _cono(cab, Vector3(0, 0.42, -0.08), Vector3(-20, 0, 0), 0.16, 0.3, mat_pelo)
				aleta.scale = Vector3(0.3, 1, 1)
		"mejillas_blancas":
			for s in [-1.0, 1.0]:
				_esf(cab, Vector3(0.2 * s, -0.1, 0.16), 0.12, mat_claro, Vector3(1, 0.8, 0.8))
		"cara_clara":
			_esf(cab, Vector3(0, 0.0, 0.2), 0.22, mat_claro, Vector3(1.1, 1.05, 0.6))


# -----------------------------------------------------------------------------
#  LA COLA
# -----------------------------------------------------------------------------

static func _cola_de(cola: Node3D, tipo: String, mat_pelo: Material, mat_claro: Material, c2: Color) -> void:
	match tipo:
		"larga", "larga_borla", "tupida":
			var n := 7
			for i in range(n):
				var f := float(i) / float(n - 1)
				var r := lerpf(0.075, 0.04, f) * (1.6 if tipo == "tupida" else 1.0)
				## Baja y luego se curva hacia arriba, como una "S" suave.
				var p := Vector3(0, -0.1 * sin(f * PI) + f * 0.25, -f * 0.55)
				_esf(cola, p, r, mat_pelo)
			if tipo == "larga_borla":
				_esf(cola, Vector3(0, 0.27, -0.58), 0.08, material_pelaje(c2.darkened(0.3), ""))
			if tipo == "tupida":
				_esf(cola, Vector3(0, 0.27, -0.6), 0.075, mat_claro)
		"bola":
			_esf(cola, Vector3(0, 0, -0.04), 0.09, mat_pelo)
		"pompon":
			_esf(cola, Vector3(0, 0, -0.05), 0.11, mat_claro)
		"plumas":
			for i in range(5):
				var pl := _cono(cola, Vector3((i - 2) * 0.05, -0.05, -0.12), Vector3(-110, (i - 2) * 14.0, 0), 0.05, 0.3, mat_pelo)
				pl.scale = Vector3(1, 1, 0.3)
		"crin":
			var crin := material_pelaje(c2.darkened(0.2), "")
			for i in range(5):
				_caps(cola, Vector3((i - 2) * 0.03, -0.25, -0.08), Vector3(-20, 0, (i - 2) * 6.0), 0.035, 0.55, crin)
		"aleta":
			var al := _cono(cola, Vector3(0, 0, -0.18), Vector3(-90, 0, 0), 0.12, 0.3, mat_pelo)
			al.scale = Vector3(0.3, 1, 1)

## La transformada de `n` respecto de `raiz` (sin depender de que estén en el árbol).
static func _rel(raiz: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var x: Node = n
	while x != null and x != raiz:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t

## Funde todas las mallas que cuelgan de `raiz` (a cualquier profundidad) en
## una sola, con una superficie por material. Las piezas se quitan.
static func fusionar(raiz: Node3D) -> MeshInstance3D:
	if raiz == null:
		return null
	var piezas: Array = []
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh != null and mi.visible:
			piezas.append(mi)
	if piezas.size() < 2:
		return null
	var por_mat := {}
	for mi: MeshInstance3D in piezas:
		var rel := _rel(raiz, mi)
		for sfc in mi.mesh.get_surface_count():
			var mat: Material = mi.material_override if mi.material_override != null else mi.get_active_material(sfc)
			if not por_mat.has(mat):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				por_mat[mat] = st
			(por_mat[mat] as SurfaceTool).append_from(mi.mesh, sfc, rel)
	var am := ArrayMesh.new()
	for mat: Material in por_mat:
		var st: SurfaceTool = por_mat[mat]
		st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, mat)
	for mi: MeshInstance3D in piezas:
		mi.get_parent().remove_child(mi)
		mi.queue_free()
	var out := MeshInstance3D.new()
	out.name = "Fundida"
	out.mesh = am
	raiz.add_child(out)
	return out
