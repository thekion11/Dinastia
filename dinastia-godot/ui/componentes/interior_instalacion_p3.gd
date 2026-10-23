extends "res://ui/componentes/interior_instalacion_p2.gd"
## (Parte 3 de 7 de `interior_instalacion.gd`.)

## Un cuadro en la pared del fondo (lámina de color con marco).
func _cuadro(p: Vector3, tam: Vector2, col: Color) -> void:
	Mini3D.caja(_raiz, p, Vector3(tam.x + 0.08, tam.y + 0.08, 0.04), Mini3D.mat(Color(0.25, 0.18, 0.12), 0.5))
	Mini3D.caja(_raiz, p + Vector3(0, 0, 0.025), Vector3(tam.x, tam.y, 0.01), Mini3D.mat(col, 0.8))

## Comisaría (18 × 12 m): puestos de los agentes, archivo, el calabozo, el
## mostrador de denuncias y el banco de espera.
func _comisaria() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(18, 3.4, 12), Color(0.55, 0.57, 0.6), Color(0.8, 0.84, 0.88), "losa", Color(0.2, 0.28, 0.42))
	var poli := [Color(0.1, 0.18, 0.35), Color(0.1, 0.12, 0.2), true]
	for p: Vector3 in [Vector3(-7.0, 0, -2.6), Vector3(-4.2, 0, -2.6), Vector3(-1.4, 0, -2.6), Vector3(-7.0, 0, 1.0)]:
		_puesto(p, 0.0, true, true, poli)
	for k in 5:
		_poner("bookcaseClosedDoors", Vector3(-8.5 + float(k) * 0.82, 0, -5.75), 0.0, null, {"wood": Color(0.55, 0.58, 0.62)})
	## El calabozo: rejas, pared y un banco con un detenido.
	var reja := Mini3D.mat(Color(0.3, 0.3, 0.32), 0.3)
	reja.metallic = 0.7
	var x := 3.0
	while x <= 9.0:
		Mini3D.cilindro(_raiz, Vector3(x, 1.6, -2.0), 0.025, 3.2, reja)
		x += 0.18
	Mini3D.caja(_raiz, Vector3(6.0, 3.25, -2.0), Vector3(6.1, 0.1, 0.1), reja)
	Mini3D.caja(_raiz, Vector3(6.0, 0.05, -2.0), Vector3(6.1, 0.1, 0.1), reja)
	Mini3D.caja(_raiz, Vector3(3.0, 1.7, -4.0), Vector3(0.15, 3.4, 4.0), Mini3D.mat(Color(0.7, 0.72, 0.75), 0.8))
	_asiento("benchCushionLow", Vector3(6.0, 0, -5.6), 0.0, [0.3], _calle(), 2.4, {"carpet": Color(0.4, 0.4, 0.42), "wood": Color(0.45, 0.45, 0.47)})
	## Mostrador de denuncias.
	var ancho := _medida("kitchenBar", 2.5).x
	for k in 3:
		_poner("kitchenBar", Vector3(-6.2 + float(k) * ancho, 0, 3.2), 0.0, 2.5, {"wood": Color(0.2, 0.28, 0.42), "woodDark": Color(0.15, 0.2, 0.3)})
	_trabajador(Vector3(-5.2, 0, 2.35), 0.0, false, ["charla", "senalar_falta", "brazos_jarra"], poli)
	_trabajador(Vector3(-5.0, 0, 4.2), PI, false, ["charla", "brazos_jarra"], _calle())
	## Banco de espera y carteles de «se busca».
	for k in 3:
		_asiento("bench", Vector3(8.6, 0, 1.4 + float(k) * 0.8), -PI * 0.5, [0.0] if k == 1 else [], _calle(), null, {"wood": Color(0.45, 0.32, 0.22)})
	for k in 3:
		_cuadro(Vector3(4.0 + float(k) * 0.8, 1.8, -5.97), Vector2(0.55, 0.7), Color(0.92, 0.88, 0.75))
	_planta(Vector3(8.5, 0, 5.4))
	_caminante([Vector3(-5.4, 0, -0.4), Vector3(1.8, 0, -0.4), Vector3(1.8, 0, 1.8), Vector3(-5.4, 0, 1.8)], poli)
	_cartel("🚔 COMISARÍA DEL DISTRITO", Vector3(-4.2, 2.85, -5.95), 34)

## Parque de bomberos (24 × 16 m, 7 m de alto): las dos autobombas, taquillas,
## la barra para bajar, mangueras y los bomberos.
func _bomberos() -> void:
	_sala(Vector3(24, 7.0, 16), Color(0.48, 0.48, 0.5), Color(0.86, 0.42, 0.36), "hormigon", Color(0.45, 0.45, 0.47))
	var cam := "coches/firetruck"
	var m := _medida(cam, 1.0)
	var esc := 8.0 / maxf(m.x, m.z)
	for k in 2:
		_poner(cam, Vector3(-4.0 + float(k) * 8.0, 0, -2.0), 0.0 if m.z >= m.x else PI * 0.5, esc)
	## Taquillas con los equipos.
	for k in 8:
		_poner("bookcaseClosedDoors", Vector3(-11.75, 0, -6.4 + float(k) * 0.82), PI * 0.5, null, {"wood": Color(0.7, 0.72, 0.75)})
	_asiento("benchCushionLow", Vector3(-10.4, 0, -3.0), PI * 0.5, [0.0], [Color(0.25, 0.22, 0.12), Color(0.9, 0.75, 0.1), true], 2.4, {"carpet": Color(0.3, 0.3, 0.32)})
	Mini3D.cilindro(_raiz, Vector3(10, 3.5, -6), 0.06, 7.0, Mini3D.mat(Color(0.85, 0.75, 0.3), 0.2))
	var bombero := [Color(0.25, 0.22, 0.12), Color(0.9, 0.75, 0.1), true]
	_caminante([Vector3(-9, 0, 5), Vector3(9, 0, 5), Vector3(9, 0, 3), Vector3(-9, 0, 3)], bombero, true)
	_caminante([Vector3(7, 0, 3.5), Vector3(-7, 0, 3.5)], bombero)
	_trabajador(Vector3(-10.6, 0, -5.0), PI * 0.5, false, ["brazos_jarra", "charla"], bombero)
	_trabajador(Vector3(0, 0, 1.0), 0.0, false, ["senalar_cielo", "charla", "pedir_calma"], bombero)
	_trabajador(Vector3(9.0, 0, -5.5), -PI * 0.5, false, ["charla", "saludo_mano"], bombero)
	## Mangueras enrolladas y conos.
	for k in 3:
		var mi := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.2
		tm.outer_radius = 0.5
		mi.mesh = tm
		mi.material_override = Mini3D.mat(Color(0.85, 0.2, 0.15), 0.6)
		mi.position = Vector3(11.2, 1.0 + float(k) * 0.5, -2.0)
		mi.rotation.z = PI * 0.5
		_raiz.add_child(mi)
	for k in 3:
		_poner("coches/cone", Vector3(4.0 + float(k) * 1.2, 0, 6.0), 0.0, 0.7)
	_cartel("🚒 PARQUE DE BOMBEROS", Vector3(0, 5.8, -7.95), 64)

## Aula (14 × 11 m): pizarra, mesa del profesor, 4 filas de 5 pupitres con los
## alumnos y estanterías.
func _aula() -> void:
	var peques := clave == "ciudad_escuela" or clave == "guarderia"
	var uni := clave == "ciudad_universidad"
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(14, 3.4, 11), Color(0.66, 0.52, 0.36), Color(0.96, 0.91, 0.76) if peques else Color(0.86, 0.89, 0.91), "parquet")
	## La pizarra y la mesa del profesor.
	Mini3D.caja(_raiz, Vector3(0, 1.6, -5.47), Vector3(5.0, 1.3, 0.05), Mini3D.mat(Color(0.12, 0.3, 0.2), 0.8))
	Mini3D.caja(_raiz, Vector3(0, 0.92, -5.4), Vector3(5.0, 0.04, 0.14), Mini3D.mat(Color(0.6, 0.45, 0.3), 0.6))
	_cartel("2 + 2 = 4" if peques else ("∫ f(x) dx" if uni else "La Revolución Industrial"), Vector3(0, 1.65, -5.42), 44, Color(0.95, 0.95, 0.9))
	_puesto(Vector3(-5.4, 0, -3.6), PI * 0.25, uni, false)
	_caminante([Vector3(-2.6, 0, -4.55), Vector3(2.6, 0, -4.55)])
	## Pupitres (mesa estrecha del kit) en filas, de cara a la pizarra.
	var pupitre := Vector3(1.0, 2.2, 1.4)
	var silla_col := {"wood": Color(0.25, 0.45, 0.8)} if peques else {"wood": Color(0.62, 0.45, 0.3)}
	var prof := _medida("table", pupitre).z
	for i in 4:
		for j in 5:
			var p := Vector3(-4.8 + float(j) * 2.4, 0, -2.4 + float(i) * 1.45)
			_poner("table", p, PI, pupitre)
			_poner("books" if _rng.randf() < 0.6 else "laptop", p + Vector3(_rng.randf_range(-0.15, 0.15), _alto("table", pupitre), 0), _rng.randf_range(2.8, 3.5), 1.6)
			_asiento("chair", p + Vector3(0, 0, prof * 0.5 + 0.18), PI, [0.0] if _rng.randf() < 0.8 else [], _calle() if not peques else [Color.from_hsv(_rng.randf(), 0.6, 0.85), Color(0.25, 0.3, 0.5)], null, silla_col)
	for k in 3:
		_poner("bookcaseOpen", Vector3(6.74, 0, -3.2 + float(k) * 0.82), -PI * 0.5)
		for b in 3:
			_poner("books", Vector3(6.74, 0.42 + float(b) * 0.5, -3.2 + float(k) * 0.82 + _rng.randf_range(-0.15, 0.15)), -PI * 0.5)
	_ventana(-1.0, -1.6, 2.0, false)
	_ventana(-1.0, 1.6, 2.0, false)
	if peques:
		for k in 6:
			Mini3D.esfera(_raiz, Vector3(5.0 + float(k % 3) * 0.5, 0.18, 4.6 - float(k / 3) * 0.5), 0.18, Mini3D.mat(Color.from_hsv(float(k) / 6.0, 0.7, 0.95), 0.4))
		_poner("bear", Vector3(6.3, 0, 3.6), -0.8)
	_planta(Vector3(6.4, 0, 5.0))
	_poner("trashcan", Vector3(-6.5, 0, 5.0), 0.0, 1.4)
	_cartel("🎓 " + _sala_nombre().to_upper(), Vector3(0, 2.85, -5.45), 32)

func _prim(forma: String, p: Vector3, tam: Vector3, col: Color, acabado: String = "mate", rot: Vector3 = Vector3.ZERO, base: Transform3D = Transform3D.IDENTITY) -> void:
	var k := forma + "|" + acabado
	if not _prims.has(k):
		_prims[k] = []
	(_prims[k] as Array).append([base * Transform3D(Basis.from_euler(rot) * Basis.from_scale(tam), p), col])

## Texto de pantalla o rótulo (sin contorno si `contorno` es false), de una sola
## cara (para poner dos espaldas con espaldas) y con su alineación. Lo devuelve
## por si hay que tumbarlo (marcas del suelo).
func _texto(texto: String, pos: Vector3, tam: int, col: Color, giro: float = 0.0, contorno: bool = true,
		alinear: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label3D:
	var l := Label3D.new()
	l.rotation.y = giro
	l.text = texto
	l.font_size = tam
	l.pixel_size = 0.01
	l.modulate = col
	l.double_sided = false
	l.horizontal_alignment = alinear
	if contorno:
		l.outline_size = 6
		l.outline_modulate = Color(0, 0, 0, 0.6)
	else:
		l.outline_size = 0
	l.position = pos
	_raiz.add_child(l)
	return l

## Maleta en el suelo: cuerpo, asa y, si es de ruedas, el tirador y las ruedas.
func _maleta(p: Vector3, giro: float, col: Color, ruedas: bool) -> void:
	var t := Transform3D(Basis(Vector3.UP, giro), p)
	var oscuro := col.darkened(0.45)
	var alto := 0.62 if ruedas else 0.42
	_prim("caja", Vector3(0, alto * 0.5 + 0.05, 0), Vector3(0.42, alto, 0.24), col, "goma", Vector3.ZERO, t)
	for k in 3:
		_prim("caja", Vector3(-0.12 + float(k) * 0.12, alto * 0.5 + 0.05, 0.122), Vector3(0.025, alto - 0.04, 0.008), oscuro, "mate", Vector3.ZERO, t)
	if ruedas:
		for s: float in [-1.0, 1.0]:
			_prim("cil", Vector3(s * 0.16, 0.035, -0.08), Vector3(0.06, 0.04, 0.06), Color(0.08, 0.08, 0.09), "goma", Vector3(0, 0, PI * 0.5), t)
			_prim("cil", Vector3(s * 0.08, alto + 0.25, -0.1), Vector3(0.02, 0.42, 0.02), Color(0.6, 0.62, 0.65), "metal", Vector3.ZERO, t)
		_prim("caja", Vector3(0, alto + 0.46, -0.1), Vector3(0.2, 0.03, 0.03), Color(0.1, 0.1, 0.11), "goma", Vector3.ZERO, t)
	else:
		_prim("caja", Vector3(0, alto + 0.09, 0), Vector3(0.16, 0.03, 0.03), oscuro, "goma", Vector3.ZERO, t)

## Esfera de reloj (de pared o colgado) en el marco `t` (mira a +Z local), de
## `radio` m, con sus doce marcas y las agujas a la `hora` dada (10,5 = 10:30).
func _reloj(t: Transform3D, radio: float, hora: float) -> void:
	var negro := Color(0.08, 0.08, 0.1)
	_prim("cil", Vector3(0, 0, 0.005), Vector3(radio * 2.0, 0.02, radio * 2.0), Color(0.97, 0.96, 0.92), "luz", Vector3(PI * 0.5, 0, 0), t)
	for k in 12:
		var a := float(k) / 12.0 * TAU
		var largo := 0.14 if k % 3 == 0 else 0.07
		_prim("caja", Vector3(sin(a), cos(a), 0) * radio * (0.86 - largo * 0.5) + Vector3(0, 0, 0.02), Vector3(0.025 if k % 3 else 0.04, radio * largo, 0.01), negro, "mate", Vector3(0, 0, -a), t)
	var a_h := fmod(hora, 12.0) / 12.0 * TAU
	var a_m := fmod(hora, 1.0) * TAU
	_prim("caja", Vector3(sin(a_h), cos(a_h), 0) * radio * 0.25 + Vector3(0, 0, 0.03), Vector3(0.05, radio * 0.5, 0.01), negro, "mate", Vector3(0, 0, -a_h), t)
	_prim("caja", Vector3(sin(a_m), cos(a_m), 0) * radio * 0.36 + Vector3(0, 0, 0.035), Vector3(0.035, radio * 0.75, 0.01), negro, "mate", Vector3(0, 0, -a_m), t)
	_prim("cil", Vector3(0, 0, 0.04), Vector3(0.05, 0.01, 0.05), Color(0.75, 0.15, 0.12), "mate", Vector3(PI * 0.5, 0, 0), t)

## Maleta de ruedas que lleva alguien que camina: va colgada de su nodo, a su
## lado y un poco detrás, inclinada como cuando se arrastra.
func _maleta_de(nodo: Node3D, col: Color) -> void:
	var n := Node3D.new()
	n.position = Vector3(-0.26, 0.05, -0.5)
	n.rotation.x = 0.45
	nodo.add_child(n)
	var m := Mini3D.mat(col, 0.55)
	Mini3D.caja(n, Vector3(0, 0.36, 0), Vector3(0.24, 0.6, 0.4), m)
	Mini3D.caja(n, Vector3(0, 0.84, 0.12), Vector3(0.02, 0.4, 0.02), Mini3D.mat(Color(0.6, 0.62, 0.65), 0.3))
	Mini3D.caja(n, Vector3(0, 0.04, -0.15), Vector3(0.2, 0.06, 0.06), Mini3D.mat(Color(0.08, 0.08, 0.09), 0.6))

## Estación (24 × 15 m, vestíbulo de 7 m; 16-10-2026: «a la altura del
## gimnasio»). Suelo de piedra con su rosa de los vientos, columnas con
## capitel, lámparas colgadas y el reloj de doble esfera sobre el pasillo. Al
## fondo, el gran panel de salidas, las tres bocas de los andenes con su
## pantalla y la línea de tornos (dos abiertos, por donde pasa la gente); a la
## izquierda las taquillas con su fila de cintas, las máquinas de billetes y la
## consigna; a la derecha el quiosco, las máquinas de bebidas y la cafetería
## con su barra, la cafetera, la vitrina y las mesas altas. Viajeros con
## maleta, gente en los bancos, el vigilante y los que van y vienen con prisa.
## Casi todo en lotes (`_prim`, `_poner`).
func _estacion() -> void:
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(24, 7.0, 15), Color(0.74, 0.7, 0.63), Color(0.88, 0.83, 0.74), "losa", Color(0.5, 0.4, 0.32))
	var hierro := Color(0.16, 0.16, 0.18)
	var acero := Color(0.68, 0.7, 0.73)
	var laton := Color(0.78, 0.62, 0.3)
	var crema := Color(0.9, 0.86, 0.78)
	var oscuro := Color(0.06, 0.07, 0.09)
	var ambar := Color(1.0, 0.78, 0.22)
	var azul_rotulo := Color(0.12, 0.24, 0.48)
	## --- Suelo: cenefa oscura junto a las paredes y la rosa de los vientos.
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(0, 0.005, s * 7.0), Vector3(23.0, 0.01, 0.35), Color(0.42, 0.36, 0.3))
		_prim("caja", Vector3(s * 11.5, 0.005, 0), Vector3(0.35, 0.01, 14.0), Color(0.42, 0.36, 0.3))
	var rosa := Vector3(0, 0, 1.2)
	_prim("cil", rosa + Vector3(0, 0.004, 0), Vector3(2.8, 0.008, 2.8), Color(0.3, 0.33, 0.3))
	_prim("cil", rosa + Vector3(0, 0.008, 0), Vector3(2.5, 0.008, 2.5), Color(0.86, 0.82, 0.72))
	for k in 8:
		var largo := 2.3 if k % 2 == 0 else 1.5
		_prim("caja", rosa + Vector3(0, 0.012, 0), Vector3(0.16, 0.006, largo), Color(0.55, 0.18, 0.14) if k % 2 == 0 else Color(0.2, 0.2, 0.22), "mate", Vector3(0, float(k) * PI * 0.25, 0))
	_prim("cil", rosa + Vector3(0, 0.016, 0), Vector3(0.36, 0.006, 0.36), laton, "metal")
	## --- Columnas con basa, anillo de latón y capitel.
	for p: Vector3 in [Vector3(-8.4, 0, -2.6), Vector3(-3.2, 0, -2.6), Vector3(3.2, 0, -2.6), Vector3(8.4, 0, -2.6), Vector3(-3.2, 0, 3.4), Vector3(3.2, 0, 3.4)]:
		_prim("caja", p + Vector3(0, 0.2, 0), Vector3(0.95, 0.4, 0.95), Color(0.62, 0.58, 0.52))
		_prim("cil", p + Vector3(0, 3.2, 0), Vector3(0.62, 5.6, 0.62), crema)
		_prim("cil", p + Vector3(0, 2.3, 0), Vector3(0.68, 0.08, 0.68), laton, "metal")
		_prim("caja", p + Vector3(0, 6.12, 0), Vector3(0.82, 0.24, 0.82), crema)
		_prim("caja", p + Vector3(0, 6.35, 0), Vector3(1.0, 0.22, 1.0), Color(0.8, 0.76, 0.68))
	## --- Lámparas colgadas: cable, campana de latón y globo encendido.
	for p: Vector3 in [Vector3(-6.0, 0, -0.6), Vector3(6.0, 0, -0.6), Vector3(-6.0, 0, 4.6), Vector3(6.0, 0, 4.6), Vector3(0, 0, 4.8)]:
		_prim("cil", p + Vector3(0, 6.2, 0), Vector3(0.025, 1.6, 0.025), hierro)
		_prim("cono", p + Vector3(0, 5.3, 0), Vector3(0.5, 0.22, 0.5), laton, "metal")
		_prim("esf", p + Vector3(0, 5.0, 0), Vector3.ONE * 0.62, Color(1.0, 0.95, 0.82), "luz")
	## --- El fondo: panel de salidas, las bocas de los andenes y los tornos.
	_prim("caja", Vector3(0, 5.0, -7.42), Vector3(9.4, 2.5, 0.12), Color(0.3, 0.3, 0.33), "metal")
	_prim("caja", Vector3(0, 5.0, -7.36), Vector3(9.0, 2.2, 0.04), oscuro)
	_texto("SALIDAS", Vector3(-4.2, 5.88, -7.32), 26, Color(1.0, 1.0, 1.0), 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	for col: Array in [["HORA", -4.2], ["DESTINO", -2.9], ["VÍA", 0.75], ["OBSERVACIONES", 1.75]]:
		_texto(String(col[0]), Vector3(float(col[1]), 5.55, -7.32), 15, Color(0.7, 0.75, 0.8), 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	_texto("10:15\n10:22\n10:30\n10:41\n10:55", Vector3(-4.2, 4.62, -7.32), 21, ambar, 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	_texto("PUERTO\nALTO NORTE\nRIBERA\nAEROPUERTO\nCOSTA AZUL", Vector3(-2.9, 4.62, -7.32), 21, ambar, 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	_texto("2\n1\n3\n1\n2", Vector3(0.75, 4.62, -7.32), 21, ambar, 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	_texto("A TIEMPO\nEMBARCANDO\nRETRASO 5'\nA TIEMPO\nA TIEMPO", Vector3(1.75, 4.62, -7.32), 21, Color(0.55, 1.0, 0.6), 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	var vias := ["VÍA 1 · 10:22 ALTO NORTE", "VÍA 2 · 10:15 PUERTO", "VÍA 3 · 10:30 RIBERA"]
	for k in 3:
		var x := -2.6 + float(k) * 2.6
		## La boca del andén (oscura, con el andén iluminado al fondo) y su marco.
		_prim("caja", Vector3(x, 1.5, -7.47), Vector3(2.0, 3.0, 0.03), Color(0.16, 0.17, 0.21))
		_prim("caja", Vector3(x, 2.75, -7.452), Vector3(1.9, 0.05, 0.01), Color(0.95, 0.95, 0.88), "luz")
		_prim("caja", Vector3(x, 1.25, -7.452), Vector3(1.9, 0.3, 0.01), Color(0.75, 0.75, 0.78))
		_prim("caja", Vector3(x, 1.1, -7.451), Vector3(1.9, 0.04, 0.01), Color(0.85, 0.15, 0.15))
		_prim("caja", Vector3(x, 0.35, -7.455), Vector3(2.0, 0.7, 0.01), Color(0.32, 0.33, 0.36))
		_prim("caja", Vector3(x, 0.72, -7.45), Vector3(2.0, 0.05, 0.01), Color(0.95, 0.8, 0.15))
		for s: float in [-1.0, 1.0]:
			_prim("caja", Vector3(x + s * 1.05, 1.55, -7.42), Vector3(0.1, 3.1, 0.12), acero, "metal")
		_prim("caja", Vector3(x, 3.08, -7.42), Vector3(2.2, 0.12, 0.12), acero, "metal")
		_prim("caja", Vector3(x, 3.42, -7.4), Vector3(2.0, 0.42, 0.1), oscuro)
		_texto(String(vias[k]), Vector3(x, 3.42, -7.34), 15, Color(0.55, 1.0, 0.6), 0.0, false)
	## Tornos: cinco cuerpos de acero; los dos del centro abiertos (por ahí pasa
	## la gente), el resto con sus aletas de cristal cerradas.
	var zt := -4.6
	for k in 5:
		var x := -3.0 + float(k) * 1.5
		_prim("caja", Vector3(x, 0.5, zt), Vector3(0.28, 1.0, 1.25), acero, "metal")
		_prim("caja", Vector3(x, 1.02, zt), Vector3(0.32, 0.05, 1.28), Color(0.14, 0.14, 0.16))
		_prim("caja", Vector3(x, 1.055, zt + 0.38), Vector3(0.18, 0.02, 0.16), Color(0.3, 0.95, 0.4), "luz")
		_prim("caja", Vector3(x, 1.055, zt - 0.38), Vector3(0.18, 0.02, 0.16), Color(0.95, 0.3, 0.25), "luz")
		for s: float in [-1.0, 1.0]:
			var paso := x + s * 0.75
			if absf(paso) < 1.0 or absf(paso) > 3.5:
				continue
			_prim("caja", Vector3(x + s * 0.37, 0.72, zt), Vector3(0.46, 0.62, 0.025), Color(0.7, 0.8, 0.88), "luz")
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 3.9, 0.55, zt), Vector3(1.1, 0.04, 0.04), acero, "metal")
		for x: float in [3.4, 4.4]:
			_prim("cil", Vector3(s * x, 0.55, zt), Vector3(0.06, 1.1, 0.06), acero, "metal")
	_prim("caja", Vector3(0, 0.006, zt + 0.95), Vector3(7.0, 0.012, 0.3), Color(0.95, 0.8, 0.15))
	_trabajador(Vector3(4.1, 0, -3.9), PI * 0.85, false, ["brazos_jarra", "charla", "senalar_adelante"], [Color(0.12, 0.14, 0.22), Color(0.12, 0.14, 0.22), true])
	_cartel("🚉 " + _sala_nombre().to_upper(), Vector3(0, 6.55, -7.4), 52)
	## --- Taquillas (fondo a la izquierda): tres puestos tras el cristal, el
	## mostrador, el rótulo y la fila con sus postes de cinta.
	for k in 3:
		_puesto(Vector3(-9.6 + float(k) * 2.4, 0, -6.0), 0.0)
	for k in 4:
		_prim("caja", Vector3(-10.8 + float(k) * 2.4, 1.45, -5.55), Vector3(0.08, 1.4, 0.12), Color(0.35, 0.25, 0.18))
	Mini3D.caja(_raiz, Vector3(-7.2, 1.45, -5.55), Vector3(7.2, 1.3, 0.03), Mini3D.mat(Color(0.8, 0.9, 1.0, 0.25), 0.05))
	_prim("caja", Vector3(-7.2, 0.38, -5.55), Vector3(7.3, 0.76, 0.12), Color(0.35, 0.25, 0.18))
	_prim("caja", Vector3(-7.2, 0.78, -5.42), Vector3(7.3, 0.04, 0.3), Color(0.5, 0.36, 0.24))
	_prim("caja", Vector3(-7.2, 2.4, -5.55), Vector3(7.3, 0.55, 0.14), azul_rotulo)
	_cartel("BILLETES · INFORMACIÓN", Vector3(-7.2, 2.4, -5.47), 30)
	for x: float in [-7.5, -5.9]:
		for k in 4:
			var p := Vector3(x, 0, -4.4 + float(k) * 0.7)
			_prim("cil", p + Vector3(0, 0.47, 0), Vector3(0.05, 0.94, 0.05), acero, "metal")
			_prim("cil", p + Vector3(0, 0.015, 0), Vector3(0.3, 0.03, 0.3), hierro, "metal")
			if k < 3:
				_prim("caja", p + Vector3(0, 0.86, 0.35), Vector3(0.02, 0.06, 0.7), Color(0.6, 0.12, 0.14), "goma")
	_trabajador(Vector3(-9.6, 0, -4.95), PI, false, ["charla", "brazos_jarra"], _calle())
	_trabajador(Vector3(-7.2, 0, -4.95), PI, false, ["charla", "saludo_mano"], _calle())
	for z: float in [-3.75, -3.0]:
		_trabajador(Vector3(-6.7, 0, z), PI, false, ["brazos_jarra", "charla", "parado"], _calle())
	_maleta(Vector3(-6.35, 0, -3.0), 0.3, Color(0.55, 0.15, 0.18), true)
	## Máquinas de billetes y la consigna (pared izquierda).
	_poner("mini_arcade/ticket-machine", Vector3(-11.5, 0, -1.6), PI * 0.5)
	_poner("mini_arcade/ticket-machine", Vector3(-11.5, 0, -0.6), PI * 0.5)
	for i in 4:
		for j in 3:
			var p := Vector3(-11.72, 0.42 + float(j) * 0.62, 1.7 + float(i) * 0.62)
			_prim("caja", p, Vector3(0.55, 0.6, 0.6), Color(0.42, 0.45, 0.5), "metal")
			_prim("caja", p + Vector3(0.28, 0, 0), Vector3(0.01, 0.52, 0.52), Color(0.78, 0.6, 0.2) if (i + j) % 4 == 1 else Color(0.62, 0.66, 0.7))
			_prim("caja", p + Vector3(0.29, 0.12, 0.17), Vector3(0.01, 0.08, 0.1), Color(0.3, 0.9, 0.4), "luz")
	_prim("caja", Vector3(-11.72, 2.2, 2.63), Vector3(0.56, 0.06, 2.6), hierro)
	_cartel("CONSIGNA", Vector3(-11.9, 2.6, 2.63), 30, Color.WHITE, PI * 0.5)
	## --- Quiosco (fondo a la derecha): mostrador con prensa y golosinas.
	var ancho := _medida("kitchenBar", 2.5).x
	for k in 3:
		_poner("kitchenBar", Vector3(6.2 + float(k) * ancho, 0, -4.8), 0.0, 2.5)
	var tope := _alto("kitchenBar", 2.5)
	for k in 8:
		_poner("books", Vector3(5.9 + float(k) * 0.28, tope, -4.8), _rng.randf_range(-0.2, 0.2), 1.8)
	for k in 4:
		_poner(["comida/chocolate", "comida/candy-bar", "comida/soda-can", "comida/lollypop"][k], Vector3(8.3 + float(k) * 0.22, tope, -4.75), _rng.randf() * TAU)
	for x: float in [6.6, 7.4, 8.2]:
		_poner("bookcaseOpen", Vector3(x, 0, -7.25), 0.0)
		for b in 3:
			_poner("books", Vector3(x, 0.42 + float(b) * 0.5, -7.25), 0.0)
	_prim("caja", Vector3(7.5, 2.6, -4.55), Vector3(3.6, 0.45, 0.1), Color(0.62, 0.12, 0.14))
	_cartel("PRENSA · REVISTAS", Vector3(7.5, 2.6, -4.48), 26)
	_trabajador(Vector3(7.2, 0, -5.8), 0.0, false, ["saludo_mano", "charla"], _calle())
	_trabajador(Vector3(6.9, 0, -3.95), PI, false, ["charla", "brazos_jarra"], _calle())
	for z: float in [-1.8, -0.7]:
		_poner("mini_arcade/vending-machine", Vector3(11.45, 0, z), -PI * 0.5, 2.2)
	## --- Cafetería (delante a la derecha): barra, cafetera, vitrina, carta y
	## mesas altas con gente tomando algo.
	var bar_ancho := _medida("kitchenBar", 2.5).x
	for k in 3:
		_poner("kitchenBar", Vector3(9.7, 0, 2.2 + float(k) * bar_ancho), -PI * 0.5, 2.5, {"wood": Color(0.42, 0.26, 0.16), "woodDark": Color(0.3, 0.18, 0.1)})
	var tope_bar := _alto("kitchenBar", 2.5)
	var z_fin := 2.2 + 2.0 * bar_ancho
	for k in 3:
		_poner("kitchenCabinet", Vector3(11.65, 0, 2.3 + float(k) * 1.0), -PI * 0.5)
	var tope_mueble := _alto("kitchenCabinet")
	_poner("kitchenCoffeeMachine", Vector3(11.65, tope_mueble, 2.4), -PI * 0.5)
	_poner("kitchenCoffeeMachine", Vector3(11.65, tope_mueble, 3.2), -PI * 0.5)
	for k in 6:
		_poner("comida/cup-saucer", Vector3(11.6, tope_mueble, 3.9 + float(k % 3) * 0.14), 0.0)
	## Vitrina de bollería sobre la barra.
	_prim("caja", Vector3(9.7, tope_bar + 0.2, z_fin - 0.3), Vector3(0.5, 0.4, 1.0), Color(0.82, 0.9, 0.95), "luz")
	for k in 6:
		_poner(["comida/croissant", "comida/donut-sprinkles", "comida/muffin"][k % 3], Vector3(9.7 + (0.1 if k < 3 else -0.1), tope_bar + 0.02, z_fin - 0.65 + float(k % 3) * 0.3), 0.0)
	for k in 3:
		_poner("comida/cup-coffee", Vector3(9.55, tope_bar, 2.4 + float(k) * 0.5), _rng.randf() * TAU)
	_prim("caja", Vector3(11.96, 3.1, 3.4), Vector3(0.04, 1.3, 2.6), oscuro)
	_texto("☕ CAFETERÍA\nCafé  1,20 · Cortado  1,40\nCroissant  1,50 · Bocadillo  3,50", Vector3(11.92, 3.1, 3.4), 22, Color(1.0, 0.92, 0.75), -PI * 0.5, false)
	_trabajador(Vector3(10.85, 0, 3.0), -PI * 0.5, false, ["charla", "saludo_mano", "brazos_jarra"], [Color(0.95, 0.95, 0.93), Color(0.15, 0.12, 0.1), true])
	_asiento("stoolBar", Vector3(8.95, 0, 4.0), PI * 0.5, [0.0], _calle())
	_poner("stoolBar", Vector3(8.95, 0, 3.1), PI * 0.5)
	for z: float in [2.4, 4.8]:
		var p := Vector3(7.3, 0, z)
		_prim("cil", p + Vector3(0, 0.015, 0), Vector3(0.5, 0.03, 0.5), hierro, "metal")
		_prim("cil", p + Vector3(0, 0.55, 0), Vector3(0.07, 1.08, 0.07), hierro, "metal")
		_prim("cil", p + Vector3(0, 1.1, 0), Vector3(0.75, 0.04, 0.75), Color(0.85, 0.82, 0.76))
		_poner("comida/cup-coffee", p + Vector3(0.12, 1.12, 0.05), _rng.randf() * TAU)
		_poner("comida/croissant", p + Vector3(-0.12, 1.12, -0.08), _rng.randf() * TAU)
	_trabajador(Vector3(6.75, 0, 2.4), PI * 0.5, false, ["charla", "brazos_jarra", "saludo_mano"], _calle())
	_trabajador(Vector3(7.8, 0, 2.55), -PI * 0.5, false, ["charla", "pedir_calma"], _calle())
	_trabajador(Vector3(7.35, 0, 5.3), PI, false, ["charla", "parado"], _calle())
	## --- Bancos de espera, espalda con espalda, con alguna maleta al lado.
	for x: float in [-5.9, 5.9]:
		for s: float in [-1.0, 1.0]:
			for k in 4:
				var p := Vector3(x - 1.2 + float(k) * 0.8, 0, 0.3 + s * 0.24)
				_asiento("bench", p, 0.0 if s > 0.0 else PI, [0.0] if _rng.randf() < 0.4 else [], _calle())
	_maleta(Vector3(-7.45, 0, 1.2), 0.2, Color(0.2, 0.3, 0.45), true)
	_maleta(Vector3(4.35, 0, -0.55), -0.4, Color(0.12, 0.12, 0.14), false)
	_maleta(Vector3(7.5, 0, 1.15), 1.4, Color(0.75, 0.55, 0.2), true)
	## Viajeros con maleta mirando el panel.
	var cols_maleta := [Color(0.2, 0.25, 0.35), Color(0.6, 0.12, 0.15), Color(0.25, 0.45, 0.35)]
	for k in 3:
		var p: Vector3 = [Vector3(-2.3, 0, -3.3), Vector3(2.2, 0, -3.2), Vector3(5.5, 0, -2.9)][k]
		_trabajador(p, PI + float(k - 1) * 0.25, false, ["charla", "brazos_jarra", "senalar_cielo"], _calle())
		_maleta(p + Vector3(0.42, 0, 0.12), 0.1 * float(k), cols_maleta[k], k != 1)
	## --- Reloj de doble esfera colgado sobre el vestíbulo (a un lado: en medio
	## tapaba el panel de salidas desde la puerta).
	var pr := Vector3(-5.8, 4.3, -1.0)
	_prim("cil", pr + Vector3(0, 1.7, 0), Vector3(0.05, 2.6, 0.05), hierro, "metal")
	_prim("cil", pr, Vector3(1.3, 0.2, 1.3), Color(0.2, 0.2, 0.22), "metal", Vector3(PI * 0.5, 0, 0))
	_reloj(Transform3D(Basis.IDENTITY, pr + Vector3(0, 0, 0.1)), 0.58, 10.27)
	_reloj(Transform3D(Basis(Vector3.UP, PI), pr - Vector3(0, 0, 0.1)), 0.58, 10.27)
	## Cartel de dirección colgado: andenes hacia el fondo, salida hacia la puerta.
	var pc := Vector3(0, 3.3, 3.0)
	for s: float in [-1.0, 1.0]:
		_prim("cil", pc + Vector3(s * 1.3, 1.9, 0), Vector3(0.02, 3.4, 0.02), hierro)
	_prim("caja", pc, Vector3(3.6, 0.6, 0.08), azul_rotulo)
	_prim("caja", pc, Vector3(3.7, 0.68, 0.06), Color(0.9, 0.9, 0.92))
	_texto("↑  ANDENES · VÍAS 1-3", pc + Vector3(0, 0, 0.05), 30, Color.WHITE, 0.0, false)
	_texto("↓  SALIDA · TAXI · BUS", pc - Vector3(0, 0, 0.05), 30, Color.WHITE, PI, false)
	## Anuncios iluminados en las paredes laterales.
	for s: float in [-1.0, 1.0]:
		var p := Vector3(s * 11.95, 3.6, -3.8)
		_prim("caja", p, Vector3(0.08, 1.8, 2.9), Color(0.25, 0.25, 0.27), "metal")
		_prim("caja", p - Vector3(s * 0.05, 0, 0), Vector3(0.02, 1.6, 2.7), Color(0.35, 0.6, 0.85) if s < 0.0 else Color(0.9, 0.55, 0.25), "luz")
	_texto("VISITA LA COSTA\nen tren, sin prisas", Vector3(-11.88, 3.6, -3.8), 30, Color.WHITE, PI * 0.5)
	_texto("NUEVO AEROPUERTO\nun tren cada 15'", Vector3(11.88, 3.6, -3.8), 30, Color.WHITE, -PI * 0.5)
	## --- Plantas, papeleras y la gente que va y viene.
	for p: Vector3 in [Vector3(-11.2, 0, 6.7), Vector3(11.2, 0, 6.7), Vector3(-11.2, 0, -6.9), Vector3(11.2, 0, -6.9)]:
		_planta(p)
	for p: Vector3 in [Vector3(-4.4, 0, -2.6), Vector3(4.4, 0, -2.6), Vector3(-2.4, 0, 3.4)]:
		_poner("trashcan", p, 0.0, 1.4)
	## Rutas fijas (sin desvío): a los tornos abiertos y de vuelta, cruzando el
	## vestíbulo entre las columnas y los bancos, y de la puerta a la cafetería.
	var rutas := [
		[Vector3(-0.75, 0, 6.2), Vector3(-0.75, 0, -6.3)],
		[Vector3(0.75, 0, -6.3), Vector3(0.75, 0, 6.2)],
		[Vector3(-10.4, 0, -1.4), Vector3(10.2, 0, -1.4)],
		[Vector3(9.8, 0, -1.25), Vector3(-10.2, 0, -1.25)],
		[Vector3(-7.6, 0, 2.15), Vector3(-1.6, 0, 5.6), Vector3(1.6, 0, 5.6), Vector3(5.4, 0, 2.15)],
		[Vector3(1.4, 0, 6.0), Vector3(5.6, 0, 3.6), Vector3(5.6, 0, 6.2)],
	]
	for k in rutas.size():
		var ruta: Array = rutas[k]
		_caminante(ruta, _calle(), k == 2)
		if _caminantes.is_empty():
			continue
		var c: Dictionary = _caminantes[-1]
		c["puntos"] = ruta
		var a: Vector3 = ruta[0]
		var b: Vector3 = ruta[1]
		(c["d"]["nodo"] as Node3D).position = a.lerp(b, _rng.randf_range(0.15, 0.85))
		c["i"] = 1
		## Algunos tiran de su maleta de ruedas.
		if k == 1 or k == 3:
			_maleta_de(c["d"]["nodo"], cols_maleta[k % 3])
