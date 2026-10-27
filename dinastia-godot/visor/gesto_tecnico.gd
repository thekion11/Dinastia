class_name GestoTecnico
extends RefCounted
## CADA GESTO CON SU HABILIDAD Y SU CLIMA (pedido del dueño, 27-10-2026). Hasta hoy todos los tiros se medían
## con el «tiro» del jugador y todos los pases con su «pase», fuera un raso, una rosca, una vaselina, un
## cañonazo, un pase al hueco o un centro; el pie malo no existía en el césped, y llover o nevar solo se veía.
## Ahora:
##   · cada tipo de tiro y de pase pesa SUS atributos (la rosca pide pase y regate; el cañonazo, físico);
##   · golpear con la pierna débil cuesta según sus estrellas (`Jugador.pierna_debil`, 1 a 5);
##   · el clima del partido (`Clima`, la clave de `Partido.clima_info`) cambia el error, el agarre del
##     portero y lo que rueda el balón: con lluvia el césped está rápido y resbala; con nieve, pesado.
## `m` es el `MotorJugable` (sin tipo: lo llaman sus capas).

## Atributos que pesa cada gesto (suman 1). Los atributos del motor van de 0,15 a 1 (`_atributos`).
const TIROS := {
	"": {"tir": 1.0},
	"rosca": {"tir": 0.5, "pas": 0.3, "reg": 0.2},
	"vaselina": {"reg": 0.45, "tir": 0.35, "pas": 0.2},
	"raso": {"tir": 0.7, "pas": 0.3},
	"potente": {"tir": 0.55, "fis": 0.45},
	"cabeza": {"tir": 0.4, "fis": 0.6},
}
const PASES := {
	"corto": {"pas": 1.0},
	"tenso": {"pas": 0.7, "tir": 0.3},
	"hueco": {"pas": 0.7, "reg": 0.3},
	"largo": {"pas": 0.6, "tir": 0.2, "fis": 0.2},
}
## Por cada estrella que le falta a la pierna débil (de 5), el error crece esto.
const PIE_MALO_POR_ESTRELLA := 0.12
## Por clima: [error de tiro y pase, error de lo que va por el aire, agarre del portero, roce del balón al rodar].
const CLIMA := {
	"lluvia": [1.08, 1.06, 0.8, 0.78],
	"tormenta": [1.12, 1.2, 0.72, 0.75],
	"nieve": [1.12, 1.1, 0.85, 1.35],
	"niebla": [1.04, 1.12, 0.95, 1.0],
}

## La habilidad (0..1) del jugador para un gesto: la media pesada de sus atributos.
static func habilidad(p: Dictionary, pesos: Dictionary) -> float:
	var a: Dictionary = p["attr"]
	var h := 0.0
	for k: String in pesos:
		h += float(a.get(k, a.get("tir", 0.6))) * float(pesos[k])
	return h

static func tiro(p: Dictionary, tipo: String) -> float:
	return habilidad(p, TIROS.get(tipo, TIROS[""]))

static func clase_pase(largo: bool, al_hueco: bool, tenso: bool) -> String:
	return "hueco" if al_hueco else ("largo" if largo else ("tenso" if tenso else "corto"))

static func pase(p: Dictionary, largo: bool, al_hueco: bool, tenso: bool) -> float:
	return habilidad(p, PASES[clase_pase(largo, al_hueco, tenso)])

## ¿Golpea hacia `destino` con la pierna débil? Si el destino le queda del lado de su pie malo más de 25°
## respecto a hacia dónde mira, se perfila con ese pie (el diestro que dispara cruzado a su izquierda).
static func con_pie_malo(p: Dictionary, desde: Vector3, destino: Vector3) -> bool:
	var nd: Node3D = p.get("node")
	if nd == null:
		return false
	var fwd := Vector3(sin(nd.rotation.y), 0.0, cos(nd.rotation.y))
	var hacia := Vector3(destino.x - desde.x, 0.0, destino.z - desde.z).normalized()
	var giro := fwd.signed_angle_to(hacia, Vector3.UP)   ## > 0: a su izquierda
	var zurdo := String(p.get("pie", "D")) == "I"
	return (giro > deg_to_rad(25.0) and not zurdo) or (giro < -deg_to_rad(25.0) and zurdo)

## El multiplicador del error por el pie con el que golpea (1 si es su pie bueno).
static func factor_pie(p: Dictionary, desde: Vector3, destino: Vector3) -> float:
	if not con_pie_malo(p, desde, destino):
		return 1.0
	return 1.0 + float(5 - clampi(int(p.get("pierna_debil", 3)), 1, 5)) * PIE_MALO_POR_ESTRELLA

static func _fila(m: Object) -> Array:
	return CLIMA.get(String(m.get("clima")), [1.0, 1.0, 1.0, 1.0])

## El multiplicador del error de un tiro o un pase por el clima; `por_el_aire`: vaselina, pase largo o bombeado.
static func factor_clima(m: Object, por_el_aire: bool) -> float:
	var f := _fila(m)
	return float(f[0]) * (float(f[1]) if por_el_aire else 1.0)

## Cuánto se le resbala al portero (multiplica su probabilidad de blocar en vez de rechazar).
static func agarre(m: Object) -> float:
	return float(_fila(m)[2])

## Fija el clima del partido en el motor (la clave de `Clima`: dia, tarde, noche, lluvia, nieve, niebla, tormenta).
static func fijar_clima(m: Object, clave: String) -> void:
	m.set("clima", clave)
	m.set("_roce_clima", float(CLIMA.get(clave, [1.0, 1.0, 1.0, 1.0])[3]))
