class_name CierreTorneos
extends RefCounted
## EL FINAL DE TEMPORADA COMPLETO (orden del dueño, 9-11; hecho el 10-11). Solo las ligas definen el fin de la temporada
## (`Mundo.temporada_en_curso`): con una liga corta, la COPA (una ronda cada 4 jornadas) o el CONTINENTAL (rondas en las semanas
## 3, 8, 13, 18, 23 y 28) podían quedar A MEDIAS y el cierre los borraba sin campeón (y sin trofeo para tu club). Aquí se juegan
## hasta el final ANTES de premiar y se devuelve lo que se cerró, para anunciarlo. También arma la FOTO de la temporada que se
## acaba (campeones, tu puesto, copa y continental) que pinta `ResumenTemporada`: tiene que tomarse ANTES de `nueva_temporada()`,
## que vuelve a sortear la copa y los continentales.

## Juega lo que quede de la copa y de los continentales. Devuelve [{torneo, campeon, mio}] de lo que se cerró ahora (vacío si
## nada estaba a medias). Es idempotente: llamarla dos veces no juega nada la segunda.
static func cerrar_pendientes(m: Mundo) -> Array:
	var cerrados: Array = []
	if m == null:
		return cerrados
	var mio := m.mi_club()
	if m.copa != null and m.copa.en_curso():
		var guard := 0
		while m.copa.en_curso() and guard < 20:
			m.copa.jugar_ronda()
			guard += 1
		if m.copa.campeon != null:
			cerrados.append({"torneo": m.copa.nombre, "campeon": m.copa.campeon, "mio": m.copa.campeon == mio})
	for t: Continental in m.continentales.values():
		if not t.en_curso():
			continue
		var guard2 := 0
		while t.en_curso() and guard2 < 20:
			t.jugar_ronda()
			guard2 += 1
		if t.campeon == null:
			continue
		var nom := Continental.nombre_conti(t.clave)
		cerrados.append({"torneo": nom, "campeon": t.campeon, "mio": t.campeon == mio})
		if t.campeon == mio and m.logros != null:
			m.logros.celebrar_titulo(nom)   ## el continental se celebra al coronarse (la copa la celebra el cierre de siempre)
	if m.prensa != null:
		for c: Dictionary in cerrados:
			m.prensa.noticia.emit("🏆 %s: %s" % [String(c["torneo"]), (c["campeon"] as Club).nombre],
				"Se juegan las rondas que faltaban antes del cierre de la temporada.")
	return cerrados

## ¿Queda copa o continental por jugar? (para avisar antes del cierre).
static func hay_pendientes(m: Mundo) -> bool:
	if m == null:
		return false
	if m.copa != null and m.copa.en_curso():
		return true
	for t: Continental in m.continentales.values():
		if t.en_curso():
			return true
	return false

## La foto de la temporada que se acaba, para la pantalla de resumen. Se toma con la liga ya terminada y la copa y el continental
## cerrados, ANTES de `nueva_temporada()`.
static func foto(m: Mundo) -> Dictionary:
	var f := {"anio": m.anio}
	var mio := m.mi_club()
	if mio == null:
		return f
	f["club"] = mio
	var liga := m.liga_de(mio)
	if liga != null:
		f["liga"] = liga.nombre
		var t: Array = liga.tabla()
		for i in t.size():
			if t[i]["club"] == mio:
				f["puesto"] = i + 1
				f["puntos"] = int(t[i].get("pts", 0))
				break
		f["equipos"] = t.size()
	if m.copa != null:
		f["copa"] = m.copa.nombre
		f["copa_campeon"] = m.copa.campeon
		f["copa_jugada"] = m.copa.participantes.has(mio)
		f["copa_viva"] = m.copa.vivos.has(mio)
	var conti := m.mi_continental()
	if conti == null:   ## si no juegas ninguno, el principal de tu confederación
		conti = m.continentales.get(Continental.confed_de(mio.pais))
	if conti != null:
		f["conti"] = Continental.nombre_conti(conti.clave)
		f["conti_campeon"] = conti.campeon
		f["conti_jugada"] = conti.participa(mio)
	return f
