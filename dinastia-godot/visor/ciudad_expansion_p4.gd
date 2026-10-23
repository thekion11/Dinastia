extends "res://visor/ciudad_expansion_p3.gd"
## [Capa 4/9 de `ciudad_expansion.gd`] _detalles_parque, _parque, _acera_bloque, _caja_det, _detalle_edificio, _kit … (+10)

## LOS DETALLES DEL PARQUE (7-10-2026): el portón con su nombre, una fuente
## en la cruz de los caminos, parterres de flores, bancos y farolas a lo largo
## de los paseos y una zona de juegos (columpios, tobogán y arenero).
func _detalles_parque(r: Rect2, c: Vector3, nombre: String, lago: bool) -> void:
	var piedra: Material = _mat["piedra"] if _mat.has("piedra") else b._mat_simple(Color(0.75, 0.72, 0.66), 0.8)
	var hierro := b._mat_simple(Color(0.12, 0.13, 0.12), 0.5)
	## El portón de entrada (lado sur) con el nombre.
	var puerta := c + Vector3(0, 0, r.size.y * 0.5 - 1.5)
	for lado: float in [-1.0, 1.0]:
		b._caja_en(puerta + Vector3(lado * 3.2, 1.8, 0), Vector3(0.7, 3.6, 0.7), piedra)
	b._caja_en(puerta + Vector3(0, 3.9, 0), Vector3(7.4, 0.7, 0.5), hierro)
	for cara: float in [1.0, -1.0]:
		var l := Label3D.new()
		l.text = nombre
		l.font_size = 48
		l.pixel_size = 0.009
		l.modulate = Color(0.95, 0.88, 0.6)
		l.outline_size = 8
		l.outline_modulate = Color(0.1, 0.12, 0.1)
		l.position = puerta + Vector3(0, 3.9, 0.3 * cara)
		l.rotation.y = 0.0 if cara > 0.0 else PI
		l.visibility_range_end = 160.0
		b.add_child(l)
	## La fuente en el cruce (si no hay lago ocupando el centro).
	if not lago:
		b._cil_en(c + Vector3(0, 0.45, 0), 3.0, 0.9, piedra)
		b._cil_en(c + Vector3(0, 0.88, 0), 2.7, 0.08, _mat["agua"])
		b._cil_en(c + Vector3(0, 1.6, 0), 0.3, 2.2, piedra)
		b._cil_en(c + Vector3(0, 2.8, 0), 1.1, 0.2, piedra)
	## Parterres de flores en las cuatro esquinas de la cruz.
	var flores: Array[Transform3D] = []
	var flores_col: Array[Color] = []
	var paleta := [Color(0.9, 0.2, 0.3), Color(0.98, 0.8, 0.2), Color(0.6, 0.3, 0.8), Color(1.0, 0.55, 0.7), Color(1, 1, 1)]
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var q := c + Vector3(sx * 7.0, 0, sz * 7.0)
			b._caja_en(q + Vector3(0, 0.2, 0), Vector3(5.0, 0.4, 5.0), b._mat_simple(Color(0.35, 0.25, 0.18), 0.9))
			for k in 12:
				flores.append(Transform3D(Basis.from_scale(Vector3(0.5, 0.45, 0.5)), q + Vector3(_rng.randf_range(-2.1, 2.1), 0.55, _rng.randf_range(-2.1, 2.1))))
				flores_col.append(paleta[_rng.randi() % paleta.size()])
	var esf := SphereMesh.new()
	esf.radial_segments = 8
	esf.rings = 4
	_multimesh(esf, null, flores, Vector3.ONE, flores_col)
	## Bancos y farolas a lo largo de los paseos.
	var bancos: Array[Transform3D] = []
	var faroles: Array[Transform3D] = []
	var globos: Array[Transform3D] = []
	for k in 6:
		var u := (float(k) - 2.5) / 6.0
		for paseo in 2:
			var pp := c + (Vector3(u * r.size.x, 0, 3.4) if paseo == 0 else Vector3(3.4, 0, u * r.size.y))
			if absf(u) < 0.12:
				continue
			bancos.append(Transform3D(Basis(Vector3.UP, 0.0 if paseo == 0 else PI * 0.5) * Basis.from_scale(Vector3(1.9, 0.5, 0.6)), pp + Vector3(0, 0.5, 0)))
			if k % 2 == 0:
				var pf := pp - (Vector3(0, 0, 6.8) if paseo == 0 else Vector3(6.8, 0, 0))
				faroles.append(Transform3D(Basis.from_scale(Vector3(0.12, 3.6, 0.12)), pf + Vector3(0, 1.8, 0)))
				globos.append(Transform3D(Basis.from_scale(Vector3(0.5, 0.5, 0.5)), pf + Vector3(0, 3.8, 0)))
	_multimesh(BoxMesh.new(), _mat["tronco"], bancos, Vector3.ONE)
	var cil := CylinderMesh.new()
	cil.height = 1.0
	cil.top_radius = 0.5
	cil.bottom_radius = 0.5
	_multimesh(cil, hierro, faroles, Vector3.ONE)
	_multimesh(SphereMesh.new(), b._mat_simple(Color(1.0, 0.95, 0.8), 0.3, 0.8), globos, Vector3.ONE)
	## La zona de juegos: arenero, columpios y tobogán.
	var zj := c + Vector3(-r.size.x * 0.27, 0, -r.size.y * 0.27)
	if lago:
		zj = c + Vector3(-r.size.x * 0.27, 0, r.size.y * 0.27)
	## Puestos de la feria (15-10-2026, kit de la montaña rusa de Kenney): comida,
	## bebidas e información en fila junto al paseo, en el cuadrante opuesto a
	## los juegos y mirando al camino. El surtido sale de la posición del parque.
	var lado_p := -1.0 if lago else 1.0
	var surtido := ["stall-food", "stall-drinks", "stall-information", "stall-food", "stall-drinks"]
	var hp := absi(hash(Vector2(c.x, c.z)))
	for k in 3:
		var ruta_p := "res://assets/kenney/montana_rusa/%s.glb" % surtido[(hp + k) % surtido.size()]
		var pp := c + Vector3(r.size.x * (0.17 + 0.09 * float(k)), 0.12, -lado_p * 8.5)
		_pieza_kit(ruta_p, pp, _escala_ancho(ruta_p, 3.2), GIRO_PUESTO if lado_p > 0.0 else GIRO_PUESTO + PI)
	b._caja_en(zj + Vector3(0, 0.12, 0), Vector3(14.0, 0.24, 10.0), b._mat_simple(Color(0.86, 0.78, 0.58), 0.95))
	var rojo := b._mat_simple(Color(0.85, 0.2, 0.15), 0.5)
	var amarillo := b._mat_simple(Color(0.98, 0.8, 0.15), 0.5)
	var azul := b._mat_simple(Color(0.2, 0.45, 0.85), 0.5)
	## Columpios: pórtico en A y dos asientos.
	for lado: float in [-1.0, 1.0]:
		var pa := b._caja_en(zj + Vector3(-3.5 + lado * 1.8, 1.4, -2.5), Vector3(0.14, 3.0, 0.14), rojo)
		pa.rotation.z = lado * 0.18
	b._caja_en(zj + Vector3(-3.5, 2.85, -2.5), Vector3(3.8, 0.14, 0.14), rojo)
	for k: float in [-0.7, 0.7]:
		b._caja_en(zj + Vector3(-3.5 + k, 1.75, -2.5), Vector3(0.03, 2.2, 0.03), hierro)
		b._caja_en(zj + Vector3(-3.5 + k, 0.65, -2.5), Vector3(0.5, 0.06, 0.25), azul)
	## Tobogán: escalera, plataforma y la rampa.
	b._caja_en(zj + Vector3(3.0, 1.0, 1.5), Vector3(1.0, 2.0, 1.0), amarillo)
	b._caja_en(zj + Vector3(3.0, 2.05, 1.5), Vector3(1.3, 0.1, 1.3), azul)
	var rampa := b._caja_en(zj + Vector3(3.0, 1.05, -0.4), Vector3(0.8, 0.08, 3.0), rojo)
	rampa.rotation.x = -0.62
	## Un balancín.
	var bal := b._caja_en(zj + Vector3(0.5, 0.55, 2.8), Vector3(3.0, 0.12, 0.3), amarillo)
	bal.rotation.z = 0.15
	b._caja_en(zj + Vector3(0.5, 0.3, 2.8), Vector3(0.3, 0.5, 0.3), azul)

func _parque(r: Rect2, lago: bool) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	_lote("cesped", Vector3(c.x, 0.05, c.z), Vector3(r.size.x, 0.1, r.size.y))
	## Caminos en cruz.
	_lote("acera", Vector3(c.x, 0.1, c.z), Vector3(r.size.x, 0.1, 4.0))
	_lote("acera", Vector3(c.x, 0.1, c.z), Vector3(4.0, 0.1, r.size.y))
	if lago:
		var l := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = minf(r.size.x, r.size.y) * 0.3
		cm.bottom_radius = cm.top_radius
		cm.height = 0.2
		cm.radial_segments = 32
		l.mesh = cm
		l.material_override = _mat["agua"]
		l.position = c + Vector3(r.size.x * 0.18, 0.18, r.size.y * 0.18)
		l.scale = Vector3(1.4, 1, 1)
		b.add_child(l)
	var pts: Array = []
	for k in 40:
		var p := c + Vector3(_rng.randf_range(-0.46, 0.46) * r.size.x, 0, _rng.randf_range(-0.46, 0.46) * r.size.y)
		## Lejos de los paseos, los parterres y la zona de juegos.
		if absf(p.x - c.x) < 6.0 or absf(p.z - c.z) < 6.0 or (absf(p.x - c.x) < 11.0 and absf(p.z - c.z) < 11.0):
			continue
		if p.x < c.x - r.size.x * 0.1 and p.z < c.z - r.size.y * 0.1 and not lago:
			continue
		pts.append(p)
	_arboles_en(pts, 1.0)
	var nombre := "Parque del Lago" if lago else String(NOMBRES_PARQUE[absi(int(c.x * 7.0 + c.z * 13.0)) % NOMBRES_PARQUE.size()])
	_detalles_parque(r, c, nombre, lago)
	b._rotulo(c + Vector3(0, 14, 0), "🌳 " + nombre, Color(0.7, 1.0, 0.7), 20)
	b.puntos_clic.append({"k": "ciudad_parque_lago" if lago else "ciudad_parque", "n": "Parque · penales con los chicos", "pos": c, "estado": "ciudad"})

func _acera_bloque(r: Rect2) -> void:
	_lote("solar", Vector3(r.get_center().x, 0.12, r.get_center().y), Vector3(r.size.x, 0.24, r.size.y))

func _caja_det(centro: Vector3, tam: Vector3, giro: float, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = m
	mi.position = centro
	mi.rotation.y = giro
	b.add_child(mi)

func _detalle_edificio(n: Node3D, escala: Vector3, giro: float, pos: Vector3, azotea_plana: bool) -> void:
	var caja := b._caja_de(n)
	var tam := Vector3(caja.size.x * escala.x, caja.size.y * escala.y, caja.size.z * escala.z)
	if tam.y < 7.0 or tam.x < 4.0 or tam.z < 4.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pos)
	var rot := Basis(Vector3.UP, giro)
	var centro: Vector3 = pos + rot * Vector3(
		(caja.position.x + caja.size.x * 0.5) * escala.x, 0.0, (caja.position.z + caja.size.z * 0.5) * escala.z)
	var base_y := pos.y + caja.position.y * escala.y
	var techo_y := base_y + tam.y
	## Zócalo: más oscuro y áspero, como la base sucia de salpicaduras.
	_caja_det(Vector3(centro.x, base_y + 0.45, centro.z),
		Vector3(tam.x + 0.3, 0.9, tam.z + 0.3), giro, _mat_det("zocalo", Color(0.30, 0.29, 0.28), 0.95))
	if not azotea_plana:
		return
	## Cornisa con parapeto.
	_caja_det(Vector3(centro.x, techo_y + 0.25, centro.z), Vector3(tam.x + 0.5, 0.5, tam.z + 0.5), giro,
		_mat_det("cornisa", Color(0.80, 0.78, 0.74), 0.7))
	## Azotea: equipos y depósito (ligeros: 3 cajas y un cilindro).
	var util := _mat_det("equipo", Color(0.55, 0.57, 0.58), 0.5)
	var n_eq := 1 + rng.randi() % 3
	for i in n_eq:
		var dx := rng.randf_range(-0.3, 0.3) * tam.x
		var dz := rng.randf_range(-0.3, 0.3) * tam.z
		var off := rot * Vector3(dx, 0, dz)
		_caja_det(Vector3(centro.x + off.x, techo_y + 0.5 + 0.45, centro.z + off.z),
			Vector3(1.8, 0.9, 1.2) * rng.randf_range(0.8, 1.3), giro + rng.randf() * 0.4, util)
	if rng.randf() < 0.5:
		var cil := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.9
		cm.bottom_radius = 0.9
		cm.height = 1.8
		cil.mesh = cm
		cil.material_override = _mat_det("deposito", Color(0.42, 0.30, 0.22), 0.8)
		var off2 := rot * Vector3(tam.x * 0.25, 0, -tam.z * 0.2)
		cil.position = Vector3(centro.x + off2.x, techo_y + 0.5 + 0.9, centro.z + off2.z)
		b.add_child(cil)

func _kit(esc: PackedScene, pos: Vector3, escala: Vector3, giro: float, azotea_plana := false) -> Node3D:
	var n: Node3D = esc.instantiate()
	if azotea_plana:
		## Torre: fachada con ventanas de verdad (el tono sale de la posición).
		b.vestir_torre(n, hash(Vector2(pos.x, pos.z)))
		if _rng.randf() < 0.45:
			_rng.randi()   ## (se consume igual que antes para no mover el resto)
	else:
		## Todos llevan tinte propio (antes solo el 45 %): el tono sale de la
		## posición, y el azar de siempre se consume igual para no mover la ciudad.
		if _rng.randf() < 0.45:
			_rng.randi()
		b.tenir(n, hash(Vector2(pos.x, pos.z)))
	n.scale = escala
	n.rotation.y = giro
	n.position = pos
	b.add_child(n)
	cuenta["edificios"] = int(cuenta.get("edificios", 0)) + 1
	_detalle_edificio(n, escala, giro, pos, azotea_plana)
	return n

func _rotulo_comercio(frente: Vector3, giro: float, ancho: float) -> void:
	var com: Array = COMERCIOS[_rng.randi() % COMERCIOS.size()]
	rotulos.append({"pos": frente, "ancho": ancho, "texto": String(com[0])})
	var col: Color = com[1]
	if String(com[0]).contains("Peña"):
		col = b._color_club("c1", col)
	var basis := Basis(Vector3.UP, giro)
	var centro := frente + Vector3(0, 4.1, 0)
	var placa := b._caja_en(centro, Vector3(minf(ancho * 0.8, 7.0), 0.9, 0.18), b._mat_simple(col, 0.5, 0.25))
	placa.rotation.y = giro
	var l := Label3D.new()
	l.text = String(com[0])
	l.font_size = 48
	l.pixel_size = 0.012
	l.outline_size = 8
	l.outline_modulate = col.darkened(0.6)
	l.position = centro + basis * Vector3(0, 0, 0.12)
	l.rotation.y = giro
	l.visibility_range_end = 110.0
	b.add_child(l)
	if String(com[0]).contains("Farmacia"):
		var cruz := b._mat_simple(Color(0.2, 1.0, 0.4), 0.4, 2.0)
		var pc := frente + basis * Vector3(minf(ancho * 0.4, 3.5) + 0.6, 0, 0.5) + Vector3(0, 5.2, 0)
		var h := b._caja_en(pc, Vector3(0.9, 0.3, 0.12), cruz)
		h.rotation.y = giro
		var v := b._caja_en(pc, Vector3(0.3, 0.9, 0.12), cruz)
		v.rotation.y = giro

## EL PATIO DE MANZANA (7-10-2026, «¿qué le pasó a los edificios?»): visto
## desde arriba, el interior de las manzanas comerciales era una explanada
## gris vacía detrás de las fachadas. Ahora es un patio como los del
## ensanche: césped, dos caminos en cruz y árboles alrededor de la torre.
func _patio_de_manzana(r: Rect2, c: Vector3) -> void:
	var lado := Vector2(maxf(r.size.x - 36.0, 10.0), maxf(r.size.y - 36.0, 10.0))
	_lote("cesped", Vector3(c.x, 0.27, c.z), Vector3(lado.x, 0.06, lado.y))
	_lote("solar", Vector3(c.x, 0.3, c.z), Vector3(lado.x, 0.06, 2.6))
	_lote("solar", Vector3(c.x, 0.3, c.z), Vector3(2.6, 0.06, lado.y))
	var pts: Array = []
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			pts.append(c + Vector3(sx * lado.x * 0.36, 0.0, sz * lado.y * 0.36))
			pts.append(c + Vector3(sx * lado.x * 0.18, 0.0, sz * lado.y * 0.4))
	_arboles_en(pts, 0.85)

## Fachadas del kit por los cuatro lados, mirando a la calle (`con_nave`: un
## bloque alto en el centro de la manzana).
func _fachadas(r: Rect2, con_nave: bool) -> void:
	if _comercial.is_empty():
		return
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	for lado in 4:
		var n := [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)][lado] as Vector3
		var dir := Vector3(-n.z, 0, n.x)
		var largo := (r.size.x if absf(n.z) > 0.5 else r.size.y) - 10.0
		var fondo_b := r.size.y if absf(n.z) > 0.5 else r.size.x
		var u := -largo * 0.5
		var giro := atan2(n.x, n.z)
		while u < largo * 0.5 - 6.0:
			var esc: PackedScene = _comercial[_rng.randi() % _comercial.size()]
			var s := 5.6 * _rng.randf_range(0.9, 1.1)
			var tmp: Node3D = esc.instantiate()
			var caja := b._caja_de(tmp)
			tmp.free()
			var ancho := maxf(caja.size.x * s, 6.0)
			var fondo := maxf(caja.size.z * s, 6.0)
			if u + ancho > largo * 0.5:
				break
			var p := c + dir * (u + ancho * 0.5) + n * (fondo_b * 0.5 - fondo * 0.5 - 0.3)
			## Escala UNIFORME (7-10-2026): estirarlos en vertical alargaba puertas
			## y ventanas, y los edificios se veían deformados.
			_kit(esc, Vector3(p.x, 0.2, p.z), Vector3.ONE * s, giro)
			if _rng.randf() < 0.4:
				_rotulo_comercio(p + n * (fondo * 0.5 + 0.35), giro, ancho)
			u += ancho + _rng.randf_range(0.3, 1.5)
	if con_nave and not _naves.is_empty():
		_patio_de_manzana(r, c)
		var s2 := 6.5 * _rng.randf_range(0.9, 1.2)
		## El bloque interior: un rascacielos del kit (pensado alto), uniforme.
		if not _altos.is_empty() and _rng.randf() < 0.6:
			_kit(_altos[_rng.randi() % _altos.size()], c + Vector3(0, 0.2, 0), Vector3.ONE * _rng.randf_range(3.2, 4.4), float(_rng.randi() % 4) * PI * 0.5)
		else:
			_kit(_naves[_rng.randi() % _naves.size()], c + Vector3(0, 0.2, 0), Vector3.ONE * s2 * 1.2, float(_rng.randi() % 4) * PI * 0.5, true)

func _comercial_bloque_borde(r: Rect2) -> void:
	_fachadas(r, false)

func _torres(r: Rect2) -> void:
	if _altos.is_empty():
		return
	## Comercios en la planta baja por los cuatro lados (como una manzana
	## comercial) y, dentro, dos o tres torres gruesas sobre un patio verde.
	_comercial_bloque_borde(r)
	var c := Vector3(r.get_center().x, 0.2, r.get_center().y)
	_lote("cesped", Vector3(c.x, 0.26, c.z), Vector3(r.size.x * 0.55, 0.06, r.size.y * 0.5))
	var offs := [Vector3(-r.size.x * 0.14, 0, -r.size.y * 0.1), Vector3(r.size.x * 0.14, 0, r.size.y * 0.1), Vector3(r.size.x * 0.14, 0, -r.size.y * 0.12)]
	var empuje := b._empuje_club()
	for k in offs.size():
		if k == 2 and _rng.randf() < 0.5:
			continue
		var s := 6.2 * _rng.randf_range(0.9, 1.25) * lerpf(0.9, 1.3, empuje)
		_kit(_altos[_rng.randi() % _altos.size()], c + (offs[k] as Vector3), Vector3(s * 1.25, s, s * 1.25), float(_rng.randi() % 4) * PI * 0.5, true)
	_arboles_en([c + Vector3(-r.size.x * 0.2, -0.2, r.size.y * 0.16), c + Vector3(r.size.x * 0.02, -0.2, -r.size.y * 0.2)], 0.9)

func _comercial_bloque(r: Rect2) -> void:
	_fachadas(r, true)

## ¿Está el kit? (si no, los bloques de siempre).
func _mallas_mod() -> Dictionary:
	return _malla_kit(RUTA_MOD + "building-window.glb")

func _mod(pieza: String, t: Transform3D, pared: Color, extra: Color) -> void:
	var ruta := RUTA_MOD + pieza + ".glb"
	if not _mod_t.has(ruta):
		_mod_t[ruta] = {"t": [] as Array[Transform3D], "c": [] as Array[Color], "d": [] as Array[Color]}
	var g: Dictionary = _mod_t[ruta]
	(g["t"] as Array[Transform3D]).append(t)
	(g["c"] as Array[Color]).append(pared)
	(g["d"] as Array[Color]).append(extra)

func _mod_caja(centro: Vector3, tam: Vector3, base: Basis, col: Color) -> void:
	_mod_cajas_t.append(Transform3D(base * Basis.from_scale(tam), centro))
	_mod_cajas_c.append(col)

## Un bloque de pisos. `frente`: centro de la fachada a ras de suelo; `giro`:
## hacia dónde mira (0 → +Z). `ancho_max`/`fondo_max`: lo que cabe en la parcela.
## Devuelve el punto de la puerta (en la línea de fachada).
func _bloque_modular(frente: Vector3, giro: float, semilla: int, ancho_max: float, fondo_max: float,
		forzar := {}) -> Vector3:
	var hr := RandomNumberGenerator.new()
	hr.seed = semilla
	var s := ESC_MOD
	var w := 4 if ancho_max >= 4.0 * s and hr.randf() < 0.6 else 3
	var d := 3 if fondo_max >= 3.0 * s and hr.randf() < 0.55 else 2
	var pisos := hr.randi_range(3, 7)
	var col: Array = COLORES_PISOS[hr.randi() % COLORES_PISOS.size()]
	var toldo := hr.randi() % 5
	var estilo: Array = ESTILOS_MOD[hr.randi() % ESTILOS_MOD.size()]
	var tienda := hr.randf() < 0.55
	var escaparate := hr.randf() < 0.35
	var puerta_pieza: String = PUERTAS_MOD[hr.randi() % PUERTAS_MOD.size()]
	w = int(forzar.get("w", w))
	d = int(forzar.get("d", d))
	pisos = int(forzar.get("pisos", pisos))
	if forzar.has("color"):
		col = forzar["color"]
	if forzar.has("tienda"):
		tienda = bool(forzar["tienda"])
	## Pared un poco apagada (a pleno sol los pastel se queman) y en lineal: el
	## shader la multiplica por el gris de la paleta.
	var pared := (col[0] as Color).lerp(Color(0.72, 0.7, 0.66), 0.1).srgb_to_linear()
	var rem := (col[1] as Color).srgb_to_linear()
	var extra := Color(rem.r, rem.g, rem.b, float(toldo) / 4.0)
	var puerta_i := w / 2
	var rot := Basis(Vector3.UP, giro)
	for p in pisos:
		for i in w:
			for j in d:
				var al_frente := j == d - 1
				var detras := j == 0
				var al_lado := i == 0 or i == w - 1
				if not (al_frente or detras or al_lado):
					continue
				var lx := (float(i) - float(w - 1) * 0.5) * s
				var lz := -(float(d - 1 - j) + 0.5) * s
				var pieza := "building-block"
				var g := 0.0
				if al_frente:
					if p == 0:
						if i == puerta_i:
							pieza = puerta_pieza
						elif tienda:
							pieza = "building-window-large" if escaparate else "building-window-awnings"
						else:
							pieza = "building-window-sill"
					else:
						pieza = String(estilo[(i + p) % 2])
				elif detras:
					g = PI
					pieza = "building-window" if p == 0 else ("building-window-sill" if (i + p) % 3 == 0 else "building-windows")
				else:
					g = -PI * 0.5 if i == 0 else PI * 0.5
					pieza = "building-block" if p == 0 else "building-window"
				var t := Transform3D(rot * Basis(Vector3.UP, g) * Basis.from_scale(Vector3.ONE * s),
					frente + rot * Vector3(lx, float(p) * PISO_MOD, lz))
				_mod(pieza, t, pared, extra)
	## Azotea: cornisa con parapeto, el suelo de grava, equipos de aire y la
	## caseta de la escalera.
	var ancho := float(w) * s
	var fondo := float(d) * s
	var alto := float(pisos) * PISO_MOD
	var centro := frente + rot * Vector3(0, 0, -fondo * 0.5)
	var remate_srgb: Color = col[1]
	_mod_caja(centro + Vector3(0, alto + 0.12, 0), Vector3(ancho + 0.5, 0.24, fondo + 0.5), rot, remate_srgb)
	for sz: float in [-1.0, 1.0]:
		_mod_caja(centro + rot * Vector3(0, 0, sz * (fondo * 0.5 + 0.1)) + Vector3(0, alto + 0.6, 0), Vector3(ancho + 0.4, 0.75, 0.3), rot, remate_srgb)
	for sx: float in [-1.0, 1.0]:
		_mod_caja(centro + rot * Vector3(sx * (ancho * 0.5 + 0.1), 0, 0) + Vector3(0, alto + 0.6, 0), Vector3(0.3, 0.75, fondo), rot, remate_srgb)
	_mod_caja(centro + Vector3(0, alto + 0.26, 0), Vector3(ancho - 0.2, 0.06, fondo - 0.2), rot, Color(0.46, 0.45, 0.43))
	var caseta := rot * Vector3((hr.randf() - 0.5) * ancho * 0.4, 0, (hr.randf() - 0.5) * fondo * 0.3)
	_mod_caja(centro + caseta + Vector3(0, alto + 1.4, 0), Vector3(2.6, 2.4, 2.6), rot, (col[0] as Color).darkened(0.08))
	_mod_caja(centro + caseta + Vector3(0, alto + 2.68, 0), Vector3(3.0, 0.16, 3.0), rot, remate_srgb)
	for k in 1 + hr.randi() % 3:
		var q := rot * Vector3((hr.randf() - 0.5) * (ancho - 3.0), 0, (hr.randf() - 0.5) * (fondo - 3.0))
		_mod("detail-ac-a" if k % 2 == 0 else "detail-ac-b", Transform3D(rot * Basis.from_scale(Vector3.ONE * ESC_MOD), centro + q + Vector3(0, alto + 0.28, 0)), pared, extra)
	## Escalón y felpudo de piedra ante la puerta.
	var puerta := frente + rot * Vector3((float(puerta_i) - float(w - 1) * 0.5) * s, 0, 0)
	_mod_caja(puerta + rot * Vector3(0, 0, 0.55) + Vector3(0, 0.08, 0), Vector3(2.6, 0.16, 1.1), rot, Color(0.62, 0.6, 0.56))
	cuenta["edificios"] = int(cuenta.get("edificios", 0)) + 1
	cuenta["bloques_modulares"] = int(cuenta.get("bloques_modulares", 0)) + 1
	_puertas_mod.append(puerta)
	return puerta
