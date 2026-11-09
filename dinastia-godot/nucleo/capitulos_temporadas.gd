class_name CapitulosTemporadas
extends RefCounted
## LOS CAPÍTULOS DE CADA TEMPORADA (9-11, idea del PES 2020 que le gusta al dueño): el documental de cada año se GUARDA en la partida
## (`Prensa.capitulos`, que va en el guardado) y se puede volver a ver cuando se quiera. Antes solo vivía el último, en memoria, y se
## perdía al cerrar el juego. Aquí solo hay datos (sin interfaz): `archivar` guarda, `reconstruir` devuelve los capítulos con sus escudos/caras.
const MAX_TEMPORADAS := 40

## Guarda el guion de la temporada `anio`. Los `ref` (Club/Jugador) se sustituyen por su id para poder escribirlos en el guardado.
static func archivar(m: Mundo, anio: int, caps: Array) -> void:
	if m == null or m.prensa == null or caps.is_empty():
		return
	var planos: Array = []
	for c: Dictionary in caps:
		var ref: Variant = c.get("ref")
		var rid := ""
		if ref is Club:
			rid = (ref as Club).id
		elif ref is Jugador:
			rid = (ref as Jugador).id
		planos.append({"titulo": String(c["titulo"]), "texto": String(c["texto"]), "tipo": String(c["tipo"]), "ref_id": rid})
	var lista: Array = m.prensa.capitulos
	for i in range(lista.size() - 1, -1, -1):
		if int((lista[i] as Dictionary).get("anio", -1)) == anio:
			lista.remove_at(i)   ## la misma temporada se reescribe (cargar y volver a cerrar)
	lista.append({"anio": anio, "caps": planos})
	while lista.size() > MAX_TEMPORADAS:
		lista.pop_front()

## Los años archivados, del más reciente al más antiguo.
static func anios(m: Mundo) -> Array:
	var out: Array = []
	if m != null and m.prensa != null:
		for e: Dictionary in m.prensa.capitulos:
			out.append(int(e.get("anio", 0)))
	out.sort()
	out.reverse()
	return out

## Los capítulos de un año, con sus referencias vivas (Club o Jugador de ESTA partida; si ya no existen, el escudo de tu club).
static func reconstruir(m: Mundo, anio: int) -> Array:
	var out: Array = []
	if m == null or m.prensa == null:
		return out
	for e: Dictionary in m.prensa.capitulos:
		if int(e.get("anio", -1)) != anio:
			continue
		for c: Dictionary in e["caps"]:
			var ref: Variant = _buscar(m, String(c.get("ref_id", "")), String(c["tipo"]))
			out.append({"titulo": String(c["titulo"]), "texto": String(c["texto"]), "tipo": String(c["tipo"]),
				"ref": ref if ref != null else m.mi_club()})
	return out

static func _buscar(m: Mundo, rid: String, tipo: String) -> Variant:
	if rid == "":
		return null
	if tipo == "jugador":
		var mio := m.mi_club()
		if mio != null:
			for j: Jugador in mio.plantilla:
				if j.id == rid:
					return j
		return null
	for l in m.ligas:
		for c: Club in l.clubes:
			if c.id == rid:
				return c
	return null
