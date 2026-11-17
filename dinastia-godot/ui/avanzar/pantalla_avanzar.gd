class_name PantallaAvanzar
extends PantallaMaqueta
## LA PANTALLA «AVANZAR EN EL TIEMPO» (paso 3, rehecha el 17-11-2026 FIEL a la maqueta aprobada: `docs/04_auditorias/maqueta_avanzar_2026-11-16.html`).
## Escenario de 1200x540 escalado a la ventana: cabecera con la fecha, BANNER grande (degradado del color del evento, rótulo «13 ABR · EVENTO IMPORTANTE», titular, texto y su
## arte; en los partidos, los dos escudos y «VS»), barra de progreso, calendario de DOS SEMANAS (lunes a domingo, 7x2) con el escudo de tu club como cursor, tilde en los
## días pasados y símbolos circulares por tipo, y los botones. El cursor corre día a día hasta el primer día con eventos (`AvanceDias`); el banner con el arte SOLO sale
## con el cursor sobre ese día, ~2,4 s. El mes cambia solo (la ventana se mueve de lunes en lunes). Cualquier tecla o clic salta la animación; otra vez cierra.
## Emite `cerrado`. La pantalla NO corre la semana: eso lo hace `AvanceDiasUI` con `rodar` antes de abrirla. Piezas en `PantallaAvanzarPiezas`.

signal cerrado

const PASO := 0.16        ## s por día recorrido
const DECORADO := 2.4     ## s que se queda el banner en un día de evento
const ESCENA := Vector2(1200, 540)

var _m: Mundo
var _res: Dictionary
var _unix0 := 0
var _unix_parada := 0
var _escena: Control
var _celdas: Array = []
var _fecha: Label
var _barra: ColorRect
var _banner: Control
var _fondo_banner: FondoCine
var _cap: Control
var _idx := 0
var _fase := 0              ## 0 = corriendo, 1 = banner a la vista, 2 = cerrada
var _tween: Tween
var _cache_ev := {}
var _acento := Color("c8102e")

## `unix0`: la fecha de PARTIDA (antes de avanzar); `res`: lo que devolvió `AvanceDias.avanzar`.
static func mostrar(pr: Node, m: Mundo, unix0: int, res: Dictionary) -> PantallaAvanzar:
	var s := PantallaAvanzar.new()
	s._m = m
	s._res = res
	s._unix0 = unix0
	s._unix_parada = unix0 + (res["pasados"] as Array).size() * 86400
	s.montar(pr, FondoCine.Modo.NOCHE, Color("0b1330"))
	s._rellenar()
	s._correr.call_deferred()
	return s

func _rellenar() -> void:
	_acento = Color(_m.mi_club().color1) if _m.mi_club().color1 != "" else _acento
	if _acento.get_luminance() < 0.08:
		_acento = Color("c8102e")
	_escena = Control.new()
	_escena.size = ESCENA
	_escena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_escena)
	_ajustar()
	_raiz.resized.connect(_ajustar)
	var cab := Panel.new()
	cab.position = Vector2(36, 22)
	cab.size = Vector2(1128, 52)
	cab.add_theme_stylebox_override("panel", PantallaAvanzarPiezas._caja(Color(0.031, 0.051, 0.094, 0.86)))
	_escena.add_child(cab)
	var t := EstiloAvanzar.etiqueta(Idiomas.t("Avanzar en el tiempo"), 26, EstiloAvanzar.TINTA, true, true)
	t.position = Vector2(18, 6)
	cab.add_child(t)
	_fecha = EstiloAvanzar.etiqueta("", 14, Color("8b95a8"))
	_fecha.size = Vector2(500, 52)
	_fecha.position = Vector2(1128 - 518, 0)
	_fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fecha.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(_fecha)
	_banner = Control.new()
	_banner.position = Vector2(36, 74)
	_banner.size = Vector2(1128, 156)
	_banner.clip_contents = true
	_escena.add_child(_banner)
	_fondo_banner = FondoCine.new()
	_banner.add_child(_fondo_banner)
	_cap = Control.new()
	_cap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.add_child(_cap)
	var riel := ColorRect.new()
	riel.position = Vector2(36, 231)
	riel.size = Vector2(1128, 4)
	riel.color = Color(1, 1, 1, 0.1)
	_escena.add_child(riel)
	_barra = ColorRect.new()
	_barra.position = Vector2(36, 231)
	_barra.size = Vector2(0, 4)
	_barra.color = _acento
	_escena.add_child(_barra)
	var cal := Control.new()
	cal.position = Vector2(36, 238)
	_escena.add_child(cal)
	var escudo := Escudo.textura(_m.mi_club(), 64)
	for i in 14:
		var c := PantallaAvanzarPiezas.celda(escudo)
		(c["panel"] as Control).position = Vector2((i % 7) * PantallaAvanzarPiezas.ANCHO_CELDA, (i / 7) * PantallaAvanzarPiezas.ALTO_CELDA)
		cal.add_child(c["panel"])
		_celdas.append(c)
	_pie()
	_pintar(0)

func _ajustar() -> void:
	var v := _raiz.size
	var k := minf(v.x / ESCENA.x, v.y / ESCENA.y) * 0.97
	_escena.scale = Vector2(k, k)
	_escena.position = (v - ESCENA * k) * 0.5

func _pie() -> void:
	var fila := HBoxContainer.new()
	fila.position = Vector2(36, 458)
	fila.size = Vector2(1128, 64)
	fila.add_theme_constant_override("separation", 10)
	_escena.add_child(fila)
	var b_av := boton(Idiomas.t("Avanzar"), true, 21)
	b_av.custom_minimum_size = Vector2(176, 46)
	b_av.pressed.connect(_pulsar)
	var b_ev := boton(Idiomas.t("Hasta el próximo evento"), false, 21)
	b_ev.custom_minimum_size = Vector2(242, 46)
	b_ev.pressed.connect(_pulsar)
	var b_menu := boton(Idiomas.t("Menú"), false, 21)
	b_menu.custom_minimum_size = Vector2(84, 46)
	b_menu.pressed.connect(_cerrar)
	for b: Button in [b_av, b_ev, b_menu]:
		fila.add_child(b)
	b_av.grab_focus.call_deferred()
	var libre := Control.new()
	libre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(libre)
	var ayuda := HBoxContainer.new()
	ayuda.add_theme_constant_override("separation", 5)
	for par: Array in [["Espacio", "avanzar"], ["N", "siguiente evento"], ["Esc", "menú"]]:
		ayuda.add_child(PantallaAvanzarPiezas.tecla(String(par[0])))
		ayuda.add_child(EstiloAvanzar.etiqueta(Idiomas.t(String(par[1])) + "   ", 11, EstiloAvanzar.SUAVE))
	fila.add_child(ayuda)

## Los eventos que se ven en la fecha `u` (unix): el de la parada, o los del calendario del juego para los días que vienen (lo de después no se conoce).
func _eventos_en(u: int) -> Array:
	if u == _unix_parada:
		return _res["eventos"]
	var off := roundi(float(u - Calendario.unix_de(_m.anio, _m.semana, 0)) / 86400.0)
	if off < 0 or off >= 21:
		return []
	if not _cache_ev.has(off):
		_cache_ev[off] = EventosDia.del_dia(_m, off / 7, off % 7)
	return _cache_ev[off]

## Pinta la ventana de dos semanas (de lunes a domingo) que contiene el día `i` del recorrido y mueve el cursor.
func _pintar(i: int) -> void:
	var u := _unix0 + i * 86400
	var fh := Time.get_datetime_dict_from_unix_time(u)
	var lunes := u - ((int(fh["weekday"]) + 6) % 7) * 86400
	for j in 14:
		var uj := lunes + j * 86400
		var f := Time.get_datetime_dict_from_unix_time(uj)
		var estado := "hoy" if uj == u else ("pasado" if uj < u else "futuro")
		PantallaAvanzarPiezas.pintar(_celdas[j], f, estado, _eventos_en(uj) if uj >= _unix0 else [], _acento, j == 0)
	_fecha.text = "%s %d · %s %d" % [Idiomas.t(String(Principal.MESES_LARGOS[int(fh["month"]) - 1])).capitalize(), int(fh["year"]), Idiomas.t("día"), int(fh["day"])]
	var total := maxi((_unix_parada - _unix0) / 86400, 1)
	_barra.size.x = 1128.0 * float(i) / float(total)
	_mostrar_vacio(fh)

func _mostrar_vacio(fh: Dictionary) -> void:
	for h in _cap.get_children():
		h.free()
	_fondo_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo_banner.modo = FondoCine.Modo.EVENTO
	_fondo_banner.color = Color("0c1426")
	_fondo_banner.franjas = false
	_fondo_banner.queue_redraw()
	var t := EstiloAvanzar.etiqueta("%s %d %s" % [Idiomas.t(String(Principal.DIAS_LARGOS[(int(fh["weekday"]) + 6) % 7])), int(fh["day"]), Idiomas.t(String(Principal.MESES_LARGOS[int(fh["month"]) - 1]))], 30, Color("cfd7ee"), true, true)
	t.position = Vector2(26, 86)
	_cap.add_child(t)

func _correr() -> void:
	var pasados: Array = _res["pasados"]
	if pasados.is_empty():
		_cerrar()
		return
	_tween = create_tween()
	for i in pasados.size():
		_tween.tween_callback(_mover.bind(i + 1))
		_tween.tween_interval(0.0 if Animar.reducidas() else PASO)
	_tween.tween_callback(_llegar)

func _mover(i: int) -> void:
	if _fase != 0:
		return
	_idx = i
	_pintar(i)

func _prioridad(ev: Dictionary) -> int:
	return {EventosDia.PARTIDO: 0, EventosDia.PANTALLA: 1}.get(String(ev.get("clase", "")), 2)

## El cursor llegó al día de evento: sale el banner con el arte (unos segundos) y luego se cierra.
func _llegar() -> void:
	if _fase != 0:
		return
	_fase = 1
	_pintar(_idx)
	var evs: Array = (_res["eventos"] as Array).duplicate()
	evs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _prioridad(a) < _prioridad(b))
	if not evs.is_empty():
		PantallaAvanzarBanner.armar(_cap, _fondo_banner, evs, _m, Time.get_datetime_dict_from_unix_time(_unix_parada))
		if not Animar.reducidas():
			_cap.position.x = -420.0
			_cap.modulate.a = 0.0
			var tb := create_tween().set_parallel(true)
			tb.tween_property(_cap, "position:x", 0.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tb.tween_property(_cap, "modulate:a", 1.0, 0.4)
	var tw := create_tween()
	tw.tween_interval(0.0 if Animar.reducidas() else DECORADO)
	tw.tween_callback(_cerrar)
	_tween = tw

func _pulsar() -> void:
	if _fase == 0:
		if _tween != null:
			_tween.kill()
		_mover((_res["pasados"] as Array).size())
		_llegar()
	else:
		_cerrar()

func _input(e: InputEvent) -> void:
	if _fase == 2:
		return
	var pulsa: bool = (e is InputEventKey and e.pressed and not e.echo) or (e is InputEventMouseButton and e.pressed) or e.is_action_pressed("ui_accept") or e.is_action_pressed("ui_cancel")
	if not pulsa or (e is InputEventMouseButton and get_viewport().gui_get_hovered_control() is Button):
		return
	get_viewport().set_input_as_handled()
	if e is InputEventKey and (e as InputEventKey).keycode == KEY_ESCAPE:
		_cerrar()
		return
	_pulsar()

func _cerrar() -> void:
	if _fase == 2:
		return
	_fase = 2
	if _tween != null:
		_tween.kill()
	cerrado.emit()
