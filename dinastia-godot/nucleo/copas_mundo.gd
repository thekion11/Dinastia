class_name CopasMundo
extends RefCounted
## LAS COPAS Y SUPERCOPAS DE TODOS LOS PAÍSES (encargo del dueño del 10-11, punto 1 «torneos»). Antes solo existía la copa de TU país (`Mundo.copa`)
## y su supercopa; en los otros 27 países no se jugaba ninguna copa. Aquí:
## - al empezar cada temporada se sortean las copas de los DEMÁS países (todas las de `Copa.COPAS_POR_PAIS`, también la segunda copa, el mismo año)
##   y las del TUYO que no son la principal (la copa de la liga en Inglaterra, Argentina o Japón), sin tu club: esas las juegan los demás;
## - se juegan simuladas en las mismas semanas que la tuya (`semana % 4 == 0`) y, si la liga acaba antes, se cierran con `CierreTorneos`;
## - al empezar la temporada siguiente se juegan las SUPERCOPAS de cada país (campeón de liga contra campeón de copa, a partido único);
## - los campeones quedan en `Mundo.palmares_mundo` ([{anio, pais, torneo, club}], lo más nuevo al final) y en la prensa (solo los títulos).
const MAX_PALMARES := 600

## Las copas de los demás NO tocan el azar del resto del juego: cada sorteo o ronda guarda el estado de `Azar`, usa una semilla propia (año, semana
## y torneo: variedad) y lo deja como estaba. Así añadirlas no cambia nada de lo que ya pasaba (mismos resultados con la misma semilla).
static func _aislado(clave: String, accion: Callable) -> void:
	var estado: int = Azar._rng.state
	Azar._rng.seed = hash(clave)
	accion.call()
	Azar._rng.state = estado

## Sortea las copas de la temporada (los demás países y las copas secundarias del tuyo). Se llama al montar la copa de tu país.
static func montar(m: Mundo) -> void:
	_aislado("montar%d" % m.anio, func() -> void: _montar(m))

static func _montar(m: Mundo) -> void:
	m.copas_otras.clear()
	var mio := m.mi_club()
	var pais_mio := mio.pais if mio != null else ""
	var por_pais := {}
	for c: Club in m.clubes.values():
		if not por_pais.has(c.pais):
			por_pais[c.pais] = []
		(por_pais[c.pais] as Array).append(c)
	var nombres: Dictionary = Datos.tabla("PAIS_SELECCION")
	for pais: String in por_pais:
		var lista: Array = por_pais[pais]
		if lista.size() < 4:
			continue
		var copas: Array = Copa.copas_de(pais, String(nombres.get(pais, pais)) if nombres != null else pais)
		for k in copas.size():
			if pais == pais_mio and k == 0:
				continue   ## la principal de tu país es `Mundo.copa` (la juegas tú)
			var inscritos: Array[Club] = []
			for c2: Club in lista:
				if c2 != mio:
					inscritos.append(c2)
			var cp := Copa.new(String((copas[k] as Array)[0]))
			cp.preparar(inscritos)
			cp.set_meta("pais", pais)
			m.copas_otras.append(cp)

## Una ronda de cada copa de los demás, en las semanas de copa.
static func semana(m: Mundo) -> void:
	if m.semana % 4 != 0:
		return
	for cp: Copa in m.copas_otras:
		if cp.en_curso():
			_aislado("%d/%d/%s" % [m.anio, m.semana, cp.nombre + String(cp.get_meta("pais", ""))], func() -> void: cp.jugar_ronda())
			if not cp.en_curso() and cp.campeon != null:
				anotar(m, String(cp.get_meta("pais", cp.campeon.pais)), cp.nombre, cp.campeon)

## Juega hasta el final las copas de los demás que sigan a medias (al terminar la liga). Devuelve cuántas cerró.
static func cerrar(m: Mundo) -> int:
	var n := 0
	for cp: Copa in m.copas_otras:
		if cp.en_curso():
			_aislado("fin%d/%s" % [m.anio, cp.nombre + String(cp.get_meta("pais", ""))], func() -> void: cp.jugar_hasta_el_final())
			n += 1
			if cp.campeon != null:
				anotar(m, String(cp.get_meta("pais", cp.campeon.pais)), cp.nombre, cp.campeon)
	return n

## Apunta, al terminar la liga, quién ganó cada liga de primera de los demás países (para sus supercopas del año siguiente).
static func anotar_campeones_liga(m: Mundo) -> void:
	var mio := m.mi_club()
	for l: Liga in m.ligas:
		if l.division() != 1 or (mio != null and l.pais == mio.pais):
			continue
		var t: Array = l.tabla()
		if not t.is_empty():
			m.campeones_liga_otros[l.pais] = t[0]["club"]
			anotar(m, l.pais, l.nombre, t[0]["club"])

## Las supercopas de los demás países (campeón de liga contra campeón de la copa principal de la temporada pasada), a partido único y simuladas.
static func supercopas(m: Mundo) -> Array:
	var jugadas: Array = []
	var mio := m.mi_club()
	for pais: String in m.campeones_liga_otros:
		if mio != null and pais == mio.pais:
			continue
		var liga_c: Club = m.campeones_liga_otros[pais]
		var copa_c: Club = null
		for cp: Copa in m.copas_otras:
			if String(cp.get_meta("pais", "")) == pais and cp.campeon != null:
				copa_c = cp.campeon
				break   ## la primera del país es la principal
		if liga_c == null or copa_c == null or liga_c == copa_c:
			continue
		var p := Partido.new(liga_c, copa_c)
		_aislado("super%d/%s" % [m.anio, pais], func() -> void: p.simular())
		var gana: Club = liga_c if p.goles_local >= p.goles_visita else copa_c   ## empate: el campeón de liga (no hay penaltis en la simulada)
		anotar(m, pais, "Supercopa", gana)
		jugadas.append({"pais": pais, "local": liga_c, "visita": copa_c, "gl": p.goles_local, "gv": p.goles_visita, "campeon": gana})
	m.campeones_liga_otros.clear()
	return jugadas

static func anotar(m: Mundo, pais: String, torneo: String, club: Club) -> void:
	m.palmares_mundo.append({"anio": m.anio, "pais": pais, "torneo": torneo, "club": club.id})
	while m.palmares_mundo.size() > MAX_PALMARES:
		m.palmares_mundo.pop_front()

## Los títulos de un club en lo que va de partida: [{anio, torneo}].
static func titulos_de(m: Mundo, c: Club) -> Array:
	return m.palmares_mundo.filter(func(t: Dictionary) -> bool: return String(t["club"]) == c.id)

# ---------------------------------------------------------------- guardado

static func a_dic(m: Mundo) -> Dictionary:
	var copas: Array = []
	for cp: Copa in m.copas_otras:
		var d := Partida._copa_a_dic(cp)
		d["pais"] = String(cp.get_meta("pais", ""))
		copas.append(d)
	var ligas := {}
	for pais: String in m.campeones_liga_otros:
		ligas[pais] = (m.campeones_liga_otros[pais] as Club).id
	return {"copas": copas, "palmares": m.palmares_mundo, "campeones_liga": ligas}

static func desde_dic(m: Mundo, d: Dictionary) -> void:
	m.copas_otras.clear()
	for dc: Dictionary in d.get("copas", []):
		var cp := Partida._dic_a_copa(dc, m)
		if cp != null:
			cp.set_meta("pais", String(dc.get("pais", "")))
			m.copas_otras.append(cp)
	m.palmares_mundo = (d.get("palmares", []) as Array).duplicate(true)
	m.campeones_liga_otros.clear()
	var ligas: Dictionary = d.get("campeones_liga", {})
	for pais: String in ligas:
		if m.clubes.has(String(ligas[pais])):
			m.campeones_liga_otros[pais] = m.clubes[String(ligas[pais])]
