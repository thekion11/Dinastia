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

## Rehace el contenido de `caja` (un HBoxContainer): rótulo, y por partido una tarjeta
## (escudo, jornada, rival y localía) más un hueco. El PRIMERO va resaltado en oro (es el que viene).
static func pintar(m: Mundo, caja: HBoxContainer) -> void:
	for h in caja.get_children():
		h.queue_free()
	var lista := datos(m)
	if lista.is_empty():
		return
	caja.add_theme_constant_override("separation", 6)
	var rot := Tema.etiqueta(Tema.TAM_ROTULO, Tema.oro(), Idiomas.t("PRÓXIMOS").to_upper())
	rot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	caja.add_child(rot)
	var primero := true
	for e: Dictionary in lista:
		caja.add_child(_tarjeta(e, primero))
		primero = false
		var hueco := Control.new()
		hueco.custom_minimum_size = Vector2(2, 0)
		caja.add_child(hueco)

static func _tarjeta(e: Dictionary, siguiente: bool) -> PanelContainer:
	var rival: Club = e["rival"]
	var local: bool = bool(e["local"])
	var tarjeta := PanelContainer.new()
	var est := Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.oro() if siguiente else Tema.BORDE)
	est.bg_color = Color("1d2c22") if siguiente else Tema.TARJETA
	est.set_border_width_all(2 if siguiente else 1)
	est.border_width_left = 4 if (local and not Tema.contraste) else est.border_width_left
	est.content_margin_left = 8
	est.content_margin_right = 10
	est.content_margin_top = 4
	est.content_margin_bottom = 4
	est.shadow_color = Color(0, 0, 0, 0.35)
	est.shadow_size = 4
	est.shadow_offset = Vector2(0, 2)
	tarjeta.add_theme_stylebox_override("panel", est)
	var celda := HBoxContainer.new()
	celda.add_theme_constant_override("separation", 6)
	tarjeta.add_child(celda)
	var tr := TextureRect.new()
	tr.texture = Escudo.textura(rival, 28)
	tr.custom_minimum_size = Vector2(28, 28)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	celda.add_child(tr)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	celda.add_child(col)
	var lado := Idiomas.t("vs") if local else Idiomas.t("en")
	var arriba := Tema.etiqueta(Tema.TAM_ROTULO, Tema.oro() if siguiente else Tema.SUAVE, "J%d" % int(e["jornada"]))
	col.add_child(arriba)
	var abajo := Tema.etiqueta(Tema.TAM_ROTULO + 1, Tema.TEXTO, "%s %s" % [lado, _corto(rival.nombre)])
	col.add_child(abajo)
	tarjeta.tooltip_text = "%s %s" % [lado, rival.nombre]
	return tarjeta

## Nombre recortado para que la fila quepa en pantallas angostas.
static func _corto(nombre: String) -> String:
	return nombre if nombre.length() <= 13 else nombre.substr(0, 12) + "…"
