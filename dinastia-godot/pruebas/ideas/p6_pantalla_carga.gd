extends BaseIdea
## La pantalla de carga cubre la ventana entera y centra su contenido aunque su padre no sea un Control o aún no tenga tamaño (móvil, prólogo en 3D).

func _probar() -> void:
	_titulo("P6: PANTALLA DE CARGA SIEMPRE A PANTALLA COMPLETA")
	await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	## Padre que NO es un Control (como el prólogo, un Node3D).
	var p3d := Node3D.new()
	add_child(p3d)
	var n1 := PantallaCarga.mostrar(p3d, "Construyendo la ciudad…")
	await get_tree().process_frame
	_comprobar(n1.size.is_equal_approx(vp) and n1.position == Vector2.ZERO, "con un Node3D de padre cubre la ventana (%s de %s)" % [str(n1.size), str(vp)])
	var centro: CenterContainer = n1.get_child(2)
	_comprobar(centro is CenterContainer and centro.size.is_equal_approx(vp), "y su contenido va dentro de un contenedor centrado del mismo tamaño")
	## Padre Control de tamaño 0 (aún sin maquetar).
	var c := Control.new()
	c.size = Vector2.ZERO
	add_child(c)
	var n2 := PantallaCarga.mostrar(c, "Construyendo la ciudad…")
	await get_tree().process_frame
	_comprobar(n2.size.x >= vp.x - 1.0 and n2.size.y >= vp.y - 1.0, "con un Control de tamaño 0 de padre también cubre la ventana (%s)" % str(n2.size))
