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
	return {"vistos": {}, "ultimatum": -999, "imp_ult": "", "sancion_ult": 0, "abiertos": {}}

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
	out.append_array(de_segunda_tanda(m, est))
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

## SEGUNDA TANDA (17-11): guerra de agentes, cantera, ojeadores, retos, cambio de DT en tu liga, llamada de selección y sanción al DT. Todos OBSERVAN.
static func de_segunda_tanda(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	out.append_array(de_guerra_agentes(m, est))
	out.append_array(de_cantera(m, est))
	out.append_array(de_ojeadores(m, est))
	out.append_array(de_retos(m, est))
	out.append_array(de_cambio_dt(m, est))
	out.append_array(de_seleccion(m, est))
	out.append_array(de_sancion_dt(m, est))
	out.append_array(de_tercera_tanda(m, est))
	return out

## (19-11) Un asunto ABIERTO (oferta, exigencia, decisión pendiente): true solo cuando se abre uno distinto del que ya se mostró; cuando se cierra
## (`actual` = "") se olvida, así que si el MISMO vuelve más tarde (otra oferta de la misma selección) se avisa de nuevo. Antes se marcaba para siempre.
static func _abierto(est: Dictionary, clave: String, actual: String) -> bool:
	var abiertos: Dictionary = est.get("abiertos", {})
	est["abiertos"] = abiertos
	if actual == "":
		abiertos.erase(clave)
		return false
	if String(abiertos.get(clave, "")) == actual:
		return false
	abiertos[clave] = actual
	return true

## Un hecho que sale una sola vez: devuelve true la primera vez que se pide `id`.
static func _nuevo(est: Dictionary, id: String) -> bool:
	if (est["vistos"] as Dictionary).has(id):
		return false
	est["vistos"][id] = true
	return true

## La guerra de agentes abierta (`Cantera.exigencia`): el representante exige algo; el texto lo trae el propio sistema.
static func de_guerra_agentes(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	if m.cantera == null or not _abierto(est, "agentes", "" if m.cantera.exigencia.is_empty() else "%s:%s" % [String(m.cantera.exigencia.get("agente", "")), String(m.cantera.exigencia.get("tipo", ""))]):
		return out
	var e: Dictionary = m.cantera.exigencia
	var id := "agentes:%s:%s:%d" % [String(e.get("agente", "")), String(e.get("tipo", "")), _abs(m)]
	var ev := _ev(id, "guerra_agentes", EventosDia.PANTALLA, "", "guerra_agentes", {"tipo": String(e.get("tipo", "")), "perfil": String(e.get("perfil", "")), "agente": String(e.get("agente", ""))})
	ev["texto"] = Idiomas.t(String(e.get("txt", "")))
	out.append(ev)
	return out

## El asunto abierto de la cantera (`EventosCantera.pendiente`): torneo, abandono o padres. Es una DECISIÓN con opciones (`DecisionesDia`): pantalla completa.
static func de_cantera(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	if m.eventos_cantera == null or not _abierto(est, "cantera", "" if m.eventos_cantera.pendiente.is_empty() else "%s:%s" % [String(m.eventos_cantera.pendiente.get("tipo", "")), String(m.eventos_cantera.pendiente.get("id", ""))]):
		return out
	var p: Dictionary = m.eventos_cantera.pendiente
	var id := "cantera:%s:%s:%d" % [String(p.get("tipo", "")), String(p.get("id", "")), _abs(m)]
	var ev := _ev(id, "evento_cantera", EventosDia.PANTALLA, "", "evento_cantera", {"tipo": String(p.get("tipo", "")), "chico": String(p.get("id", ""))})
	ev["texto"] = Idiomas.t(String(p.get("tema", "")))
	out.append(ev)
	return out

## Un hallazgo nuevo de los ojeadores (`Ojeadores.hallazgos`): aviso en «mercado» con el jugador.
static func de_ojeadores(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	if m.ojeadores == null:
		return out
	for h: Dictionary in m.ojeadores.hallazgos:
		var id := "hallazgo:%s:%d:%d" % [String(h.get("pid", "")), int(h.get("anio", 0)), int(h.get("semana", 0))]
		if not _nuevo(est, id):
			continue
		var ev := _ev(id, "hallazgo", EventosDia.AVISO, "mercado", "hallazgo", {"jugador": String(h.get("pid", ""))})
		ev["jugador_id"] = String(h.get("pid", ""))
		ev["nombre"] = Nombres.visible(String(h.get("nombre", "")))
		out.append(ev)
	return out

## Los retos de la semana (`RetosSemana.activos`): se anuncian al estrenarse (una vez por semana), aviso en «vestuario».
static func de_retos(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	var r: RetosSemana = m.retos_semana
	if r == null or r.activos.is_empty():
		return out
	var id := "retos:%d" % _abs(m)
	if not _nuevo(est, id):
		return out
	var ev := _ev(id, "retos_semana", EventosDia.AVISO, "vestuario", "retos_semana", {"n": r.activos.size()})
	ev["retos"] = r.activos.duplicate(true)
	out.append(ev)
	return out

## Un cambio de entrenador en TU liga esta semana (`MercadoDT.historial`): aviso de prensa. El tuyo lo cuenta la directiva.
static func de_cambio_dt(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	var liga := m.liga_de(m.mi_club())
	if liga == null:
		return out
	var nombres: Array[String] = []
	for c: Club in liga.clubes:
		nombres.append(c.nombre)
	for h: Dictionary in MercadoDT.de(m).historial:
		if int(h.get("anio", -1)) != m.anio or int(h.get("semana", -1)) != m.semana or not nombres.has(String(h.get("club", ""))):
			continue
		var id := "cambio_dt:%s:%d:%d" % [String(h["club"]), m.anio, m.semana]
		if not _nuevo(est, id):
			continue
		var ev := _ev(id, "cambio_dt", EventosDia.AVISO, "prensa", "cambio_dt", {"club": String(h["club"]), "sale": String(h.get("sale", "")), "entra": String(h.get("entra", ""))})
		out.append(ev)
	return out

## Una selección te llama (`CargoSeleccion.oferta`): PANTALLA, es una decisión de carrera.
static func de_seleccion(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	if m.selecciones == null or not _abierto(est, "seleccion", String(m.selecciones.cargo.oferta.get("nombre", ""))):
		return out
	var o: Dictionary = m.selecciones.cargo.oferta
	var id := "seleccion:%s:%d" % [String(o.get("nombre", "")), _abs(m)]
	out.append(_ev(id, "oferta_seleccion", EventosDia.PANTALLA, "", "oferta_seleccion", {"seleccion": String(o.get("nombre", "")), "fuerza": int(o.get("fuerza", 0)), "sueldo": int(o.get("sueldo", 0))}))
	return out

## El tribunal sanciona al DT (`Federacion.dt_suspension`): aviso en «prensa» con las fechas.
static func de_sancion_dt(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	if m.federacion == null:
		return out
	## (19-11) Solo cuando las fechas SUBEN (sanción nueva o ampliada): al cumplirse partido a partido (3 → 2 → 1) no se repite el aviso.
	var quedan := m.federacion.dt_suspension
	var antes := int(est.get("sancion_ult", 0))
	est["sancion_ult"] = quedan
	if quedan <= 0 or quedan <= antes:
		return out
	var id := "sancion:%d" % _abs(m)
	out.append(_ev(id, "sancion_dt", EventosDia.AVISO, "prensa", "sancion_dt", {"fechas": m.federacion.dt_suspension}))
	return out

## TERCERA TANDA (17-11): contratos por vencer, precontratos firmados, jugadores sancionados y caja en negativo. También solo OBSERVAN. (Las cesiones y las charlas no
## dejan estado que observar sin relanzar su sistema: `Cesiones.presion_de_fondo` SORTEA y `Charlas.semana` solo emite noticias.)
static func de_tercera_tanda(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	out.append_array(de_contratos(m, est))
	out.append_array(de_precontratos(m, est))
	out.append_array(de_sancionados(m, est))
	out.append_array(de_caja_negativa(m, est))
	return out

const SEMANA_CONTRATOS := 20   ## desde esta semana, en la segunda mitad de la temporada, se avisa de los contratos que terminan

## Los jugadores tuyos con el contrato en su último año: un aviso por temporada (zona «equipo»).
static func de_contratos(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	if m.semana < SEMANA_CONTRATOS or not _nuevo(est, "contratos:%d" % m.anio):
		return out
	var n := 0
	for j: Jugador in m.mi_club().plantilla:
		if j.anios_contrato <= 1:
			n += 1
	if n > 0:
		out.append(_ev("contratos:%d" % m.anio, "contratos_vencen", EventosDia.AVISO, "equipo", "contratos_vencen", {"n": n}))
	return out

## Cada precontrato firmado con un jugador de otro club (`Mercado.precontratos`): aviso en «mercado» con el jugador.
static func de_precontratos(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	if m.mercado == null:
		return out
	for e: Dictionary in m.mercado.precontratos:
		var id := "precontrato:%s:%d" % [String(e.get("id", "")), m.anio]
		if not _nuevo(est, id):
			continue
		var j := m.jugador_por_id(String(e.get("id", "")))
		var ev := _ev(id, "precontrato", EventosDia.AVISO, "mercado", "precontrato", {"jugador": String(e.get("id", "")), "anios": int(e.get("anios", 0))})
		ev["nombre"] = Nombres.visible(j.nombre) if j != null else ""
		out.append(ev)
	return out

## Un jugador tuyo que acaba de quedar sancionado (`Jugador.suspension`): aviso en «vestuario» una vez por sanción.
static func de_sancionados(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	for j: Jugador in m.mi_club().plantilla:
		if j.suspension <= 0:
			continue
		var id := "sancionado:%s:%d" % [j.id, j.susp_semana]   ## `Disciplina.sanciona` anota la semana: una sanción nueva = un hecho nuevo
		if not _nuevo(est, id):
			continue
		var ev := _ev(id, "jugador_sancionado", EventosDia.AVISO, "vestuario", "jugador_sancionado", {"jugador": j.id, "fechas": j.suspension})
		ev["nombre"] = Nombres.visible(j.nombre)
		out.append(ev)
	return out

## La caja del club en negativo: un aviso cada 8 semanas mientras siga así (zona «finanzas»).
static func de_caja_negativa(m: Mundo, est: Dictionary) -> Array:
	var out: Array = []
	var c := m.mi_club()
	if c.saldo >= 0:
		return out
	var id := "caja_negativa:%d" % int(_abs(m) / 8)
	if _nuevo(est, id):
		out.append(_ev(id, "caja_negativa", EventosDia.AVISO, "finanzas", "caja_negativa", {"saldo": c.saldo}))
	return out
