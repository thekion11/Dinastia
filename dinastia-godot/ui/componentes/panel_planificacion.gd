class_name PanelPlanificacion
extends RefCounted
## PLANIFICACIÓN DEL PLANTEL (26-10-2026, filas 19-21 de la propuesta de la s4),
## debajo de la lista del plantel, en tres bloques plegables:
##  · PLANIFICADOR (`PlanificadorPlantilla`): carencias, lo que se va en verano,
##    el titular con el contrato acabando y la línea sin relevo;
##  · TABLÓN DE LA LIGA (`TablonLiga`): qué busca cada club de tu país y, si uno de
##    los tuyos encaja, un botón para ofrecérselo (llega como oferta a tu bandeja);
##  · BANQUILLOS CALIENTES (`MercadoDT`): el termómetro de presión de los DT.
## Los textos se montan aquí con `Idiomas.t` (el núcleo devuelve datos).
##   PanelPlanificacion.pintar(lista, mundo, texto, al_cambiar)

const NOMBRE_LINEA := {"POR": "porteros", "DEF": "defensas", "MED": "centrocampistas", "DEL": "delanteros"}
const MAX_TABLON := 8
const MAX_TERMO := 6

## Bloques abiertos (se recuerdan mientras dure la sesión).
static var abiertos := {"plan": true, "tablon": false, "termo": false}

static func pintar(lista: VBoxContainer, m: Mundo, texto: Callable, al_cambiar: Callable) -> void:
	if m == null or m.mi_club() == null:
		return
	var c := m.mi_club()
	var plan := PlanificadorPlantilla.analizar(c)
	var avisos: Array = plan["avisos"]
	var caja := _bloque(lista, "plan", Idiomas.t("PLANIFICADOR DE PLANTILLA") + ("  ·  %d" % avisos.size() if not avisos.is_empty() else ""), texto)
	if avisos.is_empty():
		_linea(caja, Idiomas.t("Sin carencias a la vista: ninguna línea se queda corta este año ni el que viene."), Principal.COL_VERDE, texto)
	for a: Dictionary in avisos:
		_linea(caja, frase_aviso(a), Principal.COL_ROJO if int(a["nivel"]) >= 2 else Principal.COL_ORO, texto)
	var resumen := ""
	for g: String in PlanificadorPlantilla.LINEAS:
		var l: Dictionary = plan["lineas"][g]
		resumen += "%s %d (%d)   " % [g, int(l["total"]), int(l["quedan"])]
	_linea(caja, Idiomas.t("Por línea, hoy y (tras el verano): ") + resumen, Principal.COL_SUAVE, texto)
	_pintar_tablon(lista, m, texto, al_cambiar)
	_pintar_termometro(lista, m, texto)

## La frase de un aviso del planificador.
static func frase_aviso(a: Dictionary) -> String:
	var linea := Idiomas.t(String(NOMBRE_LINEA.get(String(a["grupo"]), "jugadores")))
	match String(a["tipo"]):
		"carencia":
			return Idiomas.t("⚠ Te faltan %d %s: con lesiones o sanciones no llegas.") % [int(a["n"]), linea]
		"verano":
			return Idiomas.t("☀ En verano te quedas corto de %s (faltarán %d). Contratos que vencen: %d · posibles retiros: %d.") % [linea, int(a["n"]), int(a["vencen"]), int(a["retiro"])]
		"titular_se_va":
			return Idiomas.t("✍ Vence el contrato de %s, titular: renuévalo o busca reemplazo.") % (a["jugador"] as Jugador).nombre
		"sin_relevo":
			var j: Jugador = a["jugador"]
			return Idiomas.t("⌛ %s (%d años) no tiene relevo joven en %s.") % [j.nombre, j.edad, linea]
	return ""

## El mejor de los tuyos que encaja en una necesidad (el de más media), o null.
static func candidato(m: Mundo, n: Dictionary) -> Jugador:
	var mejor: Jugador = null
	for j: Jugador in m.mi_club().plantilla:
		if TablonLiga.motivo_rechazo(n, j) == "" and (mejor == null or j.ovr > mejor.ovr):
			mejor = j
	return mejor

static func _pintar_tablon(lista: VBoxContainer, m: Mundo, texto: Callable, al_cambiar: Callable) -> void:
	var tab := TablonLiga.necesidades(m, MAX_TABLON)
	var caja := _bloque(lista, "tablon", Idiomas.t("TABLÓN DE LA LIGA: QUÉ BUSCA CADA CLUB"), texto)
	if tab.is_empty():
		_linea(caja, Idiomas.t("Ningún club de tu país busca a nadie que pueda pagar."), Principal.COL_SUAVE, texto)
		return
	for n: Dictionary in tab:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		caja.add_child(fila)
		var l: Label = texto.call(11, Principal.COL_TEXTO)
		l.text = Idiomas.t("%s busca %s · media %d+ · hasta %d años · %s") % [(n["club"] as Club).nombre,
			Idiomas.t(String(NOMBRE_LINEA[String(n["grupo"])])), int(n["media_min"]), int(n["edad_max"]), Cesiones.dinero(int(n["presupuesto"]))]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(l)
		var j := candidato(m, n)
		if j == null:
			continue
		var b := Button.new()
		b.text = Idiomas.t("Ofrecer a %s") % j.nombre
		b.add_theme_font_size_override("font_size", 11)
		b.tooltip_text = Idiomas.t("Si le encaja, el club te manda una oferta a la bandeja del mercado.")
		var club: Club = n["club"]
		b.pressed.connect(func() -> void:
			var r := TablonLiga.ofrecer(m, j, club)
			b.disabled = true
			b.text = Idiomas.t("Oferta en la bandeja") if bool(r["ok"]) else Idiomas.t(String(r["motivo"]))
			if al_cambiar.is_valid():
				al_cambiar.call())
		fila.add_child(b)

static func _pintar_termometro(lista: VBoxContainer, m: Mundo, texto: Callable) -> void:
	var mdt := MercadoDT.de(m)
	var termo := mdt.termometro(m) if mdt != null else []
	var caja := _bloque(lista, "termo", Idiomas.t("BANQUILLOS CALIENTES"), texto)
	if termo.is_empty():
		_linea(caja, Idiomas.t("Aún es pronto: la presión se mide desde la jornada %d.") % MercadoDT.JORNADA_MINIMA, Principal.COL_SUAVE, texto)
	for f: Dictionary in termo.slice(0, MAX_TERMO):
		var p := int(f["presion"])
		var col := Principal.COL_ROJO if p >= MercadoDT.PRESION_PELIGRO else (Principal.COL_ORO if p >= 55 else Principal.COL_SUAVE)
		var cola := Idiomas.t("  · presión %d") % p
		if bool(f["mio"]):
			cola += Idiomas.t("  (tú)")
		var icono := "🔥" if p >= MercadoDT.PRESION_PELIGRO else "🌡"
		_linea(caja, "%s  %s · %s%s" % [icono, (f["club"] as Club).nombre, String((f["dt"] as Dictionary).get("nombre", "")), cola], col, texto)
	if mdt != null and not mdt.historial.is_empty():
		var h: Dictionary = mdt.historial[mdt.historial.size() - 1]
		_linea(caja, Idiomas.t("Último cambio: %s → %s en %s.") % [String(h["sale"]), String(h["entra"]), String(h["club"])], Principal.COL_SUAVE, texto)

## Un bloque plegable con su título; devuelve la caja de dentro.
static func _bloque(lista: VBoxContainer, clave: String, titulo: String, _texto: Callable) -> VBoxContainer:
	lista.add_child(HSeparator.new())
	var b := Button.new()
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Principal.COL_ORO)
	lista.add_child(b)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 3)
	caja.visible = bool(abiertos.get(clave, false))
	lista.add_child(caja)
	b.text = ("▾ " if caja.visible else "▸ ") + titulo
	b.pressed.connect(func() -> void:
		caja.visible = not caja.visible
		abiertos[clave] = caja.visible
		b.text = ("▾ " if caja.visible else "▸ ") + titulo)
	return caja

static func _linea(caja: VBoxContainer, t: String, col: Color, texto: Callable) -> void:
	var l: Label = texto.call(11, col)
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(l)
