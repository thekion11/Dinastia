class_name FichaJugadorAcciones
extends RefCounted
## Los cinco bloques CON BOTONES de la ficha de un jugador: desarrollo
## prioritario, reconversión de puesto, marca personal (cláusula de
## fidelidad), jugadores similares y las dos puertas de salida (vender,
## rescindir). Es el complemento de `FichaJugadorInfo` (los bloques de solo
## lectura) -las cinco que faltaban de las 14 originales, después de medir el
## subsistema entero el 25-9-2026 y decidir NO moverlas todas de una vez.
##
## PATRÓN NUEVO, NI EL DE `PanelMercado` NI EL DE `TablaCompeticion` (26-9-2026,
## continuando el mismo pedido de fragilidad): estas funciones SÍ tienen
## botones -a diferencia de `TablaCompeticion`/`FichaJugadorInfo`, que son
## puro pintado-, pero NO son un nodo de escena vivo como `PanelMercado`: se
## llaman una vez por cada `_ver_ficha()`, pintan y se olvidan, no hay ciclo
## de vida que gestionar. Por eso, en vez de señales -que exigirían instanciar
## un nodo solo para escuchar eventos que van a disparar una sola vez-, reciben
## los propios `Callable` de la acción como parámetro. Principal sigue siendo
## dueño de TODA la lógica de mutación (`_reconvertir`, `_rescindir`,
## `_listar_transferible`, que tocan moral, prensa, agentes y confianza de
## vestuario -es lógica de juego, no de pantalla, y moverla de sitio sin venir
## a cuento sería el mismo riesgo que ya se evitó con el resto de la ficha-);
## esta clase solo arma el botón y llama al `Callable` cuando se pulsa.
##
## `paleta`: los mismos colores ya resueltos que reciben `TablaCompeticion` y
## `FichaJugadorInfo` -`_color_accesible()`/`_pal_*()`, con `escala`-.
##
## Los nombres se pintan tal cual: lo legal se resuelve en los DATOS (base
## ficticia por defecto, pack real opcional -ver `Datos`-), no en cada pantalla.

## Desarrollo prioritario -togglePrioridad() del HTML-: menores de 24. El
## único botón de este bloque, así que un solo `Callable` sin argumentos.
static func pintar_desarrollo(lista: VBoxContainer, j: Jugador, mundo: Mundo,
		al_pulsar: Callable) -> void:
	if mundo.entrenamiento == null or j.edad >= 24:
		return
	var en_plan := mundo.entrenamiento.es_prioritario(j)
	var b := Button.new()
	b.text = "★ En el plan de desarrollo (quitar)" if en_plan else "Sumar al desarrollo prioritario"
	b.pressed.connect(al_pulsar)
	lista.add_child(b)

## `🔁 POSICIÓN Y RECONVERSIÓN`: un botón por cada puesto del mismo lado de la
## cancha. `al_elegir` recibe el puesto de destino -son varios botones, no uno,
## así que hace falta el parámetro-.
static func pintar_reconversion(lista: VBoxContainer, j: Jugador, mundo: Mundo,
		paleta: Dictionary, al_elegir: Callable) -> void:
	var posd: Dictionary = Datos.tabla("POSD")
	if posd.is_empty():
		return
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "🔁 POSICIÓN Y RECONVERSIÓN"
	lista.add_child(t)
	_dato(lista, "Puesto natural", String((posd.get(j.pos_e, {}) as Dictionary).get("n", j.pos_e)), paleta["texto"], paleta)
	if not j.pos_sec.is_empty():
		_dato(lista, "También puede jugar de", ", ".join(j.pos_sec), paleta["suave"], paleta)
	var nota := _texto(10, paleta["suave"], paleta)
	nota.text = "Rendimiento estimado en cada puesto. Reconvertirlo es permanente y le cuesta unas semanas asentarse."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(nota)
	var es_por := String((posd.get(j.pos_e, {}) as Dictionary).get("g", "")) == "POR"
	var flow := HFlowContainer.new()
	lista.add_child(flow)
	for pe: String in posd.keys():
		if pe == j.pos_e:
			continue
		var d: Dictionary = posd[pe]
		if (String(d.get("g", "")) == "POR") != es_por:
			continue
		var b := Button.new()
		b.text = "%s · %d" % [pe, j.media_en_puesto(pe)]
		b.tooltip_text = String(d.get("n", pe))
		b.clip_text = true
		b.custom_minimum_size = Vector2(64, 0)
		b.add_theme_font_size_override("font_size", 11)
		var destino := pe
		b.pressed.connect(func() -> void: al_elegir.call(destino))
		flow.add_child(b)

## Ídolo de la afición y marca personal, con la cláusula de fidelidad si
## corresponde -el único botón, condicional-.
static func pintar_marca(lista: VBoxContainer, j: Jugador, mio: Club, mundo: Mundo,
		paleta: Dictionary, al_pedir_fidelidad: Callable) -> void:
	lista.add_child(HSeparator.new())
	var idolo := mundo.idolo_aproximado(j)
	var es_idolo := idolo >= 62
	_dato(lista, "Ídolo de la afición", "%d/100%s" % [idolo, " ⭐" if es_idolo else ""],
		paleta["oro"] if es_idolo else paleta["suave"], paleta)
	var habs := mundo.entrenamiento.habilidades(j).size() if mundo.entrenamiento != null else 0
	var marca := Mundo.marca_personal(j, idolo, habs)
	var etiqueta_marca := "📣 muy mediático" if marca >= 80 else ("📸 vende camisetas" if marca >= 55 else "")
	_dato(lista, "Marca personal", ("%d/100 %s" % [marca, etiqueta_marca]) if etiqueta_marca != "" else "%d/100" % marca, paleta["texto"], paleta)
	if j.fidelidad_hasta > 0:
		_dato(lista, "Cláusula de fidelidad", "hasta %d" % j.fidelidad_hasta, paleta["verde"], paleta)
	elif j.edad >= 23 and j.ovr >= 66 and mundo.cantera != null:
		var costo := int(round(float(j.sueldo) * 26.0))
		var b := Button.new()
		b.text = "Cláusula de fidelidad  %s" % _dinero(costo)
		b.tooltip_text = "Prima ahora a cambio de tres años sin que pida salida."
		b.disabled = costo > mio.saldo
		b.pressed.connect(al_pedir_fidelidad)
		lista.add_child(b)

## `similares()` del HTML: mismo puesto, edad y nivel parecidos -el plan B si
## se cae la operación-. `al_elegir` recibe el jugador similar elegido, para
## que Principal navegue a SU ficha.
static func pintar_similares(lista: VBoxContainer, j: Jugador, mio: Club, mundo: Mundo,
		paleta: Dictionary, al_elegir: Callable) -> void:
	var candidatos: Array[Jugador] = []
	for c: Club in mundo.clubes.values():
		if c.id == mio.id:
			continue
		for x in c.plantilla:
			if x.id == j.id or x.pos_e != j.pos_e:
				continue
			if absi(x.edad - j.edad) <= 2 and absi(x.ovr - j.ovr) <= 3:
				candidatos.append(x)
	if candidatos.is_empty():
		return
	## Los más parecidos primero: la distancia es media y edad juntas, porque un
	## clon de 30 años no es un plan B para un chico de 22.
	candidatos.sort_custom(func(a: Jugador, b: Jugador) -> bool:
		return absi(a.ovr - j.ovr) * 2 + absi(a.edad - j.edad) < absi(b.ovr - j.ovr) * 2 + absi(b.edad - j.edad))
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "JUGADORES SIMILARES"
	lista.add_child(t)
	for i in mini(6, candidatos.size()):
		var s: Jugador = candidatos[i]
		var club_s: Club = mundo.clubes.get(s.club_id)
		var b := Button.new()
		b.text = "%s  ·  %d años  ·  %s  ·  %s" % [
			s.nombre, s.edad, club_s.nombre if club_s else "libre",
			mundo.ojeadores.ovr_texto(s) if mundo.ojeadores != null else str(s.ovr)]
		b.add_theme_font_size_override("font_size", 11)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		## SIN `clip_text` un Button pide de ancho mínimo lo que mida su texto,
		## y el panel entero se sale de la ventana -ya se vio en captura una vez.
		b.clip_text = true
		b.custom_minimum_size = Vector2(120, 0)
		var quien := s
		b.pressed.connect(func() -> void: al_elegir.call(quien))
		lista.add_child(b)
	var nota := _texto(10, paleta["suave"], paleta)
	nota.text = "Mismo puesto, edad y nivel parecidos: por si se cae la operación o quieres comparar precio."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(nota)

## Las dos puertas de SALIDA de un jugador tuyo. `confirmando_id` es
## `Principal._confirmar_rescision_id` -el doble-toque de "¿seguro?" para
## rescindir vive en Principal, esta función solo LEE si el jugador que está
## pintando es el que está en confirmación, para pintar el botón en rojo de
## advertencia o no-.
static func pintar_venta(lista: VBoxContainer, j: Jugador, mio: Club, mundo: Mundo,
		paleta: Dictionary, confirmando_id: String,
		al_sacar_de_lista: Callable, al_poner_en_venta: Callable,
		al_rescindir: Callable) -> void:
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "VENDER"
	lista.add_child(t)
	var r := mundo.roles
	var motivo_venta := "" if r == null or r.puede_vender_jugadores() else String(r.motivo_bloqueo("vender_jugadores"))
	if motivo_venta != "":
		var no := _texto(11, paleta["suave"], paleta)
		no.text = motivo_venta
		no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(no)
	elif j.transferible:
		_dato(lista, "Estado", "en la lista de transferibles", paleta["oro"], paleta)
		_boton(lista, "Sacarlo de la lista", al_sacar_de_lista)
	else:
		_boton(lista, "Poner en venta", al_poner_en_venta)

	## Porcentaje pactado de su próxima venta.
	if mundo.cesiones != null:
		var pv := mundo.cesiones.porcentaje_pendiente(j.id)
		if not pv.is_empty() and int(pv.get("pct", 0)) > 0:
			var club_pv: Club = mundo.clubes.get(String(pv.get("club", "")))
			_dato(lista, "Porcentaje pactado de su próxima venta",
				"%d%% para %s" % [int(pv["pct"]), club_pv.nombre if club_pv else "su club anterior"], paleta["rojo"], paleta)
	## Negociación congelada tras romperse una mesa.
	if j.no_negociar_hasta > 0 and mundo.semana < j.no_negociar_hasta:
		_dato(lista, "Negociación congelada", "hasta la semana %d" % j.no_negociar_hasta, paleta["suave"], paleta)

	if mundo.cantera == null:
		return
	lista.add_child(HSeparator.new())
	var tr := _texto(11, paleta["suave"], paleta)
	tr.text = "RESCINDIR CONTRATO"
	lista.add_child(tr)
	var motivo_resc := "" if r == null or r.puede_rescindir() else String(r.motivo_bloqueo("rescindir"))
	if motivo_resc != "":
		var nr := _texto(11, paleta["suave"], paleta)
		nr.text = motivo_resc
		nr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(nr)
		return
	if mio.plantilla.size() <= 18:
		var av := _texto(11, paleta["rojo"], paleta)
		av.text = "Plantel muy corto: no puedes bajar de 18 fichas."
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(av)
		return
	var coste: Dictionary = mundo.cantera.coste_rescision(j)
	var total := int(coste["total"])
	_dato(lista, "Finiquito", _dinero(int(coste["finiquito"])), paleta["suave"], paleta)
	_dato(lista, "Comisión de salida del agente", _dinero(int(coste["comision"])), paleta["suave"], paleta)
	var confirmando := confirmando_id == j.id
	var br := Button.new()
	br.text = "¿Seguro? Pulsa de nuevo para confirmar" if confirmando else "Rescindir  %s" % _dinero(total)
	br.disabled = total > mio.saldo
	br.pressed.connect(al_rescindir)
	lista.add_child(br)

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

static func _boton(padre: Node, texto: String, accion: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(accion)
	padre.add_child(b)

## BUG REAL, ENCONTRADO ANTES DE VERIFICAR (26-9-2026): el primer intento de
## duplicar esto usaba un formato inventado ($X/XK/X.XM) sin la conversión
## `Eco.ECO` que aplica el `_dinero()` real de `principal.gd` -las cifras
## internas del juego no son euros directos, hay un factor de escala-. Habría
## mostrado montos EQUIVOCADOS en "Cláusula de fidelidad" y "Rescindir", sin
## que nada avisara: el código compila igual, el número solo está mal. Se
## corrigió calcándolo del original ANTES de correr una sola captura.
static func _dinero(monto: int) -> String:
	var euros := float(monto) * Eco.ECO
	if absf(euros) >= 1000000.0:
		return "%.1fM EUR" % (euros / 1000000.0)
	if absf(euros) >= 1000.0:
		return "%dk EUR" % int(euros / 1000.0)
	return "%d EUR" % int(euros)
