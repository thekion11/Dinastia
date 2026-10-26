class_name SalasClub
extends RefCounted
## EL MUSEO Y LA UTILERÍA DEL EDIFICIO DEL CLUB, AMUEBLADOS DE VERDAD
## (26-10-2026, paquete pint).
##
## Vistas con la cámara del paseo, las dos salas parecían vacías: el museo era
## una fila de cajas negras al fondo con un cilindro dentro y una caja de color
## en la pared; la utilería, tres tablas flotando, un cubo con cuatro bolas y
## cinco rectángulos negros por camisetas. Ahora:
##   museo     vitrinas iluminadas a los dos lados con una copa (asas, pie y
##             peana) por título o un balón antiguo si aún no hay copa; al
##             fondo, camisetas históricas enmarcadas con su año; una alfombra
##             del club marca el recorrido y dos luces cálidas lo alumbran.
##   utilería  estantería metálica con botas, ropa doblada y balones; burro
##             con las camisetas colgadas (`PiezasVestuario.camiseta`); jaula de
##             balones, cesto de toallas, conos y la lavadora.
## Como en las taquillas, todas las piezas de una sala van en un `Lote` (una
## malla por material) y lo sólido lleva su caja de choque (`ColisionClub`).

## Una caja de choque sin malla (lo que la malla del lote no trae).
static func _choque(nodo: Node3D, pos: Vector3, tam: Vector3) -> void:
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = tam
	forma.shape = bs
	cuerpo.add_child(forma)
	cuerpo.position = pos
	nodo.add_child(cuerpo)

static func _en(p: Vector3, giro := 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, giro), p)

static func _cilindro(r_arriba: float, r_abajo: float, alto: float) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = r_arriba
	cm.bottom_radius = r_abajo
	cm.height = alto
	cm.radial_segments = 16
	cm.rings = 1
	return cm

static func _esfera(r: float) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 7
	return sm

## Una copa con su peana: pie, tallo, copa abierta y dos asas. `p` es la base.
static func copa(lote: PiezasVestuario.Lote, p: Vector3, oro: Material, peana: Material) -> void:
	lote.caja(peana, _en(p + Vector3(0, 0.04, 0)), Vector3(0.24, 0.08, 0.24))
	lote.malla(oro, _en(p + Vector3(0, 0.11, 0)), _cilindro(0.06, 0.08, 0.06))
	lote.malla(oro, _en(p + Vector3(0, 0.2, 0)), _cilindro(0.025, 0.035, 0.12))
	lote.malla(oro, _en(p + Vector3(0, 0.36, 0)), _cilindro(0.14, 0.05, 0.2))
	for s: float in [-1.0, 1.0]:
		var asa := TorusMesh.new()
		asa.inner_radius = 0.035
		asa.outer_radius = 0.055
		asa.rings = 12
		asa.ring_segments = 6
		lote.malla(oro, Transform3D(Basis(Vector3.FORWARD, PI / 2.0), p + Vector3(s * 0.15, 0.37, 0)), asa)

static func museo(nodo: Node3D, caja: Rect2, y0: float, c1: Color, c2: Color, titulos: int, nivel_museo: int) -> PiezasVestuario.Lote:
	var lote := PiezasVestuario.Lote.new()
	var m := PiezasVestuario.materiales(c1, c2)
	var oro: StandardMaterial3D = Texturas.metal(Color(0.95, 0.78, 0.3), 0.22)
	var base := TunelVestuario._mat(Color(0.1, 0.1, 0.12), 0.4)
	## Vidrio de vitrina de verdad, transparente (`Texturas.cristal` es el de
	## las ventanas de fachada: opaco y encendido, tapaba la copa).
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.86, 0.93, 1.0, 0.16)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.roughness = 0.04
	vidrio.metallic_specular = 0.9
	vidrio.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cuero := TunelVestuario._mat(Color(0.45, 0.28, 0.14), 0.6)
	var cx := caja.get_center().x
	## La alfombra del recorrido, de la puerta al fondo, con ribete.
	lote.caja(m["placa"], _en(Vector3(cx, y0 + 0.035, caja.get_center().y)), Vector3(1.3, 0.01, caja.size.y - 0.3))
	lote.caja(m["cojin"], _en(Vector3(cx, y0 + 0.04, caja.get_center().y)), Vector3(1.1, 0.01, caja.size.y - 0.5))
	## Las vitrinas, alternando lado, en el tramo libre (ni la puerta ni el fondo).
	var vitrinas := clampi(2 + nivel_museo / 2, 2, 6)
	var por_lado := int(ceil(float(vitrinas) / 2.0))
	var z0 := caja.position.y + 1.7
	var z1 := caja.end.y - 1.6
	for k in vitrinas:
		var lado := -1.0 if k % 2 == 0 else 1.0
		var i := k / 2
		var pz := z0 + (z1 - z0) * (float(i) + 0.5) / float(por_lado)
		var px := (caja.position.x + 0.45) if lado < 0.0 else (caja.end.x - 0.45)
		lote.caja(base, _en(Vector3(px, y0 + 0.5, pz)), Vector3(0.7, 1.0, 0.7))
		lote.caja(m["placa"], _en(Vector3(px, y0 + 0.98, pz)), Vector3(0.74, 0.04, 0.74))
		lote.caja(vidrio, _en(Vector3(px, y0 + 1.45, pz)), Vector3(0.68, 0.9, 0.68))
		## Cantoneras de acero en las cuatro aristas del vidrio: el techo de la
		## vitrina se apoya en algo que se ve (sin ellas, con el vidrio casi
		## invisible, la tapa parecía una losa flotando a 2 m).
		for e in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			pass #			lote.caja(m["metal"], _en(Vector3(px + e.x * 0.345, y0 + 1.445, pz + e.y * 0.345)), Vector3(0.03, 0.9, 0.03))
		lote.caja(base, _en(Vector3(px, y0 + 1.92, pz)), Vector3(0.74, 0.06, 0.74))
		lote.caja(m["tira"], _en(Vector3(px, y0 + 1.885, pz)), Vector3(0.5, 0.01, 0.5))
		_choque(nodo, Vector3(px, y0 + 1.0, pz), Vector3(0.74, 2.0, 0.74))
		if k < titulos:
			copa(lote, Vector3(px, y0 + 1.0, pz), oro, m["madera"])
		else:
			## Aún sin copa: un balón de cuero antiguo en su soporte.
			lote.malla(m["metal"], _en(Vector3(px, y0 + 1.05, pz)), _cilindro(0.06, 0.08, 0.06))
			lote.malla(cuero, _en(Vector3(px, y0 + 1.19, pz)), _esfera(0.11))
	## Al fondo, las camisetas históricas enmarcadas con su año.
	var n_marcos := 3 if caja.size.x > 3.2 else 2
	var anios := [1931, 1968, 1994]
	for k in n_marcos:
		var px := caja.position.x + caja.size.x * (float(k) + 0.5) / float(n_marcos)
		var pz := caja.position.y - 0.13
		lote.caja(base, _en(Vector3(px, y0 + 1.55, pz)), Vector3(0.95, 1.15, 0.05))
		lote.caja(m["toalla"], _en(Vector3(px, y0 + 1.55, pz + 0.03)), Vector3(0.85, 1.05, 0.01))
		var alterna := k % 2 == 1
		PiezasVestuario.camiseta(lote, _en(Vector3(px, y0 + 1.6, pz + 0.06)), m["cam2"] if alterna else m["cam1"], m["cam1"] if alterna else m["cam2"])
		TunelVestuario._rotulo(nodo, str(anios[k % anios.size()]), Vector3(px, y0 + 1.07, pz + 0.07), 0.0, 22, Color(0.12, 0.12, 0.14))
	## Una franja con los colores del club bajo el rótulo de los títulos.
	lote.caja(m["cam1"], _en(Vector3(cx, y0 + 2.62, caja.position.y - 0.14)), Vector3(caja.size.x, 0.36, 0.02))
	lote.montar(nodo, "Museo")
	TunelVestuario._rotulo(nodo, Idiomas.t("%d títulos") % titulos, Vector3(cx, y0 + 2.62, caja.position.y - 0.11), 0.0, 44,
		Color(1.0, 0.86, 0.45))
	_luces_museo(nodo, caja, y0, cx)
	return lote

static func _luces_museo(nodo: Node3D, caja: Rect2, y0: float, cx: float) -> void:
	## Luz cálida de museo sobre cada fila de vitrinas.
	for f in [0.3, 0.72]:
		var o := OmniLight3D.new()
		o.position = Vector3(cx, y0 + 2.9, caja.position.y + caja.size.y * f)
		o.omni_range = 4.5
		o.light_energy = 0.7
		o.light_color = Color(1, 0.9, 0.75)
		nodo.add_child(o)

static func utileria(nodo: Node3D, caja: Rect2, y0: float, c1: Color, c2: Color) -> PiezasVestuario.Lote:
	var lote := PiezasVestuario.Lote.new()
	var m := PiezasVestuario.materiales(c1, c2)
	var acero: StandardMaterial3D = Texturas.metal(Color(0.55, 0.58, 0.62), 0.4)
	var cuero := TunelVestuario._mat(Color(0.96, 0.96, 0.96), 0.45)
	var naranja := TunelVestuario._mat(Color(1.0, 0.45, 0.1), 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	## LA ESTANTERÍA de la pared izquierda: montantes, cuatro baldas y lo suyo.
	var xs := caja.position.x + 0.3
	var z0 := caja.position.y + 0.4
	var largo := caja.size.y - 2.0
	var cz := z0 + largo / 2.0
	for k in int(largo / 1.2) + 1:
		lote.caja(acero, _en(Vector3(xs, y0 + 1.1, z0 + minf(float(k) * 1.2, largo))), Vector3(0.5, 2.2, 0.04))
	for b in 4:
		var yb := y0 + 0.25 + float(b) * 0.6
		lote.caja(acero, _en(Vector3(xs, yb, cz)), Vector3(0.5, 0.03, largo))
		var z := z0 + 0.25
		while z < z0 + largo - 0.25:
			match b:
				0:
					## Abajo, los pares de botas.
					for s: float in [-1.0, 1.0]:
						lote.caja(m["bota"], _en(Vector3(xs + s * 0.06, yb + 0.06, z), PI / 2.0), Vector3(0.1, 0.09, 0.27))
					z += 0.3
				1:
					## La ropa doblada en montones del color del club.
					var alto := rng.randf_range(0.08, 0.22)
					lote.caja(m["cam1"] if rng.randf() < 0.65 else m["cam2"], _en(Vector3(xs, yb + 0.015 + alto / 2.0, z)), Vector3(0.36, alto, 0.3))
					z += 0.38
				_:
					lote.malla(cuero, _en(Vector3(xs, yb + 0.125, z)), _esfera(0.11))
					z += 0.26
	_choque(nodo, Vector3(xs, y0 + 1.1, cz), Vector3(0.5, 2.2, largo))
	## EL BURRO DE LAS CAMISETAS en la pared derecha, mirando a la sala.
	var xb := caja.end.x - 0.35
	var lb := minf(caja.size.y - 2.4, 4.2)
	## Del lado de la puerta (al fondo va la lavadora).
	var zb := caja.end.y - 0.9 - lb / 2.0
	for s: float in [-1.0, 1.0]:
		lote.caja(acero, _en(Vector3(xb, y0 + 0.95, zb + s * lb / 2.0)), Vector3(0.04, 1.9, 0.04))
	lote.caja(acero, _en(Vector3(xb, y0 + 1.88, zb)), Vector3(0.03, 0.03, lb))
	var n := int(lb / 0.55)
	for k in n:
		var z := zb - lb / 2.0 + (float(k) + 0.5) * lb / float(n)
		PiezasVestuario.camiseta(lote, _en(Vector3(xb, y0 + 1.48, z), -PI / 2.0 + rng.randf_range(-0.08, 0.08)), m["cam1"], m["cam2"])
	_choque(nodo, Vector3(xb, y0 + 1.0, zb), Vector3(0.45, 2.0, lb))
	## LA JAULA DE BALONES, el cesto de toallas y los conos, en el centro.
	var cx := caja.get_center().x + 0.2
	var zj := caja.position.y + 1.0
	for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		lote.caja(acero, _en(Vector3(cx + s.x * 0.4, y0 + 0.45, zj + s.y * 0.3)), Vector3(0.03, 0.9, 0.03))
	for yy in [0.05, 0.9]:
		lote.caja(acero, _en(Vector3(cx, y0 + yy, zj - 0.3)), Vector3(0.83, 0.03, 0.03))
		lote.caja(acero, _en(Vector3(cx, y0 + yy, zj + 0.3)), Vector3(0.83, 0.03, 0.03))
	for k in 9:
		lote.malla(cuero, _en(Vector3(cx - 0.25 + float(k % 3) * 0.25, y0 + 0.17 + float(k / 6) * 0.2, zj - 0.2 + float((k / 3) % 2) * 0.22 + float(k / 6) * 0.1)), _esfera(0.11))
	_choque(nodo, Vector3(cx, y0 + 0.45, zj), Vector3(0.85, 0.9, 0.65))
	## El cesto y los conos, en la esquina de la puerta (el paso queda libre).
	var zc := caja.end.y - 0.7
	var xc := caja.position.x + 0.45
	lote.caja(m["fondo"], _en(Vector3(xc, y0 + 0.3, zc)), Vector3(0.6, 0.6, 0.45))
	lote.caja(m["toalla"], _en(Vector3(xc, y0 + 0.62, zc)), Vector3(0.52, 0.08, 0.38))
	_choque(nodo, Vector3(xc, y0 + 0.35, zc), Vector3(0.6, 0.7, 0.45))
	for k in 3:
		lote.malla(naranja, _en(Vector3(xc + 0.65, y0 + 0.12 + float(k) * 0.05, zc)), _cilindro(0.015, 0.12, 0.22))
	## La lavadora al fondo, con su ojo de buey.
	var xl := caja.end.x - 0.5
	var zl := caja.position.y + 0.4
	lote.caja(m["toalla"], _en(Vector3(xl, y0 + 0.43, zl)), Vector3(0.62, 0.86, 0.6))
	lote.malla(m["placa"], Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(xl, y0 + 0.4, zl + 0.3)), _cilindro(0.2, 0.2, 0.02))
	_choque(nodo, Vector3(xl, y0 + 0.43, zl), Vector3(0.62, 0.86, 0.6))
	lote.montar(nodo, "Utileria")
	return lote
