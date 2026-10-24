class_name Redes
extends "res://nucleo/redes_p1.gd"
## [Capa 2/2 de `redes.gd`] comentar_ultimo_partido, semana, comentar_jugador, a_dic, desde_dic

func comentar_ultimo_partido(m: Mundo) -> Array:
	var u: Dictionary = Partido.ultimo_mio
	var c := m.mi_club()
	if u.is_empty() or c == null:
		return []
	var clave := "%d|%d|%s" % [int(u["anio"]), int(u["semana"]), String(u["local"])]
	if clave == _comentado:
		return []
	_comentado = clave
	var local_mio := String(u["local_id"]) == c.id
	var gf := int(u["gl"]) if local_mio else int(u["gv"])
	var gc := int(u["gv"]) if local_mio else int(u["gl"])
	var rival := String(u["visita"]) if local_mio else String(u["local"])
	var nuestros: Array = []
	var suyos: Array = []
	for e: Dictionary in u["cronica"]:
		if String(e.get("tipo", "")) != "gol":
			continue
		(nuestros if String(e.get("club", "")) == c.id else suyos).append(e)
	var frases: Array = []
	for g: Dictionary in nuestros:
		var mi := int(g["min"])
		if mi >= 85:
			frases.append("¡¡%s en el %d'!! Me quedé sin voz. Esto es fútbol. %s" % [g["autor"], mi, hashtag_club(c)])
		elif frases.size() < 2:
			frases.append("Qué golazo el de %s en el %d'. Que alguien le renueve YA." % [g["autor"], mi])
	if gf >= gc + 3:
		frases.append("%d-%d a %s. Esta noche no duerme nadie en la ciudad." % [gf, gc, rival])
	elif gf < gc:
		if not suyos.is_empty():
			var ult: Dictionary = suyos[suyos.size() - 1]
			frases.append("Ese gol de %s en el %d' nos dolió en el alma. %d-%d y a casa." % [ult["autor"], int(ult["min"]), gf, gc])
		else:
			frases.append("Perder %d-%d contra %s… alguien tiene que dar explicaciones." % [gf, gc, rival])
	elif gf == gc:
		frases.append("%d-%d con %s. Punto y gracias, pero se podía más." % [gf, gc, rival])
	if nuestros.is_empty() and gf == 0:
		frases.append("Noventa minutos sin hacerle un gol a %s. Así no." % rival)
	var hechas: Array = []
	for t: String in frases.slice(0, 3):
		var f := _nueva("fan", t, [hashtag_club(c), "#DíaDePartido"], "opinion", m)
		f["autor"] = FANS[_rng.randi() % FANS.size()]
		f["likes"] = _rng.randi_range(20, 900)
		f["compartidos"] = _rng.randi_range(0, 80)
		_comentar(f, _rng.randi_range(0, 2), "bien" if gf > gc else ("mal" if gf < gc else ""))
		hechas.append(f)
	return hechas

## Cada semana: los seguidores se mueven, cambia la tendencia y, a las pocas
## semanas en el club, llega el acceso a la cuenta oficial.
func semana(m: Mundo) -> void:
	var c := m.mi_club()
	_semanas_club += 1
	if not acceso_club and c != null and _semanas_club >= SEMANAS_PARA_ACCESO:
		dar_acceso_club(m)
	if c != null:
		var obj := seguidores_base_club(c)
		var segs := int(cuentas["club"]["seguidores"])
		## Se acercan poco a poco a lo que "le toca" por reputación, más un
		## crecimiento natural pequeño.
		cuentas["club"]["seguidores"] = segs + int((obj - segs) * 0.05) + int(segs * 0.002)
	var fama := 50
	if m.roles != null and m.roles.reputacion != null:
		fama = m.roles.reputacion.valor("mediatico")
	var dt := int(cuentas["dt"]["seguidores"])
	cuentas["dt"]["seguidores"] = maxi(100, dt + int(dt * (float(fama) - 45.0) / 4000.0) + _rng.randi_range(0, 12))
	_publican_jugadores(m)
	comentar_ultimo_partido(m)
	var tags := ["#DíaDePartido", "#Hinchada", "#Cantera", "#Trabajo", "#Familia", hashtag_club(c)]
	tendencia = String(tags[(m.semana + m.anio) % tags.size()])

## Tu comentario en la publicación de un jugador de tu plantel (uno por
## publicación). Mueve su moral según cómo estaba. Devuelve el mensaje.
func comentar_jugador(m: Mundo, pub_id: int, tono: String) -> String:
	var p := buscar(pub_id)
	if p.is_empty() or String(p.get("cuenta", "")) != "jugador" or not COMENTAR_JUGADOR.has(tono):
		return "no se puede comentar eso"
	if bool(p.get("comentado", false)):
		return "ya le comentaste"
	var j := m.jugador_por_id(String(p.get("jugador_id", "")))
	var d: Array = COMENTAR_JUGADOR[tono]
	p["comentado"] = true
	(p["comentarios"] as Array).push_front({"autor": String(cuentas["dt"]["usuario"]), "texto": String(d[2]), "tono": "tuyo", "respuesta": "-"})
	var delta := int(d[4]) if String(p.get("animo", "")) == "molesto" else int(d[3])
	if j != null:
		var _m0 := j.moral
		j.moral = clampi(j.moral + delta, 0, 100)
		j.anotar_moral(j.moral - _m0, "Redes sociales")
		if tono == "cortante" and m.prensa != null:
			noticia.emit("🧊 Mensaje en público", "Le contestaste a %s en redes delante de todos. El vestuario lo comenta." % j.nombre)
		return "%s %s (moral %+d)." % [String(d[0]), j.nombre, delta]
	return "Comentado."

# --- guardar ----------------------------------------------------------------------

func a_dic() -> Dictionary:
	return {"cuentas": cuentas.duplicate(true), "pubs": publicaciones.duplicate(true), "tend": tendencia,
		"sig": _siguiente_id, "ps": _propias_semana, "sp": _semana_propias,
		"acceso": acceso_club, "clave": clave_club, "sesion": sesion, "sem_club": _semanas_club}

func desde_dic(d: Dictionary) -> void:
	if d.is_empty():
		return
	cuentas = (d.get("cuentas", cuentas) as Dictionary).duplicate(true)
	publicaciones.clear()
	for p: Variant in d.get("pubs", []):
		publicaciones.append((p as Dictionary).duplicate(true))
	tendencia = String(d.get("tend", tendencia))
	_siguiente_id = int(d.get("sig", 1))
	_propias_semana = int(d.get("ps", 0))
	_semana_propias = int(d.get("sp", -1))
	acceso_club = bool(d.get("acceso", false))
	clave_club = String(d.get("clave", ""))
	sesion = String(d.get("sesion", "dt"))
	_semanas_club = int(d.get("sem_club", 0))
