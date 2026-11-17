extends Node
## TV · CÉSPED · LUZ (16-11): fotos ANTES/DESPUÉS de la cámara de TV por defecto, el césped y la luz del partido, con la CÁMARA REAL
## (estadio, motor por defecto) y un plano de cerca del jugador que lleva el balón. Un cruce de DOS países (PAIS=ARG,ESP: local del
## primero, visita del segundo); variar los países en cada tanda (regla 34). Mide además cuánto del ALTO de la pantalla ocupa el
## jugador más cercano al balón en la cámara de TV (`ALTO_JUGADOR`: la referencia de FC Mobile es ~1/8).
##   PAIS=BRA,JPN ETIQUETA=despues SALIDA=/ruta herramientas/captura.sh res://pruebas/captura_tv_cesped_luz.tscn
##   CAMARA=TV lejana: la misma foto con otra cámara del rig (por su nombre).
var _n := 0
var _vista: VistaEstadio
var _partido: Partido
var _pais := "ARG"
var _cam_cerca: Camera3D
var _altos: Array[float] = []

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTA)
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
				a = liga.clubes[2]
			elif liga.pais == paises[paises.size() - 1] and b == null:
				b = liga.clubes[4]
	m.mi_club_id = a.id
	Partido.ctx_club_id = m.mi_club_id
	_partido = Partido.new(a, b)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(a, 0.85, b, _partido)
	var pe := a.perfil_estadio()
	print("PERFIL club=%s cesped=%s clima=%s forma=%s" % [a.nombre, pe.get("cesped"), pe.get("clima"), pe.get("forma")])

func _foto(nombre: String) -> void:
	var dir := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://"
	var ruta := "%s/%s_%s_%s.jpg" % [dir, nombre, _pais.to_lower(), OS.get_environment("ETIQUETA") if OS.get_environment("ETIQUETA") != "" else "x"]
	get_viewport().get_texture().get_image().save_jpg(ruta, 0.9)
	print("FOTO ", ruta)

## El jugador más cerca del balón (el que lo lleva casi siempre).
func _cercano(motor: MotorJugable) -> Dictionary:
	var mejor: Dictionary = {}
	var dm := INF
	for p: Dictionary in motor.jugadores:
		var d := (p["node"] as Node3D).global_position.distance_squared_to(motor.balon.global_position)
		if d < dm:
			dm = d
			mejor = p
	return mejor

## Fracción del alto de la pantalla que ocupa un jugador de 1,80 m junto al balón, vista con la cámara en pantalla.
func _alto_en_pantalla(motor: MotorJugable) -> float:
	var cam := get_viewport().get_camera_3d()
	var p := _cercano(motor)
	if cam == null or p.is_empty():
		return 0.0
	var pie := (p["node"] as Node3D).global_position
	var a := cam.unproject_position(pie)
	var b := cam.unproject_position(pie + Vector3(0, 1.8, 0))
	return absf(a.y - b.y) / get_viewport().get_visible_rect().size.y

var _fotos_cerca := 0
var _ultima := 0

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
	var rig: CameraRig = _vista.get("_rig")
	if _n == 20 and OS.get_environment("CAMARA") != "" and rig != null:
		var i := rig.camera_names.find(OS.get_environment("CAMARA"))
		if i >= 0:
			rig.switch_to(i)
	if _n < 30:
		for i in 12:
			motor.paso(1.0 / 60.0)
	else:
		motor.paso(1.0 / 60.0)
	if _n >= 40 and _n <= 200:
		_altos.append(_alto_en_pantalla(motor))
	if _n == 60:
		_foto("tv")
	if _n == 200:
		_foto("tv2")
		var s := 0.0
		for v in _altos:
			s += v
		print("ALTO_JUGADOR camara=%s medio=%.3f (1/%.1f) fov=%.1f pos=%s" % [rig.current_name() if rig != null else "?",
			s / maxf(_altos.size(), 1.0), _altos.size() / maxf(s, 0.0001), get_viewport().get_camera_3d().fov, str(get_viewport().get_camera_3d().global_position)])
	if _n == 201:
		_cam_cerca = Camera3D.new()
		_cam_cerca.fov = 34.0
		add_child(_cam_cerca)
	if _n > 201 and _cam_cerca != null:
		_cam_cerca.make_current()
		var p := _cercano(motor)
		var n: Node3D = p["node"]
		## Desde el lado de la tribuna de la TV, algo alto (3 m) y a ~8 m: el jugador entero, su sombra y el césped de cerca.
		var foco := n.global_position + Vector3(0, 0.8, 0)
		_cam_cerca.global_position = n.global_position + Vector3(7.0, 3.0, 3.5)
		_cam_cerca.look_at(foco, Vector3.UP)
		if _n - _ultima > 40 and _n > 215:
			_fotos_cerca += 1
			_ultima = _n
			_foto("cerca%d" % _fotos_cerca)
	if _fotos_cerca >= 2 or _n > 600:
		get_tree().quit()
