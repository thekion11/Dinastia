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

## UNA BUTACA DE LA GRADA (estadio 2.0, fase 3): en la primera bandeja de la
## tribuna lateral del lado `signo_x` (+1 la de los banquillos), a la altura
## `z`, en la fila `fila` (cada 0,8 m de fondo). Devuelve {pos, rumbo} con el
## rumbo mirando al campo.
static func butaca(est: Dictionary, signo_x: float, z: float, fila: int = 3) -> Dictionary:
	var g := StadiumBuilder.geom_de_forma(String(est.get("forma", "cuenco")))
	var dx: float = g["dx"]
	var dz: float = g["dz"]
	var d := 0.6 + float(fila) * 0.8
	var ang := deg_to_rad(StadiumBuilder.RAKE_GRADOS)
	var x := signo_x * (dx - StadiumBuilder.FRENTE_TRIBUNA + d)
	var y := StadiumBuilder.ALTURA_PIE + d * tan(ang) + 0.2
	var zz := clampf(z, -(dz - 12.0), dz - 12.0)
	return {"pos": Vector3(x, y, zz), "rumbo": -signo_x * PI / 2.0}

## ¿Se puede uno sentar desde aquí? Junto a una banda de la cancha.
static func junto_a_la_grada(p: Vector3, planta: int) -> bool:
	return planta == 0 and absf(p.x) > 33.0 and absf(p.z) < 50.0

## Al sentarse: los hinchas que ocupan tu butaca y las de al lado se quitan
## (escala 0 en su `MultiMesh`). Devuelve lo quitado para devolverlo después.
static func despejar_hinchas(raiz: Node, centro_global: Vector3, radio := 1.3) -> Array:
	var quitados: Array = []
	for n in raiz.find_children("Hinchada*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if mmi.multimesh == null or not mmi.is_inside_tree():
			continue
		var t := mmi.global_transform
		var mm := mmi.multimesh
		for i in mm.instance_count:
			var xf := mm.get_instance_transform(i)
			var p := t * xf.origin
			if p.distance_to(centro_global) < radio:
				quitados.append([mmi, i, xf])
				mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), xf.origin))
	return quitados

static func devolver_hinchas(quitados: Array) -> void:
	for q: Array in quitados:
		var mmi: MultiMeshInstance3D = q[0]
		if is_instance_valid(mmi) and mmi.multimesh != null:
			mmi.multimesh.set_instance_transform(int(q[1]), q[2])
