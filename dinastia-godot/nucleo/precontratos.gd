class_name Precontratos
extends RefCounted
## PRECONTRATOS (27-10-2026, M-217): el mercado prometía «libres y precontratos funcionan todo el año» y no existían. Aquí el DT cierra con un
## jugador de OTRO club que está en el último año de su contrato (y ya en su último semestre: semana ≥ `SEMANA_DESDE`) un acuerdo de ficha; cuando
## su contrato vence en el cambio de temporada, en vez de renovar con su club o irse a la bolsa de libres, LLEGA A TU CLUB sin traspaso (monto 0) y
## con la ficha pactada. Los precontratos viven en `Mercado.precontratos` (se guardan con la partida) y se vacían en cada cambio de temporada.
const SEMANA_DESDE := 19
const ANIOS := 3

static func de(m: Mundo, id: String) -> Dictionary:
	if m.mercado == null:
		return {}
	for e: Dictionary in m.mercado.precontratos:
		if String(e["id"]) == id:
			return e
	return {}

## "" si se puede firmar un precontrato con `j`; si no, el motivo (traducido).
static func motivo(m: Mundo, j: Jugador) -> String:
	var mio := m.mi_club()
	if mio == null or j == null or m.mercado == null:
		return Idiomas.t("ese jugador no existe")
	if j.club_id == mio.id:
		return Idiomas.t("ese jugador ya es tuyo")
	if j.club_id == "":
		return Idiomas.t("ya está libre: ficha como libre, sin precontrato")
	if m.roles != null and not m.roles.puede_fichar():
		return Idiomas.t(String(m.roles.motivo_bloqueo("fichar")))
	if m.tiene_desafio("cantera"):
		return Idiomas.t("Desafío «solo canteranos»: el mercado te queda vetado.")
	if m.tiene_desafio("local") and j.pais != mio.pais:
		return Idiomas.t("Desafío «un solo país»: no puedes fichar extranjeros.")
	if j.anios_contrato > 1:
		return Idiomas.t("Aún le quedan %d años de contrato: el precontrato solo vale en su último año.") % j.anios_contrato
	if m.semana < SEMANA_DESDE:
		return Idiomas.t("Los precontratos se firman en el último semestre de su contrato (desde la semana %d).") % SEMANA_DESDE
	if not de(m, j.id).is_empty():
		return Idiomas.t("Ya tienes un precontrato firmado con él.")
	if not Regiones.admite(mio, j):
		var mot := Regiones.motivo(mio)
		return Idiomas.t(mot[0].to_upper() + mot.substr(1))
	if m.federacion != null:
		var ext := m.federacion.puede_fichar_extranjero(mio, j)
		if ext != "":
			return Idiomas.t(ext)
	return ""

## Intenta cerrar el precontrato con la ficha que el jugador pide. Devuelve "" si lo firma, o el motivo por el que no.
static func firmar(m: Mundo, j: Jugador) -> String:
	var no := motivo(m, j)
	if no != "":
		return no
	var mio := m.mi_club()
	var sueldo := m.mercado.ficha_que_pide(j, mio, ANIOS)
	if not m.mercado.jugador_firma(j, mio, sueldo, ANIOS):
		return Idiomas.t("%s no se compromete: prefiere esperar a ver qué ofertas le llegan.") % j.nombre
	m.mercado.precontratos.append({"id": j.id, "sueldo": sueldo, "anios": ANIOS})
	return ""

## Lo llama `Mundo._vence_contrato` cuando a `j` se le acaba el contrato en un club de la IA: si hay precontrato contigo, no va a la bolsa ni renueva;
## queda a la espera (`club_id` vacío) y `llegan` lo mete en tu plantilla al terminar el cambio de temporada. true = se va de su club.
static func llega(m: Mundo, j: Jugador) -> bool:
	var e := de(m, j.id)
	if e.is_empty() or m.mi_club() == null:
		return false
	j.club_id = ""
	e["j"] = j
	return true

## Al terminar el cambio de temporada: entran los que llegan y se vacía la lista (los demás precontratos caducan con su contrato renovado o su retiro).
static func llegan(m: Mundo) -> Array[Jugador]:
	var entran: Array[Jugador] = []
	var mio := m.mi_club()
	if m.mercado == null or mio == null:
		return entran
	for e: Dictionary in m.mercado.precontratos:
		var j: Jugador = e.get("j")
		if j == null:
			continue
		m.mercado.fichar(j, mio, 0, int(e["sueldo"]), int(e["anios"]))
		entran.append(j)
		if m.prensa != null:
			m.prensa.noticia.emit("Llega con precontrato: %s" % j.nombre,
				"Cumplió su contrato y cumple su palabra: %s llega a %s sin traspaso." % [j.nombre, mio.nombre])
	m.mercado.precontratos.clear()
	return entran
