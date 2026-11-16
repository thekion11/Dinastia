class_name PortadaMosaico
extends RefCounted
## LA PORTADA DE UN MENÚ COMO MOSAICO (16-11, orden 57, frente 1: «menús al nivel PES 2020»). Antes, cada portada era una
## rejilla de tarjetas iguales con su descripción; en la Liga Master del PES 2020 cada pantalla es un mosaico con una tarjeta
## PRINCIPAL grande (la primera: lo que más se usa) y alrededor tarjetas más chicas con su icono, su nombre y un dato vivo.
## Aquí: la primera ocupa 2x2, las cuatro siguientes van en dos columnas a su lado y el resto en filas de cuatro; las chicas
## no llevan la descripción (va al pasar el ratón: `tooltip_text`) y son más bajas, así caben más sin desplazar.
## Solo en pantallas de 600 px lógicos de alto o más, tumbadas, con 5 submenús o más; si no, la rejilla de siempre.

const SEP := 18.0
const ALTO_CHICA := 118.0

static func cabe(pm: PantallaMenu, n: int) -> bool:
	return n >= 5 and not MenuLateral.abajo() and pm.get_viewport_rect().size.y >= 600.0

## Crea las tarjetas de `subs` y las coloca: en `rej` (la rejilla de siempre) o, si `cabe`, en un mosaico que va en `marco`.
## Devuelve las tarjetas en el orden de `subs` (para el foco y la entrada escalonada).
static func armar(pm: PantallaMenu, marco: Control, rej: GridContainer, subs: Array) -> Array:
	var tarjetas: Array = []
	for i in subs.size():   ## (15-11) se arman FUERA de la pantalla y entran de una vez: antes cada tarjeta recolocaba todas
		var t := TarjetaPortada.crear(pm, subs[i], i)
		Idiomas.traducir_arbol(t)
		tarjetas.append(t)
	if not cabe(pm, subs.size()):
		for t: Control in tarjetas:
			rej.add_child(t)
		marco.add_child(rej)
		return tarjetas
	rej.free()
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", int(SEP))
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.add_child(caja)
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", int(SEP))
	caja.add_child(arriba)
	var grande := tarjetas[0] as Control
	grande.custom_minimum_size = Vector2(0, ALTO_CHICA * 2.0 + SEP)
	grande.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grande.size_flags_stretch_ratio = 2.0
	_agrandar(grande)
	arriba.add_child(grande)
	for c in 2:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", int(SEP))
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		arriba.add_child(col)
		for k in 2:
			col.add_child(_chica(tarjetas[1 + c * 2 + k]))
	var fila: HBoxContainer = null
	for i in range(5, tarjetas.size()):
		if (i - 5) % 4 == 0:
			fila = HBoxContainer.new()
			fila.add_theme_constant_override("separation", int(SEP))
			caja.add_child(fila)
		fila.add_child(_chica(tarjetas[i]))
	if fila != null:
		while fila.get_child_count() < 4:   ## la última fila con huecos para que las tarjetas midan lo mismo que las de arriba
			var h := Control.new()
			h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fila.add_child(h)
	return tarjetas

## Una tarjeta chica: sin la descripción (pasa al texto de ayuda), más baja.
static func _chica(t: Control) -> Control:
	t.custom_minimum_size = Vector2(0, ALTO_CHICA)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for l in t.find_children("*", "Label", true, false):
		var lb := l as Label
		if lb.autowrap_mode != TextServer.AUTOWRAP_OFF:
			t.tooltip_text = lb.text
			lb.visible = false
		elif lb.get_theme_font_size("font_size") >= 20:
			lb.add_theme_font_size_override("font_size", 17)
			lb.clip_text = true
	var hueco := Control.new()   ## empuja el dato hacia abajo, donde estaba la descripción
	hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := t.get_child(t.get_child_count() - 1)
	for n in t.get_children():
		if n is VBoxContainer:
			v = n
	if v is VBoxContainer and v.get_child_count() >= 2:
		v.add_child(hueco)
		v.move_child(hueco, 2)
	return t

## La principal: título y dato más grandes.
static func _agrandar(t: Control) -> void:
	for l in t.find_children("*", "Label", true, false):
		var lb := l as Label
		var tam := lb.get_theme_font_size("font_size")
		if lb.autowrap_mode == TextServer.AUTOWRAP_OFF and tam >= 20:
			lb.add_theme_font_size_override("font_size", 30)
		elif lb.autowrap_mode != TextServer.AUTOWRAP_OFF:
			lb.add_theme_font_size_override("font_size", 16)
		elif tam == 14:
			lb.add_theme_font_size_override("font_size", 22)
