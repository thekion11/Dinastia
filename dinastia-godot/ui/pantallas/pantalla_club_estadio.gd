class_name PantallaClubEstadio
extends "res://ui/pantallas/pantalla_club_estadio_p1.gd"
## [Capa 2/2 de `pantalla_club_estadio.gd`] _pintar_estadio
## CLUB → ESTADIO: la pestaña entera (nombre, visor 3D, hinchada, los 17 campos del
## diseño, tribunas, tercios y recinto) llegó aquí desde `Principal` el 27-10 (fase 6, paso 6).

func _pintar_estadio(c: Club) -> void:
	p._limpiar(p._lista_estadio)
	var e := p.mundo.estadio
	var perf := p.mundo.perfil_estadio_de(c)
	var t := p._texto(13, p.COL_ORO)
	t.text = c.estadio_nombre if c.estadio_nombre != "" else e.nombre_de(c)
	p._lista_estadio.add_child(t)
	## Reforma en obras: el diseñador enseña el PROYECTO; el estadio que se ve y
	## se juega sigue siendo el de antes hasta que termine.
	if e.en_obras():
		var ob := p._texto(12, Color(1.0, 0.8, 0.3))
		ob.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ob.text = Idiomas.t("🏗️ Reforma en obras: faltan %d de %d semanas. Aquí ves el proyecto; en la ciudad y en los partidos sigue el estadio de siempre, con andamios.") % [
			int(e.obra["semanas"]), int(e.obra["total"])]
		p._lista_estadio.add_child(ob)
	## PONERLE NOMBRE AL ESTADIO, de `vEstadio()`. Es lo más barato que puede
	## hacer un club por su identidad y lo primero que hace cualquiera al llegar
	## a uno nuevo. Vacío vuelve al nombre por defecto: no se puede quedar sin.
	var fila_n := HBoxContainer.new()
	fila_n.add_theme_constant_override("separation", 6)
	p._lista_estadio.add_child(fila_n)
	var campo_nombre := LineEdit.new()
	campo_nombre.placeholder_text = Idiomas.t("Ponle nombre al estadio…")
	campo_nombre.text = c.estadio_nombre
	campo_nombre.add_theme_font_size_override("font_size", 11)
	campo_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo_nombre.text_submitted.connect(func(v: String) -> void:
		c.estadio_nombre = v.strip_edges()
		p._refrescar())
	fila_n.add_child(campo_nombre)
	var bn := Button.new()
	bn.text = Idiomas.t("Guardar")
	bn.add_theme_font_size_override("font_size", 11)
	bn.pressed.connect(func() -> void:
		c.estadio_nombre = campo_nombre.text.strip_edges()
		p._refrescar())
	fila_n.add_child(bn)
	## VER EL DISEÑO DE VERDAD, no solo leerlo en desplegables. Hasta ahora
	## `VistaEstadio` -el visor 3D completo, con gradas, césped y focos- solo se
	## abría desde el partido en vivo (`partido_vivo.gd`): para ver cómo había
	## quedado una reforma había que esperar al próximo partido en casa. El
	## mismo visor sirve vacío -`abrir(club)`, su primer modo, pensado para
	## justo esto- así que se engancha aquí también, sin duplicar nada.
	var ver3d := Button.new()
	ver3d.text = Idiomas.t("👁️ Ver mi estadio en 3D")
	ver3d.add_theme_font_size_override("font_size", 11)
	ver3d.pressed.connect(p._ver_estadio_con_carga)
	fila_n.add_child(ver3d)
	_pintar_estilos_estadio(c)
	## LA HINCHADA. `Prensa.animo` y `Prensa.funa` se mueven solos desde hace
	## tiempo -banderazos si el ánimo pasa de 82, lienzos si baja de 22- y no se
	## veían en ninguna pantalla: el jugador notaba los efectos sin saber nunca
	## el número. Van aquí, que es donde vive la gente que llena esto.
	if p.mundo.prensa != null:
		var animo := p.mundo.prensa.animo
		var col_animo := p.COL_VERDE if animo >= 70 else (p.COL_ROJO if animo <= 35 else p.COL_ORO)
		p._dato("Ánimo de la hinchada", "%d / 100" % animo, col_animo, p._lista_estadio)
		var funa := p.mundo.prensa.funa
		if funa > 0:
			p._dato("Presión en redes (funa)", "%d / 100" % funa,
				p.COL_ROJO if funa > 55 else p.COL_SUAVE, p._lista_estadio)
		var lectura := p._texto(11, p.COL_SUAVE)
		if animo >= 82:
			lectura.text = Idiomas.t("El estadio empuja: a este nivel salen banderazos antes de los partidos.")
		elif animo <= 22:
			lectura.text = Idiomas.t("Ambiente enrarecido: a este nivel aparecen lienzos en contra.")
		else:
			lectura.text = Idiomas.t("La gente responde a los resultados. Ganar en casa y no subir la entrada es lo que más lo mueve.")
		lectura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_estadio.add_child(lectura)
	p._dato("Socios", p._miles(c.socios), p.COL_TEXTO, p._lista_estadio)
	p._ui_club_vida._pintar_hinchada(c)
	p._lista_estadio.add_child(HSeparator.new())
	var sub := p._texto(12, p.COL_SUAVE)
	sub.text = Idiomas.t("%s de %d bandeja%s  ·  techo %s  ·  %s butacas  ·  ambiente %d") % [
		String(perf.get("forma", "?")).capitalize(), int(perf.get("niveles", 1)),
		"" if int(perf.get("niveles", 1)) == 1 else "s", String(perf.get("techo", "?")),
		p._miles(int(perf.get("aforo", 0))), e.ambiente()]
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_estadio.add_child(sub)
	var nota := p._texto(11, p.COL_SUAVE)
	nota.text = Idiomas.t("Las bandejas y el aforo se amplían construyendo tribunas en Club → Obras. Aquí se decide cómo SE VE.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_estadio.add_child(nota)
	p._lista_estadio.add_child(HSeparator.new())

	## LOS DIECISIETE CAMPOS, no seis. `EstadioPropio.CATALOGO_DE` los tiene todos
	## desde el porte -forma, techo, césped, tono, líneas, arcos, redes, córner,
	## banquillos, túnel, dónde va el escudo, clima, banderas, focos, pantallas y
	## hasta el sonido del gol- y la pantalla solo exponía seis. Todo lo demás
	## estaba escrito, probado, con su coste calculado, y era inalcanzable.
	##
	## Se agrupan por bloques porque diecisiete desplegables seguidos son una
	## lista de la compra: así se lee como lo que es, un estadio por partes.
	for bloque: Array in [
			["LA ESTRUCTURA", ["forma", "fachada", "fachadaCol", "techo", "techoCol", "focos", "luzFocos", "focosCol", "pantalla"]],
			["EL CAMPO", ["superficie", "cesped", "cespedTono", "lineaCol", "arcoCol", "redCol", "redTipo"]],
			["LA GRADA", ["asientoP", "asientoNivel", "banderas", "escudoDonde", "corner"]],
			## Sin "clima" (26-9-2026): el tiempo lo pone la ciudad, no el
			## diseñador. Elegir "lluvia" como se elige un color era ilógico.
			["LOS DETALLES", ["banquillo", "banquilloCol", "vallaCol", "ledPaleta", "ledFondo", "ledTinta", "tunel", "sonidoGol"]],
		]:
		var tb := p._texto(11, p.COL_ACENTO)
		tb.text = String(bloque[0])
		p._lista_estadio.add_child(tb)
		for campo: String in (bloque[1] as Array):
			_fila_diseno_estadio(e, perf, campo)

	## LAS TRIBUNAS, cada una con su propio estilo (16-9-2026, Fase 1 de "el
	## estadio por MÓDULOS" del ROADMAP). Con el interruptor apagado -el caso de
	## siempre- esto no pinta nada más que el aviso: activar es el paso que dice
	## "quiero decidir esto tribuna por tribuna" y por eso cuesta.
	p._lista_estadio.add_child(HSeparator.new())
	var tt := p._texto(11, p.COL_ACENTO)
	tt.text = Idiomas.t("LAS TRIBUNAS")
	p._lista_estadio.add_child(tt)
	_fila_interruptor_estadio(e.ajustes, "personalizar_bandejas", "Personalizar cada tribuna",
		"Cada una de las 4 tribunas con su propio patrón, colores de butaca y techo, en vez de un solo estilo para todo el recinto.")
	if bool(e.ajustes.get("personalizar_bandejas", false)):
		var fila_lado := HBoxContainer.new()
		fila_lado.add_theme_constant_override("separation", 6)
		p._lista_estadio.add_child(fila_lado)
		var l_lado := p._texto(11, p.COL_SUAVE)
		l_lado.text = Idiomas.t("Tribuna")
		l_lado.custom_minimum_size = Vector2(130, 0)
		fila_lado.add_child(l_lado)
		var sel_lado := OptionButton.new()
		sel_lado.add_theme_font_size_override("font_size", 11)
		sel_lado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var etiquetas_lado := {"sur": "Sur", "norte": "Norte", "este": "Este", "oeste": "Oeste"}
		for i in EstadioPropio.LADOS_BANDEJA.size():
			var lado: String = EstadioPropio.LADOS_BANDEJA[i]
			sel_lado.add_item(String(etiquetas_lado.get(lado, lado.capitalize())))
			sel_lado.set_item_metadata(i, lado)
			if lado == _bandeja_actual:
				sel_lado.select(i)
		sel_lado.item_selected.connect(func(idx: int) -> void:
			_bandeja_actual = String(sel_lado.get_item_metadata(idx))
			_pintar_estadio(c))
		fila_lado.add_child(sel_lado)
		_fila_diseno_estadio(e, perf, "bandeja_%s_asientoP" % _bandeja_actual)
		_fila_diseno_estadio(e, perf, "bandeja_%s_techo" % _bandeja_actual)
		_fila_diseno_estadio(e, perf, "bandeja_%s_col1" % _bandeja_actual)
		_fila_diseno_estadio(e, perf, "bandeja_%s_col2" % _bandeja_actual)
		## Cada anillo de esta tribuna, por separado (28-9-2026).
		for n_an in mini(5, maxi(1, int(perf.get("niveles", 1)))):
			_fila_diseno_estadio(e, perf, "anillo_%s_%d" % [_bandeja_actual, n_an + 1])

	## LOS TERCIOS: estilos mixtos DENTRO de una misma tribuna (18/22-9-2026,
	## Fase 3 de "el estadio por MÓDULOS", la última de las tres). El spike del
	## 18-9 confirmó que el corte se sostiene visualmente -ver LEEME.md del historial de git-, esta
	## es la pantalla real. Interruptor PROPIO, independiente del de arriba: se
	## puede mezclar por tercios una tribuna sin haber activado "Personalizar
	## cada tribuna" en ninguna, y viceversa. Reusa el mismo selector
	## `_bandeja_actual` que el bloque de arriba -es la misma pregunta ("¿qué
	## tribuna estoy mirando?") para las dos reformas, no hace falta un
	## segundo estado que se pueda desincronizar del primero.
	_fila_interruptor_estadio(e.ajustes, "personalizar_tramos", "Mezclar patrones por tercios",
		"Cada tribuna se puede partir en 3 tercios con su propio patrón de butaca, en vez de uno solo de punta a punta.")
	if bool(e.ajustes.get("personalizar_tramos", false)):
		var fila_lado_t := HBoxContainer.new()
		fila_lado_t.add_theme_constant_override("separation", 6)
		p._lista_estadio.add_child(fila_lado_t)
		var l_lado_t := p._texto(11, p.COL_SUAVE)
		l_lado_t.text = Idiomas.t("Tribuna")
		l_lado_t.custom_minimum_size = Vector2(130, 0)
		fila_lado_t.add_child(l_lado_t)
		var sel_lado_t := OptionButton.new()
		sel_lado_t.add_theme_font_size_override("font_size", 11)
		sel_lado_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var etiquetas_lado_t := {"sur": "Sur", "norte": "Norte", "este": "Este", "oeste": "Oeste"}
		for i in EstadioPropio.LADOS_BANDEJA.size():
			var lado_t: String = EstadioPropio.LADOS_BANDEJA[i]
			sel_lado_t.add_item(String(etiquetas_lado_t.get(lado_t, lado_t.capitalize())))
			sel_lado_t.set_item_metadata(i, lado_t)
			if lado_t == _bandeja_actual:
				sel_lado_t.select(i)
		sel_lado_t.item_selected.connect(func(idx: int) -> void:
			_bandeja_actual = String(sel_lado_t.get_item_metadata(idx))
			_pintar_estadio(c))
		fila_lado_t.add_child(sel_lado_t)
		for tercio in [1, 2, 3]:
			_fila_diseno_estadio(e, perf, "tramo_%s_%d" % [_bandeja_actual, tercio])

	## Los dos interruptores. No son desplegables y por eso se quedaron fuera
	## del catálogo: la pista de atletismo aleja la grada del campo y le quita
	## ambiente, y las vallas perimetrales son la diferencia entre un recinto de
	## los ochenta y uno moderno. Ambos estaban implementados y sin manera de
	## tocarlos.
	p._lista_estadio.add_child(HSeparator.new())
	var ti := p._texto(11, p.COL_ACENTO)
	ti.text = Idiomas.t("EL RECINTO")
	p._lista_estadio.add_child(ti)
	_fila_interruptor_estadio(e.ajustes, "pista", "Pista de atletismo",
		"Aleja la grada del campo: -3,5 de ambiente.")
	_fila_interruptor_estadio(e.ajustes, "vallas", "Vallas perimetrales",
		"Separan a la hinchada del césped. Estética de otra época.")
