class_name PrologoPasos
extends RefCounted
## EL GUION DEL PRÓLOGO 3D (fase 2 del plan del lunes, 26-10-2026). Solo DATOS:
## qué pasos hay, a qué sala lleva cada uno y qué dice el mentor al llegar. La
## lógica (esperar a que llegues, mover al mentor, abrir el PC) vive en
## `PrologoDT`; así el guion se lee y se traduce de un vistazo.
##
## Cada paso: clave, planta y zona del edificio (`TunelVestuario.datos` +
## `EdificioClub.zonas`), frases del mentor en orden y, si enseña un control,
## la acción de `Mando` cuya tecla real se escribe en la tarjeta.

## Las etapas, en el orden del guion del dueño (§2.1 del plan): llegada, cómo
## moverse, el edificio por dentro (sin tu oficina), la directiva, la prensa
## y, al final, tu oficina con el PC.
const PASOS := [
	{"clave": "llegada", "planta": 0, "zona": "", "fuera": true,
		"frases": [
			"¡Bienvenido! Soy %s. Hoy empieza tu dinastía y me ha tocado enseñártelo todo.",
			"Antes de entrar, muévete un poco: acércate hasta mí.",
		],
		"controles": ["mover", "correr"]},
	{"clave": "puerta", "planta": 0, "zona": "", "fuera": true,
		"frases": [
			"Así se camina por aquí. La cámara la giras con el ratón o el stick derecho; con V ves en primera persona.",
			"El portero abre a quien conoce. Habla con él y entramos.",
		],
		"controles": ["usar"]},
	{"clave": "vestuario", "planta": 0, "zona": "Vestuario",
		"frases": [
			"El vestuario. Cada taquilla lleva el nombre de un jugador; aquí se ganan y se pierden los partidos antes de jugarlos.",
			"Sígueme por el túnel: quiero que veas el campo desde abajo.",
		]},
	{"clave": "tunel", "planta": 0, "zona": "Túnel",
		"frases": [
			"El túnel. Por aquí sale el equipo cada partido; desde aquí ya se oye la grada.",
			"Unos pasos más y estamos en la banda.",
		]},
	{"clave": "campo", "planta": 0, "zona": "Banda",
		"frases": [
			"Tu banquillo. Desde aquí dirigirás; y cuando te sancionen, desde la grada, como todo el mundo.",
			"Ahora al sótano: la utilería y la enfermería. El ascensor está al fondo del edificio.",
		],
		"controles": ["usar"]},
	{"clave": "utileria", "planta": -1, "zona": "Utilería", "saluda": "utilero",
		"saludo": "¡Bienvenido, míster! Botas, balones y camisetas: todo numerado y listo para el domingo.",
		"frases": [
			"La utilería. Nada sale al campo sin pasar por estas manos; el utilero sabe antes que nadie quién está más fino.",
			"Al lado, la enfermería.",
		]},
	{"clave": "enfermeria", "planta": -1, "zona": "Enfermería", "saluda": "medico",
		"saludo": "Encantado. Cada lunes tendrá el parte: quién llega al domingo y quién no.",
		"frases": [
			"La enfermería. Hazle caso al médico: un jugador forzado hoy es una baja de un mes.",
			"Subamos a la primera planta: el presidente quiere conocerte.",
		]},
	{"clave": "presidente", "planta": 1, "zona": "Despacho del presidente",
		"frases": [
			"El despacho del presidente. Aquí se firma y aquí se despide. Te presento a la junta.",
		],
		"directiva": true},
	{"clave": "video", "planta": 1, "zona": "Sala de vídeo", "saluda": "ojeador",
		"saludo": "Míster, un gusto. Del próximo rival ya tengo los primeros vídeos.",
		"frases": [
			"La sala de vídeo: aquí se estudia al rival. El ojeador te dejará sus informes cada semana.",
			"Ahora arriba, a la segunda planta: la prensa te espera.",
		]},
	{"clave": "prensa", "planta": 2, "zona": "Sala de prensa",
		"frases": [
			"La sala de prensa. Te presentan hoy mismo: tres preguntas, y cada palabra se guarda.",
		],
		"prensa": true},
	{"clave": "comedor", "planta": 2, "zona": "Comedor del plantel", "saluda": "cocinera",
		"saludo": "¡Por fin! Aquí se come a su hora, míster; el que no come, no corre.",
		"frases": [
			"El comedor del plantel. Come aquí los días de trabajo: cansado y con hambre se decide peor.",
			"Bajemos a la primera planta: falta lo más importante.",
		]},
	{"clave": "oficina", "planta": 1, "zona": "Oficina del DT",
		"frases": [
			"Y esta es tu oficina. Desde el ordenador llevas el club entero: plantilla, mercado, táctica, finanzas.",
			"Aquí mandas tú. Siéntate y enciende el PC cuando quieras; yo estaré por el edificio.",
		],
		"pc": true},
]

## La pregunta de la directiva (paso «presidente») y lo que cambia cada
## respuesta: la confianza de la directiva (`Directiva.confianza`) y una línea
## para «Qué pasa». Dos caminos honestos: ninguno es trampa.
const PREGUNTA_DIRECTIVA := {
	"quien": "presidente",
	"pregunta": "¿Qué podemos esperar de ti esta temporada?",
	"opciones": [
		{"texto": "Pelear arriba desde el primer día. Para eso me contrataron.", "confianza": 3, "tono": "ambicioso",
			"respuesta": "Me gusta oírlo. Pero cuidado: las promesas aquí se cobran."},
		{"texto": "Construir algo que dure. Primero el vestuario, luego la tabla.", "confianza": 1, "tono": "prudente",
			"respuesta": "Sensato. La junta valora la paciencia… mientras duren los resultados."},
	],
}

## Las tres preguntas de la presentación ante la prensa y los tres TONOS. Cada
## tono mueve la relación con los medios (`Prensa.relaciones`) y pone al DT un
## gesto distinto en el plató: seguro (manos abiertas), evasivo (mano al
## cuello), humilde (manos juntas).
const TONOS := [
	{"clave": "seguro", "nombre": "Seguro", "gesto": "abiertas", "relacion": 2},
	{"clave": "evasivo", "nombre": "Evasivo", "gesto": "cuello", "relacion": -2},
	{"clave": "humilde", "nombre": "Humilde", "gesto": "juntas", "relacion": 1},
]
const PREGUNTAS_PRENSA := [
	{"medio": "La Jornada Deportiva", "pregunta": "¿Por qué este club y por qué ahora?",
		"respuestas": {
			"seguro": "Porque aquí hay una plantilla con hambre y una afición que empuja. No vine a aprender: vine a ganar.",
			"evasivo": "Son muchas cosas. Ya habrá tiempo de hablar de eso cuando rueden los partidos.",
			"humilde": "Porque me llamaron y creí en el proyecto. Tengo mucho que aprender de esta casa.",
		}},
	{"medio": "Radio Tribuna", "pregunta": "¿Qué objetivo se marca para la primera temporada?",
		"respuestas": {
			"seguro": "Competir cada domingo y mirar arriba. Si no, no estaría sentado aquí.",
			"evasivo": "Los objetivos los pone el club. Yo me centro en el próximo entrenamiento.",
			"humilde": "Hacer un equipo reconocible y que la gente salga orgullosa del estadio.",
		}},
	{"medio": "El Vestuario TV", "pregunta": "¿Habrá fichajes o cuenta con lo que hay?",
		"respuestas": {
			"seguro": "Primero conozco a los que están. Si falta algo, lo traeré; y el presidente lo sabe.",
			"evasivo": "Eso es cosa de la dirección deportiva. Yo entreno a quien me den.",
			"humilde": "Con lo que hay se puede hacer mucho. Si llega alguien, que sume al grupo.",
		}},
]

## El paso por su clave (o vacío).
static func paso(clave: String) -> Dictionary:
	for p: Dictionary in PASOS:
		if String(p["clave"]) == clave:
			return p
	return {}

## Índice del paso con esa clave (−1 si no existe).
static func indice(clave: String) -> int:
	for i in PASOS.size():
		if String(PASOS[i]["clave"]) == clave:
			return i
	return -1

## El saludo del personal de la sala (o vacío): [clave del puesto, frase traducida].
static func saludo_de(p: Dictionary) -> Array:
	if String(p.get("saluda", "")) == "":
		return []
	return [String(p["saluda"]), Idiomas.t(String(p.get("saludo", "")))]

## Las frases de un paso ya traducidas y con el nombre del mentor puesto.
static func frases_de(p: Dictionary, nombre_mentor: String) -> Array[String]:
	var salida: Array[String] = []
	for f: String in p.get("frases", []):
		var t := Idiomas.t(f)
		salida.append(t % nombre_mentor if "%s" in t else t)
	return salida

## La tarjeta de control de un paso: «Moverse  W A S D / stick»… con las teclas
## reales del jugador (`Mando.corto_de`). Vacía si el paso no enseña nada.
static func tarjeta_controles(p: Dictionary) -> Array[String]:
	var salida: Array[String] = []
	for accion: String in p.get("controles", []):
		match accion:
			"mover":
				salida.append("%s  ·  W A S D / %s" % [Idiomas.t("Moverse"), Idiomas.t("stick izquierdo")])
			"correr":
				salida.append("%s  ·  %s" % [Idiomas.t("Correr"), Idiomas.t("Mayús / gatillo derecho")])
			"usar":
				salida.append("%s  ·  E / %s" % [Idiomas.t("Usar o hablar"), String(Mando.NOMBRE_BOTON.get(JOY_BUTTON_X, "X"))])
	return salida
