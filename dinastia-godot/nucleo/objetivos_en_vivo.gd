class_name ObjetivosEnVivo
extends RefCounted
## EL PROGRESO EN VIVO DE LOS OBJETIVOS POR CLUB (10-11, pedido de la sesión principal): una fila por objetivo secundario y por el proyecto, con un
## progreso 0-100 y un estado («cumplido», «bien», «riesgo», «perdido») calculados con lo que ha pasado hasta hoy. Solo lee el mundo (no toca nada) y
## usa las mismas reglas que `ObjetivosCierre.juzgar`, que sigue siendo quien da el veredicto final al cerrar la temporada.
## Cada fila: {texto, peso, progreso, estado, tipo}.

static func _estado(p: int, perdido := false) -> String:
	if perdido:
		return "perdido"
	if p >= 100:
		return "cumplido"
	return "bien" if p >= 55 else "riesgo"

static func _fila(o: Dictionary, p: int, perdido := false) -> Dictionary:
	p = clampi(p, 0, 100)
	return {"texto": String(o.get("texto", "")), "peso": int(o.get("peso", 0)), "progreso": p, "estado": _estado(p, perdido), "tipo": String(o.get("tipo", ""))}

## Progreso en una copa (o copa continental): rondas ganadas frente a las que pide la meta.
static func _en_copa(copa: Copa, c: Club, o: Dictionary, grupos_ok := true) -> Dictionary:
	var meta := int(o.get("meta", 0))
	var ganadas := ObjetivosClub.rondas_ganadas(copa, c)
	var need := ObjetivosClub.rondas_para(copa, meta)
	if meta >= 16:
		need = maxi(1, need)
	if copa.campeon == c or ganadas >= need:
		return _fila(o, 100)
	var vivo := copa.vivos.has(c) or (copa is Continental and (copa as Continental).en_fase_de_grupos())
	if not vivo:
		return _fila(o, 0, true)
	return _fila(o, int(round(100.0 * float(ganadas) / float(maxi(need, 1)) * 0.9)))

static func lista(m: Mundo, d: Directiva) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	if m == null or d == null or d.club == null:
		return salida
	var c: Club = d.club
	var liga: Liga = m.liga_de(c)
	for o: Dictionary in d.objetivos:
		var meta := int(o.get("meta", 0))
		match String(o.get("tipo", "")):
			"copa":
				if m.copa != null and m.copa.participantes.has(c):
					salida.append(_en_copa(m.copa, c, o))
			"continental":
				for k: Variant in m.continentales:
					var cont: Continental = m.continentales[k]
					if cont == null or not cont.participa(c):
						continue
					if meta > 4:   ## superar la fase de grupos
						var pasa := cont.campeon == c or cont.clasificados().has(c) or ObjetivosClub.rondas_ganadas(cont, c) > 0
						if pasa:
							salida.append(_fila(o, 100))
						elif cont.en_fase_de_grupos():
							var mar: Dictionary = cont.marcador.get(c.id, {})
							salida.append(_fila(o, 35 + mini(int(mar.get("pts", 0)) * 7, 55)))
						else:
							salida.append(_fila(o, 0, true))
					else:
						salida.append(_en_copa(cont, c, o))
					break
			"economia":
				var base := int(d.bases.get("saldo", 0))
				var p := 0
				if meta == 0:
					p = 100 if c.saldo >= 0 else int(round(100.0 * (1.0 - float(-c.saldo) / float(maxi(-base, 1)))))
				elif meta > 0:
					var obj := base + maxi(int(absf(float(base)) * 0.1), Eco.escalar(300000.0, float(c.rep)))
					p = int(round(100.0 * float(c.saldo - base) / float(maxi(obj - base, 1))))
				else:
					var piso := float(base) * 0.9
					p = 100 if float(c.saldo) >= piso else int(round(100.0 * float(c.saldo) / maxf(piso, 1.0)))
				salida.append(_fila(o, p))
			"cantera":
				var jovenes := 0
				for j: Jugador in c.plantilla:
					if j.edad <= 21:
						jovenes += 1
				salida.append(_fila(o, int(round(100.0 * float(jovenes) / float(maxi(meta, 1))))))
			"social":
				var b := int(d.bases.get("socios", 0))
				if b > 0:
					salida.append(_fila(o, int(round(100.0 * float(c.socios - b) / (float(b) * float(meta) / 100.0)))))
			"estilo":
				if liga != null and liga.jornada_actual > 0:
					salida.append(_fila(o, _estilo(liga, c, meta)))
	var pr: Dictionary = d.proyecto
	if not pr.is_empty():
		var tot := maxi(int(pr.get("temporadas", ObjetivosClub.TEMPORADAS_PROYECTO)), 1)
		var p2 := int(round(100.0 * float(int(pr.get("cierres", 0))) / float(tot)))
		var mal := (String(pr.get("id", "")) == "sanear" and c.saldo < 0) or not bool(pr.get("sin_descender", true))
		var fila := _fila({"texto": pr.get("texto", ""), "peso": ObjetivosClub.PESO_PROYECTO_OK, "tipo": "proyecto"}, mini(p2, 99))
		if mal and String(fila["estado"]) == "bien":
			fila["estado"] = "riesgo"
		salida.append(fila)
	return salida

## 0-100 para el objetivo de estilo según la tabla de hoy.
static func _estilo(liga: Liga, c: Club, meta: int) -> int:
	var filas: Array = liga.tabla()
	var mias := {}
	var gc_tot := 0.0
	var pj_tot := 0.0
	for f: Dictionary in filas:
		gc_tot += float(f["gc"])
		pj_tot += float(f["pj"])
		if f["club"] == c:
			mias = f
	if mias.is_empty() or pj_tot <= 0.0:
		return 50
	if meta > 0:
		var mejores := 0
		for f2: Dictionary in filas:
			if int(f2["gf"]) > int(mias["gf"]):
				mejores += 1
		return 100 if mejores < meta else maxi(0, 90 - (mejores - meta + 1) * 18)
	var mia := float(mias["gc"]) / maxf(float(mias["pj"]), 1.0)
	var media := gc_tot / pj_tot
	return 100 if mia < media else int(round(clampf(50.0 * media / maxf(mia, 0.01), 0.0, 95.0)))
