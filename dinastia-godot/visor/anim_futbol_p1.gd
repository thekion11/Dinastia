extends RefCounted
## (Parte 1 de 3 de `anim_futbol.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `anim_futbol.gd`, conserva la clase.)

## EL PORTAFOLIO DE FÚTBOL (26-9-2026). Pedido: *"agrega diferentes tipos de
## tiros (unos 20), tipos de pase (unos 20), tipos de barrida también 20, unas
## 6 atajadas más, unos 30 regates, movimientos expresivos, movimientos de
## lesión, y animar al árbitro para que haga su trabajo"*.
##
## Todo se escribe con POSES CLAVE en lenguaje de cuerpo, no de huesos. Cada
## clave es un diccionario con lo que cambia en ese instante:
##   t    segundos
##   p    cadera desplazada [derecha, arriba, adelante] (m)
##   g    giro de la cadera [adelante, rueda a la derecha, gira a la izquierda] (°)
##   tr   tronco [se dobla adelante, se inclina a la derecha, gira a la izquierda]
##   cu   cuello [abajo, gira a la izquierda]
##   pd / pi   pierna derecha / izquierda [flexión de cadera, rodilla, tobillo
##        (punta abajo), abducción (hacia fuera), rotación (hacia fuera)]
##   bd / bi   brazo [adelante, al costado (82 = en cruz), codo]
## Ejes medidos con `pruebas/sonda_piernas.gd` y `sonda_brazos.gd`:
##   - pelvis: X inclina adelante, Z rueda a la derecha, Y gira a la izquierda;
##   - columna y cuello: los mismos sentidos;
##   - muslo: Z abre la pierna derecha y CIERRA la izquierda (espejado), igual
##     que la rotación Y; `armar()` pone el signo por lado.
## Un canal que no aparece en ninguna clave se deja en reposo (piernas y tronco)
## o colgando (brazos), para no heredar la pose del clip anterior.
##
## Se construye una vez por esqueleto y se comparte entre los 22 jugadores.

const NEUTRO := {
	"p": [0.0, 0.0, 0.0], "g": [0.0, 0.0, 0.0], "tr": [0.0, 0.0, 0.0], "cu": [0.0, 0.0],
	"pd": [0.0, 6.4, 0.0, 0.0, 0.0], "pi": [0.0, 6.4, 0.0, 0.0, 0.0],
	"bd": [2.0, 6.0, 8.0], "bi": [2.0, 6.0, 8.0],
}

static var _cache: Dictionary = {}

## [nombre, parámetros]
const TIROS := [
	["tiro_empeine", {"arm_f": -45, "arm_r": 100, "imp_f": 75, "imp_r": 10, "tob": 35}],
	["tiro_colocado", {"arm_f": -35, "arm_r": 80, "imp_f": 55, "imp_r": 15, "tob": 5, "abd": 20, "rot": 30, "giro": 20}],
	["tiro_exterior", {"arm_f": -35, "arm_r": 85, "imp_f": 50, "imp_r": 20, "tob": 25, "abd": -15, "rot": -30, "giro": -15}],
	["tiro_puntera", {"dur": 0.7, "arm_f": -30, "arm_r": 70, "imp_f": 45, "imp_r": 5, "tob": -10}],
	["tiro_canonazo", {"dur": 1.0, "arm_f": -60, "arm_r": 120, "imp_f": 95, "imp_r": 5, "tob": 40, "tronco_arm": -18, "salto": 0.08}],
	["tiro_rastron", {"arm_f": -40, "arm_r": 95, "imp_f": 35, "imp_r": 10, "tob": 40, "tronco_imp": 18}],
	["vaselina", {"arm_f": -35, "arm_r": 90, "imp_f": 40, "imp_r": 40, "tob": -20, "tronco_arm": -15, "tronco_imp": -12}],
	["tiro_bombeado", {"arm_f": -45, "arm_r": 95, "imp_f": 80, "imp_r": 25, "tob": 10, "tronco_imp": -15}],
	["volea", {"arm_f": -20, "arm_r": 70, "imp_f": 90, "imp_r": 10, "tob": 30, "incl": -25, "abd": 50, "salto": 0.12, "tronco_imp": -10}],
	["media_volea", {"dur": 0.8, "arm_f": -35, "arm_r": 90, "imp_f": 70, "imp_r": 15, "tob": 30, "tronco_imp": 15}],
	["tiro_de_primera", {"dur": 0.6, "arm_f": -30, "arm_r": 80, "imp_f": 60, "imp_r": 12, "tob": 30}],
	["tiro_cayendo", {"arm_f": -40, "arm_r": 90, "imp_f": 60, "imp_r": 15, "tob": 30, "incl": 15, "caida": 45}],
	["media_vuelta", {"dur": 1.1, "giro_inicio": 150, "arm_f": -40, "arm_r": 90, "imp_f": 65, "imp_r": 12, "tob": 30}],
	["rabona", {"arm_f": -40, "arm_r": 100, "imp_f": 25, "imp_r": 60, "tob": 20, "abd": -35, "rot": -20, "giro": 30}],
	["tiro_sin_angulo", {"arm_f": -40, "arm_r": 90, "imp_f": 60, "imp_r": 15, "tob": 10, "abd": 25, "incl": 20, "giro": 35}],
	["tiro_carrera", {"dur": 0.8, "arm_f": -50, "arm_r": 110, "imp_f": 85, "imp_r": 8, "tob": 38, "salto": 0.1}],
	["tiro_rosca", {"arm_f": -40, "arm_r": 90, "imp_f": 70, "imp_r": 12, "tob": 15, "abd": 25, "rot": 35, "giro": 30, "incl": 10}],
	["tiro_seco", {"dur": 0.65, "arm_f": -25, "arm_r": 75, "imp_f": 40, "imp_r": 8, "tob": 35, "tronco_imp": 14}],
]

const PASES := [
	["pase_interior", {"dur": 0.7, "arm_f": -25, "arm_r": 60, "imp_f": 35, "imp_r": 20, "tob": 0, "abd": 25, "rot": 35}],
	["pase_largo", {"arm_f": -50, "arm_r": 100, "imp_f": 80, "imp_r": 15, "tob": 30, "tronco_arm": -12}],
	["pase_exterior", {"dur": 0.7, "arm_f": -25, "arm_r": 65, "imp_f": 30, "imp_r": 25, "tob": 20, "abd": -20, "rot": -35}],
	["pase_rabona", {"arm_f": -35, "arm_r": 95, "imp_f": 20, "imp_r": 55, "tob": 15, "abd": -30, "rot": -20, "giro": 25}],
	["globito", {"dur": 0.8, "arm_f": -30, "arm_r": 80, "imp_f": 45, "imp_r": 35, "tob": -15, "tronco_imp": -10}],
	["centro", {"arm_f": -50, "arm_r": 100, "imp_f": 85, "imp_r": 20, "tob": 20, "incl": 15, "giro": 30, "abd": 15}],
	["centro_rosca", {"arm_f": -50, "arm_r": 100, "imp_f": 75, "imp_r": 15, "tob": 15, "abd": 25, "rot": 30, "giro": 35}],
	["centro_raso", {"arm_f": -40, "arm_r": 90, "imp_f": 45, "imp_r": 15, "tob": 30, "tronco_imp": 15, "giro": 20}],
	["pase_filtrado", {"dur": 0.75, "arm_f": -30, "arm_r": 70, "imp_f": 45, "imp_r": 15, "tob": 5, "abd": 20, "rot": 30, "tronco_imp": 12}],
	["pase_primera", {"dur": 0.5, "arm_f": -20, "arm_r": 55, "imp_f": 30, "imp_r": 18, "tob": 0, "abd": 25, "rot": 35}],
	["cambio_frente", {"dur": 1.0, "arm_f": -55, "arm_r": 110, "imp_f": 85, "imp_r": 10, "tob": 30, "giro": 30, "tronco_arm": -15}],
	["pase_atras", {"dur": 0.8, "giro_inicio": -40, "arm_f": -25, "arm_r": 60, "imp_f": 30, "imp_r": 20, "abd": 25, "rot": 35}],
	["pase_cruzado", {"arm_f": -35, "arm_r": 85, "imp_f": 55, "imp_r": 18, "tob": 10, "abd": 30, "rot": 40, "giro": 30}],
	["trivela", {"arm_f": -35, "arm_r": 85, "imp_f": 55, "imp_r": 20, "tob": 30, "abd": -25, "rot": -40, "giro": -20}],
	["pase_bombeado", {"arm_f": -40, "arm_r": 95, "imp_f": 70, "imp_r": 30, "tob": 5, "tronco_imp": -12}],
	["pase_lateral", {"dur": 0.65, "arm_f": -15, "arm_r": 45, "imp_f": 25, "imp_r": 20, "abd": 40, "rot": 50}],
	["pase_empeine", {"dur": 0.6, "arm_f": -25, "arm_r": 70, "imp_f": 40, "imp_r": 15, "tob": 30}],
]

const BARRIDAS := [
	["barrida_frontal", {}],
	["barrida_lateral", {"lateral": 0.5, "rueda": 25}],
	["barrida_larga", {"dur": 1.6, "largo": 1.6}],
	["barrida_corta", {"dur": 1.0, "largo": 0.7}],
	["barrida_dos_pies", {"dos_pies": true, "alto_pie": 0.18}],
	["barrida_rapida", {"dur": 1.0, "levanta": 0.4}],
	["barrida_desesperada", {"dur": 1.6, "largo": 1.5, "tronco": -35, "levanta": 0.1}],
	["barrida_bloqueo", {"alto_pie": 0.3, "tronco": -35, "dos_pies": true}],
	["barrida_por_detras", {"dur": 1.4, "largo": 1.2, "alto_pie": 0.12, "levanta": 0.05}],
	["barrida_lateral_larga", {"dur": 1.5, "lateral": 1.0, "rueda": 35, "largo": 1.2}],
	["barrida_giro", {"dur": 1.4, "rueda": 40, "lateral": 0.3, "levanta": 0.35}],
	["barrida_alta", {"alto_pie": 0.4, "tronco": -30}],
]

# =============================================================================
#  REGATES
# =============================================================================
#
# Postura base de regate: rodillas dobladas, tronco un poco encima del balón,
# brazos abiertos para equilibrar. La cadera se mece hacia el lado del amago y
# sale hacia el otro.
const BASE := {"pd": [15.0, 30.0, 0.0, 0.0, 0.0], "pi": [15.0, 30.0, 0.0, 0.0, 0.0], "tr": [12.0, 0.0, 0.0],
	"bi": [8.0, 32.0, 28.0], "bd": [8.0, 32.0, 28.0], "p": [0.0, -0.06, 0.0]}

## En el partido el jugador ya avanza por su cuenta (lo mueve `MatchPlayback`):
## el desplazamiento de cadera de un regate se queda en un tercio para que no
## avance dos veces ni "salte" hacia atrás al terminar el clip.
const AVANCE_REGATE := 0.35

## Pose de pierna abreviada.
static func L(flex: float, rod: float = 6.4, tob: float = 0.0, abd: float = 0.0, rot: float = 0.0) -> Array:
	return [flex, rod, tob, abd, rot]

static func _canal(a: Animation, esq: Skeleton3D, pre: String, canal: String, ks: Array) -> void:
	match canal:
		"p":
			var kp: Array = []
			for k: Array in ks:
				var v: Array = k[1]
				kp.append([k[0], Vector3(-float(v[0]), float(v[1]), float(v[2]))])
			AnimQuaternius._pista_pos(a, esq, "cadera", kp, pre, false)
		"g":
			var kg: Array = []
			for k: Array in ks:
				var v: Array = k[1]
				kg.append([k[0], Vector3(float(v[0]), float(v[2]), float(v[1]))])
			AnimQuaternius._pista(a, esq, "cadera", kg, pre)
		"tr":
			var k1: Array = []
			var k2: Array = []
			for k: Array in ks:
				var v: Array = k[1]
				var r := Vector3(float(v[0]), float(v[2]), float(v[1])) * 0.5
				k1.append([k[0], r])
				k2.append([k[0], r])
			AnimQuaternius._pista(a, esq, "espalda1", k1, pre)
			AnimQuaternius._pista(a, esq, "espalda2", k2, pre)
		"cu":
			var kc: Array = []
			for k: Array in ks:
				var v: Array = k[1]
				kc.append([k[0], Vector3(float(v[0]), float(v[1]), 0.0)])
			AnimQuaternius._pista(a, esq, "cuello", kc, pre)
		"pd", "pi":
			var lado := "d" if canal == "pd" else "i"
			var s := 1.0 if lado == "d" else -1.0
			var km: Array = []
			var kr: Array = []
			var kt: Array = []
			for k: Array in ks:
				var v: Array = k[1]
				km.append([k[0], Vector3(-float(v[0]), float(v[4]) * s, float(v[3]) * s)])
				kr.append([k[0], Vector3(float(v[1]) - AnimQuaternius.RODILLA_REPOSO, 0, 0)])
				kt.append([k[0], Vector3(float(v[2]), 0, 0)])
			AnimQuaternius._pista(a, esq, "muslo_" + lado, km, pre)
			AnimQuaternius._pista(a, esq, "pierna_" + lado, kr, pre)
			AnimQuaternius._pista(a, esq, "pie_" + lado, kt, pre)
		"bd", "bi":
			var lado2 := "d" if canal == "bd" else "i"
			var kb: Array = []
			var kk: Array = []
			for k: Array in ks:
				var v: Array = k[1]
				kb.append([k[0], AnimExtra._brazo(lado2, float(v[0]), float(v[1]))])
				kk.append([k[0], AnimExtra._codo(lado2, float(v[2]))])
			AnimQuaternius._pista(a, esq, "brazo_" + lado2, kb, pre)
			AnimQuaternius._pista(a, esq, "antebrazo_" + lado2, kk, pre)

## Arma la animación a partir de las claves.
static func armar(esq: Skeleton3D, pre: String, dur: float, bucle: bool, claves: Array) -> Animation:
	var a := AnimQuaternius._nueva(dur, bucle)
	for canal: String in NEUTRO:
		var ks: Array = []
		for k: Dictionary in claves:
			if k.has(canal):
				ks.append([float(k["t"]), k[canal]])
		if ks.is_empty():
			ks = [[0.0, NEUTRO[canal]], [dur, NEUTRO[canal]]]
		else:
			if float(ks[0][0]) > 0.001:
				ks.push_front([0.0, NEUTRO[canal]])
			if float(ks[ks.size() - 1][0]) < dur - 0.001:
				ks.append([dur, ks[ks.size() - 1][1]])
		_canal(a, esq, pre, canal, ks)
	return a

# =============================================================================
#  GOLPEOS: TIROS Y PASES
# =============================================================================
#
# Un golpeo tiene tres tiempos: armar (la pierna atrás), impactar y acompañar.
# Lo que cambia de un tiro a otro: cuánto se arma, con qué parte del pie
# (empeine = tobillo en punta; interior = pierna abierta y rotada hacia fuera;
# exterior = cerrada y rotada hacia dentro), hasta dónde sube la pierna, cuánto
# se echa atrás o encima del balón el tronco y si hay salto.

static func golpeo(esq: Skeleton3D, pre: String, c: Dictionary) -> Animation:
	var d := float(c.get("dur", 0.9))
	var ta := d * 0.33
	var ti := d * 0.5
	var tf := d * 0.68
	var af := float(c.get("arm_f", -40.0))
	var ar := float(c.get("arm_r", 90.0))
	var imf := float(c.get("imp_f", 60.0))
	var imr := float(c.get("imp_r", 15.0))
	var tob := float(c.get("tob", 25.0))
	var abd := float(c.get("abd", 0.0))
	var rot := float(c.get("rot", 0.0))
	var tra := float(c.get("tronco_arm", -8.0))
	var tri := float(c.get("tronco_imp", 8.0))
	var inc := float(c.get("incl", 0.0))
	var gir := float(c.get("giro", 0.0))
	var salto := float(c.get("salto", 0.0))
	var baja := float(c.get("baja", 0.04))
	## EL GOLPEO CON CUERPO (29-9-2026, mapa de metas 16): el informe decía que
	## la patada "termina como una pose de salto". Faltaba todo lo que no es la
	## pierna: la cadera que avanza (la última zancada), la pelvis que se abre al
	## armar y se cierra al pegar, el brazo contrario abierto para equilibrar,
	## la pierna de apoyo clavada con la rodilla flexionada y, al acompañar, el
	## cuerpo que sube en puntillas y cae hacia delante.
	var claves: Array = [
		{"t": 0.0, "pd": L(12, 22), "pi": L(6, 16), "p": [0.0, -0.02, 0.0], "g": [0.0, 0.0, 0.0]},
		{"t": ta, "pd": L(af, ar + 12, 20, abd * 0.3, rot * 0.5), "pi": L(22, 30, 6),
			"p": [0.0, -baja - 0.02, 0.07], "tr": [tra, -inc * 0.4, -gir * 0.5 - 8],
			"g": [4.0, -3.0, -14.0],
			"bi": [34, 84, 30], "bd": [-40, 34, 24], "cu": [16, 6]},
		{"t": ti, "pd": L(imf * 0.55, imr * 0.6 + 8, tob, abd, rot), "pi": L(20, 34, 8),
			"p": [0.0, -baja - 0.03 + salto * 0.6, 0.14], "tr": [tri + 6, inc, gir + 6],
			"g": [8.0, 2.0, 10.0],
			"bi": [42, 80, 34], "bd": [-26, 38, 24], "cu": [26, 0]},
		{"t": tf, "pd": L(imf, imr, tob * 0.7, abd * 0.8, rot * 0.8), "pi": L(6, 12, 22),
			"p": [0.0, salto - baja * 0.5 + 0.03, 0.19], "tr": [tri * 0.7, inc * 0.7, gir * 0.8 + 8],
			"g": [2.0, 0.0, 14.0],
			"bi": [26, 60, 26], "bd": [4, 30, 20]},
		{"t": d, "pd": L(18, 20), "pi": L(4, 12), "p": [0.0, 0.0, 0.12], "tr": [2, 0, 0],
			"g": [0.0, 0.0, 4.0],
			"bi": [2, 8, 10], "bd": [2, 8, 10], "cu": [4, 0]},
	]
	if c.has("giro_inicio"):
		claves[0]["g"] = [0.0, 0.0, float(c["giro_inicio"])]
		claves[1]["g"] = [0.0, 0.0, float(c["giro_inicio"]) * 0.2]
		claves[2]["g"] = [0.0, 0.0, 0.0]
	if c.has("caida"):
		## Tiro cayendo: después del golpeo el cuerpo se va al suelo de costado.
		claves[4]["p"] = [0.15, -0.72, 0.35]
		claves[4]["g"] = [10.0, float(c["caida"]), 0.0]
		claves[4]["pi"] = L(40, 70, 10)
		claves[4]["bi"] = [30, 60, 30]
	return armar(esq, pre, d, false, claves)

## Tiros y pases especiales, a mano (no caben en el golpeo de tres tiempos).
static func chilena(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.5, false, [
		{"t": 0.0, "pd": L(10, 20), "pi": L(10, 20)},
		{"t": 0.25, "p": [0.0, 0.1, 0.0], "g": [-30, 0, 0], "pi": L(70, 60, 20), "pd": L(10, 30), "bi": [0, 60, 20], "bd": [0, 60, 20]},
		{"t": 0.5, "p": [0.0, 0.55, -0.1], "g": [-110, 0, 0], "pi": L(40, 30), "pd": L(120, 10, 30), "bi": [-20, 90, 10], "bd": [-20, 90, 10], "cu": [30, 0]},
		{"t": 0.7, "p": [0.0, 0.45, -0.2], "g": [-150, 0, 0], "pi": L(20, 20), "pd": L(60, 20, 20)},
		{"t": 1.0, "p": [0.0, -0.75, -0.4], "g": [-90, 0, 0], "pi": L(40, 40), "pd": L(40, 40), "bi": [-40, 60, 20], "bd": [-40, 60, 20], "cu": [20, 0]},
		{"t": 1.5, "p": [0.0, -0.78, -0.4], "g": [-88, 0, 0], "pi": L(45, 50), "pd": L(45, 50), "bi": [-30, 50, 20], "bd": [-30, 50, 20]},
	])

static func tijera(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.3, false, [
		{"t": 0.0, "pd": L(10, 20), "pi": L(10, 20)},
		{"t": 0.25, "p": [0.0, 0.2, 0.0], "g": [-20, -30, 0], "pi": L(80, 40, 20), "pd": L(-10, 60)},
		{"t": 0.45, "p": [0.0, 0.35, 0.0], "g": [-40, -60, 0], "pi": L(-10, 50), "pd": L(100, 10, 30), "bi": [0, 120, 10], "bd": [30, 40, 20]},
		{"t": 0.8, "p": [0.2, -0.7, 0.0], "g": [-20, -80, 0], "pi": L(30, 40), "pd": L(40, 30), "bi": [20, 60, 20], "bd": [20, 30, 20]},
		{"t": 1.3, "p": [0.2, -0.75, 0.0], "g": [-15, -82, 0], "pi": L(35, 45), "pd": L(40, 40)},
	])

static func palomita(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.3, false, [
		{"t": 0.0, "pd": L(15, 25), "pi": L(15, 25), "p": [0.0, -0.05, 0.0]},
		{"t": 0.2, "p": [0.0, -0.12, 0.2], "g": [30, 0, 0], "pd": L(40, 60), "pi": L(30, 50), "bi": [30, 20, 20], "bd": [30, 20, 20]},
		{"t": 0.45, "p": [0.0, -0.1, 1.0], "g": [80, 0, 0], "pd": L(-10, 20, 30), "pi": L(-10, 20, 30), "cu": [-50, 0], "bi": [80, 30, 10], "bd": [80, 30, 10]},
		{"t": 0.8, "p": [0.0, -0.8, 1.6], "g": [88, 0, 0], "pd": L(0, 20, 20), "pi": L(0, 20, 20), "bi": [70, 40, 30], "bd": [70, 40, 30], "cu": [-40, 0]},
		{"t": 1.3, "p": [0.0, -0.82, 1.7], "g": [88, 0, 0], "pd": L(0, 25, 20), "pi": L(0, 25, 20)},
	])

static func cabezazo_picado(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.0, false, [
		{"t": 0.0, "pd": L(15, 25), "pi": L(15, 25), "p": [0.0, -0.05, 0.0]},
		{"t": 0.3, "p": [0.0, 0.3, 0.05], "tr": [-25, 0, 0], "pd": L(40, 70, 10), "pi": L(10, 30, 20), "bi": [-20, 60, 20], "bd": [-20, 60, 20], "cu": [-20, 0]},
		{"t": 0.45, "p": [0.0, 0.32, 0.1], "tr": [40, 0, 0], "cu": [35, 0], "bi": [-30, 40, 20], "bd": [-30, 40, 20]},
		{"t": 0.75, "p": [0.0, -0.08, 0.2], "tr": [10, 0, 0], "pd": L(30, 50), "pi": L(30, 50)},
		{"t": 1.0, "p": [0.0, 0.0, 0.2], "pd": L(5, 12), "pi": L(5, 12)},
	])

static func cabezazo_potente(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.0, false, [
		{"t": 0.0, "pd": L(20, 40), "pi": L(20, 40), "p": [0.0, -0.1, 0.0]},
		{"t": 0.3, "p": [0.0, 0.38, 0.0], "tr": [-28, 0, 0], "g": [-10, 0, 0], "pd": L(50, 90, 10), "pi": L(20, 40, 20), "bi": [-10, 70, 30], "bd": [-10, 70, 30], "cu": [-25, 0]},
		{"t": 0.45, "p": [0.0, 0.4, 0.05], "tr": [35, 0, 0], "g": [10, 0, 0], "cu": [25, 0], "bi": [-40, 30, 20], "bd": [-40, 30, 20]},
		{"t": 0.8, "p": [0.0, -0.1, 0.15], "tr": [8, 0, 0], "g": [0, 0, 0], "pd": L(35, 60), "pi": L(35, 60)},
		{"t": 1.0, "p": [0.0, 0.0, 0.15], "pd": L(5, 12), "pi": L(5, 12)},
	])

static func taconazo(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 0.8, false, [
		{"t": 0.0, "pd": L(10, 20), "pi": L(8, 18)},
		{"t": 0.25, "pd": L(20, 70, 10), "pi": L(15, 25), "tr": [8, 0, 0], "cu": [25, 0]},
		{"t": 0.4, "pd": L(-40, 55, 25), "pi": L(15, 28), "tr": [15, 0, 0], "bi": [15, 40, 20], "bd": [15, 40, 20]},
		{"t": 0.8, "pd": L(4, 12), "pi": L(4, 12), "tr": [2, 0, 0]},
	])

static func pase_pecho(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 0.9, false, [
		{"t": 0.0, "pd": L(10, 20), "pi": L(10, 20)},
		{"t": 0.3, "tr": [-25, 0, 0], "p": [0.0, 0.02, -0.05], "bi": [-25, 40, 30], "bd": [-25, 40, 30], "cu": [-10, 0], "pd": L(8, 22), "pi": L(8, 22)},
		{"t": 0.5, "tr": [12, 0, 0], "p": [0.0, 0.0, 0.08], "bi": [0, 20, 20], "bd": [0, 20, 20], "cu": [15, 0]},
		{"t": 0.9, "tr": [2, 0, 0], "pd": L(4, 12), "pi": L(4, 12)},
	])

static func pase_cabeza(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 0.9, false, [
		{"t": 0.0, "pd": L(15, 30), "pi": L(15, 30), "p": [0.0, -0.06, 0.0]},
		{"t": 0.3, "p": [0.0, 0.15, 0.0], "tr": [-15, 0, 0], "cu": [-25, 0], "pd": L(20, 40, 15), "pi": L(20, 40, 15), "bi": [0, 45, 30], "bd": [0, 45, 30]},
		{"t": 0.45, "p": [0.0, 0.16, 0.02], "tr": [12, 0, 25], "cu": [15, 20]},
		{"t": 0.9, "p": [0.0, 0.0, 0.05], "tr": [0, 0, 0], "cu": [0, 0], "pd": L(8, 18), "pi": L(8, 18)},
	])

# =============================================================================
#  BARRIDAS Y ENTRADAS
# =============================================================================
#
# Las que van al suelo usan la pierna con cinemática inversa de
# `AnimQuaternius._pierna_apoyada()` (la que ya usa `falta_barrida`): la
# cadera baja hasta el césped y los pies se quedan en él, sin hundirse.
static func barrida(esq: Skeleton3D, pre: String, c: Dictionary) -> Animation:
	var d := float(c.get("dur", 1.3))
	var largo := float(c.get("largo", 1.0))
	var lat := float(c.get("lateral", 0.0))       ## hacia la derecha (m)
	var rueda := float(c.get("rueda", 0.0))       ## ° de rueda
	var alto := float(c.get("alto_pie", 0.07))
	var dos := bool(c.get("dos_pies", false))
	var levanta := float(c.get("levanta", 0.3))   ## lo que tarda en recuperarse
	var t1 := d * 0.25
	var t2 := d * (1.0 - levanta)
	var a := AnimQuaternius._nueva(d, false)
	var cad := [[0.0, Vector3.ZERO], [t1, Vector3(-lat * 0.5, -0.56, 0.15 * largo)],
		[t2, Vector3(-lat, -0.58, 0.3 * largo)], [d, Vector3(-lat, -0.2 if levanta > 0.2 else -0.55, 0.3 * largo)]]
	AnimQuaternius._pista_pos(a, esq, "cadera", cad, pre, true)
	var rg := [[0.0, Vector3.ZERO], [t1, Vector3(0, 0, rueda * 0.7)], [t2, Vector3(0, 0, rueda)], [d, Vector3(0, 0, rueda * (0.3 if levanta > 0.2 else 1.0))]]
	AnimQuaternius._pista(a, esq, "cadera", rg, pre)
	var fin_y := -0.2 if levanta > 0.2 else -0.55
	AnimQuaternius._pierna_apoyada(a, esq, "d", [[0.0, 0.0, 0.0, 0.0, 0.0], [t1, -0.56, 0.15 * largo, 1.0 * largo, alto],
		[t2, -0.58, 0.3 * largo, 1.05 * largo, alto], [d, fin_y, 0.3 * largo, 0.45 * largo, 0.0]], pre)
	if dos:
		AnimQuaternius._pierna_apoyada(a, esq, "i", [[0.0, 0.0, 0.0, 0.0, 0.0], [t1, -0.56, 0.15 * largo, 0.95 * largo, alto],
			[t2, -0.58, 0.3 * largo, 1.0 * largo, alto], [d, fin_y, 0.3 * largo, 0.4 * largo, 0.0]], pre)
	else:
		AnimQuaternius._pierna_apoyada(a, esq, "i", [[0.0, 0.0, 0.0, 0.0, 0.0], [t1, -0.56, 0.15 * largo, -0.28, 0.04],
			[t2, -0.58, 0.3 * largo, -0.18, 0.04], [d, fin_y, 0.3 * largo, 0.0, 0.0]], pre)
	var inc := float(c.get("tronco", -26.0))
	AnimQuaternius._pista(a, esq, "espalda2", [[0.0, Vector3.ZERO], [t1, Vector3(inc, 0, 0)], [t2, Vector3(inc * 0.9, 0, 0)], [d, Vector3(-6, 0, 0)]], pre)
	AnimQuaternius._pista(a, esq, "brazo_i", [[0.0, AnimExtra._brazo("i", 2, 6)], [t1, AnimExtra._brazo("i", -40, 35)], [d, AnimExtra._brazo("i", 2, 8)]], pre)
	AnimQuaternius._pista(a, esq, "brazo_d", [[0.0, AnimExtra._brazo("d", 2, 6)], [t1, AnimExtra._brazo("d", 20, 45)], [d, AnimExtra._brazo("d", 2, 8)]], pre)
	return a

## Entradas de pie (sin ir al suelo).
static func entrada_de_pie(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 0.8, false, [
		{"t": 0.0, "pd": L(15, 30), "pi": L(15, 30), "p": [0.0, -0.06, 0.0]},
		{"t": 0.25, "pd": L(55, 15, -10, 5, 20), "pi": L(30, 50), "p": [0.0, -0.18, 0.2], "tr": [18, 0, 0], "bi": [20, 45, 20], "bd": [-10, 30, 20]},
		{"t": 0.5, "pd": L(40, 20, -5, 5, 20), "pi": L(30, 50), "p": [0.0, -0.16, 0.25]},
		{"t": 0.8, "pd": L(8, 18), "pi": L(8, 18), "p": [0.0, -0.02, 0.25], "tr": [4, 0, 0]},
	])

static func entrada_lateral_pie(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 0.8, false, [
		{"t": 0.0, "pd": L(15, 30), "pi": L(15, 30), "p": [0.0, -0.06, 0.0]},
		{"t": 0.3, "pd": L(35, 20, -10, 45, 30), "pi": L(35, 55), "p": [0.15, -0.2, 0.0], "tr": [10, -15, 0], "bi": [0, 55, 20], "bd": [10, 30, 20]},
		{"t": 0.8, "pd": L(8, 18), "pi": L(8, 18), "p": [0.1, -0.02, 0.0], "tr": [2, 0, 0]},
	])

static func carga_hombro(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 0.9, false, [
		{"t": 0.0, "pd": L(20, 35), "pi": L(10, 25), "p": [0.0, -0.05, 0.0]},
		{"t": 0.3, "p": [0.12, -0.08, 0.1], "tr": [10, 22, -10], "g": [0, 8, 0], "bd": [-5, 18, 60], "bi": [10, 30, 40], "pd": L(10, 30), "pi": L(25, 40)},
		{"t": 0.5, "p": [0.05, -0.05, 0.2], "tr": [6, 5, 0], "g": [0, 0, 0]},
		{"t": 0.9, "pd": L(8, 18), "pi": L(8, 18), "p": [0.0, 0.0, 0.25], "tr": [2, 0, 0]},
	])

static func entrada_cuerpo(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.0, false, [
		{"t": 0.0, "pd": L(20, 40, 0, 10), "pi": L(20, 40, 0, 10), "p": [0.0, -0.1, 0.0]},
		{"t": 0.3, "pd": L(30, 55, 0, 18), "pi": L(30, 55, 0, 18), "p": [0.0, -0.16, 0.0], "tr": [15, 0, 0], "bi": [15, 55, 30], "bd": [15, 55, 30]},
		{"t": 0.6, "p": [-0.2, -0.16, 0.0], "tr": [15, -8, 0]},
		{"t": 1.0, "pd": L(10, 20), "pi": L(10, 20), "p": [-0.2, -0.03, 0.0], "tr": [4, 0, 0]},
	])

static func anticipacion(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 0.9, false, [
		{"t": 0.0, "pd": L(15, 30), "pi": L(15, 30), "p": [0.0, -0.06, 0.0]},
		{"t": 0.15, "p": [0.0, 0.05, 0.0], "pd": L(10, 25), "pi": L(10, 25)},
		{"t": 0.4, "p": [0.0, -0.3, 0.55], "pd": L(70, 20, -10, 10, 20), "pi": L(-20, 45), "tr": [25, 0, 0], "bi": [30, 40, 20], "bd": [-20, 30, 20]},
		{"t": 0.9, "pd": L(10, 20), "pi": L(10, 20), "p": [0.0, -0.03, 0.6], "tr": [4, 0, 0]},
	])

static func zancadilla(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 0.9, false, [
		{"t": 0.0, "pd": L(15, 30), "pi": L(15, 30), "p": [0.0, -0.05, 0.0]},
		{"t": 0.3, "pd": L(20, 50, 10, -30, -20), "pi": L(20, 35), "tr": [8, 8, 0], "p": [0.05, -0.1, 0.05]},
		{"t": 0.45, "pd": L(5, 70, 20, -35, -25), "cu": [15, -20]},
		{"t": 0.9, "pd": L(8, 18), "pi": L(8, 18), "p": [0.0, 0.0, 0.1], "tr": [2, 0, 0], "cu": [0, 0]},
	])

static func entrada_tijera(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.4, false, [
		{"t": 0.0, "pd": L(15, 30), "pi": L(15, 30)},
		{"t": 0.3, "p": [0.3, -0.3, 0.3], "g": [0, 40, 0], "pd": L(70, 10, 20, 20), "pi": L(20, 40), "tr": [-15, 0, 0]},
		{"t": 0.6, "p": [0.5, -0.72, 0.5], "g": [0, 75, 0], "pd": L(40, 20, 20, 30), "pi": L(60, 20, 20, -10), "bi": [20, 70, 20], "bd": [20, 30, 20]},
		{"t": 1.4, "p": [0.5, -0.75, 0.5], "g": [0, 80, 0], "pd": L(30, 40), "pi": L(40, 50)},
	])

static func barrida_rodilla(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.2, false, [
		{"t": 0.0, "pd": L(15, 30), "pi": L(15, 30)},
		{"t": 0.3, "p": [0.0, -0.45, 0.4], "pi": L(20, 110, 30), "pd": L(70, 40, -10), "tr": [-15, 0, 0], "bi": [10, 50, 20], "bd": [10, 50, 20]},
		{"t": 0.8, "p": [0.0, -0.47, 0.8], "tr": [-10, 0, 0]},
		{"t": 1.2, "p": [0.0, -0.1, 0.85], "pd": L(10, 25), "pi": L(10, 25), "tr": [2, 0, 0]},
	])
