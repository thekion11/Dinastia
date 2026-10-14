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

static var _inst: Retrato3D
static var _cache := {}
static var _cola: Array = []

var _vp: SubViewport
var _cam: Camera3D
var _ocupado := false
var _spawner := PlayerSpawner.new()

static func disponible() -> bool:
	return DisplayServer.get_name() != "headless" and Engine.get_main_loop() is SceneTree

## La textura del retrato 3D de `j`. `k1`/`k2`: colores de la camiseta; `alto_px`
## decide la resolución (de 120 para arriba, la grande).
static func textura(j: Jugador, k1: String, k2: String, alto_px: int = 64) -> Texture2D:
	var tam := TAM_GRANDE if alto_px >= 120 else TAM_CHICO
	var clave := "%s_%d_%s_%s" % [j.id, tam, k1, k2]
	if _cache.has(clave):
		return _cache[clave]
	var marcador := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	marcador.fill(Color(Color(k1).darkened(0.55), 1.0))
	var t := ImageTexture.create_from_image(marcador)
	_cache[clave] = t
	_cola.append({"j": j, "k1": k1, "k2": k2, "tam": tam, "tex": t})
	_arrancar()
	return t

static func _arrancar() -> void:
	if _inst != null and is_instance_valid(_inst):
		return
	var arbol := Engine.get_main_loop() as SceneTree
	_inst = Retrato3D.new()
	_inst.name = "Retrato3D"
	arbol.root.add_child.call_deferred(_inst)

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
	sol.rotation_degrees = Vector3(-28, 28, 0)
	sol.light_energy = 1.2
	_vp.add_child(sol)
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-10, -140, 0)
	relleno.light_energy = 0.45
	_vp.add_child(relleno)
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
	var j: Jugador = job["j"]
	var tam: int = job["tam"]
	var tex: ImageTexture = job["tex"]
	_vp.size = Vector2i(tam, tam)
	var env: Environment = (_vp.get_child(0) as WorldEnvironment).environment
	## Fondo: el color del club, nunca negro (las camisetas oscuras se perdían).
	var fondo := Color(job["k1"]).lerp(Color(0.2, 0.26, 0.23), 0.55)
	env.background_color = fondo.lightened(0.05) if fondo.get_luminance() < 0.1 else fondo
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	var datos := Puente3D.jugador(j)
	var look: Array = PlayerSpawner._look_de(datos)
	var puesto := "POR" if j.pos_e == "POR" else "DEL"
	var nodo := _spawner._crear_jugador(raiz, j.id, puesto, "", Color(job["k1"]), Color(job["k2"]), "liso",
		maxi(j.dorsal, 1), look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
	if not nodo.is_empty():
		var alto := PlayerSpawner.altura_de(datos, j.id, puesto)
		## De pecho para arriba, de frente (el modelo mira a +Z).
		_cam.position = Vector3(0.0, alto * 0.915, 1.62)
		_cam.look_at(Vector3(0.0, alto * 0.885, 0.0), Vector3.UP)
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
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
