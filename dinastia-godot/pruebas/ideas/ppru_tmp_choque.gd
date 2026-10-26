extends BaseIdea
func _probar() -> void:
	for ang in [0.0, 0.0001, 0.3, PI, PI / 2.0]:
		var e := ExploradorCiudad.new()
		e.modo = "coche"
		e.cuerpo = Node3D.new()
		add_child(e)
		e.set_physics_process(false)
		var rs: Array[Rect2] = [Rect2(-20.0, 10.0, 40.0, 4.0), Rect2(-20.0, -14.0, 40.0, 4.0), Rect2(10.0, -20.0, 4.0, 40.0), Rect2(-14.0, -20.0, 4.0, 40.0)]
		e.obstaculos = rs
		e._indexar_obstaculos()
		e.cuerpo.position = Vector3(0, 0.2, 0)
		e.rumbo = ang
		e.vel = 20.0
		var vs := []
		var t0 := e._t_golpe
		for i in 30:
			var ad := Vector3(sin(e.rumbo), 0, cos(e.rumbo))
			var paso := ad * e.vel / 60.0
			var n := maxi(1, ceili(paso.length() / 0.3))
			for k in n:
				if not e._mover_un_trozo(paso / n, 1.08):
					break
			vs.append(snappedf(e.vel, 0.01))
		print("ang %.4f pos %s golpe %s vel %s" % [ang, e.cuerpo.position, e._t_golpe != t0, vs])
		e.cuerpo.free()
		e.free()
