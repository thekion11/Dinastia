class_name ReplicaPartido
extends RefCounted
## «JUGAR DE NUEVO» Y «JUGAR MOMENTO» DE VERDAD (orden de «Auditoría de sesiones», 17-11): el partido jugable de siempre (`PartidoVivo`, motor C4) con los DOS CLUBES
## CLONADOS (ida y vuelta por el guardado) para que nada de lo que pase toque la partida: ni goles, ni tarjetas, ni sanciones, ni lesiones, ni la tabla. El momento
## arranca un minuto antes de la jugada, con el marcador que había entonces (de la crónica del partido jugado), y se cierra solo a los `MINUTOS_MOMENTO` minutos.
## «Jugar de nuevo» empieza desde el 0-0 y se juega entero. Al cerrar, `terminado` avisa para volver al menú.

const MINUTOS_MOMENTO := 4

signal terminado

## Abre la réplica sobre `pr`. `minuto` = 0 para el partido entero; si no, el minuto de la jugada.
static func abrir(pr: Principal, original: Partido, minuto: int) -> ReplicaPartido:
	var r := ReplicaPartido.new()
	r._abrir(pr, original, minuto)
	return r

static func _clonar(c: Club) -> Club:
	return Partida._dic_a_club(Partida._club_a_dic(c))

## El partido de la réplica: clubes clonados y, si es un momento, el minuto y el marcador de entonces. Separado de la pantalla para poder probarlo.
static func partido_de(original: Partido, minuto: int) -> Partido:
	var p := Partido.new(_clonar(original.local), _clonar(original.visita))
	p.saca_local = original.saca_local
	if minuto > 0:
		p.arranque_minuto = maxi(minuto - 1, 0)
		for e: Dictionary in original.cronica:
			if String(e.get("tipo", "")) == "gol" and int(e.get("min", 0)) < minuto:
				p.arranque_goles[0 if String(e.get("club", "")) == original.local.id else 1] += 1
	return p

func _abrir(pr: Principal, original: Partido, minuto: int) -> void:
	var m := pr.mundo
	var mio_orig := m.mi_club()
	var p := partido_de(original, minuto)
	var local := p.local
	var visita := p.visita
	var mio := local if local.id == mio_orig.id else visita
	Partido.ctx_club_id = mio.id
	var vivo := PartidoVivo.new()
	vivo.con_3d = true
	vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pr.add_child(vivo)
	vivo.datos_pantalla = pr._datos_pantalla_estadio(local, "liga")
	pr._fundido_entrada()
	vivo.abrir(p, mio, null, false, null, pr._velocidad_partido, m.perfil_estadio_de(local).duplicate(), Comercial.color_balon(m.comercial.balon, mio_orig))
	var cierre := func() -> void:
		if is_instance_valid(vivo):
			vivo.queue_free()
		Partido.ctx_club_id = mio_orig.id
		terminado.emit()
	vivo.cerrado.connect(cierre)
	if minuto > 0:
		var limite := p.arranque_minuto + MINUTOS_MOMENTO
		p.minuto_jugado.connect(func(mi: int) -> void:
			if mi >= limite:
				cierre.call())
