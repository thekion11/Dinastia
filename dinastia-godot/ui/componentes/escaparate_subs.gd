class_name EscaparateSubs
extends RefCounted
## «DIRECCIÓN DEL EQUIPO» E «INFORMACIÓN DEL CLUB» EN EL LENGUAJE DEL ESCAPARATE (17-11-2026): el mismo mosaico con IMAGEN (una sala del club por tarjeta, teñida con el
## color del club), icono grande y el dato vivo en grande; nueve tarjetas (una grande, cuatro medianas, cuatro bajas) que se REPARTEN el alto: sin desplazamiento y sin el
## informe de la semana debajo. Cada tarjeta es `TableroInicio.tarjeta` (foco de mando, campana roja de `CampanasMenu`) y abre su submenú como siempre.

## La sala de fondo de cada tarjeta (`assets/ui/mosaico/*.jpg`).
const SALA := {"*plantel": "vestuario", "Pizarra y dibujo": "video", "Entrenamiento": "estadio", "Mercado de fichajes": "oficina", "Academia": "tunel",
	"Enfermería": "vestuario", "Contratos": "oficina", "Personal del club": "despacho", "Camarín": "vestuario",
	"*cuentas": "despacho", "Patrocinadores": "oficina", "Hinchada y socios": "estadio", "Diseño del estadio": "estadio", "Historia del club": "museo",
	"Ligas y clubes": "video", "Correo": "oficina", "Récords": "museo", "*sistema": "despacho"}

static func _sub_de(rot: String) -> Dictionary:
	var sitio := TableroInicio.buscar(rot)
	if not sitio.is_empty():
		return (MenusLaterales.menu_por_id(String(sitio[0]))["subs"] as Array)[int(sitio[1])]
	return {"label": "Sistema", "icono": "⚙️", "desc": "Guardar, cargar, pantalla, sonido y controles."}

## Una tarjeta del mosaico: sala de fondo, velo oscuro abajo, icono grande y dato en grande.
static func _tarjeta(p: Principal, c: Club, rot: String, acento: Color) -> Control:
	var tinte := Color(EscaparateBarra.color_de(c))
	var b: Control
	if rot == "*plantel":
		b = MosaicoTarjetas.plantel(p, c, acento)
	elif rot == "*cuentas":
		b = MosaicoTarjetas.cuentas(p, c, acento)
	else:
		var sub := _sub_de(rot)
		var tc := TableroInicio.tarjeta(Idiomas.t(String(sub.get("label", rot))), acento, func() -> void: TableroInicio.abrir(p, rot), Color(0.05, 0.07, 0.09, 1.0))
		b = tc[0]
		(b as Button).tooltip_text = Idiomas.t(String(sub.get("desc", "")))
		var v: VBoxContainer = tc[1]
		var fila := HBoxContainer.new()
		fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fila.add_theme_constant_override("separation", 12)
		v.add_child(fila)
		var ic := IconosUI.control(String(sub.get("icono", "•")), 44)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		fila.add_child(ic)
		var d := EstiloAvanzar.etiqueta(MenuLateral.dato(p, sub), 24, acento, true)
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.size_flags_vertical = Control.SIZE_SHRINK_END
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		d.clip_text = true
		fila.add_child(d)
		TableroInicio.cerrar(b)
	EscaparateTarjetas._escena(b, String(SALA.get(rot, "despacho")), tinte)
	EscaparateTarjetas._velo(b, 1, 0.25)
	b.custom_minimum_size = Vector2(120, 70)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return b

## Reparte las nueve tarjetas: arriba la grande (2) y dos columnas de dos (1,5 del alto); abajo cuatro (1). Todo por proporciones: nada se sale ni se desliza.
static func pintar(p: Principal, cuerpo: VBoxContainer, c: Club, lista: Array, acento: Color) -> void:
	var t: Array[Control] = []
	for rot: String in lista:
		t.append(_tarjeta(p, c, rot, acento))
	var arriba := HBoxContainer.new()
	arriba.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arriba.size_flags_stretch_ratio = 1.5
	arriba.add_theme_constant_override("separation", TableroInicio.SEP)
	cuerpo.add_child(arriba)
	t[0].size_flags_stretch_ratio = 2.0
	arriba.add_child(t[0])
	for k in 2:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", TableroInicio.SEP)
		arriba.add_child(col)
		col.add_child(t[1 + 2 * k])
		col.add_child(t[2 + 2 * k])
	var abajo := HBoxContainer.new()
	abajo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	abajo.size_flags_stretch_ratio = 1.0
	abajo.add_theme_constant_override("separation", TableroInicio.SEP)
	cuerpo.add_child(abajo)
	for i in range(5, t.size()):
		abajo.add_child(t[i])
