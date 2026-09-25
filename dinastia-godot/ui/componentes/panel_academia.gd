class_name PanelAcademia
extends RefCounted
## LA ACADEMIA EN PANTALLA (25-9-2026): los chicos de 10 a 16 años de
## `Academia`, arriba de todo en Plantel → Cantera.
##
## Mismo patrón que `FichaJugadorAcciones`: una clase estática que pinta una
## vez por refresco, con la acción del jugador pasada como `Callable`
## (`al_cambiar`, que `principal.gd` usa para repintar). Toda la lógica vive en
## `nucleo/academia.gd`; aquí solo se decide qué se ve y qué botón llama a qué.
##
## Por chico: edad, puesto, nivel actual, la horquilla de proyección (el techo
## real está oculto), físico, nota del colegio, ánimo y el rasgo que va
## dominando. Y las cuatro decisiones de la semana: plan de trabajo,
## alimentación, estudios y molde de personalidad, más "Entregar al DT" desde
## los 15. Abajo, la captación de la temporada.

static func pintar(lista: VBoxContainer, mundo: Mundo, paleta: Dictionary, al_cambiar: Callable) -> void:
	var a := mundo.academia
	if a == null:
		return
	var tit := _texto(11, paleta["oro"], paleta)
	tit.text = "ACADEMIA · CHICOS DE %d A %d AÑOS" % [Academia.EDAD_MIN, Academia.EDAD_ENTREGA]
	lista.add_child(tit)
	var ex := _texto(11, paleta["suave"], paleta)
	ex.text = "Todavía no son jugadores: viven en la residencia. Tú decides cómo entrenan, qué comen y cuánto estudian, y moldeas su carácter. A los %d pasan al primer equipo, y llegan como los hayas formado. %d/%d plazas · %s por semana." % [
		Academia.EDAD_ENTREGA, a.chicos.size(), Academia.CUPO, Eco.dinero(a.coste_semanal())]
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(ex)

	var ordenados := a.chicos.duplicate()
	ordenados.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return int(x["edad"]) > int(y["edad"]))
	for ch: Dictionary in ordenados:
		lista.add_child(_tarjeta_chico(ch, a, paleta, al_cambiar))

	lista.add_child(HSeparator.new())
	var tc := _texto(11, paleta["oro"], paleta)
	tc.text = "CAPTACIÓN DE ESTA TEMPORADA"
	lista.add_child(tc)
	if a.candidatos.is_empty():
		var nadie := _texto(11, paleta["suave"], paleta)
		nadie.text = "Ya no quedan candidatos: la próxima tanda llega con la temporada nueva."
		lista.add_child(nadie)
	for i in a.candidatos.size():
		var ch: Dictionary = a.candidatos[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		var t := _texto(12, paleta["texto"], paleta)
		var r := a.proyeccion(ch)
		t.text = "%s  ·  %d años  ·  %s  ·  proyección %d-%d" % [ch["nombre"], int(ch["edad"]), ch["pos_e"], r.x, r.y]
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(t)
		var b := Button.new()
		b.text = "Captar · %s" % Eco.dinero(a.coste_captacion(ch))
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = a.chicos.size() >= Academia.CUPO
		var indice := i
		b.pressed.connect(func() -> void: al_cambiar.call(a.captar(indice)))
		fila.add_child(b)
		lista.add_child(fila)
	lista.add_child(HSeparator.new())

static func _tarjeta_chico(ch: Dictionary, a: Academia, paleta: Dictionary, al_cambiar: Callable) -> Control:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 3)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	caja.add_child(cab)
	var n := _texto(13, paleta["texto"], paleta)
	var lesion := "  🩹 %d sem." % int(ch["lesion"]) if int(ch["lesion"]) > 0 else ""
	n.text = "%s  ·  %d años  ·  %s%s" % [ch["nombre"], int(ch["edad"]), ch["pos_e"], lesion]
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(n)
	if int(ch["edad"]) >= Academia.EDAD_ENTREGA_ANTICIPADA:
		var e := Button.new()
		e.text = "Entregar al DT"
		e.tooltip_text = "Sube ya al primer equipo, sin esperar a los %d." % Academia.EDAD_ENTREGA
		e.add_theme_font_size_override("font_size", 11)
		var id := String(ch["id"])
		e.pressed.connect(func() -> void: al_cambiar.call(a.entregar(id)))
		cab.add_child(e)

	var r := a.proyeccion(ch)
	var nota := float(ch["nota"])
	var dom := a.rasgo_dominante(ch)
	var datos := _texto(11, paleta["suave"], paleta)
	datos.text = "nivel %d  ·  proyección %d-%d  ·  físico %d  ·  nota %.1f  ·  ánimo %d%s" % [
		int(round(float(ch["nivel"]))), r.x, r.y, int(round(float(ch["fisico"]))), nota,
		int(round(float(ch["animo"]))),
		("  ·  ✦ " + String(Academia.PERSONALIDAD[dom]["nombre"])) if dom != "" else ""]
	if nota < 4.2:
		datos.add_theme_color_override("font_color", paleta["rojo"])
	caja.add_child(datos)

	var controles := HFlowContainer.new()
	controles.add_theme_constant_override("h_separation", 6)
	controles.add_theme_constant_override("v_separation", 4)
	caja.add_child(controles)
	for campo: Array in [["plan", "Plan", Academia.PLANES], ["dieta", "Comida", Academia.DIETAS],
			["estudios", "Colegio", Academia.ESTUDIOS], ["molde", "Carácter", Academia.PERSONALIDAD]]:
		controles.add_child(_selector(ch, a, String(campo[0]), String(campo[1]), campo[2], paleta, al_cambiar))
	caja.add_child(HSeparator.new())
	return caja

static func _selector(ch: Dictionary, a: Academia, campo: String, etiqueta: String,
		catalogo: Dictionary, paleta: Dictionary, al_cambiar: Callable) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	var l := _texto(11, paleta["suave"], paleta)
	l.text = etiqueta
	h.add_child(l)
	var op := OptionButton.new()
	op.add_theme_font_size_override("font_size", 11)
	op.custom_minimum_size = Vector2(150, 26)
	op.fit_to_longest_item = false
	var claves: Array = catalogo.keys()
	for i in claves.size():
		var k := String(claves[i])
		op.add_item(String(catalogo[k]["nombre"]), i)
		op.set_item_tooltip(i, String(catalogo[k]["desc"]))
		if k == String(ch[campo]):
			op.select(i)
	op.tooltip_text = String(catalogo[String(ch[campo])]["desc"])
	var id := String(ch["id"])
	op.item_selected.connect(func(i: int) -> void:
		al_cambiar.call(a.cambiar(id, campo, String(claves[i]))))
	h.add_child(op)
	return h

static func _texto(tam: int, color: Color, paleta: Dictionary) -> Label:
	var l := Label.new()
	var escala: float = float(paleta.get("escala", 1.0))
	l.add_theme_font_size_override("font_size", maxi(8, int(round(float(tam) * escala))))
	l.add_theme_color_override("font_color", color)
	return l
