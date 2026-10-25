class_name PanelReputacion
extends RefCounted
## LA REPUTACIÓN, EN MI CARRERA (26-9-2026). El nivel del club con lo que abre
## y lo que falta para el siguiente; tu fama por facetas, cada una con lo que
## hace en el juego; y las últimas decisiones que la movieron.

static func pintar(lista: VBoxContainer, m: Mundo) -> void:
	if m == null or m.roles == null or m.mi_club() == null:
		return
	var r := m.roles.reputacion
	var c := m.mi_club()
	lista.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, Idiomas.t("⭐ REPUTACIÓN")))

	## El club.
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.ORO))
	lista.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	caja.add_child(v)
	var n := Reputacion.nivel_de(c.rep)
	v.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, Idiomas.t("%s  ·  nivel del club (reputación %d)") % [Idiomas.t(Reputacion.nombre_nivel(c.rep)), c.rep]))
	var barra := ProgressBar.new()
	barra.min_value = 0.0
	barra.max_value = 1.0
	barra.value = Reputacion.progreso(c.rep)
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 10)
	v.add_child(barra)
	for b: String in Reputacion.beneficios(n):
		v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "✔ " + Idiomas.t(b)))
	if n < Reputacion.NIVELES.size() - 1:
		var sig: Array = Reputacion.NIVELES[n + 1]
		var sig_ben: Array[String] = []
		for b2: String in Reputacion.beneficios(n + 1):
			sig_ben.append(Idiomas.t(b2).to_lower())
		var t := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, Idiomas.t("Siguiente: %s %s con reputación %d → %s") % [String(sig[2]), Idiomas.t(String(sig[1])), int(sig[0]), ", ".join(sig_ben)])
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t)

	## Tu fama.
	var tit := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "🗣️ " + Idiomas.t(r.titular()))
	tit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(tit)
	for f: String in Reputacion.FACETAS:
		var fila_f: Array = Reputacion.FACETAS[f]
		var val := r.valor(f)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		lista.add_child(fila)
		var nom := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "%s %s" % [String(fila_f[1]), Idiomas.t(String(fila_f[0]))])
		## Ancho fijo para que las barras empiecen todas en la misma x, y con
		## «…» si una faceta traducida no cabe.
		nom.custom_minimum_size = Vector2(130, 0)
		nom.clip_text = true
		nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		fila.add_child(nom)
		var pb := ProgressBar.new()
		pb.max_value = 100
		pb.value = val
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(120, 12)
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sb := StyleBoxFlat.new()
		sb.bg_color = Tema.BIEN if val >= 60 else (Color("c0392b") if val <= 40 else Tema.ORO)
		sb.set_corner_radius_all(4)
		pb.add_theme_stylebox_override("fill", sb)
		fila.add_child(pb)
		var efecto := Idiomas.t(String(fila_f[2])) if val >= 55 else (Idiomas.t("Neutral") if val > 45 else _en_contra(String(fila_f[2])))
		var ef := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "%d · %s" % [val, efecto])
		ef.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ef.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(ef)

	## Lo que la movió.
	if not r.historial.is_empty():
		lista.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, Idiomas.t("LO QUE HA HECHO TU FAMA")))
		for i in mini(8, r.historial.size()):
			var h: Dictionary = r.historial[i]
			var d := int(h.get("delta", 0))
			var f2 := String(h.get("faceta", ""))
			var nombre_f := String(Reputacion.FACETAS.get(f2, ["?"])[0])
			var l := Tema.etiqueta(Tema.TAM_ROTULO, Tema.BIEN if d > 0 else Color("e57373"),
				"%+d %s · %s%s" % [d, Idiomas.t(nombre_f), Idiomas.t(String(h.get("motivo", ""))), (" (%d)" % int(h["anio"])) if int(h.get("anio", 0)) > 0 else ""])
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lista.add_child(l)

## Una faceta baja: el mismo efecto, pero en contra. En castellano se da la
## vuelta a la frase («te pagan más» → «te pagan menos»), como siempre; en los
## demás idiomas esa vuelta no existe en el diccionario, así que se dice «en
## contra» delante del efecto traducido en vez de dejarlo a medio traducir.
static func _en_contra(efecto: String) -> String:
	if Idiomas.idioma == "es":
		return "Juega en contra: " + efecto.to_lower().replace("más", "menos")
	return Idiomas.t("Juega en contra: %s") % Idiomas.t(efecto).to_lower()
