class_name ObjetivoDirectiva
extends RefCounted
## EL OBJETIVO DE LA DIRECTIVA, A LA VISTA (10-11; idea del PES 2020: los objetivos con su seguimiento). Una línea en el menú central: «OBJETIVO»,
## lo que pide la directiva (`Directiva.objetivo`), tu puesto frente a la meta (`meta_puesto`) y una barra: llena y verde si estás dentro de la meta,
## y cada vez más corta y roja cuanto más lejos. Sin liga jugada todavía, la barra va a la mitad. Solo lectura.

## 0-100: lo cerca que estás de cumplir (100 = dentro de la meta).
static func progreso(puesto: int, meta: int, equipos: int) -> int:
	if puesto <= 0 or meta <= 0:
		return 50
	if puesto <= meta:
		return 100
	var margen := maxi(equipos - meta, 1)
	return clampi(int(round(100.0 * (1.0 - float(puesto - meta) / float(margen)))), 5, 95)

static func fila(m: Mundo, c: Club, liga: Liga) -> Control:
	if m == null or m.directiva == null or c == null or String(m.directiva.objetivo) == "":
		return null
	var puesto := 0
	var equipos := 0
	if liga != null and liga.jornada_actual > 0:
		var t: Array = liga.tabla()
		equipos = t.size()
		for i in t.size():
			if t[i]["club"] == c:
				puesto = i + 1
	var meta := int(m.directiva.meta_puesto)
	var p := progreso(puesto, meta, equipos)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var rot := Label.new()
	rot.text = Idiomas.t("OBJETIVO")
	rot.add_theme_font_size_override("font_size", Tema.letra(11))
	rot.add_theme_color_override("font_color", Tema.SUAVE)
	h.add_child(rot)
	var txt := Label.new()
	txt.text = "%s · %s" % [Idiomas.t(String(m.directiva.objetivo)), ("%s %d.º / %s %d.º" % [Idiomas.t("vas"), puesto, Idiomas.t("meta"), meta]) if puesto > 0 else Idiomas.t("meta") + " %d.º" % meta]
	txt.add_theme_font_size_override("font_size", Tema.letra(12))
	txt.clip_text = true
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(txt)
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(110, 10)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra.show_percentage = false
	barra.value = p
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(1, 1, 1, 0.1)
	fondo.set_corner_radius_all(4)
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = Tema.BIEN if p >= 100 else (Tema.ORO if p >= 50 else Tema.MAL)
	lleno.set_corner_radius_all(4)
	barra.add_theme_stylebox_override("background", fondo)
	barra.add_theme_stylebox_override("fill", lleno)
	barra.tooltip_text = "%s: %d%%" % [Idiomas.t("Cerca de cumplir"), p]
	h.add_child(barra)
	h.tooltip_text = detalle(m.directiva)
	return h

## Los objetivos secundarios y el proyecto, como texto de ayuda de la fila (varios a la vez, cada uno con su peso en la confianza).
static func detalle(d: Directiva) -> String:
	var l: Array[String] = []
	for o: Dictionary in d.objetivos:
		l.append("• %s (±%d)" % [Idiomas.t(String(o.get("texto", ""))), int(o.get("peso", 0))])
	if not d.proyecto.is_empty():
		l.append("🏁 %s: %s · %d/%d" % [Idiomas.t("Proyecto"), Idiomas.t(String(d.proyecto.get("texto", ""))), int(d.proyecto.get("cierres", 0)), int(d.proyecto.get("temporadas", 3))])
	return "\n".join(l)

## (10-11) Una fila compacta por objetivo secundario y por el proyecto, con su barra de progreso en vivo (`ObjetivosEnVivo`): verde = cumplido o bien,
## naranja = en riesgo, rojo = perdido. Vacía si el club no tiene paquete.
static func secundarios(m: Mundo) -> Control:
	if m == null or m.directiva == null:
		return null
	var filas := ObjetivosEnVivo.lista(m, m.directiva)
	if filas.is_empty():
		return null
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	for f: Dictionary in filas:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var t := Label.new()
		t.text = "%s %s" % [("🏁" if String(f["tipo"]) == "proyecto" else "•"), Idiomas.t(String(f["texto"]))]
		t.add_theme_font_size_override("font_size", Tema.letra(11))
		t.add_theme_color_override("font_color", Tema.SUAVE)
		t.clip_text = true
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		var barra := ProgressBar.new()
		barra.custom_minimum_size = Vector2(90, 8)
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		barra.show_percentage = false
		barra.value = int(f["progreso"])
		var fondo := StyleBoxFlat.new()
		fondo.bg_color = Color(1, 1, 1, 0.1)
		fondo.set_corner_radius_all(4)
		var lleno := StyleBoxFlat.new()
		var est := String(f["estado"])
		lleno.bg_color = Tema.BIEN if (est == "cumplido" or est == "bien") else (Tema.ORO if est == "riesgo" else Tema.MAL)
		lleno.set_corner_radius_all(4)
		barra.add_theme_stylebox_override("background", fondo)
		barra.add_theme_stylebox_override("fill", lleno)
		barra.tooltip_text = "%s · ±%d" % [Idiomas.t(est), int(f["peso"])]
		h.add_child(barra)
		col.add_child(h)
	return col
