class_name TorneoSelecciones
extends RefCounted
## UN TORNEO DE SELECCIONES CON PARTIDOS DE VERDAD (encargo del dueño del 10-11, punto 2). Sirve para el Mundial, la Eurocopa, la Copa América, la Copa
## Oro, la Copa Africana, la Copa de Asia… con cualquier número de selecciones (`SeleccionEquipo`): GRUPOS de unos 4, todos contra todos a una vuelta
## (método del círculo), pasan los dos primeros de cada grupo y, si hace falta para cuadrar el cuadro, los mejores terceros; luego ELIMINATORIAS a
## partido único (empate: penaltis). Cada FECHA se juega entera con `jugar_fecha`; el partido de TU selección puede venir ya jugado en directo
## (`ya_jugado`), igual que en la copa. Lo simulado usa azar aislado (`CopasMundo._aislado`): no cambia nada del resto del juego.
var nombre := ""
var anio := 0
var equipos: Array[Club] = []
var grupos: Array = []          ## [[Club…], …]
var tabla := {}                 ## id -> {pts, gf, gc, pj}
var fecha := 0                  ## fecha de grupos jugadas
var fechas_grupo := 0
var vivos: Array[Club] = []     ## en eliminatorias, en orden de cruce
var en_grupos := true
var campeon: Club = null
var resultados: Array = []      ## [{fase, local, visita, gl, gv, penales, pasa}]

static func crear(nombre_: String, anio_: int, sel: Array[Club]) -> TorneoSelecciones:
	var t := TorneoSelecciones.new()
	t.nombre = nombre_
	t.anio = anio_
	t.equipos = sel.duplicate()
	var orden := sel.duplicate()
	orden.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep if a.rep != b.rep else a.id < b.id)
	var n_grupos := maxi(1, int(round(float(orden.size()) / 4.0)))
	for k in n_grupos:
		t.grupos.append([])
	for i in orden.size():   ## bombos en serpiente: los mejores, repartidos
		var fila := i / n_grupos
		var g := i % n_grupos if fila % 2 == 0 else n_grupos - 1 - (i % n_grupos)
		(t.grupos[g] as Array).append(orden[i])
	for c: Club in orden:
		t.tabla[c.id] = {"pts": 0, "gf": 0, "gc": 0, "pj": 0}
	for g2: Array in t.grupos:
		t.fechas_grupo = maxi(t.fechas_grupo, g2.size() - 1 + (g2.size() % 2))
	return t

func en_curso() -> bool:
	return campeon == null

func nombre_fase() -> String:
	if en_grupos:
		return "Fase de grupos · fecha %d" % (fecha + 1)
	match vivos.size():
		2: return "Final"
		4: return "Semifinales"
		8: return "Cuartos de final"
		16: return "Octavos de final"
		32: return "Dieciseisavos"
	return "Eliminatoria"

## Los cruces de un grupo en la fecha `f` (método del círculo; con número impar, uno descansa).
static func _cruces(g: Array, f: int) -> Array:
	var lista := g.duplicate()
	if lista.size() % 2 == 1:
		lista.append(null)
	var n := lista.size()
	var rot := [lista[0]]
	for k in range(1, n):
		rot.append(lista[1 + (k - 1 + f) % (n - 1)])
	var out: Array = []
	for k in n / 2:
		var a = rot[k]
		var b = rot[n - 1 - k]
		if a != null and b != null:
			out.append([a, b] if (f + k) % 2 == 0 else [b, a])
	return out

## Los partidos de la fecha que toca: [[local, visita], …].
func partidos_de_la_fecha() -> Array:
	var out: Array = []
	if not en_curso():
		return out
	if en_grupos:
		for g: Array in grupos:
			out.append_array(_cruces(g, fecha))
	else:
		for i in range(0, vivos.size() - 1, 2):
			out.append([vivos[i], vivos[i + 1]])
	return out

## El partido de `c` en la fecha que toca, o [].
func partido_de(c: Club) -> Array:
	for par: Array in partidos_de_la_fecha():
		if par[0] == c or par[1] == c:
			return par
	return []

## Juega la fecha entera. `ya_jugado`: el partido de tu selección, si ya se jugó en directo. Devuelve los resultados de la fecha.
func jugar_fecha(ya_jugado: Partido = null) -> Array:
	var hechos: Array = []
	var fase := nombre_fase()
	for par: Array in partidos_de_la_fecha():
		var a: Club = par[0]
		var b: Club = par[1]
		var gl := 0
		var gv := 0
		var pen: Array = []
		if ya_jugado != null and ya_jugado.local == a and ya_jugado.visita == b:
			gl = ya_jugado.goles_local
			gv = ya_jugado.goles_visita
			if gl == gv and not en_grupos:
				pen = ya_jugado.penales()
		else:
			var p := Partido.new(a, b, true)   ## sede neutral
			CopasMundo._aislado("%s%d/%s-%s" % [nombre, anio, a.id, b.id], func() -> void:
				var r := p.simular()
				gl = int(r["local"])
				gv = int(r["visita"])
				if gl == gv and not en_grupos:
					pen = p.penales())
		var pasa: Club = null
		if not en_grupos:
			pasa = a if gl > gv or (gl == gv and (pen.is_empty() or int(pen[0]) >= int(pen[1]))) else b
		else:
			_anotar(a, gl, gv)
			_anotar(b, gv, gl)
		var r2 := {"fase": fase, "local": a, "visita": b, "gl": gl, "gv": gv, "penales": pen, "pasa": pasa}
		hechos.append(r2)
		resultados.append(r2)
	if en_grupos:
		fecha += 1
		if fecha >= fechas_grupo:
			_a_eliminatorias()
	else:
		var siguen: Array[Club] = []
		for r3: Dictionary in hechos:
			siguen.append(r3["pasa"])
		vivos = siguen
		if vivos.size() == 1:
			campeon = vivos[0]
	return hechos

func _anotar(c: Club, gf: int, gc: int) -> void:
	var f: Dictionary = tabla[c.id]
	f["pj"] = int(f["pj"]) + 1
	f["gf"] = int(f["gf"]) + gf
	f["gc"] = int(f["gc"]) + gc
	f["pts"] = int(f["pts"]) + (3 if gf > gc else (1 if gf == gc else 0))

## La tabla ordenada de un grupo: [{club, pts, gf, gc, pj}].
func tabla_de_grupo(g: Array) -> Array:
	var filas: Array = []
	for c: Club in g:
		var f: Dictionary = (tabla[c.id] as Dictionary).duplicate()
		f["club"] = c
		filas.append(f)
	filas.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		if int(x["pts"]) != int(y["pts"]):
			return int(x["pts"]) > int(y["pts"])
		var dx := int(x["gf"]) - int(x["gc"])
		var dy := int(y["gf"]) - int(y["gc"])
		if dx != dy:
			return dx > dy
		if int(x["gf"]) != int(y["gf"]):
			return int(x["gf"]) > int(y["gf"])
		return (x["club"] as Club).rep > (y["club"] as Club).rep)
	return filas

## Los dos primeros de cada grupo y, para completar una potencia de dos, los mejores terceros; cruces 1.º contra 2.º de otro grupo.
func _a_eliminatorias() -> void:
	en_grupos = false
	var primeros: Array[Club] = []
	var segundos: Array[Club] = []
	var terceros: Array = []
	for g: Array in grupos:
		var t := tabla_de_grupo(g)
		if t.size() > 0: primeros.append(t[0]["club"])
		if t.size() > 1: segundos.append(t[1]["club"])
		if t.size() > 2: terceros.append(t[2])
	var n := primeros.size() + segundos.size()
	var meta := 2
	while meta < n:
		meta *= 2
	terceros.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return int(x["pts"]) * 100 + int(x["gf"]) - int(x["gc"]) > int(y["pts"]) * 100 + int(y["gf"]) - int(y["gc"]))
	var extra: Array[Club] = []
	for k in mini(meta - n, terceros.size()):
		extra.append(terceros[k]["club"])
	vivos.clear()
	var segundos_y_terceros: Array[Club] = segundos.duplicate()
	segundos_y_terceros.reverse()   ## el 1.º de A contra el 2.º del último grupo: no se cruzan los del mismo grupo
	segundos_y_terceros.append_array(extra)
	var todos: Array[Club] = primeros.duplicate()
	todos.append_array(segundos_y_terceros)
	var mitad := todos.size() / 2
	for k in mitad:
		vivos.append(todos[k])
		vivos.append(todos[todos.size() - 1 - k])
	if vivos.size() == 1:
		campeon = vivos[0]

## Hasta dónde llegó `c`: 0 campeón, 1 finalista, 2 semifinalista, 3 cuartos, 4 fase de grupos (como `Selecciones.PUESTOS_TORNEO`).
func puesto_de(c: Club) -> int:
	if campeon == c:
		return 0
	var ultimo := ""
	for r: Dictionary in resultados:
		if r["local"] == c or r["visita"] == c:
			ultimo = String(r["fase"])
	match ultimo:
		"Final": return 1
		"Semifinales": return 2
		"Cuartos de final": return 3
	return 4

## Juega todo lo que queda (simulado).
func jugar_entero() -> Club:
	var guard := 0
	while en_curso() and guard < 40:
		jugar_fecha()
		guard += 1
	return campeon
