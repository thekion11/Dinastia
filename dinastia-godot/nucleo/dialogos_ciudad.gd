class_name DialogosCiudad
extends RefCounted
## DIÁLOGOS DE LOS VECINOS (13-10-2026, «mejorar los diálogos, más variedad, NPCs con vida»).
## Cada vecino tiene un OFICIO (sale de su número) y habla en TRES TURNOS: saludo según el
## ánimo del club, una charla propia de su oficio y una despedida. Generado por
## `herramientas/dialogos_ciudad.py` (no editar a mano: las frases y sus traducciones
## a los 9 idiomas viven en ese script).

const OFICIOS := ["panadera", "jubilado", "estudiante", "taxista", "hincha"]

static func oficio_de(numero: int) -> String:
	return String(OFICIOS[absi(numero) % OFICIOS.size()])

## Grupo de ánimo: pos (euforia, bien), neu (normal), neg (mal, crisis).
static func grupo(animo: String) -> String:
	match animo:
		"euforia", "bien": return "pos"
		"mal", "crisis": return "neg"
	return "neu"

static func nombre(oficio: String) -> String:
	match oficio:
		"panadera": return Idiomas.t("La panadera")
		"jubilado": return Idiomas.t("El jubilado")
		"estudiante": return Idiomas.t("La estudiante")
		"taxista": return Idiomas.t("El taxista")
		"hincha": return Idiomas.t("El hincha")
	return ""

## Turno 0 = saludo, 1 = charla, 2 = despedida.
static func linea(oficio: String, turno: int, animo: String, rng: RandomNumberGenerator) -> String:
	match oficio:
		"panadera":
			if turno == 0:
				match grupo(animo):
					"pos": return Idiomas.t("¡Buenos días, míster! Con la victoria, el pan sale más rico.")
					"neg": return Idiomas.t("Ay, míster… hoy hasta la masa me salió triste.")
				return Idiomas.t("Buenas, míster. ¿Un pan para el camino?")
			if turno == 1:
				var c := [Idiomas.t("Madrugo a las cuatro y a esa hora ya se oye a los chicos entrenar."), Idiomas.t("Los sábados de partido vendo el doble de bocadillos."), Idiomas.t("Si quiere, le guardo una hogaza para después del entrenamiento.")]
				return String(c[rng.randi() % c.size()])
			return Idiomas.t("¡Que le vaya bien, míster! Pase por la panadería.")
		"jubilado":
			if turno == 0:
				match grupo(animo):
					"pos": return Idiomas.t("¡Mire quién anda por aquí! Esto sí que es un equipo.")
					"neg": return Idiomas.t("No sé, míster, no sé… en mis tiempos se corría más.")
				return Idiomas.t("Buenas, míster. Yo ya he visto de todo en este estadio.")
			if turno == 1:
				var c := [Idiomas.t("Fui socio desde el año cincuenta y pico. Nunca me perdí un clásico."), Idiomas.t("Me siento siempre en la misma grada. Si cambian el asiento, me muero."), Idiomas.t("Ese juvenil que sube tiene el pase de los de antes.")]
				return String(c[rng.randi() % c.size()])
			return Idiomas.t("Cuídese, míster, y cuide a esos muchachos.")
		"estudiante":
			if turno == 0:
				match grupo(animo):
					"pos": return Idiomas.t("¡Míster! ¡Mis amigas no se lo van a creer, le saludé!")
					"neg": return Idiomas.t("Hola… ¿podemos no hablar del último partido?")
				return Idiomas.t("Hola, míster. Perdone, voy tarde a clase.")
			if turno == 1:
				var c := [Idiomas.t("Hago un trabajo sobre cómo se mide el rendimiento de un equipo."), Idiomas.t("En la universidad hay una peña del club; nos juntamos a ver los partidos."), Idiomas.t("Quiero ser analista de datos y trabajar en un club como este.")]
				return String(c[rng.randi() % c.size()])
			return Idiomas.t("¡Gracias por el rato, míster! ¡Suerte este sábado!")
		"taxista":
			if turno == 0:
				match grupo(animo):
					"pos": return Idiomas.t("¡Míster, hoy el viaje va gratis… bueno, casi!")
					"neg": return Idiomas.t("Míster, los pasajeros ya no me hablan de otra cosa. Y no es bonito.")
				return Idiomas.t("Buenas, míster. La radio no habla de otra cosa que del equipo.")
			if turno == 1:
				var c := [Idiomas.t("Llevo hinchas al estadio todos los fines de semana: se les nota el humor."), Idiomas.t("Por la avenida del Reloj hay atasco los días de partido; salga con tiempo."), Idiomas.t("Una vez llevé a un jugador del equipo rival. No quiso decirme nada, claro.")]
				return String(c[rng.randi() % c.size()])
			return Idiomas.t("¡Hasta la próxima, míster! Si necesita un taxi, ya sabe.")
		"hincha":
			if turno == 0:
				match grupo(animo):
					"pos": return Idiomas.t("¡¡Míster!! ¡¡Dígale a los muchachos que este año es nuestro!!")
					"neg": return Idiomas.t("Míster… con respeto: ¡hay que poner más garra!")
				return Idiomas.t("Míster, aguante, que esto sube. Nosotros siempre estamos.")
			if turno == 1:
				var c := [Idiomas.t("Tengo el abono desde hace veinte años y ni una baja."), Idiomas.t("Con los de la grada baja hemos preparado un tifo enorme para el próximo domingo."), Idiomas.t("Pase lo que pase, yo voy a cantar. Eso no se negocia.")]
				return String(c[rng.randi() % c.size()])
			return Idiomas.t("¡Vamos, míster! ¡Mañana en la tribuna nos vemos!")
	return ""
