class_name BarridoPartido
extends CanvasLayer
## LAS TRANSICIONES ENTRE LAS PANTALLAS DEL PARTIDO (17-11-2026, Auditoría: «previa → saque → partido → descanso → final: barridos de color como en
## la referencia, nunca un corte seco, y medidas, < 300 ms»). Dos bandas diagonales con los colores de los dos clubes (y un filo blanco) entran de
## izquierda a derecha y TAPAN la pantalla (`CUBRIR` s); tapada, se cambia lo de debajo (`al_cubrir`) y las bandas siguen hacia la derecha y la
## DESTAPAN (`DESCUBRIR` s). Si lo de debajo tarda (montar el estadio), la pantalla se queda tapada con los colores: nunca se ve el salto.
## Con animaciones reducidas, un fundido corto del mismo color; sin pantalla (`--headless`, el banco), el cambio es inmediato.
## `ultima`: lo medido del último barrido (ms hasta tapar, ms en total y si estaba tapado del todo al cambiar), para las pruebas.

const CUBRIR := 0.11
const DESCUBRIR := 0.12
const INCLINA := 0.22   ## lo que se inclina la banda (parte del alto)

static var ultima := {}

var colores: Array = [Color("c8102e"), Color("0b1f4a")]
var t := 0.0              ## 0 → 1 tapando; 1 → 2 destapando
var _lienzo: Control
var _t0 := 0
var _cuadro_max := 0.0   ## el fotograma más lento mientras pasa (sin GPU, 40-100 ms: el tween se pasa hasta uno en cada punta)

func _process(delta: float) -> void:
	_cuadro_max = maxf(_cuadro_max, delta * 1000.0)

## Tapa, llama a `al_cubrir` y destapa. `cols`: [color principal, color secundario] (los de los dos clubes).
static func pasar(nodo: Node, cols: Array, al_cubrir: Callable) -> BarridoPartido:
	if DisplayServer.get_name() == "headless" or nodo == null or not nodo.is_inside_tree():
		al_cubrir.call()
		ultima = {"cubrir_ms": 0, "total_ms": 0, "tapado": true, "sin_pantalla": true}
		return null
	var b := BarridoPartido.new()
	b.layer = 128
	if cols.size() >= 2:
		b.colores = cols
	nodo.get_tree().root.add_child(b)
	b._correr(al_cubrir)
	return b

## Los colores de un partido: el del local y el del visitante (si se parecen mucho, el segundo pasa al azul noche de la maqueta).
static func colores_de(p: Partido) -> Array:
	if p == null:
		return [Color("c8102e"), Color("0b1f4a")]
	var a := _camiseta(p.local)
	var b := _camiseta(p.visita)
	if absf(a.h - b.h) < 0.06 and absf(a.v - b.v) < 0.2:
		b = Color("0b1f4a")
	return [a, b]

## El color de la camiseta que se ve en el partido (el mismo de `Puente3D.kit`, con `load()`: la memoria del menú no nombra el partido 3D).
static func _camiseta(c: Club) -> Color:
	var kit: Dictionary = load("res://visor/puente3d.gd").kit(c)
	return Color(String(kit.get("c1", c.color_kit1())))

func _correr(al_cubrir: Callable) -> void:
	_lienzo = Control.new()
	_lienzo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lienzo.mouse_filter = Control.MOUSE_FILTER_STOP   ## mientras pasa, nada de toques sueltos
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)
	_t0 = Time.get_ticks_msec()
	var reducidas := Animar.reducidas()
	var tw := create_tween()
	tw.tween_method(_poner, 0.0, 1.0, CUBRIR * (0.7 if reducidas else 1.0)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished
	var cubrir_ms := Time.get_ticks_msec() - _t0
	var c0 := Time.get_ticks_msec()
	al_cubrir.call()
	var cambio_ms := Time.get_ticks_msec() - c0   ## lo que cuesta montar lo de debajo (se hace tapado)
	var tapado := t >= 1.0
	var tw2 := create_tween()
	tw2.tween_method(_poner, 1.0, 2.0, DESCUBRIR * (0.7 if reducidas else 1.0)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw2.finished
	ultima = {"cubrir_ms": cubrir_ms, "cambio_ms": cambio_ms, "total_ms": Time.get_ticks_msec() - _t0, "tapado": tapado,
		"cuadro_max_ms": int(_cuadro_max), "disenado_ms": int((CUBRIR + DESCUBRIR) * 1000.0)}
	queue_free()

func _poner(v: float) -> void:
	t = v
	_lienzo.queue_redraw()

func _dibujar() -> void:
	var s := _lienzo.size
	if Animar.reducidas():   ## fundido del color principal
		var a := t if t <= 1.0 else 2.0 - t
		_lienzo.draw_rect(Rect2(Vector2.ZERO, s), Color(colores[0], a))
		return
	var k := s.y * INCLINA
	## La banda va de `izq` a `der` (en x, en la parte de arriba); abajo, `k` más a la izquierda.
	var der := lerpf(-k, s.x + k, minf(t, 1.0))
	var izq := -k if t <= 1.0 else lerpf(-k, s.x + k, t - 1.0)
	var ancho2 := s.x * 0.08   ## la banda del segundo color, delante
	_banda(izq, der, k, s, colores[0])
	_banda(maxf(izq, der - ancho2), der, k, s, colores[1])
	_banda(der - 4.0, der, k, s, Color(1, 1, 1, 0.9))

func _banda(x0: float, x1: float, k: float, s: Vector2, c: Color) -> void:
	if x1 <= x0:
		return
	## Un paralelogramo: arriba va `k` por delante de abajo (la inclinación); con izq = −k y der = ancho + k tapa la pantalla entera.
	_lienzo.draw_colored_polygon(PackedVector2Array([Vector2(x0 + k, 0), Vector2(x1 + k, 0), Vector2(x1, s.y), Vector2(x0, s.y)]), c)
