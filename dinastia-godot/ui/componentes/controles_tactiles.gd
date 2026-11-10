class_name ControlesTactiles
extends Control
## CONTROLES TÁCTILES DEL PARTIDO (M-433, 27-10-2026; rehechos el 4-11-2026 tras la revisión del dueño: «la posición y el estándar están mal»; unidos con los ajustes y los botones nuevos de main, 3-11). Un stick virtual
## FLOTANTE a la izquierda y los botones del mando a la derecha, en ARCO alrededor del reposo del pulgar derecho (esquina inferior derecha), como los juegos de fútbol de móvil (FIFA Mobile, eFootball, Dream League):
## lo más usado (Pase, Tiro) abajo y grande, lo secundario (Al hueco, Centro, Mod, Cambiar) más arriba y pequeño; arriba a la derecha, bajo las estadísticas, el botón II de pausa. No tiene lógica de juego: pulsa y
## suelta las MISMAS acciones del InputMap (`Mando.MAPA`), así que el motor, el tutorial y el mando físico no se enteran. Varios dedos a la vez; cada dedo se queda con el control que tocó al empezar.
##   stick      jugar_izquierda/derecha/arriba/abajo, con fuerza analógica (aparece donde se toca, en el 45 % izquierdo y por debajo del 20 % de arriba; radio `RADIO_STICK`)
##   A Pase · Presión   B Tiro · Entrada   X Centro · Barrida   Y Pase al hueco   Cambiar   Sprint (se mantiene)   Mod (rosca, tenso, vaselina…)   II pausa / táctica y cambios
## MENOS BOTONES a la vez (4-11-2026, evaluación de la líder frente a FC Mobile y DLS): con balón se ven Pase, Al hueco, Tiro y Sprint (+ Centro solo en la banda cerca del área); sin balón, Pase/Presión, Entrada, Barrida, Cambiar y Sprint; Mod solo en el modo «Botones». GESTOS: tocar la zona libre de la derecha = pase; deslizar hacia arriba = tiro (más largo = más fuerte); deslizar desde Tiro = rosca (Mod); deslizar desde Pase = pase largo; tocar Sprint = regate (mantener = correr).
## Tamaño, opacidad, separación, modo de control (Botones / Gestos / Ambos), cuándo salen y modo zurdo salen de Ajustes → Dispositivo (`AjustesTactil`). Medidas (guías de Apple 44 pt / Material 48 dp / NN-g 1 cm; en juegos 45-57 px por pulgar): en un móvil el botón grande
## mide ≈1,5 cm y el pequeño ≈1,1 cm (`escala`, por los puntos por pulgada), con ≥ 4 px entre botones; respeta el área segura (muescas). `zurdo` espeja todo salvo el botón de pausa.
const RADIO_STICK := 112.0
const RADIO_BOTON := 54.0               ## el radio de referencia (el de los botones medianos); cada botón lleva el suyo
const DIRS := {"jugar_izquierda": Vector2.LEFT, "jugar_derecha": Vector2.RIGHT, "jugar_arriba": Vector2.UP, "jugar_abajo": Vector2.DOWN}
## nombre → [etiqueta, acción, desplazamiento del centro desde la esquina inferior (derecha), radio, color del aro]
const BOTONES := {
	"A": ["Pase\nPresión", "jugar_pase", Vector2(220, 135), 66.0, Color(0.35, 0.65, 1.0)],
	"B": ["Tiro\nEntrada", "jugar_tiro", Vector2(90, 230), 66.0, Color(1.0, 0.45, 0.35)],
	"X": ["Centro\nBarrida", "jugar_centro", Vector2(200, 335), 50.0, Color(1.0, 0.85, 0.3)],
	"Y": ["Al hueco", "jugar_filtrado", Vector2(320, 280), 50.0, Color(0.45, 0.9, 0.5)],
	"Cambiar": ["Cambiar", "jugar_cambiar", Vector2(455, 245), 44.0, Color(0.8, 0.8, 0.85)],
	"Sprint": ["Sprint", "jugar_sprint", Vector2(380, 130), 56.0, Color(1, 1, 1)],
	"Mod": ["Mod", "jugar_mod", Vector2(50, 372), 44.0, Color(0.75, 0.6, 1.0)],
	"Pausa": ["II", "jugar_pausa", Vector2.ZERO, 44.0, Color(0.8, 0.8, 0.85)],   ## arriba a la derecha (ver `centro_de`)
}
## Etiqueta de cada botón según tengas o no el balón (4-11-2026; mismas acciones que `Mando.CON_BALON` / `Mando.SIN_BALON`): [con balón, sin balón]. «Al hueco» sin balón no hace nada y se ve apagado.
const CONTEXTO := {"A": ["Pase", "Presión"], "B": ["Tiro", "Entrada"], "X": ["Centro", "Barrida"], "Y": ["Al hueco", ""]}
const ZONA_STICK_X := 0.45              ## el stick solo nace en este tramo del ancho (el lado del pulgar izquierdo)
const ZONA_STICK_Y := 0.2               ## y por debajo de este tramo de arriba (no tapa el marcador)
const ALTO_ARCO := 416.0                ## lo que sube el arco de botones desde la esquina (px del lienzo con escala 1): tope del tamaño
const ANCHO_ARCO := 499.0               ## y lo que entra hacia el centro (Cambiar)
## (10-11-2026, auditoría en teléfono a 2400×1080 y 1080×2400: `pruebas/captura_tactil_movil`) Colocación rehecha para que entre dos botones
## que se ven a la vez quede SIEMPRE ≥ 2 mm de borde a borde (antes Pase y Tiro quedaban a 0,9 mm y en vertical Cambiar y Sprint a 1,5):
## ≥ 26 px del lienzo a escala 1, lo que pide el peor caso (vertical, 18,7 px/mm con escala 1,5).

static var forzar := false             ## las pruebas lo encienden; en el teléfono sale solo
static var zurdo := false              ## espejo forzado por las pruebas; el de verdad sale de Ajustes (`AjustesTactil.zurdo`)
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
var _con_balon := true                 ## el jugador que llevas tiene el balón (cambia las etiquetas y qué botones se ven)
var _en_banda := false                 ## y está en la banda cerca del área (sale el botón de Centro)
var _modo_mando := "ambos"             ## botones / gestos / ambos (Ajustes)
var _sep := 1.0                        ## separación entre botones (Ajustes, 1-1,3)
var _gesto := {}                       ## índice de dedo → estado del gesto que empezó (sprint/tiro/pase/zona libre)
var _elev := 0.0                       ## lo que sube el arco para no tapar la ficha del jugador (ver `_calcular_elev`)
static var mando_forzado := ""         ## las pruebas fuerzan el modo de control
static var contexto_forzado := ""      ## y el contexto de las capturas: «con» (balón), «banda» (balón en la banda cerca del área) o «sin» (defensa); vacío = el del juego
const MS_TOQUE := 200                  ## un toque en Sprint más corto que esto = regate; más largo = correr
const PX_DESLIZA := 70.0               ## lo que hay que arrastrar en la zona libre para que cuente como deslizar (px del lienzo)

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

## La línea de ayuda de teclado y mando del partido sobra con los botones en pantalla y tapa su borde: se mantiene oculta aunque el partido la vuelva a mostrar
## (`_ver_hud`, `_ver_hud_abajo`) o le cambie el texto cada fotograma (el partido la crea DESPUÉS de montar los controles, por eso se busca aquí).
func _process(_d: float) -> void:
	var ayuda: Variant = get_parent().get("_ayuda") if get_parent() != null else null
	if ayuda is CanvasItem and (ayuda as CanvasItem).visible:
		(ayuda as CanvasItem).visible = false
	var e := _calcular_elev()
	if absf(e - _elev) > 0.5:
		_elev = e
		queue_redraw()
	var cb := _tengo_balon() if contexto_forzado == "" else contexto_forzado != "sin"
	var eb := _estoy_en_banda() if contexto_forzado == "" else contexto_forzado == "banda"
	if cb != _con_balon or eb != _en_banda:
		_con_balon = cb
		_en_banda = eb
		queue_redraw()

## (10-11) Si el arco de botones se cruza en horizontal con la ficha del jugador de abajo (`_hud_abajo` del partido: en vertical, o
## con el modo zurdo, que lo pone a la izquierda), el arco sube por encima de ella en vez de taparla.
func _calcular_elev() -> float:
	var abajo: Variant = get_parent().get("_hud_abajo") if get_parent() != null else null
	if not (abajo is Array):
		return 0.0
	var s := escala()
	var m := margenes()
	var x0 := (m.x) if _espejo() else (size.x - m.y - ANCHO_ARCO * s * _sep)
	var x1 := (m.x + ANCHO_ARCO * s * _sep) if _espejo() else (size.x - m.y)
	var e := 0.0
	for c: Variant in abajo:
		if not (c is Control) or not is_instance_valid(c) or not (c as Control).is_visible_in_tree():
			continue
		var r := (c as Control).get_global_rect()
		if r.position.x < x1 and r.end.x > x0 and r.position.y < size.y:
			e = maxf(e, size.y - r.position.y + 8.0 * s)
	return e

## ¿Está el jugador que llevas en la banda, cerca de la línea de fondo rival (donde se centra)? Sin motor, no.
func _estoy_en_banda() -> bool:
	var motor: Variant = get_parent().get("motor") if get_parent() != null else null
	if motor == null or motor.usuario.is_empty():
		return false
	var yo: Vector3 = motor.pos(motor.usuario)
	var arco: Vector3 = motor._arco_rival(motor.usuario)
	return absf(yo.x) > 14.0 and absf(arco.z - yo.z) < 38.0

func _gestos() -> bool:
	return _modo_mando != "botones"

## ¿Se ve (y se puede pulsar) este botón ahora? `con_balon` / `en_banda` / `modo` son los de este momento (las pruebas los pasan).
func visible_en(nombre: String, con_balon: bool, en_banda: bool, modo: String) -> bool:
	if modo == "gestos":
		return nombre == "Pausa" or nombre == "Sprint" or (nombre == "Cambiar" and not con_balon)
	match nombre:
		"Y":
			return con_balon
		"X":
			return en_banda or not con_balon   ## sin balón es la Barrida; con balón, el Centro solo en la banda
		"Cambiar":
			return not con_balon
		"Mod":
			return modo == "botones"
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

## Las líneas de la etiqueta de un botón en este momento (con o sin balón); vacío = botón apagado sin acción.
func etiqueta_de(nombre: String, con_balon: bool) -> String:
	if not CONTEXTO.has(nombre):
		return String((BOTONES[nombre] as Array)[0])
	return String((CONTEXTO[nombre] as Array)[0 if con_balon else 1])

func _exit_tree() -> void:
	soltar_todo()

func _espejo() -> bool:
	return _zurdo or zurdo

## Factor de tamaño: proporcional a la altura del lienzo y, en un móvil de verdad, a los puntos por pulgada (el botón grande mide ≈1,5 cm sea cual sea la pantalla); por el tamaño elegido en Ajustes; y sin pasar de lo que
## cabe (el arco de botones no sube del 35 % de arriba). Nunca menos de 0,5.
func escala() -> float:
	var base := clampf(size.y / 720.0, 0.6, 1.25)
	var dpi_v := dpi()
	if dpi_v > 0.0:
		var vent := ventana()
		if vent.y > 0:
			var px_por_cm := dpi_v / 2.54 * size.y / float(vent.y)   ## píxeles del lienzo por cm de pantalla
			base = clampf(0.75 * px_por_cm / 66.0, 0.6, 1.5)        ## radio grande = 0,75 cm
	var cabe := 0.65 * size.y / ALTO_ARCO if size.y > 0.0 else base
	return maxf(minf(base * esc, maxf(cabe, base)), 0.5)

func radio_boton() -> float:
	return RADIO_BOTON * escala()

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
	return float((BOTONES[nombre] as Array)[3]) * escala()

## Dónde está el centro de un botón en este tamaño de pantalla.
func centro_de(nombre: String) -> Vector2:
	var s := escala()
	var m := margenes()
	if nombre == "Pausa":
		return Vector2(size.x - m.y - 24.0 * s - radio_de(nombre), 96.0 * s + radio_de(nombre))   ## bajo la ficha de estadísticas de arriba a la derecha
	var off: Vector2 = (BOTONES[nombre] as Array)[2]
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
	if b != "":
		_dedos[dedo] = b
		Input.action_press(String(BOTONES[b][1]))
		if b == "Sprint":
			_gesto[dedo] = {"tipo": "sprint", "t": Time.get_ticks_msec()}
		elif _gestos() and (b == "A" or b == "B"):
			_gesto[dedo] = {"tipo": b, "ini": pos, "r": radio_de(b), "viva": false}
	elif _dedo_stick < 0 and _en_zona_stick(pos):
		_dedo_stick = dedo
		_centro_stick = pos
		_mueve_stick(pos)
	elif _gestos() and not _en_zona_stick(pos):
		_gesto[dedo] = {"tipo": "libre", "ini": pos}   ## (un segundo dedo en la zona del stick, con el stick ya en uso, no cuenta: antes daba pases al levantarlo)   ## zona libre de la derecha: tocar = pase, deslizar hacia arriba = tiro
	queue_redraw()

## Un dedo que empezó un gesto se mueve: desde Tiro, rosca (Mod); desde Pase, pase largo.
func _desliza(dedo: int, pos: Vector2) -> void:
	var g: Dictionary = _gesto[dedo]
	if String(g["tipo"]) == "libre":
		g["fin"] = pos
		return
	if bool(g.get("viva", true)) or not g.has("ini"):
		return
	if pos.distance_to(g["ini"] as Vector2) < float(g.get("r", 60.0)) * 0.9:
		return
	g["viva"] = true
	if String(g["tipo"]) == "B":
		Input.action_press("jugar_mod")           ## rosca / tenso mientras sigue el Tiro
	elif String(g["tipo"]) == "A":
		Input.action_release("jugar_pase")
		Input.action_press("jugar_pase_largo")    ## pase largo

## Pulsa una acción un rato y la suelta (un toque o un tiro por gesto).
func _pulsar(accion: String, seg: float) -> void:
	Input.action_press(accion)
	if is_inside_tree():
		get_tree().create_timer(seg).timeout.connect(func() -> void: Input.action_release(accion))

func _suelta(dedo: int) -> void:
	if _gesto.has(dedo):
		_fin_gesto(dedo)
	if dedo == _dedo_stick:
		_dedo_stick = -1
		_vec = Vector2.ZERO
		_aplicar_stick()
	elif _dedos.has(dedo):
		Input.action_release(String(BOTONES[String(_dedos[dedo])][1]))
		_dedos.erase(dedo)
	queue_redraw()

## Se levanta el dedo de un gesto: Sprint corto = regate; zona libre: toque = pase, deslizar arriba = tiro (más largo, más fuerte).
func _fin_gesto(dedo: int) -> void:
	var g: Dictionary = _gesto[dedo]
	_gesto.erase(dedo)
	match String(g["tipo"]):
		"sprint":
			if Time.get_ticks_msec() - int(g["t"]) < MS_TOQUE:
				_pulsar("jugar_regate", 0.1)
		"B":
			if bool(g["viva"]):
				Input.action_release("jugar_mod")
		"A":
			if bool(g["viva"]):
				Input.action_release("jugar_pase_largo")
		"libre":
			var d: Vector2 = (g["fin"] as Vector2 if g.has("fin") else g["ini"] as Vector2) - (g["ini"] as Vector2)
			if d.length() < PX_DESLIZA * 0.5:
				var q := PaseTactil.receptor_en(get_parent(), g["ini"] as Vector2)   ## tocar a un compañero = pase a él
				if not q.is_empty():
					MotorPaseDirigido.pedir(get_parent().get("motor"), q)
				_pulsar("jugar_pase", 0.08)
			elif d.y < -PX_DESLIZA * 0.6 and absf(d.y) >= absf(d.x) * 0.5:
				_pulsar("jugar_tiro", clampf(d.length() / 500.0, 0.2, 0.7))

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
	for d: int in _dedos:
		Input.action_release(String(BOTONES[String(_dedos[d])][1]))
	_dedos.clear()
	_gesto.clear()
	for a2: String in ["jugar_mod", "jugar_pase_largo"]:
		Input.action_release(a2)
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
	var fuente := ThemeDB.fallback_font
	for n: String in BOTONES:
		if not visible_ahora(n):
			continue
		var c := centro_de(n)
		var r := radio_de(n)
		var col: Color = (BOTONES[n] as Array)[4]
		var activo := _dedos.values().has(n)
		var etiqueta := etiqueta_de(n, _con_balon)
		var apagado := etiqueta == ""
		var op_b := opac * (0.45 if apagado else 1.0)
		var fondo := 0.6 if n == "Pausa" else 0.42   ## (10-11) el II se perdía sobre el cielo y las gradas
		draw_circle(c, r, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.62 * op_b) if activo else Color(0.04, 0.05, 0.08, fondo * op_b))
		draw_arc(c, r, 0.0, TAU, 40, Color(col.r, col.g, col.b, (0.95 if activo else 0.75) * op_b), 4.0 * s)
		var lineas := Idiomas.t(etiqueta if not apagado else String(BOTONES[n][0])).split("\n")
		var tam := int(roundf(clampf(r * (0.55 if n == "Pausa" else 0.30), 11.0, 40.0 if n == "Pausa" else 24.0)))
		for k in lineas.size():
			var y := c.y + float(tam) * 0.35 + (float(k) - float(lineas.size() - 1) * 0.5) * float(tam) * 1.15
			var tk := tam if k == 0 else int(tam * 0.85)
			draw_string_outline(fuente, Vector2(c.x - r, y), lineas[k], HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, tk, 5, Color(0, 0, 0, 0.8 * op_b))
			draw_string(fuente, Vector2(c.x - r, y), lineas[k], HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, tk, Color(1, 1, 1, (1.0 if k == 0 else 0.85) * op_b))
