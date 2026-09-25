extends Node3D
## Barrido aislado de "espalda" (18-9-2026): la prueba con BRAZO_ABAJO-style en
## anim_mixamo.gd no dio una relacion lineal entre el offset y la inclinacion
## visible (ver project_dinastia_jugadas.md: 0, +6.9 y +13.8 dieron resultados
## que no encajan con una simple resta de grados). Este script mueve SOLO
## mixamorig_Spine directamente en el Skeleton3D (sin pasar por AnimMixamo ni
## por ninguna animacion), barre un rango de angulos, y MIDE la inclinacion
## real -desplazamiento horizontal de la cabeza respecto a la cadera, en vez
## de solo mirar capturas- para encontrar la relacion real angulo->inclinacion
## antes de tocar anim_mixamo.gd otra vez.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         --position 0,0 res://pruebas/diagnostico_espalda_sola.tscn

var _esq: Skeleton3D
var _idx_spine := -1
var _idx_head := -1
var _idx_hips := -1
var _cam: Camera3D
var _frame := 0
var _paso := 0
const ANGULOS := [14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0]

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.05, 0.06, 0.07)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.3, 0.3, 0.32)
	ent.ambient_light_energy = 0.6
	amb.environment = ent
	add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.2
	add_child(luz)
	_cam = Camera3D.new()
	_cam.position = Vector3(3.2, 1.1, 0)
	_cam.fov = 40
	add_child(_cam)
	_cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	_cam.current = true
	var piso := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6, 6)
	piso.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.25)
	piso.material_override = mat
	add_child(piso)

	var d := Futbolista.crear(1.80)
	add_child(d["nodo"])
	Futbolista.terminar(d)
	_esq = d["esqueleto"]
	_idx_spine = _esq.find_bone("mixamorig_Spine")
	_idx_head = _esq.find_bone("mixamorig_Head")
	_idx_hips = _esq.find_bone("mixamorig_Hips")
	# Sin animacion corriendo: solo queremos ver el efecto puro del offset que
	# probamos a mano, sin el pequeno balanceo que trae "parado".
	(d["anim"] as AnimationPlayer).stop()

func _aplicar(grados: float) -> void:
	var reposo := _esq.get_bone_rest(_idx_spine).basis.get_rotation_quaternion()
	var desvio := Quaternion.from_euler(Vector3(deg_to_rad(grados), 0, 0))
	_esq.set_bone_pose_rotation(_idx_spine, reposo * desvio)

func _medir_y_capturar(grados: float) -> void:
	var cabeza := _esq.global_transform * _esq.get_bone_global_pose(_idx_head).origin
	var cadera := _esq.global_transform * _esq.get_bone_global_pose(_idx_hips).origin
	var lean := cabeza.z - cadera.z
	print("espalda=%+.1f  cabeza.z-cadera.z=%.3f  cabeza=%s  cadera=%s" % [grados, lean, cabeza, cadera])
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://pruebas/espalda_%s.png" % str(grados).replace("-", "m").replace(".", "_"))

func _process(_delta: float) -> void:
	_frame += 1
	# Cada 8 fotogramas: aplica un angulo, deja que el skeleton lo procese un
	# par de cuadros, mide y captura, pasa al siguiente.
	if _frame % 8 == 4 and _paso < ANGULOS.size():
		_aplicar(ANGULOS[_paso])
	if _frame % 8 == 6 and _paso < ANGULOS.size():
		_medir_y_capturar(ANGULOS[_paso])
		_paso += 1
	if _paso >= ANGULOS.size() and _frame % 8 == 0:
		print("FIN. 0 fallos")
		get_tree().quit(0)
