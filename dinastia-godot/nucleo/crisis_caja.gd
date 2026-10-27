class_name CrisisCaja
extends RefCounted
## CRISIS DE CAJA (27-10-2026, M-208): medido con `eq_diez_temporadas`, el club grande sin gestionar se hacía rico en línea recta (6,6 → 65-95 M en diez
## años) porque nada le salía mal. Ahora, de vez en cuando, a TU club le cae un golpe: la federación le multa, su patrocinador principal recorta o una obra
## del estadio se encarece. El golpe crece con la caja (un club rico llama la atención de la federación, del patrocinador y de los constructores)
## y llega más a menudo cuanto más sana está; el club chico apenas lo nota. Sin `Azar`: sale de un hash de (semilla, año, semana), como los incidentes de
## la ciudad, para no mover ninguna otra tirada de la partida.
const POR_SEMANA := 0.075          ## probabilidad base cada semana (≈ 2,5 golpes por temporada de 34 semanas con la caja en su referencia)
const TIPOS := ["multa", "patrocinio", "obra"]

## Qué pasa esta semana, si pasa algo: {tipo, importe}. `saldo` y `ref` son los de tu club (`Eco.ref_caja(rep)`).
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
	var peso := clampf(float(saldo) / maxf(1.0, ref * 2.0), 0.6, 4.0)   ## el golpe crece con la caja
	return {"tipo": tipo, "importe": int(round(ref * (0.2 + 0.5 * u) * peso / 1000.0)) * 1000}

static func concepto(tipo: String) -> String:
	match tipo:
		"multa":
			return "Multa de la federación"
		"patrocinio":
			return "Recorte del patrocinador"
		_:
			return "Sobrecoste de obra"

## ¿Hubo ya un golpe en las últimas `ENFRIAMIENTO` semanas? Así nunca caen cuatro seguidos (medido: una temporada con cuatro se llevaba 11 M).
const ENFRIAMIENTO := 6

static func reciente(m: Mundo) -> bool:
	var nombres := TIPOS.map(func(t: String) -> String: return concepto(t))
	for k in range(m.libro_financiero.size() - 1, maxi(-1, m.libro_financiero.size() - 25), -1):
		var e: Dictionary = m.libro_financiero[k]
		if int(e["anio"]) == m.anio and nombres.has(String(e["concepto"])) and m.semana - int(e["semana"]) < ENFRIAMIENTO:
			return true
	return false

## Se llama una vez por semana (`Mundo.avanzar_semana`). Cobra el golpe, lo apunta en el libro de movimientos y lo cuenta en la prensa. Devuelve lo que pasó.
static func semana(m: Mundo) -> Dictionary:
	var c := m.mi_club()
	if c == null:
		return {}
	if reciente(m):
		return {}
	var t := tirada(m.semilla, m.anio, m.semana, c.saldo, Eco.ref_caja(float(c.rep)))
	if t.is_empty():
		return t
	var importe := int(t["importe"])
	c.mover_saldo(-importe)
	m._anotar_movimiento(concepto(String(t["tipo"])), -importe)
	if m.prensa != null:
		var d: Array = texto(String(t["tipo"]), importe, c.nombre)
		m.prensa.noticia.emit(d[0], d[1])
	return t

## [titular, cuerpo] (en castellano: quien lo muestre lo pasa por `Idiomas.t`).
static func texto(tipo: String, importe: int, club: String) -> Array:
	var din := Cesiones.dinero(importe)
	match tipo:
		"multa":
			return [Idiomas.t("La federación multa a %s") % club, Idiomas.t("Por «irregularidades administrativas»: %s de sanción. Recurrir llevaría más de lo que cuesta.") % din]
		"patrocinio":
			return [Idiomas.t("%s pierde parte de su patrocinio") % club, Idiomas.t("El patrocinador principal recorta su aportación: se resiente la caja en %s.") % din]
		_:
			return [Idiomas.t("La obra del estadio se encarece"), Idiomas.t("Suben los materiales y el constructor reclama %s más. Hay que pagar para no parar la obra.") % din]
