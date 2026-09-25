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
