class_name MotorReglas
## (16-11, informe AAA, capítulo 6) Piezas del REGLAMENTO del motor jugable sacadas a un módulo (las capas del motor
## están al tope de 450 líneas): líneas de gol y banda con la pelota entera (M6-19), el cambio que para el juego y
## no deja referencias al que sale (M6-13), la falta del usuario que solo es tiro si va a puerta (M6-15), la tanda
## con los mismos lanzadores por equipo y portero de urgencia (M6-17) y el doble toque del que saca (M6-20).
## `m` es el `MotorJugable` (sin tipo: lo llaman sus capas).

# ------------------------------------------------------------------ líneas (M6-19)

## Postes, larguero, gol y fuera. Los palos se juzgan al cruzar el plano de la línea; el GOL y el FUERA, cuando
## cruza la pelota ENTERA (el centro a un radio más allá de la línea: regla 9 y 10). Antes bastaba con el centro.
static func palos_y_lineas(m: MotorJugable, antes: Vector3) -> void:
	var p: Vector3 = m.balon.position
	var R: float = m.R
	var LARGO: float = m.LARGO
	for signo: float in [-1.0, 1.0]:
		var linea := LARGO * signo
		if (antes.z - linea) * (p.z - linea) <= 0.0 and absf(p.z) >= LARGO - 0.001 and signf(p.z) == signo:
			## Poste: el balón pega en el palo si pasa a un radio de él.
			if p.y < m.LARGUERO + R and absf(absf(p.x) - m.PALO) < 0.12 + R:
				m.vel_balon.z = -m.vel_balon.z * 0.6
				m.vel_balon.x += signf(p.x) * 1.5
				m.balon.position.z = linea - signo * 0.2
				m.aviso.emit("¡AL PALO!")
				m._cerrar_tiro("poste")
				return
			if absf(p.x) < m.PALO and absf(p.y - m.LARGUERO) < 0.12 + R:
				m.vel_balon.y = -absf(m.vel_balon.y) * 0.5
				m.vel_balon.z = -m.vel_balon.z * 0.5
				m.balon.position.z = linea - signo * 0.2
				m.aviso.emit("¡AL LARGUERO!")
				m._cerrar_tiro("poste")
				return
		var entera := (LARGO + R) * signo
		if (antes.z - entera) * (p.z - entera) <= 0.0 and absf(p.z) >= LARGO + R - 0.001 and signf(p.z) == signo:
			if absf(p.x) < m.PALO and p.y < m.LARGUERO:
				m._gol(signo > 0.0)
				return
			## Fuera por la línea de fondo: córner o saque de puerta.
			var desvio := MotorCorner.desvio(m); m._cerrar_tiro("fallo")   ## ciclo 26: remate desviado = córner
			var defiende_local := signo < 0.0   ## el local defiende -Z
			var ut: Dictionary = m.ultimo_toque
			var toco_defensor := desvio or (not ut.is_empty() and bool(ut["es_local"]) == defiende_local)
			if toco_defensor:
				m._empezar_saque("corner", not defiende_local, Vector3(signf(p.x) * (m.ANCHO - 0.3), R, linea - signo * 0.3))
			else:
				m._empezar_saque("puerta", defiende_local, Vector3(signf(p.x) * 5.0, R, linea - signo * 5.5))
			return
	if absf(p.x) > m.ANCHO + R:
		var ut2: Dictionary = m.ultimo_toque
		var local_saca := ut2.is_empty() or not bool(ut2["es_local"])
		m._empezar_saque("banda", local_saca, Vector3(signf(p.x) * (m.ANCHO - 0.2), R, clampf(p.z, -LARGO + 1.0, LARGO - 1.0)))

# ------------------------------------------------------------------ cambios (M6-13)

## El cambio que no encuentra balón parado: el árbitro PARA el juego (saque de banda para el que tenía el balón, en
## su lado) y el cambio se hace en ese saque (`_revisar_cambio` al empezar cada saque). Antes los jugadores se
## cambiaban con el balón en juego. Solo si el cambio va a hacerse (el DT aún no lo decidió o entras tú).
static func parar_para_cambio(m: MotorJugable) -> void:
	if m.entra_usuario_min < 0 and (m._cambio_decidido or m.usuario.is_empty()):
		return
	var dueno: Dictionary = m.poseedor if not (m.poseedor as Dictionary).is_empty() else m.ultimo_toque
	var local := bool(dueno.get("es_local", true))
	var b: Vector3 = m.balon.position
	m.aviso.emit("🔁 El árbitro para el juego para el cambio")
	m._empezar_saque("banda", local, Vector3((1.0 if b.x >= 0.0 else -1.0) * (m.ANCHO - 0.2), m.R, clampf(b.z, -m.LARGO + 1.0, m.LARGO - 1.0)))

## Lo que apuntaba al que sale pasa al que entra o se vacía (como `reemplazar`): nadie va a por un pase hacia un
## jugador oculto fuera del campo ni el control del equipo salta a él.
static func limpiar_sale(m: MotorJugable, sale: Dictionary, entra: Dictionary) -> void:
	for k: String in ["poseedor", "pase_a", "_receptor_marcado", "pase_dirigido", "_pase_usuario_de"]:
		if is_same(m.get(k), sale):
			m.set(k, {})
	for k: String in ["ultimo_toque", "penultimo_toque"]:
		if is_same(m.get(k), sale):
			m.set(k, entra)
	var sq: Dictionary = m.saque
	if is_same(sq.get("lanzador"), sale):
		sq["lanzador"] = entra

# ------------------------------------------------------------------ falta del usuario (M6-15)

## ¿La falta que lanzas desde `lugar` en la dirección `dir` (y `dist` m de largo) va entre los palos?
static func va_a_puerta(m: MotorJugable, p: Dictionary, lugar: Vector3, dir: Vector3, dist: float) -> bool:
	var arco: Vector3 = m._arco_rival(p)
	var dz := arco.z - lugar.z
	if dir.z * dz <= 0.0:
		return false
	var s := dz / dir.z   ## a cuánto del lugar cruza la línea de gol (en el plano)
	return absf(lugar.x + dir.x * s) < m.PALO + 0.5 and dist >= s * 0.8

# ------------------------------------------------------------------ tanda (M6-17)

## Los dos equipos tiran con el MISMO número de lanzadores (regla 10: el que tiene más se reduce) y nadie repite hasta
## que todos han tirado (el orden ya va de mejor a peor, el portero al final).
static func igualar_tanda(ordenes: Array) -> Array:
	var n := mini((ordenes[0] as Array).size(), (ordenes[1] as Array).size())
	return [(ordenes[0] as Array).slice(0, n), (ordenes[1] as Array).slice(0, n)] if n > 0 else ordenes

## Sin portero en el campo (expulsado sin suplente), ataja el último de la lista del que defiende (el que peor tira).
static func portero_de_urgencia(orden_defiende: Array) -> Dictionary:
	return orden_defiende.back() if not orden_defiende.is_empty() else {}

# ------------------------------------------------------------------ doble toque (M6-20)

## Al patear en un saque: queda anotado quién lo sacó.
static func marcar_ejecutor(m: MotorJugable, p: Dictionary) -> void:
	if m.estado == "saque":
		m.set_meta("_ejecutor_saque", String(p.get("id", "")))

## El que saca (penal, falta, córner, banda, puerta, centro) no puede volver a jugar el balón antes de que lo toque
## otro (regla 13-14: libre indirecto). Se llama al patear y al controlar; `true` = se pitó (no hay toque).
static func doble_toque(m: MotorJugable, p: Dictionary) -> bool:
	var id := String(p.get("id", ""))
	if m.estado != "juego" or not m.has_meta("_ejecutor_saque"):
		return false
	var ej := String(m.get_meta("_ejecutor_saque"))
	var ut := String((m.ultimo_toque as Dictionary).get("id", ""))
	m.remove_meta("_ejecutor_saque")
	if id != ej or ut != ej:
		return false   ## lo tocó otro antes: ya no hay doble toque posible
	var nombre := String((p.get("jugador", {}) as Dictionary).get("nombre", ""))
	m.aviso.emit("🚩 Doble toque de %s: libre indirecto" % nombre)
	var lugar := m.pos(p) as Vector3
	m._empezar_saque("falta", not bool(p["es_local"]), Vector3(clampf(lugar.x, -m.ANCHO + 1.0, m.ANCHO - 1.0), m.R,
		clampf(lugar.z, -m.LARGO + 1.0, m.LARGO - 1.0)))
	return true
