class_name EventosClub
extends RefCounted
## EVENTOS DEL CLUB CON DIÁLOGO (10-11, orden del dueño: sumar escenas al estilo de las de una «liga máster» de un juego de fútbol que él
## considera muy buenas en lo visual, CON NOMBRES Y TEXTOS PROPIOS). Se conservan nuestros eventos y conversaciones y se suman estos:
##   - «directiva»: la reunión de inicio de temporada con la directiva y su objetivo (semanas 1-2);
##   - «clasico»: la charla en el vestuario la semana de un clásico (si el próximo rival lo es);
##   - «mitad»: el balance de mitad de liga con tu ayudante (la jornada de la mitad).
## Cada evento sale UNA vez (clave por año y semana en `Prensa.eventos_vistos`, que se guarda) y SOLO al llegar su fecha.
## La escena (`EventoDialogo`) la abre `JornadaEventos`; aquí solo QUÉ toca y QUÉ mueve cada respuesta (moral del plantel y confianza de la directiva).

## El evento que toca hoy o {} si no hay. Claves: id, clave, lugar, quien, cargo, texto, opciones[{txt, moral, confianza}].
static func pendiente(m: Mundo) -> Dictionary:
	if m == null or m.prensa == null or m.mi_club() == null or not m.temporada_en_curso():
		return {}
	for f: Callable in [_directiva, _clasico, _mitad]:
		var ev: Dictionary = f.call(m)
		if not ev.is_empty() and not visto(m, String(ev["clave"])):
			return ev
	return {}

static func visto(m: Mundo, clave: String) -> bool:
	return m.prensa.eventos_vistos.has(clave)

## Aplica la respuesta `i` y marca el evento como visto. Devuelve lo que movió {moral, confianza}.
static func aplicar(m: Mundo, ev: Dictionary, i: int) -> Dictionary:
	if not m.prensa.eventos_vistos.has(String(ev["clave"])):
		m.prensa.eventos_vistos.append(String(ev["clave"]))
	var ops: Array = ev.get("opciones", [])
	if i < 0 or i >= ops.size():
		return {"moral": 0, "confianza": 0}
	var op: Dictionary = ops[i]
	var mo := int(op.get("moral", 0))
	var co := int(op.get("confianza", 0))
	var motivo := String(ev.get("lugar", "Evento"))
	if mo != 0:
		for j: Jugador in m.mi_club().plantilla:
			j.cambiar_moral(mo, motivo)
	if co != 0 and m.directiva != null:
		m.directiva.mover_confianza(co, motivo)
	return {"moral": mo, "confianza": co}

static func _clave(m: Mundo, id: String) -> String:
	return "%s:%d:%d" % [id, m.anio, m.semana]

static func _op(txt: String, moral: int, confianza: int) -> Dictionary:
	return {"txt": Idiomas.t(txt), "moral": moral, "confianza": confianza}

## REUNIÓN CON LA DIRECTIVA (semanas 1-2): el presidente fija el objetivo; tu respuesta marca cómo te miran.
static func _directiva(m: Mundo) -> Dictionary:
	if m.semana > 2 or m.directiva == null:
		return {}
	var obj := String(m.directiva.objetivo)
	return {"id": "directiva", "clave": "directiva:%d" % m.anio, "lugar": Idiomas.t("Despacho de la presidencia"),
		"quien": Idiomas.t("Presidencia del club"), "cargo": Idiomas.t("Directiva"),
		"texto": Idiomas.t("Empieza una temporada nueva. El consejo lo ha hablado y tiene claro lo que espera de usted: «%s». ¿Cómo lo ve?") % Idiomas.t(obj if obj != "" else "Hacer una temporada digna"),
		"opciones": [
			_op("Lo cumpliremos. Tiene mi palabra.", 1, 4),
			_op("Iremos a por más que eso.", 2, 6),
			_op("Necesito tiempo y paciencia.", 0, -2),
			_op("Con esta plantilla será difícil.", -2, -4),
		]}

## LA SEMANA DEL CLÁSICO: el capitán viene a hablar al vestuario antes del partido grande.
static func _clasico(m: Mundo) -> Dictionary:
	var pp := m.proximo_partido()
	if pp.size() < 2:
		return {}
	var mio := m.mi_club()
	var rival: Club = pp[1] if pp[0] == mio else pp[0]
	if not m.es_clasico(mio, rival):
		return {}
	var cap := capitan(mio)
	return {"id": "clasico", "clave": _clave(m, "clasico"), "lugar": Idiomas.t("Vestuario"),
		"quien": cap.nombre if cap != null else Idiomas.t("El capitán"), "cargo": Idiomas.t("Capitán"), "jugador": cap,
		"texto": Idiomas.t("Míster, esta semana es el clásico contra %s. El vestuario está encendido y la ciudad no habla de otra cosa. ¿Qué les decimos a los muchachos?") % rival.nombre,
		"opciones": [
			_op("¡Salgan a comérselos desde el primer minuto!", 4, 0),
			_op("Calma: es un partido más, con cabeza.", 1, 1),
			_op("Hablen ustedes; yo los escucho.", 2, 0),
			_op("El que no esté a la altura, al banco.", -1, 2),
		]}

## BALANCE DE MITAD DE LIGA: el ayudante compara el puesto con el objetivo de la directiva.
static func _mitad(m: Mundo) -> Dictionary:
	var liga := m.liga_de(m.mi_club())
	if liga == null or liga.jornadas() < 6 or liga.jornada_actual != liga.jornadas() / 2:
		return {}
	var puesto := puesto_de(liga, m.mi_club())
	var meta := int(m.directiva.meta_puesto) if m.directiva != null else 8
	var bien := puesto <= meta
	var texto := Idiomas.t("Llegamos a la mitad de la liga en el puesto %d. Vamos por encima de lo que pide la directiva: el plan funciona.") % puesto if bien \
		else Idiomas.t("Llegamos a la mitad de la liga en el puesto %d y la directiva pide el %d. Hay que cambiar algo.") % [puesto, meta]
	return {"id": "mitad", "clave": "mitad:%d" % m.anio, "lugar": Idiomas.t("Oficina del cuerpo técnico"),
		"quien": Idiomas.t("Tu ayudante"), "cargo": Idiomas.t("Segundo entrenador"), "texto": texto,
		"opciones": [
			_op("Seguimos igual: confío en el grupo.", 2 if bien else -1, 1 if bien else -1),
			_op("Más exigencia en los entrenamientos.", -1, 2),
			_op("Hablaré uno a uno con los jugadores.", 2, 0),
			_op("Pediré refuerzos a la directiva.", 0, -1 if bien else 1),
		]}

static func puesto_de(liga: Liga, c: Club) -> int:
	var t := liga.tabla()
	for i in t.size():
		if (t[i] as Dictionary)["club"] == c:
			return i + 1
	return t.size()

## El capitán para la escena: el de más edad entre los de más media (sin romper si el plantel está vacío).
static func capitan(c: Club) -> Jugador:
	var mejor: Jugador = null
	for j: Jugador in c.plantilla:
		if mejor == null or j.edad * 2 + j.ovr > mejor.edad * 2 + mejor.ovr:
			mejor = j
	return mejor
