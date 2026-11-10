extends "res://nucleo/continental_p1.gd"
## [Capa 2/3 de `continental.gd`] preparar, calendario de huecos, primera fase (grupos y fase de liga) y el cuadro

## --- EL SORTEO -------------------------------------------------------------

## Monta el torneo con estos clubes y el formato de su clave (o «ko» si no llegan a las plazas del formato).
func preparar(clubes: Array[Club]) -> void:
	preparar_con(clubes, "")

## Igual que `preparar`, con el formato forzado (pruebas y partidas viejas). «» = el de su clave.
##
## Con menos clubes que plazas no hay primera fase: se juega a eliminación directa desde el principio con lo que haya,
## que es exactamente para lo que sirve `Copa`. Pasa en los mundos de prueba, no en una partida de verdad.
func preparar_con(clubes: Array[Club], id: String) -> void:
	fecha = 0
	grupos.clear()
	marcador.clear()
	_de_grupos.clear()
	_dias.clear()
	_directos.clear()
	_ida.clear()
	_huecos.clear()
	if id == "":
		id = clave if (FormatosConti.existe(clave) and clubes.size() >= FormatosConti.plazas(clave)) else FormatosConti.KO
	formato = id
	var f := FormatosConti.formato(id)
	var fase := String(f.get("fase", "ko"))
	por_grupos = fase != "ko"
	if id == FormatosConti.BYES:
		## Eliminación directa en el orden dado y con «byes»: el último de la lista descansa cuando sobra uno.
		por_grupos = false
		participantes = clubes.duplicate()
		vivos = clubes.duplicate()
		ronda = 0
		campeon = null
		historial.clear()
		return
	if id == FormatosConti.KO or id == FormatosConti.KO_VIEJO:
		por_grupos = false
		super.preparar(clubes)
		return
	vivos = []
	ronda = 0
	campeon = null
	historial.clear()
	participantes.clear()
	var n := mini(int(f["plazas"]), clubes.size())
	for i in n:
		participantes.append(clubes[i])
	if fase == "ko":
		var por_rep: Array[Club] = participantes.duplicate()
		por_rep.sort_custom(_mas_reputado)
		vivos = _cuadro_sembrado(por_rep)
		return
	for c in participantes:
		marcador[c.id] = {"pts": 0, "pj": 0, "gf": 0, "gc": 0}
	if fase == "liga":
		var sembrados: Array[Club] = participantes.duplicate()
		sembrados.sort_custom(_mas_reputado)
		_dias = SorteoLigaConti.armar(sembrados)
		if _dias.is_empty():   ## nunca debería pasar; si pasa, el torneo se juega igual, por eliminación
			formato = FormatosConti.KO
			por_grupos = false
			marcador.clear()
			super.preparar(clubes)
			return
		grupos.append(sembrados)
	else:
		## Los grupos NO se barajan: el orden en que llegan es el del reparto de plazas y el «uno para cada grupo por
		## turnos» es lo que evita que los tres brasileños caigan juntos. Barajar rompería ese sembrado.
		var g := n / int(f["grupos_tam"])
		for i in g:
			grupos.append([])
		for i in n:
			grupos[i % g].append(participantes[i])
	sorteo_grupos.emit(grupos.duplicate())

func participa(c: Club) -> bool:
	return c != null and participantes.has(c)

## Cuadro de eliminación sembrado: el 1 contra el último, y los cabezas de serie en mitades distintas. `sembrados` va de
## mejor a peor y es potencia de 2. Si no, el orden en que llega.
static func _cuadro_sembrado(sembrados: Array[Club]) -> Array[Club]:
	var n := sembrados.size()
	if n < 2 or (n & (n - 1)) != 0:
		return sembrados.duplicate()
	var orden: Array = [0]
	var tam := 1
	while tam < n:
		var sig: Array = []
		for x: int in orden:
			sig.append(x)
			sig.append(tam * 2 - 1 - x)
		orden = sig
		tam *= 2
	var salida: Array[Club] = []
	for i: int in orden:
		salida.append(sembrados[i])
	return salida


## --- EL CALENDARIO ---------------------------------------------------------

## Los partidos del torneo, uno por semana (ver `FormatosConti.huecos`).
func huecos() -> Array:
	if _huecos.is_empty():
		var sin_formato := formato == FormatosConti.KO or formato == FormatosConti.KO_VIEJO or formato == FormatosConti.BYES
		_huecos = FormatosConti.huecos(formato, participantes.size() if sin_formato else 0)
	return _huecos

## La semana de la temporada de cada partido.
func semanas() -> Array:
	return FormatosConti.semanas(formato, clave, huecos().size())

func hueco_actual() -> Dictionary:
	var h := huecos()
	return h[ronda] if ronda >= 0 and ronda < h.size() else {}

## ¿Le toca jugar a este torneo en esta semana? Juega el hueco que sigue cuando llega su semana (o ya pasó: si una semana
## se salta, no se pierde ninguna ronda; se recupera de a una por semana).
func toca(semana_de_liga: int) -> bool:
	if not en_curso():
		return false
	var s := semanas()
	return ronda < s.size() and semana_de_liga >= int(s[ronda])

func es_fase_de_liga() -> bool:
	return String(FormatosConti.formato(formato).get("fase", "")) == "liga"

## Partidos de la primera fase por club.
func fechas_primera_fase() -> int:
	return int(FormatosConti.formato(formato).get("fechas", 0))

func en_fase_de_grupos() -> bool:
	if not por_grupos:
		return false
	var h := hueco_actual()
	return not h.is_empty() and (h["t"] == "liga" or h["t"] == "grupos")

## Se sobrescribe porque durante la primera fase `vivos` está vacío: el cuadro no existe hasta que termina, y la versión
## de `Copa` daría el torneo por acabado antes de empezar.
func en_curso() -> bool:
	if campeon != null:
		return false
	if en_fase_de_grupos():
		return true
	return vivos.size() >= 2

func nombre_de_grupo(i: int) -> String:
	if es_fase_de_liga():
		return "Fase de liga"
	return "Grupo %s" % "ABCDEFGH".substr(i, 1) if i >= 0 and i < 8 else "Grupo"

## El calendario de un grupo de cuatro, tal cual el `fixGrupo` del HTML: cada uno juega tres partidos, nadie repite
## rival y el primero de la lista es siempre local. Las fechas 4-6 (a doble vuelta) son las tres primeras con los campos cambiados.
static func _cruces_de_grupo(g: Array, r: int) -> Array:
	if g.size() < 4:
		return []
	if r >= 3:
		var vuelta: Array = []
		for par: Array in _cruces_de_grupo(g, r - 3):
			vuelta.append([par[1], par[0]])
		return vuelta
	var a: Club = g[0]
	var b: Club = g[1]
	var c: Club = g[2]
	var d: Club = g[3]
	match r:
		0: return [[a, d], [b, c]]
		1: return [[a, c], [d, b]]
		_: return [[a, b], [c, d]]

## Los cruces de la fecha de la primera fase en juego: [local, visita, índice del grupo].
func _cruces_de_la_fecha() -> Array:
	var salida: Array = []
	if es_fase_de_liga():
		if fecha < _dias.size():
			for par: Array in _dias[fecha]:
				salida.append([par[0], par[1], 0])
		return salida
	for i in grupos.size():
		for par: Array in _cruces_de_grupo(grupos[i], fecha):
			salida.append([par[0], par[1], i])
	return salida

## El cruce en el que juega tu club esta ronda, [local, visita], o vacío. Lo pide la interfaz para dirigir ESE partido
## antes de que se simulen los demás.
func emparejamiento_de(c: Club) -> Array:
	if campeon != null or c == null:
		return []
	if en_fase_de_grupos():
		for x: Array in _cruces_de_la_fecha():
			if x[0] == c or x[1] == c:
				return [x[0], x[1]]
		return []
	return _cruce_ko_de(c)

## En eliminatoria: el cruce de este club; en la vuelta se invierte el campo.
func _cruce_ko_de(c: Club) -> Array:
	if not en_curso():
		return []
	var vuelta := int(hueco_actual().get("pata", 0)) == 2
	for i in range(0, vivos.size() - 1, 2):
		if vivos[i] == c or vivos[i + 1] == c:
			return [vivos[i + 1], vivos[i]] if vuelta else [vivos[i], vivos[i + 1]]
	return []


## --- LA PRIMERA FASE (grupos o fase de liga) -------------------------------

func _anotar(l: Club, v: Club, gl: int, gv: int) -> void:
	var a: Dictionary = marcador[l.id]
	var b: Dictionary = marcador[v.id]
	a["pj"] += 1
	b["pj"] += 1
	a["gf"] += gl
	a["gc"] += gv
	b["gf"] += gv
	b["gc"] += gl
	if gl > gv:
		a["pts"] += 3
	elif gv > gl:
		b["pts"] += 3
	else:
		a["pts"] += 1
		b["pts"] += 1

## Ordena un grupo: puntos, diferencia de gol, goles a favor y, como último desempate, la posición de sembrado. Ese
## último criterio sustituye a la ordenación estable de JavaScript, en la que el HTML se apoyaba sin decirlo;
## `sort_custom` no la garantiza y sin él dos partidas con la misma semilla podrían clasificar a equipos distintos.
func _ordenar_grupo(g: Array) -> Array[Club]:
	var filas: Array = []
	for i in g.size():
		var c: Club = g[i]
		var m: Dictionary = marcador.get(c.id, {})
		var gf := int(m.get("gf", 0))
		var gc := int(m.get("gc", 0))
		filas.append({"club": c, "pts": int(m.get("pts", 0)), "dif": gf - gc, "gf": gf, "i": i})
	filas.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		if x["pts"] != y["pts"]: return x["pts"] > y["pts"]
		if x["dif"] != y["dif"]: return x["dif"] > y["dif"]
		if x["gf"] != y["gf"]: return x["gf"] > y["gf"]
		return x["i"] < y["i"])
	var salida: Array[Club] = []
	for f: Dictionary in filas:
		salida.append(f["club"])
	return salida

func _jugar_fecha_de_grupos(ya_jugado: Partido = null) -> Array:
	var titulo := nombre_de_ronda()
	var resultados: Array = []
	for x: Array in _cruces_de_la_fecha():
		var l: Club = x[0]
		var v: Club = x[1]
		var gl := 0
		var gv := 0
		if ya_jugado != null and ya_jugado.local == l and ya_jugado.visita == v:
			gl = ya_jugado.goles_local
			gv = ya_jugado.goles_visita
		else:
			## En la primera fase sí hay ventaja de local: el sorteo de localías ya está en los cruces.
			var p := Partido.new(l, v)
			var r := p.simular()
			gl = r["local"]
			gv = r["visita"]
		_anotar(l, v, gl, gv)
		resultados.append({"local": l, "visita": v, "gl": gl, "gv": gv, "ronda": titulo, "grupo": int(x[2])})
	historial.append({"ronda": titulo, "resultados": resultados})
	fecha += 1
	ronda += 1
	ronda_terminada.emit(titulo, resultados)
	if fecha >= fechas_primera_fase():
		_cerrar_primera_fase()
	return resultados

## Cierra la primera fase y arma lo que sigue: el cuadro (grupos, y asia) o el playoff (Champions y compañía).
func _cerrar_primera_fase() -> void:
	if es_fase_de_liga():
		_cerrar_fase_de_liga()
	else:
		_armar_llaves()
	grupos_terminados.emit(clasificados())
	## Salir de la primera fase abre el cuadro (o el playoff), y eso es OTRO sorteo: el momento de la cinemática.
	anunciar_sorteo()

func _cerrar_fase_de_liga() -> void:
	var f := FormatosConti.formato(formato)
	var orden := _ordenar_grupo(grupos[0])
	var directos := int(f["directos"])
	var playoff := int(f.get("playoff", 0))
	_directos.clear()
	for i in directos:
		_directos.append(orden[i])
	if playoff <= 0:
		vivos = _cuadro_sembrado(_directos)
		_de_grupos = vivos.duplicate()
		_pagar_entrada(vivos)
		return
	## Los puestos siguientes juegan el playoff: el 9.º contra el 24.º, el 10.º contra el 23.º…
	var po: Array[Club] = []
	for i in playoff:
		po.append(orden[directos + i])
	vivos = []
	for k in playoff / 2:
		vivos.append(po[k])
		vivos.append(po[playoff - 1 - k])
	_de_grupos = _directos.duplicate()
	_de_grupos.append_array(po)

## Los dos primeros de cada grupo pasan; los cruces son los del HTML: 1ºA-2ºB, 1ºC-2ºD, … y luego 1ºB-2ºA, 1ºD-2ºC, …
## Nadie se repite con alguien de su grupo y los primeros no se cruzan entre sí hasta rondas avanzadas.
##
## OJO con el orden de `vivos`: `jugar_ronda` empareja por posición, de dos en dos. Meter los clasificados en otro orden
## no cambia quién está, cambia el cuadro entero.
func _armar_llaves() -> void:
	if grupos.size() < 2:
		return
	var t: Array = []
	for g in grupos:
		var o := _ordenar_grupo(g)
		if o.size() < 2:
			return
		t.append(o)
	var cuadro: Array[Club] = []
	for k in range(0, t.size() - 1, 2):
		cuadro.append((t[k] as Array)[0])
		cuadro.append((t[k + 1] as Array)[1])
	for k in range(0, t.size() - 1, 2):
		cuadro.append((t[k + 1] as Array)[0])
		cuadro.append((t[k] as Array)[1])
	vivos = cuadro
	_de_grupos = cuadro.duplicate()
	_pagar_entrada(vivos)

## Pasar de la primera fase al cuadro ya paga: el 28 % del premio del campeón. Es el ingreso internacional que de verdad
## ve un club mediano, porque llegar a la final la mayoría de los años no le va a pasar.
func _pagar_entrada(clubes: Array) -> void:
	var bolsa := premio_de_cuartos()
	for club: Club in clubes:
		club.mover_saldo(bolsa)

func premio_de_cuartos() -> int:
	return roundi(float(premio) * CUOTA_CUARTOS)

## La tabla de un grupo, ya ordenada y lista para pintar.
func tabla_de_grupo(i: int) -> Array:
	if i < 0 or i >= grupos.size():
		return []
	var salida: Array = []
	for c: Club in _ordenar_grupo(grupos[i]):
		var m: Dictionary = marcador.get(c.id, {})
		var gf := int(m.get("gf", 0))
		var gc := int(m.get("gc", 0))
		salida.append({
			"club": c, "pts": int(m.get("pts", 0)), "pj": int(m.get("pj", 0)),
			"gf": gf, "gc": gc, "dif": gf - gc,
		})
	return salida

## Las filas de un grupo con su puesto ({puesto, club, pj, gf, gc, dif, pts}). Si el grupo es largo (la fase de liga de 36), con
## `ventana` > 0 solo las más cercanas a `club` (la mitad por arriba y la mitad por abajo): la columna del menú no da para 36 filas.
func filas_con_puesto(i: int, club: Club = null, ventana: int = 0) -> Array:
	var filas := tabla_de_grupo(i)
	for k in filas.size():
		(filas[k] as Dictionary)["puesto"] = k + 1
	if ventana <= 0 or filas.size() <= ventana or club == null:
		return filas
	var centro := 0
	for k in filas.size():
		if (filas[k] as Dictionary)["club"] == club:
			centro = k
	var ini := clampi(centro - ventana / 2, 0, filas.size() - ventana)
	return filas.slice(ini, ini + ventana)

## Qué le espera a quien acaba la primera fase en ese puesto: «directo» (al cuadro principal), «playoff» o «» (eliminado).
func destino_en_primera_fase(puesto: int) -> String:
	var f := FormatosConti.formato(formato)
	if es_fase_de_liga():
		if puesto <= int(f.get("directos", 0)):
			return "directo"
		return "playoff" if puesto <= int(f.get("directos", 0)) + int(f.get("playoff", 0)) else ""
	return "directo" if puesto <= 2 else ""

## La primera ronda del cuadro principal, en castellano («Octavos de final», «Cuartos de final»…): adónde pasan los clasificados.
func nombre_primera_ronda_del_cuadro() -> String:
	for h: Dictionary in huecos():
		if String(h["t"]) == "ko":
			match int(h["vivos"]):
				16: return "Octavos de final"
				8: return "Cuartos de final"
				4: return "Semifinales"
				32: return "Dieciseisavos"
			return "Cuadro principal"
	return "Cuadro principal"

## El texto «Pasa a …» de la zona de clasificación, en castellano (la interfaz lo traduce: son claves exactas).
func texto_de_pase() -> String:
	match nombre_primera_ronda_del_cuadro():
		"Octavos de final": return "Pasa a octavos"
		"Cuartos de final": return "Pasa a cuartos"
		"Semifinales": return "Pasa a semifinales"
	return "Pasa al cuadro"

## Los cruces de la próxima fecha de la primera fase, [local, visita] (la interfaz los enseña como «PRÓXIMA FECHA»).
func cruces_de_la_fecha() -> Array:
	var salida: Array = []
	if en_fase_de_grupos():
		for x: Array in _cruces_de_la_fecha():
			salida.append([x[0], x[1]])
	return salida

## Los que salieron de la primera fase, en orden de cuadro. Vacío mientras siga en juego.
##
## Se guarda aparte y no se devuelve `vivos`: `vivos` se va vaciando ronda a ronda hasta dejar solo al campeón, y quien
## pregunte «quién pasó de grupos» en semifinales quiere a todos los que pasaron, no los dos que quedan.
func clasificados() -> Array[Club]:
	return _de_grupos.duplicate()
