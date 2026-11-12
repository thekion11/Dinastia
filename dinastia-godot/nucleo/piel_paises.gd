class_name PielPaises
extends RefCounted
## LA PIEL Y EL PELO DE LOS PAÍSES AÑADIDOS DESPUÉS (12-11-2026). `Cara.TONO_MEDIO`, `Cara.RUBIOS` y `OlaGrada.PIEL_SESGO` solo
## tenían los 50 primeros países; los otros 88 de `datos/paises.json` caían en el valor por defecto (tono ~2,5 de 7, piel clara y
## a veces rubio) y, por ejemplo, los futbolistas inventados de Senegal salían casi blancos y pelirrojos (hallazgo de la sesión 14).
## Aquí el tono medio aproximado de los futbolistas de cada uno (índice en `Cara.PIELES`, 0 claro … 7 oscuro), la proporción de
## rubios entre los de piel clara y, para la grada, el sesgo equivalente. Es una aproximación por población, no un dato por persona.

const TONO := {
	## África subsahariana
	"ANG": 6.3, "BEN": 6.4, "BFA": 6.4, "CGO": 6.3, "CIV": 6.3, "CMR": 6.3, "COD": 6.4, "GAB": 6.3, "GAM": 6.4, "GHA": 6.3,
	"GUI": 6.4, "KEN": 6.3, "MLI": 6.3, "MOZ": 6.2, "NGA": 6.3, "SEN": 6.4, "TAN": 6.2, "TOG": 6.3, "UGA": 6.3, "ZAM": 6.2,
	"ZIM": 6.2, "MAD": 4.8, "NAM": 5.4, "CPV": 4.6,
	## Norte de África y Oriente Medio
	"ALG": 3.6, "TUN": 3.5, "LBY": 3.7, "BHR": 3.4, "KUW": 3.4, "OMA": 3.6, "IRQ": 3.1, "JOR": 3.0, "LBN": 2.8, "SYR": 2.9,
	"PLE": 3.0,
	## Caribe, Centroamérica y Norteamérica
	"JAM": 6.0, "HAI": 6.2, "TRI": 5.0, "CUR": 5.0, "CUW": 5.0, "SUR": 5.0, "CRC": 3.2, "GUA": 3.6, "HON": 3.7, "NCA": 3.5,
	"ESA": 3.6, "PAN": 4.0, "CAN": 2.4,
	## Europa
	"ALB": 2.0, "AND": 1.7, "ARM": 2.2, "AZE": 2.4, "BIH": 1.8, "BLR": 1.4, "CYP": 2.2, "EST": 1.2, "FIN": 1.2, "FRO": 1.1,
	"GEO": 2.2, "GIB": 1.8, "IRL": 1.4, "ISL": 1.1, "KOS": 2.0, "KVX": 2.0, "LTU": 1.3, "LUX": 1.9, "LVA": 1.3, "MDA": 1.6,
	"MKD": 1.9, "MLT": 2.2, "MNE": 1.8, "NIR": 1.4, "SMR": 1.7, "SVN": 1.5, "WAL": 1.6,
	## Asia y Oceanía
	"HKG": 1.8, "IDN": 3.4, "IND": 3.8, "KAZ": 2.2, "KGZ": 2.3, "TJK": 2.4, "UZB": 2.4, "MAS": 3.2, "PHI": 3.2, "SGP": 2.3,
	"THA": 3.0, "VIE": 2.6, "NZL": 2.0,
}

const RUBIOS := {"FIN": 0.42, "ISL": 0.42, "FRO": 0.38, "EST": 0.32, "LTU": 0.26, "LVA": 0.26, "IRL": 0.2, "NIR": 0.2,
	"WAL": 0.18, "NZL": 0.15, "CAN": 0.15, "BLR": 0.22, "MDA": 0.1, "SVN": 0.15, "LUX": 0.18, "KAZ": 0.04, "GEO": 0.03,
	"ARM": 0.02, "AZE": 0.02}

## El tono medio del país, o `defecto` si no está aquí.
static func tono(pais: String, defecto: float) -> float:
	return float(TONO.get(pais, defecto))

## La proporción de rubios entre los de piel clara, o `defecto`. Donde la piel es oscura casi no hay (y solo cuenta con piel clara).
static func rubios(pais: String, defecto: float) -> float:
	if RUBIOS.has(pais):
		return float(RUBIOS[pais])
	return 0.0 if TONO.has(pais) and float(TONO[pais]) >= 3.0 else defecto

## El sesgo de la grada (`OlaGrada.PIEL_SESGO`: tono medio = 7 · 0,5^sesgo) que da ese tono medio, o `defecto`.
static func sesgo(pais: String, defecto: float) -> float:
	if not TONO.has(pais):
		return defecto
	return clampf(log(7.0 / maxf(float(TONO[pais]), 0.3)) / log(2.0), 0.05, 3.0)
