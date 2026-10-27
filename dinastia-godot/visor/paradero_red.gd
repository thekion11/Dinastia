class_name ParaderoRed
extends RefCounted
## EL PARADERO DE LA RED (Red Movilidad, Santiago de Chile), COMO EN LAS FOTOS DEL DUEÑO (`docs/04_auditorias/referencias/paradero_red_{1,2,cartel}.jpg`,
## 27-10-2026). Marquesina de postes de acero gris oscuro con el TECHO plano BLANCO y costillas ROJAS por debajo; bajo el techo, la CABECERA: una banda
## NEGRA a todo lo largo con «Paradero de Red Movilidad | Parada N» en blanco y remates ROJOS en los extremos (con el logo «Red»); entre los dos postes
## de un lado, el panel publicitario enmarcado con el póster rojo y blanco de Red y, delante, la banca de láminas gris claro con su barra de apoyo;
## un papelero gris claro al lado. APARTE, el POSTE con el CARTEL NEGRO: iconos de bus arriba a la izquierda, esquina roja con «Red» arriba a la derecha,
## nombre de la parada, cuadrícula de 2 columnas con los recorridos en blanco (cajitas con línea divisoria), QR abajo a la izquierda y franja roja abajo.
## Los recorridos salen de `SECTORES` (un sector por zona de la ciudad: 100 → 1xx, 200 → 2xx…; «c» = sentido contrario, «e» = alternativa, muy rara; y los
## «C02», «C09c» de los alimentadores), el código «PA####» es estable por paradero y todo queda en `registro` (y `datos/paraderos_red.json` describe la
## tabla) para la app del móvil.
##   ParaderoRed.montar(raiz, ancho, semilla, nombre, sector)   (raiz = nodo en el suelo, ya girado; la banca queda a z = −0,9 y el frente abierto a +z)
const ROJO := Color(0.78, 0.09, 0.20)
const NEGRO := Color(0.08, 0.08, 0.10)
const POSTE := Color(0.21, 0.22, 0.25)
const BLANCO := Color(0.95, 0.95, 0.96)
const GRIS_CLARO := Color(0.78, 0.80, 0.82)

## Los recorridos que paran en cada sector de la ciudad (números de la Red: la centena es el sector). Es la tabla que usará la app del móvil.
const SECTORES := {
	100: ["101", "107", "111", "122", "126", "133", "150", "164", "175", "190"],
	200: ["201", "203", "209", "214", "217", "226", "231", "249", "262", "278"],
	300: ["301", "304", "308", "312", "319", "325", "336", "348", "357", "391"],
	400: ["401", "405", "411", "418", "421", "427", "433", "445", "458", "467"],
	500: ["501", "503", "506", "511", "514", "519", "524", "532", "547", "563"],
}
## Los alimentadores («C») que enlazan con el metro.
const ALIMENTADORES := ["C02", "C09", "C11", "C14", "C21", "C27", "C33", "C37", "C41"]

## Todos los paraderos montados: [{codigo, nombre, sector, parada, recorridos: [String], x, z}].
static var registro: Array[Dictionary] = []
static var _mats: Dictionary = {}
static var _qr: ImageTexture = null
static var _anuncio: ImageTexture = null

static func _mat(c: Color, rug := 0.6, metal := 0.0) -> StandardMaterial3D:
	var k := "%s|%.2f|%.2f" % [c.to_html(true), rug, metal]
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rug
		m.metallic = metal
		if c.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mats[k] = m
	return _mats[k]

## Material con luz propia (carteles iluminados): el color también se emite.
static func _luz(c: Color, energia := 0.5) -> StandardMaterial3D:
	var k := "luz|%s|%.2f" % [c.to_html(true), energia]
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = energia
		_mats[k] = m
	return _mats[k]

static func _caja(p: Node3D, pos: Vector3, tam: Vector3, m: Material, giro := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = giro
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if tam.y < 0.2 and tam.x < 0.6 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	p.add_child(mi)
	return mi

static func _texto(p: Node3D, txt: String, pos: Vector3, tam_px: int, col: Color, ancla := HORIZONTAL_ALIGNMENT_CENTER) -> Label3D:
	var l := Label3D.new()
	l.text = txt
	l.font_size = tam_px
	l.pixel_size = 0.0012
	l.modulate = col
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.horizontal_alignment = ancla
	l.position = pos
	p.add_child(l)
	return l

static func _quad(p: Node3D, tex: Texture2D, pos: Vector3, tam: Vector2) -> void:
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
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.add_child(mi)

## Un QR de mentira pero con pinta de QR: tres marcas de esquina y el resto a hash (determinista, 25 × 25).
static func qr() -> ImageTexture:
	if _qr != null:
		return _qr
	var n := 25
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	for y in n:
		for x in n:
			var marca := (x < 7 and y < 7) or (x >= n - 7 and y < 7) or (x < 7 and y >= n - 7)
			if marca:
				var mx := x if x < 7 else x - (n - 7)
				var my := y if y < 7 else y - (n - 7)
				var borde := mx == 0 or mx == 6 or my == 0 or my == 6
				var centro := mx >= 2 and mx <= 4 and my >= 2 and my <= 4
				img.set_pixel(x, y, Color.BLACK if (borde or centro) else Color.WHITE)
			elif absi(hash([x, y, 77])) % 100 < 48:
				img.set_pixel(x, y, Color.BLACK)
	_qr = ImageTexture.create_from_image(img)
	return _qr

## El póster del panel publicitario: rojo y blanco de Red (una ola blanca sobre el rojo), 64 × 48.
static func anuncio() -> ImageTexture:
	if _anuncio != null:
		return _anuncio
	var w := 64
	var h := 48
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var ola := 0.45 + 0.12 * sin(float(x) * 0.18) + 0.0035 * float(x)
			img.set_pixel(x, y, ROJO if float(y) / float(h) < ola else Color(0.97, 0.97, 0.98))
	for x in range(8, 56):   ## la fila de buses
		for y in range(26, 32):
			if x % 9 != 0:
				img.set_pixel(x, y, Color(0.25, 0.26, 0.3))
	_anuncio = ImageTexture.create_from_image(img)
	return _anuncio

## El sector (100…500) de un punto de la ciudad: un cuadrante por sector y el centro, el 500.
static func sector_de(x: float, z: float) -> int:
	if absf(x) < 60.0 and absf(z) < 60.0:
		return 500
	return [100, 200, 300, 400][(1 if x > 0.0 else 0) + (2 if z > 0.0 else 0)]

## El código del paradero («PA» + 3 o 4 cifras), estable por semilla.
static func codigo(semilla: int) -> String:
	return "PA%d" % (100 + absi(hash([semilla, 11])) % 9000)

## Los recorridos de un paradero del `sector`: 4-6 de su centena; el 35 % con «c» (sentido contrario), el 3 % con «e» (alternativa) y, a veces, un
## alimentador «C##» (también con «c»). Estable por semilla.
static func recorridos(semilla: int, sector: int) -> Array[String]:
	var lista: Array = SECTORES.get(sector, SECTORES[100])
	var n := 4 + absi(hash([semilla, 5])) % 3
	var out: Array[String] = []
	var k := absi(hash([semilla, 3]))
	var i := 0
	while out.size() < n and i < 40:
		var r: String
		if absi(hash([semilla, i, 9])) % 100 < 22:
			r = String(ALIMENTADORES[absi(hash([semilla, i, 4])) % ALIMENTADORES.size()])
		else:
			r = String(lista[(k + i * 3) % lista.size()])
		var azar := absi(hash([semilla, i, 6])) % 100
		if azar < 3:
			r += "e"
		elif azar < 38:
			r += "c"
		if not out.has(r):
			out.append(r)
		i += 1
	return out

## Dónde (x local) quedan los dos asientos de la banca, para que `GenteSentada` sepa dónde sentar.
static func asientos_x() -> Array[float]:
	return [0.5, 1.2]

static func montar(raiz: Node3D, ancho: float, semilla: int, nombre := "", sector := 0) -> void:
	var w := 3.8   ## el paradero real mide ~3,6 m: se ignora un ancho mayor (los de 7,5 m eran de la versión inventada)
	var parada := 1 + absi(hash([semilla, 17])) % 9
	var sec := sector if sector > 0 else 100 * (1 + absi(hash([semilla, 2])) % 5)
	var cod := codigo(semilla)
	var rs := recorridos(semilla, sec)
	registro.append({"codigo": cod, "nombre": nombre, "sector": sec, "parada": parada, "recorridos": rs, "x": raiz.global_position.x if raiz.is_inside_tree() else raiz.position.x, "z": raiz.global_position.z if raiz.is_inside_tree() else raiz.position.z})
	var poste := _mat(POSTE, 0.45, 0.5)
	var negro := _mat(NEGRO, 0.4)
	var rojo := _mat(ROJO, 0.5)
	var blanco := _mat(BLANCO, 0.5)
	var m := raiz
	## Postes: dos en el lado de la banca y el panel (x = −0,2 y x = +w/2), y uno en el extremo abierto; delanteros y traseros.
	var xs: Array[float] = [-w * 0.5, -0.2, w * 0.5]
	for x: float in xs:
		_caja(m, Vector3(x, 1.2, -1.3), Vector3(0.1, 2.4, 0.1), poste)
		_caja(m, Vector3(x, 1.2, 1.05), Vector3(0.1, 2.4, 0.1), poste)
	## Techo plano blanco de poco vuelo y costillas ROJAS por debajo (una sobre cada fila de postes y una diagonal por tramo).
	var techo := _caja(m, Vector3(0, 2.62, -0.1), Vector3(w + 0.5, 0.07, 2.95), blanco)
	techo.rotation_degrees.x = -3.0
	for x: float in xs:
		_caja(m, Vector3(x, 2.5, -0.1), Vector3(0.11, 0.1, 2.5), rojo, Vector3(-3.0, 0, 0))
	for i in 2:
		var xc: float = (xs[i] + xs[i + 1]) * 0.5
		_caja(m, Vector3(xc, 2.52, -0.1), Vector3(0.08, 0.07, 2.7), rojo, Vector3(-3.0, 12.0 if i == 0 else -12.0, 0))
	## Cabecera bajo el techo: banda negra con el texto, remates rojos con el logo «Red».
	_caja(m, Vector3(0, 2.36, 1.1), Vector3(w + 0.1, 0.3, 0.06), negro)
	for lado in [-1.0, 1.0]:
		_caja(m, Vector3(lado * (w * 0.5 + 0.04), 2.36, 1.1), Vector3(0.4, 0.34, 0.07), rojo)
	_texto(m, "Paradero de Red Movilidad", Vector3(-0.5, 2.36, 1.14), 84, Color.WHITE)
	_texto(m, "|", Vector3(0.95, 2.36, 1.14), 84, Color(0.6, 0.6, 0.65))
	_texto(m, "Parada %d" % parada, Vector3(1.4, 2.36, 1.14), 84, Color.WHITE)
	_texto(m, "Red", Vector3(w * 0.5 + 0.04, 2.38, 1.15), 70, Color.WHITE)
	## Panel publicitario enmarcado (entre los postes del lado de la banca) con el póster de Red.
	var cx := (xs[1] + xs[2]) * 0.5
	_caja(m, Vector3(cx, 1.5, -1.3), Vector3(w * 0.5 - 0.2, 1.05, 0.08), negro)
	_quad(m, anuncio(), Vector3(cx, 1.5, -1.254), Vector2(w * 0.5 - 0.42, 0.88))
	_texto(m, "Red", Vector3(cx - 0.55, 1.78, -1.248), 60, Color.WHITE)
	## Banca de láminas gris claro con su barra de apoyo.
	var bx := cx
	for z in [-1.06, -0.9, -0.74]:
		_caja(m, Vector3(bx, 0.67, z), Vector3(w * 0.5 - 0.4, 0.04, 0.12), _mat(GRIS_CLARO, 0.5, 0.3))
	for x in [bx - 0.8, bx + 0.8]:
		_caja(m, Vector3(x, 0.4, -0.9), Vector3(0.05, 0.55, 0.4), poste)
	_caja(m, Vector3(bx, 0.98, -1.18), Vector3(w * 0.5 - 0.4, 0.04, 0.05), _mat(GRIS_CLARO, 0.5, 0.3))
	## Papelero gris claro, en el extremo del lado de la banca.
	var xb := w * 0.5 + 0.75
	for dx in [-0.22, 0.22]:
		_caja(m, Vector3(xb + dx, 0.55, 0.3), Vector3(0.04, 1.1, 0.04), _mat(GRIS_CLARO, 0.5, 0.3))
	_caja(m, Vector3(xb, 0.7, 0.3), Vector3(0.44, 0.45, 0.3), _mat(GRIS_CLARO, 0.55))
	## El poste con el cartel negro, a la izquierda de la marquesina.
	var xp := -w * 0.5 - 1.2
	var cil := CylinderMesh.new()
	cil.top_radius = 0.035
	cil.bottom_radius = 0.04
	cil.height = 2.7
	var pm := MeshInstance3D.new()
	pm.mesh = cil
	pm.material_override = poste
	pm.position = Vector3(xp, 1.35, 0.9)
	m.add_child(pm)
	_cartel(m, Vector3(xp, 0, 0.9), nombre, rs)

## El cartel negro: bus (arriba izquierda), esquina roja «Red» (arriba derecha), nombre, 2 columnas de recorridos con su divisoria, QR y franja roja.
static func _cartel(m: Node3D, pos: Vector3, nombre: String, rs: Array[String]) -> void:
	var c := Node3D.new()
	c.position = pos
	m.add_child(c)
	var ancho := 0.62
	var alto := 1.0
	var yc := 2.1
	_caja(c, Vector3(0, yc, 0.03), Vector3(ancho, alto, 0.04), _mat(NEGRO, 0.45))
	var z := 0.056
	## Icono de bus (cuadrado blanco con ventanilla negra y dos ruedas) arriba a la izquierda.
	_caja(c, Vector3(-0.23, yc + 0.4, z), Vector3(0.09, 0.075, 0.01), _luz(Color.WHITE))
	_caja(c, Vector3(-0.23, yc + 0.41, z + 0.006), Vector3(0.07, 0.04, 0.01), _mat(NEGRO, 0.5))
	## Esquina roja con «Red» arriba a la derecha.
	_caja(c, Vector3(0.2, yc + 0.39, z), Vector3(0.22, 0.2, 0.01), _luz(ROJO, 0.6))
	_texto(c, "Red", Vector3(0.2, yc + 0.41, z + 0.008), 66, Color.WHITE)
	## El nombre de la parada.
	_texto(c, nombre if nombre != "" else "Paradero", Vector3(-0.02, yc + 0.27, z + 0.004), 34, Color(0.85, 0.86, 0.9))
	## Cuadrícula de 2 columnas: cajitas con la línea divisoria entre filas y en el centro.
	var filas := ceili(float(rs.size()) / 2.0)
	for f in filas + 1:
		_caja(c, Vector3(0, yc + 0.2 - float(f) * 0.13, z + 0.002), Vector3(ancho - 0.06, 0.004, 0.004), _luz(Color(0.75, 0.76, 0.8), 0.3))
	_caja(c, Vector3(0, yc + 0.2 - float(filas) * 0.065, z + 0.002), Vector3(0.004, 0.13 * float(filas), 0.004), _luz(Color(0.75, 0.76, 0.8), 0.3))
	for i in rs.size():
		var col := i % 2
		var fila := i / 2
		_texto(c, rs[i], Vector3(-0.15 + 0.3 * float(col), yc + 0.2 - 0.065 - float(fila) * 0.13, z + 0.004), 58, Color.WHITE)
	## QR abajo a la izquierda y franja roja abajo.
	_quad(c, qr(), Vector3(-0.2, yc - 0.37, z + 0.002), Vector2(0.12, 0.12))
	_caja(c, Vector3(0, yc - 0.48, z), Vector3(ancho - 0.02, 0.05, 0.01), _luz(ROJO, 0.6))
