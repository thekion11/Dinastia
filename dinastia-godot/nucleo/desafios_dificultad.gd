class_name DesafiosDificultad
extends RefCounted
## LA DIFICULTAD FUERA DEL PARTIDO (pedido del dueño, 27-10-2026: «eventos, posibilidades, retos, poca ayuda,
## asistentes deficientes, malos consejos»). Son desafíos como los de siempre (tabla `DESAFIOS`, elegidos al
## empezar, multiplican la puntuación y se consultan con `Mundo.tiene_desafio`), sumados a los del HTML sin
## reescribir aquella tabla. Cada uno se engancha en su sistema:
##   mala_racha         → `Partido.ctx_lesion_local` ×1,6 (más lesiones en casa y fuera)
##   retos_duros        → `RetosSemana.generar`: solo los retos difíciles y un 40 % menos de premio
##   poca_ayuda         → `MentorPrimerMes`: sin los consejos del primer mes
##   asistentes_torpes  → `Ojeadores._error_de`: el doble de error al estimar la media (y nunca exacta)
##   malos_consejos     → `MentorPrimerMes`: uno de cada tres consejos dice lo contrario de lo que conviene
##   impaciente         → `Directiva.impaciencia` 1,5: la confianza baja un 50 % más deprisa

## [clave, icono, nombre, descripción, multiplicador de puntuación]: el formato de `DESAFIOS`.
const EXTRA := [
	["mala_racha", "🌪", "Mala racha", "Más lesiones durante toda la temporada", 1.3],
	["retos_duros", "🎯", "Retos exigentes", "Los retos de la semana más difíciles y con menos premio", 1.15],
	["poca_ayuda", "🙈", "Poca ayuda", "Sin el mentor que te aconseja el primer mes", 1.2],
	["asistentes_torpes", "🥴", "Asistentes torpes", "Tus ojeadores fallan el doble al estimar la media de un jugador", 1.2],
	["malos_consejos", "🗣", "Malos consejos", "El mentor a veces te dice lo contrario de lo que conviene", 1.15],
	["impaciente", "⏳", "Directiva impaciente", "La confianza de la directiva baja un 50 % más deprisa", 1.3],
]
const LESIONES := 1.6
const PREMIO_RETOS := 0.6
const IMPACIENCIA := 1.5

## Todos los desafíos: los de la tabla del juego y estos.
static func todos() -> Array:
	var t: Variant = Datos.tabla("DESAFIOS")
	var salida: Array = (t as Array).duplicate() if t is Array else []
	salida.append_array(EXTRA)
	return salida

## Aplica a la directiva lo que toca (al tomar el mando y al cargar una partida).
static func aplicar(m: Mundo) -> void:
	if m != null and m.directiva != null:
		m.directiva.impaciencia = IMPACIENCIA if m.tiene_desafio("impaciente") else 1.0

## ¿Este consejo del mentor sale al revés? Uno de cada tres, fijo por semana (no tira del azar de la partida).
static func consejo_enganoso(m: Mundo, semana_al_mando: int) -> bool:
	return m != null and m.tiene_desafio("malos_consejos") and absi(hash([m.anio, semana_al_mando, "consejo"])) % 3 == 0
