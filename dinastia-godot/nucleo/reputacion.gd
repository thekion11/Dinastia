class_name Reputacion
extends RefCounted
## EL SISTEMA DE REPUTACIÓN (26-9-2026). Pedido del usuario: *"lo del sistema de
## reputación"*, de las listas de ideas: "historial de decisiones que define tu
## reputación" (48), "sistema de niveles de reputación del club" (281),
## "desbloqueo de instalaciones por hitos" (284), "sponsors premium por
## reputación" (285), "bonificación reputacional por operaciones rentables"
## (608), "reputación limpia como ventaja en negociaciones" (628), "reputación
## profesional que abre o cierra puertas" (706) e "índice de reputación social
## del club" (769).
##
## Hasta hoy la reputación era UN número del club (`Club.rep`) y otro tuyo
## (`Roles.prestigio`). Ahora hay dos cosas más:
##
## 1. LOS NIVELES DEL CLUB, de Local a Leyenda, según `Club.rep`. Cada nivel
##    abre algo concreto: hasta qué nivel se pueden construir las
##    instalaciones y qué patrocinadores te llaman (los premium pagan más).
##
## 2. TU PERFIL, siete facetas que se mueven con lo que HACES, no con lo que
##    dices: ganar (Ganador), subir canteranos (Formador), vender bien
##    (Negociador), jugar limpio (Honesto), dar la cara ante la prensa
##    (Mediático), quedarte (Leal) y el trabajo con la comunidad (Social). Cada
##    movimiento queda anotado con su motivo, y cada faceta alta o baja se nota
##    en un número del juego (ver `efectos()`).

signal cambio(titulo: String, texto: String)

## [desde (rep del club), nombre, icono, tope de instalaciones, multiplicador de patrocinio]
const NIVELES := [
	[0, "Local", "🏘️", 4, 1.00],
	[35, "Regional", "🗺️", 6, 1.05],
	[52, "Nacional", "🏳️", 8, 1.12],
	[68, "Continental", "🌎", 10, 1.22],
	[80, "Mundial", "🌍", 10, 1.35],
	[90, "Leyenda", "👑", 10, 1.50],
]

## faceta -> [nombre, icono, qué hace alta]
const FACETAS := {
	"ganador": ["Ganador", "🏆", "Los jugadores quieren venir a tu equipo"],
	"formador": ["Formador", "🌱", "Tus canteranos progresan más"],
	"negociador": ["Negociador", "🤝", "Te pagan más por tus jugadores"],
	"honesto": ["Juego limpio", "⚖️", "Los clubes te piden menos en los traspasos"],
	"mediatico": ["Mediático", "🎙️", "Las marcas te ofrecen más"],
	"leal": ["Leal", "🛡️", "La directiva te tiene más paciencia"],
	"social": ["Social", "🤲", "El club gana socios cada temporada"],
}

var facetas: Dictionary = {}
var historial: Array[Dictionary] = []   ## {anio, sem, faceta, delta, motivo}
var nivel_visto := -1                   ## último nivel del club anunciado

func _init() -> void:
	for f: String in FACETAS:
		facetas[f] = 50

func valor(f: String) -> int:
	return int(facetas.get(f, 50))

## Mueve una faceta y anota el motivo. Las facetas van de 0 a 100 y cuesta más
## moverlas cerca de los extremos (una reputación hecha es difícil de cambiar).
func registrar(f: String, delta: int, motivo: String, anio: int = 0, sem: int = 0) -> void:
	if not FACETAS.has(f) or delta == 0:
		return
	var v := valor(f)
	var d := delta
	if (d > 0 and v > 80) or (d < 0 and v < 20):
		d = int(signf(float(d)) * maxf(1.0, absf(float(d)) * 0.5))
	var nuevo := clampi(v + d, 0, 100)
	facetas[f] = nuevo
	historial.push_front({"anio": anio, "sem": sem, "faceta": f, "delta": nuevo - v, "motivo": motivo})
	if historial.size() > 40:
		historial.pop_back()
	## Cruzar el 70 o el 30 es noticia: ahí empieza a notarse.
	var nombre := String(FACETAS[f][0])
	if v < 70 and nuevo >= 70:
		cambio.emit("%s Reputación: %s" % [String(FACETAS[f][1]), nombre], "Ya te conocen así. %s." % String(FACETAS[f][2]))
	elif v >= 30 and nuevo < 30:
		cambio.emit("%s Reputación en baja: %s" % [String(FACETAS[f][1]), nombre], "Tu fama como «%s» está por los suelos y se empieza a notar." % nombre.to_lower())

## Lo que define tu reputación en una frase: la faceta más alta y la más baja.
func titular() -> String:
	var alta := "ganador"
	var baja := "ganador"
	for f: String in FACETAS:
		if valor(f) > valor(alta):
			alta = f
		if valor(f) < valor(baja):
			baja = f
	if valor(alta) < 60:
		return "Todavía sin fama definida"
	var t := "Te conocen como %s" % String(FACETAS[alta][0]).to_lower()
	if valor(baja) < 40:
		t += ", aunque dicen que te falta %s" % String(FACETAS[baja][0]).to_lower()
	return t

## ---------------------------------------------------------------- EFECTOS
## Todos van del -10 % al +10 % aprox., proporcionales a lo lejos que esté la
## faceta de 50: una reputación neutra no cambia nada.

func _desvio(f: String) -> float:
	return float(valor(f) - 50) / 50.0

## Se suma a las ganas de venir de un jugador (`Mercado.deseo_de_venir`).
func bono_fichajes() -> float:
	return 0.08 * _desvio("ganador")

## Multiplica las ofertas de marcas (`Roles.multiplicador_sponsor`).
func mult_marcas() -> float:
	return 1.0 + 0.10 * _desvio("mediatico")

## Multiplica el progreso de los canteranos (`Cantera.multiplicador_de_reputacion`).
func mult_cantera() -> float:
	return 1.0 + 0.10 * _desvio("formador")

## Multiplica lo que te ofrecen por tus jugadores.
func mult_ventas() -> float:
	return 1.0 + 0.08 * _desvio("negociador")

## Multiplica lo que te piden los otros clubes (juego limpio: te piden menos).
func mult_compras() -> float:
	return 1.0 - 0.08 * _desvio("honesto")

## Socios que se ganan (o pierden) cada temporada por la faceta social.
func socios_por_temporada(c: Club) -> int:
	if c == null:
		return 0
	return int(round(float(c.socios) * 0.04 * _desvio("social")))

## Semanas extra de paciencia de la directiva (lealtad).
func paciencia_extra() -> int:
	return int(round(4.0 * _desvio("leal")))

## ---------------------------------------------------------------- NIVELES

static func nivel_de(rep: int) -> int:
	var n := 0
	for i in NIVELES.size():
		if rep >= int(NIVELES[i][0]):
			n = i
	return n

static func nombre_nivel(rep: int) -> String:
	var fila: Array = NIVELES[nivel_de(rep)]
	return "%s %s" % [String(fila[2]), String(fila[1])]

## Hasta qué nivel se puede construir cualquier instalación.
static func tope_instalaciones(rep: int) -> int:
	return int(NIVELES[nivel_de(rep)][3])

## Multiplicador de los patrocinadores (los premium solo llaman arriba).
static func mult_patrocinio(rep: int) -> float:
	return float(NIVELES[nivel_de(rep)][4])

## Cuánto falta (0-1) para el siguiente nivel.
static func progreso(rep: int) -> float:
	var n := nivel_de(rep)
	if n >= NIVELES.size() - 1:
		return 1.0
	var desde := float(NIVELES[n][0])
	var hasta := float(NIVELES[n + 1][0])
	return clampf((float(rep) - desde) / (hasta - desde), 0.0, 1.0)

## Lo que da cada nivel, en texto.
static func beneficios(n: int) -> Array[String]:
	var fila: Array = NIVELES[clampi(n, 0, NIVELES.size() - 1)]
	var r: Array[String] = []
	r.append("Instalaciones hasta el nivel %d" % int(fila[3]))
	if float(fila[4]) > 1.0:
		r.append("Patrocinadores premium: +%d %% en las ofertas" % int(round((float(fila[4]) - 1.0) * 100.0)))
	else:
		r.append("Solo patrocinadores locales")
	return r

## Anuncia si el club cambió de nivel desde la última vez.
func revisar_nivel(c: Club) -> void:
	if c == null:
		return
	var n := nivel_de(c.rep)
	if nivel_visto < 0:
		nivel_visto = n
		return
	if n > nivel_visto:
		var fila: Array = NIVELES[n]
		cambio.emit("%s El club sube a nivel %s" % [String(fila[2]), String(fila[1])],
			"La reputación del club creció: %s." % ", ".join(beneficios(n)).to_lower())
	elif n < nivel_visto:
		cambio.emit("📉 El club baja a nivel %s" % String(NIVELES[n][1]),
			"La reputación del club cayó. Los patrocinadores premium miran hacia otro lado.")
	nivel_visto = n

func a_dic() -> Dictionary:
	return {"facetas": facetas.duplicate(), "historial": historial.duplicate(true), "nivel_visto": nivel_visto}

func desde_dic(d: Dictionary) -> void:
	for f: String in FACETAS:
		facetas[f] = int((d.get("facetas", {}) as Dictionary).get(f, 50))
	historial.clear()
	for h: Variant in d.get("historial", []):
		if h is Dictionary:
			historial.append(h)
	nivel_visto = int(d.get("nivel_visto", -1))
