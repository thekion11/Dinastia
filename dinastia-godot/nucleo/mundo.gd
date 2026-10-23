class_name Mundo
extends "res://nucleo/mundo_p7.gd"
## (Parte 8 de 8 de `mundo.gd`.)

## Las formaciones que has usado, ordenadas por puntos por partido. Es la tabla
## que contesta «¿de verdad me funciona el 4-3-3?».
func ranking_tactico() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for k: String in eficacia_tactica:
		var f: Dictionary = eficacia_tactica[k]
		var pj := int(f["pj"])
		if pj <= 0:
			continue
		salida.append({
			"formacion": k, "pj": pj, "pg": int(f["pg"]), "pe": int(f["pe"]), "pp": int(f["pp"]),
			"gf": int(f["gf"]), "gc": int(f["gc"]),
			"ppp": float(int(f["pg"]) * 3 + int(f["pe"])) / float(pj),
			"moda": factor_moda(k),
		})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["ppp"]) > float(b["ppp"]))
	return salida

func puede_analizar() -> bool:
	return semana - _ultimo_analisis >= SEMANAS_ENTRE_ANALISIS

## Prepara al equipo para el rival de esta semana. Devuelve "" si se hizo.
func analizar_rival() -> String:
	if not puede_analizar():
		return "ya hicisteis videoanálisis hace poco: uno cada %d semanas" % SEMANAS_ENTRE_ANALISIS
	var mio := mi_club()
	if mio == null:
		return "no hay club"
	var l := liga_de(mio)
	var par := l.emparejamiento_de(mio) if l != null else []
	if par.size() != 2:
		return "esta semana no hay rival que estudiar"
	var rival: Club = par[0] if par[0] != mio else par[1]
	_ultimo_analisis = semana
	## Contra uno mejor que tú el análisis vale más: estudiar a un equipo que te
	## supera es lo que de verdad cambia un partido, y estudiar al colista no.
	var diferencia := rival.rep - mio.rep
	bono_analisis = 1.0 + clampf(0.02 + float(diferencia) * 0.004, 0.01, 0.07)
	## Y el analista de vídeo del cuerpo técnico lo afina.
	if staff != null:
		bono_analisis += 0.005 * float(staff.nivel("ojeador"))
	for j in mio.plantilla:
		j.fisico = clampi(j.fisico - 2, 10, 100)
	if prensa != null:
		prensa.noticia.emit("Videoanálisis de %s" % rival.nombre,
			"Sesión de vídeo con todo el plantel: dónde aprietan, por dónde salen y a quién hay que tapar. El equipo sale al campo con la lección hecha (+%d%%)." % int(round((bono_analisis - 1.0) * 100.0)))
	return ""
