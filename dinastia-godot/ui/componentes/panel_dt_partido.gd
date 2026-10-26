class_name PanelDTPartido
extends Control
## TÁCTICA Y CAMBIOS SIN SALIR DEL 3D (13-10-2026, pedido: «que los cambios de
## jugadores o tácticas puedan cambiar el resultado»). Con el motor real el
## partido se para y el DT toca la pizarra -mentalidad, presión, línea, ritmo- o
## mete cambios viendo la energía de cada uno. Lo que se cambia aquí es la
## táctica DEL CLUB (la misma de la pantalla de táctica) y el cambio del
## `Partido` (el que va al acta): el motor lo lee al reanudar.

signal cerrado

var partido: Partido
var mi_club: Club
var motor: MotorJugable
var _sale: Jugador = null
var _estado: Label
var _col_campo: VBoxContainer
var _col_banco: VBoxContainer
var _filas_tac: Dictionary = {}
var _titulo_banco: Label
var _seguir: Button
## Abre el panel de estadísticas encima (lo pasa `VistaEstadio`).
var ver_estadisticas: Callable = Callable()
## Repite los últimos segundos (lo pasa `VistaEstadio`); cierra la pausa antes.
var ver_repeticion: Callable = Callable()

const OPCIONES := {
	"mentalidad": ["🛡 Defensiva", "⚖ Equilibrada", "⚔ Ofensiva"],
	"presion": ["Presión baja", "Presión media", "Presión alta"],
	"linea": ["Línea baja", "Línea media", "Línea alta"],
	"ritmo": ["Ritmo lento", "Ritmo medio", "Ritmo alto"],
}

static func abrir(padre: Control, p: Partido, club: Club, m: MotorJugable, estadisticas: Callable = Callable(), repeticion: Callable = Callable()) -> PanelDTPartido:
	var n := PanelDTPartido.new()
	n.ver_estadisticas = estadisticas
	n.ver_repeticion = repeticion
	n.partido = p
	n.mi_club = club
	n.motor = m
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	n.z_index = 120
	padre.add_child(n)
	n._montar()
	return n

func _montar() -> void:
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.55)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	caja.custom_minimum_size = Vector2(860, 0)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	caja.add_child(v)
	var cab := HBoxContainer.new()
	v.add_child(cab)
	cab.add_child(CuadroDialogo.placa(Idiomas.t("Táctica y cambios")))
	var reloj := Tema.etiqueta(16, Tema.TEXTO, "  %d'  ·  %s %d - %d %s" % [partido.minuto,
		Nombres.visible(partido.local.nombre), partido.goles_local, partido.goles_visita, Nombres.visible(partido.visita.nombre)])
	cab.add_child(reloj)
	## La pizarra, en dos columnas para que todo quepa en la pantalla.
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 18)
	rejilla.add_theme_constant_override("v_separation", 6)
	v.add_child(rejilla)
	for k: String in ["mentalidad", "presion", "linea", "ritmo"]:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 4)
		rejilla.add_child(fila)
		var botones: Array[Button] = []
		for i in 3:
			var b := Button.new()
			b.text = Idiomas.t(String(OPCIONES[k][i]))
			b.toggle_mode = true
			b.add_theme_font_size_override("font_size", 13)
			b.custom_minimum_size = Vector2(134, 30)
			b.pressed.connect(_fijar.bind(k, i))
			fila.add_child(b)
			botones.append(b)
		_filas_tac[k] = botones
	_pintar_tactica()
	v.add_child(HSeparator.new())
	## Los cambios: a la izquierda los once con su energía, a la derecha el banco.
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	v.add_child(cols)
	var izq := VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(izq)
	izq.add_child(Tema.etiqueta(13, Tema.ORO, Idiomas.t("EN EL CAMPO (energía)")))
	_col_campo = VBoxContainer.new()
	izq.add_child(_col_campo)
	var der := VBoxContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(der)
	_titulo_banco = Tema.etiqueta(13, Tema.ORO, Idiomas.t("BANQUILLO"))
	der.add_child(_titulo_banco)
	_col_banco = VBoxContainer.new()
	der.add_child(_col_banco)
	_estado = Tema.etiqueta(13, Tema.SUAVE, "")
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_estado)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	v.add_child(botones)
	## Las estadísticas del partido (el panel de la tele), sin salir de la pausa.
	if ver_estadisticas.is_valid():
		var stats := Button.new()
		stats.text = Idiomas.t("📊 Estadísticas") + "  (" + Mando.corto_de("jugar_estadisticas") + ")"
		stats.custom_minimum_size = Vector2(240, 36)
		stats.add_theme_font_size_override("font_size", 15)
		stats.pressed.connect(_abrir_estadisticas)
		botones.add_child(stats)
	if ver_repeticion.is_valid():
		var rep := Button.new()
		rep.text = Idiomas.t("⟲ Repetición") + "  (" + Mando.corto_de("jugar_repeticion") + ")"
		rep.custom_minimum_size = Vector2(200, 36)
		rep.add_theme_font_size_override("font_size", 15)
		rep.pressed.connect(func() -> void:
			cerrar()
			ver_repeticion.call())
		botones.add_child(rep)
	var seguir := Button.new()
	seguir.text = Idiomas.t("▶  Seguir jugando")
	seguir.custom_minimum_size = Vector2(0, 36)
	seguir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seguir.add_theme_font_size_override("font_size", 17)
	seguir.pressed.connect(cerrar)
	botones.add_child(seguir)
	_seguir = seguir
	_pintar_cambios()
	## Con mando el panel se maneja entero (antes todo era FOCUS_NONE y solo se
	## podía volver a jugar): el foco empieza en «Seguir jugando», así que A
	## reanuda como antes y la cruceta lleva a la pizarra y a los cambios.
	seguir.grab_focus.call_deferred()
	_estado.text = _ayuda_cambios()

## Qué hacer para meter un cambio y cuántos quedan: el banco sale apagado hasta
## que se elige quién sale, y sin esta línea parecía que no se podía cambiar.
func _ayuda_cambios() -> String:
	var hechos := partido.cambios_local if partido.local == mi_club else partido.cambios_visita
	if hechos >= Partido.MAX_CAMBIOS:
		return Idiomas.t("Ya hiciste los cinco cambios.")
	return Idiomas.t("Para un cambio: elige quién sale (izquierda) y luego quién entra (derecha).")

## Las estadísticas se abren encima: el foco se suelta para que A no pulse un
## botón de esta pizarra por detrás, y vuelve a «Seguir jugando» al cerrarlas.
func _abrir_estadisticas() -> void:
	get_viewport().gui_release_focus()
	var antes := get_parent().get_child_count()
	ver_estadisticas.call()
	var padre := get_parent()
	for i in range(antes, padre.get_child_count()):
		var n := padre.get_child(i)
		if n is PanelEstadisticas:
			(n as PanelEstadisticas).cerrado.connect(func() -> void:
				if is_instance_valid(_seguir):
					_seguir.grab_focus())

func _fijar(k: String, i: int) -> void:
	match k:
		"mentalidad": mi_club.tactica.mentalidad = i
		"presion": mi_club.tactica.presion = i
		"linea": mi_club.tactica.linea = i
		"ritmo": mi_club.tactica.ritmo = i
	partido.invalidar_fuerza()
	_pintar_tactica()
	_estado.text = Idiomas.t("Pizarra cambiada: el equipo la aplica en cuanto se reanude.")

func _pintar_tactica() -> void:
	var t := mi_club.tactica
	var actual := {"mentalidad": t.mentalidad, "presion": t.presion, "linea": t.linea, "ritmo": t.ritmo}
	for k: String in _filas_tac:
		var botones: Array = _filas_tac[k]
		for i in botones.size():
			(botones[i] as Button).button_pressed = i == int(actual[k])

func _mi_once() -> Array[Jugador]:
	return partido.once_local if partido.local == mi_club else partido.once_visita

func _energia(j: Jugador) -> float:
	if motor == null:
		return 1.0
	for p: Dictionary in motor.jugadores:
		if String(p.get("id", "")) == j.id:
			return motor.forma_fisica(p)
	return 1.0

## `foco`: a qué columna va el foco al repintar («banco» tras elegir quién sale,
## «campo» tras un cambio); los botones se rehacen y el foco se perdería.
func _pintar_cambios(foco := "") -> void:
	for h in _col_campo.get_children():
		h.queue_free()
	for h in _col_banco.get_children():
		h.queue_free()
	var hechos := partido.cambios_local if partido.local == mi_club else partido.cambios_visita
	_titulo_banco.text = Idiomas.t("BANQUILLO") + "  ·  " + Idiomas.t("cambios: %d de %d") % [hechos, Partido.MAX_CAMBIOS]
	for j: Jugador in _mi_once():
		var e := _energia(j)
		var b := Button.new()
		## «▼» marca al cansado sin depender del color (rojo/dorado no lo ve todo el mundo).
		b.text = "%s  %s   %d%%%s" % [j.pos_e, Nombres.visible(j.nombre), int(round(e * 100.0)), "  ▼" if e < 0.7 else ""]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 13)
		b.custom_minimum_size = Vector2(0, 27)
		b.toggle_mode = true
		b.button_pressed = _sale == j
		b.add_theme_color_override("font_color", Tema.MAL if e < 0.7 else (Tema.ORO if e < 0.82 else Tema.TEXTO))
		b.pressed.connect(func() -> void:
			_sale = j
			_estado.text = Idiomas.t("Elige quién entra por %s.") % Nombres.visible(j.nombre)
			_pintar_cambios("banco"))
		_col_campo.add_child(b)
	var banco := VistaEstadio.disponibles_fuera_del_once(mi_club, _mi_once())
	var n := 0
	for j: Jugador in banco:
		if n >= 9:
			break
		n += 1
		var b := Button.new()
		b.text = "%s  %s   %d" % [j.pos_e, Nombres.visible(j.nombre), j.ovr]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 13)
		b.custom_minimum_size = Vector2(0, 27)
		b.disabled = _sale == null or hechos >= Partido.MAX_CAMBIOS
		b.pressed.connect(func() -> void:
			var por := _sale
			var error := partido.cambiar(por, j)
			if error != "":
				_estado.text = error
			else:
				_estado.text = Idiomas.t("🔁 Entra %s por %s.") % [Nombres.visible(j.nombre), Nombres.visible(por.nombre)]
				_sale = null
			_pintar_cambios("campo"))
		_col_banco.add_child(b)
	if hechos >= Partido.MAX_CAMBIOS:
		_estado.text = Idiomas.t("Ya hiciste los cinco cambios.")
	var col := _col_banco if foco == "banco" else (_col_campo if foco == "campo" else null)
	if col != null:
		for h in col.get_children():
			if h is Button and not (h as Button).disabled and not h.is_queued_for_deletion():
				(h as Button).grab_focus.call_deferred()
				break

func cerrar() -> void:
	cerrado.emit()
	queue_free()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("jugar_pausa"):
		get_viewport().set_input_as_handled()
		cerrar()
