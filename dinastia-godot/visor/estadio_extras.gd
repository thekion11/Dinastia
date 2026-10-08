class_name EstadioExtras
extends RefCounted
## LO QUE FALTABA EN 3D DEL ESTADIO (26-9-2026). Pedido: *"mejorar los estadios
## e implementar todos los modelos 3D pendientes"*. Del plan B6/B10 quedaban:
##   - las OBRAS POR ETAPAS: andamios con red, una grúa torre y el vallado de
##     obra mientras se construye algo (`Instalaciones.obras`);
##   - las INSTALACIONES INTERNAS VISIBLES: palcos VIP acristalados e
##     iluminados sobre la tribuna principal, la cabina de prensa, el museo y
##     la tienda del club por fuera, según lo que el club haya construido;
##   - la MASCOTA del club en la banda (B10), saludando.
## Todo con geometría procedural y MultiMesh donde hay muchas piezas iguales
## (los tubos del andamio), para no costar fotogramas.
##
## `est` trae, además del perfil de siempre:
##   en_obra  claves de `Instalaciones.CATALOGO` en obra
##   inst     {clave: nivel} de lo construido

static func construir(root: Node3D, est: Dictionary, dx: float, dz: float, alto: float, niveles: int, mi: Club) -> void:
	var en_obra: Array = est.get("en_obra", [])
	if not en_obra.is_empty():
		obras(root, dx, dz, alto, niveles, en_obra)
	var inst: Dictionary = est.get("inst", {})
	instalaciones(root, dx, alto, niveles, inst, mi)
	if mi != null and bool(est.get("mascota", true)):
		mascota(root, mi)

static func _mat(col: Color, rug: float = 0.7, emision: float = 0.0, alfa: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col, alfa)
	m.roughness = rug
	if emision > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emision
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func _caja(root: Node3D, pos: Vector3, tam: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	root.add_child(mi)
	return mi

## Muchos tubos iguales en un MultiMesh: [desde, hasta] en metros.
static func _tubos(root: Node3D, tramos: Array, radio: float, m: Material) -> void:
	if tramos.is_empty():
		return
	var cm := CylinderMesh.new()
	cm.top_radius = radio
	cm.bottom_radius = radio
	cm.height = 1.0
	cm.radial_segments = 6
	cm.rings = 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cm
	mm.instance_count = tramos.size()
	for i in tramos.size():
		var a: Vector3 = tramos[i][0]
		var b: Vector3 = tramos[i][1]
		var d := b - a
		var largo := d.length()
		var y := d.normalized()
		var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var z := x.cross(y).normalized()
		var bas := Basis(x, y * largo, z)
		mm.set_instance_transform(i, Transform3D(bas, (a + b) * 0.5))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = m
	root.add_child(mmi)

# -----------------------------------------------------------------------------
#  OBRAS
# -----------------------------------------------------------------------------

## Andamio con red por fuera del fondo norte, grúa torre, vallado y casetas.
static func obras(root: Node3D, dx: float, dz: float, alto: float, niveles: int, en_obra: Array) -> void:
	var obra := Node3D.new()
	obra.name = "Obras"
	root.add_child(obra)
	var acero := _mat(Color(0.62, 0.64, 0.66), 0.4)
	var madera := _mat(Color(0.55, 0.4, 0.24), 0.9)
	var red := _mat(Color(0.1, 0.45, 0.2), 0.9, 0.0, 0.55)
	## La cara exterior del fondo norte.
	var cara := StadiumBuilder.centro_tribuna(dz, niveles) + StadiumBuilder.fondo_tribuna(niveles) * 0.5 + 0.6
	var ancho := dx * 1.1
	var alto_and := alto + 2.5
	var tramos: Array = []
	var paso := 2.0
	var x := -ancho * 0.5
	while x <= ancho * 0.5 + 0.01:
		for fila in [0.0, 1.2]:
			tramos.append([Vector3(x, 0.0, cara + fila), Vector3(x, alto_and, cara + fila)])
		x += paso
	var y := 2.0
	while y <= alto_and + 0.01:
		for fila in [0.0, 1.2]:
			tramos.append([Vector3(-ancho * 0.5, y, cara + fila), Vector3(ancho * 0.5, y, cara + fila)])
		## Travesaños y plataforma de tablones en cada nivel.
		var xx := -ancho * 0.5
		while xx <= ancho * 0.5 + 0.01:
			tramos.append([Vector3(xx, y, cara), Vector3(xx, y, cara + 1.2)])
			xx += paso
		_caja(obra, Vector3(0, y + 0.03, cara + 0.6), Vector3(ancho, 0.05, 1.1), madera)
		y += 2.0
	## Diagonales de arriostramiento.
	var xd := -ancho * 0.5
	var sube := true
	while xd < ancho * 0.5 - 0.01:
		var y0 := 0.0
		while y0 < alto_and - 2.0:
			tramos.append([Vector3(xd, y0, cara + 1.2), Vector3(xd + paso, y0 + 2.0, cara + 1.2)] if sube else [Vector3(xd + paso, y0, cara + 1.2), Vector3(xd, y0 + 2.0, cara + 1.2)])
			y0 += 2.0
		sube = not sube
		xd += paso * 2.0
	_tubos(obra, tramos, 0.035, acero)
	## Red de obra por fuera.
	var mi_red := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(ancho, alto_and)
	mi_red.mesh = q
	mi_red.material_override = red
	mi_red.position = Vector3(0, alto_and * 0.5, cara + 1.35)
	obra.add_child(mi_red)
	## La grúa torre, detrás del fondo, con la pluma sobre la grada.
	grua(obra, Vector3(dx * 0.35, 0.0, cara + 16.0), alto + 26.0, -110.0)
	## Vallado de obra y casetas.
	var valla := _mat(Color(0.95, 0.75, 0.1), 0.6)
	_caja(obra, Vector3(0, 1.0, cara + 24.0), Vector3(ancho + 12.0, 2.0, 0.08), valla)
	_caja(obra, Vector3(-ancho * 0.5 - 6.0, 1.0, cara + 12.5), Vector3(0.08, 2.0, 23.0), valla)
	_caja(obra, Vector3(ancho * 0.5 + 6.0, 1.0, cara + 12.5), Vector3(0.08, 2.0, 23.0), valla)
	for i in 3:
		var col: Color = [Color(0.85, 0.85, 0.82), Color(0.2, 0.45, 0.75), Color(0.8, 0.3, 0.15)][i]
		_caja(obra, Vector3(-ancho * 0.5 + 3.0 + i * 6.5, 1.3, cara + 20.0), Vector3(6.0, 2.6, 2.4), _mat(col, 0.6))
	## Cartel de la obra.
	var cartel := Label3D.new()
	var nombres: Array[String] = []
	for k: String in en_obra:
		if k == "reforma":
			nombres.append(Idiomas.t("REFORMA DEL ESTADIO"))
			continue
		nombres.append(String((Instalaciones.CATALOGO.get(k, [k]) as Array)[0]).to_upper())
	cartel.text = "EN OBRA: %s" % ", ".join(nombres)
	cartel.font_size = 96
	cartel.pixel_size = 0.02
	cartel.modulate = Color(1, 0.85, 0.2)
	cartel.outline_size = 10
	cartel.position = Vector3(0, 3.2, cara + 24.1)
	cartel.rotation_degrees.y = 180.0
	obra.add_child(cartel)

## Una grúa torre: mástil de celosía, cabina, pluma, contrapluma con
## contrapeso, cable y gancho con una viga colgando.
static func grua(root: Node3D, base: Vector3, altura: float, giro: float) -> void:
	var g := Node3D.new()
	g.position = base
	g.rotation_degrees.y = giro
	root.add_child(g)
	var amarillo := _mat(Color(0.96, 0.74, 0.08), 0.5)
	var gris := _mat(Color(0.3, 0.32, 0.34), 0.6)
	var tramos: Array = []
	var l := 1.0
	for esq in [Vector2(-l, -l), Vector2(l, -l), Vector2(l, l), Vector2(-l, l)]:
		tramos.append([Vector3(esq.x, 0, esq.y), Vector3(esq.x, altura, esq.y)])
	var yy := 0.0
	while yy < altura:
		## Celosía: horizontales y diagonales en las cuatro caras.
		for c in 4:
			var a: Vector2 = [Vector2(-l, -l), Vector2(l, -l), Vector2(l, l), Vector2(-l, l)][c]
			var b: Vector2 = [Vector2(l, -l), Vector2(l, l), Vector2(-l, l), Vector2(-l, -l)][c]
			tramos.append([Vector3(a.x, yy, a.y), Vector3(b.x, yy, b.y)])
			tramos.append([Vector3(a.x, yy, a.y), Vector3(b.x, yy + 2.0, b.y)])
		yy += 2.0
	## Pluma (40 m) y contrapluma (14 m), en celosía triangular.
	var largo := 40.0
	var x := 0.0
	while x < largo:
		tramos.append([Vector3(x, altura, -0.8), Vector3(x + 2.0, altura, -0.8)])
		tramos.append([Vector3(x, altura, 0.8), Vector3(x + 2.0, altura, 0.8)])
		tramos.append([Vector3(x, altura + 1.6, 0.0), Vector3(x + 2.0, altura + 1.6, 0.0)])
		tramos.append([Vector3(x, altura, -0.8), Vector3(x + 1.0, altura + 1.6, 0.0)])
		tramos.append([Vector3(x + 1.0, altura + 1.6, 0.0), Vector3(x + 2.0, altura, 0.8)])
		x += 2.0
	x = 0.0
	while x > -14.0:
		tramos.append([Vector3(x, altura, -0.9), Vector3(x - 2.0, altura, -0.9)])
		tramos.append([Vector3(x, altura, 0.9), Vector3(x - 2.0, altura, 0.9)])
		x -= 2.0
	## Tirantes desde la punta del mástil.
	tramos.append([Vector3(0, altura + 7.0, 0), Vector3(largo * 0.6, altura + 1.6, 0)])
	tramos.append([Vector3(0, altura + 7.0, 0), Vector3(-13.0, altura, 0)])
	for esq in [Vector2(-l, -l), Vector2(l, -l), Vector2(l, l), Vector2(-l, l)]:
		tramos.append([Vector3(esq.x, altura, esq.y), Vector3(0, altura + 7.0, 0)])
	_tubos(g, tramos, 0.09, amarillo)
	_caja(g, Vector3(-11.5, altura - 0.2, 0), Vector3(3.0, 2.2, 2.4), gris)             ## contrapeso
	_caja(g, Vector3(1.6, altura - 1.4, 1.6), Vector3(1.8, 2.0, 1.8), _mat(Color(0.9, 0.9, 0.88), 0.4))  ## cabina
	_caja(g, Vector3(0, 0.6, 0), Vector3(4.5, 1.2, 4.5), gris)                            ## zapata
	## Carro, cable, gancho y la viga colgando.
	var carro_x := largo * 0.7
	_caja(g, Vector3(carro_x, altura - 0.3, 0), Vector3(1.4, 0.5, 1.8), gris)
	var cuelga := altura * 0.55
	_tubos(g, [[Vector3(carro_x, altura - 0.5, 0), Vector3(carro_x, altura - cuelga, 0)]], 0.03, gris)
	_caja(g, Vector3(carro_x, altura - cuelga - 0.3, 0), Vector3(0.5, 0.6, 0.3), amarillo)
	_caja(g, Vector3(carro_x, altura - cuelga - 1.0, 0), Vector3(6.0, 0.35, 0.35), _mat(Color(0.7, 0.25, 0.1), 0.5))
	## Luz de balizamiento roja en la punta.
	_caja(g, Vector3(0, altura + 7.2, 0), Vector3(0.3, 0.3, 0.3), _mat(Color(1, 0.1, 0.05), 0.3, 4.0))

# -----------------------------------------------------------------------------
#  INSTALACIONES VISIBLES
# -----------------------------------------------------------------------------

## Palcos VIP sobre la tribuna principal (la de enfrente de la cámara de TV),
## cabina de prensa, y museo y tienda por fuera. Cuánto se ve depende de lo
## construido: "cal" y "com" dan palcos; "pren", la cabina; "museo" y "com",
## los edificios de fuera.
static func instalaciones(root: Node3D, dx: float, alto: float, niveles: int, inst: Dictionary, mi: Club) -> void:
	var nodo := Node3D.new()
	nodo.name = "Instalaciones"
	root.add_child(nodo)
	var cara_ext := -(StadiumBuilder.centro_tribuna(dx, niveles) + StadiumBuilder.fondo_tribuna(niveles) * 0.5)
	var col_club := Color(mi.color1) if mi != null else Color(0.2, 0.3, 0.5)
	var n_palcos := clampi(2 + int(inst.get("cal", 0)) + int(inst.get("com", 0)), 2, 14)
	## La fila de palcos, en lo alto de la tribuna, acristalada y encendida.
	var ancho_palco := 4.2
	var largo_fila := ancho_palco * float(n_palcos)
	var y_p := alto + 1.4
	var x_p := cara_ext + 2.2
	var vidrio := _mat(Color(0.75, 0.88, 1.0), 0.05, 0.0, 0.35)
	var interior := _mat(Color(1.0, 0.86, 0.6), 0.6, 1.6)
	var marco := _mat(Color(0.12, 0.13, 0.15), 0.4)
	_caja(nodo, Vector3(x_p, y_p - 1.45, 0), Vector3(4.6, 0.3, largo_fila + 0.6), marco)        ## losa
	_caja(nodo, Vector3(x_p, y_p + 1.45, 0), Vector3(4.8, 0.3, largo_fila + 1.0), _mat(col_club, 0.5))  ## cubierta con el color del club
	_caja(nodo, Vector3(x_p - 2.0, y_p, 0), Vector3(0.12, 2.6, largo_fila), interior)            ## fondo iluminado
	var cristal := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(largo_fila, 2.6)
	cristal.mesh = q
	cristal.material_override = vidrio
	cristal.position = Vector3(x_p + 2.2, y_p, 0)
	cristal.rotation_degrees.y = 90.0
	nodo.add_child(cristal)
	for i in n_palcos + 1:
		var z := -largo_fila * 0.5 + float(i) * ancho_palco
		_caja(nodo, Vector3(x_p, y_p, z), Vector3(4.4, 2.6, 0.12), marco)                   ## separadores
	var rot := Label3D.new()
	rot.text = "PALCOS VIP"
	rot.font_size = 72
	rot.pixel_size = 0.02
	rot.modulate = Color(1, 0.9, 0.6)
	rot.outline_size = 8
	rot.position = Vector3(x_p + 2.45, y_p + 1.9, 0)
	rot.rotation_degrees.y = 90.0
	nodo.add_child(rot)
	## Cabina de prensa, al lado.
	if int(inst.get("pren", 0)) > 0:
		var zp := largo_fila * 0.5 + 4.5
		_caja(nodo, Vector3(x_p, y_p, zp), Vector3(4.4, 2.6, 7.0), _mat(Color(0.16, 0.18, 0.22), 0.5))
		_caja(nodo, Vector3(x_p + 2.21, y_p + 0.3, zp), Vector3(0.05, 1.3, 6.2), _mat(Color(0.5, 0.75, 1.0), 0.1, 1.2))
		var rp := Label3D.new()
		rp.text = "PRENSA"
		rp.font_size = 64
		rp.pixel_size = 0.02
		rp.outline_size = 8
		rp.position = Vector3(x_p + 2.3, y_p + 1.8, zp)
		rp.rotation_degrees.y = 90.0
		nodo.add_child(rp)
	## Por fuera: museo y tienda.
	var fuera := cara_ext - 14.0
	if int(inst.get("museo", 0)) > 0:
		_edificio(nodo, Vector3(fuera, 0, -24.0), Vector3(14.0, 7.0 + int(inst.get("museo", 0)) * 0.6, 18.0), Color(0.86, 0.84, 0.8), "MUSEO DEL CLUB", col_club)
	if int(inst.get("com", 0)) > 0:
		_edificio(nodo, Vector3(fuera, 0, 24.0), Vector3(12.0, 6.0, 16.0), Color(0.18, 0.2, 0.24), "TIENDA OFICIAL", col_club)

static func _edificio(root: Node3D, base: Vector3, tam: Vector3, col: Color, rotulo: String, acento: Color) -> void:
	_caja(root, base + Vector3(0, tam.y * 0.5, 0), tam, _mat(col, 0.6))
	## Vidriera iluminada y banda con el color del club.
	_caja(root, base + Vector3(tam.x * 0.5 + 0.02, 2.0, 0), Vector3(0.05, 3.0, tam.z * 0.8), _mat(Color(1.0, 0.9, 0.7), 0.2, 1.3))
	_caja(root, base + Vector3(tam.x * 0.5 + 0.05, tam.y - 0.8, 0), Vector3(0.1, 1.2, tam.z), _mat(acento, 0.5, 0.6))
	var r := Label3D.new()
	r.text = rotulo
	r.font_size = 72
	r.pixel_size = 0.018
	r.outline_size = 8
	r.position = base + Vector3(tam.x * 0.5 + 0.2, tam.y - 0.8, 0)
	r.rotation_degrees.y = 90.0
	root.add_child(r)

# -----------------------------------------------------------------------------
#  LA MASCOTA (B10)
# -----------------------------------------------------------------------------

## El animal de la mascota sale del hash del club: siempre el mismo. La
## lista y el traje están en `MascotaQ` (26-9-2026: de 8 a 17 animales).
static func animal_de(c: Club) -> String:
	var lista: Array = MascotaQ.ANIMALES.keys()
	return String(lista[absi(hash(c.id + "|mascota")) % lista.size()])

## La mascota del club en la banda, animando a la hinchada.
static func mascota(root: Node3D, c: Club) -> Node3D:
	return MascotaQ.crear(root, c, animal_de(c), Vector3(-35.6, 0, -12.0), 90.0)
