extends Node3D
## EL PORTAFOLIO DE FÚTBOL (26-9-2026, segunda tanda): cada movimiento en un jugador, a
## mitad de su clip, para revisar espejos y expresiones de un vistazo.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_portafolio.tscn
const GRUPOS := [
	["tiro_empeine", "tiro_colocado", "tiro_exterior", "tiro_canonazo", "vaselina", "volea", "tiro_cayendo", "rabona", "chilena", "tijera", "palomita", "cabezazo_potente"],
	["pase_interior", "pase_largo", "pase_exterior", "taconazo", "centro", "centro_rosca", "pase_pecho", "pase_cabeza", "trivela", "pase_lateral", "cambio_frente", "pase_atras"],
	["barrida_frontal", "barrida_lateral", "barrida_dos_pies", "barrida_bloqueo", "barrida_por_detras", "barrida_giro", "entrada_de_pie", "entrada_lateral_pie", "carga_hombro", "anticipacion", "zancadilla", "barrida_rodilla"],
	["estirada_alta_izq", "estirada_alta_der", "estirada_baja_izq", "estirada_baja_der", "estirada_media_izq", "blocaje_alto", "punos", "achique", "blocaje_rasante", "parada_pie", "salida_aerea", "mano_cambiada"],
	["bicicleta", "elastica", "ruleta", "sombrero", "cano", "croqueta", "amague_tiro", "amague_cuerpo", "giro_cruyff", "arrastre", "lambreta", "salto_entrada"],
	["pulgar_arriba", "llamar_hinchada", "discutir_arbitro", "mano_oido", "silencio_dedo", "corazon_manos", "cruzar_brazos", "cuclillas_lamento", "rodillas_brazos_arriba", "avion", "puno_rabia", "deslizar_rodillas"],
	["lesion_tobillo", "lesion_rodilla", "lesion_isquio", "cojear", "tendido", "sentado_dolorido", "calambre", "caida_fea", "arbitro_ventaja", "arbitro_var", "asistente_bandera", "arbitro_penal"],
	["tiro_empeine_espejo", "pase_interior_espejo", "bicicleta_espejo", "barrida_lateral_espejo", "rabona_espejo", "elastica_espejo", "centro_espejo", "volea_espejo", "croqueta_espejo", "giro_cruyff_espejo", "trivela_espejo", "tiro_rosca_espejo"],
]
## En qué punto del clip se congela cada fila.
const PUNTO := [0.5, 0.5, 0.45, 0.42, 0.4, 0.5, 0.35, 0.5]
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
	var t0 := Time.get_ticks_msec()
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
	print("12 jugadores con la librería en ", Time.get_ticks_msec() - t0, " ms")
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
		(d["nodo"] as Node3D).rotation_degrees.y = -55.0 if g != 5 else -20.0
		if ap.has_animation(nom):
			ap.play(nom)
			ap.seek(ap.current_animation_length * float(PUNTO[g]), true)
			ap.pause()

func _process(_d: float) -> void:
	_n += 1
	if _n % 20 == 0:
		get_viewport().get_texture().get_image().save_png("res://pruebas/portafolio2_%d.png" % _g)
		_g += 1
		if _g >= GRUPOS.size():
			var ap: AnimationPlayer = (_jug[0] as Dictionary)["anim"]
			print("movimientos en la librería: ", ap.get_animation_list().size())
			get_tree().quit()
			return
		_poner(_g)
