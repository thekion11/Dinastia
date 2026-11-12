class_name MejorasC4Hueco
extends RefCounted
## MÁS PASES AL HUECO EN C4 (12-11-2026, sesión 15). Las cuatro variantes del adelanto (`C4_ADELANTO`) enseñaron que el pase
## arriesgado es el que crea el peligro: quitar cortes cuesta goles. Esta va al revés: con `C4_HUECO=1`, si el pase al hueco de
## siempre (`_companero_al_hueco`: DC/extremos/MC habilitados a < 7 m de la última línea) no encuentra a nadie, se busca con más
## manga: también el lateral que se incorpora, a < `LINEA` m de la última línea, con 3 m de ventaja hacia delante. La línea de pase
## tiene que seguir limpia. Solo en C4 (`MotorCombinado._companero_al_hueco`); contador `c4_hueco_extra`.

static var ACTIVO := OS.get_environment("C4_HUECO") == "1"
static var LINEA := float(OS.get_environment("C4_HUECO_L")) if OS.get_environment("C4_HUECO_L") != "" else 10.0

static func buscar(m: Object, p: Dictionary) -> Dictionary:
	if not ACTIVO:
		return {}
	var local := bool(p["es_local"])
	var d: float = m.dir_ataque(local)
	var linea: float = m._ultima_linea(not local)
	var yo: Vector3 = m.pos(p)
	var largo: float = m.LARGO
	var mejor: Dictionary = {}
	var mejor_nota := 0.0
	for q: Dictionary in m.jugadores:
		if q == p or bool(q["es_local"]) != local or bool(q["por"]):
			continue
		if not String(m._rol(q)) in ["DC", "ED", "EI", "MC", "LD", "LI"]:
			continue
		var qp: Vector3 = m.pos(q)
		var adelante := (qp.z - yo.z) * d
		if adelante < 3.0 or absf(qp.z - linea) > LINEA or m._adelantado(q, p):
			continue
		var espacio := qp + Vector3(0, 0, d * 7.0)
		espacio.z = clampf(espacio.z, -largo + 4.0, largo - 4.0)
		if m._linea_tapada(yo, espacio, local):
			continue
		var nota := adelante - absf(qp.x) * 0.15
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	if not mejor.is_empty() and m.get("diag") is Dictionary:
		(m.diag as Dictionary)["c4_hueco_extra"] = int((m.diag as Dictionary).get("c4_hueco_extra", 0)) + 1
	return mejor
