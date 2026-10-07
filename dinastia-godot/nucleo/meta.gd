class_name Meta
extends RefCounted
## LO QUE QUEDA ENTRE PARTIDAS (28-9-2026, bloque 50 del plan maestro). Como el
## perfil de gestor (`Logros`), vive en `user://` y no en la partida: borrar o
## empezar otra carrera no lo toca.
##
##   - EL ÁLBUM DE CROMOS: cada temporada cerrada y cada título te dan un sobre
##     con cinco cromos de futbolistas del mundo en el que juegas. Rarezas por
##     media: bronce, plata y oro; y leyenda, uno de cada diez, que sale del
##     libro de leyendas del mundo (retirados ilustres). Los repetidos se
##     cuentan.
##   - EL MUSEO GLOBAL: todos los títulos de todas tus carreras, con el año, el
##     club y el nombre de tu DT.
##   - EL MUNDO HEREDADO: al cerrar cada temporada se guarda cómo quedó el
##     mundo (la reputación de los clubes y tus leyendas). Una partida nueva
##     puede arrancar "heredando": los clubes que crecieron siguen grandes y los
##     que se hundieron empiezan abajo.

const RUTA := "user://meta_global.json"
const POR_SOBRE := 5
const MAX_MUSEO := 300
## [clave, nombre, media mínima, color]
const RAREZAS := [["leyenda", "Leyenda", 999, "b388ff"], ["oro", "Oro", 80, "e0b53a"],
	["plata", "Plata", 70, "c0c6cc"], ["bronce", "Bronce", 0, "b0703a"]]

## Para las pruebas: se puede apuntar a otro archivo.
static var ruta := RUTA
## Si la próxima partida nueva hereda el mundo de la última.
static var heredar_proximo := false

static func leer() -> Dictionary:
	var vacio := {"sobres": 1, "cromos": {}, "museo": [], "legado": {}}
	if not FileAccess.file_exists(ruta):
		return vacio
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return vacio
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		return vacio
	for k: String in vacio:
		if not (d as Dictionary).has(k):
			d[k] = vacio[k]
	return d

static func guardar(d: Dictionary) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	if f == null:
		push_warning("Meta: no puedo guardar en %s" % ruta)
		return
	f.store_string(JSON.stringify(d))

static func rareza_de(ovr: int, leyenda: bool) -> String:
	if leyenda:
		return "leyenda"
	for r: Array in RAREZAS:
		if String(r[0]) != "leyenda" and ovr >= int(r[2]):
			return String(r[0])
	return "bronce"

static func color_rareza(r: String) -> Color:
	for x: Array in RAREZAS:
		if String(x[0]) == r:
			return Color(String(x[3]))
	return Color.GRAY

# --- ganar sobres -------------------------------------------------------------

static func fin_de_temporada(m: Mundo) -> void:
	var d := leer()
	d["sobres"] = int(d["sobres"]) + 1
	d["legado"] = _foto_del_mundo(m)
	guardar(d)

static func registrar_trofeo(m: Mundo, titulo: String) -> void:
	var d := leer()
	var c := m.mi_club() if m != null else null
	(d["museo"] as Array).push_front({"anio": m.anio if m != null else 0, "titulo": titulo,
		"club": c.nombre if c != null else "", "dt": m.roles.nombre if m != null and m.roles != null else ""})
	if (d["museo"] as Array).size() > MAX_MUSEO:
		(d["museo"] as Array).resize(MAX_MUSEO)
	d["sobres"] = int(d["sobres"]) + 1
	guardar(d)

## Abre un sobre: cinco cromos del mundo, sesgados hacia los buenos (uno de
## cada cinco sale de los 60 mejores). Devuelve los cromos, o vacío si no
## quedan sobres.
static func abrir_sobre(m: Mundo, rng: RandomNumberGenerator = null) -> Array[Dictionary]:
	var d := leer()
	var out: Array[Dictionary] = []
	if int(d["sobres"]) <= 0 or m == null:
		return out
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var todos: Array = []
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			todos.append([j, c])
	if todos.is_empty():
		return out
	var mejores := todos.duplicate()
	mejores.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Jugador).ovr > (b[0] as Jugador).ovr)
	mejores = mejores.slice(0, 60)
	var leyendas: Array = m.cantera.leyendas if m.cantera != null else []
	for i in POR_SOBRE:
		var nombre := ""
		var club_n := ""
		var pos := ""
		var ovr := 0
		var r := ""
		## Uno de cada diez sale del libro de leyendas (retirados ilustres).
		if not leyendas.is_empty() and rng.randf() < 0.1:
			var ley: Dictionary = leyendas[rng.randi() % leyendas.size()]
			var cl: Club = m.clubes.get(String(ley.get("club_id", "")))
			nombre = String(ley["nombre"])
			club_n = cl.nombre if cl != null else "Retirado"
			pos = String(ley.get("pos", ""))
			ovr = int(ley.get("nivel", 80))
			r = "leyenda"
		else:
			var par: Array = mejores[rng.randi() % mejores.size()] if i == 0 else todos[rng.randi() % todos.size()]
			var j: Jugador = par[0]
			nombre = j.nombre
			club_n = (par[1] as Club).nombre
			pos = j.pos_e
			ovr = j.ovr
			r = rareza_de(ovr, false)
		var clave := "%s|%s" % [nombre, club_n]
		var cromos: Dictionary = d["cromos"]
		var nuevo := not cromos.has(clave)
		var cr: Dictionary = cromos.get(clave, {"nombre": nombre, "club": club_n, "pos": pos, "ovr": ovr, "rareza": r, "veces": 0})
		cr["veces"] = int(cr["veces"]) + 1
		cr["ovr"] = maxi(int(cr["ovr"]), ovr)
		cromos[clave] = cr
		var copia := cr.duplicate()
		copia["nuevo"] = nuevo
		out.append(copia)
	d["sobres"] = int(d["sobres"]) - 1
	guardar(d)
	return out

# --- el mundo heredado ----------------------------------------------------------

static func _foto_del_mundo(m: Mundo) -> Dictionary:
	var reps := {}
	for c: Club in m.clubes.values():
		reps[c.nombre] = c.rep
	var mio := m.mi_club()
	return {"anio": m.anio, "reps": reps, "club": mio.nombre if mio != null else "",
		"dt": m.roles.nombre if m.roles != null else ""}

static func hay_legado() -> bool:
	return not (leer()["legado"] as Dictionary).is_empty()

## Aplica al mundo recién generado la reputación con la que quedó cada club
## en la última partida (por nombre). Devuelve cuántos clubes cambió.
static func aplicar_herencia(m: Mundo) -> int:
	var leg: Dictionary = leer()["legado"]
	var reps: Dictionary = leg.get("reps", {})
	var n := 0
	for c: Club in m.clubes.values():
		if reps.has(c.nombre):
			var r := clampi(int(reps[c.nombre]), 5, 99)
			if r != c.rep:
				c.rep = r
				n += 1
	return n
