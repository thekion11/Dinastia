class_name ResumenPartido
extends Control
## EL PARTIDO EN RESUMEN O INSTANTÁNEO (25-9-2026, plan maestro B2).
##
## Juega el partido ENTERO de una vez -los mismos `simular_minuto()` que el
## partido en vivo y el 3D, así que el resultado es el mismo- escuchando sus
## señales, y después lo cuenta:
##  - `animado = true` ("Resumen"): las jugadas clave aparecen una a una, con
##    el marcador que se actualiza en cada gol, en unos 20 segundos. "Saltar"
##    lo termina de golpe.
##  - `animado = false` ("Instantáneo"): directamente el final, con la lista.
## "Continuar" emite `cerrado`; quien lo abrió avanza la semana con este mismo
## `Partido`, igual que al cerrar un partido en vivo.

signal cerrado

const DURACION_RESUMEN := 20.0
const COL_FONDO := Color("0b1410")
const COL_TEXTO := Color("e9eeea")
const COL_SUAVE := Color("8ea595")
const COL_ORO := Color("c9a227")
const COL_BIEN := Color("4caf6d")
const COL_MAL := Color("e05555")

var partido: Partido
var mi_club: Club
var eliminatoria := false
var _momentos: Array = []   ## {min, icono, txt, gl, gv, clave}
var _mostrados := 0
var _marcador: Label
var _reloj: Label
var _lista: VBoxContainer
var _btn_saltar: Button
var _btn_seguir: Button
var _t := 0.0
var _animado := true
var _penales: Array = []

## `partido` debe venir ya con `preparar()` hecho.
static func mostrar(padre: Control, p: Partido, club: Club, es_eliminatoria: bool, animado: bool) -> ResumenPartido:
	var r := ResumenPartido.new()
	r.partido = p
	r.mi_club = club
	r.eliminatoria = es_eliminatoria
	r._animado = animado
	padre.add_child(r)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r._jugar()
	r._construir()
	if not animado:
		r._mostrar_todo()
	return r

func _jugar() -> void:
	partido.gol.connect(func(c: Club, autor: Jugador, m: int, asis: Jugador) -> void:
		var txt := "¡Gol de %s! %s" % [c.nombre, autor.nombre if autor != null else ""]
		if asis != null:
			txt += "  (asiste %s)" % asis.nombre
		_anotar(m, "⚽", txt, "gol"))
	partido.tarjeta.connect(func(j: Jugador, roja: bool, m: int) -> void:
		if roja:
			_anotar(m, "🟥", "Roja a %s" % j.nombre, "roja"))
	partido.lesion.connect(func(j: Jugador, semanas: int, m: int) -> void:
		_anotar(m, "🚑", "%s se lesiona: %d semana%s" % [j.nombre, semanas, "" if semanas == 1 else "s"], "lesion"))
	partido.remate.connect(_al_remate)
	partido.invasion_de_campo.connect(func(m: int) -> void:
		_anotar(m, "🚨", "Invasión de campo: la barra salta al césped y el partido se para", "invasion"))
	while not partido.terminado_ya:
		partido.simular_minuto()
	if eliminatoria and partido.goles_local == partido.goles_visita:
		_penales = partido.penales()

func _al_remate(c: Club, autor: Jugador, tipo: String, m: int) -> void:
	## Nada de `Azar` aquí: contar el partido no puede consumir el generador,
	## o el resumen cambiaría el resultado que cuenta.
	var quien := autor.nombre if autor != null else "el remate"
	if tipo == "poste":
		_anotar(m, "🥅", "¡Al palo! %s (%s)" % [quien, c.nombre], "ocasion")
	elif tipo == "atajada":
		_anotar(m, "🧤", "El portero le saca el remate a %s (%s)" % [quien, c.nombre], "ocasion")

func _anotar(m: int, icono: String, txt: String, clave: String) -> void:
	## El marcador se toma DESPUÉS del suceso: en un gol, la señal llega con el
	## tanto ya sumado.
	_momentos.append({"min": m, "icono": icono, "txt": txt, "gl": partido.goles_local, "gv": partido.goles_visita, "clave": clave})

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 12)
	add_child(raiz)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 80
	raiz.offset_right = -80
	raiz.offset_top = 40
	raiz.offset_bottom = -30
	var tit := _texto(12, COL_SUAVE)
	tit.text = "RESUMEN DEL PARTIDO" if _animado else "RESULTADO"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(tit)
	_marcador = _texto(38, COL_TEXTO)
	_marcador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_marcador)
	_reloj = _texto(15, COL_ORO)
	_reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_reloj)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	raiz.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 6)
	scroll.add_child(_lista)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 10)
	raiz.add_child(fila)
	_btn_saltar = Button.new()
	_btn_saltar.text = "⏭ Saltar"
	_btn_saltar.custom_minimum_size = Vector2(140, 36)
	_btn_saltar.pressed.connect(_mostrar_todo)
	fila.add_child(_btn_saltar)
	_btn_seguir = Button.new()
	_btn_seguir.text = "Continuar ▶"
	_btn_seguir.custom_minimum_size = Vector2(160, 36)
	_btn_seguir.visible = false
	_btn_seguir.pressed.connect(func() -> void: cerrado.emit())
	fila.add_child(_btn_seguir)
	_pintar_marcador(0, 0, 0)

func _process(delta: float) -> void:
	if not _animado or _mostrados >= _momentos.size() and _btn_seguir.visible:
		return
	_t += delta
	var minuto_visto := int(clampf(_t / DURACION_RESUMEN, 0.0, 1.0) * float(Partido.MINUTOS))
	while _mostrados < _momentos.size() and int(_momentos[_mostrados]["min"]) <= minuto_visto:
		_revelar(_momentos[_mostrados])
		_mostrados += 1
	if _t >= DURACION_RESUMEN:
		_mostrar_todo()
	else:
		_reloj.text = "%d'" % minuto_visto

func _revelar(mo: Dictionary) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	var m := _texto(14, COL_SUAVE)
	m.text = "%d'" % int(mo["min"])
	m.custom_minimum_size = Vector2(44, 0)
	fila.add_child(m)
	var ic := _texto(16, COL_TEXTO)
	ic.text = String(mo["icono"])
	fila.add_child(ic)
	var tx := _texto(15, COL_TEXTO if String(mo["clave"]) != "gol" else COL_ORO)
	tx.text = String(mo["txt"])
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(tx)
	_lista.add_child(fila)
	## Entra deslizándose y aparece: se lee como algo que acaba de pasar.
	fila.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fila, "modulate:a", 1.0, 0.3)
	if String(mo["clave"]) == "gol":
		_pintar_marcador(int(mo["gl"]), int(mo["gv"]), int(mo["min"]))
		Sonido.toca("gol" if _es_mio(int(mo["gl"]), int(mo["gv"])) else "gol_rival")
		_marcador.pivot_offset = _marcador.size * 0.5
		_marcador.scale = Vector2(1.18, 1.18)
		tw.tween_property(_marcador, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## ¿El último gol fue del usuario? Se mira qué lado subió.
func _es_mio(gl: int, gv: int) -> bool:
	var subio_local := gl > int(_marcador.get_meta("gl", 0))
	return subio_local == (partido.local == mi_club)

func _pintar_marcador(gl: int, gv: int, _m: int) -> void:
	_marcador.set_meta("gl", gl)
	_marcador.text = "%s   %d - %d   %s" % [partido.local.nombre, gl, gv, partido.visita.nombre]

func _mostrar_todo() -> void:
	while _mostrados < _momentos.size():
		var mo: Dictionary = _momentos[_mostrados]
		_revelar(mo)
		_mostrados += 1
	_pintar_marcador(partido.goles_local, partido.goles_visita, Partido.MINUTOS)
	var mio_local := partido.local == mi_club
	var mios := partido.goles_local if mio_local else partido.goles_visita
	var suyos := partido.goles_visita if mio_local else partido.goles_local
	var fin := "VICTORIA" if mios > suyos else ("DERROTA" if mios < suyos else "EMPATE")
	var col := COL_BIEN if mios > suyos else (COL_MAL if mios < suyos else COL_SUAVE)
	_reloj.text = "FINAL · " + fin
	_reloj.add_theme_color_override("font_color", col)
	if not _penales.is_empty():
		var pase_local := int(_penales[0]) > int(_penales[1])
		var l := _texto(15, COL_ORO)
		l.text = "Penales %d - %d: %s" % [int(_penales[0]), int(_penales[1]),
			"pasas de ronda" if pase_local == mio_local else "quedas eliminado"]
		_lista.add_child(l)
	if _momentos.is_empty():
		var nada := _texto(14, COL_SUAVE)
		nada.text = "Un partido sin grandes ocasiones."
		_lista.add_child(nada)
	## Los números del partido, los mismos que da la crónica en vivo.
	var sep := HSeparator.new()
	_lista.add_child(sep)
	var stats := _texto(14, COL_SUAVE)
	stats.text = "Posesión %d%% - %d%%   ·   Remates %d - %d   ·   Al arco %d - %d   ·   xG %.2f - %.2f" % [
		int(round(partido.posesion_local)), 100 - int(round(partido.posesion_local)),
		partido.remates_local, partido.remates_visita,
		partido.tiros_puerta_local, partido.tiros_puerta_visita,
		partido.xg_local, partido.xg_visita]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lista.add_child(stats)
	_btn_saltar.visible = false
	_btn_seguir.visible = true
	Sonido.toca("pitido_final")
	set_process(false)

func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l
