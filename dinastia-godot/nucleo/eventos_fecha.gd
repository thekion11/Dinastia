class_name EventosFecha
extends RefCounted
## LOS EVENTOS DEL CALENDARIO (10-11, estilo PES 2020 Master League): qué viene, semana a semana, para tu club. Solo LEE el mundo (no cambia nada).
## Tipos: «liga» (tu partido), «copa», «conti» (torneo continental), «mercado_abre», «mercado_cierra» y «fin» (última jornada de la liga).
## Cada evento: {tipo, dia (0-6, lunes-domingo; el partido cae en sábado = 5), orden, icono, etiqueta, texto, rival (Club o null), local, probable}.
## `probable` = copa/continental de una ronda futura: solo ocurre si tu club sigue vivo en el torneo (el rival aún no existe).
const VISTA := 6   ## semanas que enseña la vista de varias semanas
const LOOKAHEAD := 12   ## semanas que mira la fila de próximos para juntar sus eventos
const DIA_PARTIDO := 5
const ICONO := {"liga": "⚽", "copa": "🏆", "conti": "🌎", "mercado_abre": "🔓", "mercado_cierra": "⏳", "fin": "🏁"}

## Las próximas `cuantas` semanas de la temporada en curso: [{k (0 = esta), semana, eventos}]. Vacío si la liga terminó.
static func semanas(m: Mundo, cuantas := VISTA) -> Array:
	var out: Array = []
	var mio := m.mi_club() if m != null else null
	if mio == null or not m.temporada_en_curso():
		return out
	var liga := m.liga_de(mio)
	if liga == null or not liga.quedan_jornadas():
		return out
	var ultimo := liga.calendario.size() - 1 - liga.jornada_actual   ## k de la última jornada
	for k in mini(cuantas, ultimo + 1):
		out.append({"k": k, "semana": m.semana + k, "eventos": _de_semana(m, mio, liga, k)})
	return out

## Los siguientes `cuantos` eventos en orden de fecha, desde el día `dia_hoy` de esta semana (lo ya pasado de hoy no sale).
static func proximos(m: Mundo, dia_hoy := 0, cuantos := 5) -> Array:
	var out: Array = []
	for s: Dictionary in semanas(m, LOOKAHEAD):
		for e: Dictionary in s["eventos"]:
			if int(s["k"]) == 0 and int(e["dia"]) < dia_hoy:
				continue
			var copia: Dictionary = e.duplicate()
			copia["k"] = s["k"]
			copia["semana"] = s["semana"]
			out.append(copia)
			if out.size() >= cuantos:
				return out
	return out

## El PRÓXIMO HITO para el botón «Hito»: {"dia" (hasta qué día avanzar), "icono", "texto", "tipo"}. Lo de hoy que no es partido ya pasó; si el evento es de otra
## semana se avanza hasta el domingo (el cambio de semana ya detiene el avance).
static func hito(m: Mundo, dia_hoy := 0) -> Dictionary:
	if m == null or not m.temporada_en_curso():
		return {"dia": 6, "icono": "🏁", "texto": Idiomas.t("Temporada terminada"), "tipo": "fin"}
	for e: Dictionary in proximos(m, dia_hoy, 12):
		if int(e["k"]) == 0 and int(e["dia"]) == dia_hoy and not es_partido(e):
			continue
		return {"dia": int(e["dia"]) if int(e["k"]) == 0 else 6, "icono": e["icono"], "texto": e["texto"], "tipo": e["tipo"]}
	return {"dia": 6, "icono": "🛌", "texto": Idiomas.t("Semana sin partido"), "tipo": "nada"}

static func es_partido(e: Dictionary) -> bool:
	return e["tipo"] == "liga" or e["tipo"] == "copa" or e["tipo"] == "conti"

static func _abierto(w: int) -> bool:
	return w <= Mundo.VENTANA_VERANO or (w >= Mundo.VENTANA_INVIERNO_INI and w <= Mundo.VENTANA_INVIERNO_FIN)

static func _ev(tipo: String, dia: int, orden: int, etiqueta: String, texto: String) -> Dictionary:
	return {"tipo": tipo, "dia": dia, "orden": orden, "icono": ICONO[tipo], "etiqueta": etiqueta, "texto": texto, "rival": null, "local": true, "probable": false}

static func _de_semana(m: Mundo, mio: Club, liga: Liga, k: int) -> Array:
	var w := m.semana + k
	var j := liga.jornada_actual + k
	var ev: Array = []
	if w > 1 and _abierto(w) and not _abierto(w - 1):
		ev.append(_ev("mercado_abre", 0, 0, Idiomas.t("Mercado"), Idiomas.t("Abre el mercado de fichajes")))
	for par: Array in liga.calendario[j]:
		if par[0] == mio or par[1] == mio:
			var local: bool = par[0] == mio
			var rival: Club = par[1] if local else par[0]
			var e := _ev("liga", DIA_PARTIDO, 1, "J%d" % (j + 1), "%s %s" % [Idiomas.t("vs") if local else Idiomas.t("en"), rival.nombre])
			e["rival"] = rival
			e["local"] = local
			ev.append(e)
			break
	ev.append_array(_de_copa(m, w))
	ev.append_array(_de_conti(m, mio, w))
	if _abierto(w) and not _abierto(w + 1):
		ev.append(_ev("mercado_cierra", 6, 4, Idiomas.t("Mercado"), Idiomas.t("Cierra el mercado de fichajes")))
	if j == liga.calendario.size() - 1:
		ev.append(_ev("fin", 6, 5, Idiomas.t("Temporada"), Idiomas.t("Fin de temporada")))
	ev.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["dia"]) * 10 + int(a["orden"]) < int(b["dia"]) * 10 + int(b["orden"]))
	return ev

## Cuántas rondas del torneo (semanas de copa o continental) hay entre hoy y la semana `w`, sin contarla.
static func _rondas_antes(m: Mundo, w: int, es_copa: bool) -> int:
	var n := 0
	for s in range(m.semana, w):
		if (s % 4 == 0) if es_copa else (Continental.toca_ronda(s) >= 0):
			n += 1
	return n

static func _nombre_ronda(vivos: int) -> String:
	match vivos:
		2: return Idiomas.t("Final")
		4: return Idiomas.t("Semifinales")
		8: return Idiomas.t("Cuartos de final")
		16: return Idiomas.t("Octavos de final")
		32: return Idiomas.t("Dieciseisavos")
	return Idiomas.t("Ronda")

static func _con_rival(e: Dictionary, par: Array, mio: Club) -> void:
	if par.size() == 2:
		e["local"] = par[0] == mio
		e["rival"] = par[1] if par[0] == mio else par[0]

static func _de_copa(m: Mundo, w: int) -> Array:
	var cp := m.copa
	var mio := m.club_de_la_copa()
	if cp == null or mio == null or not cp.en_curso() or w % 4 != 0 or not cp.vivos.has(mio):
		return []
	var idx := _rondas_antes(m, w, true)
	var n := cp.vivos.size() >> idx
	if n < 2:
		return []
	var e := _ev("copa", DIA_PARTIDO, 2, Idiomas.t("Copa"), "%s · %s" % [cp.nombre, _nombre_ronda(n)])
	if idx == 0:
		_con_rival(e, cp.emparejamiento_de(mio), mio)
	else:
		e["probable"] = true
	return [e]

static func _de_conti(m: Mundo, mio: Club, w: int) -> Array:
	var t := m.mi_continental()
	if t == null or Continental.toca_ronda(w) < 0 or not t.en_curso():
		return []
	var idx := _rondas_antes(m, w, false)
	var grupos := t.en_fase_de_grupos()
	if not grupos and (not t.vivos.has(mio) or (t.vivos.size() >> idx) < 2):
		return []
	var ronda := t.nombre_de_ronda() if idx == 0 else (Idiomas.t("Ronda") if grupos else _nombre_ronda(t.vivos.size() >> idx))
	var e := _ev("conti", DIA_PARTIDO, 3, Idiomas.t("Continental"), "%s · %s" % [t.nombre, ronda])
	if idx == 0:
		var par := t.emparejamiento_de(mio)
		if par.is_empty():
			return []
		_con_rival(e, par, mio)
	else:
		e["probable"] = true
	return [e]
