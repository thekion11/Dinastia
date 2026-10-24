extends Node3D
## [Capa 1/4 de `metro_ciudad.gd`] _mat, _caja, _viaducto, _tunel_xray, _tunel, _estacion_elevada … (+2)

## EL METRO DE LA CIUDAD (7-10-2026, pedido: «metro… la ciudad debe ser real,
## interactiva»). Dos líneas que FUNCIONAN:
##
##  · LÍNEA 1 (roja), ELEVADA: un viaducto sobre la mediana de la avenida
##    x = 660, de punta a punta de la ciudad, con siete estaciones de andén
##    alto. Sus trenes se ven pasar por encima del tráfico.
##  · LÍNEA 2 (azul), SUBTERRÁNEA: bajo la avenida z = -660, cruzando por
##    debajo del río, con sus bocas en la acera. Desde arriba no se ve; el
##    botón «🚇 Metro» del mapa activa la vista de rayos X: el túnel y los
##    trenes se dibujan a través del suelo.
##  · Transbordo entre las dos en (660, -660).
##
## Cada tren (tres coches) va y vuelve por su línea: acelera, va a su
## velocidad de crucero, frena antes de cada estación, abre unos segundos y
## sigue (`Tren.simular`, lógica pura y comprobable). Los paneles de cada
## estación dicen cuánto falta para el próximo tren.

const ALTO_VIADUCTO := 11.0
const PROF_TUNEL := -12.0
const VEL := 16.0          ## m/s de crucero (~58 km/h)
const ACEL := 1.2          ## m/s²
const PARADA := 7.0        ## s con las puertas abiertas

## Un tren sobre una línea recta de estaciones (posiciones `s` a lo largo).
class Tren:
	var s := 0.0
	var v := 0.0
	var sentido := 1.0
	var espera := 0.0
	var largo := 0.0
	var estaciones: PackedFloat32Array
	var paradas_hechas := 0

	func _init(largo_linea: float, est: PackedFloat32Array, s0: float, sentido0: float) -> void:
		largo = largo_linea
		estaciones = est
		s = s0
		sentido = sentido0

	## La próxima estación en el sentido de la marcha (INF si no queda ninguna:
	## está en la cabecera).
	## CORREGIDO (7-10-2026): con «d > 0,5» el tren frenaba hasta quedar a
	## menos de medio metro, daba la estación por pasada y seguía sin parar
	## (el banco lo cazó: 0 paradas en 10 minutos). Ahora solo se descarta la
	## estación donde acaba de parar.
	var ultima_parada := -INF

	func proxima() -> float:
		var mejor := INF
		for e in estaciones:
			if absf(e - ultima_parada) < 0.01:
				continue
			var d := (e - s) * sentido
			if d > -0.01 and d < mejor:
				mejor = d
		if mejor == INF:
			return INF
		return s + mejor * sentido

	func simular(delta: float) -> void:
		if espera > 0.0:
			espera -= delta
			return
		var objetivo := proxima()
		if objetivo == INF:
			## Cabecera: da la vuelta y sigue.
			sentido = -sentido
			return
		var dist := absf(objetivo - s)
		var frenada := v * v / (2.0 * ACEL)
		if dist <= frenada + 0.3:
			v = maxf(0.0, v - ACEL * delta)
		else:
			v = minf(VEL, v + ACEL * delta)
		var paso := v * delta
		if paso >= dist or dist < 0.6:
			s = objetivo
			v = 0.0
			espera = PARADA
			paradas_hechas += 1
			ultima_parada = objetivo
			return
		s += paso * sentido

	## Segundos aproximados hasta pasar por `pos` (en `s`).
	func eta(pos: float) -> float:
		var d := (pos - s) * sentido
		if d < 0.0:
			d = (largo - s if sentido > 0.0 else s) + (largo - pos if sentido > 0.0 else pos)
			d = absf(d)
		var n_paradas := 0
		for e in estaciones:
			var de := (e - s) * sentido
			if de > 0.5 and de < d:
				n_paradas += 1
		return d / VEL + float(n_paradas) * (PARADA + VEL / ACEL) + maxf(espera, 0.0)

## Los accesos para el personaje: {pie (calle), anden (donde aparece), linea, elevada}.

## LOS NOMBRES DE LAS ESTACIONES (de norte a sur / de oeste a este).
const NOMBRES := {
	"Línea 1": ["Alto Norte", "Mercado Este", "Cine", "Transbordo", "Hospital", "Ensanche", "Puerta Sur"],
	"Línea 2": ["Ribera Oeste", "Puerto", "Talleres", "Plaza Mayor", "Estación Central", "Ópera", "Transbordo"],
}
const ANDEN_LAT := 4.0      ## centro de cada andén lateral (a cada lado de la vía)
const ANDEN_ANCHO := 4.0
const ANDEN_LARGO := 60.0
const PISO_COCHE := 1.0     ## altura del suelo del coche sobre la vía

## Los accesos para el personaje: {pie (calle), anden (centro del andén), linea, idx, elevada, dir}.
var accesos: Array = []
var lineas: Array = []     ## [{nombre, color, a, b, elevada, estaciones, est_s, trenes, nodos, nodos_x}]
var _xray: Node3D
var _paneles: Array = []   ## [{label, linea, s}]
var _t_panel := 0.0

## LA DECORACIÓN DE CADA ESTACIÓN (7-10-2026, «el metro debe tener
## decoraciones por estación, nombre de estación»): cada una tiene su tema
## -un icono y un color- en un mural a lo largo del andén, más lo que trae
## cualquier estación de verdad: plano de la red, máquinas de billetes, una
## expendedora, reloj, papeleras y jardineras.
const TEMAS := {
	"Alto Norte": ["⛰️", Color(0.45, 0.6, 0.8), "Las cumbres del norte"],
	"Mercado Este": ["🍊", Color(0.95, 0.6, 0.2), "Frutas y mercados"],
	"Cine": ["🎬", Color(0.25, 0.25, 0.3), "Cien años de cine"],
	"Transbordo": ["🔁", Color(0.6, 0.3, 0.7), "Líneas 1 y 2"],
	"Hospital": ["➕", Color(0.3, 0.7, 0.5), "Salud y cuidado"],
	"Ensanche": ["🏘️", Color(0.85, 0.7, 0.45), "La ciudad que crece"],
	"Puerta Sur": ["🚪", Color(0.7, 0.4, 0.3), "La antigua muralla"],
	"Ribera Oeste": ["🌊", Color(0.25, 0.55, 0.75), "El río y sus orillas"],
	"Puerto": ["⚓", Color(0.15, 0.3, 0.55), "Barcos y remeros"],
	"Talleres": ["⚙️", Color(0.5, 0.5, 0.52), "Oficios de la ciudad"],
	"Plaza Mayor": ["🏛️", Color(0.8, 0.65, 0.4), "El corazón del barrio"],
	"Estación Central": ["🕰️", Color(0.55, 0.35, 0.25), "Trenes de toda la vida"],
	"Ópera": ["🎭", Color(0.6, 0.15, 0.25), "Música y teatro"],
}

# ------------------------------------------------- andenes vivos (15-10-2026)
## «A ese nivel debe estar todo en la ciudad» (los kits de Kenney): los andenes
## estaban vacíos (un banco-tabla y jardineras de caja con una esfera). Ahora
## llevan piezas del kit (CC0) a escala real y GENTE ESPERANDO, de pie y
## sentada. La gente solo existe en la estación junto a la cámara (`_process`).

const KENNEY := "res://assets/kenney/"
## pieza -> escala (medidas en EVALUACION_KENNEY_CIUDAD.md: arcade ×2,4-2,5;
## muebles ×2; montaña rusa ×2-2,2).
const PIEZAS_ANDEN := {
	"expendedora": ["mini_arcade/vending-machine", 2.5],     ## 1,25 × 1,9 m
	"billetes": ["mini_arcade/ticket-machine", 2.0],         ## 0,8 × 1,85 m
	"banco": ["montana_rusa/bench", 2.0],                    ## 1,6 m de largo
	"papelera": ["montana_rusa/trash", 1.9],                 ## 0,8 m de alto
	"planta": ["muebles/pottedPlant", 2.6],                  ## 1,7 m de alto
}
## Altura y fondo del asiento del banco a la escala de arriba (medidos en la
## captura: asiento a 0,45 m; el centro del asiento, 0,1 m por delante del origen).
const BANCO_ASIENTO := 0.45
const BANCO_FONDO := 0.15
const RADIO_GENTE := 75.0   ## a esta distancia de la cámara se llena el andén

static var _escenas := {}
var _sitios: Array = []     ## [{centro, clave, sitios: [{p, giro, sentado, pareja}]}]
var _gente_clave := ""
var _gente: Node3D
var _cola_gente: Array = []
var _fijos_gente: Array = []
var _t_gente := 0.0
var _rng_gente := RandomNumberGenerator.new()

# ------------------------------------- subir y bajar del tren (16-10-2026)
## Pedido: «nadie sube ni baja del tren». Cuando el tren para en la estación
## con gente, algunos de los que esperan caminan hasta la puerta más cercana y
## entran; otros salen del tren y se van hacia la escalera. El tren NO arranca
## hasta que terminan (como mucho `RETENCION_MAX` s más). Los sitios que dejan
## los que suben se vuelven a ocupar con gente que llega por la escalera.
const RETENCION_MAX := 10.0
const VEL_GENTE := 1.35
const RADIO_PERSONA := 0.3
var _gente_linea := ""
var _gente_idx := -1
var _gente_lados: Array = []
var _caminantes: Array = []   ## [{d, ruta, fin, tren, suelta, espera, andando, s?, e?}]
var _embarque := {}           ## k del tren -> {t}
var _huecos: Array = []       ## [{s, e, t}] sitios libres que se volverán a ocupar

# ------------------------------------------- pasajeros dentro del coche
## Solo en el tren más cercano a la cámara (a menos de 45 m): unos sentados y
## alguno de pie junto a las barras. Se crean de uno en uno.
var _pas_tren: Node3D
var _pas_nodo: Node3D
var _cola_pas: Array = []

## Tramos de pared entre puertas (z desde-hasta, coordenadas del coche): las
## puertas están en ±3,5 y miden 1,5 m.
const TRAMOS_PARED := [[-8.0, -4.25], [-2.75, 2.75], [4.25, 8.0]]
## Tramos de asientos (centro, largo) y paso entre asientos.
const TRAMOS_ASIENTO := [[-6.1, 3.3], [0.0, 5.0], [6.1, 3.3]]
const PASO_ASIENTO := 0.55
const ALTO_ASIENTO := 0.47   ## altura del cojín sobre el suelo del coche
## Anuncios del vagón (marcas inventadas).
const ANUNCIOS := [
	"LECHE LA PRADERA\nfresca cada mañana", "MUSEO DEL FÚTBOL\nabierto todos los días",
	"BANCO HORIZONTE\ntu primera cuenta", "ZAPATILLAS VELOZ\ncorre más lejos",
	"FESTIVAL DEL RÍO\nmúsica en la ribera", "PANADERÍA EL TRIGAL\npan de leña",
	"ESCUELA DE IDIOMAS\naprende en 3 meses", "CINE AURORA\nestrenos los viernes",
	"SEGUROS LA BRÚJULA\nviaja tranquilo", "AGUA MANANTIAL\nde la sierra",
]
const COLORES_ANUNCIO := [Color(0.85, 0.25, 0.2), Color(0.15, 0.45, 0.75), Color(0.95, 0.7, 0.15),
	Color(0.2, 0.6, 0.35), Color(0.55, 0.25, 0.6), Color(0.1, 0.12, 0.18)]

static var _mallas_interior := {}
static var _mat_int: StandardMaterial3D

# ---------------------------------------------------------------- dibujo

func _mat(c: Color, rug := 0.6, emi := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	if emi > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emi
	return m

func _caja(padre: Node3D, pos: Vector3, tam: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	padre.add_child(mi)
	return mi

func _viaducto(a: Vector3, b: Vector3, col: Color) -> void:
	var hormigon := _mat(Color(0.72, 0.71, 0.68), 0.8)
	var largo := a.distance_to(b)
	var m := (a + b) * 0.5
	var vertical := absf(a.x - b.x) < 0.1
	_caja(self, m + Vector3(0, ALTO_VIADUCTO, 0), Vector3(7.0, 1.2, largo) if vertical else Vector3(largo, 1.2, 7.0), hormigon)
	for lado: float in [-1.0, 1.0]:
		var off := Vector3(lado * 3.4, 0, 0) if vertical else Vector3(0, 0, lado * 3.4)
		_caja(self, m + off + Vector3(0, ALTO_VIADUCTO + 1.0, 0), Vector3(0.3, 1.0, largo) if vertical else Vector3(largo, 1.0, 0.3), _mat(col, 0.5))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.2
	cm.height = ALTO_VIADUCTO
	mm.mesh = cm
	var n := int(largo / 30.0)
	mm.instance_count = n
	for k in n:
		var p := a.lerp(b, (float(k) + 0.5) / float(n))
		mm.set_instance_transform(k, Transform3D(Basis(), p + Vector3(0, ALTO_VIADUCTO * 0.5, 0)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = hormigon
	add_child(mi)

## El túnel en rayos X: un tubo translúcido que se ve a través del suelo.
func _tunel_xray(a: Vector3, b: Vector3, col: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r * 1.3, col.g * 1.3, col.b * 1.3, 0.6)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var largo := a.distance_to(b)
	var vertical := absf(a.x - b.x) < 0.1
	_caja(_xray, (a + b) * 0.5 + Vector3(0, 0.6, 0), Vector3(10.0, 0.4, largo) if vertical else Vector3(largo, 0.4, 10.0), m)

## El túnel de la línea subterránea: cerrado (suelo, paredes, techo) para que
## desde dentro no se vea el cielo, con luces cada 30 m. Se corta en las
## estaciones, que tienen su propio vestíbulo.
func _tunel(a: Vector3, b: Vector3, estaciones: Array, dir: Vector3) -> void:
	var muro := _mat(Color(0.32, 0.32, 0.34), 0.95)
	var luz := _mat(Color(1.0, 0.92, 0.7), 0.4, 2.0)
	var vertical := absf(dir.z) > 0.5
	var lat := Vector3(1, 0, 0) if vertical else Vector3(0, 0, 1)
	var cortes: Array = [0.0]
	for p: Vector3 in estaciones:
		var s := a.distance_to(p)
		cortes.append(s - ANDEN_LARGO * 0.5 - 2.0)
		cortes.append(s + ANDEN_LARGO * 0.5 + 2.0)
	cortes.append(a.distance_to(b))
	var luces: Array[Transform3D] = []
	for k in range(0, cortes.size() - 1, 2):
		var s0 := float(cortes[k])
		var s1 := float(cortes[k + 1])
		if s1 - s0 < 1.0:
			continue
		var c := a + dir * (s0 + s1) * 0.5
		var largo := s1 - s0
		var y := PROF_TUNEL
		_caja(self, c + Vector3(0, y - 0.3, 0), (Vector3(8.0, 0.6, largo) if vertical else Vector3(largo, 0.6, 8.0)), muro)
		_caja(self, c + Vector3(0, y + 5.5, 0), (Vector3(8.0, 0.6, largo) if vertical else Vector3(largo, 0.6, 8.0)), muro)
		for lado: float in [-1.0, 1.0]:
			_caja(self, c + lat * lado * 3.8 + Vector3(0, y + 2.6, 0), (Vector3(0.4, 5.6, largo) if vertical else Vector3(largo, 5.6, 0.4)), muro)
		var n := int(largo / 30.0)
		for q in n:
			var pl := a + dir * (s0 + (float(q) + 0.5) * largo / float(maxi(n, 1)))
			luces.append(Transform3D(Basis.from_scale(Vector3(0.4, 0.15, 1.6) if vertical else Vector3(1.6, 0.15, 0.4)), pl + lat * 3.4 + Vector3(0, y + 4.6, 0)))
	if not luces.is_empty():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = BoxMesh.new()
		mm.instance_count = luces.size()
		for i in luces.size():
			mm.set_instance_transform(i, luces[i])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = luz
		add_child(mi)

## Estación elevada: DOS andenes laterales (la vía va por el medio), marquesina,
## pasarelas a las aceras y escaleras paralelas a la avenida.
func _estacion_elevada(p: Vector3, dir: Vector3, col: Color, nombre: String, linea_n: String, idx: int) -> void:
	var vertical := absf(dir.z) > 0.5
	var lat := Vector3(1, 0, 0) if vertical else Vector3(0, 0, 1)
	var lon := Vector3(0, 0, 1) if vertical else Vector3(1, 0, 0)
	var suelo := ALTO_VIADUCTO + 0.6 + PISO_COCHE
	## Gris de baldosa: con 0,8 el andén al sol salía blanco quemado (etapa 1).
	var losa: StandardMaterial3D = Texturas.hormigon(Color(0.6, 0.59, 0.56), 41)
	var borde := _mat(Color(0.95, 0.8, 0.1), 0.5)
	for lado: float in [-1.0, 1.0]:
		var c := p + lat * lado * ANDEN_LAT
		_caja(self, c + Vector3(0, suelo - 0.5, 0), (Vector3(ANDEN_ANCHO, 1.0, ANDEN_LARGO) if vertical else Vector3(ANDEN_LARGO, 1.0, ANDEN_ANCHO)), losa)
		## Franja amarilla del borde del andén.
		_caja(self, c - lat * lado * (ANDEN_ANCHO * 0.5 - 0.25) + Vector3(0, suelo + 0.01, 0), (Vector3(0.4, 0.02, ANDEN_LARGO) if vertical else Vector3(ANDEN_LARGO, 0.02, 0.4)), borde)
		## Los bancos, papeleras y máquinas los pone `_amueblar_anden` (kit de Kenney).
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.7, 0.85, 0.95, 0.4)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_caja(self, p + Vector3(0, suelo + 4.5, 0), Vector3(16.0, 0.3, ANDEN_LARGO) if vertical else Vector3(ANDEN_LARGO, 0.3, 16.0), vidrio)
	for k in 4:
		for lado: float in [-1.0, 1.0]:
			var f := (float(k) / 3.0 - 0.5) * (ANDEN_LARGO - 6.0)
			_caja(self, p + lat * lado * 5.8 + lon * f + Vector3(0, suelo + 2.2, 0), Vector3(0.4, 4.6, 0.4), _mat(col, 0.5))
	## Accesos: pasarela por encima de los carriles hasta la acera y escalera
	## bajando PARALELA a la avenida (no se mete en las manzanas).
	var gris := _mat(Color(0.6, 0.6, 0.62), 0.6)
	var baranda := _mat(col, 0.5)
	var subida := 22.0
	var alto := suelo
	for lado2: float in [-1.0, 1.0]:
		var x_acera := CiudadExpansion.ANCHO_AV * 0.5 + 2.0
		var z0 := ANDEN_LARGO * 0.5 - 2.0
		var x0 := ANDEN_LAT + ANDEN_ANCHO * 0.5
		var pas_c := p + lat * lado2 * (x0 + x_acera) * 0.5 + lon * z0 + Vector3(0, alto - 0.2, 0)
		_caja(self, pas_c, (Vector3(x_acera - x0 + 1.5, 0.4, 3.0) if vertical else Vector3(3.0, 0.4, x_acera - x0 + 1.5)), gris)
		var largo_e := sqrt(subida * subida + alto * alto)
		var esc_c := p + lat * lado2 * x_acera + lon * (z0 + 1.5 + subida * 0.5) + Vector3(0, alto * 0.5, 0)
		var esc := _caja(self, esc_c, Vector3(3.0, 0.4, largo_e) if vertical else Vector3(largo_e, 0.4, 3.0), gris)
		var ang := atan2(alto, subida)
		if vertical:
			esc.rotation.x = ang
		else:
			esc.rotation.z = -ang
		for lb: float in [-1.6, 1.6]:
			var bar := _caja(self, esc_c + lat * lb + Vector3(0, 1.0, 0), Vector3(0.1, 0.1, largo_e) if vertical else Vector3(largo_e, 0.1, 0.1), baranda)
			bar.rotation = esc.rotation
		var pie := p + lat * lado2 * x_acera + lon * (z0 + 1.5 + subida + 1.5)
		accesos.append({"pie": Vector3(pie.x, 0.0, pie.z), "anden": p + lat * lado2 * ANDEN_LAT + lon * (ANDEN_LARGO * 0.5 - 5.0) + Vector3(0, suelo, 0),
			"linea": linea_n, "idx": idx, "elevada": true, "nombre": nombre, "lado": lado2})
	var l := Label3D.new()
	l.text = "Ⓜ %s" % nombre
	l.font_size = 64
	l.pixel_size = 0.03
	l.modulate = Color.WHITE
	l.outline_size = 8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	## Por encima del panel del próximo tren (ALTO_VIADUCTO + 8,6): a +7,5 los
	## dos rótulos se pisaban.
	l.position = p + Vector3(0, suelo + 9.4, 0)
	add_child(l)

func a_s(_n: String, _i: int) -> float:
	return 0.0

## Estación subterránea: vestíbulo alicatado con el andén a un lado, bancos,
## carteles con el nombre, luces y el panel del próximo tren.
func _estacion_subterranea(p: Vector3, dir: Vector3, col: Color, nombre: String, linea_n: String, idx: int) -> void:
	var vertical := absf(dir.z) > 0.5
	var lat := Vector3(1, 0, 0) if vertical else Vector3(0, 0, 1)
	var lon := Vector3(0, 0, 1) if vertical else Vector3(1, 0, 0)
	var y := PROF_TUNEL
	var largo := ANDEN_LARGO + 4.0
	var ancho := 16.0
	var azulejo := _mat(Color(0.7, 0.72, 0.74), 0.5)
	var franja := _mat(col, 0.4, 0.3)
	var suelo_m := _mat(Color(0.45, 0.45, 0.47), 0.8)
	var c := p + lat * 2.0
	_caja(self, c + Vector3(0, y - 0.3, 0), (Vector3(ancho, 0.6, largo) if vertical else Vector3(largo, 0.6, ancho)), suelo_m)
	_caja(self, c + Vector3(0, y + 6.5, 0), (Vector3(ancho, 0.6, largo) if vertical else Vector3(largo, 0.6, ancho)), azulejo)
	for lado: float in [-1.0, 1.0]:
		var pared := c + lat * lado * ancho * 0.5 + Vector3(0, y + 3.1, 0)
		_caja(self, pared, (Vector3(0.4, 6.8, largo) if vertical else Vector3(largo, 6.8, 0.4)), azulejo)
		_caja(self, pared - lat * lado * 0.21 + Vector3(0, -1.2, 0), (Vector3(0.05, 0.6, largo) if vertical else Vector3(largo, 0.6, 0.05)), franja)
		var cart := Label3D.new()
		cart.text = "Ⓜ  %s" % nombre
		cart.font_size = 72
		cart.pixel_size = 0.02
		cart.modulate = Color.WHITE
		cart.outline_size = 6
		cart.outline_modulate = col.darkened(0.4)
		cart.position = pared - lat * lado * 0.3 + Vector3(0, 0.6, 0)
		cart.rotation.y = atan2(-lat.x * lado, -lat.z * lado)
		add_child(cart)
	for e: float in [-1.0, 1.0]:
		_caja(self, c + lon * e * largo * 0.5 + Vector3(0, y + 3.1, 0), (Vector3(ancho, 6.8, 0.4) if vertical else Vector3(0.4, 6.8, ancho)), azulejo)
	## El andén (lado +lateral), con su borde amarillo y bancos.
	var ca := p + lat * ANDEN_LAT * 1.6
	_caja(self, ca + Vector3(0, y + PISO_COCHE - 0.5, 0), (Vector3(ANDEN_ANCHO * 2.2, 1.0, ANDEN_LARGO) if vertical else Vector3(ANDEN_LARGO, 1.0, ANDEN_ANCHO * 2.2)), _mat(Color(0.56, 0.55, 0.52), 0.75))
	_caja(self, p + lat * (ANDEN_LAT * 1.6 - ANDEN_ANCHO * 1.1 + 0.25) + Vector3(0, y + PISO_COCHE + 0.01, 0), (Vector3(0.4, 0.02, ANDEN_LARGO) if vertical else Vector3(ANDEN_LARGO, 0.02, 0.4)), _mat(Color(0.95, 0.8, 0.1), 0.5))
	## Bancos y demás: `_amueblar_anden`.
	## Luces del vestíbulo: tiras y dos focos de verdad.
	for k in 4:
		_caja(self, c + lon * (float(k) - 1.5) * 15.0 + Vector3(0, y + 6.1, 0), Vector3(1.2, 0.1, 6.0) if vertical else Vector3(6.0, 0.1, 1.2), _mat(Color(1, 0.97, 0.9), 0.3, 2.5))
	for f: float in [-0.25, 0.25]:
		var o := OmniLight3D.new()
		o.omni_range = 30.0
		o.light_energy = 0.7
		o.position = c + lon * f * largo + Vector3(0, y + 5.0, 0)
		add_child(o)
	var panel := Label3D.new()
	panel.font_size = 32
	panel.pixel_size = 0.006
	panel.modulate = Color(1.0, 0.85, 0.3)
	panel.outline_size = 6
	panel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	panel.position = ca + lon * 12.0 + Vector3(0, y + PISO_COCHE + 2.6, 0)
	add_child(panel)
	_paneles.append({"label": panel, "linea_n": linea_n, "s": a_s(linea_n, idx), "pend": true})
