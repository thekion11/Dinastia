class_name SenalesVelocidad
extends RefCounted
## SEÑALES DE LÍMITE DE VELOCIDAD (M-199, 2-11-2026), al estilo chileno: disco blanco con aro rojo y la cifra en negro («Velocidad máxima»). El límite sale del SECTOR
## donde está la señal (`RecorridosRed.sector_de`): 40 km/h en el barrio del club (estadio, colegios), 50 en el centro, el este, el sur y el oeste y 60 en la periferia.
## En los cruces con semáforo, cada `CADA` uno lleva una señal por eje en la acera, mirando al tráfico que llega. Si el DT conduce por encima del límite + `MARGEN`
## km/h con la policía a la vista, le multan (`ServiciosVida.vigilar`); una vez cada `ENFRIA` s. Las cifras se dibujan con una tipografía de píxeles 3 × 5 en una textura
## por valor (sin Label3D): un solo MultiMesh de discos y otro de postes,.
const LIMITES := {100: 40, 200: 50, 300: 50, 400: 50, 500: 50, 600: 60}
const MARGEN := 20.0    ## km/h por encima del límite que ya se multa
const ENFRIA := 30.0    ## s entre dos multas por exceso
const CADA := 4         ## un cruce de cada 4 lleva señales


## Cifras 3 × 5 (una cadena de 15 caracteres por cifra, fila a fila).
const CIFRAS := {"0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111", "4": "101101111001001",
	"5": "111100111001111", "6": "111100111101111", "7": "111001001001001", "8": "111101111101111", "9": "111101111001111"}
static var _cache: Dictionary = {}

## El límite (km/h) en `pos`.
static func limite(pos: Vector3) -> int:
	return int(LIMITES.get(RecorridosRed.sector_de(pos), 50))

## Disco de 64 px: transparente fuera, aro rojo, fondo blanco y la cifra en negro.
static func textura(v: int) -> ImageTexture:
	if _cache.has(v):
		return _cache[v]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length()
			if d <= 31.0:
				img.set_pixel(x, y, Color(0.8, 0.05, 0.08) if d > 24.0 else Color.WHITE)
	var txt := str(v)
	var ancho := txt.length() * 4 - 1       ## cifras de 3 columnas + 1 de hueco
	var celda := 5 if txt.length() <= 2 else 4
	var x0 := 32 - int(ancho * celda / 2.0)
	var y0 := 32 - int(5.0 * celda / 2.0)
	for k in txt.length():
		var patron: String = CIFRAS[txt[k]]
		for i in 15:
			if patron[i] == "1":
				for dy in celda:
					for dx in celda:
						img.set_pixel(x0 + (k * 4 + i % 3) * celda + dx, y0 + (i / 3) * celda + dy, Color(0.05, 0.05, 0.06))
	var t := ImageTexture.create_from_image(img)
	_cache[v] = t
	return t

## Pone las señales en los cruces de `ex` y devuelve cuántas.
static func montar(ex) -> int:
	var b = ex.b
	var por_valor: Dictionary = {}   ## límite -> [Transform3D]
	var postes: Array[Transform3D] = []
	var off = CargaCiudad.de("CiudadExpansion").ANCHO_AV * 0.5 + 1.2 + 4.5
	var n := 0
	for i in ex.cruces_semaforo.size():
		if i % CADA != 0:
			continue
		var p: Vector3 = ex.cruces_semaforo[i]
		var v := limite(p)
		## [posición relativa, hacia dónde mira (al tráfico que llega)]
		for par: Array in [[Vector3(off, 0, CargaCiudad.de("CiudadExpansion").ANCHO_AV * 0.5 + 1.2), Vector3(1, 0, 0)], [Vector3(-(CargaCiudad.de("CiudadExpansion").ANCHO_AV * 0.5 + 1.2), 0, off), Vector3(0, 0, 1)]]:
			var base: Vector3 = p + par[0]
			var fd: Vector3 = par[1]
			postes.append(Transform3D(Basis.from_scale(Vector3(0.07, 2.4, 0.07)), base + Vector3(0, 1.2, 0)))
			if not por_valor.has(v):
				por_valor[v] = [] as Array[Transform3D]
			(por_valor[v] as Array).append(Transform3D(Basis(Vector3.UP, atan2(fd.x, fd.z)) * Basis.from_scale(Vector3(0.7, 0.7, 1.0)), base + Vector3(0, 2.25, 0) + fd * 0.06))
			n += 1
	if n == 0:
		return 0
	var raiz := Node3D.new()
	raiz.name = "SenalesVelocidad"
	b.add_child(raiz)   ## CiudadExpansion es RefCounted: las señales cuelgan del CityBuilder
	_mm(raiz, CylinderMesh.new(), b._mat_simple(Color(0.6, 0.62, 0.64), 0.4), postes)
	var quad := QuadMesh.new()
	for v: int in por_valor:
		var m := StandardMaterial3D.new()
		m.albedo_texture = textura(v)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 0.45
		var lista: Array[Transform3D] = []
		lista.assign(por_valor[v])
		_mm(raiz, quad, m, lista)
	return n

static func _mm(padre: Node3D, malla: Mesh, mat: Material, ts: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
