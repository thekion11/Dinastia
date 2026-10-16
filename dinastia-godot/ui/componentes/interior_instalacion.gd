class_name InteriorInstalacion
extends Control
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

## Cierra la fachada (antes baja, para ver dentro) dejando un hueco de puerta de
## 3 m, y pone techo a toda la sala con sus plafones.
func _cerrar_para_pasear() -> void:
	var m := Mini3D.mat(_col_pared, 0.9)
	var zf := _tam.z * 0.5 + 0.15
	var lado := (_tam.x - 3.0) * 0.5
	for sx: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(sx * (1.5 + lado * 0.5), _tam.y * 0.5, zf), Vector3(lado, _tam.y, 0.3), m)
		## Zócalo también en la fachada, por dentro.
		Mini3D.caja(_raiz, Vector3(sx * (1.5 + lado * 0.5), 0.06, zf - 0.165), Vector3(lado, 0.12, 0.03), Mini3D.mat(_col_pared.darkened(0.35), 0.7))
	Mini3D.caja(_raiz, Vector3(0, (_tam.y + 2.6) * 0.5, zf), Vector3(3.0, _tam.y - 2.6, 0.3), m)
	## Techo entero y plafones donde están las luces.
	Mini3D.caja(_raiz, Vector3(0, _tam.y + 0.1, 0), Vector3(_tam.x + 0.6, 0.2, _tam.z + 0.6), Mini3D.mat(Color(0.94, 0.94, 0.92), 0.95))
	var plafon := Mini3D.mat(Color(1.0, 0.97, 0.9), 0.3, 2.0)
	for q: Vector3 in _luces:
		Mini3D.caja(_raiz, Vector3(q.x, _tam.y - 0.02, q.z), Vector3(1.2, 0.04, 0.6), plafon)
	## Marco de la puerta, felpudo y la claridad de la calle al otro lado.
	var marco := Mini3D.mat(Color(0.3, 0.2, 0.14), 0.6)
	for sx: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(sx * 1.55, 1.3, zf), Vector3(0.12, 2.6, 0.4), marco)
	Mini3D.caja(_raiz, Vector3(0, 2.6, zf), Vector3(3.2, 0.14, 0.4), marco)
	_poner("rugDoormat", Vector3(0, 0, zf - 0.6), 0.0, 2.4, {"carpet": Color(0.42, 0.2, 0.16), "carpetDarker": Color(0.3, 0.14, 0.1)})
	Mini3D.caja(_raiz, Vector3(0, 1.3, zf + 0.7), Vector3(3.2, 2.7, 0.05), Mini3D.mat(Color(0.86, 0.9, 0.95), 0.9, 0.9))
	_vaciar_lotes()
	## Luz de ambiente propia: aquí no hay sol.
	var luz := OmniLight3D.new()
	luz.position = Vector3(0, _tam.y - 0.8, 0)
	luz.omni_range = maxf(_tam.x, _tam.z) * 0.9
	luz.light_energy = 0.6
	luz.shadow_enabled = false
	_raiz.add_child(luz)

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

func _montar() -> void:
	_rng.seed = hash(clave) + Time.get_ticks_msec()
	## (la base de la clave decide qué sala; lo que va tras «|» es solo el nombre)
	var sala: Array = _sala_de(clave)
	tipo = String(sala[0])
	if club != null:
		_c1 = Color(club.color1)
		_c2 = Color(club.color2)
	_v = Mini3D.vista(self, Calidad.DIA)
	_cam = _v["cam"]
	_raiz = _v["raiz"]
	## Dentro no hay cielo: fondo oscuro, luz ambiente suave y lámparas, y
	## oclusión ambiental para que los muebles se asienten en el suelo.
	(_v["sol"] as DirectionalLight3D).visible = false
	for we in _raiz.get_children():
		if we is WorldEnvironment:
			var env: Environment = (we as WorldEnvironment).environment
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.05, 0.05, 0.06)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.9, 0.88, 0.85)
			env.ambient_light_energy = 0.5
			env.tonemap_exposure = 1.0
			env.ssao_enabled = true
			env.ssao_radius = 0.8
			env.ssao_intensity = 1.6
			env.ssao_power = 1.4
	_construir_sala()
	_interfaz(String(sala[1]))
	_colocar_camara()

## Levanta la sala según `tipo` en `_raiz` (la usa la ventana y también el paseo).
func _construir_sala() -> void:
	## Ropa corta de deporte solo donde se hace deporte (13-10-2026).
	Mini3D.sala_deportiva = tipo in ["gimnasio", "piscina"]
	match tipo:
		"oficina": _oficina()
		"hospital": _hospital()
		"comisaria": _comisaria()
		"bomberos": _bomberos()
		"aula": _aula()
		"estacion": _estacion()
		"mercado": _mercado()
		"cine": _cine()
		"tienda": _tienda()
		"gimnasio": _gimnasio()
		"analisis": _analisis()
		"comedor": _comedor()
		"prensa": _prensa()
		"museo": _museo()
		"piscina": _piscina()
		"vivienda": _vivienda()
		"bar": _bar()
		"panaderia": _panaderia()
		"peluqueria": _peluqueria()
		"libreria": _libreria()
		"taller": _taller()
		"recreativos": _recreativos()
	_vaciar_lotes()
	## De vuelta al valor de siempre: los minijuegos y la ciudad lo usan.
	Mini3D.sala_deportiva = true

# ------------------------------------------------------------------ la sala

## La caja de la sala a ESCALA HUMANA (15-10-2026: antes eran naves de 22-30 m
## con 5,5-7 m de techo y los muebles se perdían). Las paredes quedan FUERA de
## `tam` (su cara interior es el borde de la sala). `piso`: «parquet», «losa»,
## «moqueta» u «hormigon». `friso` (alfa > 0) pinta el metro bajo de las paredes.
func _sala(tam: Vector3, suelo: Color, pared: Color, piso: String = "losa", friso: Color = Color(0, 0, 0, 0)) -> void:
	_tam = tam
	_col_pared = pared
	var pm := PlaneMesh.new()
	pm.size = Vector2(tam.x, tam.z)
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = _mat_suelo(piso, suelo, tam)
	_raiz.add_child(mi)
	Mini3D.caja(_raiz, Vector3(0, -0.11, 0), Vector3(tam.x + 0.6, 0.2, tam.z + 0.6), Mini3D.mat(suelo.darkened(0.4), 0.9))
	var m := Mini3D.mat(pared, 0.9)
	var hx := tam.x * 0.5
	var hz := tam.z * 0.5
	## Fondo y laterales enteros; la fachada, baja, para ver dentro (al pasear
	## la cierra `_cerrar_para_pasear` con su puerta).
	Mini3D.caja(_raiz, Vector3(0, tam.y * 0.5, -hz - 0.15), Vector3(tam.x + 0.6, tam.y, 0.3), m)
	for lado: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(lado * (hx + 0.15), tam.y * 0.5, 0), Vector3(0.3, tam.y, tam.z), m)
	if not _paseo:
		Mini3D.caja(_raiz, Vector3(0, 0.5, hz + 0.15), Vector3(tam.x + 0.6, 1.0, 0.3), m)
	## Zócalo, friso y moldura del techo.
	var zoc := Mini3D.mat(pared.darkened(0.35), 0.7)
	Mini3D.caja(_raiz, Vector3(0, 0.06, -hz + 0.015), Vector3(tam.x, 0.12, 0.03), zoc)
	for lado: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(lado * (hx - 0.015), 0.06, 0), Vector3(0.03, 0.12, tam.z), zoc)
	if friso.a > 0.0:
		var fm := Mini3D.mat(friso, 0.75)
		Mini3D.caja(_raiz, Vector3(0, 0.55, -hz + 0.01), Vector3(tam.x, 1.1, 0.02), fm)
		for lado: float in [-1.0, 1.0]:
			Mini3D.caja(_raiz, Vector3(lado * (hx - 0.01), 0.55, 0), Vector3(0.02, 1.1, tam.z), fm)
		var listel := Mini3D.mat(friso.darkened(0.3), 0.6)
		Mini3D.caja(_raiz, Vector3(0, 1.11, -hz + 0.025), Vector3(tam.x, 0.04, 0.05), listel)
		for lado: float in [-1.0, 1.0]:
			Mini3D.caja(_raiz, Vector3(lado * (hx - 0.025), 1.11, 0), Vector3(0.05, 0.04, tam.z), listel)
	var mold := Mini3D.mat(pared.lightened(0.25), 0.8)
	Mini3D.caja(_raiz, Vector3(0, tam.y - 0.05, -hz + 0.04), Vector3(tam.x, 0.1, 0.08), mold)
	for lado: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(lado * (hx - 0.04), tam.y - 0.05, 0), Vector3(0.08, 0.1, tam.z), mold)
	## Lámparas en rejilla, una cada ~6 m; las dos primeras con sombra.
	_luces.clear()
	var nx := maxi(1, ceili(tam.x / 6.5))
	var nz := maxi(1, ceili(tam.z / 6.5))
	var sombras := 0
	for i in nx:
		for j in nz:
			var p := Vector3((float(i) + 0.5) / float(nx) * tam.x - hx, tam.y - 0.35, (float(j) + 0.5) / float(nz) * tam.z - hz)
			_luces.append(p)
			var o := OmniLight3D.new()
			o.position = p
			o.omni_range = maxf(tam.x / float(nx), tam.z / float(nz)) * 1.25 + tam.y
			o.light_energy = 0.75
			o.light_color = Color(1.0, 0.95, 0.86)
			o.shadow_enabled = sombras < 2 and nx * nz <= 6
			if o.shadow_enabled:
				sombras += 1
			_raiz.add_child(o)

## Una ventana en una pared lateral (`lado` −1 izquierda, +1 derecha) centrada en
## `z`: cristal claro (la luz de fuera), marco, alféizar y, si se pide, las
## cortinas dobles de Quaternius.
func _ventana(lado: float, z: float, ancho: float = 1.6, cortinas: bool = true) -> void:
	var x := lado * (_tam.x * 0.5 - 0.02)
	var alto := minf(1.5, _tam.y - 1.3)
	var yc := 0.95 + alto * 0.5
	Mini3D.caja(_raiz, Vector3(x, yc, z), Vector3(0.03, alto, ancho), Mini3D.mat(Color(0.78, 0.88, 1.0), 0.2, 1.1))
	var marco := Mini3D.mat(Color(0.95, 0.95, 0.93), 0.5)
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(x - lado * 0.03, yc, z + s * ancho * 0.5), Vector3(0.08, alto + 0.1, 0.08), marco)
		Mini3D.caja(_raiz, Vector3(x - lado * 0.03, yc + s * alto * 0.5, z), Vector3(0.08, 0.08, ancho), marco)
	Mini3D.caja(_raiz, Vector3(x - lado * 0.03, yc, z), Vector3(0.05, alto, 0.05), marco)
	Mini3D.caja(_raiz, Vector3(x - lado * 0.1, 0.93, z), Vector3(0.22, 0.05, ancho + 0.2), marco)
	if cortinas:
		var sy := minf(0.68, (_tam.y - 0.15) / 4.34)
		_poner("quaternius/cortinas_dobles", Vector3(x - lado * 0.22, 0, z), -lado * PI * 0.5, Vector3((ancho + 0.9) / 3.47, sy, 0.6))

func _cartel(texto: String, pos: Vector3, tam: int = 64, col: Color = Color.WHITE, giro: float = 0.0) -> void:
	var l := Label3D.new()
	l.rotation.y = giro
	l.text = texto
	l.font_size = tam
	l.pixel_size = 0.01
	l.modulate = col
	l.outline_size = 8
	l.outline_modulate = Color(0, 0, 0, 0.7)
	l.position = pos
	_raiz.add_child(l)

## Un cuadro en la pared del fondo (lámina de color con marco).
func _cuadro(p: Vector3, tam: Vector2, col: Color) -> void:
	Mini3D.caja(_raiz, p, Vector3(tam.x + 0.08, tam.y + 0.08, 0.04), Mini3D.mat(Color(0.25, 0.18, 0.12), 0.5))
	Mini3D.caja(_raiz, p + Vector3(0, 0, 0.025), Vector3(tam.x, tam.y, 0.01), Mini3D.mat(col, 0.8))

func _pantalla(p: Vector3, tam: Vector2, col: Color, giro: float = 0.0) -> MeshInstance3D:
	var marco := Mini3D.caja(_raiz, p, Vector3(tam.x + 0.08, tam.y + 0.08, 0.06), Mini3D.mat(Color(0.06, 0.06, 0.07), 0.3))
	marco.rotation.y = giro
	var mi := Mini3D.caja(_raiz, p + Vector3(sin(giro), 0, cos(giro)) * 0.035, Vector3(tam.x, tam.y, 0.01), Mini3D.mat(col, 0.2, 1.4))
	mi.rotation.y = giro
	return mi

# ---------------------------------------------- suelos con dibujo (procedural)

static var _texturas_suelo := {}

## Material del suelo: una textura clara con el dibujo (tablas, baldosas,
## moqueta, hormigón) que el color tiñe. Se genera una vez por tipo.
static func _mat_suelo(piso: String, col: Color, tam: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.albedo_texture = _textura_suelo(piso)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var rep: float = {"parquet": 2.0, "losa": 2.4, "moqueta": 1.5, "hormigon": 6.0}.get(piso, 2.4)
	m.uv1_scale = Vector3(tam.x / rep, tam.z / rep, 1.0)
	m.roughness = {"parquet": 0.5, "losa": 0.35, "moqueta": 0.95, "hormigon": 0.8}.get(piso, 0.6)
	return m

static func _textura_suelo(piso: String) -> Texture2D:
	if _texturas_suelo.has(piso):
		return _texturas_suelo[piso]
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(piso)
	match piso:
		"parquet":
			## 8 hileras de tablas de largo variable, con veta y junta oscura.
			for fila in 8:
				var x0 := rng.randi_range(0, 120)
				var x := -x0
				while x < n:
					var largo := rng.randi_range(90, 170)
					var tono := rng.randf_range(0.78, 1.0)
					var veta := rng.randf_range(0.0, 6.28)
					for px in range(maxi(x, 0), mini(x + largo, n)):
						for py in range(fila * 32, fila * 32 + 32):
							var v := tono * (0.94 + 0.06 * sin(float(px) * 0.09 + float(py) * 0.6 + veta))
							if py == fila * 32 or px == x:
								v *= 0.55
							img.set_pixel(px, py, Color(v, v, v))
					x += largo
		"losa":
			for i in 4:
				for j in 4:
					var tono := rng.randf_range(0.92, 1.0)
					for px in range(i * 64, i * 64 + 64):
						for py in range(j * 64, j * 64 + 64):
							var v := tono * rng.randf_range(0.97, 1.0)
							if px - i * 64 < 2 or py - j * 64 < 2:
								v = 0.62
							img.set_pixel(px, py, Color(v, v, v))
		"moqueta":
			for px in n:
				for py in n:
					var v := rng.randf_range(0.86, 1.0)
					img.set_pixel(px, py, Color(v, v, v))
		_:
			var ruido := FastNoiseLite.new()
			ruido.seed = 7
			ruido.frequency = 0.02
			for px in n:
				for py in n:
					var v := 0.88 + ruido.get_noise_2d(float(px), float(py)) * 0.1 + rng.randf_range(-0.03, 0.03)
					img.set_pixel(px, py, Color(v, v, v))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_texturas_suelo[piso] = t
	return t

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

static func _escala_de(nombre: String, escala: Variant) -> Vector3:
	if escala is Vector3:
		return escala
	if escala is float or escala is int:
		return Vector3.ONE * float(escala)
	var kit := nombre.get_slice("/", 0) if nombre.contains("/") else "muebles"
	if kit == "comida":
		return Vector3.ONE * float(ESCALA_COMIDA.get(nombre.get_slice("/", 1), 0.3))
	return Vector3.ONE * float(ESCALA_KIT.get(kit, 1.0))

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

static func _alto_bajo(caras: PackedVector3Array, p: Vector2) -> float:
	var mejor := -1.0
	var i := 0
	while i + 2 < caras.size():
		var r: Variant = Geometry3D.ray_intersects_triangle(Vector3(p.x, 50, p.y), Vector3.DOWN, caras[i], caras[i + 1], caras[i + 2])
		if r != null:
			mejor = maxf(mejor, (r as Vector3).y)
		i += 3
	return mejor

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

## Tonos de serie de algunas piezas (el kit trae cojines rosa chicle y
## plantas verde menta): tapicería oscura en sillas de oficina y taburetes...
const TONOS_PIEZA := {
	"chairDesk": {"carpet": Color(0.2, 0.2, 0.23), "metalMedium": Color(0.55, 0.57, 0.6)},
	"stoolBar": {"carpet": Color(0.16, 0.12, 0.1)},
	"chairCushion": {"carpet": Color(0.62, 0.55, 0.46)},
	"pottedPlant": {"plant": Color(0.28, 0.52, 0.26), "wood": Color(0.62, 0.36, 0.22), "woodDark": Color(0.45, 0.3, 0.2)},
	"plantSmall1": {"plant": Color(0.3, 0.55, 0.28)}, "plantSmall2": {"plant": Color(0.3, 0.55, 0.28)}, "plantSmall3": {"plant": Color(0.3, 0.55, 0.28)},
}

func _tonos_de(nombre: String, tonos: Dictionary) -> Dictionary:
	if nombre.contains("/"):
		return tonos
	## Sala < pieza (la maceta no se tiñe con la madera de la sala) < llamada.
	var t := _tonos_sala.duplicate()
	t.merge(TONOS_PIEZA.get(nombre, {}), true)
	t.merge(tonos, true)
	return t

## Medidas (m) de una pieza a la escala con la que se pone.
func _medida(nombre: String, escala: Variant = null) -> Vector3:
	return (_pieza(nombre)["caja"] as AABB).size * _escala_de(nombre, escala)

func _alto(nombre: String, escala: Variant = null) -> float:
	return _medida(nombre, escala).y

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

# ------------------------------------- primitivas en lote (16-10-2026)
## Cajas, cilindros y esferas de cualquier color que se dibujan juntas: un
## MultiMesh por forma y acabado, con el color por instancia. Para el equipo de
## gimnasio (cientos de discos, mancuernas, losetas...) a pocas llamadas.
## `tam`: caja = medidas; cilindro = (diámetro, alto, diámetro); esfera = diámetro.
## `base`: el marco del aparato (posición y giro); `p` y `rot` van en local.
var _prims := {}
static var _mallas_prim := {}
static var _mats_prim := {}

func _prim(forma: String, p: Vector3, tam: Vector3, col: Color, acabado: String = "mate", rot: Vector3 = Vector3.ZERO, base: Transform3D = Transform3D.IDENTITY) -> void:
	var k := forma + "|" + acabado
	if not _prims.has(k):
		_prims[k] = []
	(_prims[k] as Array).append([base * Transform3D(Basis.from_euler(rot) * Basis.from_scale(tam), p), col])

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

## Un asiento del kit con gente: `plazas` son los desplazamientos laterales (m)
## de quien se sienta (vacío = libre). La persona queda en el centro del
## asiento medido del modelo, a su altura, mirando a `giro`.
func _asiento(nombre: String, p: Vector3, giro: float, plazas: Array = [0.0], deporte: Array = [], escala: Variant = null, tonos: Dictionary = {}) -> void:
	_poner(nombre, p, giro, escala, tonos)
	var a: Vector2 = _pieza(nombre)["asiento"]
	if a.x <= 0.0:
		return
	var s := _escala_de(nombre, escala)
	var f := Vector3(sin(giro), 0, cos(giro))
	var lado := Vector3(cos(giro), 0, -sin(giro))
	for x: float in plazas:
		## (+5 cm: con el clip «sentado» la pelvis queda 4-6 cm detrás del origen)
		var c := p + f * (a.y * s.z + 0.05) + lado * x
		_trabajador(c, giro, true, [], deporte, a.x * s.y)

## Un puesto de trabajo: mesa, ordenador y silla, con alguien sentado mirando a
## `giro` (la mesa queda delante de él). `p`: centro de la mesa.
func _puesto(p: Vector3, giro: float, pantalla: bool = true, ocupado: bool = true, deporte: Array = [], mesa: String = "desk") -> void:
	var f := Vector3(sin(giro), 0, cos(giro))
	var lado := Vector3(cos(giro), 0, -sin(giro))
	_poner(mesa, p, giro)
	var m := _medida(mesa)
	var arriba := Vector3(0, m.y, 0)
	if pantalla:
		_poner("computerScreen", p + arriba + f * (m.z * 0.18), giro + PI, 1.5)
		_poner("computerKeyboard", p + arriba - f * (m.z * 0.15), giro + PI, 1.6)
		_poner("computerMouse", p + arriba - f * (m.z * 0.15) + lado * 0.32, giro + PI, 1.6)
	else:
		_poner("books", p + arriba + lado * 0.3, giro + _rng.randf_range(-0.4, 0.4), 1.6)
	_poner("comida/mug", p + arriba - lado * (m.x * 0.32), _rng.randf() * TAU)
	_asiento("chairDesk", p - f * (m.z * 0.5 + 0.3), giro, [0.0] if ocupado else [], deporte)

## Mesa con sillas a lo largo de sus dos lados largos (X local) y gente sentada
## con probabilidad `ocupa`; un plato (y lo que se pida) delante de cada silla.
func _mesa_con_sillas(p: Vector3, giro: float, mesa: String, escala_mesa: Variant, por_lado: int, silla: String,
		ocupa: float, deporte: Array = [], plato: String = "comida/plate", encima: Array = [], tonos_silla: Dictionary = {}) -> void:
	_poner(mesa, p, giro, escala_mesa)
	var m := _medida(mesa, escala_mesa)
	var f := Vector3(sin(giro), 0, cos(giro))
	var lado := Vector3(cos(giro), 0, -sin(giro))
	for k in por_lado:
		var x := (float(k) + 0.5) / float(por_lado) * m.x - m.x * 0.5
		for s: float in [-1.0, 1.0]:
			## La silla mira a la mesa: la de −Z, hacia +Z (giro), y al revés.
			var c := p + lado * x + f * (s * (m.z * 0.5 + 0.2))
			var g := giro if s < 0.0 else giro + PI
			_asiento(silla, c, g, [0.0] if _rng.randf() < ocupa else [], deporte, null, tonos_silla)
			var sobre := p + lado * x + f * (s * (m.z * 0.5 - 0.22)) + Vector3(0, m.y, 0)
			if plato != "":
				_poner(plato, sobre, 0.0)
			if not encima.is_empty():
				_poner(String(encima[_rng.randi() % encima.size()]), sobre + lado * 0.2 + Vector3(0, 0.01, 0), _rng.randf() * TAU)

## Una planta en maceta (las grandes de Kenney, con un poco de variedad).
func _planta(p: Vector3, grande: bool = true) -> void:
	## (escala por lotes de dos tamaños: si cada maceta tuviera la suya, cada una
	## sería un MultiMesh aparte)
	_poner("pottedPlant", p, _rng.randf() * TAU, 2.2 if grande else 1.5)

## Una caja de cobro del mini mercado (registradora en un extremo, cinta en el
## otro) con el cajero en su puesto, junto a la registradora, y un cliente al
## otro lado de la cinta si se pide.
func _caja_cobro(p: Vector3, giro: float, uniforme: Array, cliente: bool, tonos: Dictionary = {}) -> void:
	_poner("mini_mercado/cash-register", p, giro, null, tonos)
	var f := Vector3(sin(giro), 0, cos(giro))
	var lado := Vector3(cos(giro), 0, -sin(giro))
	_trabajador(p + f * 0.85 + lado * 0.45, giro + PI, false, ["saludo_mano", "charla"], uniforme)
	if cliente:
		_trabajador(p - f * 0.85 - lado * 0.2, giro, false, ["charla", "brazos_jarra"], _calle())

## Una camiseta (colgada en una barra o plegada en una mesa) con dos colores.
func _camiseta(p: Vector3, giro: float, c1: Color, c2: Color, plegada: bool = false) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = giro
	_raiz.add_child(n)
	var m1 := Mini3D.mat(c1, 0.85)
	var m2 := Mini3D.mat(c2, 0.85)
	if plegada:
		Mini3D.caja(n, Vector3(0, 0.03, 0), Vector3(0.34, 0.06, 0.28), m1)
		Mini3D.caja(n, Vector3(0, 0.062, -0.1), Vector3(0.12, 0.005, 0.05), m2)
		return
	Mini3D.caja(n, Vector3(0, -0.36, 0), Vector3(0.48, 0.62, 0.03), m1)
	Mini3D.caja(n, Vector3(0, -0.36, 0.017), Vector3(0.1, 0.62, 0.005), m2)
	for s: float in [-1.0, 1.0]:
		var manga := Mini3D.caja(n, Vector3(s * 0.3, -0.16, 0), Vector3(0.2, 0.18, 0.03), m1)
		manga.rotation.z = s * 0.5
	Mini3D.caja(n, Vector3(0, -0.06, 0.012), Vector3(0.14, 0.04, 0.01), m2)
	## Percha.
	Mini3D.caja(n, Vector3(0, -0.03, 0), Vector3(0.36, 0.02, 0.02), Mini3D.mat(Color(0.3, 0.2, 0.12), 0.6))

## Barra de ropa con camisetas colgadas, de `largo` m, mirando a `giro`.
func _perchero(p: Vector3, giro: float, largo: float, c1: Color, c2: Color) -> void:
	var lado := Vector3(cos(giro), 0, -sin(giro))
	var metal := Mini3D.mat(Color(0.7, 0.72, 0.75), 0.25)
	metal.metallic = 0.8
	for s: float in [-1.0, 1.0]:
		Mini3D.cilindro(_raiz, p + lado * (s * largo * 0.5) + Vector3(0, 0.8, 0), 0.02, 1.6, metal)
	var barra := Mini3D.cilindro(_raiz, p + Vector3(0, 1.6, 0), 0.015, largo, metal)
	barra.rotation = Vector3(0, giro, PI * 0.5)
	var n := int(largo / 0.56)
	for k in n:
		var x := (float(k) + 0.5) / float(n) * largo - largo * 0.5
		var alterna := k % 3 == 2
		_camiseta(p + lado * x + Vector3(0, 1.6, 0), giro + _rng.randf_range(-0.06, 0.06), c2 if alterna else c1, c1 if alterna else c2)

# ------------------------------------------------------------------ gente

## Alguien en su puesto: quieto (o sentado) y de vez en cuando un gesto.
## Sentado: `p` es el CENTRO DEL ASIENTO a ras del suelo del mueble y `asiento`
## su altura. El clip «sentado» dobla las piernas pero deja la cadera a la altura
## de estar de pie (medido: la de la pose de reposo ×0,99), así que hay que bajar a cada uno
## según su esqueleto; antes se colocaban a ojo y quedaban sentados en el aire.
func _trabajador(p: Vector3, giro: float, sentado: bool, gestos: Array = ["charla", "saludo_mano", "brazos_jarra", "pedir_calma"], deporte: Array = [], asiento: float = 0.45) -> void:
	var d := Mini3D.persona(_raiz, _rng, p, deporte)
	if d.is_empty():
		return
	(d["nodo"] as Node3D).rotation.y = giro
	if sentado:
		var cadera := _altura_cadera(d["nodo"])
		if cadera > 0.0:
			(d["nodo"] as Node3D).position.y = p.y + asiento + 0.08 - cadera * 0.99
	Mini3D.anim(d, "sentado" if sentado else "parado", "")
	(d["anim"] as AnimationPlayer).seek(_rng.randf() * 0.5, true)
	_fijos.append({"d": d, "gestos": [] if sentado else gestos, "t": _rng.randf_range(1.0, 5.0), "base": "sentado" if sentado else "parado"})

## Altura de la pelvis de pie (pose de reposo) respecto al origen de la persona,
## con las escalas de todos los nodos de por medio. 0 si no se encuentra.
static func _altura_cadera(nodo: Node3D) -> float:
	var esqueletos := nodo.find_children("*", "Skeleton3D", true, false)
	if esqueletos.is_empty():
		return 0.0
	var sk: Skeleton3D = esqueletos[0]
	var b := sk.find_bone("pelvis")
	if b < 0:
		b = sk.find_bone("Hips")
	if b < 0:
		return 0.0
	var t := sk.get_bone_global_rest(b)
	var n: Node = sk
	while n != null and n != nodo:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t.origin.y

## Alguien que va y viene entre varios puntos de la sala.
func _caminante(puntos: Array, deporte: Array = [], correr: bool = false) -> void:
	## Cada uno con su desvío y empezando en un punto distinto del recorrido:
	## si no, iban todos en fila india.
	var desvio := Vector3(_rng.randf_range(-0.8, 0.8), 0, _rng.randf_range(-0.8, 0.8))
	var pts: Array = []
	for q: Vector3 in puntos:
		pts.append(q + desvio)
	var i := _rng.randi() % pts.size()
	var siguiente := (i + 1) % pts.size()
	var inicio: Vector3 = (pts[i] as Vector3).lerp(pts[siguiente], _rng.randf())
	var d := Mini3D.persona(_raiz, _rng, inicio, deporte)
	if d.is_empty():
		return
	Mini3D.anim(d, "trotar" if correr else "caminar", "")
	(d["anim"] as AnimationPlayer).seek(_rng.randf(), true)
	_caminantes.append({"d": d, "puntos": pts, "i": siguiente, "espera": 0.0, "vel": (3.2 if correr else 1.3) * _rng.randf_range(0.85, 1.15), "clip": "trotar" if correr else "caminar"})

func _process(delta: float) -> void:
	for f: Dictionary in _fijos:
		if (f["gestos"] as Array).is_empty():
			continue
		f["t"] = float(f["t"]) - delta
		if float(f["t"]) <= 0.0:
			f["t"] = _rng.randf_range(3.0, 7.0)
			var g: Array = f["gestos"]
			Mini3D.anim(f["d"], String(g[_rng.randi() % g.size()]), String(f["base"]))
	for c: Dictionary in _caminantes:
		var n: Node3D = c["d"]["nodo"]
		if float(c["espera"]) > 0.0:
			c["espera"] = float(c["espera"]) - delta
			if float(c["espera"]) <= 0.0:
				Mini3D.anim(c["d"], String(c["clip"]), "")
			continue
		var pts: Array = c["puntos"]
		var dest: Vector3 = pts[int(c["i"])]
		var dd := dest - n.position
		dd.y = 0.0
		if dd.length() < 0.2:
			c["i"] = (int(c["i"]) + 1) % pts.size()
			c["espera"] = _rng.randf_range(0.8, 3.0)
			Mini3D.anim(c["d"], ["parado", "charla", "saludo_mano"][_rng.randi() % 3], "parado")
			continue
		n.rotation.y = lerp_angle(n.rotation.y, atan2(dd.x, dd.z), clampf(delta * 6.0, 0.0, 1.0))
		n.position += dd.normalized() * minf(float(c["vel"]) * delta, dd.length())
	if _girando and not _arrastre:
		_ang += delta * 0.06
	_colocar_camara()

func _colocar_camara() -> void:
	if _cam == null:
		return
	## Vista de casa de muñecas (15-10-2026): sin techo y con la fachada baja,
	## desde arriba y por delante, a la distancia que abarca la sala entera.
	var d := maxf(_tam.x * 0.72, _tam.z * 1.1) * _dist
	var elev := 0.74
	var objetivo := Vector3(0, 0.6, -_tam.z * 0.08)
	var pos := objetivo + Vector3(sin(_ang) * cos(elev), sin(elev), cos(_ang) * cos(elev)) * d
	## Que no se salga del lado abierto de la sala: siempre por delante.
	if pos.z < _tam.z * 0.25:
		pos.z = _tam.z * 0.25 + absf(pos.z - _tam.z * 0.25) * 0.3
	_cam.position = pos
	_cam.look_at(objetivo, Vector3.UP)

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_arrastre = mb.pressed
			_girando = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist = clampf(_dist - 0.06, 0.55, 1.4)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist = clampf(_dist + 0.06, 0.55, 1.4)
		accept_event()
	elif ev is InputEventMouseMotion and _arrastre:
		_ang -= (ev as InputEventMouseMotion).relative.x * 0.005
		accept_event()
	elif ev is InputEventScreenDrag:
		_ang -= (ev as InputEventScreenDrag).relative.x * 0.005
		_girando = false
		accept_event()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		_cerrar()
		get_viewport().set_input_as_handled()

func _cerrar() -> void:
	cerrado.emit()
	queue_free()

func _interfaz(nombre: String) -> void:
	var banda := ColorRect.new()
	banda.color = Color(0, 0, 0, 0.5)
	banda.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banda.offset_bottom = 56
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banda)
	_titulo = Label.new()
	_titulo.text = "🚪 %s  ·  %d personas  ·  arrastra para girar, rueda para acercar, Esc para salir" % [nombre, _raiz.find_children("*", "Skeleton3D", true, false).size()]
	_titulo.add_theme_font_size_override("font_size", 20)
	_titulo.position = Vector2(20, 14)
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_titulo)
	var salir := Button.new()
	salir.text = "Salir"
	salir.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	salir.offset_left = -110
	salir.offset_right = -20
	salir.offset_top = 10
	salir.offset_bottom = 46
	salir.pressed.connect(_cerrar)
	add_child(salir)
	if _minijuego.is_valid():
		var jugar := Button.new()
		jugar.text = "🎮 Jugar aquí"
		jugar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		jugar.offset_left = -260
		jugar.offset_right = -120
		jugar.offset_top = 10
		jugar.offset_bottom = 46
		jugar.pressed.connect(func() -> void:
			var f := _minijuego
			_cerrar()
			f.call())
		add_child(jugar)
# ------------------------------------------------------------------ recetas
## Todas con muebles de los kits (15-10-2026, pedido: «a ese nivel debe estar
## todo en la ciudad»). Convenciones: la puerta está en z = +fondo/2 y su paso
## (|x| < 2 y los 2,6 m de delante) queda libre para entrar caminando.

## Ropa de calle de un vecino cualquiera (dos colores al azar).
func _calle() -> Array:
	return [Color.from_hsv(_rng.randf(), _rng.randf_range(0.3, 0.6), _rng.randf_range(0.45, 0.8)), Color.from_hsv(_rng.randf_range(0.55, 0.7), 0.3, _rng.randf_range(0.2, 0.4))]

const _MADERA_CLARA := {"wood": Color(0.78, 0.6, 0.42), "woodDark": Color(0.55, 0.38, 0.25)}
const _MADERA_OSCURA := {"wood": Color(0.5, 0.33, 0.21), "woodDark": Color(0.33, 0.21, 0.13)}
const _TELAS := [Color(0.32, 0.42, 0.58), Color(0.55, 0.3, 0.26), Color(0.4, 0.5, 0.36), Color(0.62, 0.58, 0.5), Color(0.28, 0.28, 0.32)]

## Una fila de muebles de cocina a lo largo de X (desde `x0`, de izquierda a
## derecha) contra la pared del fondo; devuelve la x donde acaba.
func _cocina(x0: float, z: float, piezas: Array, giro: float = 0.0, altos: bool = true) -> float:
	var x := x0
	for nombre: String in piezas:
		var m := _medida(nombre)
		x += m.x * 0.5
		_poner(nombre, Vector3(x, 0, z), giro)
		if altos and nombre != "kitchenFridgeLarge" and nombre != "kitchenFridge":
			if nombre == "kitchenStove" or nombre == "kitchenStoveElectric":
				_poner("hoodModern", Vector3(x, 1.55, z - m.z * 0.5 + 0.28), giro)
			else:
				_poner("kitchenCabinetUpper", Vector3(x, 1.5, z - m.z * 0.5 + 0.22), giro)
		x += m.x * 0.5
	return x

## Vivienda (12 × 9 m, techo de 3 m): salón con sofá, tele y alfombra; cocina
## al fondo; mesa de comer; y la familia que vive allí.
func _vivienda() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(12, 3.0, 9), Color(0.7, 0.5, 0.34), Color(0.93, 0.89, 0.82), "parquet")
	var tela: Color = _TELAS[_rng.randi() % _TELAS.size()]
	## Salón.
	_poner("quaternius/alfombra", Vector3(-3.2, 0, -2.3), PI * 0.5)
	_poner("cabinetTelevision", Vector3(-3.2, 0, -4.25))
	_poner("televisionModern", Vector3(-3.2, _alto("cabinetTelevision"), -4.3))
	_poner("speakerSmall", Vector3(-4.4, 0, -4.35))
	_poner("speakerSmall", Vector3(-2.0, 0, -4.35))
	_poner("tableCoffee", Vector3(-3.2, 0, -2.4))
	_poner("books", Vector3(-3.0, _alto("tableCoffee"), -2.4), 0.3)
	_poner("plantSmall2", Vector3(-3.5, _alto("tableCoffee"), -2.35))
	_asiento("loungeSofa", Vector3(-3.2, 0, -0.85), PI, [-0.45], _calle(), null, {"carpet": tela})
	_poner("pillowBlue", Vector3(-2.5, 0.46, -0.75), PI)
	_asiento("loungeChair", Vector3(-5.1, 0, -2.4), PI * 0.5, [], [], null, {"carpet": tela.darkened(0.2)})
	_poner("lampRoundFloor", Vector3(-5.5, 0, -3.9))
	for z: float in [0.1, 0.92]:
		_poner("bookcaseOpen", Vector3(-5.74, 0, z), PI * 0.5)
		for k in 3:
			_poner("books", Vector3(-5.74, 0.42 + float(k) * 0.5, z + _rng.randf_range(-0.15, 0.15)), PI * 0.5)
	_planta(Vector3(-5.4, 0, 2.2))
	_ventana(-1.0, -2.4)
	_cuadro(Vector3(-3.2, 2.05, -4.47), Vector2(1.2, 0.6), Color.from_hsv(_rng.randf(), 0.35, 0.75))
	## Cocina al fondo a la derecha.
	var zc := -4.5 + 0.45
	var fin := _cocina(0.62, zc, ["kitchenCabinetDrawer", "kitchenSink", "kitchenCabinet", "kitchenStove", "kitchenCabinet"])
	_poner("kitchenFridgeLarge", Vector3(fin + 0.53, 0, -4.5 + 0.42))
	var encimera := _alto("kitchenCabinet")
	_poner("kitchenCoffeeMachine", Vector3(1.05, encimera, zc - 0.1))
	_poner("toaster", Vector3(2.9, encimera, zc - 0.1))
	_poner("comida/pot", Vector3(3.5, _alto("kitchenStove"), zc))
	_poner("comida/cutting-board", Vector3(4.4, encimera, zc + 0.05), PI * 0.5)
	_trabajador(Vector3(3.3, 0, -3.05), PI, false, ["charla", "brazos_jarra"], [Color(0.9, 0.85, 0.7), Color(0.3, 0.3, 0.35), true])
	## Comedor.
	_mesa_con_sillas(Vector3(3.3, 0, -0.6), 0.0, "table", 2.2, 2, "chairCushion", 0.4, _calle(), "comida/plate", ["comida/glass"])
	_poner("comida/cake", Vector3(3.3, _alto("table", 2.2), -0.6))
	_ventana(1.0, 0.6)
	## Entrada.
	_poner("coatRackStanding", Vector3(2.5, 0, 4.15))
	_planta(Vector3(5.5, 0, 4.0))
	_poner("trashcan", Vector3(5.6, 0, -2.9), 0.0, 1.4)
	_caminante([Vector3(-4.4, 0, 1.6), Vector3(4.4, 0, 1.6), Vector3(4.4, 0, 2.9), Vector3(-4.4, 0, 2.9)])
	_cartel("🏠 " + _sala_nombre().to_upper(), Vector3(-0.4, 2.62, -4.45), 26)

## Bar (14 × 10 m): barra con taburetes, botellero, mesas, tragaperras y tele
## con el fútbol; el camarero y los clientes.
func _bar() -> void:
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(14, 3.4, 10), Color(0.46, 0.32, 0.22), Color(0.82, 0.62, 0.45), "parquet", Color(0.36, 0.22, 0.14))
	## La barra (piezas de barra de cocina a ×2,5: 1,05 m de alto).
	var zb := -2.4
	var esc_barra := 2.5
	var ancho := _medida("kitchenBar", esc_barra).x
	var xs: Array = []
	for k in 6:
		xs.append(-5.6 + float(k) * ancho)
		_poner("kitchenBar", Vector3(float(xs[k]), 0, zb), 0.0, esc_barra)
	_poner("kitchenBarEnd", Vector3(-5.6 - ancho * 0.5 - _medida("kitchenBarEnd", esc_barra).x * 0.5, 0, zb), 0.0, esc_barra)
	_poner("kitchenBarEnd", Vector3(float(xs[5]) + ancho * 0.5 + _medida("kitchenBarEnd", esc_barra).x * 0.5, 0, zb), PI, esc_barra)
	var tope := _alto("kitchenBar", esc_barra)
	## Grifos de cerveza, vasos y servilleteros sobre la barra.
	var metal := Mini3D.mat(Color(0.85, 0.85, 0.88), 0.2)
	metal.metallic = 0.9
	for k in 3:
		Mini3D.cilindro(_raiz, Vector3(-3.0 + float(k) * 0.25, tope + 0.2, zb - 0.1), 0.025, 0.4, metal)
	for x: float in xs:
		if _rng.randf() < 0.6:
			_poner(["comida/glass", "comida/mug", "comida/glass-wine", "comida/cup-coffee"][_rng.randi() % 4], Vector3(x + _rng.randf_range(-0.3, 0.3), tope, zb + 0.1), _rng.randf() * TAU)
	## Taburetes y clientes sentados de cara a la barra.
	var cliente := [false, true, true, false, true, false]
	for k in 6:
		_asiento("stoolBar", Vector3(float(xs[k]), 0, zb + 0.75), PI, [0.0] if cliente[k] else [], _calle())
	## Detrás: muebles bajos, botellero con botellas y la cafetera.
	var fin := _cocina(-6.6, -5.0 + 0.45, ["kitchenCabinet", "kitchenCabinetDrawer", "kitchenSink", "kitchenCabinet", "kitchenFridgeBuiltIn", "kitchenCabinetDrawer"], 0.0, false)
	_poner("kitchenCoffeeMachine", Vector3(-1.9, _alto("kitchenCabinet"), -4.6), 0.0, 2.4)
	var madera := Mini3D.mat(Color(0.33, 0.21, 0.13), 0.6)
	for y: float in [1.45, 1.9, 2.35]:
		Mini3D.caja(_raiz, Vector3((-6.6 + fin) * 0.5, y, -4.86), Vector3(fin + 6.6, 0.05, 0.28), madera)
		var x := -6.45
		while x < fin - 0.15:
			_poner(["comida/wine-red", "comida/wine-white", "comida/soda-bottle"][_rng.randi() % 3], Vector3(x, y + 0.025, -4.86), _rng.randf() * TAU)
			x += _rng.randf_range(0.16, 0.26)
	Mini3D.caja(_raiz, Vector3((-6.6 + fin) * 0.5, 1.92, -4.995), Vector3(fin + 6.6, 1.2, 0.01), Mini3D.mat(Color(0.75, 0.8, 0.85), 0.05))
	_trabajador(Vector3(-3.6, 0, -3.35), 0.0, false, ["charla", "brazos_jarra", "saludo_mano"], [Color(0.95, 0.95, 0.95), Color(0.15, 0.15, 0.18), true])
	_trabajador(Vector3(1.0, 0, -1.6), -PI * 0.7, false, ["charla", "aplaudir", "brazos_jarra"], _calle())
	## La pizarra del menú y el rótulo.
	Mini3D.caja(_raiz, Vector3(2.9, 1.9, -4.97), Vector3(1.6, 1.1, 0.04), Mini3D.mat(Color(0.12, 0.14, 0.13), 0.9))
	_cartel("MENÚ DEL DÍA\nTortilla · Croquetas\nCaña · Café", Vector3(2.9, 1.9, -4.93), 18, Color(0.95, 0.95, 0.88))
	_cartel("🍺 " + _sala_nombre().to_upper(), Vector3(-3.0, 2.95, -4.9), 30, Color(1.0, 0.85, 0.5))
	## Mesas de bar con dos sillas y algo de beber.
	var mesa_esc := Vector3(1.25, 2.2, 1.9)
	for p: Vector3 in [Vector3(-5.0, 0, 0.8), Vector3(-2.0, 0, 0.8), Vector3(1.6, 0, 0.9), Vector3(4.6, 0, 0.8), Vector3(-5.0, 0, 3.4), Vector3(4.6, 0, 3.4)]:
		_poner("table", p, PI * 0.5, mesa_esc)
		var alto_m := _alto("table", mesa_esc)
		for s: float in [-1.0, 1.0]:
			_asiento("chair", p + Vector3(s * 0.78, 0, 0), -s * PI * 0.5, [0.0] if _rng.randf() < 0.55 else [], _calle())
			_poner(["comida/glass-wine", "comida/mug", "comida/cocktail", "comida/glass"][_rng.randi() % 4], p + Vector3(s * 0.22, alto_m, _rng.randf_range(-0.15, 0.15)), _rng.randf() * TAU)
		if _rng.randf() < 0.5:
			_poner("comida/plate", p + Vector3(0, alto_m, 0.1))
			_poner(["comida/fries", "comida/sandwich", "comida/burger"][_rng.randi() % 3], p + Vector3(0, alto_m + 0.02, 0.1), _rng.randf() * TAU)
	## El rincón de las máquinas y la tele del partido.
	_poner("mini_arcade/gambling-machine", Vector3(6.4, 0, -3.6), -PI * 0.5)
	_poner("mini_arcade/arcade-machine", Vector3(6.45, 0, -2.4), -PI * 0.5)
	_pantalla(Vector3(6.96, 2.15, 0.6), Vector2(1.6, 0.9), Color(0.25, 0.6, 0.3), -PI * 0.5)
	_planta(Vector3(-6.5, 0, 4.4))
	_planta(Vector3(6.5, 0, 4.4))
	_ventana(-1.0, -0.6, 1.6, false)
	_caminante([Vector3(-6.4, 0, 2.1), Vector3(5.8, 0, 2.1), Vector3(5.8, 0, -0.7), Vector3(-6.4, 0, -0.7)], [Color(0.95, 0.95, 0.95), Color(0.15, 0.15, 0.18), true])

## SALA DE RECREATIVOS (16-10-2026, kit Mini Arcade de Kenney a ×2,4): 16 × 12 m,
## moqueta oscura y neones. Fila de máquinas en el fondo, pinballs a la izquierda,
## grúas, rueda de premios y la taquilla a la derecha, dos mesas de air hockey en
## medio y las máquinas de baile junto a la entrada. Las máquinas miran a +Z
## local (como en el bar); quien juega se pone delante, mirando a la pantalla.
func _recreativos() -> void:
	_sala(Vector3(16, 3.6, 12), Color(0.16, 0.1, 0.22), Color(0.2, 0.17, 0.28), "moqueta", Color(0.1, 0.08, 0.14))
	var ropa := [Color(0.85, 0.15, 0.45), Color(0.12, 0.12, 0.16), true]
	## Fondo: siete máquinas de pantalla y dos canastas.
	for k in 7:
		var x := -6.4 + float(k) * 1.12
		_poner("mini_arcade/arcade-machine", Vector3(x, 0, -5.3), 0.0)
		if k in [0, 2, 3, 5]:
			_trabajador(Vector3(x, 0, -4.15), PI, false, ["charla"], _calle())
	for x: float in [3.2, 5.2]:
		_poner("mini_arcade/basketball-game", Vector3(x, 0, -4.7), 0.0)
	_trabajador(Vector3(3.2, 0, -3.05), PI, false, ["aplaudir", "charla"], _calle())
	## Izquierda: pinballs contra la pared, mirando a la sala.
	for k in 4:
		var z := -2.6 + float(k) * 1.35
		_poner("mini_arcade/pinball", Vector3(-7.05, 0, z), PI * 0.5)
		if k % 2 == 0:
			_trabajador(Vector3(-5.9, 0, z), -PI * 0.5, false, ["charla"], _calle())
	## Derecha: grúas, rueda de premios y máquina de tickets.
	for k in 3:
		var z2 := -4.4 + float(k) * 1.7
		_poner("mini_arcade/claw-machine", Vector3(7.1, 0, z2), -PI * 0.5)
	_trabajador(Vector3(5.8, 0, -2.7), PI * 0.5, false, ["charla", "aplaudir"], _calle())
	_poner("mini_arcade/prize-wheel", Vector3(7.55, 0, 0.6), -PI * 0.5)
	_poner("mini_arcade/ticket-machine", Vector3(7.45, 0, 1.75), -PI * 0.5)
	## La taquilla de premios junto a la entrada, con su empleada.
	_poner("mini_arcade/cash-register", Vector3(5.6, 0, 3.9), -PI * 0.5)
	_poner("mini_arcade/prizes", Vector3(7.5, 0, 4.3), -PI * 0.5)
	_poner("mini_arcade/prizes", Vector3(5.6, 0, 5.5), PI)
	_trabajador(Vector3(6.75, 0, 3.6), -PI * 0.5, false, ["saludo_mano", "charla"], ropa)
	_trabajador(Vector3(4.2, 0, 3.9), PI * 0.5, false, ["charla", "brazos_jarra"], _calle())
	## En medio, dos mesas de air hockey con una pareja jugando en cada una.
	for x2: float in [-2.6, 1.4]:
		_poner("mini_arcade/air-hockey", Vector3(x2, 0, 0.2), 0.0)
		if x2 < 0.0 or _rng.randf() < 0.7:
			for s: float in [-1.0, 1.0]:
				_trabajador(Vector3(x2 + s * 1.65, 0, 0.2), -s * PI * 0.5, false, ["aplaudir", "charla", "brazos_jarra"], _calle())
	## Junto a la entrada: dos máquinas de baile, una con alguien encima.
	for k in 2:
		var z3 := 2.6 + float(k) * 1.9
		_poner("mini_arcade/dance-machine", Vector3(-6.7, 0, z3), PI * 0.5)
	_trabajador(Vector3(-6.0, 0.1, 2.6), -PI * 0.5, false, ["aplaudir", "saludo_mano"], _calle())
	_poner("mini_arcade/vending-machine", Vector3(-3.2, 0, 5.4), PI)
	_poner("mini_arcade/vending-machine", Vector3(-2.0, 0, 5.4), PI)
	## Neones a lo largo de las paredes y carteles luminosos.
	var neones := [Mini3D.mat(Color(1.0, 0.2, 0.7), 0.4, 3.0), Mini3D.mat(Color(0.2, 0.85, 1.0), 0.4, 3.0)]
	Mini3D.caja(_raiz, Vector3(0, 3.25, -5.97), Vector3(15.6, 0.06, 0.04), neones[0])
	Mini3D.caja(_raiz, Vector3(0, 0.25, -5.97), Vector3(15.6, 0.04, 0.04), neones[1])
	for lado: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(lado * 7.97, 3.25, 0), Vector3(0.04, 0.06, 11.6), neones[1 if lado < 0.0 else 0])
	_cartel("🕹️ " + _sala_nombre().to_upper(), Vector3(-2.6, 2.75, -5.9), 40, Color(1.0, 0.5, 0.9))
	_cartel("★ RÉCORDS ★", Vector3(4.2, 2.6, -5.9), 22, Color(0.5, 0.95, 1.0))
	_cuadro(Vector3(4.2, 1.95, -5.95), Vector2(2.2, 0.8), Color(0.1, 0.1, 0.25))
	## Gente que va de máquina en máquina.
	for k in 3:
		var z4 := -1.9 + float(k) * 2.6
		_caminante([Vector3(-4.6, 0, z4), Vector3(4.4, 0, z4), Vector3(4.4, 0, z4 + 1.2), Vector3(-4.6, 0, z4 + 1.2)], _calle())

## Oficinas y Ayuntamiento (16 × 12 m): mostrador de atención con sus puestos,
## sillas para el público, mesa de reuniones (oficina) o banderas (ayuntamiento).
func _oficina() -> void:
	var ayto := clave.begins_with("ciudad_ayuntamiento")
	_tonos_sala = _MADERA_CLARA if not ayto else _MADERA_OSCURA
	if ayto:
		_sala(Vector3(16, 3.6, 12), Color(0.75, 0.7, 0.62), Color(0.92, 0.89, 0.82), "losa", Color(0.52, 0.38, 0.26))
	else:
		_sala(Vector3(16, 3.2, 12), Color(0.44, 0.47, 0.53), Color(0.92, 0.92, 0.9), "moqueta")
	## Los cuatro puestos de atención, de cara al público.
	for k in 4:
		var x := -4.5 + float(k) * 3.0
		_puesto(Vector3(x, 0, -3.4), 0.0)
		_asiento("chair", Vector3(x + 0.25, 0, -2.45), PI, [0.0] if _rng.randf() < 0.5 else [], _calle(), null, {"wood": Color(0.25, 0.27, 0.32)})
	## La cola de vecinos esperando turno.
	for k in 3:
		_trabajador(Vector3(1.6 + float(k) * 0.1, 0, -0.9 + float(k) * 0.8), PI, false, ["charla", "brazos_jarra", "cruzar_brazos"], _calle())
	## Archivo al fondo.
	for k in 4:
		_poner("bookcaseClosedWide", Vector3(-7.0 + float(k) * 1.62, 0, -5.75), 0.0, null, {"wood": Color(0.7, 0.72, 0.74)})
	_poner("cardboardBoxClosed", Vector3(-0.2, 0, -5.6), 0.3)
	_poner("cardboardBoxClosed", Vector3(0.25, 0, -5.65), -0.2)
	if ayto:
		for k in 3:
			var bandera := Mini3D.caja(_raiz, Vector3(3.0 + float(k) * 1.1, 2.3, -5.92), Vector3(0.9, 1.3, 0.03), Mini3D.mat([Color(0.8, 0.1, 0.1), Color(0.95, 0.8, 0.1), _c1][k], 0.6))
			bandera.rotation.z = 0.04
			Mini3D.cilindro(_raiz, Vector3(3.0 + float(k) * 1.1 - 0.47, 1.6, -5.85), 0.02, 3.0, Mini3D.mat(Color(0.8, 0.65, 0.3), 0.3))
		_cartel("🏛️ ATENCIÓN AL VECINO", Vector3(-3.0, 2.85, -5.95), 36)
		## Folletos y la máquina de turnos.
		_poner("mini_arcade/ticket-machine", Vector3(-3.6, 0, 5.0), PI)
	else:
		_cartel("💼 " + _sala_nombre().to_upper(), Vector3(4.2, 2.55, -5.95), 32)
		_mesa_con_sillas(Vector3(4.6, 0, 1.6), 0.0, "table", 2.2, 2, "chairModernCushion", 0.5, _calle(), "", ["laptop", "books", "comida/cup-coffee"])
		_pantalla(Vector3(7.96, 1.7, 1.6), Vector2(1.5, 0.85), Color(0.3, 0.5, 0.75), -PI * 0.5)
	## Dos puestos más contra la pared izquierda.
	for z: float in [-0.4, 1.8]:
		_puesto(Vector3(-7.5, 0, z), -PI * 0.5, true, true, [], "desk")
	## Zona de espera a la derecha (ayuntamiento) o al fondo.
	for k in 4:
		var z := -1.2 + float(k) * 0.62
		if ayto or k < 2:
			_asiento("chairCushion", Vector3(7.45, 0, z - (0.0 if ayto else 2.0)), -PI * 0.5, [0.0] if _rng.randf() < 0.45 else [], _calle())
	_poner("mini_arcade/vending-machine", Vector3(7.3, 0, 4.9), -PI * 0.5, 2.2)
	_planta(Vector3(-7.4, 0, 5.4))
	_planta(Vector3(7.4, 0, -5.4))
	_planta(Vector3(-7.4, 0, -5.4))
	_poner("trashcan", Vector3(3.2, 0, 5.6), 0.0, 1.4)
	_ventana(-1.0, 4.0)
	_caminante([Vector3(-5.2, 0, 3.6), Vector3(5.6, 0, 3.6), Vector3(5.6, 0, -1.4), Vector3(-5.2, 0, -1.4)])

## Tiendas (16 × 12 m): la del club con su ropa; las demás (centro comercial,
## gasolinera, farmacia...) con góndolas, neveras y caja del mini mercado.
func _tienda() -> void:
	_sala(Vector3(14, 3.4, 10), Color(0.88, 0.87, 0.85), Color(0.96, 0.96, 0.95), "losa")
	if clave == "com":
		_tienda_club()
	else:
		_tienda_calle()
	_planta(Vector3(-6.4, 0, 4.4))
	_planta(Vector3(6.4, 0, 4.4))
	_cartel("🛍️ " + _sala_nombre().to_upper(), Vector3(0, 2.95, -4.95), 36, Color(1.0, 0.9, 0.6) if clave == "com" else Color.WHITE)

func _tienda_club() -> void:
	_tonos_sala = _MADERA_OSCURA
	## Pared del fondo y laterales con camisetas del club colgadas.
	for x: float in [-4.65, -1.55, 1.55, 4.65]:
		_perchero(Vector3(x, 0, -4.65), 0.0, 2.8, _c1, _c2)
	for z: float in [-2.0, 0.9]:
		_perchero(Vector3(-6.6, 0, z), PI * 0.5, 2.6, _c2, _c1)
	_perchero(Vector3(6.6, 0, -2.0), -PI * 0.5, 2.6, _c1, _c2)
	## Alfombra con los colores del club en el centro.
	Mini3D.caja(_raiz, Vector3(0, 0.006, 1.0), Vector3(4.0, 0.012, 2.4), Mini3D.mat(_c1.darkened(0.15), 0.95))
	Mini3D.caja(_raiz, Vector3(0, 0.008, 1.0), Vector3(3.6, 0.012, 2.0), Mini3D.mat(_c2, 0.95))
	Mini3D.caja(_raiz, Vector3(0, 0.01, 1.0), Vector3(3.3, 0.012, 1.7), Mini3D.mat(_c1, 0.95))
	## Mesas con camisetas plegadas en montones.
	for x: float in [-3.6, 0.0, 3.6]:
		var p := Vector3(x, 0, -1.5)
		_poner("table", p, 0.0, 2.2)
		var alto_m := _alto("table", 2.2)
		for i in 4:
			for pila in _rng.randi_range(2, 4):
				_camiseta(p + Vector3(-0.66 + float(i) * 0.44, alto_m + float(pila) * 0.06, _rng.randf_range(-0.1, 0.1)), _rng.randf_range(-0.1, 0.1), _c1 if (i + pila) % 3 != 2 else _c2, _c2 if (i + pila) % 3 != 2 else _c1, true)
	## Balones y bufandas en un expositor.
	## Expositor de balones y bufandas junto a la pared.
	for k in 3:
		_poner("bookcaseOpenLow", Vector3(-6.72, 0, 2.6 + float(k) * 0.82), PI * 0.5)
		for b in 2:
			Mini3D.esfera(_raiz, Vector3(-6.72, 0.88, 2.4 + float(k) * 0.82 + float(b) * 0.4), 0.11, Mini3D.mat(Color.WHITE if (k + b) % 2 == 0 else _c1, 0.5))
			Mini3D.caja(_raiz, Vector3(-6.72, 0.44, 2.4 + float(k) * 0.82 + float(b) * 0.4), Vector3(0.3, 0.06, 0.3), Mini3D.mat(_c2 if b == 0 else _c1, 0.9))
	## Caja con el dependiente con los colores del club.
	_caja_cobro(Vector3(4.8, 0, 2.6), PI * 0.5, [_c1, _c2, true], true)
	_trabajador(Vector3(-5.6, 0, -0.5), PI * 0.5, false, ["charla", "senalar_cielo"], [_c1, _c2, true])
	_trabajador(Vector3(1.9, 0, -0.4), PI * 0.8, false, ["charla"], _calle())
	for k in 3:
		var z := 0.5 + float(k) * 0.9
		_caminante([Vector3(-5.2, 0, z + 1.3), Vector3(2.4, 0, z + 1.3), Vector3(2.4, 0, -0.5), Vector3(-5.2, 0, -0.5)], _calle())

func _tienda_calle() -> void:
	var neutro := {"*": Color(0.95, 0.93, 0.9)}
	## Dos pasillos de góndolas con cabeceras.
	for z: float in [-2.9, 0.0]:
		for k in 3:
			_poner("mini_mercado/shelf-boxes" if k != 1 else "mini_mercado/shelf-bags", Vector3(-5.0 + float(k) * _medida("mini_mercado/shelf-boxes").x, 0, z), 0.0, null, neutro)
		_poner("mini_mercado/shelf-end", Vector3(-5.0 + 2.5 * _medida("mini_mercado/shelf-boxes").x + _medida("mini_mercado/shelf-end").z * 0.5, 0, z), -PI * 0.5, null, neutro)
	## Neveras contra la pared derecha, congelador y la caja.
	for z: float in [-3.7, -1.3]:
		_poner("mini_mercado/freezers-standing", Vector3(6.5, 0, z), -PI * 0.5, null, neutro)
	_poner("mini_mercado/freezer", Vector3(2.6, 0, -3.9), 0.0, null, neutro)
	_poner("mini_mercado/display-fruit", Vector3(2.6, 0, -1.6), 0.0, null, neutro)
	_caja_cobro(Vector3(4.6, 0, 2.6), PI * 0.5, [Color(0.2, 0.5, 0.8), Color(0.2, 0.22, 0.3), true], false, neutro)
	_poner("mini_mercado/shopping-cart", Vector3(-3.0, 0, 4.0), 0.3, null, neutro)
	_poner("mini_mercado/shopping-cart", Vector3(-3.5, 0, 4.1), 0.2, null, neutro)
	for k in 3:
		_poner("mini_mercado/shopping-basket", Vector3(2.6 + float(k) * 0.05, float(k) * 0.12, 4.3), 0.1 * float(k), null, neutro)
	_poner("mini_arcade/vending-machine", Vector3(-6.3, 0, 2.6), PI * 0.5, 2.2)
	_trabajador(Vector3(-2.0, 0, -1.45), PI * 0.5, false, ["charla", "brazos_jarra"], _calle())
	for k in 3:
		_caminante([Vector3(-5.6, 0, 1.4 + float(k) * 0.4), Vector3(1.4, 0, 1.4 + float(k) * 0.4), Vector3(1.4, 0, -1.45), Vector3(-5.6, 0, -1.45)], _calle())

## Mercado de abastos (22 × 16 m) y supermercado (18 × 14 m).
func _mercado() -> void:
	if clave.begins_with("edificio_mercado"):
		_supermercado()
		return
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(22, 5.0, 16), Color(0.6, 0.57, 0.52), Color(0.88, 0.82, 0.72), "losa", Color(0.45, 0.55, 0.5))
	var puestos := [
		["🍎 FRUTAS", Color(0.95, 0.5, 0.1), ["apple", "orange", "pear", "lemon", "banana", "grapes"], ["pineapple", "watermelon"]],
		["🥬 VERDURAS", Color(0.3, 0.65, 0.2), ["tomato", "carrot", "eggplant", "corn", "broccoli", "cabbage"], ["pumpkin"]],
		["🐟 PESCADOS", Color(0.2, 0.45, 0.8), ["fish", "fish", "fish"], ["fish"]],
		["🥩 CARNES", Color(0.85, 0.15, 0.12), ["meat-raw", "whole-ham", "meat-raw"], ["whole-ham"]],
		["🧀 QUESOS", Color(0.95, 0.8, 0.2), ["cheese", "cheese"], ["cheese"]],
		["🥖 PAN", Color(0.7, 0.45, 0.25), ["loaf", "loaf-baguette", "croissant", "loaf-round"], ["cake"]],
	]
	var sitios := [Vector3(-7.5, 0, -4.6), Vector3(0, 0, -4.6), Vector3(7.5, 0, -4.6), Vector3(-6.5, 0, 1.4), Vector3(6.5, 0, 1.4), Vector3(0, 0, 1.0)]
	for k in puestos.size():
		_puesto_mercado(sitios[k], puestos[k])
	for k in 4:
		var z := -2.2 + float(k) * 0.5
		_caminante([Vector3(-9.5, 0, z), Vector3(9.5, 0, z)], _calle())
	_caminante([Vector3(-3.0, 0, 4.0), Vector3(-3.0, 0, -1.5), Vector3(3.0, 0, -1.5), Vector3(3.0, 0, 4.0)], _calle())
	_cartel("🍊 MERCADO DE ABASTOS", Vector3(0, 4.3, -7.95), 48)

## Un puesto del mercado: mostrador de 2,6 m con cajas de género, toldo de
## rayas, rótulo y el tendero detrás (mirando a +Z).
func _puesto_mercado(p: Vector3, datos: Array) -> void:
	var col: Color = datos[1]
	for k in 3:
		_poner("kitchenCabinet", p + Vector3(-0.86 + float(k) * 0.86, 0, 0), 0.0, null, {"wood": Color(0.6, 0.42, 0.26)})
	var largo := 2.58
	var tope := _alto("kitchenCabinet")
	## Cajas de madera inclinadas con el género.
	var caja_m := Mini3D.mat(Color(0.62, 0.45, 0.28), 0.8)
	var genero: Array = datos[2]
	for i in 4:
		var c := p + Vector3(-0.96 + float(i) * 0.64, tope, 0.05)
		Mini3D.caja(_raiz, c + Vector3(0, 0.05, 0), Vector3(0.58, 0.1, 0.5), caja_m)
		var cosa := "comida/" + String(genero[i % genero.size()])
		var m := _medida(cosa)
		var nx := clampi(int(0.5 / maxf(m.x, 0.06)), 1, 5)
		var nz := clampi(int(0.42 / maxf(m.z, 0.06)), 1, 4)
		for a in nx:
			for b in nz:
				_poner(cosa, c + Vector3((float(a) + 0.5) / float(nx) * 0.5 - 0.25, 0.1, (float(b) + 0.5) / float(nz) * 0.42 - 0.21), _rng.randf_range(-0.4, 0.4))
	## Una caja grande en el suelo, delante, con la pieza gorda (sandías, piñas...).
	for cosa: String in datos[3]:
		var cx := _rng.randf_range(-0.8, 0.8)
		Mini3D.caja(_raiz, p + Vector3(cx, 0.15, 0.75), Vector3(0.6, 0.3, 0.45), caja_m)
		for q in 2:
			_poner("comida/" + cosa, p + Vector3(cx - 0.14 + float(q) * 0.28, 0.3, 0.75), _rng.randf() * TAU)
	_poner("mini_mercado/cash-register", p + Vector3(largo * 0.5 + 0.55, 0, -0.2), -PI * 0.5, 1.2)
	## Postes, toldo a rayas y rótulo.
	var poste := Mini3D.mat(Color(0.3, 0.3, 0.32), 0.4)
	for s: float in [-1.0, 1.0]:
		Mini3D.cilindro(_raiz, p + Vector3(s * 1.45, 1.25, -0.9), 0.04, 2.5, poste)
	for r in 6:
		var toldo := Mini3D.caja(_raiz, p + Vector3(-1.25 + float(r) * 0.5, 2.45, -0.35), Vector3(0.5, 0.04, 1.3), Mini3D.mat(col if r % 2 == 0 else Color(0.97, 0.95, 0.9), 0.8))
		toldo.rotation.x = 0.2
	Mini3D.caja(_raiz, p + Vector3(0, 2.75, -0.9), Vector3(2.4, 0.45, 0.06), Mini3D.mat(col.darkened(0.2), 0.7))
	_cartel(String(datos[0]), p + Vector3(0, 2.75, -0.85), 30)
	_trabajador(p + Vector3(_rng.randf_range(-0.6, 0.6), 0, -0.75), 0.0, false, ["saludo_mano", "charla", "aplaudir"], [Color.WHITE, col.darkened(0.3), true])

func _supermercado() -> void:
	_sala(Vector3(18, 3.8, 14), Color(0.86, 0.86, 0.84), Color(0.95, 0.95, 0.94), "losa", Color(0.2, 0.55, 0.35))
	var neutro := {"*": Color(0.95, 0.93, 0.9)}
	for z: float in [-4.6, -1.6, 1.2]:
		for k in 3:
			_poner("mini_mercado/shelf-boxes" if (k + int(z)) % 2 == 0 else "mini_mercado/shelf-bags", Vector3(-6.9 + float(k) * _medida("mini_mercado/shelf-boxes").x, 0, z), 0.0, null, neutro)
		_poner("mini_mercado/shelf-end", Vector3(-6.9 + 2.5 * _medida("mini_mercado/shelf-boxes").x + _medida("mini_mercado/shelf-end").z * 0.5, 0, z), -PI * 0.5, null, neutro)
	for z: float in [-5.6, -3.0, -0.4]:
		_poner("mini_mercado/freezers-standing", Vector3(8.5, 0, z), -PI * 0.5, null, neutro)
	for x: float in [1.4, 3.6]:
		_poner("mini_mercado/display-fruit", Vector3(x, 0, -3.2), 0.0, null, neutro)
	_poner("mini_mercado/display-bread", Vector3(1.4, 0, -5.4), 0.0, null, neutro)
	_poner("mini_mercado/freezer", Vector3(3.8, 0, -5.4), 0.0, null, neutro)
	_poner("mini_mercado/bottle-return", Vector3(-8.5, 0, 5.5), PI * 0.5, 1.6, neutro)
	## Dos cajas con su cajero sentado y la cola.
	for x: float in [3.2, 6.4]:
		_caja_cobro(Vector3(x, 0, 2.8), PI, [Color(0.85, 0.2, 0.15), Color(0.2, 0.22, 0.3), true], true, neutro)
	for k in 4:
		_poner("mini_mercado/shopping-cart", Vector3(-6.2 - float(k) * 0.12, 0, 5.4), 0.0, null, neutro)
	for k in 3:
		_caminante([Vector3(-8.0, 0, 3.0 - float(k) * 3.0), Vector3(0.4, 0, 3.0 - float(k) * 3.0), Vector3(0.4, 0, -0.1 - float(k) * 3.0), Vector3(-8.0, 0, -0.1 - float(k) * 3.0)], _calle())
	_planta(Vector3(8.4, 0, 6.4))
	_cartel("🛒 " + _sala_nombre().to_upper(), Vector3(0, 3.25, -6.95), 40)

## Panadería (10 × 8 m): vitrina con bollería, estantes de pan, el horno, los
## panaderos, la cola y una mesita para el café.
func _panaderia() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(10, 3.2, 8), Color(0.88, 0.8, 0.68), Color(0.98, 0.93, 0.82), "losa", Color(0.72, 0.5, 0.32))
	## El mostrador con la vitrina de cristal encima.
	var fin := _cocina(-3.6, -1.1, ["kitchenCabinet", "kitchenCabinetDrawer", "kitchenCabinet", "kitchenCabinetDrawer", "kitchenCabinet", "kitchenCabinet"], PI, false)
	var tope := _alto("kitchenCabinet")
	var largo := fin + 3.6
	var xc := (fin - 3.6) * 0.5
	Mini3D.caja(_raiz, Vector3(xc - 0.43, tope + 0.25, -1.1), Vector3(largo - 0.86, 0.5, 0.7), Mini3D.mat(Color(0.85, 0.93, 1.0, 0.22), 0.05))
	Mini3D.caja(_raiz, Vector3(xc - 0.43, tope + 0.505, -1.1), Vector3(largo - 0.86, 0.02, 0.72), Mini3D.mat(Color(0.95, 0.95, 0.93), 0.4))
	var dulces := ["croissant", "muffin", "donut-sprinkles", "cupcake", "croissant", "donut-sprinkles"]
	var x := -3.45
	while x < fin - 1.0:
		_poner("comida/plate-dinner" if _rng.randf() < 0.3 else "comida/plate", Vector3(x + 0.14, tope + 0.01, -1.1), 0.0)
		_poner("comida/" + String(dulces[_rng.randi() % dulces.size()]), Vector3(x + 0.14, tope + 0.04, -1.1), _rng.randf() * TAU)
		x += 0.34
	_poner("mini_arcade/cash-register", Vector3(fin - 0.43, tope, -1.15), PI, 0.55)
	## Estantes de pan contra la pared y el horno.
	var madera := Mini3D.mat(Color(0.6, 0.42, 0.26), 0.7)
	for y: float in [0.9, 1.35, 1.8]:
		Mini3D.caja(_raiz, Vector3(-2.2, y, -3.78), Vector3(5.4, 0.05, 0.42), madera)
		var xp := -4.75
		while xp < 0.3:
			var pan: String = ["loaf", "loaf-round", "loaf-baguette", "loaf"][_rng.randi() % 4]
			_poner("comida/" + pan, Vector3(xp + 0.2, y + 0.025, -3.78), _rng.randf_range(-0.2, 0.2) + (PI * 0.5 if pan == "loaf-baguette" else 0.0))
			xp += 0.42
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(-2.2 + s * 2.72, 1.0, -3.78), Vector3(0.05, 2.0, 0.42), madera)
	var horno := Mini3D.mat(Color(0.25, 0.25, 0.27), 0.35)
	horno.metallic = 0.6
	Mini3D.caja(_raiz, Vector3(3.2, 0.95, -3.45), Vector3(1.8, 1.9, 1.0), horno)
	for y: float in [0.65, 1.35]:
		Mini3D.caja(_raiz, Vector3(3.2, y, -2.94), Vector3(1.4, 0.45, 0.02), Mini3D.mat(Color(1.0, 0.55, 0.2), 0.3, 1.6))
	_trabajador(Vector3(-2.0, 0, -2.2), 0.0, false, ["charla", "brazos_jarra"], [Color.WHITE, Color(0.3, 0.3, 0.3), true])
	_trabajador(Vector3(0.9, 0, -2.2), 0.0, false, ["saludo_mano", "charla"], [Color.WHITE, Color(0.3, 0.3, 0.3), true])
	## La cola de clientes.
	for k in 3:
		_trabajador(Vector3(-2.6 + float(k) * 1.3, 0, 0.05 + float(k % 2) * 0.25), PI, false, ["charla"], _calle())
	## Mesita del café junto a la ventana.
	_poner("table", Vector3(3.6, 0, 1.6), 0.0, Vector3(1.2, 2.2, 1.5))
	_asiento("chair", Vector3(3.6, 0, 2.27), PI, [0.0], _calle())
	_asiento("chair", Vector3(3.6, 0, 0.93), 0.0, [])
	_poner("comida/cup-coffee", Vector3(3.55, _alto("table", 2.2), 1.85), 0.5)
	_poner("comida/croissant", Vector3(3.7, _alto("table", 2.2), 1.5), 1.2)
	_ventana(1.0, 1.6, 1.4)
	## Mesa de cestas con barras y hogazas.
	_poner("table", Vector3(-4.2, 0, 1.2), PI * 0.5, Vector3(1.6, 2.0, 1.6))
	var cesta := Mini3D.mat(Color(0.62, 0.45, 0.25), 0.9)
	for k in 2:
		var c := Vector3(-4.2, _alto("table", 2.0), 0.85 + float(k) * 0.7)
		Mini3D.caja(_raiz, c + Vector3(0, 0.06, 0), Vector3(0.5, 0.12, 0.55), cesta)
		for q in 3:
			_poner("comida/loaf-baguette" if k == 0 else "comida/loaf-round", c + Vector3(-0.15 + float(q) * 0.15, 0.08, 0), PI * 0.5 + _rng.randf_range(-0.2, 0.2))
	_planta(Vector3(-4.5, 0, 3.4))
	_cartel("🥖 " + _sala_nombre().to_upper(), Vector3(-2.2, 2.65, -3.95), 30)

## Peluquería (11 × 8 m): tres sillones frente a los espejos, el sofá de espera
## y la recepción.
func _peluqueria() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(11, 3.2, 8), Color(0.92, 0.9, 0.92), Color(0.8, 0.88, 0.92), "losa")
	var cuero := {"carpet": Color(0.12, 0.12, 0.14), "metalMedium": Color(0.75, 0.76, 0.78)}
	for k in 3:
		var x := -3.4 + float(k) * 3.4
		Mini3D.caja(_raiz, Vector3(x, 1.6, -3.97), Vector3(1.1, 1.3, 0.03), Mini3D.mat(Color(0.5, 0.58, 0.64), 0.05, 0.05))
		Mini3D.caja(_raiz, Vector3(x, 1.6, -3.985), Vector3(1.2, 1.4, 0.02), Mini3D.mat(Color(0.2, 0.2, 0.22), 0.4))
		_poner("sideTable", Vector3(x, 0, -3.78))
		_poner("comida/soda-bottle", Vector3(x - 0.3, _alto("sideTable"), -3.8), 0.0, 0.3)
		_poner("comida/glass", Vector3(x + 0.3, _alto("sideTable"), -3.8))
		_asiento("chairDesk", Vector3(x, 0, -2.5), PI, [0.0], _calle(), null, cuero)
		_trabajador(Vector3(x + 0.15, 0, -1.6), PI, false, ["charla", "brazos_jarra"], [Color(0.1, 0.1, 0.12), Color(0.1, 0.1, 0.12), true])
		_poner("lampWall", Vector3(x, 2.35, -3.9), 0.0)
	## Espera: sofá, mesa con revistas y planta.
	_asiento("loungeSofa", Vector3(-5.5 + 0.42, 0, 2.0), PI * 0.5, [-0.4, 0.45], _calle(), null, {"carpet": Color(0.55, 0.22, 0.3)})
	_poner("tableCoffeeGlass", Vector3(-3.9, 0, 2.0), PI * 0.5)
	_poner("books", Vector3(-3.9, _alto("tableCoffeeGlass"), 2.0), 0.7, 1.6)
	_poner("coatRackStanding", Vector3(-5.0, 0, 3.5))
	## Recepción.
	_poner("desk", Vector3(4.1, 0, 2.2), -PI * 0.5)
	_poner("mini_arcade/cash-register", Vector3(4.0, _alto("desk"), 2.4), -PI * 0.5, 0.6)
	_trabajador(Vector3(4.85, 0, 2.2), -PI * 0.5, false, ["saludo_mano", "charla"], [Color(0.1, 0.1, 0.12), Color(0.1, 0.1, 0.12), true])
	_planta(Vector3(5.0, 0, 3.5))
	_planta(Vector3(5.0, 0, -0.6), false)
	_poner("lampSquareFloor", Vector3(-5.1, 0, 0.6))
	_ventana(-1.0, -1.2, 1.4)
	_cartel("✂️ " + _sala_nombre().to_upper(), Vector3(0, 2.75, -3.95), 30)

## Librería (12 × 9 m): estanterías llenas, mesas de novedades, rincón de
## lectura y el mostrador.
func _libreria() -> void:
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(12, 3.4, 9), Color(0.6, 0.44, 0.3), Color(0.88, 0.83, 0.72), "parquet")
	## Estanterías en el fondo y en la pared izquierda, con libros.
	for k in 7:
		var x := -5.2 + float(k) * 1.62
		if x > 5.0:
			break
		_poner("bookcaseClosedWide", Vector3(x, 0, -4.25), 0.0)
		for b in 3:
			for q in 3:
				_poner("books", Vector3(x - 0.5 + float(q) * 0.5, 0.06 + float(b) * 0.52, -4.25), _rng.randf_range(-0.1, 0.1), 2.0)
	for z: float in [-2.6, -1.0, 0.6]:
		_poner("bookcaseClosedWide", Vector3(-5.75, 0, z), PI * 0.5)
		for b in 3:
			_poner("books", Vector3(-5.75, 0.06 + float(b) * 0.52, z + _rng.randf_range(-0.4, 0.4)), PI * 0.5, 2.0)
	## Mesas de novedades.
	for p: Vector3 in [Vector3(-2.4, 0, -1.6), Vector3(1.0, 0, -1.6)]:
		_poner("table", p, 0.0, 2.0)
		for k in 8:
			_poner("books", p + Vector3(-0.6 + float(k % 4) * 0.4, _alto("table", 2.0), -0.2 + float(k / 4) * 0.4), _rng.randf_range(-0.3, 0.3), 2.0)
	## Rincón de lectura.
	_poner("rugRound", Vector3(4.0, 0, -1.4), 0.0, 2.0, {"carpet": Color(0.55, 0.35, 0.3), "carpetDarker": Color(0.45, 0.28, 0.24)})
	_asiento("loungeChair", Vector3(3.4, 0, -2.2), 0.6, [0.0], _calle(), null, {"carpet": Color(0.35, 0.45, 0.32)})
	_asiento("loungeChair", Vector3(4.9, 0, -1.6), -0.9, [], [], null, {"carpet": Color(0.35, 0.45, 0.32)})
	_poner("sideTable", Vector3(4.6, 0, -2.9), 0.0, 1.2)
	_poner("lampRoundFloor", Vector3(5.4, 0, -3.2))
	## Mostrador.
	_poner("desk", Vector3(4.3, 0, 2.4), -PI * 0.5)
	_poner("mini_arcade/cash-register", Vector3(4.2, _alto("desk"), 2.6), -PI * 0.5, 0.6)
	_trabajador(Vector3(5.05, 0, 2.4), -PI * 0.5, false, ["saludo_mano", "charla"], [Color(0.4, 0.25, 0.2), Color(0.2, 0.2, 0.25)])
	_planta(Vector3(5.4, 0, 4.0))
	_planta(Vector3(-5.4, 0, 3.9))
	_ventana(1.0, 0.6, 1.4)
	_caminante([Vector3(-4.6, 0, -3.3), Vector3(2.4, 0, -3.3), Vector3(2.4, 0, -0.4), Vector3(-4.6, 0, -0.4)], _calle())
	_caminante([Vector3(-4.6, 0, 1.6), Vector3(2.6, 0, 1.6)], _calle())
	_cartel("📚 " + _sala_nombre().to_upper(), Vector3(0, 2.95, -4.45), 30)

## Taller (16 × 12 m, 5 m de alto): coche en el elevador, otro en el suelo,
## banco de trabajo, neumáticos, bidones y la oficina del jefe.
func _taller() -> void:
	_tonos_sala = {"wood": Color(0.55, 0.57, 0.6), "woodDark": Color(0.4, 0.42, 0.45)}
	_sala(Vector3(16, 5.0, 12), Color(0.45, 0.45, 0.47), Color(0.75, 0.77, 0.79), "hormigon", Color(0.25, 0.38, 0.6))
	## El elevador con un coche del kit a 1,6 m.
	var gris := Mini3D.mat(Color(0.35, 0.36, 0.38), 0.4)
	var amarillo := Mini3D.mat(Color(0.92, 0.75, 0.1), 0.5)
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(-3.5 + s * 1.5, 1.3, -1.5), Vector3(0.3, 2.6, 0.3), amarillo)
		Mini3D.caja(_raiz, Vector3(-3.5 + s * 0.8, 1.52, -1.5), Vector3(1.4, 0.08, 0.2), gris)
	var coche := "coches/sedan"
	var m := _medida(coche, 1.0)
	var esc := 4.4 / maxf(m.x, m.z)
	_poner(coche, Vector3(-3.5, 1.6, -1.5), 0.0 if m.z >= m.x else PI * 0.5, esc)
	var otro := "coches/suv"
	var m2 := _medida(otro, 1.0)
	_poner(otro, Vector3(3.6, 0, -0.6), (0.0 if m2.z >= m2.x else PI * 0.5) + 0.25, 4.6 / maxf(m2.x, m2.z))
	## Banco de trabajo, panel de herramientas y cajas.
	_cocina(-1.2, -6.0 + 0.45, ["kitchenCabinetDrawer", "kitchenCabinetDrawer", "kitchenCabinet", "kitchenCabinetDrawer", "kitchenCabinet"], 0.0, false)
	Mini3D.caja(_raiz, Vector3(1.0, 1.9, -5.97), Vector3(4.3, 1.4, 0.04), Mini3D.mat(Color(0.5, 0.52, 0.55), 0.5))
	for k in 14:
		Mini3D.caja(_raiz, Vector3(-0.9 + float(k) * 0.3, 1.9 + _rng.randf_range(-0.3, 0.3), -5.93), Vector3(0.05, _rng.randf_range(0.25, 0.5), 0.03), Mini3D.mat(Color(0.12, 0.12, 0.14) if k % 3 else Color(0.8, 0.15, 0.1), 0.3))
	_poner("cardboardBoxClosed", Vector3(5.2, 0, -5.5), 0.2)
	_poner("cardboardBoxClosed", Vector3(5.7, 0, -5.4), -0.3)
	_poner("cardboardBoxClosed", Vector3(5.45, _alto("cardboardBoxClosed"), -5.45), 0.5)
	## Neumáticos apilados y bidones.
	var goma := Mini3D.mat(Color(0.07, 0.07, 0.08), 0.85)
	for k in 5:
		var rueda := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.18
		tm.outer_radius = 0.34
		rueda.mesh = tm
		rueda.material_override = goma
		rueda.position = Vector3(-7.3, 0.08 + float(k) * 0.17, -5.3)
		rueda.scale = Vector3(1, 1.4, 1)
		_raiz.add_child(rueda)
	for k in 3:
		Mini3D.cilindro(_raiz, Vector3(7.4, 0.45, -3.0 + float(k) * 0.65), 0.29, 0.9, Mini3D.mat([Color(0.75, 0.15, 0.1), Color(0.15, 0.3, 0.6), Color(0.2, 0.45, 0.2)][k], 0.5))
	## La oficina del jefe, junto a la entrada.
	_puesto(Vector3(-6.5, 0, 3.6), PI * 0.5, true, true, [Color(0.15, 0.3, 0.6), Color(0.15, 0.3, 0.6), true])
	_poner("bookcaseClosedDoors", Vector3(-7.75, 0, 1.8), PI * 0.5, null, {"wood": Color(0.65, 0.67, 0.7)})
	_poner("washerDryerStacked", Vector3(7.5, 0, 3.2), -PI * 0.5)
	_trabajador(Vector3(-2.0, 0, -0.2), PI * 0.75, false, ["charla", "brazos_jarra"], [Color(0.15, 0.3, 0.6), Color(0.15, 0.3, 0.6), true])
	_trabajador(Vector3(0.9, 0, -4.9), 0.0, false, ["charla", "pedir_calma"], [Color(0.15, 0.3, 0.6), Color(0.15, 0.3, 0.6), true])
	_caminante([Vector3(-0.8, 0, 2.6), Vector3(6.4, 0, 2.6), Vector3(6.4, 0, -3.6), Vector3(-0.8, 0, -3.6)], [Color(0.15, 0.3, 0.6), Color(0.15, 0.3, 0.6), true])
	## Franjas amarillas en el suelo del elevador.
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(-3.5 + s * 2.0, 0.005, -1.5), Vector3(0.12, 0.01, 5.0), amarillo)
	_cartel("🔧 " + _sala_nombre().to_upper(), Vector3(-3.5, 4.2, -5.95), 40)

## Hospital y centros médicos (22 × 14 m): camas con su mesilla y su monitor,
## cortinas entre camas, recepción con enfermeras y sala de espera.
func _hospital() -> void:
	_sala(Vector3(18, 3.6, 12), Color(0.8, 0.86, 0.86), Color(0.93, 0.97, 0.97), "losa", Color(0.55, 0.76, 0.78))
	var cama := {"carpet": Color(0.55, 0.75, 0.9), "wood": Color(0.86, 0.88, 0.9)}
	var largo_cama := _medida("bedSingle").z
	for k in 5:
		var x := -6.4 + float(k) * 3.2
		var zc := -6.0 + largo_cama * 0.5 + 0.1
		_poner("bedSingle", Vector3(x, 0, zc), 0.0, null, cama)
		_poner("cabinetBedDrawerTable", Vector3(x + 0.95, 0, -5.55), 0.0, null, {"wood": Color(0.86, 0.88, 0.9)})
		_poner("comida/glass", Vector3(x + 0.95, _alto("cabinetBedDrawerTable"), -5.55))
		## Monitor de constantes.
		var gris := Mini3D.mat(Color(0.7, 0.7, 0.72), 0.3)
		Mini3D.cilindro(_raiz, Vector3(x - 0.9, 0.75, -5.6), 0.03, 1.5, gris)
		Mini3D.caja(_raiz, Vector3(x - 0.9, 1.5, -5.6), Vector3(0.4, 0.3, 0.06), Mini3D.mat(Color(0.1, 0.4, 0.2), 0.3, 1.0))
		## Paciente sentado en el borde de la cama, con los pies colgando.
		if k % 2 == 0:
			var a: Vector2 = _pieza("bedSingle")["asiento"]
			_trabajador(Vector3(x - 0.3, 0, zc + 0.3), -PI * 0.5, true, [], [], a.x * 2.0)
		## Cortina entre camas, con su riel.
		if k < 4:
			Mini3D.caja(_raiz, Vector3(x + 1.6, 1.45, -4.8), Vector3(0.04, 2.3, 2.4), Mini3D.mat(Color(0.6, 0.8, 0.85, 0.85), 0.8))
			Mini3D.caja(_raiz, Vector3(x + 1.6, 2.65, -4.8), Vector3(0.05, 0.05, 2.5), gris)
	## Recepción.
	var esc_barra := 2.5
	var ancho := _medida("kitchenBar", esc_barra).x
	for k in 3:
		_poner("kitchenBar", Vector3(4.4 + float(k) * ancho, 0, 2.2), 0.0, esc_barra, {"wood": Color(0.9, 0.93, 0.94), "woodDark": Color(0.3, 0.55, 0.6)})
	_poner("computerScreen", Vector3(5.5, _alto("kitchenBar", esc_barra), 2.1), PI, 1.5)
	var enfermera := [Color(0.4, 0.7, 0.75), Color(0.4, 0.7, 0.75), true]
	_trabajador(Vector3(4.9, 0, 1.3), 0.0, false, ["charla", "pedir_calma", "saludo_mano"], enfermera)
	_trabajador(Vector3(6.3, 0, 1.3), 0.0, false, ["charla", "senalar_cielo"], enfermera)
	Mini3D.caja(_raiz, Vector3(5.5, 3.1, 2.2), Vector3(2.4, 0.45, 0.06), Mini3D.mat(Color(0.3, 0.55, 0.6), 0.6))
	_cartel("RECEPCIÓN", Vector3(5.5, 3.1, 2.25), 26)
	## Sala de espera: dos filas de sillas.
	for fila in 2:
		for k in 5:
			var p := Vector3(-7.6 + float(k) * 0.62, 0, 1.0 + float(fila) * 1.6)
			_asiento("chairModernCushion", p, 0.0, [0.0] if _rng.randf() < 0.4 else [], _calle(), null, {"carpet": Color(0.3, 0.5, 0.7)})
	_poner("mini_arcade/vending-machine", Vector3(-8.4, 0, 4.4), PI * 0.5, 2.2)
	_poner("trashcan", Vector3(-8.5, 0, 3.3), 0.0, 1.4)
	for p: Vector3 in [Vector3(8.4, 0, 5.4), Vector3(-8.4, 0, -1.2), Vector3(8.4, 0, -1.2)]:
		_planta(p)
	## Médicos de bata que pasan de cama en cama.
	for k in 2:
		var pts: Array = []
		for q in 5:
			pts.append(Vector3(-6.4 + float(q) * 3.2, 0, -2.5 + float(k) * 0.6))
		if k == 1:
			pts.reverse()
		_caminante(pts, [Color(0.96, 0.96, 0.97), Color(0.3, 0.45, 0.7), true])
	_cartel("➕ " + _sala_nombre().to_upper(), Vector3(0, 3.1, -5.95), 40, Color(0.25, 0.6, 0.4))

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

## Estación (24 × 15 m, vestíbulo de 7 m): panel de salidas, taquillas, bancos,
## quiosco, máquinas, el reloj y los viajeros con prisa.
func _estacion() -> void:
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(24, 7.0, 15), Color(0.7, 0.66, 0.6), Color(0.86, 0.8, 0.7), "losa", Color(0.5, 0.4, 0.32))
	Mini3D.caja(_raiz, Vector3(0, 4.3, -7.38), Vector3(8.0, 2.4, 0.2), Mini3D.mat(Color(0.05, 0.05, 0.06), 0.4))
	_cartel("SALIDAS\n10:15  Puerto      vía 2\n10:22  Alto Norte  vía 1\n10:30  Ribera      vía 3", Vector3(0, 4.3, -7.25), 38, Color(1.0, 0.8, 0.2))
	## Taquillas: tres puestos tras un cristal.
	for k in 3:
		var x := -9.6 + float(k) * 2.4
		_puesto(Vector3(x, 0, -6.0), 0.0)
		Mini3D.caja(_raiz, Vector3(x, 1.45, -5.55), Vector3(2.3, 1.3, 0.03), Mini3D.mat(Color(0.8, 0.9, 1.0, 0.25), 0.05))
	Mini3D.caja(_raiz, Vector3(-7.2, 0.38, -5.55), Vector3(7.2, 0.76, 0.1), Mini3D.mat(Color(0.35, 0.25, 0.18), 0.6))
	Mini3D.caja(_raiz, Vector3(-7.2, 2.3, -5.55), Vector3(7.2, 0.5, 0.12), Mini3D.mat(Color(0.2, 0.3, 0.5), 0.6))
	_cartel("BILLETES", Vector3(-7.2, 2.3, -5.48), 32)
	for k in 2:
		_trabajador(Vector3(-8.4 + float(k) * 2.4, 0, -4.6), PI, false, ["charla", "brazos_jarra"], _calle())
	## Bancos de espera, espalda con espalda.
	for x: float in [-5.0, 0.0, 5.0]:
		for s: float in [-1.0, 1.0]:
			for k in 4:
				var p := Vector3(x - 1.2 + float(k) * 0.8, 0, 0.2 + s * 0.24)
				_asiento("bench", p, 0.0 if s > 0.0 else PI, [0.0] if _rng.randf() < 0.35 else [], _calle())
	## Viajeros con maleta mirando el panel.
	var maleta := Mini3D.mat(Color(0.2, 0.25, 0.35), 0.5)
	for k in 3:
		var p := Vector3(-1.6 + float(k) * 1.5, 0, -3.6 + float(k % 2) * 0.5)
		_trabajador(p, PI, false, ["charla", "brazos_jarra", "senalar_cielo"], _calle())
		Mini3D.caja(_raiz, p + Vector3(0.45, 0.32, 0.1), Vector3(0.4, 0.64, 0.22), maleta)
	## Quiosco a la derecha.
	var ancho := _medida("kitchenBar", 2.5).x
	for k in 3:
		_poner("kitchenBar", Vector3(6.2 + float(k) * ancho, 0, -4.8), 0.0, 2.5)
	for k in 10:
		_poner("books", Vector3(5.9 + float(k) * 0.28, _alto("kitchenBar", 2.5), -4.8), _rng.randf_range(-0.2, 0.2), 1.8)
	for x: float in [6.6, 7.4, 8.2]:
		_poner("bookcaseOpen", Vector3(x, 0, -7.25), 0.0)
		for b in 3:
			_poner("books", Vector3(x, 0.42 + float(b) * 0.5, -7.25), 0.0)
	_trabajador(Vector3(7.2, 0, -5.8), 0.0, false, ["saludo_mano", "charla"], _calle())
	for z: float in [-1.8, -0.7]:
		_poner("mini_arcade/vending-machine", Vector3(11.45, 0, z), -PI * 0.5, 2.2)
	_poner("mini_arcade/ticket-machine", Vector3(-11.5, 0, -1.6), PI * 0.5)
	_poner("mini_arcade/ticket-machine", Vector3(-11.5, 0, -0.6), PI * 0.5)
	for p: Vector3 in [Vector3(-11.2, 0, 6.7), Vector3(11.2, 0, 6.7), Vector3(-11.2, 0, -6.9), Vector3(11.2, 0, -6.9)]:
		_planta(p)
	for x: float in [-7.6, 7.6]:
		_poner("trashcan", Vector3(x, 0, 1.6), 0.0, 1.4)
	## El reloj de la estación, con sus agujas.
	var reloj := Mini3D.cilindro(_raiz, Vector3(9.0, 4.6, -7.42), 0.8, 0.1, Mini3D.mat(Color(0.97, 0.97, 0.95), 0.4, 0.3))
	reloj.rotation.x = PI * 0.5
	var aro := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.78
	tm.outer_radius = 0.86
	aro.mesh = tm
	aro.material_override = Mini3D.mat(Color(0.15, 0.15, 0.17), 0.3)
	aro.position = Vector3(9.0, 4.6, -7.4)
	aro.rotation.x = PI * 0.5
	_raiz.add_child(aro)
	var aguja := Mini3D.mat(Color(0.08, 0.08, 0.1), 0.4)
	var h := Mini3D.caja(_raiz, Vector3(9.0, 4.6, -7.35), Vector3(0.06, 0.45, 0.02), aguja)
	h.position += Vector3(sin(-0.6), cos(-0.6), 0) * 0.2
	h.rotation.z = 0.6
	var mn := Mini3D.caja(_raiz, Vector3(9.0, 4.6, -7.34), Vector3(0.04, 0.65, 0.02), aguja)
	mn.position += Vector3(sin(1.6), cos(1.6), 0) * 0.3
	mn.rotation.z = -1.6
	## Viajeros que van y vienen con prisa.
	for k in 5:
		var z := -2.4 + float(k) * 0.7 + (2.4 if k > 2 else 0.0)
		_caminante([Vector3(-10.5, 0, z), Vector3(10.5, 0, z + _rng.randf_range(-0.4, 0.4))], _calle(), k % 3 == 0)
	_cartel("🚉 " + _sala_nombre().to_upper(), Vector3(0, 6.1, -7.4), 60)

## Cine (18 × 18 m): pantalla, gradas con butacas tapizadas y el público.
func _cine() -> void:
	_sala(Vector3(18, 6.0, 18), Color(0.32, 0.08, 0.1), Color(0.28, 0.1, 0.12), "moqueta", Color(0.18, 0.05, 0.07))
	_pantalla(Vector3(0, 3.2, -8.9), Vector2(13.0, 5.0), Color(0.75, 0.85, 1.0))
	_cartel("🎬 ESTRENO", Vector3(0, 3.2, -8.8), 96, Color(0.1, 0.1, 0.2))
	var butaca := Vector3(1.35, 2.0, 2.0)
	var tela := {"carpet": Color(0.65, 0.08, 0.1), "wood": Color(0.25, 0.08, 0.08)}
	var grada := Mini3D.mat(Color(0.22, 0.06, 0.08), 0.9)
	for i in 6:
		var y := float(i) * 0.38
		var z := -2.4 + float(i) * 1.15
		if i > 0:
			Mini3D.caja(_raiz, Vector3(0, y * 0.5, z), Vector3(13.6, y, 1.15), grada)
		for j in 16:
			var p := Vector3(-5.7 + float(j) * 0.76, y, z)
			_asiento("loungeChair", p, PI, [0.0] if _rng.randf() < 0.3 else [], _calle(), butaca, tela)
		## Luces de pasillo en cada escalón.
		for s: float in [-1.0, 1.0]:
			Mini3D.caja(_raiz, Vector3(s * 6.85, y + 0.02, z + 0.5), Vector3(0.1, 0.04, 0.1), Mini3D.mat(Color(1.0, 0.8, 0.4), 0.3, 2.0))
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(s * 8.97, 2.4, 7.4), Vector3(0.05, 0.3, 0.9), Mini3D.mat(Color(0.2, 0.9, 0.3), 0.3, 1.5))
		_cartel("SALIDA", Vector3(s * 8.93, 2.4, 7.4), 20, Color.WHITE, -s * PI * 0.5)
	_caminante([Vector3(-7.6, 0, 7.5), Vector3(-7.6, 0, -5.5), Vector3(7.6, 0, -5.5), Vector3(7.6, 0, 7.5)])

## Gimnasio y recuperación (16 × 12 m, 16-10-2026: «que parezca el gimnasio de
## un club de verdad y lleno de vida»). Zonas sobre suelo de goma: cardio al
## fondo (cintas y bicis ante el espejo, teles con datos), pista de césped con
## escalera de agilidad y conos, zona de fuerza a la derecha (poleas, rack de
## mancuernas, bancos, jaula de sentadillas, kettlebells), zona funcional en el
## centro (cajones, balones medicinales, fitballs), estiramientos y camilla del
## fisio a la izquierda, y delante el banco de vestuario y la mesa del
## preparador con la pantalla de GPS. Casi todo el equipo va en lotes
## (`_prim`, `_poner`): cientos de piezas a pocas llamadas de dibujo.
func _gimnasio() -> void:
	_tonos_sala = _MADERA_CLARA
	var goma := Color(0.17, 0.17, 0.19)
	_sala(Vector3(16, 4.2, 12), goma, Color(0.88, 0.88, 0.9), "moqueta", _c1.darkened(0.55))
	var dep := [_c1, _c2]
	var hierro := Color(0.12, 0.12, 0.13)
	var cromo := Color(0.78, 0.79, 0.82)
	var acero := Color(0.42, 0.44, 0.47)
	var blanco := Color(0.94, 0.94, 0.95)
	## --- Suelo por zonas: losetas de cardio, pista de césped, damero de
	## fuerza y la zona funcional con su borde del color del club.
	_prim("caja", Vector3(-2.2, 0.005, -4.7), Vector3(11.2, 0.01, 2.6), Color(0.22, 0.24, 0.29))
	for i in 11:
		_prim("caja", Vector3(-7.8 + float(i) * 1.12, 0.012, -4.7), Vector3(0.02, 0.005, 2.6), Color(0.13, 0.14, 0.17))
	_prim("caja", Vector3(-2.2, 0.006, -2.15), Vector3(11.2, 0.012, 1.7), Color(0.2, 0.42, 0.2))
	for z: float in [-2.97, -1.33]:
		_prim("caja", Vector3(-2.2, 0.014, z), Vector3(11.2, 0.006, 0.05), blanco)
	for i in 6:
		_prim("caja", Vector3(-7.4 + float(i) * 2.0, 0.014, -2.15), Vector3(0.05, 0.006, 1.6), blanco)
	for i in 4:
		for j in 9:
			var claro := (i + j) % 2 == 0
			_prim("caja", Vector3(4.1 + float(i) * 1.0, 0.007, -5.45 + float(j) * 1.0), Vector3(0.98, 0.014, 0.98),
				Color(0.26, 0.26, 0.28) if claro else Color(0.2, 0.2, 0.22))
	_prim("caja", Vector3(0.7, 0.006, 1.05), Vector3(5.2, 0.012, 3.7), Color(0.3, 0.31, 0.33))
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(0.7, 0.014, 1.05 + s * 1.82), Vector3(5.2, 0.006, 0.06), _c1)
		_prim("caja", Vector3(0.7 + s * 2.57, 0.014, 1.05), Vector3(0.06, 0.006, 3.7), _c1)
	## --- Paredes: franja del club, espejo largo, teles y altavoces.
	for z: float in [-5.99]:
		_prim("caja", Vector3(0, 2.75, z), Vector3(16, 0.18, 0.02), _c1)
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 7.99, 2.75, 0), Vector3(0.02, 0.18, 12), _c1)
	Mini3D.caja(_raiz, Vector3(-2.2, 1.35, -5.98), Vector3(10.8, 2.1, 0.02), Mini3D.mat(Color(0.62, 0.68, 0.74), 0.04, 0.08))
	_prim("caja", Vector3(-2.2, 0.27, -5.97), Vector3(10.9, 0.06, 0.04), cromo, "metal")
	_prim("caja", Vector3(-2.2, 2.43, -5.97), Vector3(10.9, 0.06, 0.04), cromo, "metal")
	var datos_tv := ["RITMO  5:12 /km\nFC  152 ppm", "CARGA  ▲ 8 %\nRPE  6,4", "SPRINTS  118\nVEL. MÁX  33,1"]
	for k in 3:
		var x := -6.0 + float(k) * 3.0
		_pantalla(Vector3(x, 3.25, -5.95), Vector2(1.3, 0.72), Color(0.12, 0.3, 0.5))
		_cartel(String(datos_tv[k]), Vector3(x, 3.25, -5.9), 16, Color(0.85, 1.0, 0.9))
	for p: Vector3 in [Vector3(-7.72, 3.2, -5.72), Vector3(7.72, 3.2, -5.72), Vector3(-7.72, 3.2, 5.6), Vector3(7.72, 3.2, 5.6)]:
		_prim("caja", p + Vector3(0, -0.06, 0), Vector3(0.25, 0.04, 0.25), hierro)
		_poner("speakerSmall", p, atan2(-p.x, -p.z))
	_cartel("💪 " + _sala_nombre().to_upper(), Vector3(4.6, 3.55, -5.95), 34)
	_cartel("ESFUERZO · EQUIPO · VICTORIA", Vector3(-7.96, 3.2, 1.2), 30, _c1.lightened(0.25), PI * 0.5)
	## --- Cardio: cuatro cintas (tres en marcha) y tres bicis.
	for k in 4:
		var t := Transform3D(Basis.IDENTITY, Vector3(-7.0 + float(k) * 1.4, 0, -4.6))
		_cinta(t, hierro, acero)
		if k != 2:
			var d := Mini3D.persona(_raiz, _rng, t.origin + Vector3(0, 0.25, 0.15), dep)
			if not d.is_empty():
				(d["nodo"] as Node3D).rotation.y = PI
				Mini3D.anim(d, "trotar", "")
				(d["anim"] as AnimationPlayer).seek(_rng.randf(), true)
	_prim("caja", Vector3(-4.2 + 0.42, 1.38, -5.4), Vector3(0.5, 0.05, 0.3), blanco, "mate", Vector3(0, 0, 0.1))
	for k in 3:
		var t := Transform3D(Basis.IDENTITY, Vector3(-0.9 + float(k) * 1.25, 0, -4.75))
		var sillin := _bici(t, hierro, acero)
		if k != 1:
			_trabajador(Vector3(sillin.x, 0, sillin.z - 0.05), PI, true, [], dep, sillin.y)
	## --- Fuerza: poleas al fondo a la derecha con alguien haciendo press.
	_poleas(Transform3D(Basis.IDENTITY, Vector3(6.0, 0, -5.45)), hierro, acero, cromo)
	_trabajador(Vector3(6.0, 0, -4.55), 0.0, false, ["empujar", "empujar", "cansado"], dep)
	## Rack de mancuernas contra la pared derecha y su par de bancos.
	_rack_mancuernas(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(7.5, 0, -1.6)), hierro, cromo)
	for z: float in [-2.6, -0.6]:
		_banco_pesas(Transform3D(Basis.IDENTITY, Vector3(5.3, 0, z)), hierro, acero)
	_trabajador(Vector3(5.3, 0, -2.6), PI * 0.5, true, [], dep, 0.46)
	_trabajador(Vector3(4.4, 0, -0.4), PI * 0.5, false, ["charla", "brazos_jarra", "pedir_calma"], dep)
	_poner("trashcan", Vector3(4.2, 0, -3.35), 0.0, 1.4)
	## Jaula de sentadillas con su barra, el árbol de discos y las kettlebells.
	_jaula(Transform3D(Basis.IDENTITY, Vector3(5.3, 0, 1.9)), hierro, cromo)
	var colores_kb := [Color(0.85, 0.3, 0.5), Color(0.25, 0.45, 0.85), Color(0.95, 0.8, 0.2), Color(0.55, 0.3, 0.7), Color(0.3, 0.7, 0.35), Color(0.9, 0.5, 0.15)]
	for k in 6:
		var r := 0.17 + float(k) * 0.018
		var p := Vector3(7.45, 0, 0.45 + float(k) * 0.33)
		_prim("esf", p + Vector3(0, r * 0.5, 0), Vector3.ONE * r, colores_kb[k], "goma")
		_prim("caja", p + Vector3(0, r * 1.0 + 0.04, 0), Vector3(0.03, 0.03, r * 0.75), hierro)
		for s: float in [-1.0, 1.0]:
			_prim("caja", p + Vector3(0, r * 0.9, s * r * 0.36), Vector3(0.03, 0.12, 0.03), hierro)
	_trabajador(Vector3(6.75, 0, 1.3), PI * 0.5, false, ["recoger_balon", "parado", "cansado"], dep)
	## --- Pista de césped: escalera de agilidad, conos y alguien que esprinta.
	for i in 12:
		_prim("caja", Vector3(-6.6 + float(i) * 0.42, 0.02, -2.15), Vector3(0.04, 0.012, 0.5), Color(0.98, 0.85, 0.1))
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(-6.6 + 11.0 * 0.21, 0.018, -2.15 + s * 0.25), Vector3(4.66, 0.008, 0.025), Color(0.98, 0.85, 0.1))
	for k in 6:
		var p := Vector3(-1.4 + float(k) * 0.8, 0, -2.15 + (0.52 if k % 2 == 0 else -0.52))
		_prim("cono", p + Vector3(0, 0.12, 0), Vector3(0.2, 0.24, 0.2), Color(1.0, 0.45, 0.08), "goma")
		_prim("caja", p + Vector3(0, 0.008, 0), Vector3(0.24, 0.016, 0.24), Color(1.0, 0.45, 0.08))
	_caminante([Vector3(-7.2, 0, -2.15), Vector3(2.8, 0, -2.15)], dep, true)
	if not _caminantes.is_empty():
		## Por el centro de la pista, sin el desvío al azar: entre los conos.
		_caminantes[-1]["puntos"] = [Vector3(-7.2, 0, -2.15), Vector3(2.8, 0, -2.15)]
		(_caminantes[-1]["d"]["nodo"] as Node3D).position.z = -2.15
	## --- Zona funcional: cajones pliométricos, balones medicinales y fitballs.
	var altos := [0.3, 0.5, 0.75]
	for k in 3:
		var p := Vector3(-1.2 + float(k) * 1.0, 0, -0.25)
		var h: float = altos[k]
		_prim("caja", p + Vector3(0, h * 0.5, 0), Vector3(0.75, h, 0.6), Color(0.62, 0.45, 0.3) if k != 1 else Color(0.15, 0.15, 0.17))
		_prim("caja", p + Vector3(0, h + 0.004, 0), Vector3(0.7, 0.01, 0.55), Color(0.2, 0.2, 0.22))
		_prim("caja", p + Vector3(0, h * 0.5, 0.302), Vector3(0.3, 0.12, 0.004), _c1)
	_trabajador(Vector3(-0.2, 0, 0.55), PI, false, ["saltar_inicio", "caer_salto", "saltar_inicio", "cansado"], dep)
	_estante_balones(Transform3D(Basis(Vector3.UP, PI), Vector3(2.75, 0, -0.35)), hierro)
	_prim("esf", Vector3(2.0, 0.13, 0.35), Vector3.ONE * 0.26, Color(0.75, 0.2, 0.15), "goma")
	var fit := [Color(0.25, 0.45, 0.8), _c1, Color(0.55, 0.57, 0.6), Color(0.25, 0.45, 0.8)]
	var sitios_fit := [Vector3(0.3, 0, 2.3), Vector3(1.35, 0, 2.55), Vector3(2.4, 0, 2.1), Vector3(2.75, 0, 1.2)]
	for k in 4:
		var dm := 0.65 if k != 3 else 0.55
		_prim("esf", (sitios_fit[k] as Vector3) + Vector3(0, dm * 0.5, 0), Vector3.ONE * dm, fit[k], "goma")
	_trabajador(Vector3(1.35, 0, 2.6), 0.0, true, [], dep, 0.6)
	## --- Estiramientos (izquierda): colchonetas, rulos y gomas.
	var mats := [Vector3(-5.3, 0, 0.4), Vector3(-3.4, 0, 0.4), Vector3(-5.3, 0, 2.0), Vector3(-3.4, 0, 2.0)]
	for k in 4:
		var p: Vector3 = mats[k]
		_prim("caja", p + Vector3(0, 0.02, 0), Vector3(1.8, 0.04, 0.85), _c1.darkened(0.15) if k % 2 == 0 else Color(0.25, 0.3, 0.38), "goma")
		_prim("cil", p + Vector3(0.75, 0.1, -0.3), Vector3(0.15, 0.6, 0.15), [Color(0.2, 0.2, 0.22), Color(0.3, 0.55, 0.85)][k % 2], "goma", Vector3(PI * 0.5, 0, 0))
	_prim("caja", Vector3(-3.0, 0.045, 0.62), Vector3(0.7, 0.01, 0.05), Color(0.9, 0.3, 0.3))
	_prim("caja", Vector3(-4.9, 0.045, 2.25), Vector3(0.6, 0.01, 0.05), Color(0.3, 0.75, 0.4))
	_trabajador(Vector3(-5.6, 0.04, 0.4), 0.0, false, ["agachado", "parado", "agachado", "agachado"], dep)
	_trabajador(Vector3(-3.3, 0.04, 0.35), PI * 0.3, false, ["atarse_botin"], dep)
	_tumbado(Vector3(-5.3, 0.04, 2.0), PI * 0.5, dep)
	_trabajador(Vector3(-3.6, 0.04, 2.0), PI * 0.15, false, ["brazos_al_frente", "cansado", "charla", "aplaudir"], dep)
	## --- Recuperación: fuente de agua, toallero, la camilla con el fisio.
	_fuente_agua(Vector3(-7.72, 0, -0.55), acero, cromo)
	_toallero(Vector3(-7.62, 0, 1.15))
	_prim("caja", Vector3(-6.8, 0.37, 3.7), Vector3(0.7, 0.06, 1.95), acero, "metal")
	for x: float in [-7.08, -6.52]:
		for z: float in [2.9, 4.5]:
			_prim("caja", Vector3(x, 0.18, z), Vector3(0.05, 0.36, 0.05), acero, "metal")
	_prim("caja", Vector3(-6.8, 0.48, 3.7), Vector3(0.72, 0.16, 1.95), Color(0.15, 0.2, 0.3), "goma")
	_prim("caja", Vector3(-6.8, 0.565, 4.45), Vector3(0.5, 0.01, 0.4), blanco)
	_tumbado(Vector3(-6.8, 0.56, 3.7), 0.0, dep)
	_trabajador(Vector3(-6.0, 0, 3.4), -PI * 0.5, false, ["charla", "pedir_calma", "brazos_jarra"], [Color(0.95, 0.95, 0.97), Color(0.14, 0.18, 0.32), true])
	_prim("caja", Vector3(-7.6, 0.4, 5.1), Vector3(0.5, 0.8, 0.45), blanco)
	_prim("caja", Vector3(-7.36, 0.6, 5.1), Vector3(0.02, 0.08, 0.08), Color(0.85, 0.15, 0.15))
	_planta(Vector3(-7.3, 0, 5.6))
	## --- Delante a la derecha: banco de vestuario, mochilas, la mesa del
	## preparador con su portátil y la pantalla de GPS.
	_asiento("benchCushionLow", Vector3(3.8, 0, 5.35), PI, [0.4], dep, Vector3(4.8, 2.2, 2.2), {"carpet": _c1.darkened(0.35), "wood": Color(0.62, 0.48, 0.32)})
	for k in 3:
		_prim("caja", Vector3(3.0 + float(k) * 0.35, 0.47, 5.35), Vector3(0.3, 0.05, 0.36), blanco if k != 1 else _c1)
	for k in 2:
		var p := Vector3(2.7 + float(k) * 2.1, 0, 4.95)
		_prim("caja", p + Vector3(0, 0.16, 0), Vector3(0.55, 0.32, 0.28), [Color(0.1, 0.1, 0.12), _c1.darkened(0.3)][k], "goma")
		_prim("cil", p + Vector3(0.38, 0.12, 0), Vector3(0.08, 0.24, 0.08), Color(0.25, 0.55, 0.9), "goma")
	var mesa_esc := 2.5
	_poner("kitchenBar", Vector3(6.5, 0, 4.82), -PI * 0.5, mesa_esc)
	_poner("kitchenBar", Vector3(6.5, 0, 3.75), -PI * 0.5, mesa_esc)
	var tope := _alto("kitchenBar", mesa_esc)
	_poner("laptop", Vector3(6.4, tope, 4.15), PI * 0.5, 2.0)
	_poner("comida/cup-coffee", Vector3(6.55, tope, 4.75), 0.3)
	_prim("caja", Vector3(6.5, tope + 0.01, 3.6), Vector3(0.22, 0.02, 0.3), blanco)
	_pantalla(Vector3(7.96, 2.0, 4.0), Vector2(2.2, 1.25), Color(0.08, 0.16, 0.22), -PI * 0.5)
	_cartel("GPS · SESIÓN DE HOY\nDistancia  6,8 km\nAlta intensidad  1.240 m\nSprints  22   ·   FC media  148", Vector3(7.9, 2.0, 4.0), 17, Color(0.6, 1.0, 0.75), -PI * 0.5)
	_trabajador(Vector3(5.7, 0, 4.2), PI * 0.5, false, ["senalar_adelante", "charla", "brazos_jarra", "aplaudir"], [_c1.darkened(0.5), Color(0.12, 0.12, 0.15), true])
	_poner("mini_arcade/vending-machine", Vector3(5.6, 0, 5.45), PI, 2.2)
	_planta(Vector3(2.6, 0, 5.6))
	_planta(Vector3(-2.6, 0, 5.6), false)
	_ventana(-1.0, -2.2, 2.0, false)

## Persona tumbada boca arriba (la caída del pack, congelada en su último fotograma).
func _tumbado(p: Vector3, giro: float, deporte: Array) -> void:
	var d := Mini3D.persona(_raiz, _rng, p, deporte)
	if d.is_empty():
		return
	(d["nodo"] as Node3D).rotation.y = giro
	Mini3D.anim(d, "caida_lesion", "", 0.0)
	var ap: AnimationPlayer = d["anim"]
	ap.seek(ap.current_animation_length, true)
	## El clip acaba con el cuerpo lejos de su origen y girado: se mide dónde
	## quedan la cabeza y los pies y se recoloca para que el cuerpo quede
	## centrado en `p` con la cabeza hacia `giro`.
	var nodo: Node3D = d["nodo"]
	var esq: Array = nodo.find_children("*", "Skeleton3D", true, false)
	if esq.is_empty():
		return
	var sk: Skeleton3D = esq[0]
	var cab := _hueso_local(nodo, sk, "Head")
	var pies := (_hueso_local(nodo, sk, "foot_l") + _hueso_local(nodo, sk, "foot_r")) * 0.5
	var eje := cab - pies
	if Vector2(eje.x, eje.z).length() < 0.3:
		return
	var th := giro - atan2(eje.x, eje.z)
	var mitad := (cab + pies) * 0.5
	mitad.y = 0.0
	nodo.rotation.y = th
	nodo.position = p - Basis(Vector3.UP, th) * mitad

## Posición de un hueso (pose actual) en el espacio de `nodo`.
static func _hueso_local(nodo: Node3D, sk: Skeleton3D, hueso: String) -> Vector3:
	var b := sk.find_bone(hueso)
	if b < 0:
		return Vector3.ZERO
	var t := sk.get_bone_global_pose(b)
	var n: Node = sk
	while n != null and n != nodo:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t.origin

## Cinta de correr; quien corre mira a −Z local (consola).
func _cinta(t: Transform3D, hierro: Color, acero: Color) -> void:
	_prim("caja", Vector3(0, 0.11, 0.05), Vector3(0.82, 0.22, 1.95), hierro, "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 0.225, 0.1), Vector3(0.52, 0.012, 1.7), Color(0.05, 0.05, 0.06), "goma", Vector3.ZERO, t)
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 0.34, 0.23, 0.1), Vector3(0.14, 0.02, 1.7), acero, "metal", Vector3.ZERO, t)
		_prim("caja", Vector3(s * 0.36, 0.72, -0.78), Vector3(0.06, 1.0, 0.07), acero, "metal", Vector3(0.18, 0, 0), t)
		_prim("caja", Vector3(s * 0.36, 1.12, -0.5), Vector3(0.05, 0.05, 0.55), Color(0.2, 0.2, 0.22), "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 1.3, -0.82), Vector3(0.8, 0.32, 0.1), Color(0.2, 0.2, 0.22), "mate", Vector3(-0.5, 0, 0), t)
	_prim("caja", Vector3(0, 1.31, -0.77), Vector3(0.5, 0.2, 0.01), Color(0.2, 0.55, 0.85), "luz", Vector3(-0.5, 0, 0), t)

## Bici estática mirando a −Z local; devuelve el centro del sillín (global).
func _bici(t: Transform3D, hierro: Color, acero: Color) -> Vector3:
	_prim("caja", Vector3(0, 0.04, 0), Vector3(0.5, 0.08, 1.2), hierro, "goma", Vector3.ZERO, t)
	_prim("cil", Vector3(0, 0.33, -0.55), Vector3(0.5, 0.08, 0.5), acero, "metal", Vector3(0, 0, PI * 0.5), t)
	_prim("caja", Vector3(0, 0.33, -0.55), Vector3(0.1, 0.3, 0.3), Color(0.8, 0.15, 0.12), "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 0.45, -0.1), Vector3(0.08, 0.08, 0.9), hierro, "goma", Vector3(0.35, 0, 0), t)
	_prim("caja", Vector3(0, 0.55, 0.3), Vector3(0.07, 0.6, 0.07), hierro, "goma", Vector3(-0.25, 0, 0), t)
	_prim("caja", Vector3(0, 0.82, 0.38), Vector3(0.24, 0.07, 0.3), Color(0.08, 0.08, 0.09), "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 0.72, -0.38), Vector3(0.07, 0.75, 0.07), hierro, "goma", Vector3(0.3, 0, 0), t)
	_prim("caja", Vector3(0, 1.08, -0.28), Vector3(0.55, 0.05, 0.1), Color(0.2, 0.2, 0.22), "goma", Vector3.ZERO, t)
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 0.25, 1.1, -0.18), Vector3(0.05, 0.05, 0.22), Color(0.2, 0.2, 0.22), "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 1.2, -0.38), Vector3(0.24, 0.15, 0.04), Color(0.2, 0.55, 0.85), "luz", Vector3(-0.4, 0, 0), t)
	_prim("cil", Vector3(0, 0.36, -0.05), Vector3(0.16, 0.06, 0.16), acero, "metal", Vector3(0, 0, PI * 0.5), t)
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 0.14, 0.3, -0.05), Vector3(0.08, 0.025, 0.14), Color(0.08, 0.08, 0.09), "goma", Vector3.ZERO, t)
	return t * Vector3(0, 0.86, 0.38)

## Máquina de poleas: dos torres con su pila de placas, travesaño de dominadas
## y los cables con sus agarres.
func _poleas(t: Transform3D, hierro: Color, acero: Color, cromo: Color) -> void:
	for s: float in [-1.0, 1.0]:
		var x := s * 1.3
		for dx: float in [-0.22, 0.22]:
			_prim("caja", Vector3(x + dx, 1.15, 0), Vector3(0.08, 2.3, 0.08), hierro, "goma", Vector3.ZERO, t)
		_prim("caja", Vector3(x, 0.03, 0), Vector3(0.6, 0.06, 0.5), hierro, "goma", Vector3.ZERO, t)
		for k in 12:
			_prim("caja", Vector3(x, 0.1 + float(k) * 0.055, 0), Vector3(0.34, 0.05, 0.2), Color(0.25, 0.25, 0.27) if k % 2 == 0 else Color(0.3, 0.3, 0.32), "metal", Vector3.ZERO, t)
		_prim("caja", Vector3(x, 1.2, 0.0), Vector3(0.02, 1.8, 0.02), cromo, "metal", Vector3.ZERO, t)
		_prim("cil", Vector3(x - s * 0.22, 2.0, 0.1), Vector3(0.14, 0.04, 0.14), acero, "metal", Vector3(PI * 0.5, 0, 0), t)
		_prim("caja", Vector3(x - s * 0.35, 1.6, 0.25), Vector3(0.012, 0.85, 0.012), Color(0.1, 0.1, 0.1), "goma", Vector3(0.4, 0, -s * 0.15), t)
		_prim("caja", Vector3(x - s * 0.45, 1.2, 0.42), Vector3(0.14, 0.03, 0.03), Color(0.12, 0.12, 0.12), "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 2.3, 0), Vector3(3.1, 0.1, 0.1), hierro, "goma", Vector3.ZERO, t)
	_prim("cil", Vector3(0, 2.15, 0.15), Vector3(0.035, 1.6, 0.035), cromo, "metal", Vector3(0, 0, PI * 0.5), t)
	_prim("caja", Vector3(0, 2.3, 0.06), Vector3(1.2, 0.08, 0.01), _c1, "mate", Vector3.ZERO, t)

## Rack de mancuernas de dos baldas inclinadas (frente hacia +Z local), con
## diez pares de peso creciente.
func _rack_mancuernas(t: Transform3D, hierro: Color, cromo: Color) -> void:
	var largo := 3.2
	for x: float in [-largo * 0.5, 0.0, largo * 0.5]:
		_prim("caja", Vector3(x, 0.4, 0), Vector3(0.06, 0.8, 0.55), hierro, "goma", Vector3.ZERO, t)
	for b in 2:
		var y := 0.42 + float(b) * 0.36
		var z := 0.1 - float(b) * 0.2
		_prim("caja", Vector3(0, y, z), Vector3(largo, 0.04, 0.32), hierro, "goma", Vector3(0.2, 0, 0), t)
		for k in 10:
			var x := -largo * 0.5 + 0.17 + float(k) * 0.32
			var peso := float(k) / 9.0
			var r := 0.085 + peso * 0.05 - float(b) * 0.015
			_prim("cil", Vector3(x, y + r + 0.02, z), Vector3(0.035, 0.32, 0.035), cromo, "metal", Vector3(PI * 0.5, 0, 0), t)
			for s: float in [-1.0, 1.0]:
				_prim("cil", Vector3(x, y + r + 0.02, z + s * (0.12 + peso * 0.03)), Vector3(r * 2.0, 0.07 + peso * 0.04, r * 2.0), Color(0.1, 0.1, 0.11), "goma", Vector3(PI * 0.5, 0, 0), t)
	_prim("caja", Vector3(0, 0.95, -0.25), Vector3(largo, 0.1, 0.03), _c1, "mate", Vector3.ZERO, t)

## Banco plano de pesas, a lo largo de Z local.
func _banco_pesas(t: Transform3D, hierro: Color, acero: Color) -> void:
	_prim("caja", Vector3(0, 0.42, 0), Vector3(0.3, 0.08, 1.15), Color(0.1, 0.1, 0.12), "goma", Vector3.ZERO, t)
	for z: float in [-0.45, 0.45]:
		_prim("caja", Vector3(0, 0.19, z), Vector3(0.08, 0.38, 0.08), acero, "metal", Vector3.ZERO, t)
		_prim("caja", Vector3(0, 0.02, z), Vector3(0.45, 0.04, 0.08), acero, "metal", Vector3.ZERO, t)

## Jaula de sentadillas (frente +Z local) con la barra cargada en los ganchos
## y el árbol de discos al lado.
func _jaula(t: Transform3D, hierro: Color, cromo: Color) -> void:
	for x: float in [-0.6, 0.6]:
		for z: float in [-0.55, 0.55]:
			_prim("caja", Vector3(x, 1.15, z), Vector3(0.08, 2.3, 0.08), hierro, "goma", Vector3.ZERO, t)
		_prim("caja", Vector3(x, 2.28, 0), Vector3(0.08, 0.08, 1.18), hierro, "goma", Vector3.ZERO, t)
		_prim("caja", Vector3(x, 0.03, 0), Vector3(0.1, 0.06, 1.3), hierro, "goma", Vector3.ZERO, t)
	for z: float in [-0.55, 0.55]:
		_prim("caja", Vector3(0, 2.28, z), Vector3(1.28, 0.08, 0.08), hierro, "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 0.005, 0), Vector3(1.2, 0.01, 1.1), Color(0.45, 0.33, 0.22), "mate", Vector3.ZERO, t)
	_prim("cil", Vector3(0, 1.38, 0.55), Vector3(0.03, 2.2, 0.03), cromo, "metal", Vector3(0, 0, PI * 0.5), t)
	for s: float in [-1.0, 1.0]:
		for k in 2:
			_prim("cil", Vector3(s * (0.78 + float(k) * 0.06), 1.38, 0.55), Vector3(0.45 - float(k) * 0.12, 0.05, 0.45 - float(k) * 0.12),
				[Color(0.75, 0.15, 0.15), Color(0.2, 0.4, 0.8)][k], "goma", Vector3(0, 0, PI * 0.5), t)
	## Árbol de discos.
	var arbol := Vector3(-1.2, 0, -0.3)
	_prim("caja", arbol + Vector3(0, 0.55, 0), Vector3(0.06, 1.1, 0.06), hierro, "goma", Vector3.ZERO, t)
	_prim("caja", arbol + Vector3(0, 0.02, 0), Vector3(0.5, 0.04, 0.5), hierro, "goma", Vector3.ZERO, t)
	for k in 3:
		for s: float in [-1.0, 1.0]:
			var dm := 0.45 - float(k) * 0.1
			_prim("cil", arbol + Vector3(0, 0.3 + float(k) * 0.3, s * 0.08), Vector3(dm, 0.05, dm),
				[Color(0.75, 0.15, 0.15), Color(0.2, 0.4, 0.8), Color(0.9, 0.75, 0.15)][k], "goma", Vector3(PI * 0.5, 0, 0), t)

## Estantería en A con dos baldas de balones medicinales (frente +Z local).
func _estante_balones(t: Transform3D, hierro: Color) -> void:
	for x: float in [-0.7, 0.7]:
		_prim("caja", Vector3(x, 0.5, 0), Vector3(0.05, 1.0, 0.5), hierro, "goma", Vector3.ZERO, t)
	var cols := [Color(0.75, 0.2, 0.15), Color(0.2, 0.2, 0.22), Color(0.25, 0.45, 0.8), Color(0.9, 0.7, 0.15), Color(0.3, 0.6, 0.3)]
	for b in 2:
		var y := 0.25 + float(b) * 0.45
		_prim("caja", Vector3(0, y, 0), Vector3(1.4, 0.03, 0.4), hierro, "goma", Vector3.ZERO, t)
		for k in 5:
			var dm := 0.24 + float(k % 3) * 0.02
			_prim("esf", Vector3(-0.54 + float(k) * 0.27, y + 0.015 + dm * 0.5, 0), Vector3.ONE * dm, cols[(k + b * 2) % cols.size()], "goma", Vector3.ZERO, t)

## Fuente de agua contra la pared izquierda con su garrafa y vasos.
func _fuente_agua(p: Vector3, acero: Color, cromo: Color) -> void:
	_prim("caja", p + Vector3(0, 0.5, 0), Vector3(0.36, 1.0, 0.36), Color(0.88, 0.88, 0.9))
	_prim("caja", p + Vector3(0.05, 0.85, 0), Vector3(0.3, 0.12, 0.3), acero, "metal")
	_prim("cil", p + Vector3(0, 1.22, 0), Vector3(0.28, 0.42, 0.28), Color(0.45, 0.68, 0.95), "luz")
	_prim("cil", p + Vector3(0, 1.0, 0), Vector3(0.1, 0.04, 0.1), Color(0.3, 0.5, 0.85))
	_prim("caja", p + Vector3(0.2, 0.92, 0), Vector3(0.04, 0.04, 0.04), cromo, "metal")
	_prim("cil", p + Vector3(0.05, 0.95, 0.35), Vector3(0.08, 0.3, 0.08), Color(0.92, 0.92, 0.94))

## Estantería abierta con toallas dobladas (blancas y del club).
func _toallero(p: Vector3) -> void:
	var madera := Color(0.62, 0.48, 0.32)
	for z: float in [-0.6, 0.6]:
		_prim("caja", p + Vector3(0, 0.8, z), Vector3(0.4, 1.6, 0.04), madera)
	for b in 4:
		var y := 0.15 + float(b) * 0.45
		_prim("caja", p + Vector3(0, y, 0), Vector3(0.4, 0.03, 1.2), madera)
		for k in 3:
			for n in 3 - (b + k) % 2:
				_prim("caja", p + Vector3(0.02, y + 0.05 + float(n) * 0.075, -0.38 + float(k) * 0.38), Vector3(0.3, 0.07, 0.32), Color(0.95, 0.95, 0.96) if (k + b) % 3 != 1 else _c1)

## Sala de vídeo / e-sports (14 × 10 m): ocho puestos mirando a la pantalla
## grande; en la de e-sports, además, máquinas recreativas y un sofá.
func _analisis() -> void:
	var esports := clave == "esports"
	_sala(Vector3(14, 3.4, 10), Color(0.2, 0.2, 0.24), Color(0.3, 0.32, 0.38), "moqueta", Color(0.16, 0.17, 0.2))
	_pantalla(Vector3(0, 1.65, -4.94), Vector2(5.6, 2.0), Color(0.2, 0.55, 0.3) if not esports else Color(0.55, 0.25, 0.7))
	_cartel("⚽ 4-3-3  ·  presión alta" if not esports else "🎮 TORNEO DEL CLUB", Vector3(0, 1.65, -4.87), 44)
	for i in 2:
		for j in 4:
			var p := Vector3(-4.5 + float(j) * 3.0, 0, -1.6 + float(i) * 2.4)
			_puesto(p, PI, true, true, [_c1, _c2] if esports else [])
	if esports:
		for z: float in [-3.6, -2.6, -1.6]:
			_poner("mini_arcade/arcade-machine", Vector3(6.45, 0, z), -PI * 0.5)
		_asiento("loungeSofa", Vector3(-6.55, 0, 2.6), PI * 0.5, [0.0], [_c1, _c2], null, {"carpet": Color(0.15, 0.15, 0.2)})
		_poner("mini_arcade/air-hockey", Vector3(5.6, 0, 2.6), PI * 0.5)
	else:
		_poner("bookcaseClosedDoors", Vector3(6.75, 0, -2.0), -PI * 0.5)
		Mini3D.caja(_raiz, Vector3(-6.97, 1.6, 1.0), Vector3(0.02, 1.2, 3.0), Mini3D.mat(Color(0.95, 0.95, 0.95), 0.6))
	_caminante([Vector3(-5.0, 0, -3.8), Vector3(5.0, 0, -3.8)])
	_cartel("📊 " + _sala_nombre().to_upper(), Vector3(0, 3.0, -4.94), 26)

## Comedor (18 × 12 m): la cocina al fondo con su barra de servir y los
## cocineros; las mesas con los jugadores comiendo.
func _comedor() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(18, 3.6, 12), Color(0.72, 0.64, 0.52), Color(0.96, 0.93, 0.86), "losa", Color(0.6, 0.48, 0.34))
	_cocina(-6.9, -6.0 + 0.45, ["kitchenFridgeLarge", "kitchenCabinet", "kitchenStove", "kitchenStove", "kitchenCabinetDrawer", "kitchenSink",
		"kitchenCabinet", "kitchenStoveElectric", "kitchenCabinet", "kitchenCabinetDrawer", "kitchenFridgeLarge"])
	var cocinero := [Color.WHITE, Color(0.2, 0.2, 0.22), true]
	for k in 3:
		_trabajador(Vector3(-4.0 + float(k) * 3.5, 0, -4.5), 0.0, false, ["charla", "pedir_calma", "saludo_mano"], cocinero)
	## Barra de servir con bandejas.
	var ancho := _medida("kitchenBar", 2.5).x
	for k in 8:
		_poner("kitchenBar", Vector3(-3.8 + float(k) * ancho, 0, -3.5), PI, 2.5, {"wood": Color(0.85, 0.86, 0.88), "woodDark": Color(0.6, 0.62, 0.65)})
	var tope := _alto("kitchenBar", 2.5)
	for k in 8:
		_poner(["comida/pot", "comida/bowl"][k % 2], Vector3(-3.8 + float(k) * ancho, tope, -3.5), 0.0)
	## Mesas con los jugadores comiendo.
	for i in 2:
		for j in 3:
			var p := Vector3(-5.5 + float(j) * 5.5, 0, -0.6 + float(i) * 3.0)
			_mesa_con_sillas(p, 0.0, "table", 2.2, 3, "chair", 0.6, [_c1, _c2], "comida/plate-dinner", ["comida/glass", "comida/salad", "comida/sandwich"])
	_ventana(-1.0, 0.8, 2.0)
	_ventana(1.0, 0.8, 2.0)
	_planta(Vector3(-8.4, 0, 5.4))
	_planta(Vector3(8.4, 0, 5.4))
	_cartel("🥗 " + _sala_nombre().to_upper(), Vector3(0, 3.05, -5.95), 34)

## Sala de prensa (14 × 11 m): panel de patrocinadores con los colores del club,
## mesa con el entrenador y un jugador, periodistas sentados y las cámaras.
func _prensa() -> void:
	_sala(Vector3(14, 3.6, 11), Color(0.22, 0.24, 0.32), Color(0.26, 0.3, 0.44), "moqueta")
	for i in 6:
		for j in 2:
			Mini3D.caja(_raiz, Vector3(-3.75 + float(i) * 1.5, 1.3 + float(j) * 1.1, -5.47), Vector3(1.48, 1.08, 0.04), Mini3D.mat(_c1 if (i + j) % 2 == 0 else _c2, 0.6))
	## La mesa sobre una tarima.
	Mini3D.caja(_raiz, Vector3(0, 0.1, -4.2), Vector3(6.0, 0.2, 2.2), Mini3D.mat(Color(0.12, 0.12, 0.15), 0.6))
	_poner("desk", Vector3(0, 0.2, -3.9), 0.0, Vector3(3.0, 2.0, 2.0), {"wood": Color(0.1, 0.1, 0.12), "woodDark": Color(0.1, 0.1, 0.12)})
	var tope := 0.2 + _alto("desk")
	for k in 2:
		var x := -0.8 + float(k) * 1.6
		_asiento("chairDesk", Vector3(x, 0.2, -4.75), 0.0, [0.0], [Color(0.1, 0.1, 0.12), Color(0.1, 0.1, 0.12), true] if k == 0 else [_c1, _c2])
		Mini3D.cilindro(_raiz, Vector3(x, tope + 0.15, -3.7), 0.012, 0.3, Mini3D.mat(Color(0.1, 0.1, 0.1), 0.3))
		Mini3D.esfera(_raiz, Vector3(x, tope + 0.32, -3.68), 0.035, Mini3D.mat(Color(0.15, 0.15, 0.15), 0.6))
		_poner("comida/soda-bottle", Vector3(x + 0.35, tope, -3.85), 0.0)
	## Periodistas sentados.
	for i in 3:
		for j in 6:
			var p := Vector3(-3.75 + float(j) * 1.5, 0, -1.3 + float(i) * 1.4)
			_asiento("chairModernCushion", p, PI, [0.0] if _rng.randf() < 0.75 else [], _calle(), null, {"carpet": Color(0.2, 0.2, 0.25)})
	## Las cámaras al fondo, a los lados del pasillo.
	for x: float in [-4.6, -2.6, 2.6, 4.6]:
		var cp := Vector3(x, 0, 3.9)
		Mini3D.cilindro(_raiz, cp + Vector3(0, 0.75, 0), 0.03, 1.5, Mini3D.mat(Color(0.2, 0.2, 0.2), 0.4))
		Mini3D.caja(_raiz, cp + Vector3(0, 1.6, 0), Vector3(0.3, 0.3, 0.55), Mini3D.mat(Color(0.12, 0.12, 0.13), 0.4))
		if absf(x) > 4.0:
			_trabajador(cp + Vector3(0, 0, 0.6), PI, false, ["charla", "brazos_jarra"], _calle())
	_cartel("🎙️ " + _sala_nombre().to_upper(), Vector3(0, 3.05, -5.45), 30)

## Museo (22 × 14 m): vitrinas con trofeos iluminadas, camisetas históricas,
## bancos y visitantes.
func _museo() -> void:
	_sala(Vector3(22, 5.0, 14), Color(0.42, 0.32, 0.26), Color(0.2, 0.2, 0.23), "parquet")
	var oro := Mini3D.mat(Color(0.95, 0.75, 0.25), 0.25)
	oro.metallic = 0.9
	var vidrio := Mini3D.mat(Color(0.8, 0.9, 1.0, 0.25), 0.05)
	for k in 5:
		var p := Vector3(-8.0 + float(k) * 4.0, 0, -2.2)
		Mini3D.caja(_raiz, p + Vector3(0, 0.5, 0), Vector3(1.4, 1.0, 1.4), Mini3D.mat(Color(0.12, 0.12, 0.14), 0.5))
		Mini3D.caja(_raiz, p + Vector3(0, 1.55, 0), Vector3(1.3, 1.1, 1.3), vidrio)
		Mini3D.cilindro(_raiz, p + Vector3(0, 1.25, 0), 0.1, 0.5, oro)
		Mini3D.esfera(_raiz, p + Vector3(0, 1.6, 0), 0.2, oro)
		var foco := SpotLight3D.new()
		foco.position = p + Vector3(0, 4.6, 0)
		foco.rotation.x = -PI * 0.5
		foco.light_energy = 3.0
		foco.spot_range = 6.0
		foco.spot_angle = 18.0
		_raiz.add_child(foco)
	## Camisetas históricas enmarcadas.
	for k in 6:
		var x := -8.75 + float(k) * 3.5
		Mini3D.caja(_raiz, Vector3(x, 2.4, -6.97), Vector3(1.3, 1.5, 0.04), Mini3D.mat(Color(0.1, 0.1, 0.1), 0.4))
		_camiseta(Vector3(x, 3.0, -6.93), 0.0, _c1 if k % 2 == 0 else _c2, _c2 if k % 2 == 0 else _c1)
	## Bancos para mirar y alfombra de pasillo.
	for x: float in [-6.0, 0.0, 6.0]:
		_asiento("benchCushionLow", Vector3(x, 0, 1.6), PI, [0.0] if _rng.randf() < 0.5 else [], _calle(), 2.6, {"carpet": Color(0.55, 0.12, 0.12), "wood": Color(0.25, 0.2, 0.18)})
	for p: Vector3 in [Vector3(-10.4, 0, 6.4), Vector3(10.4, 0, 6.4), Vector3(-10.4, 0, -6.4), Vector3(10.4, 0, -6.4)]:
		_planta(p)
	for k in 4:
		var z := 3.0 + float(k) * 0.8
		_caminante([Vector3(-9.5, 0, z), Vector3(-5.0, 0, -0.6), Vector3(5.0, 0, -0.6), Vector3(9.5, 0, z)], _calle())
	_trabajador(Vector3(10.2, 0, 3.6), -PI * 0.5, false, ["charla", "saludo_mano"], [Color(0.15, 0.15, 0.2), Color(0.15, 0.15, 0.2), true])
	_cartel("🏆 " + _sala_nombre().to_upper(), Vector3(0, 4.3, -6.95), 56, Color(1.0, 0.85, 0.4))

## Piscina de recuperación (22 × 14 m): el vaso con su borde y sus calles,
## jugadores en el agua, tumbonas y el fisio en el borde.
func _piscina() -> void:
	_sala(Vector3(22, 5.5, 14), Color(0.86, 0.89, 0.9), Color(0.76, 0.88, 0.92), "losa")
	var largo := 15.0
	var ancho := 7.0
	var agua := Mini3D.caja(_raiz, Vector3(0, 0.02, -2.0), Vector3(largo, 0.05, ancho), Mini3D.mat(Color(0.2, 0.6, 0.85, 0.9), 0.05, 0.25))
	agua.name = "Agua"
	var borde := Mini3D.mat(Color(0.95, 0.95, 0.94), 0.5)
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(0, 0.06, -2.0 + s * (ancho * 0.5 + 0.2)), Vector3(largo + 0.8, 0.08, 0.4), borde)
		Mini3D.caja(_raiz, Vector3(s * (largo * 0.5 + 0.2), 0.06, -2.0), Vector3(0.4, 0.08, ancho), borde)
	for k in 3:
		Mini3D.caja(_raiz, Vector3(0, 0.06, -2.0 - ancho * 0.5 + float(k + 1) * ancho * 0.25), Vector3(largo, 0.03, 0.06), Mini3D.mat(Color(0.95, 0.85, 0.2), 0.5))
	## Escalerilla.
	var metal := Mini3D.mat(Color(0.85, 0.86, 0.88), 0.2)
	metal.metallic = 0.8
	for s: float in [-1.0, 1.0]:
		Mini3D.cilindro(_raiz, Vector3(largo * 0.5 - 1.0 + s * 0.3, 0.45, -2.0 + ancho * 0.5 + 0.15), 0.03, 0.9, metal)
	for k in 4:
		var d := Mini3D.persona(_raiz, _rng, Vector3(-5.0 + float(k) * 3.4, -0.9, -3.4 + float(k % 2) * 2.4), [_c1, _c2])
		if not d.is_empty():
			Mini3D.anim(d, ["caminar", "parado", "saltar_inicio", "caminar"][k], "")
	_trabajador(Vector3(0, 0, 2.8), PI, false, ["aplaudir", "charla", "pedir_calma"], [Color.WHITE, Color(0.2, 0.4, 0.7), true])
	for k in 4:
		_asiento("loungeChairRelax", Vector3(-8.0 + float(k) * 1.6, 0, 4.4), PI, [0.0] if k == 1 else [], [_c1, _c2], null, {"carpet": Color(0.95, 0.95, 0.95), "wood": Color(0.7, 0.72, 0.75)})
	_poner("kitchenFridgeSmall", Vector3(10.65, 0, 4.0), -PI * 0.5)
	for k in 3:
		Mini3D.caja(_raiz, Vector3(8.4 + float(k) * 0.05, 0.05 + float(k) * 0.08, 5.6), Vector3(0.6, 0.08, 0.4), Mini3D.mat([Color.WHITE, _c1, _c2][k], 0.9))
	for p: Vector3 in [Vector3(10.4, 0, 6.4), Vector3(-10.4, 0, 6.4)]:
		_planta(p)
	_ventana(-1.0, -2.0, 4.0, false)
	_ventana(1.0, -2.0, 4.0, false)
	_cartel("🏊 " + _sala_nombre().to_upper(), Vector3(0, 4.3, -6.95), 44)

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
