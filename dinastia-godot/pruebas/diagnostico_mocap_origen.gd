extends Node3D
## Referencia visual del clip ANTES de retargetearlo. Esta escena no usa
## FutbolistaQ ni AnimQuaternius: reproduce directamente el FBX de origen.
## Sirve para separar dos problemas que antes estaban mezclados: si aqui se
## ve bien y en nuestro modelo se ve mal, el fallo es del retargeting; si aqui
## tambien se ve mal, el clip elegido no sirve para la accion.

const CLIP := "res://assets/characters/quaternius/anims_futbol/09_Power_Kick_ue5.fbx"
const INSTANTE_CAPTURA := 0.55

var _ap: AnimationPlayer
var _tiempo := 0.0
var _capturado := false

func _ready() -> void:
	var env := Node3D.new()
	add_child(env)
	var mundo := WorldEnvironment.new()
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.05, 0.06, 0.07)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.42, 0.42, 0.44)
	ambiente.ambient_light_energy = 0.8
	mundo.environment = ambiente
	env.add_child(mundo)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	luz.light_energy = 1.4
	env.add_child(luz)
	var piso := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(6.0, 6.0)
	piso.mesh = plano
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.50, 0.25)
	piso.material_override = mat
	env.add_child(piso)
	var cam := Camera3D.new()
	cam.position = Vector3(3.2, 1.1, 0.0)
	cam.fov = 40.0
	env.add_child(cam)
	cam.look_at(Vector3(0.0, 0.9, 0.0), Vector3.UP)
	cam.current = true
	var packed: PackedScene = load(CLIP)
	if packed == null:
		push_error("No se pudo cargar el clip de origen")
		get_tree().quit(1)
		return
	var origen: Node3D = packed.instantiate()
	add_child(origen)
	_ap = _buscar_ap(origen)
	if _ap == null or not _ap.has_animation("clip"):
		push_error("El FBX de origen no trae la animacion clip")
		get_tree().quit(1)
		return
	_ap.play("clip")

func _process(delta: float) -> void:
	if _capturado:
		return
	_tiempo += delta
	if _tiempo < INSTANTE_CAPTURA:
		return
	_capturado = true
	var textura := get_viewport().get_texture()
	var img := textura.get_image() if textura != null else null
	if img != null:
		img.save_png("res://pruebas/mocap_origen_power_kick_lado.png")
		print("CAPTURA ORIGEN OK en ", _tiempo)
	else:
		## El renderer dummy de --headless no tiene framebuffer: el mismo
		## diagnostico se graba con --write-movie para inspeccion visual.
		print("SIN FRAMEBUFFER: usar --write-movie para ver el origen")
	get_tree().quit(0)

func _buscar_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for hijo in n.get_children():
		var encontrado := _buscar_ap(hijo)
		if encontrado != null:
			return encontrado
	return null
