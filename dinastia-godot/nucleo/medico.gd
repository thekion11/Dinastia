class_name Medico
extends "res://nucleo/medico_p1.gd"
## [Capa 2/2 de `medico.gd`] riesgo_declarado, informe, informe_de, retiro_forzado, _estimar_semanas, ranking_liga … (+4)

## El veredicto en una palabra. El frágil sin historial sale "medio-alto" y no
## "bajo": el informe está para avisar de lo que va a pasar, no solo de lo que
## ya pasó.
func riesgo_declarado(j: Jugador) -> String:
	var graves := lesiones_graves(j)
	if graves >= 2:
		return "alto"
	if graves == 1:
		return "medio"
	return "medio-alto" if j.rasgo == "fragil" else "bajo"

func informe(j: Jugador, c: Club, anio: int = 0) -> String:
	var f := ficha(j)
	if not (f["informe"] as Dictionary).is_empty():
		return "ya tienes su informe médico"
	var costo := costo_informe(j, c.rep)
	if costo > c.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [costo, c.saldo]
	c.mover_saldo(-costo)
	var inf := {"riesgo": riesgo_declarado(j), "graves": lesiones_graves(j), "anio": anio}
	f["informe"] = inf
	gasto.emit("Informe médico de " + j.nombre, costo)
	informe_listo.emit(j, inf)
	return ""

func informe_de(j: Jugador) -> Dictionary:
	return ficha(j)["informe"]

# ---------------------------------------------------------------------------
#  CUANDO EL CUERPO DICE BASTA
# ---------------------------------------------------------------------------

## Retiro forzado: tres lesiones de diez semanas o más y la rodilla ya no
## responde. No se aplica a los chicos —antes de los 27 se vuelve de casi todo—
## y ni siquiera entonces es seguro: es una probabilidad que crece con cada
## lesión larga. Quien lo llame se encarga de sacarlo del mundo; aquí solo se
## dictamina.
func retiro_forzado(j: Jugador) -> bool:
	var graves := lesiones_graves(j, SEM_RETIRO)
	if graves < 3 or j.edad < 27:
		return false
	return Azar.suerte(0.18 + 0.05 * float(graves))

## La estimación para los clubes de la IA: alrededor de la media, peor cuanto
## más modesto es el club. El hash del id la hace ESTABLE —el mismo club da
## siempre la misma cifra dentro de una temporada— porque un ranking que baila
## en cada repintado no se puede leer.
func _estimar_semanas(c: Club) -> int:
	var h := 0
	for i in c.id.length():
		h = (h * 31 + c.id.unicode_at(i)) & 0x7FFFFFFF
	var base := 26.0 - float(c.rep - 50) * 0.16
	return maxi(4, int(round(base + float(h % 11) - 5.0)))

## Dónde estás en la liga por semanas perdidas. Devuelve tu puesto, el total de
## clubes, tus semanas y la media.
##
## Los otros clubes no llevan ficha médica -sería guardar 384 historiales para
## nada-, así que su cifra se ESTIMA a partir de lo que se sabe de ellos: los
## que tienen mejor reputación tienen mejor cuerpo médico y pierden menos. No es
## una simulación, es una referencia, y como tal se presenta.
func ranking_liga(mio: Club, liga: Liga) -> Dictionary:
	if liga == null or mio == null:
		return {"puesto": 1, "total": 1, "mias": dias_perdidos / 7, "media": dias_perdidos / 7}
	var cifras: Array = []
	var suma := 0
	for c: Club in liga.clubes:
		var n := (dias_perdidos / 7) if c == mio else _estimar_semanas(c)
		cifras.append({"club": c, "n": n})
		suma += n
	cifras.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["n"]) < int(b["n"]))
	var puesto := 1
	for i in cifras.size():
		if (cifras[i] as Dictionary)["club"] == mio:
			puesto = i + 1
	return {
		"puesto": puesto, "total": cifras.size(),
		"mias": dias_perdidos / 7,
		"media": int(round(float(suma) / float(maxi(1, cifras.size())))),
	}

## Arranca un brote. Lo llama el pulso semanal cuando toca: unos cuantos tocados
## a la vez, que es lo que obliga a rotar de verdad.
func iniciar_brote(c: Club, cuantos: int, semanas: int) -> void:
	brote = {"n": cuantos, "semanas": semanas}
	var sanos: Array[Jugador] = []
	for j in c.plantilla:
		if j.lesion <= 0:
			sanos.append(j)
	Azar.barajar(sanos)
	for i in mini(cuantos, sanos.size()):
		var j2: Jugador = sanos[i]
		j2.fisico = clampi(j2.fisico - Azar.ent(18, 34), 20, 100)

func avanzar_brote() -> void:
	if brote.is_empty():
		return
	brote["semanas"] = int(brote["semanas"]) - 1
	if int(brote["semanas"]) <= 0:
		brote = {}

func a_dic() -> Dictionary:
	var f := {}
	for id: String in _fichas:
		var x: Dictionary = _fichas[id]
		var sin_historial: bool = (x["historial"] as Array).is_empty()
		var sin_informe: bool = (x["informe"] as Dictionary).is_empty()
		if sin_historial and sin_informe and int(x.get("terapia", 0)) <= 0:
			continue
		f[id] = x
	return {"dias": dias_perdidos, "fichas": f, "brote": brote.duplicate()}

func desde_dic(d: Dictionary) -> void:
	dias_perdidos = int(d.get("dias", 0))
	brote = (d.get("brote", {}) as Dictionary).duplicate()
	_fichas.clear()
	var f: Dictionary = d.get("fichas", {})
	for id: String in f:
		var x: Dictionary = f[id]
		_fichas[id] = {
			"tipo": String(x.get("tipo", "")),
			"clase": String(x.get("clase", "")),
			"total": int(x.get("total", 0)),
			"riesgo_recaida": float(x.get("riesgo_recaida", 0.0)),
			"terapia": int(x.get("terapia", 0)),
			"informe": x.get("informe", {}),
			"historial": x.get("historial", []),
		}
