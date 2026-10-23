class_name PantallaCantera
extends "res://ui/pantallas/pantalla_cantera_p2.gd"
## (Parte 3 de 3 de `pantalla_cantera.gd`.)

## `vComparador()` de vistas.js -un archivo aparte de juego.js que esta sesión
## no había mirado hasta ahora, y donde vive el render real de las 33
## sub-pestañas de "Club"-: hasta tres jugadores lado a lado, con el mejor
## valor de cada fila resaltado en verde. Fuera de alcance a propósito: la
## fila "Ansiedad" del HTML no tiene equivalente -Godot no tiene portado
## `j.mente.ansiedad`, es un sistema propio, no un olvido de esta fila-. El
## "modo ciego" sí se portó después (`Ojeadores.modo_ciego`): esta tabla en
## particular no usa la palabra cualitativa de `ovr_palabra()` -el HTML tampoco
## lo hace aquí-, sino un simple "?" en la fila Media, igual que ya hacía la
## fila Proyección para quien no conocías.
func _pintar_comparar() -> void:
	p._limpiar(p._lista_comparar)
	var jugadores: Array[Jugador] = []
	for id in p._comparar_ids:
		var j := p.mundo.jugador_por_id(id)
		if j != null:
			jugadores.append(j)
	## Si alguno se vendió, se retiró o fue rescindido entre medio, desaparece
	## solo del comparador -no queda un id muerto señalando a nadie-.
	p._comparar_ids.clear()
	for j in jugadores:
		p._comparar_ids.append(j.id)

	if jugadores.is_empty():
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = Idiomas.t("Abre la ficha de cualquier jugador y pulsa «Comparar» para ponerlo aquí. Puedes enfrentar hasta tres a la vez, de tu club o de cualquier otro.")
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_comparar.add_child(vacio)
		return

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 12)
	p._lista_comparar.add_child(cabecera)
	for j in jugadores:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cabecera.add_child(col)
		var retrato := TextureRect.new()
		var suyo: Club = p.mundo.clubes.get(j.club_id)
		retrato.texture = Cara.textura(j, suyo.color1 if suyo else "#2b6b45", suyo.color2 if suyo else "#ffffff", 48)
		retrato.custom_minimum_size = Vector2(48, 48)
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(retrato)
		var nom := p._texto(11, Principal.COL_TEXTO)
		nom.text = _apellido(j.nombre)
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(nom)
		var bq := Button.new()
		bq.text = "✕"
		bq.custom_minimum_size = Vector2(0, 26)
		bq.pressed.connect(func() -> void: _alternar_comparar(j))
		col.add_child(bq)
	p._lista_comparar.add_child(HSeparator.new())

	var g := GridContainer.new()
	g.columns = 1 + jugadores.size()
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 3)
	p._lista_comparar.add_child(g)

	## `mostrar_de` es aparte de `valor_de` para que Valor/Sueldo comparen el
	## número de verdad (`j.valor`/`j.sueldo`) y no la cadena ya formateada
	## ("7.4M EUR" nunca es `is int`, así que comparar cadenas dejaba a los
	## tres empatados en 0 y los resaltaba a los tres, o a ninguno).
	var conoce := func(j: Jugador) -> bool: return j.club_id == p.mundo.mi_club_id or p.mundo.ojeados.has(j.id)
	## `cegado()` del HTML: en "mercado a ciegas" ni la Media se enseña de
	## quien no conoces -aquí se ve un "?", no la palabra cualitativa de
	## `ovr_palabra()`, tal cual hace el HTML en ESTA tabla en particular-.
	var cegado := func(j: Jugador) -> bool:
		return p.mundo.ojeadores != null and p.mundo.ojeadores.modo_ciego and not conoce.call(j)
	var edad_de := func(j: Jugador) -> Variant: return j.edad
	var valor_de := func(j: Jugador) -> Variant: return j.valor
	var sueldo_de := func(j: Jugador) -> Variant: return j.sueldo
	var como_dinero := func(v: Variant) -> String: return p._dinero(int(v))
	_fila_comparar(g, jugadores, "Media", func(j: Jugador) -> Variant: return "?" if cegado.call(j) else j.ovr)
	_fila_comparar(g, jugadores, "Proyección", func(j: Jugador) -> Variant: return j.pot if conoce.call(j) else "?")
	_fila_comparar(g, jugadores, "Edad", edad_de, false)
	_fila_comparar(g, jugadores, "Valor", valor_de, true, como_dinero)
	_fila_comparar(g, jugadores, "Sueldo", sueldo_de, false, como_dinero)
	var claves := jugadores[0].atributos.keys() if not jugadores.is_empty() else []
	for k: String in claves:
		var clave := k
		_fila_comparar(g, jugadores, String(Principal.NOMBRES_ATRIBUTOS.get(clave, clave)),
			func(j: Jugador) -> Variant: return int(j.atributos.get(clave, 0)) if j.atributos.has(clave) else "—")
	_fila_comparar(g, jugadores, "Forma", func(j: Jugador) -> Variant: return j.forma)
	_fila_comparar(g, jugadores, "Físico", func(j: Jugador) -> Variant: return j.fisico)
	_fila_comparar(g, jugadores, "Goles", func(j: Jugador) -> Variant: return j.goles)
	_fila_comparar(g, jugadores, "Partidos", func(j: Jugador) -> Variant: return j.partidos)

	if p.mundo.entrenamiento != null:
		p._lista_comparar.add_child(HSeparator.new())
		var th := p._texto(11, Principal.COL_SUAVE)
		th.text = Idiomas.t("HABILIDADES")
		p._lista_comparar.add_child(th)
		for j in jugadores:
			var claves_hab: Array = p.mundo.entrenamiento.habilidades(j)
			var nombres: Array[String] = []
			for k2 in claves_hab:
				nombres.append(p.mundo.entrenamiento.nombre_habilidad(String(k2)))
			var fh := HBoxContainer.new()
			p._lista_comparar.add_child(fh)
			var eq := p._texto(11, Principal.COL_TEXTO)
			eq.text = _apellido(j.nombre)
			eq.custom_minimum_size = Vector2(90, 0)
			fh.add_child(eq)
			var vh := p._texto(11, Principal.COL_SUAVE)
			vh.text = ", ".join(nombres) if not nombres.is_empty() else "—"
			vh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fh.add_child(vh)

	var vaciar := func() -> void:
		p._comparar_ids.clear()
		_pintar_comparar()
	p._boton("Vaciar comparador", vaciar, p._lista_comparar)

## `vRecords()` de vistas.js: rachas, marcas, goleadores e historial cara a
## cara. Todo esto ya lo llevaba `Logros` -`h2h`, `rachas`, `rec`, `efemerides`,
## `planteles`- desde que se enganchó la memoria del club, probado y guardado,
## pero la pestaña Logros solo enseñaba la vitrina de títulos y el top 5 de
## goleadores: el resto vivía en el guardado sin que nadie lo viera nunca.
## `vLegado()`: lo que queda de ti cuando te vas. Es la ÚNICA pantalla del juego
## que no habla del club sino del entrenador: el club se pierde al cambiar de
## banco, esto te sigue. Cuatro bloques, en el orden del HTML — el resumen, el
## palmarés, la escalera de rol y los homenajes— más el epílogo, que solo aparece
## a partir de la tercera temporada porque antes no hay carrera que resumir.
## `vInicio()`: la portada del club. Es la pantalla que el HTML abre por defecto
## cada semana y la que aquí no existía: se entraba directamente al Estadio y
## había que ir tabulando para saber si tenías gente lesionada o cómo iba la
## caja.
##
## No repite información: la RESUME y la enlaza. Los cuatro recuadros son atajos
## -pulsarlos lleva a la pestaña donde de verdad se decide-, que es lo que hace
## que una portada sirva para algo en vez de ser un adorno de bienvenida.
## EL INFORME DE GESTIÓN. Lo primero de la pantalla de Inicio: las seis cosas
## que hay que mirar cada lunes, juntas y con el botón que lleva a arreglarlas.
##
## No añade ninguna mecánica: junta lo que ya está repartido por ocho pestañas.
## Este juego tiene dieciocho, y sin esto un jugador nuevo no sabe cuáles mirar
## y uno veterano se olvida siempre de la misma.
func _pintar_informe() -> void:
	var lineas := p.mundo.informe_de_gestion()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("📋 INFORME DE LA SEMANA")
	p._lista_inicio.add_child(t)
	for f: Dictionary in lineas:
		var grave := bool(f["grave"])
		var tab := String(f.get("tab", ""))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_inicio.add_child(fila)
		var n := p._texto(12, Principal.COL_ROJO if grave else Principal.COL_TEXTO)
		## Traducido ANTES de ponerle la viñeta: los patrones con números
		## («5 contratos terminan…») empiezan en la frase, no en «●».
		n.text = "%s %s" % ["●" if grave else "○", Idiomas.t(String(f["txt"]))]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(n)
		if tab == "":
			continue
		var b := Button.new()
		b.text = Idiomas.t(tab)
		b.add_theme_font_size_override("font_size", 10)
		b.clip_text = true
		b.custom_minimum_size = Vector2(92, 24)
		b.pressed.connect(func() -> void: p._ir_a_pestana(tab))
		fila.add_child(b)
	p._lista_inicio.add_child(HSeparator.new())
