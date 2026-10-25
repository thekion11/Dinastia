extends "res://ui/principal_p4.gd"
## [Capa 5/17 de `principal.gd`] _ver_estadio_propio, _ver_estadio_con_carga, _dato, _miles, _pintar_estadio

func _ver_estadio_propio() -> void:
	_fundido_entrada()
	var c := mundo.mi_club()
	if c == null:
		return
	var f := Finanzas.new(c)
	var gente := float(f.asistencia()) / float(maxi(c.estadio_aforo, 1))
	## VistaEstadio pinta el 3D DIRECTO en el viewport raíz y a propósito no
	## trae ningún fondo opaco -es lo que deja ver el estadio de verdad, ver
	## el comentario en `estadio.gd::_construir()`-, pero eso significa que
	## cualquier Control que siga encima -la barra superior, las pestañas,
	## esta misma lista de Estadio- lo tapa entero: en un mismo viewport los
	## Control se pintan SIEMPRE sobre el 3D, sin importar el orden en que se
	## añadieron los nodos. `partido_vivo._ver_estadio()` no tiene este
	## problema porque su propia pantalla ya deja hueco de sobra; esta sí
	## está cubierta de paneles, así que hay que esconderlos a mano mientras
	## el visor está abierto y devolverlos tal cual al volver -guardando
	## cuáles estaban visibles, no asumiendo que todos lo estaban-.
	var ocultados: Array = []
	for h in get_children():
		if h is CanvasItem and (h as CanvasItem).visible:
			(h as CanvasItem).visible = false
			ocultados.append(h)
	var vista := VistaEstadio.new()
	## Sin partido la pantalla gigante enseña bienvenida + tabla + goleadores,
	## que es lo que hace un estadio de verdad un día entre semana. Va antes de
	## `abrir()`, que es donde se monta.
	vista.datos_pantalla = _datos_pantalla_estadio(c)
	add_child(vista)
	vista.abrir(c, clampf(gente, 0.05, 1.0), null, null, mundo.perfil_estadio_de(c),
		Comercial.color_balon(mundo.comercial.balon, c))
	vista.cerrado.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as CanvasItem).visible = true)

## Con pantalla de carga y consejos: se pinta ANTES de empezar a construir.
func _ver_estadio_con_carga() -> void:
	PantallaCarga.club = mundo.mi_club() if mundo != null else null
	var carga := PantallaCarga.mostrar(self, Idiomas.t("Levantando el estadio…"))
	await get_tree().process_frame
	await get_tree().process_frame
	_ver_estadio_propio()
	## Si algo la cerró mientras se esperaba (otra pantalla encima, o el
	## recorrido de pantallas), llamarla aquí tumbaba el juego (señal 11).
	if is_instance_valid(carga):
		carga.cerrar()

## `padre` por defecto es `_ficha` -de ahí salió esta función, para la ficha
## del jugador-, pero cualquier otra pestaña con la misma "etiqueta … valor"
## puede pasar la suya. Pasarlo mal es un bug silencioso: sin error, la fila
## sale dibujada en el sitio equivocado y desaparece en el próximo repintado.
## Una fila "etiqueta ......... valor".
##
## La etiqueta se RECORTA si no cabe, y esa línea no es cosmética: sin ella un
## Label pide de ancho mínimo lo que mida su texto, ese mínimo sube por el
## HBoxContainer de columnas, y la tercera columna se sale de la ventana entera
## -el contrato y el sueldo del jugador salían cortados por el borde derecho-.
## El valor NO se recorta a propósito: es el dato, y un dato a medias engaña
## más que un dato que no cabe.
func _dato(etiqueta: String, valor: String, color: Color, padre: Node = null) -> void:
	var h := HBoxContainer.new()
	var a := _texto(12, COL_SUAVE)
	a.text = etiqueta
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.clip_text = true
	a.tooltip_text = etiqueta
	h.add_child(a)
	var b := _texto(12, color)
	b.text = valor
	h.add_child(b)
	(padre if padre != null else _ficha).add_child(h)

func _miles(n: int) -> String:
	var s := str(n)
	var salida := ""
	var cuenta := 0
	for i in range(s.length() - 1, -1, -1):
		salida = s[i] + salida
		cuenta += 1
		if cuenta % 3 == 0 and i > 0:
			salida = "." + salida
	return salida

func _pintar_estadio(c: Club) -> void:
	_limpiar(_lista_estadio)
	var e := mundo.estadio
	var p := mundo.perfil_estadio_de(c)
	var t := _texto(13, COL_ORO)
	t.text = c.estadio_nombre if c.estadio_nombre != "" else e.nombre_de(c)
	_lista_estadio.add_child(t)
	## Reforma en obras: el diseñador enseña el PROYECTO; el estadio que se ve y
	## se juega sigue siendo el de antes hasta que termine.
	if e.en_obras():
		var ob := _texto(12, Color(1.0, 0.8, 0.3))
		ob.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ob.text = Idiomas.t("🏗️ Reforma en obras: faltan %d de %d semanas. Aquí ves el proyecto; en la ciudad y en los partidos sigue el estadio de siempre, con andamios.") % [
			int(e.obra["semanas"]), int(e.obra["total"])]
		_lista_estadio.add_child(ob)
	## PONERLE NOMBRE AL ESTADIO, de `vEstadio()`. Es lo más barato que puede
	## hacer un club por su identidad y lo primero que hace cualquiera al llegar
	## a uno nuevo. Vacío vuelve al nombre por defecto: no se puede quedar sin.
	var fila_n := HBoxContainer.new()
	fila_n.add_theme_constant_override("separation", 6)
	_lista_estadio.add_child(fila_n)
	var campo_nombre := LineEdit.new()
	campo_nombre.placeholder_text = Idiomas.t("Ponle nombre al estadio…")
	campo_nombre.text = c.estadio_nombre
	campo_nombre.add_theme_font_size_override("font_size", 11)
	campo_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo_nombre.text_submitted.connect(func(v: String) -> void:
		c.estadio_nombre = v.strip_edges()
		(self as Principal)._refrescar())
	fila_n.add_child(campo_nombre)
	var bn := Button.new()
	bn.text = Idiomas.t("Guardar")
	bn.add_theme_font_size_override("font_size", 11)
	bn.pressed.connect(func() -> void:
		c.estadio_nombre = campo_nombre.text.strip_edges()
		(self as Principal)._refrescar())
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
	ver3d.pressed.connect(_ver_estadio_con_carga)
	fila_n.add_child(ver3d)
	_ui_club_estadio._pintar_estilos_estadio(c)
	## LA HINCHADA. `Prensa.animo` y `Prensa.funa` se mueven solos desde hace
	## tiempo -banderazos si el ánimo pasa de 82, lienzos si baja de 22- y no se
	## veían en ninguna pantalla: el jugador notaba los efectos sin saber nunca
	## el número. Van aquí, que es donde vive la gente que llena esto.
	if mundo.prensa != null:
		var animo := mundo.prensa.animo
		var col_animo := COL_VERDE if animo >= 70 else (COL_ROJO if animo <= 35 else COL_ORO)
		_dato("Ánimo de la hinchada", "%d / 100" % animo, col_animo, _lista_estadio)
		var funa := mundo.prensa.funa
		if funa > 0:
			_dato("Presión en redes (funa)", "%d / 100" % funa,
				COL_ROJO if funa > 55 else COL_SUAVE, _lista_estadio)
		var lectura := _texto(11, COL_SUAVE)
		if animo >= 82:
			lectura.text = Idiomas.t("El estadio empuja: a este nivel salen banderazos antes de los partidos.")
		elif animo <= 22:
			lectura.text = Idiomas.t("Ambiente enrarecido: a este nivel aparecen lienzos en contra.")
		else:
			lectura.text = Idiomas.t("La gente responde a los resultados. Ganar en casa y no subir la entrada es lo que más lo mueve.")
		lectura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_estadio.add_child(lectura)
	_dato("Socios", _miles(c.socios), COL_TEXTO, _lista_estadio)
	_ui_club_vida._pintar_hinchada(c)
	_lista_estadio.add_child(HSeparator.new())
	var sub := _texto(12, COL_SUAVE)
	sub.text = Idiomas.t("%s de %d bandeja%s  ·  techo %s  ·  %s butacas  ·  ambiente %d") % [
		String(p.get("forma", "?")).capitalize(), int(p.get("niveles", 1)),
		"" if int(p.get("niveles", 1)) == 1 else "s", String(p.get("techo", "?")),
		_miles(int(p.get("aforo", 0))), e.ambiente()]
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_estadio.add_child(sub)
	var nota := _texto(11, COL_SUAVE)
	nota.text = Idiomas.t("Las bandejas y el aforo se amplían construyendo tribunas en Club → Obras. Aquí se decide cómo SE VE.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_estadio.add_child(nota)
	_lista_estadio.add_child(HSeparator.new())

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
			["LA GRADA", ["asientoP", "banderas", "escudoDonde", "corner"]],
			## Sin "clima" (26-9-2026): el tiempo lo pone la ciudad, no el
			## diseñador. Elegir "lluvia" como se elige un color era ilógico.
			["LOS DETALLES", ["banquillo", "banquilloCol", "vallaCol", "ledPaleta", "ledFondo", "ledTinta", "tunel", "sonidoGol"]],
		]:
		var tb := _texto(11, COL_ACENTO)
		tb.text = String(bloque[0])
		_lista_estadio.add_child(tb)
		for campo: String in (bloque[1] as Array):
			_ui_club_estadio._fila_diseno_estadio(e, p, campo)

	## LAS TRIBUNAS, cada una con su propio estilo (16-9-2026, Fase 1 de "el
	## estadio por MÓDULOS" del ROADMAP). Con el interruptor apagado -el caso de
	## siempre- esto no pinta nada más que el aviso: activar es el paso que dice
	## "quiero decidir esto tribuna por tribuna" y por eso cuesta.
	_lista_estadio.add_child(HSeparator.new())
	var tt := _texto(11, COL_ACENTO)
	tt.text = Idiomas.t("LAS TRIBUNAS")
	_lista_estadio.add_child(tt)
	_ui_club_estadio._fila_interruptor_estadio(e.ajustes, "personalizar_bandejas", "Personalizar cada tribuna",
		"Cada una de las 4 tribunas con su propio patrón, colores de butaca y techo, en vez de un solo estilo para todo el recinto.")
	if bool(e.ajustes.get("personalizar_bandejas", false)):
		var fila_lado := HBoxContainer.new()
		fila_lado.add_theme_constant_override("separation", 6)
		_lista_estadio.add_child(fila_lado)
		var l_lado := _texto(11, COL_SUAVE)
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
		_ui_club_estadio._fila_diseno_estadio(e, p, "bandeja_%s_asientoP" % _bandeja_actual)
		_ui_club_estadio._fila_diseno_estadio(e, p, "bandeja_%s_techo" % _bandeja_actual)
		_ui_club_estadio._fila_diseno_estadio(e, p, "bandeja_%s_col1" % _bandeja_actual)
		_ui_club_estadio._fila_diseno_estadio(e, p, "bandeja_%s_col2" % _bandeja_actual)
		## Cada anillo de esta tribuna, por separado (28-9-2026).
		for n_an in mini(5, maxi(1, int(p.get("niveles", 1)))):
			_ui_club_estadio._fila_diseno_estadio(e, p, "anillo_%s_%d" % [_bandeja_actual, n_an + 1])

	## LOS TERCIOS: estilos mixtos DENTRO de una misma tribuna (18/22-9-2026,
	## Fase 3 de "el estadio por MÓDULOS", la última de las tres). El spike del
	## 18-9 confirmó que el corte se sostiene visualmente -ver LEEME.md-, esta
	## es la pantalla real. Interruptor PROPIO, independiente del de arriba: se
	## puede mezclar por tercios una tribuna sin haber activado "Personalizar
	## cada tribuna" en ninguna, y viceversa. Reusa el mismo selector
	## `_bandeja_actual` que el bloque de arriba -es la misma pregunta ("¿qué
	## tribuna estoy mirando?") para las dos reformas, no hace falta un
	## segundo estado que se pueda desincronizar del primero.
	_ui_club_estadio._fila_interruptor_estadio(e.ajustes, "personalizar_tramos", "Mezclar patrones por tercios",
		"Cada tribuna se puede partir en 3 tercios con su propio patrón de butaca, en vez de uno solo de punta a punta.")
	if bool(e.ajustes.get("personalizar_tramos", false)):
		var fila_lado_t := HBoxContainer.new()
		fila_lado_t.add_theme_constant_override("separation", 6)
		_lista_estadio.add_child(fila_lado_t)
		var l_lado_t := _texto(11, COL_SUAVE)
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
			_ui_club_estadio._fila_diseno_estadio(e, p, "tramo_%s_%d" % [_bandeja_actual, tercio])

	## Los dos interruptores. No son desplegables y por eso se quedaron fuera
	## del catálogo: la pista de atletismo aleja la grada del campo y le quita
	## ambiente, y las vallas perimetrales son la diferencia entre un recinto de
	## los ochenta y uno moderno. Ambos estaban implementados y sin manera de
	## tocarlos.
	_lista_estadio.add_child(HSeparator.new())
	var ti := _texto(11, COL_ACENTO)
	ti.text = Idiomas.t("EL RECINTO")
	_lista_estadio.add_child(ti)
	_ui_club_estadio._fila_interruptor_estadio(e.ajustes, "pista", "Pista de atletismo",
		"Aleja la grada del campo: -3,5 de ambiente.")
	_ui_club_estadio._fila_interruptor_estadio(e.ajustes, "vallas", "Vallas perimetrales",
		"Separan a la hinchada del césped. Estética de otra época.")
