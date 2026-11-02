extends Node
## La extensión en C++ (`Nativo`) da los MISMOS bytes que las versiones GDScript a las que
## sustituye, con datos reales: la rampa de las texturas de ruido y el alisado de la ropa de los dos
## cuerpos (30-10-2026). En Linux y Windows la extensión tiene que estar; si falta, es un FALLO.

var _fallos := 0

func _ready() -> void:
	_probar.call_deferred()

func _probar() -> void:
	var nat := Nativo.obj()
	_comprobar(nat != null, "la extensión nativa está cargada")
	if nat == null:
		_fin()
		return
	## La rampa: dos pisos distintos y ruido de verdad.
	for piso: float in [0.78, 0.55]:
		var lut := RuidosFondo._lut(piso)
		var n := FastNoiseLite.new()
		n.seed = 97
		var img := n.get_seamless_image(512, 512, false, false, 0.1, true)
		var t0 := Time.get_ticks_usec()
		var a := RuidosFondo._con_rampa_gd(img, lut).get_data()
		var t1 := Time.get_ticks_usec()
		var b := RuidosFondo._con_rampa(img, lut).get_data()
		var t2 := Time.get_ticks_usec()
		_comprobar(a == b, "rampa (piso %s) igual byte a byte" % piso)
		print("rampa %.2f: GDScript %d ms, C++ %d ms" % [piso, (t1 - t0) / 1000, (t2 - t1) / 1000])
	## El relieve de la ciudad (64 baldosas) y la textura de hierba.
	var r := FastNoiseLite.new()
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	r.seed = 20260912
	r.frequency = 0.00055
	r.fractal_octaves = 4
	r.fractal_lacunarity = 2.1
	var d := FastNoiseLite.new()
	d.noise_type = FastNoiseLite.TYPE_SIMPLEX
	d.seed = 771
	d.frequency = 0.0035
	var u0 := Time.get_ticks_usec()
	var tg := TerrenoArreglos.calcular_gd(r, d)
	var u1 := Time.get_ticks_usec()
	var tn := TerrenoArreglos.calcular(r, d)
	var u2 := Time.get_ticks_usec()
	_comprobar(var_to_bytes(tg) == var_to_bytes(tn), "terreno igual byte a byte (%d baldosas)" % tn.size())
	print("terreno: GDScript %d ms, C++ %d ms" % [(u1 - u0) / 1000, (u2 - u1) / 1000])
	u0 = Time.get_ticks_usec()
	var hg := CityBuilder._imagen_hierba_gd()
	u1 = Time.get_ticks_usec()
	var hn := CityBuilder._imagen_hierba()
	u2 = Time.get_ticks_usec()
	_comprobar(hg.get_data() == hn.get_data(), "hierba igual byte a byte")
	print("hierba: GDScript %d ms, C++ %d ms" % [(u1 - u0) / 1000, (u2 - u1) / 1000])
	## El alisado, con las mallas reales de los cuerpos.
	for ruta in [FutbolistaQ.MODELO_MALE, FutbolistaQ.MODELO_FEMALE]:
		var raiz: Node = (load(ruta) as PackedScene).instantiate()
		for mi: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
			var am := mi.mesh as ArrayMesh
			if am == null:
				continue
			for s in am.get_surface_count():
				var arr := am.surface_get_arrays(s)
				var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				if pos.size() < 2000:
					continue
				var t0 := Time.get_ticks_usec()
				var a: Array = VestidorQ._alisado_gd(pos, arr[Mesh.ARRAY_NORMAL], arr[Mesh.ARRAY_INDEX])
				var t1 := Time.get_ticks_usec()
				var b: Array = VestidorQ._alisado(pos, arr[Mesh.ARRAY_NORMAL], arr[Mesh.ARRAY_INDEX])
				var t2 := Time.get_ticks_usec()
				var igual := var_to_bytes(a[0]) == var_to_bytes(b[0]) and var_to_bytes(a[1]) == var_to_bytes(b[1])
				_comprobar(igual, "alisado de %s/%s igual byte a byte" % [ruta.get_file(), mi.name])
				print("alisado %s (%d vértices): GDScript %d ms, C++ %d ms" % [mi.name, pos.size(), (t1 - t0) / 1000, (t2 - t1) / 1000])
		raiz.free()
	_fin()

func _comprobar(ok: bool, que: String) -> void:
	if not ok:
		_fallos += 1
		print("FALLO ", que)

func _fin() -> void:
	print("FIN. %d fallos" % _fallos)
	get_tree().quit()
