class_name GalaPremio3D
extends FestejoCampo3D
## LA ENTREGA DE CADA PREMIO DE «LA RUTA», EN 3D (13-11-2026, pedido del dueño: «animar el recibimiento de cada premio de
## forma única, según el país, la liga y el equipo; realista, en 3D, optimizado»). Sobre la base de los festejos (césped,
## grada en un MultiMesh, focos, papelitos, `FestejoCampo3D`) y con el MODELO REAL de tu jugador y sus animaciones.
## Cada premio tiene su GUION (`GalaGuiones.GUIONES`): dónde es (tu campo, la gala de tu liga, el estadio de la final o la
## gala mundial), qué galardón te dan (hecho por código, `GalaObjetos`), cómo lo celebras y cómo se mueve la cámara.
## Lo que cambia con tu carrera: los colores y el escudo de tu club, la bandera del país de tu liga, el nombre de la liga y
## el del premio en el fondo, tus compañeros (los de tu plantilla) y las banderas de la gala mundial (las ligas de tu mundo).
## La escena: entras caminando, te dan el galardón y lo celebras. Coste: tu jugador + 1 a 4 más, una grada o un patio de
## butacas en UNA llamada. Sin pantalla o en calidad mínima no se monta (`crear` devuelve null).

var premio := ""
var guion: Dictionary = {}
var _yo: Node3D
var _yo_anim: AnimationPlayer
var _objeto: Node3D
var _atril := Vector3(1.0, 1.25, 0.2)
var _suelo := 0.0
var _fase := 0
var _destellos: Array[OmniLight3D] = []
var _confeti: CPUParticles3D
var _esq: Skeleton3D
var _mano := -1   ## el hueso de la mano derecha: el galardón va EN la mano y sube y baja con el gesto

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
	## Quien entrega: en el campo, tu capitán; en las galas, alguien de traje oscuro.
	var entrega: Jugador = GalaGuiones.quien_entrega(club, j)
	if entrega != null:
		var traje := lugar in ["gala", "mundo"]
		_jugador(raiz, spawner, entrega, Vector3(1.7, _suelo, 0.1), -PI * 0.5, "aplaudir|idle", Color(0.1, 0.11, 0.14) if traje else c1, Color(0.2, 0.2, 0.24) if traje else c2, 0.4)
	## Tú: de gala en las galas (los colores del traje), con tu equipación en el césped.
	var de_gala := lugar in ["gala", "mundo"]
	_yo = _jugador(raiz, spawner, j, Vector3(-4.2, _suelo, 0.2), PI * 0.5, "caminar|trotar|idle", Color(0.07, 0.08, 0.11) if de_gala else c1, Color(0.16, 0.17, 0.21) if de_gala else c2)
	var aps := _yo.find_children("*", "AnimationPlayer", true, false)
	_yo_anim = aps[0] if not aps.is_empty() else null
	var esqs := _yo.find_children("*", "Skeleton3D", true, false)
	if not esqs.is_empty():
		_esq = esqs[0]
		for hueso: String in ["hand_r", "RightHand", "Hand.R", "mano_d"]:
			if _mano < 0:
				_mano = _esq.find_bone(hueso)
		if _mano >= 0:   ## el galardón se coloca DESPUÉS de que la animación mueva el esqueleto (si no, va un fotograma por detrás de la mano)
			_esq.skeleton_updated.connect(_seguir_mano)
	if spawner is Node:
		(spawner as Node).queue_free()
	_objeto = GalaObjetos.crear(String(guion["objeto"]), club)
	_objeto.scale = Vector3.ONE * 1.35
	_atril.y += _suelo
	_objeto.position = _atril
	raiz.add_child(_objeto)
	_confeti = GalaGuiones.confeti(self, raiz, c1, c2, String(guion.get("extra", "")))
	if String(guion.get("extra", "")) == "cohetes":
		_cohetes(raiz, c1, c2)
	if String(guion.get("extra", "")) == "flashes" or lugar in ["gala", "mundo"]:
		for k in 3:
			var o := OmniLight3D.new()
			o.position = Vector3(-3.0 + k * 3.0, 1.6, 6.0)
			o.omni_range = 11.0
			o.light_energy = 0.0
			raiz.add_child(o)
			_destellos.append(o)
	_cam = Camera3D.new()
	_cam.fov = 38.0
	_vp.add_child(_cam)
	_colocar_camara()

func _seguir_mano() -> void:
	if _fase == 2 and _objeto != null:
		_objeto.global_position = _esq.global_transform * _esq.get_bone_global_pose(_mano).origin + Vector3(0, 0.04, 0.06)

func _pon_anim(nombres: String) -> void:
	if _yo_anim == null:
		return
	for a: String in nombres.split("|"):
		if _yo_anim.has_animation(a):
			_yo_anim.play(a)
			return

func _colocar_camara() -> void:
	var centro := Vector3(-0.6, _suelo + 1.3, 0.2)
	var cerca := clampf((_t - 3.2) / 2.5, 0.0, 1.0)   ## tras la entrega, la cámara se acerca
	var pos: Vector3
	match String(guion.get("camara", "orbita")):
		"frontal":
			pos = Vector3(-0.6 + sin(_t * 0.25) * 0.6, _suelo + 1.6, lerpf(8.5, 4.6, cerca))
		"contrapicado":
			pos = Vector3(-0.6 + sin(_t * 0.2) * 1.8, _suelo + 0.5, lerpf(7.0, 4.2, cerca))
			centro.y += 0.3
		"travelling":
			pos = Vector3(lerpf(-5.0, 2.5, clampf(_t / 9.0, 0.0, 1.0)), _suelo + 1.9, lerpf(8.0, 5.2, cerca))
		"alta":
			pos = Vector3(sin(_t * 0.18) * 4.0, _suelo + lerpf(5.5, 2.6, cerca), lerpf(9.5, 5.5, cerca))
		_:
			var ang := -0.5 + _t * 0.12
			pos = Vector3(-0.6 + sin(ang) * lerpf(8.0, 5.0, cerca), _suelo + 2.0, cos(ang) * lerpf(8.0, 5.0, cerca))
	_cam.transform = Transform3D(Basis(), pos).looking_at(centro, Vector3.UP)

func _process(d: float) -> void:
	if _cam == null or _yo == null:
		return
	_t += d
	_colocar_camara()
	## 0 → 2,2 s: entras; 2,2 → 3,4 s: te lo entregan; después, lo celebras a tu manera.
	if _t < 2.2:
		_yo.position.x = lerpf(-4.2, -0.6, _t / 2.2)
	elif _fase == 0:
		_fase = 1
		_yo.position.x = -0.6
		_yo.rotation.y = 0.0
		_pon_anim("idle|aplaudir")
	## Dónde lo llevas: en la mano derecha si el modelo la tiene (sube con el brazo); si no, delante del pecho.
	var manos := _yo.position + Vector3(0.0, 1.25, 0.42)
	if _esq != null and _mano >= 0:
		manos = _esq.global_transform * _esq.get_bone_global_pose(_mano).origin + Vector3(0, 0.04, 0.06)
	if _fase == 1:
		_objeto.position = _atril.lerp(manos, clampf((_t - 2.2) / 1.2, 0.0, 1.0))
		if _t >= 3.4:
			_fase = 2
			_pon_anim(String(guion["anim"]))
			if _confeti != null:
				_confeti.emitting = true
	elif _fase == 2:
		_objeto.position = manos
		_objeto.rotation.y = sin(_t * 0.7) * 0.5
	for k in _destellos.size():
		_destellos[k].light_energy = maxf(0.0, 1.0 - fmod(_t + k * 0.83, 2.1) * 5.0) * (7.0 if _fase == 2 else 2.0)
