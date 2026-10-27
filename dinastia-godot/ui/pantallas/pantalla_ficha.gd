class_name PantallaFicha
extends "res://ui/pantallas/pantalla_ficha_p1.gd"
## [Capa 2/2 de `pantalla_ficha.gd`] _club_staff, _pintar_club

## EL PERSONAL CONTRATADO: cuerpo técnico, red de ojeadores, analítica y
## academias. Todo lo que se paga en nómina y no juega.
func _club_staff(c: Club) -> void:
	var t2 := p._texto(11, Principal.COL_SUAVE)
	t2.text = Idiomas.t("CUERPO TÉCNICO  ·  nómina %s/semana") % p._dinero(p.mundo.staff.sueldo_semanal(c.rep))
	p._lista_club.add_child(t2)
	## C9: la jornada legal del personal del país, con su norma.
	var jl := p._texto(11, Principal.COL_SUAVE)
	var fe := Contratos.factor_estructura(c.pais, p.mundo.anio, p.mundo.semana)
	jl.text = Idiomas.t("⚖️ Jornada legal del personal: %s%s") % [Contratos.texto_jornada(c.pais, p.mundo.anio, p.mundo.semana),
		"" if is_equal_approx(fe, 1.0) else Idiomas.t("  (la estructura cuesta un %+d%%)") % int(round((fe - 1.0) * 100.0))]
	jl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_club.add_child(jl)
	## El bono de productividad: una vez por temporada, sube la moral de TODO el
	## plantel, y sube más cuanto mejor vayas. Premiar a la gente yendo primero
	## es una fiesta; hacerlo yendo último se agradece y poco más.
	if p.mundo.staff.escalones_contratados() > 0:
		var fila_bono := HBoxContainer.new()
		fila_bono.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila_bono)
		var ya := p.mundo.staff.anio_bono == p.mundo.anio
		var lb := p._texto(12, Principal.COL_SUAVE)
		lb.text = Idiomas.t("Bono de productividad") if not ya else Idiomas.t("Bono de productividad  ·  ya repartido este año")
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_bono.add_child(lb)
		var coste_bono := p.mundo.staff.coste_bono(c.rep)
		var bb := Button.new()
		bb.text = Idiomas.t("Repartir  %s") % p._dinero(coste_bono)
		bb.add_theme_font_size_override("font_size", 11)
		bb.disabled = ya or coste_bono > c.saldo
		bb.pressed.connect(func() -> void: p._ui_club_vida._bono_staff(c))
		fila_bono.add_child(bb)
	for puesto: String in Staff.PUESTOS:
		var datos: Array = Staff.PUESTOS[puesto]
		var n := p.mundo.staff.nivel(puesto)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila)
		var nom := p._texto(12, Principal.COL_TEXTO)
		## Las estrellas se leen de un vistazo; "nivel 3 de 5" hay que pararse a
		## leerlo.
		nom.text = "%s  %s" % ["★".repeat(n) + "·".repeat(Staff.NIVEL_MAX - n), datos[0]]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		if n >= Staff.NIVEL_MAX:
			var tope := p._texto(11, Principal.COL_VERDE); tope.text = Idiomas.t("al máximo")
			fila.add_child(tope)
		else:
			var coste := p.mundo.staff.coste_subir(puesto, c.rep)
			var b := Button.new()
			b.text = Idiomas.t("Contratar  %s") % p._dinero(coste)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = coste > c.saldo or (p.mundo.roles != null and not p.mundo.roles.puede_contratar_staff())
			b.pressed.connect(func() -> void: _contratar(puesto))
			fila.add_child(b)
		var que := p._texto(11, Principal.COL_SUAVE)
		que.text = "    " + String(datos[1])
		que.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(que)
	_pintar_ojeadores(c)
	_pintar_analitica(c)
	_pintar_academias(c)

func _pintar_club(c: Club) -> void:
	p._limpiar(p._lista_club)
	match p._secc_club:
		"directorio": _club_directorio(c)
		"staff": _club_staff(c)
		"infra": p._club_infra(c)
		"carrera": p._club_carrera(c)
		_: _club_directorio(c)

## LA FICHA DEL JUGADOR (fase 6, paso 7; sale de `Principal`, capa 8, el 27-10-2026).
func _ver_ficha(j: Jugador) -> void:
	p.vista_cambiada.emit()
	## Una ficha pedida a mano manda sobre la que quedara diferida (`_refrescar`).
	p._pendientes.erase(p._ficha)
	## El panel de objetivos no tapa la ficha que se abre (s3, primera hora).
	if is_instance_valid(p._panel_obj):
		p._panel_obj.ceder_ficha(p._ficha)
	if j == null or (p._seleccionado != null and j.id != p._seleccionado.id):
		p._confirmar_rescision_id = ""
	p._seleccionado = j
	## La pestaña Entrenar muestra el árbol de habilidades DEL SELECCIONADO, pero
	## no pasa por aquí cuando se pulsa una fila del plantel -eso llama solo a
	## _ver_ficha(), no a _refrescar()-, así que sin esto el árbol se quedaba con
	## el jugador anterior hasta la siguiente semana.
	## Diferido (29-9-2026): solo se repinta si la pestaña está a la vista; si
	## no, al abrirla. Era 0,3-0,5 s en cada clic de la ficha.
	p._perezoso(p._lista_entren, p._ui_club_vida._pintar_entrenamiento.bind(p.mundo.mi_club()))
	for n in p._ficha.get_children():
		if n.has_meta("titulo_bloque"):
			continue
		p._ficha.remove_child(n)
		n.queue_free()
	if j == null:
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = Idiomas.t("Pulsa un jugador de la lista para ver su ficha.")
		p._ficha.add_child(vacio)
		return

	var mio := p.mundo.mi_club()
	var suyo: Club = p.mundo.clubes.get(j.club_id)
	var propio := suyo == mio

	## La ficha con su cara grande: es la pantalla donde se decide si se ficha a
	## alguien, y una cara pega el nombre a una persona.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	p._ficha.add_child(cab)
	var retrato := TextureRect.new()
	retrato.texture = Cara.textura(j, suyo.color1 if suyo else "#2b6b45",
		suyo.color2 if suyo else "#ffffff", 64)
	retrato.custom_minimum_size = Vector2(64, 64)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab.add_child(retrato)
	var nom := p._texto(19, Principal.COL_TEXTO)
	nom.text = j.nombre
	nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(nom)
	var det := p._texto(12, Principal.COL_SUAVE)
	det.text = Idiomas.t("%s · %d años · %s · %s") % [
		j.pos_e, j.edad, suyo.nombre if suyo else Idiomas.t("sin club"),
		Nombres.limpiar(String((Datos.tabla("RASGOS") as Dictionary).get(j.rasgo, [Idiomas.t("sin rasgo")])[0])) if j.rasgo != "" else Idiomas.t("sin rasgo")]
	p._ficha.add_child(det)
	var credito := Cara.credito_foto(j)
	if credito != "":
		var cr := p._texto(9, Principal.COL_SUAVE)
		cr.text = credito
		cr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._ficha.add_child(cr)

	## La proyección de un rival no se ve gratis: `vComparador()` en vistas.js
	## la esconde con un "?" salvo que sea tuyo o ya lo hayas ojeado
	## (`j.club===G.miClub||j.ojeado`), y hasta esta tanda la ficha de Godot
	## enseñaba el potencial de CUALQUIERA sin condición -el ojeo pasaba a
	## alimentar `mundo.ojeados` desde el primer día, pero nada lo leía-.
	var conoce_potencial := j.club_id == p.mundo.mi_club_id or p.mundo.ojeados.has(j.id)
	## MODO CIEGO (`cegado()` del HTML): con `Ojeadores.modo_ciego` activado y un
	## rival que no conoces, ni la grilla de atributos se enseña -se cambia por
	## el informe cualitativo de `_pintar_ficha_ciega()`, mejor/peor cualidad y
	## fiabilidad en vez de números-. Hasta esta tanda la ficha SIEMPRE pintaba
	## los atributos exactos de cualquiera, ajuste o no.
	var cegado_ficha := not propio and p.mundo.ojeadores != null and p.mundo.ojeadores.modo_ciego and not conoce_potencial
	if cegado_ficha:
		FichaJugadorInfo.pintar_ciega(p._ficha, j, p.mundo, p._ui_ficha._paleta_ficha())
	else:
		var fila_attr := HBoxContainer.new()
		fila_attr.add_theme_constant_override("separation", 8)
		p._ficha.add_child(fila_attr)
		var g := GridContainer.new()
		g.columns = 4
		g.add_theme_constant_override("h_separation", 10)
		g.add_theme_constant_override("v_separation", 3)
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_attr.add_child(g)
		## El radar: la forma del jugador de un vistazo (informe de diseño).
		var radar := RadarAtributos.new()
		var etq := PackedStringArray()
		var vals := PackedFloat32Array()
		for k: String in j.atributos:
			## Nombre traducido y, si es largo, abreviado con punto («Coloc.»): con
			## `.left(4)` salían «Colo», «Esti» o «Refl», que no se entendían.
			var nom_at := Idiomas.t(String(p.NOMBRES_ATRIBUTOS.get(k, k)))
			etq.append(nom_at if nom_at.length() <= 7 else nom_at.left(5) + ".")
			vals.append(float(j.atributos[k]))
		radar.color_texto = Principal.COL_SUAVE
		radar.poner(etq, vals, Principal.COL_VERDE)
		fila_attr.add_child(radar)
		## Los atributos, que son la razón de que un central de 90 de ritmo no
		## sea un central de 90.
		for k: String in j.atributos:
			p._celda(g, String(p.NOMBRES_ATRIBUTOS.get(k, k)), Principal.COL_SUAVE, false, 11)
			var v := int(j.atributos[k])
			p._celda(g, str(v), Principal.COL_VERDE if v >= 80 else (Principal.COL_TEXTO if v >= 65 else Principal.COL_SUAVE), true, 12)

	p._ficha.add_child(HSeparator.new())
	## La media de un rival tampoco se ve exacta salvo que lo conozcas bien
	## -ovrTxt() del HTML-: sale un rango que se cierra cuanto mejor cubierto
	## esté su país por tu red de ojeadores, o del todo si ya lo ojeaste.
	var media_txt := str(j.ovr) if propio else (p.mundo.ojeadores.ovr_texto(j) if p.mundo.ojeadores != null else str(j.ovr))
	p._dato("Media / potencial", "%s / %s" % [media_txt, str(j.pot) if conoce_potencial else "?"], Principal.COL_TEXTO)
	## CUANTO HA CRECIDO ESTA TEMPORADA. Es la unica linea de la ficha que dice
	## si tu academia y tu plan de entrenamiento sirven de algo: mirando solo la
	## media de hoy no se distingue a un chico que crece de uno que se estanco.
	if propio and j.ovr_al_empezar > 0:
		var crec := j.crecimiento_temporada()
		p._dato("Este año", "%+d de media (empezó en %d)" % [crec, j.ovr_al_empezar],
			Principal.COL_VERDE if crec > 0 else (Principal.COL_ROJO if crec < 0 else Principal.COL_SUAVE))
	p._dato("Forma", str(j.forma), Principal.COL_TEXTO)
	p._dato("Moral", str(j.moral), Principal.COL_VERDE if j.moral >= 60 else Principal.COL_ROJO)
	p._dato("Contrato", "%d año%s" % [j.anios_contrato, "" if j.anios_contrato == 1 else "s"],
		Principal.COL_ROJO if j.anios_contrato <= 1 else Principal.COL_TEXTO)
	## C9: el tipo de contrato y su límite legal (norma FIFA).
	p._dato("Régimen", Contratos.tipo(j, p.mundo.cesiones != null and p.mundo.cesiones.esta_cedido(j.id)), Principal.COL_SUAVE)
	p._dato("Valor de tasación", p._dinero(j.valor), Principal.COL_TEXTO)
	## LOS DERECHOS DE FORMACIÓN. `Cesiones.derechos_de_formacion()` se COBRA de
	## verdad en cada traspaso, pero no se veía en ninguna pantalla: podías
	## vender a un chico de veinte y llevarte un 10% menos de lo que esperabas
	## sin entender por qué. Ahora se avisa ANTES, que es cuando sirve.
	if p.mundo.cesiones != null and j.club_formacion != "" and j.club_formacion != j.club_id:
		var pct := p.mundo.cesiones.derechos_de_formacion(j, mio)
		if pct > 0.0:
			var formador: Club = p.mundo.clubes.get(j.club_formacion)
			p._dato("Derechos de formación", "%d%% para %s" % [
				int(round(pct * 100.0)), formador.nombre if formador else Idiomas.t("su club formador")],
				Principal.COL_ORO)
	p._dato("Sueldo actual", p._dinero(j.sueldo) + " / semana", Principal.COL_TEXTO)
	## El detalle de la baja -antes solo decía "lesión, N semanas" o
	## "sancionado" a secas-: `Medico.diagnostico()` ya sabe el TIPO exacto
	## (esguince, rotura...) desde que se porta el parte médico, y `j.suspension`
	## ya llevaba la cuenta de fechas sin que ninguna pantalla la mostrara.
	if j.lesion > 0:
		var tipo := p.mundo.medico.diagnostico(j) if p.mundo.medico != null else ""
		p._dato("Estado", ("%s: vuelve en %d semana(s)" % [tipo, j.lesion]) if tipo != "" else
			"lesión, %d semanas" % j.lesion, Principal.COL_ROJO)
	elif j.suspension > 0:
		p._dato("Estado", "Suspendido %d fecha(s)" % j.suspension, Principal.COL_ROJO)
	if j.adapt > 0:
		p._dato("Adaptándose a su nueva posición", "%d semana(s) rindiendo por debajo" % j.adapt, Principal.COL_ORO)
	## `Perfil` del HTML: una fila propia con el rasgo -ademas del que ya sale
	## resumido en la cabecera-. La descripcion larga (RASGOS[rasgo][1]) va en
	## la biografia de mas abajo, junto al nombre, igual que hace el HTML.
	if j.rasgo != "":
		var rdesc: Array = (Datos.tabla("RASGOS") as Dictionary).get(j.rasgo, ["sin rasgo", ""])
		p._dato("Perfil", "✦ %s" % Nombres.limpiar(String(rdesc[0])), Principal.COL_ORO)
	## `Últimas notas` del HTML: se ve siempre, propio o ajeno.
	p._dato("Últimas notas", " · ".join(PackedStringArray(j.notas.map(func(n: float) -> String: return "%.1f" % n))) if not j.notas.is_empty() else "—", Principal.COL_TEXTO)

	## El informe individual -ojearJug() del HTML-: paga y a partir de ahí ese
	## jugador se ve exacto para siempre, media y proyección incluidas.
	if not propio and p.mundo.ojeadores != null and not p.mundo.ojeados.has(j.id):
		var costo_oj := p.mundo.ojeadores.costo_informe()
		var bo := Button.new()
		bo.text = Idiomas.t("Pedir informe de ojeo  %s") % p._dinero(costo_oj)
		bo.disabled = costo_oj > p.mundo.ojeadores.presupuesto and (mio == null or costo_oj > mio.saldo)
		bo.pressed.connect(func() -> void: p._ui_ficha._pedir_informe_ojeo(j))
		p._ficha.add_child(bo)

	## compararJug(pid) del HTML: funciona igual para un jugador propio que
	## ajeno -por eso va aquí, antes de que la ficha se bifurque-.
	var en_comparador := p._comparar_ids.has(j.id)
	var bc2 := Button.new()
	bc2.text = Idiomas.t("Quitar del comparador") if en_comparador else Idiomas.t("Comparar")
	bc2.disabled = not en_comparador and p._comparar_ids.size() >= 3
	bc2.pressed.connect(func() -> void: p._ui_cantera._alternar_comparar(j))
	p._ficha.add_child(bc2)

	if propio:
		var pal := p._ui_ficha._paleta_ficha()
		FichaJugadorInfo.pintar_estadisticas(p._ficha, j, pal)
		FichaJugadorInfo.pintar_perfil_y_premios(p._ficha, j, pal)
		FichaJugadorInfo.pintar_cabeza(p._ficha, j, p.mundo, pal)
		FichaJugadorInfo.pintar_promesa(p._ficha, j, p.mundo, pal)
		FichaJugadorAcciones.pintar_desarrollo(p._ficha, j, p.mundo, func() -> void:
			var problema := p.mundo.entrenamiento.alternar_prioritario(j)
			if problema != "":
				p._escribir("[color=#e05555]%s[/color]" % problema)
			_ver_ficha(j))
		FichaJugadorInfo.pintar_habilidades(p._ficha, j, p.mundo, pal)
		FichaJugadorAcciones.pintar_reconversion(p._ficha, j, p.mundo, pal,
			func(destino: String) -> void: p._reconvertir(j, destino))
		FichaJugadorInfo.pintar_historial_medico(p._ficha, j, p.mundo, pal)
		FichaJugadorAcciones.pintar_marca(p._ficha, j, mio, p.mundo, pal, func() -> void:
			var problema := p.mundo.cantera.ofrecer_fidelidad(j, mio)
			if problema != "":
				p._escribir("[color=#e05555]%s[/color]" % problema)
			(p as Principal)._refrescar()
			_ver_ficha(j))
		FichaJugadorAcciones.pintar_charla(p._ficha, j, p.mundo, pal)
		FichaJugadorInfo.pintar_vida_personal(p._ficha, j, p.mundo, pal)
		FichaJugadorInfo.pintar_historial(p._ficha, j, pal)
		FichaJugadorAcciones.pintar_venta(p._ficha, j, mio, p.mundo, pal, p._confirmar_rescision_id,
			func() -> void:
				j.transferible = false
				p._escribir("[color=#8ea595]%s ya no está en la lista de transferibles.[/color]" % j.nombre)
				(p as Principal)._refrescar()
				_ver_ficha(j),
			func() -> void: p._listar_transferible(j),
			func() -> void: p._rescindir(j, int((p.mundo.cantera.coste_rescision(j) as Dictionary)["total"])))
		(p as Principal)._traducir_pantalla(p._ficha)
		return
	## SEGUIR A UN OBJETIVO. Va aquí arriba, junto a comparar, porque son la
	## misma clase de gesto: apuntar a alguien para volver a él más tarde.
	if p.mundo.ojeadores != null:
		var sigo := p.mundo.ojeadores.sigue(j)
		var bs := Button.new()
		bs.text = Idiomas.t("👁️ Dejar de seguir") if sigo else Idiomas.t("👁️ Seguir")
		bs.pressed.connect(func() -> void:
			p.mundo.ojeadores.alternar_seguimiento(j)
			(p as Principal)._refrescar()
			_ver_ficha(j))
		p._ficha.add_child(bs)
	var pal_ajeno := p._ui_ficha._paleta_ficha()
	FichaJugadorInfo.pintar_estadisticas(p._ficha, j, pal_ajeno)
	FichaJugadorInfo.pintar_habilidades(p._ficha, j, p.mundo, pal_ajeno)
	FichaJugadorAcciones.pintar_similares(p._ficha, j, mio, p.mundo, pal_ajeno,
		func(quien: Jugador) -> void: _ver_ficha(quien))

	## Las tres puertas del fichaje.
	p._ficha.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("PARA FICHARLO")
	p._ficha.add_child(t)
	var pedido := p.mundo.mercado.valor_pedido(j)
	var d: Dictionary = p.mundo.mercado.deseo_de_venir(j, mio)
	var ficha_pide := p.mundo.mercado.ficha_que_pide(j, mio)
	p._dato("Piden por él", p._dinero(pedido), Principal.COL_TEXTO if pedido <= mio.saldo else Principal.COL_ROJO)
	p._dato("Pide de ficha", p._dinero(ficha_pide) + " / semana", Principal.COL_TEXTO)
	p._dato("Ganas de venir", "%d%%" % int(float(d["p"]) * 100.0),
		Principal.COL_VERDE if float(d["p"]) > 0.6 else (Principal.COL_ORO if float(d["p"]) > 0.35 else Principal.COL_ROJO))
	for r: Dictionary in d["razones"]:
		var l := p._texto(11, Principal.COL_VERDE if r["bien"] else Principal.COL_ROJO)
		l.text = ("+ " if r["bien"] else "− ") + String(r["txt"])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._ficha.add_child(l)

	## Si el rol no deja fichar -ayudante, cantera- o un desafío activo lo
	## prohíbe -"solo canteranos", "un solo país" con un extranjero-, ni la
	## mesa de negociación ni el clausulazo son tuyos: son las dos puertas de
	## la MISMA decisión, y dejar una abierta habría sido un permiso a medias.
	var motivo_no := p._motivo_fichaje_bloqueado(j)
	if motivo_no == "":
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._ficha.add_child(fila)
		p._boton("Ofrecer lo que piden", func() -> void: p._intentar_fichar(j, pedido, ficha_pide), fila)
		p._boton("Ofrecer un 15% menos", func() -> void: p._intentar_fichar(j, int(pedido * 0.85), ficha_pide), fila)
		p._boton("Negociar en la mesa", func() -> void: p._ui_plantel._abrir_negociacion(j), fila)
	else:
		var no := p._texto(11, Principal.COL_SUAVE)
		no.text = motivo_no
		no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._ficha.add_child(no)

	## El clausulazo: la puerta de atrás. Ni mesa ni negociación -si tiene
	## cláusula y hay caja, se paga y es tuyo, gane o pierda el club vendedor.
	if p.mundo.cesiones != null and motivo_no == "":
		var clau := p.mundo.cesiones.clausula_de(j)
		if clau > 0:
			var coste := p.mundo.cesiones.coste_de_clausula(j)
			p._ficha.add_child(HSeparator.new())
			var tc := p._texto(11, Principal.COL_ORO)
			tc.text = Idiomas.t("TIENE CLÁUSULA DE RESCISIÓN")
			p._ficha.add_child(tc)
			p._dato("Cláusula", p._dinero(clau), Principal.COL_TEXTO)
			p._dato("Comisión del agente", p._dinero(int(coste["comision"])), Principal.COL_SUAVE)
			var total := int(coste["total"])
			var bc := Button.new()
			bc.text = Idiomas.t("Pagar la cláusula  %s") % p._dinero(total)
			bc.disabled = total > mio.saldo
			bc.pressed.connect(func() -> void: p._ui_ficha._pagar_clausula(j))
			p._ficha.add_child(bc)

	## El informe médico: `Medico.informe()` estaba completo -riesgo, lesiones
	## graves, hasta el precio escalado al valor del jugador- pero sin ningún
	## botón que lo llamara en ningún sitio del juego.
	if p.mundo.medico != null:
		var ya_tiene := not (p.mundo.medico.informe_de(j) as Dictionary).is_empty()
		p._ficha.add_child(HSeparator.new())
		if ya_tiene:
			var inf: Dictionary = p.mundo.medico.informe_de(j)
			var tm := p._texto(11, Principal.COL_SUAVE)
			tm.text = Idiomas.t("INFORME MÉDICO")
			p._ficha.add_child(tm)
			p._dato("Riesgo declarado", String(inf.get("riesgo", "?")), Principal.COL_TEXTO)
			p._dato("Lesiones graves en su historial", str(int(inf.get("graves", 0))), Principal.COL_TEXTO)
		else:
			var costo := p.mundo.medico.costo_informe(j, mio.rep)
			var bm := Button.new()
			bm.text = Idiomas.t("Pedir informe médico  %s") % p._dinero(costo)
			bm.disabled = costo > mio.saldo
			bm.pressed.connect(func() -> void: p._pedir_informe_medico(j))
			p._ficha.add_child(bm)

	## El informe de personalidad -informePersonal() del HTML-: a diferencia
	## del médico, este cuenta cómo es FUERA de la cancha -profesionalidad,
	## cómo encaja en un vestuario, qué tan fácil es convencerlo de mudarse-.
	if p.mundo.ojeadores != null:
		var ya_pers := not p.mundo.ojeadores.informe_personalidad_de(j).is_empty()
		p._ficha.add_child(HSeparator.new())
		if ya_pers:
			var infp: Dictionary = p.mundo.ojeadores.informe_personalidad_de(j)
			var tp := p._texto(11, Principal.COL_SUAVE)
			tp.text = Idiomas.t("INFORME DE PERSONALIDAD")
			p._ficha.add_child(tp)
			p._dato("Profesionalidad", "%d/100" % int(infp.get("prof", 0)), Principal.COL_TEXTO)
			p._dato("En el vestuario", String(infp.get("vestuario", "?")), Principal.COL_TEXTO)
			p._dato("Mudarse de país", String(infp.get("mudanza", "?")), Principal.COL_TEXTO)
		else:
			var costo_p := p.mundo.ojeadores.costo_informe_personalidad(mio.rep)
			var bp := Button.new()
			bp.text = Idiomas.t("Pedir informe de personalidad  %s") % p._dinero(costo_p)
			bp.disabled = costo_p > mio.saldo
			bp.pressed.connect(func() -> void:
				var problema := p.mundo.ojeadores.informe_personalidad(j, mio)
				if problema != "":
					p._escribir("[color=#e05555]%s[/color]" % problema)
				(p as Principal)._refrescar()
				_ver_ficha(j))
			p._ficha.add_child(bp)

	## `HISTORIA` del HTML: la biografía se enseña siempre, sea o no tuyo -a
	## diferencia de `perfilHumano()`, que es cosa del vestuario propio y solo
	## se ve en `_pintar_vida_personal_ficha()`.
	p._ficha.add_child(HSeparator.new())
	var bio_ajeno := p._texto(11, Principal.COL_SUAVE)
	bio_ajeno.text = FichaJugadorInfo.bio_de(j, p.mundo)
	bio_ajeno.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._ficha.add_child(bio_ajeno)
	## La ficha se rehace entera en cada clic: sin esto, lo que no pasó por
	## `Idiomas.t` se quedaba en castellano hasta el siguiente repintado general.
	(p as Principal)._traducir_pantalla(p._ficha)
