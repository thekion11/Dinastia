class_name Mundo
extends "res://nucleo/mundo_p7.gd"
## [Capa 9/9 de `mundo.gd`] ranking_tactico, puede_analizar, analizar_rival, nueva_temporada (tope del valor)

## EL TOPE DEL VALOR DE LA IA SEGÚN LA DIFICULTAD (26-10, decisión del dueño). En diez temporadas el valor
## medio del mercado de la IA sube ×1,36-×1,45 por el asentamiento del mundo generado (`eq_diez_temporadas`).
## El dueño aceptó ×1,50 como techo, pero que dependa de la dificultad: en fácil los fichajes se encarecen
## menos y en leyenda más. Por encima del tope, el valor de TODA la IA (no tu club, no los sueldos firmados)
## se escala hasta él al cerrar la temporada. Claves = las de la tabla `DIF`.
const TOPE_VALOR_IA := {"facil": 1.35, "normal": 1.50, "leyenda": 1.65}
## La dificultad de la partida (la pone `CicloPartida.arrancar_con`; se guarda) y el valor medio de la IA de
## referencia (al tomar el mando; 0 = todavía no).
## (`dificultad` vive en mundo_p6, que la usa para los premios.)
var valor_ia_ref: float = 0.0

func tope_valor_ia() -> float:
	return float(TOPE_VALOR_IA.get(dificultad, TOPE_VALOR_IA["normal"]))

## La referencia se toma al empezar la partida (guardados viejos: en su primer cierre).
func tomar_el_mando(club_id: String) -> Directiva:
	var d := super(club_id)
	Finanzas.fijar_medias_tv(ligas)
	if valor_ia_ref <= 0.0:
		valor_ia_ref = valor_medio_ia()
	return d

func nueva_temporada() -> Dictionary:
	if valor_ia_ref <= 0.0:
		valor_ia_ref = valor_medio_ia()
	var r := super()
	Finanzas.fijar_medias_tv(ligas)
	## La cláusula de descenso alcanza a los que llegan mientras el club siga abajo.
	for c: Club in clubes.values():
		if c.division >= 2 and c.plantilla.any(func(j: Jugador) -> bool: return j.descenso_club == c.id):
			Contratos.aplicar_descenso(c, anio, true)
	var v := valor_medio_ia()
	var tope := valor_ia_ref * tope_valor_ia()
	if valor_ia_ref > 0.0 and v > tope:
		var f := tope / v
		for c: Club in clubes.values():
			if c.id != mi_club_id:
				for j in c.plantilla:
					j.valor = int(max(300.0, floor(float(j.valor) * f / 100.0) * 100.0))   ## hacia abajo: redondeando, la media quedaba un pelo sobre el tope
		r["tope_valor"] = f
	return r

## El valor medio de los jugadores de los clubes de la IA (sin tu club ni los libres).
func valor_medio_ia() -> float:
	var suma := 0.0
	var n := 0
	for c: Club in clubes.values():
		if c.id == mi_club_id:
			continue
		for j in c.plantilla:
			suma += j.valor
			n += 1
	return suma / float(n) if n > 0 else 0.0

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
