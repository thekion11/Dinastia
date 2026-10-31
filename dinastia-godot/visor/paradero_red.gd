class_name ParaderoRed
extends RefCounted
## EL PARADERO DE LA RED (Red Movilidad, Santiago de Chile), COMO EN LAS FOTOS DEL DUEÑO (`docs/04_auditorias/referencias/paradero_red_{1,2,cartel}.jpg`,
## 27-10-2026). Marquesina de postes de acero gris oscuro con el TECHO plano BLANCO y costillas ROJAS por debajo; bajo el techo, la CABECERA: una banda
## NEGRA a todo lo largo con «Paradero de Red Movilidad | Parada N» en blanco y remates ROJOS en los extremos (con el logo «Red»); entre los dos postes
## de un lado, el panel publicitario enmarcado con el póster rojo y blanco de Red y, delante, la banca de láminas gris claro con su barra de apoyo;
## un papelero gris claro al lado. APARTE, el POSTE con el CARTEL NEGRO: iconos de bus arriba a la izquierda, esquina roja con «Red» arriba a la derecha,
## nombre de la parada, cuadrícula de 2 columnas con los recorridos en blanco (cajitas con línea divisoria), QR abajo a la izquierda y franja roja abajo.
## Los recorridos, el nombre de la parada y el código «PA####» salen de `RecorridosRed` (los recorridos sobre el mapa, la misma fuente que lee la app «Red»
## del móvil); todo queda en `registro`.
##   ParaderoRed.montar(raiz, ancho, semilla, nombre, sector, codigo)   (raiz = nodo en el suelo, ya girado; la banca queda a z = −0,9 y el frente abierto
##   a +z). Con `codigo` (un paradero del mapa) se usa ese; sin él, `semilla` elige uno real del sector (pruebas y capturas sueltas).
const ROJO := Color(0.70, 0.03, 0.11)   ## rojo Red (con el sol y el cielo azul, el anterior se veía rosa)
const NEGRO := Color(0.08, 0.08, 0.10)
const POSTE := Color(0.21, 0.22, 0.25)
const BLANCO := Color(0.95, 0.95, 0.96)
const GRIS_CLARO := Color(0.78, 0.80, 0.82)

## Todos los paraderos montados: [{codigo, nombre, sector, parada, recorridos: [String], x, z}].
static var registro: Array[Dictionary] = []
static var _mats: Dictionary = {}
static var _qr: ImageTexture = null
static var _anuncio: ImageTexture = null

## Es de noche en la ciudad (lo pone `TraficoCiudad.faros`): las luces de los paraderos nacen encendidas o apagadas según esto.
static var noche := false

## Enciende o apaga la luz de todos los paraderos montados.
static func encender(arbol: SceneTree, si: bool) -> void:
	noche = si
	arbol.call_group("luz_paradero", "set_visible", si)

static func _mat(c: Color, rug := 0.6, metal := 0.0) -> StandardMaterial3D:
	var k := "%s|%.2f|%.2f" % [c.to_html(true), rug, metal]
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rug
		m.metallic = metal
		m.metallic_specular = 0.25   ## plástico mate: sin reflejo del cielo que lo lava
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
	mi.visibility_range_end = 450.0
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
	l.visibility_range_end = 90.0   ## letra de 1-6 cm: de más lejos no se lee y cuesta dibujarla (hay ~120 paraderos)
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

## El código del paradero («PA» + 4 cifras, la primera es el sector) y sus recorridos: los da `RecorridosRed` (un paradero real del
## mapa), la misma fuente que lee la app «Red» del móvil, así que el cartel y la app dicen siempre lo mismo. `sector` 0 = el del origen.
static func codigo(semilla: int, sector: int = 0) -> String:
	return RecorridosRed.codigo(semilla, sector if sector > 0 else RecorridosRed.sector_de(Vector3.ZERO))

static func recorridos(semilla: int, sector: int = 0) -> Array[String]:
	return RecorridosRed.recorridos(codigo(semilla, sector))

## Dónde (x local) quedan los dos asientos de la banca, para que `GenteSentada` sepa dónde sentar.
static func asientos_x() -> Array[float]:
	return [0.5, 1.2]

static func montar(raiz: Node3D, ancho: float, semilla: int, nombre := "", sector := 0, cod := "") -> void:
	var w := 3.8   ## el paradero real mide ~3,6 m: se ignora un ancho mayor (los de 7,5 m eran de la versión inventada)
	var donde := raiz.global_position if raiz.is_inside_tree() else raiz.position
	var sec := sector if sector > 0 else RecorridosRed.sector_de(donde)
	if cod == "":
		cod = codigo(semilla, sec)
	else:
		sec = RecorridosRed.sector_del_codigo(cod)
	var rs := RecorridosRed.recorridos(cod)
	## «Parada N»: el número del paradero dentro de su sector (las tres últimas cifras del código), como en la cabecera real;
	## antes salía de un hash y casi todos decían «Parada 1».
	var parada := maxi(1, int(cod.right(3))) if cod.length() >= 6 else 1 + absi(hash([semilla, 17])) % 9
	if nombre == "":
		nombre = RecorridosRed.nombre_parada(cod)
	## La app encuentra el paradero por el grupo y la meta.
	raiz.add_to_group("paradero_red")
	raiz.set_meta("codigo_red", cod)
	registro.append({"codigo": cod, "nombre": nombre, "sector": sec, "parada": parada, "recorridos": rs, "x": donde.x, "z": donde.z})
	var poste := _mat(POSTE, 0.45, 0.5)
	var negro := _mat(NEGRO, 0.4)
	var rojo := _mat(ROJO, 0.85)
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
	## Tubo fluorescente bajo el techo (emisivo: de noche el paradero se ve encendido; de día no se nota).
	_caja(m, Vector3(0.3, 2.47, 0.1), Vector3(w * 0.7, 0.03, 0.1), _luz(Color(0.95, 0.97, 1.0), 1.6))
	## Y una luz de verdad bajo el techo (28-10): ilumina banca, suelo y cartel; solo de noche (`encender`), sin sombras y con desvanecido por distancia.
	var foco := OmniLight3D.new()
	foco.name = "LuzParadero"
	foco.position = Vector3(0.3, 2.3, 0.1)
	foco.omni_range = 5.0
	foco.light_energy = 3.2
	foco.light_color = Color(0.95, 0.97, 1.0)
	foco.shadow_enabled = false
	foco.distance_fade_enabled = true
	foco.distance_fade_begin = 45.0
	foco.distance_fade_length = 15.0
	foco.visible = noche
	foco.add_to_group("luz_paradero")
	m.add_child(foco)
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
	_cartel(m, Vector3(xp, 0, 0.9), nombre, rs, cod)

## El cartel negro: bus (arriba izquierda), esquina roja «Red» (arriba derecha), nombre, 2 columnas de recorridos con su divisoria, QR y franja roja.
static func _cartel(m: Node3D, pos: Vector3, nombre: String, rs: Array[String], cod := "") -> void:
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
	_caja(c, Vector3(0.2, yc + 0.39, z), Vector3(0.22, 0.2, 0.01), _luz(ROJO, 0.3))
	_texto(c, "Red", Vector3(0.2, yc + 0.41, z + 0.008), 66, Color.WHITE)
	## El nombre de la parada.
	_texto(c, nombre if nombre != "" else "Paradero", Vector3(-0.02, yc + 0.27, z + 0.004), 34, Color(0.85, 0.86, 0.9))
	## El código del paradero, el que se escribe en la app «Red» del móvil para ver qué micros vienen.
	if cod != "":
		_texto(c, cod, Vector3(-0.08, yc + 0.4, z + 0.006), 40, Color.WHITE)
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
	_caja(c, Vector3(0, yc - 0.48, z), Vector3(ancho - 0.02, 0.05, 0.01), _luz(ROJO, 0.3))
