class_name RolTactico
extends RefCounted
## LOS ROLES POR JUGADOR (26-10-2026, sesión 5, fila 18 de la propuesta, primera parte: el núcleo). Lo único
## de FM26 que todos elogian: además del puesto, QUÉ HACE cada uno en él. Un lateral puede quedarse atrás o
## subir de carrilero; un nueve puede vivir en el área o bajar a recibir (falso nueve); un mediocentro puede
## tapar delante de la defensa o mover el balón desde atrás.
##
## Cada rol mueve dos cosas del partido (`Partido`), y solo si el jugador ENCAJA en él:
##   - la fuerza del equipo: un poco más de ataque a cambio de algo de defensa, o al revés (como las perillas
##     de `Tactica`, nada es gratis);
##   - a quién le caen los goles y las asistencias (`_elegir_goleador`, `_elegir_asistente`): el falso nueve
##     marca menos y asiste más; el nueve de área, al revés.
## El encaje sale de sus atributos (`ENCAJE`): un carrilero sin piernas o un organizador sin pase no solo no
## suman, RESTAN. Sin rol asignado, el jugador juega como siempre: un club sin roles juega exactamente igual
## que antes de esta pieza.
##
## La pizarra (la interfaz) va después; aquí, el catálogo, el encaje y los efectos.

## clave → {grupo, nombre, idea, ata, def, gol, asist}. `ata`/`def`: lo que suma (o resta) al ataque y a la
## defensa del EQUIPO un jugador que encaja del todo (0,02 = un 2 %). `gol`/`asist`: cuánto multiplica sus
## papeletas para marcar y para dar el pase de gol.
const CATALOGO := {
	"portero_clasico": {"grupo": "POR", "nombre": "Portero clásico", "idea": "Bajo palos: para y despeja.", "ata": -0.004, "def": 0.008, "gol": 1.0, "asist": 0.6},
	"portero_libero": {"grupo": "POR", "nombre": "Portero líbero", "idea": "Adelantado, juega con los pies y corta los balones a la espalda.", "ata": 0.008, "def": -0.004, "gol": 1.0, "asist": 1.6},
	"central_marcador": {"grupo": "DEF", "nombre": "Central marcador", "idea": "Se pega a su delantero y no sale de la zona.", "ata": -0.004, "def": 0.012, "gol": 0.8, "asist": 0.6},
	"central_salida": {"grupo": "DEF", "nombre": "Central con salida", "idea": "Saca el balón jugado desde atrás.", "ata": 0.008, "def": -0.004, "gol": 1.0, "asist": 1.5},
	"lateral_defensivo": {"grupo": "DEF", "nombre": "Lateral defensivo", "idea": "Cierra su banda; sube poco.", "ata": -0.006, "def": 0.01, "gol": 0.7, "asist": 0.7},
	"carrilero": {"grupo": "DEF", "nombre": "Carrilero", "idea": "Recorre toda la banda: llega arriba y centra.", "ata": 0.014, "def": -0.01, "gol": 1.2, "asist": 1.8},
	"pivote": {"grupo": "MED", "nombre": "Pivote", "idea": "Tapa delante de los centrales y corta.", "ata": -0.006, "def": 0.014, "gol": 0.5, "asist": 0.8},
	"organizador": {"grupo": "MED", "nombre": "Organizador", "idea": "Pide el balón atrás y lo distribuye.", "ata": 0.012, "def": -0.004, "gol": 0.8, "asist": 1.7},
	"box_to_box": {"grupo": "MED", "nombre": "Llegador (box to box)", "idea": "Defiende y pisa el área rival.", "ata": 0.006, "def": 0.004, "gol": 1.5, "asist": 1.0},
	"mediapunta": {"grupo": "MED", "nombre": "Mediapunta", "idea": "Entre líneas, detrás del nueve.", "ata": 0.014, "def": -0.01, "gol": 1.5, "asist": 1.4},
	"nueve_area": {"grupo": "DEL", "nombre": "Nueve de área", "idea": "Vive en el área: remata lo que le llegue.", "ata": 0.008, "def": -0.002, "gol": 1.5, "asist": 0.6},
	"falso_nueve": {"grupo": "DEL", "nombre": "Falso nueve", "idea": "Baja a recibir y arrastra a los centrales.", "ata": 0.01, "def": 0.0, "gol": 0.65, "asist": 1.8},
	"extremo": {"grupo": "DEL", "nombre": "Extremo de desborde", "idea": "Abierto y a por su lateral.", "ata": 0.01, "def": -0.004, "gol": 1.0, "asist": 1.5},
	"delantero_presionante": {"grupo": "DEL", "nombre": "Delantero presionante", "idea": "El primer defensor: muerde la salida rival.", "ata": 0.0, "def": 0.01, "gol": 0.85, "asist": 0.9},
}

## Qué atributos piden (pesos). El encaje es esa media, de 55 (no le va nada) a 85 (hecho para él).
const ENCAJE := {
	"portero_clasico": {"def": 0.6, "fis": 0.4},
	"portero_libero": {"pas": 0.5, "rit": 0.5},
	"central_marcador": {"def": 0.7, "fis": 0.3},
	"central_salida": {"pas": 0.6, "def": 0.4},
	"lateral_defensivo": {"def": 0.7, "rit": 0.3},
	"carrilero": {"rit": 0.5, "fis": 0.3, "pas": 0.2},
	"pivote": {"def": 0.6, "fis": 0.2, "pas": 0.2},
	"organizador": {"pas": 0.8, "reg": 0.2},
	"box_to_box": {"fis": 0.4, "def": 0.3, "tir": 0.3},
	"mediapunta": {"pas": 0.4, "reg": 0.4, "tir": 0.2},
	"nueve_area": {"tir": 0.8, "fis": 0.2},
	"falso_nueve": {"pas": 0.5, "reg": 0.3, "tir": 0.2},
	"extremo": {"reg": 0.5, "rit": 0.5},
	"delantero_presionante": {"fis": 0.5, "rit": 0.3, "def": 0.2},
}

static func existe(clave: String) -> bool:
	return CATALOGO.has(clave)

## Los roles que puede hacer un jugador de esa línea ("POR", "DEF", "MED", "DEL").
static func de_grupo(grupo: String) -> Array:
	var r: Array = []
	for k: String in CATALOGO:
		if String(CATALOGO[k]["grupo"]) == grupo:
			r.append(k)
	return r

## De dónde a dónde va el encaje, medido en una liga entera (sonda del 26-10, los onces titulares): la
## media ponderada de los atributos que pide el rol está entre ~56 (el 10 % peor) y ~77 (el 10 % mejor) en
## los de campo; los porteros, con sus atributos traducidos (`AccionesJuego.atributo`), entre ~35 y ~47.
const RANGO_CAMPO := [56.0, 77.0]
const RANGO_PORTERO := [35.0, 47.0]

## Cuánto encaja `j` en el rol (0 = como el 10 % peor de la liga, 1 = como el 10 % mejor).
static func encaje(j: Jugador, clave: String) -> float:
	var pesos: Dictionary = ENCAJE.get(clave, {})
	if pesos.is_empty() or j == null:
		return 0.0
	var s := 0.0
	for k: String in pesos:
		s += AccionesJuego.atributo(j, k) * float(pesos[k])
	var rango: Array = RANGO_PORTERO if String(CATALOGO[clave]["grupo"]) == "POR" else RANGO_CAMPO
	return clampf((s - float(rango[0])) / (float(rango[1]) - float(rango[0])), 0.0, 1.0)

## Lo que rinde el rol: 1 si encaja del todo, ~0,4 el jugador mediano, NEGATIVO si no le va (hasta −0,4: el
## carrilero sin piernas deja la banda abierta y no llega arriba).
static func rendimiento(j: Jugador, clave: String) -> float:
	return encaje(j, clave) * 1.4 - 0.4

## El rol de `j` en esta táctica, si tiene uno válido para su línea ("" si no).
static func de(t: Tactica, j: Jugador) -> String:
	if t == null or j == null:
		return ""
	var r := String(t.roles.get(j.id, ""))
	if r == "" or not CATALOGO.has(r) or String(CATALOGO[r]["grupo"]) != Datos.grupo(j.pos_e):
		return ""
	return r

## Lo que los roles del once suman al ataque y a la defensa: [mult_ataque, mult_defensa]. [1, 1] sin roles.
static func multiplicadores(t: Tactica, once: Array) -> Array:
	var ata := 1.0
	var dfa := 1.0
	for j: Jugador in once:
		var r := de(t, j)
		if r == "":
			continue
		var f := rendimiento(j, r)
		var d: Dictionary = CATALOGO[r]
		## Si no encaja, el rol no da lo suyo y además resta por los dos lados: no hay rol gratis.
		if f >= 0.0:
			ata *= 1.0 + float(d["ata"]) * f
			dfa *= 1.0 + float(d["def"]) * f
		else:
			ata *= 1.0 - 0.01 * -f
			dfa *= 1.0 - 0.01 * -f
	return [ata, dfa]

## Cuánto multiplica el rol las papeletas de `j` para marcar ("gol") o asistir ("asist"). 1 sin rol. Con
## mal encaje, el efecto se queda a medias (el falso nueve que no sabe pasar tampoco asiste tanto).
static func peso(t: Tactica, j: Jugador, que: String) -> float:
	var r := de(t, j)
	if r == "":
		return 1.0
	var m := float(CATALOGO[r][que])
	return lerpf(1.0, m, clampf(0.4 + 0.6 * encaje(j, r), 0.0, 1.0))
