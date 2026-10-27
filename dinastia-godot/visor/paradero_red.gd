class_name ParaderoRed
extends RefCounted
## EL PARADERO COMO LOS DE SANTIAGO DE CHILE (27-10-2026, orden del dueño: «son hermosos: que se reconozcan»). Referencia (de memoria; las
## webs de Red/DTPM no se pueden abrir desde el contenedor): el paradero de la Red Metropolitana de Movilidad (ex Transantiago) es una
## marquesina de acero gris con el techo plano de poco vuelo, panel trasero translúcido con los mapas de recorrido en póster, panel lateral
## de cristal, banca de láminas metálicas corrida, y APARTE un poste con el cartel del paradero: franja verde con «PARADERO», el CÓDIGO
## grande («PA» y tres o cuatro cifras), un QR, y los recorridos que paran ahí en cajitas de color. El techo lleva una franja burdeos
## con el rótulo «Red». Todo en el marco local de la marquesina: la banca a z = −0,9, la trasera a z = −1,4 y el frente abierto a +z.
##   ParaderoRed.montar(raiz, ancho, semilla)   (raiz = nodo en el suelo, ya girado; ancho = largo de la marquesina)
const GRIS := Color(0.43, 0.45, 0.48)
const BURDEOS := Color(0.55, 0.10, 0.28)
const VERDE := Color(0.0, 0.56, 0.36)
const COLORES_RUTA := [Color(0.0, 0.5, 0.75), Color(0.85, 0.35, 0.1), Color(0.0, 0.6, 0.35), Color(0.55, 0.2, 0.6), Color(0.8, 0.15, 0.2)]

static var _mats: Dictionary = {}
static var _qr: ImageTexture = null
static var _afiche: Dictionary = {}

static func _mat(c: Color, rug := 0.6, metal := 0.0, sin_luz := false) -> StandardMaterial3D:
	var k := "%s|%.2f|%.2f|%s" % [c.to_html(true), rug, metal, str(sin_luz)]
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rug
		m.metallic = metal
		if c.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		if sin_luz:
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mats[k] = m
	return _mats[k]

static func _caja(p: Node3D, pos: Vector3, tam: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if tam.y < 0.2 and tam.x < 0.6 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	p.add_child(mi)
	return mi

static func _texto(p: Node3D, txt: String, pos: Vector3, tam_px: int, col: Color, giro_y := 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = txt
	l.font_size = tam_px
	l.pixel_size = 0.0012
	l.modulate = col
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.position = pos
	l.rotation.y = giro_y
	p.add_child(l)
	return l

## Un QR de mentira pero con pinta de QR: tres marcas de esquina y el resto a hash (determinista, 25 × 25).
static func qr() -> ImageTexture:
	if _qr != null:
		return _qr
	var n := 25
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	for y in n:
		for x in n:
			var en_marca := (x < 8 and y < 8) or (x >= n - 8 and y < 8) or (x < 8 and y >= n - 8)
			if en_marca:
				var mx := x % (n - 8) if x >= n - 8 else x
				var my := y - (n - 8) if y >= n - 8 else y
				if x >= n - 8:
					mx = x - (n - 8)
				var borde := mx == 0 or mx == 6 or my == 0 or my == 6
				var centro := mx >= 2 and mx <= 4 and my >= 2 and my <= 4
				img.set_pixel(x, y, Color.BLACK if (borde or centro) and mx < 7 and my < 7 else Color.WHITE)
			elif absi(hash([x, y, 77])) % 100 < 48:
				img.set_pixel(x, y, Color.BLACK)
	_qr = ImageTexture.create_from_image(img)
	return _qr

## El póster del mapa de recorridos: fondo claro, tres líneas de colores con paradas, el río. 48 × 72.
static func afiche(variante: int) -> ImageTexture:
	var v := variante % 3
	if _afiche.has(v):
		return _afiche[v]
	var w := 48
	var h := 72
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	img.fill(Color(0.94, 0.95, 0.93))
	for y in range(0, 7):
		for x in w:
			img.set_pixel(x, y, BURDEOS)
	for l in 3:
		var c: Color = COLORES_RUTA[(l + v) % COLORES_RUTA.size()]
		var x0 := 8 + l * 14
		for y in range(10, h - 4):
			var xx := x0 + int(round(sin(float(y) * 0.12 + float(l + v)) * 4.0))
			for dx in 2:
				img.set_pixel(clampi(xx + dx, 0, w - 1), y, c)
			if y % 11 == 0:
				for dy in 3:
					for dx in range(-2, 4):
						img.set_pixel(clampi(xx + dx, 0, w - 1), clampi(y + dy, 0, h - 1), Color(0.1, 0.1, 0.12))
	_afiche[v] = ImageTexture.create_from_image(img)
	return _afiche[v]

static func _quad(p: Node3D, tex: Texture2D, pos: Vector3, tam: Vector2, giro_y := 0.0) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = tam
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = giro_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.add_child(mi)

## El código del paradero («PA» + 4 cifras, la primera es el sector) y sus recorridos: los da la tabla `RecorridosRed`, la
## misma que lee la app «Red» del móvil. `sector` 0 = el del origen (las pruebas montan el paradero ahí).
static func codigo(semilla: int, sector: int = 0) -> String:
	return RecorridosRed.codigo(semilla, sector if sector > 0 else RecorridosRed.sector_de(Vector3.ZERO))

static func recorridos(semilla: int, sector: int = 0) -> Array[String]:
	return RecorridosRed.recorridos(codigo(semilla, sector))

static func montar(raiz: Node3D, ancho: float, semilla: int) -> void:
	## El sector sale de dónde está (la zona de la ciudad); la app encuentra el paradero por el grupo y la meta.
	var cod := codigo(semilla, RecorridosRed.sector_de(raiz.global_position if raiz.is_inside_tree() else raiz.position))
	raiz.add_to_group("paradero_red")
	raiz.set_meta("codigo_red", cod)
	var gris := _mat(GRIS, 0.45, 0.5)
	var oscuro := _mat(Color(0.2, 0.21, 0.23), 0.5, 0.5)
	var vidrio := _mat(Color(0.7, 0.84, 0.9, 0.32), 0.1, 0.2)
	var m := raiz
	## Techo plano de poco vuelo, con la franja burdeos «Red» por delante y el canto gris.
	var techo := _caja(m, Vector3(0, 2.72, -0.1), Vector3(ancho + 0.3, 0.1, 2.6), gris)
	techo.rotation_degrees.x = -2.0
	_caja(m, Vector3(0, 2.66, 1.17), Vector3(ancho + 0.32, 0.22, 0.05), _mat(BURDEOS, 0.5))
	_texto(m, "Red", Vector3(-ancho * 0.5 + 0.55, 2.66, 1.205), 120, Color.WHITE)
	## Postes: dos en cada extremo (trasero y delantero) y uno trasero cada ~3,5 m.
	var tramos := maxi(1, int(round(ancho / 3.5)))
	for i in tramos + 1:
		var x := -ancho * 0.5 + ancho * float(i) / float(tramos)
		_caja(m, Vector3(x, 1.33, -1.34), Vector3(0.09, 2.66, 0.09), oscuro)
	for lado in [-1.0, 1.0]:
		_caja(m, Vector3(lado * ancho * 0.5, 1.33, 1.1), Vector3(0.09, 2.66, 0.09), oscuro)
	## Trasera: cristal arriba y pósters de recorridos abajo (uno por tramo); lateral de cristal en un extremo.
	_caja(m, Vector3(0, 1.85, -1.4), Vector3(ancho, 1.4, 0.04), vidrio)
	_caja(m, Vector3(0, 0.55, -1.4), Vector3(ancho, 1.1, 0.04), _mat(Color(0.82, 0.84, 0.86), 0.5, 0.2))
	for i in tramos:
		var xc := -ancho * 0.5 + ancho * (float(i) + 0.5) / float(tramos)
		_quad(m, afiche(semilla + i), Vector3(xc, 1.15, -1.375), Vector2(0.9, 1.35))
	_caja(m, Vector3(ancho * 0.5, 1.45, -0.15), Vector3(0.04, 2.3, 2.4), vidrio)
	## Banca corrida de láminas metálicas (el tablero a 0,45 m de la acera, como los bancos de la ciudad).
	for z in [-1.07, -0.9, -0.73]:
		_caja(m, Vector3(0, 0.67, z), Vector3(ancho * 0.72, 0.04, 0.14), gris)
	for x in [-ancho * 0.34, 0.0, ancho * 0.34]:
		_caja(m, Vector3(x, 0.4, -0.9), Vector3(0.06, 0.55, 0.5), oscuro)
	## El poste con el cartel del paradero, a un lado.
	var xp := ancho * 0.5 + 0.9
	var cil := CylinderMesh.new()
	cil.top_radius = 0.04
	cil.bottom_radius = 0.045
	cil.height = 3.1
	var pm := MeshInstance3D.new()
	pm.mesh = cil
	pm.material_override = oscuro
	pm.position = Vector3(xp, 1.55, 0.9)
	m.add_child(pm)
	var cartel := Node3D.new()
	cartel.position = Vector3(xp, 0, 0.9)
	m.add_child(cartel)
	_caja(cartel, Vector3(0, 2.55, 0.03), Vector3(0.56, 1.0, 0.04), _mat(Color(0.97, 0.97, 0.96), 0.5))
	_caja(cartel, Vector3(0, 2.96, 0.056), Vector3(0.56, 0.17, 0.02), _mat(VERDE, 0.5))
	_texto(cartel, "PARADERO", Vector3(0, 2.96, 0.07), 62, Color.WHITE)
	_texto(cartel, cod, Vector3(0, 2.76, 0.07), 108, Color(0.1, 0.1, 0.12))
	_quad(cartel, qr(), Vector3(0.0, 2.42, 0.07), Vector2(0.24, 0.24))
	var rs := RecorridosRed.recorridos(cod)
	for i in rs.size():
		var col: Color = RecorridosRed.color(rs[i])
		var xr := -0.19 + float(i % 3) * 0.19
		var yr := 2.2 - float(i / 3) * 0.12
		_caja(cartel, Vector3(xr, yr, 0.056), Vector3(0.17, 0.1, 0.02), _mat(col, 0.5))
		_texto(cartel, rs[i], Vector3(xr, yr, 0.07), 44, Color.WHITE)
