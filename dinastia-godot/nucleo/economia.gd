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
	"POR": 1.0, "NED": 0.95, "BEL": 0.85, "CRO": 0.5, "DEN": 0.7,
	"TUR": 0.95, "SCO": 0.7, "SUI": 0.8, "AUT": 0.75, "GRE": 0.85, "QAT": 0.9,
	"SWE": 0.8, "NOR": 0.85, "POL": 0.8, "CZE": 0.7, "ROU": 0.65, "SRB": 0.5, "UKR": 0.6, "CHN": 1.0,
	"ISR": 0.8, "RUS": 0.9, "HUN": 0.65, "SVK": 0.55, "BUL": 0.55, "UAE": 1.1, "IRN": 0.5,
	"NGA": 0.35, "GHA": 0.3, "SEN": 0.32, "CIV": 0.3, "ALG": 0.3, "TUN": 0.3, "CMR": 0.3, "CAN": 0.6, "CRC": 0.3, "IRL": 0.55,
	"WAL": 0.4, "SVN": 0.5, "JOR": 0.3, "CYP": 0.55, "IRQ": 0.3, "UZB": 0.4, "FIN": 0.6, "JAM": 0.2, "HON": 0.25, "PAN": 0.3, "NZL": 0.4, "MLI": 0.25,
	"BIH": 0.3, "MNE": 0.3, "ISL": 0.5, "EST": 0.4, "KAZ": 0.5, "AZE": 0.5, "BLR": 0.3, "LVA": 0.4, "ALB": 0.3, "MKD": 0.3, "GEO": 0.3, "LTU": 0.4, "NIR": 0.5, "LUX": 0.6,
	"THA": 0.5, "IDN": 0.4, "VIE": 0.35, "IND": 0.5, "MAS": 0.5, "BHR": 0.5, "OMA": 0.5, "COD": 0.2, "BFA": 0.2, "ZAM": 0.25, "GUI": 0.2, "KEN": 0.25, "ARM": 0.3, "MDA": 0.25, "ESA": 0.25, "GUA": 0.25,
	"KOS": 0.3, "MLT": 0.3, "FRO": 0.2, "AND": 0.15, "GIB": 0.15, "SMR": 0.1, "CPV": 0.2, "GAB": 0.2, "ANG": 0.25, "MOZ": 0.15, "UGA": 0.2, "TAN": 0.25, "LBY": 0.2, "BEN": 0.15, "TOG": 0.15, "CGO": 0.15, "ZIM": 0.2, "NAM": 0.2, "MAD": 0.15, "SYR": 0.2, "LBN": 0.3, "PLE": 0.15, "KGZ": 0.2, "TJK": 0.2, "PHI": 0.3, "SGP": 0.4, "HKG": 0.4, "KUW": 0.4, "HAI": 0.15, "CUW": 0.2, "TRI": 0.25, "SUR": 0.15, "NCA": 0.2,
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
