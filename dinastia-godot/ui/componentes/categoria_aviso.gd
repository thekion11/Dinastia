class_name CategoriaAviso
extends RefCounted
## M-296 (28-10-2026): LA BANDEJA POR TEMAS. Los avisos llegan de decenas de sistemas con solo título y cuerpo; aquí se
## les pone tema por palabras del título (en castellano, como se guardan) para poder filtrar: prensa, cantera, mercado,
## plantel, competición, club y vida. Lo que no encaja va a «otros». El orden de la tabla manda (el primero que acierta).

const TEMAS := [
	["prensa", "📰 Prensa", ["prensa", "a pie de campo", "salió a la luz", "redes", "mensaje en público", "dijiste", "prometiste", "periodista"]],
	["cantera", "🎓 Cantera", ["cantera", "academia", "canterano", "juvenil", "camada", "joya", "beca", "escuela", "derechos de formación", "filial"]],
	["mercado", "💼 Mercado", ["fichaje", "firmado", "oferta", "traspaso", "cesión", "cedido", "préstamo", "precontrato", "renovado", "contrato",
		"se va libre", "te quiere", "ojeo", "opción por", "plusvalía", "mercado", "cláusula", "llega ", "venta", "clausulazo", "sin ficha", "nómina", "prenómina", "aumento", "tope salarial", "porcentaje pactado",
		"ventana de emergencia", "ojeador", "guerra por"]],
	["plantel", "🏃 Plantel", ["lesión", "sanción", "vestuario", "camarín", "habilidad", "entrenamiento", "práctica", "racha", "debut", "arenga",
		"se retira", "malestar", "promesa", "convocados", "dopaje", "antidopaje", "rotacion", "nacionaliz", "líder", "posición", "prima", "descanso", "hermano", "quiere hablar", "videoanálisis", "tocado", "decadencia", "«el nuevo»", "presentación",
		"pide ayuda", "médico", "ayudante", "cuerpo técnico", "generación", "acaba una carrera", "homenaje", "apellido", "afina", "nivel", "maestría"]],
	["competicion", "🏆 Competición", ["federación", "liga", "copa", "playoff", "título", "asamblea", "apelación", "licencia", "fecha internacional",
		"partido", "sorteo", "jornada", "campeón", "fair play", "auditoría", "puertas cerradas", "veedor", "permiso", "aforo", "mundial", "campeones", "continental", "promoción", "puntos menos", "tribunal", "alineación",
		"reglamento", "pretemporada", "vitrina", "moda", "bloque", "solicitud"]],
	["club", "🏟 Club", ["directiva", "dueño", "estadio", "obra", "inaugurado", "patrocin", "auspic", "naming", "socios", "abonos", "crédito",
		"banco", "cuentas", "fondo", "dinero", "mora", "tv", "vocero", "hinchada", "barra", "césped", "concierto", "asciendes", "subvención", "entrenador", "terreno", "jeque", "accionistas", "elecciones", "electoral", "moción",
		"corrupción", "escándalo", "refundado", "seguridad", "zona vendida", "cubierta", "avión", "lienzos", "puertas abiertas", "asado",
		"proyecto", "comercial", "cuenta del club", "cinturón", "jefe", "atrasos", "bono", "época dorada", "inversión", "operación histórica",
		"desafío", "misión", "decisión pendiente", "incendio", "asunto en"]],
	["vida", "🏠 Vida", ["familia", "hijo", "colegio", "mudanza", "cumpleaños", "vecin", "barrio", "casa", "lío nocturno", "gemelos", "mi vida", "viaje", "tenso", "examen", "aprobada", "alumno"]],
]

## Cada palabra tiene que EMPEZAR una palabra del título («cedido» no acierta en «concedido»; «patrocin» sí en «patrocinador»).
static func de(titulo: String) -> String:
	var t := " " + titulo.to_lower().replace("«", " «").replace(":", " ").replace("¡", " ").replace("¿", " ")
	for tema: Array in TEMAS:
		for palabra: String in tema[2]:
			if t.contains(" " + palabra):
				return String(tema[0])
	return "otros"

static func nombre(clave: String) -> String:
	for tema: Array in TEMAS:
		if String(tema[0]) == clave:
			return String(tema[1])
	return "📌 Otros"

## El tema de una fila de la bandeja (las guardadas antes de esto no lo llevan: se calcula y se queda).
static func de_fila(it: Dictionary) -> String:
	if not it.has("tema"):
		it["tema"] = de(String(it.get("titulo", "")))
	return String(it["tema"])
