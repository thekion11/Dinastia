class_name Federacion
extends "res://nucleo/federacion_p2.gd"
## [Capa 3/3 de `federacion.gd`] apelar, sancionar_dt, cumplir_sancion_dt, dt_sancionado, a_dic, desde_dic … (+4)

## Apela un expediente. Devuelve "" si se tramitó, o el motivo por el que no.
##
## `prestigio_dt` es la reputación del entrenador, de 0 a 99. Va como parámetro y
## no como campo porque el perfil de gestor todavía no está portado: con el 50
## por defecto la fórmula queda en su punto neutro, y el día que exista solo hay
## que pasárselo. El HTML sumaba además 0,22 si tenías consejero legal, que
## tampoco existe aún: cuando exista, entra por esta misma línea.
func apelar(caso_id: String, mi: Club, prestigio_dt: int = 50) -> String:
	if mi == null:
		return "no hay club"
	var caso: Dictionary = {}
	for c: Dictionary in casos:
		if String(c["id"]) == caso_id:
			caso = c
			break
	if caso.is_empty():
		return "ese expediente no existe"
	if bool(caso["apelado"]):
		return "ese expediente ya se apeló"
	var coste := Eco.escalar(COSTE_APELACION, float(mi.rep))
	if mi.saldo < coste:
		return "no hay caja: la apelación cuesta %d" % coste
	mi.mover_saldo(-coste)
	movimiento.emit("Honorarios legales: apelación de %s" % caso["nombre"], -coste)
	caso["apelado"] = true

	var p := 0.35 + float(prestigio_dt - 50) / 400.0 - float(enojo_arbitral) * 0.03
	if String(caso["tipo"]) == "roja":
		p -= 0.08
	if String(caso["tipo"]) == "agresion":
		p -= 0.2
	p = clampf(p, 0.05, 0.85)

	var j := _jugador_de(mi, String(caso["pid"]))
	if Azar.suerte(p):
		## O te la quitan entera o te quitan una sola fecha: el tribunal no hace
		## descuentos finos, y esa es justo la tensión de apelar.
		var quita: int = int(caso["fechas"]) if Azar.suerte(0.5) else 1
		quita = mini(int(caso["fechas"]), quita)
		caso["fechas"] = int(caso["fechas"]) - quita
		caso["estado"] = "rebajada"
		if j != null:
			j.suspension = maxi(0, j.suspension - quita)
		noticia.emit("Apelación ACOGIDA",
			"El tribunal rebaja la sanción de %s en %d fecha(s). Le quedan %d." % [
				caso["nombre"], quita, caso["fechas"]])
	else:
		caso["estado"] = "confirmada"
		enojo_arbitral += 1
		noticia.emit("Apelación RECHAZADA",
			"El tribunal confirma la sanción de %s y deja constancia de que el club recurre demasiado. Los árbitros toman nota." % caso["nombre"])
	caso_resuelto.emit(caso)
	return ""

## Te expulsan del área técnica: el tribunal te sanciona `fechas` partidos.
func sancionar_dt(fechas: int) -> void:
	dt_suspension = maxi(dt_suspension, fechas)
	dt_susp_nueva = true
	enojo_arbitral = mini(enojo_arbitral + 1, 5)
	noticia.emit("🟥 Sanción al entrenador",
		"El tribunal te sanciona con %d partido(s) por la expulsión. Los verás desde la grada, sin dar órdenes desde la banda." % fechas)

## Tras cada partido tuyo: la sanción corre (no la del partido en que te
## expulsaron, que empieza a contar en el siguiente).
func cumplir_sancion_dt() -> void:
	if dt_susp_nueva:
		dt_susp_nueva = false
		return
	if dt_suspension > 0:
		dt_suspension -= 1
		if dt_suspension == 0:
			noticia.emit("✅ Vuelves a la banda", "Cumpliste la sanción: el próximo partido lo diriges desde el banquillo.")

## ¿Ves este partido desde la grada?
func dt_sancionado() -> bool:
	return dt_suspension > 0 and not dt_susp_nueva

# ============================================================================
# GUARDADO
# ============================================================================

func a_dic() -> Dictionary:
	return {
		"reparto_tv": reparto_tv, "cupo_juvenil": cupo_juvenil,
		"tope_extranjeros": tope_extranjeros, "playoffs": playoffs, "infr_ley": infracciones_ley,
		"superliga": superliga, "var": var_activo,
		"fpf": fpf_activo, "fpf_avisos": fpf_avisos, "fpf_sancion": fpf_sancionado,
		"aliados": aliados, "votos": votos, "voto_pendiente": voto_pendiente,
		"licencia": licencia, "avisos": avisos, "auditoria": auditoria,
		"sin_cupo": sin_cupo_internacional,
		"casos": casos, "controles": controles,
		"semanas_en_rojo": semanas_en_rojo, "enojo_arbitral": enojo_arbitral,
		"dt_susp": dt_suspension, "dt_susp_n": dt_susp_nueva,
		"playoffs_ultimo": playoffs_ultimo, "sec": _sec,
		"presidente": presidente,
		"desempate": desempate_directo, "promocion": promocion, "arbitros": arbitros,
	}

func desde_dic(d: Dictionary) -> void:
	reparto_tv = float(d.get("reparto_tv", 1.0))
	cupo_juvenil = bool(d.get("cupo_juvenil", false))
	tope_extranjeros = int(d.get("tope_extranjeros", 0))
	infracciones_ley = d.get("infr_ley", {})
	dt_suspension = int(d.get("dt_susp", 0))
	dt_susp_nueva = bool(d.get("dt_susp_n", false))
	playoffs = bool(d.get("playoffs", false))
	superliga = bool(d.get("superliga", false))
	var_activo = bool(d.get("var", false))
	desempate_directo = bool(d.get("desempate", false))
	Liga.desempate_directo = desempate_directo
	promocion = bool(d.get("promocion", false))
	arbitros = (d.get("arbitros", {}) as Dictionary).duplicate(true)
	fpf_activo = bool(d.get("fpf", false))
	fpf_avisos = int(d.get("fpf_avisos", 0))
	fpf_sancionado = bool(d.get("fpf_sancion", false))
	aliados = int(d.get("aliados", 0))
	presidente = (d.get("presidente", {}) as Dictionary).duplicate()
	votos = (d.get("votos", []) as Array).duplicate()
	voto_pendiente = (d.get("voto_pendiente", {}) as Dictionary).duplicate()
	licencia = String(d.get("licencia", "vigente"))
	avisos = (d.get("avisos", []) as Array).duplicate()
	auditoria = (d.get("auditoria", {}) as Dictionary).duplicate()
	sin_cupo_internacional = bool(d.get("sin_cupo", false))
	casos = (d.get("casos", []) as Array).duplicate()
	controles = (d.get("controles", []) as Array).duplicate()
	semanas_en_rojo = int(d.get("semanas_en_rojo", 0))
	enojo_arbitral = int(d.get("enojo_arbitral", 0))
	playoffs_ultimo = (d.get("playoffs_ultimo", {}) as Dictionary).duplicate()
	_sec = int(d.get("sec", 0))
	## El campeón no se restaura: es una referencia viva a un Club de ESTA
	## partida cargada, y el que se guardó ya no existe. Quien lo necesite lo
	## busca por el id, que sí está en `playoffs_ultimo`.
	_campeon_ref = null

## Las seis mociones. Vienen de la tabla del juego, no reescritas aquí: si el
## HTML añade una séptima, se vuelve a exportar `tablas.json` y aparece sola.
## Anota el resultado de TU partido con su árbitro.
func anotar_arbitro(nombre: String, perfil: String, gf: int, gc: int) -> void:
	if nombre == "":
		return
	var h: Dictionary = arbitros.get(nombre, {"pj": 0, "g": 0, "e": 0, "p": 0, "perfil": perfil})
	h["pj"] = int(h["pj"]) + 1
	var k := "g" if gf > gc else ("e" if gf == gc else "p")
	h[k] = int(h[k]) + 1
	arbitros[nombre] = h

## "Con él: 5 PJ · 1G 2E 2P" o vacío si nunca te dirigió.
func texto_arbitro(nombre: String) -> String:
	if not arbitros.has(nombre):
		return ""
	var h: Dictionary = arbitros[nombre]
	return "Con él: %d PJ · %dG %dE %dP" % [int(h["pj"]), int(h["g"]), int(h["e"]), int(h["p"])]

## Revisa las cuentas del club al cerrar la temporada. `pct` es el porcentaje de
## masa salarial sobre ingresos, el mismo que enseña la proyección anual.
func revisar_fair_play(mi: Club, pct: int) -> String:
	if not fpf_activo or mi == null:
		fpf_sancionado = false
		return ""
	if pct <= FPF_UMBRAL:
		if fpf_avisos > 0:
			noticia.emit("Cuentas en regla",
				"La federación cierra el expediente: tu masa salarial vuelve a estar por debajo del %d%% de los ingresos." % FPF_UMBRAL)
		fpf_avisos = 0
		fpf_sancionado = false
		return ""
	fpf_avisos += 1
	if fpf_avisos < FPF_AVISOS:
		noticia.emit("Aviso de fair play financiero",
			"Tu masa salarial se lleva el %d%% de los ingresos, por encima del %d%% permitido. Un año más así y hay sanción." % [pct, FPF_UMBRAL])
		return "aviso"
	var multa := Eco.escalar(FPF_MULTA, float(mi.rep))
	mi.mover_saldo(-multa)
	movimiento.emit("Multa por fair play financiero", -multa)
	fpf_sancionado = true
	castigo_directiva.emit(-3, "el expediente de fair play financiero")
	noticia.emit("Sanción por fair play financiero",
		"Dos temporadas gastando por encima de lo que ingresas. La federación multa al club con %s y te cierra el mercado la próxima ventana: solo podrás fichar libres." % Cesiones.dinero(multa))
	return "sancion"

## Con el expediente abierto solo se puede fichar a coste cero. Lo consulta el
## mercado, igual que el cupo de extranjeros.
func puede_pagar_traspaso() -> bool:
	return not fpf_sancionado
