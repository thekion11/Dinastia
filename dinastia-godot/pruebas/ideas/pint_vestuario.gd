extends BaseIdea
## LAS TAQUILLAS, EL MUSEO Y LA UTILERÍA DEL CLUB (26-10-2026, paquete pint).
## Comprueba lo que la foto no garantiza: que cada taquilla lleva el dorsal y
## el nombre de SU jugador (y solo el número si no hay plantilla), que ningún
## texto es más ancho que la taquilla (antes se montaban unos sobre otros),
## que las piezas van juntas en pocas mallas, que todo lo sólido tiene su caja
## de choque y que el museo y la utilería dejan libre el paso de la puerta.

func _cajas(n: Node) -> Array:
	var sal: Array = []
	for c in n.find_children("*", "StaticBody3D", true, false):
		var sb := c as StaticBody3D
		var cs := sb.get_child(0) as CollisionShape3D
		if cs != null and cs.shape is BoxShape3D:
			var t := (cs.shape as BoxShape3D).size
			sal.append(AABB(sb.position + cs.position - t / 2.0, t))
	return sal

func _toca(cajas: Array, p: Vector3) -> bool:
	for a: AABB in cajas:
		if a.has_point(p):
			return true
	return false

func _textos(n: Node) -> Array:
	return n.find_children("*", "Label3D", true, false).map(func(l: Label3D) -> String: return l.text)

func _probar() -> void:
	_titulo("TAQUILLAS CON NOMBRE (plan: «nombre de cada jugador en su taquilla y en la camiseta»)")
	_comprobar(PiezasVestuario.apellido("Fernando de Pedro") == "DE PEDRO", "apellido compuesto: «DE PEDRO»")
	_comprobar(PiezasVestuario.apellido("Martín Álvarez") == "ÁLVAREZ", "apellido simple con tilde: «ÁLVAREZ»")
	_comprobar(PiezasVestuario.apellido("Pelé") == "PELÉ", "un nombre solo se queda entero")
	var largo := "10 · Maximiliano Fernández de la Fuente"
	var f := PiezasVestuario.letra_para(largo, PiezasVestuario.ANCHO - 0.22, 26, 11)
	var ancho_est := float(f) * largo.length() * 0.6 * PiezasVestuario.PIXEL
	_comprobar(f < 26, "un nombre largo baja la letra (%d)" % f)
	_comprobar(ancho_est <= PiezasVestuario.ANCHO - 0.2 or f == 11, "y cabe en la placa (%.2f m)" % ancho_est)

	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var club: Club = m.ligas[0].clubes[0]
	var perfil := EstadioPropio.new().perfil(club)
	perfil["forma"] = "cuenco"
	perfil["tunel"] = "central"
	var antes := EdificioClub.ctx
	EdificioClub.ctx = {"plantilla": [[1, "Martín Álvarez"], [9, "Óscar Obezo"], [15, "Fernando de Pedro"]]}
	PersonajeDT.club_usuario = ""
	var raiz := Node3D.new()
	add_child(raiz)
	TunelVestuario.montar(raiz, perfil, 2, null)
	EdificioClub.ctx = antes
	var tv := raiz.get_node("TunelVestuario")
	var textos := _textos(tv)
	_comprobar("9 · Óscar Obezo" in textos, "la placa de la taquilla 2 dice «9 · Óscar Obezo»")
	_comprobar("DE PEDRO" in textos and "15" in textos, "la camiseta de la 3 lleva «DE PEDRO» y el 15")
	_comprobar("4" in textos and not textos.any(func(t: String) -> bool: return t.begins_with("4 ·")),
		"sin jugador, la taquilla 4 lleva solo su número")
	var anchas := 0
	for l: Label3D in tv.find_children("*", "Label3D", true, false):
		if l.pixel_size == PiezasVestuario.PIXEL and (l.width <= 0.0 or l.width * l.pixel_size > PiezasVestuario.ANCHO):
			anchas += 1
	_comprobar(anchas == 0, "ningún texto de taquilla es más ancho que la taquilla (%d)" % anchas)
	var mallas := tv.find_children("Taquillas*", "MeshInstance3D", false, false).size()
	_comprobar(mallas >= 5 and mallas <= 16, "las taquillas van juntas en pocas mallas (%d)" % mallas)
	## Cada taquilla tiene choque: el centro de cada una (16) está dentro de una caja.
	var d := TunelVestuario.datos(perfil, 2)
	var x0: float = d["x0"]
	var cajas := _cajas(tv)
	var sin_choque := 0
	var n := 0
	for lado: float in [-1.0, 1.0]:
		var z: float = float(d["z_out"]) + 1.6
		while z < float(d["z_fin"]) - 3.4:
			n += 1
			if not _toca(cajas, Vector3(x0 + lado * (TunelVestuario.VEST_MEDIO - 0.36), 1.0, z)):
				sin_choque += 1
			z += 1.05
	_comprobar(n >= 12 and sin_choque == 0, "las %d taquillas tienen caja de choque (sin: %d)" % [n, sin_choque])
	_comprobar(not _toca(cajas, Vector3(x0, 1.0, float(d["z_out"]) + 3.0)), "el centro del vestuario queda libre")
	raiz.queue_free()

	_titulo("MUSEO Y UTILERÍA AMUEBLADOS")
	var sala := Rect2(0.0, 0.0, 4.1, 9.2)
	var puerta := AABB(Vector3(sala.get_center().x - 0.6, 0.0, sala.end.y - 1.6), Vector3(1.2, 2.0, 1.6))
	var mu := Node3D.new()
	add_child(mu)
	SalasClub.museo(mu, sala, 0.0, Color(0.1, 0.4, 0.2), Color.WHITE, 3, 4)
	var cm := _cajas(mu)
	_comprobar(cm.size() == 4, "nivel 4 de museo: 4 vitrinas con choque (%d)" % cm.size())
	_comprobar(not cm.any(func(a: AABB) -> bool: return a.intersects(puerta)), "las vitrinas no tapan la puerta")
	var pasillo := AABB(Vector3(sala.get_center().x - 0.6, 0.0, 0.0), Vector3(1.2, 2.0, sala.size.y))
	_comprobar(not cm.any(func(a: AABB) -> bool: return a.intersects(pasillo)), "el recorrido central del museo queda libre")
	_comprobar("3 títulos" in _textos(mu), "el rótulo cuenta los títulos")
	_comprobar(mu.find_children("Museo*", "MeshInstance3D", false, false).size() <= 14, "el museo va en pocas mallas")
	mu.queue_free()
	var ut := Node3D.new()
	add_child(ut)
	SalasClub.utileria(ut, sala, 0.0, Color(0.1, 0.4, 0.2), Color.WHITE)
	var cu := _cajas(ut)
	_comprobar(cu.size() >= 5, "la utilería tiene sus muebles sólidos (%d)" % cu.size())
	_comprobar(not cu.any(func(a: AABB) -> bool: return a.intersects(puerta)), "nada de la utilería tapa la puerta")
	_comprobar(not _toca(cu, Vector3(sala.get_center().x, 1.0, sala.get_center().y)), "el centro de la utilería se pisa")
	ut.queue_free()
