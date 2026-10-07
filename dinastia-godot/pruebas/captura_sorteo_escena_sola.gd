extends Node
## Diagnostico paso 2: monta SOLO `SorteoEscena3D` (su sala, bombo, luces y
## presentador), sin la superposicion `Sorteo` ni `principal.tscn` alrededor,
## para saber si el brazo estirado viene de algo en la propia escena del
## sorteo o de tener el juego completo corriendo detras.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_sorteo_escena_sola.tscn

var _n := 0
var _escena: SorteoEscena3D

func _ready() -> void:
	_escena = SorteoEscena3D.new()
	add_child(_escena)
	_escena.montar(Color("f5c518"), Color("0d2818"))
	## DIAGNOSTICO: el bombo de vidrio (RigidBody3D con material de cristal)
	## esta muy cerca del presentador -si es un reflejo/refraccion del propio
	## brazo a traves del vidrio curvo lo que se ve "estirado", ocultarlo debe
	## hacer desaparecer el efecto sin tocar ni un hueso.
	var bombo = _escena.get("_bombo")
	if bombo != null:
		bombo.visible = false
		print("bombo ocultado para la prueba")

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_escena.cortar_plano(2)
		## Camara nueva: casi de frente al presentador (poco desplazamiento
		## lateral respecto a su propia posicion), que es el angulo donde el
		## brazo de "parado" se ve natural -el de picado lateral de antes
		## revelaba un giro del brazo fuera del plano frontal que ninguna
		## camara frontal deja ver.
		_escena.set("_cam_pos", Vector3(1.15, 1.62, 2.55))
		_escena.set("_cam_mira", Vector3(1.15, 1.3, -0.35))
	if _n == 16:
		_listar_mallas(_escena, 0)
		var esq := _buscar_esqueleto(_escena)
		if esq != null:
			for n: String in ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Spine1",
					"mixamorig_Spine2", "mixamorig_Neck", "mixamorig_Head",
					"mixamorig_LeftShoulder", "mixamorig_LeftArm", "mixamorig_LeftForeArm",
					"mixamorig_RightShoulder", "mixamorig_RightArm", "mixamorig_RightForeArm"]:
				var i := esq.find_bone(n)
				print(n, " pose=", esq.get_bone_pose_rotation(i).get_euler(),
					" global_pos=", esq.global_transform * esq.get_bone_global_pose(i).origin)
		else:
			print("NO SE ENCONTRO ESQUELETO")
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/sorteo_escena_sola.png")
		print("capturado escena sola")
		get_tree().quit()

func _listar_mallas(n: Node, prof: int) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		print("MESH ", mi.name, " skel_path=", mi.skeleton,
			" pos_global=", mi.global_position, " tiene_skin=", mi.skin != null)
	for h in n.get_children():
		_listar_mallas(h, prof + 1)

func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for h in n.get_children():
		var r := _buscar_esqueleto(h)
		if r != null:
			return r
	return null
