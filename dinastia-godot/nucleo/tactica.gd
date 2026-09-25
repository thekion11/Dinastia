class_name Tactica
extends RefCounted
## La pizarra: formacion y las seis perillas que mueven el partido.
##
## Los multiplicadores son EXACTAMENTE los del HTML (`fuerzaEquipo`). Cada uno de
## esos tres numeros -por ejemplo [0.88, 1, 1.12] para la mentalidad- esta
## calibrado: subir el ataque siempre baja la defensa en la misma proporcion, que
## es lo que impide que exista una tactica "gratis" que gane siempre.

enum Mentalidad { DEFENSIVA, EQUILIBRADA, OFENSIVA }
enum Nivel { BAJO, MEDIO, ALTO }

var formacion: String = "4-3-3"
var mentalidad: int = Mentalidad.EQUILIBRADA
var presion: int = Nivel.MEDIO
var ritmo: int = Nivel.MEDIO
var linea: int = Nivel.MEDIO
var amplitud: int = Nivel.MEDIO
var salida_corta: bool = false
var marca_al_hombre: bool = false
var fuera_de_juego: bool = false
var tiro_lejano: bool = false

const _MENT_ATA := [0.88, 1.0, 1.12]
const _MENT_DEF := [1.10, 1.0, 0.90]
const _PRES_ATA := [0.97, 1.0, 1.05]
const _RITMO_ATA := [0.95, 1.0, 1.07]
const _RITMO_DEF := [1.05, 1.0, 0.95]
const _LINEA_ATA := [0.96, 1.0, 1.06]
const _LINEA_DEF := [1.06, 1.0, 0.93]
const _AMPL_ATA := [0.98, 1.0, 1.04]
const _AMPL_DEF := [1.03, 1.0, 0.98]

func multiplicador_ataque() -> float:
	var m: float = _MENT_ATA[mentalidad] * _PRES_ATA[presion] * _RITMO_ATA[ritmo] * _LINEA_ATA[linea] * _AMPL_ATA[amplitud]
	if salida_corta: m *= 1.03
	if marca_al_hombre: m *= 0.98
	if tiro_lejano: m *= 1.02
	return m

func multiplicador_defensa() -> float:
	var m: float = _MENT_DEF[mentalidad] * _RITMO_DEF[ritmo] * _LINEA_DEF[linea] * _AMPL_DEF[amplitud]
	if marca_al_hombre: m *= 1.03
	if fuera_de_juego: m *= 1.06
	return m

func duplicar() -> Tactica:
	var t := Tactica.new()
	t.formacion = formacion
	t.mentalidad = mentalidad
	t.presion = presion
	t.ritmo = ritmo
	t.linea = linea
	t.amplitud = amplitud
	t.salida_corta = salida_corta
	t.marca_al_hombre = marca_al_hombre
	t.fuera_de_juego = fuera_de_juego
	t.tiro_lejano = tiro_lejano
	return t

# ---------------------------------------------------------------------------
#  JUGADAS ENSAYADAS Y PLANES SEGÚN EL MARCADOR (`vTacticaAvanzada()`)
# ---------------------------------------------------------------------------
#
# Las jugadas de balón parado no son un adorno: su efectividad depende de si
# TIENES gente con la habilidad que pide cada una. Elegir "todos al área" sin un
# cabeceador es tirar los córners a la nada, y el juego tiene que dejar que se
# note esa diferencia.
#
# Los PLANES son la otra mitad: qué hacer cuando vas perdiendo y qué cuando vas
# ganando. Sin ellos, el entrenador que se levanta a mitad de partido y el que
# no toca nada juegan igual.

## clave, nombre, explicación, habilidades que la hacen buena.
const CORNERS := [
	["area", "Todos al área", "Máximo volumen: el que gana por arriba manda", ["cabezazo"]],
	["corto", "Córner en corto", "Sacar al rival de su zona y buscar el centro atrás", ["pasePro", "corner"]],
	["primer", "Al primer palo", "Peinada y confusión en el área chica", ["corner"]],
	["segundo", "Al segundo palo", "Buscar al que llega solo por detrás", ["cabezazo", "corner"]],
	["borde", "Atrás, al borde del área", "Para el que pega de media distancia", ["latigo"]],
]
const LIBRES := [
	["directo", "Tiro directo", "Buscar la portería sin más", ["tiroLibre", "latigo"]],
	["centro", "Centro al área", "Colgarla al segundo palo", ["corner", "cabezazo"]],
	["ensayada", "Jugada ensayada", "Pase corto y remate desde ángulo distinto", ["pasePro", "tiroLibre"]],
	["bloqueo", "Bloqueo de barrera", "Un jugador tapa la visión del portero", ["tiroLibre"]],
]

## Los planes: qué cambia cuando el marcador va en tu contra o a favor.
const PLANES := [
	["nada", "No tocar nada", "El plan es el plan. A veces es lo mejor."],
	["ofensivo", "Ir a por el partido", "Mentalidad ofensiva y línea adelantada en cuanto vayas perdiendo."],
	["cerrojo", "Cerrar el partido", "Mentalidad defensiva y línea baja en cuanto vayas ganando."],
]

var corner: String = "area"
var libre: String = "directo"
var plan_perdiendo: String = "nada"
var plan_ganando: String = "nada"

static func def_corner(clave: String) -> Array:
	for f: Array in CORNERS:
		if String(f[0]) == clave:
			return f
	return CORNERS[0]

static func def_libre(clave: String) -> Array:
	for f: Array in LIBRES:
		if String(f[0]) == clave:
			return f
	return LIBRES[0]

## Cuánto rinde una jugada con el once que tienes. Es la cuenta del HTML:
## cuántos de los once tienen alguna de las habilidades que la jugada pide.
##
## Devuelve un factor alrededor de 1: por debajo, la jugada elegida no le va a
## este equipo; por encima, tienes justo a la gente para ella.
static func efectividad(once: Array, habilidades_pedidas: Array, entrenamiento) -> float:
	if once.is_empty() or entrenamiento == null:
		return 1.0
	var con := 0
	for j: Jugador in once:
		for h in entrenamiento.habilidades(j):
			if habilidades_pedidas.has(String(h)):
				con += 1
				break
	return clampf(0.82 + float(con) * 0.09, 0.82, 1.35)

## Qué mentalidad y línea toca según cómo va el marcador. La consulta quien
## dirige el partido; devuelve {} si no hay que tocar nada.
func plan_para(diferencia: int) -> Dictionary:
	var clave := ""
	if diferencia < 0:
		clave = plan_perdiendo
	elif diferencia > 0:
		clave = plan_ganando
	match clave:
		"ofensivo":
			return {"mentalidad": Mentalidad.OFENSIVA, "linea": Nivel.ALTO}
		"cerrojo":
			return {"mentalidad": Mentalidad.DEFENSIVA, "linea": Nivel.BAJO}
	return {}
