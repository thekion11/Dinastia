class_name MomentosPartido
extends PantallaMaqueta
## TODOS LOS MOMENTOS (17-11-2026, como la maqueta): las jugadas importantes del partido ya jugado en tarjetas («12' · Ataque» en verde, «27' · Defensa» en rojo), cada una
## con su texto y el botón JUGAR MOMENTO; abajo, VOLVER AL MENÚ. `filtro`: «todas», «ofensivas» o «defensivas».
## Los momentos se anotan MIENTRAS se juega (`registrar`, con las señales del `Partido`: goles, remates al palo o atajados, rojas) en un metadato de ejecución (no se guarda
## con la partida). Un partido sin rastro (simulado de golpe) cae a los goles de su crónica. `elegido("momento:<n>")` o `elegido("volver")`.

const VERDE := Color("1f7a45")
const ROJO := Color("b32a24")
const META := "momentos_dia"
const MAX := 12   ## tope de momentos que se guardan por partido

## El último partido de tu club (para el botón «Partido jugado» del menú). Solo de ejecución.
static var ultimo: Partido = null
static var ultimo_mundo_id := 0

var partido: Partido
var mi_club: Club
var filtro := "todas"
var _lista: Array = []

## Conecta las señales del partido para ir anotando los momentos. Llamar ANTES de jugarlo. No consume `Azar` ni toca el resultado.
static func registrar(p: Partido) -> void:
	if p.has_meta(META):
		return
	p.set_meta(META, [])
	p.gol.connect(func(c: Club, autor: Jugador, m: int, _a: Jugador) -> void: _anotar(p, m, "gol", c, autor))
	p.remate.connect(func(c: Club, autor: Jugador, tipo: String, m: int) -> void:
		if tipo in ["poste", "atajada"]:
			_anotar(p, m, tipo, c, autor))
	p.tarjeta.connect(func(j: Jugador, roja: bool, m: int) -> void:
		if roja:
			_anotar(p, m, "roja", p.local if p.local.plantilla.has(j) else p.visita, j))

static func _anotar(p: Partido, m: int, tipo: String, c: Club, autor: Jugador) -> void:
	var l: Array = p.get_meta(META)
	if tipo != "atajada" or l.size() < MAX * 5:   ## los goles, palos y rojas siempre; las atajadas, con tope
		l.append({"min": m, "tipo": tipo, "club_id": c.id, "autor": autor.nombre if autor != null else "", "gl": p.goles_local, "gv": p.goles_visita})

## Deja el partido como el último de tu club (para «Partido jugado» del menú).
static func recordar(p: Partido, mundo: Mundo) -> void:
	ultimo = p
	ultimo_mundo_id = mundo.get_instance_id() if mundo != null else 0

static func hay_ultimo(mundo: Mundo) -> bool:
	return ultimo != null and mundo != null and ultimo_mundo_id == mundo.get_instance_id()

## Los momentos del partido, ordenados por minuto, cada uno con su clase («ataque» si es tuyo, «defensa» si es del rival) y su texto.
static func lista_de(p: Partido, club: Club) -> Array:
	var crudo: Array = []
	if p.has_meta(META):
		crudo = (p.get_meta(META) as Array).duplicate()
	if crudo.is_empty():
		for e: Dictionary in p.cronica:
			if String(e.get("tipo", "")) == "gol":
				crudo.append({"min": int(e["min"]), "tipo": "gol", "club_id": String(e["club"]), "autor": String(e.get("autor", ""))})
	## Mandan los goles, los palos y las rojas; las atajadas solo rellenan hasta `MAX`.
	var fuertes := crudo.filter(func(e: Dictionary) -> bool: return String(e["tipo"]) != "atajada")
	var atajadas := crudo.filter(func(e: Dictionary) -> bool: return String(e["tipo"]) == "atajada")
	crudo = fuertes + atajadas.slice(0, maxi(MAX - fuertes.size(), 0))
	crudo.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["min"]) < int(b["min"]))
	var out: Array = []
	for e: Dictionary in crudo:
		var mio := String(e["club_id"]) == club.id
		## Una atajada o un palo del rival es una ocasión de ataque del rival: defensa para ti. Una roja es del equipo que la sufre.
		var ataque := mio if String(e["tipo"]) != "roja" else not mio
		var quien := ResultadoPartido.abreviar(String(e["autor"]))
		var txt := ""
		match String(e["tipo"]):
			"gol": txt = Idiomas.t("Gol de %s.") % quien if mio else Idiomas.t("Gol del rival: %s.") % quien
			"poste": txt = Idiomas.t("Remate al palo de %s.") % quien
			"atajada": txt = Idiomas.t("El portero ataja el remate de %s.") % quien
			"roja": txt = Idiomas.t("Roja a %s.") % quien
		out.append({"min": int(e["min"]), "ataque": ataque, "txt": txt})
		if out.size() >= MAX:
			break
	return out

static func mostrar(pr: Node, p: Partido, club: Club, filtro_: String = "todas") -> MomentosPartido:
	var s := MomentosPartido.new()
	s.partido = p
	s.mi_club = club
	s.filtro = filtro_
	s._armar(pr)
	return s

func _armar(pr: Node) -> void:
	montar(pr, FondoCine.Modo.NOCHE, Color.BLACK)
	var raiz := VBoxContainer.new()
	raiz.anchor_right = 1.0; raiz.anchor_bottom = 1.0
	raiz.offset_left = 60; raiz.offset_right = -60; raiz.offset_top = 40; raiz.offset_bottom = -130
	raiz.add_theme_constant_override("separation", 6)
	_raiz.add_child(raiz)
	raiz.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Todos los momentos"), 64, EstiloAvanzar.TINTA, true, true))
	raiz.add_child(EstiloAvanzar.etiqueta("%s %d-%d %s · %s" % [partido.local.nombre, partido.goles_local, partido.goles_visita, partido.visita.nombre,
		Idiomas.t("elige un momento y juégalo desde ese minuto")], 18, EstiloAvanzar.SUAVE))
	var desliza := ScrollContainer.new()
	desliza.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	raiz.add_child(desliza)
	var rej := GridContainer.new()
	rej.columns = 3
	rej.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rej.add_theme_constant_override("h_separation", 22)
	rej.add_theme_constant_override("v_separation", 18)
	desliza.add_child(rej)
	_lista = []
	for m: Dictionary in lista_de(partido, mi_club):
		if (filtro == "ofensivas" and not bool(m["ataque"])) or (filtro == "defensivas" and bool(m["ataque"])) or (filtro == "goles" and String(m.get("tipo", "")) != "gol"):
			continue
		_lista.append(m)
	var primero: Button = null
	for i in _lista.size():
		var b := _tarjeta(rej, _lista[i], i)
		if primero == null:
			primero = b
	if _lista.is_empty():
		rej.add_child(EstiloAvanzar.etiqueta(Idiomas.t("No hubo momentos de este tipo."), 22, EstiloAvanzar.SUAVE))
	var volver := boton(Idiomas.t("Volver al menú"), true)
	volver.custom_minimum_size = Vector2(300, 58)
	volver.pressed.connect(func() -> void: elegido.emit("volver"))
	volver.anchor_left = 1.0; volver.anchor_right = 1.0; volver.anchor_top = 1.0; volver.anchor_bottom = 1.0
	volver.offset_left = -340; volver.offset_right = -40; volver.offset_top = -100; volver.offset_bottom = -40
	_raiz.add_child(volver)
	var ayuda := ayuda_mando()
	ayuda.anchor_top = 1.0; ayuda.anchor_bottom = 1.0
	ayuda.offset_left = 60; ayuda.offset_top = -70; ayuda.offset_bottom = -40
	_raiz.add_child(ayuda)
	(primero if primero != null else volver).grab_focus.call_deferred()

func _tarjeta(padre: Control, m: Dictionary, i: int) -> Button:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("d8dcec")
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var ataque := bool(m["ataque"])
	v.add_child(EstiloAvanzar.etiqueta("%d' · %s" % [int(m["min"]), Idiomas.t("Ataque") if ataque else Idiomas.t("Defensa")], 40, VERDE if ataque else ROJO, true))
	var t := EstiloAvanzar.etiqueta(String(m["txt"]), 17, Color("1b2340"))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var b := boton(Idiomas.t("Jugar desde el minuto %d") % int(m["min"]), true, 16)
	b.custom_minimum_size = Vector2(170, 40)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func() -> void: elegido.emit("momento:%d" % i))
	v.add_child(b)
	padre.add_child(panel)
	return b
