extends "res://pruebas/banco/cobertura_p1.gd"
## [Banco · grupo «cobertura»] (18-11) Pruebas de COMPORTAMIENTO de clases que el banco casi no tocaba (informe
## `docs/04_auditorias/cobertura_lineas_2026-11-18.md`). Esta capa: las citas en persona (nacimiento, caducidad,
## lecturas, resolución y guardado) y el pulso de roles. La capa 1 (`cobertura_p1.gd`): actualizador, entrada al campeonato y roles.

var _a
var _c
var _ci
var _m: Mundo
var _m6
var _prox
var _q
var _r
var _vistas: Array[String]

func _mundo_citas(semilla: int, pais: String, quien := 3) -> Mundo:
	_m = Mundo.new()
	_m.generar([pais], semilla)
	_m.tomar_el_mando(_m.ligas[0].clubes[quien].id)
	_m.citas = Citas.new()
	return _m

func _probar_citas_nacen_y_caducan() -> void:
	_titulo("CITAS: NACEN DE LO QUE PASA, CADUCAN EL DOMINGO Y TIENEN TOPE")
	var rep1_a = Citas.nombre_ficticio("a|b"); var rep1_b = Citas.nombre_ficticio("a|b")
	_comprobar(rep1_a == rep1_b and rep1_a != Citas.nombre_ficticio("x|y"), "nombre_ficticio(): determinista por semilla y distinto entre semillas")
	_m = _mundo_citas(9001, "ESP")
	_ci = _m.citas
	_c = _m.mi_club()
	_vistas = []
	_ci.noticia.connect(func(t: String, _x: String) -> void: _vistas.append(t))
	_ci.semana(_m, _m.semana + 1)
	_comprobar(_ci.lista.size() <= Citas.MAX_SEMANA, "sin nada que pase no nacen más que el tope de citas: %d" % _ci.lista.size())
	_ci.lista.clear()
	_probar_citas_nacen_y_caducan_01()
	_probar_citas_nacen_y_caducan_02()
	_probar_citas_nacen_y_caducan_03()
	_probar_citas_nacen_y_caducan_04()
	_probar_citas_nacen_y_caducan_05()
	_probar_citas_nacen_y_caducan_06()
	_probar_citas_nacen_y_caducan_07()
	_probar_citas_nacen_y_caducan_08()
	_probar_citas_nacen_y_caducan_09()

func _probar_citas_nacen_y_caducan_01() -> void:
	## 1) La junta pide la palabra.
	_m.junta.formar(_c)
	_m.junta.pendiente = {"quien": "Ana Soto", "exige": "titulos", "monto": 0, "tema": "exige el título.", "a": "Prometer", "b": "Paciencia"}
	_prox = _m.semana + 1
	_ci.semana(_m, _prox)
	var junta = _ci.pendientes().filter(func(x: Dictionary) -> bool: return x["tipo"] == "junta")
	_comprobar(junta.size() == 1 and String(junta[0]["asunto"]).contains("Ana Soto") and int(junta[0]["semana"]) == _prox and String(junta[0]["estado"]) == "pendiente", "la junta abierta convoca UNA cita en el despacho")
	_ci.semana(_m, _prox)
	_comprobar(_ci.pendientes().filter(func(x: Dictionary) -> bool: return x["tipo"] == "junta").size() == 1, "no se duplica en la misma semana")
	_comprobar(_vistas.size() >= 1 and _vistas[0].ends_with(Idiomas.t("Cita nueva")), "avisa con una noticia «Cita nueva»")

func _probar_citas_nacen_y_caducan_02() -> void:
	## 2) Patrocinio: la mejor oferta de la primera zona por orden alfabético (se parte de la agenda vacía).
	_ci.lista.clear()
	_m.comercial.ofertas_zona = {"zb": [{"marca": "Alfa", "color": "#fff", "monto": 100000, "anios": 1}], "za": [{"marca": "Beta", "color": "#fff", "monto": 100000, "anios": 1}, {"marca": "Gamma", "color": "#fff", "monto": 300000, "anios": 2}]}
	_ci.semana(_m, _prox)
	var pat = _ci.pendientes().filter(func(x: Dictionary) -> bool: return x["tipo"] == "patrocinio")
	_comprobar(pat.size() == 1 and String(pat[0]["clave"]) == "za|1", "patrocinio: la zona «za» y su oferta más alta (clave %s)" % (pat[0]["clave"] if not pat.is_empty() else "—"))

func _probar_citas_nacen_y_caducan_03() -> void:
	## 3) Agente.
	_m.mercado_av.superagente = "Jorge Mendes Falso"
	_ci.semana(_m, _prox)
	_comprobar(_ci.pendientes().filter(func(x: Dictionary) -> bool: return x["tipo"] == "agente" and x["quien"] == "Jorge Mendes Falso").size() == 1, "agente: aparece cuando hay superagente")
	_comprobar(_ci.pendientes().size() <= Citas.MAX_SEMANA, "nunca más de 3 citas nacidas en la semana (%d)" % _ci.pendientes().size())

func _probar_citas_nacen_y_caducan_04() -> void:
	## 4) Caducidad: al pasar _a otra semana las pendientes se archivan.
	var ids_viejos: Array = _ci.pendientes().map(func(x: Dictionary) -> String: return String(x["id"]))
	_ci.objetivo = String(ids_viejos[0])
	_ci.semana(_m, _prox + 1)
	var todas_caducadas := true
	for id: String in ids_viejos:
		todas_caducadas = todas_caducadas and String(_ci.por_id(id)["estado"]) == "caducada"
	_comprobar(todas_caducadas and _ci.objetivo == "", "pasada la semana caducan sin castigo y se suelta el «Ir»")

func _probar_citas_nacen_y_caducan_05() -> void:
	## 5) Solo se guardan 12.
	for i in 20:
		_ci._nueva(_m, _prox + 1, "agente", "X%d" % i, "c", "a", "")
	_ci.semana(_m, _prox + 1)
	_comprobar(_ci.lista.size() <= 12 + Citas.MAX_SEMANA, "el historial se recorta (%d)" % _ci.lista.size())

func _probar_citas_nacen_y_caducan_06() -> void:
	## 6) Asamblea: año múltiplo de 4, semana 3.
	var m2 := _mundo_citas(9002, "ARG", 5)
	m2.anio = 2028
	m2.citas.semana(m2, Citas.ASAMBLEA_SEMANA)
	_comprobar(m2.citas.pendientes().any(func(x: Dictionary) -> bool: return x["tipo"] == "asamblea" and int(x["dia"]) == 5), "asamblea: año 2028, semana 3, el sábado")
	var m3 := _mundo_citas(9003, "ARG", 5)
	m3.anio = 2027
	m3.directiva.confianza = 10
	m3.citas.semana(m3, Citas.ASAMBLEA_SEMANA)
	_comprobar(m3.citas.pendientes().any(func(x: Dictionary) -> bool: return x["tipo"] == "asamblea"), "asamblea: confianza por los suelos también la convoca")
	var m4 := _mundo_citas(9004, "ARG", 5)
	m4.anio = 2027
	m4.directiva.confianza = 80
	m4.citas.semana(m4, Citas.ASAMBLEA_SEMANA)
	_comprobar(not m4.citas.pendientes().any(func(x: Dictionary) -> bool: return x["tipo"] == "asamblea"), "asamblea: con confianza alta y año normal, no")

func _probar_citas_nacen_y_caducan_07() -> void:
	## 7) Trofeo nuevo → celebración en el museo.
	var m5 := _mundo_citas(9005, "ITA", 1)
	m5.citas.semana(m5, 2)
	m5.roles.sumar_trofeo("Copa de prueba")
	m5.citas.semana(m5, 3)
	_comprobar(m5.citas.pendientes().any(func(x: Dictionary) -> bool: return x["tipo"] == "celebracion" and int(x["dia"]) == 0), "un trofeo nuevo convoca la celebración el lunes")

func _probar_citas_nacen_y_caducan_08() -> void:
	## 8) Rama de otro deporte pide presupuesto en la semana 5.
	_m6 = _mundo_citas(9006, "ESP", 2)
	var clave := String((Hinchada.RAMAS[1] as Array)[0])
	if not _m6.hinchada.tiene_rama(clave):
		_m6.hinchada.anios_rama[clave] = 1
	var tiene = _m6.hinchada.tiene_rama(clave)
	_m6.citas.semana(_m6, Citas.RAMA_SEMANA)
	_comprobar(not tiene or _m6.citas.pendientes().any(func(x: Dictionary) -> bool: return x["tipo"] == "rama" and x["clave"] == clave), "rama «%s»: su coordinadora pide el extra en la semana 5" % clave)

func _probar_citas_nacen_y_caducan_09() -> void:
	## 9) Sin club no hace nada.
	var vacio := Mundo.new()
	vacio.generar(["CHI"], 9007)
	var cv := Citas.new()
	cv.semana(vacio)
	_comprobar(cv.lista.is_empty(), "sin club propio no nacen citas")

func _probar_citas_lecturas_y_resolucion() -> void:
	_titulo("CITAS: HORA, LUGAR, OPCIONES Y RESOLVER CADA TIPO")
	_m = _mundo_citas(9101, "BRA", 4)
	_ci = _m.citas
	_c = _m.mi_club()
	_m.junta.formar(_c)
	_m.junta.pendiente = {"quien": "Luis Reyes", "exige": "titulos", "monto": 0, "tema": "exige el título.", "a": "Prometer pelear", "b": "Pedir paciencia"}
	_ci._nueva(_m, _m.semana, "junta", "Presi", "Presidente", "tema", "")
	var ct: Dictionary = _ci.lista[0]
	var rel := Reloj.new()
	rel.anio = _m.anio
	rel.semana = _m.semana
	rel.dia = int(ct["dia"])
	rel.minuto = int(ct["hora"]) * 60
	_comprobar(_ci.en_hora(ct, rel), "en hora: su día y su hora")
	rel.minuto = (int(ct["hora"]) + Citas.DURACION) * 60
	_comprobar(not _ci.en_hora(ct, rel), "pasada la duración ya no está")
	rel.minuto = (int(ct["hora"]) - 1) * 60
	_comprobar(not _ci.en_hora(ct, rel), "antes de la hora tampoco")
	rel.minuto = int(ct["hora"]) * 60
	rel.dia = (int(ct["dia"]) + 1) % 7
	_comprobar(not _ci.en_hora(ct, rel) and not _ci.en_hora({}, rel) and not _ci.en_hora(ct, null), "otro día, cita vacía o sin reloj: no")
	_comprobar(_ci.cuando(ct).contains("11:00") and _ci.lugar(ct)["planta"] == 1 and _ci.lugar(ct)["donde"] == "estadio", "cuando() y lugar() de la junta")
	_comprobar(_ci.opciones(_m, ct) == ["Prometer pelear", "Pedir paciencia"], "opciones de la junta: las de la propia junta")
	_comprobar(_ci.por_id("no_existe").is_empty() and _ci.por_id(String(ct["id"]))["tipo"] == "junta", "por_id()")
	for tipo: String in ["patrocinio", "agente", "rama", "celebracion", "asamblea", "entrevista", "politica"]:
		_ci._nueva(_m, _m.semana, tipo, "q", "c", "a", "k")
		var o = _ci.opciones(_m, _ci.lista.back())
		_comprobar(o.size() >= 2 and ((tipo != "asamblea" and tipo != "entrevista") or o.size() == 3), "opciones de «%s»: %d" % [tipo, o.size()])
	_ci.lista.clear()
	_probar_citas_lecturas_y_resolucion_01()
	_probar_citas_lecturas_y_resolucion_02()
	_probar_citas_lecturas_y_resolucion_03()
	_probar_citas_lecturas_y_resolucion_04()
	_probar_citas_lecturas_y_resolucion_05()
	_probar_citas_lecturas_y_resolucion_06()
	_probar_citas_lecturas_y_resolucion_07()
	_probar_citas_lecturas_y_resolucion_08()
	_probar_citas_lecturas_y_resolucion_09()

func _probar_citas_lecturas_y_resolucion_01() -> void:
	## Resolver: junta.
	_ci._nueva(_m, _m.semana, "junta", "Presi", "Presidente", "tema", "")
	var conf0 = _m.directiva.confianza
	_r = _ci.resolver(_m, String(_ci.lista[0]["id"]), 0)
	_comprobar(String(_ci.lista[0]["estado"]) == "hecha" and _r.has("titulo") and _m.directiva.confianza >= conf0 + 1 and _m.junta.pendiente.is_empty(), "junta: se resuelve, +1 de confianza y la junta se cierra")
	_comprobar(_ci.resolver(_m, String(_ci.lista[0]["id"]), 0).is_empty() and _ci.resolver(_m, "no_existe", 0).is_empty(), "una cita hecha o inexistente no se resuelve otra vez")
	_ci._nueva(_m, _m.semana, "junta", "Presi", "Presidente", "tema", "")
	_comprobar(String(_ci.resolver(_m, String(_ci.lista.back()["id"]), 1)["texto"]) != "", "junta sin asunto pendiente: respuesta de cortesía")

func _probar_citas_lecturas_y_resolucion_02() -> void:
	## Patrocinio: firma en persona con +5 %.
	_m.comercial.zonas_firmadas.clear()
	_m.comercial.ofertas_zona = {"za": [{"marca": "Beta", "color": "#fff", "monto": 1000000, "anios": 2}]}
	_ci._nueva(_m, _m.semana, "patrocinio", "Dir", "marketing", "a", "za|0")
	var idp = String(_ci.lista.back()["id"])
	_r = _ci.resolver(_m, idp, 0)
	_comprobar(_m.comercial.zonas_firmadas.has("za") and int(_m.comercial.zonas_firmadas["za"]["monto"]) == 1050000, "patrocinio: la zona se firma con +5 %% (%d)" % int((_m.comercial.zonas_firmadas.get("za", {}) as Dictionary).get("monto", 0)))
	_ci._nueva(_m, _m.semana, "patrocinio", "Dir", "marketing", "a", "za|0")
	_r = _ci.resolver(_m, String(_ci.lista.back()["id"]), 0)
	_comprobar(String(_r["texto"]).length() > 0 and _m.comercial.zonas_firmadas.size() == 1, "patrocinio con la zona ya vendida: avisa y no firma otra")
	_ci._nueva(_m, _m.semana, "patrocinio", "Dir", "marketing", "a", "za|0")
	var zf = _m.comercial.zonas_firmadas.size()
	_r = _ci.resolver(_m, String(_ci.lista.back()["id"]), 1)
	_comprobar(_m.comercial.zonas_firmadas.size() == zf, "patrocinio, «lo pienso»: no firma")

func _probar_citas_lecturas_y_resolucion_03() -> void:
	## Agente.
	_m.mercado_av.superagente = "Ag Ente"
	_ci._nueva(_m, _m.semana, "agente", "Ag Ente", "Agente", "a", "")
	_ci.resolver(_m, String(_ci.lista.back()["id"]), 0)
	_comprobar(_ci.favor_agente == _m.anio * 60 + _m.semana, "agente: escucharlo deja un favor anotado")
	_ci.favor_agente = -1
	_ci._nueva(_m, _m.semana, "agente", "Ag Ente", "Agente", "a", "")
	_ci.resolver(_m, String(_ci.lista.back()["id"]), 1)
	_comprobar(_ci.favor_agente == -1, "agente: rechazarlo no deja favor")

func _probar_citas_lecturas_y_resolucion_04() -> void:
	## Entrevista: moral por tono y por staff.
	var j: Jugador = _c.plantilla[3]
	_ci.entrevista(_m, j)
	var ent: Dictionary = _ci.lista.back()
	_comprobar(ent["tipo"] == "entrevista" and ent["clave"] == j.id and int(ent["dia"]) >= 0 and int(ent["dia"]) <= 5 and ent["quien"] == j.nombre, "entrevista(): cita para el nuevo fichaje")
	j.moral = 50
	_r = _ci.resolver(_m, String(ent["id"]), 0, [-1, 2])
	_comprobar(j.moral == 50 + Citas.MORAL_ENTREVISTA[0] + 1, "entrevista tono seguro (+2) y trabajar con nadie en especial (+1): moral %d" % j.moral)
	_ci.entrevista(_m, j)
	var f0 := j.forma
	var a0 := j.adapt
	j.moral = 50
	_ci.resolver(_m, String(_ci.lista.back()["id"]), 1, [-1, 0])
	_comprobar(j.moral == 50 + Citas.MORAL_ENTREVISTA[1] and j.forma == mini(100, f0 + 3) and j.adapt == a0, "entrevista evasiva y preparador físico: −1 de moral y +3 de forma")
	_ci.entrevista(_m, j)
	j.adapt = 20
	_ci.resolver(_m, String(_ci.lista.back()["id"]), 2, [-1, 1])
	_comprobar(j.adapt == 35, "entrevista con el analista: +15 de adaptación")
	_ci.entrevista(_m, j)
	var id_i = String(_ci.lista.back()["id"])
	_c.plantilla.erase(j)
	_comprobar(String(_ci.resolver(_m, id_i, 0)["texto"]).length() > 0, "entrevista de alguien que ya no está: lo dice")
	_c.plantilla.append(j)
	_comprobar(_ci.opciones_entrevista(_m, _ci.lista.back(), 2).size() == 3 and _ci.opciones_entrevista(_m, _ci.lista.back(), 0).size() == 3, "preguntas 1 y 3 de la entrevista: 3 opciones")
	var grupos = _ci.grupos_entrevista(_m)
	_comprobar(grupos.size() <= 2 and _ci.opciones_entrevista(_m, _ci.lista.back(), 1).size() == grupos.size() + 1, "pregunta 2: un grupo por opción (hasta 2) más «con todos»")
	if not grupos.is_empty():
		_ci.entrevista(_m, j)
		_ci.resolver(_m, String(_ci.lista.back()["id"]), 0, [0])
		_comprobar((grupos[0]["miembros"] as Array).has(j.id) and _m.vestuario._clan_de[j.id] == grupos[0]["id"], "entrevista: entras al grupo elegido")

func _probar_citas_lecturas_y_resolucion_05() -> void:
	## Asamblea: gana y pierde.
	_m.prensa.animo = 80
	_m.directiva.confianza = 80
	_ci._nueva(_m, _m.semana, "asamblea", "Presi", "Asamblea", "a", "")
	_r = _ci.resolver(_m, String(_ci.lista.back()["id"]), 0)
	_comprobar(_ci.asamblea_anio == _m.anio and _m.directiva.confianza == 82 and String(_r["titulo"]) == Idiomas.t("La asamblea respalda al presidente"), "asamblea con grada contenta: respalda y +2 de confianza")
	_m.prensa.animo = 10
	_m.directiva.confianza = 5
	_ci._nueva(_m, _m.semana, "asamblea", "Presi", "Asamblea", "a", "")
	_r = _ci.resolver(_m, String(_ci.lista.back()["id"]), 1)
	_comprobar(_m.directiva.confianza == 50 and String(_r["titulo"]) == Idiomas.t("Nuevo presidente") and not _m.prensa.titular_pendiente.is_empty(), "asamblea perdida: nuevo presidente, confianza 50 y titular de prensa")

func _probar_citas_lecturas_y_resolucion_06() -> void:
	## Rama: aprobar paga, sin caja no.
	var clave := String((Hinchada.RAMAS[0] as Array)[0])
	_ci._nueva(_m, _m.semana, "rama", "Coord", "c", "a", clave)
	_c.saldo = 0
	_r = _ci.resolver(_m, String(_ci.lista.back()["id"]), 0)
	_comprobar(not _m.hinchada.bono_rama.has(clave), "rama sin caja: no hay bono")
	_ci._nueva(_m, _m.semana, "rama", "Coord", "c", "a", clave)
	_c.saldo = 900000000
	var s0 = _c.saldo
	_ci.resolver(_m, String(_ci.lista.back()["id"]), 0)
	_comprobar(_m.hinchada.bono_rama.get(clave, -1) == _m.anio and _c.saldo < s0, "rama aprobada: se paga y queda el bono de la temporada")
	_ci._nueva(_m, _m.semana, "rama", "Coord", "c", "a", clave)
	s0 = _c.saldo
	_ci.resolver(_m, String(_ci.lista.back()["id"]), 1)
	_comprobar(_c.saldo == s0, "rama rechazada: no cuesta")

func _probar_citas_lecturas_y_resolucion_07() -> void:
	## Celebración: sube el ánimo.
	_m.prensa.animo = 40
	_ci._nueva(_m, _m.semana, "celebracion", "Presi", "c", "a", "")
	_ci.resolver(_m, String(_ci.lista.back()["id"]), 1)
	_comprobar(_m.prensa.animo == 43, "celebración en privado: +3 de ánimo")

func _probar_citas_lecturas_y_resolucion_08() -> void:
	## Política.
	_ci._nueva(_m, _m.semana, "politica", "Jefe", "c", "a", _c.pais)
	_ci.resolver(_m, String(_ci.lista.back()["id"]), 0)
	_comprobar(int(_m.politica.gobierno(_c.pais, _m.anio).get("apoyo_club", -1)) == _m.anio, "política: apoyar al gobierno queda anotado")
	_ci._nueva(_m, _m.semana, "politica", "Jefe", "c", "a", _c.pais)
	_comprobar(String(_ci.resolver(_m, String(_ci.lista.back()["id"]), 1)["texto"]) != "", "política: negarse da una respuesta")

func _probar_citas_lecturas_y_resolucion_09() -> void:
	## Objetivo: al resolver la cita marcada, se suelta.
	_ci._nueva(_m, _m.semana, "celebracion", "Presi", "c", "a", "")
	_ci.objetivo = String(_ci.lista.back()["id"])
	_ci.resolver(_m, _ci.objetivo, 1)
	_comprobar(_ci.objetivo == "", "resolver la cita marcada con «Ir» la suelta")

func _probar_citas_rueda_y_guardado() -> void:
	_titulo("CITAS: RUEDA DE PRENSA DESDE EL MÓVIL Y GUARDADO")
	_m = _mundo_citas(9201, "FRA", 2)
	_ci = _m.citas
	_comprobar(_ci.convocar_rueda(null) != "" and Citas.new().convocar_rueda(Mundo.new()) != "", "sin prensa no se puede convocar")
	var e1 = _ci.convocar_rueda(_m)
	_comprobar(e1 == "" or e1.contains("Ya hay"), "primera convocatoria: abierta (o ya había una): «%s»" % e1)
	_m.prensa.pregunta_pendiente = {}
	var e2 = _ci.convocar_rueda(_m)
	_comprobar(e2.contains("esta semana") or e2.contains("Ya hay"), "segunda en la misma semana: no")
	_ci._nueva(_m, _m.semana, "agente", "Ag", "Agente", "a", "")
	_ci.objetivo = String(_ci.lista[0]["id"])
	_ci.favor_agente = 77
	_ci.asamblea_anio = 2030
	var d = _ci.a_dic()
	var otro := Citas.new()
	otro.desde_dic(JSON.parse_string(JSON.stringify(d)))
	_comprobar(otro.lista.size() == _ci.lista.size() and otro.objetivo == _ci.objetivo and otro.favor_agente == 77 and otro.asamblea_anio == 2030 and otro.rueda_semana == _ci.rueda_semana, "a_dic()/desde_dic(): ida y vuelta por JSON")
	otro.lista[0]["estado"] = "caducada"
	_comprobar(_ci.lista[0]["estado"] == "pendiente", "lo cargado es una copia, no comparte datos con la partida guardada")
	otro.desde_dic({})
	_comprobar(otro.lista.is_empty() and otro.objetivo == "" and otro.favor_agente == -1, "desde_dic({}) deja todo en blanco")

func _probar_roles_pulso_y_ascenso_de_ayudante() -> void:
	_titulo("ROLES: PULSO DE PARTIDOS, AYUDANTE, INTERINATO Y CANTERA")
	_m = _mundo_roles(8101)
	_r = _m.roles
	_r.prestigio = 50
	_r.tras_partido(2, 0)
	_comprobar(_r.prestigio == 51, "ganar sube 1 de prestigio")
	_r.tras_partido(1, 1)
	_comprobar(_r.prestigio == 51, "empatar no lo mueve")
	_r.tras_partido(0, 1)
	_comprobar(_r.prestigio == 50, "perder baja 1")
	var rep_antes = _r.reputacion.historial.size()
	_r.tras_partido(5, 0)
	_r.tras_partido(0, 4)
	_comprobar(_r.prestigio == 50, "una goleada a favor y otra en contra (±1): vuelve a 50 (%d)" % _r.prestigio)
	_comprobar(_r.reputacion.historial.size() >= rep_antes + 2, "las goleadas dejan anotada su reputación de «ganador»")
	_probar_roles_pulso_y_ascenso_de_ayudante_01()
	_probar_roles_pulso_y_ascenso_de_ayudante_02()
	_probar_roles_pulso_y_ascenso_de_ayudante_03()
	_probar_roles_pulso_y_ascenso_de_ayudante_04()
	_probar_roles_pulso_y_ascenso_de_ayudante_05()
	_probar_roles_pulso_y_ascenso_de_ayudante_06()

func _probar_roles_pulso_y_ascenso_de_ayudante_01() -> void:
	## Ayudante: gana y asciende.
	var m2 := _mundo_roles(8102)
	_a = m2.roles
	_a.arrancar_ayudante()
	var ascensos: Array[String] = []
	var cambios: Array[String] = []
	_a.ascenso.connect(func(n: String) -> void: ascensos.append(n))
	_a.rol_cambiado.connect(func(x: String, y: String) -> void: cambios.append(x + ">" + y))
	_a.prestigio = Roles.PRESTIGIO_PARA_EL_BANCO
	_a.dt_empleado["confianza"] = Roles.JEFE_ASCIENDE - 2
	_a.tras_partido(2, 0)
	_comprobar(_a.rol == Roles.DT and not _a.es_ayudante(), "tras ganar con confianza y prestigio altos pasa a entrenador principal")
	_comprobar(ascensos == [Roles.DT] and cambios == ["ayudante>dt"] and bool(_a.ayudante.get("ascendido", false)) and _a.dt_empleado.is_empty(), "señales de ascenso y marca de «ascendido»")
	_comprobar(m2.directiva.confianza == 62 and _a.prestigio >= Roles.PRESTIGIO_PARA_EL_BANCO + 8, "ascender: confianza directiva 62 y +8 de prestigio (%d)" % m2.directiva.confianza)

func _probar_roles_pulso_y_ascenso_de_ayudante_02() -> void:
	## Ayudante: pierde mucho y lo echan del cuerpo técnico.
	var m3 := _mundo_roles(8103)
	var e: Roles = m3.roles
	e.arrancar_ayudante()
	var fuera: Array[String] = []
	e.fuera_del_cuerpo_tecnico.connect(func(j: String) -> void: fuera.append(j))
	var jefe := e.jefe_nombre()
	var p_ini := e.prestigio
	e.dt_empleado["confianza"] = Roles.JEFE_ECHA + 1
	e.tras_partido(0, 1)
	_comprobar(e.sin_club and e.rol == Roles.DT and fuera == [jefe] and e.ayudante.is_empty() and e.prestigio == p_ini - 1 - 3, "con la confianza del jefe por los suelos te sacan del cuerpo técnico (sin club, −1 y −3 de prestigio)")

func _probar_roles_pulso_y_ascenso_de_ayudante_03() -> void:
	## Ayudante con empate: la confianza solo sube 1 y no hay ascenso.
	var m4 := _mundo_roles(8104)
	var f: Roles = m4.roles
	f.arrancar_ayudante()
	f.dt_empleado["confianza"] = 40
	f.tras_partido(1, 1)
	_comprobar(f.jefe_confianza() == 41 and f.es_ayudante(), "un empate: +1 de confianza del jefe")
	f.tras_partido(0, 1)
	_comprobar(f.jefe_confianza() == 39 and int(f.dt_empleado["malos"]) == 1, "una derrota: −2 y un «mal» más")
	f.tras_partido(3, 0)
	_comprobar(f.jefe_confianza() == 42 and int(f.dt_empleado["malos"]) == 0, "ganar: +3 y borra los «malos»")

func _probar_roles_pulso_y_ascenso_de_ayudante_04() -> void:
	## Interinato: se resuelve _a las cinco fechas.
	var m5 := _mundo_roles(8105)
	var i: Roles = m5.roles
	i.arrancar_interinato("CHI")
	var resultados: Array[bool] = []
	i.interinato_resuelto.connect(func(s: bool) -> void: resultados.append(s))
	_comprobar(i.en_interinato() and i.fechas_interinato_restantes() > 0, "recién empezado quedan fechas (%d)" % i.fechas_interinato_restantes())
	i.tras_jornada()
	_comprobar(resultados.is_empty() and i.en_interinato(), "con fechas por jugar no se resuelve")
	var liga := m5.liga_de(m5.mi_club())
	liga.jornada_actual = liga.jornadas()
	_comprobar(i.fechas_interinato_restantes() == 0, "sin fechas por jugar quedan 0")
	var prest0 := i.prestigio
	i.tras_jornada()
	_comprobar(resultados.size() == 1 and not i.en_interinato() and bool(i.interino["cumplido"]) and i.prestigio != prest0, "se cumple el contrato: veredicto emitido y el prestigio se mueve")
	_comprobar(i.fechas_interinato_restantes() == 0, "ya no es interino: 0 fechas")
	i.tras_jornada()
	_comprobar(resultados.size() == 1, "no se resuelve dos veces")

func _probar_roles_pulso_y_ascenso_de_ayudante_05() -> void:
	## Cantera: meta cumplida y meta incumplida.
	_m6 = _mundo_roles(8106)
	_q = _m6.roles
	_q.arrancar_cantera()
	var av: Array[String] = []
	_q.aviso.connect(func(t: String, _x: String) -> void: av.append(t))
	_q.cantera["meta"] = 2
	_q.cantera["subidos"] = ["a", "b"]
	var p0 = _q.prestigio
	var conf0 = _m6.directiva.confianza
	_q._chequeo_cantera()
	_comprobar(_q.prestigio == p0 + 8 and av.back() == "Objetivo de cantera cumplido" and _m6.directiva.confianza >= conf0, "cantera cumplida: +8 de prestigio y aviso")
	_comprobar(int(_q.cantera["meta"]) >= 3 and int(_q.cantera["meta"]) <= 5 and (_q.cantera["subidos"] as Array).is_empty(), "y se fija una meta nueva de 3 a 5 con el contador a cero")
	_q.cantera["subidos"] = ["a"]
	_q.cantera["meta"] = 4
	var conf1 = _m6.directiva.confianza
	_q._chequeo_cantera()
	_comprobar(av.back() == "Objetivo de cantera incumplido" and _m6.directiva.confianza < conf1, "cantera incumplida: aviso y baja la confianza de la directiva")

func _probar_roles_pulso_y_ascenso_de_ayudante_06() -> void:
	## Reputación de temporada: lealtad, formador y social.
	var antes = _q.reputacion.historial.size()
	_q._reputacion_de_temporada()
	_comprobar(_q.reputacion.historial.size() >= antes + 3, "el cierre de temporada anota lealtad, formador y social")
	_comprobar(_m6.mi_club().socios >= 0, "los socios no quedan negativos")
