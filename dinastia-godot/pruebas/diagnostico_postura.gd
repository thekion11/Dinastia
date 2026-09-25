extends Node3D
## Diagnostico aislado (18-9-2026): el usuario reporto jugadores inclinados
## hacia delante y "hundidos en el suelo" durante un partido real. Para saber
## si la culpa es de `Futbolista.enderezar()`/`escalar()` (la pose base) o de
## `AnimMixamo.correr()` (la animacion), esto instancia UN solo jugador, SIN
## partido ni cancha alrededor, con luz y fondo simples, y prueba "parado" vs
## "correr" por separado.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/diagnostico_postura.tscn

var _frame := 0
var _d: Dictionary
var _fase := 0
var _cam_frente: Camera3D
var _cam_lado: Camera3D

func _ready() -> void:
	var env := Node3D.new()
	add_child(env)
	# Sin WorldEnvironment las capturas salian en blanco puro: el render sin un
	# Environment explicito (fondo + luz ambiente) se queda sobreexpuesto. Mismo
	# arreglo que ya usa captura_parado_aislado.gd, que si funciona.
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.05, 0.06, 0.07)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.3, 0.3, 0.32)
	ent.ambient_light_energy = 0.6
	amb.environment = ent
	env.add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.2
	env.add_child(luz)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.1, 3.2)
	cam.fov = 40
	# look_at() necesita el nodo YA dentro del arbol -llamarlo antes tira
	# "Node not inside tree" y deja al nodo sin orientar.
	env.add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true
	_cam_frente = cam
	# Camara de perfil (lateral): de frente no se nota si la inclinacion es
	# hacia adelante o hacia atras, de perfil si.
	var cam_lado := Camera3D.new()
	cam_lado.position = Vector3(3.2, 1.1, 0)
	cam_lado.fov = 40
	env.add_child(cam_lado)
	cam_lado.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	_cam_lado = cam_lado
	var piso := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6, 6)
	piso.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.25)
	piso.material_override = mat
	env.add_child(piso)

	_d = Futbolista.crear(1.80)
	add_child(_d["nodo"])
	# terminar() ya deja la libreria de animaciones cargada -repetirla aqui
	# tiraba "Can't add animation library twice with name: ".
	Futbolista.terminar(_d)
	var esq: Skeleton3D = _d["esqueleto"]

	## Imprime la pose de reposo de la cadera/espalda: si YA viene inclinada
	## antes de aplicar ninguna animacion, el problema es la pose base, no
	## `AnimMixamo`.
	for hueso in ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2", "mixamorig_Neck", "mixamorig_Head"]:
		var i := esq.find_bone(hueso)
		if i >= 0:
			var e := esq.get_bone_rest(i).basis.get_euler() * (180.0 / PI)
			print("reposo %s: x=%.1f y=%.1f z=%.1f" % [hueso, e.x, e.y, e.z])

func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 10:
		(_d["anim"] as AnimationPlayer).play("parado")
	if _frame == 40:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/postura_parado.png")
		print("capturado: parado")
	if _frame == 42:
		_cam_lado.current = true
	if _frame == 43:
		var imgl := get_viewport().get_texture().get_image()
		imgl.save_png("res://pruebas/postura_parado_lado.png")
		print("capturado: parado lado")
		_cam_frente.current = true
	if _frame == 45:
		(_d["anim"] as AnimationPlayer).play("correr")
	if _frame == 60:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/postura_correr.png")
		print("capturado: correr")
		print("FIN. 0 fallos")
		get_tree().quit(0)
