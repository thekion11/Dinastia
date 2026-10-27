extends "res://ui/componentes/telefono_p2.gd"
## [Capa 3/4 de `telefono.gd`] restaurar_marcas, _unhandled_input, atras, _tras_abrir, enfocar, _estilo_aviso … (+4)

## PULIDO DEL MÓVIL (25-10-2026, paquete uite):
##   - TECLADO Y MANDO: Esc / B da un paso atrás (del chat a Mensajes, de una pestaña de Tribuna a su
##     inicio, de una app a la pantalla de inicio y, desde ahí, guarda el móvil). Al abrir y al cambiar
##     de app el foco cae en el primer botón útil, sin mostrar el recuadro hasta que se navega con
##     flechas: antes el foco se quedaba en la pantalla de DETRÁS del móvil y el mando movía lo que no
##     se veía.
##   - TRANSICIONES: cada app entra con un fundido corto; el móvil sube y aparece al abrirse y se
##     desvanece al guardarse (con «Animaciones reducidas» todo es instantáneo).

## NOMBRE PROPIO DE LA RED SOCIAL (cierre de la sesión 2): «Tribuna» es también la tribuna del
## estadio, que se traduce («Stand», «Tribüne»…); como `Idiomas` traduce por la frase sin contexto, la
## app acabaría llamándose «Stand» en inglés. Las etiquetas de la marca llevan esta meta y se dejan
## como están tras pasar el traductor por el árbol (se ponen en telefono_p1, capa de abajo, con el
## mismo texto de clave).
const META_MARCA := "marca_sin_traducir"

## Devuelve a las marcas su texto original tras `Idiomas.traducir_arbol`.
static func restaurar_marcas(raiz: Node) -> void:
	for n in raiz.find_children("*", "Label", true, false):
		if n.has_meta(META_MARCA):
			(n as Label).text = String(n.get_meta(META_MARCA))

## Qué hacer cuando, ya en la pantalla de inicio, se pide «atrás». Lo pone quien abre el móvil.
var al_cerrar: Callable
var _tw_app: Tween

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") and is_visible_in_tree() and atras():
		Sonido.toca("menu_atras", Sonido.Bus.INTERFAZ)
		get_viewport().set_input_as_handled()

## Un paso atrás. Devuelve false si no había adónde volver, para que el Esc le sirva a la pantalla de debajo.
func atras() -> bool:
	if _app == "mensajes" and _chat != "":
		_chat = ""
		(self as Telefono).abrir_app("mensajes")
	elif _app == "tribuna" and _sub != "inicio" and m.redes.sesion != "":
		_sub = "inicio"
		(self as Telefono).abrir_app("tribuna")
	elif _app != "inicio":
		(self as Telefono).abrir_app("inicio")
	elif al_cerrar.is_valid():
		al_cerrar.call()
	else:
		return false
	return true

## Lo que pasa cada vez que se pinta una app: el fundido de entrada y el foco.
func _tras_abrir() -> void:
	if not is_inside_tree():
		return
	if _tw_app != null and _tw_app.is_valid():
		_tw_app.kill()
	if Animar.reducidas():
		_cuerpo.modulate.a = 1.0
	else:
		_cuerpo.modulate.a = 0.0
		_tw_app = _cuerpo.create_tween()
		_tw_app.tween_property(_cuerpo, "modulate:a", 1.0, 0.16).set_ease(Tween.EASE_OUT)
	## Solo si el foco era del móvil (o de nadie: el botón enfocado se acaba de borrar). Si lo tiene
	## otra cosa -los botones de la casa 3D, junto al móvil-, no se lo roba.
	var dueno := get_viewport().gui_get_focus_owner()
	if dueno == null or is_ancestor_of(dueno):
		enfocar.call_deferred()

## Pone el foco en el primer botón útil de la app (el «‹ atrás» solo si no hay otro). `hide_focus`:
## el recuadro no se ve hasta que el jugador navega con teclado o mando.
func enfocar() -> void:
	if not is_inside_tree():
		return
	var atras_b: Button = null
	for n in _cuerpo.find_children("*", "Button", true, false):
		var b := n as Button
		if b.is_queued_for_deletion() or not b.is_visible_in_tree() or b.disabled or b.focus_mode == Control.FOCUS_NONE:
			continue
		if b.text == "‹":
			if atras_b == null:
				atras_b = b
			continue
		b.grab_focus(true)
		return
	if atras_b != null:
		atras_b.grab_focus(true)

## La píldora del aviso de arriba: fondo oscuro, esquinas redondas y filo de color a la izquierda.
static func _estilo_aviso() -> StyleBoxFlat:
	## Radio pequeño: con 12 el filo izquierdo se curvaba como un paréntesis pegado al icono.
	var sb := Tema.caja(Color(0.05, 0.06, 0.08, 0.94), 5, Tema.ORO)
	sb.set_border_width_all(0)
	sb.border_width_left = 3
	sb.content_margin_left = 14
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.expand_margin_left = -8
	sb.expand_margin_right = -8
	return sb

## El móvil a pantalla completa aparece (fondo que se oscurece y aparato que sube un poco) o se va.
static func animar_pop(pop: Control, tel: Control, entrando: bool, luego: Callable = Callable()) -> void:
	if Animar.reducidas() or not pop.is_inside_tree():
		pop.modulate.a = 1.0 if entrando else 0.0
		if luego.is_valid():
			luego.call()
		return
	tel.pivot_offset = tel.size * 0.5 if tel.size != Vector2.ZERO else Vector2(Telefono.ANCHO * 0.5, 390.0)
	var tw := pop.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if entrando else Tween.EASE_IN)
	if entrando:
		pop.modulate.a = 0.0
		tel.scale = Vector2(0.94, 0.94)
	tw.tween_property(pop, "modulate:a", 1.0 if entrando else 0.0, 0.2 if entrando else 0.14)
	tw.tween_property(tel, "scale", Vector2.ONE if entrando else Vector2(0.96, 0.96), 0.22 if entrando else 0.14)
	if luego.is_valid():
		tw.chain().tween_callback(luego)

# --- agenda (fase 3 del plan del lunes, 26-10-2026) ------------------------------------------------
## Día y hora del reloj de la partida, lo próximo que toca y «Adelantar» con la rutina
## (`Reloj.avanzar_con_rutina`: duermes y comes como siempre, así el hambre no se dispara).

func _agenda() -> void:
	_titulo_app("Agenda")
	var r: Reloj = m.reloj
	r._al_dia()
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(TARJETA, 12, TARJETA))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	caja.add_child(v)
	var hora := Tema.etiqueta(46, Tema.TEXTO, r.texto_hora())
	hora.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hora)
	var dia := Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO, "%s · %s %d" % [Idiomas.t(VidaCiudad.DIAS[clampi(r.dia, 0, 6)]), Idiomas.t("Semana"), m.semana])
	dia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dia)
	_cuerpo.add_child(caja)
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Tema.ORO, Idiomas.t("LO PRÓXIMO")))
	for linea: String in _proximos(r):
		_cuerpo.add_child(_nota(linea))
	## Las citas en persona (fase 4): quién, cuándo y «Ir» (la flecha del paseo te lleva).
	if m.citas != null and not m.citas.pendientes().is_empty():
		_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Tema.ORO, Idiomas.t("CITAS")))
		for ct: Dictionary in m.citas.pendientes():
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			var txt := _nota("%s · %s\n%s" % [String(ct["quien"]), String(ct["cargo"]), m.citas.cuando(ct)])
			txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(txt)
			var ir := Button.new()
			ir.text = Idiomas.t("Guiando") if m.citas.objetivo == String(ct["id"]) else Idiomas.t("Ir")
			ir.custom_minimum_size = Vector2(90, 40)
			ir.pressed.connect(func() -> void:
				m.citas.objetivo = "" if m.citas.objetivo == String(ct["id"]) else String(ct["id"])
				(self as Telefono).abrir_app("agenda"))
			fila.add_child(ir)
			_cuerpo.add_child(fila)
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Tema.ORO, Idiomas.t("ADELANTAR")))
	for par: Array in [["1h", "⏩ Una hora"], ["manana", "🌅 Hasta mañana a las 08:00"], ["partido", "⚽ Hasta el partido"]]:
		var b := Button.new()
		b.text = Idiomas.t(String(par[1]))
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(_adelantar.bind(String(par[0])))
		_cuerpo.add_child(b)
	_cuerpo.add_child(_nota(Idiomas.t("El tiempo adelantado sigue tu rutina: duermes y comes como siempre.")))
	## Convocar una rueda de prensa extra (fase 4, bloque 6): una por semana.
	if m.citas != null:
		var rp := Button.new()
		rp.text = Idiomas.t("📣 Convocar rueda de prensa")
		rp.custom_minimum_size = Vector2(0, 40)
		rp.pressed.connect(func() -> void:
			var motivo := m.citas.convocar_rueda(m)
			_decir(Idiomas.t("Rueda convocada: la respondes en el PC.") if motivo == "" else Idiomas.t(motivo)))
		_cuerpo.add_child(rp)

## Entrenamiento (laborables a las 10:00), partido (sábado) y rueda de prensa (viernes).
func _proximos(r: Reloj) -> Array[String]:
	var sal: Array[String] = []
	if r.dia <= 4:
		sal.append(Idiomas.t("Entrenamiento: %s a las 10:00") % (Idiomas.t("hoy") if r.hora() < 10 else Idiomas.t("mañana")))
	var prox := m.proximo_partido()
	if prox.size() >= 2 and r.dia <= 5:
		sal.append(Idiomas.t("Partido: sábado a las %02d:00 · %s - %s") % [VidaCiudad.HORA_PARTIDO, (prox[0] as Club).nombre, (prox[1] as Club).nombre])
	if r.dia <= 4:
		sal.append(Idiomas.t("Rueda de prensa: viernes a las 12:00"))
	if sal.is_empty():
		sal.append(Idiomas.t("Fin de semana: nada en la agenda. Descansa."))
	return sal

func _adelantar(que: String) -> void:
	var r: Reloj = m.reloj
	var ahora := r.dia * Reloj.MINUTOS_DIA + r.minuto
	var mins := 0
	match que:
		"1h": mins = Reloj.MINUTOS_HORA
		"manana": mins = (r.dia + 1) * Reloj.MINUTOS_DIA + Reloj.HORA_INICIO * Reloj.MINUTOS_HORA - ahora
		"partido": mins = 5 * Reloj.MINUTOS_DIA + VidaCiudad.HORA_PARTIDO * Reloj.MINUTOS_HORA - ahora
	if mins <= 0:
		_decir(Idiomas.t("Ya pasó esta semana: la semana avanza en el PC o durmiendo el domingo."))
		return
	r.avanzar_con_rutina(mins)
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	(self as Telefono).abrir_app("agenda")
