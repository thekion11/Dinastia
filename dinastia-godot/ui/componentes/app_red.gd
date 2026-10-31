class_name AppRed
extends RefCounted
## LA APP «RED» DEL MÓVIL (27-10-2026, orden del dueño 16): como la app de Red Movilidad de Santiago. Arriba, el paradero
## más cercano al DT (si está a menos de 40 m) o un campo para escribir el código «PA####» del poste; luego el nombre de la
## parada, sus recorridos en cajitas del color del cartel y las PRÓXIMAS LLEGADAS: recorrido y destino, minutos («Llegando»
## si falta menos de uno), patente del bus y lo lleno que va. Los recorridos son los del mapa (`RecorridosRed`, el cartel 3D lee
## lo mismo); en la calle, los minutos salen de los buses reales (`BusesRed.llegadas`) y si no, del horario con la hora del reloj
## único (`Mundo.reloj`). Aquí solo se dibuja.

const ROJO := Color("d7182a")
const RADIO_CERCA := 40.0
const META_MARCA := "marca_sin_traducir"

## Qué paradero mostrar: el escrito a mano manda; si no, el más cercano al DT (cuando el móvil se abre en la calle).
static func paradero_elegido(tel: Telefono) -> Dictionary:
	if tel.codigo_red != "":
		return {"codigo": tel.codigo_red, "distancia": -1.0}
	if tel.en_la_calle and tel.is_inside_tree():
		return RecorridosRed.paradero_cercano(tel.get_tree(), tel.posicion_dt, RADIO_CERCA)
	return {}

## El minuto de la semana del reloj de la partida (lunes 00:00 = 0). Sin reloj (pruebas sueltas), el lunes a las 18:00.
static func minuto_semana(m: Mundo) -> int:
	if m != null and m.reloj != null and m.reloj.semana >= 0:
		return m.reloj.minuto_de_semana()
	return 18 * 60

## Un texto que no se traduce (nombres de calles, patentes, la marca): `traducir_arbol` lo dejaría igual o lo estropearía.
static func _fijo(l: Label) -> Label:
	l.set_meta(META_MARCA, l.text)
	return l

static func _chip(recorrido: String, tam: int) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = RecorridosRed.color(recorrido)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pc.add_theme_stylebox_override("panel", sb)
	var l := _fijo(Tema.etiqueta(tam, Color.WHITE, recorrido))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pc.add_child(l)
	return pc

static func pintar(tel: Telefono) -> void:
	var cuerpo: VBoxContainer = tel._cuerpo
	## Cabecera: la marca en su píldora roja (no se traduce: «Red» es el nombre, no «network»).
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var atras := Button.new()
	atras.flat = true
	atras.text = "‹"
	atras.add_theme_font_size_override("font_size", 22)
	atras.pressed.connect(func() -> void: tel.abrir_app("inicio"))
	fila.add_child(atras)
	var marca := PanelContainer.new()
	marca.add_theme_stylebox_override("panel", Tema.caja(ROJO, 10, ROJO))
	marca.add_child(_fijo(Tema.etiqueta(Tema.TAM_DESTACADO + 2, Color.WHITE, "Red")))
	marca.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(marca)
	cuerpo.add_child(fila)
	_buscador(tel, cuerpo)
	var par := paradero_elegido(tel)
	if par.is_empty():
		cuerpo.add_child(tel._vacio("🚏", "No hay un paradero cerca",
			"Acércate a menos de 40 m de un paradero o escribe el código PA del poste."))
		return
	var cod := String(par["codigo"])
	if not RecorridosRed.existe(cod):
		cuerpo.add_child(tel._vacio("🚏", "Ese paradero no existe", "Revisa el código del poste: «PA» y cuatro cifras."))
		return
	_tarjeta_paradero(tel, cuerpo, cod, float(par["distancia"]))
	cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Tema.ORO, Idiomas.t("PRÓXIMAS LLEGADAS")))
	## En la calle, con los buses de verdad (`BusesRed`: su posición y su velocidad sobre el recorrido); si no, el horario.
	var ls: Array[Dictionary] = []
	if tel.en_la_calle and tel.is_inside_tree():
		ls = BusesRed.llegadas(tel.get_tree(), cod)
	var vivo := not ls.is_empty()
	if not vivo:
		ls = RecorridosRed.llegadas(cod, minuto_semana(tel.m))
	if ls.is_empty():
		cuerpo.add_child(tel._nota(Idiomas.t("Sin servicio a esta hora. Los recorridos vuelven a pasar desde las 05:30.")))
	for l: Dictionary in ls:
		cuerpo.add_child(fila_llegada(l))
	cuerpo.add_child(tel._nota(Idiomas.t("Tiempos según la posición real de cada bus.") if vivo else Idiomas.t("Tiempos estimados según el horario de cada recorrido.")))

## Campo del código y «Buscar»; «Cerca» vuelve al paradero más cercano.
static func _buscador(tel: Telefono, cuerpo: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	var campo := LineEdit.new()
	campo.placeholder_text = "PA1234"
	campo.text = tel.codigo_red
	campo.max_length = 8
	campo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo.custom_minimum_size = Vector2(0, 40)
	fila.add_child(campo)
	var buscar := Button.new()
	buscar.text = Idiomas.t("Buscar")
	buscar.custom_minimum_size = Vector2(84, 40)
	var hacer := func() -> void:
		var c := RecorridosRed.normalizar(campo.text)
		if c == "":
			tel._decir(Idiomas.t("⚠️ El código es «PA» y cuatro cifras, como en el poste."))
			return
		tel.codigo_red = c
		tel.abrir_app("red")
	buscar.pressed.connect(hacer)
	campo.text_submitted.connect(func(_t: String) -> void: hacer.call())
	fila.add_child(buscar)
	if tel.codigo_red != "" and tel.en_la_calle:
		var cerca := Button.new()
		cerca.text = Idiomas.t("Cerca")
		cerca.custom_minimum_size = Vector2(70, 40)
		cerca.pressed.connect(func() -> void:
			tel.codigo_red = ""
			tel.abrir_app("red"))
		fila.add_child(cerca)
	cuerpo.add_child(fila)

static func _tarjeta_paradero(tel: Telefono, cuerpo: VBoxContainer, cod: String, distancia: float) -> void:
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Telefono.TARJETA, 12, Color(ROJO, 0.6)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 8)
	var poste := PanelContainer.new()
	var sb := Tema.caja(Color(0.0, 0.56, 0.36), 6, Color(0.0, 0.56, 0.36))
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	poste.add_theme_stylebox_override("panel", sb)
	poste.add_child(_fijo(Tema.etiqueta(Tema.TAM_DESTACADO + 6, Color.WHITE, cod)))
	poste.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	arriba.add_child(poste)
	var donde := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE,
		Idiomas.t("A %d m de ti") % int(round(distancia)) if distancia >= 0.0 else Idiomas.t("Código escrito"))
	donde.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	donde.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	arriba.add_child(donde)
	v.add_child(arriba)
	var nombre := _fijo(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, RecorridosRed.nombre_parada(cod)))
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nombre)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	for r: String in RecorridosRed.recorridos(cod):
		chips.add_child(_chip(r, Tema.TAM_CUERPO))
	v.add_child(chips)
	cuerpo.add_child(caja)

## Una llegada: [recorrido] destino ........ minutos / patente · ocupación.
static func fila_llegada(l: Dictionary) -> Control:
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Telefono.TARJETA, 10, Telefono.TARJETA))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	caja.add_child(h)
	var chip := _chip(String(l["recorrido"]), Tema.TAM_DESTACADO)
	chip.custom_minimum_size = Vector2(62, 0)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(chip)
	var medio := VBoxContainer.new()
	medio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	medio.add_theme_constant_override("separation", 1)
	var dest := _fijo(Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "→ " + String(l["destino"])))
	dest.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	dest.clip_text = true
	medio.add_child(dest)
	var ocup := int(l["ocupacion"])
	var col_o: Color = [Tema.BIEN, Tema.ORO, Tema.MAL][clampi(ocup, 0, 2)]
	var fila2 := HBoxContainer.new()
	fila2.add_theme_constant_override("separation", 6)
	var pat := _fijo(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, String(l["patente"])))
	pat.name = "Patente"
	fila2.add_child(pat)
	fila2.add_child(Tema.etiqueta(Tema.TAM_ROTULO, col_o, "● " + Idiomas.t(RecorridosRed.OCUPACION[clampi(ocup, 0, 2)])))
	medio.add_child(fila2)
	h.add_child(medio)
	var mins := int(l["minutos"])
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.BIEN if mins < 1 else Tema.TEXTO,
		Idiomas.t("Llegando") if mins < 1 else Idiomas.t("%d min") % mins)
	t.name = "Minutos"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	return caja
