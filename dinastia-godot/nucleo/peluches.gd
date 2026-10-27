class_name Peluches
extends RefCounted
## LOS PELUCHES COLECCIONABLES (27-10-2026, pieza D de `PLAN_DEL_LUNES.md` §2.2h; decisión del dueño: los peluches dan LOGROS). Tres máquinas de garra en
## UNA sala del centro comercial; cada intento cuesta una moneda de 1 € del EFECTIVO (no de la tarjeta). Lo que cae a la salida va al álbum del DT
## (`Roles.peluches`, con su estantería en la vivienda y su resumen en el móvil). Un LOGRO por serie completa y otro por la colección entera.
## `PELUCHES` es la TABLA donde se enchufan los modelos: `modelo` vacío = peluche de relleno hecho con esferas (`PelucheModelo`); cuando lleguen los 14
## modelos del regalo del dueño (en el Drive, pendientes de subir), basta poner su ruta en `modelo` y su escala en `escala`. Sin azar global: el campo de
## cada partida sale de una semilla (día, máquina, intento) y la tirada de un `RandomNumberGenerator` propio.
const MONEDA := 1
const RADIO_AGARRE := 0.14        ## fracción del ancho del campo: a más distancia del centro del peluche, menos probabilidad
const FALLO_EXTRA := 0.05         ## cada intento fallido seguido suma esto a la probabilidad (hasta MAX_EXTRA): para que nunca sea imposible
const MAX_EXTRA := 0.25

const SERIES := {
	"bosque": "Amigos del bosque", "granja": "La granja", "mar": "Fondo del mar", "fantasia": "Fantasía",
}
## id, nombre, serie, peso (1 ligero … 4 pesado), máquina (0-2), forma (cómo se dibuja el relleno), color, modelo (ruta .glb, "" = relleno), escala del modelo.
const PELUCHES := [
	{"id": "oso", "nombre": "Oso pardo", "serie": "bosque", "peso": 3, "maquina": 0, "forma": "oso", "color": Color(0.55, 0.36, 0.22), "modelo": "", "escala": 1.0},
	{"id": "zorro", "nombre": "Zorrito", "serie": "bosque", "peso": 2, "maquina": 0, "forma": "puntas", "color": Color(0.93, 0.5, 0.18), "modelo": "", "escala": 1.0},
	{"id": "ciervo", "nombre": "Cervatillo", "serie": "bosque", "peso": 2, "maquina": 0, "forma": "puntas", "color": Color(0.82, 0.66, 0.42), "modelo": "", "escala": 1.0},
	{"id": "buho", "nombre": "Búho", "serie": "bosque", "peso": 2, "maquina": 0, "forma": "puntas", "color": Color(0.5, 0.42, 0.36), "modelo": "", "escala": 1.0},
	{"id": "pollito", "nombre": "Pollito", "serie": "granja", "peso": 1, "maquina": 0, "forma": "bola", "color": Color(1.0, 0.88, 0.25), "modelo": "", "escala": 1.0},
	{"id": "cerdito", "nombre": "Cerdito", "serie": "granja", "peso": 2, "maquina": 1, "forma": "oso", "color": Color(0.98, 0.7, 0.75), "modelo": "", "escala": 1.0},
	{"id": "vaca", "nombre": "Vaquita", "serie": "granja", "peso": 3, "maquina": 1, "forma": "oso", "color": Color(0.94, 0.94, 0.92), "modelo": "", "escala": 1.0},
	{"id": "pulpo", "nombre": "Pulpo", "serie": "mar", "peso": 2, "maquina": 1, "forma": "bola", "color": Color(0.62, 0.38, 0.8), "modelo": "", "escala": 1.0},
	{"id": "pinguino", "nombre": "Pingüino", "serie": "mar", "peso": 2, "maquina": 1, "forma": "bola", "color": Color(0.16, 0.18, 0.24), "modelo": "", "escala": 1.0},
	{"id": "ballena", "nombre": "Ballenita", "serie": "mar", "peso": 4, "maquina": 1, "forma": "bola", "color": Color(0.3, 0.55, 0.9), "modelo": "", "escala": 1.0},
	{"id": "cangrejo", "nombre": "Cangrejo", "serie": "mar", "peso": 2, "maquina": 2, "forma": "puntas", "color": Color(0.9, 0.22, 0.18), "modelo": "", "escala": 1.0},
	{"id": "dragon", "nombre": "Dragoncito", "serie": "fantasia", "peso": 4, "maquina": 2, "forma": "puntas", "color": Color(0.3, 0.72, 0.4), "modelo": "", "escala": 1.0},
	{"id": "unicornio", "nombre": "Unicornio", "serie": "fantasia", "peso": 3, "maquina": 2, "forma": "puntas", "color": Color(0.84, 0.66, 0.95), "modelo": "", "escala": 1.0},
	{"id": "fantasma", "nombre": "Fantasmita", "serie": "fantasia", "peso": 1, "maquina": 2, "forma": "bola", "color": Color(0.96, 0.96, 1.0), "modelo": "", "escala": 1.0},
]
const LOGRO_TODO := "coleccion"

var conseguidos: Dictionary = {}   ## id -> veces que ha caído
var logros: Array = []             ## ids de los logros ya ganados, en orden
var fallos_seguidos := 0

static func def(id: String) -> Dictionary:
	for p: Dictionary in PELUCHES:
		if String(p["id"]) == id:
			return p
	return {}

static func de_maquina(m: int) -> Array:
	var r: Array = []
	for p: Dictionary in PELUCHES:
		if int(p["maquina"]) == m:
			r.append(p)
	return r

static func de_serie(serie: String) -> Array:
	var r: Array = []
	for p: Dictionary in PELUCHES:
		if String(p["serie"]) == serie:
			r.append(p)
	return r

## Los logros: uno por serie y el de la colección entera. [{id, nombre}] con el nombre ya TRADUCIDO.
static func definicion_logros() -> Array:
	var r: Array = []
	for s: String in SERIES:
		r.append({"id": "serie_" + s, "nombre": Idiomas.t("Serie «%s» completa") % Idiomas.t(String(SERIES[s]))})
	r.append({"id": LOGRO_TODO, "nombre": Idiomas.t("Colección de peluches completa")})
	return r

func tiene(id: String) -> bool:
	return int(conseguidos.get(id, 0)) > 0

func distintos() -> int:
	var n := 0
	for p: Dictionary in PELUCHES:
		if tiene(String(p["id"])):
			n += 1
	return n

func serie_completa(serie: String) -> bool:
	for p: Dictionary in de_serie(serie):
		if not tiene(String(p["id"])):
			return false
	return true

func completa() -> bool:
	return distintos() == PELUCHES.size()

## Anota un peluche ganado y devuelve los logros NUEVOS (ids) que desbloquea.
func conseguir(id: String) -> Array:
	if def(id).is_empty():
		return []
	conseguidos[id] = int(conseguidos.get(id, 0)) + 1
	fallos_seguidos = 0
	var nuevos: Array = []
	for s: String in SERIES:
		if serie_completa(s) and not logros.has("serie_" + s):
			logros.append("serie_" + s)
			nuevos.append("serie_" + s)
	if completa() and not logros.has(LOGRO_TODO):
		logros.append(LOGRO_TODO)
		nuevos.append(LOGRO_TODO)
	return nuevos

static func nombre_logro(id: String) -> String:
	for l: Dictionary in definicion_logros():
		if String(l["id"]) == id:
			return String(l["nombre"])
	return id

# ---------------------------------------------------------------- la partida

## El campo de una máquina para una semilla: de 5 a 6 peluches de ESA máquina, sin pisarse. Posición (x, y) en 0..1 (y hacia el fondo).
static func campo(maquina: int, semilla: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var lista := de_maquina(maquina)
	var campo_: Array = []
	if lista.is_empty():
		return campo_
	var n := 5 + (semilla % 2)
	var intentos := 0
	while campo_.size() < n and intentos < 400:
		intentos += 1
		var p: Dictionary = lista[campo_.size() % lista.size()] if campo_.size() < lista.size() else lista[rng.randi() % lista.size()]
		var x := rng.randf_range(0.12, 0.88)
		var y := rng.randf_range(0.14, 0.86)
		var libre := true
		for q: Dictionary in campo_:
			if Vector2(float(q["x"]) - x, float(q["y"]) - y).length() < 0.2:
				libre = false
		if libre:
			campo_.append({"id": String(p["id"]), "x": x, "y": y})
	return campo_

## Probabilidad de agarrar el peluche `def_p` si la garra cierra a `dist` (en fracción del campo) de su centro.
func probabilidad(def_p: Dictionary, dist: float) -> float:
	if dist > RADIO_AGARRE:
		return 0.0
	var base := 0.7 - 0.1 * float(int(def_p["peso"]) - 1)
	var cerca := 1.0 - 0.55 * (dist / RADIO_AGARRE)
	return clampf(base * cerca + minf(float(fallos_seguidos) * FALLO_EXTRA, MAX_EXTRA), 0.0, 0.95)

## La garra cierra en (x, y): {"indice": peluche más cercano o -1, "p": probabilidad, "exito": bool}. Si falla, sube la ayuda; no gana nada aquí (lo hace `conseguir`).
func intento(campo_: Array, x: float, y: float, rng: RandomNumberGenerator) -> Dictionary:
	var mejor := -1
	var mejor_d := 9.0
	for i in campo_.size():
		var q: Dictionary = campo_[i]
		var d := Vector2(float(q["x"]) - x, float(q["y"]) - y).length()
		if d < mejor_d:
			mejor_d = d
			mejor = i
	if mejor < 0 or mejor_d > RADIO_AGARRE:
		fallos_seguidos += 1
		return {"indice": -1, "p": 0.0, "exito": false}
	var p := probabilidad(def(String(campo_[mejor]["id"])), mejor_d)
	var ok := rng.randf() < p
	if not ok:
		fallos_seguidos += 1
	return {"indice": mejor, "p": p, "exito": ok}

func a_dict() -> Dictionary:
	return {"conseguidos": conseguidos.duplicate(), "logros": logros.duplicate(), "fallos": fallos_seguidos}

## Partida vieja (vacío): álbum vacío.
func desde_dict(d: Dictionary) -> void:
	conseguidos = (d.get("conseguidos", {}) as Dictionary).duplicate()
	logros = (d.get("logros", []) as Array).duplicate()
	fallos_seguidos = int(d.get("fallos", 0))
