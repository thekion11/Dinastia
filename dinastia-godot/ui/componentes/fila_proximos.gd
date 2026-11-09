class_name FilaProximos
extends RefCounted
## LA FILA DE LOS PRÓXIMOS PARTIDOS (9-11, idea del PES 2020: en el inicio de Master League, abajo, una fila de escudos con lo que viene).
## Debajo de la tira de días: los próximos N partidos de liga de tu club, cada uno con el escudo del rival y «J12 · vs / en».
const CUANTOS := 5

## Los próximos partidos de liga de `m.mi_club()`, desde la jornada que toca: [{jornada, rival, local}].
static func datos(m: Mundo, cuantos := CUANTOS) -> Array:
	var out: Array = []
	var mio := m.mi_club() if m != null else null
	if mio == null:
		return out
	var liga := m.liga_de(mio)
	if liga == null:
		return out
	var j := liga.jornada_actual
	while j < liga.calendario.size() and out.size() < cuantos:
		for par: Array in liga.calendario[j]:
			if par[0] == mio or par[1] == mio:
				var local: bool = par[0] == mio
				out.append({"jornada": j + 1, "rival": par[1] if local else par[0], "local": local})
				break
		j += 1
	return out

## Rehace el contenido de `caja` (un HBoxContainer).
static func pintar(m: Mundo, caja: HBoxContainer) -> void:
	for h in caja.get_children():
		h.queue_free()
	var lista := datos(m)
	if lista.is_empty():
		return
	var rot := Label.new()
	rot.text = Idiomas.t("PRÓXIMOS")
	rot.add_theme_font_size_override("font_size", 11)
	caja.add_child(rot)
	for e: Dictionary in lista:
		var rival: Club = e["rival"]
		var celda := HBoxContainer.new()
		celda.add_theme_constant_override("separation", 4)
		var tr := TextureRect.new()
		tr.texture = Escudo.textura(rival, 28)
		tr.custom_minimum_size = Vector2(28, 28)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		celda.add_child(tr)
		var t := Label.new()
		t.text = "J%d %s" % [int(e["jornada"]), Idiomas.t("vs") if bool(e["local"]) else Idiomas.t("en")]
		t.add_theme_font_size_override("font_size", 11)
		celda.add_child(t)
		celda.tooltip_text = "%s %s" % [Idiomas.t("vs") if bool(e["local"]) else Idiomas.t("en"), rival.nombre]
		caja.add_child(celda)
		var sep := VSeparator.new()
		caja.add_child(sep)
