extends BaseIdea
## LA TÁCTICA VUELVE TRAS EL PARTIDO Y LA COSTUMBRE DEL PLAN (25-10-2026).
## `_aplicar_plan()` escribía el plan en `club.tactica` para siempre; ahora se
## devuelve al pitar el final, y seis activaciones seguidas del mismo cambio
## abren la pregunta de `PreguntaPlan`.

const OFE := Tactica.Mentalidad.OFENSIVA
const EQU := Tactica.Mentalidad.EQUILIBRADA

## Un partido de `mio` (local) que llega al 60 con el marcador dado y se juega
## hasta el final. Devuelve la mentalidad que tenía justo en el 60.
func _jugar(mio: Club, rival: Club, gl: int, gv: int) -> Array:
	var p := Partido.new(mio, rival)
	p.preparar()
	p.goles_local = gl
	p.goles_visita = gv
	p.minuto = 59
	p.simular_minuto()
	var en_60 := [mio.tactica.mentalidad, mio.tactica.linea]
	while not p.terminado_ya:
		p.simular_minuto()
	return en_60

func _probar() -> void:
	_titulo("PLAN: TÁCTICA DEVUELTA Y COSTUMBRE DE 6")
	var m := _mundo(2510)
	var mio := m.mi_club()
	var rival: Club = m.ligas[0].clubes[1]
	Partido.ctx_club_id = mio.id
	var t := mio.tactica
	t.mentalidad = EQU
	t.linea = Tactica.Nivel.MEDIO
	t.plan_perdiendo = "ofensivo"

	## 1) Restauración.
	var en_60 := _jugar(mio, rival, 0, 1)
	_comprobar(int(en_60[0]) == OFE and int(en_60[1]) == Tactica.Nivel.ALTO, "en el 60 perdiendo salta el plan ofensivo")
	_comprobar(t.mentalidad == EQU and t.linea == Tactica.Nivel.MEDIO, "al acabar vuelve la táctica de antes")
	_comprobar(t.racha_plan_clave == "perdiendo:ofensivo" and t.racha_plan_n == 1, "la racha cuenta 1")
	## La IA (no humana) no cuenta racha, pero también recupera su táctica.
	_comprobar(rival.tactica.racha_plan_n == 0, "el rival no humano no lleva racha")

	## 2) Un partido sin activación corta la racha.
	_jugar(mio, rival, 1, 0)
	_comprobar(t.racha_plan_n == 0 and t.racha_plan_clave == "", "sin activación la racha vuelve a 0")

	## 3) Seis seguidos → toca preguntar (y no antes).
	for i in 5:
		_jugar(mio, rival, 0, 1)
	_comprobar(t.racha_plan_n == 5 and not t.toca_preguntar_plan(), "con 5 todavía no se pregunta")
	_jugar(mio, rival, 0, 1)
	_comprobar(t.racha_plan_n == 6 and t.toca_preguntar_plan(), "con 6 seguidos toca preguntar")

	## 4) La interfaz: se abre una sola vez y «No, gracias» reinicia la cuenta.
	var padre := Control.new()
	add_child(padre)
	var dlg := PreguntaPlan.mostrar_si_toca(padre, mio)
	_comprobar(dlg != null, "se abre la pregunta")
	_comprobar(PreguntaPlan.mostrar_si_toca(padre, mio) == null, "no se apila una segunda")
	_comprobar(dlg.find_child("Opcion_siempre", true, false) != null and dlg.find_child("Opcion_desde_60", true, false) != null
		and dlg.find_child("Opcion_no", true, false) != null, "tiene las tres opciones")
	dlg.elegir("no")
	_comprobar(t.racha_plan_n == 0 and t.plan_perdiendo == "ofensivo" and t.mentalidad == EQU, "«No, gracias» solo reinicia la cuenta")

	## 5) «Solo desde el minuto 60»: queda el plan y no se vuelve a preguntar por él.
	for i in 6:
		_jugar(mio, rival, 0, 1)
	t.responder_plan("desde_60")
	_comprobar(t.plan_fijo == "perdiendo:ofensivo" and t.plan_perdiendo == "ofensivo" and t.mentalidad == EQU, "«desde el 60» deja el plan fijo")
	for i in 6:
		_jugar(mio, rival, 0, 1)
	_comprobar(t.racha_plan_n == 6 and not t.toca_preguntar_plan(), "aceptado como plan fijo, no se vuelve a preguntar")

	## 6) Guardado: la racha va con el club; un guardado viejo carga a cero.
	var d := Partida._club_a_dic(mio)
	var c2 := Partida._dic_a_club(d)
	_comprobar(c2.tactica.racha_plan_n == 6 and c2.tactica.racha_plan_clave == "perdiendo:ofensivo"
		and c2.tactica.plan_fijo == "perdiendo:ofensivo", "la racha y el plan fijo se guardan y se cargan")
	d.erase("plan_rc")
	d.erase("plan_rn")
	d.erase("plan_fijo")
	var c3 := Partida._dic_a_club(d)
	_comprobar(c3.tactica.racha_plan_n == 0 and c3.tactica.racha_plan_clave == "" and c3.tactica.plan_fijo == "", "guardado viejo: racha a cero")

	## 7) «Siempre, todo el partido»: pasa a la base y el plan de ese lado se apaga.
	t.plan_fijo = ""
	t.racha_plan_clave = ""
	t.racha_plan_n = 0
	for i in 6:
		_jugar(mio, rival, 0, 1)
	var dlg2 := PreguntaPlan.mostrar_si_toca(padre, mio)
	_comprobar(dlg2 != null, "vuelve a preguntar tras quitar el plan fijo")
	dlg2.elegir("siempre")
	_comprobar(t.mentalidad == OFE and t.linea == Tactica.Nivel.ALTO and t.plan_perdiendo == "nada" and t.racha_plan_n == 0,
		"«Siempre» la hace táctica base")
	_jugar(mio, rival, 0, 1)
	_comprobar(t.mentalidad == OFE and t.racha_plan_n == 0, "y se mantiene tras otro partido")

	## 8) Partido abandonado pasado el 60: el pendiente guarda la táctica de
	## antes; al completarlo se reaplica el plan y al final se devuelve.
	t.mentalidad = EQU
	t.linea = Tactica.Nivel.MEDIO
	t.plan_perdiendo = "ofensivo"
	var p := Partido.new(mio, rival)
	p.preparar()
	p.goles_visita = 1
	p.minuto = 59
	p.simular_minuto()
	for i in 10:
		p.simular_minuto()
	PartidoPendiente.abrir(m, p)
	## «Se cierra el juego»: el guardado tenía la táctica de antes.
	t.mentalidad = EQU
	t.linea = Tactica.Nivel.MEDIO
	var antes := t.racha_plan_n
	var pend := PartidoPendiente.pendiente(m)
	_comprobar(not (pend.get("previa", {}) as Dictionary).is_empty(), "el pendiente guarda la táctica de antes")
	var pt := PartidoPendiente.resolver(m, pend)
	_comprobar(pt != null and pt.terminado_ya, "se completa el abandonado")
	_comprobar(t.mentalidad == EQU and t.linea == Tactica.Nivel.MEDIO, "tras completarlo vuelve la táctica de antes")
	_comprobar(t.racha_plan_n == antes + 1, "y la activación cuenta en la racha")
	## Pendiente viejo (sin las claves nuevas) no rompe nada.
	var viejo := {"local": mio.id, "visita": rival.id, "gl": 0, "gv": 0, "minuto": 30}
	_comprobar(PartidoPendiente.resolver(m, viejo) != null, "un pendiente viejo se sigue completando")
	padre.queue_free()
	Partido.limpiar_contexto()
