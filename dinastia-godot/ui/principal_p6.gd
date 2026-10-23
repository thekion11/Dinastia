extends "res://ui/principal_p5.gd"
## [Capa 6/19 de `principal.gd`] _pintar_finanzas, _pintar_porque_moral, _pintar_camarin

func _pintar_finanzas(c: Club) -> void:
	_limpiar(_lista_finanzas)
	## EL PRECIO DE LA ENTRADA. `Club.precio_entrada` existía y `Finanzas` lo
	## usaba de verdad -mueve la ocupación un 5% por euro y multiplica lo que
	## deja cada espectador-, pero no había ningún control para tocarlo: una
	## palanca de gestión real, escrita y funcionando, que el jugador no podía
	## mover. Va arriba del todo porque es una decisión, no un dato.
	var tp := _texto(11, COL_SUAVE)
	tp.text = Idiomas.t("PRECIO DE LA ENTRADA")
	_lista_finanzas.add_child(tp)
	var fila_p := HBoxContainer.new()
	fila_p.add_theme_constant_override("separation", 8)
	_lista_finanzas.add_child(fila_p)
	var lp := _texto(16, COL_TEXTO)
	lp.text = Eco.dinero_euros(c.precio_entrada)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_p.add_child(lp)
	_boton("−1", func() -> void:
		c.precio_entrada = maxf(2.0, c.precio_entrada - 1.0)
		(self as Principal)._refrescar(), fila_p)
	_boton("+1", func() -> void:
		c.precio_entrada = minf(30.0, c.precio_entrada + 1.0)
		(self as Principal)._refrescar(), fila_p)
	## Se enseña el efecto de las dos palancas a la vez, porque el precio es
	## justo el sitio donde subir puede recaudar MENOS: más por cabeza, pero
	## menos cabezas.
	## `Finanzas` no vive en el mundo: se construye por club y por semana dentro
	## de `Mundo.avanzar_semana()` (línea 558). Aquí se monta uno igual, solo
	## para PREGUNTARLE -no cobra nada, no mueve la caja-, con el mismo aporte de
	## instalaciones que usará el de verdad.
	var f_sim := Finanzas.new(c, mundo.obras.aporte_ocupacion(), 0, 0.0)
	f_sim.aplica_operacion = true
	f_sim.factor_operacion = mundo.obras.abarata_operacion()
	var gente := f_sim.asistencia()
	var por_cabeza := Finanzas.ingreso_por_espectador(c.precio_entrada)
	_dato("Asistencia estimada", "%s de %s  (%d%%)" % [
		_miles(gente), _miles(c.estadio_aforo),
		int(round(float(gente) * 100.0 / float(maxi(c.estadio_aforo, 1))))], COL_TEXTO, _lista_finanzas)
	_dato("Taquilla por partido", _dinero(int(round(float(gente) * por_cabeza))), COL_VERDE, _lista_finanzas)
	_lista_finanzas.add_child(HSeparator.new())

	## LA TIENDA DEL CLUB. Se paga el montaje una vez y vende todos los meses.
	## Depende de los SOCIOS y del ÁNIMO de la hinchada: rinde cuando el equipo
	## ilusiona, que es lo que la hace una decisión y no un grifo abierto.
	var tt := _texto(11, COL_SUAVE)
	tt.text = Idiomas.t("TIENDA DEL CLUB  ·  rinde %s/mes") % _dinero(mundo.ingreso_tienda(c))
	_lista_finanzas.add_child(tt)
	for clave: String in Mundo.TIENDA:
		var linea: Dictionary = Mundo.TIENDA[clave]
		var activa := bool(mundo.tienda.get(clave, false))
		var fila_t := HBoxContainer.new()
		fila_t.add_theme_constant_override("separation", 8)
		_lista_finanzas.add_child(fila_t)
		var nt := _texto(12, COL_TEXTO if activa else COL_SUAVE)
		nt.text = "%s%s" % [String(linea["nombre"]), Idiomas.t("   ·   a la venta") if activa else ""]
		nt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_t.add_child(nt)
		var bt := Button.new()
		bt.text = Idiomas.t("Retirar") if activa else Idiomas.t("Lanzar  %s") % _dinero(Eco.escalar(int(linea["montaje"]), c.rep))
		bt.add_theme_font_size_override("font_size", 11)
		bt.pressed.connect(func() -> void:
			var err := mundo.alternar_tienda(clave, c)
			if err != "":
				_escribir("[color=#e05555]No se pudo: %s.[/color]" % err)
			(self as Principal)._refrescar())
		fila_t.add_child(bt)
	_lista_finanzas.add_child(HSeparator.new())

	## `vContabilidad()` del HTML: el ejercicio entero de un vistazo. Sin esto,
	## la única forma de saber si el club gana o pierde dinero al AÑO era ir
	## sumando cierres de mes a ojo. No inventa cifras: multiplica las mismas
	## partidas que ya cobra y paga `Finanzas.mes()`.
	var partidos_casa := int(_liga_de(c).jornadas() / 2)
	var proy := f_sim.proyeccion_anual(partidos_casa, mundo.ingreso_tienda(c))
	var tc2 := _texto(11, COL_SUAVE)
	tc2.text = Idiomas.t("EJERCICIO %d  ·  PROYECCIÓN ANUAL") % mundo.anio
	_lista_finanzas.add_child(tc2)
	var res: int = proy["resultado"]
	_dato("Ingresos previstos", _dinero(int(proy["total_ingresos"])), COL_VERDE, _lista_finanzas)
	_dato("Gastos previstos", _dinero(int(proy["total_gastos"])), COL_ROJO, _lista_finanzas)
	_dato("Resultado del ejercicio", _dinero(res), COL_VERDE if res >= 0 else COL_ROJO, _lista_finanzas)
	## El porcentaje de masa salarial sobre ingresos: LA cifra que mira
	## cualquiera que entienda de esto. Por encima del 70% el club va camino de
	## un problema aunque la caja de hoy se vea estupenda.
	var pct: int = proy["pct_salarial"]
	_dato("Masa salarial sobre ingresos", "%d%%" % pct,
		COL_ROJO if pct > 70 else (COL_ORO if pct > 55 else COL_VERDE), _lista_finanzas)
	if pct > 70:
		var av := _texto(11, COL_ROJO)
		av.text = Idiomas.t("Los sueldos se comen más del 70% de lo que entra. Así no se sostiene una temporada mala.")
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_finanzas.add_child(av)
	var te := _texto(11, COL_SUAVE)
	te.text = Idiomas.t("ESTADO DE RESULTADOS")
	_lista_finanzas.add_child(te)
	for k: String in proy["ingresos"]:
		_dato(k, _dinero(int(proy["ingresos"][k])), COL_VERDE, _lista_finanzas)
	for k2: String in proy["gastos"]:
		_dato(k2, "−%s" % _dinero(int(proy["gastos"][k2])), COL_ROJO, _lista_finanzas)
	var pal := _ui_ficha._paleta_ficha()
	PanelFinanzas.pintar_balance_y_caja(_lista_finanzas, c, mundo, proy, pal)
	PanelFinanzas.pintar_auspicio(_lista_finanzas, c, mundo, pal,
		func(idx: int) -> void: _ui_gente._firmar_auspicio(idx))
	PanelFinanzas.pintar_patrocinio(_lista_finanzas, c, mundo, pal,
		func(clave: String) -> void: _ui_gente._lanzar_campana(clave),
		func() -> void: _ui_gente._pujar_marca())
	PanelFinanzas.pintar_banco(_lista_finanzas, c, mundo, pal,
		func(i: int) -> void: _ui_gente._pedir_credito(i, c),
		func(i: int) -> void: _ui_gente._prepagar(i, c),
		func(i: int) -> void: _ui_gente._renegociar(i),
		func() -> void: _ui_gente._emitir_bono(c))
	_lista_finanzas.add_child(HSeparator.new())

	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("RESUMEN")
	_lista_finanzas.add_child(t)
	_dato("Caja", _dinero(c.saldo), COL_VERDE if c.saldo >= 0 else COL_ROJO, _lista_finanzas)
	_dato("Sueldos del plantel", _dinero(c.masa_salarial()) + "/semana", COL_TEXTO, _lista_finanzas)
	if mundo.staff != null:
		_dato("Cuerpo técnico", _dinero(mundo.staff.sueldo_semanal(c.rep)) + "/semana", COL_TEXTO, _lista_finanzas)
	_lista_finanzas.add_child(HSeparator.new())

	## Otra pieza que ya funcionaba y no se veía: `cobrar_plusvalias()` corre
	## sola cada temporada -Mundo.nueva_temporada()-, pero el porcentaje que te
	## guardaste al vender no aparecía en ningún sitio hasta que se cobraba solo.
	if mundo.cesiones != null and not mundo.cesiones.plusvalias.is_empty():
		var tpv := _texto(11, COL_SUAVE)
		tpv.text = Idiomas.t("PLUSVALÍAS PENDIENTES")
		_lista_finanzas.add_child(tpv)
		for pv: Dictionary in mundo.cesiones.plusvalias:
			if String(pv.get("beneficiario", "")) != c.id:
				continue
			var jact: Jugador = mundo.jugador_por_id(String(pv.get("pid", "")))
			var detalle := "ya no está en el mundo"
			if jact != null:
				var club_hoy: Club = mundo.clubes.get(jact.club_id)
				detalle = "hoy en %s · vale %s" % [club_hoy.nombre if club_hoy else "?", _dinero(jact.valor)]
			_dato("%s  (%d%%)" % [String(pv.get("nombre", "")), int(pv.get("pct", 0))], detalle, COL_SUAVE, _lista_finanzas)
		_lista_finanzas.add_child(HSeparator.new())

	var libro := mundo.libro_financiero
	var tm := _texto(11, COL_SUAVE)
	tm.text = Idiomas.t("LIBRO DE MOVIMIENTOS  ·  últimos %d") % libro.size()
	_lista_finanzas.add_child(tm)
	if libro.is_empty():
		var vacio := _texto(12, COL_SUAVE)
		vacio.text = Idiomas.t("Todavía no hay movimientos aparte de la taquilla y los sueldos. Ficha, cede, contrata staff o levanta un título: todo lo que mueve la caja por fuera de la semana normal queda anotado aquí.")
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_finanzas.add_child(vacio)
		return
	for i in range(libro.size() - 1, -1, -1):
		var mov: Dictionary = libro[i]
		var monto := int(mov.get("monto", 0))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_finanzas.add_child(fila)
		var et := _texto(11, COL_SUAVE)
		et.text = "S%d/%d" % [int(mov.get("semana", 0)), int(mov.get("anio", 0))]
		et.custom_minimum_size = Vector2(50, 0)
		fila.add_child(et)
		var co := _texto(12, COL_TEXTO)
		co.text = String(mov.get("concepto", ""))
		co.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		co.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(co)
		var va := _texto(12, COL_VERDE if monto >= 0 else COL_ROJO)
		va.text = ("+" if monto > 0 else "") + _dinero(monto)
		fila.add_child(va)

## `vCamarin()` del HTML: clanes, salud mental y jerarquía interna. Toda la
## maquinaria -`Vestuario.camarillas`, `mente()`/`ansiedad()`, `mediar()`,
## `dar_terapia()`, `descanso_mental()`- ya estaba escrita y probada -la
## ansiedad ya se movía sola cada semana con `_proceso_mental()`, y `mediar()`
## ya la bajaba de verdad-, pero no había ni una fila en ningún sitio del
## juego que la enseñara: la nota de esta sesión que decía "la ansiedad no
## está portada" (escrita al tocar Ojeadores y la mesa de negociación) estaba
## mal -no se había mirado con suficiente cuidado-, y queda corregida aquí.
## POR QUÉ SUBE O BAJA LA MORAL (17-10-2026, lo pedía el informe y lo hace FM):
## los motivos de las últimas semanas sumados por el plantel, lo que pesa en la
## satisfacción de media y los tres más tocados con su motivo.
func _pintar_porque_moral(c: Club) -> void:
	var v := mundo.vestuario
	var pl := c.plantilla
	if pl.is_empty():
		return
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("📈 POR QUÉ SUBE O BAJA LA MORAL")
	_lista_camarin.add_child(t)
	## Las cuatro últimas semanas con algún cambio.
	var semanas := {}
	for j in pl:
		for e: Dictionary in j.historial_moral:
			semanas[int(e["s"])] = true
	var orden: Array = semanas.keys()
	orden.sort()
	var desde: int = orden[maxi(orden.size() - 4, 0)] if not orden.is_empty() else 0
	var por_motivo := {}
	for j in pl:
		for e: Dictionary in j.historial_moral:
			if int(e["s"]) >= desde:
				por_motivo[String(e["m"])] = float(por_motivo.get(String(e["m"]), 0.0)) + float(e["d"])
	var motivos: Array = por_motivo.keys()
	motivos.sort_custom(func(a: String, b: String) -> bool: return absf(float(por_motivo[a])) > absf(float(por_motivo[b])))
	if motivos.is_empty():
		var nada := _texto(12, COL_SUAVE)
		nada.text = Idiomas.t("Todavía no hay cambios de moral que explicar (empieza a jugar semanas).")
		_lista_camarin.add_child(nada)
	else:
		var sub := _texto(10, COL_SUAVE)
		sub.text = Idiomas.t("Últimas semanas, media por jugador:")
		_lista_camarin.add_child(sub)
		for mo: String in motivos.slice(0, 6):
			var media := float(por_motivo[mo]) / float(pl.size())
			if absf(media) < 0.05:
				continue
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			_lista_camarin.add_child(fila)
			var n := _texto(12, COL_TEXTO)
			n.text = Idiomas.t(mo)
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(n)
			var dv := _texto(12, COL_VERDE if media > 0 else COL_ROJO)
			dv.text = "%+.1f" % media
			fila.add_child(dv)
	## Lo que pesa en la satisfacción, de media: hacia ahí va la moral cada semana.
	if v != null and v.has_method("satisfaccion_de"):
		var suma := {"min": 0.0, "rend": 0.0, "tact": 0.0, "inst": 0.0}
		for j in pl:
			var sat: Dictionary = v.satisfaccion_de(j)
			for k: String in suma:
				suma[k] = float(suma[k]) + float(sat[k])
		var sub2 := _texto(10, COL_SUAVE)
		sub2.text = Idiomas.t("Hacia dónde tira la satisfacción (la moral se acerca a ella cada semana):")
		_lista_camarin.add_child(sub2)
		var peor := "min"
		for k: String in suma:
			if float(suma[k]) < float(suma[peor]):
				peor = k
		var nombres := {"min": "Minutos de juego", "rend": "Rendimiento", "tact": "Comodidad en su puesto", "inst": "Instalaciones"}
		for k: String in ["min", "rend", "tact", "inst"]:
			var val := float(suma[k]) / float(pl.size())
			var fila2 := HBoxContainer.new()
			fila2.add_theme_constant_override("separation", 8)
			_lista_camarin.add_child(fila2)
			var et := _texto(12, COL_ROJO if k == peor else COL_TEXTO)
			et.text = Idiomas.t(nombres[k])
			et.custom_minimum_size = Vector2(190, 0)
			fila2.add_child(et)
			var barra := ProgressBar.new()
			barra.max_value = 100
			barra.value = val
			barra.show_percentage = false
			barra.custom_minimum_size = Vector2(160, 10)
			barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			fila2.add_child(barra)
			var num := _texto(12, COL_SUAVE)
			num.text = str(roundi(val))
			fila2.add_child(num)
		var consejo := {"min": "Reparte minutos: los que no juegan son los que más tiran la moral abajo.",
			"rend": "El equipo no rinde: la moral sube sola cuando llegan buenas notas.",
			"tact": "Hay jugadores fuera de su puesto: revisa la alineación o reconviértelos.",
			"inst": "Mejorar ciudad deportiva, médicos, gimnasio y cocina sube la moral de todos."}
		var tip := _texto(12, COL_ORO)
		tip.text = "💡 " + Idiomas.t(consejo[peor])
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_camarin.add_child(tip)
	## Los tres más tocados y su motivo.
	var bajos: Array = pl.duplicate()
	bajos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.moral < b.moral)
	var sub3 := _texto(10, COL_SUAVE)
	sub3.text = Idiomas.t("Los más tocados:")
	_lista_camarin.add_child(sub3)
	for j: Jugador in bajos.slice(0, 3):
		var mot := ""
		for k in range(j.historial_moral.size() - 1, -1, -1):
			if int(j.historial_moral[k]["d"]) < 0:
				mot = Idiomas.t(String(j.historial_moral[k]["m"]))
				break
		if mot == "" and v != null and v.has_method("satisfaccion_de"):
			mot = Idiomas.t(Vestuario.motivo_satisfaccion(v.satisfaccion_de(j), true))
		var fj := _texto(12, COL_ROJO if j.moral < 40 else COL_TEXTO)
		fj.text = "%s  ·  %s %d  ·  %s" % [j.nombre, Idiomas.t("moral"), j.moral, mot]
		_lista_camarin.add_child(fj)
	_lista_camarin.add_child(HSeparator.new())

func _pintar_camarin(c: Club) -> void:
	_limpiar(_lista_camarin)
	var v := mundo.vestuario
	if v == null:
		return
	## LAS CÁMARAS. Si aceptaste el documental, el vestuario está grabado y a la
	## gente le incomoda. Va lo primero porque explica caídas de moral que si no
	## parecerían salidas de la nada.
	if mundo.prensa != null and mundo.prensa.hay_camaras():
		var cam := _texto(12, COL_ORO)
		cam.text = Idiomas.t("🎥 Hay cámaras en el vestuario %d semana(s) más. A los más sensibles del plantel les incomoda.") % mundo.prensa.semanas_documental
		cam.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_camarin.add_child(cam)
	var pl := c.plantilla
	var moral := 60
	var ansi := 0
	if not pl.is_empty():
		var sm := 0
		var sa := 0
		for j in pl:
			sm += j.moral
			sa += v.ansiedad(j)
		moral = int(round(float(sm) / float(pl.size())))
		ansi = int(round(float(sa) / float(pl.size())))
	var cap: Jugador = null
	for j in pl:
		if j.capitan:
			cap = j
			break

	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("CLIMA DEL VESTUARIO")
	_lista_camarin.add_child(t)
	var gr := GridContainer.new()
	gr.columns = 4
	gr.add_theme_constant_override("h_separation", 14)
	_lista_camarin.add_child(gr)
	for par in [["Moral media", str(moral)], ["Ansiedad media", str(ansi)],
			["Capitán", _ui_cantera._apellido(cap.nombre) if cap else "—"], ["Grupos", str(v.camarillas.size())]]:
		var col := VBoxContainer.new()
		gr.add_child(col)
		var et := _texto(10, COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := _texto(15, COL_ROJO if (String(par[0]) == "Ansiedad media" and ansi > 50) else COL_TEXTO)
		va.text = String(par[1])
		col.add_child(va)
	_lista_camarin.add_child(HSeparator.new())
	_pintar_porque_moral(c)

	var tc := _texto(11, COL_SUAVE)
	tc.text = Idiomas.t("CLANES Y CAMARILLAS")
	_lista_camarin.add_child(tc)
	if v.camarillas.is_empty():
		var vc := _texto(12, COL_SUAVE)
		vc.text = Idiomas.t("Todavía no hay grupos definidos en el vestuario.")
		_lista_camarin.add_child(vc)
	for cl: Dictionary in v.camarillas:
		var humor := int(cl.get("humor", 0))
		var lider: Jugador = mundo.jugador_por_id(String(cl.get("lider", "")))
		var miembros: Array = cl.get("miembros", [])
		var en_mi_club := 0
		var nombres: Array[String] = []
		for id in miembros:
			var jm := mundo.jugador_por_id(String(id))
			if jm != null and jm.club_id == c.id:
				en_mi_club += 1
				if nombres.size() < 7:
					nombres.append(_ui_cantera._apellido(jm.nombre))
		var estado_txt := "enojados" if humor < -25 else ("contentos" if humor > 15 else "neutrales")
		var estado_col := COL_ROJO if humor < -25 else (COL_VERDE if humor > 15 else COL_ORO)
		var fila := VBoxContainer.new()
		_lista_camarin.add_child(fila)
		var cab := HBoxContainer.new()
		cab.add_theme_constant_override("separation", 8)
		fila.add_child(cab)
		var nom := _texto(12, COL_TEXTO)
		nom.text = (Idiomas.t("%s  ·  %d jugador") if en_mi_club == 1 else Idiomas.t("%s  ·  %d jugadores")) % [String(cl.get("nombre", "")), en_mi_club]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cab.add_child(nom)
		var et2 := _texto(11, estado_col)
		et2.text = estado_txt
		cab.add_child(et2)
		var lid := _texto(11, COL_SUAVE)
		lid.text = Idiomas.t("Líder: %s  ·  %s") % [lider.nombre if lider else "—", ", ".join(nombres)]
		lid.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(lid)
		if humor < -10:
			var cid := String(cl.get("id", ""))
			_boton("🕊️ Mediar con el grupo", func() -> void: _ui_finanzas._mediar_clan(cid), fila)
		_lista_camarin.add_child(HSeparator.new())

	var en_riesgo: Array[Jugador] = []
	for j in pl:
		if v.ansiedad(j) >= 48:
			en_riesgo.append(j)
	en_riesgo.sort_custom(func(a: Jugador, b: Jugador) -> bool: return v.ansiedad(a) > v.ansiedad(b))
	var tm := _texto(11, COL_SUAVE)
	tm.text = Idiomas.t("🧠 SALUD MENTAL")
	_lista_camarin.add_child(tm)
	if en_riesgo.is_empty():
		var vm := _texto(12, COL_SUAVE)
		vm.text = Idiomas.t("Nadie está pasándolo mal ahora mismo.")
		_lista_camarin.add_child(vm)
	for j: Jugador in en_riesgo:
		var est: Dictionary = v.estado_mental(j)
		var filaj := HBoxContainer.new()
		filaj.add_theme_constant_override("separation", 8)
		_lista_camarin.add_child(filaj)
		var nomj := _texto(12, COL_TEXTO)
		nomj.text = Idiomas.t("%s  ·  %s  ·  %d años") % [j.nombre, j.pos_e, j.edad]
		nomj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filaj.add_child(nomj)
		var etj := _texto(11, Color(String(est.get("color", "#8ea595"))))
		etj.text = "%s  %d" % [String(est.get("txt", "")), v.ansiedad(j)]
		filaj.add_child(etj)
		_boton("Terapia", func() -> void: _ui_finanzas._dar_terapia_mental(j), filaj)
		_boton("Descanso mental", func() -> void: _ui_finanzas._pedir_descanso_mental(j), filaj)
	_lista_camarin.add_child(HSeparator.new())

	var th := _texto(11, COL_SUAVE)
	th.text = Idiomas.t("JERARQUÍA INTERNA")
	_lista_camarin.add_child(th)
	var jerarquia := pl.duplicate()
	jerarquia.sort_custom(func(a: Jugador, b: Jugador) -> bool:
		var va2 := float(a.ovr) + float(a.edad) * 1.6 + (25.0 if a.capitan else 0.0)
		var vb2 := float(b.ovr) + float(b.edad) * 1.6 + (25.0 if b.capitan else 0.0)
		return va2 > vb2)
	for i in mini(10, jerarquia.size()):
		var jj: Jugador = jerarquia[i]
		var etiqueta := "referente" if i < 3 else ("influyente" if i < 6 else "periférico")
		_dato("%d.  %s%s" % [i + 1, "ⓒ " if jj.capitan else "", jj.nombre], "%d  ·  %s" % [jj.ovr, etiqueta], COL_TEXTO, _lista_camarin)
