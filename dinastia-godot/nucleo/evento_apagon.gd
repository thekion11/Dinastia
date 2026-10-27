class_name EventoApagon
extends RefCounted
## EL EVENTO ESPECIAL DEL SUBSUELO (27-10-2026): «Apagón de tormenta». En una semana de tormenta, a las 20:00, salta
## el disyuntor del cuadro general y dos sectores interiores se quedan sin luz. El móvil avisa; abajo, en la galería
## eléctrica, hay que REARMAR el disyuntor y luego RECONECTAR la red desde la sala de control. Si nadie baja, la
## cuadrilla municipal lo arregla a las 08:00 (con un titular peor). Lógica pura: lo dibuja `SubsueloCiudad`.

const HORA_INICIO := 20
const HORA_CUADRILLA := 8
const PROBABILIDAD := 0.6

var activo := false
var sectores: Array[Vector2i] = []
var rearmado := false
var resueltos := 0                   ## veces que lo arregló el jugador
var por_cuadrilla := 0
var avisos: Array = []               ## [{tipo, texto}] pendientes de enseñar (los recoge `tomar_avisos`)

func tick(m: RedesCiudad, hora: int, clima: String) -> void:
	if not activo:
		if clima == "tormenta" and hora == HORA_INICIO and float(absi(hash([m.semilla, m.horas, "apagon"])) % 1000) / 1000.0 < PROBABILIDAD:
			_empezar(m)
	elif hora == HORA_CUADRILLA:
		_reparar(m)
		por_cuadrilla += 1
		avisos.append({"tipo": "cuadrilla", "texto": "La cuadrilla municipal repuso la luz a primera hora."})

func _empezar(m: RedesCiudad) -> void:
	var h := absi(hash([m.semilla, m.horas, "sectores"]))
	sectores = [Vector2i(1 + h % 3, 1 + (h / 3) % 3), Vector2i(1 + (h / 9) % 3, 1 + (h / 27) % 3)]
	if sectores[1] == sectores[0]:
		sectores[1] = Vector2i(2, 2) if sectores[0] != Vector2i(2, 2) else Vector2i(2, 1)
	for s in sectores:
		m.averiar("luz", s)
	activo = true
	rearmado = false
	m.recalcular()
	m.anotar("¡Salta el disyuntor general! Sin luz: sectores %s" % ", ".join(sectores.map(func(s: Vector2i) -> String: return "%d·%d" % [s.x, s.y])))
	avisos.append({"tipo": "inicio", "texto": "Apagón por la tormenta en %d sectores." % sectores.size()})

func _reparar(m: RedesCiudad) -> void:
	for s in sectores:
		m.reparar("luz", s)
	activo = false
	rearmado = false
	m.recalcular()

## En la galería: levanta el disyuntor. Devuelve «no_activo», «ya» o «ok».
func rearmar() -> String:
	if not activo:
		return "no_activo"
	if rearmado:
		return "ya"
	rearmado = true
	return "ok"

## En la sala de control: reconecta la red. «no_activo», «falta_rearmar» u «ok».
func reconectar(m: RedesCiudad) -> String:
	if not activo:
		return "no_activo"
	if not rearmado:
		return "falta_rearmar"
	_reparar(m)
	resueltos += 1
	m.anotar("Red reconectada desde el subsuelo")
	avisos.append({"tipo": "resuelto", "texto": "Alguien reconectó la red desde abajo."})
	return "ok"

func a_dic() -> Dictionary:
	return {"activo": activo, "sectores": sectores.map(func(s: Vector2i) -> Array: return [s.x, s.y]), "rearmado": rearmado,
		"resueltos": resueltos, "cuadrilla": por_cuadrilla}

func desde_dic(d: Dictionary) -> void:
	activo = bool(d.get("activo", false))
	rearmado = bool(d.get("rearmado", false))
	resueltos = int(d.get("resueltos", 0))
	por_cuadrilla = int(d.get("cuadrilla", 0))
	sectores.clear()
	for p: Variant in d.get("sectores", []):
		if p is Array and (p as Array).size() == 2:
			sectores.append(Vector2i(int(p[0]), int(p[1])))
	avisos.clear()

func tomar_avisos() -> Array:
	var a := avisos.duplicate()
	avisos.clear()
	return a
