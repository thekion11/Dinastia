class_name Continental
extends "res://nucleo/continental_p2.gd"
## [Capa 3/3 de `continental.gd`] eliminatorias (a partido único o ida y vuelta), premios, jugar_ronda, guardado

## --- LAS ELIMINATORIAS -----------------------------------------------------

## Lo que cobra el que gana una eliminatoria, según cuántos quedaban vivos antes de jugarla (cifras en `FormatosConti`).
##
## La rareza es del HTML y se deja tal cual: la Libertadores paga casi el doble que cualquier otra copa por la misma
## ronda, la Champions incluida, aunque la Champions reparta el premio de campeón más gordo de todos.
func premio_de_ronda(vivos_antes: int) -> int:
	if es_fifa():
		return 0   ## los torneos de la FIFA no pagan por rondas: solo el 28 % de entrar al cuadro y el premio del campeón
	if vivos_antes == 16 and (formato == FormatosConti.CLASICO or formato == FormatosConti.KO_VIEJO):
		return 0   ## el torneo de antes no tenía octavos
	return FormatosConti.premio_de_ronda(clave, vivos_antes)

## ¿Es un torneo de la FIFA (Mundial de Clubes o Copa Intercontinental) y no un continental de confederación?
func es_fifa() -> bool:
	return FormatosConti.FIFA.has(clave)

## Los participantes de mejor a peor según hasta dónde llegaron: el campeón, y luego por partidos jugados (cuanto más
## lejos, más) y reputación. Lo usa la FIFA para elegir quién va al Mundial de Clubes.
func puestos() -> Array[Club]:
	var jugados := {}
	for h: Dictionary in historial:
		for r: Dictionary in h["resultados"]:
			for c: Club in [r["local"], r["visita"]]:
				jugados[c.id] = int(jugados.get(c.id, 0)) + 1
	var lista: Array[Club] = participantes.duplicate()
	lista.sort_custom(func(a: Club, b: Club) -> bool:
		if (a == campeon) != (b == campeon):
			return a == campeon
		var ja := int(jugados.get(a.id, 0))
		var jb := int(jugados.get(b.id, 0))
		if ja != jb:
			return ja > jb
		return PlazasConti.mas_reputado(a, b))
	return lista

## ¿El partido de esta ronda tiene que acabar con un ganador (prórroga y penales)? Sí en partido único y en la vuelta.
## Lo usa la pantalla del partido en directo.
func necesita_ganador() -> bool:
	if en_fase_de_grupos():
		return false
	return int(hueco_actual().get("pata", 0)) != 1

## Juega un partido de eliminatoria (o toma el que el entrenador acaba de dirigir). Devuelve [goles local, goles visita, partido].
func _partido_de(l: Club, v: Club, neutral: bool, ya_jugado: Partido) -> Array:
	if ya_jugado != null and ya_jugado.local == l and ya_jugado.visita == v:
		return [ya_jugado.goles_local, ya_jugado.goles_visita, ya_jugado]
	var p := Partido.new(l, v, neutral)
	var r := p.simular()
	return [int(r["local"]), int(r["visita"]), p]

func _ida_de(a: Club, b: Club) -> Dictionary:
	for x: Dictionary in _ida:
		if x["local"] == a and x["visita"] == b:
			return x
	return {}

## Juega la ronda de eliminatoria que toque: partido único, ida o vuelta. Los que pasan quedan en `vivos`, en orden de
## cuadro. `ya_jugado` es el partido que el entrenador acaba de dirigir en directo: ese no se vuelve a simular.
func _jugar_eliminatoria(ya_jugado: Partido) -> Array:
	var h := hueco_actual()
	var pata := int(h.get("pata", 0))
	var es_po := String(h.get("t", "")) == "po"
	var titulo := nombre_de_ronda()
	var vivos_antes := vivos.size()
	var final := vivos_antes == 2 and not es_po
	var pasan: Array[Club] = []
	var resultados: Array = []
	var nueva_ida: Array = []
	for i in range(0, vivos.size() - 1, 2):
		var a: Club = vivos[i]
		var b: Club = vivos[i + 1]
		if pata == 1:
			var ri := _partido_de(a, b, false, ya_jugado)
			nueva_ida.append({"local": a, "visita": b, "gl": ri[0], "gv": ri[1]})
			resultados.append({"local": a, "visita": b, "gl": ri[0], "gv": ri[1], "ronda": titulo})
			continue
		var local := a
		var visita := b
		var neutral := false
		var ida := {}
		if pata == 2:
			local = b
			visita = a
			ida = _ida_de(a, b)
		elif final:
			## La final a partido único se juega en cancha neutral, salvo que uno de los dos sea el dueño de la sede fija.
			var en_casa := sede_final_id != "" and (a.id == sede_final_id or b.id == sede_final_id)
			if en_casa and b.id == sede_final_id:
				local = b
				visita = a
			neutral = not en_casa
		var r := _partido_de(local, visita, neutral, ya_jugado)
		var gl: int = r[0]
		var gv: int = r[1]
		var tot_l := gl
		var tot_v := gv
		if pata == 2:
			tot_l = gl + int(ida.get("gv", 0))   ## el local de la vuelta (b) y lo que hizo de visitante en la ida
			tot_v = gv + int(ida.get("gl", 0))
		var penales: Array = []
		if tot_l == tot_v:
			penales = (r[2] as Partido).penales()
		var gana: Club = local
		if tot_v > tot_l:
			gana = visita
		elif tot_l == tot_v and not penales.is_empty() and int(penales[1]) > int(penales[0]):
			gana = visita
		pasan.append(gana)
		var fila := {"local": local, "visita": visita, "gl": gl, "gv": gv, "penales": penales, "pasa": gana, "ronda": titulo}
		if _etiqueta_de(i / 2, vivos_antes) != "":
			fila["etiqueta"] = _etiqueta_de(i / 2, vivos_antes)
		if pata == 2:
			fila["ida"] = [int(ida.get("gv", 0)), int(ida.get("gl", 0))]   ## en el orden de la vuelta: local, visita
			fila["agregado"] = [tot_l, tot_v]
		resultados.append(fila)
	## Un número impar de vivos (un cuadro cargado o armado a mano) no descarta al último club en silencio: pasa con un «bye».
	if pata != 1 and vivos.size() % 2 == 1:
		pasan.append(vivos[vivos.size() - 1])
	historial.append({"ronda": titulo, "resultados": resultados})
	ronda += 1
	if pata == 1:
		_ida = nueva_ida
		ronda_terminada.emit(titulo, resultados)
		return resultados
	_ida.clear()
	vivos = pasan
	if es_po:
		_unir_playoff_y_octavos()
	ronda_terminada.emit(titulo, resultados)
	if vivos.size() == 1:
		campeon = vivos[0]
		campeon.mover_saldo(premio)
		campeon_proclamado.emit(campeon)
	else:
		if not es_po:
			_pagar_eliminatoria(vivos_antes)
		anunciar_sorteo()
	return resultados

## Acabado el playoff, sus ganadores se enfrentan a los ocho primeros de la fase de liga: el 1.º contra el ganador del
## cruce más flojo, y los cabezas de serie en mitades distintas del cuadro. Todos los que llegan a octavos cobran la bolsa.
func _unir_playoff_y_octavos() -> void:
	var ganadores: Array[Club] = vivos.duplicate()
	var cuadro: Array[Club] = []
	var n := _directos.size()
	for s: int in _orden_de_semillas(n):
		cuadro.append(_directos[s])
		cuadro.append(ganadores[ganadores.size() - 1 - s])
	vivos = cuadro
	_pagar_entrada(vivos)

## El orden de los cabezas de serie dentro del cuadro: [0, 7, 3, 4, 1, 6, 2, 5] con 8.
static func _orden_de_semillas(n: int) -> Array:
	var orden: Array = [0]
	var tam := 1
	while tam < n:
		var sig: Array = []
		for x: int in orden:
			sig.append(x)
			sig.append(tam * 2 - 1 - x)
		orden = sig
		tam *= 2
	return orden

## Paga lo que corresponda después de una eliminatoria (la bolsa de la ronda ganada a cada club que pasa).
func _pagar_eliminatoria(vivos_antes: int) -> void:
	var bolsa := premio_de_ronda(vivos_antes)
	if bolsa <= 0:
		return
	for club in vivos:
		club.mover_saldo(bolsa)

## Juega la ronda que toque: fecha de la primera fase o eliminatoria. `ya_jugado` es el partido que el entrenador acaba de
## dirigir en directo; ese no se vuelve a simular, igual que en la liga y en la copa nacional.
func jugar_ronda(ya_jugado: Partido = null) -> Array:
	if not en_curso():
		return []
	if en_fase_de_grupos():
		return _jugar_fecha_de_grupos(ya_jugado)
	return _jugar_eliminatoria(ya_jugado)

## Cómo se llama la ronda que toca. Las de ida y vuelta llevan «· Ida» o «· Vuelta»; el playoff, su nombre.
func nombre_de_ronda() -> String:
	var h := hueco_actual()
	if en_fase_de_grupos():
		return ("Fase de liga · Fecha %d" if es_fase_de_liga() else "Grupos · Fecha %d") % (fecha + 1)
	var base := "Playoff" if String(h.get("t", "")) == "po" else _nombre_ko()
	match int(h.get("pata", 0)):
		1: return base + " · Ida"
		2: return base + " · Vuelta"
	return base

## El nombre de la ronda de eliminatoria por los que quedan. Con «byes» cuentan también los que descansan.
func _nombre_ko() -> String:
	if formato != FormatosConti.BYES:
		return super.nombre_de_ronda()
	var n := vivos.size()
	if clave == "interc":
		return "Final" if n <= 2 else ("Semifinal intercontinental" if n <= 3 else "Challenger Cup y Derbi de las Américas")
	if n <= 2:
		return "Final"
	if n <= 4:
		return "Semifinales"
	if n <= 8:
		return "Cuartos de final"
	return super.nombre_de_ronda()

## La etiqueta de un cruce concreto (la Copa Intercontinental da nombre propio a sus dos primeros partidos).
func _etiqueta_de(i_par: int, vivos_antes: int) -> String:
	if clave == "interc" and vivos_antes == 5:
		return "Challenger Cup" if i_par == 0 else "Derbi de las Américas"
	return ""

func _to_string() -> String:
	if campeon != null:
		return "%s %s: campeón %s" % [nombre, clave, campeon.nombre]
	return "%s %s: %s" % [nombre, clave, nombre_de_ronda()]


## --- GUARDADO --------------------------------------------------------------
## Antes solo se guardaban vivos/inscritos/ronda/fecha: una partida cargada a mitad del continental perdía los grupos, la
## tabla y los clasificados. Los guardados viejos no traen las claves nuevas y siguen abriendo como antes (formato «clasico»).

func grupos_a_dic() -> Dictionary:
	var g: Array = []
	for grupo: Array in grupos:
		g.append(grupo.map(func(c: Club) -> String: return c.id))
	var dias: Array = []
	for d: Array in _dias:
		dias.append(d.map(func(par: Array) -> Array: return [(par[0] as Club).id, (par[1] as Club).id]))
	return {
		"grupos": g, "marcador": marcador.duplicate(true), "de_grupos": _de_grupos.map(func(c: Club) -> String: return c.id),
		"formato": formato, "dias": dias,
		"directos": _directos.map(func(c: Club) -> String: return c.id),
		"ida": _ida.map(func(x: Dictionary) -> Array: return [(x["local"] as Club).id, (x["visita"] as Club).id, x["gl"], x["gv"]]),
	}

func grupos_desde_dic(d: Dictionary, clubes: Dictionary) -> void:
	## Un guardado sin «formato» es de antes de los formatos nuevos: el de 16 clubes y 4 grupos (o la eliminación directa vieja).
	formato = String(d.get("formato", FormatosConti.CLASICO if por_grupos else FormatosConti.KO_VIEJO))
	_huecos.clear()
	grupos.clear()
	for g: Array in d.get("grupos", []):
		var fila: Array = []
		for id: String in g:
			if clubes.has(id):
				fila.append(clubes[id])
		grupos.append(fila)
	marcador = (d.get("marcador", {}) as Dictionary).duplicate(true)
	for k: String in marcador:
		var f: Dictionary = marcador[k]
		for campo: String in f:
			f[campo] = int(f[campo])   ## el JSON devuelve decimales
	_de_grupos = _clubes_de(d.get("de_grupos", []), clubes)
	_directos = _clubes_de(d.get("directos", []), clubes)
	_dias.clear()
	for dia: Array in d.get("dias", []):
		var pares: Array = []
		for par: Array in dia:
			if clubes.has(par[0]) and clubes.has(par[1]):
				pares.append([clubes[par[0]], clubes[par[1]]])
		_dias.append(pares)
	_ida.clear()
	for x: Array in d.get("ida", []):
		if clubes.has(x[0]) and clubes.has(x[1]):
			_ida.append({"local": clubes[x[0]], "visita": clubes[x[1]], "gl": int(x[2]), "gv": int(x[3])})

static func _clubes_de(ids: Array, clubes: Dictionary) -> Array[Club]:
	var salida: Array[Club] = []
	for id: String in ids:
		if clubes.has(id):
			salida.append(clubes[id])
	return salida
