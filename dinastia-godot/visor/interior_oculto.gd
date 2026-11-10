class_name InteriorOculto
extends Node
## EL EDIFICIO DEL CLUB SOLO SE DIBUJA CUANDO LA CÁMARA ESTÁ DENTRO (10-11). Sus salas (~730 mallas) quedan detrás de la tribuna, pero Godot
## no oculta lo que tapa otra cosa: una cámara a ras de césped cerca del túnel (celebración, repetición del remate) las metía todas en el
## encuadre y el partido pasaba de ~420 a ~1.500 llamadas de dibujo durante esos planos. Ahora el edificio se apaga mientras la cámara no
## haya entrado al túnel (z local menor que la boca); al entrar a pie o en el recorrido se ve como siempre.
var _z_boca := 0.0

## Se busca por nombre cada vez: `EdificioClub.reconstruir` lo cambia por uno nuevo al decorar.
static func vigilar(tunel: Node3D, z_boca: float) -> InteriorOculto:
	var v := InteriorOculto.new()
	v.name = "InteriorOculto"
	v._z_boca = z_boca
	tunel.add_child(v)
	return v

func _process(_d: float) -> void:
	var edificio := get_parent().get_node_or_null("EdificioClub") as Node3D
	if edificio == null:
		return
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var dentro := (get_parent() as Node3D).to_local(cam.global_position).z > _z_boca - 1.0
	if edificio.visible != dentro:
		edificio.visible = dentro
