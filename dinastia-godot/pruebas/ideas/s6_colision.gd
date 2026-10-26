extends BaseIdea
## SESIÓN 6 (26-10-2026), pedido de la S1: en la ciudad a pie, una pieza alargada
## solo tenía dos círculos de choque en las puntas y su centro se atravesaba (87
## postes eléctricos 1,9 × 5,2 y ~104 paneles finos 3,5 × 0,1). Ahora los círculos
## van repartidos cada 2·r: ningún punto a lo largo de la pieza queda libre para
## un jugador de radio 0,3, y los círculos no se salen de la pieza.

const RADIO_JUGADOR := 0.3

func _pieza(raiz: Node3D, pos: Vector3, tam: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.position = pos + Vector3(0, tam.y * 0.5, 0)
	raiz.add_child(mi)

func _bloquea(circ: PackedVector3Array, p: Vector2) -> bool:
	for c in circ:
		if Vector2(c.x, c.y).distance_to(p) < c.z + RADIO_JUGADOR:
			return true
	return false

func _probar() -> void:
	_titulo("S6: CHOQUE CON PIEZAS ALARGADAS (postes y paneles)")
	var raiz := Node3D.new()
	add_child(raiz)
	_pieza(raiz, Vector3(-656, 0, -646), Vector3(3.5, 2.2, 0.1))   ## panel fino a lo largo de X
	_pieza(raiz, Vector3(100, 0, 40), Vector3(1.9, 7.0, 5.2))      ## poste con travesaño a lo largo de Z
	var circ := Optimizar.obstaculos(raiz, [])
	var panel := true
	for i in 21:
		var x := -656.0 - 1.75 + 3.5 * float(i) / 20.0
		panel = panel and _bloquea(circ, Vector2(x, -646))
	_comprobar(panel, "el panel fino (3,5 × 0,1) bloquea de punta a punta, también el centro (%d círculos)" % circ.size())
	var poste := true
	for i in 21:
		var z := 40.0 - 2.6 + 5.2 * float(i) / 20.0
		poste = poste and _bloquea(circ, Vector2(100, z))
	_comprobar(poste, "el poste (1,9 × 5,2) bloquea de punta a punta")
	var dentro := true
	for c in circ:
		var cerca_panel := Vector2(c.x, c.y).distance_to(Vector2(-656, -646)) < 10.0
		var limite := Rect2(-656 - 1.75, -646 - 0.05, 3.5, 0.1) if cerca_panel else Rect2(100 - 0.95, 40 - 2.6, 1.9, 5.2)
		dentro = dentro and limite.grow(0.16).has_point(Vector2(c.x, c.y)) and (limite.position.x - (c.x - c.z) <= 0.16 or cerca_panel)
	_comprobar(dentro, "los centros de los círculos quedan sobre la pieza")
	_comprobar(not _bloquea(circ, Vector2(-656, -646 + 0.15 + RADIO_JUGADOR + 0.2)), "y se puede pasar pegado al panel sin chocar en el aire")
	raiz.queue_free()
