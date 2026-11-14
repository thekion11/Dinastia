class_name GalaPremio3D
extends FestejoCampo3D
## LA ENTREGA DE CADA PREMIO DE «LA RUTA», EN 3D (13-11-2026, pedido del dueño: «animar el recibimiento de cada premio de
## forma única, según el país, la liga y el equipo; realista, en 3D, optimizado»). Sobre la base de los festejos (césped,
## grada en un MultiMesh, focos, papelitos, `FestejoCampo3D`) y con el MODELO REAL de tu jugador y sus animaciones.
## Cada premio tiene su GUION (`GalaGuiones.GUIONES`): dónde es (tu campo, la gala de tu liga, el estadio de la final o la
## gala mundial), qué galardón te dan (hecho por código, `GalaObjetos`), cómo lo celebras y cómo se mueve la cámara.
## Lo que cambia con tu carrera: los colores y el escudo de tu club, la bandera del país de tu liga, el nombre de la liga y
## el del premio en el fondo, tus compañeros (los de tu plantilla) y las banderas de la gala mundial (las ligas de tu mundo).
## La escena (13-11 noche, dueño: «que vaya a la copa, la tome de forma natural y celebre mientras le sacan fotos»):
## caminas hasta el pedestal, alargas las DOS manos hacia el galardón (`BrazosIK` en los brazos, con la influencia
## subiendo de 0 a 1), lo levantas mientras te giras hacia las cámaras y lo celebras con él EN las manos; delante, los
## fotógrafos (agachados y de pie) disparan sus flashes. Coste: tu jugador + 1 a 4 más, una grada o un patio de
## butacas en UNA llamada. Sin pantalla o en calidad mínima no se monta (`crear` devuelve null).

var premio := ""
var guion: Dictionary = {}
var fotografos := 0   ## cuántos se montaron (lo lee la prueba)
var _yo: Node3D
var _yo_anim: AnimationPlayer
var _objeto: Node3D
var _pedestal := Vector3(0.7, 1.0, 0.2)   ## dónde espera el galardón (la y, sobre el suelo del lugar)
var _suelo := 0.0
var _fase := 0   ## 0 camina · 1 alarga las manos · 2 lo levanta y se gira · 3 lo celebra
var _flashes: Array[OmniLight3D] = []
var _confeti: CPUParticles3D
var _esq: Skeleton3D
var _ik: SkeletonModifier3D
var _mano_d: Node3D
var _mano_i: Node3D

const T_LLEGA := 2.4
const T_AGARRA := 3.3
const T_ARRIBA := 4.6
const PARADO_EN := -0.02   ## donde te detienes, a un brazo del pedestal

## `datos`: {jugador, club, liga (nombre), pais (código), mundo}. Devuelve null sin pantalla.
static func crear_gala(id: String, datos: Dictionary) -> GalaPremio3D:
	var club: Club = datos.get("club")
	var j: Jugador = datos.get("jugador")
	if DisplayServer.get_name() == "headless" or club == null or j == null or not GalaGuiones.GUIONES.has(id):
		return null
	var g := GalaPremio3D.new()
	g.premio = id
	g.guion = GalaGuiones.GUIONES[id]
	g.stretch = true
	g.custom_minimum_size = Vector2(640, 300)
	g._vp = SubViewport.new()
	g._vp.own_world_3d = true
	g._vp.msaa_3d = Calidad.msaa_ui(Viewport.MSAA_2X)
	g.add_child(g._vp)
	g._montar_gala(datos, club, j)
	return g

func _montar_gala(datos: Dictionary, club: Club, j: Jugador) -> void:
	var c1 := Color(club.color1)
	var c2 := Color(club.color2)
	var lugar := String(guion["lugar"])
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.06) if lugar in ["campo", "estadio"] else Color(0.03, 0.02, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.7)
	env.ambient_light_energy = 0.6 if lugar in ["campo", "estadio"] else 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = Calidad.elegida > Calidad.BAJA
	env.glow_intensity = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	var spawner = load("res://visor/player_spawner.gd").new()
	var titulo := Idiomas.t(String(CarreraPremios.PREMIOS[premio][0])) if CarreraPremios.PREMIOS.has(premio) else Nombres.visible(String(datos.get("titulo", "")))
	match lugar:
		"campo":
			_cesped(raiz)
			_grada(raiz, c1, c2)
			_focos(raiz)
			GalaGuiones.companeros(self, raiz, spawner, club, j, c1, c2)
		"estadio":
			_cesped(raiz)
			_grada(raiz, c1, c2)
			_focos(raiz)
			_suelo = GalaGuiones.tarima(self, raiz, c1, titulo)
		_:
			_suelo = GalaGuiones.salon(self, raiz, datos, club, titulo, lugar == "mundo")
	var de_gala := lugar in ["gala", "mundo"]
	## El pedestal con el galardón encima.
	_pedestal.y += _suelo
	_caja(raiz, Vector3(_pedestal.x, _suelo + 0.5, _pedestal.z), Vector3(0.42, 1.0, 0.42), _mat(Color(0.1, 0.1, 0.13), 0.35))
	_caja(raiz, Vector3(_pedestal.x, _pedestal.y - 0.015, _pedestal.z), Vector3(0.48, 0.03, 0.48), _mat(Color(0.95, 0.78, 0.3), 0.3, 1.2))
	_objeto = GalaObjetos.crear(String(guion["objeto"]), club)
	_objeto.scale = Vector3.ONE * 1.35
	_objeto.position = _pedestal
	raiz.add_child(_objeto)
	## Quien preside: en el campo, tu capitán; en las galas, alguien de oscuro. Aplaude a un lado.
	var preside: Jugador = GalaGuiones.quien_entrega(club, j)
	if preside != null:
		_jugador(raiz, spawner, preside, Vector3(2.3, _suelo, -0.3), -PI * 0.3, "aplaudir|parado", Color(0.1, 0.11, 0.14) if de_gala else c1, Color(0.2, 0.2, 0.24) if de_gala else c2, 0.4)
	## Tú: de oscuro en las galas, con tu equipación en el césped. Entras caminando hacia el pedestal.
	_yo = _jugador(raiz, spawner, j, Vector3(-4.2, _suelo, _pedestal.z), PI * 0.5, "caminar|trotar", Color(0.07, 0.08, 0.11) if de_gala else c1, Color(0.16, 0.17, 0.21) if de_gala else c2)
	var aps := _yo.find_children("*", "AnimationPlayer", true, false)
	_yo_anim = aps[0] if not aps.is_empty() else null
	var esqs := _yo.find_children("*", "Skeleton3D", true, false)
	if not esqs.is_empty():
		_esq = esqs[0]
		_montar_brazos()
	_flashes = GalaGuiones.fotografos(self, raiz, spawner, club, j, _suelo)
	if spawner is Node:
		(spawner as Node).queue_free()
	_confeti = GalaGuiones.confeti(self, raiz, c1, c2, String(guion.get("extra", "")))
	if String(guion.get("extra", "")) == "cohetes":
		_cohetes(raiz, c1, c2)
	_cam = Camera3D.new()
	_cam.fov = 38.0
	_vp.add_child(_cam)
	_colocar_camara()

## Los dos brazos con cinemática inversa hacia dos puntos del galardón (uno por mano). Empieza sin influencia.
func _montar_brazos() -> void:
	if _esq.find_bone("hand_r") < 0 or _esq.find_bone("hand_l") < 0:
		return
	_mano_d = Node3D.new()
	_mano_i = Node3D.new()
	_objeto.add_child(_mano_d)
	_objeto.add_child(_mano_i)
	_ik = GalaGuiones.brazos_a(_esq, _mano_d, _mano_i)
	if _ik != null:
		_ik.influence = 0.0

func _pon_anim(nombres: String) -> void:
	if _yo_anim == null:
		return
	for a: String in nombres.split("|"):
		if _yo_anim.has_animation(a):
			_yo_anim.play(a)
			return

func _colocar_camara() -> void:
	var centro := Vector3(0.1, _suelo + 1.35, _pedestal.z)
	var cerca := clampf((_t - T_AGARRA) / 2.5, 0.0, 1.0)   ## al levantarlo, la cámara se acerca (siempre por detrás de los fotógrafos)
	var pos: Vector3
	match String(guion.get("camara", "orbita")):
		"frontal":
			pos = Vector3(0.1 + sin(_t * 0.25) * 0.6, _suelo + 1.6, lerpf(9.0, 6.4, cerca))
		"contrapicado":
			pos = Vector3(0.1 + sin(_t * 0.2) * 1.8, _suelo + 0.7, lerpf(8.5, 6.2, cerca))
			centro.y += 0.25
		"travelling":
			pos = Vector3(lerpf(-4.5, 3.0, clampf(_t / 9.0, 0.0, 1.0)), _suelo + 1.9, lerpf(9.0, 6.6, cerca))
		"alta":
			pos = Vector3(sin(_t * 0.18) * 3.5, _suelo + lerpf(5.0, 2.8, cerca), lerpf(10.0, 7.0, cerca))
		_:
			var ang := -0.45 + _t * 0.1
			pos = Vector3(0.1 + sin(ang) * lerpf(9.0, 6.6, cerca), _suelo + 2.0, cos(ang) * lerpf(9.0, 6.6, cerca))
	_cam.transform = Transform3D(Basis(), pos).looking_at(centro, Vector3.UP)

## Dónde llevas el galardón (su base), según cómo lo celebra este premio: arriba (sobre la cabeza), pecho o beso.
func _porte(celebrando: float) -> Vector3:
	var frente := Vector3(sin(_yo.rotation.y), 0, cos(_yo.rotation.y))
	var pecho := _yo.position + Vector3(0, 1.12, 0) + frente * 0.42
	match String(guion.get("porte", "arriba")):
		"pecho":
			return pecho + Vector3(0, 0.12 * celebrando + sin(_t * 2.0) * 0.03 * celebrando, 0)
		"beso":
			var sube := (sin(_t * 1.6) * 0.5 + 0.5) * celebrando
			return pecho.lerp(_yo.position + Vector3(0, 1.42, 0) + frente * 0.3, sube)
		_:
			return pecho.lerp(_yo.position + Vector3(0, 1.66 + absf(sin(_t * 1.8)) * 0.12, 0) + frente * 0.22, celebrando)

func _process(d: float) -> void:
	if _cam == null or _yo == null:
		return
	_t += d
	_colocar_camara()
	## Las manos van a los lados del galardón, a media altura.
	if _mano_d != null:
		var agarre := float(guion.get("agarre", 0.075))   ## en metros del galardón (va a escala 1,35): las palmas pegadas a sus lados
		_mano_d.position = Vector3(-agarre, 0.2, 0.02)
		_mano_i.position = Vector3(agarre, 0.2, 0.02)
	if _t < T_LLEGA:   ## 0: camina hasta el pedestal
		_yo.position.x = lerpf(-4.2, PARADO_EN, _t / T_LLEGA)
	elif _t < T_AGARRA:   ## 1: se para y alarga las manos
		if _fase == 0:
			_fase = 1
			_yo.position.x = PARADO_EN
			_pon_anim("parado|aplaudir")
			Sonido.toca("flashes", Sonido.Bus.INTERFAZ, -6.0)
		if _ik != null:
			_ik.influence = smoothstep(0.0, 1.0, (_t - T_LLEGA) / (T_AGARRA - T_LLEGA))
	elif _t < T_ARRIBA:   ## 2: lo levanta del pedestal y se gira hacia las cámaras
		_fase = 2
		var k := smoothstep(0.0, 1.0, (_t - T_AGARRA) / (T_ARRIBA - T_AGARRA))
		_yo.rotation.y = lerpf(PI * 0.5, 0.0, k)
		_objeto.position = _pedestal.lerp(_porte(0.0), k)
		_objeto.rotation.y = _yo.rotation.y
	else:   ## 3: lo celebra con él en las manos
		if _fase != 3:
			_fase = 3
			_yo.rotation.y = 0.0
			_pon_anim(String(guion["anim"]))
			Sonido.toca("ovacion" if String(guion["lugar"]) in ["campo", "estadio"] else "aplauso", Sonido.Bus.INTERFAZ)
			Sonido.toca("flashes", Sonido.Bus.INTERFAZ)
			if _confeti != null:
				_confeti.emitting = true
		_objeto.position = _porte(clampf((_t - T_ARRIBA) / 0.8, 0.0, 1.0))
		_objeto.rotation.y = sin(_t * 0.7) * 0.25
	## Los flashes: sueltos mientras llegas, en ráfaga cuando lo levantas.
	for i in _flashes.size():
		var ritmo := 1.1 if _fase >= 2 else 2.6
		_flashes[i].light_energy = maxf(0.0, 1.0 - fmod(_t * (1.0 + i * 0.13) + i * 0.71, ritmo) * 9.0) * (9.0 if _fase >= 2 else 4.0)
