extends RefCounted
## (Parte 1 de 2 de `recorrido_club.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `recorrido_club.gd`, conserva la clase.)

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
	"portero": "Aquí estoy, míster. Nadie entra sin que yo lo vea.",
}

const PREGUNTA_OFICIO := {
	"medico": "¿Cómo está la enfermería?",
	"cocinera": "¿Cómo ves al grupo?",
	"jardinero": "¿Cómo está el césped?",
	"secretaria": "¿Cómo va la caja?",
	"utilero": "¿Quién está más fino esta semana?",
	"ojeador": "¿Algún chico de la cantera que valga?",
}

## ¿La última respuesta fue mala noticia? (para la cara de quien la dice)
static var _ultima_mala := false

## Lo que cuenta el portero si le preguntas (gente ficticia del club).
const NOVEDADES_PORTERO := [
	"Esta mañana vino un periodista preguntando por usted. Le dije que no estaba.",
	"El jefe de cancha lleva dos horas regando la misma esquina. Algo le pasa con esa esquina.",
	"Han llegado las camisetas nuevas; el utilero no deja ni mirarlas.",
	"Anoche se quedó encendida la luz de la sala de vídeo. Ya la apagué yo.",
	"Un chico del barrio dejó una carta para el capitán. La tengo guardada aquí.",
	"El de la puerta 7 ya está ahí fuera. Dice que hoy no se mueve hasta el domingo.",
	"El bus salió a lavar y volvió más sucio. No pregunte.",
]
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
	panel.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
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

## Lo que contesta, sacado de la partida.
static func respuesta_oficio(clave: String, m: Mundo) -> String:
	_ultima_mala = false
	var c := m.mi_club()
	if c == null:
		return Idiomas.t("Hoy no sé qué decirle, míster.")
	match clave:
		"medico":
			var fuera: Array = []
			for j: Jugador in c.plantilla:
				if j.lesion > 0:
					fuera.append("%s (%d sem.)" % [Nombres.visible(j.nombre), j.lesion])
			if fuera.is_empty():
				return Idiomas.t("Enfermería vacía, míster. Que siga así.")
			_ultima_mala = true
			return Idiomas.t("Tengo a %s. Paciencia con ellos.") % ", ".join(fuera.slice(0, 3))
		"cocinera":
			var suma := 0
			for j: Jugador in c.plantilla:
				suma += j.moral
			var media := suma / maxi(1, c.plantilla.size())
			if media >= 75:
				return Idiomas.t("Comen con hambre y se ríen en la mesa. El grupo está bien.")
			if media >= 55:
				return Idiomas.t("Normal, míster. Algunos callados, nada raro.")
			_ultima_mala = true
			return Idiomas.t("Están apagados. Ni el postre les levanta el ánimo.")
		"jardinero":
			var cesped := m.ciudad.cesped if m.ciudad != null else 100
			if cesped >= 85:
				return Idiomas.t("Como una alfombra. Que no me lo pisen en los rondos.")
			if cesped >= 60:
				return Idiomas.t("Aguanta, pero hay calvas en las áreas. Riego cada noche.")
			_ultima_mala = true
			return Idiomas.t("Sufre, míster. Necesita descanso o una inversión.")
		"secretaria":
			var sem := int(c.saldo / maxi(1, c.masa_salarial())) if c.saldo > 0 else 0
			_ultima_mala = sem < 8
			return Idiomas.t("En caja hay para %d semanas de sueldos. El presidente pregunta a menudo.") % sem
		"utilero":
			var mejor: Jugador = null
			for j: Jugador in c.plantilla:
				if j.lesion == 0 and (mejor == null or j.forma > mejor.forma):
					mejor = j
			if mejor == null:
				return Idiomas.t("Todos regulares, míster.")
			return Idiomas.t("%s. Llega el primero y se va el último.") % Nombres.visible(mejor.nombre)
		"ojeador":
			var joven: Jugador = null
			for j: Jugador in c.plantilla:
				if j.edad <= 20 and (joven == null or j.pot > joven.pot):
					joven = j
			if joven == null:
				return Idiomas.t("En el primer equipo no hay chicos. Mire la academia.")
			return Idiomas.t("%s, %d años. Tiene techo de %d. No lo queme.") % [Nombres.visible(joven.nombre), joven.edad, joven.pot]
	return Idiomas.t("Hoy no sé qué decirle, míster.")

## La conversación en persona con alguien del club. `g` es de
## `PersonalEstadio.gente`. Usa la partida si está a mano (`Gente.charlar`,
## la directiva y la junta); si no, solo saluda.
static func dialogo(capa: CanvasLayer, personal: PersonalEstadio, g: Dictionary, desde: Vector3) -> PanelContainer:
	personal.atender(g, desde, true)
	if g.has("nodo") and is_instance_valid(g["nodo"]):
		Expresion.de(g["nodo"]).poner("alegre", 2.5)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -330
	panel.offset_right = 330
	panel.offset_top = -270
	panel.offset_bottom = -110
	panel.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	panel.add_child(caja)
	caja.add_child(CuadroDialogo.placa("%s · %s" % [String(g["nombre"]), Idiomas.t(String(g["puesto"]))]))
	var dice := Label.new()
	dice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dice.custom_minimum_size = Vector2(610, 0)
	dice.add_theme_font_size_override("font_size", 19)
	caja.add_child(dice)
	CuadroDialogo.escribir(dice, "«%s»" % Idiomas.t(String(SALUDOS.get(String(g["clave"]), "Buenas, míster."))))
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
	## UNA PREGUNTA DE SU OFICIO (13-10-2026): cada uno sabe algo del club que
	## le sirve al míster, con datos de verdad de la partida.
	var pregunta := PREGUNTA_OFICIO.get(clave, "") as String
	if pregunta != "" and m != null:
		var bq := Button.new()
		bq.text = "❓ " + Idiomas.t(pregunta)
		bq.pressed.connect(func() -> void:
			var r := respuesta_oficio(clave, m)
			CuadroDialogo.escribir(dice, "«%s»" % r)
			## La cara acompaña lo que dice (13-10-2026).
			if g.has("nodo") and is_instance_valid(g["nodo"]):
				var malo := _ultima_mala
				Expresion.de(g["nodo"]).poner("triste" if malo else "alegre", 4.0)
			bq.disabled = true)
		fila.add_child(bq)
	var adios := Button.new()
	adios.text = Idiomas.t("Adiós")
	adios.pressed.connect(cerrar)
	fila.add_child(adios)
	for b in fila.get_children():
		CuadroDialogo.respuesta(b as Button)
	capa.add_child(panel)
	return panel

## EL PORTERO (8-10-2026): saluda según la hora, sabe si estás sancionado, te
## cuenta lo que ha visto y, si se lo pides, abre la puerta (gesto + puertas
## correderas) y te deja pasar: `al_pasar` se llama cuando ya está abierta.
static func dialogo_portero(capa: CanvasLayer, personal: PersonalEstadio, g: Dictionary, desde: Vector3,
		al_pasar: Callable) -> PanelContainer:
	personal.atender(g, desde, true)
	if g.has("nodo") and is_instance_valid(g["nodo"]):
		Expresion.de(g["nodo"]).poner("sorpresa" if PersonajeDT.sancionado else "alegre", 2.5)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -330
	panel.offset_right = 330
	panel.offset_top = -270
	panel.offset_bottom = -110
	panel.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	panel.add_child(caja)
	caja.add_child(CuadroDialogo.placa("%s · %s" % [String(g["nombre"]), Idiomas.t(String(g["puesto"]))]))
	var dice := Label.new()
	dice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dice.custom_minimum_size = Vector2(610, 0)
	dice.add_theme_font_size_override("font_size", 19)
	var h := PersonalEstadio.hora
	var saludo := "Buenas, míster."
	if h >= 0.0:
		saludo = "Buenos días, míster." if h < 13.0 else ("Buenas tardes, míster." if h < 20.5 else "Buenas noches, míster. Aquí sigo de guardia.")
	var txt := Idiomas.t(saludo)
	if PersonajeDT.sancionado:
		txt += " " + Idiomas.t("Ya me enteré de la sanción… Al club puede pasar; al banquillo, el domingo no.")
	txt += " " + Idiomas.t("¿Le abro?")
	caja.add_child(dice)
	CuadroDialogo.escribir(dice, "«%s»" % txt)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	var cerrar := func() -> void:
		personal.atender(g, desde, false)
		panel.queue_free()
	var ba := Button.new()
	ba.text = "🚪 " + Idiomas.t("Sí, ábrame, por favor")
	ba.pressed.connect(func() -> void:
		ba.disabled = true
		personal.gesto(g, ["saludo_mano", "saludar_publico", "senalar"])
		EntradaClub.abrir(capa.get_tree(), true)
		dice.text = "«%s»" % Idiomas.t("Adelante, míster. Que tenga buena jornada.")
		var arbol := capa.get_tree()
		arbol.create_timer(EntradaClub.SEG_ABRIR + 0.2).timeout.connect(func() -> void:
			personal.atender(g, desde, false)
			if is_instance_valid(panel):
				panel.queue_free()
			al_pasar.call()))
	fila.add_child(ba)
	var bn := Button.new()
	bn.text = "💬 " + Idiomas.t("¿Alguna novedad?")
	var vez := [absi(String(g["nombre"]).hash())]
	bn.pressed.connect(func() -> void:
		vez[0] = int(vez[0]) + 1
		dice.text = "«%s»" % Idiomas.t(String(NOVEDADES_PORTERO[int(vez[0]) % NOVEDADES_PORTERO.size()])))
	fila.add_child(bn)
	var adios := Button.new()
	adios.text = Idiomas.t("Adiós")
	adios.pressed.connect(cerrar)
	fila.add_child(adios)
	for b in fila.get_children():
		CuadroDialogo.respuesta(b as Button)
	capa.add_child(panel)
	ba.grab_focus()
	return panel

## En coordenadas de `raiz` (el estadio puede estar desplazado en la ciudad).
static func _butaca_real(raiz: Node, cerca_de_local: Vector3, signo_x: float) -> Vector3:
	var r3 := raiz as Node3D
	if r3 == null or not r3.is_inside_tree():
		return Vector3.INF
	var cerca_de := r3.to_global(cerca_de_local)
	var mejor := Vector3.INF
	var dist := 25.0
	for n in raiz.find_children("ButacasCerca", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if mmi.multimesh == null or not mmi.is_inside_tree() or signf(r3.to_local(mmi.global_position).x) != signf(signo_x):
			continue
		var t := mmi.global_transform
		for i in mmi.multimesh.instance_count:
			var xf := mmi.multimesh.get_instance_transform(i)
			## Las columnas de pasillo tienen escala cero: no son butacas.
			if xf.basis.get_scale().x < 0.01:
				continue
			var p := t * xf.origin
			var d := p.distance_to(cerca_de)
			if d < dist:
				dist = d
				mejor = p
	return r3.to_local(mejor) + Vector3(0, 0.25, 0) if mejor != Vector3.INF else mejor

## UNA BUTACA DE LA GRADA (estadio 2.0, fase 3): en la primera bandeja de la
## tribuna lateral del lado `signo_x` (+1 la de los banquillos), a la altura
## `z`, en la fila `fila` (cada 0,8 m de fondo). Devuelve {pos, rumbo} con el
## rumbo mirando al campo.
static func butaca(est: Dictionary, signo_x: float, z: float, fila: int = 3, raiz: Node = null) -> Dictionary:
	var g := StadiumBuilder.geom_de_forma(String(est.get("forma", "cuenco")))
	var dx: float = g["dx"]
	var dz: float = g["dz"]
	var d := 0.6 + float(fila) * 0.8
	var ang := deg_to_rad(StadiumBuilder.RAKE_GRADOS)
	var x := signo_x * (dx - StadiumBuilder.FRENTE_TRIBUNA + d)
	var y := StadiumBuilder.ALTURA_PIE + d * tan(ang) + 0.2
	var zz := clampf(z, -(dz - 12.0), dz - 12.0)
	var aprox := Vector3(x, y, zz)
	## 21-10-2026: con el estadio en la escena, la butaca DE VERDAD más cercana
	## (las cuentas de arriba no seguían el paso de fila real ni las tribunas
	## con otra pendiente, y uno se sentaba en el aire o dentro del escalón).
	if raiz != null:
		var real := _butaca_real(raiz, aprox, signo_x)
		if real != Vector3.INF:
			return {"pos": real, "rumbo": -signo_x * PI / 2.0}
	return {"pos": aprox, "rumbo": -signo_x * PI / 2.0}

## EL CAMINO HASTA LA BUTACA (21-10-2026): por la escalera del pasillo más
## cercano. Devuelve los puntos (en coordenadas de `raiz`): pie de la escalera,
## peldaño de la fila de la butaca y la butaca. Vacío si no hay pasillos.
static func camino_a_butaca(raiz: Node, butaca_local: Vector3) -> Array[Vector3]:
	var r3 := raiz as Node3D
	var camino: Array[Vector3] = []
	if r3 == null or not r3.is_inside_tree():
		return camino
	var asiento := r3.to_global(butaca_local)
	var mejor_fila := Vector3.INF
	var dist := 12.0
	var pasillo: MultiMeshInstance3D = null
	## El peldaño a la altura de la butaca y más cerca de ella.
	for n in raiz.find_children("Pasillos", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if mmi.multimesh == null or not mmi.is_inside_tree():
			continue
		for i in mmi.multimesh.instance_count:
			var p := mmi.global_transform * mmi.multimesh.get_instance_transform(i).origin
			if absf(p.y - asiento.y) < 0.6 and p.distance_to(asiento) < dist:
				dist = p.distance_to(asiento)
				mejor_fila = p
				pasillo = mmi
	if pasillo == null:
		return camino
	## El pie de esa misma escalera: el peldaño más bajo de la columna (en las
	## laterales, donde uno se sienta, la columna es la misma z).
	var pie := mejor_fila
	for i in pasillo.multimesh.instance_count:
		var p := pasillo.global_transform * pasillo.multimesh.get_instance_transform(i).origin
		if absf(p.z - mejor_fila.z) < 0.6 and p.y < pie.y:
			pie = p
	## La escalera de acceso: desde el suelo, hacia el campo, sube peldaño a
	## peldaño hasta el pie del pasillo (`StadiumBuilder._escaleras_de_acceso`).
	var hacia_campo := Vector3(-signf(pie.x), 0, 0)
	var n := int(ceil((pie.y - 0.05) / StadiumBuilder.PELDANO_ALTO))
	var suelo := r3.to_local(pie + hacia_campo * (0.45 + float(n) * StadiumBuilder.PELDANO_FONDO + 0.4))
	suelo.y = 0.0
	camino.append(suelo)
	camino.append(r3.to_local(pie + hacia_campo * 0.45) + Vector3(0, 0.25, 0))
	camino.append(r3.to_local(pie) + Vector3(0, 0.25, 0))
	camino.append(r3.to_local(mejor_fila) + Vector3(0, 0.25, 0))
	camino.append(butaca_local)
	return camino

## ¿Se puede uno sentar desde aquí? Junto a una banda de la cancha.
static func junto_a_la_grada(p: Vector3, planta: int) -> bool:
	return planta == 0 and absf(p.x) > 33.0 and absf(p.z) < 50.0

## Al sentarse: los hinchas que ocupan tu butaca y las de al lado se quitan
## (escala 0 en su `MultiMesh`). Devuelve lo quitado para devolverlo después.
static func despejar_hinchas(raiz: Node, centro_global: Vector3, radio := 1.3) -> Array:
	var quitados: Array = []
	## «Personas*»: el público de personas reales (desde el 14-10); antes solo
	## se buscaban los maniquíes y uno se sentaba encima de alguien.
	for n in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		if not (String(n.name).begins_with("Hinchada") or String(n.name).begins_with("Personas")):
			continue
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
