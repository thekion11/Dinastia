class_name PantallaMovil
extends RefCounted
## LA MEDIDA DE LA PANTALLA (4-11-2026, A4): puntos por pulgada, ventana y lienzo, y de ahí los píxeles por milímetro.
## Vive SOLA, sin nombrar ninguna clase del partido: la usan el menú (`EscalaMovil`, toques de 7 mm) y el partido
## (`ControlesTactiles`, `HudTactil`). Antes estaba dentro de `ControlesTactiles`, y el menú, al medir sus botones,
## arrastraba el motor del partido entero (regla de memoria del menú de CLAUDE.md; prueba `mem_menu_estadio`).

static var dpi_forzado := 0.0                  ## las pruebas simulan los puntos por pulgada de un móvil (p. ej. 400); 0 = los del aparato
static var ventana_forzada := Vector2i.ZERO    ## las pruebas simulan el tamaño de la ventana (p. ej. 2400×1080); 0 = el real
static var lienzo_forzado := Vector2.ZERO      ## y el del lienzo del juego (con el escalado del proyecto, 2400×1080 son 1600×720); 0 = el real

static func ventana() -> Vector2i:
	return ventana_forzada if ventana_forzada.x > 0 else DisplayServer.window_get_size()

## Puntos por pulgada: los forzados por una prueba o, en un móvil de verdad, los del aparato (0 = no se sabe / no es móvil).
static func dpi() -> float:
	if dpi_forzado > 0.0:
		return dpi_forzado
	return float(DisplayServer.screen_get_dpi()) if OS.has_feature("mobile") else 0.0

## Píxeles del lienzo por milímetro de pantalla real (0 = no se sabe: PC sin puntos por pulgada).
static func px_por_mm(nodo: Node) -> float:
	var d := dpi()
	var vent := ventana()
	var vp := nodo.get_viewport()
	if d <= 0.0 or vent.y <= 0 or vp == null:
		return 0.0
	var lienzo := lienzo_forzado if lienzo_forzado.y > 0.0 else vp.get_visible_rect().size
	return lienzo.y / float(vent.y) * d / 25.4
