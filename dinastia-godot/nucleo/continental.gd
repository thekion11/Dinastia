class_name Continental
extends "res://nucleo/continental_p1.gd"
## [Capa 2/2 de `continental.gd`] _anotar, _ordenar_grupo, premio_de_cuartos, _armar_llaves, _jugar_fecha_de_grupos, premio_de_ronda … (+5)

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

## Ordena un grupo: puntos, diferencia de gol, goles a favor y, como último
## desempate, la posición de sembrado. Ese último criterio sustituye a la
## ordenación estable de JavaScript, en la que el HTML se apoyaba sin decirlo;
## `sort_custom` no la garantiza y sin él dos partidas con la misma semilla
## podrían clasificar a equipos distintos.
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


## --- LOS PREMIOS -----------------------------------------------------------

func premio_de_cuartos() -> int:
	return roundi(float(premio) * CUOTA_CUARTOS)

## Cierra los grupos y arma el cuadro de cuartos.
##
## Los cruces son los del HTML: 1ºA-2ºB, 1ºC-2ºD, 1ºB-2ºA, 1ºD-2ºC. Nadie se
## repite con alguien de su grupo y los cuatro primeros no se cruzan entre sí
## hasta semifinales.
##
## OJO con el orden de `vivos`: `Copa.jugar_ronda` empareja por posición, de dos
## en dos. Meter los ocho clasificados en otro orden no cambia quién está, cambia
## el cuadro entero.
func _armar_llaves() -> void:
	if grupos.size() < GRUPOS:
		return
	var t: Array = []
	for g in grupos:
		var o := _ordenar_grupo(g)
		if o.size() < 2:
			return
		t.append(o)
	var a: Array[Club] = t[0]
	var b: Array[Club] = t[1]
	var c: Array[Club] = t[2]
	var d: Array[Club] = t[3]
	var cuadro: Array[Club] = []
	for club in [a[0], b[1], c[0], d[1], b[0], a[1], d[0], c[1]]:
		cuadro.append(club)
	vivos = cuadro
	_de_grupos = cuadro.duplicate()
	## Salir de la fase de grupos ya paga: el 28% del premio del campeón, para
	## los ocho. Es el ingreso internacional que de verdad ve un club mediano,
	## porque llegar a la final la mayoría de los años no le va a pasar.
	var bolsa := premio_de_cuartos()
	for club in vivos:
		club.mover_saldo(bolsa)
	grupos_terminados.emit(vivos.duplicate())
	## Salir de los grupos abre el cuadro, y eso es OTRO sorteo: es el momento
	## de la cinemática de cuartos.
	anunciar_sorteo()

func _jugar_fecha_de_grupos(ya_jugado: Partido = null) -> Array:
	var titulo := nombre_de_ronda()
	var resultados: Array = []
	for i in grupos.size():
		for par: Array in _cruces_de_grupo(grupos[i], fecha):
			var l: Club = par[0]
			var v: Club = par[1]
			var gl := 0
			var gv := 0
			if ya_jugado != null and ya_jugado.local == l and ya_jugado.visita == v:
				gl = ya_jugado.goles_local
				gv = ya_jugado.goles_visita
			else:
				## En grupos sí hay ventaja de local: el partido es de ida única
				## y el sorteo de localías ya está en `_cruces_de_grupo`.
				var p := Partido.new(l, v)
				var r := p.simular()
				gl = r["local"]
				gv = r["visita"]
			_anotar(l, v, gl, gv)
			resultados.append({
				"local": l, "visita": v, "gl": gl, "gv": gv,
				"ronda": titulo, "grupo": i,
			})
	historial.append({"ronda": titulo, "resultados": resultados})
	fecha += 1
	ronda += 1
	ronda_terminada.emit(titulo, resultados)
	if fecha >= FECHAS_DE_GRUPO:
		_armar_llaves()
	return resultados

## Lo que cobra el que gana una eliminatoria, según cuántos quedaban vivos antes
## de jugarla: ocho eran cuartos (premio de semifinalista) y cuatro, semifinales
## (premio de finalista).
##
## La rareza es del HTML y se deja tal cual: la Libertadores paga casi el doble
## que cualquier otra copa por la misma ronda, la Champions incluida, aunque la
## Champions reparta el premio de campeón más gordo de todos. No es una errata de
## transcripción; está así en el original.
func premio_de_ronda(vivos_antes: int) -> int:
	match vivos_antes:
		8: return 350000 if clave == "lib" else 180000
		4: return 500000 if clave == "lib" else 250000
	return 0

## Paga lo que corresponda después de una eliminatoria.
##
## La final es un caso aparte: `Copa.jugar_ronda` ya le ha abonado al campeón su
## premio fijo de copa nacional, que no es el de este torneo. Aquí se abona la
## DIFERENCIA hasta el premio continental en vez de reescribir la eliminatoria
## entera solo para cambiar una cifra. Se resta la constante y no el número 220000
## para que esto siga cuadrando si algún día `Copa` sube su premio.
func _pagar_eliminatoria(vivos_antes: int) -> void:
	if vivos_antes <= 2:
		if campeon != null:
			campeon.mover_saldo(premio - Copa.PREMIO)
		return
	var bolsa := premio_de_ronda(vivos_antes)
	if bolsa <= 0:
		return
	for club in vivos:
		club.mover_saldo(bolsa)

## Juega la ronda que toque: fecha de grupos o eliminatoria. `ya_jugado` es el
## partido que el entrenador acaba de dirigir en directo; ese no se vuelve a
## simular, igual que en la liga y en la copa nacional.
func jugar_ronda(ya_jugado: Partido = null) -> Array:
	if not en_curso():
		return []
	if en_fase_de_grupos():
		return _jugar_fecha_de_grupos(ya_jugado)
	var vivos_antes := vivos.size()
	var resultados := super.jugar_ronda(ya_jugado)
	_pagar_eliminatoria(vivos_antes)
	return resultados

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

## Los ocho que salieron de los grupos, en orden de cuadro. Vacío mientras los
## grupos sigan en juego.
##
## Se guarda aparte y no se devuelve `vivos`: `vivos` se va vaciando ronda a
## ronda hasta dejar solo al campeón, y quien pregunte "quién pasó de grupos" en
## semifinales quiere los ocho, no los dos que quedan.
func clasificados() -> Array[Club]:
	return _de_grupos.duplicate()

func _to_string() -> String:
	if campeon != null:
		return "%s %s: campeón %s" % [nombre, clave, campeon.nombre]
	return "%s %s: %s" % [nombre, clave, nombre_de_ronda()]
