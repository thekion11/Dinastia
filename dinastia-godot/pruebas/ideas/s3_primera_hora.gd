extends BaseIdea
## s3 (26-10-2026): LOS PUNTOS DE «PRIMERA HORA» del plan §8 (informe onb): botones de la cabecera
## que son solo un icono, el panel OBJETIVOS encima de la ficha, reabrir el tutorial y el carril
## de chips de una pestaña que no es del bloque abierto.
var _p: Principal

func _ready() -> void:
	await get_tree().process_frame
	_titulo("S3: PRIMERA HORA (cabecera, objetivos, tutorial, carril de chips)")
	var m := Mundo.new()
	m.generar([], 20261026)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	Principal.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 4:
		await get_tree().process_frame
	_cabecera()
	await _objetivos()
	await _tutorial()
	await _carril()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _cabecera() -> void:
	var sin_ayuda: Array[String] = []
	var vistos := 0
	for b in _p.find_children("*", "Button", true, false):
		var t := String((b as Button).text).strip_edges()
		## Un botón sin letras (solo icono): necesita su ayuda.
		var letras := false
		for i in t.length():
			letras = letras or (t.unicode_at(i) < 0x2000 and t.unicode_at(i) > 64)
		if t != "" and not letras and (b as Button).is_visible_in_tree() and _p.get("_botones").is_ancestor_of(b):
			vistos += 1
			if String((b as Button).tooltip_text).strip_edges() == "":
				sin_ayuda.append(t)
	_comprobar(vistos >= 3 and sin_ayuda.is_empty(), "los botones de la cabecera que son solo un icono dicen qué hacen al pasar por encima (%d, sin ayuda: %s)" % [vistos, str(sin_ayuda)])

func _objetivos() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	var po: PanelObjetivos = _p.get("_panel_obj")
	var guardado_antes: Variant = PanelObjetivos._leer("plegado_v2", null)
	po._plegado = false
	po._aplicar_plegado()
	for i in 3:
		await get_tree().process_frame
	var j: Jugador = _p.mundo.mi_club().plantilla[2]
	_p._ver_ficha(j)
	_comprobar(po._plegado, "a 1280×720, abrir la ficha de un jugador pliega el panel de objetivos que la tapaba")
	_comprobar(PanelObjetivos._leer("plegado_v2", null) == guardado_antes, "y ese plegado no se guarda como preferencia")

func _tutorial() -> void:
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	await get_tree().process_frame
	var antes := _contar_tutoriales()
	_p.abrir_tutorial()
	await get_tree().process_frame
	_comprobar(antes == 0 and _contar_tutoriales() == 1, "cerrado el tutorial, se vuelve a abrir (con «Hablar con el mentor» o Ajustes → Interfaz)")
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	await get_tree().process_frame

func _contar_tutoriales() -> int:
	var n := 0
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial and not (t as Node).is_queued_for_deletion():
			n += 1
	return n

func _carril() -> void:
	_p._elegir_grupo("central")
	await get_tree().process_frame
	_p._ir_a_pestana("Finanzas")
	for i in 2:
		await get_tree().process_frame
	var textos: Array[String] = []
	var marcado := ""
	for b in (_p.get("_fila_sub") as Node).get_children():
		if String((b as Button).text) == "?":
			continue
		textos.append(String((b as Button).text))
		if (b as Button).button_pressed:
			marcado = String((b as Button).text)
	_comprobar(textos == ["Finanzas", "Mercado", "Libres"] and marcado == "Finanzas",
		"en Finanzas, el carril enseña su hub (%s) con Finanzas marcado, no el del bloque anterior" % ", ".join(textos))
