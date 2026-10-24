extends "res://visor/city_builder_p9.gd"
## [Capa 10/12 de `city_builder.gd`] _karts_en_pista, _redondear, autobus, _un_peaton, _hacer_bote, _trafico … (+3)

## Llamado desde `_trafico()`, cuando ya existe el tráfico.
func _karts_en_pista(t: TraficoCiudad) -> void:
	if _karts_pendientes.is_empty():
		return
	var id := t.agregar_ruta(_karts_pendientes["ruta"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	for i in KARTS.size():
		var e := _extra(KARTS[i])
		if e == null:
			continue
		var n: Node3D = e.instantiate()
		n.scale = Vector3.ONE * 2.2
		t.agregar_vehiculo(n, id, float(i) * 22.0, rng.randf_range(11.0, 15.0), 0.0, 0.0)
	_karts_pendientes = {}

## Redondea las esquinas de un recorrido: en cada vértice se corta `radio`
## metros por cada lado y se cose el hueco con un arco de cuatro tramos. Sin
## esto, un coche llega a la esquina y gira 90° en un fotograma -se ve como un
## salto- y el velero daba un volantazo imposible al final del río.
func _redondear(puntos: PackedVector3Array, radio: float) -> PackedVector3Array:
	var n := puntos.size()
	if n < 3 or radio <= 0.01:
		return puntos
	var salida := PackedVector3Array()
	for i in range(n):
		var prev: Vector3 = puntos[(i - 1 + n) % n]
		var act: Vector3 = puntos[i]
		var sig: Vector3 = puntos[(i + 1) % n]
		var a: Vector3 = (prev - act)
		var b: Vector3 = (sig - act)
		## El radio nunca puede comerse más de la mitad de un tramo, o las
		## curvas de dos esquinas seguidas se solaparían y el recorrido se
		## cruzaría consigo mismo.
		var r: float = minf(radio, minf(a.length(), b.length()) * 0.45)
		var pa: Vector3 = act + a.normalized() * r
		var pb: Vector3 = act + b.normalized() * r
		salida.append(pa)
		for k in range(1, 4):
			var tt: float = float(k) / 4.0
			## Bézier cuadrática con el vértice como punto de control: es la
			## curva más barata que entra y sale tangente a los dos tramos.
			var q0: Vector3 = pa.lerp(act, tt)
			var q1: Vector3 = act.lerp(pb, tt)
			salida.append(q0.lerp(q1, tt))
		salida.append(pb)
	return salida

## EL AUTOBÚS URBANO (7-10-2026): el kit no trae ninguno y la furgoneta
## agrandada medía 6 m de alto. Este se arma con piezas: 12 m de largo, 3,1 de
## alto y 2,55 de ancho, con franja de ventanas, parabrisas, dos puertas,
## rótulo de destino encendido, ruedas y el color de la línea. Mira a +Z.
static func autobus(col: Color, destino: String = "") -> Node3D:
	var raiz := Node3D.new()
	var pintura := StandardMaterial3D.new()
	pintura.albedo_color = col
	pintura.roughness = 0.35
	pintura.metallic = 0.2
	var blanco := StandardMaterial3D.new()
	blanco.albedo_color = Color(0.94, 0.94, 0.92)
	blanco.roughness = 0.4
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.12, 0.16, 0.2)
	vidrio.roughness = 0.08
	vidrio.metallic = 0.6
	var goma := StandardMaterial3D.new()
	goma.albedo_color = Color(0.06, 0.06, 0.06)
	goma.roughness = 0.9
	var piezas := [
		[Vector3(0, 1.0, 0), Vector3(2.55, 1.2, 12.0), pintura],           ## faldón
		[Vector3(0, 2.3, 0), Vector3(2.5, 1.4, 11.9), vidrio],            ## ventanas
		[Vector3(0, 3.05, 0), Vector3(2.55, 0.2, 12.0), blanco],          ## techo
		[Vector3(0, 3.25, -1.5), Vector3(1.8, 0.25, 3.0), blanco],        ## climatizador
		[Vector3(0, 2.3, 5.97), Vector3(2.3, 1.5, 0.08), vidrio],         ## parabrisas
		[Vector3(0, 1.0, 6.02), Vector3(2.4, 0.5, 0.05), blanco],         ## parachoques
		[Vector3(0, 2.85, 6.0), Vector3(1.8, 0.28, 0.06), null],          ## rótulo
	]
	for pz: Array in piezas:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = pz[1]
		mi.mesh = bm
		mi.position = pz[0]
		if pz[2] != null:
			mi.material_override = pz[2]
		else:
			var led := StandardMaterial3D.new()
			led.albedo_color = Color(1.0, 0.7, 0.1)
			led.emission_enabled = true
			led.emission = Color(1.0, 0.6, 0.1)
			led.emission_energy_multiplier = 1.5
			mi.material_override = led
		raiz.add_child(mi)
	## Pilares entre ventanas y las dos puertas (lado derecho, +X).
	for k in 7:
		var pil := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(2.58, 1.4, 0.18)
		pil.mesh = bm2
		pil.material_override = pintura
		pil.position = Vector3(0, 2.3, -5.4 + float(k) * 1.8)
		raiz.add_child(pil)
	for zp: float in [4.6, -0.8]:
		var pu := MeshInstance3D.new()
		var bm3 := BoxMesh.new()
		bm3.size = Vector3(0.06, 2.3, 1.2)
		pu.mesh = bm3
		pu.material_override = vidrio
		pu.position = Vector3(1.29, 1.55, zp)
		raiz.add_child(pu)
	## Ruedas.
	for zr: float in [3.8, -3.6]:
		for xr: float in [-1.15, 1.15]:
			var r := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.5
			cm.bottom_radius = 0.5
			cm.height = 0.32
			r.mesh = cm
			r.material_override = goma
			r.rotation.z = PI * 0.5
			r.position = Vector3(xr, 0.5, zr)
			raiz.add_child(r)
	if destino != "":
		var l := Label3D.new()
		l.text = destino
		l.font_size = 32
		l.pixel_size = 0.006
		l.modulate = Color(0.1, 0.05, 0.0)
		l.outline_size = 0
		l.position = Vector3(0, 2.85, 6.04)
		raiz.add_child(l)
	return raiz

## Un peatón de verdad (`PeatonQ`: hombre o mujer del paquete Quaternius, con
## ropa de calle, pelo y a veces barba) caminando por la acera a paso humano.
## Los modelos miran a +Z, que es lo que `TraficoCiudad` alinea con la marcha.
func _un_peaton(t: TraficoCiudad, rng: RandomNumberGenerator, ruta: int, s0: float) -> void:
	var d := PeatonQ.crear(rng)
	if d.is_empty():
		return
	t.agregar_vehiculo(d["nodo"], ruta, s0, rng.randf_range(1.15, 1.5), 0.18, 0.0)
	PeatonQ.terminar(d)

## El velero ya no se monta aquí: navega, así que lo cuelga `_trafico()` de su
## propia ruta por el río. Esta función solo lo fabrica.
## Un bote de paseo (casco, cabina y toldo), lo bastante bajo para pasar bajo
## los puentes. Mira a +Z como los coches.
func _hacer_bote(k: int) -> Node3D:
	var n := Node3D.new()
	n.name = "Bote"
	var casco := [Color(0.9, 0.9, 0.88), Color(0.15, 0.3, 0.55), Color(0.7, 0.15, 0.12)][k % 3] as Color
	var mc := _mat_simple(casco, 0.4)
	var c := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.4, 1.2, 9.0)
	c.mesh = bm
	c.material_override = mc
	c.position = Vector3(0, 0.3, 0)
	n.add_child(c)
	var proa := MeshInstance3D.new()
	var pr := PrismMesh.new()
	pr.size = Vector3(3.4, 2.2, 1.2)
	proa.mesh = pr
	proa.material_override = mc
	proa.rotation = Vector3(PI * 0.5, 0, 0)
	proa.position = Vector3(0, 0.3, 5.0)
	n.add_child(proa)
	var cab := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(2.6, 1.3, 3.2)
	cab.mesh = cb
	cab.material_override = _mat_simple(Color(0.95, 0.95, 0.93), 0.5)
	cab.position = Vector3(0, 1.5, -0.8)
	n.add_child(cab)
	var toldo := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(3.0, 0.12, 3.6)
	toldo.mesh = tb
	toldo.material_override = _mat_simple(_color_club("c1", Color(0.2, 0.5, 0.3)), 0.7)
	toldo.position = Vector3(0, 2.25, -0.8)
	n.add_child(toldo)
	return n

func _trafico() -> void:
	var t := TraficoCiudad.new()
	t.name = "Trafico"
	add_child(t)
	_karts_en_pista(t)

	## La flota: los coches normales pesan mucho más que los de servicio -uno de
	## cada cinco- porque si no el mapa parece una emergencia permanente.
	var coches: Array = flota_coches()
	for ruta in RUTAS_SERVICIO:
		var esc2: PackedScene = load(ruta)
		if esc2 != null:
			coches.append({"esc": esc2, "escala": 1.65, "fbx": false})

	var rng := RandomNumberGenerator.new()
	rng.seed = 8821

	## 1) EL ANILLO, en los dos sentidos. Dos carriles separados del eje, uno
	## por sentido: con un solo recorrido todos los coches iban en fila india
	## por el mismo sitio y la calle de vuelta quedaba vacía.
	var n_norte: float = RING_Z_NORTE
	var n_sur: float = RING_Z_SUR
	for sentido in [1.0, -1.0]:
		var off: float = CARRIL * sentido
		var esquinas := PackedVector3Array([
			Vector3(RING_X - off, 0.25, n_norte + off),
			Vector3(RING_X - off, 0.25, n_sur - off),
			Vector3(-RING_X + off, 0.25, n_sur - off),
			Vector3(-RING_X + off, 0.25, n_norte + off),
		])
		if sentido < 0.0:
			esquinas.reverse()
		var id := t.agregar_ruta(_redondear(esquinas, 26.0))
		if coches.is_empty():
			continue
		## Y el TRÁFICO también sube con el club: de 4 coches por sentido en un
		## club de barrio a 10 en uno grande. Una ciudad de primera división no
		## puede tener las calles igual de vacías que una de tercera.
		var por_sentido: int = int(round(lerpf(4.0, 10.0, _empuje_club())))
		for i in range(por_sentido):
			var nodo: Node3D = instanciar_coche(coches[rng.randi() % coches.size()], rng)
			## Giro 0: `instanciar_coche` ya deja el morro en +Z (ver arriba).
			t.agregar_vehiculo(nodo, id, rng.randf() * 1800.0,
				rng.randf_range(13.0, 22.0), 0.0, 0.0)

	## 1b) EL EJE EXTERIOR, con su propio tráfico -si la circunvalación estuviera
	## vacía se notaría más que si no existiera-.
	for sentido2 in [1.0, -1.0]:
		var off2: float = CARRIL * sentido2
		var esq2 := PackedVector3Array([
			Vector3(392.0 - off2, 0.25, -282.0 + off2),
			Vector3(392.0 - off2, 0.25, 262.0 - off2),
			Vector3(-392.0 + off2, 0.25, 262.0 - off2),
			Vector3(-392.0 + off2, 0.25, -282.0 + off2),
		])
		if sentido2 < 0.0:
			esq2.reverse()
		var id_ex := t.agregar_ruta(_redondear(esq2, 30.0))
		if coches.is_empty():
			continue
		for i in range(int(round(lerpf(3.0, 7.0, _empuje_club())))):
			var n_ex: Node3D = instanciar_coche(coches[rng.randi() % coches.size()], rng)
			t.agregar_vehiculo(n_ex, id_ex, rng.randf() * 2200.0,
				rng.randf_range(15.0, 24.0), 0.0, 0.0)
		## Y dos autobuses por sentido, en la misma ruta -es el eje que pasa
		## junto a las cuatro paradas y la terminal-, más grandes y más lentos
		## que el tráfico normal.
		for i in range(2):
			if true:
				var bus: Node3D = autobus(Color(0.95, 0.75, 0.15), "ESTADIO")
				t.agregar_vehiculo(bus, id_ex, rng.randf_range(200.0, 2000.0),
					9.0, 0.0, 0.0)

	## 2) LA AVENIDA DE ACCESO y 3) LA CALLE DEL BARRIO: circuitos estrechos
	## -se baja por un carril y se sube por el otro-, que es lo que hace que un
	## tramo sin salida tenga tráfico sin necesidad de dar media vuelta a lo
	## bruto delante de la cámara.
	for tramo in [
			{"x": 0.0, "z0": -85.0, "z1": RING_Z_SUR - 10.0, "n": 3},
			{"x": BARRIO_EN.x, "z0": RING_Z_SUR + 10.0, "z1": FINCA_PORTON_Z - 14.0, "n": 2},
		]:
		var x: float = tramo["x"]
		var z0: float = tramo["z0"]
		var z1: float = tramo["z1"]
		var circuito := PackedVector3Array([
			Vector3(x - CARRIL, 0.25, z0), Vector3(x - CARRIL, 0.25, z1),
			Vector3(x + CARRIL, 0.25, z1), Vector3(x + CARRIL, 0.25, z0),
		])
		var id2 := t.agregar_ruta(_redondear(circuito, 7.0))
		if coches.is_empty():
			continue
		for i in range(int(tramo["n"])):
			var nodo2: Node3D = instanciar_coche(coches[rng.randi() % coches.size()], rng)
			t.agregar_vehiculo(nodo2, id2, rng.randf() * 600.0,
				rng.randf_range(9.0, 15.0), 0.0, 0.0)

	## 5) LOS PEATONES (26-9-2026, B7): por las aceras del anillo y de la
	## avenida, en los dos sentidos, más cuanto más grande es el club.
	var rng_p := RandomNumberGenerator.new()
	rng_p.seed = 5150
	for sentido_p: float in [1.0, -1.0]:
		var acera: float = (ANCHO_CALLE * 0.5 + BORDILLO + ACERA * 0.5) * sentido_p
		var esq_p := PackedVector3Array([
			Vector3(RING_X + acera, 0.3, RING_Z_NORTE - acera),
			Vector3(RING_X + acera, 0.3, RING_Z_SUR + acera),
			Vector3(-RING_X - acera, 0.3, RING_Z_SUR + acera),
			Vector3(-RING_X - acera, 0.3, RING_Z_NORTE - acera),
		])
		if sentido_p < 0.0:
			esq_p.reverse()
		var id_p := t.agregar_ruta(_redondear(esq_p, 20.0))
		for i in range(int(round(lerpf(10.0, 22.0, _empuje_club())))):
			_un_peaton(t, rng_p, id_p, rng_p.randf() * 2400.0)
	var acera_av := PackedVector3Array([
		Vector3(-(ANCHO_CALLE * 0.5 + BORDILLO + ACERA * 0.5), 0.3, -85.0), Vector3(-(ANCHO_CALLE * 0.5 + BORDILLO + ACERA * 0.5), 0.3, RING_Z_SUR - 10.0),
		Vector3(ANCHO_CALLE * 0.5 + BORDILLO + ACERA * 0.5, 0.3, RING_Z_SUR - 10.0), Vector3(ANCHO_CALLE * 0.5 + BORDILLO + ACERA * 0.5, 0.3, -85.0),
	])
	var id_av := t.agregar_ruta(_redondear(acera_av, 5.0))
	for i in range(int(round(lerpf(6.0, 14.0, _empuje_club())))):
		_un_peaton(t, rng_p, id_av, rng_p.randf() * 900.0)

	## 4) LOS BOTES DEL RÍO (7-10-2026). El velero tiene el mástil más alto
	## que los puentes de la ciudad grande: se queda amarrado en el puerto y
	## el río lo recorren botes de paseo, que pasan por debajo.
	var cauce := PackedVector3Array([
		Vector3(RIO_X - 14.0, 0.0, -1300.0), Vector3(RIO_X - 14.0, 0.0, 1300.0),
		Vector3(RIO_X + 14.0, 0.0, 1300.0), Vector3(RIO_X + 14.0, 0.0, -1300.0),
	])
	var id3 := t.agregar_ruta(_redondear(cauce, 13.0))
	for k in 3:
		t.agregar_vehiculo(_hacer_bote(k), id3, 2700.0 * float(k), 4.0, 0.15, 0.0)
	if expansion != null:
		expansion.trafico(t, coches, rng)

func _banderas_anillo(c1: Color, c2: Color) -> void:
	if _anillo_con_banderas:
		return
	_anillo_con_banderas = true
	for i in 28:
		var t := float(i) / 28.0
		var x := lerpf(-RING_X, RING_X, t)
		for z in [RING_Z_NORTE + ANCHO_CALLE, RING_Z_SUR - ANCHO_CALLE]:
			var mastil := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.2, 9.0, 0.2)
			mastil.mesh = bm
			var gris := StandardMaterial3D.new()
			gris.albedo_color = Color(0.7, 0.7, 0.72)
			mastil.material_override = gris
			mastil.position = Vector3(x, 4.5, z)
			add_child(mastil)
			StadiumBuilder._bandera_ondeante(self, Vector3(x + 1.3, 7.6, z), Vector2(2.6, 1.6),
				c1 if i % 2 == 0 else c2, 0.0, float(i) * 0.7)

static func _mallas_hincha_de_pie() -> Array:
	if not _piezas_hincha.is_empty():
		return _piezas_hincha
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	## Piernas.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pierna := CapsuleMesh.new()
	pierna.radius = 0.085
	pierna.height = 0.9
	pierna.radial_segments = 6
	pierna.rings = 1
	for lado in [-1.0, 1.0]:
		st.append_from(pierna, 0, Transform3D(Basis(), Vector3(0.1 * lado, 0.45, 0)))
	var cadera := CylinderMesh.new()
	cadera.top_radius = 0.17
	cadera.bottom_radius = 0.16
	cadera.height = 0.16
	cadera.radial_segments = 7
	cadera.rings = 1
	st.append_from(cadera, 0, Transform3D(Basis().scaled(Vector3(1, 1, 0.72)), Vector3(0, 0.86, 0)))
	st.generate_normals()
	var piernas := st.commit()
	## Torso y brazos.
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var torso := CylinderMesh.new()
	torso.top_radius = 0.2
	torso.bottom_radius = 0.17
	torso.height = 0.58
	torso.radial_segments = 7
	torso.rings = 1
	st.append_from(torso, 0, Transform3D(Basis().scaled(Vector3(1, 1, 0.7)), Vector3(0, 1.21, 0)))
	var brazo := CapsuleMesh.new()
	brazo.radius = 0.055
	brazo.height = 0.62
	brazo.radial_segments = 5
	brazo.rings = 1
	for lado in [-1.0, 1.0]:
		st.append_from(brazo, 0, Transform3D(Basis(Vector3(0, 0, 1), 0.08 * lado), Vector3(0.25 * lado, 1.17, 0)))
	st.generate_normals()
	var camiseta := st.commit()
	## Cuello y cabeza.
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cuello := CylinderMesh.new()
	cuello.top_radius = 0.05
	cuello.bottom_radius = 0.055
	cuello.height = 0.1
	cuello.radial_segments = 5
	cuello.rings = 1
	st.append_from(cuello, 0, Transform3D(Basis(), Vector3(0, 1.54, 0)))
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.11
	cabeza.height = 0.25
	cabeza.radial_segments = 8
	cabeza.rings = 5
	st.append_from(cabeza, 0, Transform3D(Basis(), Vector3(0, 1.67, 0)))
	st.generate_normals()
	var piel := st.commit()
	for m: Mesh in [piernas, camiseta, piel]:
		m.surface_set_material(0, mat)
	_piezas_hincha = [piernas, camiseta, piel]
	return _piezas_hincha

func _en_huella(p: Vector3) -> bool:
	for r: Rect2 in huellas:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false
