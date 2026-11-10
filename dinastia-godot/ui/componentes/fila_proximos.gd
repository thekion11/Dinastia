class_name FilaProximos
extends RefCounted
## LA FILA DE LOS PRÓXIMOS PARTIDOS (9-11, idea del PES 2020: en el inicio de Master League, abajo, una fila de escudos con lo que viene).
## Debajo de la tira de días: los próximos N eventos de tu club (liga, copa, continental, mercado, fin de temporada; 10-11) y un botón 📅 con la vista de varias semanas.
const CUANTOS := 5

## Los próximos partidos de liga de `m.mi_club()`, desde la jornada que toca: [{jornada, rival, local}].
static func datos(m: Mundo, cuantos := CUANTOS) -> Array:
	var out: Array = []
	var mio := m.mi_club() if m != null else null
	if mio == null:
		return out
	var liga := m.liga_de(mio)
	if liga == null:
		return out
	var j := liga.jornada_actual
	while j < liga.calendario.size() and out.size() < cuantos:
		for par: Array in liga.calendario[j]:
			if par[0] == mio or par[1] == mio:
				var local: bool = par[0] == mio
				out.append({"jornada": j + 1, "rival": par[1] if local else par[0], "local": local})
				break
		j += 1
	return out

## Rehace el contenido de `caja` (un HBoxContainer): rótulo, un botón que abre la vista de varias semanas, y por evento una tarjeta (`TarjetaEvento`) más un
## hueco. Los eventos (`EventosFecha`) son partidos de liga, copa y continental, el mercado y el fin de temporada. El PRIMERO va resaltado en oro (es el que viene).
## `dia_hoy` (0-6) deja fuera lo que ya pasó de esta semana.
static func pintar(m: Mundo, caja: HBoxContainer, dia_hoy := 0) -> void:
	for h in caja.get_children():
		h.queue_free()
	var lista := EventosFecha.proximos(m, dia_hoy, CUANTOS)
	if lista.is_empty():
		return
	caja.add_theme_constant_override("separation", 6)
	var rot := Tema.etiqueta(Tema.TAM_ROTULO, Tema.oro(), Idiomas.t("PRÓXIMOS").to_upper())
	rot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	caja.add_child(rot)
	var ver := Button.new()
	ver.text = "📅"
	ver.tooltip_text = Idiomas.t("Ver las próximas semanas")
	ver.custom_minimum_size = Vector2(34, 30)
	## Estilo propio y compacto: el del tema, en el móvil, agranda el margen de los botones (`EscalaMovil.ampliar_toque`) y estiraba toda la fila
	## hasta sacar de la pantalla el botón «Plantel y cuerpo» (prueba especial `aud4_movil_partido`, 10-11).
	var est := Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.BORDE)
	est.set_content_margin_all(3)
	for estado: String in ["normal", "hover", "pressed", "focus"]:
		ver.add_theme_stylebox_override(estado, est)
	ver.pressed.connect(func() -> void: abrir_semanas(caja, m, dia_hoy))
	caja.add_child(ver)
	var primero := true
	for e: Dictionary in lista:
		caja.add_child(TarjetaEvento.crear(e, primero))
		primero = false
		var hueco := Control.new()
		hueco.custom_minimum_size = Vector2(2, 0)
		caja.add_child(hueco)

## Abre la vista de varias semanas (`CalendarioSemanas`, a pantalla completa) colgada de la raíz del juego. Se carga al pulsar: el menú no la compila al arrancar.
static func abrir_semanas(desde: Node, m: Mundo, dia_hoy := 0) -> void:
	var raiz: Node = desde
	while raiz.get_parent() != null and raiz.get_parent() != desde.get_tree().root:
		raiz = raiz.get_parent()
	(load("res://ui/componentes/calendario_semanas.gd") as GDScript).call("mostrar", raiz, m, dia_hoy)
