class_name FichaPorque
extends RefCounted
## «¿POR QUÉ SUBE O BAJA?» EN LA FICHA (26-10-2026, fila 16 de la propuesta de
## la s4: «Hattrick: reglas legibles que se recuerdan 20 años»). Un bloque
## plegable sobre el crecimiento por temporada que cuenta, con las reglas DE
## VERDAD del núcleo y los números de ESTE jugador, por qué su media se mueve:
##  · la curva de edad (`ProgresoJugador`): crece sobre todo de 17 a 20, más
##    despacio hasta los 23, se queda quieto de 24 a 29 y baja desde los 30;
##  · el techo que se gasta de los 19 a los 26 si no lo alcanza;
##  · los partidos que le faltan para los puntos de habilidad del cierre de
##    temporada (`Entrenamiento.repartir_puntos`: 12 partidos, y 8 más joven).
## Si cambian esas reglas, se cambian aquí los mismos números: la prueba
## `pruebas/ideas/s6_porque.gd` los compara con el núcleo.
##   FichaPorque.pintar(lista, jugador, paleta)   (lo llama `FichaJugadorInfo.pintar_historial`)

## Los umbrales de `Entrenamiento.repartir_puntos()`.
const PJ_PUNTO := 12
const PJ_JOVEN := 8
const EDAD_JOVEN := 21

## Plegado o abierto: se recuerda mientras dure la sesión (cambiar de jugador
## repinta la ficha entera).
static var abierto := false

## La fase de la curva de edad en una frase, con la regla que la gobierna.
static func fase_edad(edad: int) -> String:
	if edad <= 20:
		return Idiomas.t("Edad de crecer: es cuando más sube (hasta +2 cada cumpleaños y subidas en el entrenamiento semanal).")
	if edad <= 22:
		return Idiomas.t("Aún crece, pero más despacio que con 20 o menos.")
	if edad == 23:
		return Idiomas.t("Último año en que crece entrenando; desde los 24 su media se queda quieta.")
	if edad <= 29:
		return Idiomas.t("Plenitud: ni sube ni baja por la edad. Lo que cambia es la forma, la moral y el estado físico.")
	if edad == 30:
		return Idiomas.t("A los 30 empieza la cuesta abajo: la mitad de los años pierde 1 punto.")
	return Idiomas.t("Veterano: pierde de 0 a 3 puntos cada año y, alguna semana, 1 más (primero las piernas).")

## Cuánto puede crecer por la edad, de 0 a 1 (la forma de la curva dibujada):
## el mismo freno por edad que `ProgresoJugador.freno()` y la caída de los 30.
static func ritmo_por_edad(edad: int) -> float:
	if edad <= 20:
		return 0.8
	if edad <= 22:
		return 0.5
	if edad == 23:
		return 0.3
	if edad <= 29:
		return 0.0
	return -clampf(float(edad - 29) * 0.25, 0.0, 1.0)

## Partidos de liga y copa que le faltan para cada punto de habilidad del
## cierre de temporada. {"punto": n, "joven": n o -1 si ya no aplica}.
static func faltan(j: Jugador) -> Dictionary:
	return {
		"punto": maxi(0, PJ_PUNTO - j.partidos),
		"joven": maxi(0, PJ_JOVEN - j.partidos) if j.edad <= EDAD_JOVEN else -1,
	}

static func pintar(lista: VBoxContainer, j: Jugador, paleta: Dictionary) -> void:
	var b := Button.new()
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = ("▾ " if abierto else "▸ ") + Idiomas.t("¿POR QUÉ SUBE O BAJA?")
	b.add_theme_font_size_override("font_size", maxi(8, int(round(11.0 * float(paleta.get("escala", 1.0))))))
	b.add_theme_color_override("font_color", paleta["acento"])
	b.tooltip_text = Idiomas.t("La edad, el techo y los minutos: las reglas que mueven su media.")
	lista.add_child(b)
	var caja := VBoxContainer.new()
	caja.visible = abierto
	caja.add_theme_constant_override("separation", 3)
	lista.add_child(caja)
	b.pressed.connect(func() -> void:
		abierto = not abierto
		caja.visible = abierto
		b.text = ("▾ " if abierto else "▸ ") + Idiomas.t("¿POR QUÉ SUBE O BAJA?"))
	var curva := CurvaEdad.new()
	curva.edad = j.edad
	curva.color = paleta["acento"]
	curva.color_suave = paleta["suave"]
	caja.add_child(curva)
	_frase(caja, Idiomas.t("%d años.") % j.edad + " " + fase_edad(j.edad), paleta["texto"], paleta)
	## El techo.
	if j.ovr < j.pot:
		var techo := Idiomas.t("Le quedan %d puntos hasta su techo (%d).") % [j.pot - j.ovr, j.pot]
		if j.edad >= 19 and j.edad <= 26:
			techo += " " + Idiomas.t("Ojo: de los 19 a los 26, cada año que no lo alcanza el techo baja de 0 a 2 puntos.")
		_frase(caja, techo, paleta["suave"], paleta)
	else:
		_frase(caja, Idiomas.t("Ya está en su techo (%d): solo puede mantenerse.") % j.pot, paleta["suave"], paleta)
	## Los minutos.
	var f := faltan(j)
	var pj := Idiomas.t("Lleva %d partidos esta temporada.") % j.partidos
	if int(f["punto"]) > 0:
		pj += " " + Idiomas.t("Con %d más gana 1 punto de habilidad al cerrar la temporada.") % int(f["punto"])
	else:
		pj += " " + Idiomas.t("Ya tiene asegurado 1 punto de habilidad al cerrar la temporada.")
	if int(f["joven"]) > 0:
		pj += " " + Idiomas.t("Por ser joven, con %d más gana otro.") % int(f["joven"])
	elif int(f["joven"]) == 0:
		pj += " " + Idiomas.t("Por ser joven, ya tiene asegurado otro.")
	_frase(caja, pj, paleta["verde"] if int(f["punto"]) == 0 else paleta["texto"], paleta)
	_frase(caja, Idiomas.t("El plan de entrenamiento, el desarrollo prioritario, el rasgo «motor» y el centro de entrenamiento aceleran las subidas semanales; ninguno pasa del techo."), paleta["suave"], paleta)

static func _frase(padre: Node, t: String, color: Color, paleta: Dictionary) -> void:
	var l := FichaJugadorInfo._texto(11, color, paleta)
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	padre.add_child(l)

## La curva de 16 a 36 años: por encima de la raya crece, por debajo baja; el
## punto es la edad del jugador. La curva es una línea suave (`TrazoSuave`).
class CurvaEdad:
	extends Control
	const DESDE := 16
	const HASTA := 36
	var edad := 20
	var color := Color(0.4, 0.8, 1.0)
	var color_suave := Color(0.6, 0.65, 0.7)

	func _init() -> void:
		custom_minimum_size = Vector2(220, 74)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _punto(e: float) -> Vector2:
		var x := 6.0 + (size.x - 12.0) * (e - float(DESDE)) / float(HASTA - DESDE)
		var y := size.y * 0.42 - FichaPorque.ritmo_por_edad(int(round(e))) * size.y * 0.36
		return Vector2(x, y)

	func _notification(que: int) -> void:
		if que == NOTIFICATION_RESIZED:
			TrazoSuave.limpiar(self)
			if size.x < 40.0:
				return
			var pts := PackedVector2Array()
			for e in range(DESDE, HASTA + 1):
				pts.append(_punto(float(e)))
			TrazoSuave.linea(self, PackedVector2Array([Vector2(6, size.y * 0.42), Vector2(size.x - 6, size.y * 0.42)]),
				Color(color_suave, 0.35), 1.0, false, true)
			TrazoSuave.linea(self, pts, color, 2.0, false, true)

	## Relleno entre la curva y el eje: verde donde sube, rojo donde baja. Va por
	## tramos de un año (un trapecio o un triángulo), que siempre son convexos.
	func _relleno() -> void:
		var eje := size.y * 0.42
		for e in range(DESDE, HASTA):
			var a := _punto(float(e))
			var b := _punto(float(e + 1))
			var arriba := minf(a.y, b.y) < eje - 0.5
			var abajo := maxf(a.y, b.y) > eje + 0.5
			if not arriba and not abajo:
				continue
			var pts := PackedVector2Array()
			for q: Vector2 in [Vector2(a.x, eje), a, b, Vector2(b.x, eje)]:
				if pts.is_empty() or not pts[pts.size() - 1].is_equal_approx(q):
					pts.append(q)
			if pts.size() >= 3:
				draw_colored_polygon(pts, Color(0.3, 0.85, 0.45, 0.22) if arriba else Color(0.95, 0.35, 0.3, 0.22))

	func _draw() -> void:
		_relleno()
		var f := get_theme_default_font()
		## La leyenda arriba a la derecha, donde la curva ya va por debajo del eje.
		var sube := Idiomas.t("▲ sube")
		var baja := Idiomas.t("▼ baja")
		var w_baja := f.get_string_size(baja, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var w_sube := f.get_string_size(sube, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(f, Vector2(size.x - 6.0 - w_baja, 10.0), baja, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.5, 0.45))
		draw_string(f, Vector2(size.x - 14.0 - w_baja - w_sube, 10.0), sube, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 0.9, 0.5))
		for e: int in [17, 20, 23, 26, 30, 34]:
			var p := _punto(float(e))
			draw_string(f, Vector2(p.x - 6.0, size.y - 2.0), str(e), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color_suave)
		var aqui := _punto(float(clampi(edad, DESDE, HASTA)))
		draw_circle(aqui, 5.0, Color(0, 0, 0, 0.6), true, -1.0, true)
		draw_circle(aqui, 3.6, color, true, -1.0, true)
