class_name IncidentesCiudad
extends RefCounted
## INCIDENTES DE LA CIUDAD (27-10-2026, pieza E «policía y bomberos», `PLAN_DEL_LUNES.md` §2.2h): de vez en cuando hay un robo, un incendio o un
## accidente en una calle; salen los vehículos de emergencia de su edificio, llegan, atienden y vuelven. Esto es la parte PURA (sin escena):
## cuándo pasa, dónde, quién acude, cuánto tarda en resolverse y cuánto cuesta saltarse un semáforo. La escena (`ServiciosVida`) solo lo dibuja.
##
## SIN `Azar`: todo sale de un hash de (semilla, día, hora). Los incidentes no tocan la liga ni la partida; con la misma semilla, el mismo día
## y la misma hora ocurre lo mismo (y se puede probar).
const CELDA := 110.0
const MULTA_SEMAFORO := 90                ## € de la cartera por cruzar en rojo con la policía delante
const HORA_DESDE := 7                     ## no hay incidentes de madrugada
const UNO_DE_CADA := 8                    ## una hora de cada 8 (≈ 2 incidentes por día de juego)
const RADIO_CIUDAD := 4                   ## calles a cada lado del centro donde puede pasar
const FUEGO_BASE := 45.0                  ## s que tarda un camión en apagar un incendio con la red de agua sana
const FUEGO_SIN_AGUA := 110.0             ## s con el sector sin presión (la manguera da lo que da el camión)

## tipo → quién acude (uso del edificio de salida), cuánto atiende y el icono del móvil.
const TIPOS := {
	"robo": {"acuden": ["comisaria"], "dura": 30.0, "icono": "🚓"},
	"incendio": {"acuden": ["bomberos", "bomberos"], "dura": FUEGO_BASE, "icono": "🔥"},
	"accidente": {"acuden": ["hospital", "comisaria"], "dura": 25.0, "icono": "🚑"},
}
## Vehículo (modelo de `assets/ciudad/kenney_cars`) de cada edificio.
const MODELO := {"comisaria": "police", "bomberos": "firetruck", "hospital": "ambulance"}

## ¿Pasa algo a esta hora? `{}` si no. `{tipo, pos}`; `pos` está a pie de calle (la acera, junto a la avenida i·110), nunca dentro de un edificio
## del núcleo: eso lo comprueba quien lo pinta con `nombre_calle_en`.
static func sortear(semilla: int, dia: int, hora: int) -> Dictionary:
	if hora < HORA_DESDE:
		return {}
	var h := absi(hash(Vector3i(semilla, dia, hora)))
	if h % UNO_DE_CADA != 0:
		return {}
	var tipos := ["robo", "incendio", "accidente"]
	var lado := RADIO_CIUDAD * 2 + 1
	var i := (h / 8) % lado - RADIO_CIUDAD
	var j := (h / 64) % lado - RADIO_CIUDAD
	return {"tipo": tipos[(h / 4096) % tipos.size()], "pos": Vector3(float(i) * CELDA + 11.0, 0.2, float(j) * CELDA + 35.0)}

## Un incidente en marcha: {tipo, pos, esperados, llegados, atendido, dura, fase}. Fases: «camino» → «atendiendo» → «resuelto».
static func nuevo(tipo: String, pos: Vector3) -> Dictionary:
	var d: Dictionary = TIPOS[tipo]
	return {"tipo": tipo, "pos": pos, "esperados": (d["acuden"] as Array).size(), "llegados": 0, "atendido": 0.0,
		"dura": float(d["dura"]), "fase": "camino"}

static func llega(inc: Dictionary) -> void:
	inc["llegados"] = int(inc["llegados"]) + 1

## Pasa `dt` segundos de partida. Atiende cuando ya ha llegado todo el mundo; el incendio, más despacio si falta presión de agua (`ritmo`
## < 1). Devuelve la fase.
static func avanzar(inc: Dictionary, dt: float, ritmo := 1.0) -> String:
	if inc["fase"] == "camino" and int(inc["llegados"]) >= int(inc["esperados"]):
		inc["fase"] = "atendiendo"
	if inc["fase"] == "atendiendo":
		inc["atendido"] = float(inc["atendido"]) + dt * ritmo
		if float(inc["atendido"]) >= float(inc["dura"]):
			inc["fase"] = "resuelto"
	return String(inc["fase"])

## Lo que queda por hacer (1 = recién llegados, 0 = resuelto): para encoger las llamas.
static func pendiente(inc: Dictionary) -> float:
	return clampf(1.0 - float(inc["atendido"]) / maxf(float(inc["dura"]), 0.001), 0.0, 1.0)

## El ritmo de un incendio: 1 con agua en el sector, `FUEGO_BASE / FUEGO_SIN_AGUA` sin ella.
static func ritmo_fuego(hay_presion: bool) -> float:
	return 1.0 if hay_presion else FUEGO_BASE / FUEGO_SIN_AGUA

## Textos del móvil y del titular (en español; la escena los pasa por `Idiomas.t`).
static func aviso(tipo: String) -> String:
	match tipo:
		"incendio":
			return "🔥 Incendio en una calle del centro: salen los bomberos."
		"accidente":
			return "🚑 Accidente en la calle: salen la ambulancia y la policía."
		_:
			return "🚓 Robo en un comercio: la policía va de camino."

static func resuelto(tipo: String) -> String:
	match tipo:
		"incendio":
			return "🔥 El fuego está apagado. Los bomberos vuelven al parque."
		"accidente":
			return "🚑 Heridos atendidos. La calle vuelve a estar libre."
		_:
			return "🚓 La policía detuvo al sospechoso."

## Un camino por las calles de la rejilla (líneas cada `CELDA`): sale hacia el sur hasta la calle más cercana, recorre esa calle hasta la avenida
## del destino y baja o sube por ella. Con las esquinas redondeadas. `desde` ya está fuera del edificio.
static func ruta_calles(desde: Vector3, hasta: Vector3) -> PackedVector3Array:
	var zs := roundf((desde.z + 4.0) / CELDA) * CELDA
	if zs < desde.z - 1.0:
		zs += CELDA
	var xt := roundf((hasta.x - 11.0) / CELDA) * CELDA
	var y := desde.y
	var p := PackedVector3Array([desde, Vector3(desde.x, y, zs)])
	if absf(xt - desde.x) > 1.0:
		p.append(Vector3(xt, y, zs))
	if absf(hasta.z - zs) > 1.0:
		p.append(Vector3(xt, y, hasta.z))
	return redondear(p, 14.0)

## Corta las esquinas con una curva (cuadrática por tramo) para que el vehículo gire en lugar de pivotar.
static func redondear(p: PackedVector3Array, radio: float) -> PackedVector3Array:
	if p.size() < 3:
		return p
	var r := PackedVector3Array([p[0]])
	for k in range(1, p.size() - 1):
		var a: Vector3 = p[k - 1]
		var c: Vector3 = p[k]
		var b: Vector3 = p[k + 1]
		var rad := minf(radio, minf(a.distance_to(c), c.distance_to(b)) * 0.5)
		var ini := c + (a - c).normalized() * rad
		var fin := c + (b - c).normalized() * rad
		for n in range(0, 7):
			var t := float(n) / 6.0
			r.append((ini * (1.0 - t) + c * t) * (1.0 - t) + (c * (1.0 - t) + fin * t) * t)
	r.append(p[p.size() - 1])
	return r

static func largo_de(p: PackedVector3Array) -> float:
	var s := 0.0
	for k in range(1, p.size()):
		s += p[k - 1].distance_to(p[k])
	return s

## Posición y rumbo (radianes sobre Y, con +Z como morro) a `s` metros del inicio del camino.
static func punto_en(p: PackedVector3Array, s: float) -> Array:
	var resto := maxf(s, 0.0)
	for k in range(1, p.size()):
		var l := p[k - 1].distance_to(p[k])
		if resto <= l or k == p.size() - 1:
			var d := (p[k] - p[k - 1]).normalized()
			return [p[k - 1] + d * minf(resto, l), atan2(d.x, d.z)]
		resto -= l
	return [p[0], 0.0]
