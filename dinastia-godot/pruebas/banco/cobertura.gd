extends "res://pruebas/banco/cobertura_p2.gd"
## [Capa final de `cobertura.gd`] El entrenamiento: tope de la temporada, árbol de habilidades, planes individuales,
## pretemporada, reparto de puntos, semana completa y progreso de jugadores ajenos.

var _avisos
var _campo
var _e
var _j
var _otro
var _portero
var _res
var _u

func _mundo_entreno(semilla: int, pais: String) -> Mundo:
	_m = Mundo.new()
	_m.generar([pais], semilla)
	_m.tomar_el_mando(_m.ligas[0].clubes[3].id)
	return _m

func _probar_entrenamiento_habilidades() -> void:
	_titulo("ENTRENAMIENTO: ÁRBOL DE HABILIDADES, PUNTOS Y MOTIVOS")
	_m = _mundo_entreno(9301, "ESP")
	_e = _m.entrenamiento
	_c = _m.mi_club()
	_campo = null
	_portero = null
	for _j: Jugador in _c.plantilla:
		if _j.es_portero() and _portero == null:
			_portero = _j
		elif not _j.es_portero() and _campo == null:
			_campo = _j
	_probar_entrenamiento_habilidades_01()
	_probar_entrenamiento_habilidades_02()
	_probar_entrenamiento_habilidades_03()
	_probar_entrenamiento_habilidades_04()
	_probar_entrenamiento_habilidades_05()
	_probar_entrenamiento_habilidades_06()

func _probar_entrenamiento_habilidades_01() -> void:
	## Disponibles: el _portero solo ve sus tres; el de _campo no ve las de _portero.
	var dp = _e.disponibles(_portero)
	var dc = _e.disponibles(_campo)
	_comprobar(dp.size() == 3 and dp.has("atajaPen") and dp.has("juegoPies") and dp.has("liderazgo"), "portero: solo penales, juego con los pies y liderazgo (%s)" % str(dp))
	_comprobar(not dc.has("atajaPen") and not dc.has("juegoPies") and dc.has("ruleta"), "jugador de campo: sin las de portero")
	_comprobar(_e.atributo_de(_campo, "ruleta") == "reg" and _e.atributo_de(_campo, "no_existe") == "", "atributo_de(): el de la tabla; clave desconocida vacío")
	_comprobar(_e.atributo_de(_portero, "liderazgo") == "pos" and _portero.atributos.has("pos"), "un portero lidera con «pos» (no tiene «def»)")

func _probar_entrenamiento_habilidades_02() -> void:
	## Motivos.
	_campo.atributos["reg"] = 40
	_comprobar(_e.motivo(_campo, "no_existe") == "no disponible", "motivo(): habilidad inexistente")
	_comprobar(_e.motivo(_campo, "caño").begins_with("antes:"), "motivo(): pide antes la habilidad previa («ruleta»)")
	_comprobar(_e.motivo(_campo, "ruleta").begins_with("necesita REG 68") and _e.motivo(_campo, "ruleta").contains("tiene 40"), "motivo(): dice qué atributo falta y cuánto")
	_campo.atributos["reg"] = 80
	_comprobar(_e.motivo(_campo, "ruleta") == "sin puntos" and not _e.puede(_campo, "ruleta"), "con el atributo pero sin puntos: «sin puntos»")
	_comprobar(_e.aprender(_campo, "ruleta") == "sin puntos" and not _e.tiene_habilidad(_campo, "ruleta"), "aprender() sin puntos no hace nada")

func _probar_entrenamiento_habilidades_03() -> void:
	## Repartir puntos: 12 partidos = 1; menor de 22 con 8 partidos = _otro.
	for _j: Jugador in _c.plantilla:
		_j.partidos = 0
		_e._habs.erase(_j.id)
	_campo.partidos = 12
	_campo.edad = 30
	var joven: Jugador = _c.plantilla.filter(func(x: Jugador) -> bool: return x != _campo and x != _portero)[0]
	joven.partidos = 12
	joven.edad = 19
	_avisos = []
	_e.noticia.connect(func(t: String, _x: String) -> void: _avisos.append(t))
	var s8: Jugador = _c.plantilla.filter(func(x: Jugador) -> bool: return x != _campo and x != _portero and x != joven)[0]
	s8.partidos = 8
	s8.edad = 19
	var ganaron = _e.repartir_puntos(_c)
	_comprobar(_e.puntos(s8) == 1, "un joven con solo 8 partidos gana 1 punto (el de la edad)")
	_comprobar(ganaron.size() == 3 and _e.puntos(_campo) == 1 and _e.puntos(joven) == 2, "reparto: 12 partidos = 1 punto; joven de 21 o menos con 12 = 2 (%d y %d)" % [_e.puntos(_campo), _e.puntos(joven)])
	_comprobar(int(ganaron[0]["puntos"]) == 2 and ganaron[0]["jugador"] == joven and _avisos.size() == 1, "el de más puntos va primero y se avisa")
	_comprobar(_e.repartir_puntos(null).is_empty(), "repartir_puntos(null) no da nada")
	for _j: Jugador in _c.plantilla:
		_j.partidos = 0
	_comprobar(_e.repartir_puntos(_c).is_empty(), "sin minutos no hay puntos")

func _probar_entrenamiento_habilidades_04() -> void:
	## Aprender de verdad.
	_comprobar(_e.motivo(_campo, "ruleta") == "", "ahora sí: atributo y punto disponibles")
	var reg0 = int(_campo.atributos["reg"])
	var moral0 = _campo.moral
	var aprendidas: Array[String] = []
	_e.habilidad_aprendida.connect(func(_j: Jugador, k: String, _n: String) -> void: aprendidas.append(k))
	_comprobar(_e.aprender(_campo, "ruleta") == "" and _e.tiene_habilidad(_campo, "ruleta") and _e.puntos(_campo) == 0, "aprender(): gasta el punto y queda la habilidad")
	_comprobar(int(_campo.atributos["reg"]) == reg0 + 1 and _campo.moral >= moral0 and aprendidas == ["ruleta"], "deja +1 en el atributo que la gobierna y avisa")
	_comprobar(_e.motivo(_campo, "ruleta") == "ya la tiene" and _e.habilidades(_campo).has("ruleta"), "ya aprendida: «ya la tiene»")
	_comprobar(_e.nombre_habilidad("ruleta") == "Ruleta" and _e.nombre_habilidad("zzz") == "zzz" and _e.descripcion_habilidad("ruleta") != "" and _e.descripcion_habilidad("zzz") == "", "nombre y descripción de la habilidad")

func _probar_entrenamiento_habilidades_05() -> void:
	## dar_habilidad: sin gastar puntos, sin repetir, sin inventar.
	_comprobar(_e.dar_habilidad(_campo, "bicicleta") and not _e.dar_habilidad(_campo, "bicicleta") and not _e.dar_habilidad(_campo, "zzz"), "dar_habilidad(): una vez y solo las que existen")
	_e.habilidades(_campo).append("falsa")
	_comprobar(not _e.tiene_habilidad(_campo, "falsa"), "habilidades() devuelve una copia")

func _probar_entrenamiento_habilidades_06() -> void:
	## Con tres habilidades el valor sube un 5 %.
	_comprobar((_e.dar_habilidad(_campo, "sombrero") or _e.tiene_habilidad(_campo, "sombrero")) and _e.habilidades(_campo).size() >= 3, "tres habilidades")
	_campo.tasar()
	var v_sin = _campo.valor
	_e._tasar(_campo)
	_comprobar(_campo.valor >= v_sin, "con 3 habilidades el valor no baja (bono del 5 %%): %d → %d" % [v_sin, _campo.valor])

func _probar_entrenamiento_semana_y_planes() -> void:
	_titulo("ENTRENAMIENTO: SEMANA COMPLETA, PLANES INDIVIDUALES, PRETEMPORADA Y AJENOS")
	_m = _mundo_entreno(9401, "ITA")
	_e = _m.entrenamiento
	_c = _m.mi_club()
	_u = _c.plantilla.filter(func(x: Jugador) -> bool: return not x.es_portero() and x.edad < 24)[0]
	_probar_entrenamiento_semana_y_planes_01()
	_probar_entrenamiento_semana_y_planes_02()
	_probar_entrenamiento_semana_y_planes_03()
	_probar_entrenamiento_semana_y_planes_04()
	_probar_entrenamiento_semana_y_planes_05()
	_probar_entrenamiento_semana_y_planes_06()
	_probar_entrenamiento_semana_y_planes_07()
	_probar_entrenamiento_semana_y_planes_08()
	_probar_entrenamiento_semana_y_planes_09()

func _probar_entrenamiento_semana_y_planes_01() -> void:
	## Freno de la temporada.
	_u.partidos = 0
	_e._subidas[_u.id] = 0
	_comprobar(is_equal_approx(_e.freno_temporada(_u), 1.0), "sin subidas, sin freno")
	_e._subidas[_u.id] = 4
	_comprobar(absf(_e.freno_temporada(_u) - 0.5) < 0.0001, "con 4 subidas sin minutos: 0,5")
	_e._subidas[_u.id] = 5
	_comprobar(absf(_e.freno_temporada(_u) - 0.3) < 0.0001, "5 subidas: 0,3")
	_u.partidos = 12
	_e._subidas[_u.id] = 5
	_comprobar(is_equal_approx(_e.freno_temporada(_u), 1.0), "con 12 partidos el umbral sube a 6")
	_e._subidas[_u.id] = Entrenamiento.TOPE_TEMPORADA
	_comprobar(is_zero_approx(_e.freno_temporada(_u)), "tope duro de la temporada: 0")
	_e.reiniciar_subidas()
	_comprobar(is_equal_approx(_e.freno_temporada(_u), 1.0), "reiniciar_subidas() levanta el freno")

func _probar_entrenamiento_semana_y_planes_02() -> void:
	## Plan individual completado: la habilidad se aprende.
	_otro = _c.plantilla.filter(func(x: Jugador) -> bool: return x != _u and not x.es_portero())[0]
	_comprobar(_e.asignar_individual(_otro, "penales") == "" and _e.plan_de(_otro)["clave"] == "penales", "asignar_individual(): queda el plan")
	_e.individual[_otro.id]["semanas"] = 50
	var f0 = _otro.fisico
	_res = {"subieron": [], "bajaron": [], "aprendieron": [], "lesionados": [], "punto_dt": false}
	_avisos = []
	_e.noticia.connect(func(t: String, _x: String) -> void: _avisos.append(t))
	_e._trabajo_individual(_c, _res)
	_comprobar(_e.tiene_habilidad(_otro, "penalero") and not _e.individual.has(_otro.id) and _res["aprendieron"].size() == 1 and _otro.fisico <= f0, "plan terminado: aprende «penalero» y paga piernas")
	_comprobar(_avisos.any(func(t: String) -> bool: return t.contains("domina una habilidad nueva")), "y se anuncia")

func _probar_entrenamiento_semana_y_planes_03() -> void:
	## Repetir el mismo plan: atributos en vez de habilidad.
	_e.asignar_individual(_otro, "penales")
	_e.individual[_otro.id]["semanas"] = 50
	var ks: Array = _otro.atributos.keys()
	var a0 = int(_otro.atributos[ks[0]])
	_e._trabajo_individual(_c, _res)
	_comprobar(_avisos.any(func(t: String) -> bool: return t.contains("afina lo que ya sabía")) and int(_otro.atributos[ks[0]]) >= a0, "plan repetido: se traduce en atributos")

func _probar_entrenamiento_semana_y_planes_04() -> void:
	## Liderazgo: moral y cinta si no hay capitán.
	for _j: Jugador in _c.plantilla:
		_j.capitan = false
	var lider: Jugador = _c.plantilla[5]
	var plan_lid := ""
	for f: Array in _e.especiales():
		if f[3] == null:
			plan_lid = String(f[0])
	if plan_lid != "":
		_e.asignar_individual(lider, plan_lid)
		_e.individual[lider.id]["semanas"] = 50
		_e._trabajo_individual(_c, _res)
		_comprobar(lider.capitan and _avisos.any(func(t: String) -> bool: return t.contains("líder")), "plan de liderazgo: se lleva la cinta si no había capitán")

func _probar_entrenamiento_semana_y_planes_05() -> void:
	## Plan que no existe o lleno.
	_comprobar(_e.asignar_individual(_u, "no_existe").contains("no existe") and _e.asignar_individual(null, "penales") == "no hay jugador", "planes inexistentes o sin jugador")

func _probar_entrenamiento_semana_y_planes_06() -> void:
	## Pretemporada.
	_c.saldo = 0
	_comprobar(_e.elegir_pretemporada("nada", _c) == "esa pretemporada no existe", "pretemporada inexistente")
	_comprobar(_e.elegir_pretemporada("dura", _c).begins_with("no hay caja"), "sin caja no hay pretemporada exigente")
	_c.saldo = 900000000
	var gastos: Array = []
	_e.gasto.connect(func(cn: String, mo: int) -> void: gastos.append([cn, mo]))
	var fis0: Array = _c.plantilla.map(func(x: Jugador) -> int: return x.fisico)
	_comprobar(_e.elegir_pretemporada("dura", _c, _m.anio, _m.semana) == "" and _e.pretemporada == "dura" and gastos.size() == 1, "pretemporada exigente: se hace y se cobra")
	var sube := 0
	for i in _c.plantilla.size():
		if _c.plantilla[i].fisico >= int(fis0[i]):
			sube += 1
	_comprobar(sube == _c.plantilla.size(), "el físico nunca baja con la pretemporada")
	_comprobar(_e.elegir_pretemporada("suave", _c) == "la pretemporada de este año ya está hecha", "solo una por año")
	_e.reiniciar_pretemporada()
	_comprobar(_e.pretemporada == "" and _e.elegir_pretemporada("suave", _c) == "" and gastos.size() == 1, "al año siguiente se elige otra (la suave es gratis)")

func _probar_entrenamiento_semana_y_planes_07() -> void:
	## Semana completa: el punto de entrenador llega cada 10 semanas y la concentración cuesta.
	_e.concentracion = true
	_e.semanas_trabajadas = Entrenamiento.SEMANAS_POR_PUNTO_DT - 1
	var puntos0 = _e.dt_puntos
	var saldo0 = _c.saldo
	var r = _e.procesar_semana(_c, _m.anio, _m.semana)
	_comprobar(bool(r["punto_dt"]) and _e.dt_puntos == puntos0 + 1 and _c.saldo < saldo0, "décima semana: +1 punto de entrenador y la concentración se paga")
	r = _e.procesar_semana(_c, _m.anio, _m.semana)
	_comprobar(not bool(r["punto_dt"]) and _e.dt_puntos == puntos0 + 1, "la siguiente no da punto")
	_comprobar(_e.procesar_semana(null)["subieron"].is_empty(), "sin club no hace nada")
	var fuera = _c.plantilla.filter(func(j: Jugador) -> bool: return j.fisico < 10 or j.fisico > 100 or j.ovr < 1 or j.ovr > 99)
	_comprobar(fuera.is_empty(), "tras las semanas de entreno nadie queda con físico o media fuera de rango (%d)" % fuera.size())

func _probar_entrenamiento_semana_y_planes_08() -> void:
	## Al límite: con la intensidad alta y mucha suerte alguien se lesiona (se repite hasta que pase).
	_e.intensidad = "alta"
	_e.concentracion = false
	var lesion := false
	for i in 120:
		var rr = _e.procesar_semana(_c, _m.anio, _m.semana)
		if not (rr["lesionados"] as Array).is_empty():
			lesion = true
			break
	_comprobar(lesion and _avisos.any(func(t: String) -> bool: return t == "Lesión en entrenamiento"), "entrenar al límite acaba cobrándose una lesión (en 120 semanas)")

func _probar_entrenamiento_semana_y_planes_09() -> void:
	## Ajenos: no se pasan de rango y los veteranos se apagan con el tiempo.
	var ajeno: Jugador = _m.ligas[0].clubes[7].plantilla[2]
	var vet: Jugador = _m.ligas[0].clubes[7].plantilla[4]
	vet.edad = 35
	vet.ovr = 70
	var ovr0 := vet.ovr
	for i in 400:
		_e.procesar_ajeno(ajeno)
		_e.procesar_ajeno(vet)
	_comprobar(vet.ovr < ovr0 and vet.ovr >= 45, "un veterano de 35 pierde media con los años y no baja de 45 (%d → %d)" % [ovr0, vet.ovr])
	_comprobar(ajeno.fisico >= 10 and ajeno.fisico <= 100 and ajeno.ovr <= 99, "un ajeno sigue dentro de rango")

func _probar_medicion_calculos() -> void:
	_titulo("MEDICIÓN: ESTADÍSTICAS DE LAS MUESTRAS, DURACIONES, CIERRE DE PARTE Y MSAA (sin abrir el juego)")
	var md := Medicion.new()
	_comprobar(not Medicion.pedida() or Medicion.forzada or "--medir" in OS.get_cmdline_user_args() or "--benchmark" in OS.get_cmdline_user_args(), "pedida(): solo con --medir, --benchmark o el botón")
	var largo0 := Medicion.largo
	Medicion.largo = true
	_comprobar(Medicion.es_largo(), "es_largo(): el botón de Ajustes lo activa")
	Medicion.largo = false
	_comprobar(Medicion.es_largo() == ("--benchmark" in OS.get_cmdline_user_args()), "es_largo(): apagado, solo lo dice --benchmark")
	Medicion.largo = largo0
	## Columnas: [cpu, llamadas, triángulos, objetos, memoria, vídeo]
	md._muestras = [[1.0, 100, 1000, 10, 50.0, 20.0], [3.0, 300, 9000, 30, 70.0, 40.0], [2.0, 200, 2000, 20, 60.0, 30.0], [6.0, 600, 3000, 60, 80.0, 50.0]]
	_comprobar(is_equal_approx(md._media_col(0), 3.0) and is_equal_approx(md._media_col(4), 65.0), "_media_col(): media de la columna")
	_comprobar(is_equal_approx(md._max_col(2), 9000.0) and is_equal_approx(md._max_col(1), 600.0), "_max_col(): el máximo")
	_comprobar(is_equal_approx(md._mediana_col(2), 2000.0), "_mediana_col(): la mediana BAJA con número par de muestras (1000, 2000, 3000, 9000 → 2000)")
	md._muestras = [[0, 7, 0, 0, 0, 0], [0, 5, 0, 0, 0, 0], [0, 9, 0, 0, 0, 0]]
	_comprobar(is_equal_approx(md._mediana_col(1), 7.0), "_mediana_col(): impar, la del medio (7) aunque lleguen desordenadas")
	md._muestras = []
	_comprobar(is_zero_approx(md._mediana_col(1)) and is_zero_approx(md._media_col(1)) and is_zero_approx(md._max_col(1)), "sin muestras todo da 0 (sin dividir por cero)")
	_comprobar(absf(md._fps_de([10.0, 10.0]) - 100.0) < 0.001 and absf(md._fps_de([20.0, 10.0, 30.0]) - 50.0) < 0.001, "_fps_de(): 1000 / ms medio")
	_comprobar(md._fps_de([]) > 0.0, "_fps_de([]) no divide por cero")
	## Duración por parte.
	md._parte = "estadio MÍNIMA al 50 %"
	_comprobar(md._duracion() == Medicion.SEG_BARRIDO, "el barrido dura 10 s")
	md._parte = "menú"
	Medicion.largo = false
	_comprobar(md._duracion() == Medicion.SEGUNDOS_POR_PARTE, "modo corto: 8 s")
	Medicion.largo = true
	_comprobar(md._duracion() == Medicion.SEG_LARGO_OTRAS, "modo largo: 20 s en menú y ciudad")
	md._parte = "estadio TV"
	_comprobar(md._duracion() == Medicion.SEG_LARGO_PARTIDO, "modo largo: el partido 180 s")
	Medicion.largo = false
	md.largo = false
	## Cierre de parte: 3 primeros fotogramas fuera, media, 1 % peor y mínimo.
	md._parte = "prueba"
	md._frames = PackedFloat32Array([50.0, 50.0, 50.0, 10.0, 10.0, 10.0, 10.0, 20.0])
	md._muestras = [[2.0, 100, 1000, 10, 50.0, 20.0], [4.0, 300, 3000, 30, 70.0, 40.0], [4.0, 200, 2000, 20, 60.0, 30.0]]
	md._cerrar_parte()
	var d: Dictionary = (md._json["partes"] as Array)[0]
	_comprobar(String(d["parte"]) == "prueba" and int(d["fotogramas"]) == 5 and absf(float(d["fps_medio"]) - 83.3) < 0.2, "fps_medio sin los 3 primeros fotogramas: quedan 5, media de 12 ms = 83,3 FPS (%s)" % str(d["fps_medio"]))
	_comprobar(is_equal_approx(float(d["peor_ms"]), 20.0) and is_equal_approx(float(d["fps_min"]), 50.0) and is_equal_approx(float(d["fps_p1"]), 50.0), "peor fotograma 20 ms = 50 FPS")
	_comprobar(int(d["llamadas"]) == 200 and int(d["triangulos"]) == 2000 and int(d["triangulos_max"]) == 3000 and int(d["muestras"]) == 3 and is_equal_approx(float(d["cpu_ms"]), 3.33), "la mediana para llamadas y triángulos, el máximo aparte y la media para la CPU")
	_comprobar(md._muestras.is_empty() and not d.has("caida_pct"), "tras cerrar se vacían las muestras; sin modo largo no hay calor")
	md._frames = PackedFloat32Array([1.0, 1.0, 1.0])
	md._cerrar_parte()
	_comprobar((md._json["partes"] as Array).size() == 1, "una parte sin fotogramas útiles no se anota")
	## Modo largo: el primer tercio contra el último (se apaga el calor).
	md.largo = true
	var fr := PackedFloat32Array([9.0, 9.0, 9.0])
	for i in 50:
		fr.append(10.0)
	for i in 50:
		fr.append(20.0)
	md._parte = "largo"
	md._frames = fr
	md._muestras = [[1.0, 1, 1, 1, 1.0, 1.0]]
	md._cerrar_parte()
	var dl: Dictionary = (md._json["partes"] as Array)[1]
	_comprobar(dl.has("caida_pct") and is_equal_approx(float(dl["fps_primer_tercio"]), 100.0) and is_equal_approx(float(dl["fps_ultimo_tercio"]), 50.0) and is_equal_approx(float(dl["caida_pct"]), 50.0), "modo largo: de 100 a 50 FPS = caída del 50 %")
	md.largo = false
	## Resumen del MSAA.
	md._json["partes"] = [{"parte": "estadio MÍNIMA al 50 % con MSAA", "fps_medio": 40.0}, {"parte": "estadio MÍNIMA al 50 % sin MSAA", "fps_medio": 50.0},
		{"parte": "estadio MÍNIMA al 70 % con MSAA", "fps_medio": 30.0}, {"parte": "estadio MÍNIMA al 70 % sin MSAA", "fps_medio": 27.0}, {"parte": "menú", "fps_medio": 99.0}]
	md._resumen_msaa()
	_comprobar(md._json.has("msaa_50") and is_equal_approx(md._json["msaa_50"]["gana_pct"], 25.0) and is_equal_approx(md._json["msaa_70"]["gana_pct"], -10.0) and not md._json.has("msaa_menú"), "MSAA: apagarlo gana 25 % a la escala 50 y pierde 10 % a la 70")
	var inf := md._informe
	_comprobar(inf.size() >= 2 and inf[inf.size() - 2].contains("gana") and inf[inf.size() - 1].contains("pierde"), "el informe dice «gana» o «pierde» según el caso")
	md.free()
