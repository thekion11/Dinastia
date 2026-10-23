class_name ExploradorCiudad
extends Node3D
## RECORRER LA CIUDAD (7-10-2026, pedido: «la ciudad debe ser real,
## interactiva… conducir, caminar, interactuar con NPC»). Dos modos:
##
##  · CONDUCIR: un coche del kit con conducción arcade (W/S o flechas para
##    acelerar y frenar, A/D para girar, o el mando). Choca con las manzanas y
##    con el río, y sube a los puentes por sus rampas.
##  · A PIE: un peatón animado del paquete Quaternius (W/A/S/D, Mayús para
##    correr). Puede entrar en parques y plazas, no atravesar edificios.
##
## En los dos: cámara de seguimiento detrás, «E» para HABLAR con el peatón
## más cercano (te dice algo según cómo va el club) o para ENTRAR en el lugar
## que tengas delante (instalaciones, estadio, Casa Grande, minijuegos de la
## ciudad), y «Esc» para volver al mapa. La lógica de colisión es pura
## (`libre`) para poder probarla sin dibujar nada.

signal salir
signal interactuar(k: String)

const RADIO_COCHE := 2.2
const RADIO_PIE := 0.5
const VEL_COCHE := 26.0
const VEL_PIE := 1.7
const VEL_CORRER := 5.0
const LIMITE := 1480.0

var modo := "coche"
var cb: CityBuilder
var trafico: TraficoCiudad
var club_nombre := ""
var animo := "normal"
var cuerpo: Node3D
var camara: Camera3D
var rumbo := 0.0        ## ángulo en Y (0 = mirando a +Z)
var vel := 0.0
var obstaculos: Array[Rect2] = []
## Captura el cursor en primera persona (para mirar con el ratón) y lo suelta fuera.
func _raton_en_primera_persona() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if primera_persona and DisplayServer.get_name() != "headless" else Input.MOUSE_MODE_VISIBLE

## Visión en primera persona (tecla V).
var primera_persona := false
func _sentado_fp() -> bool:
	return _sentado

var _vel_pie := 0.0   ## velocidad a pie dentro del estadio, sin la cinta rodante
var _anim: AnimationPlayer
var _hud: Label
var _aviso: Label
var _cerca := {}        ## lo que hay delante para la E: {tipo, k, n, peaton}
var _burbuja: Label3D
var _t_burbuja := 0.0
var _cuadro: CuadroDialogo
var _hablando_con: Node3D
var _int_cerca: Dictionary = {}   ## alguien de la sala a mano para charlar
var _t_gesto_propio := 0.0   ## mientras tu personaje gesticula, no se le cambia el clip
var _t_gente := -1000.0   ## < -100: aún no se llenó el entorno
## Nombres de pila ficticios para los vecinos.
const NOMBRES_M := ["Marta", "Lucía", "Carmen", "Elena", "Paula", "Rosa", "Inés", "Julia", "Nuria", "Teresa", "Alba", "Sara"]
const NOMBRES_H := ["Andrés", "Manolo", "Jorge", "Ramón", "Pablo", "Luis", "Tomás", "Iván", "Héctor", "Ernesto", "Óscar", "Félix"]

## EL METRO A PIE (7-10-2026, «que nuestro personaje lo pueda usar… y por
## dentro»): `estado` es "calle", "anden" o "tren".
var estado := "calle"
var metro: MetroCiudad
var _acc: Dictionary = {}       ## el acceso por el que se entró
var _linea := ""
var _idx := -1
var _anden_c := Vector3.ZERO    ## centro del andén
var _anden_lat := Vector3.ZERO
var _anden_lon := Vector3.ZERO
var _anden_medio := Vector2.ZERO   ## medio ancho (lat) y medio largo (lon)
var _tren_k := -1
var _bajar_en_proxima := false
var _ventana := false
var _luz_cam: OmniLight3D
## ESTADIO INTERACTIVO 2.0 (fase 1): el estadio de la ciudad se recorre por
## dentro sin salir del mundo. `_est` son los datos de `TunelVestuario.datos()`
## (en coordenadas del estadio, que está en `CityBuilder.ESTADIO_EN`).
var _est: Dictionary = {}
var _zona_est := ""
var _aviso_hablar := false
var _planta := 0
var _menu_asc: PanelContainer
var _sentado := false
var _hinchas_quitados: Array = []
var _de_pie := Vector3.ZERO
var _mirada := 0.0
var _t_sacudida := 0.0

const FRASES := {
	"euforia": ["¡Campeones! ¡Esta ciudad es de %s!", "No me lo creo todavía… ¡qué temporada!", "Mi abuelo lloró con el último gol. Gracias, míster."],
	"bien": ["Vamos bien, míster. Que no se nos suba.", "El sábado voy con mis hijos al estadio.", "Ese chico de la cantera va a ser crack."],
	"normal": ["Ni fu ni fa. A ver si fichamos a alguien.", "¿Usted es el entrenador de %s? ¡Una foto!", "El tráfico los días de partido es un horror."],
	"mal": ["Así no, míster. Así no.", "Mi cuñado dice que lo van a echar…", "Hay que meter más carácter."],
	"crisis": ["¡Fuera! Bueno… perdón, es la rabia.", "Esto es una vergüenza para %s.", "Ni regalando entradas se llena el estadio."],
}

func iniciar(builder: CityBuilder, modo_: String, desde: Vector3, club: String, estado_animo: String) -> void:
	cb = builder
	modo = modo_
	club_nombre = club
	animo = estado_animo
	trafico = cb.get_node_or_null("Trafico") as TraficoCiudad
	metro = cb.expansion.metro if cb.expansion != null else null
	obstaculos = construir_obstaculos(cb)
	_indexar_obstaculos()
	_indexar_circulos()
	var perfil: Dictionary = cb.datos.get("perfil_estadio", {})
	if not perfil.is_empty():
		var aforo := int(perfil.get("aforo", 20000))
		_est = TunelVestuario.datos(perfil, StadiumBuilder.niveles_de(perfil, aforo))
		## La galería subterránea al complejo (fase 6) solo existe aquí.
		_est["zonas"] = GaleriaClub.zonas(_est) + (_est["zonas"] as Array)
	position = Vector3.ZERO
	cuerpo = _crear_cuerpo()
	if trafico != null:
		trafico.jugador = cuerpo
	add_child(cuerpo)
	cuerpo.position = buscar_libre(desde)
	camara = Camera3D.new()
	camara.fov = 65.0
	camara.far = 5000.0
	add_child(camara)
	camara.make_current()
	_luz_cam = OmniLight3D.new()
	_luz_cam.omni_range = 12.0
	_luz_cam.light_energy = 0.45
	_luz_cam.visible = false
	camara.add_child(_luz_cam)
	_burbuja = Label3D.new()
	_burbuja.font_size = 40
	_burbuja.pixel_size = 0.012
	_burbuja.outline_size = 8
	_burbuja.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_burbuja.visible = false
	add_child(_burbuja)
	_montar_hud()
	_colocar_camara(1.0)
	_rotulos_de_paseo(true)

## A pie o en coche, los rótulos del mapa (pensados para la vista aérea) se
## veían a kilómetros y a través de los edificios: aquí solo los cercanos y
## tapados por lo que haya delante (etapa 1, 8-10-2026).
func _rotulos_de_paseo(si: bool) -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("rotulo_mapa"):
		var l := n as Label3D
		if l == null:
			continue
		l.visibility_range_end = (60.0 if modo == "pie" else 140.0) if si else 0.0
		l.no_depth_test = not si

## Las huellas sólidas: manzanas edificadas, edificios del núcleo e
## instalaciones (todo lo que `CityBuilder` apunta en `_frentes`).
static func construir_obstaculos(b: CityBuilder) -> Array[Rect2]:
	var sal: Array[Rect2] = []
	for r: Rect2 in b._frentes:
		sal.append(r)
	for r2: Rect2 in b.huellas:
		sal.append(r2)
	return sal

## ¿Puede estar aquí algo de este radio? (manzanas, río sin puente, límites).
static func libre(p: Vector3, radio: float, obst: Array[Rect2]) -> bool:
	if absf(p.x) > LIMITE or absf(p.z) > LIMITE:
		return false
	if en_rio(p.x, p.z) and not en_puente(p.x, p.z):
		return false
	for r: Rect2 in obst:
		if p.x > r.position.x - radio and p.x < r.end.x + radio and p.z > r.position.y - radio and p.z < r.end.y + radio:
			return false
	return true

## Las huellas de las manzanas, también por celdas (15-10-2026): `libre` las
## recorría TODAS en cada consulta (~190 µs) y el paseo hace de 3 a 20 consultas
## por fotograma (moverse, deslizar, la cámara que no atraviesa paredes). Cada
## huella se apunta en las celdas que toca, ensanchada `MARGEN_OBST` para que
## baste mirar la celda del punto (radios de hasta 3 m: pie 0,5, coche 2,2).
const CELDA_OBST := 32.0
const MARGEN_OBST := 3.0
var _rej_obst := {}
var _t_cerca := 0.0
var _moviles_fotograma := -1
var _moviles_cerca := PackedVector3Array()
var _p_cerca := Vector3.INF

func _indexar_obstaculos() -> void:
	_rej_obst.clear()
	for r: Rect2 in obstaculos:
		var a := r.grow(MARGEN_OBST)
		for i in range(floori(a.position.x / CELDA_OBST), floori(a.end.x / CELDA_OBST) + 1):
			for j in range(floori(a.position.y / CELDA_OBST), floori(a.end.y / CELDA_OBST) + 1):
				var k := Vector2i(i, j)
				if not _rej_obst.has(k):
					_rej_obst[k] = [] as Array[Rect2]
				(_rej_obst[k] as Array[Rect2]).append(r)

## Igual que `libre(p, radio, obstaculos)`, pero mirando solo la celda de `p`.
func libre_obst(p: Vector3, radio: float) -> bool:
	if radio > MARGEN_OBST:
		return libre(p, radio, obstaculos)
	var celda: Array[Rect2] = _rej_obst.get(Vector2i(floori(p.x / CELDA_OBST), floori(p.z / CELDA_OBST)), [] as Array[Rect2])
	return libre(p, radio, celda)

## Círculos sólidos (farolas, troncos, coches aparcados...) por celdas de 8 m.
const CELDA_CIRC := 8.0
var _rej_circ := {}

func _indexar_circulos() -> void:
	_rej_circ.clear()
	if cb == null:
		return
	for c: Vector3 in cb.circulos:
		var k := Vector2i(floori(c.x / CELDA_CIRC), floori(c.y / CELDA_CIRC))
		if not _rej_circ.has(k):
			_rej_circ[k] = []
		(_rej_circ[k] as Array).append(c)

func _choca_circulos(p: Vector3, radio: float) -> bool:
	var cx := floori(p.x / CELDA_CIRC)
	var cz := floori(p.z / CELDA_CIRC)
	for i in range(cx - 1, cx + 2):
		for j in range(cz - 1, cz + 2):
			var lista: Array = _rej_circ.get(Vector2i(i, j), [])
			for c: Vector3 in lista:
				var dx := p.x - c.x
				var dz := p.z - c.y
				var rr := radio + c.z
				if dx * dx + dz * dz < rr * rr:
					return true
	return false

## Los que se mueven: coches y vecinos del tráfico.
func _choca_moviles(p: Vector3, radio: float) -> bool:
	if trafico == null:
		return false
	## Una vez por fotograma de física se apuntan los móviles a menos de 30 m del
	## personaje (x, z, radio); las 3-20 consultas del fotograma miran solo esos
	## (15-10-2026: antes cada consulta recorría los ~300 coches y vecinos y pedía
	## su `global_position`; el tráfico cuelga de la ciudad, que está en el origen).
	var f := Engine.get_physics_frames()
	if f != _moviles_fotograma:
		_moviles_fotograma = f
		_moviles_cerca.clear()
		var c := cuerpo.position if cuerpo != null else p
		for v: Dictionary in trafico._vehiculos:
			var n: Node3D = v["nodo"]
			if not is_instance_valid(n):
				continue
			var q := n.position
			if absf(q.x - c.x) < 30.0 and absf(q.z - c.z) < 30.0:
				_moviles_cerca.append(Vector3(q.x, q.z, 0.45 if float(v["alto"]) < 0.3 else 1.7))
	var c0 := cuerpo.position if cuerpo != null else p
	if absf(p.x - c0.x) > 25.0 or absf(p.z - c0.z) > 25.0:
		## Lejos del personaje (buscar un sitio libre al aparecer): todos.
		for v: Dictionary in trafico._vehiculos:
			var n: Node3D = v["nodo"]
			if is_instance_valid(n):
				var rr0 := radio + (0.45 if float(v["alto"]) < 0.3 else 1.7)
				if Vector2(n.position.x - p.x, n.position.z - p.z).length_squared() < rr0 * rr0:
					return true
		return false
	for m: Vector3 in _moviles_cerca:
		var dx := m.x - p.x
		var dz := m.y - p.z
		var rr := radio + m.z
		if dx * dx + dz * dz < rr * rr:
			return true
	return false

## Un trozo de movimiento con sus choques. Devuelve false si chocó de frente.
func _mover_un_trozo(paso: Vector3, r: float) -> bool:
	var pos := cuerpo.position
	## Si ya estás dentro de algo FIJO (al salir del metro, por ejemplo), se te
	## deja andar para salir. Si lo que tienes encima es un MÓVIL (un coche que
	## se te mete), se ignoran los móviles pero NO las paredes: antes, con un
	## coche encima, se podía entrar caminando en los edificios (17-10).
	var libre_fijo := func(q: Vector3) -> bool: return libre_obst(q, r) and not _choca_circulos(q, r)
	var dentro_fijo: bool = not libre_fijo.call(pos)
	var solo_movil: bool = not dentro_fijo and _choca_moviles(pos, r)
	var vale := func(q: Vector3) -> bool:
		if dentro_fijo:
			return true
		if solo_movil:
			return libre_fijo.call(q)
		return libre_total(q, r)
	if vale.call(pos + paso):
		cuerpo.position = Vector3(pos.x + paso.x, altura_suelo(pos.x + paso.x, pos.z + paso.z), pos.z + paso.z)
		return true
	if vale.call(pos + Vector3(paso.x, 0, 0)):
		## Choque en diagonal: se desliza por la pared en vez de pararse en seco.
		cuerpo.position = Vector3(pos.x + paso.x, altura_suelo(pos.x + paso.x, pos.z), pos.z)
		vel *= 0.92
		return true
	if vale.call(pos + Vector3(0, 0, paso.z)):
		cuerpo.position = Vector3(pos.x, altura_suelo(pos.x, pos.z + paso.z), pos.z + paso.z)
		vel *= 0.92
		return true
	if modo == "coche":
		_golpe_coche(absf(vel), not libre_fijo.call(pos + paso))
	vel *= -0.25 if modo == "coche" else 0.0
	return false

## EL CHOQUE SE NOTA (21-10-2026, M-172): antes el coche se quedaba quieto en
## silencio. Ahora, según la velocidad: el golpe de chapa, la sacudida de la
## cámara y del mando y, contra otro coche o una persona a más de 25 km/h, la
## multa (el móvil avisa y se apunta en `multas`). Un choque cada medio
## segundo como mucho (al rozar una pared no suena en bucle).
var multas := 0
var _t_golpe := 0.0
var _sacudida_golpe := 0.0
func _golpe_coche(v: float, contra_fijo: bool) -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	if v < 2.5 or ahora - _t_golpe < 0.5:
		return
	_t_golpe = ahora
	Sonido.toca("choque_coche")
	_sacudida_golpe = clampf(v / 18.0, 0.15, 1.0)
	Mando.vibrar(clampf(v / 20.0, 0.25, 1.0), 0.35)
	if not contra_fijo and v * 3.6 > 25.0:
		multas += 1
		Sonido.toca("claxon", Sonido.Bus.AMBIENTE)
		if _movil != null:
			_movil.notificar(Idiomas.t("🚓 Multa por conducción temeraria (%d)") % multas)

## Manzanas, río, círculos y móviles: todo lo que impide estar en `p`.
func libre_total(p: Vector3, radio: float) -> bool:
	return libre_obst(p, radio) and not _choca_circulos(p, radio) and not _choca_moviles(p, radio)

## Tipos de edificio con sala propia, con su peso y sus nombres.
const EDIFICIOS := [
	["edificio_vivienda", 40, ["Casa de la familia %s"], ["Ortega", "Salas", "Núñez", "Ibarra", "Campos", "Rivas", "Lagos", "Vidal", "Peña", "Soto"]],
	["edificio_bar", 15, ["Bar %s"], ["El Rincón", "La Esquina", "El Gol", "Los Amigos", "La Tertulia", "El Faro"]],
	["edificio_panaderia", 12, ["Panadería %s"], ["La Espiga", "Pan Nuestro", "El Horno", "Doña Rosa", "La Hogaza"]],
	["edificio_peluqueria", 9, ["Peluquería %s"], ["Estilo", "Corte Fino", "Tijeras", "Nuevo Look", "Mechones"]],
	["edificio_libreria", 8, ["Librería %s"], ["El Capítulo", "Página Uno", "La Tinta", "Letra Viva", "El Marcapáginas"]],
	["edificio_taller", 8, ["Taller %s"], ["Motor", "Hermanos Paz", "El Pistón", "AutoRepara", "Tuercas"]],
	["edificio_oficina", 8, ["Oficinas %s"], ["Delta", "Norte", "Grupo Álamo", "Cima", "Vértice"]],
]

## La sala de cada rótulo de comercio (`CiudadExpansion.COMERCIOS`): al entrar
## por una puerta con rótulo, lo de dentro tiene que ser lo que dice fuera
## (antes el rótulo y la sala se sorteaban por separado: una «Farmacia» podía
## abrir un taller).
const SALA_DE_ROTULO := {
	"Farmacia": "edificio_tienda", "Cafetería": "edificio_bar", "Panadería": "edificio_panaderia",
	"Banco": "edificio_oficina", "Correos": "edificio_oficina", "Peluquería": "edificio_peluqueria",
	"Librería": "edificio_libreria", "Supermercado": "edificio_mercado", "Pizzería": "edificio_bar",
	"Hotel": "edificio_oficina", "Deportes": "edificio_tienda", "Bar": "edificio_bar",
	"Floristería": "edificio_tienda", "Ferretería": "edificio_tienda", "Peña del club": "edificio_bar",
	"Heladería": "edificio_panaderia",
}

## El rótulo de comercio cuya fachada está junto a `p`, o vacío.
func _rotulo_en(p: Vector3) -> Dictionary:
	if cb == null or cb.expansion == null:
		return {}
	var mejor: Dictionary = {}
	var md := INF
	for r: Dictionary in cb.expansion.rotulos:
		var q: Vector3 = r["pos"]
		var d := Vector2(q.x - p.x, q.z - p.z).length()
		if d < float(r["ancho"]) * 0.5 + 2.5 and d < md:
			md = d
			mejor = r
	return mejor

## ¿Hay una fachada de manzana al alcance de este punto (3 m)? Devuelve la
## clave de la sala con el nombre propio, o vacío.
func edificio_en(p: Vector3) -> Dictionary:
	if cb == null:
		return {}
	## Entre casas no hay bares: las viviendas ya son sus propios lugares.
	for pc: Dictionary in cb.puntos_clic:
		if String(pc["k"]).begins_with("edificio_vivienda"):
			var q: Vector3 = pc["pos"]
			if Vector2(q.x - p.x, q.z - p.z).length() < 22.0:
				return {}
	for r: Rect2 in cb._frentes:
		var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
		var dz := maxf(maxf(r.position.y - p.z, 0.0), p.z - r.end.y)
		if dx * dx + dz * dz > 3.2 * 3.2:
			continue
		var rot := _rotulo_en(p)
		if not rot.is_empty():
			## «💊 Farmacia» -> «Farmacia»: el nombre sin el icono.
			var texto := String(rot["texto"])
			var nombre_r := texto.substr(texto.find(" ") + 1)
			if SALA_DE_ROTULO.has(nombre_r):
				return {"k": "%s|%s" % [SALA_DE_ROTULO[nombre_r], nombre_r], "n": nombre_r}
		var h := absi(hash(Vector3i(floori(p.x / 14.0), 0, floori(p.z / 14.0))) + hash(r.position))
		var total := 0
		for e: Array in EDIFICIOS:
			total += int(e[1])
		var tiro := h % total
		for e: Array in EDIFICIOS:
			tiro -= int(e[1])
			if tiro < 0:
				var nombres: Array = e[3]
				var nombre: String = String((e[2] as Array)[0]) % String(nombres[(h / 7) % nombres.size()])
				return {"k": "%s|%s" % [e[0], nombre], "n": nombre}
	return {}

static func en_rio(x: float, z: float) -> bool:
	return absf(x - CityBuilder.RIO_X) < 50.0 and absf(z) < 1360.0

## Sobre el tablero o las rampas de un puente (calles horizontales de la rejilla).
static func en_puente(x: float, z: float) -> bool:
	var linea := snappedf(z, CiudadExpansion.CELDA)
	return absf(z - linea) < CiudadExpansion.ANCHO_AV * 0.5 - 1.0 and absf(x - CityBuilder.RIO_X) < 66.0

## La altura del suelo (sube por las rampas de los puentes).
static func altura_suelo(x: float, z: float) -> float:
	if not en_puente(x, z):
		return 0.2
	var dx := absf(x - CityBuilder.RIO_X)
	if dx <= 44.0:
		return CiudadExpansion.PUENTE_ALTO + 0.3
	if dx >= 64.0:
		return 0.2
	return lerpf(CiudadExpansion.PUENTE_ALTO + 0.3, 0.2, (dx - 44.0) / 20.0)

func buscar_libre(desde: Vector3) -> Vector3:
	var r := RADIO_COCHE if modo == "coche" else RADIO_PIE
	for k in 400:
		var ang := float(k) * 0.7
		var d := float(k) * 2.0
		var p := desde + Vector3(cos(ang) * d, 0, sin(ang) * d)
		if libre_total(p, r):
			return Vector3(p.x, altura_suelo(p.x, p.z), p.z)
	return desde

func _crear_cuerpo() -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	if modo == "coche":
		var esc := load("res://assets/ciudad/kenney_cars/sedan-sports.glb") as PackedScene
		var raiz := Node3D.new()
		if esc != null:
			var c: Node3D = esc.instantiate()
			c.scale = Vector3.ONE * 1.65
			raiz.add_child(c)
		return raiz
	## TU PERSONAJE (estadio 2.0): el DT con el aspecto que elegiste, si hay.
	if not PersonajeDT.del_usuario.is_empty():
		var raiz := Node3D.new()
		add_child(raiz)
		var dt := PersonajeDT.crear(raiz, PersonajeDT.del_usuario, Color(0.12, 0.13, 0.16), Color(0.9, 0.9, 0.92))
		remove_child(raiz)
		if not dt.is_empty():
			_anim = dt.get("anim") as AnimationPlayer
			_es_dt = true
			## Parpadea y gesticula con los ojos (13-10-2026).
			Expresion.de.call_deferred(raiz)
			return raiz
		raiz.queue_free()
	var d := PeatonQ.crear(rng)
	if d.is_empty():
		return Node3D.new()
	var n: Node3D = d["nodo"]
	add_child(n)
	PeatonQ.terminar(d)
	remove_child(n)
	_anim = _buscar_anim(n)
	return n

var _es_dt := false

## Con el cuerpo del DT: «caminar» o «correr» al moverse y «parado» quieto.
## Pasos que suenan al andar a pie (etapa 1): uno cada ~0,7 m caminando y
## cada ~1,1 m corriendo.
var _hasta_paso := 0.0

func _sonar_pasos(v: float) -> void:
	if modo != "pie" or absf(v) < 0.3:
		return
	_hasta_paso -= absf(v) * get_physics_process_delta_time()
	if _hasta_paso <= 0.0:
		_hasta_paso = 1.1 if absf(v) > 3.0 else 0.7
		Sonido.toca("paso", Sonido.Bus.EFECTOS)

## MI CAMINATA (14-10-2026): estilo elegido en ⚙ Ajustes de la ciudad. Cada uno
## es [clip, velocidad de reproducción]. Correr y quieto no cambian.
const ESTILOS_CAMINATA := {
	"formal": ["caminar", 1.0],
	"normal": ["caminar_normal", 1.0],
	"animado": ["caminar_normal", 1.3],
	"cansado": ["caminar", 0.72],
	"agachado": ["caminar_agachado", 1.0],
	"trote": ["caminar_trote", 1.0],
}
static func estilo_caminata() -> String:
	return String(AjustesCiudad.valor("caminata", "formal"))

func _animar_dt(v: float) -> void:
	_sonar_pasos(v)
	if not _es_dt or _anim == null:
		return
	## Un gesto en curso (al charlar) no se corta mientras estés quieto.
	if _t_gesto_propio > 0.0:
		_t_gesto_propio -= get_physics_process_delta_time()
		if absf(v) < 0.05:
			return
		_t_gesto_propio = 0.0
	var quiere := "parado"
	if absf(v) > 3.0 and _anim.has_animation("correr"):
		quiere = "correr"
	var vel_anim := 1.0
	if quiere == "parado" and absf(v) > 0.05 and _anim.has_animation("caminar"):
		var est: Array = ESTILOS_CAMINATA.get(estilo_caminata(), ESTILOS_CAMINATA["formal"])
		quiere = String(est[0]) if _anim.has_animation(String(est[0])) else "caminar"
		vel_anim = float(est[1])
	if _anim.current_animation != quiere and _anim.has_animation(quiere):
		_anim.play(quiere, 0.25)
	_anim.speed_scale = vel_anim

func _buscar_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for h in n.get_children():
		var a := _buscar_anim(h)
		if a != null:
			return a
	return null

var _capa: CanvasLayer

## Pausa el paseo (minijuego abierto): sin moverse, sin cartel, sin teclas.
func pausar(si: bool) -> void:
	set_physics_process(not si)
	set_process_unhandled_input(not si)
	if _capa != null:
		_capa.visible = not si

func _montar_hud() -> void:
	var capa := CanvasLayer.new()
	_capa = capa
	add_child(capa)
	_hud = Label.new()
	_hud.position = Vector2(18, 14)
	_hud.add_theme_font_size_override("font_size", 16)
	_hud.add_theme_color_override("font_color", Color.WHITE)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 6)
	capa.add_child(_hud)
	_aviso = Label.new()
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.offset_top = -90
	_aviso.offset_left = -300
	_aviso.offset_right = 300
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 20)
	_aviso.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	_aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override("outline_size", 8)
	capa.add_child(_aviso)
	_tactil(capa)
	## Sin textos fijos en pantalla (13-10-2026): los controles van en ⚙ y en el
	## tutorial de la ciudad; la velocidad, en el móvil que sacas al correr.
	_movil = MovilMano.new()
	capa.add_child(_movil)
	_minimapa = MinimapaCiudad.new()
	capa.add_child(_minimapa)
	if DisplayServer.is_touchscreen_available():
		_minimapa.arriba()
	var engranaje := CuadroDialogo.respuesta(Button.new())
	engranaje.text = "⚙"
	engranaje.add_theme_font_size_override("font_size", 22)
	engranaje.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	engranaje.offset_left = -70
	engranaje.offset_top = 16
	engranaje.offset_right = -18
	engranaje.offset_bottom = 62
	engranaje.pressed.connect(func() -> void:
		if capa.get_node_or_null("AjustesCiudad") == null:
			var a := AjustesCiudad.crear(_aplicar_ajustes)
			a.name = "AjustesCiudad"
			capa.add_child(a))
	capa.add_child(engranaje)
	_aplicar_ajustes()
	if not bool(AjustesCiudad.valor("tutorial_visto", false)):
		capa.add_child.call_deferred(AjustesCiudad.TutorialCiudad.new())

var _movil: MovilMano
var _boton_e: Button
var _ayudas := false
var _con_movil := true
var _m_antes := false
var _gps_oculto := false
var _minimapa: MinimapaCiudad

func _aplicar_ajustes() -> void:
	_ayudas = bool(AjustesCiudad.valor("ayudas", false))
	_con_movil = bool(AjustesCiudad.valor("movil", true))
	_hud.visible = _ayudas
	_aviso.visible = _ayudas

## El móvil en la mano y el botón E que brilla si hay algo cerca.
func _actualizar_mano(modo_mano: String, km_h: float, maxima: float, metros: float) -> void:
	if _movil != null:
		var calle := ""
		if cb != null and cb.expansion != null and estado == "calle":
			calle = cb.expansion.nombre_calle_en(cuerpo.position)
		_movil.poner(modo_mano if _con_movil else "pie", km_h, maxima, calle, metros)
	## EL GPS ESTILO GTA (17-10-2026): M lo esconde o lo vuelve a mostrar.
	if _minimapa != null:
		if Input.is_physical_key_pressed(KEY_M) != _m_antes:
			_m_antes = not _m_antes
			if _m_antes:
				_gps_oculto = not _gps_oculto
		_minimapa.visible = estado == "calle" and not _gps_oculto
		if _minimapa.visible:
			if _minimapa.red == null and cb != null:
				_minimapa.red = cb.expansion
			_minimapa.poner(cuerpo.position, rumbo if modo == "coche" else cuerpo.rotation.y, get_physics_process_delta_time())
	## Las paredes de oclusión, solo en la calle: dentro de un edificio taparían
	## lo que se ve por la puerta (`OclusoresCiudad`).
	if cb != null:
		OclusoresCiudad.activar(cb, estado == "calle")
	if _boton_e != null:
		var hay := _aviso.text.strip_edges() != ""
		_boton_e.modulate = Color(1.0, 0.82, 0.3, 1.0) if hay else Color(1, 1, 1, 0.55)
		_boton_e.visible = hay or es_tactil()
		_boton_e.tooltip_text = _aviso.text

## CONTROLES TÁCTILES (el juego también va en Android): cruceta abajo a la
## izquierda, «E» y «Salir» abajo a la derecha. Mantener pulsado = tecla.
var _tactil_vec := Vector2.ZERO

## ¿Pantalla táctil? En PC (21-10-2026, vídeo de gameplay) la cruceta, la E y
## «Salir» tapaban la imagen: ahí se usan las teclas, y la E solo aparece,
## brillando, cuando hay algo con lo que interactuar.
static func es_tactil() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.get_environment("TACTIL") != ""

func _tactil(capa: CanvasLayer) -> void:
	var tam := 74.0
	var base := Control.new()
	base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	base.offset_left = 24
	base.offset_top = -tam * 3.0 - 24
	## Solo en pantallas táctiles (en PC ocupaba el rincón del GPS).
	base.visible = es_tactil()
	capa.add_child(base)
	for d: Array in [["▲", Vector2(1, 0), Vector2(0, 1)], ["▼", Vector2(1, 2), Vector2(0, -1)],
			["◀", Vector2(0, 1), Vector2(-1, 0)], ["▶", Vector2(2, 1), Vector2(1, 0)]]:
		var b := Button.new()
		b.text = String(d[0])
		b.position = (d[1] as Vector2) * tam
		b.size = Vector2(tam - 6, tam - 6)
		b.add_theme_font_size_override("font_size", 28)
		b.modulate = Color(1, 1, 1, 0.7)
		var v: Vector2 = d[2]
		b.button_down.connect(func() -> void: _tactil_vec += v)
		b.button_up.connect(func() -> void: _tactil_vec -= v)
		base.add_child(b)
	var der := HBoxContainer.new()
	der.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	der.offset_left = -260
	der.offset_top = -100
	der.offset_right = -24
	der.offset_bottom = -24
	der.add_theme_constant_override("separation", 12)
	capa.add_child(der)
	var be := Button.new()
	be.text = "E"
	be.custom_minimum_size = Vector2(tam, tam)
	be.add_theme_font_size_override("font_size", 28)
	be.modulate = Color(1, 1, 1, 0.75)
	be.pressed.connect(_usar)
	der.add_child(be)
	_boton_e = be
	var bs := Button.new()
	bs.text = Idiomas.t("Salir")
	bs.custom_minimum_size = Vector2(tam * 1.6, tam)
	bs.modulate = Color(1, 1, 1, 0.75)
	bs.pressed.connect(func() -> void: salir.emit())
	bs.visible = es_tactil()
	der.add_child(bs)

func _entrada() -> Vector2:
	var x := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var y := float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
	var jx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var jy := -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(jx) > 0.2:
		x = jx
	if absf(jy) > 0.2:
		y = jy
	if _tactil_vec != Vector2.ZERO:
		x = clampf(_tactil_vec.x, -1.0, 1.0)
		y = clampf(_tactil_vec.y, -1.0, 1.0)
	return Vector2(x, y)

func _physics_process(delta: float) -> void:
	if cuerpo == null:
		return
	if estado in ["anden", "estadio", "interior", "puerta"]:
		_actualizar_mano("pie", 0.0, 1.0, 0.0)
	if estado == "anden":
		_mover_en_anden(delta)
		return
	if estado == "tren":
		_viajar(delta)
		return
	if estado == "estadio":
		_mover_en_estadio(delta)
		return
	if estado == "interior":
		_mover_en_interior(delta)
		return
	if estado == "puerta":
		_andar_solo(delta)
		return
	_cerrar_puerta_si_lejos()
	var e := _entrada()
	if modo == "coche":
		_conducir(e, delta)
	else:
		var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
		## Aceleración y frenada suaves: arrancar y parar no es instantáneo.
		var objetivo := (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
		vel = move_toward(vel, objetivo, (7.0 if absf(objetivo) > absf(vel) else 12.0) * delta)
		rumbo -= e.x * delta * 2.6
		if _es_dt:
			_animar_dt(vel)
		elif _anim != null:
			if _t_gesto_propio > 0.0 and absf(vel) < 0.05:
				_t_gesto_propio -= delta
			else:
				if _t_gesto_propio > 0.0 and _anim.has_animation("caminar"):
					_anim.play("caminar")
				_t_gesto_propio = 0.0
				_anim.speed_scale = absf(vel) / 1.4 if absf(vel) > 0.05 else 0.0
			_sonar_pasos(vel)
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var r := RADIO_COCHE if modo == "coche" else RADIO_PIE
	## En pasos de 30 cm como mucho (17-10, caza de bugs): con un tirón de
	## fotogramas el coche avanzaba metros de golpe y se saltaba vallas finas.
	var paso_total := adelante * vel * delta
	var trozos := maxi(1, ceili(paso_total.length() / 0.3))
	for _k in trozos:
		if not _mover_un_trozo(paso_total / float(trozos), r):
			break
	cuerpo.rotation.y = rumbo
	if modo == "coche":
		cuerpo.rotation.x = _cabeceo
		cuerpo.rotation.z = _balanceo
	_colocar_camara(delta)
	## Qué hay cerca (puertas, metro, vecinos, fachadas): ~370 µs por búsqueda;
	## basta unas 8 veces por segundo o al dar medio metro (15-10-2026).
	_t_cerca -= delta
	if _t_cerca <= 0.0 or cuerpo.position.distance_squared_to(_p_cerca) > 0.25:
		_t_cerca = 0.12
		_p_cerca = cuerpo.position
		_buscar_cerca()
	## Gente alrededor: los peatones lejanos reaparecen cerca (a la espalda).
	_t_gente -= delta
	if _t_gente <= 0.0 and trafico != null and estado == "calle":
		var mira := -camara.global_transform.basis.z
		## La primera vez (al empezar a pasear) se llena el entorno de golpe.
		## Cuánta gente alrededor: menos en calidad media o con el motor ligero.
		var max_gente := 18 if (Calidad.motor_ligero or Calidad.elegida == Calidad.MEDIO) else 34
		trafico.reciclar_peatones(cuerpo.position, mira, 95.0, max_gente if _t_gente < -100.0 else 3, max_gente, _t_gente < -100.0)
		_t_gente = 1.2
	var corriendo := modo != "coche" and absf(vel) > VEL_PIE * 1.15
	_actualizar_mano("coche" if modo == "coche" else ("correr" if corriendo else "pie"), absf(vel) * 3.6,
		VEL_COCHE * 3.6 if modo == "coche" else VEL_CORRER * 3.6, absf(vel) * delta)
	_hud.text = (Idiomas.t("🚗 Conduciendo") if modo == "coche" else Idiomas.t("🚶 A pie")) + Idiomas.t("  ·  %d km/h  ·  W/S/A/D o mando · %sE: interactuar · Esc: volver al mapa") % [
		int(absf(vel) * 3.6), "" if modo == "coche" else Idiomas.t("Mayús: correr · V: vista · ")]
	## Dónde estás: el nombre de la calle (o el cruce).
	if cb != null and cb.expansion != null:
		var calle := cb.expansion.nombre_calle_en(cuerpo.position)
		if calle != "":
			_hud.text = "📍 %s\n%s" % [calle, _hud.text]
	if _t_burbuja > 0.0:
		_t_burbuja -= delta
		if _t_burbuja <= 0.0:
			_burbuja.visible = false
			if _cuadro != null:
				_cuadro.cerrar()

## CONDUCCIÓN (14-10-2026, «conducción mejorada»): la potencia cae al acercarse a
## la punta (curva en vez de una rampa), S frena fuerte si vas hacia delante y
## marcha atrás si ya estás parado, ESPACIO es el freno de mano (frena y deja el
## coche girar más cerrado, como al derrapar), el volante se mueve suave y la
## carrocería se inclina en curvas y al acelerar o frenar.
var _volante := 0.0
var _ui_volante: Control
var _cabeceo := 0.0
var _balanceo := 0.0
var cam_coche := 0     ## 0 tercera persona, 1 capó, 2 interior

## El motor del coche suena con sus revoluciones y marchas (M-173).
var _motor_sonido: MotorCocheSonido

func _conducir(e: Vector2, delta: float) -> void:
	if _motor_sonido == null:
		_motor_sonido = MotorCocheSonido.new()
		add_child(_motor_sonido)
	_motor_sonido.poner(vel, maxf(e.y, 0.0))
	var freno_mano := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(0, JOY_BUTTON_B)
	_volante = lerpf(_volante, e.x, clampf(delta * 6.0, 0.0, 1.0))
	if e.y > 0.0:
		var potencia := 15.0 * (1.0 - clampf(maxf(vel, 0.0) / VEL_COCHE, 0.0, 1.0) * 0.82) + 2.0
		vel = clampf(vel + e.y * potencia * delta, -8.0, VEL_COCHE)
	elif e.y < 0.0:
		if vel > 0.5:
			vel = maxf(vel - 24.0 * absf(e.y) * delta, 0.0)
		else:
			vel = clampf(vel + e.y * 7.0 * delta, -8.0, VEL_COCHE)
	else:
		vel = move_toward(vel, 0.0, (4.0 + absf(vel) * 0.12) * delta)
	if freno_mano:
		vel = move_toward(vel, 0.0, 20.0 * delta)
	var giro := 1.9 * (1.6 if freno_mano and absf(vel) > 4.0 else 1.0)
	## A más velocidad el volante gira menos (no se vuelca a 90 km/h).
	var cierre := clampf(absf(vel) / 8.0, 0.0, 1.0) * (1.0 - clampf(absf(vel) / VEL_COCHE, 0.0, 1.0) * 0.45)
	rumbo -= _volante * delta * giro * cierre * signf(vel if vel != 0.0 else 1.0)
	var acel_real := e.y if absf(vel) < VEL_COCHE else 0.0
	_cabeceo = lerpf(_cabeceo, clampf(-acel_real * 0.035 - (0.03 if freno_mano else 0.0), -0.06, 0.06), clampf(delta * 4.0, 0.0, 1.0))
	_balanceo = lerpf(_balanceo, clampf(_volante * absf(vel) * 0.0035, -0.07, 0.07), clampf(delta * 5.0, 0.0, 1.0))

## El salpicadero y el volante (solo en la cámara interior): dibujos 2D sobre la
## pantalla; el volante gira con la dirección.
func _volante_ui(ver: bool = true) -> void:
	var quiero := ver and modo == "coche" and cam_coche == 2
	if not quiero:
		if _ui_volante != null:
			_ui_volante.visible = false
		return
	if _ui_volante == null:
		_ui_volante = VolanteUI.new()
		_ui_volante.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui_volante.set_anchors_preset(Control.PRESET_FULL_RECT)
		_capa.add_child(_ui_volante)
		_ui_volante.move_to_front()
	_ui_volante.visible = true
	_ui_volante.set("giro", _volante)
	_ui_volante.set("kmh", absf(vel) * 3.6)
	_ui_volante.queue_redraw()

var _cam_yaw := 0.0
var _t_cabina := 0.0
var _cabina: Node3D
var _cabina_volante: Node3D
var _cabina_kmh: Label3D
## Los brazos del conductor (17-10-2026): las manos van en el aro a las diez y
## diez y giran con él; el antebrazo va del hombro a la mano.
var _cabina_manos: Array[MeshInstance3D] = []
var _cabina_brazos: Array[MeshInstance3D] = []
const _MANO_EN_ARO := [Vector3(-0.156, 0.02, -0.09), Vector3(0.156, 0.02, -0.09)]
const _HOMBRO := [Vector3(-0.3, -0.42, 0.1), Vector3(0.3, -0.42, 0.1)]

func _fov_hacia(f: float, delta: float) -> void:
	camara.fov = lerpf(camara.fov, f, clampf(delta * 3.0, 0.0, 1.0)) if delta < 1.0 else f

## La cabina del coche en primera persona: piezas sencillas hijas de la cámara.
func _cabina_3d(ver: bool) -> void:
	if not ver:
		if _cabina != null:
			_cabina.visible = false
		return
	if _cabina == null:
		_cabina = Node3D.new()
		_cabina.name = "Cabina"
		camara.add_child(_cabina)
		var oscuro := StandardMaterial3D.new()
		oscuro.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		oscuro.albedo_color = Color(0.2, 0.21, 0.23)
		oscuro.roughness = 0.85
		var gris := StandardMaterial3D.new()
		gris.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gris.albedo_color = Color(0.36, 0.37, 0.4)
		gris.roughness = 0.6
		var piel := StandardMaterial3D.new()
		piel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		piel.albedo_color = Color(0.07, 0.07, 0.08)
		piel.roughness = 0.5
		## Medidas desde los ojos (x a la derecha, y arriba, -z adelante): el
		## conductor va 0,34 m a la izquierda del centro, el coche mide 1,8 m.
		## El salpicadero: su borde de arriba queda 17 cm bajo los ojos.
		_caja_cabina(Vector3(1.8, 0.3, 0.6), Vector3(0.34, -0.32, -0.88), Vector3.ZERO, oscuro)
		_caja_cabina(Vector3(0.34, 0.2, 0.5), Vector3(0.34, -0.42, -0.5), Vector3.ZERO, gris)
		## Los pilares delanteros, del salpicadero al techo, y el borde del techo.
		_barra_cabina(Vector3(-0.52, -0.17, -0.95), Vector3(-0.47, 0.3, -0.38), 0.07, oscuro)
		_barra_cabina(Vector3(1.2, -0.17, -0.95), Vector3(1.15, 0.3, -0.38), 0.07, oscuro)
		_barra_cabina(Vector3(-0.5, 0.36, -0.38), Vector3(1.18, 0.36, -0.38), 0.04, oscuro)
		## El retrovisor, arriba al centro del parabrisas.
		_caja_cabina(Vector3(0.15, 0.045, 0.02), Vector3(0.36, 0.3, -0.48), Vector3(0, -12, 0), gris)
		## El volante: aro, buje y radios; gira con `_volante`.
		_cabina_volante = Node3D.new()
		_cabina_volante.position = Vector3(0.0, -0.3, -0.5)
		_cabina.add_child(_cabina_volante)
		var aro := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.165
		tm.outer_radius = 0.195
		tm.rings = 24
		tm.ring_segments = 8
		aro.mesh = tm
		aro.material_override = piel
		_cabina_volante.add_child(aro)
		for ang: float in [0.0, 120.0, 240.0]:
			var radio := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.025, 0.02, 0.17)
			radio.mesh = bm
			radio.material_override = gris
			radio.rotation_degrees = Vector3(0, ang, 0)
			radio.position = Vector3(sin(deg_to_rad(ang)), 0, cos(deg_to_rad(ang))) * 0.085
			_cabina_volante.add_child(radio)
		var buje := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.05
		cm.height = 0.04
		buje.mesh = cm
		buje.material_override = gris
		_cabina_volante.add_child(buje)
		## Los brazos: manga oscura y mano color piel.
		var manga := StandardMaterial3D.new()
		manga.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		manga.albedo_color = Color(0.16, 0.2, 0.3)
		var mano_m := StandardMaterial3D.new()
		mano_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mano_m.albedo_color = Color(0.8, 0.6, 0.47)
		for i in 2:
			var br := MeshInstance3D.new()
			var cm2 := CylinderMesh.new()
			cm2.top_radius = 0.034
			cm2.bottom_radius = 0.042
			cm2.height = 1.0
			cm2.radial_segments = 10
			br.mesh = cm2
			br.material_override = manga
			_cabina.add_child(br)
			_cabina_brazos.append(br)
			var mn := MeshInstance3D.new()
			var sm2 := SphereMesh.new()
			sm2.radius = 0.045
			sm2.height = 0.08
			sm2.radial_segments = 10
			sm2.rings = 6
			mn.mesh = sm2
			mn.material_override = mano_m
			mn.scale = Vector3(1.0, 0.8, 1.35)
			_cabina.add_child(mn)
			_cabina_manos.append(mn)
		## El velocímetro, en el cuadro tras el volante.
		_cabina_kmh = Label3D.new()
		_cabina_kmh.font_size = 48
		_cabina_kmh.pixel_size = 0.0012
		_cabina_kmh.modulate = Color(0.55, 0.95, 0.75)
		_cabina_kmh.outline_size = 0
		## En la consola del centro (tras el volante quedaba tapado).
		_cabina_kmh.position = Vector3(0.3, -0.13, -0.66)
		_cabina_kmh.rotation_degrees = Vector3(-35, -18, 0)
		_cabina_kmh.pixel_size = 0.0010
		_cabina_kmh.no_depth_test = false
		_cabina.add_child(_cabina_kmh)
		for h in _cabina.find_children("*", "GeometryInstance3D", true, false):
			(h as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cabina.visible = true
	## El aro mira al conductor (eje inclinado hacia atrás) y gira sobre su eje.
	_cabina_volante.basis = Basis(Vector3.RIGHT, deg_to_rad(70.0)) * Basis(Vector3.UP, _volante * 2.6)
	## Manos en el aro (giran con él) y antebrazos del hombro a la mano; el
	## cuerpo se inclina un poco hacia el lado al que giras.
	var lean := Vector3(-_volante * 0.04, 0, 0)
	for i in mini(2, _cabina_manos.size()):
		## Las manos acompañan el aro hasta ~35° y ahí resbalan (no se cruzan
		## ni bajan tras la consola en los giros fuertes).
		var giro_mano := clampf(_volante * 2.6, -0.6, 0.6)
		var base_mano := Basis(Vector3.RIGHT, deg_to_rad(70.0)) * Basis(Vector3.UP, giro_mano)
		var mano: Vector3 = _cabina_volante.position + base_mano * (_MANO_EN_ARO[i] as Vector3)
		_cabina_manos[i].position = mano
		_cabina_manos[i].basis = base_mano.scaled(Vector3(1.0, 0.8, 1.35))
		var hombro: Vector3 = (_HOMBRO[i] as Vector3) + lean
		var eje := mano - hombro
		var largo := eje.length()
		if largo < 0.01:
			continue
		var y := eje / largo
		var x := y.cross(Vector3.FORWARD)
		if x.length() < 0.01:
			x = y.cross(Vector3.RIGHT)
		x = x.normalized()
		_cabina_brazos[i].transform = Transform3D(Basis(x, y * largo, x.cross(y)), (hombro + mano) * 0.5)
	_cabina_kmh.text = "%d km/h" % int(round(absf(vel) * 3.6))

## Una barra de `a` a `b` (pilares y techo).
func _barra_cabina(a: Vector3, b: Vector3, grosor: float, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(grosor, a.distance_to(b), grosor)
	m.mesh = bm
	m.material_override = mat
	var eje := (b - a).normalized()
	var lado := eje.cross(Vector3.FORWARD)
	if lado.length() < 0.01:
		lado = eje.cross(Vector3.RIGHT)
	lado = lado.normalized()
	m.transform = Transform3D(Basis(lado, eje, lado.cross(eje)), (a + b) * 0.5)
	_cabina.add_child(m)

func _caja_cabina(tam: Vector3, en: Vector3, giro: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	m.mesh = bm
	m.material_override = mat
	m.position = en
	m.rotation_degrees = giro
	_cabina.add_child(m)

class VolanteUI extends Control:
	var giro := 0.0
	var kmh := 0.0
	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, h * 0.8, w, h * 0.2), Color(0.06, 0.06, 0.07, 0.96))
		draw_rect(Rect2(0, h * 0.8, w, 3), Color(0.35, 0.35, 0.4, 0.9))
		var c := Vector2(w * 0.38, h * 0.93)
		var r := h * 0.19
		draw_set_transform(c, giro * 1.2, Vector2.ONE)
		draw_arc(Vector2.ZERO, r, PI, TAU, 40, Color(0.24, 0.24, 0.27), 16.0, true)
		draw_arc(Vector2.ZERO, r, PI * 1.02, TAU * 0.99, 40, Color(0.28, 0.28, 0.32, 0.8), 3.0, true)
		draw_line(Vector2(-r, 0), Vector2(r, 0), Color(0.24, 0.24, 0.27), 12.0, true)
		draw_line(Vector2.ZERO, Vector2(0, -r), Color(0.24, 0.24, 0.27), 12.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(w * 0.56, h * 0.9), "%d km/h" % int(kmh), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.7, 1.0, 0.85))

func _colocar_camara(delta: float) -> void:
	## PLANO DE CONVERSACIÓN (13-10-2026): mientras alguien te habla, la cámara
	## se pone tras tu hombro y encuadra su cara (antes tu espalda la tapaba).
	if _hablando_con != null and is_instance_valid(_hablando_con) and _t_burbuja > 0.0 \
			and estado in ["calle", "interior"] and modo != "coche" and not primera_persona:
		var yo := cuerpo.position
		var el := _hablando_con.global_position
		var dir := Vector3(el.x - yo.x, 0, el.z - yo.z)
		if dir.length() > 0.2:
			dir = dir.normalized()
			var lado := dir.cross(Vector3.UP)
			var plano := yo - dir * 0.9 + lado * 0.6 + Vector3(0, 1.7, 0)
			var k := 1.0 if delta >= 1.0 else minf(1.0, delta * 5.0)
			camara.position = camara.position.lerp(plano, k)
			## Se mira algo por debajo de la cara: así queda en el tercio de arriba
			## y el cuadro de diálogo no la tapa.
			camara.look_at(el + Vector3(0, 1.2, 0) - lado * 0.25, Vector3.UP)
			return
	## EN COCHE (V cambia): 1 = capó, 2 = interior con volante dibujado.
	if modo == "coche" and cam_coche > 0:
		var dir_c := Vector3(sin(rumbo), 0, cos(rumbo))
		var der := Vector3(cos(rumbo), 0, -sin(rumbo))
		if cam_coche == 1:
			camara.position = cuerpo.position + Vector3(0, 1.25, 0) + dir_c * 2.15
			cuerpo.visible = true
		else:
			## PRIMERA PERSONA (17-10-2026): los ojos del conductor dentro de una
			## cabina 3D (salpicadero, volante que gira, pilares, retrovisor) que
			## va pegada a la cámara; con la velocidad, un leve temblor.
			var tiembla := Vector3(0, sin(_t_cabina * 23.0) * 0.004 * clampf(absf(vel) / 20.0, 0.0, 1.0), 0)
			camara.position = cuerpo.position + Vector3(0, 1.12, 0) + dir_c * 0.05 + der * 0.34 + tiembla
			cuerpo.visible = false
		var mira_dir := dir_c.rotated(Vector3.UP, -_volante * (0.18 if cam_coche == 1 else 0.28))
		camara.look_at(camara.position + mira_dir * 8.0 + Vector3(0, -0.2, 0), Vector3.UP)
		camara.rotate_object_local(Vector3.FORWARD, -_balanceo * 0.6)
		_t_cabina += delta if delta < 1.0 else 0.0
		_cabina_3d(cam_coche == 2)
		_fov_hacia(70.0 if cam_coche == 2 else 68.0, delta)
		_volante_ui(false)
		return
	_cabina_3d(false)
	_volante_ui(false)
	if modo == "coche" and not cuerpo.visible:
		cuerpo.visible = true
	## PRIMERA PERSONA (V): la cámara en los ojos, el cuerpo escondido.
	if primera_persona and (modo != "coche"):
		var dir_fp := Vector3(sin(rumbo), 0, cos(rumbo))
		camara.position = cuerpo.position + Vector3(0, 1.62, 0) + dir_fp * 0.18
		camara.look_at(camara.position + dir_fp * 5.0 + Vector3(0, -0.15, 0), Vector3.UP)
		cuerpo.visible = false
		return
	if modo != "coche" and not cuerpo.visible and not _sentado_fp():
		cuerpo.visible = true
	var atras := 5.5
	var alto := 2.6
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	## EN COCHE, CÁMARA DE PERSECUCIÓN (17-10-2026): sigue al coche con retraso
	## en el giro (en las curvas se ve el costado), se aleja y abre el ángulo
	## con la velocidad, y mira por delante del capó.
	if modo == "coche":
		var rapidez := clampf(absf(vel) / 25.0, 0.0, 1.0)
		_cam_yaw = lerp_angle(_cam_yaw, rumbo, clampf(delta * (2.2 + rapidez * 1.5), 0.0, 1.0)) if delta < 1.0 else rumbo
		adelante = Vector3(sin(_cam_yaw), 0, cos(_cam_yaw))
		atras = lerpf(8.0, 11.5, rapidez)
		alto = lerpf(3.0, 3.8, rapidez)
		_fov_hacia(lerpf(66.0, 80.0, rapidez), delta)
	else:
		_fov_hacia(65.0, delta)
	var deseo := cuerpo.position - adelante * atras + Vector3(0, alto, 0)
	if estado == "anden" and not _acc.is_empty() and not bool(_acc["elevada"]):
		## BAJO TIERRA la cámara no puede salirse del vestíbulo: se queda entre
		## la vía y la pared del fondo, y bajo el techo.
		var rel := deseo - _anden_c
		var l_lat := clampf(rel.dot(_anden_lat), -5.0, 3.0)
		var l_lon := clampf(rel.dot(_anden_lon), -29.0, 29.0)
		deseo = _anden_c + _anden_lat * l_lat + _anden_lon * l_lon
		deseo.y = minf(cuerpo.position.y + alto, MetroCiudad.PROF_TUNEL + 5.6)
	elif estado == "interior" and is_instance_valid(_int):
		## Dentro de la sala la cámara no sale de las paredes ni pasa del techo.
		var t := _int.tam_sala()
		deseo.x = clampf(deseo.x, _INT_ORIGEN.x - t.x * 0.5 + 0.3, _INT_ORIGEN.x + t.x * 0.5 - 0.3)
		deseo.z = clampf(deseo.z, _INT_ORIGEN.z - t.z * 0.5 + 0.3, _INT_ORIGEN.z + t.z * 0.5 - 0.3)
		deseo.y = minf(deseo.y, _INT_ORIGEN.y + t.y - 0.3)
	elif estado == "calle":
		## La cámara no se mete dentro de los edificios: si el punto de detrás
		## cae en una huella, se acerca al personaje hasta el último sitio libre
		## (etapa 1, 8-10-2026).
		var desde := cuerpo.position + Vector3(0, alto, 0)
		var paso := (deseo - desde)
		var largo := paso.length()
		if largo > 0.01 and not libre_obst(deseo, 0.3):
			var bueno := desde
			var k := 0.5
			while k <= largo:
				var q := desde + paso / largo * k
				if not libre_obst(q, 0.3):
					break
				bueno = q
				k += 0.5
			deseo = bueno
	camara.position = camara.position.lerp(deseo, clampf(delta * (8.0 if modo == "coche" else 5.0), 0.0, 1.0)) if delta < 1.0 else deseo
	if modo == "coche":
		camara.look_at(cuerpo.position + Vector3(0, 1.2, 0) + Vector3(sin(rumbo), 0, cos(rumbo)) * (5.0 + absf(vel) * 0.25), Vector3.UP)
		## La sacudida del choque (M-172), que se apaga en medio segundo.
		if _sacudida_golpe > 0.0:
			camara.position += Vector3(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5), randf_range(-1.0, 1.0)) * _sacudida_golpe * 0.18
			_sacudida_golpe = maxf(_sacudida_golpe - (delta if delta < 1.0 else 0.0) * 2.0, 0.0)
	else:
		camara.look_at(cuerpo.position + Vector3(0, 1.4, 0) + adelante * 4.0, Vector3.UP)

## Lo que hay al alcance de la E: un peatón (a pie) o un lugar.
func _buscar_cerca() -> void:
	_cerca = {}
	var p := cuerpo.position
	## La puerta del club del estadio (a pie).
	if modo == "pie" and not _est.is_empty():
		var pu: Vector3 = CityBuilder.ESTADIO_EN + (_est["puerta"] as Vector3)
		## El portero: es él quien abre (8-10-2026).
		var port := _portero()
		if not port.is_empty() and Vector2(pu.x - p.x, pu.z - p.z).length() < 4.5:
			_cerca = {"tipo": "portero", "g": port, "n": String(port["nombre"])}
			_aviso.text = Idiomas.t("E: hablar con %s (%s)") % [String(port["nombre"]), Idiomas.t(String(port["puesto"]))]
			return
		if Vector2(pu.x - p.x, pu.z - p.z).length() < 3.5:
			_cerca = {"tipo": "puerta_estadio", "n": "el estadio"}
			_aviso.text = Idiomas.t("E: entrar al estadio por la puerta del club")
			return
		## La caseta de la galería, junto al complejo.
		var gb := GaleriaClub.boca_mundo(_est)
		if absf(gb.x - p.x) < 2.2 and p.z > gb.z - 5.0 and p.z < gb.z + 3.0:
			_cerca = {"tipo": "galeria", "n": "la galería"}
			_aviso.text = Idiomas.t("E: bajar a la galería del club (al estadio)")
			return
	## Una entrada de metro (a pie).
	if modo == "pie" and metro != null:
		for a: Dictionary in metro.accesos:
			var q: Vector3 = a["pie"]
			if Vector2(q.x - p.x, q.z - p.z).length() < 4.0:
				_cerca = {"tipo": "metro", "acc": a, "n": "Ⓜ %s · %s" % [a["linea"], a["nombre"]]}
				_aviso.text = Idiomas.t("E: entrar al metro (%s, estación %s)") % [a["linea"], a["nombre"]]
				return
	if modo == "pie" and trafico != null:
		for v: Dictionary in trafico._vehiculos:
			var n: Node3D = v["nodo"]
			if not is_instance_valid(n) or float(v["alto"]) < 0.1 or float(v["alto"]) > 0.3:
				continue
			if n.position.distance_to(p) < 3.5:
				_cerca = {"tipo": "peaton", "v": v, "n": "un vecino"}
				break
	if _cerca.is_empty():
		var alcance := 30.0 if modo == "coche" else 14.0
		var mejor := alcance
		for pc: Dictionary in cb.puntos_clic:
			var q: Vector3 = pc["pos"]
			var d := Vector2(q.x - p.x, q.z - p.z).length()
			if d < mejor and d < float(pc.get("radio", 99.0)):
				mejor = d
				_cerca = {"tipo": "lugar", "k": String(pc["k"]), "n": String(pc["n"])}
	## Cualquier fachada de manzana: se puede entrar (etapa 6). El tipo y el
	## nombre salen del tramo de calle, así que son siempre los mismos.
	if _cerca.is_empty() and modo == "pie":
		var ed := edificio_en(p)
		if not ed.is_empty():
			_cerca = {"tipo": "lugar", "k": String(ed["k"]), "n": String(ed["n"])}
	if _cerca.is_empty():
		_aviso.text = ""
	elif _cerca["tipo"] == "peaton":
		_aviso.text = Idiomas.t("E: hablar con %s") % _cerca["n"]
	else:
		_aviso.text = "E: %s" % _cerca["n"]

func _unhandled_input(ev: InputEvent) -> void:
	## En primera persona el ratón mira (cursor capturado).
	if ev is InputEventMouseMotion and primera_persona and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rumbo -= (ev as InputEventMouseMotion).relative.x * 0.003
		return
	if not (ev is InputEventKey) or not (ev as InputEventKey).pressed or (ev as InputEventKey).echo:
		if ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_X:
			_usar()
		return
	var k := (ev as InputEventKey).keycode
	if k == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		salir.emit()
	elif k == KEY_E:
		get_viewport().set_input_as_handled()
		_usar()
	elif k == KEY_V and modo == "coche" and estado == "calle":
		cam_coche = (cam_coche + 1) % 3
		_aviso.text = [Idiomas.t("Cámara: tercera persona"), Idiomas.t("Cámara: capó"), Idiomas.t("Cámara: primera persona")][cam_coche]
	elif k == KEY_V:
		primera_persona = not primera_persona
		_raton_en_primera_persona()
		_aviso.text = Idiomas.t("Primera persona") if primera_persona else Idiomas.t("Tercera persona")
	elif k == KEY_C and estado == "tren":
		_ventana = not _ventana

func _usar() -> void:
	if estado == "interior":
		## E junto a alguien que trabaja ahí: charlar (13-10-2026); si no, salir.
		if not _int_cerca.is_empty():
			_hablar_con_vecino(_int_cerca)
			return
		_salir_del_edificio()   ## E dentro de un edificio: salir a la calle
		return
	if estado == "estadio":
		if is_instance_valid(_menu_asc):
			return
		var loc := cuerpo.position - CityBuilder.ESTADIO_EN
		if _sentado:
			_sentado = false
			cuerpo.visible = true
			RecorridoClub.devolver_hinchas(_hinchas_quitados)
			_hinchas_quitados = []
			cuerpo.position = _de_pie
			_aviso.text = ""
			_zona_est = "?"
			return
		if RecorridoClub.junto_a_la_grada(loc, _planta):
			var b := RecorridoClub.butaca(cb.datos.get("perfil_estadio", {}), signf(loc.x), loc.z)
			_de_pie = cuerpo.position
			cuerpo.position = CityBuilder.ESTADIO_EN + (b["pos"] as Vector3)
			rumbo = float(b["rumbo"])
			cuerpo.rotation.y = rumbo
			_mirada = 0.0
			_sentado = true
			cuerpo.visible = false
			_hinchas_quitados = RecorridoClub.despejar_hinchas(cb, cuerpo.global_position + Vector3(0, 0.5, 0))
			_aviso.text = Idiomas.t("En la grada. A/D: mirar alrededor · E: levantarse")
			return
		var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
		var g: Dictionary = pe.cercano(cuerpo.position - CityBuilder.ESTADIO_EN, _planta) if pe != null else {}
		if not g.is_empty():
			_menu_asc = RecorridoClub.dialogo(_capa, pe, g, cuerpo.position - CityBuilder.ESTADIO_EN)
			return
		if _zona_est == "Acceso":
			_salir_del_estadio()
		elif _zona_est == "Ascensor" and not is_instance_valid(_menu_asc):
			_menu_asc = RecorridoClub.menu_ascensor(_capa, _planta, _ir_a_planta)
		elif RecorridoClub.sala_decorable(_zona_est):
			_menu_asc = RecorridoClub.panel_decorar(_capa, get_tree(), _zona_est)
		return
	if estado == "anden":
		_usar_en_anden()
		return
	if estado == "tren":
		if metro.estacion_del_tren(_linea, _tren_k) >= 0:
			_bajar_del_tren()
		else:
			_bajar_en_proxima = not _bajar_en_proxima
		return
	if _cerca.is_empty():
		return
	if _cerca["tipo"] == "lugar" and modo == "pie" and (String(_cerca["k"]).begins_with("edificio_") \
			or (InteriorInstalacion.tiene(String(_cerca["k"])) and not Instalaciones.CATALOGO.has(String(_cerca["k"])) \
				and MinijuegosCiudad.juego_de(String(_cerca["k"])) == "")):
		_entrar_en_edificio(String(_cerca["k"]))
		return
	if _cerca["tipo"] == "metro":
		_entrar_al_anden(_cerca["acc"])
		return
	if _cerca["tipo"] == "puerta_estadio":
		_entrar_al_estadio()
		return
	if _cerca["tipo"] == "portero":
		if is_instance_valid(_menu_asc):
			return
		var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
		_menu_asc = RecorridoClub.dialogo_portero(_capa, pe, _cerca["g"], cuerpo.position - CityBuilder.ESTADIO_EN, _cruzar_puerta)
		_menu_asc.set_meta("portero", _cerca["g"])
		return
	if _cerca["tipo"] == "galeria":
		_bajar_a_la_galeria()
		return
	if _cerca["tipo"] == "peaton":
		_hablar_con_vecino(_cerca["v"])
	else:
		interactuar.emit(String(_cerca["k"]))


## ============================================================ ENTRAR EN UN EDIFICIO
## La sala se levanta bajo el mapa (`_INT_ORIGEN`); el personaje camina dentro
## en tercera o primera persona y sale por la puerta (o con E).
const _INT_ORIGEN := Vector3(0.0, -400.0, 0.0)
var _int: InteriorInstalacion = null
var _int_raiz: Node3D = null
var _int_circulos := PackedVector3Array()
var _calle_pos := Vector3.ZERO
var _calle_rumbo := 0.0

func _entrar_en_edificio(k: String) -> void:
	_fundido()
	_int_raiz = Node3D.new()
	_int_raiz.name = "InteriorPaseo"
	_int_raiz.position = _INT_ORIGEN
	cb.add_child(_int_raiz)
	_int = InteriorInstalacion.en_mundo(_int_raiz, k, null)
	if _int == null:
		_int_raiz.queue_free()
		return
	_capa.add_child(_int)   ## (oculto: solo para que la gente se mueva)
	## El mobiliario es sólido: círculos sacados de la propia sala (mesas, sofás,
	## mostradores, estanterías...), sin paredes ni suelo.
	_int_circulos = Optimizar.obstaculos(_int_raiz, [] as Array[Rect2], 0.4, 0.5)
	_calle_pos = cuerpo.position
	_calle_rumbo = rumbo
	estado = "interior"
	_bajo_tierra(true)
	_vel_pie = 0.0
	var t := _int.tam_sala()
	cuerpo.position = _INT_ORIGEN + Vector3(0, 0.05, t.z * 0.5 - 1.6)
	rumbo = PI
	cuerpo.rotation.y = rumbo
	cuerpo.visible = not primera_persona
	_cerca = {}
	_aviso.text = ""
	_colocar_camara(1.0)

func _mover_en_interior(delta: float) -> void:
	if not is_instance_valid(_int):
		_salir_del_edificio()
		return
	var e := _entrada()
	var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	var objetivo := (3.4 if corre else 1.6) * clampf(e.y, -0.5, 1.0)
	_vel_pie = move_toward(_vel_pie, objetivo, (7.0 if absf(objetivo) > absf(_vel_pie) else 12.0) * delta)
	vel = _vel_pie
	rumbo -= e.x * delta * 2.6
	var t := _int.tam_sala()
	var rel := cuerpo.position - _INT_ORIGEN
	var nueva := rel + Vector3(sin(rumbo), 0, cos(rumbo)) * vel * delta
	## La puerta: pasar de la línea del hueco (|x| < 1,4) sale a la calle.
	if nueva.z > t.z * 0.5 - 0.2 and absf(nueva.x) < 1.4:
		_salir_del_edificio()
		return
	nueva.x = clampf(nueva.x, -t.x * 0.5 + 0.7, t.x * 0.5 - 0.7)
	nueva.z = clampf(nueva.z, -t.z * 0.5 + 0.7, t.z * 0.5 - 0.7)
	## Contra el mobiliario: se desliza por ejes, como en la calle.
	if _choca_mueble(nueva):
		if not _choca_mueble(Vector3(nueva.x, 0, rel.z)):
			nueva.z = rel.z
		elif not _choca_mueble(Vector3(rel.x, 0, nueva.z)):
			nueva.x = rel.x
		else:
			nueva = rel
			_vel_pie = 0.0
	cuerpo.position = _INT_ORIGEN + Vector3(nueva.x, 0.05, nueva.z)
	cuerpo.rotation.y = rumbo
	if _es_dt:
		_animar_dt(vel)
	elif _anim != null:
		_anim.speed_scale = absf(vel) / 1.4 if absf(vel) > 0.05 else 0.0
	_colocar_camara(delta)
	_hud.text = Idiomas.t("🏠 %s  ·  W/S/A/D para moverte · V: vista · E o la puerta: salir") % String(_int.call("_sala_nombre"))
	## ¿Alguien de la sala a mano para charlar?
	_int_cerca = {}
	var mejor := 1.9
	for lista: Array in [_int.get("_fijos"), _int.get("_caminantes")]:
		for f: Dictionary in lista:
			var d: Dictionary = f["d"]
			var n: Node3D = d.get("nodo")
			if n == null or not is_instance_valid(n):
				continue
			var dist := Vector2(n.global_position.x - cuerpo.position.x, n.global_position.z - cuerpo.position.z).length()
			if dist < mejor:
				mejor = dist
				if not f.has("charla"):
					f["charla"] = {"nodo": n}
				_int_cerca = f["charla"]
	_aviso.text = Idiomas.t("E: charlar") if not _int_cerca.is_empty() else ""
	if _t_burbuja > 0.0:
		_t_burbuja -= delta
		if _t_burbuja <= 0.0:
			_burbuja.visible = false
			if _cuadro != null:
				_cuadro.cerrar()

func _choca_mueble(rel: Vector3) -> bool:
	var p := _INT_ORIGEN + rel
	for c: Vector3 in _int_circulos:
		var dx := p.x - c.x
		var dz := p.z - c.y
		var rr := c.z + 0.35
		if dx * dx + dz * dz < rr * rr:
			return true
	return false

func _salir_del_edificio() -> void:
	_fundido()
	if is_instance_valid(_int):
		_int.queue_free()
	if is_instance_valid(_int_raiz):
		_int_raiz.queue_free()
	_int = null
	_int_raiz = null
	estado = "calle"
	_t_gente = -1000.0   ## al volver a la calle se llena el entorno
	_bajo_tierra(false)
	_vel_pie = 0.0
	cuerpo.visible = not primera_persona
	cuerpo.position = _calle_pos
	rumbo = _calle_rumbo
	cuerpo.rotation.y = rumbo
	_colocar_camara(1.0)

## UNA CONVERSACIÓN CON UN VECINO (13-10-2026): tiene un OFICIO, habla en tres
## turnos (saludo según el ánimo del club, charla de su oficio, despedida), se
## gira hacia ti y gesticula; al acabar vuelve a andar.
var _rng_dialogo := RandomNumberGenerator.new()

## Un gesto de tu personaje (saludar, charlar) y vuelta a estar parado.
func _gesto_propio(gesto: String) -> void:
	if _anim == null or not AnimExtra.UAL.has(gesto):
		return
	var lib := _anim.get_animation_library("")
	if lib != null and not lib.has_animation(gesto):
		var esq := FutbolistaQ.esqueleto_de(cuerpo)
		var clip: Animation = AnimQuaternius.cargar_real(String(AnimExtra.UAL[gesto]), str(_anim.get_path_to(esq)) if esq != null else "")
		if clip != null:
			lib.add_animation(gesto, clip)
	if _anim.has_animation(gesto):
		_anim.speed_scale = 1.0
		_anim.play(gesto, 0.25)
		_t_gesto_propio = minf(_anim.get_animation(gesto).length, 3.0)

func _hablar_con_vecino(v: Dictionary) -> void:
	var nodo: Node3D = v["nodo"]
	if not is_instance_valid(nodo):
		return
	_hablando_con = nodo
	## Si el texto aún se escribe, E lo completa en vez de pasar de turno.
	if _cuadro != null and _cuadro.escribiendo() and _hablando_con == nodo:
		_cuadro.completar()
		_t_burbuja = maxf(_t_burbuja, 4.0)
		return
	if not v.has("oficio"):
		## Oficio acorde a quien es (antes un hombre podía ser «La panadera»)
		## y un nombre propio, ficticio.
		var semilla := absi(hash(String(nodo.name)) + int(nodo.position.x * 7.0))
		var mujer := bool(nodo.get_meta("mujer", semilla % 2 == 0))
		var lista: Array = ["panadera", "estudiante", "kiosquera", "enfermera"] if mujer else ["jubilado", "taxista", "hincha", "barrendero", "repartidor"]
		## Dentro de un edificio, un oficio que pegue con el sitio.
		if estado == "interior" and is_instance_valid(_int):
			var sala := String(_int.call("_sala_nombre")).to_lower()
			if sala.contains("hospital") or sala.contains("clínica"):
				lista = ["enfermera"] if mujer else ["repartidor"]
			elif sala.contains("panader"):
				lista = ["panadera"] if mujer else ["repartidor"]
			else:
				lista = ["estudiante", "kiosquera"] if mujer else ["hincha", "repartidor"]
		v["oficio"] = String(lista[semilla % lista.size()])
		var nombres: Array = NOMBRES_M if mujer else NOMBRES_H
		v["nombre"] = String(nombres[(semilla / 7) % nombres.size()])
	var ahora := Time.get_ticks_msec()
	if ahora - int(v.get("t_charla", 0)) > 25000:
		v["turno"] = 0
	var turno := int(v.get("turno", 0))
	v["t_charla"] = ahora
	var oficio: String = v["oficio"]
	var frase := DialogosCiudad.linea(oficio, turno, animo, _rng_dialogo)
	if frase.contains("%s"):
		frase = frase % club_nombre
	## El texto va al CUADRO DE DIÁLOGO; sobre la cabeza solo queda un aviso.
	if _cuadro == null:
		_cuadro = CuadroDialogo.new()
		add_child(_cuadro)
	var tono := Color.from_hsv(fposmod(float(hash(oficio)) / 1000.0, 1.0), 0.45, 1.0)
	_cuadro.decir("%s · %s" % [String(v.get("nombre", "")), DialogosCiudad.nombre(oficio)], frase, tono, turno, 3)
	## Con el plano de conversación el globo sobra: solo en primera persona.
	_burbuja.text = "💬"
	_burbuja.pixel_size = 0.006
	_burbuja.position = nodo.global_position + Vector3(0, 2.3, 0)
	_burbuja.visible = primera_persona
	_t_burbuja = 6.0
	v["turno"] = (turno + 1) % 3
	v["espera"] = 6.0
	## Y la cara acompaña: alegre al saludar y despedirse; en la charla, según
	## cómo va el club.
	var cara: String = "alegre" if turno != 1 else {"euforia": "alegre", "bien": "alegre", "mal": "triste", "crisis": "enfado"}.get(animo, "neutral")
	Expresion.de(nodo).poner(cara, 5.0)
	## Se gira hacia ti y hace el gesto que toca (saluda, charla, se despide).
	var d := cuerpo.global_position - nodo.global_position
	nodo.rotation.y = atan2(d.x, d.z)
	## Y tú hacia esa persona, con tu propio gesto (13-10-2026).
	if not primera_persona:
		rumbo = atan2(-d.x, -d.z)
		cuerpo.rotation.y = rumbo
		_vel_pie = 0.0
		vel = 0.0
		_gesto_propio("saludo_mano" if turno == 0 else "charla")
	var gesto := "saludo_mano" if turno != 1 else "charla"
	for ap: AnimationPlayer in nodo.find_children("*", "AnimationPlayer", true, false):
		var lib := ap.get_animation_library("")
		if lib != null and not lib.has_animation(gesto):
			var esq := FutbolistaQ.esqueleto_de(nodo)
			var clip: Animation = AnimQuaternius.cargar_real(String(AnimExtra.UAL[gesto]), str(ap.get_path_to(esq)) if esq != null else "")
			if clip != null:
				lib.add_animation(gesto, clip)
		if lib != null and lib.has_animation(gesto):
			ap.play(gesto, 0.2)
			get_tree().create_timer(6.0).timeout.connect(func() -> void:
				if is_instance_valid(ap) and ap.has_animation("caminar"):
					ap.play("caminar", 0.3))

# ============================================================== EL ESTADIO (2.0)

## Cruza la puerta del club: ya dentro, en el vestuario.
func _entrar_al_estadio() -> void:
	_fundido()
	Optimizar.butacas_livianas(cb, false)
	estado = "estadio"
	_planta = 0
	## Los rótulos flotantes del mapa se ven a través de las paredes: fuera.
	_rotulos_antes = cb._rotulos.visible if cb._rotulos != null else true
	cb.mostrar_rotulos(false)
	var pu: Vector3 = _est["puerta"]
	cuerpo.position = CityBuilder.ESTADIO_EN + pu + Vector3(0, 0, -2.2)
	rumbo = PI
	_zona_est = ""
	_aviso.text = ""
	Sonido.toca("puerta", Sonido.Bus.EFECTOS)

## El ascensor del edificio del club: misma x y z, otra planta. Los sótanos
## van sin sol ni niebla (como el metro).
func _ir_a_planta(p: int) -> void:
	var antes := _planta
	_planta = p
	cuerpo.position.y = RecorridoClub.y_de(p)
	_zona_est = "?"
	if (antes < 0) != (p < 0):
		_bajo_tierra(p < 0)

## De vuelta a la calle, delante de la puerta del club.
var _rotulos_antes := true

## FUNDIDO al cambiar de sitio de golpe (puerta, escaleras, galería): la
## pantalla parte de negro y se aclara, en vez de saltar (etapa 1).
var _velo: ColorRect

func _fundido() -> void:
	if _capa == null:
		return
	if not is_instance_valid(_velo):
		_velo = ColorRect.new()
		_velo.color = Color.BLACK
		_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
		_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_capa.add_child(_velo)
		_capa.move_child(_velo, 0)
	_velo.modulate.a = 1.0
	var tw := _velo.create_tween()
	tw.tween_property(_velo, "modulate:a", 0.0, 0.45).set_delay(0.05)

# ---------------------------------------------------- la puerta y el portero

## Camino que el DT hace solo al cruzar la puerta (mundo).
var _auto: Array = []

func _portero() -> Dictionary:
	var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
	if pe == null:
		return {}
	var g := pe.buscar("portero")
	if g.is_empty() or not is_instance_valid(g["nodo"]) or not (g["nodo"] as Node3D).visible:
		return {}
	return g

## El portero ya abrió: el DT sube el escalón y entra andando.
func _cruzar_puerta() -> void:
	var pu: Vector3 = CityBuilder.ESTADIO_EN + (_est["puerta"] as Vector3)
	## Hacia la puerta sin dar la vuelta (si ya está pegado, entra recto).
	_auto = [Vector3(pu.x, cuerpo.position.y, maxf(cuerpo.position.z - 0.3, pu.z + 0.6)), Vector3(pu.x, cuerpo.position.y, pu.z - 1.6)]
	estado = "puerta"
	_aviso.text = ""

func _andar_solo(delta: float) -> void:
	if _auto.is_empty():
		_entrar_al_estadio()
		get_tree().create_timer(1.4).timeout.connect(func() -> void: EntradaClub.abrir(get_tree(), false))
		return
	var meta: Vector3 = _auto[0]
	var hacia := meta - cuerpo.position
	hacia.y = 0.0
	var d := hacia.length()
	if d < 0.08:
		_auto.pop_front()
		return
	rumbo = atan2(hacia.x, hacia.z)
	cuerpo.rotation.y = rumbo
	cuerpo.position += hacia / d * minf(d, VEL_PIE * delta)
	_animar_dt(VEL_PIE)
	## La cámara se queda donde estaba (detrás, en la calle) y le sigue con
	## la mirada: así se ve al DT cruzar la puerta.
	camara.look_at(cuerpo.position + Vector3(0, 1.3, 0), Vector3.UP)

## En la calle, con la puerta abierta y ya lejos: se cierra sola. Y si te
## vas a mitad de la charla con el portero, la charla se acaba.
func _cerrar_puerta_si_lejos() -> void:
	if _est.is_empty():
		return
	var pu: Vector3 = CityBuilder.ESTADIO_EN + (_est["puerta"] as Vector3)
	var lejos := Vector2(pu.x - cuerpo.position.x, pu.z - cuerpo.position.z).length() > 5.5
	if lejos and is_instance_valid(_menu_asc) and _menu_asc.has_meta("portero"):
		var g: Dictionary = _menu_asc.get_meta("portero")
		var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
		if pe != null:
			pe.atender(g, Vector3.ZERO, false)
		_menu_asc.queue_free()
	if lejos and EntradaClub.abierta(get_tree()):
		EntradaClub.abrir(get_tree(), false)

## Desde la caseta de la calle: escalera abajo, al pie de la galería.
func _bajar_a_la_galeria() -> void:
	_fundido()
	estado = "estadio"
	_rotulos_antes = cb._rotulos.visible if cb._rotulos != null else true
	cb.mostrar_rotulos(false)
	_planta = GaleriaClub.PLANTA
	cuerpo.position = CityBuilder.ESTADIO_EN + GaleriaClub.pie_de_escalera(_est)
	rumbo = PI
	_zona_est = "?"
	_aviso.text = ""
	_bajo_tierra(true)
	_mover_en_estadio(1.0)

## Arriba de la escalera mecánica: a la calle, delante de la caseta.
func _subir_de_la_galeria() -> void:
	_fundido()
	estado = "calle"
	_t_gente = -1000.0   ## al volver a la calle se llena el entorno
	_planta = 0
	_bajo_tierra(false)
	cb.mostrar_rotulos(_rotulos_antes)
	cuerpo.position = GaleriaClub.boca_mundo(_est) + Vector3(0, 0, 1.6)
	cuerpo.position.y = altura_suelo(cuerpo.position.x, cuerpo.position.z)
	rumbo = 0.0
	_aviso.text = ""
	_colocar_camara(1.0)

func _salir_del_estadio() -> void:
	_fundido()
	Optimizar.butacas_livianas(cb, true)
	estado = "calle"
	_t_gente = -1000.0   ## al volver a la calle se llena el entorno
	cb.mostrar_rotulos(_rotulos_antes)
	var pu: Vector3 = _est["puerta"]
	cuerpo.position = CityBuilder.ESTADIO_EN + pu + Vector3(0, 0, 3.2)
	cuerpo.position.y = altura_suelo(cuerpo.position.x, cuerpo.position.z)
	rumbo = 0.0
	_aviso.text = ""
	## El portero despide con la mano.
	var port := _portero()
	if not port.is_empty():
		var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
		pe.atender(port, cuerpo.position - CityBuilder.ESTADIO_EN, true)
		pe.gesto(port, ["saludo_mano", "saludar_publico"])
		port["quieto"] = false
		_burbuja.text = "💬 " + Idiomas.t("¡Hasta luego, míster!")
		## Pequeña: el portero está a dos pasos de la cámara.
		_burbuja.pixel_size = 0.0035
		_burbuja.position = (port["nodo"] as Node3D).global_position + Vector3(0, 2.25, 0)
		_burbuja.visible = true
		_t_burbuja = 3.0

## Dentro del estadio se camina por las zonas de `TunelVestuario` (vestuario,
## túnel, banda, campo y la puerta). Salir por la puerta devuelve a la calle.
func _mover_en_estadio(delta: float) -> void:
	var e := _entrada()
	if _sentado:
		_mirada = clampf(_mirada - e.x * delta * 1.4, -1.2, 1.2)
		var dir := Vector3(sin(rumbo + _mirada), 0, cos(rumbo + _mirada))
		camara.position = cuerpo.position + Vector3(0, 1.2, 0) + Vector3(sin(rumbo), 0, cos(rumbo)) * 0.1
		camara.look_at(camara.position + dir * 10.0 + Vector3(0, -1.6, 0), Vector3.UP)
		return
	var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	var objetivo_e := (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
	_vel_pie = move_toward(_vel_pie, objetivo_e, (7.0 if absf(objetivo_e) > absf(_vel_pie) else 12.0) * delta)
	vel = _vel_pie
	## La galería tiene cinta rodante: 150 m se hacen en un rato.
	if _zona_est == "Galería":
		vel *= GaleriaClub.CINTA
	rumbo -= e.x * delta * 2.6
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var nueva := cuerpo.position + adelante * vel * delta
	var local := nueva - CityBuilder.ESTADIO_EN
	var zonas: Array = _est["zonas"]
	## La puerta del club se abre sola desde dentro (sensor), como en la vida.
	if _planta == 0:
		var pl: Vector3 = _est["puerta"]
		EntradaClub.abrir(get_tree(), Vector2(local.x - pl.x, local.z - pl.z).length() < 1.9)
	if _planta == GaleriaClub.PLANTA and GaleriaClub.arriba(_est, local):
		## Arriba de la escalera mecánica: la calle.
		_subir_de_la_galeria()
		return
	if _planta == 0 and local.z > float((_est["puerta"] as Vector3).z) + 1.0:
		## Cruzada la puerta, ya en la calle.
		_salir_del_estadio()
		return
	## Colisión del cuerpo entero (paredes, muebles, gente): `ColisionClub`.
	## La puerta a la calle es la excepción: cruzarla saca del estadio.
	if _planta == 0 and local.z > float((_est["puerta"] as Vector3).z) + 0.5:
		_salir_del_estadio()
		return
	var ant := cuerpo.position
	var pe_col := (get_tree().get_first_node_in_group("personal_club") as PersonalEstadio) if is_inside_tree() else null
	var llega := ColisionClub.mover(cuerpo, ant, nueva, zonas, _planta, CityBuilder.ESTADIO_EN, pe_col)
	var pedido := Vector2(nueva.x - ant.x, nueva.z - ant.z).length()
	var hecho := Vector2(llega.x - ant.x, llega.z - ant.z).length()
	if pedido > 1e-4:
		if hecho < pedido * 0.2:
			vel = 0.0
			_vel_pie = 0.0
		elif hecho < pedido * 0.9:
			_vel_pie *= 0.92
	cuerpo.position = Vector3(llega.x, RecorridoClub.y_de(_planta), llega.z)
	PersonalEstadio.avisar_jugador(cuerpo.position - CityBuilder.ESTADIO_EN, _planta)
	cuerpo.rotation.y = rumbo
	_animar_dt(vel)
	var z := TunelVestuario.zona_en(zonas, cuerpo.position - CityBuilder.ESTADIO_EN, _planta)
	var nombre := String(z.get("nombre", ""))
	var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
	var g: Dictionary = pe.cercano(cuerpo.position - CityBuilder.ESTADIO_EN, _planta) if pe != null else {}
	if not g.is_empty():
		_aviso.text = Idiomas.t("E: hablar con %s (%s)") % [String(g["nombre"]), Idiomas.t(String(g["puesto"]))]
		_zona_est = nombre
		_aviso_hablar = true
	elif RecorridoClub.junto_a_la_grada(cuerpo.position - CityBuilder.ESTADIO_EN, _planta):
		_aviso.text = Idiomas.t("E: sentarse en la grada")
		_zona_est = "·grada"
	elif nombre != _zona_est or _aviso_hablar:
		## Antes se miraba si el texto empezaba por «E: hablar»: en otro idioma
		## nunca coincidía y el aviso de hablar se quedaba pegado.
		_aviso_hablar = false
		_zona_est = nombre
		_aviso.text = RecorridoClub.aviso_de(nombre)
		if RecorridoClub.sala_decorable(nombre):
			_aviso.text += "  ·  " + Idiomas.t("E: decorar")
	if nombre == "Galería":
		_aviso.text = Idiomas.t("Galería del club · al complejo: %d m · cinta rodante") % GaleriaClub.metros_hasta(_est, cuerpo.position - CityBuilder.ESTADIO_EN)
	_hud.text = "📍 %s · %s %d · %s\n🚶 %s" % [Idiomas.t(nombre), Idiomas.t("Planta"), _planta, str(cb.datos.get("club", {}).get("estadioNom", "Estadio")),
		Idiomas.t("W/S/A/D o mando · Mayús: correr · E: usar · Esc: volver al mapa")]
	## Cámara: dentro de una sala no atraviesa paredes ni techo.
	var cerrado := float(z.get("techo", 99.0)) < 50.0
	var atras := 3.2 if cerrado else 5.5
	var alto := 1.9 if cerrado else 2.6
	var deseo := cuerpo.position - adelante * atras + Vector3(0, alto, 0)
	if cerrado:
		var r: Rect2 = z["r"]
		var o := CityBuilder.ESTADIO_EN
		deseo.x = clampf(deseo.x, o.x + r.position.x + 0.15, o.x + r.end.x - 0.15)
		## Solo el túnel deja que la cámara asome por sus extremos (la boca y la
		## puerta del vestuario); en una sala cerrada se queda dentro.
		var holgura := 1.0 if nombre == "Túnel" else -0.15
		deseo.z = clampf(deseo.z, o.z + r.position.y - holgura, o.z + r.end.y + holgura)
		deseo.y = minf(deseo.y, RecorridoClub.y_de(_planta) + float(z["techo"]) - 0.25)
		if nombre == "Escalera de la galería":
			## Mirando hacia abajo desde la escalera: la cámara va sobre los
			## peldaños, dentro del pozo, y no se sale por arriba.
			deseo.z = minf(deseo.z, o.z + float(GaleriaClub.trazado(_est)["z_esc"]) + 4.0)
			deseo.y = RecorridoClub.y_de(_planta) + GaleriaClub.alto_rampa(_est, deseo.z - o.z) + 1.7
	camara.position = camara.position.lerp(deseo, clampf(delta * 6.0, 0.0, 1.0)) if delta < 1.0 else deseo
	camara.look_at(cuerpo.position + Vector3(0, 1.4, 0) + adelante * 3.0, Vector3.UP)

# ============================================================== EL METRO

## Del pie de la escalera (o de la boca) al andén.
func _entrar_al_anden(a: Dictionary) -> void:
	_acc = a
	_linea = String(a["linea"])
	_idx = int(a["idx"])
	var l := metro.linea(_linea)
	var dir: Vector3 = l["dir"]
	var p: Vector3 = l["estaciones"][_idx]
	_anden_lon = dir.abs()
	_anden_lat = Vector3(dir.z, 0, -dir.x).abs()
	if bool(a["elevada"]):
		var lado := float(a.get("lado", 1.0))
		_anden_c = p + _anden_lat * lado * MetroCiudad.ANDEN_LAT
		_anden_c.y = MetroCiudad.ALTO_VIADUCTO + 0.6 + MetroCiudad.PISO_COCHE
		_anden_medio = Vector2(MetroCiudad.ANDEN_ANCHO * 0.5 - 0.4, MetroCiudad.ANDEN_LARGO * 0.5 - 1.0)
	else:
		_anden_c = p + _anden_lat * MetroCiudad.ANDEN_LAT * 1.6
		_anden_c.y = MetroCiudad.PROF_TUNEL + MetroCiudad.PISO_COCHE
		_anden_medio = Vector2(MetroCiudad.ANDEN_ANCHO * 1.1 - 0.5, MetroCiudad.ANDEN_LARGO * 0.5 - 1.0)
	estado = "anden"
	cuerpo.visible = true
	cuerpo.position = a["anden"] if bool(a["elevada"]) else _anden_c
	cuerpo.position.y = _anden_c.y
	_luz_cam.visible = not bool(a["elevada"])
	_bajo_tierra(not bool(a["elevada"]))
	if not bool(a["elevada"]):
		rumbo = atan2(_anden_lon.x, _anden_lon.z)
	_colocar_camara(1.0)

func _mover_en_anden(delta: float) -> void:
	var e := _entrada()
	var corre := Input.is_physical_key_pressed(KEY_SHIFT)
	vel = (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
	rumbo -= e.x * delta * 2.6
	if _anim != null:
		_anim.speed_scale = absf(vel) / 1.4 if absf(vel) > 0.05 else 0.0
	_sonar_pasos(vel)
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var p := cuerpo.position + adelante * vel * delta
	## No se atraviesa a la gente del andén: se la rodea (círculos, 16-10-2026).
	p = metro.apartar(p, 0.3)
	## Dentro del andén: ni a la vía ni fuera de la estación.
	var rel := p - _anden_c
	var la := clampf(rel.dot(_anden_lat), -_anden_medio.x, _anden_medio.x)
	var lo := clampf(rel.dot(_anden_lon), -_anden_medio.y, _anden_medio.y)
	cuerpo.position = _anden_c + _anden_lat * la + _anden_lon * lo
	cuerpo.rotation.y = rumbo
	_colocar_camara(delta)
	var k := metro.tren_parado_en(_linea, _idx)
	var eta := metro.eta_minima(_linea, _idx)
	var nombre := String(MetroCiudad.NOMBRES[_linea][_idx])
	_hud.text = Idiomas.t("Ⓜ %s · estación %s  ·  W/A/S/D · Mayús: correr · E: %s · Esc: mapa") % [
		_linea, nombre, Idiomas.t("subir al tren") if k >= 0 else Idiomas.t("salir a la calle")]
	if k >= 0:
		_aviso.text = Idiomas.t("🚇 Tren en el andén, puertas abiertas · E para subir")
	else:
		_aviso.text = Idiomas.t("Próximo tren: %s · E: salir a la calle") % ("llegando" if eta < 20.0 else "%d s" % int(eta))

func _usar_en_anden() -> void:
	var k := metro.tren_parado_en(_linea, _idx)
	if k >= 0:
		_subir_al_tren(k)
		return
	## Salir a la calle por donde se entró (o por la boca de esta estación).
	estado = "calle"
	_t_gente = -1000.0   ## al volver a la calle se llena el entorno
	_luz_cam.visible = false
	_bajo_tierra(false)
	var pie: Vector3 = _acc.get("pie", cuerpo.position)
	cuerpo.position = Vector3(pie.x, altura_suelo(pie.x, pie.z), pie.z)
	_colocar_camara(1.0)

func _subir_al_tren(k: int) -> void:
	estado = "tren"
	_tren_k = k
	_bajar_en_proxima = false
	_ventana = false
	cuerpo.visible = false
	_luz_cam.visible = true

func _viajar(delta: float) -> void:
	var l := metro.linea(_linea)
	var tren: Node3D = l["nodos"][_tren_k]
	_t_sacudida += delta
	var f := MetroCiudad.PISO_COCHE
	var t: MetroCiudad.Tren = l["trenes"][_tren_k]
	_actualizar_mano("tren", t.v * 3.6, MetroCiudad.VEL * 3.6, t.v * delta)
	var vaiven := sin(_t_sacudida * 9.0) * 0.012 * clampf(t.v / MetroCiudad.VEL, 0.0, 1.0)
	var local_pos := Vector3(0.45, f + 1.62 + vaiven, -5.0)
	var local_mira := Vector3(0.2, f + 1.45, 10.0)
	if _ventana:
		local_pos = Vector3(-0.6, f + 1.55 + vaiven, 0.0)
		local_mira = Vector3(6.0, f + 1.3, 0.5)
	camara.global_position = tren.global_transform * local_pos
	camara.look_at(tren.global_transform * local_mira, Vector3.UP)
	var parada := metro.estacion_del_tren(_linea, _tren_k)
	if parada >= 0 and _bajar_en_proxima and t.espera < MetroCiudad.PARADA - 1.0:
		_bajar_del_tren()
		return
	var prox := metro.proxima_de(_linea, _tren_k)
	_hud.text = Idiomas.t("🚇 %s · %s · %d km/h  ·  C: %s · Esc: mapa") % [_linea,
		(Idiomas.t("parado en %s") % String(MetroCiudad.NOMBRES[_linea][parada])) if parada >= 0 else (Idiomas.t("próxima: %s") % prox),
		int(t.v * 3.6), Idiomas.t("mirar al frente") if _ventana else Idiomas.t("mirar por la ventana")]
	if parada >= 0:
		_aviso.text = Idiomas.t("Puertas abiertas en %s · E: bajar aquí") % String(MetroCiudad.NOMBRES[_linea][parada])
	else:
		_aviso.text = Idiomas.t("Próxima estación: %s · E: %s") % [prox, Idiomas.t("no bajar") if _bajar_en_proxima else Idiomas.t("bajar en la próxima")]

func _bajar_del_tren() -> void:
	var parada := metro.estacion_del_tren(_linea, _tren_k)
	if parada < 0:
		return
	var l := metro.linea(_linea)
	var a := {"linea": _linea, "idx": parada, "elevada": bool(l["elevada"]), "nombre": String(MetroCiudad.NOMBRES[_linea][parada]), "lado": 1.0}
	## La salida a la calle de la estación de llegada.
	for acc: Dictionary in metro.accesos:
		if String(acc["linea"]) == _linea and int(acc["idx"]) == parada and float(acc.get("lado", 1.0)) > 0.0:
			a["pie"] = acc["pie"]
			a["anden"] = acc["anden"]
	if not a.has("anden"):
		a["anden"] = Vector3.ZERO
	_entrar_al_anden(a)
	if bool(a["elevada"]):
		var tren: Node3D = l["nodos"][_tren_k]
		cuerpo.position = Vector3(cuerpo.position.x, _anden_c.y, cuerpo.position.z)
		## Aparece frente a la puerta del coche central.
		var rel := tren.global_position - _anden_c
		var lo := clampf(rel.dot(_anden_lon), -_anden_medio.y, _anden_medio.y)
		cuerpo.position = _anden_c + _anden_lon * lo


## BAJO TIERRA el cielo de la ciudad no puede iluminar ni empañar: sin niebla y
## con poca luz ambiente (se restaura al salir).
var _env_guardado := {}
var _soles_apagados: Array = []

func _bajo_tierra(si: bool) -> void:
	## El entorno se guarda con lo demás: al cerrar el explorador bajo tierra la
	## cámara ya no está en el mundo, pero hay que devolver el sol igual.
	var env: Environment = _env_guardado.get("env") as Environment
	if env == null and camara != null and camara.is_inside_tree() and camara.get_world_3d() != null:
		env = camara.get_world_3d().environment
	if env == null:
		return
	if si and _env_guardado.is_empty():
		_env_guardado = {"env": env, "fog": env.fog_enabled, "amb": env.ambient_light_energy, "exp": env.tonemap_exposure,
			"vol": env.volumetric_fog_enabled}
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
		env.ambient_light_energy = 0.25
		env.tonemap_exposure = 0.9
		for n in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
			if (n as DirectionalLight3D).visible:
				(n as DirectionalLight3D).visible = false
				_soles_apagados.append(n)
		get_tree().call_group("rotulo_mapa", "hide")
	elif not si and not _env_guardado.is_empty():
		env.fog_enabled = _env_guardado["fog"]
		env.volumetric_fog_enabled = _env_guardado["vol"]
		env.ambient_light_energy = _env_guardado["amb"]
		env.tonemap_exposure = _env_guardado["exp"]
		for n in _soles_apagados:
			if is_instance_valid(n):
				(n as DirectionalLight3D).visible = true
		_soles_apagados.clear()
		if is_inside_tree():
			get_tree().call_group("rotulo_mapa", "show")
		_env_guardado = {}

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if trafico != null and is_instance_valid(trafico):
		trafico.jugador = null
	_bajo_tierra(false)
	_rotulos_de_paseo(false)
