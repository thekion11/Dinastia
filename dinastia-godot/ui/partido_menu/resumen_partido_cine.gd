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

static func _ancla(c: Control, l: float, t: float, r: float, b: float) -> Control:
	return ResultadoPartido._ancla(c, l, t, r, b)

## Todo el resumen dentro de `raiz`. `descanso`: rótulo «DESCANSO» y la figura de la primera parte.
static func montar(raiz: Control, p: Partido, mi_club: Club, descanso: bool) -> void:
	var mio_local := p.local == mi_club
	var gm := p.goles_local if mio_local else p.goles_visita
	var gr := p.goles_visita if mio_local else p.goles_local
	var clave := "DESCANSO" if descanso else ("VICTORIA" if gm > gr else ("DERROTA" if gm < gr else "EMPATE"))
	var col := CLARO if descanso else (VERDE if gm > gr else (ROJO if gm < gr else AMARILLO))
	var titulo := EstiloAvanzar.etiqueta(Idiomas.t(clave), 22, col, true, true)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_ancla(titulo, 0.0, 0.03, 1.0, 0.08))
	if descanso:
		var minuto := EstiloAvanzar.etiqueta("45'", 18, AMARILLO, true)
		minuto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		raiz.add_child(_ancla(minuto, 0.0, 0.075, 1.0, 0.11))
	_equipo(raiz, p, p.local, 0.12, 0.34)
	_equipo(raiz, p, p.visita, 0.66, 0.88)
	var marcador := EstiloAvanzar.etiqueta("%d - %d" % [p.goles_local, p.goles_visita], 140, EstiloAvanzar.TINTA, true)
	marcador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marcador.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	raiz.add_child(_ancla(marcador, 0.36, 0.08, 0.64, 0.30))
	_barras(raiz, p)
	_figura(raiz, p)

## Escudo con sombra, nombre y, debajo, sus goleadores con los minutos.
static func _equipo(raiz: Control, p: Partido, c: Club, x0: float, x1: float) -> void:
	var esc: Control = load("res://ui/partido_menu/menu_partido_previa.gd").escudo(c, 140)   ## con load(): el menú central nombra ResultadoPartido y la memoria del menú no debe llegar a MenuPartido
	raiz.add_child(_ancla(esc, x0 + 0.04, 0.085, x1 - 0.04, 0.24))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	var n := EstiloAvanzar.etiqueta(Nombres.visible(c.nombre), 28, EstiloAvanzar.TINTA, true, true)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.clip_text = true
	col.add_child(n)
	for g: String in goleadores(p, c):
		var f := HBoxContainer.new()
		f.alignment = BoxContainer.ALIGNMENT_CENTER
		f.add_theme_constant_override("separation", 6)
		var ic := TextureRect.new()
		ic.texture = EstiloAvanzar.icono("ball", Color(1, 1, 1, 0.85), 18)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		f.add_child(ic)
		f.add_child(EstiloAvanzar.etiqueta(g, 17, Color(1, 1, 1, 0.85), true))
		col.add_child(f)
	raiz.add_child(_ancla(col, x0 - 0.04, 0.245, x1 + 0.04, 0.38))

## Las estadísticas comparadas: cifra local, barra a dos colores y cifra visitante, con el rótulo en medio debajo.
static func _barras(raiz: Control, p: Partido) -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 4)
	for d: Array in estadisticas(p):
		var a := int(d[1])
		var b := int(d[2])
		var fila := HBoxContainer.new()
		var na := EstiloAvanzar.etiqueta(str(a), 20, Color.WHITE, true)
		na.custom_minimum_size = Vector2(60, 0)
		fila.add_child(na)
		var rot := EstiloAvanzar.etiqueta(Idiomas.t(String(d[0])), 14, EstiloAvanzar.SUAVE, false, true)
		rot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(rot)
		var nb := EstiloAvanzar.etiqueta(str(b), 20, Color.WHITE, true)
		nb.custom_minimum_size = Vector2(60, 0)
		nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(nb)
		caja.add_child(fila)
		var barra := ResultadoPartido._Barra.new()
		barra.local = float(a) / maxf(float(a + b), 1.0) if (a + b) > 0 else 0.5
		barra.custom_minimum_size = Vector2(0, 6)
		caja.add_child(barra)
	raiz.add_child(_ancla(caja, 0.06, 0.46, 0.60, 0.86))

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
		raiz.add_child(_ancla(r3d, 0.63, 0.43, 0.81, 0.86))
		r3d.call_deferred("montar")
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 0)
	t.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Figura del partido"), 13, EstiloAvanzar.SUAVE, false, true))
	t.add_child(EstiloAvanzar.etiqueta(ResultadoPartido.abreviar(j.nombre), 32, Color.WHITE, true, true))
	t.add_child(EstiloAvanzar.etiqueta(Nombres.visible(club.nombre), 15, EstiloAvanzar.SUAVE))
	t.add_child(EstiloAvanzar.etiqueta(("%.1f" % float(mvp["nota"])).replace(".", ","), 44, AMARILLO, true))
	raiz.add_child(_ancla(t, 0.81, 0.55, 0.99, 0.84))

## Una fila de botones abajo a la derecha: [[texto, acción, rojo]]; el primero recibe el foco (mando).
static func botones(raiz: Control, lista: Array) -> Array:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_END
	fila.add_theme_constant_override("separation", 14)
	var hechos: Array = []
	for par: Array in lista:
		var b := PantallaMaqueta.boton(Idiomas.t(String(par[0])), bool(par[2]))
		b.custom_minimum_size = Vector2(220, 56)
		b.pressed.connect(par[1])
		fila.add_child(b)
		hechos.append(b)
	raiz.add_child(_ancla(fila, 0.30, 0.88, 0.97, 0.96))
	if not hechos.is_empty():
		(hechos[0] as Button).grab_focus.call_deferred()
	return hechos
