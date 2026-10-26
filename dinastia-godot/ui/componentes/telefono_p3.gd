extends "res://ui/componentes/telefono_p2.gd"
## [Capa 3/4 de `telefono.gd`] atras, _unhandled_input, _tras_abrir, enfocar, _estilo_aviso, animar_pop

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
