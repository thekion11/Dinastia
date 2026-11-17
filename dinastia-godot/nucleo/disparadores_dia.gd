class_name DisparadoresDia
extends RefCounted
## EL AVANCE POR DÍAS, PASO 2: LOS DISPARADORES (17-11-2026). Los eventos NACEN DE UNA CAUSA (estado del club o azar), no de un día fijo (decisión del dueño).
## Aquí vive el registro de los que YA existen en el juego: la directiva (confianza, ultimátum, despido), la crisis de caja, los imprevistos y el jugador del mes.
##
## REGLA DE ORO: este registro SOLO OBSERVA. La simulación semanal (`Mundo.avanzar_semana`, `mundo_p5.gd`) ya ejecuta esos sistemas y los anuncia; aquí no se
## relanza ninguno (no se gasta `Azar` ni se mueve el estado de la partida). `consultar` lee lo que dejó cada sistema y lo convierte en eventos del avance
## (clase PANTALLA o AVISO, zona de la campana y CAUSA). Cada observador es idempotente: el mismo hecho solo sale UNA vez (`est["vistos"]`).
## `est` es el estado de ejecución del avance (NO se guarda con la partida): `nuevo_estado()`.
##
## Los textos nuevos de interfaz no se escriben aquí: el evento trae `causa` = {id, datos} y la pantalla la redacta (con `Idiomas.t`). Donde el sistema ya tiene texto
## propio y traducido (`CrisisCaja.texto_aviso`, el catálogo de `Imprevistos`) se usa ese, sin tocarlo.
## Regla de la extensión: esta lógica pasará a C++ con esta versión como gemela exacta.

const ULTIMATUM_HASTA := 24          ## «Tu puesto está en el aire» (`Directiva.humor`): de aquí hacia abajo hay ultimátum
const ENFRIAMIENTO_ULTIMATUM := 8    ## semanas mínimas entre dos ultimátums

static func nuevo_estado() -> Dictionary:
	return {"vistos": {}, "ultimatum": -999, "imp_ult": ""}

static func _abs(m: Mundo) -> int:
	return m.anio * 60 + m.semana

static func _ev(id: String, tipo: String, clase: String, zona: String, causa_id: String, datos: Dictionary) -> Dictionary:
	return {"id": id, "tipo": tipo, "clase": clase, "zona": zona, "origen": EventosDia.ORIGEN_DISPARADOR, "causa": {"id": causa_id, "datos": datos}}

## Todo lo que hay que mostrar ahora mismo (y que aún no se mostró), en este orden: directiva, caja, imprevistos, jugador del mes.
static func consultar(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	if m == null or m.mi_club() == null:
		return out
	out.append_array(de_directiva(m, est))
	out.append_array(de_crisis_caja(m, est))
	out.append_array(de_imprevistos(m, est))
	out.append_array(de_premio_mensual(m, est))
	return out

## ULTIMÁTUM cuando la confianza baja de `ULTIMATUM_HASTA` (sin llegar al despido) y DESPIDO cuando la directiva te echa (`despedido_ya`).
static func de_directiva(m: Mundo, est: Dictionary) -> Array:
	var d := m.directiva
	var out: Array = []
	if d == null:
		return out
	if d.despedido_ya:
		if not (est["vistos"] as Dictionary).has("despido"):
			est["vistos"]["despido"] = true
			out.append(_ev("despido", "despido", EventosDia.PANTALLA, "", "despido", {"confianza": d.confianza, "umbral": Directiva.UMBRAL_DESPIDO}))
		return out
	if d.confianza <= ULTIMATUM_HASTA and d.confianza > Directiva.UMBRAL_DESPIDO and _abs(m) - int(est["ultimatum"]) >= ENFRIAMIENTO_ULTIMATUM:
		est["ultimatum"] = _abs(m)
		out.append(_ev("ultimatum:%d" % _abs(m), "ultimatum", EventosDia.PANTALLA, "", "ultimatum", {"confianza": d.confianza, "humor": d.humor()}))
	return out

## Los golpes de caja YA AVISADOS y aún sin cobrar (`Roles.crisis_pendiente`): el aviso sale una vez, con el texto de `CrisisCaja`.
static func de_crisis_caja(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	if m.roles == null:
		return out
	for e: Dictionary in m.roles.crisis_pendiente:
		var id := "caja:%s:%d" % [String(e["tipo"]), int(e["vence"])]
		if (est["vistos"] as Dictionary).has(id):
			continue
		est["vistos"][id] = true
		var t: Array = CrisisCaja.texto_aviso(String(e["tipo"]), int(e["importe"]), m.mi_club().nombre)
		var ev := _ev(id, "golpe_caja", EventosDia.AVISO, "finanzas", "golpe_caja", {"tipo": String(e["tipo"]), "importe": int(e["importe"]), "semanas": maxi(0, int(e["vence"]) - _abs(m))})
		ev["titulo"] = String(t[0])
		ev["texto"] = String(t[1])
		out.append(ev)
	return out

## El último imprevisto que dejó `Imprevistos` (no se repiten seguidos, así que un id nuevo = un imprevisto nuevo).
static func de_imprevistos(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	var rec: Array = m.imprevistos.recientes
	if rec.is_empty():
		return out
	var ultimo := String(rec[rec.size() - 1])
	if ultimo == String(est["imp_ult"]):
		return out
	est["imp_ult"] = ultimo
	var fila := {}
	for f: Dictionary in Imprevistos.CATALOGO:
		if String(f["id"]) == ultimo:
			fila = f
			break
	if fila.is_empty():
		return out
	var c := m.mi_club()
	var quien := c.nombre
	for a: Dictionary in m.imprevistos.activos:
		if String(a.get("id", "")) == ultimo and String(a.get("jid", "")) != "":
			for j: Jugador in c.plantilla:
				if j.id == String(a["jid"]):
					quien = Nombres.visible(j.nombre)
	var txt := Idiomas.t(String(fila["txt"]))
	if txt.contains("%s"):
		txt = txt % quien
	var ev := _ev("imprevisto:%s:%d" % [ultimo, _abs(m)], "imprevisto", EventosDia.AVISO, "equipo", "imprevisto", {"fila": ultimo})
	ev["titulo"] = Idiomas.t(String(Imprevistos.TITULOS.get(String(fila["t"]), Imprevistos.TITULOS["club"])))
	ev["texto"] = txt
	out.append(ev)
	return out

## El jugador del mes de ESTA semana (`PremioMensual.revisar` deja `semana` en su premio): PANTALLA si es de tu club, AVISO de prensa si es de otro.
static func de_premio_mensual(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	if m.semana <= 0 or m.semana % PremioMensual.CADA != 0:
		return out
	var id := "premio:%d:%d" % [m.anio, m.semana]
	if (est["vistos"] as Dictionary).has(id):
		return out
	var mio := m.mi_club()
	var liga := m.liga_de(mio)
	if liga == null:
		return out
	for c: Club in liga.clubes:
		for j: Jugador in c.plantilla:
			if j.premios.is_empty():
				continue
			var p: Dictionary = j.premios[j.premios.size() - 1]
			if String(p.get("premio", "")) == "Jugador del mes" and int(p.get("anio", -1)) == m.anio and int(p.get("semana", -1)) == m.semana:
				est["vistos"][id] = true
				var es_mio := c.id == mio.id
				var ev := _ev(id, "jugador_del_mes", EventosDia.PANTALLA if es_mio else EventosDia.AVISO, "" if es_mio else "prensa", "jugador_del_mes", {"semana": m.semana})
				ev["jugador_id"] = j.id
				ev["nombre"] = Nombres.visible(j.nombre)
				ev["club"] = c.nombre
				ev["es_mio"] = es_mio
				out.append(ev)
				return out
	return out
