class_name PanelFinanzas
extends RefCounted
## Cuatro de los cinco bloques de la pestaña "Finanzas": balance y caja
## (solo lectura), la marca del pecho, las campañas publicitarias y el
## banco -las mismas 500+ líneas que el plan externo del 25-9 subestimaba
## como "~200 líneas"-. Medido y confirmado con grep antes de tocar nada,
## la misma disciplina que ya costó cara dos veces ese día.
##
## `_pintar_finanzas()` (el precio de entrada, la tienda, la proyección
## anual, el resumen y el libro de movimientos) SE QUEDA en `principal.gd`,
## igual que `_ver_ficha()` se quedó como orquestador de la ficha del
## jugador: es la función que decide el ORDEN de la pestaña entera y llama
## a las de aquí, no un bloque que se pueda pintar solo.
##
## MISMO PATRÓN QUE `FichaJugadorAcciones` (26-9-2026): clase estática con
## `Callable` para las acciones, no señales -se pinta una vez por refresco
## de la pestaña, sin ciclo de vida propio-. `pintar_balance_y_caja()` es
## la excepción: no tiene ni un botón, así que no recibe ningún `Callable`,
## igual que `TablaCompeticion`/`FichaJugadorInfo`.
##
## `paleta`: los mismos colores ya resueltos -`_color_accesible()`/`_pal_*()`,
## con `escala`- que reciben los demás componentes de esta carpeta.
##
## Los nombres se pintan tal cual: lo legal se resuelve en los DATOS (base
## ficticia por defecto, pack real opcional -ver `Datos`-), no en cada pantalla.

## BALANCE + FLUJO DE CAJA A 12 MESES. Puro: ni un botón, solo lee `c`,
## `mundo.banco` y la proyección que ya calculó `_pintar_finanzas()`.
static func pintar_balance_y_caja(lista: VBoxContainer, c: Club, mundo: Mundo,
		proy: Dictionary, paleta: Dictionary) -> void:
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "BALANCE"
	lista.add_child(t)
	var valor_plantel := 0
	for j in c.plantilla:
		valor_plantel += j.valor
	var valor_obras := 0
	if mundo.obras != null:
		for k: String in Instalaciones.CATALOGO:
			valor_obras += mundo.obras.nivel(k) * int((Instalaciones.CATALOGO[k] as Array)[2]) / 2
	var activo := c.saldo + valor_plantel + valor_obras
	_dato(lista, "Caja", _dinero(c.saldo), paleta["verde"] if c.saldo >= 0 else paleta["rojo"], paleta)
	_dato(lista, "Valor del plantel", _dinero(valor_plantel), paleta["texto"], paleta)
	_dato(lista, "Instalaciones", _dinero(valor_obras), paleta["texto"], paleta)
	_dato(lista, "TOTAL ACTIVO", _dinero(activo), paleta["oro"], paleta)
	var pasivo := 0
	if mundo.banco != null:
		for p: Dictionary in mundo.banco.prestamos:
			pasivo += int(p.get("deuda", 0))
	_dato(lista, "Pasivo exigible", _dinero(pasivo) if pasivo > 0 else "sin deuda",
		paleta["rojo"] if pasivo > 0 else paleta["suave"], paleta)
	_dato(lista, "PATRIMONIO NETO", _dinero(activo - pasivo),
		paleta["oro"] if activo - pasivo >= 0 else paleta["rojo"], paleta)
	var nota := _texto(10, paleta["suave"], paleta)
	if pasivo > 0:
		nota.text = "El pasivo es lo que queda por devolver de tus %d línea(s) de crédito. El patrimonio neto es lo que quedaría si hoy se liquidara todo." % mundo.banco.prestamos.size()
	else:
		nota.text = "Sin créditos abiertos: el activo entero es patrimonio. Pedir uno cambia esta línea al día siguiente."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(nota)

	lista.add_child(HSeparator.new())
	var tf := _texto(11, paleta["suave"], paleta)
	tf.text = "FLUJO DE CAJA A 12 MESES"
	lista.add_child(tf)
	var mensual := int(proy["resultado"]) / 12
	var saldo := c.saldo
	var minimo := saldo
	var mes_minimo := 0
	for m in 12:
		saldo += mensual
		if saldo < minimo:
			minimo = saldo
			mes_minimo = m + 1
	_dato(lista, "Dentro de 12 meses", _dinero(saldo), paleta["verde"] if saldo >= 0 else paleta["rojo"], paleta)
	_dato(lista, "Punto más bajo", "%s (mes %d)" % [_dinero(minimo), mes_minimo],
		paleta["rojo"] if minimo < 0 else paleta["texto"], paleta)
	if minimo < 0:
		var av := _texto(11, paleta["rojo"], paleta)
		av.text = "La caja se queda en negativo en el mes %d. Hay que vender, recortar sueldos o subir ingresos antes de llegar ahí." % mes_minimo
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(av)
	var gastos := int(proy["total_gastos"])
	var ratio := float(proy["total_ingresos"]) / float(maxi(1, gastos))
	_dato(lista, "Ratio de cobertura", "%.2f×" % ratio,
		paleta["verde"] if ratio >= 1.15 else (paleta["rojo"] if ratio < 1.0 else paleta["oro"]), paleta)

## LA MARCA DEL PECHO: el auspiciador activo, o las tres ofertas sobre la
## mesa si todavía no hay ninguno. `al_firmar` recibe el índice de la
## oferta elegida.
static func pintar_auspicio(lista: VBoxContainer, c: Club, mundo: Mundo,
		paleta: Dictionary, al_firmar: Callable) -> void:
	var a := mundo.auspicio
	if a == null:
		return
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "👕 LA MARCA DEL PECHO"
	lista.add_child(t)

	if not a.contrato.is_empty():
		var marca := String(a.contrato.get("marca", ""))
		var color_hex := String(a.contrato.get("color", "#e8b13a"))
		var col := Color(color_hex)
		var fila_marca := HBoxContainer.new()
		fila_marca.add_theme_constant_override("separation", 8)
		lista.add_child(fila_marca)
		fila_marca.add_child(_marca(marca, color_hex, 32, paleta))
		var n := _texto(14, col, paleta)
		n.text = marca
		fila_marca.add_child(n)
		_dato(lista, "Aporte de la temporada", _dinero(int(a.contrato.get("monto", 0))), paleta["verde"], paleta)
		_dato(lista, "Entra cada semana", _dinero(a.semanal()), paleta["verde"], paleta)
		var pedido := int(a.contrato.get("exig_pos", 0))
		var puesto := _puesto_en_liga(c, mundo)
		var cumple := puesto > 0 and puesto <= pedido
		_dato(lista, "Exigencia contractual", "terminar top %d de la liga" % pedido, paleta["texto"], paleta)
		_dato(lista, "Ahora mismo vas", "%d.º — %s" % [puesto, "cumpliendo" if cumple else "por debajo"],
			paleta["verde"] if cumple else paleta["rojo"], paleta)
		var av := _texto(10, paleta["suave"], paleta)
		av.text = "Si no cumples la exigencia, las ofertas del próximo año llegan un 30% más flacas."
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(av)
		return

	if a.ofertas.is_empty():
		var vac := _texto(11, paleta["suave"], paleta)
		vac.text = "Sin auspiciador esta temporada. Las marcas vuelven a golpear la puerta en la pretemporada."
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(vac)
		return

	var ex := _texto(10, paleta["suave"], paleta)
	ex.text = "Tres marcas sobre la mesa. La que más paga suele ser también la que más pide, y solo se luce una: al firmar, las otras se retiran."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(ex)
	for i in a.ofertas.size():
		var o: Dictionary = a.ofertas[i]
		var idx := i
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		lista.add_child(fila)
		fila.add_child(_marca(String(o.get("marca", "")), String(o.get("color", "#e8b13a")), 22, paleta))
		var n2 := _texto(12, Color(String(o.get("color", "#e8b13a"))), paleta)
		n2.text = String(o.get("marca", ""))
		n2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n2.clip_text = true
		n2.tooltip_text = "Exigencia: terminar top %d de la liga" % int(o.get("exig_pos", 0))
		fila.add_child(n2)
		var m2 := _texto(12, paleta["texto"], paleta)
		m2.text = _dinero(int(o.get("monto", 0)))
		m2.custom_minimum_size = Vector2(96, 0)
		fila.add_child(m2)
		var e2 := _texto(11, paleta["suave"], paleta)
		e2.text = "top %d" % int(o.get("exig_pos", 0))
		e2.custom_minimum_size = Vector2(52, 0)
		fila.add_child(e2)
		var b := Button.new()
		b.text = "Firmar"
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(80, 0)
		b.pressed.connect(func() -> void: al_firmar.call(idx))
		fila.add_child(b)

## CAMPAÑAS PUBLICITARIAS + LA GUERRA DE MARCAS. `al_lanzar_campana` recibe
## la clave de la campaña elegida; `al_ir_a_por_marca` no lleva argumentos.
static func pintar_patrocinio(lista: VBoxContainer, c: Club, mundo: Mundo,
		paleta: Dictionary, al_lanzar_campana: Callable, al_ir_a_por_marca: Callable) -> void:
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "📣 CAMPAÑAS PUBLICITARIAS"
	lista.add_child(t)
	var ex := _texto(10, paleta["suave"], paleta)
	ex.text = "Una por temporada. No dan dinero directo: mueven socios, ánimo y seguidores."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(ex)
	if mundo.campana_lanzada_este_anio():
		var d := Finanzas.def_campana(String(mundo.campana.get("clave", "")))
		var ya := _texto(12, paleta["verde"], paleta)
		ya.text = "✔ Ya lanzada este año: %s. La próxima, la temporada que viene." % (String(d[1]) if not d.is_empty() else "")
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(ya)
	else:
		for f: Array in Finanzas.CAMPANAS:
			var clave := String(f[0])
			var coste := Eco.escalar(float(f[3]), float(c.rep))
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			lista.add_child(fila)
			var n := _texto(12, paleta["texto"], paleta)
			n.text = "%s  —  %s" % [String(f[1]), String(f[2])]
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n.clip_text = true
			fila.add_child(n)
			var b := Button.new()
			b.text = _dinero(coste)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = c.saldo < coste
			b.custom_minimum_size = Vector2(90, 0)
			b.pressed.connect(func() -> void: al_lanzar_campana.call(clave))
			fila.add_child(b)

	var rival := mundo.rival_de_marcas()
	if rival == null:
		return
	var tg := _texto(11, paleta["rojo"], paleta)
	tg.text = "⚔️ GUERRA DE MARCAS"
	lista.add_child(tg)
	var dg := _texto(11, paleta["suave"], paleta)
	dg.text = "Puedes ir a por el patrocinador de %s. Si sale, firmas mejor y a ellos les duele. Si falla, pierdes el dinero y se enteran igual." % rival.nombre
	dg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(dg)
	var coste_g := mundo.coste_guerra_marcas()
	_dato(lista, "Coste de la operación", _dinero(coste_g), paleta["texto"] if c.saldo >= coste_g else paleta["rojo"], paleta)
	_dato(lista, "Probabilidad estimada", "%d%%" % int(round(mundo.probabilidad_guerra_marcas() * 100.0)),
		paleta["texto"], paleta)
	var bg := Button.new()
	bg.text = "⚔️ Ir a por su patrocinador"
	bg.disabled = c.saldo < coste_g
	bg.pressed.connect(al_ir_a_por_marca)
	lista.add_child(bg)
	var np := _texto(10, paleta["suave"], paleta)
	np.text = "Un palco mejor sube tus opciones: ahí es donde se cierran estas cosas."
	np.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(np)

## EL BANCO: estado, créditos vigentes, líneas disponibles y el bono
## social. Cuatro acciones distintas, cuatro `Callable`.
static func pintar_banco(lista: VBoxContainer, c: Club, mundo: Mundo, paleta: Dictionary,
		al_pedir_credito: Callable, al_prepagar: Callable, al_renegociar: Callable,
		al_emitir_bono: Callable) -> void:
	var b := mundo.banco
	if b == null:
		return
	lista.add_child(HSeparator.new())
	var e: Dictionary = b.estado(c)
	var col: Color = paleta["verde"]
	if String(e["color"]) == "ambar":
		col = paleta["oro"]
	elif String(e["color"]) == "rojo":
		col = paleta["rojo"]
	var t := _texto(14, col, paleta)
	t.text = "🏦 %s" % String(e["estado"])
	lista.add_child(t)
	var d := _texto(11, paleta["suave"], paleta)
	d.text = String(e["texto"])
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(d)
	if b.semanas_en_rojo > 0:
		_dato(lista, "Semanas en rojo", "%d de %d" % [b.semanas_en_rojo, Banco.SEM_LIQUIDACION], paleta["rojo"], paleta)

	if not b.prestamos.is_empty():
		var tv := _texto(11, paleta["suave"], paleta)
		tv.text = "CRÉDITOS VIGENTES  ·  %d de %d" % [b.prestamos.size(), Banco.MAX_PRESTAMOS]
		lista.add_child(tv)
		for i in b.prestamos.size():
			var p: Dictionary = b.prestamos[i]
			var l := _texto(12, paleta["texto"], paleta)
			l.text = "%s  ·  cuota %s/sem  ·  %d restantes  ·  debes %s" % [
				String(p["banco"]), _dinero(int(p["cuota"])), int(p["restan"]), _dinero(int(p["deuda"]))]
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lista.add_child(l)
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			lista.add_child(fila)
			var idx := i
			var bp := Button.new()
			bp.text = "Prepagar  %s" % _dinero(int(p["deuda"]))
			bp.add_theme_font_size_override("font_size", 11)
			bp.disabled = c.saldo < int(p["deuda"])
			bp.pressed.connect(func() -> void: al_prepagar.call(idx))
			fila.add_child(bp)
			if not bool(p["renegociado"]):
				var br := Button.new()
				br.text = "Renegociar (baja la cuota, sube la tasa)"
				br.add_theme_font_size_override("font_size", 11)
				br.clip_text = true
				br.custom_minimum_size = Vector2(150, 0)
				br.pressed.connect(func() -> void: al_renegociar.call(idx))
				fila.add_child(br)

	var tl := _texto(11, paleta["suave"], paleta)
	tl.text = "LÍNEAS DISPONIBLES"
	lista.add_child(tl)
	for i2 in Banco.BANCOS.size():
		var f: Array = Banco.BANCOS[i2]
		var monto := Banco.monto_linea(i2, c)
		var cuota := Banco.cuota_francesa(monto, float(f[1]), int(f[2]))
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 6)
		lista.add_child(fila2)
		var n := _texto(12, paleta["texto"], paleta)
		n.text = "%s  ·  %s  ·  %d cuotas de %s  ·  %.1f%%/sem" % [
			String(f[0]), _dinero(monto), int(f[2]), _dinero(cuota), float(f[1]) * 100.0]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila2.add_child(n)
		var idx2 := i2
		var bt := Button.new()
		bt.text = "Tomar"
		bt.add_theme_font_size_override("font_size", 11)
		bt.disabled = b.prestamos.size() >= Banco.MAX_PRESTAMOS or b.en_mora()
		bt.custom_minimum_size = Vector2(80, 0)
		bt.pressed.connect(func() -> void: al_pedir_credito.call(idx2))
		fila2.add_child(bt)
	var nota := _texto(10, paleta["suave"], paleta)
	nota.text = "La cuota se descuenta sola cada semana, llueva o truene. Dos créditos como mucho, y en mora no hay ventanilla."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(nota)

	var tb := _texto(11, paleta["acento"], paleta)
	tb.text = "🎗️ BONO SOCIAL"
	lista.add_child(tb)
	var db := _texto(10, paleta["suave"], paleta)
	db.text = "La hinchada compra deuda del club a tasa baja, incluso en mora. Más barato que un banco, pero si el club se liquida sin pagarlo, la afición no lo olvida."
	db.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(db)
	var bb := Button.new()
	bb.text = "Emitir bono social"
	bb.disabled = b.prestamos.size() >= Banco.MAX_PRESTAMOS
	bb.pressed.connect(al_emitir_bono)
	lista.add_child(bb)

## En qué puesto va el club en su liga. Cero si todavía no juega ninguna.
## Calcado de `Principal._liga_de()`/`_puesto_en_liga()` -pura, solo lee
## `mundo`, sin ningún estado de pantalla-, para que `pintar_auspicio()` no
## necesite que Principal se la calcule antes y se la pase aparte.
static func _puesto_en_liga(c: Club, mundo: Mundo) -> int:
	var l: Liga = mundo.ligas[0]
	for candidata in mundo.ligas:
		if candidata.clubes.has(c):
			l = candidata
			break
	var n := 0
	for f: Dictionary in l.tabla():
		n += 1
		if f["club"] == c:
			return n
	return 0

# ── HELPERS DE UI, duplicados a propósito de `principal.gd` ────────────────
static func _texto(tam: int, color: Color, paleta: Dictionary) -> Label:
	var l := Label.new()
	var escala: float = float(paleta.get("escala", 1.0))
	l.add_theme_font_size_override("font_size", maxi(8, int(round(float(tam) * escala))))
	l.add_theme_color_override("font_color", color)
	return l

static func _dato(padre: Node, etiqueta: String, valor: String, color: Color, paleta: Dictionary) -> void:
	var h := HBoxContainer.new()
	var a := _texto(12, paleta["suave"], paleta)
	a.text = etiqueta
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.clip_text = true
	a.tooltip_text = etiqueta
	h.add_child(a)
	var b := _texto(12, color, paleta)
	b.text = valor
	h.add_child(b)
	padre.add_child(h)

## Blanco o negro sobre el color del logo, calcado de `Principal._tinta()`.
static func _tinta(fondo: Color) -> Color:
	var lum := 0.299 * fondo.r + 0.587 * fondo.g + 0.114 * fondo.b
	return Color("0c130e") if lum > 0.59 else Color("ffffff")

## El logo de un sponsor, calcado de `Principal._marca()`.
static func _marca(nombre: String, color_hex: String, alto: int, paleta: Dictionary) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	var t := TextureRect.new()
	t.texture = Marca.textura(nombre, color_hex, alto)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := _texto(0, _tinta(Color(color_hex)), paleta)
	l.text = Marca.iniciales(nombre)
	l.add_theme_font_size_override("font_size", maxi(8, alto / 2 - 2))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(l)
	return caja

## Calcado de `Principal._dinero()`, con el mismo factor `Eco.ECO` -la
## lección del bug real encontrado en `FichaJugadorAcciones` el 26-9: sin
## este factor los montos salen mal sin ningún error visible.
static func _dinero(monto: int) -> String:
	return Eco.dinero(monto)
