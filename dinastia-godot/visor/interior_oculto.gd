class_name InteriorOculto
extends Node
## EL EDIFICIO DEL CLUB SOLO SE DIBUJA CUANDO LA CÁMARA ESTÁ DENTRO (10-11). Sus salas (~730 mallas) quedan detrás de la tribuna, pero Godot
## no oculta lo que tapa otra cosa: una cámara a ras de césped cerca del túnel (celebración, repetición del remate) las metía todas en el
## encuadre y el partido pasaba de ~420 a ~1.500 llamadas de dibujo durante esos planos. Ahora el edificio se apaga mientras la cámara no
## haya entrado al túnel (z local menor que la boca); al entrar a pie o en el recorrido se ve como siempre.
var _z_boca := 0.0
var _z_out := 0.0
## (10-11) El VESTUARIO (taquillas, bancos, duchas, luces: ~550 piezas sueltas hijas del túnel) también queda detrás de la tribuna y una
## cámara a ras de césped lo metía entero en el encuadre: se apaga con el edificio. El pasillo del túnel y su boca NO (se verían huecos).
var _vestuario: Array[Node3D] = []

## Se busca por nombre cada vez: `EdificioClub.reconstruir` lo cambia por uno nuevo al decorar.
static func vigilar(tunel: Node3D, z_boca: float, z_out: float) -> InteriorOculto:
	var v := InteriorOculto.new()
	v._z_out = z_out
	v.name = "InteriorOculto"
	v._z_boca = z_boca
	tunel.add_child(v)
	return v

func _process(_d: float) -> void:
	var edificio := get_parent().get_node_or_null("EdificioClub") as Node3D
	if edificio == null:
		return
	if _vestuario.is_empty():
		_juntar_vestuario()
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	## Dentro = en el pasillo del túnel (pasada la boca y bajo su techo) o ya detrás de la tribuna (el edificio, todas sus plantas).
	## La cámara de repetición tras el arco (y≈4, z≈±61) está pasada la boca pero sobre la grada: ahí el edificio sigue apagado.
	var p := (get_parent() as Node3D).to_local(cam.global_position)
	var dentro := (p.z > _z_boca - 1.0 and p.y < 3.2) or p.z > _z_out - 1.0
	if edificio.visible != dentro:
		edificio.visible = dentro
		for n in _vestuario:
			if is_instance_valid(n):
				n.visible = dentro

func _juntar_vestuario() -> void:
	var tunel := get_parent() as Node3D
	for h in tunel.get_children():
		if h == self or not h is Node3D or String(h.name) == "EdificioClub":
			continue
		var n := h as Node3D
		var z := n.position.z
		if n is GeometryInstance3D:
			var caja := n.transform * (n as GeometryInstance3D).get_aabb()
			if caja.size.length() > 6.0:
				continue   ## paredes, suelo y techo se quedan: por la boca del túnel se ve el fondo del vestuario, no un hueco
			z = caja.get_center().z
		if z > _z_out + 0.5:
			_vestuario.append(n)
	if _vestuario.is_empty():
		_vestuario.append(self)   ## marca de «ya se buscó» (apagarse a sí mismo no hace nada)
