extends "res://ui/principal_p3.gd"
## [Capa 4/17 de `principal.gd`] _fuente_de, _caja, _pal_fondo, _aplicar_tema, _tinta, _escudo … (+9)

func _fuente_de(clave: String) -> Font:
	if not TIPOGRAFIAS.has(clave) or clave == "juego":
		return null
	if _fuentes.has(clave):
		return _fuentes[clave]
	var f := SystemFont.new()
	var nombres: Array = (TIPOGRAFIAS[clave] as Array)[1]
	f.font_names = PackedStringArray(nombres + REPUESTO_SIMBOLOS)
	## Sin esto, un texto pequeno con una serif se ve sucio: la rejilla de pixeles
	## y los remates finos pelean, y a 10 px gana la rejilla.
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	_fuentes[clave] = f
	return f

func _caja(fondo: Color, borde: Color, radio: int, grosor: int) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(grosor)
	e.set_corner_radius_all(radio)
	e.content_margin_left = 8
	e.content_margin_right = 8
	e.content_margin_top = 4
	e.content_margin_bottom = 4
	return e

## Los cuatro colores del lienzo. Se leen a través de estas funciones y no de la
## constante para que cambiar de paleta repinte todo de una vez.
func _pal_fondo() -> Color: return _ui_ajustes._color_pal(1, COL_FONDO)

func _aplicar_tema() -> void:
	var t := theme if theme != null else Theme.new()
	## La fuente va en `default_font` del tema: baja por todo -etiquetas, botones,
	## pestanas, el registro- sin tener que decirselo a cada clase.
	t.default_font = _fuente_de(_tipografia)
	var panel := _pal_panel()
	var texto := _pal_texto()
	var suave := _pal_suave()
	var borde := _ui_ajustes._pal_borde()
	var forma: Array = FORMAS_TARJETA.get(_forma_tarjeta, ["", 8, 1])
	var radio := int(forma[1])

	## El botón: un panel un pelo desplazado hacia el texto, para que se despegue
	## del fondo sin ser otro color. Encima aclara, pulsado se va al acento.
	var reposo := _mezcla(panel, texto, 0.14)
	t.set_stylebox("normal", "Button", _caja(reposo, borde, radio, 1))
	t.set_stylebox("hover", "Button", _caja(_mezcla(panel, texto, 0.24), borde, radio, 1))
	t.set_stylebox("pressed", "Button", _caja(_mezcla(panel, COL_ACENTO, 0.45), COL_ACENTO, radio, 1))
	t.set_stylebox("focus", "Button", _caja(Color(0, 0, 0, 0), COL_ACENTO, radio, 2))
	t.set_stylebox("disabled", "Button", _caja(_mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_color("font_color", "Button", texto)
	t.set_color("font_hover_color", "Button", texto)
	t.set_color("font_pressed_color", "Button", texto)
	t.set_color("font_disabled_color", "Button", _mezcla(suave, panel, 0.5))

	## Los desplegables y las casillas heredan del botón: en Godot son clases
	## distintas y si no se les dice nada se quedan con el tema oscuro de fábrica.
	for clase: String in ["OptionButton", "MenuButton", "CheckBox", "CheckButton"]:
		t.set_stylebox("normal", clase, _caja(reposo, borde, radio, 1))
		t.set_stylebox("hover", clase, _caja(_mezcla(panel, texto, 0.24), borde, radio, 1))
		t.set_stylebox("pressed", clase, _caja(_mezcla(panel, COL_ACENTO, 0.45), COL_ACENTO, radio, 1))
		t.set_color("font_color", clase, texto)
		t.set_color("font_hover_color", clase, texto)

	## Las pestañas. El fondo de la hoja es EL panel, sin borde: encima van las
	## tarjetas, y dos bordes pegados uno dentro de otro se ven como un error.
	var hoja := _caja(panel, borde, radio, 0)
	hoja.content_margin_left = 6
	hoja.content_margin_right = 6
	hoja.content_margin_top = 6
	hoja.content_margin_bottom = 6
	t.set_stylebox("panel", "TabContainer", hoja)
	t.set_stylebox("tabbar_background", "TabContainer", _caja(Color(0, 0, 0, 0), borde, 0, 0))
	t.set_stylebox("tab_selected", "TabContainer", _caja(_mezcla(panel, COL_ACENTO, 0.30), COL_ACENTO, radio, 1))
	t.set_stylebox("tab_unselected", "TabContainer", _caja(_mezcla(panel, texto, 0.06), borde, radio, 1))
	t.set_stylebox("tab_hovered", "TabContainer", _caja(_mezcla(panel, texto, 0.18), borde, radio, 1))
	t.set_color("font_selected_color", "TabContainer", texto)
	t.set_color("font_unselected_color", "TabContainer", suave)
	t.set_color("font_hovered_color", "TabContainer", texto)

	t.set_stylebox("panel", "Panel", _caja(panel, borde, radio, 1))
	t.set_stylebox("panel", "PanelContainer", _caja(panel, borde, radio, 1))
	t.set_stylebox("panel", "PopupPanel", _caja(_mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_stylebox("panel", "PopupMenu", _caja(_mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_color("font_color", "PopupMenu", texto)
	t.set_color("font_hover_color", "PopupMenu", texto)

	## Los campos de texto. El fondo va al REVÉS que el botón -hacia el fondo, no
	## hacia el texto- porque un cuadro donde se escribe tiene que verse hundido.
	var hueco := _caja(_mezcla(panel, _pal_fondo(), 0.55), borde, radio, 1)
	for clase2: String in ["LineEdit", "TextEdit", "SpinBox"]:
		t.set_stylebox("normal", clase2, hueco)
		t.set_color("font_color", clase2, texto)
		t.set_color("font_placeholder_color", clase2, suave)
		t.set_color("caret_color", clase2, COL_ACENTO)
	t.set_stylebox("focus", "LineEdit", _caja(_mezcla(panel, _pal_fondo(), 0.55), COL_ACENTO, radio, 2))

	## Barras y deslizadores.
	t.set_stylebox("slider", "HSlider", _caja(_mezcla(panel, _pal_fondo(), 0.5), borde, 3, 0))
	t.set_stylebox("grabber_area", "HSlider", _caja(COL_ACENTO, COL_ACENTO, 3, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", _caja(COL_ACENTO, COL_ACENTO, 3, 0))
	t.set_stylebox("background", "ProgressBar", _caja(_mezcla(panel, _pal_fondo(), 0.5), borde, 3, 0))
	t.set_stylebox("fill", "ProgressBar", _caja(COL_ACENTO, COL_ACENTO, 3, 0))

	t.set_color("default_color", "RichTextLabel", texto)
	t.set_color("font_color", "Label", texto)
	t.set_color("font_color", "ItemList", texto)
	t.set_stylebox("panel", "ItemList", _caja(_mezcla(panel, _pal_fondo(), 0.4), borde, radio, 1))
	t.set_color("font_color", "Tree", texto)
	t.set_stylebox("panel", "Tree", _caja(_mezcla(panel, _pal_fondo(), 0.4), borde, radio, 1))

	## La separación entre filas la sigue mandando la vista compacta: se vuelve a
	## poner aquí porque este `Theme` es el mismo objeto y el orden de llamadas
	## entre las dos funciones no está garantizado.
	var sep := SEPARACION_COMPACTA if _vista_compacta else SEPARACION_NORMAL
	for clase3: String in ["BoxContainer", "VBoxContainer", "HBoxContainer"]:
		t.set_constant("separation", clase3, sep)
	theme = t

## Blanco o negro sobre el color del escudo, según su luminosidad. Es el `lumTx`
## del HTML: sin esto, las iniciales de un club amarillo se leen en blanco y
## desaparecen.
func _tinta(fondo: Color) -> Color:
	var lum := 0.299 * fondo.r + 0.587 * fondo.g + 0.114 * fondo.b
	return Color("0c130e") if lum > 0.59 else Color("ffffff")

## Un escudo con sus iniciales encima, listo para meter en una fila.
##
## Las letras van FUERA del SVG porque el rasterizador de Godot no dibuja
## `<text>`: un SVG con texto carga sin error y sale sin las letras. Puestas
## como etiqueta encima quedan además más nítidas y con el color correcto según
## lo claro u oscuro que sea el escudo.
func _escudo(c: Club, alto: int = 22) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	var t := TextureRect.new()
	t.texture = Escudo.textura(c, alto)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := Label.new()
	## EL SÍMBOLO ("ESC_SIM" del HTML) REEMPLAZA A LAS INICIALES, no se suman
	## las dos cosas -mismo "sym ? ... : ini" del HTML-. Es un emoji, así que
	## tampoco necesita el color de contraste que sí hace falta para que dos
	## letras se lean sobre cualquier fondo de escudo.
	var simbolo := Escudo.simbolo_de(c)
	if simbolo != "":
		l.text = simbolo
		l.add_theme_font_size_override("font_size", maxi(9, int(float(alto) * 0.55)))
	else:
		l.text = Escudo.iniciales(c)
		l.add_theme_font_size_override("font_size", maxi(8, alto / 2 - 2))
		l.add_theme_color_override("font_color", _tinta(Color(c.color1)))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	## Las iniciales se suben un poco: el escudo es más alto que ancho y en el
	## centro geométrico quedan bajas respecto al centro visual.
	l.offset_top = -float(alto) * 0.10
	caja.add_child(l)
	return caja

func _color_accesible(c: Color) -> Color:
	if not _daltonico:
		return c
	if c == COL_VERDE:
		return COL_VERDE_DALT
	if c == COL_ROJO:
		return COL_ROJO_DALT
	if c == COL_ORO:
		return COL_ORO_DALT
	return c

func _perezoso(cont: Control, pintar: Callable) -> void:
	if pintar_todo or cont == null or not cont.is_inside_tree() or cont.is_visible_in_tree():
		_pendientes.erase(cont)
		pintar.call()
	else:
		_pendientes[cont] = pintar

## TODA la interfaz pasa por aqui, y por eso los dos ajustes de accesibilidad
## -el tamano del texto y la paleta para daltonismo- se aplican en este punto y
## no en las mil y pico llamadas repartidas por el archivo.
func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", maxi(8, int(round(float(tam) * _escala_texto))))
	l.add_theme_color_override("font_color", _color_accesible(_color_de_paleta(color)))
	return l

func _boton(texto: String, accion: Callable, padre: Node = null) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 32)
	## Un Button pide de ancho mínimo lo que mida su texto, y varios botones
	## largos en fila desbordan la ventana sin dar ningún error: solo se ve en
	## una captura. Con `clip_text` la fila puede encoger; el tooltip guarda el
	## texto entero para cuando no quepa.
	b.clip_text = true
	b.tooltip_text = texto
	## Con `clip_text` a secas un botón puede encoger hasta CERO y desaparecer:
	## la primera vez que se probó esto, la fila entera de acciones se quedó en
	## siete rayas de un píxel. El mínimo garantiza que siempre se lea algo.
	b.custom_minimum_size.x = 92
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## Y el reparto del ancho va POR LARGO DEL ROTULO. Todos los botones de la
	## fila expandian igual, asi que "Guardar" sobraba sitio mientras "Temporada
	## siguiente" se quedaba en "Temporada s". Con esto cada uno pide lo suyo.
	b.size_flags_stretch_ratio = clampf(float(texto.length()) / 12.0, 0.95, 1.9)
	b.pressed.connect(accion)
	(padre if padre != null else _botones).add_child(b)
	return b

func _votar(opcion: String) -> void:
	var asamblea: Array = mundo.liga_de(mundo.mi_club()).clubes
	var r := mundo.federacion.votar(opcion, mundo.mi_club(), asamblea)
	var paso := bool(r.get("pasa", false))
	var contigo := bool(r.get("ganaste", false))
	_escribir("[color=%s]La votación %s.[/color] %s" % [
		"#4caf6d" if contigo else "#e05555",
		"sale adelante" if paso else "se rechaza",
		"Salió lo que querías." if contigo else "La asamblea votó al revés que tú."])
	if String(r.get("efecto", "")) != "":
		_escribir("[color=#8ea595]%s[/color]" % String(r["efecto"]))
	(self as Principal)._refrescar()

# --- las cuatro pantallas que faltaban -------------------------------------
#
# Cuatro sistemas enteros estaban en el motor, probados y guardados, y no se
# podían tocar jugando. Un sistema sin pantalla no existe para quien juega, por
# muy bien que funcione por dentro.

func _pintar_federacion(c: Club) -> void:
	_limpiar(_lista_fed)
	var f := mundo.federacion
	## EL PRESIDENTE (C5): quién manda y qué empuja.
	if not f.presidente.is_empty():
		var ag: Array = Federacion.AGENDAS[String(f.presidente["agenda"])]
		var tp := _texto(12, COL_ORO)
		tp.text = Idiomas.t("🏛️ Presidente: %s · corriente %s · mandato hasta %d") % [String(f.presidente["nombre"]), String(ag[0]).to_lower(), int(f.presidente["hasta"])]
		tp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(tp)
		var lema := _texto(11, COL_SUAVE)
		lema.text = String(ag[2]) + Idiomas.t(" Sus propuestas salen antes en la asamblea y hace campaña por ellas.")
		lema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(lema)
	_ui_club_vida._pintar_gobierno(c)
	_ui_club_vida._pintar_licencia_y_tribunal(c, f)
	_ui_club_vida._pintar_historial_federacion(f)
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("REGLAMENTO VIGENTE")
	_lista_fed.add_child(t)
	for regla in f.reglas_vigentes(c.pais if c != null else ""):
		var l := _texto(12, COL_TEXTO)
		l.text = "· " + String(regla)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(l)
	## CUMPLIR O INCUMPLIR LAS REGLAS DE LA LIGA (7-10-2026): una decisión
	## del club, con su precio.
	if c != null:
		var inf: Dictionary = f.infracciones_de(mundo.anio)
		var est := _texto(12, COL_SUAVE)
		est.text = Idiomas.t("Política con el reglamento: %s · esta temporada: %d semana(s) con el plantel fuera de cupo, %d alineación(es) indebida(s)") % [
			Idiomas.t("CUMPLIR (el once se corrige solo)") if c.ley_politica == "cumplir" else Idiomas.t("INCUMPLIR (pagas multas; a la tercera alineación indebida, 3 puntos menos cada vez)"),
			int(inf.get("plantel", 0)), int(inf.get("alin", 0))]
		est.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(est)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		for op: Array in [["cumplir", "✅ Cumplir el reglamento"], ["incumplir", "⚠️ Incumplir y asumir multas"]]:
			var bt := Button.new()
			bt.text = String(op[1])
			bt.toggle_mode = true
			bt.button_pressed = c.ley_politica == String(op[0])
			var valor := String(op[0])
			bt.pressed.connect(func() -> void:
				c.ley_politica = valor
				_pintar_federacion(c))
			fila.add_child(bt)
		_lista_fed.add_child(fila)

	if f.voto_pendiente.is_empty():
		_lista_fed.add_child(HSeparator.new())
		var nada := _texto(12, COL_SUAVE)
		nada.text = Idiomas.t("No hay ninguna votación abierta. La federación convoca cada tanto.")
		nada.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(nada)
		return

	## La votación pendiente. Tu voto no decide solo: hay una asamblea, y por eso
	## se puede votar a favor y perder — que es lo que hace que votar signifique
	## algo en vez de ser un interruptor.
	_lista_fed.add_child(HSeparator.new())
	var v: Dictionary = f.voto_pendiente
	var t2 := _texto(11, COL_ORO)
	t2.text = Idiomas.t("VOTACIÓN ABIERTA")
	_lista_fed.add_child(t2)
	var q := _texto(13, COL_TEXTO)
	## La tabla VOTACIONES guarda el título en "t", no en "titulo" -esa clave
	## nunca existió-, así que esto mostraba el id interno en crudo ("tvigual")
	## en vez de "Reparto igualitario de los derechos de TV". Corregido 14-9-2026.
	q.text = String(v.get("t", v.get("id", "")))
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_fed.add_child(q)
	var d := _texto(12, COL_SUAVE)
	d.text = String(v.get("texto", v.get("desc", "")))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_fed.add_child(d)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_lista_fed.add_child(fila)
	## `Federacion.votar()` -portado tal cual del HTML- solo distingue "a" (a
	## favor) de cualquier otra cosa (en contra): mandar "si" nunca es igual a
	## "a", así que el botón "A favor" jamás sumaba tu voto explícito y el
	## mensaje de "ganaste/perdiste" salía invertido cada vez que votabas a
	## favor. Corregido 14-9-2026. "Abstenerse" no existe en el original -es
	## un tercer botón agregado en la migración- y hoy cae en la misma rama que
	## "En contra" (cuenta igual, sin el bono de "a favor"): si alguna vez se
	## quiere que abstenerse no cuente en el total, hace falta un tercer caso en
	## `votar()`, decisión de diseño que no tocamos aquí.
	_boton("A favor", func() -> void: _votar("a"), fila)
	_boton("En contra", func() -> void: _votar("b"), fila)
	_boton("Abstenerse", func() -> void: _votar("abs"), fila)

## Abre el visor 3D del propio estadio, vacío -sin rival ni partido-, para
## mirarlo desde Club → Estadio en vez de tener que esperar al próximo partido
## en casa. Mismo patrón exacto que `partido_vivo._ver_estadio()`: se cuelga
## de la raíz y se libera solo al volver, `VistaEstadio` ya sabe dar tamaño a
## sí mismo. La ocupación de las gradas es la de verdad -la misma cuenta que
## usa el partido en vivo-, no un número fijo: un estadio medio vacío tiene
## que verse medio vacío también aquí.
## FUNDIDO DE ENTRADA (etapa 1, 8-10-2026): al abrir una escena 3D grande
## (ciudad, estadio, partido) la pantalla saltaba de golpe del menú al 3D, a
## veces con un fotograma a medio construir. Un velo negro por encima de todo
## que se aclara en medio segundo.
func _fundido_entrada() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 120
	get_tree().root.add_child(capa)
	var velo := ColorRect.new()
	velo.color = Color.BLACK
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(velo)
	var tw := velo.create_tween()
	tw.tween_interval(0.12)
	tw.tween_property(velo, "modulate:a", 0.0, 0.5)
	tw.tween_callback(capa.queue_free)

func _goleadores_de(clubes: Array) -> Array:
	var tiradores: Array = []
	for c: Club in clubes:
		for j: Jugador in c.plantilla:
			if j.goles > 0:
				tiradores.append({"nombre": j.nombre, "club": c.nombre, "goles": j.goles})
	tiradores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["goles"]) > int(b["goles"]))
	return tiradores.slice(0, 8)

## LO QUE ENSEÑA LA PANTALLA GIGANTE DEL ESTADIO (23-9-2026, pedido repetido:
## "una visualización de los puntos de la competencia... máximos goleadores").
##
## `VistaEstadio` es un VISOR: conoce clubes y partido, no el `Mundo` -y no
## debe conocerlo, igual que no conoce ni la economía ni el mercado-. Así que
## la tabla, los goleadores y los nombres se calculan aquí, que es donde el
## mundo está delante, y se le pasan ya masticados. Mismo patrón exacto que
## `perfil_estadio_de()` y `Comercial.color_balon()`, que ya viajaban así.
##
## `local` es el dueño del recinto: la tabla que se enseña es la de SU liga
## -un partido de copa entre divisiones distintas enseña la del anfitrión-,
## no la del club del usuario.
## `comp` (26-9-2026): "liga", "copa" o "conti". Antes la pantalla enseñaba
## SIEMPRE la liga del local, también en un partido de copa o de la copa
## continental; ahora enseña la competición que se está jugando.
func _datos_pantalla_estadio(local: Club, comp: String = "liga") -> Dictionary:
	var d: Dictionary = {
		"tabla": [], "goleadores": [], "liga": "", "jornada": 0, "recinto": "", "cruces": [],
	}
	if local == null or mundo == null:
		return d
	## El nombre propio del recinto solo vale para TU estadio: `mundo.estadio`
	## es el diseñador de tu club, y llamar a `nombre_de()` con un rival
	## devolvería el nombre que tú le pusiste al tuyo.
	if local.estadio_nombre != "":
		d["recinto"] = local.estadio_nombre
	elif local == mundo.mi_club() and mundo.estadio != null:
		d["recinto"] = mundo.estadio.nombre_de(local)
	else:
		d["recinto"] = "Estadio " + Nombres.visible(local.nombre)
	if comp == "copa" and mundo.copa != null:
		d["liga"] = "%s · %s" % [mundo.copa.nombre, mundo.copa.nombre_de_ronda()]
		for par: Array in mundo.copa.cruces():
			d["cruces"].append([Nombres.visible((par[0] as Club).nombre), Nombres.visible((par[1] as Club).nombre)])
		d["goleadores"] = _goleadores_de(mundo.copa.vivos)
		return d
	var conti := mundo.mi_continental()
	if comp == "conti" and conti != null:
		d["liga"] = "%s · %s" % [Continental.nombre_conti(conti.clave), conti.nombre_de_ronda()]
		if conti.en_fase_de_grupos():
			for gi in conti.grupos.size():
				if (conti.grupos[gi] as Array).has(local) or (conti.grupos[gi] as Array).has(mundo.mi_club()):
					d["titulo_tabla"] = "GRUPO " + conti.nombre_de_grupo(gi).to_upper()
					for f: Dictionary in conti.tabla_de_grupo(gi):
						var cg: Club = f["club"]
						d["tabla"].append({"id": cg.id, "nombre": cg.nombre, "pts": int(f["pts"]), "pj": int(f["pj"]), "dif": int(f["dif"])})
					break
		else:
			for par2: Array in conti.cruces():
				d["cruces"].append([Nombres.visible((par2[0] as Club).nombre), Nombres.visible((par2[1] as Club).nombre)])
		d["goleadores"] = _goleadores_de(conti.vivos)
		return d
	var l: Liga = mundo.liga_de(local)
	if l == null:
		return d
	d["liga"] = l.nombre
	d["jornada"] = l.jornada_actual
	var filas: Array = []
	for f: Dictionary in l.tabla():
		var c: Club = f["club"]
		filas.append({
			"id": c.id, "nombre": c.nombre, "pts": int(f["pts"]),
			"pj": int(f["pj"]), "dif": int(f["dif"]),
		})
	d["tabla"] = filas
	## Los goleadores de ESA liga, no del mundo entero: es la pantalla de ese
	## estadio, no un ranking global. Sin goles todavía (jornada 1) la lista
	## sale vacía y la pantalla simplemente no rota a ese panel.
	d["goleadores"] = _goleadores_de(l.clubes)
	return d
