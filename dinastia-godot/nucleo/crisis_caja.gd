class_name CrisisCaja
extends RefCounted
## CRISIS DE CAJA (27-10-2026, M-208): medido con `eq_diez_temporadas`, el club grande sin gestionar se hacía rico en línea recta (6,6 → 65-95 M en diez
## años) porque nada le salía mal. Ahora, de vez en cuando, a TU club le espera un golpe: la federación le multa, su patrocinador principal recorta o una
## obra del estadio se encarece. NO es un castigo ciego (revisión del líder, 27-10):
##   · AVISO: el golpe se anuncia `AVISO_SEMANAS` semanas antes de cobrarse (noticia con el importe previsto y quién podría evitarlo);
##   · SE ESQUIVA: un consejero lo rebaja si ya está en el directorio al cobrarse (legal −70 % la multa, de marketing −60 % el recorte, financiero −50 % la
##     obra); el aviso da tiempo a contratarlo (`Directiva.alternar_consejero`);
##   · PROPORCIONAL: crece con la caja (un club rico llama la atención de la federación, del patrocinador y de los constructores) y llega más a menudo
##     cuanto más sana está; el club chico apenas lo nota, y un club sin caja no sufre ninguno.
## Sin `Azar`: sale de un hash de (semilla, año, semana), como los incidentes de la ciudad, para no mover ninguna otra tirada de la partida.
const POR_SEMANA := 0.055          ## probabilidad base cada semana (con la caja en tres referencias, ≈ 1,9 golpes por temporada de 34 semanas)
const AVISO_SEMANAS := 3
const ENFRIAMIENTO := 4            ## semanas mínimas entre un golpe cobrado y el aviso del siguiente
const TIPOS := ["multa", "patrocinio", "obra"]
## tipo → [consejero que lo rebaja, fracción que se ahorra]
const REBAJA := {"multa": ["leg", 0.7], "patrocinio": ["mkt", 0.6], "obra": ["fin", 0.5]}

## Qué se avecina esta semana, si algo: {tipo, importe}. `saldo` y `ref` son los de tu club (`Eco.ref_caja(rep)`).
static func tirada(semilla: int, anio: int, semana: int, saldo: int, ref: float) -> Dictionary:
	if float(saldo) < ref * 0.3:
		return {}   ## un club sin caja no se multa más: bastante tiene
	var h := absi(hash(Vector3i(semilla, anio, semana)))
	var rica := clampf(float(saldo) / maxf(1.0, ref * 3.0), 0.0, 2.5)   ## 1 = tres referencias de caja
	var p := POR_SEMANA * clampf(0.4 + rica, 0.4, 2.0)
	if float(h % 10000) / 10000.0 >= p:
		return {}
	var tipo: String = TIPOS[(h / 10000) % TIPOS.size()]
	var u := float((h / 30000) % 1000) / 1000.0
	var peso := clampf(float(saldo) / maxf(1.0, ref * 2.0), 0.6, 3.0)   ## el golpe crece con la caja
	var grave := 2.0 if (h / 30000000) % 100 < 12 else 1.0   ## uno de cada ocho es de los gordos (la cola larga que hace bajar la caja de verdad)
	return {"tipo": tipo, "importe": int(round(ref * (0.2 + 0.5 * u) * peso * grave / 1000.0)) * 1000}

static func concepto(tipo: String) -> String:
	match tipo:
		"multa":
			return "Multa de la federación"
		"patrocinio":
			return "Recorte del patrocinador"
		_:
			return "Sobrecoste de obra"

static func _abs(m: Mundo) -> int:
	return m.anio * 60 + m.semana

## ¿Se cobró un golpe en las últimas `ENFRIAMIENTO` semanas?
static func reciente(m: Mundo) -> bool:
	var nombres := TIPOS.map(func(t: String) -> String: return concepto(t))
	for k in range(m.libro_financiero.size() - 1, maxi(-1, m.libro_financiero.size() - 25), -1):
		var e: Dictionary = m.libro_financiero[k]
		if int(e["anio"]) == m.anio and nombres.has(String(e["concepto"])) and m.semana - int(e["semana"]) < ENFRIAMIENTO:
			return true
	return false

## Lo que se ahorra con los consejeros que hay ahora: [fracción, clave del consejero].
static func ahorro(m: Mundo, tipo: String) -> Array:
	var r: Array = REBAJA[tipo]
	var hay := m.directiva != null and m.directiva.tiene_consejero(String(r[0]))
	return [float(r[1]) if hay else 0.0, String(r[0])]

## Se llama una vez por semana (`Mundo.avanzar_semana`): cobra lo que ya se avisó y vence, y avisa de un golpe nuevo si toca. Devuelve lo cobrado ({} si nada).
static func semana(m: Mundo) -> Dictionary:
	var c := m.mi_club()
	if c == null or m.roles == null:
		return {}
	var cobrado := {}
	var pend: Array = m.roles.crisis_pendiente
	for e: Dictionary in pend.duplicate():
		if _abs(m) >= int(e["vence"]):
			pend.erase(e)
			cobrado = _cobrar(m, c, e)
	if not pend.is_empty() or reciente(m):
		return cobrado
	var t := tirada(m.semilla, m.anio, m.semana, c.saldo, Eco.ref_caja(float(c.rep)))
	if t.is_empty():
		return cobrado
	t["vence"] = _abs(m) + AVISO_SEMANAS
	pend.append(t)
	if m.prensa != null:
		var d: Array = texto_aviso(String(t["tipo"]), int(t["importe"]), c.nombre)
		m.prensa.noticia.emit(d[0], d[1])
	return cobrado

static func _cobrar(m: Mundo, c: Club, e: Dictionary) -> Dictionary:
	var tipo := String(e["tipo"])
	var a := ahorro(m, tipo)
	var importe := int(round(float(e["importe"]) * (1.0 - float(a[0])) / 1000.0)) * 1000
	c.mover_saldo(-importe)
	m._anotar_movimiento(concepto(tipo), -importe)
	if m.prensa != null:
		var d: Array = texto(tipo, importe, c.nombre, float(a[0]) > 0.0)
		m.prensa.noticia.emit(d[0], d[1])
	return {"tipo": tipo, "importe": importe}

## [titular, cuerpo] del AVISO (en castellano: quien lo muestre lo pasa por `Idiomas.t`).
static func texto_aviso(tipo: String, importe: int, club: String) -> Array:
	var din := Cesiones.dinero(importe)
	var quien: String = String(Directiva.CONSEJEROS[String(REBAJA[tipo][0])]["nombre"]).to_lower()
	match tipo:
		"multa":
			return [Idiomas.t("Expediente de la federación contra %s") % club, Idiomas.t("Se resolverá en unas semanas con una sanción de unos %s. Un %s podría recurrirla.") % [din, Idiomas.t(quien)]]
		"patrocinio":
			return [Idiomas.t("%s, en el aire con su patrocinador") % club, Idiomas.t("El patrocinador principal estudia recortar unos %s su aportación. Un %s podría renegociarlo.") % [din, Idiomas.t(quien)]]
		_:
			return [Idiomas.t("La obra del estadio se complica"), Idiomas.t("Suben los materiales: el constructor reclamará unos %s más en unas semanas. Un %s podría negociarlo.") % [din, Idiomas.t(quien)]]

## [titular, cuerpo] de lo COBRADO; `rebajado`: un consejero lo dejó en menos.
static func texto(tipo: String, importe: int, club: String, rebajado: bool) -> Array:
	var din := Cesiones.dinero(importe)
	var cola := Idiomas.t(" Tu consejero lo rebajó.") if rebajado else ""
	match tipo:
		"multa":
			return [Idiomas.t("La federación multa a %s") % club, Idiomas.t("Por «irregularidades administrativas»: %s de sanción.") % din + cola]
		"patrocinio":
			return [Idiomas.t("%s pierde parte de su patrocinio") % club, Idiomas.t("El patrocinador principal recorta su aportación: la caja pierde %s.") % din + cola]
		_:
			return [Idiomas.t("La obra del estadio se encarece"), Idiomas.t("El constructor reclama %s más. Hay que pagar para no parar la obra.") % din + cola]
