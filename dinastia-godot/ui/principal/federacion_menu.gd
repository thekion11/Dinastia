class_name FederacionMenu
extends RefCounted
## (fase 6, paso 7 del plan §7.1: sale de `Principal`, ui/principal_p4.gd, el 27-10-2026). `p` es la pantalla principal;
## sus miembros se usan como `p.x` y `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _votar(opcion: String) -> void:
	var asamblea: Array = p.mundo.liga_de(p.mundo.mi_club()).clubes
	var r := p.mundo.federacion.votar(opcion, p.mundo.mi_club(), asamblea)
	var paso := bool(r.get("pasa", false))
	var contigo := bool(r.get("ganaste", false))
	p._escribir("[color=%s]La votación %s.[/color] %s" % [
		"#4caf6d" if contigo else "#e05555",
		"sale adelante" if paso else "se rechaza",
		"Salió lo que querías." if contigo else "La asamblea votó al revés que tú."])
	if String(r.get("efecto", "")) != "":
		p._escribir("[color=#8ea595]%s[/color]" % String(r["efecto"]))
	(p as Principal)._refrescar()

# --- las cuatro pantallas que faltaban -------------------------------------
#
# Cuatro sistemas enteros estaban en el motor, probados y guardados, y no se
# podían tocar jugando. Un sistema sin pantalla no existe para quien juega, por
# muy bien que funcione por dentro.
func _pintar_federacion(c: Club) -> void:
	p._limpiar(p._lista_fed)
	var f := p.mundo.federacion
	## EL PRESIDENTE (C5): quién manda y qué empuja.
	if not f.presidente.is_empty():
		var ag: Array = Federacion.AGENDAS[String(f.presidente["agenda"])]
		var tp := p._texto(12, p.COL_ORO)
		tp.text = Idiomas.t("🏛️ Presidente: %s · corriente %s · mandato hasta %d") % [String(f.presidente["nombre"]), String(ag[0]).to_lower(), int(f.presidente["hasta"])]
		tp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_fed.add_child(tp)
		var lema := p._texto(11, p.COL_SUAVE)
		lema.text = Idiomas.t(String(ag[2])) + Idiomas.t(" Sus propuestas salen antes en la asamblea y hace campaña por ellas.")
		lema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_fed.add_child(lema)
	p._ui_club_vida._pintar_gobierno(c)
	p._ui_club_vida._pintar_licencia_y_tribunal(c, f)
	p._ui_club_vida._pintar_historial_federacion(f)
	var t := p._texto(11, p.COL_SUAVE)
	t.text = Idiomas.t("REGLAMENTO VIGENTE")
	p._lista_fed.add_child(t)
	for regla in f.reglas_vigentes(c.pais if c != null else ""):
		var l := p._texto(12, p.COL_TEXTO)
		l.text = "· " + String(regla)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_fed.add_child(l)
	## CUMPLIR O INCUMPLIR LAS REGLAS DE LA LIGA (7-10-2026): una decisión
	## del club, con su precio.
	if c != null:
		var inf: Dictionary = f.infracciones_de(p.mundo.anio)
		var est := p._texto(12, p.COL_SUAVE)
		est.text = Idiomas.t("Política con el reglamento: %s · esta temporada: %d semana(s) con el plantel fuera de cupo, %d alineación(es) indebida(s)") % [
			Idiomas.t("CUMPLIR (el once se corrige solo)") if c.ley_politica == "cumplir" else Idiomas.t("INCUMPLIR (pagas multas; a la tercera alineación indebida, 3 puntos menos cada vez)"),
			int(inf.get("plantel", 0)), int(inf.get("alin", 0))]
		est.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_fed.add_child(est)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		for op: Array in [["cumplir", "✅ Cumplir el reglamento"], ["incumplir", "⚠️ Incumplir y asumir multas"]]:
			var bt := Button.new()
			bt.text = String(op[1])
			bt.toggle_mode = true
			bt.button_pressed = c.ley_politica == String(op[0])
			var valor := String(op[0])
			bt.pressed.connect(func() -> void:
				c.ley_politica = valor
				_pintar_federacion(c))
			fila.add_child(bt)
		p._lista_fed.add_child(fila)

	if f.voto_pendiente.is_empty():
		p._lista_fed.add_child(HSeparator.new())
		var nada := p._texto(12, p.COL_SUAVE)
		nada.text = Idiomas.t("No hay ninguna votación abierta. La federación convoca cada tanto.")
		nada.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_fed.add_child(nada)
		return

	## La votación pendiente. Tu voto no decide solo: hay una asamblea, y por eso
	## se puede votar a favor y perder — que es lo que hace que votar signifique
	## algo en vez de ser un interruptor.
	p._lista_fed.add_child(HSeparator.new())
	var v: Dictionary = f.voto_pendiente
	var t2 := p._texto(11, p.COL_ORO)
	t2.text = Idiomas.t("VOTACIÓN ABIERTA")
	p._lista_fed.add_child(t2)
	var q := p._texto(13, p.COL_TEXTO)
	## La tabla VOTACIONES guarda el título en "t", no en "titulo" -esa clave
	## nunca existió-, así que esto mostraba el id interno en crudo ("tvigual")
	## en vez de "Reparto igualitario de los derechos de TV". Corregido 14-9-2026.
	q.text = String(v.get("t", v.get("id", "")))
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_fed.add_child(q)
	var d := p._texto(12, p.COL_SUAVE)
	d.text = String(v.get("texto", v.get("desc", "")))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_fed.add_child(d)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_fed.add_child(fila)
	## `Federacion.votar()` -portado tal cual del HTML- solo distingue "a" (a
	## favor) de cualquier otra cosa (en contra): mandar "si" nunca es igual a
	## "a", así que el botón "A favor" jamás sumaba tu voto explícito y el
	## mensaje de "ganaste/perdiste" salía invertido cada vez que votabas a
	## favor. Corregido 14-9-2026. "Abstenerse" no existe en el original -es
	## un tercer botón agregado en la migración- y hoy cae en la misma rama que
	## "En contra" (cuenta igual, sin el bono de "a favor"): si alguna vez se
	## quiere que abstenerse no cuente en el total, hace falta un tercer caso en
	## `votar()`, decisión de diseño que no tocamos aquí.
	p._boton("A favor", func() -> void: _votar("a"), fila)
	p._boton("En contra", func() -> void: _votar("b"), fila)
	p._boton("Abstenerse", func() -> void: _votar("abs"), fila)
