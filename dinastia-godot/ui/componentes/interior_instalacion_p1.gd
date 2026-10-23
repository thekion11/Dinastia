extends Control
## [Capa 1/7 de `interior_instalacion.gd`] _sala_de, tiene, abrir, en_mundo, _sala_nombre, tam_sala … (+11)

## LAS INSTALACIONES POR DENTRO (7-10-2026, pedido: «crear las instalaciones
## por dentro con NPC trabajando»). Una sala 3D cerrada por tipo de lugar
## -oficina, hospital, comisaría, cuartel de bomberos, aula, estación, mercado,
## cine, tienda, gimnasio, sala de análisis, comedor, sala de prensa, museo y
## piscina- con sus muebles y su gente trabajando:
##   · puestos fijos: sentados al escritorio, detrás del mostrador, junto a una
##     cama... y de vez en cuando hacen un gesto (hablan, saludan, señalan);
##   · caminantes: van de un punto a otro de la sala, se paran y siguen.
## Se abre con E en la puerta de un lugar de la ciudad, o con «Ver por dentro»
## en la ficha de una instalación del club. La cámara gira sola; arrastrando
## se mueve y la rueda acerca. Todo con `Mini3D` en un mundo aparte.

signal cerrado

## Qué sala corresponde a cada lugar (ciudad y club).
const SALAS := {
	"ciudad_ayuntamiento": ["oficina", "Ayuntamiento"], "ciudad_hospital": ["hospital", "Hospital"],
	"ciudad_comisaria": ["comisaria", "Comisaría"], "ciudad_bomberos": ["bomberos", "Parque de bomberos"],
	"ciudad_escuela": ["aula", "Escuela"], "ciudad_instituto": ["aula", "Instituto"],
	"ciudad_universidad": ["aula", "Universidad"], "ciudad_estacion_central": ["estacion", "Estación Central"],
	"ciudad_mercado": ["mercado", "Mercado"], "ciudad_cine": ["cine", "Cine"],
	"ciudad_centro_comercial": ["tienda", "Centro Comercial"], "ciudad_gasolinera": ["tienda", "Tienda de la gasolinera"],
	"med": ["hospital", "Centro médico del club"], "rehab": ["hospital", "Centro de rehabilitación"],
	"gim": ["gimnasio", "Gimnasio y recuperación"], "ct": ["gimnasio", "Centro de entrenamiento"],
	"bienestar": ["gimnasio", "Espacio de bienestar"], "video": ["analisis", "Sala de video y análisis"],
	"esports": ["analisis", "Sala de juegos y e-sports"], "cocina": ["comedor", "Comedor y nutrición"],
	"pren": ["prensa", "Sala de prensa"], "museo": ["museo", "Museo del club"], "com": ["tienda", "Tienda del club"],
	"piscina": ["piscina", "Piscina de recuperación"], "acad": ["aula", "Academia juvenil"],
	"resid": ["comedor", "Residencia de canteranos"], "guarderia": ["aula", "Guardería y zona familiar"],
}

## EDIFICIOS DE LA CIUDAD (etapa 6, 13-10-2026): casas, bares, panaderías...
## no son «instalaciones», pero también se entra. La clave lleva el nombre
## propio del sitio tras una barra: «edificio_bar|Bar El Rincón».
const SALAS_EDIFICIO := {
	"edificio_vivienda": ["vivienda", "Vivienda"], "edificio_bar": ["bar", "Bar"],
	"edificio_panaderia": ["panaderia", "Panadería"], "edificio_peluqueria": ["peluqueria", "Peluquería"],
	"edificio_libreria": ["libreria", "Librería"], "edificio_taller": ["taller", "Taller mecánico"],
	"edificio_oficina": ["oficina", "Oficinas"],
	## Para los rótulos de comercio que no tienen sala propia (farmacia, súper...).
	"edificio_tienda": ["tienda", "Tienda"], "edificio_mercado": ["mercado", "Supermercado"],
	## La sala de recreativos del parque de atracciones (16-10-2026).
	"edificio_recreativos": ["recreativos", "Recreativos"],
}

var clave := ""
var club: Club
var tipo := ""
var _minijuego: Callable
var _rng := RandomNumberGenerator.new()
var _v := {}
var _cam: Camera3D
var _raiz: Node3D
var _tam := Vector3(12, 3.2, 9)
var _fijos: Array = []        ## {d, gestos, t}
var _caminantes: Array = []   ## {d, puntos, i, espera}
var _ang := 0.6
var _dist := 1.0
var _arrastre := false
var _girando := true
var _titulo: Label
var _c1 := Color(0.2, 0.45, 0.3)
var _c2 := Color.WHITE
var _gente := 0
## true cuando la sala se pasea a pie (fachada cerrada y techo).
var _paseo := false
var _col_pared := Color(0.9, 0.88, 0.84)
var _luces: Array = []        ## posiciones de las lámparas (para los plafones)
## Tono por material de los muebles de esta sala («wood», «carpet»...).
var _tonos_sala := {}
## Piezas repetidas pendientes de montar en MultiMesh: clave → {nombre, escala, tonos, puestos}.
var _lotes := {}

# ---------------------------------------------- suelos con dibujo (procedural)

static var _texturas_suelo := {}

# ------------------------------------------- piezas de los kits (CC0)
## Muebles, comida, mini mercado y mini arcade de Kenney, y la alfombra y las
## cortinas de Quaternius. Cada modelo se carga UNA vez (`_piezas`) y se
## coloca centrado: el centro de su huella en el punto pedido y la base en el
## suelo. Las piezas sueltas van a lotes (`_poner`) que acaban en MultiMesh: la
## sala entera cuesta pocas llamadas de dibujo aunque tenga cientos de platos.

## Escala de cada kit (medida con `pruebas/medir_muebles.gd`): los muebles de
## Kenney salen a ×2 a medidas reales (silla: asiento a 0,48 m, alto 0,94 m).
const ESCALA_KIT := {"muebles": 2.0, "comida": 0.3, "mini_mercado": 1.9, "mini_arcade": 2.4, "quaternius": 1.0, "coches": 1.0}
## Comida a su tamaño real (con la escala común del kit las frutas eran canicas).
const ESCALA_COMIDA := {
	"apple": 0.45, "orange": 0.5, "lemon": 0.4, "pear": 0.4, "banana": 0.35, "grapes": 0.4, "pineapple": 0.6,
	"watermelon": 0.6, "tomato": 0.5, "carrot": 0.3, "cabbage": 0.5, "broccoli": 0.45, "eggplant": 0.5, "corn": 0.5,
	"pumpkin": 0.7, "fish": 0.55, "meat-raw": 0.5, "whole-ham": 0.5, "cheese": 0.45, "loaf": 0.45, "loaf-baguette": 0.6,
	"loaf-round": 0.4, "croissant": 0.4, "cake": 0.5, "muffin": 0.35, "donut-sprinkles": 0.4, "cupcake": 0.3,
	"pizza": 0.4, "burger": 0.35, "glass": 0.45, "glass-wine": 0.4, "mug": 0.4, "cup-coffee": 0.45, "wine-red": 0.42,
	"wine-white": 0.42, "soda-bottle": 0.42, "soda-can": 0.38, "plate": 0.3, "plate-dinner": 0.3, "cocktail": 0.4,
	"pot": 0.45, "bowl": 0.35, "sandwich": 0.35, "salad": 0.3, "fries": 0.4, "cutting-board": 0.45,
}

static var _piezas := {}
static var _mallas_tenidas := {}
static var _mats_tenidos := {}

## Tonos de serie de algunas piezas (el kit trae cojines rosa chicle y
## plantas verde menta): tapicería oscura en sillas de oficina y taburetes...
const TONOS_PIEZA := {
	"chairDesk": {"carpet": Color(0.2, 0.2, 0.23), "metalMedium": Color(0.55, 0.57, 0.6)},
	"stoolBar": {"carpet": Color(0.16, 0.12, 0.1)},
	"chairCushion": {"carpet": Color(0.62, 0.55, 0.46)},
	"pottedPlant": {"plant": Color(0.28, 0.52, 0.26), "wood": Color(0.62, 0.36, 0.22), "woodDark": Color(0.45, 0.3, 0.2)},
	"plantSmall1": {"plant": Color(0.3, 0.55, 0.28)}, "plantSmall2": {"plant": Color(0.3, 0.55, 0.28)}, "plantSmall3": {"plant": Color(0.3, 0.55, 0.28)},
}

# ------------------------------------- primitivas en lote (16-10-2026)
## Cajas, cilindros y esferas de cualquier color que se dibujan juntas: un
## MultiMesh por forma y acabado, con el color por instancia. Para el equipo de
## gimnasio (cientos de discos, mancuernas, losetas...) a pocas llamadas.
## `tam`: caja = medidas; cilindro = (diámetro, alto, diámetro); esfera = diámetro.
## `base`: el marco del aparato (posición y giro); `p` y `rot` van en local.
var _prims := {}
static var _mallas_prim := {}
static var _mats_prim := {}

const _MADERA_CLARA := {"wood": Color(0.78, 0.6, 0.42), "woodDark": Color(0.55, 0.38, 0.25)}
const _MADERA_OSCURA := {"wood": Color(0.5, 0.33, 0.21), "woodDark": Color(0.33, 0.21, 0.13)}
const _TELAS := [Color(0.32, 0.42, 0.58), Color(0.55, 0.3, 0.26), Color(0.4, 0.5, 0.36), Color(0.62, 0.58, 0.5), Color(0.28, 0.28, 0.32)]

static func _sala_de(clave: String) -> Array:
	var base := clave.get_slice("|", 0)
	var fila: Array = (SALAS[base] if SALAS.has(base) else SALAS_EDIFICIO[base]).duplicate()
	if clave.contains("|"):
		fila[1] = clave.get_slice("|", 1)
	return fila

static func tiene(clave: String) -> bool:
	var base := clave.get_slice("|", 0)
	return SALAS.has(base) or SALAS_EDIFICIO.has(base)

static func abrir(padre: Control, clave: String, club: Club = null, minijuego: Callable = Callable()) -> InteriorInstalacion:
	if not tiene(clave):
		return null
	var n := InteriorInstalacion.new()
	n.clave = clave
	n.club = club
	n._minijuego = minijuego
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

## LA SALA PARA PASEARLA (etapa 6): se construye dentro del mundo 3D de la
## ciudad, bajo el mapa, con la fachada cerrada salvo la puerta. Devuelve el
## objeto (hay que añadirlo al árbol para que la gente se mueva) o null.
static func en_mundo(raiz3d: Node3D, clave_: String, club_: Club = null) -> InteriorInstalacion:
	if not tiene(clave_):
		return null
	var n := InteriorInstalacion.new()
	n.clave = clave_
	n.club = club_
	n._raiz = raiz3d
	n.visible = false
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sala: Array = _sala_de(clave_)
	n.tipo = String(sala[0])
	n._rng.seed = hash(clave_)
	n._paseo = true
	if club_ != null:
		n._c1 = Color(club_.color1)
		n._c2 = Color(club_.color2)
	n._construir_sala()
	n._cerrar_para_pasear()
	return n

## El nombre propio de este sitio («Bar El Rincón»).
func _sala_nombre() -> String:
	return String(_sala_de(clave)[1])

## Tamaño de la sala (m): ancho X, alto Y, fondo Z. La puerta está en z = +fondo/2.
func tam_sala() -> Vector3:
	return _tam

static func _escala_de(nombre: String, escala: Variant) -> Vector3:
	if escala is Vector3:
		return escala
	if escala is float or escala is int:
		return Vector3.ONE * float(escala)
	var kit := nombre.get_slice("/", 0) if nombre.contains("/") else "muebles"
	if kit == "comida":
		return Vector3.ONE * float(ESCALA_COMIDA.get(nombre.get_slice("/", 1), 0.3))
	return Vector3.ONE * float(ESCALA_KIT.get(kit, 1.0))

func _tonos_de(nombre: String, tonos: Dictionary) -> Dictionary:
	if nombre.contains("/"):
		return tonos
	## Sala < pieza (la maceta no se tiñe con la madera de la sala) < llamada.
	var t := _tonos_sala.duplicate()
	t.merge(TONOS_PIEZA.get(nombre, {}), true)
	t.merge(tonos, true)
	return t

## Pone una pieza (va a un lote; se monta al final en MultiMesh).
## `p`: centro de la huella a ras del suelo del mueble. `giro`: hacia dónde
## mira su frente (+Z local) — los muebles de Kenney tienen el respaldo en −Z.
func _poner(nombre: String, p: Vector3, giro: float = 0.0, escala: Variant = null, tonos: Dictionary = {}) -> void:
	if nombre == "books" and tonos.is_empty():
		## Lomos de varios colores (el kit los trae todos rosa y turquesa).
		tonos = {"*": [Color.WHITE, Color(0.55, 0.75, 1.0), Color(1.0, 0.8, 0.5), Color(0.7, 1.0, 0.7)][_rng.randi() % 4]}
	var s := _escala_de(nombre, escala)
	var t := _tonos_de(nombre, tonos)
	var k := "%s|%s|%s" % [nombre, str(s), str(t)]
	if not _lotes.has(k):
		_lotes[k] = {"nombre": nombre, "s": s, "tonos": t, "puestos": []}
	(_lotes[k]["puestos"] as Array).append(Transform3D(Basis(Vector3.UP, giro) * Basis.from_scale(s), p))

static func _ruta_pieza(nombre: String) -> String:
	if not nombre.contains("/"):
		return "res://assets/kenney/muebles/%s.glb" % nombre
	var kit := nombre.get_slice("/", 0)
	var pieza := nombre.get_slice("/", 1)
	match kit:
		"quaternius":
			return "res://assets/quaternius_muebles/%s.glb" % pieza
		"coches":
			return "res://assets/ciudad/kenney_cars/%s.glb" % pieza
	return "res://assets/kenney/%s/%s.glb" % [kit, pieza]

static func _alto_bajo(caras: PackedVector3Array, p: Vector2) -> float:
	var mejor := -1.0
	var i := 0
	while i + 2 < caras.size():
		var r: Variant = Geometry3D.ray_intersects_triangle(Vector3(p.x, 50, p.y), Vector3.DOWN, caras[i], caras[i + 1], caras[i + 2])
		if r != null:
			mejor = maxf(mejor, (r as Vector3).y)
		i += 3
	return mejor

## Altura del asiento (rayo al centro de la huella, algo hacia +Z, lejos del
## respaldo) y el centro en Z de la zona que está a esa altura.
static func _medir_asiento(caras: PackedVector3Array, caja: AABB) -> Vector2:
	var alto := _alto_bajo(caras, Vector2(0, caja.size.z * 0.1))
	if alto <= 0.0:
		return Vector2(-1, 0)
	var zs: Array = []
	for k in 13:
		var z := caja.position.z + caja.size.z * (float(k) + 0.5) / 13.0
		if absf(_alto_bajo(caras, Vector2(0, z)) - alto) < caja.size.y * 0.05:
			zs.append(z)
	var zc := 0.0
	if not zs.is_empty():
		zc = (float(zs[0]) + float(zs[-1])) * 0.5
	return Vector2(alto, zc)

## Las mallas de un modelo con su transformación, ya centradas (huella en el
## origen, base en y = 0), su caja y su asiento («alto» y «z» del centro del
## asiento, en unidades del modelo; alto < 0 si no tiene).
static func _pieza(nombre: String) -> Dictionary:
	if _piezas.has(nombre):
		return _piezas[nombre]
	var res := {"mallas": [], "caja": AABB(Vector3.ZERO, Vector3(0.1, 0.1, 0.1)), "asiento": Vector2(-1, 0)}
	var ruta := _ruta_pieza(nombre)
	var ps: PackedScene = load(ruta) if ResourceLoader.exists(ruta) else null
	var n: Node3D = ps.instantiate() as Node3D if ps != null else null
	if n == null:
		push_warning("InteriorInstalacion: falta la pieza " + ruta)
		_piezas[nombre] = res
		return res
	var lista: Array = []
	var caja := AABB()
	var primera := true
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var t := Transform3D.IDENTITY
		var x: Node = mi
		while x != null and x != n:
			if x is Node3D:
				t = (x as Node3D).transform * t
			x = x.get_parent()
		lista.append([mi.mesh, t])
		var a := t * mi.mesh.get_aabb()
		caja = a if primera else caja.merge(a)
		primera = false
	n.free()
	var centro := Vector3(caja.get_center().x, caja.position.y, caja.get_center().z)
	var caras := PackedVector3Array()
	for e: Array in lista:
		e[1] = Transform3D(Basis.IDENTITY, -centro) * (e[1] as Transform3D)
		for v in (e[0] as Mesh).get_faces():
			caras.append((e[1] as Transform3D) * v)
	caja.position -= centro
	res = {"mallas": lista, "caja": caja, "asiento": _medir_asiento(caras, caja)}
	_piezas[nombre] = res
	return res

## La malla con otros colores por material («wood», «carpet», «metal»...; «*»
## multiplica todos, también los de textura). Cacheada por malla y tonos.
static func _malla_tenida(m: Mesh, tonos: Dictionary) -> Mesh:
	if tonos.is_empty():
		return m
	var clave_t := "%d|%s" % [m.get_instance_id(), str(tonos)]
	if _mallas_tenidas.has(clave_t):
		return _mallas_tenidas[clave_t]
	var nm: Mesh = m.duplicate()
	for i in nm.get_surface_count():
		var mat := nm.surface_get_material(i) as StandardMaterial3D
		if mat == null:
			continue
		var col: Variant = tonos.get(String(mat.resource_name), null)
		var mult: Variant = tonos.get("*", null)
		if col == null and mult == null:
			continue
		var k := "%d|%s|%s" % [mat.get_instance_id(), str(col), str(mult)]
		if not _mats_tenidos.has(k):
			var m2: StandardMaterial3D = mat.duplicate()
			if col != null:
				m2.albedo_color = col
			if mult != null:
				m2.albedo_color *= (mult as Color)
			_mats_tenidos[k] = m2
		nm.surface_set_material(i, _mats_tenidos[k])
	_mallas_tenidas[clave_t] = nm
	return nm

static func _malla_prim(forma: String) -> Mesh:
	if _mallas_prim.has(forma):
		return _mallas_prim[forma]
	var m: Mesh
	match forma:
		"cil":
			var c := CylinderMesh.new()
			c.top_radius = 0.5
			c.bottom_radius = 0.5
			c.height = 1.0
			c.radial_segments = 14
			c.rings = 1
			m = c
		"cono":
			var c := CylinderMesh.new()
			c.top_radius = 0.08
			c.bottom_radius = 0.5
			c.height = 1.0
			c.radial_segments = 12
			c.rings = 1
			m = c
		"esf":
			var s := SphereMesh.new()
			s.radius = 0.5
			s.height = 1.0
			s.radial_segments = 14
			s.rings = 7
			m = s
		_:
			m = BoxMesh.new()
	_mallas_prim[forma] = m
	return m

static func _mat_prim(acabado: String) -> StandardMaterial3D:
	if _mats_prim.has(acabado):
		return _mats_prim[acabado]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	match acabado:
		"metal":
			m.metallic = 0.75
			m.roughness = 0.3
		"goma":
			m.roughness = 0.55
		"luz":
			m.roughness = 0.2
			m.emission_enabled = true
			m.emission = Color(0.9, 0.95, 1.0)
			m.emission_energy_multiplier = 0.35
		_:
			m.roughness = 0.85
	_mats_prim[acabado] = m
	return m

## Monta los lotes pendientes: un MultiMeshInstance3D por malla de cada pieza.
func _vaciar_lotes() -> void:
	for k: String in _lotes:
		var l: Dictionary = _lotes[k]
		var pz := _pieza(String(l["nombre"]))
		var puestos: Array = l["puestos"]
		for e: Array in pz["mallas"]:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = _malla_tenida(e[0], l["tonos"])
			mm.instance_count = puestos.size()
			for i in puestos.size():
				mm.set_instance_transform(i, (puestos[i] as Transform3D) * (e[1] as Transform3D))
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Pieza_" + String(l["nombre"]).replace("/", "_")
			mmi.multimesh = mm
			_raiz.add_child(mmi)
	_lotes.clear()
	for k: String in _prims:
		var lista: Array = _prims[k]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _malla_prim(k.get_slice("|", 0))
		mm.instance_count = lista.size()
		for i in lista.size():
			mm.set_instance_transform(i, lista[i][0])
			mm.set_instance_color(i, lista[i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Prim_" + k.replace("|", "_")
		mmi.multimesh = mm
		mmi.material_override = _mat_prim(k.get_slice("|", 1))
		_raiz.add_child(mmi)
	_prims.clear()
