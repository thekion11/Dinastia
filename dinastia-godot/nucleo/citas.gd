class_name Citas
extends "res://nucleo/citas_p1.gd"
## [Capa 2/2 de `citas.gd`] resolver, sus ramas y la asamblea (20-11, orden 63: partido en funciones).

## `extra` = [grupo, staff] de las preguntas 2 y 3 de la entrevista (vacío = solo el tono, como antes).
func resolver(m: Mundo, id: String, opcion: int, extra: Array = []) -> Dictionary:
	var ct := por_id(id)
	if ct.is_empty() or String(ct["estado"]) != "pendiente":
		return {}
	ct["estado"] = "hecha"
	if objetivo == id:
		objetivo = ""
	var c := m.mi_club()
	match String(ct["tipo"]):
		"junta":
			return _resolver_junta(m, c, ct, opcion)
		"patrocinio":
			return _resolver_patrocinio(m, ct, opcion)
		"agente":
			return _resolver_representante(m, ct, opcion)
		"entrevista":
			return _resolver_entrevista(m, c, ct, opcion, extra)
		"rama":
			return _resolver_rama(m, c, ct, opcion)
		"celebracion":
			return _resolver_celebracion(m, c, ct, opcion)
		"asamblea":
			return _asamblea(m, c, opcion)
	return _resolver_politica(m, c, ct, opcion)

## Rama «junta» de `resolver`, sacada tal cual (orden 63).
func _resolver_junta(m: Mundo, c: Club, ct: Dictionary, opcion: int) -> Dictionary:
	if m.junta == null or m.junta.pendiente.is_empty():
		return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Ya lo hablamos por escrito. Gracias por venir igual.»")}
	var r := m.junta.resolver("a" if opcion == 0 else "b", c, m.directiva, m.prensa)
	if m.directiva != null:
		m.directiva.confianza = clampi(m.directiva.confianza + BONO_JUNTA, 0, 100)
	return {"titulo": String(r.get("titulo", ct["quien"])), "texto": "%s %s" % [String(r.get("cuerpo", "")), Idiomas.t("(Dar la cara en el despacho: +1 de confianza.)")]}

## Rama «patrocinio» de `resolver`, sacada tal cual (orden 63).
func _resolver_patrocinio(m: Mundo, ct: Dictionary, opcion: int) -> Dictionary:
	var partes := String(ct["clave"]).split("|")
	if opcion != 0 or partes.size() < 2 or m.comercial == null:
		return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Piénsalo; la oferta sigue en pie unos días.»")}
	var error := m.comercial.firmar_zona(partes[0], int(partes[1]))
	if error != "":
		return {"titulo": String(ct["quien"]), "texto": Idiomas.t("No se pudo firmar: %s.") % Idiomas.t(error)}
	var z: Dictionary = m.comercial.zonas_firmadas[partes[0]]
	z["monto"] = int(round(float(z["monto"]) * (1.0 + BONO_PATROCINIO) / 10000.0)) * 10000
	return {"titulo": Idiomas.t("Firmado en persona"), "texto": Idiomas.t("%s cierra %s por %s al año (+5 %% por cerrarlo en persona).") % [
		String(z["marca"]), Comercial._nombre_zona(partes[0]), Eco.dinero(int(z["monto"]))]}

## Rama «agente» de `resolver`, sacada tal cual (orden 63).
func _resolver_representante(m: Mundo, ct: Dictionary, opcion: int) -> Dictionary:
	if opcion != 0:
		return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Como quieras. Ya sabes dónde encontrarme.»")}
	favor_agente = m.anio * 60 + m.semana
	return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Represento a %d de los tuyos. Tratemos bien a mi gente y la próxima mesa será más barata.» (−5 %% en su próxima negociación.)") % m.mercado_av.clientes.size()}

## Rama «entrevista» de `resolver`, sacada tal cual (orden 63).
func _resolver_entrevista(m: Mundo, c: Club, ct: Dictionary, opcion: int, extra: Array) -> Dictionary:
	var j: Jugador = null
	for x: Jugador in c.plantilla:
		if x.id == String(ct["clave"]):
			j = x
	if j == null:
		return {"titulo": String(ct["quien"]), "texto": Idiomas.t("Ya no está en el club.")}
	var d: int = MORAL_ENTREVISTA[clampi(opcion, 0, 2)] + _entrevista_extra(m, j, extra)
	j.cambiar_moral(d, "Entrevista con el DT")
	return {"titulo": Idiomas.t("Primera charla con %s") % j.nombre, "texto": Idiomas.t("Sale de tu oficina %s (moral %+d).") % [
		[Idiomas.t("con ganas de demostrar"), Idiomas.t("sin saber qué esperar"), Idiomas.t("sintiéndose uno más")][clampi(opcion, 0, 2)], d]}

## Rama «rama» de `resolver`, sacada tal cual (orden 63).
func _resolver_rama(m: Mundo, c: Club, ct: Dictionary, opcion: int) -> Dictionary:
	if opcion == 2:
		return CitasRamas.visibilidad(m, c, ct)
	if opcion != 0 or m.hinchada == null:
		return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Lo entiendo. Seguiremos con lo que hay.»")}
	var coste := 0
	for f: Array in Hinchada.RAMAS:
		if String(f[0]) == String(ct["clave"]):
			coste = int(float(f[3]) * RAMA_EXTRA)
	if c.saldo < coste:
		return {"titulo": String(ct["quien"]), "texto": Idiomas.t("No hay caja para el extra (%s).") % Eco.dinero(coste)}
	c.mover_saldo(-coste)
	m.hinchada.bono_rama[String(ct["clave"])] = m.anio
	return {"titulo": Idiomas.t("Presupuesto aprobado"), "texto": Idiomas.t("%s para la rama esta temporada: jugará más fuerte.") % Eco.dinero(coste)}

## Rama «celebracion» de `resolver`, sacada tal cual (orden 63).
func _resolver_celebracion(m: Mundo, c: Club, ct: Dictionary, opcion: int) -> Dictionary:
	if String(ct["clave"]).begins_with("rama|"):
		return CitasRamas.celebrar(m, c, ct, opcion)
	if m.prensa != null:
		m.prensa.animo = clampi(m.prensa.animo + 3, 0, 100)
	if opcion == 0 and m.redes != null:
		m.redes.publicar(m, "victoria", [Redes.hashtag_club(c), "#Campeones"])
		return {"titulo": Idiomas.t("¡Campeones!"), "texto": Idiomas.t("La copa ya está en la vitrina y la foto en Tribuna. La grada está en una nube (+3 de ánimo).")}
	return {"titulo": Idiomas.t("¡Campeones!"), "texto": Idiomas.t("La copa ya está en la vitrina. La grada está en una nube (+3 de ánimo).")}

## Política: lo que pasa si ninguna rama de arriba coincidió con el tipo de la cita (el apoyo al gobierno).
func _resolver_politica(m: Mundo, c: Club, ct: Dictionary, opcion: int) -> Dictionary:
	## política
	if opcion != 0 or m.politica == null:
		return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Lo entiendo. El fútbol es de todos.»")}
	var gob := m.politica.gobierno(c.pais, m.anio)
	gob["apoyo_club"] = m.anio
	if m.prensa != null:
		for f: Array in Prensa.PERIODISTAS:
			if String(f[3]) == "crítico":
				m.prensa._mover_relacion(String(f[0]), -2)
		m.prensa.noticia.emit("🏛️ El club, con el gobierno", "El club apoya públicamente al gobierno antes de la votación. Si repite, será un aliado (sus ayudas, +25 %); si pierde, el nuevo gobierno lo recordará.")
	return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«El alcalde lo recordará.» El club apoya al gobierno en la próxima rueda; la prensa crítica toma nota (−2 de relación).")}

## La votación de la asamblea (determinista: ánimo de la grada, confianza y tu discurso).
## Perder no te echa: cambia el presidente de la `Junta` y la confianza vuelve a 50.
func _asamblea(m: Mundo, c: Club, opcion: int) -> Dictionary:
	asamblea_anio = m.anio
	var animo := m.prensa.animo if m.prensa != null else 50
	var conf := m.directiva.confianza if m.directiva != null else 50
	var votos := 40.0 + (animo - 50) * 0.5 + (conf - 50) * 0.3
	match clampi(opcion, 0, 2):
		0: votos += 6.0 if animo >= 50 else -4.0
		1: votos -= 2.0
		2: votos += 4.0 if animo < 50 else 1.0
	var pct := clampi(int(round(votos)), 5, 95)
	if pct >= 50:
		if m.directiva != null:
			m.directiva.confianza = clampi(m.directiva.confianza + 2, 0, 100)
		return {"titulo": Idiomas.t("La asamblea respalda al presidente"), "texto": Idiomas.t("%d %% de los votos. El proyecto sigue; la directiva te lo agradece (+2 de confianza).") % pct}
	if m.junta != null:
		var h := absi(("pres|%d|%s" % [m.anio, c.id]).hash())
		var estilos: Array = Junta.ESTILOS.keys()
		var anterior := String(m.junta.presidente.get("estilo", ""))
		var estilo := String(estilos[h % estilos.size()])
		if estilo == anterior:
			estilo = String(estilos[(h + 1) % estilos.size()])
		m.junta.presidente = {"nombre": m.junta._nombre(h), "estilo": estilo}
	if m.directiva != null:
		m.directiva.confianza = 50
	if m.prensa != null and m.prensa.titular_pendiente.is_empty():
		m.prensa.titular_pendiente = {"t": Idiomas.t("Cambio en la presidencia tras la asamblea"), "c": Idiomas.t("Los socios votaron el cambio; el entrenador sigue."), "tipo": "neutro", "medio": "La Tribuna"}
	return {"titulo": Idiomas.t("Nuevo presidente"), "texto": Idiomas.t("%d %% de los votos: los socios eligen otra presidencia. Tú sigues; %s empieza de cero contigo (confianza 50).") % [
		pct, String(m.junta.presidente.get("nombre", "")) if m.junta != null else ""]}

## Convocar una rueda de prensa desde el móvil (§2.2d bloque 6): una extra por semana, con
## el guion neutro de siempre; se responde en el PC como cualquier rueda. "" = convocada.
func convocar_rueda(m: Mundo) -> String:
	if m == null or m.prensa == null:
		return "No hay prensa en esta partida."
	if m.prensa.hay_rueda():
		return "Ya hay una rueda abierta: respóndela en el PC."
	if rueda_semana == m.anio * 60 + m.semana:
		return "Ya convocaste una rueda esta semana."
	rueda_semana = m.anio * 60 + m.semana
	m.prensa.abrir_rueda(false, true)
	return ""

# ======================================================================== GUARDADO

func a_dic() -> Dictionary:
	return {"lista": lista.duplicate(true), "objetivo": objetivo, "favor_agente": favor_agente, "rueda": rueda_semana, "asamblea": asamblea_anio, "trofeos": _trofeos_vistos, "ramas": _ramas_vistas, "n": _n}

func desde_dic(d: Dictionary) -> void:
	lista.clear()
	for ct: Variant in d.get("lista", []):
		if ct is Dictionary:
			lista.append((ct as Dictionary).duplicate(true))   ## copia (A4-GES-001): `semana()` las caduca en el sitio y estropeaba los datos guardados
	objetivo = String(d.get("objetivo", ""))
	favor_agente = int(d.get("favor_agente", -1))
	rueda_semana = int(d.get("rueda", -1))
	asamblea_anio = int(d.get("asamblea", -1))
	_trofeos_vistos = int(d.get("trofeos", -1))
	_ramas_vistas = int(d.get("ramas", -1))
	_n = int(d.get("n", 0))

## Las preguntas 2 y 3 de la entrevista: entra en el grupo elegido (hasta que el vestuario se
## redibuje) y trabaja con el staff. Devuelve la moral extra (grupo de buen humor +1, enfadado −1).
func _entrevista_extra(m: Mundo, j: Jugador, extra: Array) -> int:
	var d := 0
	if extra.size() >= 1:
		var grupos := grupos_entrevista(m)
		var gi := int(extra[0])
		if gi >= 0 and gi < grupos.size():
			var cl: Dictionary = grupos[gi]
			if not (cl["miembros"] as Array).has(j.id):
				(cl["miembros"] as Array).append(j.id)
			m.vestuario._clan_de[j.id] = cl["id"]
			d += 1 if int(cl.get("humor", 0)) >= 0 else -1
	if extra.size() >= 2:
		var st: Array = STAFF_ENTREVISTA[clampi(int(extra[1]), 0, 2)]
		j.forma = clampi(j.forma + int(st[0]), 0, 100)
		j.adapt = mini(100, j.adapt + int(st[1]))
		d += int(st[2])
	return d
