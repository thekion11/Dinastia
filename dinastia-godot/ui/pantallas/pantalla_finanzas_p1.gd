extends RefCounted
## [Capa 1/2 de `pantalla_finanzas.gd`] _init, _pintar_finanzas

## FINANZAS, CAMARÍN Y ROL: las cuentas, el vestuario, la equipación, las directrices y la carrera en el club.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).
## La pestaña entera de cuentas (`_pintar_finanzas`) llegó aquí el 27-10 (fase 6, paso 6).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

## La pestaña FINANZAS: precio de la entrada, tienda, proyección anual, balance y caja,
## auspicios, patrocinio, banco, resumen, plusvalías y libro de movimientos.
func _pintar_finanzas(c: Club) -> void:
	p._limpiar(p._lista_finanzas)
	## EL PRECIO DE LA ENTRADA. `Club.precio_entrada` existía y `Finanzas` lo
	## usaba de verdad -mueve la ocupación un 5% por euro y multiplica lo que
	## deja cada espectador-, pero no había ningún control para tocarlo: una
	## palanca de gestión real, escrita y funcionando, que el jugador no podía
	## mover. Va arriba del todo porque es una decisión, no un dato.
	var tp := p._texto(11, p.COL_SUAVE)
	tp.text = Idiomas.t("PRECIO DE LA ENTRADA")
	p._lista_finanzas.add_child(tp)
	var fila_p := HBoxContainer.new()
	fila_p.add_theme_constant_override("separation", 8)
	p._lista_finanzas.add_child(fila_p)
	var lp := p._texto(16, p.COL_TEXTO)
	lp.text = Eco.dinero_euros(c.precio_entrada)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_p.add_child(lp)
	p._boton("−1", func() -> void:
		c.precio_entrada = maxf(2.0, c.precio_entrada - 1.0)
		p._refrescar(), fila_p)
	p._boton("+1", func() -> void:
		c.precio_entrada = minf(30.0, c.precio_entrada + 1.0)
		p._refrescar(), fila_p)
	## Se enseña el efecto de las dos palancas a la vez, porque el precio es
	## justo el sitio donde subir puede recaudar MENOS: más por cabeza, pero
	## menos cabezas.
	## `Finanzas` no vive en el p.mundo: se construye por club y por semana. Aquí se pide EL MISMO que cobra
	## (`Mundo._finanzas_de_la_semana`: tele de la asamblea y de prensa, marketing, honorarios, jornada
	## legal, operación), solo para PREGUNTARLE: proyectar no mueve la caja. Antes se montaba uno a mano sin
	## esas palancas y la proyección no cuadraba con lo que luego se cobraba.
	var f_sim: Finanzas = p.mundo._finanzas_de_la_semana(c)
	## La taquilla con las palancas de la jornada (horario, techo, sanción, fiestas, precios dinámicos).
	var taq := p.mundo.estimar_taquilla(c)
	var gente := int(taq["gente"])
	p._dato("Asistencia estimada", "%s de %s  (%d%%)" % [
		p._miles(gente), p._miles(c.estadio_aforo),
		int(round(float(gente) * 100.0 / float(maxi(c.estadio_aforo, 1))))], p.COL_TEXTO, p._lista_finanzas)
	p._dato("Taquilla por partido", p._dinero(int(taq["monto"])), p.COL_VERDE, p._lista_finanzas)
	p._lista_finanzas.add_child(HSeparator.new())

	## LA TIENDA DEL CLUB. Se paga el montaje una vez y vende todos los meses.
	## Depende de los SOCIOS y del ÁNIMO de la hinchada: rinde cuando el equipo
	## ilusiona, que es lo que la hace una decisión y no un grifo abierto.
	var tt := p._texto(11, p.COL_SUAVE)
	tt.text = Idiomas.t("TIENDA DEL CLUB  ·  rinde %s/mes") % p._dinero(p.mundo.ingreso_tienda(c))
	p._lista_finanzas.add_child(tt)
	for clave: String in Mundo.TIENDA:
		var linea: Dictionary = Mundo.TIENDA[clave]
		var activa := bool(p.mundo.tienda.get(clave, false))
		var fila_t := HBoxContainer.new()
		fila_t.add_theme_constant_override("separation", 8)
		p._lista_finanzas.add_child(fila_t)
		var nt := p._texto(12, p.COL_TEXTO if activa else p.COL_SUAVE)
		nt.text = "%s%s" % [String(linea["nombre"]), Idiomas.t("   ·   a la venta") if activa else ""]
		nt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_t.add_child(nt)
		var bt := Button.new()
		bt.text = Idiomas.t("Retirar") if activa else Idiomas.t("Lanzar  %s") % p._dinero(Eco.escalar(int(linea["montaje"]), c.rep))
		bt.add_theme_font_size_override("font_size", 11)
		bt.pressed.connect(func() -> void:
			var err := p.mundo.alternar_tienda(clave, c)
			if err != "":
				p._escribir("[color=#e05555]No se pudo: %s.[/color]" % err)
			p._refrescar())
		fila_t.add_child(bt)
	p._lista_finanzas.add_child(HSeparator.new())

	## `vContabilidad()` del HTML: el ejercicio entero de un vistazo. Sin esto,
	## la única forma de saber si el club gana o pierde dinero al AÑO era ir
	## sumando cierres de mes a ojo. No inventa cifras: multiplica las mismas
	## partidas que ya cobra y paga `Finanzas.mes()`.
	var partidos_casa := int(p._liga_de(c).jornadas() / 2)
	var proy := f_sim.proyeccion_anual(partidos_casa, p.mundo.ingreso_tienda(c))
	var tc2 := p._texto(11, p.COL_SUAVE)
	tc2.text = Idiomas.t("EJERCICIO %d  ·  PROYECCIÓN ANUAL") % p.mundo.anio
	p._lista_finanzas.add_child(tc2)
	var res: int = proy["resultado"]
	p._dato("Ingresos previstos", p._dinero(int(proy["total_ingresos"])), p.COL_VERDE, p._lista_finanzas)
	p._dato("Gastos previstos", p._dinero(int(proy["total_gastos"])), p.COL_ROJO, p._lista_finanzas)
	p._dato("Resultado del ejercicio", p._dinero(res), p.COL_VERDE if res >= 0 else p.COL_ROJO, p._lista_finanzas)
	## El porcentaje de masa salarial sobre ingresos: LA cifra que mira
	## cualquiera que entienda de esto. Por encima del 70% el club va camino de
	## un problema aunque la caja de hoy se vea estupenda.
	var pct: int = proy["pct_salarial"]
	p._dato("Masa salarial sobre ingresos", "%d%%" % pct,
		p.COL_ROJO if pct > 70 else (p.COL_ORO if pct > 55 else p.COL_VERDE), p._lista_finanzas)
	if pct > 70:
		var av := p._texto(11, p.COL_ROJO)
		av.text = Idiomas.t("Los sueldos se comen más del 70% de lo que entra. Así no se sostiene una temporada mala.")
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_finanzas.add_child(av)
	var te := p._texto(11, p.COL_SUAVE)
	te.text = Idiomas.t("ESTADO DE RESULTADOS")
	p._lista_finanzas.add_child(te)
	for k: String in proy["ingresos"]:
		p._dato(k, p._dinero(int(proy["ingresos"][k])), p.COL_VERDE, p._lista_finanzas)
	for k2: String in proy["gastos"]:
		p._dato(k2, "−%s" % p._dinero(int(proy["gastos"][k2])), p.COL_ROJO, p._lista_finanzas)
	var nota := p._texto(10, p.COL_SUAVE)
	nota.text = Idiomas.t("La proyección solo cuenta lo fijo de la temporada: no incluye premios, copas, ventas de jugadores ni abonos.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_finanzas.add_child(nota)
	var pal := p._ui_ficha._paleta_ficha()
	PanelFinanzas.pintar_balance_y_caja(p._lista_finanzas, c, p.mundo, proy, pal)
	PanelFinanzas.pintar_auspicio(p._lista_finanzas, c, p.mundo, pal,
		func(idx: int) -> void: p._ui_gente._firmar_auspicio(idx))
	PanelFinanzas.pintar_patrocinio(p._lista_finanzas, c, p.mundo, pal,
		func(clave: String) -> void: p._ui_gente._lanzar_campana(clave),
		func() -> void: p._ui_gente._pujar_marca())
	PanelFinanzas.pintar_banco(p._lista_finanzas, c, p.mundo, pal,
		func(i: int) -> void: p._ui_gente._pedir_credito(i, c),
		func(i: int) -> void: p._ui_gente._prepagar(i, c),
		func(i: int) -> void: p._ui_gente._renegociar(i),
		func() -> void: p._ui_gente._emitir_bono(c))
	p._lista_finanzas.add_child(HSeparator.new())

	var t := p._texto(11, p.COL_SUAVE)
	t.text = Idiomas.t("RESUMEN")
	p._lista_finanzas.add_child(t)
	p._dato("Caja", p._dinero(c.saldo), p.COL_VERDE if c.saldo >= 0 else p.COL_ROJO, p._lista_finanzas)
	p._dato("Sueldos del plantel", p._dinero(c.masa_salarial()) + "/semana", p.COL_TEXTO, p._lista_finanzas)
	if p.mundo.staff != null:
		p._dato("Cuerpo técnico", p._dinero(p.mundo.staff.sueldo_semanal(c.rep)) + "/semana", p.COL_TEXTO, p._lista_finanzas)
	p._lista_finanzas.add_child(HSeparator.new())

	## Otra pieza que ya funcionaba y no se veía: `cobrar_plusvalias()` corre
	## sola cada temporada -Mundo.nueva_temporada()-, pero el porcentaje que te
	## guardaste al vender no aparecía en ningún sitio hasta que se cobraba solo.
	if p.mundo.cesiones != null and not p.mundo.cesiones.plusvalias.is_empty():
		var tpv := p._texto(11, p.COL_SUAVE)
		tpv.text = Idiomas.t("PLUSVALÍAS PENDIENTES")
		p._lista_finanzas.add_child(tpv)
		for pv: Dictionary in p.mundo.cesiones.plusvalias:
			if String(pv.get("beneficiario", "")) != c.id:
				continue
			var jact: Jugador = p.mundo.jugador_por_id(String(pv.get("pid", "")))
			var detalle := "ya no está en el p.mundo"
			if jact != null:
				var club_hoy: Club = p.mundo.clubes.get(jact.club_id)
				detalle = "hoy en %s · vale %s" % [club_hoy.nombre if club_hoy else "?", p._dinero(jact.valor)]
			p._dato("%s  (%d%%)" % [String(pv.get("nombre", "")), int(pv.get("pct", 0))], detalle, p.COL_SUAVE, p._lista_finanzas)
		p._lista_finanzas.add_child(HSeparator.new())

	var libro := p.mundo.libro_financiero
	var tm := p._texto(11, p.COL_SUAVE)
	tm.text = Idiomas.t("LIBRO DE MOVIMIENTOS  ·  últimos %d") % libro.size()
	p._lista_finanzas.add_child(tm)
	if libro.is_empty():
		var vacio := p._texto(12, p.COL_SUAVE)
		vacio.text = Idiomas.t("Todavía no hay movimientos aparte de la taquilla y los sueldos. Ficha, cede, contrata staff o levanta un título: todo lo que mueve la caja por fuera de la semana normal queda anotado aquí.")
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_finanzas.add_child(vacio)
		return
	for i in range(libro.size() - 1, -1, -1):
		var mov: Dictionary = libro[i]
		var monto := int(mov.get("monto", 0))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_finanzas.add_child(fila)
		var et := p._texto(11, p.COL_SUAVE)
		et.text = "S%d/%d" % [int(mov.get("semana", 0)), int(mov.get("anio", 0))]
		et.custom_minimum_size = Vector2(50, 0)
		fila.add_child(et)
		var co := p._texto(12, p.COL_TEXTO)
		co.text = String(mov.get("concepto", ""))
		co.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		co.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(co)
		var va := p._texto(12, p.COL_VERDE if monto >= 0 else p.COL_ROJO)
		va.text = ("+" if monto > 0 else "") + p._dinero(monto)
		fila.add_child(va)

## `vCamarin()` del HTML: clanes, salud mental y jerarquía interna. Toda la
## maquinaria -`Vestuario.camarillas`, `mente()`/`ansiedad()`, `mediar()`,
## `dar_terapia()`, `descanso_mental()`- ya estaba escrita y probada -la
## ansiedad ya se movía sola cada semana con `_proceso_mental()`, y `mediar()`
## ya la bajaba de verdad-, pero no había ni una fila en ningún sitio del
## juego que la enseñara: la nota de esta sesión que decía "la ansiedad no
## está portada" (escrita al tocar Ojeadores y la mesa de negociación) estaba
## mal -no se había mirado con suficiente cuidado-, y queda corregida aquí.
