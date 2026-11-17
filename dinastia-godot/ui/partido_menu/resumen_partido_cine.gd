class_name ResumenPartidoCine
extends RefCounted
## EL RESUMEN DEL PARTIDO, COMÚN AL DESCANSO Y AL FINAL (17-11-2026, Auditoría: «al nivel de la referencia»). Arma, dentro del `_raiz` de una
## `PantallaMaqueta`: el rótulo (DESCANSO / VICTORIA / EMPATE / DERROTA), los dos escudos con sus nombres y el marcador grande, los goleadores de
## cada club con sus minutos debajo de su escudo, las estadísticas comparadas en barras y la figura del partido con su retrato 3D y su nota.
## LAS CIFRAS SON LAS REALES del `Partido` (jugado, simulado o saltado): posesión, tiros, a puerta, faltas, córners y fueras de juego las lleva siempre;
## los PASES solo existen si se jugó en el césped (los deja `VistaEstadio` en la meta «pases»): si no, la fila no sale (nada de ceros inventados).
## Los botones los pone quien lo usa (`ResultadoPartido`: Continuar / Repetición de los goles / Jugar momentos; `DescansoPartido`: Continuar /
## Cambios / Táctica).

const VERDE := Color("2fa866")
const AMARILLO := Color("e2b84a")
const ROJO := Color("e5484d")
const ROJO_BARRA := Color("c8102e")
const CLARO := Color("d6dcf0")

## Las filas de estadísticas que tiene este partido: [rótulo, local, visita, es_porcentaje].
static func estadisticas(p: Partido) -> Array:
	var pl := int(round(p.posesion_local))
	var filas: Array = [["Posesión %", pl, 100 - pl, true], ["Tiros", p.remates_local, p.remates_visita, false],
		["Tiros a puerta", p.tiros_puerta_local, p.tiros_puerta_visita, false]]
	var pases = p.get_meta("pases") if p.has_meta("pases") else null   ## (get_meta con null por defecto avisa de error)
	if pases is Array and (pases as Array).size() == 2:
		var tot: Array = pases[0]
		var ok: Array = pases[1]
		if int(tot[0]) + int(tot[1]) > 0:
			filas.append(["Pases", int(tot[0]), int(tot[1]), false])
			filas.append(["Precisión de pase %", int(round(100.0 * float(ok[0]) / maxf(float(tot[0]), 1.0))), int(round(100.0 * float(ok[1]) / maxf(float(tot[1]), 1.0))), true])
	filas.append(["Faltas", p.faltas_local, p.faltas_visita, false])
	filas.append(["Tarjetas amarillas", p.amarillas_local, p.amarillas_visita, false])
	if p.rojas_local + p.rojas_visita > 0:
		filas.append(["Tarjetas rojas", p.rojas_local, p.rojas_visita, false])
	filas.append(["Córners", p.corners_local, p.corners_visita, false])
	filas.append(["Fueras de juego", p.fueras_local, p.fueras_visita, false])
	return filas

## «Gómez 12', 40'» de un club (los goles de la crónica, en orden).
static func goleadores(p: Partido, c: Club) -> Array:
	var por := {}
	var orden: Array = []
	for e: Dictionary in p.cronica:
		if String(e.get("tipo", "")) == "gol" and String(e.get("club", "")) == c.id:
			var n := ResultadoPartido.abreviar(String(e.get("autor", "?")))
			if not por.has(n):
				por[n] = []
				orden.append(n)
			(por[n] as Array).append("%d'" % int(e.get("min", 0)))
	var r: Array = []
	for n: String in orden:
		r.append("%s  %s" % [n, ", ".join(por[n])])
	return r

## Las tarjetas de un club en orden: [«Gómez 34'», roja].
static func tarjetas(p: Partido, c: Club) -> Array:
	var r: Array = []
	for e: Dictionary in p.cronica:
		var t := String(e.get("tipo", ""))
		if t in ["amarilla", "roja"] and String(e.get("club", "")) == c.id:
			r.append(["%s %d'" % [ResultadoPartido.abreviar(String(e.get("autor", "?"))), int(e.get("min", 0))], t == "roja"])
	return r

## La cartulina dibujada (amarilla o roja), del tamaño de una letra.
static func cartulina(roja: bool, alto: float = 15.0) -> ColorRect:
	var cr := ColorRect.new()
	cr.color = ROJO_BARRA if roja else Color("f2c94c")
	cr.custom_minimum_size = Vector2(alto * 0.7, alto)
	cr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return cr

static func _ancla(c: Control, l: float, t: float, r: float, b: float) -> Control:
	return ResultadoPartido._ancla(c, l, t, r, b)

## DÓNDE VA CADA COSA (anclas l, t, r, b), en el PC y en el TELÉFONO (17-11, auditoría táctil: el lienzo del teléfono es ~1067×480, más ancho y
## mucho más bajo; ahí las estadísticas van en dos columnas, la figura más estrecha y los botones abajo a todo el ancho, de ≥ 9 mm).
const SITIO := {
	"titulo": [[0.0, 0.03, 1.0, 0.08], [0.0, 0.01, 1.0, 0.07]],
	"minuto": [[0.0, 0.075, 1.0, 0.11], [0.0, 0.065, 1.0, 0.10]],
	"marcador": [[0.36, 0.08, 0.64, 0.30], [0.37, 0.07, 0.63, 0.29]],
	"linea": [[0.06, 0.405, 0.94, 0.47], [0.02, 0.42, 0.98, 0.48]],
	"barras": [[0.06, 0.48, 0.60, 0.865], [0.0, 0.535, 0.70, 0.835]],
	"retrato": [[0.63, 0.43, 0.81, 0.86], [0.70, 0.43, 0.84, 0.84]],
	"figura": [[0.81, 0.55, 0.99, 0.84], [0.84, 0.52, 1.0, 0.82]],
	"botones": [[0.30, 0.88, 0.97, 0.96], [0.0, 0.855, 1.0, 0.99]],
}
## Tamaños de letra [PC, teléfono].
const LETRA := {"marcador": [140, 100], "nombre": [28, 20], "gol": [17, 14], "tarjeta": [13, 13], "cifra": [20, 17], "rotulo": [14, 13],
	"fig_rotulo": [13, 13], "fig_nombre": [32, 22], "fig_club": [15, 13], "fig_nota": [44, 34]}

static func _movil(raiz: Control) -> bool:
	return bool(raiz.get_meta("movil", false))

static func _l(raiz: Control, que: String) -> int:
	return int(LETRA[que][1 if _movil(raiz) else 0])

## Pone `c` en su sitio (dentro de la zona segura en el teléfono).
static func poner(raiz: Control, c: Control, que: String) -> Control:
	var a: Array = SITIO[que][1 if _movil(raiz) else 0]
	var z: Control = raiz.get_meta("zona") if raiz.has_meta("zona") else raiz
	z.add_child(_ancla(c, a[0], a[1], a[2], a[3]))
	return c

## Todo el resumen dentro de `raiz`. `descanso`: rótulo «DESCANSO» y la figura de la primera parte.
static func montar(raiz: Control, p: Partido, mi_club: Club, descanso: bool) -> void:
	raiz.set_meta("movil", TactilPartido.es_movil(raiz))
	raiz.set_meta("zona", TactilPartido.zona_segura(raiz))
	var mio_local := p.local == mi_club
	var gm := p.goles_local if mio_local else p.goles_visita
	var gr := p.goles_visita if mio_local else p.goles_local
	var clave := "DESCANSO" if descanso else ("VICTORIA" if gm > gr else ("DERROTA" if gm < gr else "EMPATE"))
	var col := CLARO if descanso else (VERDE if gm > gr else (ROJO if gm < gr else AMARILLO))
	var titulo := EstiloAvanzar.etiqueta(Idiomas.t(clave), 22, col, true, true)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poner(raiz, titulo, "titulo")
	if descanso:
		var minuto := EstiloAvanzar.etiqueta("45'", 18, AMARILLO, true)
		minuto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		poner(raiz, minuto, "minuto")
	var m := _movil(raiz)
	_equipo(raiz, p, p.local, 0.10 if m else 0.12, 0.34 if m else 0.34)
	_equipo(raiz, p, p.visita, 0.66, 0.90 if m else 0.88)
	var marcador := EstiloAvanzar.etiqueta("%d - %d" % [p.goles_local, p.goles_visita], _l(raiz, "marcador"), EstiloAvanzar.TINTA, true)
	marcador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marcador.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	poner(raiz, marcador, "marcador")
	_barras(raiz, p)
	_figura(raiz, p)

## Escudo con sombra, nombre y, debajo, sus goleadores con los minutos y sus tarjetas.
static func _equipo(raiz: Control, p: Partido, c: Club, x0: float, x1: float) -> void:
	var m := _movil(raiz)
	var z: Control = raiz.get_meta("zona") if raiz.has_meta("zona") else raiz
	var esc: Control = load("res://ui/partido_menu/menu_partido_previa.gd").escudo(c, 100 if m else 140)   ## con load(): el menú central nombra ResultadoPartido y la memoria del menú no debe llegar a MenuPartido
	z.add_child(_ancla(esc, x0 + 0.04, 0.07 if m else 0.085, x1 - 0.04, 0.22 if m else 0.24))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0 if m else 2)
	var n := EstiloAvanzar.etiqueta(Nombres.visible(c.nombre), _l(raiz, "nombre"), EstiloAvanzar.TINTA, true, true)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.clip_text = true
	col.add_child(n)
	for g: String in goleadores(p, c):
		var f := HBoxContainer.new()
		f.alignment = BoxContainer.ALIGNMENT_CENTER
		f.add_theme_constant_override("separation", 6)
		var ic := TextureRect.new()
		ic.texture = EstiloAvanzar.icono("ball", Color(1, 1, 1, 0.85), _l(raiz, "gol") + 1)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		f.add_child(ic)
		f.add_child(EstiloAvanzar.etiqueta(g, _l(raiz, "gol"), Color(1, 1, 1, 0.85), true))
		col.add_child(f)
	var ts := tarjetas(p, c)
	if not ts.is_empty():
		var fl := HFlowContainer.new()
		fl.alignment = FlowContainer.ALIGNMENT_CENTER
		fl.add_theme_constant_override("h_separation", 12)
		fl.add_theme_constant_override("v_separation", 0)
		for t: Array in ts:   ## cartulina y nombre juntos: nunca se separan en dos líneas
			var par := HBoxContainer.new()
			par.add_theme_constant_override("separation", 4)
			par.add_child(cartulina(bool(t[1]), float(_l(raiz, "tarjeta"))))
			par.add_child(EstiloAvanzar.etiqueta(String(t[0]), _l(raiz, "tarjeta"), Color(1, 1, 1, 0.7)))
			fl.add_child(par)
		col.add_child(fl)
	z.add_child(_ancla(col, x0 - 0.06, 0.225 if m else 0.245, x1 + 0.06, 0.43 if m else 0.40))

## Las estadísticas comparadas: cifra local, barra a dos colores y cifra visitante, con el rótulo en medio. En el teléfono, en dos columnas.
static func _barras(raiz: Control, p: Partido) -> void:
	var filas := estadisticas(p)
	var m := _movil(raiz)
	var cajas: Array = []
	var fuera := HBoxContainer.new()
	fuera.add_theme_constant_override("separation", 24)
	for k in (2 if m else 1):
		var caja := VBoxContainer.new()
		caja.add_theme_constant_override("separation", 2 if m else 4)
		caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fuera.add_child(caja)
		cajas.append(caja)
	var mitad := ceili(filas.size() / 2.0)
	for i in filas.size():
		var d: Array = filas[i]
		var caja: VBoxContainer = cajas[1 if (m and i >= mitad) else 0]
		var a := int(d[1])
		var b := int(d[2])
		var fila := HBoxContainer.new()
		var na := EstiloAvanzar.etiqueta(str(a), _l(raiz, "cifra"), Color.WHITE, true)
		na.custom_minimum_size = Vector2(40 if m else 60, 0)
		fila.add_child(na)
		var rot := EstiloAvanzar.etiqueta(Idiomas.t(String(d[0])), _l(raiz, "rotulo"), EstiloAvanzar.SUAVE, false, true)
		rot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rot.clip_text = true
		fila.add_child(rot)
		var nb := EstiloAvanzar.etiqueta(str(b), _l(raiz, "cifra"), Color.WHITE, true)
		nb.custom_minimum_size = Vector2(40 if m else 60, 0)
		nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(nb)
		caja.add_child(fila)
		var barra := ResultadoPartido._Barra.new()
		barra.local = float(a) / maxf(float(a + b), 1.0) if (a + b) > 0 else 0.5
		barra.custom_minimum_size = Vector2(0, 4 if m else 6)
		caja.add_child(barra)
	poner(raiz, fuera, "barras")

## La figura del partido (la mejor nota hasta ahora): su retrato 3D con la equipación de su club, su nombre y su nota. Sin pantalla, solo el texto.
static func _figura(raiz: Control, p: Partido) -> void:
	var vals := p.valoraciones()
	if vals.is_empty():
		return
	var mvp: Dictionary = vals[0]
	var j: Jugador = mvp["jugador"]
	var club := p.local if bool(mvp["local"]) else p.visita
	var r3d: Control = load("res://ui/partido_menu/retrato_jugador3d.gd").crear(club, j, [], -0.3)
	if r3d != null:
		poner(raiz, r3d, "retrato")
		r3d.call_deferred("montar")
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 0)
	t.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Figura del partido"), _l(raiz, "fig_rotulo"), EstiloAvanzar.SUAVE, false, true))
	var nom := EstiloAvanzar.etiqueta(ResultadoPartido.abreviar(j.nombre), _l(raiz, "fig_nombre"), Color.WHITE, true, true)
	nom.clip_text = true
	t.add_child(nom)
	var cl := EstiloAvanzar.etiqueta(Nombres.visible(club.nombre), _l(raiz, "fig_club"), EstiloAvanzar.SUAVE)
	cl.clip_text = true
	t.add_child(cl)
	t.add_child(EstiloAvanzar.etiqueta(("%.1f" % float(mvp["nota"])).replace(".", ","), _l(raiz, "fig_nota"), AMARILLO, true))
	poner(raiz, t, "figura")

## Una fila de botones abajo (a la derecha en el PC, a todo el ancho en el teléfono): [[texto, acción, rojo]]; el primero recibe el foco (mando).
static func botones(raiz: Control, lista: Array) -> Array:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_END
	fila.add_theme_constant_override("separation", 14)
	var hechos: Array = []
	for par: Array in lista:
		var b := PantallaMaqueta.boton(Idiomas.t(String(par[0])), bool(par[2]))
		b.custom_minimum_size = Vector2(0 if _movil(raiz) else 220, 56)
		if _movil(raiz):
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(par[1])
		fila.add_child(b)
		hechos.append(b)
	poner(raiz, fila, "botones")
	TactilPartido.agrandar(fila)
	if not hechos.is_empty():
		(hechos[0] as Button).grab_focus.call_deferred()
	return hechos
