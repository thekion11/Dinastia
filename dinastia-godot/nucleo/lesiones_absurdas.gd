class_name LesionesAbsurdas
extends RefCounted
## LESIONES ABSURDAS FUERA DE LA CANCHA (26-9-2026, plan maestro C8). Pedido:
## *"lesiones absurdas fuera de la cancha"*. En el fútbol de verdad pasan: el
## resbalón en la ducha, el perro, la consola, la barbacoa... Son poco
## frecuentes (una cada ~14 semanas en tu plantel), cortas, y son noticia: la
## prensa sensacionalista vive de ellas.
##
## Las de NOCHE (la boda, la fiesta, la consola a las tres de la mañana) no
## pasan si el vestuario tiene toque de queda (`Mundo.normas["queda"]`): es la
## razón de ser de esa norma, que hasta hoy solo costaba moral.
##
## Nada de `Azar`: el sorteo sale de un generador local sembrado con la fecha y
## el club, así que no mueve ningún otro resultado de la partida.

const PROB_SEMANA := 0.07

## texto (con %s = nombre), semanas mínimo, máximo, ¿de noche?
const CATALOGO := [
	["%s se resbaló en la ducha del vestuario", 1, 2, false],
	["A %s lo mordió su propio perro mientras lo paseaba", 1, 2, false],
	["%s se hizo una tendinitis en la muñeca de tanto jugar a la consola", 1, 3, true],
	["%s se torció el tobillo al bajar del autobús del equipo", 1, 3, false],
	["%s se quemó la mano con la barbacoa familiar", 1, 2, false],
	["%s se golpeó con la puerta del coche celebrando el gol de otro equipo en la tele", 1, 1, true],
	["%s se lastimó la espalda al levantar en brazos a su hijo", 1, 3, false],
	["%s se cortó con un vaso roto en una cena de cumpleaños", 1, 2, true],
	["%s se hizo daño en el cuello durmiendo torcido en el avión", 1, 2, false],
	["%s se esguinzó el tobillo bailando en una boda", 2, 4, true],
	["%s tropezó con el perro al salir de casa", 1, 2, false],
	["%s se golpeó la rodilla contra la mesa de ping-pong del vestuario", 1, 2, false],
	["%s se contracturó al dormirse en la camilla de fisioterapia", 1, 1, false],
	["%s se torció la muñeca en una pelea de almohadas en la concentración", 1, 2, true],
]

## Lo que pasó esta semana, o vacío: {jugador, texto, semanas}.
static func sortear(c: Club, anio: int, semana: int, toque_de_queda: bool) -> Dictionary:
	if c == null or c.plantilla.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(("%s|%d|%d|absurda" % [c.id, anio, semana]).hash())
	if rng.randf() >= PROB_SEMANA:
		return {}
	var sanos: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.lesion <= 0:
			sanos.append(j)
	if sanos.is_empty():
		return {}
	var posibles: Array = []
	for f: Array in CATALOGO:
		if not (toque_de_queda and bool(f[3])):
			posibles.append(f)
	var fila: Array = posibles[rng.randi() % posibles.size()]
	var j: Jugador = sanos[rng.randi() % sanos.size()]
	var sem := rng.randi_range(int(fila[1]), int(fila[2]))
	return {"jugador": j, "texto": String(fila[0]) % j.nombre, "semanas": sem, "noche": bool(fila[3])}
