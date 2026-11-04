class_name HudTactil
extends RefCounted
## EL HUD DEL PARTIDO EN EL MÓVIL (4-11-2026, orden del dueño por la líder: «el HUD es diminuto en un teléfono»). El marcador, las estadísticas y la ficha del jugador estaban dibujados para una pantalla de PC: en un
## 6,5" a 2400×1080 la letra de las estadísticas medía ≈1,6 mm. Con los controles táctiles puestos, todo el HUD crece por los puntos por pulgada del aparato para que la letra más pequeña mida al menos `MIN_MM` mm
## de alto y el marcador `MIN_MM_MARCADOR`, y se aparta de las muescas (área segura). Sin controles táctiles (PC) el factor es 1 y nada cambia.
const MIN_MM := 2.5                    ## alto mínimo de la letra más pequeña del HUD (las estadísticas, de 15 px de base)
const MIN_MM_MARCADOR := 3.2           ## y del marcador (de 24 px de base)
const BASE_PEQUENA := 15.0
const MAX_FACTOR := 2.0

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
