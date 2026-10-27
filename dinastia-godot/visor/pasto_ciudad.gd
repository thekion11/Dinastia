class_name PastoCiudad
extends RefCounted
## Matas de pasto del Drive del dueño (`assets/pasto/mata_1.glb` y `mata_2.glb`, ~7-8 mil triángulos cada una, licencia confirmada) repartidas
## en los parques y en las orillas del río con MultiMesh. El MultiMesh es un solo nodo, así que se parte en celdas de CELDA m y cada una
## se oculta a DISTANCIA m (`visibility_range_end`): de lejos solo se ve el césped plano. Nunca en la cancha ni en el agua.
## Determinista: sin el azar del juego (`hash`). PASTO_DRIVE=0 lo apaga (para las capturas «antes»).
const RUTAS := ["res://assets/pasto/mata_1.glb", "res://assets/pasto/mata_2.glb"]
const CELDA := 24.0
const DISTANCIA := 42.0
const ANCHO_MATA := 1.3   ## m que ocupa de ancho una mata sembrada (el glb mide ~0,9)
const BORDE := 2.2        ## m de profundidad de la franja de matas junto al borde del parque
const TINTE := Color(0.62, 0.86, 0.50)   ## se multiplica por la textura
const SEPARACION := 1.7   ## m entre matas del borde
const AZAR_INTERIOR := 0.012   ## manchones por m² en el interior (cada uno son 3 matas juntas)

static var _partes: Array = []   ## por variante: [[Mesh, Transform3D], ...]
static var total_sembradas := 0

static func apagado() -> bool:
	return OS.get_environment("PASTO_DRIVE") == "0"

static func _cargar() -> void:
	if not _partes.is_empty():
		return
	for ruta: String in RUTAS:
		var lista: Array = []
		var ps := load(ruta) as PackedScene if ResourceLoader.exists(ruta) else null
		if ps != null:
			var raiz := ps.instantiate() as Node3D
			_recoger(raiz, Transform3D.IDENTITY, lista)
			raiz.free()
		_partes.append(lista)

## Copia de la malla con el color llevado al verde del césped de los parques (las texturas del pack tiran a amarillo/naranja).
static func _verde(m: Mesh) -> Mesh:
	var c := m.duplicate() as Mesh
	for i in c.get_surface_count():
		var mat := c.surface_get_material(i) as StandardMaterial3D
		if mat != null:
			mat = mat.duplicate() as StandardMaterial3D
			mat.albedo_color = TINTE
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			c.surface_set_material(i, mat)
	return c

static func _recoger(n: Node, t: Transform3D, lista: Array) -> void:
	for h in n.get_children():
		if h is Node3D:
			var tt: Transform3D = t * (h as Node3D).transform
			if h is MeshInstance3D and (h as MeshInstance3D).mesh != null:
				lista.append([_verde((h as MeshInstance3D).mesh), tt])
			_recoger(h, tt, lista)

## Siembra las matas de `puntos` (Vector3 con y del suelo). `evita`: Callable(Vector3) -> bool, true = no sembrar ahí.
static func sembrar(raiz: Node3D, puntos: Array, semilla: int) -> int:
	if apagado() or puntos.is_empty():
		return 0
	_cargar()
	var celdas: Dictionary = {}
	for p: Vector3 in puntos:
		var k := Vector2i(floori(p.x / CELDA), floori(p.z / CELDA))
		if not celdas.has(k):
			celdas[k] = []
		(celdas[k] as Array).append(p)
	var n := 0
	for k: Vector2i in celdas:
		var pts: Array = celdas[k]
		for v in _partes.size():
			var partes: Array = _partes[v]
			if partes.is_empty():
				continue
			var mios: Array[Transform3D] = []
			for i in pts.size():
				if (absi(hash([semilla, k, i])) % _partes.size()) != v:
					continue
				var h := absi(hash([semilla, k, i, 7]))
				var giro := float(h % 628) / 100.0
				var esc := ANCHO_MATA / 0.9 * (0.75 + float((h / 628) % 50) / 100.0)
				mios.append(Transform3D(Basis(Vector3.UP, giro).scaled(Vector3.ONE * esc), pts[i]))
			if mios.is_empty():
				continue
			for pa: Array in partes:
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = pa[0]
				mm.instance_count = mios.size()
				for i in mios.size():
					mm.set_instance_transform(i, mios[i] * (pa[1] as Transform3D))
				var mi := MultiMeshInstance3D.new()
				mi.name = "PastoDrive"
				mi.multimesh = mm
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mi.visibility_range_end = DISTANCIA
				raiz.add_child(mi)
			n += mios.size()
	total_sembradas += n
	return n

## Parque: franja junto a todo el borde y matas sueltas por dentro, lejos de los paseos en cruz, la cancha y el lago.
static func parque(raiz: Node3D, r: Rect2, c: Vector3, evita: Callable, arboles: Array = []) -> int:
	if apagado():
		return 0
	var pts: Array = []
	var semilla := int(c.x * 3.0 + c.z * 5.0)
	var y := 0.1
	var largo_x := r.size.x - 2.0
	var largo_z := r.size.y - 2.0
	for lado in 4:
		var horizontal := lado < 2
		var largo := largo_x if horizontal else largo_z
		var pasos := int(largo / SEPARACION)
		for i in pasos:
			for f in 2:   ## dos filas: pegada al borde y otra detrás
				var a := (float(i) + 0.5) / float(pasos) - 0.5
				var h := absi(hash([semilla, lado, i, f]))
				var prof := 1.0 + float(f) * (BORDE * 0.55) + float(h % 60) / 100.0
				var p: Vector3
				match lado:
					0: p = Vector3(c.x + a * largo_x, y, r.position.y + prof)
					1: p = Vector3(c.x + a * largo_x, y, r.end.y - prof)
					2: p = Vector3(r.position.x + prof, y, c.z + a * largo_z)
					_: p = Vector3(r.end.x - prof, y, c.z + a * largo_z)
				if absf(p.x - c.x) < 3.5 or absf(p.z - c.z) < 3.5 or evita.call(p):
					continue
				pts.append(p)
	## A lo largo de los paseos en cruz (a 3,2 m del eje) y al pie de cada árbol.
	for eje in 2:
		var largo := r.size.x if eje == 0 else r.size.y
		for i in int(largo / 2.4):
			for lado: float in [-1.0, 1.0]:
				var h := absi(hash([semilla, eje, i, int(lado), 21]))
				var a := -largo * 0.5 + (float(i) + float(h % 100) / 100.0) * 2.4
				var d: float = lado * (3.2 + float((h / 100) % 80) / 100.0)
				var p := Vector3(c.x + a, y, c.z + d) if eje == 0 else Vector3(c.x + d, y, c.z + a)
				if not evita.call(p) and r.grow(-1.0).has_point(Vector2(p.x, p.z)):
					pts.append(p)
	for k in arboles.size():
		var t: Vector3 = arboles[k]
		for j in 4:
			var g := absi(hash([semilla, k, j, 31]))
			var ang := float(g % 628) / 100.0
			var p := Vector3(t.x + cos(ang) * (0.9 + float((g / 628) % 50) / 100.0), y, t.z + sin(ang) * (0.9 + float((g / 628) % 50) / 100.0))
			if not evita.call(p):
				pts.append(p)
	var interior := int(r.size.x * r.size.y * AZAR_INTERIOR)
	for i in interior:
		var h := absi(hash([semilla, i, 99]))
		var p := Vector3(r.position.x + BORDE + float(h % 1000) / 1000.0 * (r.size.x - 2.0 * BORDE), y,
			r.position.y + BORDE + float((h / 1000) % 1000) / 1000.0 * (r.size.y - 2.0 * BORDE))
		if absf(p.x - c.x) < 5.0 or absf(p.z - c.z) < 5.0 or evita.call(p):
			continue
		for j in 3:   ## manchón: la mata y dos vecinas a menos de un metro
			var g := absi(hash([semilla, i, j, 3]))
			pts.append(p + (Vector3(float(g % 100) / 50.0 - 1.0, 0.0, float((g / 100) % 100) / 50.0 - 1.0) if j > 0 else Vector3.ZERO))
	return sembrar(raiz, pts, semilla)

## Orilla del río: matas a lo largo del paseo (x0 = pie del agua, `lado` = ±1 hacia fuera), entre z0 y z1.
static func orilla(raiz: Node3D, x0: float, lado: float, z0: float, z1: float) -> int:
	if apagado():
		return 0
	var pts: Array = []
	var pasos := int((z1 - z0) / 1.6)
	for i in pasos:
		var h := absi(hash([int(x0), i, 5]))
		var fuera := 12.0 + float(h % 120) / 10.0   ## del pie del agua hacia fuera, pasado el paseo (acera a 4 m, árboles a 10 m)
		pts.append(Vector3(x0 + lado * fuera, 0.1, z0 + (float(i) + float((h / 7) % 100) / 100.0) * 1.6))
	return sembrar(raiz, pts, int(x0))

## Huecos entre casas (bloques de casas: césped liso entre las dos filas y entre cada casa): manchones fuera de las casas.
static func solar_casas(raiz: Node3D, r: Rect2, cols: int) -> int:
	if apagado():
		return 0
	var pts: Array = []
	var semilla := int(r.position.x * 3.0 + r.position.y * 7.0)
	var paso := r.size.x / float(cols)
	for i in int(r.size.x * r.size.y * 0.02):
		var h := absi(hash([semilla, i, 61]))
		var x := r.position.x + float(h % 1000) / 1000.0 * r.size.x
		var z := r.position.y + float((h / 1000) % 1000) / 1000.0 * r.size.y
		var rel := absf(z - r.get_center().y) / r.size.y   ## 0 en el centro, 0,5 en el borde
		var fx := fposmod(x - r.position.x, paso) / paso   ## 0,5 = en medio de una casa
		var hueco := rel < 0.10 or rel > 0.36 or fx < 0.14 or fx > 0.86
		if not hueco:
			continue
		for j in 3:
			var g := absi(hash([semilla, i, j, 3]))
			pts.append(Vector3(x + (float(g % 100) / 50.0 - 1.0) * (1.0 if j > 0 else 0.0), 0.1, z + (float((g / 100) % 100) / 50.0 - 1.0) * (1.0 if j > 0 else 0.0)))
	return sembrar(raiz, pts, semilla)
