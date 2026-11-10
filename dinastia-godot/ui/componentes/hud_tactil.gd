class_name HudTactil
extends RefCounted
## EL HUD DEL PARTIDO EN EL MÓVIL (4-11-2026, orden del dueño por la líder: «el HUD es diminuto en un teléfono»). El marcador, las estadísticas y la ficha del jugador estaban dibujados para una pantalla de PC: en un
## 6,5" a 2400×1080 la letra de las estadísticas medía ≈1,6 mm. Con los controles táctiles puestos, todo el HUD crece por los puntos por pulgada del aparato para que la letra más pequeña mida al menos `MIN_MM` mm
## de alto y el marcador `MIN_MM_MARCADOR`, y se aparta de las muescas (área segura). Sin controles táctiles (PC) el factor es 1 y nada cambia.
const MIN_MM := 2.5                    ## alto mínimo de la letra más pequeña del HUD (las estadísticas, de 15 px de base)
const MIN_MM_MARCADOR := 3.2           ## y del marcador (de 24 px de base)
const BASE_PEQUENA := 15.0
const MAX_FACTOR := 3.2   ## (10-11) era 2,0: en vertical (1080×2400, 18,7 px/mm del lienzo) la letra se quedaba en 1,6 mm; en horizontal el factor es 1,75 y no cambia

## Píxeles del lienzo por milímetro de pantalla (0 si no se sabe).
static func px_por_mm(nodo: Node) -> float: return PantallaMovil.px_por_mm(nodo)

## ¿Hay controles táctiles en este partido?
static func activo(nodo: Node) -> bool:
	return nodo.get_node_or_null("ControlesTactiles") != null

## Factor de tamaño del HUD (1 = el de PC).
static func f(nodo: Node) -> float:
	if not activo(nodo):
		return 1.0
	var p := px_por_mm(nodo)
	if p <= 0.0:
		return 1.0
	return clampf(MIN_MM * p / BASE_PEQUENA, 1.0, MAX_FACTOR)

## Un tamaño de letra de PC llevado al del móvil.
static func tam(n: int, nodo: Node) -> int:
	return int(ceilf(float(n) * f(nodo)))

## Un largo en píxeles de PC llevado al del móvil.
static func px(v: float, nodo: Node) -> float:
	return v * f(nodo)

## Márgenes de área segura (izquierda, derecha) en píxeles del lienzo; 0 fuera de un móvil.
static func margen(nodo: Node) -> Vector2:
	var c := nodo.get_node_or_null("ControlesTactiles") as ControlesTactiles
	if c == null:
		return Vector2.ZERO
	var vp := nodo.get_viewport()
	## (4-11) Sin escribir `c.size`: el control tiene anclas opuestas y Godot avisaba de cada llamada; se le pasa el ancho del lienzo.
	return c.margenes(vp.get_visible_rect().size.x if vp != null and c.size.x <= 0.0 else 0.0)

## (10-11, auditoría del HUD en el teléfono) La ficha del jugador de abajo a la izquierda, en el móvil, mide lo que necesita: crece
## hacia arriba y hacia la derecha desde la esquina (a 400 ppp ocupaba el 43 % del ancho con media caja vacía, y el arco de botones
## la tapaba en vertical). En PC no cambia.
static func compactar_ficha(caja: Control, nodo: Node) -> void:
	if not activo(nodo):
		return
	caja.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caja.offset_top = caja.offset_bottom
	caja.offset_right = caja.offset_left

## La barra de aguante de la ficha: más corta en el móvil (170 en vez de 300, por el factor del HUD).
static func ancho_aguante(nodo: Node) -> Vector2:
	return Vector2(170.0 if activo(nodo) else 300.0, 10.0) * f(nodo)

## Dónde empieza la ficha de estadísticas de arriba a la derecha: en VERTICAL (lienzo más alto que ancho) no cabe al lado del
## marcador con letra legible y baja a una segunda fila; si no, arriba del todo (18) como siempre.
static func alto_fila2(nodo: Node) -> float:
	var vp := nodo.get_viewport()
	if not activo(nodo) or vp == null:
		return 18.0
	var r := vp.get_visible_rect().size
	if r.y <= r.x:
		return 18.0
	return 18.0 + float(tam(24, nodo)) * 1.45 + 12.0 + 10.0

## Un tamaño de letra fijo de PC, con un mínimo en milímetros en el móvil (el aviso grande: «¡GOL!», «Saque de banda»…).
static func tam_minimo(base: int, mm: float, nodo: Node) -> int:
	var p := px_por_mm(nodo)
	if not activo(nodo) or p <= 0.0:
		return base
	return maxi(base, int(ceilf(mm * p)))

## Dónde va el aviso grande: a 110 como siempre o, en vertical, por debajo de la segunda fila (la de estadísticas).
static func alto_aviso(nodo: Node) -> float:
	var f2 := alto_fila2(nodo)
	if f2 <= 18.0:
		return 110.0
	return maxf(110.0, f2 + float(tam(15, nodo)) * 1.45 + 12.0 + 14.0)
