class_name AyudaMovil
extends RefCounted
## AYUDA DE PRUEBAS DEL MÓVIL (4-11-2026, auditoría 4): pone la ventana de un teléfono (2400×1080 a 400 ppp con el zoom del móvil, o 1280×720) y mide una pantalla:
## botones más bajos de 7 mm, controles fuera de la ventana, textos recortados por su propio control.

static func poner(ventana: Vector2i, raiz: Window) -> void:
	raiz.size = ventana
	raiz.content_scale_factor = EscalaMovil.ZOOM_MOVIL if ventana.x >= 2000 else 1.0
	PantallaMovil.dpi_forzado = 400.0
	PantallaMovil.ventana_forzada = ventana

static func quitar(raiz: Window) -> void:
	PantallaMovil.dpi_forzado = 0.0
	PantallaMovil.ventana_forzada = Vector2i.ZERO
	raiz.content_scale_factor = 1.0

## Problemas de lo que se ve bajo `raiz` (lista de textos). `alto_toque`: px del lienzo (EscalaMovil.alto_toque).
static func problemas(raiz: Node, alto_toque: float) -> Array[String]:
	var r: Array[String] = []
	var vp := raiz.get_viewport().get_visible_rect().size
	for n in raiz.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c.get_window() != raiz.get_tree().root or c.size.x < 4.0:
			continue
		var rect := c.get_global_rect()
		if c is Button:
			var b := c as Button
			if b.size.y < alto_toque - 1.5 and not b.disabled:
				r.append("toque bajo «%s» %.0f<%.0f" % [b.text.left(18), b.size.y, alto_toque])
			if rect.end.x > vp.x + 2.0 and rect.position.x < vp.x:
				r.append("botón fuera «%s» +%d px" % [b.text.left(18), int(rect.end.x - vp.x)])
			elif rect.end.y > vp.y + 2.0 and rect.position.y + 4.0 < rect.end.y and not _en_scroll(c):   ## también si queda ENTERO por debajo (no se puede pulsar)
				r.append("botón por debajo «%s» +%d px" % [b.text.left(18), int(rect.end.y - vp.y)])
		if c is Button or c is Label:
			var t: String = c.get("text")
			if t.strip_edges() == "" or t.contains("\n") or (c is Label and t.strip_edges().length() <= 3):   ## las iniciales de los escudos (LF, PD…) son decoración recortada por su caja
				continue
			var corta: bool = c.get("clip_text") or int(c.get("text_overrun_behavior")) != TextServer.OVERRUN_NO_TRIMMING
			var envuelve: bool = int(c.get("autowrap_mode")) != TextServer.AUTOWRAP_OFF
			if corta and not envuelve:
				var f := c.get_theme_font("font")
				var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, c.get_theme_font_size("font_size")).x
				var hueco := c.size.x - (c.get_theme_stylebox("normal").get_minimum_size().x if c is Button else 0.0)
				if w > hueco + 2.0:
					r.append("cortado «%s» %d/%d" % [t.left(22), int(w), int(hueco)])
			if not (c is Button) and rect.end.x > vp.x + 2.0 and rect.position.x < vp.x:
				r.append("texto fuera «%s» +%d px" % [t.left(22), int(rect.end.x - vp.x)])
			elif not (c is Button) and rect.end.y > vp.y + 2.0 and rect.position.y < vp.y and not _en_scroll(c):
				r.append("texto por debajo «%s» +%d px" % [t.left(22), int(rect.end.y - vp.y)])
	return r

static func _en_scroll(c: Control) -> bool:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false
