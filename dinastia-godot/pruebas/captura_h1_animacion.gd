extends Node
## H1 · ANIMACIÓN (16-11): fotos ANTES/DESPUÉS del pie al balón, la cabeza que sigue al balón y el giro suave, con la CÁMARA REAL
## del partido (estadio, motor por defecto) y un plano de cerca del jugador que lleva el balón. Un cruce de DOS países (PAIS=ARG,ESP:
## local del primero, visita del segundo); variar los países en cada tanda (regla 34). Con `H1_IK=0` sale el «antes» (sin `AnimacionCercana`).
##   PAIS=BRA,JPN ETIQUETA=despues SALIDA=/ruta herramientas/captura.sh res://pruebas/captura_h1_animacion.tscn
var _n := 0
var _vista: VistaEstadio
var _partido: Partido
var _pais := "ARG"
var _cam_cerca: Camera3D

func _ready() -> void:
	Calidad.elegida = Calidad.ALTA
	if OS.get_environment("H1_IK") == "0":
		AnimacionCercana.encendida = false
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

func _foto(nombre: String) -> void:
	var dir := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://"
	var ruta := "%s/%s_%s_%s.jpg" % [dir, nombre, _pais, OS.get_environment("ETIQUETA") if OS.get_environment("ETIQUETA") != "" else "x"]
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
	## Avanza el partido a saltos y luego a ritmo real (que la cabeza y el pie alcancen su peso suavizado).
	if _n < 30:
		for i in 12:
			motor.paso(1.0 / 60.0)
	else:
		motor.paso(1.0 / 60.0)
	if _n == 60:
		_foto("tv")
	if _n == 61:
		_cam_cerca = Camera3D.new()
		_cam_cerca.fov = 32.0
		add_child(_cam_cerca)
	if _n > 61 and _cam_cerca != null:
		_cam_cerca.make_current()
		var p := _cercano(motor)
		var n: Node3D = p["node"]
		var foco := n.global_position + Vector3(0, 0.55, 0)
		var lado := n.global_basis.x.normalized()
		_cam_cerca.global_position = foco + lado * 3.4 + n.global_basis.z.normalized() * 1.6 + Vector3(0, 0.45, 0)
		_cam_cerca.look_at(foco, Vector3.UP)
		var bp := motor.balon.global_position
		var dh := Vector2(n.global_position.x - bp.x, n.global_position.z - bp.z).length()
		## Solo cuando lo lleva pegado (es cuando trabaja el pie al balón), y con 30 fotogramas entre una y otra.
		if dh < 0.75 and bp.y < 0.3 and _n - _ultima > 30 and _n > 75:
			_fotos_cerca += 1
			_ultima = _n
			_foto("cerca%d" % _fotos_cerca)
	if _fotos_cerca >= 3 or _n > 600:
		print("MOTOR ", motor.get_script().resource_path, " estado ", motor.estado, " n ", _n)
		get_tree().quit()
