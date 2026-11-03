extends Node
## ARENA DE PRUEBAS (P5, 3-11): un banco aislado para probar UNA pieza del partido sola, mirarla desde cuatro cámaras a la vez y medirla.
## Monta SOLO lo pedido: cancha + N jugadores + árbitro (+ balón), sin público, sin ciudad, sin menú. Todo por variables de entorno:
##
##   ARENA=cancha|jugador|arbitro|balon|porteria|partido    qué se monta (por defecto «jugador»)
##   N=11            jugadores por equipo en «partido» (1 en «jugador», «arbitro» y «balon»; «porteria»: un tirador y el portero)
##   CAMARAS=4       cuántas de las cuatro vistas se dibujan (1 = medir la pieza sin el coste de las otras tres)
##   VELOCIDAD=1     reloj acelerado (Engine.time_scale; T en vivo: 1-2-4-8)
##   DURACION=0      segundos de reloj de pared; 0 = hasta cerrar (en headless, 8 por defecto)
##   CALIDAD=minima|media|alta|ultra      (por defecto la elegida del juego)
##   MOTOR=0|1       el motor jugable lleva a los 22 (1 en «partido» y «balon»/«porteria», 0 en el resto)
##   ESTADIO=0|1     monta además el estadio entero (público, vallas, focos) para medir lo que cuesta
##   SEMILLA=4711    mundo y motor
##   ANIM_T=0.5      con ANIM, congela el clip a esa fracción de su duración
##   ANIM=clip       el primer jugador repite ese clip (p. ej. entrada_tijera, estirada_alta_der); SIN_ANCLA=1 le quita AnclaSuelo (P4)
##   CAPTURA=ruta.jpg   guarda la pantalla a los 4 s (revisión a ojo sin GPU)
##
##   godot --path . --rendering-driver vulkan --resolution 1280x720 res://pruebas/arena/arena.tscn
##   ARENA=arbitro CAMARAS=1 DURACION=10 godot --headless --path . res://pruebas/arena/arena.tscn   (métricas en /tmp/arena_arbitro.csv)
## Teclas: 1-4 una cámara a pantalla completa · 0 la cuadrícula · T velocidad · Esc salir. Ver `ArenaMetricas` y `ArenaCamaras`.

var modo := "jugador"
var _camaras: ArenaCamaras
var _metricas: ArenaMetricas
var _raiz: Node3D
var _motor: MotorJugable
var _lista: Array = []
var _balon: Node3D
var _rotulo: Label
var _t := 0.0
var _duracion := 0.0
var _proximo_toque := 1.0
var _capturada := false

static func _env(nombre: String, defecto: String) -> String:
	var v := OS.get_environment(nombre)
	return v if v != "" else defecto

func _ready() -> void:
	modo = _env("ARENA", "jugador").to_lower()
	var nivel := _calidad(_env("CALIDAD", ""))
	Calidad.elegida = nivel
	Engine.max_fps = 0
	Engine.time_scale = float(_env("VELOCIDAD", "1"))
	_duracion = float(_env("DURACION", "8" if DisplayServer.get_name() == "headless" else "0"))
	var mundo := Mundo.new()
	mundo.generar(["CHI"], int(_env("SEMILLA", "4711")))
	var a: Club = mundo.ligas[0].clubes[0]
	var b: Club = mundo.ligas[0].clubes[1]
	_camaras = ArenaCamaras.new()
	add_child(_camaras)
	_raiz = _camaras.montar(clampi(int(_env("CAMARAS", "4")), 1, 4), nivel)
	_camaras.escala = 1.0 if modo in ["cancha", "partido", "porteria"] else 0.3
	var perfil := mundo.perfil_estadio_de(a).duplicate()
	Ambience.apply(_raiz, perfil, null, nivel)
	StadiumBuilder.build_pitch(_raiz, perfil, a)
	if _env("ESTADIO", "0") == "1":
		StadiumBuilder.build(_raiz, perfil, int(perfil.get("aforo", 20000)), 0.8, a._hash_id(), a)
	_montar_jugadores(a, b)
	_camaras.foco = _foco
	_metricas = ArenaMetricas.new()
	add_child(_metricas)
	_metricas.iniciar(modo)
	_rotulo = Label.new()
	_rotulo.position = Vector2(10, 26)
	_rotulo.add_theme_font_size_override("font_size", 13)
	_rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	_rotulo.add_theme_constant_override("outline_size", 4)
	add_child(_rotulo)

func _calidad(nombre: String) -> int:
	match nombre.to_lower():
		"minima", "minimo", "mínima", "mínimo": return Calidad.MINIMO
		"media", "medio": return Calidad.MEDIO
		"alta", "alto": return Calidad.ALTO
		"ultra": return Calidad.ULTRA
	return Calidad.elegida

## Lo que cada modo pone en el campo. Los jugadores salen de los dos primeros clubes de un mundo ficticio de semilla fija.
func _montar_jugadores(a: Club, b: Club) -> void:
	if modo == "cancha":
		return
	var n := int(_env("N", "11")) if modo == "partido" else (2 if modo == "porteria" else 1)
	var sp := PlayerSpawner.new()
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	var xi_l: Array = l["xi"].slice(0, n) if modo == "partido" else [l["xi"][5]]
	var xi_v: Array = v["xi"].slice(0, n) if modo == "partido" else ([v["xi"][0]] if modo == "porteria" else [])
	_lista.append_array(sp.spawn_team(_raiz, xi_l, l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	if not xi_v.is_empty():
		_lista.append_array(sp.spawn_team(_raiz, xi_v, v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	if modo in ["partido", "arbitro"]:
		_lista.append_array(sp.spawn_arbitros(_raiz, Puente3D.kit_arbitro(Puente3D.kit(a), Puente3D.kit(b), 1, [Puente3D.kit_portero(a), Puente3D.kit_portero(b)])))
	if modo in ["jugador", "arbitro"]:
		for p: Dictionary in _lista:
			if p.has("base_pos"):
				(p["node"] as Node3D).position = Vector3(0, 0, 0)
	if _env("ANIM", "") != "" and not _lista.is_empty():
		var ap: AnimationPlayer = _lista[0]["anim"]
		if ap.has_animation(_env("ANIM", "")):
			ap.get_animation(_env("ANIM", "")).loop_mode = Animation.LOOP_LINEAR
			ap.play(_env("ANIM", ""))
			if _env("ANIM_T", "") != "":   ## congela el clip en esa fracción (0-1) de su duración
				ap.seek(float(_env("ANIM_T", "0")) * ap.get_animation(_env("ANIM", "")).length, true)
				ap.pause()
		if _env("SIN_ANCLA", "0") == "1":
			var an := (_lista[0]["node"] as Node).find_child("AnclaSuelo", false, false)
			if an != null:
				an.queue_free()
	if modo in ["partido", "balon", "porteria"]:
		_balon = StadiumBuilder.spawn_ball(_raiz, Vector3(0, 0.11, 0))
	var con_motor := _env("MOTOR", "1" if modo in ["partido", "balon", "porteria"] else "0") == "1"
	if con_motor and _balon != null:
		_motor = MotorJugable.new()
		add_child(_motor)
		_motor.autopiloto = modo == "partido"
		_motor.preparar(_lista.filter(func(p: Dictionary) -> bool: return p.has("base_pos") and p.has("id") and str(p["id"]) != "arbitro" and not str(p["id"]).begins_with("linea")), _balon, "", int(_env("SEMILLA", "4711")))
		if modo == "partido":
			_motor._saque_de_centro(true)

## Qué miran las cámaras: el balón si lo hay, si no el primer jugador, si no el centro.
func _foco() -> Vector3:
	if _balon != null and is_instance_valid(_balon):
		return _balon.position
	if not _lista.is_empty() and is_instance_valid(_lista[0]["node"]):
		return (_lista[0]["node"] as Node3D).position
	return Vector3.ZERO

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.0001)
	_t += real
	## «balon» y «porteria»: un toque cada tres segundos de reloj de juego, para ver rodar, botar y entrar el balón.
	if _motor != null and modo in ["balon", "porteria"]:
		_proximo_toque -= delta
		if _proximo_toque <= 0.0:
			_proximo_toque = 3.0
			var rng := RandomNumberGenerator.new()
			rng.seed = int(_t * 1000.0)
			_motor.estado = "juego"
			_motor.poseedor = {}
			_balon.position = Vector3(rng.randf_range(-6, 6), 0.11, 20.0 if modo == "porteria" else 0.0)
			var hacia := Vector3(rng.randf_range(-3.2, 3.2), rng.randf_range(0.0, 2.0), 52.0) - _balon.position if modo == "porteria" else Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1))
			_motor.vel_balon = hacia.normalized() * (rng.randf_range(14.0, 26.0) if modo == "porteria" else rng.randf_range(6.0, 16.0))
			_motor.vel_balon.y += 3.0
	_rotulo.text = "ARENA «%s» · ×%.0f · %s\n%s" % [modo, Engine.time_scale, _metricas.resumen_corto(), "1-4 cámara · 0 cuadrícula · T velocidad · Esc salir"]
	if not _capturada and _t >= 4.0 and _env("CAPTURA", "") != "":
		_capturada = true
		get_viewport().get_texture().get_image().save_jpg(_env("CAPTURA", ""), 0.9)
	if _duracion > 0.0 and _t >= _duracion:
		_metricas.imprimir_resumen()
		get_tree().quit()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		var k := (e as InputEventKey).keycode
		if k == KEY_T:
			Engine.time_scale = 1.0 if Engine.time_scale >= 8.0 else Engine.time_scale * 2.0
		elif k == KEY_ESCAPE:
			_metricas.imprimir_resumen()
			get_tree().quit()
