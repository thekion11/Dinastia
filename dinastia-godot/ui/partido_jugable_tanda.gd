class_name PartidoJugableTanda
extends Node
## LA PRÓRROGA Y LA TANDA EN EL PARTIDO DE LA CARRERA (26-10-2026). En la copa
## (`PartidoJugable.eliminatoria`) el motor ya sabe ir a la prórroga y a los
## penales; esto pone lo que ve el jugador: el pitido y el reloj de la
## prórroga, el marcador de la tanda (el mismo `MarcadorTanda` del modo
## entrenador, con los colores de este modo), la ayuda de cada momento y el
## «gana en penales» en el cuadro final. Va aparte para no pasar de 450 líneas.

var pj: PartidoJugable
var _marcador: MarcadorTanda

static func poner(p: PartidoJugable) -> PartidoJugableTanda:
	var n := PartidoJugableTanda.new()
	n.pj = p
	p.add_child(n)
	p.motor.prorroga_empieza.connect(n._al_empezar_prorroga)
	p.motor.tanda_empieza.connect(n._al_empezar_tanda)
	p.motor.tanda_tiro.connect(func(_eq: int, _id: String, marcado: bool) -> void:
		n._pintar()
		if not p._simulando:
			Sonido.toca("gol" if marcado else "ocasion", Sonido.Bus.AMBIENTE))
	p.motor.cambio_estado.connect(func(e: String) -> void:
		if e == "tanda_penal":
			n._pintar())
	## Después de `_al_terminar` (que monta el cuadro final): se le añade la tanda.
	p.motor.terminado.connect(n._al_terminar)
	return n

func _al_empezar_prorroga() -> void:
	if not pj._simulando:
		Sonido.toca("pitido_final")

func _al_empezar_tanda() -> void:
	if _marcador == null:
		_marcador = MarcadorTanda.crear(pj)
		## Debajo del gran rótulo de sucesos («Penal 3: …», «¡Dentro!»).
		_marcador.offset_top = 186
		var e := (_marcador.get_theme_stylebox("panel") as StyleBoxFlat)
		if e != null:
			e = e.duplicate()
			e.border_color = PartidoJugable.LIMA
			_marcador.add_theme_stylebox_override("panel", e)
	_pintar()

func _pintar() -> void:
	var m := pj.motor
	if _marcador == null or m == null or m.tanda.is_empty():
		return
	var turno := -1 if String(m.tanda.get("fase", "")) == "fin" else m.tanda_turno()
	_marcador.pintar(pj._abrev(pj.local.nombre), pj._abrev(pj.visita.nombre), m.tanda["tiros"], turno)

## La ayuda y el reloj de cada momento (corre después del `_process` de la
## pantalla, que es su padre).
func _process(_delta: float) -> void:
	var m := pj.motor
	if m == null or m.tanda.is_empty() or pj._ayuda == null:
		return
	pj._reloj.text = Idiomas.t("PEN")
	if m.estado != "tanda":
		return
	if m.apuntando or m.tanda_me_toca_parar():
		return
	var fase := String(m.tanda.get("fase", ""))
	if m.tanda_me_toca_tirar() and fase == "preparar":
		pj._ayuda.text = Idiomas.t("TU PENAL: vas al punto. Luego stick para apuntar y mantén %s para la fuerza") % Mando.corto_de("jugar_tiro")
	else:
		pj._ayuda.text = Idiomas.t("TANDA DE PENALES: espera tu turno en el círculo central · %s pausa") % Mando.corto_de("jugar_pausa")

func _al_terminar() -> void:
	_pintar()
	var m := pj.motor
	if m.tanda.is_empty() or not is_instance_valid(pj._resumen):
		return
	var gl := m.goles_tanda(0)
	var gv := m.goles_tanda(1)
	var gana := pj.local if gl > gv else pj.visita
	var caja: VBoxContainer = pj._resumen.find_children("*", "VBoxContainer", true, false)[0]
	var linea := pj._etiqueta(22, PartidoJugable.FUCSIA)
	linea.text = Idiomas.t("%s gana %d-%d en los penales") % [Nombres.visible(gana.nombre), maxi(gl, gv), mini(gl, gv)]
	caja.add_child(linea)
	caja.move_child(linea, 1)
