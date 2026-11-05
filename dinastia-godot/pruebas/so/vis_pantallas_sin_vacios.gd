extends BaseSO
## VISUALIZACIÓN · ninguna pantalla del menú sale vacía, comprobado sobre el ÁRBOL (sin dibujar: vale en --headless, Web y Android sin GPU de
## pruebas): en cada pestaña hay controles visibles con texto, botones que se pueden pulsar y nada de «null» ni de marcas sin sustituir (%s, {x}, ???).
func _nombre() -> String:
	return "vis_pantallas_sin_vacios"

const PESTANAS := ["Inicio", "Mi plantel", "Táctica", "Entrenar", "Enfermería", "Cantera", "Contratos", "Calendario", "Finanzas", "Mercado", "Clubes", "Copa", "Correo", "Estadio", "Récords", "Ajustes", "Glosario"]

func _probar() -> void:
	_titulo("VISUALIZACIÓN · pantallas con contenido [%s]" % sistema())
	_respaldar_user()
	Animar._reducidas = 1
	PedidoPartida.mundo_pregenerado = _mundo(20261026)
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _frames(10)
	for t in get_tree().root.find_children("*", "Tutorial", true, false):
		(t as Tutorial)._terminar(false)
	CapasTutorial.poner_activas(false)
	var feas: Array[String] = []
	for tab in PESTANAS:
		p._ir_a_pestana(tab)
		await _frames(12)
		var con_texto := 0
		var botones := 0
		for n in p.find_children("*", "Control", true, false):
			var c := n as Control
			if not c.is_visible_in_tree():
				continue
			var txt := ""
			if c is Label:
				txt = (c as Label).text
			elif c is Button:
				txt = (c as Button).text
				botones += 1
			elif c is RichTextLabel:
				txt = (c as RichTextLabel).get_parsed_text()
			if txt.strip_edges() != "":
				con_texto += 1
				if txt == "null" or txt.contains("<null>") or txt.contains("???") or RegEx.create_from_string("%[sdf]").search(txt) != null or txt.contains("{x}"):
					feas.append("%s: «%s»" % [tab, txt.left(30)])
		_comprobar(con_texto >= 6, "«%s»: %d textos visibles" % [tab, con_texto])
		_comprobar(botones >= 1, "«%s»: %d botones visibles" % [tab, botones])
	_comprobar(feas.is_empty(), "ningún texto roto (null, ???, %%s, {x}) %s" % str(feas.slice(0, 5)))
	p.queue_free()
	await _frames(2)
	_restaurar_user()
