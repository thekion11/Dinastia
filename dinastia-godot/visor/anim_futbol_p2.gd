extends "res://visor/anim_futbol_p1.gd"
## [Capa 2/3 de `anim_futbol.gd`] estirada, portero_lateral, defensor_pica, duelo_hombro, duelo_empujado, duelo_agarron … (+16)

# =============================================================================
#  PORTERO: ESTIRADAS Y PARADAS
# =============================================================================

## Una estirada: `lado` +1 a la derecha, -1 a la izquierda; `alto` de la mano
## (0 raso, 1 escuadra).
static func estirada(esq: Skeleton3D, pre: String, lado: float, alto: float) -> Animation:
	var der := 1.25 * lado
	var rueda := 80.0 * lado * (0.7 + alto * 0.3)
	var cad_alto := 0.1 + alto * 0.35
	var brazo_al := 110.0 + alto * 60.0
	var bd_c := brazo_al if lado > 0 else 40.0 + alto * 90.0
	var bi_c := brazo_al if lado < 0 else 40.0 + alto * 90.0
	return armar(esq, pre, 1.5, false, [
		{"t": 0.0, "pd": L(25, 45, 0, 10), "pi": L(25, 45, 0, 10), "p": [0.0, -0.14, 0.0], "tr": [15, 0, 0], "bi": [25, 30, 40], "bd": [25, 30, 40]},
		{"t": 0.12, "p": [der * 0.1, -0.2, 0.0], "pd": L(35, 60, 0, 12), "pi": L(35, 60, 0, 12)},
		{"t": 0.4, "p": [der * 0.8, cad_alto - 0.05, 0.12], "g": [5, rueda * 0.8, 0], "tr": [0, rueda * 0.2, 0],
			"pd": L(20, 30, 20, 20 if lado < 0 else 5), "pi": L(20, 30, 20, 20 if lado > 0 else 5),
			"bi": [30, bi_c, 5], "bd": [30, bd_c, 5], "cu": [0, -20 * lado]},
		{"t": 0.75, "p": [der, -0.75, 0.15], "g": [0, rueda, 0], "pd": L(30, 40, 10), "pi": L(20, 30, 10),
			"bi": [40, bi_c * 0.9, 20], "bd": [40, bd_c * 0.9, 20]},
		{"t": 1.5, "p": [der, -0.78, 0.15], "g": [0, rueda * 0.95, 0], "pd": L(40, 60), "pi": L(30, 50), "bi": [50, 60, 60], "bd": [50, 60, 60]},
	])

## EL PASO LATERAL DEL PORTERO (14-10-2026, «¿qué le pasa al portero?»): antes
## se movía corriendo de espaldas al balón, como un jugador de campo. Un
## portero de verdad se desplaza de lado, en guardia, sin cruzar las piernas:
## abre una, cierra la otra, siempre de cara al juego. `lado` +1 a su derecha.
## En bucle; el que lo lleva por el campo es el motor.
static func portero_lateral(esq: Skeleton3D, pre: String, lado: float) -> Animation:
	var abre := "pd" if lado > 0 else "pi"
	var cierra := "pi" if lado > 0 else "pd"
	var brazos := [30, 28, 45]
	var k0 := {"t": 0.0, "p": [0.0, -0.15, 0.0], "tr": [16, 0, 0], abre: L(26, 48, 0, 8), cierra: L(26, 48, 0, 8), "bd": brazos, "bi": brazos}
	var k1 := {"t": 0.13, "p": [0.03 * lado, -0.12, 0.0], abre: L(32, 58, 5, 24), cierra: L(25, 46, 0, 6)}
	var k2 := {"t": 0.26, "p": [0.06 * lado, -0.17, 0.0], "tr": [16, 3 * lado, 0], abre: L(24, 44, 0, 18), cierra: L(28, 50, 0, 14)}
	var k3 := {"t": 0.39, "p": [0.03 * lado, -0.13, 0.0], abre: L(25, 46, 0, 10), cierra: L(33, 58, 5, 0)}
	var k4 := k0.duplicate()
	k4["t"] = 0.52
	return armar(esq, pre, 0.52, true, [k0, k1, k2, k3, k4])

## EL DEFENSOR QUE PICA (16-10-2026): se tira hacia el lado del amago, la
## cadera baja y se va de lado, el tronco se le inclina, abre la pierna de
## ese lado y mira hacia atrás cómo se le escapa; luego se recompone. Antes
## el que picaba solo ponía la guardia de «marcar» y desde la cámara de
## transmisión no se notaba que lo habían engañado. `lado` 1 = a su derecha.
static func defensor_pica(esq: Skeleton3D, pre: String, lado: float) -> Animation:
	var abre := "pd" if lado > 0 else "pi"
	var cierra := "pi" if lado > 0 else "pd"
	var k0 := {"t": 0.0, "p": [0.0, -0.12, 0.0], "tr": [18, 0, 0], abre: L(25, 45), cierra: L(25, 45), "bd": [20, 30, 40], "bi": [20, 30, 40]}
	var k1 := {"t": 0.18, "p": [0.24 * lado, -0.22, 0.0], "g": [0, 12 * lado, 8 * lado], "tr": [24, 20 * lado, 6 * lado],
		abre: L(38, 64, 0, 30), cierra: L(6, 12, 10, 14), "bd": [10, 75, 25] if lado > 0 else [30, 25, 60], "bi": [30, 25, 60] if lado > 0 else [10, 75, 25]}
	var k2 := {"t": 0.45, "p": [0.30 * lado, -0.24, -0.05], "g": [0, 14 * lado, 22 * lado], "tr": [28, 24 * lado, 18 * lado], "cu": [8, -30 * lado],
		abre: L(42, 70, 0, 26), cierra: L(4, 10, 15, 10)}
	var k3 := {"t": 0.8, "p": [0.10 * lado, -0.12, 0.0], "g": [0, 4 * lado, 10 * lado], "tr": [18, 6 * lado, 8 * lado], "cu": [0, -10 * lado],
		abre: L(25, 45, 0, 8), cierra: L(25, 45), "bd": [20, 30, 40], "bi": [20, 30, 40]}
	return armar(esq, pre, 0.9, false, [k0, k1, k2, k3])

## LOS DUELOS CUERPO A CUERPO (16-10-2026, «duelos/contacto»). Cuatro gestos
## para que desde la cámara de transmisión se lea quién gana el contacto:
##   - `duelo_hombro`: en carrera, mete el hombro hacia el rival que va a su
##     `lado` (+1 = a su derecha): tronco inclinado, cadera que empuja, el
##     brazo de ese lado pegado al cuerpo; las piernas siguen la zancada.
##   - `duelo_empujado`: el que pierde el choque trastabilla hacia `lado`,
##     abre el brazo para no caerse y cruza la pierna; luego se recompone.
##   - `duelo_agarron`: el defensor estira el brazo y tira de la camiseta.
##   - `duelo_forcejeo`: el que lleva el balón se inclina y aparta el brazo
##     del rival hacia atrás para zafarse.
static func duelo_hombro(esq: Skeleton3D, pre: String, lado: float) -> Animation:
	var pega := "bd" if lado > 0 else "bi"
	var libre := "bi" if lado > 0 else "bd"
	return armar(esq, pre, 0.6, false, [
		{"t": 0.0, "pd": L(35, 50), "pi": L(-10, 25), "p": [0.0, -0.04, 0.0], "tr": [8, 0, 0]},
		{"t": 0.18, "p": [0.09 * lado, -0.09, 0.04], "g": [0, 7 * lado, 0], "tr": [12, 17 * lado, -8 * lado],
			pega: [-5, 16, 75], libre: [28, 32, 55], "pi": L(35, 50), "pd": L(-10, 25)},
		{"t": 0.38, "p": [0.10 * lado, -0.08, 0.06], "tr": [12, 15 * lado, -6 * lado], "pd": L(35, 50), "pi": L(-10, 25)},
		{"t": 0.6, "p": [0.02 * lado, -0.04, 0.0], "g": [0, 0, 0], "tr": [8, 0, 0], pega: [10, 12, 40], libre: [10, 12, 40], "pi": L(30, 45), "pd": L(-5, 25)},
	])

static func duelo_empujado(esq: Skeleton3D, pre: String, lado: float) -> Animation:
	var abre := "pd" if lado > 0 else "pi"
	var cruza := "pi" if lado > 0 else "pd"
	var b_abre := "bd" if lado > 0 else "bi"
	var b_otro := "bi" if lado > 0 else "bd"
	return armar(esq, pre, 0.75, false, [
		{"t": 0.0, "pd": L(25, 35), "pi": L(20, 30), "p": [0.0, -0.05, 0.0], "tr": [8, 0, 0]},
		{"t": 0.15, "p": [0.18 * lado, -0.12, 0.0], "g": [0, 8 * lado, 0], "tr": [10, 20 * lado, 4 * lado], "cu": [4, -8 * lado],
			abre: L(20, 40, 0, 26), cruza: L(18, 22, 0, -14), b_abre: [12, 72, 18], b_otro: [35, 45, 45]},
		{"t": 0.38, "p": [0.26 * lado, -0.16, 0.04], "g": [0, 10 * lado, 0], "tr": [14, 12 * lado, 0], "cu": [6, -4 * lado],
			abre: L(28, 48, 0, 18), cruza: L(30, 40, 0, -6), b_abre: [20, 80, 10], b_otro: [40, 55, 40]},
		{"t": 0.75, "p": [0.10 * lado, -0.05, 0.08], "g": [0, 0, 0], "tr": [6, 0, 0], "cu": [0, 0],
			abre: L(22, 32), cruza: L(18, 28), b_abre: [10, 15, 30], b_otro: [10, 15, 30]},
	])

static func duelo_agarron(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 0.9, false, [
		{"t": 0.0, "pd": L(25, 35), "pi": L(10, 25), "p": [0.0, -0.05, 0.0], "tr": [10, 0, 0]},
		{"t": 0.2, "p": [0.0, -0.1, -0.04], "tr": [20, 0, -12], "bd": [78, 8, 12], "bi": [25, 35, 55], "pd": L(32, 42), "pi": L(8, 22), "cu": [-4, 6]},
		{"t": 0.5, "p": [0.0, -0.12, -0.08], "tr": [14, 0, -6], "bd": [62, 10, 45], "bi": [30, 40, 50], "pd": L(18, 30), "pi": L(30, 45)},
		{"t": 0.9, "p": [0.0, -0.04, 0.0], "tr": [8, 0, 0], "bd": [12, 12, 30], "bi": [12, 12, 30], "pd": L(25, 35), "pi": L(10, 25), "cu": [0, 0]},
	])

static func duelo_forcejeo(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 0.8, false, [
		{"t": 0.0, "pd": L(35, 50), "pi": L(-8, 25), "p": [0.0, -0.05, 0.0], "tr": [10, 0, 0]},
		{"t": 0.2, "p": [0.0, -0.1, 0.06], "tr": [22, -6, 14], "bi": [-35, 38, 28], "bd": [30, 30, 60], "pi": L(38, 55), "pd": L(-10, 25), "cu": [-6, -10]},
		{"t": 0.45, "p": [0.0, -0.09, 0.08], "tr": [20, -4, 10], "bi": [-28, 45, 20], "pd": L(38, 55), "pi": L(-10, 25)},
		{"t": 0.8, "p": [0.0, -0.04, 0.04], "tr": [10, 0, 0], "bi": [10, 12, 35], "bd": [10, 12, 35], "pd": L(30, 45), "pi": L(-5, 25), "cu": [0, 0]},
	])

static func blocaje_alto(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.1, false, [
		{"t": 0.0, "pd": L(20, 40), "pi": L(20, 40), "p": [0.0, -0.1, 0.0], "bi": [25, 30, 40], "bd": [25, 30, 40]},
		{"t": 0.35, "p": [0.0, 0.4, 0.0], "pd": L(60, 100, 10), "pi": L(10, 30, 20), "bi": [150, 20, 20], "bd": [150, 20, 20], "cu": [-25, 0]},
		{"t": 0.55, "p": [0.0, 0.38, 0.0], "bi": [90, 10, 90], "bd": [90, 10, 90], "cu": [0, 0]},
		{"t": 0.85, "p": [0.0, -0.1, 0.0], "pd": L(30, 50), "pi": L(30, 50), "bi": [45, 10, 110], "bd": [45, 10, 110]},
		{"t": 1.1, "p": [0.0, 0.0, 0.0], "pd": L(8, 18), "pi": L(8, 18)},
	])

static func punos(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.0, false, [
		{"t": 0.0, "pd": L(20, 40), "pi": L(20, 40), "p": [0.0, -0.1, 0.0], "bi": [25, 30, 40], "bd": [25, 30, 40]},
		{"t": 0.3, "p": [0.0, 0.35, 0.05], "pd": L(70, 100, 10), "pi": L(10, 30, 20), "bi": [100, 15, 110], "bd": [100, 15, 110], "cu": [-20, 0]},
		{"t": 0.42, "bi": [165, 10, 0], "bd": [165, 10, 0]},
		{"t": 0.75, "p": [0.0, -0.1, 0.1], "pd": L(30, 50), "pi": L(30, 50), "bi": [60, 20, 30], "bd": [60, 20, 30], "cu": [0, 0]},
		{"t": 1.0, "p": [0.0, 0.0, 0.1], "pd": L(8, 18), "pi": L(8, 18)},
	])

static func achique(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.4, false, [
		{"t": 0.0, "pd": L(25, 45), "pi": L(25, 45), "p": [0.0, -0.14, 0.0], "tr": [15, 0, 0]},
		{"t": 0.35, "p": [0.0, -0.5, 0.6], "g": [30, 60, 0], "pd": L(60, 60), "pi": L(40, 50), "bi": [60, 30, 30], "bd": [60, 30, 30], "cu": [-20, 0]},
		{"t": 0.7, "p": [0.1, -0.8, 0.9], "g": [10, 85, 0], "pd": L(50, 70), "pi": L(40, 60), "bi": [75, 40, 20], "bd": [75, 40, 20]},
		{"t": 1.4, "p": [0.1, -0.8, 0.9], "g": [10, 85, 0], "pd": L(55, 80), "pi": L(45, 70), "bi": [60, 30, 90], "bd": [60, 30, 90]},
	])

static func blocaje_rasante(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.2, false, [
		{"t": 0.0, "pd": L(25, 45), "pi": L(25, 45), "p": [0.0, -0.14, 0.0], "tr": [15, 0, 0]},
		{"t": 0.35, "p": [0.0, -0.5, 0.1], "pd": L(40, 110, 20), "pi": L(70, 90), "tr": [45, 0, 0], "bi": [70, 15, 20], "bd": [70, 15, 20], "cu": [20, 0]},
		{"t": 0.7, "tr": [40, 0, 0], "bi": [55, 10, 100], "bd": [55, 10, 100]},
		{"t": 1.2, "p": [0.0, -0.1, 0.1], "pd": L(15, 30), "pi": L(15, 30), "tr": [10, 0, 0], "bi": [45, 10, 110], "bd": [45, 10, 110]},
	])

static func parada_pie(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.0, false, [
		{"t": 0.0, "pd": L(25, 45, 0, 10), "pi": L(25, 45, 0, 10), "p": [0.0, -0.14, 0.0], "bi": [25, 30, 40], "bd": [25, 30, 40]},
		{"t": 0.3, "p": [-0.3, -0.35, 0.0], "pd": L(20, 20, -10, 70, 30), "pi": L(50, 80, 0, 5), "tr": [0, -20, 0], "bi": [10, 70, 20], "bd": [10, 50, 20]},
		{"t": 1.0, "p": [-0.1, -0.1, 0.0], "pd": L(20, 40), "pi": L(20, 40)},
	])

static func salida_aerea(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.3, false, [
		{"t": 0.0, "pd": L(20, 40), "pi": L(20, 40), "p": [0.0, -0.08, 0.0]},
		{"t": 0.25, "p": [0.0, -0.05, 0.4], "pd": L(40, 60), "pi": L(-10, 30)},
		{"t": 0.55, "p": [0.0, 0.45, 0.8], "pd": L(85, 110, 10), "pi": L(5, 20, 20), "bi": [160, 10, 10], "bd": [160, 10, 10], "cu": [-30, 0]},
		{"t": 0.75, "bi": [100, 5, 90], "bd": [100, 5, 90]},
		{"t": 1.05, "p": [0.0, -0.1, 1.0], "pd": L(30, 50), "pi": L(30, 50), "bi": [45, 10, 110], "bd": [45, 10, 110], "cu": [0, 0]},
		{"t": 1.3, "p": [0.0, 0.0, 1.0], "pd": L(8, 18), "pi": L(8, 18)},
	])

static func mano_cambiada(esq: Skeleton3D, pre: String) -> Animation:
	return armar(esq, pre, 1.3, false, [
		{"t": 0.0, "pd": L(25, 45), "pi": L(25, 45), "p": [0.0, -0.14, 0.0], "bi": [25, 30, 40], "bd": [25, 30, 40]},
		{"t": 0.35, "p": [-0.9, 0.3, 0.1], "g": [0, -60, 0], "bd": [40, 165, 0], "bi": [20, 60, 30], "pd": L(20, 30, 20), "pi": L(30, 50), "cu": [-10, 25]},
		{"t": 0.7, "p": [-1.1, -0.75, 0.1], "g": [0, -80, 0], "bd": [40, 140, 20]},
		{"t": 1.3, "p": [-1.1, -0.78, 0.1], "g": [0, -78, 0], "pd": L(40, 60), "pi": L(30, 50), "bd": [40, 80, 60], "bi": [40, 50, 50]},
	])

static func _k(t: float, cambios: Dictionary) -> Dictionary:
	var k := BASE.duplicate(true)
	for c: String in cambios:
		k[c] = cambios[c]
	k["t"] = t
	return k

## Los 30 regates: [nombre, duración, claves [t, cambios]]
static func regates() -> Array:
	return [
		["bicicleta", 1.0, [[0.2, {"pd": L(30, 40, 10, -25), "p": [0.05, -0.08, 0.0]}], [0.4, {"pd": L(35, 50, 10, 30), "p": [0.15, -0.08, 0.05], "tr": [12, 15, 0]}],
			[0.6, {"pd": L(10, 25), "p": [-0.05, -0.08, 0.1]}], [0.8, {"p": [-0.2, -0.06, 0.2], "tr": [12, -12, 0], "pi": L(35, 50, 0, 25)}]]],
		["doble_bicicleta", 1.4, [[0.2, {"pd": L(30, 40, 10, -25)}], [0.35, {"pd": L(35, 50, 10, 30), "p": [0.15, -0.08, 0.0], "tr": [12, 15, 0]}],
			[0.55, {"pi": L(30, 40, 10, -25), "p": [0.0, -0.08, 0.05]}], [0.7, {"pi": L(35, 50, 10, 30), "p": [-0.15, -0.08, 0.05], "tr": [12, -15, 0]}],
			[1.0, {"p": [0.2, -0.06, 0.2], "pd": L(35, 50, 0, 25), "tr": [12, 12, 0]}]]],
		["bicicleta_inversa", 1.0, [[0.2, {"pd": L(30, 40, 10, 30)}], [0.4, {"pd": L(35, 50, 10, -25), "p": [-0.12, -0.08, 0.05], "tr": [12, -15, 0]}],
			[0.8, {"p": [0.2, -0.06, 0.2], "tr": [12, 12, 0], "pd": L(35, 50, 0, 25)}]]],
		["bicicleta_triple", 1.8, [[0.2, {"pd": L(30, 40, 10, -25)}], [0.35, {"pd": L(35, 50, 10, 30), "tr": [12, 15, 0], "p": [0.12, -0.08, 0.0]}],
			[0.55, {"pi": L(30, 40, 10, -25)}], [0.7, {"pi": L(35, 50, 10, 30), "tr": [12, -15, 0], "p": [-0.12, -0.08, 0.0]}],
			[0.9, {"pd": L(30, 40, 10, -25)}], [1.05, {"pd": L(35, 50, 10, 30), "tr": [12, 15, 0], "p": [0.12, -0.08, 0.0]}],
			[1.4, {"p": [-0.2, -0.06, 0.2], "tr": [12, -12, 0], "pi": L(35, 50, 0, 25)}]]],
		["elastica", 0.9, [[0.25, {"pd": L(20, 30, 0, 20, -25), "p": [0.1, -0.08, 0.0], "tr": [12, 12, 0]}],
			[0.45, {"pd": L(22, 35, 0, -20, 30), "p": [-0.15, -0.08, 0.1], "tr": [12, -14, 0]}], [0.7, {"p": [-0.25, -0.06, 0.25]}]]],
		["elastica_inversa", 0.9, [[0.25, {"pd": L(22, 35, 0, -20, 30), "p": [-0.1, -0.08, 0.0], "tr": [12, -12, 0]}],
			[0.45, {"pd": L(20, 30, 0, 20, -25), "p": [0.15, -0.08, 0.1], "tr": [12, 14, 0]}], [0.7, {"p": [0.25, -0.06, 0.25]}]]],
		["ruleta", 1.2, [[0.2, {"pd": L(20, 30, -20), "g": [0, 0, 0]}], [0.4, {"g": [0, 0, 90], "pi": L(25, 40)}], [0.6, {"g": [0, 0, 180], "pd": L(20, 35, -20)}],
			[0.8, {"g": [0, 0, 270], "pi": L(20, 35)}], [1.0, {"g": [0, 0, 355], "p": [0.1, -0.06, 0.2]}]]],
		["ruleta_inversa", 1.2, [[0.2, {"pi": L(20, 30, -20)}], [0.4, {"g": [0, 0, -90], "pd": L(25, 40)}], [0.6, {"g": [0, 0, -180], "pi": L(20, 35, -20)}],
			[0.8, {"g": [0, 0, -270], "pd": L(20, 35)}], [1.0, {"g": [0, 0, -355], "p": [-0.1, -0.06, 0.2]}]]],
		["sombrero", 1.0, [[0.25, {"pd": L(-25, 95, 30), "pi": L(15, 30)}], [0.4, {"pd": L(-10, 110, 35), "p": [0.0, 0.12, 0.05], "pi": L(20, 40, 20)}],
			[0.7, {"p": [0.0, -0.06, 0.3], "pd": L(30, 40)}]]],
		["cano", 0.8, [[0.25, {"pd": L(30, 35, 0, 15, 25), "tr": [18, 0, 0]}], [0.5, {"p": [0.0, -0.06, 0.35], "tr": [20, 0, 0], "pi": L(40, 50)}]]],
		["croqueta", 0.8, [[0.2, {"pd": L(18, 30, 0, 25), "pi": L(18, 30, 0, -10), "p": [0.1, -0.08, 0.0]}],
			[0.4, {"pd": L(18, 30, 0, -10), "pi": L(18, 30, 0, 25), "p": [-0.12, -0.08, 0.05], "tr": [12, -8, 0]}], [0.6, {"p": [-0.2, -0.06, 0.2]}]]],
		["amague_tiro", 1.0, [[0.3, {"pd": L(-45, 100, 20), "tr": [-6, 0, 0], "bi": [18, 62, 22]}],
			[0.5, {"pd": L(25, 35, 0, -30, 30), "p": [-0.12, -0.1, 0.05], "tr": [15, -10, 0]}], [0.8, {"p": [-0.3, -0.06, 0.25]}]]],
		["amague_pase", 0.9, [[0.3, {"pd": L(-25, 60, 0, 20, 30), "cu": [10, -25]}], [0.5, {"pd": L(20, 30, 0, 25, 10), "p": [0.1, -0.08, 0.1]}],
			[0.75, {"p": [0.2, -0.06, 0.3], "cu": [0, 0]}]]],
		["amague_cuerpo", 0.9, [[0.25, {"tr": [12, 22, 0], "p": [0.15, -0.1, 0.0], "cu": [0, -15], "pd": L(25, 45, 0, 15)}],
			[0.5, {"tr": [12, -22, 0], "p": [-0.2, -0.1, 0.1], "cu": [0, 15], "pi": L(25, 45, 0, 15)}], [0.75, {"p": [-0.3, -0.06, 0.3], "cu": [0, 0]}]]],
		["giro_cruyff", 1.0, [[0.3, {"pd": L(-40, 90, 20)}], [0.5, {"pd": L(15, 45, 0, -35, 30), "g": [0, 0, -60], "tr": [15, 0, 0]}],
			[0.75, {"g": [0, 0, -165], "p": [0.1, -0.06, 0.0]}], [0.95, {"g": [0, 0, -175], "p": [0.1, -0.06, -0.2]}]]],
		["arrastre", 1.0, [[0.25, {"pd": L(25, 30, -25)}], [0.45, {"pd": L(-15, 40, -10), "p": [0.0, -0.08, -0.2]}],
			[0.7, {"g": [0, 0, 90], "p": [0.0, -0.06, -0.25]}], [0.95, {"g": [0, 0, 170]}]]],
		["pisada_lateral", 0.9, [[0.2, {"pd": L(22, 30, -20, -15)}], [0.45, {"pd": L(22, 30, -20, 30), "p": [0.15, -0.08, 0.0], "tr": [12, 12, 0]}],
			[0.7, {"p": [0.25, -0.06, 0.2]}]]],
		["cola_de_vaca", 1.0, [[0.25, {"pd": L(20, 45, 0, -35, 25), "tr": [15, 0, 0]}], [0.5, {"g": [0, 0, 80], "p": [-0.1, -0.08, 0.0]}],
			[0.8, {"g": [0, 0, 100], "p": [-0.25, -0.06, 0.2]}]]],
		["lambreta", 1.1, [[0.25, {"pi": L(15, 30), "pd": L(-30, 100, 30)}], [0.4, {"pd": L(-10, 120, 40), "pi": L(-25, 90, 30), "p": [0.0, 0.1, 0.0]}],
			[0.6, {"p": [0.0, 0.15, 0.1], "pd": L(20, 50)}], [0.9, {"p": [0.0, -0.06, 0.3]}]]],
		["rabona_regate", 1.0, [[0.3, {"pd": L(-35, 95, 15, -30, -15), "tr": [10, 0, 25]}], [0.5, {"pd": L(20, 50, 10, -35, -20)}],
			[0.8, {"p": [-0.25, -0.06, 0.25], "tr": [12, 0, 0]}]]],
		["cambio_ritmo", 1.1, [[0.35, {"p": [0.0, -0.08, 0.05], "tr": [8, 0, 0]}], [0.55, {"tr": [28, 0, 0], "pd": L(45, 60), "pi": L(-20, 40), "bd": [45, 20, 80], "bi": [-35, 20, 80]}],
			[0.8, {"p": [0.0, -0.1, 0.5], "tr": [25, 0, 0], "pi": L(45, 60), "pd": L(-20, 40), "bi": [45, 20, 80], "bd": [-35, 20, 80]}]]],
		["frenar_arrancar", 1.2, [[0.3, {"pd": L(30, 30, -20), "tr": [-5, 0, 0], "p": [0.0, -0.1, -0.05]}], [0.6, {"tr": [0, 0, 0]}],
			[0.8, {"tr": [26, 0, 0], "p": [0.0, -0.1, 0.4], "pi": L(45, 60), "pd": L(-15, 40)}]]],
		["recorte_interior", 0.9, [[0.3, {"pd": L(25, 40, 0, -30, 30), "tr": [15, -10, 0], "p": [0.05, -0.1, 0.0]}],
			[0.55, {"g": [0, 0, 45], "p": [-0.15, -0.08, 0.1]}], [0.8, {"g": [0, 0, 45], "p": [-0.3, -0.06, 0.25]}]]],
		["recorte_exterior", 0.9, [[0.3, {"pd": L(25, 40, 10, 25, -30), "tr": [15, 10, 0], "p": [-0.05, -0.1, 0.0]}],
			[0.55, {"g": [0, 0, -45], "p": [0.15, -0.08, 0.1]}], [0.8, {"g": [0, 0, -45], "p": [0.3, -0.06, 0.25]}]]],
		["media_luna", 1.4, [[0.3, {"pd": L(30, 35, 0, -20, 20), "p": [0.1, -0.08, 0.1]}], [0.7, {"p": [0.45, -0.06, 0.5], "tr": [18, 10, 0], "pi": L(45, 60), "pd": L(-15, 40)}],
			[1.1, {"p": [0.1, -0.06, 0.9], "tr": [18, -10, 0], "pd": L(45, 60), "pi": L(-15, 40)}]]],
		["finta_hombro", 0.9, [[0.3, {"tr": [15, 28, 0], "cu": [0, -20], "p": [0.1, -0.1, 0.0], "bd": [0, 20, 40], "bi": [10, 55, 30]}],
			[0.55, {"tr": [15, -15, 0], "p": [-0.2, -0.08, 0.1], "cu": [0, 10]}], [0.8, {"p": [-0.3, -0.06, 0.25], "cu": [0, 0]}]]],
		["salto_entrada", 1.0, [[0.25, {"p": [0.0, -0.15, 0.0], "pd": L(40, 70), "pi": L(40, 70)}],
			[0.5, {"p": [0.0, 0.45, 0.3], "pd": L(80, 110, 20), "pi": L(70, 100, 20), "bi": [20, 80, 30], "bd": [20, 80, 30]}],
			[0.8, {"p": [0.0, -0.12, 0.6], "pd": L(40, 60), "pi": L(40, 60)}]]],
		["giro_suela", 1.1, [[0.25, {"pd": L(20, 30, -25)}], [0.45, {"g": [0, 0, 90], "pd": L(10, 30, -20, 20)}], [0.65, {"g": [0, 0, 180]}],
			[0.85, {"g": [0, 0, 270], "pi": L(20, 35, -20)}], [1.05, {"g": [0, 0, 355]}]]],
		["autopase", 1.1, [[0.25, {"pd": L(-20, 60, 25)}], [0.4, {"pd": L(40, 20, 20), "tr": [15, 0, 0]}],
			[0.7, {"tr": [26, 0, 0], "p": [0.0, -0.1, 0.5], "pi": L(45, 60), "pd": L(-15, 40), "bd": [45, 20, 80], "bi": [-35, 20, 80]}],
			[0.95, {"p": [0.0, -0.1, 1.0], "pd": L(45, 60), "pi": L(-15, 40), "bi": [45, 20, 80], "bd": [-35, 20, 80]}]]],
		["proteger_espalda", 1.3, [[0.3, {"g": [0, 0, 170], "tr": [20, 0, 0], "pd": L(30, 55, 0, 15), "pi": L(30, 55, 0, 15), "bi": [-10, 45, 60], "bd": [-10, 45, 60]}],
			[0.8, {"g": [0, 0, 175], "pd": L(20, 35, -20, 10)}], [1.1, {"g": [0, 0, 100], "p": [0.2, -0.06, 0.1]}]]],
		["bicicleta_frenada", 1.2, [[0.3, {"pd": L(30, 40, 10, -25), "p": [0.0, -0.1, -0.05]}], [0.5, {"pd": L(35, 50, 10, 30), "tr": [8, 12, 0]}],
			[0.7, {"pd": L(20, 30, -20)}], [1.0, {"tr": [26, 0, 0], "p": [0.0, -0.1, 0.45], "pi": L(45, 60), "pd": L(-15, 40)}]]],
	]

# =============================================================================
#  EXPRESIVOS, LESIONES Y ÁRBITRO
# =============================================================================

static func expresivos() -> Array:
	return [
		## La palmada del cambio (M-104): la derecha arriba y delante, choca y baja.
		["chocar_mano", 1.2, false, [{"t": 0.3, "bd": [118, 18, 30], "tr": [0, -8, 0]}, {"t": 0.62, "bd": [128, 14, 18]}, {"t": 1.2, "bd": [2, 6, 8], "tr": [0, 0, 0]}]],
		## El saludo de capitanes y árbitro (M-160): la derecha adelante, dos sacudidas.
		["dar_mano", 1.6, false, [{"t": 0.35, "bd": [52, 6, 34], "cu": [8, 0]}, {"t": 0.6, "bd": [46, 6, 30]}, {"t": 0.8, "bd": [54, 6, 36]},
			{"t": 1.05, "bd": [48, 6, 31]}, {"t": 1.6, "bd": [2, 6, 8], "cu": [0, 0]}]],
		["pulgar_arriba", 1.4, false,[{"t": 0.3, "bd": [40, 14, 80]}, {"t": 1.1, "bd": [40, 14, 80]}, {"t": 1.4, "bd": [2, 6, 8]}]],
		["llamar_hinchada", 2.0, true, [{"t": 0.0, "bi": [10, 150, 30], "bd": [10, 150, 30], "cu": [-15, 0]}, {"t": 0.5, "bi": [10, 120, 80], "bd": [10, 120, 80]},
			{"t": 1.0, "bi": [10, 150, 30], "bd": [10, 150, 30]}, {"t": 1.5, "bi": [10, 120, 80], "bd": [10, 120, 80]}, {"t": 2.0, "bi": [10, 150, 30], "bd": [10, 150, 30], "cu": [-15, 0]}]],
		["pedir_perdon", 1.6, false, [{"t": 0.3, "bi": [40, 30, 90], "bd": [40, 30, 90], "cu": [10, 0], "tr": [6, 0, 0]}, {"t": 1.3, "bi": [40, 30, 90], "bd": [40, 30, 90]}, {"t": 1.6, "bi": [2, 6, 8], "bd": [2, 6, 8], "cu": [0, 0], "tr": [0, 0, 0]}]],
		["discutir_arbitro", 2.0, false, [{"t": 0.3, "bd": [70, 15, 10], "bi": [20, 45, 60], "tr": [10, 0, 0]}, {"t": 0.8, "bd": [60, 20, 40]}, {"t": 1.2, "bd": [70, 15, 10], "bi": [30, 55, 70]},
			{"t": 1.7, "bd": [40, 50, 50], "bi": [40, 50, 50], "cu": [-10, 15]}, {"t": 2.0, "bd": [2, 6, 8], "bi": [2, 6, 8], "tr": [0, 0, 0], "cu": [0, 0]}]],
		["agradecer_palmas", 2.0, false, [{"t": 0.4, "bi": [30, 150, 10], "bd": [30, 150, 10], "cu": [-20, 0]}, {"t": 0.8, "bi": [45, 20, 60], "bd": [45, 5, 60]},
			{"t": 1.2, "bi": [45, 12, 60], "bd": [45, 12, 60]}, {"t": 2.0, "bi": [2, 6, 8], "bd": [2, 6, 8], "cu": [0, 0]}]],
		["mano_oido", 1.8, false, [{"t": 0.3, "bd": [10, 110, 140], "cu": [0, -20], "tr": [0, 10, 0]}, {"t": 1.5, "bd": [10, 110, 140]}, {"t": 1.8, "bd": [2, 6, 8], "cu": [0, 0], "tr": [0, 0, 0]}]],
		["silencio_dedo", 1.6, false, [{"t": 0.3, "bd": [28, 8, 140], "cu": [0, 0]}, {"t": 1.3, "bd": [28, 8, 140]}, {"t": 1.6, "bd": [2, 6, 8]}]],
		["corazon_manos", 1.8, false, [{"t": 0.4, "bi": [70, 25, 95], "bd": [70, 25, 95]}, {"t": 1.5, "bi": [70, 25, 95], "bd": [70, 25, 95]}, {"t": 1.8, "bi": [2, 6, 8], "bd": [2, 6, 8]}]],
		["cruzar_brazos", 2.0, true, [{"t": 0.0, "bi": [18, -12, 100], "bd": [18, -12, 100], "cu": [0, 0]}, {"t": 1.0, "cu": [5, 10]}, {"t": 2.0, "bi": [18, -12, 100], "bd": [18, -12, 100], "cu": [0, 0]}]],
		["patada_al_aire", 1.2, false, [{"t": 0.2, "pd": L(-25, 70, 20)}, {"t": 0.4, "pd": L(55, 10, 30), "tr": [-8, 0, 0], "bi": [20, 60, 30], "bd": [-20, 30, 20]}, {"t": 0.8, "pd": L(5, 12)}, {"t": 1.2, "tr": [10, 0, 0], "cu": [20, 0]}]],
		["cuclillas_lamento", 2.4, false, [{"t": 0.5, "p": [0.0, -0.45, -0.1], "pd": L(90, 130, -30), "pi": L(90, 130, -30), "tr": [30, 0, 0], "bi": [60, 10, 120], "bd": [60, 10, 120], "cu": [30, 0]},
			{"t": 2.0, "p": [0.0, -0.45, -0.1]}, {"t": 2.4, "p": [0.0, 0.0, 0.0], "pd": L(0), "pi": L(0), "tr": [0, 0, 0], "bi": [2, 6, 8], "bd": [2, 6, 8], "cu": [0, 0]}]],
		["rodillas_brazos_arriba", 2.4, false, [{"t": 0.4, "p": [0.0, -0.5, 0.0], "pd": L(0, 90, 40), "pi": L(0, 90, 40), "bi": [10, 150, 20], "bd": [10, 150, 20], "cu": [-35, 0], "tr": [-15, 0, 0]},
			{"t": 2.0, "p": [0.0, -0.5, 0.0]}, {"t": 2.4, "p": [0.0, -0.5, 0.0]}]],
		["avion", 2.0, true, [{"t": 0.0, "bi": [0, 85, 0], "bd": [0, 85, 0], "tr": [8, 18, 0], "pd": L(20, 40), "pi": L(-10, 20)}, {"t": 0.5, "tr": [8, -18, 0], "pi": L(20, 40), "pd": L(-10, 20)},
			{"t": 1.0, "tr": [8, 18, 0], "pd": L(20, 40), "pi": L(-10, 20)}, {"t": 1.5, "tr": [8, -18, 0], "pi": L(20, 40), "pd": L(-10, 20)}, {"t": 2.0, "bi": [0, 85, 0], "bd": [0, 85, 0], "tr": [8, 18, 0], "pd": L(20, 40), "pi": L(-10, 20)}]],
		["puno_rabia", 1.3, false, [{"t": 0.25, "bd": [20, 30, 130], "tr": [15, 0, 0], "cu": [-10, 0]}, {"t": 0.45, "bd": [-15, 15, 120], "p": [0.0, -0.08, 0.0], "pd": L(15, 30), "pi": L(15, 30)}, {"t": 1.0, "bd": [-15, 15, 120]}, {"t": 1.3, "bd": [2, 6, 8], "tr": [0, 0, 0]}]],
		["aplauso_arriba", 1.6, true, [{"t": 0.0, "bi": [30, 150, 20], "bd": [30, 150, 20]}, {"t": 0.4, "bi": [30, 165, 30], "bd": [30, 165, 30]}, {"t": 0.8, "bi": [30, 150, 20], "bd": [30, 150, 20]}, {"t": 1.2, "bi": [30, 165, 30], "bd": [30, 165, 30]}, {"t": 1.6, "bi": [30, 150, 20], "bd": [30, 150, 20]}]],
		["deslizar_rodillas", 2.2, false, [{"t": 0.3, "p": [0.0, -0.15, 0.3], "pd": L(40, 60), "pi": L(-10, 40)}, {"t": 0.6, "p": [0.0, -0.5, 0.8], "pd": L(0, 95, 40), "pi": L(0, 95, 40), "tr": [-25, 0, 0], "bi": [0, 100, 20], "bd": [0, 100, 20], "cu": [-30, 0]},
			{"t": 1.4, "p": [0.0, -0.5, 1.8]}, {"t": 2.2, "p": [0.0, -0.5, 1.9], "tr": [-30, 0, 0]}]],
	]

static func lesiones() -> Array:
	return [
		["lesion_tobillo", 3.0, true, [{"t": 0.0, "p": [0.0, -0.82, 0.0], "g": [-80, 0, 0], "pd": L(80, 110, 10), "pi": L(20, 30), "bi": [60, 20, 80], "bd": [70, 20, 70], "tr": [40, 0, 0], "cu": [20, 0]},
			{"t": 1.5, "p": [0.0, -0.82, 0.0], "g": [-75, 10, 0], "pd": L(85, 115, 15), "tr": [45, 0, 0], "cu": [30, 15]},
			{"t": 3.0, "p": [0.0, -0.82, 0.0], "g": [-80, 0, 0], "pd": L(80, 110, 10), "tr": [40, 0, 0], "cu": [20, 0]}]],
		["lesion_rodilla", 3.0, true, [{"t": 0.0, "p": [0.0, -0.82, 0.0], "g": [-85, -20, 0], "pd": L(70, 90), "pi": L(10, 20), "bi": [55, 25, 60], "bd": [55, 25, 60], "tr": [35, 0, 0], "cu": [25, 0]},
			{"t": 1.5, "g": [-80, -30, 0], "pd": L(75, 100), "cu": [15, 20]},
			{"t": 3.0, "p": [0.0, -0.82, 0.0], "g": [-85, -20, 0], "pd": L(70, 90), "cu": [25, 0]}]],
		["lesion_isquio", 2.0, false, [{"t": 0.0, "pd": L(30, 40), "pi": L(-10, 20), "p": [0.0, 0.0, 0.0]}, {"t": 0.25, "pd": L(10, 60, 10), "tr": [30, 0, 0], "p": [0.0, -0.1, 0.3], "bd": [-30, 20, 30], "cu": [20, 0]},
			{"t": 0.6, "pd": L(5, 45, 10), "tr": [35, 0, 0], "p": [0.0, -0.12, 0.4], "bd": [-40, 15, 40], "bi": [10, 30, 30]}, {"t": 2.0, "p": [0.0, -0.12, 0.45], "tr": [38, 0, 0], "pd": L(5, 50)}]],
		["cojear", 1.4, true, [{"t": 0.0, "pd": L(15, 25, 20), "pi": L(-10, 15), "p": [0.0, -0.02, 0.0], "tr": [8, -8, 0], "cu": [10, 0]},
			{"t": 0.35, "pd": L(0, 15, 15), "pi": L(5, 20), "p": [0.0, -0.06, 0.08], "tr": [10, 10, 0]},
			{"t": 0.7, "pd": L(-10, 25, 25), "pi": L(20, 30), "p": [0.0, -0.01, 0.16], "tr": [8, -8, 0]},
			{"t": 1.05, "pd": L(10, 20, 20), "pi": L(-5, 15), "p": [0.0, -0.05, 0.24], "tr": [10, 10, 0]},
			{"t": 1.4, "pd": L(15, 25, 20), "pi": L(-10, 15), "p": [0.0, -0.02, 0.32], "tr": [8, -8, 0], "cu": [10, 0]}]],
		["tendido", 3.0, true, [{"t": 0.0, "p": [0.0, -0.85, 0.0], "g": [-90, 0, 0], "pd": L(10, 20), "pi": L(30, 50), "bi": [-10, 60, 30], "bd": [-10, 40, 40], "cu": [-5, 10]},
			{"t": 1.5, "p": [0.0, -0.85, 0.0], "g": [-90, 0, 0], "cu": [-5, -10]}, {"t": 3.0, "p": [0.0, -0.85, 0.0], "g": [-90, 0, 0], "cu": [-5, 10]}]],
		["sentado_dolorido", 3.0, true, [{"t": 0.0, "p": [0.0, -0.78, -0.1], "pd": L(80, 90), "pi": L(85, 20), "tr": [30, 0, 0], "bi": [60, 15, 60], "bd": [60, 15, 60], "cu": [30, 0]},
			{"t": 1.5, "tr": [35, 5, 0], "cu": [35, 10]}, {"t": 3.0, "p": [0.0, -0.78, -0.1], "tr": [30, 0, 0], "cu": [30, 0]}]],
		["calambre", 3.0, true, [{"t": 0.0, "p": [0.0, -0.8, -0.1], "pd": L(85, 10, -30), "pi": L(80, 80), "tr": [40, 0, 0], "bd": [75, 10, 10], "bi": [60, 20, 40], "cu": [20, 0]},
			{"t": 1.5, "tr": [48, 0, 0], "bd": [80, 8, 5], "pd": L(85, 8, -35)}, {"t": 3.0, "p": [0.0, -0.8, -0.1], "tr": [40, 0, 0], "bd": [75, 10, 10], "pd": L(85, 10, -30)}]],
		["caida_fea", 1.6, false, [{"t": 0.0, "pd": L(30, 40), "pi": L(-10, 20)}, {"t": 0.25, "p": [0.0, -0.3, 0.4], "g": [40, 10, 0], "bi": [60, 30, 20], "bd": [60, 30, 20], "pd": L(-10, 30), "pi": L(20, 60)},
			{"t": 0.6, "p": [0.0, -0.8, 0.9], "g": [85, 20, 0], "bi": [70, 60, 60], "bd": [70, 60, 60], "cu": [-30, 0]}, {"t": 1.6, "p": [0.0, -0.82, 1.0], "g": [88, 25, 0], "pd": L(10, 40), "pi": L(20, 50)}]],
	]

static func arbitro() -> Array:
	return [
		["arbitro_silbato", 1.2, false, [{"t": 0.3, "bd": [50, 20, 140], "cu": [-5, 0]}, {"t": 0.9, "bd": [50, 20, 140]}, {"t": 1.2, "bd": [2, 6, 8], "cu": [0, 0]}]],
		["arbitro_ventaja", 1.6, false, [{"t": 0.3, "bi": [70, 25, 5], "bd": [70, 25, 5], "cu": [-5, 0]}, {"t": 1.3, "bi": [75, 22, 5], "bd": [75, 22, 5]}, {"t": 1.6, "bi": [2, 6, 8], "bd": [2, 6, 8]}]],
		["arbitro_penal", 1.8, false, [{"t": 0.3, "bd": [60, 20, 5], "tr": [5, 0, 0]}, {"t": 0.35, "bi": [50, 20, 140]}, {"t": 1.4, "bd": [55, 20, 5], "bi": [50, 20, 140]}, {"t": 1.8, "bd": [2, 6, 8], "bi": [2, 6, 8], "tr": [0, 0, 0]}]],
		["arbitro_corner", 1.6, false, [{"t": 0.3, "bd": [30, 120, 5], "cu": [0, -30]}, {"t": 1.3, "bd": [30, 120, 5]}, {"t": 1.6, "bd": [2, 6, 8], "cu": [0, 0]}]],
		["arbitro_saque_meta", 1.6, false, [{"t": 0.3, "bd": [30, 50, 5], "tr": [5, 0, 0], "cu": [10, -20]}, {"t": 1.3, "bd": [30, 50, 5]}, {"t": 1.6, "bd": [2, 6, 8], "tr": [0, 0, 0], "cu": [0, 0]}]],
		["arbitro_var", 2.2, false, [{"t": 0.3, "bi": [70, 40, 50], "bd": [70, 40, 50]}, {"t": 0.7, "bi": [70, 70, 30], "bd": [70, 70, 30]}, {"t": 1.1, "bi": [55, 70, 30], "bd": [55, 70, 30]},
			{"t": 1.5, "bi": [55, 40, 50], "bd": [55, 40, 50]}, {"t": 1.8, "bi": [70, 40, 50], "bd": [70, 40, 50]}, {"t": 2.2, "bi": [2, 6, 8], "bd": [2, 6, 8]}]],
		["arbitro_dispersar", 1.6, true, [{"t": 0.0, "bi": [60, 30, 20], "bd": [60, 30, 20]}, {"t": 0.4, "bi": [50, 70, 10], "bd": [50, 70, 10]}, {"t": 0.8, "bi": [60, 30, 20], "bd": [60, 30, 20]},
			{"t": 1.2, "bi": [50, 70, 10], "bd": [50, 70, 10]}, {"t": 1.6, "bi": [60, 30, 20], "bd": [60, 30, 20]}]],
		["arbitro_tiempo_anadido", 1.8, false, [{"t": 0.4, "bi": [60, 10, 110], "bd": [60, 10, 110]}, {"t": 1.4, "bi": [60, 10, 110], "bd": [60, 10, 110]}, {"t": 1.8, "bi": [2, 6, 8], "bd": [2, 6, 8]}]],
		["arbitro_calma", 1.4, true, [{"t": 0.0, "bi": [40, 25, 30], "bd": [40, 25, 30], "tr": [4, 0, 0]}, {"t": 0.35, "bi": [30, 25, 20], "bd": [30, 25, 20]}, {"t": 0.7, "bi": [40, 25, 30], "bd": [40, 25, 30]},
			{"t": 1.05, "bi": [30, 25, 20], "bd": [30, 25, 20]}, {"t": 1.4, "bi": [40, 25, 30], "bd": [40, 25, 30], "tr": [4, 0, 0]}]],
		["arbitro_amonestar_hablar", 2.0, false, [{"t": 0.3, "bd": [45, 15, 90], "tr": [8, 0, 0], "cu": [8, 0]}, {"t": 0.8, "bd": [60, 15, 40]}, {"t": 1.3, "bd": [45, 15, 90]}, {"t": 2.0, "bd": [2, 6, 8], "tr": [0, 0, 0], "cu": [0, 0]}]],
		["asistente_bandera", 1.8, false, [{"t": 0.3, "bd": [10, 165, 0], "cu": [0, 0]}, {"t": 1.5, "bd": [10, 165, 0]}, {"t": 1.8, "bd": [2, 6, 8]}]],
		["asistente_fuera_juego", 1.8, false, [{"t": 0.3, "bd": [85, 10, 0]}, {"t": 1.5, "bd": [85, 10, 0]}, {"t": 1.8, "bd": [2, 6, 8]}]],
		["arbitro_correr_senalando", 1.0, true, [{"t": 0.0, "pd": L(35, 50), "pi": L(-15, 30), "p": [0.0, -0.03, 0.0], "bd": [70, 20, 10], "bi": [-20, 20, 70], "tr": [8, 0, 0]},
			{"t": 0.5, "pi": L(35, 50), "pd": L(-15, 30), "p": [0.0, -0.01, 0.0]},
			{"t": 1.0, "pd": L(35, 50), "pi": L(-15, 30), "p": [0.0, -0.03, 0.0], "bd": [70, 20, 10], "bi": [-20, 20, 70], "tr": [8, 0, 0]}]],
	]

## Todas, construidas (una vez por esqueleto).
static func todas(esq: Skeleton3D, pre: String) -> Dictionary:
	if _cache.has(pre):
		return _cache[pre]
	var r := {}
	for t: Array in TIROS:
		r[t[0]] = golpeo(esq, pre, t[1])
	for t: Array in PASES:
		r[t[0]] = golpeo(esq, pre, t[1])
	r["chilena"] = chilena(esq, pre)
	r["tijera"] = tijera(esq, pre)
	r["palomita"] = palomita(esq, pre)
	r["cabezazo_picado"] = cabezazo_picado(esq, pre)
	r["cabezazo_potente"] = cabezazo_potente(esq, pre)
	r["taconazo"] = taconazo(esq, pre)
	r["pase_pecho"] = pase_pecho(esq, pre)
	r["pase_cabeza"] = pase_cabeza(esq, pre)
	for t: Array in BARRIDAS:
		r[t[0]] = barrida(esq, pre, t[1])
	r["entrada_de_pie"] = entrada_de_pie(esq, pre)
	r["entrada_lateral_pie"] = entrada_lateral_pie(esq, pre)
	r["carga_hombro"] = carga_hombro(esq, pre)
	r["entrada_cuerpo"] = entrada_cuerpo(esq, pre)
	r["anticipacion"] = anticipacion(esq, pre)
	r["zancadilla"] = zancadilla(esq, pre)
	r["entrada_tijera"] = entrada_tijera(esq, pre)
	r["barrida_rodilla"] = barrida_rodilla(esq, pre)
	r["estirada_alta_izq"] = estirada(esq, pre, -1.0, 1.0)
	r["estirada_alta_der"] = estirada(esq, pre, 1.0, 1.0)
	r["estirada_baja_izq"] = estirada(esq, pre, -1.0, 0.0)
	r["estirada_baja_der"] = estirada(esq, pre, 1.0, 0.0)
	r["estirada_media_izq"] = estirada(esq, pre, -1.0, 0.5)
	r["estirada_media_der"] = estirada(esq, pre, 1.0, 0.5)
	r["blocaje_alto"] = blocaje_alto(esq, pre)
	r["punos"] = punos(esq, pre)
	r["achique"] = achique(esq, pre)
	r["blocaje_rasante"] = blocaje_rasante(esq, pre)
	r["parada_pie"] = parada_pie(esq, pre)
	r["salida_aerea"] = salida_aerea(esq, pre)
	r["mano_cambiada"] = mano_cambiada(esq, pre)
	r["portero_lateral_der"] = portero_lateral(esq, pre, 1.0)
	r["portero_lateral_izq"] = portero_lateral(esq, pre, -1.0)
	r["defensor_pica_der"] = defensor_pica(esq, pre, 1.0)
	r["defensor_pica_izq"] = defensor_pica(esq, pre, -1.0)
	r["duelo_hombro_der"] = duelo_hombro(esq, pre, 1.0)
	r["duelo_hombro_izq"] = duelo_hombro(esq, pre, -1.0)
	r["duelo_empujado_der"] = duelo_empujado(esq, pre, 1.0)
	r["duelo_empujado_izq"] = duelo_empujado(esq, pre, -1.0)
	r["duelo_agarron"] = duelo_agarron(esq, pre)
	r["duelo_forcejeo"] = duelo_forcejeo(esq, pre)
	for t: Array in regates():
		r[t[0]] = regate(esq, pre, float(t[1]), t[2])
	for lista: Array in [expresivos(), lesiones(), arbitro()]:
		for t: Array in lista:
			var an := armar(esq, pre, float(t[1]), bool(t[2]), t[3])
			r[t[0]] = an
	_cache[pre] = r
	return r

static func regate(esq: Skeleton3D, pre: String, dur: float, claves: Array) -> Animation:
	var todas: Array = [_k(0.0, {})]
	for c: Array in claves:
		var k := _k(float(c[0]), c[1])
		var p: Array = k["p"]
		k["p"] = [float(p[0]) * 0.8, float(p[1]), float(p[2]) * AVANCE_REGATE]
		todas.append(k)
	todas.append(_k(dur, {"p": [0.0, -0.06, 0.1]}))
	return armar(esq, pre, dur, false, todas)

# =============================================================================
#  LA LIBRERÍA
# =============================================================================

## Nombres por familia (para `AnimExtra.CATEGORIAS` y las pruebas).
static func familias() -> Dictionary:
	var f := {"tiro": [], "pase": [], "barrida": [], "atajada": [], "regate": [], "expresivo": [], "lesion": [], "arbitro": []}
	for t: Array in TIROS:
		f["tiro"].append(t[0])
	f["tiro"].append_array(["chilena", "tijera", "palomita", "cabezazo_picado", "cabezazo_potente"])
	for t: Array in PASES:
		f["pase"].append(t[0])
	f["pase"].append_array(["taconazo", "pase_pecho", "pase_cabeza"])
	for t: Array in BARRIDAS:
		f["barrida"].append(t[0])
	f["barrida"].append_array(["entrada_de_pie", "entrada_lateral_pie", "carga_hombro", "entrada_cuerpo", "anticipacion", "zancadilla", "entrada_tijera", "barrida_rodilla"])
	f["atajada"] = ["estirada_alta_izq", "estirada_alta_der", "estirada_baja_izq", "estirada_baja_der", "estirada_media_izq", "estirada_media_der",
		"blocaje_alto", "punos", "achique", "blocaje_rasante", "parada_pie", "salida_aerea", "mano_cambiada",
		"portero_lateral_der", "portero_lateral_izq"]
	for t: Array in regates():
		f["regate"].append(t[0])
	for t: Array in expresivos():
		f["expresivo"].append(t[0])
	for t: Array in lesiones():
		f["lesion"].append(t[0])
	for t: Array in arbitro():
		f["arbitro"].append(t[0])
	return f
