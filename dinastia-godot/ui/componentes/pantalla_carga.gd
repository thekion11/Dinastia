class_name PantallaCarga
extends ColorRect
## PANTALLA DE CARGA CON CONSEJOS (informe de diseño, 13-10-2026: «el salto a la
## ciudad no debe congelar el juego sin explicación»). Construir la ciudad o el
## estadio tarda varios segundos y, mientras, la pantalla parecía colgada. Esto
## se pone ENCIMA, se deja pintar dos fotogramas y recién entonces se empieza a
## construir; al acabar se quita con un fundido.
##
## Pulido (13-10-2026): fondo en degradado con los colores del club, su escudo
## grande y tenue detrás, tres puntos que laten y el consejo en una tarjeta.

## El club para teñir la pantalla (lo fija quien la abre, si lo sabe).
static var club: Club = null

var _t := 0.0
var _anillo: Control
var _barra: ColorRect
var _tarjeta_txt: Label
var _contador: Label
var _tarjeta: Control
var _orden: Array = []
var _k := 0
var _cambia_en := 4.5
var _ultimo_cambio := Time.get_ticks_msec()   ## cuándo se puso el consejo actual
var _tono := Color(0.2, 0.45, 0.3)
var _etapa: Label
var _destino := 0.0   ## hasta dónde ha llegado la construcción (0-1), según las etapas que avisa `CityBuilder._marca`
var _frac := 0.0      ## lo que se dibuja (persigue a `_destino` suavemente)
static var _actual: PantallaCarga = null

## (2-11, «se demora demasiado»): la barra ya no va y viene sin saber nada; avanza con las etapas de la construcción y dice cuál es. Cada etapa: [fracción hecha, texto].
const ETAPAS := {
	"_suelo": [0.12, "Terreno"], "_calles": [0.17, "Calles"], "_estadio": [0.33, "Estadio"], "_parcelas": [0.38, "Instalaciones"],
	"_barrio_residencial": [0.43, "Barrio del club"], "expansion.construir": [0.72, "Ciudad"], "_arbolado": [0.77, "Árboles y parques"],
	"_trafico": [0.9, "Tráfico y gente"], "despejar": [0.97, "Últimos detalles"],
}

## Lo llama la construcción de la ciudad al acabar cada etapa (no hace nada si no hay pantalla de carga).
static func paso(que: String) -> void:
	if _actual == null or not is_instance_valid(_actual) or not ETAPAS.has(que):
		return
	var e: Array = ETAPAS[que]
	_actual._destino = maxf(_actual._destino, float(e[0]))
	_actual._etapa.text = Idiomas.t(String(e[1])) + "…"
	## Cada etapa que acaba es un buen momento para otro consejo (si el anterior lleva más de 2,5 s a la vista).
	if Time.get_ticks_msec() - _actual._ultimo_cambio > 2500:
		_actual._siguiente_consejo()

## REHECHA (2-11-2026, queja del dueño: «una pantalla gris, debería notarse que es de carga»): fondo con
## el color del club y franjas en diagonal, escudo grande, un anillo con un balón que gira, una barra
## que corre, el título y un consejo que cambia cada pocos segundos (ahora hay 18).
static func mostrar(padre: Node, mensaje: String) -> PantallaCarga:
	var n := PantallaCarga.new()
	var c1 := Color(club.color1) if club != null else Color(0.12, 0.3, 0.2)
	n.color = Color(0.03, 0.05, 0.04, 1.0)
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	n.z_index = 200
	var tono := c1 if c1.get_luminance() > 0.12 else (Color(club.color2) if club != null and Color(club.color2).get_luminance() > 0.12 else Color(0.2, 0.45, 0.3))
	n._tono = tono
	## Degradado: el color del club, oscuro, sube desde abajo.
	var fondo := TextureRect.new()
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(0.02, 0.03, 0.03))
	gr.set_color(1, tono.darkened(0.78))
	g.gradient = gr
	g.fill_from = Vector2(0.5, 0.0)
	g.fill_to = Vector2(0.5, 1.0)
	fondo.texture = g
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_child(fondo)
	## Franjas en diagonal que se deslizan despacio (se dibujan en `_Franjas`).
	var fr := _Franjas.new()
	fr.tono = tono
	fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_child(fr)
	## 2-11 (queja del dueño, móvil): con `PRESET_CENTER` la caja se centraba sobre un padre de tamaño 0 y la pantalla salía en la esquina
	## (cortada, con el gris de fondo). Un CenterContainer de pantalla completa la centra sea cual sea el tamaño que acabe teniendo.
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_child(centro)
	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 16)
	centro.add_child(caja)
	## El anillo con el balón, y dentro el escudo.
	var cont := CenterContainer.new()
	caja.add_child(cont)
	var zona := Control.new()
	zona.custom_minimum_size = Vector2(190, 190)
	cont.add_child(zona)
	n._anillo = _Anillo.new()
	(n._anillo as _Anillo).tono = tono
	n._anillo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	zona.add_child(n._anillo)
	if club != null:
		var esc := TextureRect.new()
		esc.texture = EscudoTexto.textura(club, 256)
		esc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 38)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zona.add_child(esc)
	var t := Label.new()
	t.text = mensaje
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(0.94, 0.97, 0.94))
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	t.add_theme_constant_override("outline_size", 4)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(t)
	## La barra que corre (no sabemos cuánto falta: va y viene).
	var pista := ColorRect.new()
	pista.color = Color(1, 1, 1, 0.12)
	pista.custom_minimum_size = Vector2(360, 6)
	pista.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pista.clip_contents = true
	caja.add_child(pista)
	n._barra = ColorRect.new()
	n._barra.color = Color(1.0, 0.82, 0.35)
	n._barra.size = Vector2(110, 6)
	pista.add_child(n._barra)
	n._etapa = Label.new()
	n._etapa.add_theme_font_size_override("font_size", 15)
	n._etapa.add_theme_color_override("font_color", Color(0.85, 0.9, 0.85, 0.85))
	n._etapa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(n._etapa)
	## El consejo en una tarjeta, con el mismo estilo que los diálogos.
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	tarjeta.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	n._tarjeta = tarjeta
	var v := VBoxContainer.new()
	tarjeta.add_child(v)
	n._contador = Label.new()
	n._contador.add_theme_font_size_override("font_size", 13)
	n._contador.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	v.add_child(CuadroDialogo.placa(Idiomas.t("Consejo")))
	v.add_child(n._contador)
	n._tarjeta_txt = Label.new()
	n._tarjeta_txt.add_theme_font_size_override("font_size", 18)
	n._tarjeta_txt.add_theme_color_override("font_color", Color(0.9, 0.92, 0.9))
	n._tarjeta_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n._tarjeta_txt.custom_minimum_size = Vector2(560, 56)
	v.add_child(n._tarjeta_txt)
	caja.add_child(tarjeta)
	n._orden = range(lista_consejos().size())
	n._orden.shuffle()
	n._poner_consejo()
	padre.add_child(n)
	_actual = n
	n._ajustar()
	n.get_viewport().size_changed.connect(n._ajustar)
	return n

## Cubre SIEMPRE la ventana entera: si el padre no es un Control (el prólogo cuelga de un Node3D) o aún no tiene tamaño, se le da el de la ventana.
func _ajustar() -> void:
	var vp := get_viewport_rect().size
	if not (get_parent() is Control) or get_parent_area_size().x < 2.0:
		## Sin un Control que le dé tamaño (el prólogo cuelga de un Node3D): anclas iguales arriba a la izquierda y el tamaño de la ventana a mano.
		set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		position = Vector2.ZERO
		size = vp
	else:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## Deja que el sistema PINTE la pantalla antes de bloquear con la construcción. Dos fotogramas de
## `process_frame` no bastan: en Windows la ventana se quedaba en gris porque el primer dibujo aún no había
## salido. Esperar al dibujo de verdad (`frame_post_draw`) lo arregla.
static func dejar_pintar(arbol: SceneTree) -> void:
	for _i in 2:
		await arbol.process_frame
		## En headless no hay dibujo (la señal no llega nunca): solo fotogramas.
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw

## (3-11, R4 del dueño) Antes de quitar la pantalla de carga, la escena ya montada se dibuja unos fotogramas DEBAJO de ella:
## así los sombreadores se compilan y las texturas suben a la gráfica mientras el jugador aún ve la carga, en vez de dar
## tirones al empezar. En headless solo pasan los fotogramas.
static func estabilizar(arbol: SceneTree, fotogramas: int = 10) -> void:
	var n := fotogramas if DisplayServer.get_name() != "headless" else 2
	for _i in n:
		await arbol.process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw

func _poner_consejo() -> void:
	var l := lista_consejos()
	var txt := String(l[int(_orden[_k % _orden.size()])]).trim_prefix(Idiomas.t("Consejo: "))
	_tarjeta_txt.text = txt.substr(0, 1).to_upper() + txt.substr(1)
	_contador.text = "%d / %d" % [(_k % _orden.size()) + 1, _orden.size()]

func _process(delta: float) -> void:
	_t += delta
	if _anillo != null:
		_anillo.queue_redraw()
	if _barra != null:
		var ancho := (_barra.get_parent() as Control).size.x
		if _destino > 0.0:
			## Con etapas conocidas: barra que se llena (con un pequeño avance propio para que no parezca parada entre etapa y etapa).
			_frac = minf(minf(_frac + delta * 0.02 + maxf(_destino - _frac, 0.0) * delta * 3.0, 0.995), _destino + 0.06)
			_barra.size.x = ancho * _frac
			_barra.position.x = 0.0
		else:
			var u := (sin(_t * 2.2) + 1.0) * 0.5
			_barra.position.x = -_barra.size.x + u * (ancho + _barra.size.x)
	_cambia_en -= delta
	if _cambia_en <= 0.0:
		_siguiente_consejo()

## Pasa al consejo siguiente. El texto cambia AL INSTANTE (antes lo hacía un tween a mitad de fundido: con la construcción
## bloqueando el hilo, los fotogramas son escasos y el consejo parecía congelado); el fundido solo se suma si hay fotogramas.
func _siguiente_consejo() -> void:
	_cambia_en = 4.5
	_ultimo_cambio = Time.get_ticks_msec()
	_k += 1
	if _tarjeta == null or _tarjeta_txt == null:
		return
	_poner_consejo()
	_tarjeta.modulate.a = 0.35
	var tw := create_tween()
	tw.tween_property(_tarjeta, "modulate:a", 1.0, 0.3)

## Franjas diagonales suaves que se deslizan.
class _Franjas extends Control:
	var tono := Color.WHITE
	var _t := 0.0
	func _process(d: float) -> void:
		_t += d
		queue_redraw()
	func _draw() -> void:
		var paso := 120.0
		var desp := fposmod(_t * 14.0, paso * 2.0)
		var a := Color(tono.r, tono.g, tono.b, 0.055)
		var h := size.y
		var x := -h - paso * 2.0 + desp
		while x < size.x + h:
			draw_colored_polygon(PackedVector2Array([Vector2(x, h), Vector2(x + paso, h), Vector2(x + paso + h * 0.6, 0), Vector2(x + h * 0.6, 0)]), a)
			x += paso * 2.0

## El anillo del escudo: un aro tenue y un arco brillante con un balón que lo recorre.
class _Anillo extends Control:
	var tono := Color.WHITE
	var _t := 0.0
	func _process(d: float) -> void:
		_t += d
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 8.0
		draw_arc(c, r, 0.0, TAU, 64, Color(1, 1, 1, 0.1), 5.0, true)
		var a0 := _t * 3.2
		draw_arc(c, r, a0, a0 + 1.7, 32, Color(1.0, 0.82, 0.35), 5.0, true)
		var p := c + Vector2(cos(a0 + 1.7), sin(a0 + 1.7)) * r
		draw_circle(p, 9.0, Color(0.97, 0.97, 0.95))
		draw_circle(p, 3.6, Color(0.12, 0.12, 0.12))

static func lista_consejos() -> Array:
	return [
		Idiomas.t("Consejo: los días de partido el estadio se llena más si el equipo viene ganando."),
		Idiomas.t("Consejo: el Centro médico acelera la recuperación entre partidos."),
		Idiomas.t("Consejo: pulsa V al pasear para cambiar a primera persona."),
		Idiomas.t("Consejo: entra en las casas y los bares; la gente de la ciudad tiene cosas que contarte."),
		Idiomas.t("Consejo: la Academia juvenil mejora el potencial de los canteranos."),
		Idiomas.t("Consejo: de noche las ventanas se encienden y las farolas alumbran la calle."),
		Idiomas.t("Consejo: arrastra al personaje para girarlo y usa la rueda del ratón para acercarte."),
		Idiomas.t("Consejo: la mascota de tu club gesticula en la banda durante los partidos."),
		Idiomas.t("Consejo: los patrocinadores de tu camiseta salen de los contratos de Finanzas."),
		Idiomas.t("Consejo: el escudo y los colores que elijas se ven en la camiseta, el estadio y la ciudad."),
		Idiomas.t("Consejo: el museo del club guarda los trofeos que vas ganando."),
		Idiomas.t("Consejo: puedes cambiar el aspecto de tu personaje cuando quieras desde el menú."),
		Idiomas.t("Consejo: descansar a los jugadores cansados baja el riesgo de lesión."),
		Idiomas.t("Consejo: cuida la caja del club: una plantilla demasiado cara puede ahogarte."),
		Idiomas.t("Consejo: cambia la táctica durante el partido si el rival te sorprende."),
		Idiomas.t("Consejo: tu móvil tiene una agenda con las citas y reuniones del día."),
		Idiomas.t("Consejo: una buena rueda de prensa mantiene contenta a la hinchada."),
		Idiomas.t("Consejo: la ciudad tiene metro, buses y teleférico para moverte sin prisa."),
	]

## Un consejo al azar (lo usa quien quiera mostrar uno suelto).
static func consejo() -> String:
	var l := lista_consejos()
	return String(l[randi() % l.size()])

## Quita la pantalla con un fundido corto.
func cerrar() -> void:
	if _actual == self:
		_actual = null
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
