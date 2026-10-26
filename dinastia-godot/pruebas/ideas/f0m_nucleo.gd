extends BaseIdea
## FASE 0 (M-403/M-279): PRUEBAS DIRECTAS de los módulos de `nucleo/` que no tenían
## ninguna: `Cierre`, `Creditos`, `EventosCantera`, `Genero`, `Mercado` y `Precarga`.
## Cada bloque instancia el módulo solo y comprueba lo que promete su cabecera.

func _probar() -> void:
	_titulo("FASE 0 · NÚCLEO SIN PRUEBA DIRECTA (f0m)")
	_probar_cierre()
	_probar_creditos()
	_probar_genero()
	var m := _mundo(4031)
	_probar_eventos_cantera(m)
	_probar_mercado(m)
	_probar_precarga()

# --------------------------------------------------------------------- Cierre

## La lista de `Cierre.CACHES` es lo que evita el «segmentation fault» al salir:
## cada fila tiene que apuntar a una variable estática que EXISTE (si se renombra,
## el vaciado no hace nada y el fallo vuelve sin avisar) y el valor de vaciado
## tiene que caber en ella. Se prueba el vaciado de verdad (y se deshace).
func _probar_cierre() -> void:
	_linea("· Cierre")
	var malas: Array[String] = []
	var tipos_malos: Array[String] = []
	var no_vacia: Array[String] = []
	var vistas := {}
	for fila: Array in Cierre.CACHES:
		var ruta := String(fila[0])
		var nombre := String(fila[1])
		vistas["%s|%s" % [ruta, nombre]] = true
		var decl := _declaracion_estatica(ruta, nombre)
		if decl == "":
			malas.append("%s:%s" % [ruta.get_file(), nombre])
			continue
		var v: Variant = fila[2]
		var ok_tipo := true
		if v is Dictionary:
			ok_tipo = decl.contains("{}") or decl.contains("Dictionary")
		elif v is Array:
			ok_tipo = decl.contains("[]") or decl.contains("Array")
		elif v == null:
			ok_tipo = not decl.contains("{}") and not decl.contains("[]") and not decl.contains(": Dictionary") and not decl.contains(": Array")
		if not ok_tipo:
			tipos_malos.append("%s:%s" % [ruta.get_file(), nombre])
			continue
		## El vaciado de verdad, como en `_exit_tree`, y se deja como estaba.
		var s: Script = load(ruta)
		var antes: Variant = s.get(nombre)
		s.set(nombre, v)
		var despues: Variant = s.get(nombre)
		var vacio: bool = (despues == null) if v == null else (typeof(despues) == typeof(v) and despues.is_empty())
		if not vacio:
			no_vacia.append("%s:%s" % [ruta.get_file(), nombre])
		s.set(nombre, antes)
	_comprobar(malas.is_empty(), "cada fila de Cierre.CACHES apunta a una `static var` que existe %s" % str(malas))
	_comprobar(tipos_malos.is_empty(), "y el valor de vaciado es del tipo de la variable %s" % str(tipos_malos))
	_comprobar(no_vacia.is_empty(), "y `Script.set()` la vacía de verdad (el vaciado no es un no-op) %s" % str(no_vacia))
	## Los módulos que prueban estas fases guardan texturas, mallas y materiales en
	## cachés estáticas: tienen que estar en la lista (la propia cabecera lo exige).
	var deben := [
		["res://visor/banderas.gd", "_cache"], ["res://visor/cara_malla.gd", "_texturas"],
		["res://visor/cara_malla.gd", "_cache_mallas"], ["res://visor/retrato3d.gd", "_cache"],
		["res://visor/retrato3d.gd", "_cola"], ["res://visor/peaton_q.gd", "_mats"],
		["res://visor/peaton_q.gd", "_zapatillas"], ["res://visor/peaton_q.gd", "_mat_zapatilla"],
		["res://visor/pelo_capas.gd", "_mat_cache"], ["res://visor/pelo_capas.gd", "_cache_cuero"],
		["res://visor/pelo_capas.gd", "_cache_pestanas"], ["res://nucleo/precarga.gd", "_guardados"],
	]
	var faltan: Array[String] = []
	for d: Array in deben:
		if not vistas.has("%s|%s" % [d[0], d[1]]):
			faltan.append("%s:%s" % [String(d[0]).get_file(), d[1]])
	_comprobar(faltan.is_empty(), "las cachés de recursos de los módulos probados están en Cierre.CACHES %s" % str(faltan))

## La línea `static var <nombre>` del script o de sus capas (`_pN`), o "".
func _declaracion_estatica(ruta: String, nombre: String) -> String:
	var s: Script = load(ruta)
	var re := RegEx.new()
	re.compile("(?m)^static var %s\\b.*$" % nombre)
	while s != null:
		var f := FileAccess.open(s.resource_path, FileAccess.READ)
		if f != null:
			var r := re.search(f.get_as_text())
			if r != null:
				return r.get_string()
		s = s.get_base_script()
	return ""

# ------------------------------------------------------------------ Creditos

func _probar_creditos() -> void:
	_linea("· Creditos")
	var l := Creditos.lineas()
	_comprobar(l.size() == Creditos.LISTA.size() and l.size() >= 6, "una línea por crédito (%d)" % l.size())
	var completas := true
	for c: Array in Creditos.LISTA:
		completas = completas and c.size() == 3 and String(c[0]).strip_edges() != "" and String(c[1]).strip_edges() != "" and String(c[2]).strip_edges() != ""
	_comprobar(completas, "cada crédito trae qué, quién y licencia")
	_comprobar(l[0] == "%s — %s · %s" % Creditos.LISTA[0], "formato «qué — quién · licencia»")
	## Lo que se cita tiene que estar también en la referencia completa.
	var lic := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../docs/05_referencia/LICENCIAS.md"))
	var sin_ref: Array[String] = []
	for autor: String in ["Godot", "Quaternius", "Kenney", "Anderson Rohr", "MediaPipe", "NASA"]:
		if not lic.contains(autor):
			sin_ref.append(autor)
	_comprobar(lic != "" and sin_ref.is_empty(), "cada autor citado está en docs/05_referencia/LICENCIAS.md %s" % str(sin_ref))
	## El número de efectos que se anuncia es el del catálogo de verdad.
	var re := RegEx.new()
	re.compile("(\\d+) efectos de sonido")
	var dice := -1
	for x: String in l:
		var r := re.search(x)
		if r != null:
			dice = int(r.get_string(1))
	## (Las licencias las lleva el dueño: un número desfasado se avisa, no se corrige aquí.)
	_comprobar(dice > 0, "los créditos dicen cuántos efectos sintetiza el juego (%d)" % dice)
	if dice != Sonido.NOMBRES.size():
		_linea("  (aviso) los créditos dicen %d efectos y el catálogo de Sonido tiene %d" % [dice, Sonido.NOMBRES.size()])

# -------------------------------------------------------------------- Genero

func _probar_genero() -> void:
	_linea("· Genero")
	var antes := Genero.mujer
	Genero.mujer = false
	_comprobar(Genero.adaptar("El entrenador del club") == "El entrenador del club", "con personaje hombre no toca nada")
	Genero.mujer = true
	var casos := {
		"El entrenador del club": "La entrenadora del club",
		"Bienvenido, míster": "Bienvenida, míster",
		"Eres el nuevo entrenador": "Eres la nueva entrenadora",
		"Modo director deportivo": "Modo directora deportiva",
		"El técnico principal": "La entrenadora principal",
		"Estás despedido.": "Estás despedida.",
		"La prensa pregunta al entrenador": "La prensa pregunta a la entrenadora",
		"Las palabras del entrenador": "Las palabras de la entrenadora",
		"CARRERA DE ENTRENADOR": "CARRERA DE ENTRENADORA",
	}
	var mal: Array[String] = []
	for k: String in casos:
		if Genero.adaptar(k) != String(casos[k]):
			mal.append("%s → %s" % [k, Genero.adaptar(k)])
	_comprobar(mal.is_empty(), "adapta lo que habla de TI %s" % str(mal))
	_comprobar(Genero.adaptar("Habla el entrenador rival") == "Habla el entrenador rival"
		and Genero.adaptar("Las quejas del entrenador contrario") == "Las quejas del entrenador contrario",
		"y no lo que habla del OTRO entrenador")
	_comprobar(Genero.adaptar("ola") == "ola", "textos muy cortos, tal cual")
	## Enganchado al traductor: `tr()` adapta, y al desinstalar deja de hacerlo.
	Genero.instalar()
	var inst: Genero = Genero._instalado
	_comprobar(inst != null and String(inst._get_message(&"Bienvenido", &"")) == "Bienvenida", "como traducción: «Bienvenido» → «Bienvenida»")
	_comprobar(inst != null and String(inst._get_message(&"Sin cambios aquí", &"")) == "", "y vacío (= el original) si no cambia nada")
	Genero.desinstalar()
	_comprobar(Genero._instalado == null, "desinstalar() lo saca del servidor de traducciones")
	Genero.mujer = antes

# ------------------------------------------------------------ EventosCantera

func _probar_eventos_cantera(m: Mundo) -> void:
	_linea("· EventosCantera")
	var a := m.academia
	var c := m.mi_club()
	_comprobar(a != null and a.chicos.size() >= 3, "hay academia con chicos para probar")
	if a == null or a.chicos.size() < 3:
		return
	var ev := EventosCantera.new()
	var noticias: Array = []
	var movs: Array = []
	ev.noticia.connect(func(t: String, cu: String) -> void: noticias.append([t, cu]))
	ev.movimiento.connect(func(con: String, monto: int) -> void: movs.append([con, monto]))
	## Por hash: la misma semana da siempre lo mismo, y no consume `Azar`.
	var tipos := {}
	var menores_padres := 0
	var semanas_con_algo := 0
	for anio in [2026, 2027, 2028]:
		for sem in range(1, 39):
			var n0 := noticias.size()
			ev.semana(a, c, anio, sem)
			if not ev.pendiente.is_empty():
				semanas_con_algo += 1
				tipos[String(ev.pendiente["tipo"])] = true
				var ch := a.chico(String(ev.pendiente["id"]))
				if String(ev.pendiente["tipo"]) == "padres" and not ch.is_empty() and int(ch["edad"]) < Academia.EDAD_ENTREGA_ANTICIPADA:
					menores_padres += 1
				ev.pendiente = {}
			elif noticias.size() > n0:
				semanas_con_algo += 1
				tipos["convocatoria"] = true
	_comprobar(semanas_con_algo >= 6 and semanas_con_algo <= 22, "pasa algo cada ~10 semanas (%d en 114)" % semanas_con_algo)
	_comprobar(tipos.size() >= 3, "y de varios tipos %s" % str(tipos.keys()))
	if menores_padres > 0:
		_linea("  (aviso) %d veces los padres exigen subir a un chico de menos de %d años: la opción A no puede cumplirse" % [menores_padres, Academia.EDAD_ENTREGA_ANTICIPADA])
	## Con un asunto abierto no se abre otro.
	ev.pendiente = {"tipo": "torneo", "id": String(a.chicos[0]["id"]), "nombre": "X", "a": "Ir", "b": "No"}
	var copia := ev.pendiente.duplicate()
	ev.semana(a, c, 2026, 10)
	_comprobar(ev.pendiente == copia, "con un asunto abierto no se pisa con otro")
	## Torneo, sí: cuesta lo que dice `Eco.escalar` y todos suben 1,5.
	var niveles: Array[float] = []
	for x: Dictionary in a.chicos:
		niveles.append(float(x["nivel"]))
	var saldo0 := c.saldo
	var r := ev.resolver("a", a, c)
	var coste := Eco.escalar(80000.0, float(c.rep))
	var suben := true
	for i in a.chicos.size():
		suben = suben and is_equal_approx(float(a.chicos[i]["nivel"]), niveles[i] + 1.5)
	_comprobar(c.saldo == saldo0 - coste and movs.size() == 1 and int(movs[0][1]) == -coste, "torneo: se paga %s y se anota el movimiento" % _dinero(coste))
	_comprobar(suben and ev.pendiente.is_empty() and String(r.get("titulo", "")).contains("Ir"), "y todos los chicos suben 1,5 (el asunto queda cerrado)")
	_comprobar(ev.resolver("a", a, c).is_empty(), "sin asunto abierto, resolver no hace nada")
	## Abandono, respetado: el chico se va.
	var n_antes := a.chicos.size()
	var id_x := String(a.chicos[n_antes - 1]["id"])
	ev.pendiente = {"tipo": "abandono", "id": id_x, "nombre": "Y", "a": "Hablar", "b": "Respetar"}
	ev.resolver("b", a, c)
	_comprobar(a.chicos.size() == n_antes - 1 and a.chico(id_x).is_empty(), "abandono respetado: deja la academia")
	## Visita: una por semana.
	var nv := float(a.chicos[0]["nivel"])
	var v1 := ev.visitar(a, 2026, 5)
	var v2 := ev.visitar(a, 2026, 5)
	_comprobar(v1 == "" and v2 != "" and is_equal_approx(float(a.chicos[0]["nivel"]), nv + 0.5), "visitar: +0,5 a todos, una vez por semana")
	_comprobar(ev.visitar(a, 2026, 6) == "", "y la semana siguiente se puede volver")
	_comprobar(ev.visitar(null, 2026, 7) != "", "sin academia, un aviso en vez de un error")
	## Guardado.
	ev.pendiente = {"tipo": "padres", "id": "z", "nombre": "Z", "a": "A", "b": "B"}
	var d := ev.a_dic()
	var ev2 := EventosCantera.new()
	ev2.desde_dic(d)
	ev.pendiente["nombre"] = "cambiado"
	_comprobar(ev2.ultima_visita == ev.ultima_visita and String(ev2.pendiente.get("nombre", "")) == "Z", "a_dic/desde_dic: vuelve igual (y es una copia)")

# ------------------------------------------------------------------- Mercado

func _probar_mercado(m: Mundo) -> void:
	_linea("· Mercado")
	var mer := m.mercado
	var mio := m.mi_club()
	var rival: Club = m.ligas[0].clubes[1]
	var j: Jugador = rival.plantilla[0]
	for x: Jugador in rival.plantilla:
		if x.valor > j.valor:
			j = x
	var v := mer.valor_pedido(j)
	_comprobar(v >= 1000 and v % 1000 == 0, "valor pedido redondeado a miles (%s)" % _dinero(v))
	var ps := j.pide_salir
	j.pide_salir = true
	var v_sale := mer.valor_pedido(j)
	j.pide_salir = ps
	_comprobar(v_sale < v, "si pide salir, piden menos (%s < %s)" % [_dinero(v_sale), _dinero(v)])
	_comprobar(mer.club_acepta(j, v) and not mer.club_acepta(j, int(v * 0.6)), "acepta lo pedido; por debajo del 70 % nunca")
	var d := mer.deseo_de_venir(j, mio)
	var razones_ok := true
	for rz: Dictionary in d["razones"]:
		razones_ok = razones_ok and rz.has("bien") and String(rz.get("txt", "")) != ""
	_comprobar(float(d["p"]) >= 0.02 and float(d["p"]) <= 0.98 and razones_ok, "deseo de venir en [0,02; 0,98] con sus razones (%.2f)" % float(d["p"]))
	var f3 := mer.ficha_que_pide(j, mio, 3)
	var f5 := mer.ficha_que_pide(j, mio, 5)
	_comprobar(f3 >= 30 and f3 % 10 == 0 and f5 >= f3, "la ficha va de diez en diez y el contrato largo cuesta más (%d ≤ %d)" % [f3, f5])
	## La mesa: no con uno tuyo.
	_comprobar(mer.abrir_negociacion(mio.plantilla[0]) == "ese jugador ya es tuyo" and mer.negociacion == null, "no se negocia por un jugador propio")
	var motivo := mer.abrir_negociacion(j)
	_comprobar((motivo == "" and mer.negociacion != null) or (motivo != "" and mer.negociacion == null), "con un rival: se abre la mesa o dice por qué no («%s»)" % motivo)
	mer.cerrar_negociacion()
	_comprobar(mer.negociacion == null, "cerrar_negociacion() la quita")
	## Guardado de ofertas: lo que apunta a alguien que ya no está se descarta.
	mer.ofertas_recibidas.clear()
	var mi_j: Jugador = mio.plantilla[0]
	mer.ofertas_recibidas.append({"jugador": mi_j, "club": rival, "monto": 1234000, "semana": 7, "clausula": true})
	var dic := mer.a_dic()
	(dic["ofertas_recibidas"] as Array).append({"jugador_id": "no_existe", "club_id": rival.id, "monto": 5, "semana": 1, "clausula": false})
	mer.desde_dic(dic)
	var o: Dictionary = mer.ofertas_recibidas[0] if mer.ofertas_recibidas.size() == 1 else {}
	_comprobar(mer.ofertas_recibidas.size() == 1 and o.get("jugador") == mi_j and o.get("club") == rival
		and int(o.get("monto", 0)) == 1234000 and int(o.get("semana", 0)) == 7 and bool(o.get("clausula", false)),
		"a_dic/desde_dic de ofertas: vuelven igual y la huérfana se descarta")
	var n_of := mer.ofertas_recibidas.size()
	mer.responder_oferta(9, true)
	_comprobar(mer.ofertas_recibidas.size() == n_of, "responder una oferta que no existe no hace nada")
	mer.ofertas_recibidas.clear()
	## El traspaso: el dinero y el jugador se mueven a la vez.
	var traspasos: Array = []
	mer.traspaso.connect(func(jj: Jugador, _de: Club, _a: Club, monto: int) -> void: traspasos.append([jj, monto]))
	var s_mio := mio.saldo
	var s_riv := rival.saldo
	var n_fich := mer.fichajes_temporada.size()
	mer.fichar(j, mio, 2000000, j.sueldo, 3)
	_comprobar(mio.saldo == s_mio - 2000000 and rival.saldo == s_riv + 2000000, "fichar: el dinero va de uno a otro, exacto")
	_comprobar(j.club_id == mio.id and mio.plantilla.has(j) and not rival.plantilla.has(j), "y el jugador cambia de plantilla")
	_comprobar(traspasos.size() == 1 and mer.fichajes_temporada.size() == n_fich + 1, "se avisa del traspaso y queda en el documental de la temporada")

# ------------------------------------------------------------------ Precarga

## Sin gráfica no arranca sola (las pruebas miden la carga en frío); a mano, deja
## en la caché todo lo que promete y se borra al terminar.
func _probar_precarga() -> void:
	_linea("· Precarga")
	var faltan: Array[String] = []
	for r: String in Precarga.FIJOS:
		if not ResourceLoader.exists(r):
			faltan.append(r.get_file())
	_comprobar(faltan.is_empty(), "los fijos de la precarga existen %s" % str(faltan))
	var antes := Precarga._hecha
	Precarga.empezar(get_tree())
	_comprobar(Precarga._hecha == antes and get_tree().root.get_node_or_null("Precarga") == null, "en headless no arranca sola")
	var p := Precarga.new()
	p._ready()
	var en_cola := p._cola.size()
	_comprobar(en_cola > Precarga.FIJOS.size(), "la cola lleva los fijos y los modelos de las carpetas (%d)" % en_cola)
	var t0 := Time.get_ticks_msec()
	while not p.is_queued_for_deletion() and Time.get_ticks_msec() - t0 < 120000:
		p._process(0.016)
		OS.delay_msec(4)
	var sin_cache: Array[String] = []
	for r: String in Precarga.FIJOS:
		if not ResourceLoader.has_cached(r):
			sin_cache.append(r.get_file())
	_comprobar(p.is_queued_for_deletion(), "termina y se borra sola (%d ms)" % (Time.get_ticks_msec() - t0))
	_comprobar(sin_cache.is_empty(), "y deja los fijos en la caché %s" % str(sin_cache))
	if not p.is_queued_for_deletion():
		p.free()
