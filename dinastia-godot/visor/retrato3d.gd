class_name Retrato3D
extends Node
## EL RETRATO ES EL MODELO 3D (14-10-2026, pedido del usuario: «cada nombre y cara
## de los jugadores debe corresponder al jugador real; no debe existir otras caras
## que no sean las versiones 3D»). Hasta hoy las fichas, listas, teléfono, prensa…
## pintaban un retrato 2D aparte (un SVG o la foto) que podía no parecerse al
## futbolista del campo. Ahora CUALQUIER cara que sale en pantalla es el busto del
## mismo modelo 3D que juega -misma cara, pelo, barba y piel, con la camiseta de su
## club- renderizado una vez y guardado en caché por jugador.
##
## Cómo: un `SubViewport` con mundo propio (en el árbol, invisible para el
## jugador) monta el modelo con `PlayerSpawner._crear_jugador` -el mismo camino que
## usa el partido-, lo encuadra de pecho para arriba, espera dos fotogramas y copia
## la imagen a una textura que ya estaba en la pantalla (un marcador de posición
## que se rellena en cuanto está lista: la interfaz no se bloquea). Los encargos
## se sirven de uno en uno, uno por fotograma.
##
## Sin pantalla (las pruebas en `--headless`) no hay nada que renderizar: ahí se
## devuelve el retrato antiguo para que la interfaz siga funcionando.

const TAM_CHICO := 128
const TAM_GRANDE := 256
const TAM_ESCAPARATE := 512   ## (17-11) las tarjetas del escaparate del menú central: 512 px, antialias 4x, FONDO TRANSPARENTE (se pone sobre una escena) y contraluz del color del club
## Hasta este alto en pantalla (filas de listas: 22-30 px) el busto de pecho para
## arriba dejaba la cara en 6 píxeles casi negros (s3, 26-10-2026, defecto que
## anotó la sesión 2): ahí se encuadra la cabeza con el cuello de la camiseta.
## (10-11, el dueño: «el corte de la cara en la alineación está mal, no se ve toda la cara») Subido de 40 a 70: las caras del campo de la plantilla
## (68 px en un aro de 48) y de la pizarra (42) salían como busto y la cara quedaba chica y cortada arriba. El busto queda para las fichas grandes.
const ALTO_CABEZA := 70
## Luminosidad mínima del fondo: con un club negro, fondo y camiseta se fundían.
const LUZ_FONDO := 0.2
const _RUTA_PERSONAJE_DT := "res://visor/personaje_dt.gd"
const _RUTA_PLAYER_SPAWNER := "res://visor/player_spawner.gd"
const _RUTA_VESTIDOR_Q := "res://visor/vestidor_q.gd"

static var _inst: Retrato3D
static var _cache := {}
static var _cola: Array = []

var _vp: SubViewport
var _cam: Camera3D
var _rim: DirectionalLight3D
var _sol: DirectionalLight3D
var _relleno: DirectionalLight3D
var _ocupado := false
var _spawner = load(_RUTA_PLAYER_SPAWNER).new()

static func disponible() -> bool:
	return DisplayServer.get_name() != "headless" and Engine.get_main_loop() is SceneTree

## La textura del retrato 3D de `j`. `k1`/`k2`: colores de la camiseta; `alto_px`
## decide la resolución (de 120 para arriba, la grande).
static func textura(j: Jugador, k1: String, k2: String, alto_px: int = 64) -> Texture2D:
	var tam := TAM_ESCAPARATE if alto_px >= 400 else (TAM_GRANDE if alto_px >= 120 else TAM_CHICO)
	var cabeza := alto_px <= ALTO_CABEZA
	var clave := "%s_%d_%s_%s%s" % [j.id, tam, k1, k2, "_c" if cabeza else ""]
	if _cache.has(clave):
		return _cache[clave]
	var t := ImageTexture.create_from_image(_vacio(tam) if tam == TAM_ESCAPARATE else _marcador(tam, fondo_de(k1)))
	_cache[clave] = t
	_cola.append({"j": j, "k1": k1, "k2": k2, "tam": tam, "tex": t, "cabeza": cabeza})
	_arrancar()
	return t

static func _arrancar() -> void:
	if _inst != null and is_instance_valid(_inst):
		return
	var arbol := Engine.get_main_loop() as SceneTree
	_inst = Retrato3D.new()
	_inst.name = "Retrato3D"
	arbol.root.add_child.call_deferred(_inst)

## EL DT EN 3D (s3, 26-10-2026; regla del dueño: nada de retratos 2D sueltos). El
## mismo busto que el de los jugadores, pero del personaje del entrenador
## (`PersonajeDT.crear`, la figura que sale en la banda): `aspecto` es el aspecto 3D
## guardado (`Roles.aspecto_3d()`). Mismo marcador, misma cola, misma caché.
static func textura_dt(aspecto: Dictionary, k1: String, k2: String, alto_px: int = 64) -> Texture2D:
	var tam := TAM_ESCAPARATE if alto_px >= 400 else (TAM_GRANDE if alto_px >= 120 else TAM_CHICO)
	var clave := "dt_%s_%d_%s_%s" % [str(hash(aspecto)), tam, k1, k2]
	if _cache.has(clave):
		return _cache[clave]
	var t := ImageTexture.create_from_image(_vacio(tam) if tam == TAM_ESCAPARATE else _marcador(tam, fondo_de(k1)))
	_cache[clave] = t
	_cola.append({"dt": aspecto, "k1": k1, "k2": k2, "tam": tam, "tex": t, "cabeza": alto_px <= ALTO_CABEZA})
	_arrancar()
	return t

## El fondo del retrato: el color del club hacia un verde oscuro, nunca más
## oscuro que `LUZ_FONDO` (antes un club negro daba un cuadro negro).
static func fondo_de(k1: String) -> Color:
	var f := Color(k1).lerp(Color(0.2, 0.26, 0.23), 0.55)
	var paso := 0
	while f.get_luminance() < LUZ_FONDO and paso < 8:
		f = f.lightened(0.08)
		paso += 1
	return f

## Mientras se pinta el busto: el fondo con una silueta clara (cabeza y hombros),
## para que la fila no sea un cuadro liso y oscuro.
static var _siluetas := {}
static func _marcador(tam: int, fondo: Color) -> Image:
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	img.fill(fondo)
	if not _siluetas.has(tam):
		var s := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
		var c := Color(1, 1, 1, 0.16)
		var r := float(tam) * 0.19
		var cab := Vector2(tam * 0.5, tam * 0.4)
		var hombro := Vector2(tam * 0.5, tam * 1.02)
		for y in tam:
			for x in tam:
				var p := Vector2(x + 0.5, y + 0.5)
				if p.distance_to(cab) < r or (p - hombro).length() < tam * 0.4:
					s.set_pixel(x, y, c)
		_siluetas[tam] = s
	img.blend_rect(_siluetas[tam], Rect2i(0, 0, tam, tam), Vector2i.ZERO)
	return img

static func _vacio(tam: int) -> Image:
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

## Los ajustes de un encargo grande (escaparate): fondo transparente, antialias 4x y el contraluz del color del club; los chicos, como siempre.
func _modo(tam: int, k1: String, env: Environment) -> bool:
	var escap := tam >= TAM_ESCAPARATE
	_vp.transparent_bg = escap
	_vp.msaa_3d = Viewport.MSAA_DISABLED if Calidad.elegida <= Calidad.MINIMO else (Viewport.MSAA_4X if escap else Viewport.MSAA_2X)   ## en ULTRA BAJA sin MSAA (orden R01)
	env.background_mode = Environment.BG_CLEAR_COLOR if escap else Environment.BG_COLOR
	_rim.light_energy = 1.1 if escap else 0.0
	## (17-11) luz más baja en el escaparate (igual que la previa del partido): las caras no se queman
	_sol.light_energy = 0.65 if escap else 1.2
	_relleno.light_energy = 0.2 if escap else 0.45
	env.tonemap_exposure = 0.72 if escap else 1.0
	_rim.light_color = Color(k1).lightened(0.35)
	return escap

static func limpiar_cache() -> void:
	_cache.clear()
	_cola.clear()

func _ready() -> void:
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = false
	_vp.msaa_3d = Viewport.MSAA_2X
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_vp.size = Vector2i(TAM_CHICO, TAM_CHICO)
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.8, 0.86)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var sol := DirectionalLight3D.new()
	_sol = sol
	sol.rotation_degrees = Vector3(-28, 28, 0)
	sol.light_energy = 1.2
	_vp.add_child(sol)
	var relleno := DirectionalLight3D.new()
	_relleno = relleno
	relleno.rotation_degrees = Vector3(-10, -140, 0)
	relleno.light_energy = 0.45
	_vp.add_child(relleno)
	_rim = DirectionalLight3D.new()   ## el contraluz de borde (solo en los retratos del escaparate)
	_rim.rotation_degrees = Vector3(-14, 152, 0)
	_rim.light_energy = 0.0
	_vp.add_child(_rim)
	_cam = Camera3D.new()
	_cam.fov = 21.0
	_vp.add_child(_cam)

func _process(_d: float) -> void:
	if _ocupado or _cola.is_empty():
		return
	_ocupado = true
	_servir.call_deferred()

func _servir() -> void:
	var job: Dictionary = _cola.pop_front()
	if job.has("dt"):
		await _servir_dt(job)
		_ocupado = false
		return
	var j: Jugador = job["j"]
	var tam: int = job["tam"]
	var tex: ImageTexture = job["tex"]
	_vp.size = Vector2i(tam, tam)
	var env: Environment = (_vp.get_child(0) as WorldEnvironment).environment
	## Fondo: el color del club, nunca negro (las camisetas oscuras se perdían).
	env.background_color = fondo_de(String(job["k1"]))
	var escap := _modo(tam, String(job["k1"]), env)
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	var datos := Puente3D.jugador(j)
	var look: Array = load(_RUTA_PLAYER_SPAWNER)._look_de(datos)
	var puesto := "POR" if j.pos_e == "POR" else "DEL"
	## La camiseta completa del CLUB del jugador (escudo y patrocinadores), si se sabe.
	var m := Mundo.actual()
	_spawner._kit_x = {}
	if m != null and m.clubes.has(j.club_id):
		_spawner._kit_x = load("res://ui/disenos_kit.gd").kit_de_club(m.clubes[j.club_id])
	## En los retratos la camiseta va con VOLUMEN (la ropa aparte, la prenda modelada
	## con mangas y bajo), aunque en el partido siga pintada sobre el cuerpo.
	var aparte_antes = load(_RUTA_VESTIDOR_Q).ropa_aparte
	load(_RUTA_VESTIDOR_Q).ropa_aparte = true
	var nodo = _spawner._crear_jugador(raiz, j.id, puesto, "", Color(job["k1"]), Color(job["k2"]), "liso",
		maxi(j.dorsal, 1), look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
	load(_RUTA_VESTIDOR_Q).ropa_aparte = aparte_antes
	if not nodo.is_empty():
		var alto = load(_RUTA_PLAYER_SPAWNER).altura_de(datos, j.id, puesto)
		## De pecho para arriba, de frente (el modelo mira a +Z); en las filas de las
		## listas, la cabeza y el cuello de la camiseta.
		if bool(job.get("cabeza", false)):
			_cam.position = Vector3(0.0, alto * 0.93, 1.1)   ## (10-11) algo más abierto: entran el pelo y la barbilla enteros
			_cam.look_at(Vector3(0.0, alto * 0.912, 0.0), Vector3.UP)
		elif escap:   ## (17-11) de la cintura para arriba y un poco más abierto: cabeza, hombros y la chaqueta del club
			_cam.position = Vector3(0.0, alto * 0.9, 2.15)   ## (17-11) más margen arriba: pelo y coronilla enteros
			_cam.look_at(Vector3(0.0, alto * 0.875, 0.0), Vector3.UP)
		else:
			_cam.position = Vector3(0.0, alto * 0.915, 1.62)
			_cam.look_at(Vector3(0.0, alto * 0.885, 0.0), Vector3.UP)
		await _fotografiar(raiz)
		var img := _vp.get_texture().get_image()
		_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		if img != null and not img.is_empty():
			img.convert(Image.FORMAT_RGBA8)
			if Vector2i(img.get_size()) == Vector2i(tex.get_size()):
				tex.update(img)
			else:
				tex.set_image(img)
	raiz.queue_free()
	_ocupado = false

## El encargo de un DT: su figura de `PersonajeDT`, encuadrada como la de un jugador.
func _servir_dt(job: Dictionary) -> void:
	var tam: int = job["tam"]
	var tex: ImageTexture = job["tex"]
	_vp.size = Vector2i(tam, tam)
	var env: Environment = (_vp.get_child(0) as WorldEnvironment).environment
	env.background_color = fondo_de(String(job["k1"]))
	var escap := _modo(tam, String(job["k1"]), env)
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	var d = load(_RUTA_PERSONAJE_DT).crear(raiz, job["dt"], Color(job["k1"]), Color(job["k2"]))
	if not d.is_empty():
		var alto = float(load(_RUTA_PERSONAJE_DT).aspecto(job["dt"]).get("altura", 1.78))
		if bool(job.get("cabeza", false)):
			_cam.position = Vector3(0.0, alto * 0.93, 1.1)   ## (10-11) algo más abierto: entran el pelo y la barbilla enteros
			_cam.look_at(Vector3(0.0, alto * 0.912, 0.0), Vector3.UP)
		elif escap:
			_cam.position = Vector3(0.0, alto * 0.9, 2.15)   ## (17-11) más margen arriba: pelo y coronilla enteros
			_cam.look_at(Vector3(0.0, alto * 0.875, 0.0), Vector3.UP)
		else:
			_cam.position = Vector3(0.0, alto * 0.915, 1.62)
			_cam.look_at(Vector3(0.0, alto * 0.885, 0.0), Vector3.UP)
		await _fotografiar(raiz)
		var img := _vp.get_texture().get_image()
		_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		if img != null and not img.is_empty():
			img.convert(Image.FORMAT_RGBA8)
			if Vector2i(img.get_size()) == Vector2i(tex.get_size()):
				tex.update(img)
			else:
				tex.set_image(img)
	raiz.queue_free()

## (3-11) La foto, igual siempre: la animación de reposo se congela en su primer instante (antes la pose dependía de
## cuándo se tomaba) y se espera a que el SubViewport se DIBUJE de verdad (antes eran 3 fotogramas de proceso, que en
## una máquina cargada o con el ahorro del menú podían no llegar a dibujar).
func _fotografiar(raiz: Node) -> void:
	await get_tree().process_frame
	for ap: Node in raiz.find_children("*", "AnimationPlayer", true, false):
		var a := ap as AnimationPlayer
		if a.current_animation != "":
			a.seek(0.0, true)
		a.pause()
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	## Dos dibujos de verdad, con tope: sin gráfica (pruebas sin pantalla) o si nada pide repintar, no llegan nunca.
	_dibujos = 0
	if not RenderingServer.frame_post_draw.is_connected(_contar_dibujo):
		RenderingServer.frame_post_draw.connect(_contar_dibujo)
	for i in 12:
		await get_tree().process_frame
		if _dibujos >= 2 and i >= 2:
			break

var _dibujos := 0
func _contar_dibujo() -> void:
	_dibujos += 1
