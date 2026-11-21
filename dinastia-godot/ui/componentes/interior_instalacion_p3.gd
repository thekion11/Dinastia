extends "res://ui/componentes/interior_instalacion_p2.gd"
## [Capa 3/7 de `interior_instalacion.gd`] _cuadro, _comisaria, _bomberos, _aula, _prim, _texto … (+4)

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
	var reja := Mini3D.mat_unico(Color(0.3, 0.3, 0.32), 0.3)
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
