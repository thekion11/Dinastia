class_name RecorridoCharla
extends RefCounted
## LA CHARLA DEL PERSONAL, MÁS VARIADA (25-10-2026, paquete pint).
##
## Antes cada persona del club decía SIEMPRE la misma frase al acercarte
## (`RecorridoClub.SALUDOS`): a la tercera visita sonaba a muñeco. Aquí el
## saludo cambia con la hora del día y con la semana de la partida (dos
## variantes más por oficio, elegidas de forma estable: la misma semana dice
## lo mismo, la siguiente otra cosa), y cuatro oficios que no tenían pregunta
## propia (prensa, chófer, conserje, hincha) la ganan, con datos de verdad.

## Preguntas nuevas (se suman a `RecorridoClub.PREGUNTA_OFICIO`).
const PREGUNTAS := {
	"prensa": "¿Qué se dice de nosotros fuera?",
	"chofer": "¿Adónde toca viajar?",
	"conserje": "¿Cómo está el estadio?",
	"hincha": "¿Cómo está la gente?",
}

## Qué saludo toca. `semana` < 0 = no hay partida (se usa el saludo base).
## La hora manda primero: de madrugada o de noche se nota.
static func saludo(clave: String, base: String, semana: int, hora: float) -> String:
	if hora >= 0.0 and (hora < 9.0 or hora >= 20.0):
		var tarde := hora >= 20.0
		match clave:
			"conserje":
				return Idiomas.t("A estas horas solo quedamos usted y yo. Y las ratas del sótano.") if tarde \
					else Idiomas.t("Llega antes que el café, míster. Eso me gusta.")
			"cocinera":
				return Idiomas.t("La cocina ya está cerrada, pero algo le guardo.") if tarde \
					else Idiomas.t("El desayuno está servido. Los chicos aún bostezan.")
			"medico":
				return Idiomas.t("Me quedo a revisar las placas. Usted también debería descansar.") if tarde \
					else Idiomas.t("Primera hora: hielo, vendas y quejas. Lo de siempre.")
	var variantes := _variantes(clave)
	if semana < 0 or variantes.is_empty():
		return Idiomas.t(base)
	## Base + variantes, rotando por semana (y desfasado por oficio, para que
	## no cambien todos a la vez).
	var i := (semana + absi(clave.hash())) % (variantes.size() + 1)
	return Idiomas.t(base) if i == 0 else variantes[i - 1]

static func _variantes(clave: String) -> Array:
	match clave:
		"conserje":
			return [Idiomas.t("He cambiado las bombillas del pasillo. Ahora se ve hasta el polvo."),
				Idiomas.t("Si oye un golpe en el vestuario, es la caldera. Está vieja, como yo.")]
		"jardinero":
			return [Idiomas.t("He bajado el corte un milímetro. Al balón le gusta rápido."),
				Idiomas.t("Si llueve el sábado, el campo aguanta. Se lo prometo.")]
		"hincha":
			return [Idiomas.t("Traje la bufanda de mi padre. Da suerte, ya verá."),
				Idiomas.t("En el barrio no se habla de otra cosa, míster.")]
		"utilero":
			return [Idiomas.t("Botas engrasadas, tacos revisados. Nadie se me resbala."),
				Idiomas.t("Alguien me ha vuelto a esconder los petos. Ya sé quién.")]
		"medico":
			return [Idiomas.t("Más estiramientos y menos excusas. Se lo digo a todos."),
				Idiomas.t("Si alguien le dice que está bien, pregúnteme a mí primero.")]
		"chofer":
			return [Idiomas.t("He limpiado los cristales del bus. Se ve hasta el futuro."),
				Idiomas.t("Ruta revisada, depósito lleno. Usted solo diga cuándo.")]
		"secretaria":
			return [Idiomas.t("Le he dejado la agenda en la mesa. Mañana no tiene ni un hueco."),
				Idiomas.t("Ha llamado un agente. Dice que es urgente; siempre lo es.")]
		"ojeador":
			return [Idiomas.t("He visto tres partidos este fin de semana. Uno valía la pena."),
				Idiomas.t("A mi edad ya no corro, pero sigo viendo antes que nadie.")]
		"presidente":
			return [Idiomas.t("Pase. La puerta de este despacho está abierta para usted."),
				Idiomas.t("Los socios preguntan. Déme algo que contarles.")]
		"prensa":
			return [Idiomas.t("Hoy vienen cuatro radios y un diario. Sonría, aunque cueste."),
				Idiomas.t("Le preparé las respuestas difíciles. Úselas.")]
		"cocinera":
			return [Idiomas.t("Pescado al horno. Al que proteste, doble ración."),
				Idiomas.t("El capitán repitió dos veces. Buena señal.")]
		"portero":
			return [Idiomas.t("Buen día para entrar, míster. La casa está en orden."),
				Idiomas.t("Ya he espantado a dos curiosos. Usted pase.")]
	return []

## Respuesta a las preguntas nuevas, con datos de la partida. Devuelve
## [texto, mala_noticia]; texto vacío si la clave no es de aquí.
static func respuesta(clave: String, m: Mundo, c: Club) -> Array:
	match clave:
		"prensa":
			if c.confianza >= 70:
				return [Idiomas.t("Nos tratan bien. Hasta los de la capital hablan del equipo."), false]
			if c.confianza >= 45:
				return [Idiomas.t("Tibios. Una buena racha y cambian el titular."), false]
			return [Idiomas.t("Afilan los cuchillos, míster. Cuidado con lo que dice."), true]
		"chofer", "hincha":
			var rival := _rival(m, c)
			if rival == null:
				return [Idiomas.t("Esta semana no hay partido. Descanso para todos."), false]
			var en_casa: bool = m.proximo_partido()[0] == c
			if clave == "chofer":
				return [Idiomas.t("Jugamos en casa contra %s. Hoy el bus no sale.") % rival.nombre if en_casa
					else Idiomas.t("Toca ir a casa de %s. Salimos el día antes.") % rival.nombre, false]
			if c.confianza >= 55:
				return [Idiomas.t("Con ganas de %s. Llenamos la grada, se lo juro.") % rival.nombre, false]
			return [Idiomas.t("Nerviosa. Contra %s no perdonan otra mala tarde.") % rival.nombre, true]
		"conserje":
			if c.estadio_aforo <= 0:
				return [Idiomas.t("Todo en orden, míster."), false]
			var lleno := float(c.socios) / float(c.estadio_aforo)
			if lleno >= 0.6:
				return [Idiomas.t("Con %d socios y %d asientos, se nos queda chico.") % [c.socios, c.estadio_aforo], false]
			return [Idiomas.t("%d asientos y %d socios. Sobran butacas por llenar.") % [c.estadio_aforo, c.socios], lleno < 0.3]
	return ["", false]

static func _rival(m: Mundo, c: Club) -> Club:
	var par := m.proximo_partido()
	if par.size() < 2:
		return null
	return (par[1] if par[0] == c else par[0]) as Club
