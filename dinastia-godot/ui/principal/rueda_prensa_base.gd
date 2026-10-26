extends Control
## CAPA BASE DE LA RUEDA DE PRENSA 2D (26-10, pulido de la petición 8 de la
## sesión 2): el estado, el reloj en palabras con tiempo de lectura, la entrada
## suave y el mando/teclado. La pantalla en sí está en `rueda_prensa.gd`, que
## hereda de esta (norma de 450 líneas).

var p: Principal
## Lo que la repregunta cambia sin rehacer el plató (B5).
var _quien: Label
var _pregunta: Label
var _opciones: VBoxContainer
var _reloj: ProgressBar
## Pulido (26-10, petición 8 de la sesión 2): el medio y el trato van aparte
## del nombre -jerarquía: quién pregunta, qué pregunta, qué contestas- y el
## reloj dice con palabras cuánto queda, no solo una rayita.
var _medio: Label
var _reloj_txt: Label
var _atajos: Label
## Cuándo EMPIEZA a contar el titubeo (ms). Ya no es el instante en que sale
## la pregunta: antes se da un tiempo de lectura (`_lectura()`), para que una
## pregunta larga -o leída en otro idioma- no cuente como duda.
var desde := 0
var _fondo: ColorRect
## Las tres piezas de la interfaz sobre el plató (ver `abrir()`).
var _columna: PanelContainer
var _franja: PanelContainer
var _posturas: Control
var _objetivos_ocultos := false
var _escena: RuedaPrensaEscena3D
const _PrincipalRuedaResumen := preload("res://ui/principal/rueda_prensa_resumen.gd")
## Quién hizo la última pregunta (la entrevista ya se vacía al cerrar).
var _ultimo_periodista := ""
var _ultimo_medio := ""
## Lo que movió la rueda entera (con repreguntas), para el resumen final.
var _suma := {"moral": 0, "confianza": 0, "socios": 0}
## Medidas en píxeles lógicos (la ventana base es 1280×720 con «expand»).
const ANCHO_COLUMNA := 400
const ALTO_FRANJA := 108
const MARGEN := 18
const COL_FONDO := Color(0.035, 0.038, 0.045)
## Tiempo de lectura: un mínimo, y algo más por letra, con techo.
const LECTURA_MIN := 1.5
const LECTURA_POR_LETRA := 0.04
const LECTURA_MAX := 4.0


## Las define la capa de arriba (`rueda_prensa.gd`).
func responder(_i: int) -> void:
	pass

func repintar_posturas() -> void:
	pass

## ENTRADA SUAVE: fundido desde negro y las opciones un poco después.
func _entrar() -> void:
	if Animar.reducidas():
		return
	modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.35)

## MANDO Y TECLADO. Las teclas 1-9 contestan directo (si no se está escribiendo
## en el campo libre: el `LineEdit` se queda la tecla antes). Con mando, ↑↓ y
## A ya los da el foco de Godot; LB/RB cambian el «cómo lo dices».
func _unhandled_input(ev: InputEvent) -> void:
	if not is_visible_in_tree() or is_queued_for_deletion():
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k := (ev as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_9 and _opciones != null and k - KEY_1 < _opciones.get_child_count():
			get_viewport().set_input_as_handled()
			responder(k - KEY_1)
	elif ev is InputEventJoypadButton and ev.pressed:
		var bj := (ev as InputEventJoypadButton).button_index
		if bj == JOY_BUTTON_LEFT_SHOULDER or bj == JOY_BUTTON_RIGHT_SHOULDER:
			get_viewport().set_input_as_handled()
			_girar_postura(1 if bj == JOY_BUTTON_RIGHT_SHOULDER else -1)

## Pasa a la postura siguiente/anterior (LB/RB del mando).
func _girar_postura(paso: int) -> void:
	var claves: Array = p.mundo.prensa.cuerpos().keys()
	if claves.is_empty():
		return
	var i := maxi(claves.find(p.mundo.prensa.cuerpo), 0)
	p.mundo.prensa.fijar_cuerpo(String(claves[posmod(i + paso, claves.size())]))
	repintar_posturas()
	_enfocar()

## El foco en la primera opción, para que el mando y las flechas funcionen
## sin tocar el ratón.
func _enfocar() -> void:
	if _opciones != null and is_instance_valid(_opciones) and _opciones.get_child_count() > 0:
		(_opciones.get_child(0) as Control).grab_focus()

## Segundos de lectura que se regalan antes de que el reloj empiece a contar.
static func _lectura(pregunta: String) -> float:
	return clampf(LECTURA_MIN + pregunta.length() * LECTURA_POR_LETRA, LECTURA_MIN, LECTURA_MAX)

## El reloj en palabras: lectura, segundos que quedan o «ya se nota».
func _process(_d: float) -> void:
	if not is_instance_valid(_reloj) or _reloj_txt == null:
		return
	var ahora := Time.get_ticks_msec()
	if ahora < desde:
		_reloj.value = 0.0
		_reloj_txt.text = Idiomas.t("📖 Leyendo la pregunta…")
		_reloj_txt.add_theme_color_override("font_color", Tema.SUAVE)
		return
	var seg := segundos()
	_reloj.value = minf(seg, Prensa.TITUBEO_SEG)
	var quedan := int(ceil(Prensa.TITUBEO_SEG - seg))
	if quedan > 0:
		_reloj_txt.text = Idiomas.t("⏱ %d s para contestar con aplomo") % quedan
		_reloj_txt.add_theme_color_override("font_color", Tema.ORO if quedan <= 3 else Tema.TEXTO)
		_reloj.modulate = Color.WHITE
	else:
		_reloj_txt.text = Idiomas.t("⏱ La sala ya nota que dudas")
		_reloj_txt.add_theme_color_override("font_color", Tema.MAL)
		_reloj.modulate = Tema.MAL


## El reloj, DISCRETO (26-10, pedido del dueño): una línea pequeña con los
## segundos y una barra fina debajo, al pie de la columna de respuestas.
func _fila_reloj() -> VBoxContainer:
	var fila := VBoxContainer.new()
	fila.add_theme_constant_override("separation", 3)
	_reloj_txt = p._texto(11, Principal.COL_TEXTO)
	_reloj_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(_reloj_txt)
	var reloj := ProgressBar.new()
	reloj.show_percentage = false
	reloj.custom_minimum_size = Vector2(0, 5)
	reloj.max_value = Prensa.TITUBEO_SEG
	for par: Array in [["background", Color(1, 1, 1, 0.1)], ["fill", Color(p.COL_ACENTO, 0.85)]]:
		var sbr := StyleBoxFlat.new()
		sbr.bg_color = par[1]
		sbr.set_corner_radius_all(3)
		reloj.add_theme_stylebox_override(String(par[0]), sbr)
	fila.add_child(reloj)
	_reloj = reloj
	_atajos = p._texto(10, Principal.COL_SUAVE)
	_atajos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(_atajos)
	return fila


## La pregunta en pantalla y el reloj a cero. La usa también la repregunta,

## Segundos desde que acabó el tiempo de lectura (0 mientras se lee).
func segundos() -> float:
	return maxf(0.0, float(Time.get_ticks_msec() - desde) / 1000.0)

## QUIÉN HABLA DE VERDAD (14-9-2026): si el DT es un empleado (ayudante,
## director deportivo, dueño con el banco delegado), da él la rueda, con un
## aspecto fijo por su nombre; si no, tú con tu aspecto.
func _nombre_dt() -> String:
	if p.mundo.roles == null:
		return ""
	return p.mundo.roles.dt_nombre() if not p.mundo.roles.dt_empleado.is_empty() else p.mundo.roles.nombre

func _look_dt() -> Dictionary:
	if p.mundo.roles == null:
		return {}
	if not p.mundo.roles.dt_empleado.is_empty():
		return CaraDT.look_de_nombre(p.mundo.roles.dt_nombre())
	return p.mundo.roles.look_efectivo()

## Caja semitransparente común (columna, cabecera, franja).
static func _caja(alfa: float, radio: int, margen: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.025, 0.03, alfa)
	sb.set_corner_radius_all(radio)
	sb.content_margin_left = margen; sb.content_margin_right = margen
	sb.content_margin_top = margen * 0.7; sb.content_margin_bottom = margen * 0.7
	return sb
