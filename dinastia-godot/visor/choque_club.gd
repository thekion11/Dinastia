class_name ChoqueClub
extends RefCounted
## CAJAS DE CHOQUE A LA MEDIDA DE UN MODELO (10-11, sesión 7, «solo club» paso 2). Los modelos que no pasan por `Modulos` (los coches del
## estacionamiento, por ejemplo) no tenían colisión y el jugador los atravesaba. `de_modelo` mide las mallas del modelo (ya colgado de `padre`, con su
## posición, giro y escala) y deja un `StaticBody3D` con una caja del mismo tamaño en `padre`, sin escalar (la física no admite escalas raras).

static func de_modelo(padre: Node3D, modelo: Node3D) -> StaticBody3D:
	var caja := AABB()
	var primera := true
	for mi: MeshInstance3D in modelo.find_children("*", "MeshInstance3D", true, false):
		var t := Transform3D.IDENTITY
		var x: Node = mi
		while x != null and x != modelo:
			if x is Node3D:
				t = (x as Node3D).transform * t
			x = x.get_parent()
		var a := t * mi.get_aabb()
		caja = a if primera else caja.merge(a)
		primera = false
	if primera:
		return null
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Choque_" + String(modelo.name)
	cuerpo.position = modelo.position
	cuerpo.rotation.y = modelo.rotation.y
	var forma := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = caja.size * modelo.scale
	forma.shape = bs
	forma.position = caja.get_center() * modelo.scale
	cuerpo.add_child(forma)
	padre.add_child(cuerpo)
	return cuerpo
