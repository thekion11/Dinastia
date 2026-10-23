extends Node3D
## (Parte 1 de 6 de `explorador_ciudad.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `explorador_ciudad.gd`, conserva la clase.)

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

## Visión en primera persona (tecla V).
var primera_persona := false

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

## Círculos sólidos (farolas, troncos, coches aparcados...) por celdas de 8 m.
const CELDA_CIRC := 8.0
var _rej_circ := {}

## EL CHOQUE SE NOTA (21-10-2026, M-172): antes el coche se quedaba quieto en
## silencio. Ahora, según la velocidad: el golpe de chapa, la sacudida de la
## cámara y del mando y, contra otro coche o una persona a más de 25 km/h, la
## multa (el móvil avisa y se apunta en `multas`). Un choque cada medio
## segundo como mucho (al rozar una pared no suena en bucle).
var multas := 0
var _t_golpe := 0.0
var _sacudida_golpe := 0.0

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

var _es_dt := false

## Con el cuerpo del DT: «caminar» o «correr» al moverse y «parado» quieto.
## Pasos que suenan al andar a pie (etapa 1): uno cada ~0,7 m caminando y
## cada ~1,1 m corriendo.
var _hasta_paso := 0.0

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

var _capa: CanvasLayer

var _movil: MovilMano
var _boton_e: Button
var _ayudas := false
var _con_movil := true
var _m_antes := false
var _gps_oculto := false
var _minimapa: MinimapaCiudad

## CONTROLES TÁCTILES (el juego también va en Android): cruceta abajo a la
## izquierda, «E» y «Salir» abajo a la derecha. Mantener pulsado = tecla.
var _tactil_vec := Vector2.ZERO

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


## ============================================================ ENTRAR EN UN EDIFICIO
## La sala se levanta bajo el mapa (`_INT_ORIGEN`); el personaje camina dentro
## en tercera o primera persona y sale por la puerta (o con E).
const _INT_ORIGEN := Vector3(0.0, -400.0, 0.0)
var _int: InteriorInstalacion = null
var _int_raiz: Node3D = null
var _int_circulos := PackedVector3Array()
var _calle_pos := Vector3.ZERO
var _calle_rumbo := 0.0

## UNA CONVERSACIÓN CON UN VECINO (13-10-2026): tiene un OFICIO, habla en tres
## turnos (saludo según el ánimo del club, charla de su oficio, despedida), se
## gira hacia ti y gesticula; al acabar vuelve a andar.
var _rng_dialogo := RandomNumberGenerator.new()

## De vuelta a la calle, delante de la puerta del club.
var _rotulos_antes := true

## FUNDIDO al cambiar de sitio de golpe (puerta, escaleras, galería): la
## pantalla parte de negro y se aclara, en vez de saltar (etapa 1).
var _velo: ColorRect

# ---------------------------------------------------- la puerta y el portero

## Camino que el DT hace solo al cruzar la puerta (mundo).
var _auto: Array = []


## BAJO TIERRA el cielo de la ciudad no puede iluminar ni empañar: sin niebla y
## con poca luz ambiente (se restaura al salir).
var _env_guardado := {}
var _soles_apagados: Array = []
## Captura el cursor en primera persona (para mirar con el ratón) y lo suelta fuera.
func _raton_en_primera_persona() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if primera_persona and DisplayServer.get_name() != "headless" else Input.MOUSE_MODE_VISIBLE
func _sentado_fp() -> bool:
	return _sentado

## Las huellas sólidas: manzanas edificadas, edificios del núcleo e
## instalaciones (todo lo que `CityBuilder` apunta en `_frentes`).
static func construir_obstaculos(b: CityBuilder) -> Array[Rect2]:
	var sal: Array[Rect2] = []
	for r: Rect2 in b._frentes:
		sal.append(r)
	for r2: Rect2 in b.huellas:
		sal.append(r2)
	return sal

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

func _indexar_circulos() -> void:
	_rej_circ.clear()
	if cb == null:
		return
	for c: Vector3 in cb.circulos:
		var k := Vector2i(floori(c.x / CELDA_CIRC), floori(c.y / CELDA_CIRC))
		if not _rej_circ.has(k):
			_rej_circ[k] = []
		(_rej_circ[k] as Array).append(c)

func _buscar_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for h in n.get_children():
		var a := _buscar_anim(h)
		if a != null:
			return a
	return null

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

static func en_rio(x: float, z: float) -> bool:
	return absf(x - CityBuilder.RIO_X) < 50.0 and absf(z) < 1360.0

## Sobre el tablero o las rampas de un puente (calles horizontales de la rejilla).
static func en_puente(x: float, z: float) -> bool:
	var linea := snappedf(z, CiudadExpansion.CELDA)
	return absf(z - linea) < CiudadExpansion.ANCHO_AV * 0.5 - 1.0 and absf(x - CityBuilder.RIO_X) < 66.0

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

## Igual que `libre(p, radio, obstaculos)`, pero mirando solo la celda de `p`.
func libre_obst(p: Vector3, radio: float) -> bool:
	if radio > MARGEN_OBST:
		return libre(p, radio, obstaculos)
	var celda: Array[Rect2] = _rej_obst.get(Vector2i(floori(p.x / CELDA_OBST), floori(p.z / CELDA_OBST)), [] as Array[Rect2])
	return libre(p, radio, celda)

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

## Manzanas, río, círculos y móviles: todo lo que impide estar en `p`.
func libre_total(p: Vector3, radio: float) -> bool:
	return libre_obst(p, radio) and not _choca_circulos(p, radio) and not _choca_moviles(p, radio)

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
