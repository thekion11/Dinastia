extends Node
## La economia del juego, portada tal cual del HTML.
##
## Las constantes NO son inventadas ni redondeadas: son las mismas que ya estan
## equilibradas en `js/juego.js` (lineas 65-70), donde costaron una depuracion
## entera. Cambiar cualquiera de ellas mueve el juego completo -fichajes,
## sueldos, premios, el mercado de la IA-, asi que si un dia se tocan, se tocan
## aqui y se vuelve a correr el banco de pruebas, nunca al reves.
##
## La idea de fondo: el dinero es EXPONENCIAL sobre la reputacion del club y
## sobre la media del jugador, y las dos curvas pivotan en 70, que es el club y
## el jugador "medios". Un +1 de media no suma, multiplica.

const ECO := 12.0            ## 1 punto interno = 12 EUR en pantalla
const CURVA_CLUB := 1.134    ## cada punto de reputacion multiplica el dinero del club
const CURVA_JUG := 1.135     ## cada punto de media multiplica el valor del jugador
const REP_PIVOTE := 70.0
const OVR_PIVOTE := 70.0
const PRESUP_PIVOTE := 686000.0
const VALOR_PIVOTE := 436600.0

## Peso economico de cada liga. Un 80 en Inglaterra no cuesta lo que un 80 en Bolivia.
const TIER_PAIS := {
	"ESP": 1.9, "ENG": 2.4, "ITA": 1.6, "GER": 1.7, "FRA": 1.3,
	"BRA": 0.9, "ARG": 0.75, "CHI": 0.5, "COL": 0.42, "URU": 0.34,
	"PER": 0.3, "ECU": 0.3, "PAR": 0.26, "VEN": 0.2, "BOL": 0.18,
	"KSA": 1.15, "JPN": 0.85, "KOR": 0.6, "MEX": 0.9, "USA": 0.95,
	"EGY": 0.34, "MAR": 0.3, "RSA": 0.32, "AUS": 0.4,
}

# ---------------------------------------------------------------------------
#  LA MONEDA EN PANTALLA (25-9-2026)
# ---------------------------------------------------------------------------
## Hasta hoy todo el juego decía "EUR" fijo -anotado en el ROADMAP como
## "divisas seleccionables"- y había OCHO copias de la función que da formato al
## dinero, que no coincidían entre sí: la de la mesa de negociación del mercado
## ni siquiera pasaba por `ECO` y pintaba "$" con una cifra doce veces menor que
## la de la ficha del mismo jugador. Ahora hay una sola, aquí.
##
## La moneda es SOLO presentación: el motor sigue calculando en puntos internos
## y en euros de pantalla, y el tipo de cambio es FIJO -un manager no es una
## casa de cambio, y un tipo que se moviera cambiaría el valor de la plantilla
## entre una semana y otra sin que nadie hiciera nada-. Se elige en Ajustes y se
## guarda en `user://ajustes.cfg`.
const MONEDAS := {
	"EUR": {"nombre": "Euro", "por_euro": 1.0},
	"USD": {"nombre": "Dólar estadounidense", "por_euro": 1.08},
	"GBP": {"nombre": "Libra esterlina", "por_euro": 0.85},
	"CLP": {"nombre": "Peso chileno", "por_euro": 1010.0},
	"ARS": {"nombre": "Peso argentino", "por_euro": 1100.0},
	"BRL": {"nombre": "Real brasileño", "por_euro": 5.9},
	"MXN": {"nombre": "Peso mexicano", "por_euro": 20.0},
	"COP": {"nombre": "Peso colombiano", "por_euro": 4400.0},
	"PEN": {"nombre": "Sol peruano", "por_euro": 4.05},
	"JPY": {"nombre": "Yen japonés", "por_euro": 162.0},
}
const AJUSTES_RUTA := "user://ajustes.cfg"
var moneda: String = "EUR"

func _ready() -> void:
	var c := ConfigFile.new()
	if c.load(AJUSTES_RUTA) == OK:
		var m := String(c.get_value("moneda", "codigo", "EUR"))
		if MONEDAS.has(m):
			moneda = m

func elegir_moneda(codigo: String) -> void:
	if not MONEDAS.has(codigo):
		return
	moneda = codigo
	var c := ConfigFile.new()
	c.load(AJUSTES_RUTA)
	c.set_value("moneda", "codigo", codigo)
	c.save(AJUSTES_RUTA)

## Un monto INTERNO (el que manejan clubes, sueldos y fichajes) en texto:
## "79.2M EUR", "850k USD", "1.2MM CLP". Es la única función del juego que
## debería escribir dinero.
func dinero(interno: float) -> String:
	return dinero_euros(interno * ECO)

## Lo mismo para una cifra que ya viene en euros de pantalla (el precio de la
## entrada, por ejemplo, que se fija directamente en euros).
func dinero_euros(euros: float) -> String:
	var v := euros * float(MONEDAS[moneda]["por_euro"])
	var a := absf(v)
	var signo := "-" if v < 0.0 else ""
	var cifra := ""
	if a >= 1000000000.0:
		cifra = "%.1fMM" % (a / 1000000000.0)
	elif a >= 1000000.0:
		cifra = "%.1fM" % (a / 1000000.0)
	elif a >= 1000.0:
		cifra = "%dk" % int(a / 1000.0)
	else:
		cifra = "%d" % int(round(a))
	return "%s%s %s" % [signo, cifra, moneda]

func tier_pais(p: String) -> float:
	return TIER_PAIS.get(p, 0.4)

func factor_club(rep: float) -> float:
	return pow(CURVA_CLUB, (rep if rep > 0.0 else 70.0) - REP_PIVOTE)

## Cuanto vale la caja de referencia de un club de esta reputacion.
func ref_caja(rep: float) -> float:
	return PRESUP_PIVOTE * factor_club(rep)

## Escala un coste o ingreso OPERATIVO al tamano del club. Los premios de los
## torneos NO pasan por aqui a proposito: valen lo mismo para todos, que es lo
## que hace que una copa sea un salto real para un club chico.
func escalar(n: float, rep: float) -> int:
	return int(max(1.0, round(n * pow(factor_club(rep), 0.62))))

## La curva de edad. Un chico de 19 con techo alto se dispara; un veterano de 34
## no vale casi nada aunque siga rindiendo. El margen (potencial - media) solo
## cuenta hasta los 23: despues, lo que hay es lo que hay.
func factor_edad(edad: int, ovr: int, pot: int) -> float:
	var margen := float(max(0, pot - ovr))
	var f: float
	if edad <= 18: f = 1.55
	elif edad <= 21: f = 1.70
	elif edad <= 24: f = 1.55
	elif edad <= 27: f = 1.20
	elif edad <= 29: f = 1.00
	elif edad <= 31: f = 0.66
	elif edad <= 33: f = 0.38
	else: f = 0.16
	if edad <= 23:
		f *= 1.0 + min(margen, 18.0) * 0.022
	return f
