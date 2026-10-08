class_name RecorridoClub
extends RefCounted
## Lo común a recorrer el estadio a pie, desde la ciudad (`ExploradorCiudad`)
## o desde la vista del estadio (`ExploradorEstadio`): el texto de cada zona y
## el panel del ascensor del edificio del club (estadio interactivo 2.0).

## El aviso de abajo al entrar en una zona.
static func aviso_de(nombre: String, club: String = "") -> String:
	match nombre:
		"Vestuario":
			return Idiomas.t("El vestuario. Por el túnel se sale al campo.")
		"Túnel":
			return Idiomas.t("El túnel. Al fondo se oye la grada.")
		"Banda":
			return Idiomas.t("¡A la cancha!")
		"Acceso":
			return Idiomas.t("E: salir a la calle")
		"Ascensor":
			return Idiomas.t("E: llamar al ascensor")
		"Pasillo", "Campo", "":
			return ""
	return Idiomas.t(nombre)

## La altura del suelo de una planta.
static func y_de(planta: int) -> float:
	return float(planta) * EdificioClub.ALTO_PLANTA + 0.02

## El panel del ascensor: un botón por planta. `al_elegir(planta)`.
static func menu_ascensor(capa: CanvasLayer, actual: int, al_elegir: Callable) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -190
	panel.offset_right = 190
	panel.offset_top = -170
	panel.offset_bottom = 170
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	panel.add_child(caja)
	var t := Label.new()
	t.text = "🛗 " + Idiomas.t("Ascensor")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 20)
	caja.add_child(t)
	var plantas := EdificioClub.plantas()
	plantas.reverse()
	for p: int in plantas:
		var b := Button.new()
		b.text = "%s %d · %s" % ["▶" if p == actual else "  ", p, Idiomas.t(EdificioClub.nombre_planta(p))]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = p == actual
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(func() -> void:
			panel.queue_free()
			al_elegir.call(p))
		caja.add_child(b)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("Cerrar")
	cerrar.pressed.connect(func() -> void: panel.queue_free())
	caja.add_child(cerrar)
	capa.add_child(panel)
	return panel

## Cómo te recibe cada uno (lo primero que dice al acercarte).
const SALUDOS := {
	"conserje": "Buenas, míster. Hoy entra usted temprano, ¿eh? Yo abro a las siete.",
	"jardinero": "Cuidado con pisar el área chica, que la acabo de resembrar.",
	"hincha": "¡Míster! Treinta años en esta puerta. Ganemos el domingo, por favor.",
	"utilero": "Las camisetas ya están lavadas y colgadas. Cada uno en su sitio.",
	"medico": "Pase, pase. Le cuento cómo están los tocados.",
	"chofer": "El bus está listo cuando usted diga. Yo no escucho nada… casi nada.",
	"secretaria": "Tiene tres llamadas del presidente y un contrato para firmar.",
	"ojeador": "Estoy viendo a un chico del barrio. Tiene algo, se lo digo yo.",
	"presidente": "Siéntese. Hablemos de cómo va esto.",
	"prensa": "La sala está lista. Intente no encender ningún fuego hoy.",
	"cocinera": "Hoy hay legumbres. Y nadie se levanta sin terminar el plato.",
}

## La conversación en persona con alguien del club. `g` es de
## `PersonalEstadio.gente`. Usa la partida si está a mano (`Gente.charlar`,
## la directiva y la junta); si no, solo saluda.
static func dialogo(capa: CanvasLayer, personal: PersonalEstadio, g: Dictionary, desde: Vector3) -> PanelContainer:
	personal.atender(g, desde, true)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -330
	panel.offset_right = 330
	panel.offset_top = -270
	panel.offset_bottom = -110
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	panel.add_child(caja)
	var t := Label.new()
	t.text = "%s · %s" % [String(g["nombre"]), Idiomas.t(String(g["puesto"]))]
	t.add_theme_font_size_override("font_size", 19)
	t.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	caja.add_child(t)
	var dice := Label.new()
	dice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dice.custom_minimum_size = Vector2(620, 0)
	dice.text = "«%s»" % Idiomas.t(String(SALUDOS.get(String(g["clave"]), "Buenas, míster.")))
	caja.add_child(dice)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	var m: Mundo = EdificioClub.mundo_ref.get_ref() as Mundo if EdificioClub.mundo_ref != null else null
	var clave := String(g["clave"])
	var cerrar := func() -> void:
		personal.atender(g, desde, false)
		panel.queue_free()
	if clave == "presidente":
		var bp := Button.new()
		bp.text = "🏛️ " + Idiomas.t("¿Cómo nos ve la directiva?")
		bp.pressed.connect(func() -> void:
			if m != null and m.directiva != null:
				var txt := "%s (%d/100)." % [Idiomas.t(m.directiva.humor()), m.directiva.confianza]
				if m.junta != null and not m.junta.pendiente.is_empty():
					txt += " " + Idiomas.t("Y hay una junta pendiente: %s") % String(m.junta.pendiente.get("tema", ""))
				dice.text = "«%s»" % txt
			else:
				dice.text = "«%s»" % Idiomas.t("Estamos con usted. Por ahora."))
		fila.add_child(bp)
	elif clave in Gente.ROLES.map(func(f: Array) -> String: return String(f[0])):
		var bc := Button.new()
		bc.text = "💬 " + Idiomas.t("Charlar un rato")
		bc.pressed.connect(func() -> void:
			if m != null and m.gente != null:
				var r := m.gente.charlar(clave)
				dice.text = "«%s»" % Idiomas.t(r if r != "" else "…")
				bc.disabled = true
			else:
				dice.text = "«%s»" % Idiomas.t("Charla corta. Te escucha, asiente y sigue con lo suyo."))
		fila.add_child(bc)
	var adios := Button.new()
	adios.text = Idiomas.t("Adiós")
	adios.pressed.connect(cerrar)
	fila.add_child(adios)
	capa.add_child(panel)
	return panel
