class_name ListaLogrosLargo
extends RefCounted
## LA LISTA DE LOS TREINTA LOGROS A LARGO PLAZO (26-10-2026, `LogrosLargo`), en
## la pestaña de logros, debajo de los veinte de siempre. A diferencia de los
## ocultos, se enseñan enteros y con su barra: son metas de años y lo que
## engancha es ver cuánto falta («312 / 500»). Los que el club ya cumplía al
## llegar salen como «heredado», sin fingir que fueron mérito tuyo.
##   ListaLogrosLargo.pintar(lista, logros, texto)   ← `texto` = `Principal._texto`

static func pintar(lista: VBoxContainer, lg: Logros, texto: Callable) -> void:
	if lg == null:
		return
	## Antes del primer partido aún no se ha hecho la revisión (ni apuntado lo
	## heredado): se hace aquí para que la lista no enseñe metas llenas sin marcar.
	lg.revisar_largos()
	var cat := lg.catalogo_largo()
	if cat.is_empty():
		return
	lista.add_child(HSeparator.new())
	var hechos := 0
	for f: Dictionary in cat:
		if bool(f["conseguido"]) and not bool(f["heredado"]):
			hechos += 1
	var t: Label = texto.call(13, Principal.COL_ORO)
	t.text = Idiomas.t("🏁 A LARGO PLAZO  ·  %d/%d") % [hechos, cat.size()]
	lista.add_child(t)
	var ex: Label = texto.call(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Metas de muchas temporadas, con lo que llevas hasta hoy.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(ex)
	## Primero los que faltan, ordenados por lo cerca que estás; al final los hechos.
	cat.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a["conseguido"]) != bool(b["conseguido"]):
			return not bool(a["conseguido"])
		return _fraccion(a) > _fraccion(b))
	for f: Dictionary in cat:
		_fila(lista, f, texto)

static func _fraccion(f: Dictionary) -> float:
	return float(f["valor"]) / maxf(1.0, float(f["meta"]))

## «312 / 500»; la caja va en millones y lo grande con puntos de miles.
static func cifra(f: Dictionary) -> String:
	var unidad := " M" if String(f["clave"]).begins_with("caja") else ""
	return "%s / %s%s" % [_miles(int(f["valor"])), _miles(int(f["meta"])), unidad]

static func _miles(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + out

static func _fila(lista: VBoxContainer, f: Dictionary, texto: Callable) -> void:
	var hecho := bool(f["conseguido"])
	var heredado := bool(f["heredado"])
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	lista.add_child(fila)
	var col := Principal.COL_SUAVE if heredado else (Principal.COL_VERDE if hecho else Principal.COL_TEXTO)
	var nom: Label = texto.call(12, col)
	nom.text = "%s %s" % [String(f["icono"]), Idiomas.t(String(f["titulo"]))]
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nom.tooltip_text = Idiomas.t(String(f["descripcion"]))
	nom.mouse_filter = Control.MOUSE_FILTER_PASS
	fila.add_child(nom)
	var der: Label = texto.call(11, col)
	if heredado:
		der.text = Idiomas.t("heredado")
	elif hecho:
		der.text = Idiomas.t("hecho en %d") % int((f["cuando"] as Dictionary).get("anio", 0))
	else:
		der.text = cifra(f)
	fila.add_child(der)
	if not hecho:
		var barra := ProgressBar.new()
		barra.max_value = float(f["meta"])
		barra.value = float(f["valor"])
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(0, 5)
		var fondo := StyleBoxFlat.new()
		fondo.bg_color = Color(1, 1, 1, 0.07)
		fondo.set_corner_radius_all(2)
		var lleno := StyleBoxFlat.new()
		lleno.bg_color = Color(Principal.COL_ORO, 0.85)
		lleno.set_corner_radius_all(2)
		barra.add_theme_stylebox_override("background", fondo)
		barra.add_theme_stylebox_override("fill", lleno)
		lista.add_child(barra)
	var d: Label = texto.call(10, Principal.COL_SUAVE)
	d.text = "     " + Idiomas.t(String(f["descripcion"]))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(d)
