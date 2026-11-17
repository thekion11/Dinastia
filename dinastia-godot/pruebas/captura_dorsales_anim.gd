extends Node
## DORSALES Y ANIMACIÓN (17-11): fotos ANTES/DESPUÉS de la espalda de los futbolistas (dorsal y nombre) y de su carrera, con la
## CÁMARA REAL de TV del partido (estadio, motor por defecto) y de cerca: detrás del jugador más cercano al balón (espalda) y de
## lado (carrera y giro). Un cruce de DOS países (PAIS=ARG,ESP: local del primero, visita del segundo); variar los países en cada
## tanda (regla 34). Mide además las llamadas de dibujo y los triángulos de la vista de TV.
##   PAIS=BRA,JPN ETIQUETA=despues SALIDA=/ruta herramientas/captura.sh res://pruebas/captura_dorsales_anim.tscn
var _n := 0
var _vista: VistaEstadio
var _pais := "ARG"
var _cam_cerca: Camera3D
var _fotos := 0
var _ultima := 0
var _sigue: Dictionary = {}

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTA)
	if OS.get_environment("CALIDAD") == "minima":
		Calidad.elegida = Calidad.ULTRA_BAJA   ## (17-11) CALIDAD=minima: la MÍNIMA del juego (las fotos llevan «_minima»)
	var paises: Array[String] = []
	for q in (OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "ARG,ESP").split(",", false):
		paises.append(String(q))
	_pais = "_".join(paises)
	var m := Mundo.new()
	m.generar(paises, 4711)
	var a: Club = null
	var b: Club = null
	for liga: Liga in m.ligas:
		if int(liga.div) == 1:
			if liga.pais == paises[0] and a == null:
				a = liga.clubes[3]
			elif liga.pais == paises[paises.size() - 1] and b == null:
				b = liga.clubes[5]
	m.mi_club_id = a.id
	Partido.ctx_club_id = m.mi_club_id
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(a, 0.85, b, Partido.new(a, b))
	print("CRUCE %s (%s) - %s (%s)" % [a.nombre, paises[0], b.nombre, paises[paises.size() - 1]])

func _foto(nombre: String) -> void:
	var dir := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://"
	var cal := "_minima" if OS.get_environment("CALIDAD") == "minima" else ""
	var ruta := "%s/%s%s_%s_%s.jpg" % [dir, nombre, cal, _pais.to_lower(), OS.get_environment("ETIQUETA") if OS.get_environment("ETIQUETA") != "" else "x"]
	get_viewport().get_texture().get_image().save_jpg(ruta, 0.92)
	print("FOTO ", ruta)

## El jugador de campo más cerca del balón.
func _cercano(motor: MotorJugable) -> Dictionary:
	var mejor: Dictionary = {}
	var dm := INF
	for p: Dictionary in motor.jugadores:
		if bool(p.get("por", false)):
			continue
		var d := (p["node"] as Node3D).global_position.distance_squared_to(motor.balon.global_position)
		if d < dm:
			dm = d
			mejor = p
	return mejor

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		if _n > 60:
			print("SIN MOTOR")
			get_tree().quit()
		return
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
	if _n < 30:
		for i in 12:
			motor.paso(1.0 / 60.0)
	else:
		motor.paso(1.0 / 60.0)
	if _n == 90:
		_foto("tv")
		print("DIBUJO llamadas=%d triangulos=%d" % [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	if _n == 160:
		_foto("tv2")
	if _n == 161:
		_cam_cerca = Camera3D.new()
		_cam_cerca.fov = 30.0
		add_child(_cam_cerca)
		_sigue = _cercano(motor)
	if _n > 161 and _cam_cerca != null:
		_cam_cerca.make_current()
		if _n == 230:
			_sigue = _cercano(motor)
		var n: Node3D = _sigue["node"]
		var fr := Vector3(sin(n.global_rotation.y), 0.0, cos(n.global_rotation.y))
		var foco := n.global_position + Vector3(0, 1.1, 0)
		if _n < 230:
			## Detrás del jugador, a la altura del hombro de un cámara: la espalda entera (dorsal y nombre).
			_cam_cerca.global_position = n.global_position - fr * 5.5 + Vector3(0, 2.0, 0)
		else:
			## De lado, más lejos: la carrera, el giro y los pies sobre el césped.
			_cam_cerca.global_position = n.global_position + Vector3(fr.z, 0.0, -fr.x) * 8.0 + Vector3(0, 1.6, 0)
		_cam_cerca.look_at(foco, Vector3.UP)
		if _n in [200, 226, 262, 290]:
			_fotos += 1
			_foto(("espalda%d" if _n < 230 else "lado%d") % _fotos)
	## (17-11, 2.ª pasada) De lado, uno que TROTA sin el balón (el trote de captura real de `TroteCmu`; con TROTE_CMU=0, el de siempre:
	## el motor es el mismo, así que es el mismo jugador en el mismo momento).
	if _n == 293 or _n == 336:
		_sigue = _trotador(motor)
	if _n >= 293 and _cam_cerca != null and not _sigue.is_empty():
		var n2: Node3D = _sigue["node"]
		var fr2 := Vector3(sin(n2.global_rotation.y), 0.0, cos(n2.global_rotation.y))
		_cam_cerca.global_position = n2.global_position + Vector3(fr2.z, 0.0, -fr2.x) * 6.5 + Vector3(0, 1.3, 0)
		_cam_cerca.look_at(n2.global_position + Vector3(0, 0.9, 0), Vector3.UP)
		if _n == 322 or _n == 360:
			_foto("trote%d" % (1 if _n == 322 else 2))
	if _n > 362:
		get_tree().quit()

## El que trota más cerca del balón (sin llevarlo); si nadie trota, el de campo más cercano.
func _trotador(motor: MotorJugable) -> Dictionary:
	var mejor: Dictionary = {}
	var dm := INF
	for p: Dictionary in motor.jugadores:
		if bool(p.get("por", false)) or p == motor.poseedor:
			continue
		var d := (p["node"] as Node3D).global_position.distance_squared_to(motor.balon.global_position)
		d += 0.0 if String(p.get("anim_actual", "")) == "trotar" else 1.0e6
		if d < dm:
			dm = d
			mejor = p
	return mejor
