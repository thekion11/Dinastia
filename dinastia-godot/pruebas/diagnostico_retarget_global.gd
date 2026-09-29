extends Node3D
## Prueba aislada del retarget global. No toca las animaciones que hoy usa
## FutbolistaQ: compara una sola pose de Power Kick con la conversion nueva.

const CLIP := "res://assets/characters/quaternius/anims_futbol/09_Power_Kick_ue5.fbx"
const INSTANTE := 0.55

var _retarget: RetargetFutbolQ
var _origen_ap: AnimationPlayer
var _frame := 0

func _ready() -> void:
	var mundo := WorldEnvironment.new()
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.05, 0.06, 0.07)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.42, 0.42, 0.44)
	ambiente.ambient_light_energy = 0.8
	mundo.environment = ambiente
	add_child(mundo)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	luz.light_energy = 1.4
	add_child(luz)
	var piso := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(6.0, 6.0)
	piso.mesh = plano
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.50, 0.25)
	piso.material_override = mat
	add_child(piso)
	var cam := Camera3D.new()
	cam.position = Vector3(3.2, 1.1, 0.0)
	cam.fov = 40.0
	add_child(cam)
	cam.look_at(Vector3(0.0, 0.9, 0.0), Vector3.UP)
	cam.current = true

	var d := FutbolistaQ.crear(1.80)
	add_child(d["nodo"])
	FutbolistaQ.terminar(d)
	var destino: Skeleton3D = d["esqueleto"]
	(d["anim"] as AnimationPlayer).stop()
	var packed: PackedScene = load(CLIP)
	var nodo_origen: Node3D = packed.instantiate()
	add_child(nodo_origen)
	_origen_ap = _buscar_ap(nodo_origen)
	var origen := _buscar_esqueleto(nodo_origen)
	_retarget = RetargetFutbolQ.crear(origen, destino)
	_origen_ap.play("clip")
	_origen_ap.seek(INSTANTE, true)
	_origen_ap.pause()

func _process(_delta: float) -> void:
	_frame += 1
	if _frame != 4:
		return
	_retarget.aplicar()
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://pruebas/capturas/retarget_global_power_kick_lado.png")
	print("RETARGET GLOBAL OK")
	get_tree().quit(0)

func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for hijo in n.get_children():
		var encontrado := _buscar_esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null

func _buscar_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for hijo in n.get_children():
		var encontrado := _buscar_ap(hijo)
		if encontrado != null:
			return encontrado
	return null
