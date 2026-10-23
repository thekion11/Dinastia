extends "res://ui/principal_p7.gd"
## [Capa 8/19 de `principal.gd`] _ver_ficha, _jugador_de_la_semana

func _ver_ficha(j: Jugador) -> void:
	vista_cambiada.emit()
	if j == null or (_seleccionado != null and j.id != _seleccionado.id):
		_confirmar_rescision_id = ""
	_seleccionado = j
	## La pestaña Entrenar muestra el árbol de habilidades DEL SELECCIONADO, pero
	## no pasa por aquí cuando se pulsa una fila del plantel -eso llama solo a
	## _ver_ficha(), no a _refrescar()-, así que sin esto el árbol se quedaba con
	## el jugador anterior hasta la siguiente semana.
	## Diferido (29-9-2026): solo se repinta si la pestaña está a la vista; si
	## no, al abrirla. Era 0,3-0,5 s en cada clic de la ficha.
	_perezoso(_lista_entren, _ui_club_vida._pintar_entrenamiento.bind(mundo.mi_club()))
	for n in _ficha.get_children():
		if n.has_meta("titulo_bloque"):
			continue
		_ficha.remove_child(n)
		n.queue_free()
	if j == null:
		var vacio := _texto(12, COL_SUAVE)
		vacio.text = Idiomas.t("Pulsa un jugador de la lista para ver su ficha.")
		_ficha.add_child(vacio)
		return

	var mio := mundo.mi_club()
	var suyo: Club = mundo.clubes.get(j.club_id)
	var propio := suyo == mio

	## La ficha con su cara grande: es la pantalla donde se decide si se ficha a
	## alguien, y una cara pega el nombre a una persona.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	_ficha.add_child(cab)
	var retrato := TextureRect.new()
	retrato.texture = Cara.textura(j, suyo.color1 if suyo else "#2b6b45",
		suyo.color2 if suyo else "#ffffff", 64)
	retrato.custom_minimum_size = Vector2(64, 64)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab.add_child(retrato)
	var nom := _texto(19, COL_TEXTO)
	nom.text = j.nombre
	nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(nom)
	var det := _texto(12, COL_SUAVE)
	det.text = Idiomas.t("%s · %d años · %s · %s") % [
		j.pos_e, j.edad, suyo.nombre if suyo else Idiomas.t("sin club"),
		Nombres.limpiar(String((Datos.tabla("RASGOS") as Dictionary).get(j.rasgo, [Idiomas.t("sin rasgo")])[0])) if j.rasgo != "" else Idiomas.t("sin rasgo")]
	_ficha.add_child(det)
	var credito := Cara.credito_foto(j)
	if credito != "":
		var cr := _texto(9, COL_SUAVE)
		cr.text = credito
		cr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ficha.add_child(cr)

	## La proyección de un rival no se ve gratis: `vComparador()` en vistas.js
	## la esconde con un "?" salvo que sea tuyo o ya lo hayas ojeado
	## (`j.club===G.miClub||j.ojeado`), y hasta esta tanda la ficha de Godot
	## enseñaba el potencial de CUALQUIERA sin condición -el ojeo pasaba a
	## alimentar `mundo.ojeados` desde el primer día, pero nada lo leía-.
	var conoce_potencial := j.club_id == mundo.mi_club_id or mundo.ojeados.has(j.id)
	## MODO CIEGO (`cegado()` del HTML): con `Ojeadores.modo_ciego` activado y un
	## rival que no conoces, ni la grilla de atributos se enseña -se cambia por
	## el informe cualitativo de `_pintar_ficha_ciega()`, mejor/peor cualidad y
	## fiabilidad en vez de números-. Hasta esta tanda la ficha SIEMPRE pintaba
	## los atributos exactos de cualquiera, ajuste o no.
	var cegado_ficha := not propio and mundo.ojeadores != null and mundo.ojeadores.modo_ciego and not conoce_potencial
	if cegado_ficha:
		FichaJugadorInfo.pintar_ciega(_ficha, j, mundo, _ui_ficha._paleta_ficha())
	else:
		var fila_attr := HBoxContainer.new()
		fila_attr.add_theme_constant_override("separation", 8)
		_ficha.add_child(fila_attr)
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
			etq.append(String(NOMBRES_ATRIBUTOS.get(k, k)).left(4))
			vals.append(float(j.atributos[k]))
		radar.color_texto = COL_SUAVE
		radar.poner(etq, vals, COL_VERDE)
		fila_attr.add_child(radar)
		## Los atributos, que son la razón de que un central de 90 de ritmo no
		## sea un central de 90.
		for k: String in j.atributos:
			_celda(g, String(NOMBRES_ATRIBUTOS.get(k, k)), COL_SUAVE, false, 11)
			var v := int(j.atributos[k])
			_celda(g, str(v), COL_VERDE if v >= 80 else (COL_TEXTO if v >= 65 else COL_SUAVE), true, 12)

	_ficha.add_child(HSeparator.new())
	## La media de un rival tampoco se ve exacta salvo que lo conozcas bien
	## -ovrTxt() del HTML-: sale un rango que se cierra cuanto mejor cubierto
	## esté su país por tu red de ojeadores, o del todo si ya lo ojeaste.
	var media_txt := str(j.ovr) if propio else (mundo.ojeadores.ovr_texto(j) if mundo.ojeadores != null else str(j.ovr))
	_dato("Media / potencial", "%s / %s" % [media_txt, str(j.pot) if conoce_potencial else "?"], COL_TEXTO)
	## CUANTO HA CRECIDO ESTA TEMPORADA. Es la unica linea de la ficha que dice
	## si tu academia y tu plan de entrenamiento sirven de algo: mirando solo la
	## media de hoy no se distingue a un chico que crece de uno que se estanco.
	if propio and j.ovr_al_empezar > 0:
		var crec := j.crecimiento_temporada()
		_dato("Este año", "%+d de media (empezó en %d)" % [crec, j.ovr_al_empezar],
			COL_VERDE if crec > 0 else (COL_ROJO if crec < 0 else COL_SUAVE))
	_dato("Forma", str(j.forma), COL_TEXTO)
	_dato("Moral", str(j.moral), COL_VERDE if j.moral >= 60 else COL_ROJO)
	_dato("Contrato", "%d año%s" % [j.anios_contrato, "" if j.anios_contrato == 1 else "s"],
		COL_ROJO if j.anios_contrato <= 1 else COL_TEXTO)
	## C9: el tipo de contrato y su límite legal (norma FIFA).
	_dato("Régimen", Contratos.tipo(j, mundo.cesiones != null and mundo.cesiones.esta_cedido(j.id)), COL_SUAVE)
	_dato("Valor de tasación", _dinero(j.valor), COL_TEXTO)
	## LOS DERECHOS DE FORMACIÓN. `Cesiones.derechos_de_formacion()` se COBRA de
	## verdad en cada traspaso, pero no se veía en ninguna pantalla: podías
	## vender a un chico de veinte y llevarte un 10% menos de lo que esperabas
	## sin entender por qué. Ahora se avisa ANTES, que es cuando sirve.
	if mundo.cesiones != null and j.club_formacion != "" and j.club_formacion != j.club_id:
		var pct := mundo.cesiones.derechos_de_formacion(j, mio)
		if pct > 0.0:
			var formador: Club = mundo.clubes.get(j.club_formacion)
			_dato("Derechos de formación", "%d%% para %s" % [
				int(round(pct * 100.0)), formador.nombre if formador else Idiomas.t("su club formador")],
				COL_ORO)
	_dato("Sueldo actual", _dinero(j.sueldo) + " / semana", COL_TEXTO)
	## El detalle de la baja -antes solo decía "lesión, N semanas" o
	## "sancionado" a secas-: `Medico.diagnostico()` ya sabe el TIPO exacto
	## (esguince, rotura...) desde que se porta el parte médico, y `j.suspension`
	## ya llevaba la cuenta de fechas sin que ninguna pantalla la mostrara.
	if j.lesion > 0:
		var tipo := mundo.medico.diagnostico(j) if mundo.medico != null else ""
		_dato("Estado", ("%s: vuelve en %d semana(s)" % [tipo, j.lesion]) if tipo != "" else
			"lesión, %d semanas" % j.lesion, COL_ROJO)
	elif j.suspension > 0:
		_dato("Estado", "Suspendido %d fecha(s)" % j.suspension, COL_ROJO)
	if j.adapt > 0:
		_dato("Adaptándose a su nueva posición", "%d semana(s) rindiendo por debajo" % j.adapt, COL_ORO)
	## `Perfil` del HTML: una fila propia con el rasgo -ademas del que ya sale
	## resumido en la cabecera-. La descripcion larga (RASGOS[rasgo][1]) va en
	## la biografia de mas abajo, junto al nombre, igual que hace el HTML.
	if j.rasgo != "":
		var rdesc: Array = (Datos.tabla("RASGOS") as Dictionary).get(j.rasgo, ["sin rasgo", ""])
		_dato("Perfil", "✦ %s" % Nombres.limpiar(String(rdesc[0])), COL_ORO)
	## `Últimas notas` del HTML: se ve siempre, propio o ajeno.
	_dato("Últimas notas", " · ".join(PackedStringArray(j.notas.map(func(n: float) -> String: return "%.1f" % n))) if not j.notas.is_empty() else "—", COL_TEXTO)

	## El informe individual -ojearJug() del HTML-: paga y a partir de ahí ese
	## jugador se ve exacto para siempre, media y proyección incluidas.
	if not propio and mundo.ojeadores != null and not mundo.ojeados.has(j.id):
		var costo_oj := mundo.ojeadores.costo_informe()
		var bo := Button.new()
		bo.text = Idiomas.t("Pedir informe de ojeo  %s") % _dinero(costo_oj)
		bo.disabled = costo_oj > mundo.ojeadores.presupuesto and (mio == null or costo_oj > mio.saldo)
		bo.pressed.connect(func() -> void: _ui_ficha._pedir_informe_ojeo(j))
		_ficha.add_child(bo)

	## compararJug(pid) del HTML: funciona igual para un jugador propio que
	## ajeno -por eso va aquí, antes de que la ficha se bifurque-.
	var en_comparador := _comparar_ids.has(j.id)
	var bc2 := Button.new()
	bc2.text = Idiomas.t("Quitar del comparador") if en_comparador else Idiomas.t("Comparar")
	bc2.disabled = not en_comparador and _comparar_ids.size() >= 3
	bc2.pressed.connect(func() -> void: _ui_cantera._alternar_comparar(j))
	_ficha.add_child(bc2)

	if propio:
		var pal := _ui_ficha._paleta_ficha()
		FichaJugadorInfo.pintar_estadisticas(_ficha, j, pal)
		FichaJugadorInfo.pintar_perfil_y_premios(_ficha, j, pal)
		FichaJugadorInfo.pintar_cabeza(_ficha, j, mundo, pal)
		FichaJugadorInfo.pintar_promesa(_ficha, j, mundo, pal)
		FichaJugadorAcciones.pintar_desarrollo(_ficha, j, mundo, func() -> void:
			var problema := mundo.entrenamiento.alternar_prioritario(j)
			if problema != "":
				_escribir("[color=#e05555]%s[/color]" % problema)
			_ver_ficha(j))
		FichaJugadorInfo.pintar_habilidades(_ficha, j, mundo, pal)
		FichaJugadorAcciones.pintar_reconversion(_ficha, j, mundo, pal,
			func(destino: String) -> void: _reconvertir(j, destino))
		FichaJugadorInfo.pintar_historial_medico(_ficha, j, mundo, pal)
		FichaJugadorAcciones.pintar_marca(_ficha, j, mio, mundo, pal, func() -> void:
			var problema := mundo.cantera.ofrecer_fidelidad(j, mio)
			if problema != "":
				_escribir("[color=#e05555]%s[/color]" % problema)
			(self as Principal)._refrescar()
			_ver_ficha(j))
		FichaJugadorAcciones.pintar_charla(_ficha, j, mundo, pal)
		FichaJugadorInfo.pintar_vida_personal(_ficha, j, mundo, pal)
		FichaJugadorInfo.pintar_historial(_ficha, j, pal)
		FichaJugadorAcciones.pintar_venta(_ficha, j, mio, mundo, pal, _confirmar_rescision_id,
			func() -> void:
				j.transferible = false
				_escribir("[color=#8ea595]%s ya no está en la lista de transferibles.[/color]" % j.nombre)
				(self as Principal)._refrescar()
				_ver_ficha(j),
			func() -> void: _listar_transferible(j),
			func() -> void: _rescindir(j, int((mundo.cantera.coste_rescision(j) as Dictionary)["total"])))
		return
	## SEGUIR A UN OBJETIVO. Va aquí arriba, junto a comparar, porque son la
	## misma clase de gesto: apuntar a alguien para volver a él más tarde.
	if mundo.ojeadores != null:
		var sigo := mundo.ojeadores.sigue(j)
		var bs := Button.new()
		bs.text = Idiomas.t("👁️ Dejar de seguir") if sigo else Idiomas.t("👁️ Seguir")
		bs.pressed.connect(func() -> void:
			mundo.ojeadores.alternar_seguimiento(j)
			(self as Principal)._refrescar()
			_ver_ficha(j))
		_ficha.add_child(bs)
	var pal_ajeno := _ui_ficha._paleta_ficha()
	FichaJugadorInfo.pintar_estadisticas(_ficha, j, pal_ajeno)
	FichaJugadorInfo.pintar_habilidades(_ficha, j, mundo, pal_ajeno)
	FichaJugadorAcciones.pintar_similares(_ficha, j, mio, mundo, pal_ajeno,
		func(quien: Jugador) -> void: _ver_ficha(quien))

	## Las tres puertas del fichaje.
	_ficha.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("PARA FICHARLO")
	_ficha.add_child(t)
	var pedido := mundo.mercado.valor_pedido(j)
	var d: Dictionary = mundo.mercado.deseo_de_venir(j, mio)
	var ficha_pide := mundo.mercado.ficha_que_pide(j, mio)
	_dato("Piden por él", _dinero(pedido), COL_TEXTO if pedido <= mio.saldo else COL_ROJO)
	_dato("Pide de ficha", _dinero(ficha_pide) + " / semana", COL_TEXTO)
	_dato("Ganas de venir", "%d%%" % int(float(d["p"]) * 100.0),
		COL_VERDE if float(d["p"]) > 0.6 else (COL_ORO if float(d["p"]) > 0.35 else COL_ROJO))
	for r: Dictionary in d["razones"]:
		var l := _texto(11, COL_VERDE if r["bien"] else COL_ROJO)
		l.text = ("+ " if r["bien"] else "− ") + String(r["txt"])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ficha.add_child(l)

	## Si el rol no deja fichar -ayudante, cantera- o un desafío activo lo
	## prohíbe -"solo canteranos", "un solo país" con un extranjero-, ni la
	## mesa de negociación ni el clausulazo son tuyos: son las dos puertas de
	## la MISMA decisión, y dejar una abierta habría sido un permiso a medias.
	var motivo_no := _motivo_fichaje_bloqueado(j)
	if motivo_no == "":
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_ficha.add_child(fila)
		_boton("Ofrecer lo que piden", func() -> void: _intentar_fichar(j, pedido, ficha_pide), fila)
		_boton("Ofrecer un 15% menos", func() -> void: _intentar_fichar(j, int(pedido * 0.85), ficha_pide), fila)
		_boton("Negociar en la mesa", func() -> void: _ui_plantel._abrir_negociacion(j), fila)
	else:
		var no := _texto(11, COL_SUAVE)
		no.text = motivo_no
		no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ficha.add_child(no)

	## El clausulazo: la puerta de atrás. Ni mesa ni negociación -si tiene
	## cláusula y hay caja, se paga y es tuyo, gane o pierda el club vendedor.
	if mundo.cesiones != null and motivo_no == "":
		var clau := mundo.cesiones.clausula_de(j)
		if clau > 0:
			var coste := mundo.cesiones.coste_de_clausula(j)
			_ficha.add_child(HSeparator.new())
			var tc := _texto(11, COL_ORO)
			tc.text = Idiomas.t("TIENE CLÁUSULA DE RESCISIÓN")
			_ficha.add_child(tc)
			_dato("Cláusula", _dinero(clau), COL_TEXTO)
			_dato("Comisión del agente", _dinero(int(coste["comision"])), COL_SUAVE)
			var total := int(coste["total"])
			var bc := Button.new()
			bc.text = Idiomas.t("Pagar la cláusula  %s") % _dinero(total)
			bc.disabled = total > mio.saldo
			bc.pressed.connect(func() -> void: _ui_ficha._pagar_clausula(j))
			_ficha.add_child(bc)

	## El informe médico: `Medico.informe()` estaba completo -riesgo, lesiones
	## graves, hasta el precio escalado al valor del jugador- pero sin ningún
	## botón que lo llamara en ningún sitio del juego.
	if mundo.medico != null:
		var ya_tiene := not (mundo.medico.informe_de(j) as Dictionary).is_empty()
		_ficha.add_child(HSeparator.new())
		if ya_tiene:
			var inf: Dictionary = mundo.medico.informe_de(j)
			var tm := _texto(11, COL_SUAVE)
			tm.text = Idiomas.t("INFORME MÉDICO")
			_ficha.add_child(tm)
			_dato("Riesgo declarado", String(inf.get("riesgo", "?")), COL_TEXTO)
			_dato("Lesiones graves en su historial", str(int(inf.get("graves", 0))), COL_TEXTO)
		else:
			var costo := mundo.medico.costo_informe(j, mio.rep)
			var bm := Button.new()
			bm.text = Idiomas.t("Pedir informe médico  %s") % _dinero(costo)
			bm.disabled = costo > mio.saldo
			bm.pressed.connect(func() -> void: _pedir_informe_medico(j))
			_ficha.add_child(bm)

	## El informe de personalidad -informePersonal() del HTML-: a diferencia
	## del médico, este cuenta cómo es FUERA de la cancha -profesionalidad,
	## cómo encaja en un vestuario, qué tan fácil es convencerlo de mudarse-.
	if mundo.ojeadores != null:
		var ya_pers := not mundo.ojeadores.informe_personalidad_de(j).is_empty()
		_ficha.add_child(HSeparator.new())
		if ya_pers:
			var infp: Dictionary = mundo.ojeadores.informe_personalidad_de(j)
			var tp := _texto(11, COL_SUAVE)
			tp.text = Idiomas.t("INFORME DE PERSONALIDAD")
			_ficha.add_child(tp)
			_dato("Profesionalidad", "%d/100" % int(infp.get("prof", 0)), COL_TEXTO)
			_dato("En el vestuario", String(infp.get("vestuario", "?")), COL_TEXTO)
			_dato("Mudarse de país", String(infp.get("mudanza", "?")), COL_TEXTO)
		else:
			var costo_p := mundo.ojeadores.costo_informe_personalidad(mio.rep)
			var bp := Button.new()
			bp.text = Idiomas.t("Pedir informe de personalidad  %s") % _dinero(costo_p)
			bp.disabled = costo_p > mio.saldo
			bp.pressed.connect(func() -> void:
				var problema := mundo.ojeadores.informe_personalidad(j, mio)
				if problema != "":
					_escribir("[color=#e05555]%s[/color]" % problema)
				(self as Principal)._refrescar()
				_ver_ficha(j))
			_ficha.add_child(bp)

	## `HISTORIA` del HTML: la biografía se enseña siempre, sea o no tuyo -a
	## diferencia de `perfilHumano()`, que es cosa del vestuario propio y solo
	## se ve en `_pintar_vida_personal_ficha()`.
	_ficha.add_child(HSeparator.new())
	var bio_ajeno := _texto(11, COL_SUAVE)
	bio_ajeno.text = FichaJugadorInfo.bio_de(j, mundo)
	bio_ajeno.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ficha.add_child(bio_ajeno)

## A quién enseña la ficha cuando no has elegido a nadie.
##
## Antes se quedaba vacía o clavada en el mismo jugador semana tras semana, y un
## plantel de veinticuatro se convertía en uno. Rotar por rotar tampoco sirve:
## lo que se enseña es a quien tiene ALGO que contar esta semana, y solo si no
## hay nadie así se pasa el turno por la plantilla.
func _jugador_de_la_semana(c: Club) -> Jugador:
	if c.plantilla.is_empty():
		return null
	## 1 · El que está roto: es lo primero que uno querría saber al abrir.
	for j in c.plantilla:
		if j.lesion > 0:
			return j
	## 2 · El que está en racha: mejor nota media de las tres últimas, y solo si
	## de verdad ha jugado.
	var mejor: Jugador = null
	var mejor_nota := 6.8
	for j in c.plantilla:
		if j.notas.size() < 3:
			continue
		var ultimas := j.notas.slice(maxi(0, j.notas.size() - 3))
		var s := 0.0
		for x in ultimas:
			s += float(x)
		var media := s / float(ultimas.size())
		if media > mejor_nota:
			mejor_nota = media
			mejor = j
	if mejor != null:
		return mejor
	## 3 · Y si no hay noticia, el turno rota con la semana: cada una le toca a
	## uno distinto, y en un año pasan todos por la ficha.
	return c.plantilla[(mundo.semana + mundo.anio) % c.plantilla.size()]
