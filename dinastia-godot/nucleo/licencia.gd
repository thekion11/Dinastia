class_name Licencia
extends RefCounted
## LA LICENCIA DE ENTRENADOR: EXÁMENES (26-9-2026, plan maestro C7). Pedido:
## *"exámenes"*. Cuatro niveles -C, B, A y Pro, los mismos escalones que usan las
## federaciones-, cada uno con su examen: ocho preguntas de un banco de reglamento
## (las Reglas de Juego vigentes) y de táctica. Se aprueba con seis. Aprobar sube
## el prestigio y la reputación como entrenador; suspender obliga a esperar
## cuatro semanas para volver a presentarse.
##
## Las preguntas se eligen con un hash del intento: el mismo intento, el mismo
## examen, sin `Azar`.

signal noticia(titulo: String, cuerpo: String)

const NIVELES := ["Sin licencia", "Licencia C", "Licencia B", "Licencia A", "Licencia Pro"]
const PREGUNTAS_POR_EXAMEN := 8
const PARA_APROBAR := 6
const ESPERA_SEMANAS := 4
## Lo que suma aprobar cada nivel: [prestigio, reputación de entrenador].
const PREMIO := [[0, 0], [2, 2], [3, 3], [4, 4], [6, 6]]

## pregunta, [opciones], índice correcto, nivel mínimo (1 = C ... 4 = Pro)
const BANCO := [
	["¿Cuántos jugadores necesita como mínimo un equipo para que el partido empiece o continúe?", ["5", "7", "9"], 1, 1],
	["¿Cuánto dura cada tiempo de un partido oficial de adultos?", ["40 minutos", "45 minutos", "50 minutos"], 1, 1],
	["¿A qué distancia de la línea de meta está el punto penal?", ["9,15 m", "11 m", "12 m"], 1, 1],
	["¿A qué distancia mínima debe colocarse la barrera en un tiro libre?", ["9,15 m", "7 m", "11 m"], 0, 1],
	["¿Se puede marcar gol directamente de un saque de banda?", ["Sí", "No", "Solo en la portería rival"], 1, 1],
	["¿Hay fuera de juego si se recibe el balón directamente de un saque de esquina?", ["Sí", "No", "Solo en el área"], 1, 1],
	["Un jugador ve la segunda amarilla del partido. ¿Qué pasa?", ["Nada más", "Es expulsado", "Queda amonestado otra vez"], 1, 1],
	["¿Cuándo está fuera el balón?", ["Cuando toca la línea", "Cuando la cruza por completo", "Cuando la cruza a medias"], 1, 1],
	["¿Cuántas sustituciones permite hoy el reglamento en un partido oficial?", ["3", "5", "7"], 1, 2],
	["¿Cuánto mide la portería?", ["7,32 m × 2,44 m", "7 m × 2,5 m", "8 m × 2,44 m"], 0, 2],
	["¿Hay fuera de juego si se recibe el balón directamente de un saque de meta?", ["Sí", "No", "Solo en campo rival"], 1, 2],
	["¿Cómo indica el árbitro un tiro libre indirecto?", ["Señalando el punto", "Con el brazo en alto", "Con el silbato largo"], 1, 2],
	["¿Cuánto mide el radio del círculo central?", ["9,15 m", "10 m", "11 m"], 0, 2],
	["¿Cuánto dura la prórroga?", ["Un tiempo de 30 min", "Dos tiempos de 15 min", "Dos tiempos de 10 min"], 1, 2],
	["En un 4-3-3, ¿cuántos defensores hay?", ["3", "4", "5"], 1, 2],
	["¿Se puede marcar gol directamente de un saque de meta en la portería rival?", ["Sí", "No", "Solo si lo toca otro"], 0, 3],
	["Un tiro libre indirecto entra directo en la portería rival sin que nadie lo toque. ¿Qué se señala?", ["Gol", "Saque de meta", "Se repite"], 1, 3],
	["Desde 2025, si el portero retiene el balón en las manos más de 8 segundos, se concede…", ["Tiro libre indirecto", "Saque de esquina al rival", "Penal"], 1, 3],
	["Un atacante toca el balón con la mano de forma accidental y marca inmediatamente. ¿Qué pasa?", ["Gol válido", "Gol anulado", "Penal en contra"], 1, 3],
	["¿Qué es un «falso 9»?", ["Un 9 que baja a crear juego", "Un lateral que ataca", "Un portero-líbero"], 0, 3],
	["Una línea defensiva muy adelantada aumenta sobre todo el riesgo de…", ["Tiros lejanos", "Balones a la espalda", "Córners en contra"], 1, 3],
	["Presionar alto tras pérdida busca principalmente…", ["Descansar con balón", "Recuperar cerca del área rival", "Proteger el marcador"], 1, 3],
	["Los días previos a un partido importante, la carga de entrenamiento suele…", ["Aumentar", "Reducirse", "Mantenerse al máximo"], 1, 4],
	["¿Qué buscan los «tercer hombre» en el juego de posición?", ["Un pase largo directo", "Liberar a un jugador que recibe de cara tras una pared", "Ganar segundas jugadas"], 1, 4],
	["Con un 3-5-2, ¿quién da la amplitud en ataque?", ["Los centrales", "Los carrileros", "Los delanteros"], 1, 4],
	["Un bloque bajo con transiciones rápidas renuncia a…", ["La posesión", "Los contraataques", "Defender el área"], 0, 4],
	["La «periodización táctica» organiza el entrenamiento en torno a…", ["El físico aislado", "El modelo de juego del equipo", "Los partidos amistosos"], 1, 4],
	["En la gestión de un vestuario, la rotación programada sirve sobre todo para…", ["Castigar", "Repartir carga y mantener implicado al grupo", "Probar juveniles"], 1, 4],
]

var nivel: int = 0
var espera_hasta: int = 0      ## semana absoluta desde la que puedes volver a presentarte
var intentos: int = 0

static func _abs(anio: int, semana: int) -> int:
	return anio * 60 + semana

func nombre() -> String:
	return NIVELES[nivel]

func puede_presentarse(anio: int, semana: int) -> String:
	if nivel >= NIVELES.size() - 1:
		return "Ya tienes la licencia más alta."
	if _abs(anio, semana) < espera_hasta:
		return "Suspendiste hace poco: podrás volver a presentarte en %d semana(s)." % (espera_hasta - _abs(anio, semana))
	return ""

## Las preguntas del próximo examen (el del nivel siguiente).
func examen() -> Array:
	var objetivo := nivel + 1
	var pool: Array = []
	for q: Array in BANCO:
		if int(q[3]) <= objetivo and int(q[3]) >= maxi(1, objetivo - 1):
			pool.append(q)
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(("examen|%d|%d" % [objetivo, intentos]).hash())
	var salida: Array = []
	var usados := {}
	while salida.size() < mini(PREGUNTAS_POR_EXAMEN, pool.size()):
		var i := rng.randi() % pool.size()
		if not usados.has(i):
			usados[i] = true
			salida.append(pool[i])
	return salida

## Corrige. `respuestas` son los índices elegidos, en el orden de `examen()`.
func corregir(preguntas: Array, respuestas: Array, anio: int, semana: int, roles: Roles, prensa: Prensa) -> Dictionary:
	var bien := 0
	for i in mini(preguntas.size(), respuestas.size()):
		if int(respuestas[i]) == int((preguntas[i] as Array)[2]):
			bien += 1
	intentos += 1
	var aprobado := bien >= PARA_APROBAR
	if aprobado:
		nivel += 1
		var premio: Array = PREMIO[nivel]
		if roles != null:
			roles.sumar_prestigio(int(premio[0]))
		if prensa != null:
			prensa.rep_entrenador = clampi(prensa.rep_entrenador + int(premio[1]), 1, 99)
		noticia.emit("🎓 %s aprobada" % nombre(), "%d de %d respuestas correctas. Más prestigio en el banquillo." % [bien, preguntas.size()])
	else:
		espera_hasta = _abs(anio, semana) + ESPERA_SEMANAS
		noticia.emit("🎓 Examen suspendido", "%d de %d: hacían falta %d. Podrás repetirlo en %d semanas." % [
			bien, preguntas.size(), PARA_APROBAR, ESPERA_SEMANAS])
	return {"bien": bien, "total": preguntas.size(), "aprobado": aprobado, "nivel": nombre()}

func a_dic() -> Dictionary:
	return {"nivel": nivel, "espera": espera_hasta, "intentos": intentos}

func desde_dic(d: Dictionary) -> void:
	nivel = int(d.get("nivel", 0))
	espera_hasta = int(d.get("espera", 0))
	intentos = int(d.get("intentos", 0))
