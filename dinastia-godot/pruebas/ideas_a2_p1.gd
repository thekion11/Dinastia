extends "res://pruebas/ideas_base.gd"
## (Parte 1 de 2 de `ideas_a2.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `ideas_a2.gd`, conserva la clase.)

## Ideas del dueño (lote a, a2): entrenamiento, ojeo y cantera.

var _cn: Cantera

var _ar
var _ejemplo
var _en
var _j
var _obj
var _oj

func ejecutar() -> void:
	_ideas_a_entrenamiento()
	_ideas_a_ojeo()
	_ideas_a_regens()
	_ideas_a_linajes()

func _ideas_a_entrenamiento() -> void:
	var m := _mundo_ideas(2611)
	var c := m.mi_club()
	c.mover_saldo(900000000)
	_en = m.entrenamiento
	_ideas_a_entrenamiento_01(m, c)
	_ideas_a_entrenamiento_02(m, c)
	_ideas_a_entrenamiento_03(m, c)
	_ideas_a_entrenamiento_04(m, c)
	_ideas_a_entrenamiento_05(m, c)

func _ideas_a_entrenamiento_01(m: Mundo, c: Club) -> void:
	## Reconversión (420): permanente, cambia el puesto y deja semanas de adaptación.
	var lat: Jugador = null
	for _j: Jugador in c.plantilla:
		if _j.pos_e == "DFC":
			lat = _j
			break
	var media_antes := lat.media_en_puesto("LI")
	var r := lat.reconvertir("LI")
	_comprobar(not r.is_empty() and lat.pos_e == "LI" and lat.adapt >= 3 and int(r["semanas"]) == lat.adapt, "un central se reconvierte a lateral y queda adaptándose (%d sem) (420)" % lat.adapt)
	_comprobar(lat.reconvertir("LI").is_empty() and lat.reconvertir("POR").is_empty(), "no se reconvierte al mismo puesto ni cruzando la frontera de portero (420)")
	_comprobar(lat.aptitud_en("DFC") < 1.0 and media_antes <= lat.ovr_en_puesto("DFC") + 30, "y el puesto anterior pasa a ser secundario o menos natural (420)")

func _ideas_a_entrenamiento_02(m: Mundo, c: Club) -> void:
	## Habilidades (421).
	var j1: Jugador = c.plantilla[3]
	for jc: Jugador in c.plantilla:   ## (10-11) uno que aún no lo tenga (con las ligas reales, el 4.º puede traerlo de serie)
		if not _en.tiene_habilidad(jc, "cabezazo"):
			j1 = jc
			break
	var ef0 = Tactica.efectividad([j1], ["cabezazo"], _en)
	_comprobar(not _en.tiene_habilidad(j1, "cabezazo") and _en.dar_habilidad(j1, "cabezazo") and _en.tiene_habilidad(j1, "cabezazo"), "se entrena el cabeceo y el jugador lo tiene (421)")
	_comprobar(not _en.dar_habilidad(j1, "cabezazo") and not _en.dar_habilidad(j1, "inventada"), "ni se repite ni existe una inventada (421)")
	_comprobar(Tactica.efectividad([j1], ["cabezazo"], _en) > ef0, "y sube la efectividad de las jugadas que lo piden (421)")
	for k: String in ["tiroLibre", "penalero", "corner", "cabezazo", "latigo", "atajaPen"]:
		_comprobar(_en.nombre_habilidad(k) != k, "la habilidad «%s» tiene nombre legible (421)" % k)

func _ideas_a_entrenamiento_03(m: Mundo, c: Club) -> void:
	## Curva de edad (422): el joven con margen sube; el de 30 no.
	var jov := Jugador.new()
	jov.edad = 19
	var vet := Jugador.new()
	vet.edad = 30
	for x: Jugador in [jov, vet]:
		x.ovr = 60
		x.pot = 85
		x.pos_e = "MC"
		x.club_id = c.id
		x.generar_atributos()
		x.ovr = 60
	var cj := Club.new()
	cj.id = "club_prueba"
	cj.plantilla = [jov, vet]
	var ganancia_joven := 0
	var ganancia_vet := 0
	var en2 := Entrenamiento.new(Staff.new(), Instalaciones.new())
	for sem in 60:
		en2.procesar_semana(cj, m.anio, sem % 38 + 1)
	ganancia_joven = jov.ovr - 60
	ganancia_vet = vet.ovr - 60
	_comprobar(ganancia_joven >= 1 and ganancia_joven > ganancia_vet, "en 60 semanas el de 19 años sube %d y el de 30 %d (422)" % [ganancia_joven, ganancia_vet])

func _ideas_a_entrenamiento_04(m: Mundo, c: Club) -> void:
	## Instalaciones: el centro de entrenamiento multiplica el progreso (442).
	var obras := Instalaciones.new()
	var base := obras.ritmo_de_progreso()
	var cc := Club.new()
	cc.saldo = 900000000
	cc.rep = 60
	for i in 3:
		obras.iniciar("ct", cc)
		for k in obras.semanas_de("ct") + 1:
			obras.avanzar_semana(cc)
	_comprobar(is_equal_approx(base, 1.0) and obras.ritmo_de_progreso() > base, "con el centro de entrenamiento el ritmo de progreso pasa de 1,0 a %.2f (442)" % obras.ritmo_de_progreso())
	var subidas := []
	for obr in [Instalaciones.new(), obras]:
		var jj := Jugador.new()
		jj.edad = 18
		jj.pos_e = "MC"
		jj.generar_atributos()
		jj.ovr = 50
		jj.pot = 95
		var cl := Club.new()
		cl.id = "x"
		cl.plantilla = [jj]
		var e3 := Entrenamiento.new(Staff.new(), obr)
		var total := 0
		for rep in 8:
			jj.ovr = 50
			e3._subidas.clear()   ## cada repetición es una temporada nueva (el tope de +6 por temporada del entrenamiento se cuenta aparte)
			Azar.sembrar(700 + rep)
			for sem in 40:
				e3.procesar_semana(cl, 2030, sem % 38 + 1)
			total += jj.ovr - 50
		subidas.append(total)
	_comprobar(subidas[1] > subidas[0], "y en 8 repeticiones de 40 semanas el joven con centro sube más (%d contra %d puntos) (442)" % [subidas[1], subidas[0]])

func _ideas_a_entrenamiento_05(m: Mundo, c: Club) -> void:
	## Mentorías (443): el veterano apadrina y el pupilo mejora.
	var vet2: Jugador = null
	var pup: Jugador = null
	for _j: Jugador in c.plantilla:
		if vet2 == null and _j.edad >= 29 and _j.ovr >= 62:
			vet2 = _j
		elif pup == null and _j.edad <= 21:
			pup = _j
	if vet2 == null:
		vet2 = c.plantilla[5]
		vet2.edad = 33
		vet2.ovr = 70
	if pup == null:
		pup = c.plantilla[6]
		pup.edad = 18
	pup.pot = 99
	pup.ovr = 50
	var moral0 := pup.moral
	_comprobar(_en.crear_mentoria(vet2, pup) == "" and pup.moral > moral0 and _en.mentorias.size() == 1, "un veterano apadrina a un juvenil y a este le sube la moral (443)")
	_comprobar(_en.crear_mentoria(vet2, pup) != "", "pero no se puede repetir la misma pareja (443)")
	for sem in 80:
		_en.procesar_semana(c, m.anio, sem % 38 + 1)
	_comprobar(_en.mentorias.is_empty() or int(_en.mentorias[0]["subidas"]) >= 1, "tras 80 semanas la mentoría dio subidas al pupilo (443)")
	_comprobar(pup.ovr > 50, "y el pupilo mejoró su media (50 → %d) (443)" % pup.ovr)


func _ideas_a_ojeo() -> void:
	var m := _mundo_ideas(2612)
	var c := m.mi_club()
	c.mover_saldo(900000000)
	_oj = m.ojeadores
	_ideas_a_ojeo_01(m, c)
	_ideas_a_ojeo_02(m, c)
	_ideas_a_ojeo_03(m, c)
	_ideas_a_ojeo_04(m, c)
	_ideas_a_ojeo_05(m, c)
	_ideas_a_ojeo_06(m, c)

func _ideas_a_ojeo_01(m: Mundo, c: Club) -> void:
	## Sin jefe de ojeadores no hay red (446).
	_comprobar(_oj.alternar_pais("ARG") != "" and not _oj.cubre("ARG"), "sin jefe de ojeadores no se puede cubrir un país (446)")
	_comprobar(m.staff.subir("ojeador", c) == "", "se contrata al jefe de ojeadores")
	_comprobar(_oj.alternar_pais("ARG") == "" and _oj.cubre("ARG") and _oj.ojeadores["ARG"].has("espec") and _oj.ojeadores["ARG"].has("precision"), "se contrata un ojeador para Argentina con especialidad y precisión (446)")
	_ar = null
	for k: Club in m.clubes.values():
		if k.pais == "ARG":
			_ar = k
			break
	_obj = _ar.plantilla[2]
	var nivel_cubierto = _oj.nivel_de(_obj)
	_oj.alternar_pais("ARG")
	_comprobar(not _oj.cubre("ARG") and _oj.nivel_de(_obj) < nivel_cubierto, "retirar al ojeador baja lo que sabes del país (446)")

func _ideas_a_ojeo_02(m: Mundo, c: Club) -> void:
	## Rangos de incertidumbre (448) y base revelada con el ojeo (453).
	var txt = _oj.ovr_texto(_obj)
	_comprobar(txt.contains("-"), "de un jugador ajeno sin cobertura se ve un rango, no la media exacta: «%s» (448)" % txt)
	var partes = txt.split("-")
	_comprobar(int(partes[0]) <= _obj.ovr and int(partes[1]) >= _obj.ovr, "y el rango contiene la media real %d (448)" % _obj.ovr)
	_comprobar(_oj.ovr_texto(c.plantilla[0]) == str(c.plantilla[0].ovr), "los jugadores propios se ven exactos (448)")
	_comprobar(_oj.ovr_texto(_obj) == txt, "el rango es estable entre consultas (448)")
	var presu = _oj.presupuesto
	var saldo := c.saldo
	_comprobar(_oj.ojear(_obj) == "" and m.ojeados.has(_obj.id) and _oj.ovr_texto(_obj) == str(_obj.ovr), "al ojearlo la media se revela exacta (453)")
	_comprobar(_oj.presupuesto == presu - _oj.costo_informe() and c.saldo == saldo, "el ojeo sale del presupuesto de scouting y no de la caja de fichajes (468)")
	_comprobar(_oj.ojear(_obj) != "", "no se ojea dos veces (453)")
	_oj.modo_ciego = true
	var otro: Jugador = _ar.plantilla[3]
	_comprobar(not _oj.ovr_texto(otro).contains("-") and _oj.ovr_texto(otro) != str(otro.ovr), "en modo ciego se ve una palabra y no un número (448)")
	_oj.modo_ciego = false
	_oj.presupuesto = 0
	var otro2: Jugador = _ar.plantilla[4]
	var s1 := c.saldo
	_oj.ojear(otro2)
	_comprobar(c.saldo == s1 - _oj.costo_informe(), "sin presupuesto de ojeo se paga con la caja del club (468)")

func _ideas_a_ojeo_03(m: Mundo, c: Club) -> void:
	## Sesgos y precisión de cada ojeador (449, 450).
	for k: String in ["opt", "pes", "fiel", "vende"]:
		_comprobar(Ojeadores.SESGOS.has(k) and String(Ojeadores.SESGOS[k]["desc"]) != "", "existe el sesgo «%s» (449)" % k)
	var lejano: Jugador = _ar.plantilla[5]
	_oj.ojeadores["ARG"] = {"sesgo": "fiel", "precision": 2, "espec": "juveniles", "informes": 0, "ignorados": 0, "humor": 70, "nombre": "A", "pais": "ARG"}
	var fiel = _oj.ovr_aproximado(lejano)
	_oj.ojeadores["ARG"]["sesgo"] = "vende"
	var vende = _oj.ovr_aproximado(lejano)
	_oj.ojeadores["ARG"]["sesgo"] = "pes"
	var pes = _oj.ovr_aproximado(lejano)
	_comprobar(_oj.sesgo_de("ARG") == -2 and vende > fiel and fiel > pes, "el vendedor exagera (%d) frente al ecuánime (%d) y el desconfiado (%d) (449, 450)" % [vende, fiel, pes])

func _ideas_a_ojeo_04(m: Mundo, c: Club) -> void:
	## Ojeador que renuncia (466).
	_oj.ojeadores["ARG"]["ignorados"] = 20
	_oj.ojeadores["ARG"]["informes"] = 2
	_oj.ojeadores["ARG"]["humor"] = 70
	_oj.red["ARG"] = 1
	var sem := 0
	while _oj.ojeadores.has("ARG") and sem < 40:
		_oj.procesar_semana()
		sem += 1
	_comprobar(not _oj.ojeadores.has("ARG") and not _oj.cubre("ARG") and sem >= 10 and sem <= 25, "si ignoras sus informes el ojeador renuncia a las %d semanas (466)" % sem)

func _ideas_a_ojeo_05(m: Mundo, c: Club) -> void:
	## Informe de personalidad (461) y médico (462).
	var tipo: Jugador = _ar.plantilla[6]
	var caja := c.saldo
	_comprobar(_oj.informe_personalidad(tipo, c) == "" and c.saldo < caja, "el informe de personalidad se paga (461)")
	var ip = _oj.informe_personalidad_de(tipo)
	_comprobar(ip.has("prof") and ip.has("vestuario") and ip.has("mudanza") and int(ip["prof"]) >= 0, "e informa de profesionalidad, vestuario y mudanza (461)")
	_comprobar(_oj.informe_personalidad(tipo, c) != "", "y no se encarga dos veces (461)")
	var inf := m.medico.informe_de(tipo)
	_comprobar(inf is Dictionary and m.medico.costo_informe(tipo, c.rep) > 0, "el informe médico previo al fichaje existe y cuesta %d (462)" % m.medico.costo_informe(tipo, c.rep))

func _ideas_a_ojeo_06(m: Mundo, c: Club) -> void:
	## Departamento de análisis (469, 470, 471).
	_comprobar(_oj.mejorar_analitica(c) == "" and _oj.analitica_nivel == 1, "se amplía el departamento de análisis de datos (469)")
	_oj.mejorar_analitica(c)
	_oj.mejorar_analitica(c)
	_comprobar(_oj.analitica_nivel == 3 and _oj.mejorar_analitica(c) != "", "hasta un máximo de tres niveles (469)")
	for i in 120:
		_oj.semana_analitica(0)
	var vivos = _oj.hallazgos_vivos()
	_comprobar(vivos.size() >= 1 and vivos.size() <= 8, "el modelo propio del club señala hallazgos infravalorados (%d) (470)" % vivos.size())
	var h0: Jugador = vivos[0]["jugador"]
	_comprobar(h0.edad <= 24 and h0.pot - h0.ovr >= 10, "joven y con margen de crecimiento (470)")
	_comprobar(_oj.analitica_tension == 0, "con ojeador novato no hay tensión (471)")
	for i in 120:
		_oj.semana_analitica(3)
	_comprobar(_oj.analitica_tension > 0 and _oj.analitica_avisado, "con un jefe de ojeadores veterano la tensión con los analistas sube hasta la guerra (471): %d" % _oj.analitica_tension)


func _ideas_a_regens() -> void:
	var m := _mundo_ideas(2613)
	var c := m.mi_club()
	_cn = m.cantera
	_ideas_a_regens_01(m, c)
	_ideas_a_regens_02(m, c)
	_ideas_a_regens_03(m, c)
	_ideas_a_regens_04(m, c)

func _ideas_a_regens_01(m: Mundo, c: Club) -> void:
	## Regens (476): al cerrar la temporada hay retiros y llega una camada de juveniles.
	var antes := c.plantilla.size()
	m.nueva_temporada()
	var nuevos := 0
	for id: String in _cn.ultima_camada:
		if m.jugador_por_id(id) != null:
			nuevos += 1
	_comprobar(_cn.ultima_camada.size() >= 1 and nuevos == _cn.ultima_camada.size(), "cada temporada llega una camada de %d regens a la plantilla (476)" % nuevos)
	_comprobar(c.plantilla.size() >= antes - 6 and c.plantilla.size() >= 18, "y la plantilla conserva su tamaño tras los retiros (%d → %d) (476)" % [antes, c.plantilla.size()])
	_j = m.jugador_por_id(_cn.ultima_camada[0])
	_comprobar(_j.edad <= 21, "los regens son chicos (%d años) (476)" % _j.edad)

func _ideas_a_regens_02(m: Mundo, c: Club) -> void:
	## Origen y biografía (497, 498, 499).
	_cn._sortear_origen(_j)
	var o = _cn.origen_de(_j)
	_comprobar(not o.is_empty() and String(o["frase"]) != "" and String(o["historia"]) != "", "cada regen tiene una historia de origen: %s (497)" % String(o.get("id", "")))
	var tipos := {}
	for x: Jugador in c.plantilla:
		_cn._sortear_origen(x)
		tipos[String(_cn.origen_de(x).get("id", ""))] = true
	_comprobar(tipos.size() >= 3 and not tipos.has(""), "los orígenes son variados (%d distintos) (497)" % tipos.size())
	var bio = FichaJugadorInfo.bio_de(_j, m)
	_comprobar(bio.begins_with("Debutó a los") and bio.length() > 30, "la ficha trae una biografía autogenerada: «%s» (498)" % bio.left(60))
	_comprobar(FichaJugadorInfo.bio_de(_j, m) == bio, "y es estable (498)")
	var l1 = Cara.look_de(_j)
	_comprobar(not l1.is_empty() and Cara.look_de(_j) == l1, "el avatar procedural es determinista para el mismo jugador (499)")
	var distintos := {}
	for x: Jugador in c.plantilla:
		distintos[str(Cara.look_de(x))] = true
	_comprobar(distintos.size() >= c.plantilla.size() / 2, "y distinto entre jugadores (%d looks en %d jugadores) (499)" % [distintos.size(), c.plantilla.size()])

func _ideas_a_regens_03(m: Mundo, c: Club) -> void:
	## Inversión _en cantera (495).
	m.mi_club().mover_saldo(900000000)
	var b0 := _cn.bono_de_camada()
	for k: String in ["acad", "resid"]:
		m.obras.iniciar(k, c)
		for i in m.obras.semanas_de(k) + 1:
			m.obras.avanzar_semana(c)
	m.staff.subir("cantera", c)
	_comprobar(_cn.bono_de_camada() > b0, "academia y residencia suben el techo de la camada (%d → %d) (495)" % [b0, _cn.bono_de_camada()])
	m.roles.prestigio = 90
	var alto := _cn.multiplicador_de_reputacion()
	m.roles.prestigio = 30
	_comprobar(alto > _cn.multiplicador_de_reputacion(), "y el prestigio del entrenador atrae mejores camadas (495)")

func _ideas_a_regens_04(m: Mundo, c: Club) -> void:
	## Épocas doradas y decadencia (491, 492).
	var er: Eras = m.eras
	er.activas.clear()
	var doradas := 0
	for i in 60:
		er.activas.clear()
		er.cierre_de_temporada()
		for p: String in er.activas:
			if er.activas[p]["tipo"] == "dorada":
				doradas += 1
				if doradas == 1:
					_comprobar(er.bono(p, m.anio) == Eras.BONO_DORADA and er.mapa_del_talento(m.anio).size() >= 1, "una época dorada sube un 13%% el techo de los juveniles de %s (491)" % p)
	_comprobar(doradas >= 3, "con los años aparecen épocas doradas (%d en 60 cierres) (491)" % doradas)
	for k: Club in m.clubes.values():
		k.saldo = 0
	var decad := 0
	for i in 80:
		er.activas.clear()
		er.cierre_de_temporada()
		for p: String in er.activas:
			if er.activas[p]["tipo"] == "decadencia":
				decad += 1
				if decad == 1:
					_comprobar(er.bono(p, m.anio) == Eras.BONO_DECADENCIA, "un país arruinado entra en decadencia y su techo baja al 90%% (%s) (492)" % p)
	_comprobar(decad >= 3, "con las ligas arruinadas aparece decadencia (%d en 80 cierres) (492)" % decad)
	for k: Club in m.clubes.values():
		k.saldo = 900000000
	var d2 := 0
	for i in 60:
		er.activas.clear()
		er.cierre_de_temporada()
		for p: String in er.activas:
			if er.activas[p]["tipo"] == "decadencia":
				d2 += 1
	_comprobar(d2 == 0, "pero un país rico nunca cae en decadencia por sorteo (492)")


func _ideas_a_linajes() -> void:
	var m := _mundo_ideas(2614)
	var c := m.mi_club()
	_cn = m.cantera
	_cn.leyendas.clear()
	_ideas_a_linajes_01(m, c)
	_ideas_a_linajes_02(m, c)
	_ideas_a_linajes_03(m, c)
	call(&"_ideas_a_linajes_04", m, c)
	call(&"_ideas_a_linajes_05", m, c)

func _ideas_a_linajes_01(m: Mundo, c: Club) -> void:
	## Hijos de leyendas (477, 479, 480, 481, 502).
	while c.plantilla.size() > 22:
		c.plantilla.pop_back()
	var clubes_l: Array = m.clubes.values()
	var n := 40
	var con_apellido := 0
	var mismo_grupo := 0
	var en_club := 0
	var hallados := 0
	_ejemplo = null
	for i in n:
		var padre := "Mauricio Zambrano%d" % i
		_cn.leyendas.append({"nombre": padre, "club_id": (clubes_l[i % 30] as Club).id, "pos": "DEL", "nivel": 90, "anio_hijo": m.anio, "usado": false})
	_cn._hijos_de_leyendas()
	for k: Club in m.clubes.values():
		for _j: Jugador in k.plantilla:
			var lin = _cn.linaje_de(_j)
			if lin.is_empty() or not String(lin["padre"]).begins_with("Mauricio Zambrano"):
				continue
			hallados += 1
			_ejemplo = _j
			if _j.nombre.ends_with(" Zambrano%d" % int(String(lin["padre"]).substr(17))):
				con_apellido += 1
			if _j.pos == "DEL":
				mismo_grupo += 1
			if k.id == (clubes_l[int(String(lin["padre"]).substr(17)) % 30] as Club).id:
				en_club += 1
	_comprobar(hallados >= 30 and con_apellido == hallados, "los hijos de leyendas heredan el apellido (%d de %d) (477)" % [con_apellido, hallados])
	_comprobar(float(mismo_grupo) / float(hallados) >= 0.55, "la mayoría juega en la posición del padre (%d de %d) (479)" % [mismo_grupo, hallados])
	_comprobar(float(en_club) / float(hallados) >= 0.55, "la mayoría debuta en el club donde su padre fue leyenda (%d de %d) (480)" % [en_club, hallados])
	_comprobar(not _cn.etiqueta_de(_ejemplo).is_empty() and String(_cn.etiqueta_de(_ejemplo)["ref"]).begins_with("Mauricio"), "al hijo le cuelgan la etiqueta «el nuevo [padre]» (481, 502)")
	_comprobar(_ejemplo.pot >= _ejemplo.ovr + 4 and _ejemplo.edad <= 17, "y llega con techo de proyección y 16-17 años (477)")

func _ideas_a_linajes_02(m: Mundo, c: Club) -> void:
	## Familias (508).
	var fams := _cn.familias()
	var hay := false
	for k: String in fams:
		if k.begins_with("L:Mauricio Zambrano") and (fams[k] as Array).size() >= 1:
			hay = true
	_comprobar(hay, "el árbol de familias agrupa a los hijos por su padre (508)")

func _ideas_a_linajes_03(m: Mundo, c: Club) -> void:
	## Nietos (484): el hijo retirado con linaje entra _en el libro aunque su media sea baja.
	_ejemplo.ovr = 55
	var l0 := _cn.leyendas.size()
	_comprobar(_cn.registrar_retiro(_ejemplo, c) and _cn.leyendas.size() == l0 + 1, "un retirado con linaje entra en el libro de leyendas aunque sea modesto: hay nietos (484)")
	var anonimo := Jugador.new()
	anonimo.ovr = 55
	_comprobar(not _cn.registrar_retiro(anonimo, c), "y uno corriente sin linaje no (484)")
