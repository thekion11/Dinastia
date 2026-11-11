class_name ControlesTactiles
extends Control
## CONTROLES TÁCTILES DEL PARTIDO (M-433, 27-10-2026; rehechos el 4-11 tras la revisión del dueño; REHECHOS OTRA VEZ el 11-11-2026 al estilo FC MOBILE, pedido del dueño:
## `docs/04_auditorias/MANDO_TACTIL_FC_2026-11-11.md`). Un stick virtual FLOTANTE a la izquierda y, a la derecha, SIEMPRE 4 botones fijos (`MandoFC`: SP grande abajo a la derecha, PA abajo a la izquierda,
## AH arriba a la izquierda, TI arriba a la derecha) que cambian de función, etiqueta y color con la posesión (con balón: Sprint y regate · Pase · Al hueco · Tiro; sin balón: Sprint y entrada ·
## Cambiar · 2.º defensor · Barrida), con GESTOS por botón (deslizar hacia donde indican los triangulitos del aro) y el botón II de pausa arriba a la derecha, bajo las estadísticas.
## No tiene lógica de juego: pulsa y suelta las MISMAS acciones del InputMap (`Mando.MAPA`) que el mando físico y el teclado, que no cambian. Varios dedos a la vez; cada dedo se queda con lo que tocó al empezar.
##   stick      jugar_izquierda/derecha/arriba/abajo, con fuerza analógica (aparece donde se toca, en el 45 % izquierdo y por debajo del 20 % de arriba; radio `RADIO_STICK`)
##   zona libre (modos Gestos y Ambos): tocar a un compañero = pase a él (`PaseTactil`), tocar = pase, deslizar hacia arriba = tiro (más largo = más fuerte)
## Tamaño, opacidad, separación, modo de control (Botones / Gestos / Ambos), cuándo salen y modo zurdo: Ajustes → Dispositivo (`AjustesTactil`). Medidas: el botón grande ≈ 1,6 cm y los otros ≈ 1,2 cm (`escala`, por los
## puntos por pulgada), con ≥ 2 mm entre bordes; respeta el área segura (muescas). `zurdo` espeja todo salvo el botón de pausa. VERTICAL (sesión 8): el mismo arco, con el tamaño topado (`ESCALA_VERTICAL`).
const RADIO_STICK := 112.0
const RADIO_PAUSA := 44.0
const DIRS := {"jugar_izquierda": Vector2.LEFT, "jugar_derecha": Vector2.RIGHT, "jugar_arriba": Vector2.UP, "jugar_abajo": Vector2.DOWN}
const BOTONES: Array[String] = ["SP", "PA", "AH", "TI", "Pausa"]
const ESCALA_VERTICAL := 0.7
const ZONA_STICK_X := 0.45              ## el stick solo nace en este tramo del ancho (el lado del pulgar izquierdo)
const ZONA_STICK_Y := 0.2               ## y por debajo de este tramo de arriba (no tapa el marcador)
const MS_TRANSICION := 0.15             ## el cambio de etiqueta y color al cambiar la posesión
const PX_DESLIZA := 70.0                ## lo que hay que arrastrar en la zona libre para que cuente como deslizar (px del lienzo)

static var forzar := false             ## las pruebas lo encienden; en el teléfono sale solo
static var zurdo := false              ## espejo forzado por las pruebas; el de verdad sale de Ajustes (`AjustesTactil.zurdo`)
static var mando_forzado := ""         ## las pruebas fuerzan el modo de control
static var contexto_forzado := ""      ## y el contexto de las capturas: «con» (balón), «banda» (balón en la banda cerca del área) o «sin» (defensa); vacío = el del juego
## ppp, ventana y lienzo (y sus valores forzados por las pruebas) viven en `PantallaMovil` (A4, 4-11: el menú no debe arrastrar el partido).
static func ventana() -> Vector2i: return PantallaMovil.ventana()
static func dpi() -> float: return PantallaMovil.dpi()

var _dedo_stick := -1
var _centro_stick := Vector2.ZERO
var _vec := Vector2.ZERO
var _dedos := {}                       ## índice de dedo → nombre del botón
var esc := 1.0                         ## tamaño elegido en Ajustes (1 = el de siempre)
var opac := 1.0                        ## opacidad elegida en Ajustes
var _zurdo := false
var _con_balon := true                 ## el jugador que llevas tiene el balón (cambia las etiquetas, los colores y las funciones)
var _en_banda := false                 ## y está en la banda cerca del área (el Pase pasa a centrar)
var _suelto_propio := false            ## el balón anda suelto en tu mitad (la Barrida pasa a Despeje)
var _mezcla := 1.0                     ## 0 = sin balón, 1 = con balón; se mueve en `MS_TRANSICION` s (transición de etiqueta y color)
var _modo_mando := "ambos"             ## botones / gestos / ambos (Ajustes)
var _sep := 1.0                        ## separación entre botones (Ajustes, 1-1,3)
var _gesto := {}                       ## índice de dedo → {tipo: "boton" | "libre", b, ini, t, viva, mant, fin}
var _elev := 0.0                       ## lo que sube el arco para no tapar la ficha del jugador (ver `_calcular_elev`)
var _bajo_stats := 0.0                 ## dónde acaba por abajo la ficha de estadísticas de arriba a la derecha (el II va debajo)

## Lo añade al partido si el aparato es táctil (o `forzar`). Devuelve el control (null si no hacía falta).
static func poner(padre: Node) -> ControlesTactiles:
	var modo := AjustesTactil.modo()
	if modo == "no" or not (forzar or modo == "si" or CargaCiudad.de("ExploradorCiudad").es_tactil()):
		return null
	var c := ControlesTactiles.new()
	c.name = "ControlesTactiles"
	padre.add_child(c)
	return c

func _ready() -> void:
	esc = AjustesTactil.tamano()
	opac = AjustesTactil.opacidad()
	_sep = AjustesTactil.separacion()
	_modo_mando = mando_forzado if mando_forzado != "" else AjustesTactil.mando()
	_zurdo = zurdo or AjustesTactil.zurdo()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20

## La línea de ayuda de teclado y mando del partido sobra con los botones en pantalla y tapa su borde: se mantiene oculta aunque el partido la vuelva a mostrar.
func _process(d: float) -> void:
	var ayuda: Variant = get_parent().get("_ayuda") if get_parent() != null else null
	if ayuda is CanvasItem and (ayuda as CanvasItem).visible:
		(ayuda as CanvasItem).visible = false
	var e := _calcular_elev()
	var bs := _calcular_bajo_stats()
	if absf(e - _elev) > 0.5 or absf(bs - _bajo_stats) > 0.5:
		_elev = e
		_bajo_stats = bs
		queue_redraw()
	var cb := _tengo_balon() if contexto_forzado == "" else contexto_forzado != "sin"
	var eb := _estoy_en_banda() if contexto_forzado == "" else contexto_forzado == "banda"
	var sp := _suelto_en_mi_mitad() if contexto_forzado == "" else false
	if cb != _con_balon or eb != _en_banda or sp != _suelto_propio:
		var cambia_funcion := cb != _con_balon or sp != _suelto_propio
		_con_balon = cb
		_en_banda = eb
		_suelto_propio = sp
		if cambia_funcion:
			_reaplicar_dedos()
		queue_redraw()
	var objetivo := 1.0 if _con_balon else 0.0
	if not is_equal_approx(_mezcla, objetivo):
		_mezcla = move_toward(_mezcla, objetivo, d / MS_TRANSICION)
		queue_redraw()

## (11-11) Si el arco de botones se cruza en horizontal con la ficha del jugador de abajo (`_hud_abajo` del partido: en vertical, o con el modo zurdo), el arco sube por encima de ella en vez de taparla.
func _calcular_elev() -> float:
	var abajo: Variant = get_parent().get("_hud_abajo") if get_parent() != null else null
	if not (abajo is Array):
		return 0.0
	var s := escala()
	var m := margenes()
	var ancho_arco := MandoFC.ANCHO_ARCO
	var x0 := (m.x) if _espejo() else (size.x - m.y - ancho_arco * s * _sep)
	var x1 := (m.x + ancho_arco * s * _sep) if _espejo() else (size.x - m.y)
	var e := 0.0
	for c: Variant in abajo:
		if not (c is Control) or not is_instance_valid(c) or not (c as Control).is_visible_in_tree():
			continue
		var r := (c as Control).get_global_rect()
		if r.position.x < x1 and r.end.x > x0 and r.position.y < size.y:
			e = maxf(e, size.y - r.position.y + 8.0 * s)
	return e

## El borde de abajo de los paneles del HUD anclados arriba a la derecha (las estadísticas), para poner el II debajo.
func _calcular_bajo_stats() -> float:
	var hud: Variant = get_parent().get("_hud") if get_parent() != null else null
	if not (hud is Array):
		return 0.0
	var b := 0.0
	for c: Variant in hud:
		if c is Control and is_instance_valid(c) and (c as Control).is_visible_in_tree() and (c as Control).anchor_left >= 0.99 and (c as Control).anchor_top <= 0.01:
			b = maxf(b, (c as Control).get_global_rect().end.y)
	return b

## ¿Está el jugador que llevas en la banda, cerca de la línea de fondo rival (donde se centra)? Sin motor, no.
func _estoy_en_banda() -> bool:
	var motor: Variant = get_parent().get("motor") if get_parent() != null else null
	if motor == null or motor.usuario.is_empty():
		return false
	var yo: Vector3 = motor.pos(motor.usuario)
	var arco: Vector3 = motor._arco_rival(motor.usuario)
	return absf(yo.x) > 14.0 and absf(arco.z - yo.z) < 38.0

## ¿Anda el balón suelto en tu mitad (sin dueño, del lado de tu propio arco)? Entonces la Barrida es un Despeje.
func _suelto_en_mi_mitad() -> bool:
	var motor: Variant = get_parent().get("motor") if get_parent() != null else null
	if motor == null or motor.usuario.is_empty() or not motor.poseedor.is_empty() or motor.balon == null:
		return false
	return motor.balon.position.z * motor.dir_ataque(bool(motor.usuario["es_local"])) < 0.0

func _gestos() -> bool:
	return _modo_mando != "botones"

## ¿Se ve (y se puede pulsar) este botón ahora? `con_balon` / `en_banda` / `modo` son los de este momento (las pruebas los pasan). Siempre salen los 4 (modo Gestos: solo Sprint y, sin balón, Cambiar).
func visible_en(nombre: String, con_balon: bool, _en_banda_: bool, modo: String) -> bool:
	if modo == "gestos":
		return nombre == "Pausa" or nombre == "SP" or (nombre == "PA" and not con_balon)
	return true

func visible_ahora(nombre: String) -> bool:
	return visible_en(nombre, _con_balon, _en_banda, _modo_mando)

## ¿Tiene el balón el jugador que manejas? Sin motor (pruebas sueltas) se queda como con balón.
func _tengo_balon() -> bool:
	var motor: Variant = get_parent().get("motor") if get_parent() != null else null
	if motor == null:
		return true
	var yo: Dictionary = motor.usuario
	return not yo.is_empty() and motor.poseedor == yo

## La etiqueta de un botón en este momento (con o sin balón); «II» el de pausa.
func etiqueta_de(nombre: String, con_balon: bool) -> String:
	return "II" if nombre == "Pausa" else MandoFC.etiqueta(nombre, con_balon, _suelto_propio)

func _exit_tree() -> void:
	soltar_todo()

func _espejo() -> bool:
	return _zurdo or zurdo

## Factor de tamaño: proporcional a la altura del lienzo y, en un móvil de verdad, a los puntos por pulgada (el botón grande mide ≈1,6 cm sea cual sea la pantalla); por el tamaño elegido en Ajustes; y sin pasar de lo que
## cabe (el arco de botones no sube del 35 % de arriba). Nunca menos de 0,5.
func escala() -> float:
	var base := clampf(size.y / 720.0, 0.6, 1.25)
	var dpi_v := dpi()
	if dpi_v > 0.0:
		var vent := ventana()
		if vent.y > 0:
			var px_por_cm := dpi_v / 2.54 * size.y / float(vent.y)   ## píxeles del lienzo por cm de pantalla
			base = clampf(0.75 * px_por_cm / 66.0, 0.6, 1.5)        ## radio de un botón mediano ≈ 0,6 cm
	if _vertical():
		base = minf(base, ESCALA_VERTICAL)
	var cabe := 0.65 * size.y / MandoFC.ALTO_ARCO if size.y > 0.0 else base
	return maxf(minf(base * esc, maxf(cabe, base)), 0.5)

func _vertical() -> bool:
	return size.y > size.x

func radio_stick() -> float:
	return RADIO_STICK * escala()

## Márgenes por muescas y esquinas redondeadas: x = izquierda, y = derecha (en píxeles del lienzo). 0 fuera de un móvil.
func margenes(ancho_lienzo := 0.0) -> Vector2:
	if not OS.has_feature("mobile"):
		return Vector2.ZERO
	var vent := ventana()
	var seg := DisplayServer.get_display_safe_area()
	var pant := DisplayServer.screen_get_size()
	if vent.x <= 0 or pant.x <= 0 or seg.size.x <= 0:
		return Vector2.ZERO
	var k := (ancho_lienzo if ancho_lienzo > 0.0 else size.x) / float(vent.x)
	return Vector2(maxf(0.0, float(seg.position.x)), maxf(0.0, float(pant.x - seg.position.x - seg.size.x))) * k

## Radio de un botón en este tamaño de pantalla.
func radio_de(nombre: String) -> float:
	return (RADIO_PAUSA if nombre == "Pausa" else MandoFC.radio(nombre)) * escala()

## Dónde está el centro de un botón en este tamaño de pantalla.
func centro_de(nombre: String) -> Vector2:
	var s := escala()
	var m := margenes()
	if nombre == "Pausa":
		return Vector2(size.x - m.y - 24.0 * s - radio_de(nombre), maxf(96.0 * s, _bajo_stats + 12.0 * s) + radio_de(nombre))   ## bajo la ficha de estadísticas de arriba a la derecha
	var off := MandoFC.offset(nombre, _vertical())
	var x := (m.x + off.x * s * _sep) if _espejo() else (size.x - m.y - off.x * s * _sep)
	return Vector2(x, size.y - _elev - off.y * s * _sep)

## Dónde se dibuja el stick en reposo (el pulgar izquierdo; por encima de la ficha del jugador, abajo a la izquierda).
func centro_reposo() -> Vector2:
	var s := escala()
	var m := margenes()
	var x := (size.x - m.y - (RADIO_STICK + 60.0) * s) if _espejo() else (m.x + (RADIO_STICK + 60.0) * s)
	return Vector2(x, size.y - (RADIO_STICK + 185.0) * s)   ## por encima de la ficha del jugador (abajo a la izquierda, que con letra grande mide más)

func _boton_en(pos: Vector2) -> String:
	var mejor := ""
	var md := INF
	for n: String in BOTONES:
		if not visible_ahora(n):
			continue
		var d := centro_de(n).distance_to(pos)
		if d <= radio_de(n) * (1.0 if n == "Pausa" else 1.15) and d < md:   ## 15 % de margen alrededor: un dedo grande no falla; el más cercano gana
			md = d
			mejor = n
	return mejor

## ¿Está `pos` en la zona donde puede nacer el stick?
func _en_zona_stick(pos: Vector2) -> bool:
	var lado := pos.x > size.x * (1.0 - ZONA_STICK_X) if _espejo() else pos.x < size.x * ZONA_STICK_X
	return lado and pos.y > size.y * ZONA_STICK_Y

func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if ev is InputEventScreenTouch:
		var t := ev as InputEventScreenTouch
		if t.pressed:
			_toca(t.index, t.position)
		else:
			_suelta(t.index)
	elif ev is InputEventScreenDrag:
		var d := ev as InputEventScreenDrag
		if d.index == _dedo_stick:
			_mueve_stick(d.position)
		elif _gesto.has(d.index):
			_desliza(d.index, d.position)

func _toca(dedo: int, pos: Vector2) -> void:
	var b := _boton_en(pos)
	if b == "Pausa":
		_dedos[dedo] = b
		Input.action_press("jugar_pausa")
	elif b != "":
		_dedos[dedo] = b
		var mant := MandoFC.al_tocar(b, _con_balon, _gestos(), _suelto_propio)
		_gesto[dedo] = {"tipo": "boton", "b": b, "ini": pos, "t": Time.get_ticks_msec(), "viva": false, "mant": mant.duplicate()}
		for a: String in mant:
			Input.action_press(a)
	elif _dedo_stick < 0 and _en_zona_stick(pos):
		_dedo_stick = dedo
		_centro_stick = pos
		_mueve_stick(pos)
	elif _gestos() and not _en_zona_stick(pos):
		_gesto[dedo] = {"tipo": "libre", "ini": pos}   ## (un segundo dedo en la zona del stick, con el stick ya en uso, no cuenta) zona libre: tocar = pase, deslizar hacia arriba = tiro
	queue_redraw()

## Un dedo que empezó un gesto se mueve: desde un botón, el gesto de ese botón en esa dirección (una vez por toque); en la zona libre, solo se anota.
func _desliza(dedo: int, pos: Vector2) -> void:
	var g: Dictionary = _gesto[dedo]
	if String(g["tipo"]) == "libre":
		g["fin"] = pos
		return
	if bool(g["viva"]) or not _gestos():
		return
	var b := String(g["b"])
	var dir := MandoFC.direccion(pos - (g["ini"] as Vector2), radio_de(b) * 0.9)
	if dir == "":
		return
	g["viva"] = true   ## ya no es un toque: aunque ese gesto no haga nada, levantar el dedo no pasa ni regatea
	var r := MandoFC.al_deslizar(b, _con_balon, _en_banda, dir)
	for a: String in r.get("mant", []):
		Input.action_press(a)
		(g["mant"] as Array).append(a)
	if r.has("pulso"):
		_pulsar(r["pulso"], float(r.get("dur", 0.08)))

## Pulsa varias acciones a la vez un rato y las suelta (un toque o un gesto).
func _pulsar(acciones: Array, seg: float) -> void:
	for a: String in acciones:
		Input.action_press(a)
	if is_inside_tree():
		get_tree().create_timer(seg).timeout.connect(func() -> void:
			for a2: String in acciones:
				Input.action_release(a2))

func _suelta(dedo: int) -> void:
	if _gesto.has(dedo):
		_fin_gesto(dedo)
	if dedo == _dedo_stick:
		_dedo_stick = -1
		_vec = Vector2.ZERO
		_aplicar_stick()
	elif _dedos.has(dedo):
		if String(_dedos[dedo]) == "Pausa":
			Input.action_release("jugar_pausa")
		_dedos.erase(dedo)
	queue_redraw()

## Se levanta el dedo: suelta lo mantenido; un toque (sin deslizar) hace lo suyo (Sprint corto = regate, Pase/Al hueco con gestos); zona libre: toque = pase, deslizar arriba = tiro.
func _fin_gesto(dedo: int) -> void:
	var g: Dictionary = _gesto[dedo]
	_gesto.erase(dedo)
	if String(g["tipo"]) == "boton":
		for a: String in g["mant"]:
			Input.action_release(a)
		if not bool(g["viva"]):
			var r := MandoFC.al_soltar_toque(String(g["b"]), _con_balon, _gestos(), Time.get_ticks_msec() - int(g["t"]))
			if r.has("pulso"):
				_pulsar(r["pulso"], float(r.get("dur", 0.08)))
		return
	var d: Vector2 = (g["fin"] as Vector2 if g.has("fin") else g["ini"] as Vector2) - (g["ini"] as Vector2)
	if d.length() < PX_DESLIZA * 0.5:
		var q := PaseTactil.receptor_en(get_parent(), g["ini"] as Vector2)   ## tocar a un compañero = pase a él
		if not q.is_empty():
			MotorPaseDirigido.pedir(get_parent().get("motor"), q)
		_pulsar(["jugar_pase"], 0.08)
	elif d.y < -PX_DESLIZA * 0.6 and absf(d.y) >= absf(d.x) * 0.5:
		_pulsar(["jugar_tiro"], clampf(d.length() / 500.0, 0.2, 0.7))

## Cambia la posesión con un dedo puesto: lo mantenido por el botón pasa a ser lo del contexto nuevo (sin soltar y volver a tocar).
func _reaplicar_dedos() -> void:
	for dedo: int in _gesto:
		var g: Dictionary = _gesto[dedo]
		if String(g["tipo"]) != "boton":
			continue
		for a: String in g["mant"]:
			Input.action_release(a)
		var mant := MandoFC.al_tocar(String(g["b"]), _con_balon, _gestos(), _suelto_propio)
		g["mant"] = mant.duplicate()
		g["viva"] = true   ## ya no es un toque
		for a: String in mant:
			Input.action_press(a)

func _mueve_stick(pos: Vector2) -> void:
	_vec = ((pos - _centro_stick) / radio_stick()).limit_length(1.0)
	_aplicar_stick()
	queue_redraw()

## Las cuatro acciones de dirección con la fuerza que toque (el motor lee `Mando.movimiento`, que es analógico).
func _aplicar_stick() -> void:
	for a: String in DIRS:
		var f := maxf(0.0, _vec.dot(DIRS[a]))
		if f > 0.0:
			Input.action_press(a, f)
		else:
			Input.action_release(a)

func soltar_todo() -> void:
	for a: String in DIRS:
		Input.action_release(a)
	for dedo: int in _gesto:
		var g: Dictionary = _gesto[dedo]
		if String(g["tipo"]) == "boton":
			for a: String in g["mant"]:
				Input.action_release(a)
	for d: int in _dedos:
		if String(_dedos[d]) == "Pausa":
			Input.action_release("jugar_pausa")
	_dedos.clear()
	_gesto.clear()
	_dedo_stick = -1
	_vec = Vector2.ZERO

func _draw() -> void:
	var s := escala()
	var rs := radio_stick()
	var c0 := _centro_stick if _dedo_stick >= 0 else centro_reposo()
	var en_uso := _dedo_stick >= 0
	draw_circle(c0, rs, Color(1, 1, 1, (0.13 if en_uso else 0.07) * opac))
	draw_arc(c0, rs, 0.0, TAU, 48, Color(1, 1, 1, (0.55 if en_uso else 0.30) * opac), 3.0)
	draw_circle(c0 + _vec * rs, rs * 0.38, Color(1, 1, 1, (0.50 if en_uso else 0.25) * opac))
	var alfa := 0.3 + 0.7 * absf(2.0 * _mezcla - 1.0)   ## el texto se apaga un instante al cambiar la posesión
	for n: String in BOTONES:
		if not visible_ahora(n):
			continue
		var pausa := n == "Pausa"
		var col := Color(0.8, 0.8, 0.85) if pausa else MandoFC.color(n, true).lerp(MandoFC.color(n, false), 1.0 - _mezcla)
		var activo := _dedos.values().has(n)
		var etiqueta := etiqueta_de(n, _con_balon if (pausa or _mezcla == 0.0 or _mezcla == 1.0) else _mezcla >= 0.5)
		var tri: Array = [] if pausa or not _gestos() else MandoFC.triangulos(n, _con_balon, _en_banda)
		DibujoBotonFC.boton(self, centro_de(n), radio_de(n), col, Idiomas.t(etiqueta).split("\n") if not pausa else PackedStringArray([etiqueta]), opac, activo, false, s, tri, 1.0 if pausa else alfa,
				0.6 if pausa else 0.42, 0.55 if pausa else 0.30)
