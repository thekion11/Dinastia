extends "res://pruebas/banco/base.gd"
## [Banco · grupo «cobertura»] (18-11) Pruebas de COMPORTAMIENTO de clases que el banco casi no tocaba (informe
## `docs/04_auditorias/cobertura_lineas_2026-11-18.md`): actualizador, entrada al campeonato, permisos y pulso de roles.

func _probar_actualizador_logica() -> void:
	_titulo("ACTUALIZADOR: VERSIONES, ETIQUETAS, RELEASES Y RESPUESTAS DEL SERVIDOR")
	_comprobar(Actualizador.partes("v0.9.2") == [0, 9, 2] and Actualizador.partes("1.2") == [1, 2, 0] and Actualizador.partes("0.9.2-beta") == [0, 9, 2], "partes(): «v0.9.2», «1.2» y «0.9.2-beta»")
	_comprobar(Actualizador.partes("x.y") == [0, 0, 0], "partes(): lo que no es número cuenta como 0")
	_comprobar(Actualizador.comparar("0.9.2", "0.9.10") == -1 and Actualizador.comparar("1.0", "0.99.99") == 1 and Actualizador.comparar("v1.2.3", "1.2.3") == 0, "comparar(): numérica, no de texto (0.9.2 < 0.9.10)")
	var t := Actualizador.leer_tag("parche-0.9.3-android")
	_comprobar(String(t.get("version", "")) == "0.9.3" and String(t.get("sistema", "")) == "android", "leer_tag(): versión y sistema")
	_comprobar(Actualizador.leer_tag("parche-1.0.0-beta-escritorio").get("version", "") == "1.0.0-beta", "leer_tag(): admite sufijo")
	_comprobar(Actualizador.leer_tag("release-0.9.3").is_empty() and Actualizador.leer_tag("parche-0.9.3-ios").is_empty() and Actualizador.leer_tag("").is_empty(), "leer_tag(): lo que no tiene la forma da {}")
	_comprobar(Actualizador.nombre_archivo("0.9.3") == "parche_0.9.3.pck" and Actualizador.ruta_destino("0.9.3") == "user://parches/parche_0.9.3.pck", "nombre y ruta del parche")
	_comprobar(Actualizador.sistema() in ["android", "escritorio"] and Actualizador.version_actual() != "", "sistema() y version_actual() devuelven algo")
	## elegir(): publicada, de este sistema, más nueva y con su archivo.
	var lista: Array = [
		_rel("parche-0.9.5-escritorio", {"draft": true}),
		_rel("parche-0.9.6-escritorio", {"prerelease": true}),
		_rel("parche-0.9.7-android"),
		_rel("parche-0.9.4-escritorio"),
		_rel("parche-0.9.3-escritorio"),
		_rel("parche-0.9.1-escritorio"),
		"basura", {"tag_name": "no-es-parche"}, {"assets": []}]
	var e := Actualizador.elegir(lista, "0.9.2", "escritorio")
	_comprobar(String(e.get("version", "")) == "0.9.4", "elegir(): la más nueva válida (no borrador, no prerrelease, no de otro sistema): %s" % e.get("version", "—"))
	_comprobar(String(e.get("nombre", "")) == "parche_0.9.4.pck" and int(e.get("tam", 0)) == 1000 and String(e.get("sha256", "")) == "ABC123", "elegir(): nombre, tamaño y SHA sin el prefijo")
	_comprobar(Actualizador.elegir(lista, "0.9.4", "escritorio").is_empty(), "elegir(): con la última ya instalada no hay nada")
	_comprobar(String(Actualizador.elegir(lista, "0.9.2", "android").get("version", "")) == "0.9.7", "elegir(): el sistema Android ve la suya")
	var mal_nombre := [_rel("parche-0.9.8-escritorio", {}, "otro.pck")]
	var sin_tam := [_rel("parche-0.9.8-escritorio", {}, "", 0)]
	var sin_url := [{"tag_name": "parche-0.9.8-escritorio", "assets": [{"name": "parche_0.9.8.pck", "size": 5, "browser_download_url": "ftp://x"}]}]
	_comprobar(Actualizador.elegir(mal_nombre, "0.9.2", "escritorio").is_empty() and Actualizador.elegir(sin_tam, "0.9.2", "escritorio").is_empty() and Actualizador.elegir(sin_url, "0.9.2", "escritorio").is_empty(), "elegir(): sin su .pck, sin tamaño o con URL que no es http, no sirve")
	var largo := Actualizador.elegir([_rel("parche-0.9.9-escritorio", {"body": "x".repeat(900)})], "0.9.2", "escritorio")
	_comprobar(String(largo.get("notas", "")).length() == 600, "elegir(): las notas se recortan a 600")
	var sin_sha := Actualizador.elegir([{"tag_name": "parche-0.9.9-escritorio", "assets": [{"name": "parche_0.9.9.pck", "size": 9, "browser_download_url": "https://x.invalid/a", "digest": "md5:zz"}]}], "0.9.2", "escritorio")
	_comprobar(String(sin_sha.get("sha256", "x")) == "", "elegir(): un digest que no es sha256 no se toma")
	## mensaje_de(): cada manera de fallar tiene su frase.
	var frases := {}
	for par: Array in [[HTTPRequest.RESULT_SUCCESS, 403], [HTTPRequest.RESULT_SUCCESS, 429], [HTTPRequest.RESULT_SUCCESS, 404], [HTTPRequest.RESULT_SUCCESS, 503], [HTTPRequest.RESULT_SUCCESS, 418],
			[HTTPRequest.RESULT_CANT_CONNECT, 0], [HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR, 0], [HTTPRequest.RESULT_TIMEOUT, 0], [HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR, 0], [HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED, 0]]:
		frases[Actualizador.mensaje_de(int(par[0]), int(par[1]))] = true
	_comprobar(frases.size() == 9, "mensaje_de(): 10 casos, 9 frases (403 y 429 comparten la de «GitHub limita»): %d" % frases.size())
	_comprobar(Actualizador.mensaje_de(HTTPRequest.RESULT_SUCCESS, 503).contains("503") and Actualizador.mensaje_de(HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED, 0).contains(str(HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED)), "mensaje_de(): lleva el código cuando hace falta")

func _rel(tag: String, extra: Dictionary = {}, nombre := "", tam := 1000) -> Dictionary:
	var v: String = str(Actualizador.leer_tag(tag).get("version", "0"))
	var r := {"tag_name": tag, "body": "notas de " + tag, "assets": [{"name": nombre if nombre != "" else Actualizador.nombre_archivo(v), "size": tam,
		"browser_download_url": "https://ejemplo.invalid/" + tag, "digest": "sha256:ABC123"}]}
	r.merge(extra, true)
	return r

func _probar_actualizador_flujo() -> void:
	_titulo("ACTUALIZADOR: CONSULTA Y DESCARGA CON RESPUESTAS SIMULADAS (sin red)")
	var a := Actualizador.new()
	add_child(a)
	var visto := {"consultado": [], "fallo": [], "descargado": [], "progreso": []}
	a.consultado.connect(func(hay: bool, info: Dictionary, msg: String) -> void: visto["consultado"].append([hay, info, msg]))
	a.fallo.connect(func(msg: String) -> void: visto["fallo"].append(msg))
	a.descargado.connect(func(ruta: String, info: Dictionary) -> void: visto["descargado"].append([ruta, info]))
	a.progreso.connect(func(rec: int, tot: int) -> void: visto["progreso"].append([rec, tot]))
	_comprobar(not a.ocupado(), "recién creado no está ocupado")
	var sist := Actualizador.sistema()
	var v_nueva := "99.0.0"
	var cuerpo_ok := JSON.stringify([{"tag_name": "parche-%s-%s" % [v_nueva, sist], "body": "n", "assets": [{"name": "parche_99.0.0.pck", "size": 5, "browser_download_url": "https://ejemplo.invalid/p"}]}]).to_utf8_buffer()
	## Respuesta ignorada si no se había preguntado.
	a._al_consultar(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), cuerpo_ok)
	_comprobar((visto["consultado"] as Array).is_empty() and (visto["fallo"] as Array).is_empty(), "una respuesta que nadie pidió se ignora")
	## Con parche nuevo.
	a._estado = "consultando"
	_comprobar(a.ocupado(), "consultando = ocupado")
	a._al_consultar(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), cuerpo_ok)
	var c0: Array = (visto["consultado"] as Array)[0] if not (visto["consultado"] as Array).is_empty() else [false, {}, ""]
	_comprobar(bool(c0[0]) and String((c0[1] as Dictionary).get("version", "")) == v_nueva and String(c0[2]).contains(v_nueva) and not a.ocupado(), "hay parche nuevo: lo avisa y queda libre")
	## Sin parche nuevo.
	a._estado = "consultando"
	a._al_consultar(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), "[]".to_utf8_buffer())
	var c1: Array = (visto["consultado"] as Array)[1] if (visto["consultado"] as Array).size() > 1 else [true, {}, ""]
	_comprobar(not bool(c1[0]) and String(c1[2]).contains(Actualizador.version_actual()), "sin parche: «ya tienes la última (%s)»" % Actualizador.version_actual())
	## Fallos: código HTTP, JSON roto, JSON que no es lista.
	for caso: Array in [[HTTPRequest.RESULT_SUCCESS, 403, "[]"], [HTTPRequest.RESULT_SUCCESS, 200, "{{no es json"], [HTTPRequest.RESULT_SUCCESS, 200, "{\"a\":1}"], [HTTPRequest.RESULT_TIMEOUT, 0, ""]]:
		a._estado = "consultando"
		a._al_consultar(int(caso[0]), int(caso[1]), PackedStringArray(), String(caso[2]).to_utf8_buffer())
	_comprobar((visto["fallo"] as Array).size() == 4 and not a.ocupado(), "cuatro respuestas malas = cuatro fallos y vuelve a libre")
	_comprobar(String((visto["fallo"] as Array)[0]).contains("limita") and String((visto["fallo"] as Array)[1]).contains("no se entiende") and String((visto["fallo"] as Array)[2]).contains("no se entiende"), "cada fallo con su frase")
	## Descarga: tamaño y SHA-256 verificados antes del nombre definitivo.
	DirAccess.make_dir_recursive_absolute(Actualizador.CARPETA)
	var contenido := "parche de prueba".to_utf8_buffer()
	var tmp := Actualizador.ruta_destino("0.0.1") + ".descarga"
	var destino := Actualizador.ruta_destino("0.0.1")
	var escribir := func() -> void:
		var f := FileAccess.open(tmp, FileAccess.WRITE)
		f.store_buffer(contenido)
		f.close()
	var info := {"version": "0.0.1", "tam": contenido.size(), "sha256": "", "url": "https://ejemplo.invalid/p"}
	## 1) tamaño distinto
	escribir.call()
	a._tmp = tmp
	a._info = info.duplicate()
	a._info["tam"] = contenido.size() + 1
	a._estado = "descargando"
	a._al_descargar(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), PackedByteArray())
	_comprobar(String((visto["fallo"] as Array).back()).contains("tamaño") and not FileAccess.file_exists(tmp) and not FileAccess.file_exists(destino), "tamaño distinto: falla y borra el temporal")
	## 2) SHA distinto
	escribir.call()
	a._tmp = tmp
	a._info = info.duplicate()
	a._info["sha256"] = "0".repeat(64)
	a._estado = "descargando"
	a._al_descargar(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), PackedByteArray())
	_comprobar(String((visto["fallo"] as Array).back()).contains("SHA-256") and not FileAccess.file_exists(destino), "SHA-256 distinto: falla y no deja el parche")
	## 3) todo bien (con SHA en mayúsculas: se compara sin distinguir)
	escribir.call()
	a._tmp = tmp
	a._info = info.duplicate()
	a._info["sha256"] = FileAccess.get_sha256(tmp).to_upper()
	a._estado = "descargando"
	a._al_descargar(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), PackedByteArray())
	_comprobar((visto["descargado"] as Array).size() == 1 and FileAccess.file_exists(destino) and not FileAccess.file_exists(tmp) and not a.ocupado(), "descarga correcta: el parche queda con su nombre")
	_comprobar(not (visto["progreso"] as Array).is_empty() and int(((visto["progreso"] as Array).back() as Array)[0]) == contenido.size(), "el último aviso de progreso trae lo que llegó")
	## Un fallo HTTP en la descarga y la cancelación.
	a._estado = "descargando"
	a._al_descargar(HTTPRequest.RESULT_SUCCESS, 404, PackedStringArray(), PackedByteArray())
	_comprobar(String((visto["fallo"] as Array).back()).contains("No se encontró"), "la descarga con 404 dice por qué")
	escribir.call()
	a._tmp = tmp
	a._estado = "descargando"
	a.cancelar()
	_comprobar(not a.ocupado() and not FileAccess.file_exists(tmp), "cancelar() deja libre y borra el temporal")
	## Una descarga parada se corta sola (con la espera acortada).
	a._http = HTTPRequest.new()
	a.add_child(a._http)
	a._info = {"tam": 10}
	a._estado = "descargando"
	a._ultimo = a._http.get_downloaded_bytes()
	var antes := Actualizador.espera_sin_datos
	Actualizador.espera_sin_datos = 1.0
	var n := (visto["fallo"] as Array).size()
	a._process(0.6)
	_comprobar((visto["fallo"] as Array).size() == n, "0,6 s sin datos todavía no corta")
	a._process(0.6)
	_comprobar((visto["fallo"] as Array).size() == n + 1 and String((visto["fallo"] as Array).back()).contains("parada"), "1,2 s sin datos con tope de 1 s: corta con «parada»")
	Actualizador.espera_sin_datos = antes
	## Una consulta que no avisa se corta con su tope.
	a._estado = "consultando"
	a._t_consulta = 0.0
	a._process(Actualizador.espera_consulta + 3.5)
	_comprobar(String((visto["fallo"] as Array).back()).contains("tardó"), "una consulta que nunca responde acaba con «tardó demasiado»")
	## consultar() y descargar() no hacen nada si ya está ocupado o si no hay info.
	a._estado = "consultando"
	a.consultar()
	a.descargar({"version": "1"})
	_comprobar(a._estado == "consultando", "ocupado: ni consulta ni descarga otra vez")
	a._estado = "libre"
	a.descargar({})
	_comprobar(a._estado == "libre", "descargar({}) no hace nada")
	if FileAccess.file_exists(destino):
		DirAccess.remove_absolute(destino)
	a.queue_free()

# ---------------------------------------------------------------------------- ENTRADA AL CAMPEONATO

func _probar_entrada_campeonato_datos() -> void:
	_titulo("ENTRADA AL CAMPEONATO: NORMALIZAR, DATOS, CANDIDATOS Y PREVISUALIZACIÓN")
	var n := EntradaCampeonato.normalizar({"tipo": "confederacion", "club_id": "c7", "pais": "ARG"})
	_comprobar(String(n["modo"]) == "pagar" and String(n["pais"]) == "ARG" and String(n["club_reemplazado"]) == "c7", "normalizar(): «confederacion» = «pagar» y toma club_id")
	n = EntradaCampeonato.normalizar({"modo": "loquesea", "reemplaza": "c3"}, "ESP")
	_comprobar(String(n["modo"]) == "reemplazar" and String(n["pais"]) == "ESP" and String(n["club_reemplazado"]) == "c3", "normalizar(): un modo desconocido es reemplazar; país por defecto")
	n = EntradaCampeonato.normalizar({"club_reemplazado": "", "reemplaza": "c9", "club_id": "c1"})
	_comprobar(String(n["club_reemplazado"]) == "c9", "normalizar(): salta las claves vacías y toma la primera con valor")
	var d := EntradaCampeonato.datos_de_config({"nombre_club": "  Sol  ", "col1": Color(1, 0, 0), "color2": "00ff00", "estadio": " Nido "})
	_comprobar(String(d["nombre"]) == "Sol" and String(d["color1"]) == "#ff0000" and String(d["color2"]) == "#00ff00" and String(d["estadio"]) == "Nido", "datos_de_config(): recorta, convierte Color y pone «#»")
	d = EntradaCampeonato.datos_de_config({})
	_comprobar(String(d["nombre"]) == "" and String(d["color1"]) == "" and String(d["estadio"]) == "", "datos_de_config({}) todo vacío")
	_comprobar(EntradaCampeonato.rep_reemplazo(_club_con_rep(60)) == 50 and EntradaCampeonato.rep_reemplazo(_club_con_rep(3)) == EntradaCampeonato.REP_MINIMA, "rep_reemplazo(): −10 con suelo en 1")
	_comprobar(EntradaCampeonato.rep_confederacion() == Mundo.REP_FUNDACION - 20, "rep_confederacion() = fundación − 20")
	var m := Mundo.new()
	m.generar(["CHI", "ESP"], 515)
	var cand := EntradaCampeonato.candidatos(m, "ESP")
	var ordenado := not cand.is_empty()
	for i in range(1, cand.size()):
		if cand[i].division < cand[i - 1].division or (cand[i].division == cand[i - 1].division and cand[i].rep > cand[i - 1].rep):
			ordenado = false
	var todos_esp := true
	for c: Club in cand:
		todos_esp = todos_esp and c.pais == "ESP"
	_comprobar(ordenado and todos_esp, "candidatos(): solo del país, de mayor a menor división y reputación (%d clubes)" % cand.size())
	var peor := EntradaCampeonato.candidato_sugerido(m, "ESP")
	var l_baja := EntradaCampeonato.liga_mas_baja(m, "ESP")
	var minrep := 9999
	for c: Club in l_baja.clubes:
		minrep = mini(minrep, c.rep)
	_comprobar(peor != null and l_baja.clubes.has(peor) and peor.rep == minrep, "candidato_sugerido(): el más flojo de la liga más baja (%s, rep %d)" % [peor.nombre, peor.rep])
	_comprobar(l_baja.division() == EntradaCampeonato.liga_de_club(m, cand.back()).division(), "liga_mas_baja() coincide con la liga del último candidato")
	_comprobar(EntradaCampeonato.liga_mas_baja(m, "XXX") == null and EntradaCampeonato.candidato_sugerido(m, "XXX") == null and EntradaCampeonato.liga_de_club(m, _club_con_rep(1)) == null, "país sin liga o club suelto: null")
	_comprobar(EntradaCampeonato.presupuesto_base(null) == 0 and EntradaCampeonato.presupuesto_base(Liga.new()) == 0, "presupuesto_base(): sin liga o sin clubes es 0")
	var l1: Liga = m.liga_de(cand[0])
	var base1 := EntradaCampeonato.presupuesto_base(l1)
	var rep_media := 0.0
	for c: Club in l1.clubes:
		rep_media += float(c.rep)
	_comprobar(base1 == int(round(Eco.ref_caja(rep_media / float(l1.clubes.size())))), "presupuesto_base() = ref_caja de la reputación media de la liga")
	## Previsualizaciones.
	var pa := EntradaCampeonato.previsualizar(m, "reemplazar", "ESP", cand[2].id)
	_comprobar(not pa.has("error") and int(pa["cuota"]) == 0 and int(pa["rep"]) == maxi(1, cand[2].rep - 10) and int(pa["jugadores_libres"]) == cand[2].plantilla.size(), "A: sin cuota, reputación −10, sus jugadores quedan libres")
	_comprobar(int(pa["socios"]) + int(pa["socios_repartidos"]) == cand[2].socios and int(pa["socios"]) == int(floor(float(cand[2].socios) / 3.0)), "A: un tercio de los socios se queda y el resto se reparte")
	_comprobar(EntradaCampeonato.previsualizar(m, "reemplazar", "CHI", cand[2].id).has("error") and EntradaCampeonato.previsualizar(m, "reemplazar", "ESP", "no_existe").has("error"), "A: club de otro país o inexistente da error")
	var pb := EntradaCampeonato.previsualizar(m, "pagar", "ESP")
	var b := int(pb["presupuesto_base"])
	_comprobar(int(pb["cuota"]) == int(round(float(b) * 0.25)) and int(pb["presupuesto"]) == b - int(pb["cuota"]), "B: cuota = 25 % de B y presupuesto = B − cuota")
	_comprobar(int(pb["confianza"]) == 40 and int(pb["animo_delta"]) == -15 and int(pb["clubes_liga"]) == l_baja.clubes.size() + 1 and bool(pb["descansos"]) == ((l_baja.clubes.size() + 1) % 2 == 1), "B: confianza 40, ánimo −15 y un club más (descansos si queda impar)")
	_comprobar(int(pb["aforo"]) > 0 and int(pb["socios"]) == int(float(int(pb["aforo"])) * (0.22 + float(int(pb["rep"])) / 420.0)), "B: aforo modesto y socios con la fórmula del mundo")
	l_baja.jornada_actual = 3
	_comprobar(String(EntradaCampeonato.previsualizar(m, "pagar", "ESP").get("error", "")).contains("ya empezó"), "B: con la liga empezada no se puede")
	l_baja.jornada_actual = 0
	_comprobar(EntradaCampeonato.previsualizar(m, "pagar", "XXX").has("error") and EntradaCampeonato.previsualizar(m, "raro", "ESP").has("error"), "B en país sin liga y modo desconocido dan error")
	_comprobar(EntradaCampeonato.pregunta_primera_rueda({"modo": "reemplazar"}).is_empty(), "pregunta de rueda: solo para quien pagó")
	var q := EntradaCampeonato.pregunta_primera_rueda({"modo": "pagar"})
	_comprobar(String(q["pregunta"]) != "" and (q["opciones"] as Array).size() == 3 and (q["opciones"] as Array).all(func(o: Dictionary) -> bool: return o.has("txt") and o.has("tono")), "pregunta de rueda: 3 opciones con texto y tono")

func _club_con_rep(r: int) -> Club:
	var c := Club.new()
	c.rep = r
	return c

func _probar_entrada_campeonato_aplicar() -> void:
	_titulo("ENTRADA AL CAMPEONATO: APLICAR (REEMPLAZAR Y PAGAR) SOBRE MUNDOS DISTINTOS")
	var datos := EntradaCampeonato.datos_de_config({"nombre_club": "Unión Alba", "col1": "102030", "color2": "e0e0e0", "estadio": "El Faro"})
	## A: reemplazar, en Italia.
	var m := Mundo.new()
	m.generar(["ITA", "BRA"], 616)
	var cand := EntradaCampeonato.candidatos(m, "ITA")
	var r: Club = cand[4]
	var l := EntradaCampeonato.liga_de_club(m, r)
	var otros_antes := 0
	for k: Club in l.clubes:
		if k != r:
			otros_antes += k.socios
	var pre := EntradaCampeonato.previsualizar(m, "reemplazar", "ITA", r.id)
	var ids: Array[String] = []
	for j: Jugador in r.plantilla:
		ids.append(j.id)
	var c := EntradaCampeonato.aplicar(m, {"tipo": "reemplazar", "pais": "ITA", "reemplaza": r.id}, datos)
	_comprobar(c == r, "A: el mismo objeto del club reemplazado")
	_comprobar(c.nombre == "Unión Alba" and c.color1 == "#102030" and c.color2 == "#e0e0e0" and c.estadio_nombre == "El Faro", "A: nombre, colores y estadio nuevos (%s %s %s %s)" % [c.nombre, c.color1, c.color2, c.estadio_nombre])
	_comprobar(c.rep == int(pre["rep"]) and c.saldo == int(pre["presupuesto"]) and c.socios == int(pre["socios"]) and m.mi_club_id == c.id, "A: reputación, caja y socios de la previsualización; tú al mando")
	var otros_despues := 0
	for k: Club in l.clubes:
		if k != r:
			otros_despues += k.socios
	_comprobar(otros_despues - otros_antes == int(pre["socios_repartidos"]), "A: los socios repartidos llegan a los demás clubes (%d)" % (otros_despues - otros_antes))
	var libres := 0
	for j: Jugador in m.libres:
		if ids.has(j.id):
			libres += 1
			if j.club_id != "" or j.motivo_libre != EntradaCampeonato.MOTIVO_LIBRE or j.capitan or j.dorsal != 0:
				libres += 1000
	_comprobar(libres == ids.size(), "A: sus %d jugadores están libres con el motivo y sin dorsal ni brazalete (%d)" % [ids.size(), libres])
	_comprobar(not c.plantilla.is_empty() and c.plantilla.all(func(j: Jugador) -> bool: return not ids.has(j.id)), "A: la plantilla nueva no tiene a ninguno de los viejos")
	_comprobar(m.directiva.confianza == 60 and m.prensa.pregunta_pendiente.is_empty(), "A: confianza 60 y sin pregunta dura de prensa")
	_comprobar(EntradaCampeonato.aplicar(m, {"tipo": "reemplazar", "pais": "ITA", "reemplaza": c.id}, {"nombre": "  "}) == null, "sin nombre de club no aplica")
	_comprobar(EntradaCampeonato.aplicar(m, {"tipo": "reemplazar", "pais": "ITA", "reemplaza": "zzz"}, datos) == null, "con un club que no existe no aplica")
	## B: pagar, en Brasil, y con las cifras que anunció.
	var m2 := Mundo.new()
	m2.generar(["BRA", "FRA"], 717)
	var lb := EntradaCampeonato.liga_mas_baja(m2, "BRA")
	var n0 := lb.clubes.size()
	var pre2 := EntradaCampeonato.previsualizar(m2, "pagar", "BRA")
	var serie := Mundo.new()
	serie.generar(["BRA", "FRA"], 717)
	serie.tomar_el_mando(serie.ligas[0].clubes[1].id)
	var animo0 := serie.prensa.animo
	var c2 := EntradaCampeonato.aplicar(m2, {"tipo": "confederacion", "pais": "BRA"}, datos)
	_comprobar(c2 != null and lb.clubes.size() == n0 + 1 and lb.clubes.has(c2) and m2.clubes.get(c2.id) == c2 and c2.division == lb.division(), "B: club nuevo en la liga más baja (%d → %d clubes)" % [n0, lb.clubes.size()])
	_comprobar(c2.rep == int(pre2["rep"]) and c2.socios == int(pre2["socios"]) and c2.saldo == int(pre2["presupuesto"]), "B: reputación, socios y caja anunciados (caja %s)" % _dinero(c2.saldo))
	_comprobar(m2.directiva.confianza == 40 and m2.prensa.animo < animo0 and m2.mi_club_id == c2.id, "B: confianza 40 y ánimo más bajo (%d → %d)" % [animo0, m2.prensa.animo])
	_comprobar(not m2.prensa.pregunta_pendiente.is_empty() and (m2.prensa.pregunta_pendiente["opciones"] as Array).size() == 3, "B: te espera la pregunta dura de la primera rueda")
	_comprobar(not c2.plantilla.is_empty() and lb.jornadas() > 0, "B: plantilla y calendario rehechos")
	var ids_unicos := {}
	for k: Club in m2.clubes.values():
		ids_unicos[k.id] = true
	_comprobar(ids_unicos.size() == m2.clubes.size(), "B: ningún id de club repetido")

# ---------------------------------------------------------------------------- ROLES: permisos y pulso

func _mundo_roles(semilla: int, pais := "CHI") -> Mundo:
	var m := Mundo.new()
	m.generar([pais], semilla)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	return m

func _probar_roles_permisos_y_ventana() -> void:
	_titulo("ROLES: PERMISOS, MOTIVOS DE BLOQUEO, VENTANA DE EMERGENCIA Y ESCALERA")
	var m := _mundo_roles(8001)
	var r: Roles = m.roles
	m.semana = 3
	_comprobar(r.puede_fichar() and r.puede_alinear() and r.puede_contratar_staff() and r.puede_construir() and r.puede_vender_jugadores() and r.puede_rescindir(), "DT con la ventana abierta: puede todo lo del banquillo")
	_comprobar(not r.puede_contratar_dt() and not r.puede_inyectar_capital() and not r.puede_vender_club() and r.le_pueden_echar(), "el DT no contrata DT, no mete capital, no vende el club y puede ser despedido")
	m.semana = 10
	_comprobar(not r.puede_fichar() and r.motivo_bloqueo("fichar").contains("Mercado cerrado"), "semana 10: mercado cerrado y lo explica")
	## Ventana de emergencia: una por temporada, una sola bala.
	_comprobar(not r.emergencia_activa() and r.abrir_emergencia("j1") and r.emergencia_activa() and r.puede_fichar(), "la emergencia abre el mercado")
	_comprobar(not r.abrir_emergencia("j2"), "no se puede abrir otra en la misma temporada")
	var avisos: Array[String] = []
	r.aviso.connect(func(t: String, _x: String) -> void: avisos.append(t))
	r.usar_emergencia()
	_comprobar(not r.emergencia_activa() and not r.puede_fichar() and avisos.size() == 1 and bool(r.emergencia["usada"]), "usarla la gasta y avisa")
	r.usar_emergencia()
	_comprobar(avisos.size() == 1, "gastar lo ya gastado no avisa otra vez")
	m.semana = 14
	r.emergencia = {"anio": m.anio, "hasta": 15, "jugador_id": "j", "usada": false}
	_comprobar(r.emergencia_activa(), "dentro de su plazo")
	m.semana = 16
	_comprobar(not r.emergencia_activa(), "pasado el plazo caduca")
	m.semana = 3
	_comprobar(not r.abrir_emergencia("j9"), "con la ventana abierta no hace falta emergencia")
	## Ascenso de rol.
	r.trofeos.clear()
	r.prestigio = 50
	_comprobar(r.puede_ascender() == "" and r.siguiente_escalon().contains("trofeo"), "sin trofeos ni prestigio no asciendes y te dice cuánto falta")
	for i in 6:
		r.sumar_trofeo("Copa prueba %d" % i)
	r.prestigio = 80
	_comprobar(r.puede_ascender() == Roles.DIR and r.siguiente_escalon().begins_with("Puedes dar el salto"), "6 trofeos y prestigio 80: puedes ser director")
	_comprobar(r.trofeos.size() == 6 and r.trofeos[0]["titulo"] == "Copa prueba 0" and int(r.trofeos[0]["anio"]) == m.anio, "los trofeos quedan con año y título")
	r.sumar_prestigio(500)
	_comprobar(r.prestigio == Roles.PRESTIGIO_MAX, "el prestigio tiene techo")
	r.sumar_prestigio(-900)
	_comprobar(r.prestigio == Roles.PRESTIGIO_MIN, "y suelo")
	r.rol = Roles.DUENO
	_comprobar(r.puede_ascender() == "" and r.siguiente_escalon() == "", "el dueño no tiene escalón superior")
	r.rol = Roles.DT
	## El resumen coincide con las preguntas sueltas.
	r.prestigio = 60
	var s := r.resumen()
	_comprobar(String(s["rol"]) == Roles.DT and bool(s["puede_fichar"]) == r.puede_fichar() and int(s["trofeos"]) == 6 and int(s["prestigio"]) == 60 and int(s["jefe_confianza"]) == -1 and int(s["interinato"]) == 0, "resumen(): coherente con las consultas")
	## Cambiar de DT: solo quien contrata DT, y cuesta.
	_comprobar(r.cambiar_dt().contains("no lo eliges"), "el DT no elige entrenador")
	r.rol = Roles.DIR
	var c := m.mi_club()
	c.saldo = 0
	_comprobar(r.cambiar_dt().contains("hacen falta"), "sin caja no hay cambio")
	c.saldo = 900000000
	var antes := c.saldo
	avisos.clear()
	_comprobar(r.cambiar_dt() == "" and c.saldo < antes and avisos.size() == 1 and r.estilo_dt() != "", "con caja: cuesta, avisa y el nuevo DT tiene estilo")
	r.rol = Roles.DT
	## Motivos de bloqueo por cargo.
	var m2 := _mundo_roles(8002)
	m2.roles.arrancar_ayudante()
	var ra: Roles = m2.roles
	m2.semana = 10
	for acc: String in ["fichar", "alinear", "vender_jugadores", "rescindir", "staff", "construir"]:
		_comprobar(ra.motivo_bloqueo(acc) != "", "ayudante: «%s» trae un motivo" % acc)
	_comprobar(ra.motivo_bloqueo("alinear").contains(ra.jefe_nombre()) and not ra.puede_alinear() and not ra.puede_contratar_staff() and not ra.puede_construir(), "el ayudante propone, el jefe pone el once")
	_comprobar(not ra.le_pueden_echar() and ra.manda(), "al ayudante no lo echa el directorio y no es quien manda en el once")
	_comprobar(ra.motivo_bloqueo("capital") != "" and ra.motivo_bloqueo("vender_club") != "" and ra.motivo_bloqueo("otra_cosa") == "", "motivos de capital y venta; una acción desconocida no inventa motivo")
	m2.roles.rol = Roles.DIR
	m2.roles.ayudante = {}
	_comprobar(m2.roles.motivo_bloqueo("alinear").contains("entrenador"), "director: el once lo pone el entrenador")
	var m3 := _mundo_roles(8003)
	m3.roles.arrancar_interinato("CHI")
	_comprobar(m3.roles.motivo_bloqueo("fichar").contains("Interinato") and not m3.roles.le_pueden_echar(), "interino: mercado cerrado y no lo echan")

func _probar_roles_pulso_y_ascenso_de_ayudante() -> void:
	_titulo("ROLES: PULSO DE PARTIDOS, AYUDANTE, INTERINATO Y CANTERA")
	var m := _mundo_roles(8101)
	var r: Roles = m.roles
	r.prestigio = 50
	r.tras_partido(2, 0)
	_comprobar(r.prestigio == 51, "ganar sube 1 de prestigio")
	r.tras_partido(1, 1)
	_comprobar(r.prestigio == 51, "empatar no lo mueve")
	r.tras_partido(0, 1)
	_comprobar(r.prestigio == 50, "perder baja 1")
	var rep_antes := r.reputacion.historial.size()
	r.tras_partido(5, 0)
	r.tras_partido(0, 4)
	_comprobar(r.prestigio == 50, "una goleada a favor y otra en contra (±1): vuelve a 50 (%d)" % r.prestigio)
	_comprobar(r.reputacion.historial.size() >= rep_antes + 2, "las goleadas dejan anotada su reputación de «ganador»")
	## Ayudante: gana y asciende.
	var m2 := _mundo_roles(8102)
	var a: Roles = m2.roles
	a.arrancar_ayudante()
	var ascensos: Array[String] = []
	var cambios: Array[String] = []
	a.ascenso.connect(func(n: String) -> void: ascensos.append(n))
	a.rol_cambiado.connect(func(x: String, y: String) -> void: cambios.append(x + ">" + y))
	a.prestigio = Roles.PRESTIGIO_PARA_EL_BANCO
	a.dt_empleado["confianza"] = Roles.JEFE_ASCIENDE - 2
	a.tras_partido(2, 0)
	_comprobar(a.rol == Roles.DT and not a.es_ayudante(), "tras ganar con confianza y prestigio altos pasa a entrenador principal")
	_comprobar(ascensos == [Roles.DT] and cambios == ["ayudante>dt"] and bool(a.ayudante.get("ascendido", false)) and a.dt_empleado.is_empty(), "señales de ascenso y marca de «ascendido»")
	_comprobar(m2.directiva.confianza == 62 and a.prestigio >= Roles.PRESTIGIO_PARA_EL_BANCO + 8, "ascender: confianza directiva 62 y +8 de prestigio (%d)" % m2.directiva.confianza)
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
	## Interinato: se resuelve a las cinco fechas.
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
	## Cantera: meta cumplida y meta incumplida.
	var m6 := _mundo_roles(8106)
	var q: Roles = m6.roles
	q.arrancar_cantera()
	var av: Array[String] = []
	q.aviso.connect(func(t: String, _x: String) -> void: av.append(t))
	q.cantera["meta"] = 2
	q.cantera["subidos"] = ["a", "b"]
	var p0 := q.prestigio
	var conf0 := m6.directiva.confianza
	q._chequeo_cantera()
	_comprobar(q.prestigio == p0 + 8 and av.back() == "Objetivo de cantera cumplido" and m6.directiva.confianza >= conf0, "cantera cumplida: +8 de prestigio y aviso")
	_comprobar(int(q.cantera["meta"]) >= 3 and int(q.cantera["meta"]) <= 5 and (q.cantera["subidos"] as Array).is_empty(), "y se fija una meta nueva de 3 a 5 con el contador a cero")
	q.cantera["subidos"] = ["a"]
	q.cantera["meta"] = 4
	var conf1 := m6.directiva.confianza
	q._chequeo_cantera()
	_comprobar(av.back() == "Objetivo de cantera incumplido" and m6.directiva.confianza < conf1, "cantera incumplida: aviso y baja la confianza de la directiva")
	## Reputación de temporada: lealtad, formador y social.
	var antes := q.reputacion.historial.size()
	q._reputacion_de_temporada()
	_comprobar(q.reputacion.historial.size() >= antes + 3, "el cierre de temporada anota lealtad, formador y social")
	_comprobar(m6.mi_club().socios >= 0, "los socios no quedan negativos")
