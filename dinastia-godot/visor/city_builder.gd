class_name CityBuilder
extends "res://visor/city_builder_p11.gd"
## [Capa 12/12 de `city_builder.gd`] _distritos, _casa_gigante, mostrar_rotulos

func _distritos() -> void:
	var comercial: Array[PackedScene] = []
	for ruta in RUTAS_COMERCIAL:
		var e: PackedScene = load(ruta)
		if e != null:
			comercial.append(e)
	var naves: Array[PackedScene] = []
	for ruta in RUTAS_NAVES:
		var e2: PackedScene = load(ruta)
		if e2 != null:
			naves.append(e2)
	var altos: Array[PackedScene] = []
	for ruta in RUTAS_HORIZONTE:
		var e3: PackedScene = load(ruta)
		if e3 != null:
			altos.append(e3)
	var toldos: Array[PackedScene] = []
	for ruta in RUTAS_MOBILIARIO:
		var e4: PackedScene = load(ruta)
		if e4 != null:
			toldos.append(e4)
	if comercial.is_empty():
		return
	## 25-10-2026 (pciu): la imagen del asfalto se lee como sRGB, así que un
	## tinte 0,13 quedaba en ~0,013 lineal: de noche la calzada salía NEGRA junto a
	## aceras bien visibles. Asfalto real ≈ 0,08-0,12 lineal: tinte ~0,40.
	var asfalto: StandardMaterial3D = Texturas.asfalto(Color(0.40, 0.40, 0.415)).duplicate()
	asfalto.roughness = 0.75
	var acera := _mat_simple(Color(0.42, 0.41, 0.39), 0.9)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7102026
	var lleno: float = lerpf(0.62, 1.0, _empuje_club())
	manzanas_distrito = 0
	for d: Dictionary in DISTRITOS:
		var desde: Vector2 = d["desde"]
		var hasta: Vector2 = d["hasta"]
		var paso := MANZANA + Vector2(CALLE_DISTRITO, CALLE_DISTRITO)
		var nx := int(floor((hasta.x - desde.x) / paso.x))
		var nz := int(floor((hasta.y - desde.y) / paso.y))
		if nx <= 0 or nz <= 0:
			continue
		## Centrado en su rectángulo.
		var origen := desde + ((hasta - desde) - Vector2(nx, nz) * paso + Vector2(CALLE_DISTRITO, CALLE_DISTRITO)) * 0.5
		## Las calles del distrito: una rejilla de franjas de asfalto.
		var ancho_total := float(nx) * paso.x + CALLE_DISTRITO
		var fondo_total := float(nz) * paso.y + CALLE_DISTRITO
		var esquina := origen - Vector2(CALLE_DISTRITO, CALLE_DISTRITO)
		for i in nx + 1:
			var x := esquina.x + CALLE_DISTRITO * 0.5 + float(i) * paso.x
			_franja(Vector3(x, 0, esquina.y + fondo_total * 0.5), Vector2(CALLE_DISTRITO, fondo_total), asfalto)
		for k in nz + 1:
			var z := esquina.y + CALLE_DISTRITO * 0.5 + float(k) * paso.y
			_franja(Vector3(esquina.x + ancho_total * 0.5, 0, z), Vector2(ancho_total, CALLE_DISTRITO), asfalto)
		var mitad := Vector2(float(nx) * 0.5, float(nz) * 0.5)
		for i in nx:
			for k in nz:
				var c2 := origen + Vector2(float(i) * paso.x + MANZANA.x * 0.5, float(k) * paso.y + MANZANA.y * 0.5)
				var c := Vector3(c2.x, 0, c2.y)
				## La acera de la manzana.
				var base := _caja_en(Vector3(c.x, altura_en(c.x, c.z) + 0.1, c.z), Vector3(MANZANA.x, 0.2, MANZANA.y), acera)
				base.name = "Manzana"
				if rng.randf() > lleno:
					continue
				manzanas_distrito += 1
				## El corazón del distrito norte: torres.
				var cerca_centro: bool = bool(d["centro"]) and absf(float(i) + 0.5 - mitad.x) <= 1.0 and absf(float(k) + 0.5 - mitad.y) <= 1.0
				if cerca_centro and not altos.is_empty():
					## Tres torres por manzana y comercios en la planta baja.
					for o: Vector3 in [Vector3(-14, 0, -9), Vector3(14, 0, -9), Vector3(0, 0, 10)]:
						_torre_distrito(altos[rng.randi() % altos.size()], c + o, rng)
				else:
					_manzana(c, comercial, naves, toldos, rng)
		_cartel(Vector3(origen.x - 6.0, 0, origen.y - 6.0), String(d["nombre"]), false)

## La casa grande del barrio (`complejo_residencial.glb`), medida y centrada
## dentro de la finca, con un margen de jardín hasta el muro y el camino de
## entrada desde el portón.
func _casa_gigante(centro: Vector3, tam: Vector2) -> void:
	var esc := load(RUTA_CASA_GIGANTE)
	if esc == null or not (esc is PackedScene):
		return
	var n: Node3D = (esc as PackedScene).instantiate()
	var raiz := Node3D.new()
	raiz.name = "CasaGigante"
	add_child(raiz)
	raiz.add_child(n)
	var caja := _caja_de(n)
	## El origen del modelo no está en su centro ni en su base: se corrige.
	n.position = -Vector3(caja.position.x + caja.size.x * 0.5, caja.position.y, caja.position.z + caja.size.z * 0.5)
	var margen := 8.0
	var escala := minf((tam.x - margen * 2.0) / maxf(caja.size.x, 0.01), (tam.y - margen * 2.0 - 6.0) / maxf(caja.size.z, 0.01))
	raiz.scale = Vector3.ONE * escala
	raiz.rotation.y = PI
	raiz.position = centro + Vector3(0, 0.05, 3.0)
	casa_gigante = raiz
	## El camino desde el portón hasta la puerta.
	var losa := _mat_simple(Color(0.78, 0.74, 0.66), 0.85)
	var z0 := centro.z - tam.y * 0.5
	_caja_en(Vector3(centro.x, 0.06, z0 + 5.0), Vector3(6.0, 0.1, 10.0), losa)
	_rotulo(centro + Vector3(0, caja.size.y * escala + 6.0, 0), "🏰 La Casa Grande", Color(1, 0.92, 0.7), 22)
	puntos_clic.append({"k": "casa_grande", "n": "La Casa Grande", "pos": centro, "estado": "ciudad"})

func mostrar_rotulos(si: bool) -> void:
	if _rotulos != null:
		_rotulos.visible = si
