class_name Viajes
extends RefCounted
## LO QUE CUESTA JUGAR: EL DÍA DE PARTIDO EN CASA Y EL VIAJE A DOMICILIO (26-10, pedido del dueño: «calcularlo
## en base a la distancia y los costos de la vida real»). Antes era un 30 % plano de la taquilla y los viajes
## iban sin desglosar dentro de «Operación». Ahora cada coste sale de una cuenta con precios reales:
##   · CASA: seguridad (1 vigilante cada 70 personas), limpieza, personal de puertas y hospitalidad, servicio
##     sanitario y seguro, y abrir el estadio (luz, agua, césped, marcador: depende del AFORO, haya o no gente).
##   · VISITA: distancia entre las dos sedes (haversine sobre `datos/geografia.json`; dentro de un mismo país, los
##     km medios de esa liga) → autocar hasta 1.000 km, avión comercial hasta 3.500, chárter más allá; noches de
##     hotel y dietas de toda la delegación (jugadores + cuerpo técnico), según el coste de la vida del destino.
## Los precios están en EUROS REALES con España = 1,0 y se escalan con el coste de la vida del país (elevado a 0,6:
## la mano de obra cambia mucho de un país a otro; el combustible, los aviones y los focos, mucho menos).
## ESCALA_JUEGO: en el juego una entrada rinde ~84 EUR por espectador (la taquilla ×3,5 lleva dentro palcos,
## abonos y hospitalidad), unas seis veces lo real de un club chileno; los costes se multiplican por lo mismo para
## que el balance siga en pie. Lo que sí es real es la PROPORCIÓN entre países, estadios y distancias.

const RUTA := "res://datos/geografia.json"
static var _tabla: Dictionary = {}

const VIDA_DEFECTO := 0.7
const KM_LOCAL_DEFECTO := 400.0
const EXPONENTE_VIDA := 0.6
## Anclada para que el día de partido de un club medio chileno (rep 70, 20.000 de aforo, ~70 % lleno) cueste
## lo mismo que el 30 % de antes (medido por `pruebas/banco/finanzas`).
const ESCALA_JUEGO := 6.5

# --- casa (euros reales, España = 1,0) ---
const GENTE_POR_VIGILANTE := 70.0
const VIGILANTE_EUR := 115.0
const LIMPIEZA_EUR := 0.55
const PERSONAL_EUR := 1.4
const SANITARIO_EUR := 0.35
const SANITARIO_FIJO_EUR := 1500.0
const APERTURA_EUR_BUTACA := 0.45

# --- viaje ---
const BUS_EUR_KM := 1.9           ## autocar de 55 plazas con chófer, por km (la vuelta se cuenta aparte)
const PLAZAS_BUS := 55
const AVION_FIJO_EUR := 85.0      ## tasas y tarifa base por persona y tramo
const AVION_EUR_KM := 0.085
const CHARTER_FIJO_EUR := 14000.0 ## un chárter de pasillo único: ~11.000 EUR por hora de vuelo, a ~850 km/h
const CHARTER_EUR_KM := 13.0
const HOTEL_NOCHE_EUR := 105.0    ## habitación y comidas, por persona
const DIETA_DIA_EUR := 38.0
const KM_BUS_NOCHE := 350.0       ## hasta aquí se va y se vuelve en el día
const KM_BUS_MAX := 1000.0
const KM_AVION_MAX := 3500.0

static func _datos() -> Dictionary:
	if _tabla.is_empty() and FileAccess.file_exists(RUTA):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
		if d is Dictionary:
			_tabla = (d as Dictionary).get("paises", {})
	return _tabla

static func _pais(codigo: String) -> Dictionary:
	return _datos().get(codigo, {})

## Coste de la vida con España = 1,0 (0,7 si el país no está en la tabla).
static func vida(codigo: String) -> float:
	return float(_pais(codigo).get("vida", VIDA_DEFECTO))

static func _precio(codigo: String) -> float:
	return pow(vida(codigo), EXPONENTE_VIDA)

## Kilómetros entre las sedes de dos países (en círculo máximo). Dentro del mismo país: los km medios de su liga.
static func distancia_km(a: String, b: String) -> float:
	var pa := _pais(a)
	if a == b:
		return float(pa.get("km_local", KM_LOCAL_DEFECTO))
	var pb := _pais(b)
	if pa.is_empty() or pb.is_empty():
		return 2500.0   ## sin datos: un vuelo mediano, ni local ni transoceánico
	var la1 := deg_to_rad(float(pa["lat"]))
	var la2 := deg_to_rad(float(pb["lat"]))
	var dl := deg_to_rad(float(pb["lon"]) - float(pa["lon"]))
	var h := pow(sin((la2 - la1) / 2.0), 2.0) + cos(la1) * cos(la2) * pow(sin(dl / 2.0), 2.0)
	return 2.0 * RADIO_TIERRA_KM * asin(minf(1.0, sqrt(h)))

const RADIO_TIERRA_KM := 6371.0

## Cómo se viaja: «bus», «avion» o «charter».
static func medio(km: float) -> String:
	if km <= KM_BUS_MAX:
		return "bus"
	return "avion" if km <= KM_AVION_MAX else "charter"

## Noches de hotel de la delegación: ninguna si se vuelve en el día.
static func noches(km: float) -> int:
	if km <= KM_BUS_NOCHE:
		return 0
	if km <= 2500.0:
		return 1
	return 2 if km <= 9000.0 else 3

## Quiénes viajan: 25 del plantel y cuerpo técnico, más en un club grande (rep 70 → 38; rep 85 → 45).
static func delegacion(rep: int) -> int:
	return clampi(int(round(38.0 + (float(rep) - 70.0) * 0.45)), 32, 52)

## Desglose del viaje de ida y vuelta de un club de `origen` a `destino`, EN EUROS REALES (sin escala del juego).
## {km, medio, noches, personas, transporte, hotel, dietas, total}
static func viaje_euros(origen: String, destino: String, rep: int) -> Dictionary:
	var km := distancia_km(origen, destino)
	var medio_ := medio(km)
	var n := noches(km)
	var personas := delegacion(rep)
	var transporte := 0.0
	match medio_:
		"bus":
			transporte = 2.0 * km * BUS_EUR_KM * ceilf(float(personas) / float(PLAZAS_BUS))
		"avion":
			transporte = 2.0 * float(personas) * (AVION_FIJO_EUR + km * AVION_EUR_KM)
		_:
			transporte = 2.0 * (CHARTER_FIJO_EUR + km * CHARTER_EUR_KM)
	transporte *= _precio(origen)
	## Un club grande se aloja mejor: el hotel sube con su peso (misma curva suave que la operación).
	var clase := pow(Eco.factor_club(float(rep)), 0.1)
	var hotel := float(n) * float(personas) * HOTEL_NOCHE_EUR * _precio(destino) * clase
	var dietas := float(personas) * DIETA_DIA_EUR * float(n + 1) * _precio(destino)
	return {"km": km, "medio": medio_, "noches": n, "personas": personas, "transporte": transporte,
		"hotel": hotel, "dietas": dietas, "total": transporte + hotel + dietas}

## El viaje en PUNTOS INTERNOS del juego (lo que se descuenta de la caja).
static func viaje_interno(origen: String, destino: String, rep: int) -> int:
	return int(round(float(viaje_euros(origen, destino, rep)["total"]) * ESCALA_JUEGO / Eco.ECO))

## Un día de partido en casa, en euros reales. `gente` = espectadores; `aforo` = butacas del estadio.
static func dia_de_partido_euros(pais: String, gente: int, aforo: int) -> Dictionary:
	var p := _precio(pais)
	var g := float(gente)
	var seguridad := g / GENTE_POR_VIGILANTE * VIGILANTE_EUR * p
	var limpieza := g * LIMPIEZA_EUR * p
	var personal := g * PERSONAL_EUR * p
	var sanitario := (g * SANITARIO_EUR + SANITARIO_FIJO_EUR) * p
	var apertura := float(aforo) * APERTURA_EUR_BUTACA * p
	return {"seguridad": seguridad, "limpieza": limpieza, "personal": personal, "sanitario": sanitario,
		"apertura": apertura, "total": seguridad + limpieza + personal + sanitario + apertura}

static func dia_de_partido_interno(pais: String, gente: int, aforo: int) -> int:
	return int(round(float(dia_de_partido_euros(pais, gente, aforo)["total"]) * ESCALA_JUEGO / Eco.ECO))
