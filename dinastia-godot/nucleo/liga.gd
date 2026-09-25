class_name Liga
extends RefCounted
## Un campeonato de ida y vuelta, con su calendario y su tabla.
##
## El calendario se arma con el metodo del circulo (Berger): un equipo se queda
## fijo y los demas rotan. Garantiza que todos juegan una vez por jornada y que
## nadie repite rival en la primera vuelta, cosa que un sorteo al azar no
## garantiza y que hay que arreglar despues a parches.

signal jornada_terminada(numero: int, resultados: Array)
signal campeonato_terminado(campeon: Club)

var nombre: String = ""
var pais: String = "CHI"
## 1 = primera, 2 = segunda. Decide quien sube, quien baja y cuanto cobra cada
## club de television, que es la diferencia economica real entre divisiones.
var div: int = 1
var clubes: Array[Club] = []
var calendario: Array = []       ## Array de jornadas; cada jornada, Array de [local, visita]
var jornada_actual: int = 0
## Lo que YA se jugó, jornada a jornada: cada entrada es la lista de
## {local, visita, gl, gv} de esa fecha. No se guarda en la partida -se puede
## reconstruir la tabla sin él y ocuparía bastante-, así que al cargar empieza
## vacío y se vuelve a llenar a partir de la jornada siguiente.
var historial: Array = []
var tabla_puntos: Dictionary = {}   ## club_id -> {pts, pj, gf, gc, g, e, p}

func _init(_nombre: String = "", _pais: String = "CHI", _div: int = 1) -> void:
	nombre = _nombre
	pais = _pais
	div = _div

func division() -> int:
	return div

func preparar() -> void:
	_armar_tabla()
	_armar_calendario()
	jornada_actual = 0

func _armar_tabla() -> void:
	tabla_puntos.clear()
	for c in clubes:
		tabla_puntos[c.id] = {"pts": 0, "pj": 0, "gf": 0, "gc": 0, "g": 0, "e": 0, "p": 0}

func _armar_calendario() -> void:
	calendario.clear()
	if clubes.size() < 2:
		return
	var lista: Array[Club] = clubes.duplicate()
	## Con un numero impar de equipos se anade un hueco: quien le toque ese
	## hueco descansa esa jornada. Sin esto, el metodo del circulo no cierra.
	var descansa := lista.size() % 2 == 1
	if descansa:
		lista.append(null)
	var n := lista.size()
	var ida: Array = []
	for ronda in n - 1:
		var jornada: Array = []
		for i in n / 2:
			var a: Club = lista[i]
			var b: Club = lista[n - 1 - i]
			if a == null or b == null:
				continue
			## Se alterna quien es local por ronda para que nadie acumule
			## demasiados partidos seguidos en casa.
			if ronda % 2 == 0:
				jornada.append([a, b])
			else:
				jornada.append([b, a])
		ida.append(jornada)
		## Rotacion: el primero se queda fijo, el resto gira una posicion.
		var ultimo: Club = lista.pop_back()
		lista.insert(1, ultimo)
	for j in ida:
		calendario.append(j)
	## Vuelta: los mismos cruces con los campos cambiados.
	for j in ida:
		var vuelta: Array = []
		for par in j:
			vuelta.append([par[1], par[0]])
		calendario.append(vuelta)

func jornadas() -> int:
	return calendario.size()

func quedan_jornadas() -> bool:
	return jornada_actual < calendario.size()

## El cruce de esta jornada en el que juega este club, o vacío si descansa.
## Lo necesita la interfaz para poder jugar ESE partido en directo antes de que
## el mundo simule los otros quince.
func emparejamiento_de(c: Club) -> Array:
	if not quedan_jornadas():
		return []
	for par: Array in calendario[jornada_actual]:
		if par[0] == c or par[1] == c:
			return par
	return []

## Juega la jornada. Si se le pasa un partido ya jugado -el que el entrenador
## acaba de dirigir en directo-, ese NO se vuelve a simular: se anota su
## resultado tal cual.
##
## Sin esto, el partido que acabas de ganar remontando se volvía a jugar por
## dentro y en la tabla aparecía otro marcador. El jugador vería un resultado en
## la pantalla del partido y otro distinto en la tabla, que es la clase de fallo
## que hace desconfiar de todo lo demás.
func jugar_jornada(ya_jugado: Partido = null) -> Array:
	if not quedan_jornadas():
		return []
	var resultados: Array = []
	for par in calendario[jornada_actual]:
		var gl := 0
		var gv := 0
		if ya_jugado != null and ya_jugado.local == par[0] and ya_jugado.visita == par[1]:
			gl = ya_jugado.goles_local
			gv = ya_jugado.goles_visita
		else:
			var p := Partido.new(par[0], par[1])
			var r := p.simular()
			gl = r["local"]
			gv = r["visita"]
		_anotar_resultado(par[0], par[1], gl, gv)
		resultados.append({"local": par[0], "visita": par[1], "gl": gl, "gv": gv})
	## Se guarda la jornada entera, no solo se emite. Hasta ahora el resultado
	## viajaba en la señal y se perdía: la tabla sabía los puntos pero nadie
	## podía volver a mirar CÓMO se llegó a ellos. La pantalla de competición
	## -"últimos resultados"- necesita justo eso.
	historial.append(resultados.duplicate())
	jornada_actual += 1
	jornada_terminada.emit(jornada_actual, resultados)
	if not quedan_jornadas():
		var t := tabla()
		if not t.is_empty():
			campeonato_terminado.emit(t[0]["club"])
	return resultados

func _anotar_resultado(l: Club, v: Club, gl: int, gv: int) -> void:
	var a: Dictionary = tabla_puntos[l.id]
	var b: Dictionary = tabla_puntos[v.id]
	a["pj"] += 1; b["pj"] += 1
	a["gf"] += gl; a["gc"] += gv
	b["gf"] += gv; b["gc"] += gl
	if gl > gv:
		a["pts"] += 3; a["g"] += 1; b["p"] += 1
	elif gl < gv:
		b["pts"] += 3; b["g"] += 1; a["p"] += 1
	else:
		a["pts"] += 1; b["pts"] += 1; a["e"] += 1; b["e"] += 1

## Tabla ordenada: puntos, diferencia de gol, goles a favor.
func tabla() -> Array:
	var filas: Array = []
	for c in clubes:
		var d: Dictionary = tabla_puntos[c.id]
		filas.append({
			"club": c, "pts": d["pts"], "pj": d["pj"], "g": d["g"], "e": d["e"], "p": d["p"],
			"gf": d["gf"], "gc": d["gc"], "dif": d["gf"] - d["gc"],
		})
	filas.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		if x["pts"] != y["pts"]: return x["pts"] > y["pts"]
		if x["dif"] != y["dif"]: return x["dif"] > y["dif"]
		return x["gf"] > y["gf"])
	return filas

func jugar_temporada() -> Array:
	while quedan_jornadas():
		jugar_jornada()
	return tabla()
