extends Node
## M-098: la cabeza sigue al balón. Jugador quieto de frente a la cámara, el
## balón a su derecha y luego a su izquierda (MIRADA_OFF=1: sin el modificador).
##   herramientas/captura.sh res://pruebas/captura_mirada.tscn
var _vista: VistaEstadio
var _n := 0
var _p: Dictionary = {}
var _motor: MotorJugable

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	if OS.get_environment("MIRADA_EJE") != "":
		MiradaBalon.eje = int(OS.get_environment("MIRADA_EJE")) as SkeletonModifier3D.BoneAxis
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	for k in ["_intro", "_ceremonia"]:
		var x: Variant = _vista.get(k)
		if x != null and is_instance_valid(x) and x.activa:
			x.terminar()
			return
	_n += 1
	_motor = _vista.get("_motor")
	if _motor == null:
		return
	if _n == 10:
		_motor.set_process(false)
		_motor.set_physics_process(false)
		_vista.set_process(false)
		_p = _motor.jugadores[5]
		var n: Node3D = _p["node"]
		n.position = Vector3(0, 0, 0)
		n.rotation = Vector3.ZERO
		var ap: AnimationPlayer = _p["anim"]
		if ap.has_animation("parado"):
			ap.play("parado")
		if OS.get_environment("MIRADA_OFF") != "":
			for m in n.find_children("MiradaBalon", "", true, false):
				m.queue_free()
		for a: Dictionary in _motor.arbitros:
			(a["node"] as Node3D).position = Vector3(20, 0, -20)
		for q: Dictionary in _motor.jugadores:
			if q != _p:
				(q["node"] as Node3D).position.x += 40.0 if absf((q["node"] as Node3D).position.x) < 6.0 and absf((q["node"] as Node3D).position.z) < 8.0 else 0.0
		var cam := Camera3D.new()
		(_vista.get("_raiz3d") as Node3D).add_child(cam)
		cam.global_position = Vector3(0, 1.65, 2.2)
		cam.look_at(Vector3(0, 1.55, 0))
		cam.fov = 30.0
		cam.current = true
		## A SU derecha: mirando a +Z, su derecha es −X (izquierda de la foto).
		_motor.balon.position = Vector3(-6, 0.11, 2)
	if _n == 30:
		_foto("mirada_derecha")
		_motor.balon.position = Vector3(6, 0.11, 2)
	if _n == 50:
		_foto("mirada_izquierda")
		get_tree().quit()

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s%s%s.png" % [nombre, "_off" if OS.get_environment("MIRADA_OFF") != "" else "", OS.get_environment("MIRADA_EJE")])
	print("FOTO ", nombre)
