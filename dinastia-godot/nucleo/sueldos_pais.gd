class_name SueldosPais
extends RefCounted
## LO QUE SE COBRA EN CADA LIGA (13-11-2026, decisión del dueño: «recalibrar la economía de las ligas chicas»).
## El sueldo de un futbolista salía solo de su valor, igual en todo el mundo; los ingresos de un club, en cambio, dependen de
## su liga. Medido al empezar (`pruebas/_sonda/sonda_sueldos_todos.tscn`): en 115 de 135 países la masa salarial pasaba del 34 %
## de los ingresos previstos, con casi todos los clubes en rojo (Uruguay 100 %, Paraguay 89 %, San Marino 248 %). Aquí va,
## por país, el factor que deja la mediana de la liga en el 28 %: lo aplica `Jugador.sueldo_de_valor()` según el país del club.
## Las ligas que ya estaban sanas no aparecen (factor 1). Para rehacer la tabla: correr la sonda con la tabla vacía y `herramientas/sueldos_pais.py` (raíz del repositorio).
const OBJETIVO := 28
const FACTOR := {
	"ALB": 0.4, "ALG": 0.72, "AND": 0.16, "ANG": 0.47, "ARM": 0.25, "AUS": 0.8, "AUT": 0.67, "AZE": 0.48, "BEL": 0.76, "BEN": 0.19,
	"BFA": 0.31, "BHR": 0.39, "BIH": 0.41, "BLR": 0.4, "BOL": 0.35, "BUL": 0.58, "CAN": 0.49, "CGO": 0.31, "CHI": 0.65, "CIV": 0.34,
	"CMR": 0.37, "COD": 0.52, "COL": 0.61, "CPV": 0.17, "CRC": 0.44, "CRO": 0.53, "CUW": 0.24, "CYP": 0.56, "CZE": 0.58, "DEN": 0.64,
	"ECU": 0.36, "EGY": 0.57, "ESA": 0.42, "EST": 0.23, "FIN": 0.43, "FRO": 0.26, "GAB": 0.25, "GEO": 0.26, "GHA": 0.36, "GIB": 0.16,
	"GRE": 0.78, "GUA": 0.49, "GUI": 0.26, "HAI": 0.26, "HKG": 0.32, "HON": 0.8, "HUN": 0.54, "IDN": 0.78, "IRL": 0.44, "IRN": 0.72,
	"ISL": 0.33, "ISR": 0.74, "JAM": 0.26, "JOR": 0.5, "KAZ": 0.5, "KEN": 0.31, "KGZ": 0.29, "KOS": 0.26, "KUW": 0.74, "LBN": 0.33,
	"LBY": 0.5, "LTU": 0.28, "LUX": 0.29, "LVA": 0.21, "MAD": 0.23, "MAR": 0.64, "MDA": 0.25, "MKD": 0.41, "MLT": 0.28, "MNE": 0.22,
	"MOZ": 0.4, "NAM": 0.25, "NCA": 0.39, "NED": 0.76, "NGA": 0.5, "NIR": 0.36, "NOR": 0.68, "NZL": 0.32, "OMA": 0.47, "PAN": 0.26,
	"PAR": 0.31, "PER": 0.47, "PHI": 0.32, "PLE": 0.26, "POL": 0.8, "POR": 0.76, "QAT": 0.74, "ROU": 0.78, "RSA": 0.64, "SCO": 0.68,
	"SEN": 0.32, "SGP": 0.34, "SMR": 0.11, "SRB": 0.52, "SUI": 0.72, "SUR": 0.18, "SVK": 0.49, "SVN": 0.46, "SWE": 0.72, "SYR": 0.65,
	"THA": 0.57, "TJK": 0.49, "TOG": 0.42, "TRI": 0.47, "TUN": 0.55, "UAE": 0.74, "UGA": 0.19, "UKR": 0.55, "URU": 0.28, "USA": 0.74,
	"UZB": 0.68, "VIE": 0.8, "WAL": 0.32, "ZAM": 0.47, "ZIM": 0.46,
}

static func de(pais: String) -> float:
	return float(FACTOR.get(pais, 1.0))

## El factor del club donde juega `j` (1 si está libre o no se conoce su club).
static func del_jugador(j: Jugador) -> float:
	if j == null or j.club_id == "":
		return 1.0
	var c: Variant = LeyesPais.clubes_mundo.get(j.club_id)
	return de((c as Club).pais) if c is Club else 1.0
