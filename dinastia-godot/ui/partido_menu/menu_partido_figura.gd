class_name FiguraClub
extends Control
## EL JUGADOR GRANDE DE LA PREVIA (17-11-2026, maqueta): la figura con la camiseta del club (`EstiloAvanzar.figura`, colores del club) y su dorsal en el short.
## Más abajo, `EmblemaLiga` (el círculo de la competición, entre los escudos) y `MiniaturaMenu` (dibujos pequeños de los paneles: estadio, cámara y campo con la formación).

var textura: Texture2D
var dorsal := 0
var espejo := false

func _draw() -> void:
	if textura == null:
		return
	var alto := size.y
	var ancho := alto * 200.0 / 460.0
	var x0 := (size.x - ancho) * 0.5
	if espejo:
		draw_set_transform(Vector2(x0 + ancho, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect(textura, Rect2(Vector2.ZERO, Vector2(ancho, alto)), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect(textura, Rect2(Vector2(x0, 0), Vector2(ancho, alto)), false)
	var f := EstiloAvanzar.fuente_titulo()
	var tam := int(alto * 40.0 / 460.0)
	var txt := str(dorsal)
	var ancho_txt := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var pos := Vector2(x0 + ancho * 0.5 - ancho_txt * 0.5, alto * 316.0 / 460.0)
	draw_string_outline(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 3, Color(0, 0, 0, 0.3))
	draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color.WHITE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

