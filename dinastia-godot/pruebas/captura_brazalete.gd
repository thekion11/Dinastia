extends Node
## M-073: el brazalete del capitán, de cerca y con la cámara de TV.
##   herramientas/captura.sh res://pruebas/captura_brazalete.tscn
var _vista: VistaEstadio
var _n := 0
var _cap: Dictionary = {}

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
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
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		return
	if _n == 30:
		_foto("brazalete_tv")
		for p: Dictionary in motor.jugadores:
			if bool(p["es_local"]) and bool((p.get("jugador", {}) as Dictionary).get("capitan", false)):
				_cap = p
		motor.set_process(false)
		motor.set_physics_process(false)
		_vista.set_process(false)
		var n: Node3D = _cap["node"]
		var cam := Camera3D.new()
		(_vista.get("_raiz3d") as Node3D).add_child(cam)
		## Su brazo izquierdo: a su izquierda (−X local si mira a +Z).
		var izq := -n.global_transform.basis.x.normalized()
		cam.global_position = n.global_position + izq * 2.2 + n.global_transform.basis.z * 0.8 + Vector3(0, 1.5, 0)
		cam.look_at(n.global_position + Vector3(0, 1.35, 0))
		cam.fov = 40.0
		cam.current = true
	if _n == 34:
		_foto("brazalete_cerca")
		get_tree().quit()

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)
	print("FOTO ", nombre)
