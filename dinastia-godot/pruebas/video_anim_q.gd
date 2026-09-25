extends Node3D
## Mini-video de las animaciones ya conectadas a FutbolistaQ -reales
## (parado/caminar/trotar/correr) y a mano (patear/cabezazo/celebrar)-, para
## que el usuario las vea en movimiento y no solo en fotos sueltas. Pensado
## para correr con --write-movie (ver herramientas/video_anim_q.ps1 o el
## comando en el propio LEEME.md).

const SECUENCIA := [
	["parado", 2.0],
	["caminar", 2.5],
	["trotar", 2.0],
	["correr", 2.0],
	["patear", 1.3],
	["cabezazo", 1.5],
	["celebrar", 2.2],
]

var _d: Dictionary
var _ap: AnimationPlayer
var _i := 0
var _t := 0.0
var _cam: Camera3D

func _ready() -> void:
	var env := Node3D.new()
	add_child(env)
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.08, 0.35, 0.14)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.4, 0.4, 0.42)
	ent.ambient_light_energy = 0.8
	amb.environment = ent
	env.add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-55, -30, 0)
	luz.light_energy = 1.3
	env.add_child(luz)

	_cam = Camera3D.new()
	_cam.position = Vector3(2.6, 1.1, 2.6)
	_cam.fov = 45
	env.add_child(_cam)
	_cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	_cam.current = true

	var piso := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 8)
	piso.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.48, 0.22)
	piso.material_override = mat
	env.add_child(piso)

	var etiqueta := Label3D.new()
	etiqueta.position = Vector3(0, 2.05, 0)
	etiqueta.font_size = 64
	etiqueta.outline_size = 12
	etiqueta.name = "Etiqueta"
	env.add_child(etiqueta)
	_etiqueta = etiqueta

	_d = FutbolistaQ.crear(1.80)
	add_child(_d["nodo"])
	FutbolistaQ.terminar(_d, true)
	_ap = _d["anim"]
	_ap.play(SECUENCIA[0][0])
	_etiqueta.text = SECUENCIA[0][0]

var _etiqueta: Label3D

func _process(delta: float) -> void:
	# La camara gira lento alrededor del jugador todo el tiempo, para que se
	# vea el movimiento desde varios angulos sin cortar el clip.
	var ang := Time.get_ticks_msec() / 1000.0 * 0.35
	_cam.position = Vector3(cos(ang) * 2.8, 1.1, sin(ang) * 2.8)
	_cam.look_at(_d["esqueleto"].global_position + Vector3(0, 0.9, 0), Vector3.UP)

	_t += delta
	if _t >= SECUENCIA[_i][1]:
		_t = 0.0
		_i += 1
		if _i >= SECUENCIA.size():
			get_tree().quit(0)
			return
		_ap.play(SECUENCIA[_i][0])
		_etiqueta.text = SECUENCIA[_i][0]
