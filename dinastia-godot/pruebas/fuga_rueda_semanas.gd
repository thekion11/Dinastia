extends Node
## (10-11) ¿Crece el árbol con el TIEMPO (semanas y ruedas de prensa) con el MISMO club? Cuenta nodos por clase tras cada vuelta
## (6 semanas + una rueda de prensa contestada entera) y dice qué clases crecen. Sin pantalla.
##   VUELTAS=4 CLUB="Riestra Sur" godot --headless res://pruebas/fuga_rueda_semanas.tscn
func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _ready() -> void:
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _esperar(3.0)
	CapasTutorial.poner_activas(false)
	var nombre := OS.get_environment("CLUB") if OS.get_environment("CLUB") != "" else "Riestra Sur"
	var c: Club = null
	for x: Club in p.mundo.clubes.values():
		if x.nombre == nombre:
			c = x
	p.mundo.tomar_el_mando(c.id)
	var antes := _contar()
	var primera := antes
	for v in int(OS.get_environment("VUELTAS")) if OS.get_environment("VUELTAS") != "" else 4:
		for s in 6:
			p.mundo.avanzar_semana()
		p.mundo.prensa.abrir_rueda(true, false)
		p._refrescar()
		await _esperar(1.0)
		if p._rueda_pop == null:
			p._abrir_rueda_pantalla_completa(p.mundo.prensa.entrevista)
		await _esperar(1.0)
		while p._rueda_pop != null:
			p._responder(0)
			await _esperar(0.3)
		for h in p.get_children():
			## Lo que en el juego cierra el jugador (eventos y la portada del periódico de la semana): fuera, para ver solo lo que se FUGA.
			var sc := h.get_script() as Script
			if h is EventoPantallaCompleta or (sc != null and sc.get_global_name() == &"PortadaPeriodico"):
				h.queue_free()
		p._refrescar()
		await _esperar(1.0)
		var ahora := _contar()
		var crecen: Array = []
		for k: String in ahora:
			var d := int(ahora[k]) - int(antes.get(k, 0))
			if d > 0:
				crecen.append([d, k])
		crecen.sort_custom(func(a, b) -> bool: return a[0] > b[0])
		print("VUELTA %d · nodos %d (%+d) · crecen: %s" % [v + 1, get_tree().get_node_count(), get_tree().get_node_count() - _total(antes), str(crecen.slice(0, 8))])
		antes = ahora
	var fin := _contar()
	var tot: Array = []
	for k: String in fin:
		var d := int(fin[k]) - int(primera.get(k, 0))
		if d > 0:
			tot.append([d, k])
	tot.sort_custom(func(a, b) -> bool: return a[0] > b[0])
	print("TOTAL crecen desde el principio: ", tot.slice(0, 12))
	print("FIN")
	get_tree().quit()

func _total(c: Dictionary) -> int:
	var t := 0
	for k: String in c:
		t += int(c[k])
	return t

## Nodos por «clase/script» bajo la raíz.
func _contar() -> Dictionary:
	var c := {}
	for n: Node in get_tree().root.find_children("*", "", true, false):
		var k := n.get_class()
		var sc = n.get_script()
		if sc != null and (sc as Script).resource_path != "":
			k += ":" + (sc as Script).resource_path.get_file()
		c[k] = int(c.get(k, 0)) + 1
	return c
