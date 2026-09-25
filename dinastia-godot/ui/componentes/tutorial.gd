class_name Tutorial
extends Control
## EL TUTORIAL GUIADO (25-9-2026).
##
## Hasta hoy la tarjeta "Tutorial" del menú salía apagada con "el tutorial
## todavía no está en esta versión de Godot", y los ocho textos de `TUT_PASOS`
## -escritos para el HTML- hablaban de "cinco pestañas abajo" y de un botón
## verde CONTINUAR que en Godot no existen. El análisis externo lo marcó como
## una de las tres prioridades: un manager sin onboarding pierde a la mayoría
## de los jugadores nuevos en la primera hora.
##
## Cómo funciona:
##  * Una TARJETA con el paso actual y un MARCO que late alrededor del control
##    real del que habla (`Principal.tutorial_objetivo()`), con el resto de la
##    pantalla atenuado.
##  * La pantalla sigue viva debajo: el tutorial no bloquea ni un clic. Cada
##    paso se completa pulsando "Siguiente" o HACIENDO lo que pide -abrir el
##    plantel, cambiar de bloque...- (`Principal.tutorial_hecho()`), y
##    "Muéstramelo" lo hace por ti (`Principal.tutorial_accion()`).
##  * Los pasos son comunes a todas las carreras más uno o dos PROPIOS DEL MODO
##    (entrenador, director deportivo, ayudante, cantera, interinato, dueño...):
##    lo que hay que saber no es lo mismo si el once lo pones tú o no.
##  * Se guarda como visto en `user://ajustes.cfg`; se ofrece solo la primera
##    carrera, se fuerza desde la tarjeta del menú y se repite desde Ajustes.
##
## `pasos_para()` es estático y no toca la interfaz, para que el banco pueda
## comprobar el guion de cada modo sin abrir ninguna pantalla.

signal terminado(completo: bool)

const AJUSTES := "user://ajustes.cfg"
const SECCION := "tutorial"

const COL_FONDO := Color("141c16")
const COL_BORDE := Color("3fa06a")
const COL_TEXTO := Color("e9eeea")
const COL_SUAVE := Color("8ea595")
const COL_ORO := Color("c9a227")
const ANCHO_TARJETA := 470.0

var _principal: Node
var _pasos: Array[Dictionary] = []
var _i := 0
var _t := 0.0
var _tarjeta: PanelContainer
var _lbl_titulo: Label
var _lbl_texto: RichTextLabel
var _lbl_progreso: Label
var _btn_atras: Button
var _btn_sig: Button
var _btn_mostrar: Button
var _marco: Panel
var _sombras: Array[ColorRect] = []

# ---------------------------------------------------------------------------
#  GUION
# ---------------------------------------------------------------------------

## Los pasos de una carrera. Cada paso: `titulo`, `texto` (BBCode), y
## opcionales `objetivo` (qué control resaltar), `hecho` (qué acción del
## jugador lo completa) y `mostrar` (qué hace "Muéstramelo").
static func pasos_para(modo: String, club: String) -> Array[Dictionary]:
	var p: Array[Dictionary] = []
	p.append({"titulo": "👋 Bienvenido a DINASTÍA",
		"texto": "Te haces cargo de [b]%s[/b]. Este recorrido dura dos minutos: te enseña dónde está cada cosa y qué se espera de ti.\n\nPuedes hacer lo que te pide cada tarjeta o pulsar [b]Siguiente[/b]. Y cerrarlo cuando quieras." % club})
	p.append({"titulo": "🎯 Lo que se espera de ti", "objetivo": "estado",
		"texto": "Debajo del nombre del club está tu situación: la jornada, los sueldos, la media del plantel, [b]el objetivo de la temporada[/b] y la [b]confianza[/b] del directorio.\n\nEl objetivo lo fija el directorio. Si la confianza se hunde, el puesto peligra."})
	p.append({"titulo": "🧭 Los seis bloques", "objetivo": "grupos", "hecho": "grupo",
		"texto": "Arriba tienes seis bloques: [b]CENTRAL, CLUB, GENTE, HISTORIA, OPERACIONES y AJUSTES[/b]. Cada uno abre su fila de accesos justo debajo.\n\n[color=#c9a227]Prueba: toca CLUB.[/color]",
		"mostrar": "grupo_club"})
	p.append({"titulo": "🔖 Los accesos de cada bloque", "objetivo": "chips",
		"texto": "Esta fila cambia con el bloque. En CLUB, por ejemplo, están el estadio, la infraestructura, el diseño 3D de tu ciudad deportiva y el directorio.\n\nSe desliza con el dedo o la rueda si no cabe entera."})
	p.append({"titulo": "👔 Tu plantel", "objetivo": "plantel", "hecho": "plantel",
		"texto": "El día a día del equipo no está arriba: se abre tocando la zona que ya habla de él. Este acceso lleva al [b]plantel, la táctica, el entrenamiento, la enfermería, el camarín, la cantera y los contratos[/b].\n\n[color=#c9a227]Prueba: ábrelo y elige una pestaña.[/color]",
		"mostrar": "plantel"})
	p.append({"titulo": "🧍 La ficha del jugador", "objetivo": "ficha",
		"texto": "Toca a cualquier jugador, tuyo o de otro club, y su ficha aparece aquí: atributos, media y potencial, forma, moral, contrato, sueldo y estado mental.\n\nDesde la ficha también se renueva, se vende o se le cambia de puesto."})
	p.append({"titulo": "💰 El dinero", "objetivo": "dinero", "hecho": "dinero",
		"texto": "Finanzas, mercado de fichajes y agentes libres. La caja del club paga sueldos, fichajes y obras: [b]un club sin caja no ficha[/b], y uno en números rojos acaba con el banco encima.",
		"mostrar": "dinero"})
	p.append({"titulo": "⚽ El partido", "objetivo": "partido", "hecho": "partido",
		"texto": "El partido de esta semana, el rival, el calendario y la previa: cuotas, informe del rival y quién llega tocado.",
		"mostrar": "partido"})
	p.append({"titulo": "🏆 La competición", "objetivo": "tabla",
		"texto": "La tabla de lo que se juega esta semana: liga, copa o tu grupo continental. Abajo, [b]Ver la competición[/b] abre la ficha completa y [b]Todas las competiciones[/b] lleva a copas, torneos internacionales, selección y federación."})
	p.append({"titulo": "📰 Lo que va pasando", "objetivo": "registro",
		"texto": "Resultados, lesiones, ofertas, prensa, decisiones del directorio... Todo lo que ocurre en el mundo te llega aquí, y lo importante además salta como aviso."})
	p.append({"titulo": "📅 Avanzar el tiempo", "objetivo": "calendario",
		"texto": "Aquí avanza el juego:\n• [b]Dirigir el partido[/b]: lo juegas en directo, con cambios, órdenes desde la banda y charla en el entretiempo (y en 3D si quieres).\n• [b]Avanzar semana[/b]: se simula sola.\n• [b]Jugar la temporada[/b] y [b]Temporada siguiente[/b], para ir rápido."})
	p.append({"titulo": "⏭ Día a día", "objetivo": "un_dia",
		"texto": "Si prefieres ir con calma, [b]Un día[/b] avanza solo un día del calendario. Al pasar el domingo corre la semana entera, con el partido incluido."})
	p.append({"titulo": "💾 Guardar", "objetivo": "guardar",
		"texto": "El juego no guarda solo cada vez que haces algo: [b]guarda antes de cerrar[/b]. Con [b]Cargar[/b] vuelves a cualquier partida."})
	p.append_array(_pasos_del_modo(modo))
	p.append({"titulo": "🚀 A jugar",
		"texto": "Eso es todo. Un buen primer paso: abre [b]📅 Calendario → Dirigir el partido[/b] y juega tu primer partido en directo.\n\nPuedes repetir este recorrido cuando quieras en [b]AJUSTES → Interfaz[/b]."})
	return p

static func _pasos_del_modo(modo: String) -> Array[Dictionary]:
	match modo:
		"dir":
			return [{"titulo": "🗂️ Director Deportivo", "objetivo": "dinero",
				"texto": "Tú no pones el once: lo pone el [b]entrenador empleado[/b]. Lo tuyo son los fichajes, los contratos y las finanzas, y elegir quién se sienta en el banco.\n\nPuedes pedirle cosas al entrenador (más cantera, rotar a los cansados...), pero [b]meterte en su trabajo desgasta la relación[/b]."}]
		"ayudante":
			return [{"titulo": "📋 Ayudante de Campo", "objetivo": "plantel",
				"texto": "Empiezas abajo: [b]no fichas, no vendes y no pones el once[/b]. Eso es cosa de tu jefe.\n\nLo tuyo son los entrenamientos, el camarín y la cantera. Si te ganas su confianza y el equipo responde, el banco acabará siendo tuyo."}]
		"interino":
			return [{"titulo": "🚒 Interinato", "objetivo": "estado",
				"texto": "Te contratan como bombero: [b]cinco fechas[/b] para salvar a un club hundido. Sin fichajes ni proyecto, solo motivación y táctica.\n\nEl directorio no te puede echar: tu contrato ya trae fecha de término."}]
		"cantera":
			return [{"titulo": "🌱 Director de Cantera", "objetivo": "plantel",
				"texto": "No diriges al primer equipo. Lo tuyo es la [b]Academia[/b] (Plantel → Cantera): chicos de 10 a 16 años a los que les eliges el entrenamiento, la comida, cuánto estudian y el carácter que forjan. A los 16 pasan al plantel tal como los formaste.\n\nEl club te pide un número de debutantes por temporada y te da un presupuesto de academia, no el de un plantel profesional."}]
		"imperio":
			return [{"titulo": "🏛️ Dueño de Club", "objetivo": "dinero",
				"texto": "El club es tuyo: [b]nadie te puede echar[/b]. Puedes meter capital propio (dos veces por temporada) y un entrenador empleado dirige los partidos.\n\nSin directorio que te frene, lo que salga mal es cosa tuya."}]
		"jeque":
			return [{"titulo": "💎 Modo Jeque", "objetivo": "dinero",
				"texto": "Un fondo soberano compra el club: [b]caja sin límite desde el primer día[/b]. Es un modo libre, para construir el equipo que quieras sin mirar la calculadora."}]
		"creador":
			return [{"titulo": "🛠️ Tu club", "objetivo": "grupos",
				"texto": "Fundaste un club de cero y empiezas desde el fondo de la tabla. En [b]GENTE → Identidad Visual[/b] y [b]Equipación[/b] le das escudo y colores propios."}]
	return [{"titulo": "🧠 Entrenador", "objetivo": "plantel",
		"texto": "Tú pones el once y la táctica (Plantel → Táctica), hablas al vestuario en el camarín y negocias los fichajes.\n\nOjo con el [b]camarín[/b]: si dejas fuera al líder de un grupo demasiadas semanas, todo el grupo se resiente."}]

static func visto(modo: String = "general") -> bool:
	var c := ConfigFile.new()
	if c.load(AJUSTES) != OK:
		return false
	return bool(c.get_value(SECCION, modo, false))

static func marcar_visto(modo: String = "general") -> void:
	var c := ConfigFile.new()
	c.load(AJUSTES)
	c.set_value(SECCION, modo, true)
	c.save(AJUSTES)

# ---------------------------------------------------------------------------
#  INTERFAZ
# ---------------------------------------------------------------------------

func iniciar(principal: Node, modo: String, club: String) -> void:
	_principal = principal
	_pasos = pasos_para(modo, club)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Las cuatro sombras rodean el hueco del control resaltado: atenúan el
	## resto de la pantalla sin taparle los clics a nadie.
	for k in 4:
		var s := ColorRect.new()
		s.color = Color(0, 0, 0, 0.42)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(s)
		_sombras.append(s)
	_marco = Panel.new()
	_marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var borde := StyleBoxFlat.new()
	borde.bg_color = Color(0, 0, 0, 0)
	borde.border_color = COL_ORO
	borde.set_border_width_all(3)
	borde.set_corner_radius_all(8)
	_marco.add_theme_stylebox_override("panel", borde)
	add_child(_marco)
	_construir_tarjeta()
	_mostrar(0)

func _construir_tarjeta() -> void:
	_tarjeta = PanelContainer.new()
	_tarjeta.mouse_filter = Control.MOUSE_FILTER_STOP
	var e := StyleBoxFlat.new()
	e.bg_color = Color(COL_FONDO, 0.97)
	e.border_color = COL_BORDE
	e.set_border_width_all(2)
	e.set_corner_radius_all(12)
	e.shadow_color = Color(0, 0, 0, 0.5)
	e.shadow_size = 12
	e.content_margin_left = 18; e.content_margin_right = 18
	e.content_margin_top = 14; e.content_margin_bottom = 14
	_tarjeta.add_theme_stylebox_override("panel", e)
	_tarjeta.custom_minimum_size = Vector2(ANCHO_TARJETA, 0)
	add_child(_tarjeta)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_tarjeta.add_child(v)
	var fila := HBoxContainer.new()
	v.add_child(fila)
	_lbl_titulo = Label.new()
	_lbl_titulo.add_theme_font_size_override("font_size", 19)
	_lbl_titulo.add_theme_color_override("font_color", COL_TEXTO)
	_lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_lbl_titulo)
	_lbl_progreso = Label.new()
	_lbl_progreso.add_theme_font_size_override("font_size", 12)
	_lbl_progreso.add_theme_color_override("font_color", COL_SUAVE)
	fila.add_child(_lbl_progreso)
	_lbl_texto = RichTextLabel.new()
	_lbl_texto.bbcode_enabled = true
	_lbl_texto.fit_content = true
	_lbl_texto.scroll_active = false
	_lbl_texto.add_theme_font_size_override("normal_font_size", 14)
	_lbl_texto.add_theme_font_size_override("bold_font_size", 14)
	_lbl_texto.add_theme_color_override("default_color", COL_TEXTO)
	_lbl_texto.custom_minimum_size = Vector2(ANCHO_TARJETA - 36.0, 0)
	v.add_child(_lbl_texto)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	v.add_child(botones)
	var saltar := Button.new()
	saltar.text = "Cerrar tutorial"
	saltar.flat = true
	saltar.add_theme_color_override("font_color", COL_SUAVE)
	saltar.pressed.connect(func() -> void: _terminar(false))
	botones.add_child(saltar)
	var empuje := Control.new()
	empuje.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botones.add_child(empuje)
	_btn_mostrar = Button.new()
	_btn_mostrar.text = "Muéstramelo"
	_btn_mostrar.pressed.connect(_hacer_por_mi)
	botones.add_child(_btn_mostrar)
	_btn_atras = Button.new()
	_btn_atras.text = "◂ Atrás"
	_btn_atras.pressed.connect(func() -> void: _mostrar(_i - 1))
	botones.add_child(_btn_atras)
	_btn_sig = Button.new()
	_btn_sig.custom_minimum_size = Vector2(110, 0)
	_btn_sig.pressed.connect(func() -> void: _mostrar(_i + 1))
	botones.add_child(_btn_sig)

func _mostrar(i: int) -> void:
	if i >= _pasos.size():
		_terminar(true)
		return
	_i = clampi(i, 0, _pasos.size() - 1)
	var paso := _pasos[_i]
	_lbl_titulo.text = String(paso["titulo"])
	_lbl_texto.text = String(paso["texto"])
	_lbl_progreso.text = "%d / %d" % [_i + 1, _pasos.size()]
	_btn_atras.visible = _i > 0
	_btn_mostrar.visible = paso.has("mostrar")
	_btn_sig.text = "¡A jugar!" if _i == _pasos.size() - 1 else "Siguiente ▸"
	_t = 0.0
	_colocar()

func paso_actual() -> Dictionary:
	return _pasos[_i] if _i < _pasos.size() else {}

func indice() -> int:
	return _i

func _hacer_por_mi() -> void:
	var paso := paso_actual()
	if paso.has("mostrar") and _principal != null and _principal.has_method("tutorial_accion"):
		_principal.call("tutorial_accion", String(paso["mostrar"]))

func _terminar(completo: bool) -> void:
	terminado.emit(completo)
	queue_free()

func _objetivo() -> Control:
	var paso := paso_actual()
	if not paso.has("objetivo") or _principal == null or not _principal.has_method("tutorial_objetivo"):
		return null
	var c: Variant = _principal.call("tutorial_objetivo", String(paso["objetivo"]))
	if c is Control and is_instance_valid(c) and (c as Control).is_visible_in_tree():
		return c
	return null

func _process(delta: float) -> void:
	## Siempre por encima: los hubs y los avisos se cuelgan de la misma raíz
	## después de nosotros.
	if get_parent() != null and get_index() != get_parent().get_child_count() - 1:
		move_to_front()
	_t += delta
	var paso := paso_actual()
	if paso.has("hecho") and _principal != null and _principal.has_method("tutorial_hecho") \
			and bool(_principal.call("tutorial_hecho", String(paso["hecho"]))) and _t > 0.4:
		_mostrar(_i + 1)
		return
	_colocar()

## Coloca el marco, las sombras y la tarjeta. Se recalcula cada cuadro: el
## control resaltado puede moverse (una fila que se reconstruye, la ventana que
## cambia de tamaño).
func _colocar() -> void:
	var pantalla := get_viewport_rect().size
	var obj := _objetivo()
	if obj == null:
		_marco.visible = false
		_poner_sombras(Rect2(pantalla * 0.5, Vector2.ZERO), pantalla, true)
		_tarjeta.position = (pantalla - _tarjeta.size) * 0.5
		return
	var r := obj.get_global_rect().grow(6.0)
	_marco.visible = true
	_marco.position = r.position
	_marco.size = r.size
	## El latido: el borde respira para que el ojo lo encuentre.
	_marco.modulate.a = 0.65 + 0.35 * sin(_t * 5.0)
	_poner_sombras(r, pantalla, false)
	## La tarjeta debajo del objetivo si cabe; si no, encima; si tampoco, al
	## lado. Siempre dentro de la pantalla.
	var ts := _tarjeta.size
	var pos := Vector2(r.position.x, r.end.y + 12.0)
	if pos.y + ts.y > pantalla.y - 8.0:
		pos.y = r.position.y - ts.y - 12.0
	if pos.y < 8.0:
		pos = Vector2(r.end.x + 12.0, r.position.y)
		if pos.x + ts.x > pantalla.x - 8.0:
			pos.x = r.position.x - ts.x - 12.0
	pos.x = clampf(pos.x, 8.0, maxf(8.0, pantalla.x - ts.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, pantalla.y - ts.y - 8.0))
	_tarjeta.position = pos

func _poner_sombras(hueco: Rect2, pantalla: Vector2, todo: bool) -> void:
	if todo:
		_sombras[0].position = Vector2.ZERO
		_sombras[0].size = pantalla
		for k in range(1, 4):
			_sombras[k].size = Vector2.ZERO
		return
	var h := hueco
	_sombras[0].position = Vector2.ZERO
	_sombras[0].size = Vector2(pantalla.x, maxf(0.0, h.position.y))
	_sombras[1].position = Vector2(0, h.end.y)
	_sombras[1].size = Vector2(pantalla.x, maxf(0.0, pantalla.y - h.end.y))
	_sombras[2].position = Vector2(0, h.position.y)
	_sombras[2].size = Vector2(maxf(0.0, h.position.x), h.size.y)
	_sombras[3].position = Vector2(h.end.x, h.position.y)
	_sombras[3].size = Vector2(maxf(0.0, pantalla.x - h.end.x), h.size.y)
