extends "res://visor/ciudad_expansion_p5.gd"
## (Parte 6 de 9 de `ciudad_expansion.gd`.)

## LA SALA DE RECREATIVOS: un edificio modular de dos plantas en el noreste,
## mirando al paseo central (al oeste), con rótulo de neón; con E en la puerta se
## entra (sala «recreativos» de `InteriorInstalacion`).
func _recreativos(c: Vector3, r: Rect2) -> void:
	var nombre := "Recreativos Galaxia"
	var frente := Vector3(c.x + 9.5, 0.12, r.position.y + 20.0)
	var puerta := _bloque_modular(frente, -PI * 0.5, 77, 4.0 * ESC_MOD, 3.0 * ESC_MOD,
		{"w": 4, "d": 3, "pisos": 2, "tienda": true, "color": [Color(0.42, 0.3, 0.6), Color(0.95, 0.9, 0.98)]})
	## Huella maciza (no se atraviesa a pie).
	b.huellas.append(Rect2(frente.x, frente.z - 2.0 * ESC_MOD, 3.0 * ESC_MOD, 4.0 * ESC_MOD))
	## Rótulo de neón sobre la puerta y marquesina.
	var neon := b._mat_simple(Color(1.0, 0.3, 0.8), 0.4, 2.2)
	var placa := b._caja_en(Vector3(frente.x - 0.25, PISO_MOD * 2.0 - 0.6, puerta.z), Vector3(0.2, 1.1, 9.0), b._mat_simple(Color(0.1, 0.08, 0.16), 0.5))
	placa.name = "RotuloRecreativos"
	b._caja_en(Vector3(frente.x - 0.36, PISO_MOD * 2.0 - 0.02, puerta.z), Vector3(0.06, 0.07, 9.0), neon)
	b._caja_en(Vector3(frente.x - 0.36, PISO_MOD * 2.0 - 1.18, puerta.z), Vector3(0.06, 0.07, 9.0), neon)
	var l := Label3D.new()
	l.text = "🕹️ " + nombre
	l.font_size = 64
	l.pixel_size = 0.012
	l.modulate = Color(1.0, 0.75, 0.95)
	l.outline_size = 10
	l.outline_modulate = Color(0.45, 0.05, 0.35)
	l.position = Vector3(frente.x - 0.4, PISO_MOD * 2.0 - 0.6, puerta.z)
	l.rotation.y = -PI * 0.5
	l.visibility_range_end = 160.0
	b.add_child(l)
	b.puntos_clic.append({"k": "edificio_recreativos|" + nombre, "n": nombre,
		"pos": Vector3(puerta.x - 2.6, 0, puerta.z), "estado": "ciudad", "radio": 6.0})
	feria["recreativos"] = puerta

## Puestos a los dos lados del paseo central, mirando al paseo, y los aseos.
func _puestos_feria(c: Vector3) -> void:
	var surtido := ["stall-food", "stall-drinks", "stall-food", "stall-drinks", "stall-information", "stall-food"]
	var h := absi(hash(Vector2(c.x, c.z)))
	var k := 0
	for z: float in [-1.0, 5.5]:
		for sx: float in [-1.0, 1.0]:
			var ruta := RUTA_FERIA + "%s.glb" % surtido[(h + k) % surtido.size()]
			## El mostrador del modelo mira a −Z: −π/2 lo vuelve hacia +X.
			_pieza_kit(ruta, c + Vector3(sx * 7.8, 0.12, z), _escala_ancho(ruta, 3.4), -PI * 0.5 * -sx)
			k += 1
	var ruta_a := RUTA_FERIA + "stall-toilets.glb"
	_pieza_kit(ruta_a, c + Vector3(30.0, 0.12, -1.0), _escala_ancho(ruta_a, 3.6), PI * 0.5)
	## Mesas con sombrilla entre los puestos (como las terrazas de la ciudad).
	var tela := [Color(0.85, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.5, 0.85), Color(0.25, 0.65, 0.35)]
	var palos: Array[Transform3D] = []
	var lonas: Array[Transform3D] = []
	var lonas_c: Array[Color] = []
	var mesas: Array[Transform3D] = []
	for q in 4:
		var p := c + Vector3(-14.0 + float(q % 2) * 28.0, 0.12, -1.0 + float(q / 2) * 7.0)
		palos.append(Transform3D(Basis.from_scale(Vector3(0.06, 2.4, 0.06)), p + Vector3(0, 1.2, 0)))
		lonas.append(Transform3D(Basis.from_scale(Vector3(2.6, 0.5, 2.6)), p + Vector3(0, 2.45, 0)))
		lonas_c.append(tela[(h + q) % tela.size()])
		mesas.append(Transform3D(Basis.from_scale(Vector3(1.0, 0.06, 1.0)), p + Vector3(0, 0.74, 0)))
	_multimesh(CylinderMesh.new(), _mat_det("feria_mastil", Color(0.85, 0.85, 0.86), 0.4), palos, Vector3.ONE)
	var cono := CylinderMesh.new()
	cono.top_radius = 0.0
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 8
	_multimesh(cono, null, lonas, Vector3.ONE, lonas_c)
	_multimesh(CylinderMesh.new(), _mat_det("feria_mesa", Color(0.95, 0.95, 0.93), 0.5), mesas, Vector3.ONE)

## La estación: andén cubierto junto a la recta baja, con escalera, valla y la
## cola con sus vallas del kit.
func _estacion_rusa(origen: Vector3, base: Basis, e: float) -> void:
	## La recta de la estación va de (−8, 0, 4) a (−8, 0, 0) en unidades del kit.
	var a := origen + base * (Vector3(-8.0, 0, 4.0) * e)
	var c2 := origen + base * (Vector3(-8.0, 0, 0.0) * e)
	var mitad := (a + c2) * 0.5
	var largo := a.distance_to(c2)
	## Andén por dentro del óvalo (hacia el norte en el mundo).
	var anden := Vector3(mitad.x, 0, mitad.z - 2.6)
	var piedra := _mat_det("rusa_anden", Color(0.62, 0.58, 0.54), 0.85)
	b._caja_en(Vector3(anden.x, BASE_RUSA * 0.5, anden.z), Vector3(largo, BASE_RUSA, 3.2), piedra)
	b.huellas.append(Rect2(anden.x - largo * 0.5, anden.z - 1.6, largo, 3.2))
	var techo := _mat_det("rusa_techo", Color(0.15, 0.4, 0.75), 0.5)
	var poste := _mat_det("rusa_poste", Color(0.9, 0.9, 0.92), 0.4)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b._cil_en(Vector3(anden.x + sx * (largo * 0.5 - 0.6), BASE_RUSA + 1.7, anden.z + sz * 1.3 + 1.0), 0.12, 3.4, poste)
	b._caja_en(Vector3(anden.x, BASE_RUSA + 3.5, anden.z + 1.0), Vector3(largo + 1.0, 0.25, 6.4), techo)
	b._caja_en(Vector3(anden.x, BASE_RUSA + 3.75, anden.z + 1.0), Vector3(largo + 1.4, 0.25, 0.4), _mat_det("rusa_cenefa", Color(0.98, 0.8, 0.2), 0.5))
	## Escalera de subida desde el paseo (al norte del andén).
	for k in 4:
		var alto := BASE_RUSA * float(k + 1) / 4.0
		b._caja_en(Vector3(anden.x - largo * 0.25, alto * 0.5, anden.z - 1.6 - 0.35 - float(3 - k) * 0.4), Vector3(3.0, alto, 0.4), piedra)
	var ruta_q := RUTA_FERIA + "ride-entrance.glb"
	_pieza_kit(ruta_q, Vector3(anden.x - largo * 0.25, 0.12, anden.z - 4.6), _escala_ancho(ruta_q, 3.0), PI)
	var ruta_v := RUTA_FERIA + "queue-straight.glb"
	for k in 3:
		_pieza_kit(ruta_v, Vector3(anden.x - largo * 0.25 + 3.0 + float(k) * 2.5, 0.12, anden.z - 4.6), 2.5, PI * 0.5)
	b._rotulo(Vector3(anden.x, BASE_RUSA + 5.2, anden.z), "🎢 Montaña rusa", Color(1.0, 0.9, 0.5), 18)
	feria["estacion"] = anden

## Punto y orientación (mirando hacia donde avanza) a `s` metros del recorrido.
static func _en_recorrido(pts: PackedVector3Array, acum: PackedFloat32Array, s: float) -> Array:
	var i := acum.bsearch(s) - 1
	i = clampi(i, 0, pts.size() - 2)
	var largo := maxf(acum[i + 1] - acum[i], 0.001)
	var f := clampf((s - acum[i]) / largo, 0.0, 1.0)
	var p := pts[i].lerp(pts[i + 1], f)
	var d := (pts[i + 1] - pts[i]).normalized()
	if d.length() < 0.5:
		d = Vector3(0, 0, 1)
	var q := Basis.looking_at(-d, Vector3.UP).get_rotation_quaternion()
	return [p, q]

## El tren: tres vagones que recorren el circuito, despacio en la cuesta de
## subida (la cadena) y más rápido según bajan (v² = v0² + 2·g·caída). Las
## claves salen de simular el recorrido; cada vagón va a su distancia del
## primero sobre la vía.
func _tren_rusa(origen: Vector3, base: Basis, e: float, camino: Array) -> void:
	var raiz := Node3D.new()
	raiz.name = "TrenRusa"
	raiz.add_to_group("feria_animada")
	b.add_child(raiz)
	## Recorrido en el mundo, con su distancia acumulada.
	var pts := PackedVector3Array()
	var tipo := PackedFloat32Array()
	for q: Array in camino:
		pts.append(origen + base * ((q[0] as Vector3) * e) + Vector3(0, 0.3 * e - 0.15, 0))
		tipo.append(float(q[2]))
	pts.append(pts[0])
	tipo.append(tipo[0])
	var acum := PackedFloat32Array([0.0])
	for i in range(1, pts.size()):
		acum.append(acum[i - 1] + pts[i].distance_to(pts[i - 1]))
	var total: float = acum[acum.size() - 1]
	var y_max := 0.0
	for p in pts:
		y_max = maxf(y_max, p.y)
	var vagones := ["coaster-train-front", "coaster-train", "coaster-train"]
	var nodos: Array[Node3D] = []
	for k in vagones.size():
		var kv := _malla_kit(RUTA_FERIA + vagones[k] + ".glb")
		if kv.is_empty():
			return
		var n := Node3D.new()
		n.name = "Vagon%d" % k
		raiz.add_child(n)
		var mi := MeshInstance3D.new()
		mi.mesh = kv["malla"]
		mi.scale = Vector3.ONE * e
		n.add_child(mi)
		nodos.append(n)
	## Simulación: la distancia del primer vagón en cada instante.
	var dt := 0.1
	var s := 0.0
	var tiempos: Array[float] = [0.0]
	var distancias: Array[float] = [0.0]
	var t := 0.0
	var i_seg := 0
	while s < total and t < 200.0:
		while i_seg < acum.size() - 2 and acum[i_seg + 1] < s:
			i_seg += 1
		var y := pts[i_seg].y
		var v := 3.0 if tipo[i_seg] > 0.5 else 4.0 + sqrt(maxf(2.0 * 9.8 * (y_max - y), 0.0)) * 0.8
		s += v * dt
		t += dt
		tiempos.append(t)
		distancias.append(minf(s, total))
	var largo_anim := t
	var anim := Animation.new()
	anim.length = largo_anim
	anim.loop_mode = Animation.LOOP_LINEAR
	var hueco := 1.45 * e
	for k in nodos.size():
		var tp := anim.add_track(Animation.TYPE_POSITION_3D)
		var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tp, NodePath("Vagon%d" % k))
		anim.track_set_path(tr, NodePath("Vagon%d" % k))
		for j in tiempos.size():
			var sk := fposmod(distancias[j] - float(k) * hueco, total)
			if j == tiempos.size() - 1:
				sk = fposmod(-float(k) * hueco, total)
			var punto := _en_recorrido(pts, acum, sk)
			anim.position_track_insert_key(tp, tiempos[j], punto[0])
			anim.rotation_track_insert_key(tr, tiempos[j], punto[1])
	_animar(raiz, anim, "vueltas")
	feria["vuelta_rusa"] = largo_anim
	feria["largo_rusa"] = total

func _montana_rusa(o: Vector3) -> void:
	var e := ESC_RUSA
	## El kit va hacia +Z; el circuito, hacia +X del mundo: giro de +π/2.
	var base := Basis(Vector3.UP, PI * 0.5)
	var origen := o + Vector3(0, BASE_RUSA, 0)
	var piezas := {}    ## ruta -> Array[Transform3D]
	var pilares: Array[Transform3D] = []
	var pos := Vector3.ZERO
	var rumbo := 0.0
	var h := 0.0
	var camino: Array = []    ## [punto (local, en unidades), rumbo] cada poco, para el tren
	for seg: String in CIRCUITO_RUSA:
		var dir := Vector3(sin(rumbo), 0, cos(rumbo))
		var ruta := RUTA_FERIA + "coaster-steel-straight.glb"
		var t_local := Transform3D(Basis(Vector3.UP, rumbo), pos + Vector3(0, h, 0))
		var pasos := 8
		match seg:
			"recta":
				for q in pasos:
					camino.append([pos + dir * (4.0 * float(q) / float(pasos)) + Vector3(0, h, 0), rumbo, 0.0])
				pos += dir * 4.0
			"sube":
				ruta = RUTA_FERIA + "coaster-steel-straight-hill-complete.glb"
				for q in pasos:
					var f := float(q) / float(pasos)
					camino.append([pos + dir * (4.0 * f) + Vector3(0, h + smoothstep(0.0, 1.0, f), 0), rumbo, 1.0])
				pos += dir * 4.0
				h += 1.0
			"baja":
				ruta = RUTA_FERIA + "coaster-steel-straight-hill-complete.glb"
				var fin := pos + dir * 4.0
				t_local = Transform3D(Basis(Vector3.UP, rumbo + PI), fin + Vector3(0, h - 1.0, 0))
				for q in pasos:
					var f := float(q) / float(pasos)
					camino.append([pos + dir * (4.0 * f) + Vector3(0, h - smoothstep(0.0, 1.0, f), 0), rumbo, -1.0])
				pos = fin
				h -= 1.0
			"curva":
				ruta = RUTA_FERIA + "coaster-steel-corner-large.glb"
				var bas := Basis(Vector3.UP, rumbo)
				var centro := pos + bas * Vector3(-4.0, 0, 0)
				for q in pasos * 2:
					var th := PI * 0.5 * float(q) / float(pasos * 2)
					camino.append([centro + bas * Vector3(4.0 * cos(th), 0, 4.0 * sin(th)) + Vector3(0, h, 0), rumbo - th, 0.0])
				pos = centro + bas * Vector3(0, 0, 4.0)
				rumbo -= PI * 0.5
		if not piezas.has(ruta):
			piezas[ruta] = [] as Array[Transform3D]
		var t_mundo := Transform3D(base * t_local.basis * Basis.from_scale(Vector3.ONE * e), origen + base * (t_local.origin * e))
		(piezas[ruta] as Array[Transform3D]).append(t_mundo)
	feria["cierre_rusa"] = pos.length()    ## 0 si el circuito cierra
	## Pilares bajo la vía: uno cada ~6 m de recorrido, de la vía al suelo.
	for k in range(0, camino.size(), 4):
		var q: Vector3 = (camino[k] as Array)[0]
		var pm := origen + base * (q * e)
		var alto := pm.y - 0.15
		## Sobre el paseo central la vía pasa alta y sin pilar (el paseo sigue).
		var sobre_paseo := absf(pm.x - (feria["centro"] as Vector3).x) < 4.5
		if alto > 0.4 and not sobre_paseo:
			pilares.append(Transform3D(Basis.from_scale(Vector3(2.4, alto, 2.4)), Vector3(pm.x, 0.0, pm.z)))
	for ruta: String in piezas:
		var k := _malla_kit(ruta)
		if k.is_empty():
			return
		var lista: Array[Transform3D] = []
		lista.assign(piezas[ruta])
		_multimesh(k["malla"], null, lista, Vector3.ONE)
	var kp := _malla_kit(RUTA_FERIA + "support-large.glb")
	if not kp.is_empty():
		_multimesh(kp["malla"], null, pilares, Vector3.ONE)
	feria["pilares_rusa"] = pilares.size()
	_estacion_rusa(origen, base, e)
	_tren_rusa(origen, base, e, camino)

## Guirnaldas de bombillas sobre el paseo central (se encienden de noche).
func _guirnaldas_feria(c: Vector3, r: Rect2) -> void:
	var colores := [Color(1, 0.35, 0.3), Color(1, 0.85, 0.3), Color(0.35, 0.8, 1), Color(1, 0.5, 0.9)]
	var por_color: Array = [[] as Array[Transform3D], [] as Array[Transform3D], [] as Array[Transform3D], [] as Array[Transform3D]]
	var cables: Array[Transform3D] = []
	var postes: Array[Transform3D] = []
	var z := r.position.y + 12.0
	while z < c.z + 10.0:
		var e0 := Vector3(c.x - 4.6, 0, z)
		var e1 := Vector3(c.x + 4.6, 0, z)
		var prev := Vector3.ZERO
		for s in 10:
			var f := float(s) / 9.0
			var pos := e0.lerp(e1, f) + Vector3(0, 5.4 - 0.9 * sin(f * PI), 0)
			if s > 0:
				cables.append(_tramo_cable(prev, pos, 0.02))
			prev = pos
			(por_color[s % colores.size()] as Array).append(Transform3D(Basis.from_scale(Vector3.ONE * 0.22), pos - Vector3(0, 0.14, 0)))
		for e: Vector3 in [e0, e1]:
			postes.append(Transform3D(Basis.from_scale(Vector3(0.08, 5.6, 0.08)), e + Vector3(0, 2.8, 0)))
		z += 7.0
	for k in colores.size():
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colores[k]
		mat.emission_enabled = true
		mat.emission = colores[k]
		mat.emission_energy_multiplier = 0.2
		_bombillas.append(mat)
		var esf := SphereMesh.new()
		esf.radial_segments = 6
		esf.rings = 3
		var lista: Array[Transform3D] = []
		lista.assign(por_color[k])
		_multimesh(esf, mat, lista, Vector3.ONE)
	var oscuro := _mat_det("feria_cable", Color(0.12, 0.12, 0.13), 0.6)
	_multimesh(CylinderMesh.new(), oscuro, cables, Vector3.ONE)
	_multimesh(CylinderMesh.new(), oscuro, postes, Vector3.ONE)

## Árboles, bancos, papeleras y parterres del kit, lejos de los caminos.
func _jardines_feria(c: Vector3, r: Rect2) -> void:
	var hx := r.size.x * 0.5
	var hz := r.size.y * 0.5
	var arboles := [Vector3(-hx + 4.0, 0, -hz + 6.0), Vector3(-hx + 4.0, 0, 2.0), Vector3(hx - 4.0, 0, 6.0),
		Vector3(hx - 4.0, 0, -hz + 6.0), Vector3(-15.5, 0, -hz + 5.0), Vector3(15.5, 0, -hz + 4.5),
		Vector3(-hx + 4.0, 0, 9.0), Vector3(hx - 4.5, 0, 10.0), Vector3(-24.0, 0, 4.0)]
	for k in arboles.size():
		var ruta := RUTA_FERIA + ("tree-large.glb" if k % 3 == 0 else "tree.glb")
		_pieza_kit(ruta, c + (arboles[k] as Vector3) + Vector3(0, 0.1, 0), 4.2 if k % 3 == 0 else 5.0, float(k) * 1.3)
	var ruta_b := RUTA_FERIA + "bench.glb"
	var ruta_p := RUTA_FERIA + "trash.glb"
	var ruta_f := RUTA_FERIA + "flowers.glb"
	## Bancos a los dos lados del paseo, entre los postes de las guirnaldas,
	## mirando al paseo (el frente del banco es +Z, al revés que los puestos).
	for z: float in [-26.0, -19.0]:
		for sx: float in [-1.0, 1.0]:
			_pieza_kit(ruta_b, c + Vector3(sx * 5.0, 0.12, z), _escala_ancho(ruta_b, 1.9), -PI * 0.5 * sx)
	for sx: float in [-1.0, 1.0]:
		_pieza_kit(ruta_p, c + Vector3(sx * 4.6, 0.12, -hz + 8.0), 2.2, 0.0)
		for q in 2:
			_pieza_kit(ruta_f, c + Vector3(sx * (14.5 + float(q) * 3.0), 0.12, -hz + 9.0), 3.0, float(q))

func _feria(r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var hx := r.size.x * 0.5
	var hz := r.size.y * 0.5
	feria = {"rect": r, "centro": c}
	## Suelo: césped, paseo central norte-sur, paseo este-oeste y la explanada
	## de la entrada.
	_lote("cesped", Vector3(c.x, 0.05, c.z), Vector3(r.size.x, 0.1, r.size.y))
	_lote("acera", Vector3(c.x, 0.11, c.z - 4.0), Vector3(7.0, 0.1, r.size.y - 8.0))
	_lote("acera", Vector3(c.x, 0.11, c.z - 8.0), Vector3(r.size.x - 8.0, 0.1, 6.0))
	_lote("acera", Vector3(c.x, 0.11, r.position.y + 7.0), Vector3(24.0, 0.1, 14.0))
	_lote("acera", Vector3(c.x, 0.11, c.z + 26.0), Vector3(40.0, 0.1, 24.0))
	_valla_feria(r)
	## El pórtico de entrada, la taquilla y los mástiles con los colores del club.
	var puerta := Vector3(c.x, 0.12, r.position.y + 2.2)
	var ruta_e := RUTA_FERIA + "park-entrance.glb"
	_pieza_kit(ruta_e, puerta, _escala_ancho(ruta_e, 9.0), 0.0)
	var ruta_i := RUTA_FERIA + "stall-information.glb"
	_pieza_kit(ruta_i, Vector3(c.x + 8.5, 0.12, r.position.y + 5.0), _escala_ancho(ruta_i, 3.2), -PI * 0.5)
	var tex_franjas := _franjas_club()
	for sx: float in [-1.0, 1.0]:
		var mastil := Vector3(c.x + sx * 6.5, 0, r.position.y + 1.5)
		b._cil_en(mastil + Vector3(0, 4.0, 0), 0.08, 8.0, _mat_det("feria_mastil", Color(0.85, 0.85, 0.86), 0.4))
		## (16-10-2026) Antes, una caja plana de 1,4 × 0,9 m de un solo color del
		## club: con un club de negro, la del mástil derecho era un CUADRADO NEGRO
		## flotando junto a la noria. Ahora es una bandera de tela que ondea, con
		## las tres franjas del club (el color claro fuera, el oscuro en medio).
		var bnd := StadiumBuilder._bandera_ondeante(b, mastil + Vector3(0, 7.4, 0), Vector2(1.6, 1.0),
			Color.WHITE, 0.0 if sx > 0.0 else PI, 0.4 if sx > 0.0 else 1.3)
		var mb := bnd.material_override as ShaderMaterial
		mb.set_shader_parameter("dibujo", tex_franjas)
		mb.set_shader_parameter("usa_dibujo", true)
		mb.set_shader_parameter("espejo", sx < 0.0)
	b._rotulo(Vector3(c.x, 30.0, c.z), "🎡 Parque de atracciones", Color(1.0, 0.85, 0.55), 22)
	feria["puerta"] = puerta
	_noria(c + Vector3(-hx * 0.55, 0, -hz * 0.42))
	_recreativos(c, r)
	_puestos_feria(c)
	_montana_rusa(c + Vector3(-18.0, 0, 14.0))
	_guirnaldas_feria(c, r)
	_jardines_feria(c, r)
	cuenta["instalaciones"] = int(cuenta.get("instalaciones", 0)) + 1

## Todo el cuerpo en bronce y quieto (sin animación: es una estatua).
func _bronce(n: Node, m: Material) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = m
	if n is AnimationPlayer:
		(n as AnimationPlayer).seek(0.35, true)
		(n as AnimationPlayer).speed_scale = 0.0
	for h in n.get_children():
		_bronce(h, m)

## LA ESTATUA DEL ÍDOLO (originalidad): en la Plaza Mayor, un futbolista de
## bronce de 5 m sobre su pedestal, con la placa del ídolo del club (su última
## leyenda, o su capitán). Cambia con la historia de tu partida.
func _estatua_idolo(p: Vector3) -> void:
	var nombre := String(b.datos.get("idolo", ""))
	b._caja_en(p + Vector3(0, 1.5, 0), Vector3(5.0, 3.0, 5.0), _mat["piedra"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(nombre)
	## Un cuerpo de futbolista sin ropa aparte ni pelo: en bronce no se ven, y
	## el peatón completo (prendas en mallas sueltas) hacía que el motor avisara
	## «material is null» al reconstruir la ciudad.
	var d := FutbolistaQ.crear(1.8, "male")
	if not d.is_empty():
		var n: Node3D = d["nodo"]
		b.add_child(n)
		FutbolistaQ.terminar(d, false)
		if (d["anim"] as AnimationPlayer).has_animation("celebrar"):
			(d["anim"] as AnimationPlayer).play("celebrar")
		elif (d["anim"] as AnimationPlayer).has_animation("parado"):
			(d["anim"] as AnimationPlayer).play("parado")
		n.position = p + Vector3(0, 3.0, 0)
		n.scale = Vector3.ONE * 2.9
		n.rotation.y = 0.0
		var bronce := StandardMaterial3D.new()
		bronce.albedo_color = Color(0.55, 0.38, 0.2)
		bronce.metallic = 0.85
		bronce.roughness = 0.35
		_bronce(n, bronce)
	if nombre != "":
		var l := Label3D.new()
		l.text = "A %s\nídolo de %s" % [nombre, String(b.datos.get("club", {}).get("nombre", ""))]
		l.font_size = 48
		l.pixel_size = 0.02
		l.modulate = Color(0.95, 0.85, 0.55)
		l.outline_size = 6
		l.position = p + Vector3(0, 1.6, 2.6)
		b.add_child(l)
	cuenta["estatua"] = nombre

## UN MURAL DEL CLUB en una medianera: franjas de sus colores y su nombre.
func _mural(p: Vector3, giro: float) -> void:
	var c1 := b._color_club("c1", Color(0.2, 0.5, 0.3))
	var c2 := b._color_club("c2", Color(1, 1, 1))
	var muro := b._caja_en(p + Vector3(0, 9.0, 0), Vector3(1.0, 18.0, 30.0), _mat["claro"], giro)
	muro.rotation.y = 0.0
	for k in 5:
		var franja := b._caja_en(p + Vector3(0.55, 3.0 + float(k) * 3.4, 0), Vector3(0.1, 2.6, 28.0), b._mat_simple(c1 if k % 2 == 0 else c2, 0.7))
		franja.rotation.x = 0.18
	var l := Label3D.new()
	l.text = String(b.datos.get("club", {}).get("nombre", "")).to_upper()
	l.font_size = 96
	l.pixel_size = 0.05
	l.modulate = Color.WHITE
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0, 0.8)
	l.position = p + Vector3(0.7, 15.0, 0)
	l.rotation.y = PI * 0.5
	b.add_child(l)
