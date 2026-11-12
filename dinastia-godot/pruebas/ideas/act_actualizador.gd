extends BaseIdea
## EL ACTUALIZADOR (4-11-2026): lógica pura (versiones, tags, qué Release sirve) y red CONTRA UN SERVIDOR FALSO local (TCPServer en este mismo proceso): consulta, descarga con
## progreso, verificación de tamaño y SHA-256, redirección, errores (404, 500, 403, JSON roto, nada escuchando) y que NUNCA se cuelga (servidor que no responde, descarga parada).
var _srv := TCPServer.new()
var _conex: Array = []             ## [{p: StreamPeerTCP, buf: PackedByteArray, t: float}]
var _puerto := 0
var _cuerpo_pck := PackedByteArray()
var _modo_lista := "ok"
var _pidieron: Array[String] = []

func _release(tag: String, nombre: String, tam: int, url: String, extra: Dictionary = {}) -> Dictionary:
	var r := {"tag_name": tag, "draft": false, "prerelease": false, "body": "Notas de %s" % tag,
		"assets": [{"name": nombre, "size": tam, "browser_download_url": url}]}
	r.merge(extra, true)
	return r

func _probar() -> void:
	_titulo("ACTUALIZADOR: versiones, Releases y red contra un servidor falso")
	_logica()
	_cuerpo_pck = Crypto.new().generate_random_bytes(300000)
	_puerto = 38000 + randi() % 1500
	while _srv.listen(_puerto, "127.0.0.1") != OK:
		_puerto += 1
	var base := "http://127.0.0.1:%d" % _puerto
	DirAccess.make_dir_recursive_absolute(Actualizador.CARPETA)
	Actualizador.url_api = base + "/releases"
	Actualizador.espera_consulta = 1.5
	Actualizador.espera_sin_datos = 1.5
	for i in 5:
		await get_tree().process_frame   ## el cuadro largo de arriba (rellenar el cuerpo) no debe contar como espera de la red
	await _red(base)
	_srv.stop()
	await _pantalla_de_ajustes()
	Actualizador.url_api = "https://api.github.com/repos/%s/releases?per_page=30" % Actualizador.REPO
	Actualizador.espera_consulta = Actualizador.ESPERA_CONSULTA
	Actualizador.espera_sin_datos = Actualizador.ESPERA_SIN_DATOS

func _logica() -> void:
	_comprobar(Actualizador.comparar("0.9.2", "0.9.1") == 1 and Actualizador.comparar("0.9.1", "0.9.2") == -1 and Actualizador.comparar("0.9.1", "0.9.1") == 0, "comparar: 0.9.2 > 0.9.1 y a la inversa")
	_comprobar(Actualizador.comparar("0.10.0", "0.9.9") == 1, "comparar: 0.10.0 > 0.9.9 (por número, no por texto)")
	_comprobar(Actualizador.comparar("v1.0", "1.0.0") == 0 and Actualizador.comparar("1.0.1", "1.0") == 1, "comparar: «v1.0» = 1.0.0 y 1.0.1 > 1.0")
	_comprobar(Actualizador.comparar("0.9.2-beta", "0.9.2") == 0, "comparar: un sufijo no cambia los números")
	_comprobar(Actualizador.partes("0.9.1") == [0, 9, 1] and Actualizador.partes("x") == [0, 0, 0], "partes: 0.9.1 y lo que no es número")
	_comprobar(Actualizador.leer_tag("parche-0.9.2-escritorio") == {"version": "0.9.2", "sistema": "escritorio"}, "tag: parche-0.9.2-escritorio")
	_comprobar(Actualizador.leer_tag("parche-1.0-android") == {"version": "1.0", "sistema": "android"}, "tag: parche-1.0-android")
	_comprobar(Actualizador.leer_tag("parche-0.9.2-beta-escritorio").get("version", "") == "0.9.2-beta", "tag: con sufijo de versión")
	for malo: String in ["latest", "v0.9.2", "parche-0.9.2", "parche--escritorio", "parche-0.9.2-linux", "parche-abc-escritorio", "Parche-0.9.2-escritorio", ""]:
		_comprobar(Actualizador.leer_tag(malo).is_empty(), "tag no válido: «%s»" % malo)
	_comprobar(Actualizador.nombre_archivo("0.9.2") == "parche_0.9.2.pck" and Actualizador.ruta_destino("0.9.2") == "user://parches/parche_0.9.2.pck", "nombre y ruta del archivo")
	var u := "https://x/y"
	var rs: Array = [
		_release("parche-0.9.2-escritorio", "parche_0.9.2.pck", 1000, u),
		_release("parche-0.9.3-escritorio", "parche_0.9.3.pck", 2000, u, {"draft": true}),
		_release("parche-0.9.4-escritorio", "parche_0.9.4.pck", 2000, u, {"prerelease": true}),
		_release("parche-0.9.5-android", "parche_0.9.5.pck", 2000, u),
		_release("parche-0.9.1-escritorio", "parche_0.9.1.pck", 2000, u),
		_release("parche-0.9.6-escritorio", "otro_nombre.pck", 2000, u),
		_release("parche-0.9.7-escritorio", "parche_0.9.7.pck", 0, u),
		_release("v1.0.0", "x.pck", 5, u),
		"basura", 42]
	var e := Actualizador.elegir(rs, "0.9.1", "escritorio")
	_comprobar(String(e.get("version", "")) == "0.9.2" and int(e.get("tam", 0)) == 1000, "elegir: de las Releases, la 0.9.2 (sin borradores, prerrelease, otros sistemas, iguales ni archivos que no son el parche)")
	_comprobar(Actualizador.elegir(rs, "0.9.1", "android").get("version", "") == "0.9.5", "elegir: para Android, la de Android")
	_comprobar(Actualizador.elegir(rs, "0.9.2", "escritorio").is_empty(), "elegir: ya con la 0.9.2 no hay nada más nuevo")
	_comprobar(Actualizador.elegir([], "0.9.1", "escritorio").is_empty() and Actualizador.elegir(rs, "0.9.1", "linux").is_empty(), "elegir: sin Releases o sin sistema, nada")
	var mas: Array = rs.duplicate()
	mas.append(_release("parche-0.10.0-escritorio", "parche_0.10.0.pck", 77, u, {"assets": [{"name": "parche_0.10.0.pck", "size": 77, "browser_download_url": u, "digest": "sha256:abcdef"}]}))
	var e2 := Actualizador.elegir(mas, "0.9.1", "escritorio")
	_comprobar(e2.get("version", "") == "0.10.0" and e2.get("sha256", "") == "abcdef", "elegir: la más nueva por número (0.10.0 > 0.9.2) y trae su SHA-256")
	_comprobar(Actualizador.mensaje_de(HTTPRequest.RESULT_CANT_CONNECT, 0).contains("conexión") and Actualizador.mensaje_de(HTTPRequest.RESULT_SUCCESS, 429).contains("limita") \
		and Actualizador.mensaje_de(HTTPRequest.RESULT_SUCCESS, 404).contains("No se encontró") and Actualizador.mensaje_de(HTTPRequest.RESULT_SUCCESS, 503).contains("falló") \
		and Actualizador.mensaje_de(HTTPRequest.RESULT_TIMEOUT, 0).contains("tardó"), "mensajes claros para cada fallo")
	_comprobar(Actualizador.version_actual() == String(ProjectSettings.get_setting("application/config/version")) and Actualizador.sistema() in ["escritorio", "android"], "versión instalada y sistema")

# ---------------------------------------------------------------- servidor falso

func _process(_d: float) -> void:
	if not _srv.is_listening():
		return
	while _srv.is_connection_available():
		_conex.append({"p": _srv.take_connection(), "buf": PackedByteArray(), "t": 0.0, "ruta": ""})
	for c: Dictionary in _conex.duplicate():
		var p: StreamPeerTCP = c["p"]
		p.poll()
		if p.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_conex.erase(c)
			continue
		var n := p.get_available_bytes()
		if n > 0:
			var b: PackedByteArray = c["buf"]
			b.append_array(p.get_data(n)[1])
			c["buf"] = b
		var txt: String = (c["buf"] as PackedByteArray).get_string_from_utf8()
		if c["ruta"] == "" and txt.contains("\r\n\r\n"):
			c["ruta"] = txt.get_slice(" ", 1)
			_pidieron.append(c["ruta"])
			_responder(c)

func _enviar(c: Dictionary, estado: String, cabeceras: String, cuerpo: PackedByteArray, declarar: int = -1) -> void:
	var p: StreamPeerTCP = c["p"]
	var h := "HTTP/1.1 %s\r\nContent-Length: %d\r\nConnection: close\r\n%s\r\n" % [estado, cuerpo.size() if declarar < 0 else declarar, cabeceras]
	p.put_data(h.to_utf8_buffer())
	if cuerpo.size() > 0:
		p.put_data(cuerpo)

func _responder(c: Dictionary) -> void:
	var base := "http://127.0.0.1:%d" % _puerto
	var ruta: String = c["ruta"]
	match ruta:
		"/releases":
			match _modo_lista:
				"ok":
					var lista := [_release("parche-0.9.3-escritorio", "parche_0.9.3.pck", _cuerpo_pck.size(), base + "/parche.pck"),
						_release("parche-0.9.0-escritorio", "parche_0.9.0.pck", 10, base + "/parche.pck")]
					_enviar(c, "200 OK", "Content-Type: application/json\r\n", JSON.stringify(lista).to_utf8_buffer())
				"json_roto":
					_enviar(c, "200 OK", "Content-Type: application/json\r\n", "esto no es json{".to_utf8_buffer())
				"objeto":
					_enviar(c, "200 OK", "Content-Type: application/json\r\n", '{"message":"nada"}'.to_utf8_buffer())
				"500":
					_enviar(c, "500 Internal Server Error", "", "error".to_utf8_buffer())
				"403":
					_enviar(c, "403 Forbidden", "", '{"message":"rate limit"}'.to_utf8_buffer())
				"404":
					_enviar(c, "404 Not Found", "", "no".to_utf8_buffer())
				"mudo":
					pass   ## acepta y no contesta nunca
				"sin_nuevas":
					_enviar(c, "200 OK", "Content-Type: application/json\r\n", JSON.stringify([_release("parche-0.9.0-escritorio", "parche_0.9.0.pck", 10, base + "/parche.pck")]).to_utf8_buffer())
				"mal_tam":
					_enviar(c, "200 OK", "Content-Type: application/json\r\n", JSON.stringify([_release("parche-0.9.3-escritorio", "parche_0.9.3.pck", _cuerpo_pck.size() + 5, base + "/parche.pck")]).to_utf8_buffer())
				"mal_sha":
					var r := _release("parche-0.9.3-escritorio", "parche_0.9.3.pck", _cuerpo_pck.size(), base + "/parche.pck")
					r["assets"][0]["digest"] = "sha256:" + "0".repeat(64)
					_enviar(c, "200 OK", "Content-Type: application/json\r\n", JSON.stringify([r]).to_utf8_buffer())
				"con_sha":
					var r2 := _release("parche-0.9.3-escritorio", "parche_0.9.3.pck", _cuerpo_pck.size(), base + "/redirige")
					r2["assets"][0]["digest"] = "sha256:" + _sha(_cuerpo_pck)
					_enviar(c, "200 OK", "Content-Type: application/json\r\n", JSON.stringify([r2]).to_utf8_buffer())
				"parada":
					_enviar(c, "200 OK", "Content-Type: application/json\r\n", JSON.stringify([_release("parche-0.9.3-escritorio", "parche_0.9.3.pck", _cuerpo_pck.size(), base + "/parada")]).to_utf8_buffer())
		"/parche.pck":
			_enviar(c, "200 OK", "Content-Type: application/octet-stream\r\n", _cuerpo_pck)
		"/redirige":
			_enviar(c, "302 Found", "Location: %s/parche.pck\r\n" % base, PackedByteArray())
		"/parada":
			## Anuncia el tamaño entero y manda solo un trozo: luego no llega nada más.
			_enviar(c, "200 OK", "Content-Type: application/octet-stream\r\n", _cuerpo_pck.slice(0, 1000), _cuerpo_pck.size())
		_:
			_enviar(c, "404 Not Found", "", "no".to_utf8_buffer())

static func _sha(b: PackedByteArray) -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(b)
	return h.finish().hex_encode()

# ---------------------------------------------------------------- las pruebas de red

func _consultar(a: Actualizador, seg: float = 6.0) -> Dictionary:
	var resultado := {"visto": false}
	## (las lambdas copian las variables: se rellena el MISMO diccionario, no se reasigna)
	var f1 := func(hay: bool, info: Dictionary, mensaje: String) -> void:
		resultado.merge({"visto": true, "hay": hay, "info": info, "mensaje": mensaje, "fallo": ""}, true)
	var f2 := func(mensaje: String) -> void:
		resultado.merge({"visto": true, "hay": false, "info": {}, "mensaje": "", "fallo": mensaje}, true)
	a.consultado.connect(f1, CONNECT_ONE_SHOT)
	a.fallo.connect(f2, CONNECT_ONE_SHOT)
	var t0 := Time.get_ticks_msec()
	a.consultar()
	while not bool(resultado["visto"]) and (Time.get_ticks_msec() - t0) / 1000.0 < seg:
		await get_tree().process_frame
	resultado["seg"] = (Time.get_ticks_msec() - t0) / 1000.0
	if a.consultado.is_connected(f1):
		a.consultado.disconnect(f1)
	if a.fallo.is_connected(f2):
		a.fallo.disconnect(f2)
	return resultado

func _bajar(a: Actualizador, info: Dictionary, seg: float = 10.0) -> Dictionary:
	var resultado := {"visto": false, "progresos": 0, "max": 0}
	var fp := func(r: int, t: int) -> void:
		resultado["progresos"] = int(resultado["progresos"]) + 1
		resultado["max"] = maxi(int(resultado["max"]), r)
	var f1 := func(ruta: String, _i: Dictionary) -> void:
		resultado["visto"] = true
		resultado["ruta"] = ruta
		resultado["fallo"] = ""
	var f2 := func(mensaje: String) -> void:
		resultado["visto"] = true
		resultado["fallo"] = mensaje
	a.progreso.connect(fp)
	a.descargado.connect(f1, CONNECT_ONE_SHOT)
	a.fallo.connect(f2, CONNECT_ONE_SHOT)
	var t0 := Time.get_ticks_msec()
	a.descargar(info)
	while not bool(resultado["visto"]) and (Time.get_ticks_msec() - t0) / 1000.0 < seg:
		await get_tree().process_frame
	resultado["seg"] = (Time.get_ticks_msec() - t0) / 1000.0
	a.progreso.disconnect(fp)
	return resultado

func _red(base: String) -> void:
	var a := Actualizador.new()
	add_child(a)
	var limpiar := func() -> void:
		for f: String in DirAccess.get_files_at(Actualizador.CARPETA):
			DirAccess.remove_absolute(Actualizador.CARPETA.path_join(f))
	limpiar.call()
	## Consulta normal (12-11: el proyecto ya es 0.9.2, el servidor simulado ofrece la 0.9.3): hay 0.9.3 (y la 0.9.0 de abajo no cuenta).
	_modo_lista = "ok"
	var r := await _consultar(a)
	_comprobar(bool(r["visto"]) and bool(r["hay"]) and String(r["info"]["version"]) == "0.9.3", "consulta: encuentra la 0.9.3 (%s)" % str(r.get("mensaje", "")))
	_comprobar(_pidieron.has("/releases"), "…preguntando a la ruta /releases")
	var info: Dictionary = r["info"]
	## Descarga con progreso, tamaño verificado y nombre definitivo.
	var d := await _bajar(a, info)
	_comprobar(String(d.get("fallo", "x")) == "" and String(d.get("ruta", "")) == "user://parches/parche_0.9.3.pck", "descarga: llega a user://parches/parche_0.9.3.pck (%s)" % str(d.get("fallo", "")))
	var f := FileAccess.open("user://parches/parche_0.9.3.pck", FileAccess.READ)
	_comprobar(f != null and f.get_length() == _cuerpo_pck.size() and f.get_buffer(f.get_length()) == _cuerpo_pck, "descarga: el archivo es idéntico (%d bytes)" % _cuerpo_pck.size())
	if f != null:
		f.close()   ## (6-11) en Windows un archivo abierto NO se puede borrar ni renombrar: sin esto `limpiar` y la descarga siguiente fallaban solo allí
	_comprobar(not FileAccess.file_exists("user://parches/parche_0.9.3.pck.descarga"), "descarga: no queda el temporal")
	_comprobar(int(d["progresos"]) >= 1 and int(d["max"]) == _cuerpo_pck.size(), "descarga: hubo %d avisos de progreso hasta los %d bytes" % [d["progresos"], d["max"]])
	_comprobar(Parches.buscar().has(ProjectSettings.globalize_path("user://parches").path_join("parche_0.9.3.pck")) or Parches.buscar().has("user://parches/parche_0.9.3.pck"), "el autoload Parches encontrará el archivo en el próximo arranque")
	limpiar.call()
	## Redirección (GitHub sirve los archivos desde otro servidor) + SHA-256 correcto.
	_modo_lista = "con_sha"
	r = await _consultar(a)
	d = await _bajar(a, r["info"])
	_comprobar(String(d.get("fallo", "x")) == "" and FileAccess.file_exists("user://parches/parche_0.9.3.pck"), "descarga: sigue la redirección y verifica el SHA-256 (%s)" % str(d.get("fallo", "")))
	limpiar.call()
	## Fallos de la descarga: tamaño anunciado distinto, SHA-256 distinto, descarga parada.
	_modo_lista = "mal_tam"
	r = await _consultar(a)
	d = await _bajar(a, r["info"])
	_comprobar(String(d.get("fallo", "")).contains("tamaño") and not FileAccess.file_exists("user://parches/parche_0.9.3.pck") and DirAccess.get_files_at(Actualizador.CARPETA).is_empty(), "descarga: un tamaño que no coincide se rechaza y no deja nada (%s)" % str(d.get("fallo", "")))
	_modo_lista = "mal_sha"
	r = await _consultar(a)
	d = await _bajar(a, r["info"])
	_comprobar(String(d.get("fallo", "")).contains("SHA-256") and DirAccess.get_files_at(Actualizador.CARPETA).is_empty(), "descarga: un SHA-256 que no coincide se rechaza y no deja nada (%s)" % str(d.get("fallo", "")))
	_modo_lista = "parada"
	r = await _consultar(a)
	d = await _bajar(a, r["info"], 12.0)
	_comprobar(bool(d["visto"]) and String(d.get("fallo", "")).contains("parada") and float(d["seg"]) < 8.0 and DirAccess.get_files_at(Actualizador.CARPETA).is_empty(), "descarga parada: se corta en %.1f s con mensaje claro (%s)" % [d["seg"], str(d.get("fallo", ""))])
	## Fallos de la consulta.
	var casos := {"500": "falló", "403": "limita", "404": "No se encontró", "json_roto": "no se entiende", "objeto": "no se entiende"}
	for modo: String in casos:
		_modo_lista = modo
		r = await _consultar(a)
		_comprobar(bool(r["visto"]) and String(r["fallo"]).contains(String(casos[modo])), "consulta con «%s»: mensaje claro (%s)" % [modo, str(r.get("fallo", ""))])
	_modo_lista = "sin_nuevas"
	r = await _consultar(a)
	_comprobar(bool(r["visto"]) and not bool(r["hay"]) and String(r["fallo"]) == "" and String(r["mensaje"]).contains("última"), "consulta: sin versiones nuevas dice que ya está al día (%s)" % str(r.get("mensaje", "")))
	## Nunca se cuelga: servidor que acepta y no contesta, y nada escuchando.
	_modo_lista = "mudo"
	r = await _consultar(a, 10.0)
	_comprobar(bool(r["visto"]) and String(r["fallo"]).contains("tardó") and float(r["seg"]) < 6.0, "servidor mudo: la consulta se rinde en %.1f s (%s)" % [r["seg"], str(r.get("fallo", ""))])
	_srv.stop()
	r = await _consultar(a, 10.0)
	_comprobar(bool(r["visto"]) and String(r["fallo"]).contains("conexión") and float(r["seg"]) < 6.0, "sin servidor: «sin conexión» en %.1f s (%s)" % [r["seg"], str(r.get("fallo", ""))])
	_comprobar(not a.ocupado(), "tras los fallos el actualizador queda libre para volver a intentarlo")
	## Una segunda pulsación mientras trabaja no lanza otra petición.
	Actualizador.url_api = "http://127.0.0.1:1/x"
	a.consultar()
	var antes := a.ocupado()
	a.consultar()
	_comprobar(antes, "mientras consulta, está ocupado (y una segunda orden se ignora)")
	await get_tree().create_timer(2.0).timeout
	a.queue_free()
	limpiar.call()

## La cara en Ajustes → Partida y guardado: está, se ve la versión, y SIN red el botón acaba con un mensaje (no se queda «Buscando…»).
func _pantalla_de_ajustes() -> void:
	var ajustes_antes := FileAccess.get_file_as_bytes("user://ajustes.cfg") if FileAccess.file_exists("user://ajustes.cfg") else PackedByteArray()
	var m := Mundo.new()
	m.generar(["CHI"], 20261104)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	PedidoPartida.mundo_pregenerado = m
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	for i in 6:
		await get_tree().process_frame
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	var aj := MenusLaterales.menu_por_id("ajustes")
	var sub := 0
	for i in (aj["subs"] as Array).size():
		if String(aj["subs"][i].get("secc", "")) == "partida":
			sub = i
	p._menu_lateral.abrir_menu("ajustes", sub)
	for i in 8:
		await get_tree().process_frame
	var act := p.find_child("Actualizador", true, false) as Actualizador
	_comprobar(act != null, "Ajustes → Partida y guardado trae el actualizador")
	if act != null:
		var caja := act.get_parent()
		var buscar := caja.find_child("Buscar", true, false) as Button
		var estado := caja.find_child("Estado", true, false) as Label
		var barra := caja.find_child("Barra", true, false) as ProgressBar
		var bajar := caja.find_child("Descargar", true, false) as Button
		var visibles := ""
		for l in caja.find_children("*", "Label", true, false):
			visibles += (l as Label).text + "\n"
		_comprobar(visibles.contains(Actualizador.version_actual()), "enseña la versión instalada (%s)" % Actualizador.version_actual())
		_comprobar(buscar != null and buscar.is_visible_in_tree() and not bajar.visible and not barra.visible, "al principio solo está el botón «Buscar actualización» (nada se baja solo)")
		Actualizador.url_api = "http://127.0.0.1:1/releases"
		Actualizador.espera_consulta = 2.0
		buscar.pressed.emit()
		_comprobar(estado.text.contains("Buscando") and buscar.disabled, "al pulsar: «Buscando…» y el botón se desactiva")
		var t0 := Time.get_ticks_msec()
		while estado.text.contains("Buscando") and (Time.get_ticks_msec() - t0) < 9000:
			await get_tree().process_frame
		_comprobar(estado.text.begins_with("⚠") and not buscar.disabled, "sin red acaba con un mensaje y se puede volver a intentar (%s)" % estado.text)
		Actualizador.espera_consulta = Actualizador.ESPERA_CONSULTA
	var pv := ""
	for l in p.find_children("*", "Label", true, false):
		pv += (l as Label).text + "\n"
	_comprobar(pv.contains("solo se conecta a internet cuando tú pulsas") and not pv.contains("no se conecta a internet:"), "el texto de privacidad dice cuándo se conecta")
	p.queue_free()
	await get_tree().process_frame
	if ajustes_antes.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ajustes.cfg"))
	else:
		FileAccess.open("user://ajustes.cfg", FileAccess.WRITE).store_buffer(ajustes_antes)
