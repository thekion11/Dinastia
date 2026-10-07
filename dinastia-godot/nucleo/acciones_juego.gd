class_name AccionesJuego
extends RefCounted
## EL CATÁLOGO DE ACCIONES DEL JUGADOR (26-9-2026). La base para dos cosas que
## vendrán: una IA que JUEGA en vez de elegir jugadas prehechas y el control con
## mando. Las dos necesitan lo mismo: saber qué puede hacer un futbolista, con qué
## botón, con qué animación y con qué probabilidad le sale según sus atributos.
##
## Cada acción:
##   nombre   lo que ve el jugador
##   tipo     con_balon / sin_balon / portero
##   pesos    qué atributos mandan (rit/tir/pas/reg/def/fis; en el portero
##            div/par/saq/ref/vel/pos)
##   dificultad  cuánto cuesta de base (0 fácil, 40 muy difícil)
##   alcance  metros hasta donde tiene sentido
##   boton    acción del InputMap (ver `Mando`; el mismo botón cambia de
##            significado con y sin balón)
##   anim     categoría de `AnimExtra.CATEGORIAS` que la representa
##   pie      si se golpea con un pie (entra la pierna débil)

const CATALOGO := {
	"pase_corto": {"nombre": "Pase corto", "tipo": "con_balon", "pesos": {"pas": 0.8, "reg": 0.2}, "dificultad": 0.0, "alcance": 22.0, "boton": "jugar_pase", "anim": "pase", "pie": true},
	"pase_largo": {"nombre": "Pase largo", "tipo": "con_balon", "pesos": {"pas": 0.75, "fis": 0.25}, "dificultad": 14.0, "alcance": 55.0, "boton": "jugar_pase_largo", "anim": "patear", "pie": true},
	"pase_filtrado": {"nombre": "Pase al hueco", "tipo": "con_balon", "pesos": {"pas": 0.9, "reg": 0.1}, "dificultad": 18.0, "alcance": 35.0, "boton": "jugar_filtrado", "anim": "pase", "pie": true},
	"centro": {"nombre": "Centro", "tipo": "con_balon", "pesos": {"pas": 0.7, "tir": 0.3}, "dificultad": 12.0, "alcance": 45.0, "boton": "jugar_centro", "anim": "patear", "pie": true},
	"tiro": {"nombre": "Tiro", "tipo": "con_balon", "pesos": {"tir": 0.85, "fis": 0.15}, "dificultad": 10.0, "alcance": 30.0, "boton": "jugar_tiro", "anim": "patear", "pie": true},
	"tiro_colocado": {"nombre": "Tiro colocado", "tipo": "con_balon", "pesos": {"tir": 0.7, "pas": 0.3}, "dificultad": 14.0, "alcance": 22.0, "boton": "jugar_tiro", "anim": "patear", "pie": true},
	"tiro_lejano": {"nombre": "Disparo lejano", "tipo": "con_balon", "pesos": {"tir": 0.7, "fis": 0.3}, "dificultad": 26.0, "alcance": 35.0, "boton": "jugar_tiro", "anim": "patear", "pie": true},
	"cabezazo": {"nombre": "Cabezazo", "tipo": "con_balon", "pesos": {"fis": 0.6, "tir": 0.4}, "dificultad": 16.0, "alcance": 14.0, "boton": "jugar_tiro", "anim": "cabezazo", "pie": false},
	"regate": {"nombre": "Regate", "tipo": "con_balon", "pesos": {"reg": 0.75, "rit": 0.25}, "dificultad": 12.0, "alcance": 3.0, "boton": "jugar_regate", "anim": "regate", "pie": false},
	"conducir": {"nombre": "Conducir", "tipo": "con_balon", "pesos": {"reg": 0.5, "rit": 0.5}, "dificultad": 0.0, "alcance": 0.0, "boton": "", "anim": "conducir", "pie": false},
	"proteger": {"nombre": "Proteger el balón", "tipo": "con_balon", "pesos": {"fis": 0.7, "reg": 0.3}, "dificultad": 4.0, "alcance": 0.0, "boton": "jugar_regate", "anim": "conducir", "pie": false},
	"sprint": {"nombre": "Sprint", "tipo": "sin_balon", "pesos": {"rit": 1.0}, "dificultad": 0.0, "alcance": 0.0, "boton": "jugar_sprint", "anim": "", "pie": false},
	"desmarque": {"nombre": "Desmarque", "tipo": "sin_balon", "pesos": {"rit": 0.5, "pas": 0.2, "reg": 0.3}, "dificultad": 0.0, "alcance": 0.0, "boton": "jugar_pedir", "anim": "pedir_balon", "pie": false},
	"presionar": {"nombre": "Presionar", "tipo": "sin_balon", "pesos": {"def": 0.5, "rit": 0.3, "fis": 0.2}, "dificultad": 0.0, "alcance": 6.0, "boton": "jugar_pase", "anim": "defender", "pie": false},
	"entrada": {"nombre": "Entrada", "tipo": "sin_balon", "pesos": {"def": 0.8, "fis": 0.2}, "dificultad": 8.0, "alcance": 1.8, "boton": "jugar_tiro", "anim": "defender", "pie": false},
	"entrada_barrida": {"nombre": "Barrida", "tipo": "sin_balon", "pesos": {"def": 0.7, "rit": 0.3}, "dificultad": 16.0, "alcance": 3.0, "boton": "jugar_centro", "anim": "defender", "pie": false},
	"interceptar": {"nombre": "Interceptar", "tipo": "sin_balon", "pesos": {"def": 0.7, "rit": 0.3}, "dificultad": 10.0, "alcance": 2.5, "boton": "", "anim": "defender", "pie": false},
	"despejar": {"nombre": "Despejar", "tipo": "sin_balon", "pesos": {"def": 0.6, "fis": 0.4}, "dificultad": 4.0, "alcance": 2.0, "boton": "jugar_tiro", "anim": "patear", "pie": true},
	"atajar": {"nombre": "Atajar", "tipo": "portero", "pesos": {"div": 0.4, "ref": 0.4, "pos": 0.2}, "dificultad": 0.0, "alcance": 0.0, "boton": "", "anim": "atajar", "pie": false},
	"salida": {"nombre": "Salida del portero", "tipo": "portero", "pesos": {"vel": 0.5, "par": 0.3, "pos": 0.2}, "dificultad": 10.0, "alcance": 16.0, "boton": "jugar_pase_largo", "anim": "atajar", "pie": false},
	"saque_portero": {"nombre": "Saque del portero", "tipo": "portero", "pesos": {"saq": 1.0}, "dificultad": 6.0, "alcance": 60.0, "boton": "jugar_pase_largo", "anim": "patear", "pie": true},
}

## Lo que se usa cuando el portero hace de jugador de campo (o al revés).
## Dónde está el 50 % de la curva de éxito (calibrado con `MotorLibre`: con
## 35, un equipo de media 77 acierta ~85 % de pases y uno de 56 ~65 %).
const CENTRO := 35.0

const EQUIVALENTE_PORTERO := {"rit": "vel", "tir": "saq", "pas": "saq", "reg": "pos", "def": "pos", "fis": "par"}
const EQUIVALENTE_CAMPO := {"div": "fis", "par": "def", "saq": "pas", "ref": "rit", "vel": "rit", "pos": "def"}

static func existe(accion: String) -> bool:
	return CATALOGO.has(accion)

static func de_tipo(tipo: String) -> Array:
	var r: Array = []
	for k: String in CATALOGO:
		if String(CATALOGO[k]["tipo"]) == tipo:
			r.append(k)
	return r

## Un atributo, traduciéndolo si el jugador es portero (o si no lo es).
static func atributo(j: Jugador, clave: String) -> float:
	if j.atributos.has(clave):
		return float(j.atributos[clave])
	var otro := String((EQUIVALENTE_PORTERO if j.pos == "POR" else EQUIVALENTE_CAMPO).get(clave, ""))
	if otro != "" and j.atributos.has(otro):
		return float(j.atributos[otro]) * (0.6 if j.pos == "POR" else 0.4)
	return float(j.ovr) * 0.5

## Lo buena que es la ejecución del jugador en esa acción (0-100), antes del
## contexto: sus atributos ponderados, con la forma y la moral encima.
static func calidad(j: Jugador, accion: String) -> float:
	var d: Dictionary = CATALOGO.get(accion, {})
	if d.is_empty():
		return 0.0
	var suma := 0.0
	var pesos: Dictionary = d["pesos"]
	for k: String in pesos:
		suma += atributo(j, k) * float(pesos[k])
	## La forma y la moral mueven hasta ±5 puntos; el cansancio resta.
	suma += (float(j.forma) - 60.0) * 0.08 + (float(j.moral) - 70.0) * 0.05
	suma -= maxf(0.0, 70.0 - float(j.fisico)) * 0.15
	return clampf(suma, 1.0, 99.0)

## PROBABILIDAD DE QUE SALGA BIEN (0-1). `ctx`:
##   dist       metros del pase o del tiro
##   presion    0 solo, 1 encima
##   pie_malo   si la golpea con la pierna débil
##   rival      calidad del que se opone (duelos: regate contra entrada)
##   bono       multiplicador del club (táctica, maestrías, árbol del DT)
static func prob_exito(j: Jugador, accion: String, ctx: Dictionary = {}) -> float:
	var d: Dictionary = CATALOGO.get(accion, {})
	if d.is_empty():
		return 0.0
	## El bono del club (maestrías, árbol del DT, táctica) suma puntos: +20 %
	## son +6 de calidad. Multiplicarlo entero disparaba las diferencias.
	var q := calidad(j, accion) + (float(ctx.get("bono", 1.0)) - 1.0) * 30.0
	q -= float(d["dificultad"])
	var alcance := float(d["alcance"])
	var dist := float(ctx.get("dist", 0.0))
	if alcance > 0.0 and dist > 0.0:
		q -= 30.0 * pow(dist / alcance, 2.0)
	q -= 12.0 * float(ctx.get("presion", 0.0))
	if bool(d["pie"]) and bool(ctx.get("pie_malo", false)):
		q -= float(5 - j.pierna_debil()) * 6.0
	## En un duelo (regate contra entrada) cuenta la DIFERENCIA con el rival,
	## no el nivel absoluto: dos iguales se reparten los duelos.
	if ctx.has("rival"):
		q = CENTRO + (q + float(d["dificultad"]) - float(ctx["rival"])) * 0.5 - float(d["dificultad"]) * 0.5
	## Logística centrada en CENTRO y suave (12): un 35 "limpio" sale la mitad
	## de las veces y 20 puntos de diferencia no convierten un partido en paliza.
	return clampf(1.0 / (1.0 + exp(-(q - CENTRO) / 12.0)), 0.02, 0.98)

## ¿Con qué pie le llega? Si el balón le cae a la banda de su pierna débil, la
## usa según su nota: un 5 estrellas casi siempre se la acomoda a la buena.
static func usa_pie_malo(j: Jugador, lado_izquierdo: bool, rng: RandomNumberGenerator) -> bool:
	var zurdo := j.pie() == "I"
	if lado_izquierdo == zurdo:
		return false
	return rng.randf() > 0.2 * float(j.pierna_debil())

## Probabilidad de gol de un disparo (el "xG"): distancia y ángulo a portería.
## `desde` en metros con la portería en (0, 0) y el campo hacia +x.
static func xg(desde: Vector2) -> float:
	## El ángulo de portería que se ve desde ahí, al cuadrado: ~0,25 desde el
	## punto de penal en jugada, ~0,08 desde 20 m, ~0,03 desde 30 m.
	var d := desde.length()
	var angulo := absf(atan2(3.66, d) * 2.0 * cos(atan2(desde.y, desde.x)))
	return clampf(0.6 * angulo * angulo, 0.005, 0.75)
