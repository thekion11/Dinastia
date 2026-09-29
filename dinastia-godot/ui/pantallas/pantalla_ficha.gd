class_name PantallaFicha
extends RefCounted
## LA FICHA Y EL CLUB POR DENTRO: la ficha del jugador y sus acciones, el directorio, el staff, los consejeros, el embajador, los ojeadores, la analítica y las academias.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

## La ficha. Es la pantalla donde el jugador decide, así que enseña las TRES
## puertas del fichaje juntas -lo que pide su club, lo que pide él de ficha y las
## ganas que tiene de venir- y no solo el precio.
## `_paleta_ficha()`: los colores YA resueltos que reciben `FichaJugadorInfo` y
## `TablaCompeticion` -mismo criterio, misma lección del bug de coherencia
## visual del 25-9-2026 (`PanelMercado` no la tenía desde el principio y hubo
## que corregirla después).
func _paleta_ficha() -> Dictionary:
	return {
		"suave": p._pal_suave(), "texto": p._pal_texto(), "acento": p.COL_ACENTO,
		"verde": p._color_accesible(Principal.COL_VERDE), "rojo": p._color_accesible(Principal.COL_ROJO),
		"oro": p._color_accesible(Principal.COL_ORO), "escala": p._escala_texto,
	}

func _pedir_informe_ojeo(j: Jugador) -> void:
	var problema := p.mundo.ojeadores.ojear(j)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo pedir el informe: %s.[/color]" % problema)
		return
	p._escribir("[color=#c9a227]Informe recibido:[/color] %s revela su media y su potencial reales." % j.nombre)
	p._refrescar()
	p._ver_ficha(j)

func _pagar_clausula(j: Jugador) -> void:
	var r := p.mundo.cesiones.pagar_clausula(j, p.mundo.mi_club())
	if r.has("error"):
		p._escribir("[color=#e05555]No se puede: %s.[/color]" % String(r["error"]))
		return
	Sonido.toca("fichaje")
	p._escribir("[color=#4caf6d]¡Clausulazo![/color] %s es tuyo por %s más %s de comisión." % [
		j.nombre, p._dinero(int(r["clausula"])), p._dinero(int(r["comision"]))])
	p._refrescar()

## Los colores que recibe `PanelClubDentro`: los mismos `COL_*` de siempre,
## sin traducir -los traduce `_texto()`, que es quien pinta-.
func _paleta_club_dentro() -> Dictionary:
	return {"suave": Principal.COL_SUAVE, "acento": p.COL_ACENTO, "verde": Principal.COL_VERDE, "texto": Principal.COL_TEXTO,
		"oro": Principal.COL_ORO, "rojo": Principal.COL_ROJO}

func _pintar_club(c: Club) -> void:
	p._limpiar(p._lista_club)
	match p._secc_club:
		"directorio": _club_directorio(c)
		"staff": _club_staff(c)
		"infra": p._club_infra(c)
		"carrera": p._club_carrera(c)
		_: _club_directorio(c)

## EL DIRECTORIO: quién te puso ahí, qué te pide y cuánto te aguanta.
func _club_directorio(c: Club) -> void:
	var d := p.mundo.directiva
	if d != null:
		var t := p._texto(11, Principal.COL_SUAVE); t.text = "LA DIRECTIVA"
		p._lista_club.add_child(t)
		var obj := p._texto(15, Principal.COL_ORO); obj.text = d.objetivo
		obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(obj)
		var meta := p._texto(12, Principal.COL_SUAVE)
		meta.text = "Te piden acabar %s.º o mejor." % d.meta_puesto
		p._lista_club.add_child(meta)

		## La confianza en barra, no en número: "34" no le dice nada a nadie, y
		## "tu puesto está en el aire" sí.
		var barra := ProgressBar.new()
		barra.min_value = 0
		barra.max_value = 100
		barra.value = d.confianza
		barra.custom_minimum_size = Vector2(0, 18)
		barra.show_percentage = false
		p._lista_club.add_child(barra)
		var humor := p._texto(13, Principal.COL_VERDE if d.confianza >= 45 else (Principal.COL_ORO if d.confianza > Directiva.UMBRAL_DESPIDO else Principal.COL_ROJO))
		humor.text = "%s  (%d de 100)" % [d.humor(), d.confianza]
		humor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(humor)
		if not d.trofeos.is_empty():
			var tr := p._texto(12, Principal.COL_ORO)
			tr.text = "Vitrina: " + ", ".join(d.trofeos)
			p._lista_club.add_child(tr)
		p._lista_club.add_child(HSeparator.new())
		_pintar_consejeros(d, c)
		_pintar_embajador(d)

## EL PERSONAL CONTRATADO: cuerpo técnico, red de ojeadores, analítica y
## academias. Todo lo que se paga en nómina y no juega.
func _club_staff(c: Club) -> void:
	var t2 := p._texto(11, Principal.COL_SUAVE)
	t2.text = "CUERPO TÉCNICO  ·  nómina %s/semana" % p._dinero(p.mundo.staff.sueldo_semanal(c.rep))
	p._lista_club.add_child(t2)
	## C9: la jornada legal del personal del país, con su norma.
	var jl := p._texto(11, Principal.COL_SUAVE)
	var fe := Contratos.factor_estructura(c.pais, p.mundo.anio, p.mundo.semana)
	jl.text = "⚖️ Jornada legal del personal: %s%s" % [Contratos.texto_jornada(c.pais, p.mundo.anio, p.mundo.semana),
		"" if is_equal_approx(fe, 1.0) else "  (la estructura cuesta un %+d%%)" % int(round((fe - 1.0) * 100.0))]
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
		lb.text = "Bono de productividad" if not ya else "Bono de productividad  ·  ya repartido este año"
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_bono.add_child(lb)
		var coste_bono := p.mundo.staff.coste_bono(c.rep)
		var bb := Button.new()
		bb.text = "Repartir  %s" % p._dinero(coste_bono)
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
			var tope := p._texto(11, Principal.COL_VERDE); tope.text = "al máximo"
			fila.add_child(tope)
		else:
			var coste := p.mundo.staff.coste_subir(puesto, c.rep)
			var b := Button.new()
			b.text = "Contratar  %s" % p._dinero(coste)
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

## `contratarConsejero(k)` del HTML: hasta dos asesores del directorio a la
## vez, con un costo de entrada y un honorario semanal.
func _pintar_consejeros(d: Directiva, _c: Club) -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "CONSEJEROS DEL DIRECTORIO  ·  %d de %d  ·  %s/semana en honorarios" % [
		d.consejeros.size(), Directiva.MAX_CONSEJEROS, p._dinero(d.honorarios_semanales())]
	p._lista_club.add_child(t)
	for k: String in Directiva.CONSEJEROS:
		var info: Dictionary = Directiva.CONSEJEROS[k]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila)
		var contratado := d.tiene_consejero(k)
		var nom := p._texto(12, Principal.COL_VERDE if contratado else Principal.COL_TEXTO)
		if contratado:
			var o: Dictionary = d.consejeros[k]
			nom.text = "%s  ·  %s (%d años)" % [String(info["nombre"]), String(o["nombre"]), int(o["edad"])]
		else:
			nom.text = String(info["nombre"])
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		var b := Button.new()
		b.add_theme_font_size_override("font_size", 11)
		if contratado:
			b.text = "Cesar"
		else:
			b.text = "Contratar  %s" % p._dinero(Directiva.COSTO_CONTRATAR_CONSEJERO)
			b.disabled = d.consejeros.size() >= Directiva.MAX_CONSEJEROS or _c.saldo < Directiva.COSTO_CONTRATAR_CONSEJERO
		b.pressed.connect(func() -> void: _alternar_consejero(k))
		fila.add_child(b)
		var desc := p._texto(11, Principal.COL_SUAVE)
		desc.text = "    " + String(info["desc"])
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(desc)
	p._lista_club.add_child(HSeparator.new())

func _alternar_consejero(k: String) -> void:
	var problema := p.mundo.directiva.alternar_consejero(k)
	if problema != "":
		p._escribir("[color=#e05555]%s[/color]" % problema)
		return
	p._refrescar()

## "EMBAJADOR DEL CLUB" de `vDirectorio()`: una leyenda retirada -de cualquier
## club- que puedes fichar como ídolo institucional. `Directiva.embajador`
## reutiliza los mismos datos que ya guardaba `Cantera.leyendas` para el
## linaje; aquí solo hacía falta la pantalla.
func _pintar_embajador(d: Directiva) -> void:
	var t := p._texto(11, Principal.COL_SUAVE); t.text = "EMBAJADOR DEL CLUB"
	p._lista_club.add_child(t)
	if not d.embajador.is_empty():
		var e: Dictionary = d.embajador
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila)
		var nom := p._texto(12, Principal.COL_VERDE)
		nom.text = "⭐ %s  ·  ídolo · %s · %s/semana · la hinchada suma socios" % [
			String(e.get("nombre", "")), String(e.get("pos", "")), p._dinero(int(e.get("sueldo", 0)))]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(nom)
		p._boton("Cesar  %s" % p._dinero(Directiva.FINIQUITO_EMBAJADOR), _cesar_embajador, fila)
	else:
		var cantera := p.mundo.cantera
		var candidatas: Array[Dictionary] = Directiva.candidatas_embajador(cantera.leyendas, p.mundo.anio) if cantera != null else []
		if candidatas.is_empty():
			var av := p._texto(11, Principal.COL_SUAVE)
			av.text = "Sin leyendas disponibles todavía."
			p._lista_club.add_child(av)
		for l: Dictionary in candidatas:
			var fila2 := HBoxContainer.new()
			fila2.add_theme_constant_override("separation", 8)
			p._lista_club.add_child(fila2)
			var nom2 := p._texto(12, Principal.COL_TEXTO)
			nom2.text = "⭐ %s  ·  %s · nivel %d en su época" % [
				String(l.get("nombre", "")), String(l.get("pos", "")), int(l.get("nivel", 80))]
			nom2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila2.add_child(nom2)
			var costo := 400000 + int(l.get("nivel", 80)) * 8000
			p._boton("Firmar  %s" % p._dinero(costo), func() -> void: _contratar_embajador(l), fila2)
	p._lista_club.add_child(HSeparator.new())

func _contratar_embajador(l: Dictionary) -> void:
	var problema := p.mundo.directiva.contratar_embajador(l)
	if problema != "":
		p._escribir("[color=#e05555]%s[/color]" % problema)
		return
	if p.mundo.prensa != null:
		p.mundo.prensa.sumar_animo(6)
	p._escribir("[color=#c9a227][b]Vuelve una leyenda:[/b][/color] %s firma como embajador del club." % String(l.get("nombre", "")))
	p._refrescar()

func _cesar_embajador() -> void:
	var nombre := String(p.mundo.directiva.embajador.get("nombre", ""))
	var problema := p.mundo.directiva.cesar_embajador()
	if problema != "":
		p._escribir("[color=#e05555]%s[/color]" % problema)
		return
	p._escribir("[color=#8ea595]Fin de una era: %s deja el rol institucional.[/color]" % nombre)
	p._refrescar()

## `toggleRed()` del HTML: qué países cubre tu red de ojeadores, con nombre y
## sesgo de cada uno. Cuántos puedes cubrir a la vez sale del nivel de
## "ojeador" en el cuerpo técnico, justo arriba de esta sección.
func _pintar_ojeadores(c: Club) -> void:
	var oj := p.mundo.ojeadores
	if oj == null:
		return
	## LA LISTA DE SEGUIMIENTO, de `vOjeo()`. Va lo primero: es lo que se viene
	## a mirar aquí semana tras semana, por delante de la red de ojeadores, que
	## se toca una vez cada varios meses.
	var seguidos := oj.lista_seguimiento()
	if not seguidos.is_empty():
		p._lista_club.add_child(HSeparator.new())
		var ts := p._texto(11, Principal.COL_SUAVE)
		ts.text = "👁️ EN SEGUIMIENTO  ·  %d" % seguidos.size()
		p._lista_club.add_child(ts)
		for j: Jugador in seguidos:
			var suyo: Club = p.mundo.clubes.get(j.club_id)
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			p._lista_club.add_child(fila)
			fila.add_child(p._retrato(j, 22))
			var b := Button.new()
			b.text = "%s  ·  %d años  ·  %s" % [j.nombre, j.edad, suyo.nombre if suyo else "libre"]
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.clip_text = true
			b.custom_minimum_size = Vector2(120, 0)
			b.add_theme_font_size_override("font_size", 12)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void: p._ver_ficha(j))
			fila.add_child(b)
			## Lo que se sigue de alguien es si sube o si baja de precio, así
			## que la media y lo que piden por él son las dos cifras que van.
			var med := p._texto(11, Principal.COL_TEXTO)
			med.text = oj.ovr_texto(j)
			med.custom_minimum_size = Vector2(56, 0)
			fila.add_child(med)
			var pide := p._texto(11, Principal.COL_SUAVE)
			pide.text = p._dinero(p.mundo.mercado.valor_pedido(j))
			pide.custom_minimum_size = Vector2(70, 0)
			fila.add_child(pide)
	p._lista_club.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "RED DE OJEADORES  ·  %d de %d países  ·  presupuesto %s" % [oj.red.size(), oj.max_paises(), p._dinero(oj.presupuesto)]
	p._lista_club.add_child(t)
	## "MERCADO A CIEGAS": tenía el MISMO interruptor duplicado aquí y en
	## Ajustes → Accesibilidad -mismo booleano, `oj.modo_ciego`, dos pantallas
	## sin relación entre sí que nunca se enteraban una de la otra-. El usuario
	## lo marcó jugando ("evitar la duplicidad en los menús"): se toca desde UN
	## solo sitio -Ajustes, que trae además la explicación completa- y aquí
	## queda solo el estado y el atajo para llegar.
	var fila_ciego := HBoxContainer.new()
	fila_ciego.add_theme_constant_override("separation", 8)
	p._lista_club.add_child(fila_ciego)
	var txt_ciego := p._texto(11, Principal.COL_TEXTO)
	txt_ciego.text = "Mercado a ciegas: %s." % ("activado" if oj.modo_ciego else "desactivado")
	txt_ciego.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_ciego.add_child(txt_ciego)
	var b_ciego := Button.new()
	b_ciego.text = "Ir a Ajustes"
	b_ciego.add_theme_font_size_override("font_size", 11)
	b_ciego.pressed.connect(func() -> void:
		p._secc_ajustes = "acceso"
		p._ir_a_pestana("Ajustes"))
	fila_ciego.add_child(b_ciego)
	if oj.max_paises() <= 0:
		var av := p._texto(11, Principal.COL_SUAVE)
		av.text = "Contrata un jefe de ojeadores para poder cubrir países."
		p._lista_club.add_child(av)
	for pais: String in oj.ojeadores:
		var o: Dictionary = oj.ojeadores[pais]
		var s: Dictionary = Ojeadores.SESGOS.get(o["sesgo"], Ojeadores.SESGOS["fiel"])
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila)
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = "%s  ·  %s  ·  %s  ·  precisión %d/3  ·  humor %d" % [
			String(o["nombre"]), pais, String(s["nombre"]), int(o["precision"]), int(o["humor"])]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(nom)
		p._boton("Retirar", func() -> void: _alternar_pais_ojeo(pais), fila)
	var paises: Array[String] = []
	for l: Liga in p.mundo.ligas:
		if not paises.has(l.pais) and not oj.ojeadores.has(l.pais):
			paises.append(l.pais)
	paises.sort()
	if not paises.is_empty():
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		p._lista_club.add_child(flow)
		for pais2: String in paises:
			var bp := Button.new()
			bp.text = pais2
			bp.add_theme_font_size_override("font_size", 11)
			bp.custom_minimum_size = Vector2(52, 28)
			bp.disabled = oj.red.size() >= oj.max_paises()
			bp.pressed.connect(func() -> void: _alternar_pais_ojeo(pais2))
			flow.add_child(bp)

## `vOjeo()`: EL DEPARTAMENTO DE ANÁLISIS DE DATOS.
##
## La otra forma de encontrar futbolistas. El ojeo dice lo BUENO que es alguien;
## el modelo dice lo INFRAVALORADO que está, que no es la misma pregunta. Y a
## partir del nivel dos, con un jefe de ojeadores de la vieja escuela en casa, la
## tensión sube sola: esto no es una mejora, es tomar partido.
func _pintar_analitica(c: Club) -> void:
	var oj := p.mundo.ojeadores
	if oj == null:
		return
	p._lista_club.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "📊 DEPARTAMENTO DE ANÁLISIS DE DATOS"
	p._lista_club.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_club.add_child(fila)
	var l := p._texto(12, Principal.COL_TEXTO)
	l.text = "Modelo propio  ·  nivel %d de %d" % [oj.analitica_nivel, Ojeadores.ANALITICA_MAX]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.tooltip_text = "Cruza minutos, duelos y distancia recorrida para encontrar lo que el ojo no ve."
	fila.add_child(l)
	var b := Button.new()
	var tope := oj.analitica_nivel >= Ojeadores.ANALITICA_MAX
	b.text = "AL MÁXIMO" if tope else "Ampliar · %s" % p._dinero(oj.coste_analitica(c))
	b.add_theme_font_size_override("font_size", 11)
	b.disabled = tope or c.saldo < oj.coste_analitica(c)
	b.clip_text = true
	b.custom_minimum_size = Vector2(140, 0)
	b.pressed.connect(func() -> void: _mejorar_analitica(c))
	fila.add_child(b)

	if oj.analitica_nivel >= 1 and p.mundo.staff != null and p.mundo.staff.nivel("ojo") >= 2:
		p._dato("Tensión con el ojeo tradicional", "%d%%" % oj.analitica_tension,
			Principal.COL_ROJO if oj.analitica_tension >= Ojeadores.TENSION_CRITICA else Principal.COL_ORO, p._lista_club)

	var vivos := oj.hallazgos_vivos()
	if vivos.is_empty():
		if not p._modo_experto:
			var vac := p._texto(10, Principal.COL_SUAVE)
			vac.text = "El modelo todavía no ha señalado a nadie. Necesita al menos un nivel y unas semanas de datos."
			vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_club.add_child(vac)
	else:
		var th := p._texto(10, Principal.COL_SUAVE)
		th.text = "Últimos hallazgos del modelo:"
		p._lista_club.add_child(th)
		for h: Dictionary in vivos:
			var j: Jugador = h["jugador"]
			var suyo: Club = p.mundo.clubes.get(j.club_id)
			var fh := HBoxContainer.new()
			fh.add_theme_constant_override("separation", 6)
			p._lista_club.add_child(fh)
			var bj := Button.new()
			bj.text = "%s  ·  %s, %d años" % [j.nombre, suyo.nombre if suyo else "libre", j.edad]
			bj.flat = true
			bj.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bj.add_theme_font_size_override("font_size", 12)
			bj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bj.clip_text = true
			bj.pressed.connect(func() -> void: p._ver_ficha(j))
			fh.add_child(bj)
			var mj := p._texto(11, Principal.COL_ORO)
			mj.text = oj.ovr_texto(j)
			mj.custom_minimum_size = Vector2(60, 0)
			fh.add_child(mj)

## LAS ACADEMIAS INTERNACIONALES. La apuesta más larga del juego: la sede que
## abres hoy da su primer futbolista el año que viene. Cuesta de construir y
## cuesta todas las semanas, y a cambio cada pretemporada llega una joya local.
func _pintar_academias(c: Club) -> void:
	var oj := p.mundo.ojeadores
	if oj == null:
		return
	p._lista_club.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🏫 ACADEMIAS INTERNACIONALES  ·  %d de %d" % [oj.academias.size(), Ojeadores.ACADEMIAS_MAX]
	p._lista_club.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Construir cuesta %s y mantenerla %s a la semana por sede. Cada pretemporada llega una joya local con proyección alta, directa a tu plantel." % [
			p._dinero(Eco.escalar(Ojeadores.COSTE_ACADEMIA, float(c.rep))),
			p._dinero(Eco.escalar(Ojeadores.MANTENCION_ACADEMIA, float(c.rep)))]
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(ex)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	p._lista_club.add_child(flow)
	var paises: Array[String] = []
	for l: Liga in p.mundo.ligas:
		if l.pais != c.pais and not paises.has(l.pais):
			paises.append(l.pais)
	for p_local: String in paises:
		var pais := p_local
		var tengo := oj.tiene_academia(pais)
		var bp := Button.new()
		bp.text = ("🏫 " if tengo else "") + pais
		bp.add_theme_font_size_override("font_size", 11)
		bp.toggle_mode = true
		bp.button_pressed = tengo
		bp.custom_minimum_size = Vector2(64, 28)
		bp.disabled = not tengo and oj.academias.size() >= Ojeadores.ACADEMIAS_MAX
		bp.pressed.connect(func() -> void: _alternar_academia(pais, c))
		flow.add_child(bp)
	if not oj.academias.is_empty():
		p._dato("Mantención semanal", p._dinero(oj.mantencion_academias(c)), Principal.COL_ROJO, p._lista_club)

func _mejorar_analitica(c: Club) -> void:
	var problema := p.mundo.ojeadores.mejorar_analitica(c)
	if problema != "":
		p._escribir("[color=#e05555]No se puede ampliar: %s.[/color]" % problema)
	p._refrescar()

func _alternar_academia(pais: String, c: Club) -> void:
	var problema := p.mundo.ojeadores.alternar_academia(pais, c)
	if problema != "":
		p._escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
	p._refrescar()

func _alternar_pais_ojeo(pais: String) -> void:
	var problema := p.mundo.ojeadores.alternar_pais(pais)
	if problema != "":
		p._escribir("[color=#e05555]%s.[/color]" % problema)
		return
	p._refrescar()

func _contratar(puesto: String) -> void:
	var problema := p.mundo.staff.subir(puesto, p.mundo.mi_club())
	if problema != "":
		p._escribir("[color=#e05555]No se puede contratar: %s.[/color]" % problema)
		return
	var datos: Array = Staff.PUESTOS[puesto]
	p._escribir("[color=#4caf6d]Contratado: %s, nivel %d.[/color] %s." % [
		datos[0], p.mundo.staff.nivel(puesto), datos[1]])
	p._refrescar()
