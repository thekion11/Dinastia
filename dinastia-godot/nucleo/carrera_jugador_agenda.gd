class_name CarreraAgenda
extends RefCounted
## LA AGENDA DE LA SEMANA (M-263, 25-10-2026). En la Carrera de Jugador, además
## del foco de entrenamiento, eliges qué haces con el resto de la semana. Cada
## opción tiene un efecto REAL al cerrar la semana (energía, moral, seguidores,
## relación con el DT, probabilidad de mejorar al entrenar) y se guarda con la
## partida (`CarreraJugador.agenda`). También viven aquí los eventos únicos que
## nacen de la agenda o de la trayectoria (goles y partidos de carrera).
##
## Todo con el generador propio de la carrera: no mueve la simulación del mundo.

const AGENDAS := {
	"normal": ["⚖️ Semana normal", "Entrenas, descansas lo justo y poco más."],
	"extra": ["🏋️ Sesión extra", "Más opciones de mejorar al entrenar; cansa más."],
	"descanso": ["🛌 Descanso y fisio", "Recuperas energía y ánimo."],
	"social": ["🎉 Vida social", "Más seguidores y ánimo; si vas cansado, al DT no le gusta."],
}

## Lo que suma la agenda a la probabilidad de mejorar al entrenar.
static func extra_entreno(agenda: String) -> float:
	return 0.12 if agenda == "extra" else 0.0

## Aplica la agenda al cerrar la semana. Devuelve el resumen para el aviso, ya
## traducido (la UI lo une con «·» a otras frases y el conjunto no se traduce).
static func aplicar(c: CarreraJugador, j: Jugador) -> String:
	match c.agenda:
		"extra":
			c.energia = maxi(0, c.energia - 8)
			c.relacion_dt = mini(100, c.relacion_dt + 1)
			c.racha_social = 0
			return Idiomas.t("Sesión extra: el DT lo nota (+1 relación), −8 energía.")
		"descanso":
			c.energia = mini(CarreraJugador.ENERGIA_MAX, c.energia + 12)
			c.racha_social = 0
			if j != null:
				j.cambiar_moral(1, "Carrera")
			return Idiomas.t("Descanso y fisio: +12 energía.")
		"social":
			var nuevos := 40 + c.fama * 2
			c.seguidores += nuevos
			c.energia = maxi(0, c.energia - 6)
			c.racha_social += 1
			if j != null:
				j.cambiar_moral(3, "Carrera")
			if c.energia < 35:
				c.relacion_dt = maxi(0, c.relacion_dt - 2)
				return Idiomas.t("Vida social: +%d seguidores, pero el DT te ve cansado (−2 relación).") % nuevos
			return Idiomas.t("Vida social: +%d seguidores y buen ánimo, −6 energía.") % nuevos
	c.racha_social = 0
	return ""

## Eventos únicos nuevos: cada uno sale de algo que hiciste de verdad.
static func eventos(c: CarreraJugador, j: Jugador) -> Array:
	var p: Array = []
	if not c.hitos.has("foto_viral") and c.racha_social >= 3:
		p.append(c._ev("foto_viral", "Una foto tuya se hace viral",
			"Tres semanas seguidas de salidas: una foto tuya en una terraza a medianoche da la vuelta a las redes. El DT la ha visto.",
			[c._op("Pides perdón al DT y prometes centrarte.", {"relacion": 3, "seguidores": -100}),
			c._op("Lo conviertes en una broma en tus redes.", {"seguidores": 700, "fama": 2, "relacion": -4})], true))
	if not c.hitos.has("goles_10") and c.goles_carrera >= 10:
		p.append(c._ev("goles_10", "Diez goles como profesional",
			"La afición te canta en el calentamiento: ya llevas diez goles en tu carrera.",
			[c._op("Les regalas tus botas al acabar el partido.", {"seguidores": 400, "fama": 3, "moral": 4}),
			c._op("Lo celebras en silencio: quieres muchos más.", {"relacion": 2, "attr_tir": 1})], true))
	if not c.hitos.has("partidos_100") and c.pj_carrera >= 100 and j != null:
		p.append(c._ev("partidos_100", "Cien partidos profesionales",
			"El club te entrega una camiseta enmarcada con el número 100 antes del partido.",
			[c._op("Se la dedicas a tu familia.", {"moral": 6, "seguidores": 300}),
			c._op("Pides que la cuelguen en el vestuario.", {"relacion": 4, "fama": 2})], true))
	return p

## La progresión visible: cuánto subió tu media desde el inicio de la temporada.
static func progreso(c: CarreraJugador, j: Jugador) -> int:
	if j == null or c.ovr_inicio < 0:
		return 0
	return j.ovr - c.ovr_inicio
