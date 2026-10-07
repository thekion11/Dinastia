extends Node3D
## EL PORTAFOLIO DE MOVIMIENTOS (26-9-2026): cada movimiento en un jugador, a
## mitad de su clip, para revisar espejos y expresiones de un vistazo.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_portafolio.tscn
const GRUPOS := [
	["aplaudir", "protestar", "brazos_jarra", "cansado", "besar_escudo", "pedir_balon", "saludar_publico", "pedir_calma", "manos_cabeza", "senalar_adelante", "mirar_cielo", "silbar_dedos"],
	["patear", "patear_espejo", "pase", "pase_espejo", "regate_finta", "regate_finta_espejo", "regate_pausa", "regate_pausa_espejo", "conducir", "conducir_espejo", "atajar_izq", "atajar_izq_espejo"],
	["aplaudir", "protestar", "brazos_jarra", "cansado", "besar_escudo", "pedir_balon", "saludar_publico", "pedir_calma", "manos_cabeza", "cabeza_gacha", "mirar_cielo", "senalar_cielo"],
	["saltar_inicio", "voltereta", "golpe_pecho", "balonazo_cara", "caida_lesion", "atarse_botin", "baile", "charla", "empujar", "recoger_balon", "agachado", "cabezazo_espejo"],
]
var _n := 0
var _g := 0
var _jug: Array = []
var _rot: Array = []
var _cam: Camera3D

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.13, 0.32, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.62, 0.66)
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 20, 0)
	add_child(sol)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 1.1, 7.6)
	_cam.fov = 58
	add_child(_cam)
	for i in 12:
		var d := FutbolistaQ.crear(1.8, "male")
		var raiz: Node3D = d["nodo"]
		raiz.position = Vector3(-6.05 + i * 1.1, 0, 0)
		add_child(raiz)
		FutbolistaQ.terminar(d, true)
		VestidorQ.vestir_equipacion(d, Color("1d4fa3"), Color.WHITE, "franjas", Color("c68d68"), Color(0.15, 0.1, 0.07))
		var r := Label3D.new()
		r.font_size = 24
		r.pixel_size = 0.004
		r.position = Vector3(raiz.position.x, 2.1, 0)
		add_child(r)
		_jug.append(d)
		_rot.append(r)
	_poner(0)

func _poner(g: int) -> void:
	for i in 12:
		var d: Dictionary = _jug[i]
		var ap: AnimationPlayer = d["anim"]
		var nom: String = GRUPOS[g][i]
		(_rot[i] as Label3D).text = nom if ap.has_animation(nom) else nom + " (NO)"
		## Pose limpia antes de cada fila: sin esto, los huesos que el clip
		## nuevo no mueve se quedan como los dejó el anterior.
		for esq in (d["nodo"] as Node).find_children("*", "Skeleton3D", true, false):
			(esq as Skeleton3D).reset_bone_poses()
		(d["nodo"] as Node3D).rotation_degrees.y = -60.0 if g == 0 else 0.0
		if ap.has_animation(nom):
			ap.play(nom)
			ap.seek(ap.current_animation_length * 0.5, true)
			ap.pause()

func _process(_d: float) -> void:
	_n += 1
	if _n % 20 == 0:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/portafolio_%d.png" % _g)
		_g += 1
		if _g >= GRUPOS.size():
			var ap: AnimationPlayer = (_jug[0] as Dictionary)["anim"]
			print("movimientos en la librería: ", ap.get_animation_list().size())
			get_tree().quit()
			return
		_poner(_g)
