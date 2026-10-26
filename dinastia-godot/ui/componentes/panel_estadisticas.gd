class_name PanelEstadisticas
extends Control
## ESTADÍSTICAS A PEDIDO (16-10-2026, pendiente de la línea del motor real y
## del vídeo de FC 26): un panel de transmisión que se abre con su botón
## (`jugar_estadisticas`, configurable en `Mando`) o desde la pausa. El partido
## se para mientras está abierto. Arriba el marcador, en el centro la tabla con
## barras enfrentadas (local a la izquierda, visita a la derecha) y debajo dos
## campos: el MAPA DE TIROS (tamaño = xG, relleno = a puerta, estrella = gol) y
## el MAPA DE CALOR del equipo elegido.

signal cerrado

var partido: Partido
var motor: MotorJugable
var datos: EstadisticasVivo
var _col_l := Color("3fa06a")
var _col_v := Color("e9eeea")
var _calor_eq := 0
var _campo_calor: Control
var _boton_calor: Button
var _caja: Control

static func abrir(padre: Control, p: Partido, m: MotorJugable, d: EstadisticasVivo) -> PanelEstadisticas:
	var n := PanelEstadisticas.new()
	n.partido = p
	n.motor = m
	n.datos = d if d != null else EstadisticasVivo.new()
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	n.z_index = 130
	padre.add_child(n)
	n._montar()
	return n

## Dos colores de equipo que se distingan (si los kits se parecen, la visita
## pasa a su segundo color o a blanco).
static func colores_equipos(local: Club, visita: Club) -> Array:
	var cl := Color(local.color_kit1()) if local != null else Color("3fa06a")
	var cv := Color(visita.color_kit1()) if visita != null else Color("e9eeea")
	if _parecidos(cl, cv) and visita != null:
		cv = Color(visita.color_kit2())
	if _parecidos(cl, cv):
		cv = Color("e9eeea") if cl.get_luminance() < 0.6 else Color("2a3a8f")
	## Muy oscuros no se ven sobre el panel (negro, azul marino): se aclaran
	## hacia un tono vivo; si así quedan iguales, la visita va en dorado.
	if cl.get_luminance() < 0.3:
		cl = _aclarar(cl)
	if cv.get_luminance() < 0.3:
		cv = _aclarar(cv)
	if _parecidos(cl, cv):
		cv = Tema.ORO
	return [cl, cv]

static func _aclarar(c: Color) -> Color:
	## Un color sin tinte (negro, gris oscuro) pasa a gris claro; uno con
	## tinte conserva el tono y gana luz.
	if c.s < 0.2:
		return Color(0.78, 0.8, 0.82)
	return Color.from_hsv(c.h, minf(c.s, 0.85), maxf(c.v, 0.85))

static func _parecidos(a: Color, b: Color) -> bool:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() < 0.28

func _montar() -> void:
	var cols := colores_equipos(partido.local if partido else null, partido.visita if partido else null)
	_col_l = cols[0]
	_col_v = cols[1]
	_calor_eq = 0 if (partido == null or partido.local.id == Partido.ctx_club_id or partido.visita.id != Partido.ctx_club_id) else 1
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.6)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := PanelContainer.new()
	_caja = caja
	var st := CuadroDialogo.estilo_panel()
	caja.add_theme_stylebox_override("panel", st)
	caja.custom_minimum_size = Vector2(980, 0)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	caja.add_child(v)
	## Cabecera de transmisión: placa, marcador y reloj.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)
	cab.add_child(CuadroDialogo.placa(Idiomas.t("ESTADÍSTICAS DEL PARTIDO")))
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(hueco)
	if partido != null:
		cab.add_child(_chip(_col_l))
		cab.add_child(Tema.etiqueta(20, Tema.TEXTO, "%s  %d - %d  %s" % [Nombres.visible(partido.local.nombre),
			partido.goles_local, partido.goles_visita, Nombres.visible(partido.visita.nombre)]))
		cab.add_child(_chip(_col_v))
		var minuto := motor.minuto() if motor != null else partido.minuto
		cab.add_child(Tema.etiqueta(18, Tema.ORO, "  %d'" % minuto))
	## Cuerpo: tabla a la izquierda, mapas a la derecha.
	var cuerpo := HBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 22)
	v.add_child(cuerpo)
	var tabla := VBoxContainer.new()
	tabla.add_theme_constant_override("separation", 5)
	tabla.custom_minimum_size = Vector2(470, 0)
	cuerpo.add_child(tabla)
	var i := 0
	for f: Array in datos.resumen(partido, motor):
		var fila := _fila(f)
		tabla.add_child(fila)
		## Entran escalonadas, como los rótulos de la tele.
		fila.modulate.a = 0.0
		var tw := fila.create_tween()
		tw.tween_interval(0.03 * i)
		tw.tween_property(fila, "modulate:a", 1.0, 0.18)
		i += 1
	var mapas := VBoxContainer.new()
	mapas.add_theme_constant_override("separation", 6)
	mapas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(mapas)
	mapas.add_child(Tema.etiqueta(13, Tema.ORO, Idiomas.t("MAPA DE TIROS")))
	var campo_tiros := MapaCampo.new()
	campo_tiros.modo = "tiros"
	campo_tiros.datos = datos
	campo_tiros.col_l = _col_l
	campo_tiros.col_v = _col_v
	campo_tiros.custom_minimum_size = Vector2(430, 200)
	mapas.add_child(campo_tiros)
	mapas.add_child(Tema.etiqueta(11, Tema.SUAVE, Idiomas.t("● tamaño = xG · relleno = a puerta · ★ gol")))
	var fila_calor := HBoxContainer.new()
	mapas.add_child(fila_calor)
	fila_calor.add_child(Tema.etiqueta(13, Tema.ORO, Idiomas.t("MAPA DE CALOR")))
	var h2 := Control.new()
	h2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_calor.add_child(h2)
	_boton_calor = Button.new()
	_boton_calor.focus_mode = Control.FOCUS_NONE
	_boton_calor.add_theme_font_size_override("font_size", 12)
	_boton_calor.pressed.connect(_cambiar_calor)
	fila_calor.add_child(_boton_calor)
	var mc := MapaCampo.new()
	mc.modo = "calor"
	mc.datos = datos
	mc.col_l = _col_l
	mc.col_v = _col_v
	mc.custom_minimum_size = Vector2(430, 200)
	mapas.add_child(mc)
	_campo_calor = mc
	_pintar_calor()
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 10)
	v.add_child(pie)
	var aviso := Tema.etiqueta(12, Tema.SUAVE, Idiomas.t("El partido está parado.") + "  " +
		Mando.corto_de("jugar_estadisticas") + " / " + Mando.corto_de("jugar_pausa") + ": " + Idiomas.t("volver") +
		## Las flechas ya cambiaban de equipo el mapa de calor, pero no lo decía nadie.
		"  ·  ← / →: " + Idiomas.t("mapa de calor del otro equipo"))
	aviso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(aviso)
	var seguir := Button.new()
	seguir.text = Idiomas.t("▶  Volver al partido")
	seguir.custom_minimum_size = Vector2(220, 36)
	seguir.add_theme_font_size_override("font_size", 16)
	seguir.pressed.connect(cerrar)
	pie.add_child(seguir)
	## Entrada: sube y aparece.
	caja.modulate.a = 0.0
	caja.pivot_offset = caja.custom_minimum_size * 0.5
	caja.scale = Vector2(0.96, 0.96)
	var tw2 := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw2.tween_property(caja, "modulate:a", 1.0, 0.22)
	tw2.tween_property(caja, "scale", Vector2.ONE, 0.25)
	Sonido.toca("menu_seccion")

func _chip(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.custom_minimum_size = Vector2(10, 22)
	return r

## Una fila: valor local, barra enfrentada con el nombre encima, valor visita.
func _fila(f: Array) -> Control:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 1)
	var arriba := HBoxContainer.new()
	caja.add_child(arriba)
	var a := Tema.etiqueta(15, Tema.TEXTO, String(f[1]))
	a.custom_minimum_size = Vector2(70, 0)
	arriba.add_child(a)
	var nom := Tema.etiqueta(13, Tema.SUAVE, Idiomas.t(String(f[0])))
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(nom)
	var b := Tema.etiqueta(15, Tema.TEXTO, String(f[2]))
	b.custom_minimum_size = Vector2(70, 0)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	arriba.add_child(b)
	var barra := BarraDoble.new()
	barra.l = float(f[3])
	barra.v = float(f[4])
	barra.col_l = _col_l
	barra.col_v = _col_v
	barra.custom_minimum_size = Vector2(0, 6)
	caja.add_child(barra)
	return caja

func _cambiar_calor() -> void:
	_calor_eq = 1 - _calor_eq
	_pintar_calor()
	Sonido.toca("menu_mover")

func _pintar_calor() -> void:
	if partido != null:
		_boton_calor.text = "⇄ " + Nombres.visible((partido.local if _calor_eq == 0 else partido.visita).nombre)
	(_campo_calor as MapaCampo).equipo = _calor_eq
	_campo_calor.queue_redraw()

func cerrar() -> void:
	if is_queued_for_deletion():
		return
	Sonido.toca("menu_atras")
	cerrado.emit()
	queue_free()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("jugar_estadisticas") or e.is_action_pressed("jugar_pausa") or e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()
	elif e.is_action_pressed("jugar_tac_izquierda") or e.is_action_pressed("jugar_tac_derecha") \
			or e.is_action_pressed("ui_left") or e.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_cambiar_calor()


## Barra enfrentada: lo del local crece desde el centro hacia la izquierda y lo
## de la visita hacia la derecha, en proporción al total.
class BarraDoble extends Control:
	var l := 0.0
	var v := 0.0
	var col_l := Color.WHITE
	var col_v := Color.WHITE
	var _k := 0.0
	func _ready() -> void:
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(x: float) -> void:
			_k = x
			queue_redraw(), 0.0, 1.0, 0.45)
	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.08))
		var tot := l + v
		if tot <= 0.0:
			return
		var mitad := w * 0.5
		var gana_l := l >= v
		draw_rect(Rect2(mitad - mitad * l / tot * _k, 0, mitad * l / tot * _k, h), col_l if gana_l else col_l.darkened(0.35))
		draw_rect(Rect2(mitad, 0, mitad * v / tot * _k, h), col_v if not gana_l else col_v.darkened(0.35))
		draw_rect(Rect2(mitad - 1, -2, 2, h + 4), Color(0, 0, 0, 0.6))


## Un campo visto desde arriba, a lo largo (el local ataca hacia la derecha).
class MapaCampo extends Control:
	var modo := "tiros"
	var datos: EstadisticasVivo
	var equipo := 0
	var col_l := Color.WHITE
	var col_v := Color.WHITE
	func _a_pantalla(p: Vector2, r: Rect2) -> Vector2:
		## p = (x, z) del motor: z a lo largo (izquierda→derecha), x a lo ancho.
		return Vector2(r.position.x + (p.y + EstadisticasVivo.LARGO) / (2.0 * EstadisticasVivo.LARGO) * r.size.x,
			r.position.y + (p.x + EstadisticasVivo.ANCHO) / (2.0 * EstadisticasVivo.ANCHO) * r.size.y)
	func _draw() -> void:
		## Que el campo guarde la proporción 105 x 68.
		var alto := minf(size.y, size.x * 68.0 / 105.0)
		var ancho := alto * 105.0 / 68.0
		var r := Rect2((size.x - ancho) * 0.5, (size.y - alto) * 0.5, ancho, alto)
		draw_rect(r, Color("1d5a33"))
		for k in 10:
			if k % 2 == 0:
				draw_rect(Rect2(r.position.x + r.size.x * k / 10.0, r.position.y, r.size.x / 10.0, r.size.y), Color("21653a"))
		if modo == "calor" and datos != null:
			var a: PackedInt32Array = datos.calor[equipo]
			var mx := 1
			for n in a:
				mx = maxi(mx, n)
			var cw := r.size.x / EstadisticasVivo.COLS
			var ch := r.size.y / EstadisticasVivo.FILAS
			for f in EstadisticasVivo.FILAS:
				for c in EstadisticasVivo.COLS:
					var val := float(a[f * EstadisticasVivo.COLS + c]) / float(mx)
					if val <= 0.02:
						continue
					## Frío (amarillo tenue) → caliente (rojo).
					var col := Color("ffd23f").lerp(Color("ff3b2f"), val)
					col.a = 0.18 + 0.62 * val
					draw_rect(Rect2(r.position.x + c * cw, r.position.y + f * ch, cw, ch), col)
		var linea := Color(1, 1, 1, 0.75)
		draw_rect(r, linea, false, 1.5)
		var mx2 := r.position.x + r.size.x * 0.5
		draw_line(Vector2(mx2, r.position.y), Vector2(mx2, r.end.y), linea, 1.2)
		draw_arc(r.get_center(), r.size.y * 9.15 / 68.0, 0, TAU, 32, linea, 1.2)
		for lado in [-1.0, 1.0]:
			var area_l := r.size.x * 16.5 / 105.0
			var area_a := r.size.y * 40.3 / 68.0
			var chica_l := r.size.x * 5.5 / 105.0
			var chica_a := r.size.y * 18.3 / 68.0
			var x0: float = r.position.x if lado < 0.0 else r.end.x - area_l
			draw_rect(Rect2(x0, r.get_center().y - area_a * 0.5, area_l, area_a), linea, false, 1.2)
			var x1: float = r.position.x if lado < 0.0 else r.end.x - chica_l
			draw_rect(Rect2(x1, r.get_center().y - chica_a * 0.5, chica_l, chica_a), linea, false, 1.2)
		if modo == "tiros" and datos != null:
			for t: Dictionary in datos.tiros:
				var c := col_l if bool(t["local"]) else col_v
				var p := _a_pantalla(t["pos"], r)
				var rad := 3.0 + 14.0 * sqrt(float(t["xg"]))
				var res := String(t["res"])
				if res == "gol":
					_estrella(p, rad + 2.0, c)
				elif res == "atajada":
					draw_circle(p, rad, c)
					draw_arc(p, rad, 0, TAU, 20, Color.BLACK, 1.0)
				else:
					draw_arc(p, rad, 0, TAU, 20, c, 2.0)
	func _estrella(p: Vector2, rad: float, c: Color) -> void:
		var pts := PackedVector2Array()
		for k in 10:
			var ang := -PI * 0.5 + k * PI / 5.0
			var rr := rad if k % 2 == 0 else rad * 0.45
			pts.append(p + Vector2(cos(ang), sin(ang)) * rr)
		draw_colored_polygon(pts, c)
		pts.append(pts[0])
		draw_polyline(pts, Color.BLACK, 1.0)
