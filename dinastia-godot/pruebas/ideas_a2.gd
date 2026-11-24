extends "res://pruebas/ideas_a2_p1.gd"
## (Parte 2 de 2 de `ideas_a2.gd`.)

func _ideas_a_linajes_04(m: Mundo, c: Club) -> void:
	## Presión del apellido (481, 482, 483) sobre un hijo propio.
	_cn.leyendas.append({"nombre": "Ariel Quintana", "club_id": c.id, "pos": "MED", "nivel": 88, "anio_hijo": m.anio, "usado": false, "propio": true})
	_cn._hijos_de_leyendas()
	var hijo: Jugador = null
	for _j: Jugador in c.plantilla:
		if String(_cn.linaje_de(_j).get("padre", "")) == "Ariel Quintana":
			hijo = _j
	_comprobar(hijo != null and c.plantilla.has(hijo), "el hijo de tu propio jugador llega siempre a tu cantera (477)")
	var e := _cn.etiqueta_de(hijo)
	e["desde"] = m.anio - 1
	hijo.partidos = 10
	var moral0 := hijo.moral
	var pesa := false
	for sem in 8:
		for s: Dictionary in _cn.procesar_semana():
			if s["tipo"] == "etiqueta_pesa" and s["jugador"] == hijo:
				pesa = true
	_comprobar(pesa and hijo.moral < moral0, "si rinde mal seis semanas la prensa lo entierra y baja la moral (%d → %d) (481, 482)" % [moral0, hijo.moral])
	var e2 := _cn.etiqueta_de(hijo)
	e2["presion"] = 0
	var supera := false
	for sem in 10:
		hijo.anotar_nota(8.0)
		hijo.anotar_nota(8.0)
		hijo.anotar_nota(8.0)
		for s: Dictionary in _cn.procesar_semana():
			if s["tipo"] == "etiqueta_superada" and s["jugador"] == hijo:
				supera = true
	_comprobar(supera and bool(_cn.etiqueta_de(hijo)["libre"]), "y si rinde ocho semanas se libra de la etiqueta y supera a su padre (483)")

func _ideas_a_linajes_05(m: Mundo, c: Club) -> void:
	## Hermanos y gemelos (485, 486).
	var h1: Jugador = c.plantilla[0]
	var h2: Jugador = c.plantilla[1]
	var base := m.vestuario.bonus_hermanos([h1, h2])
	m.vestuario.emparentar(h1, h2)
	_comprobar(is_equal_approx(base, 1.0) and absf(m.vestuario.bonus_hermanos([h1, h2]) - 1.018) < 0.0001 and is_equal_approx(m.vestuario.bonus_hermanos([h1]), 1.0), "dos hermanos en el once dan bono de química, sin el hermano no (485)")
	var gemelos := 0
	var normales := 0
	var gem_ok := true
	for i in 400:
		var mio := c
		var ant := mio.plantilla.duplicate()
		_cn._sortear_hermano(mio)
		for x: Jugador in mio.plantilla:
			if ant.has(x):
				continue
			var f: Dictionary = _cn._fichas[x.id]
			var base_j: Jugador = m.jugador_por_id(String(f["hermano"]))
			if bool(f["gemelo"]):
				gemelos += 1
				gem_ok = gem_ok and x.edad == base_j.edad and absi(x.ovr - base_j.ovr) <= 4 and x.nombre.split(" ")[-1] == base_j.nombre.split(" ")[-1]
			else:
				normales += 1
			mio.plantilla.erase(x)
			_cn._fichas.erase(x.id)
			(_cn._fichas[base_j.id] as Dictionary).erase("hermano")
	_comprobar(gemelos >= 3 and normales > gemelos and gem_ok, "aparecen hermanos y a veces gemelos: misma edad, media casi idéntica y mismo apellido (%d gemelos, %d hermanos) (486)" % [gemelos, normales])
