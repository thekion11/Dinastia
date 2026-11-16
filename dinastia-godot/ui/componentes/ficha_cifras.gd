class_name FichaCifras
extends RefCounted
## LOS ATRIBUTOS DE LA FICHA DEL JUGADOR EN CIFRAS GRANDES (16-11, orden 57, frente 1; referencia del Drive: la ficha de
## reparto de atributos, «cifra grande por columna con su detalle»). Sale de `pantalla_ficha.gd` (estaba en 450 líneas).
## Arriba, una banda de 4 cifras (media, potencial, forma, moral); debajo, cada atributo como una columna: la cifra grande
## en su color (verde 80+, blanco 65+, gris el resto), una barra fina y el nombre (con su explicación al pasar). Al lado,
## el radar de siempre. Antes eran parejas «nombre  valor» en letra de 11-12 px.

const ANCHO_COL := 50.0

## `media_txt`: la media como se puede ver (exacta si es tuyo; un rango si es un rival sin ojear). `conoce_pot`: si se ve el potencial.
static func pintar(p: Principal, ficha: VBoxContainer, j: Jugador, media_txt: String, conoce_pot: bool) -> void:
	ficha.add_child(CifrasClave.banda([
		[Idiomas.t("Media"), media_txt, Principal.COL_VERDE],
		[Idiomas.t("Potencial"), str(j.pot) if conoce_pot else "?", Principal.COL_ORO],
		[Idiomas.t("Forma"), str(j.forma), Principal.COL_TEXTO],
		[Idiomas.t("Moral"), str(j.moral), Principal.COL_VERDE if j.moral >= 60 else Principal.COL_ROJO]],
		Principal.COL_SUAVE, 2 if EscalaMovil.es_tactil() else 4))   ## en el teléfono, de a dos por fila
	## Los atributos en una fila de columnas iguales (6 en PC; 3 por fila en el teléfono) y el radar debajo.
	var g := GridContainer.new()
	g.columns = 3 if (EscalaMovil.es_vertical() or EscalaMovil.es_tactil()) else clampi(j.atributos.size(), 1, 6)   ## en el teléfono la columna es estrecha: 3 por fila
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ficha.add_child(g)
	## El radar: la forma del jugador de un vistazo (informe de diseño).
	var radar := RadarAtributos.new()
	var etq := PackedStringArray()
	var vals := PackedFloat32Array()
	for k: String in j.atributos:
		## Nombre traducido y, si es largo, abreviado con punto («Coloc.»).
		var nom_at := Idiomas.t(String(p.NOMBRES_ATRIBUTOS.get(k, k)))
		etq.append(nom_at if nom_at.length() <= 7 else nom_at.left(5) + ".")
		vals.append(float(j.atributos[k]))
	radar.color_texto = Principal.COL_SUAVE
	radar.poner(etq, vals, Principal.COL_VERDE)
	radar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ficha.add_child(radar)
	for k: String in j.atributos:
		g.add_child(_columna(p, k, int(j.atributos[k])))

## Un atributo: la cifra grande, la barra y el nombre.
static func _columna(p: Principal, k: String, v: int) -> Control:
	var col_v := Principal.COL_VERDE if v >= 80 else (Principal.COL_TEXTO if v >= 65 else Principal.COL_SUAVE)
	var caja := PanelContainer.new()
	caja.custom_minimum_size.x = ANCHO_COL
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.04)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6; sb.content_margin_right = 6
	sb.content_margin_top = 4; sb.content_margin_bottom = 5
	caja.add_theme_stylebox_override("panel", sb)
	caja.tooltip_text = Idiomas.t(String(TablasMenu.AYUDA_ATRIBUTOS.get(k, "")))
	var pila := VBoxContainer.new()
	pila.add_theme_constant_override("separation", 1)
	pila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(pila)
	var cifra := p._texto(24, col_v)
	cifra.text = str(v)
	cifra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cifra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pila.add_child(cifra)
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.value = clampi(v, 0, 100)
	barra.custom_minimum_size = Vector2(0, 4)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(1, 1, 1, 0.1)
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = col_v
	barra.add_theme_stylebox_override("background", fondo)
	barra.add_theme_stylebox_override("fill", lleno)
	pila.add_child(barra)
	var nom := p._texto(11, Principal.COL_SUAVE)
	nom.text = String(p.NOMBRES_ATRIBUTOS.get(k, k))
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.clip_text = true
	nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pila.add_child(nom)
	return caja

## (16-11) LA CANTERA EN CIFRAS GRANDES (arriba de Academia, Juveniles y Linaje): lo que sale de casa, de un vistazo.
static func banda_cantera(c: Club) -> Control:
	var de_casa := 0
	var sub21 := 0
	var promesas := 0
	var suma := 0
	for j: Jugador in c.plantilla:
		if j.club_formacion == c.id and j.edad <= 23:   ## al empezar, todo el plantel figura como formado en el club: solo cuentan los jóvenes
			de_casa += 1
		if j.edad <= 21:
			sub21 += 1
			suma += j.ovr
			if j.pot >= 80:
				promesas += 1
	return CifrasClave.banda([
		[Idiomas.t("Jóvenes de casa (≤ 23)"), str(de_casa), Principal.COL_VERDE],
		[Idiomas.t("Sub-21 en el plantel"), str(sub21), Principal.COL_TEXTO],
		[Idiomas.t("Promesas (pot. 80+)"), str(promesas), Principal.COL_ORO],
		[Idiomas.t("Media de los sub-21"), str(roundi(float(suma) / float(sub21))) if sub21 > 0 else "—", Principal.COL_TEXTO]],
		Principal.COL_SUAVE, 2 if EscalaMovil.es_tactil() else 4)

## (16-11) EL MERCADO EN CIFRAS GRANDES (arriba del mercado de fichajes): caja, sueldos, en venta y ofertas que esperan respuesta.
static func banda_mercado(m: Mundo, c: Club) -> Control:
	var en_venta := 0
	for j: Jugador in c.plantilla:
		if j.transferible:
			en_venta += 1
	var ofertas: int = m.mercado.ofertas_recibidas.size() if m.mercado != null else 0
	return CifrasClave.banda([
		[Idiomas.t("Caja"), Eco.dinero(c.saldo), Principal.COL_VERDE if c.saldo >= 0 else Principal.COL_ROJO],
		[Idiomas.t("Sueldos/sem"), Eco.dinero(c.masa_salarial()), Principal.COL_TEXTO],
		[Idiomas.t("En venta"), str(en_venta), Principal.COL_ORO],
		[Idiomas.t("Ofertas recibidas"), str(ofertas), Principal.COL_ORO if ofertas > 0 else Principal.COL_SUAVE]],
		Principal.COL_SUAVE, 2 if EscalaMovil.es_tactil() else 4)
