extends BaseIdea
## ENTRADA AL CAMPEONATO (fase 1, etapa 5): cada cifra validada por el dueño (PLAN_DEL_LUNES §2.3), aplicada
## sobre un mundo de verdad, y la pantalla que la explica. Las cifras esperadas se calculan aquí A MANO
## (media de reputación de la liga → `Eco.ref_caja`), no con las funciones que se prueban.

const DATOS := {"nombre": "Atlético Fénix", "color1": "#112233", "color2": "#ddeeff", "estadio": "La Forja"}

func _probar() -> void:
	var base := _animo_y_confianza_de_serie()
	_probar_reemplazar(int(base["animo"]))
	_probar_confederacion(int(base["animo"]))
	_probar_normalizar()

## Lo que deja `tomar_el_mando()` sin entrada al campeonato: el «ánimo normal».
func _animo_y_confianza_de_serie() -> Dictionary:
	var m := Mundo.new()
	m.generar(["CHI"], 999)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	return {"animo": m.prensa.animo, "confianza": m.directiva.confianza}

static func _b_a_mano(l: Liga) -> int:
	var s := 0.0
	for c: Club in l.clubes:
		s += float(c.rep)
	return int(round(Eco.ref_caja(s / float(l.clubes.size()))))

func _probar_reemplazar(animo_serie: int) -> void:
	_titulo("ENTRADA A · REEMPLAZAR UN CLUB EXISTENTE")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	var l: Liga = null
	for x: Liga in m.ligas:
		if x.pais == "CHI" and x.division() == 1:
			l = x
	var r: Club = l.clubes[5]
	var id := r.id
	var rep0 := r.rep
	var nombre0 := r.nombre
	var socios0 := r.socios
	var n_liga := l.clubes.size()
	var b := _b_a_mano(l)
	var ids_viejos: Array[String] = []
	for j: Jugador in r.plantilla:
		ids_viejos.append(j.id)
	var socios_otros := 0
	for k: Club in l.clubes:
		if k != r:
			socios_otros += k.socios

	var p := EntradaCampeonato.previsualizar(m, "reemplazar", "CHI", id)
	_comprobar(not p.has("error"), "la previsualización de A no da error")
	_comprobar(int(p["cuota"]) == 0, "A: coste ninguno (%d)" % int(p["cuota"]))
	_comprobar(int(p["presupuesto"]) == b, "A: presupuesto de partida = B de su división (%s = %s)" % [_dinero(int(p["presupuesto"])), _dinero(b)])
	_comprobar(int(p["rep"]) == rep0 - 10, "A: reputación = la del reemplazado − 10 (%d → %d)" % [rep0, int(p["rep"])])
	_comprobar(int(p["confianza"]) == 60 and int(p["animo_delta"]) == 0, "A: confianza 60 y ánimo normal en la previsualización")
	_comprobar(r.nombre == nombre0 and r.rep == rep0 and r.plantilla.size() == ids_viejos.size(), "previsualizar no toca el mundo")

	var c := EntradaCampeonato.aplicar(m, {"modo": "reemplazar", "pais": "CHI", "club_reemplazado": id}, DATOS)
	_comprobar(c != null and c == r and c.id == id, "A: el club nuevo ocupa el MISMO objeto/id (nada queda colgando)")
	if c == null:
		return
	_comprobar(c.nombre == "Atlético Fénix" and c.color1 == "#112233" and c.estadio_nombre == "La Forja", "A: nombre, colores y estadio elegidos")
	_comprobar(c.rep == rep0 - 10, "A: reputación aplicada %d (= %d − 10)" % [c.rep, rep0])
	_comprobar(c.saldo == b, "A: caja aplicada = B (%s)" % _dinero(c.saldo))
	_comprobar(c.division == 1 and l.clubes.has(c) and l.clubes.size() == n_liga, "A: misma división y la liga sigue con %d clubes" % n_liga)
	_comprobar(m.mi_club_id == id and m.directiva != null and m.directiva.confianza == 60, "A: al mando y confianza de la directiva 60 (%d)" % (m.directiva.confianza if m.directiva != null else -1))
	_comprobar(m.prensa.animo == animo_serie, "A: ánimo de la afición normal (%d, el de serie %d)" % [m.prensa.animo, animo_serie])
	var libres_ids: Dictionary = {}
	for j: Jugador in m.libres:
		libres_ids[j.id] = j
	var todos := true
	for jid: String in ids_viejos:
		var j: Jugador = libres_ids.get(jid)
		if j == null or j.club_id != "" or j.motivo_libre != EntradaCampeonato.MOTIVO_LIBRE:
			todos = false
	_comprobar(todos, "A: los %d futbolistas del club desaparecido están en la bolsa de libres, sin club" % ids_viejos.size())
	var ninguno_viejo := true
	for j: Jugador in c.plantilla:
		if ids_viejos.has(j.id) or j.club_id != c.id:
			ninguno_viejo = false
	_comprobar(ninguno_viejo and c.plantilla.size() >= 18, "A: plantilla rehecha entera (%d fichas nuevas)" % c.plantilla.size())
	var otros_ahora := 0
	for k: Club in l.clubes:
		if k != c:
			otros_ahora += k.socios
	_comprobar(c.socios == socios0 / 3, "A: un tercio de los socios se queda (%d de %d)" % [c.socios, socios0])
	_comprobar(otros_ahora - socios_otros == socios0 - socios0 / 3, "A: los otros dos tercios se reparten entre la liga (+%d)" % (otros_ahora - socios_otros))
	_comprobar(not m.prensa.portadas.is_empty() and String(m.prensa.portadas[0]["t"]).contains(nombre0), "A: portada «Nace un club sobre las cenizas de %s»" % nombre0)
	_comprobar(c.esc_especial == "" and c.kit_color1 == "", "A: sin escudo ni camiseta del club anterior")
	## Un libre del club desaparecido se puede fichar como cualquier otro (puede decir que no, no dar error).
	var idx := m.libres.find(libres_ids.get(ids_viejos[0]))
	var res := m.fichar_libre(idx, c)
	_comprobar(not res.has("error") or String(res["error"]).begins_with("no alcanza"), "A: un ex futbolista del club desaparecido es fichable (%s)" % str(res))

	## Guardado: todo sobrevive.
	Partida.borrar("_prueba_f1e")
	_comprobar(Partida.guardar(m, "_prueba_f1e"), "A: la partida se guarda")
	var m2 := Partida.cargar("_prueba_f1e")
	var c2: Club = m2.clubes.get(id) if m2 != null else null
	_comprobar(c2 != null and c2.nombre == "Atlético Fénix" and c2.rep == rep0 - 10 and m2.directiva.confianza == 60,
		"A: al cargar vuelven nombre, reputación y confianza")
	Partida.borrar("_prueba_f1e")

func _probar_confederacion(animo_serie: int) -> void:
	_titulo("ENTRADA B · PAGAR A LA CONFEDERACIÓN")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4243)
	var l := EntradaCampeonato.liga_mas_baja(m, "CHI")
	_comprobar(l != null and l.division() == 2, "B: la liga más baja de Chile es la de Ascenso")
	var n0 := l.clubes.size()
	var total0 := m.clubes.size()
	var b := _b_a_mano(l)
	var cuota := int(round(float(b) * 0.25))
	var antes: Dictionary = {}
	for k: Club in m.clubes.values():
		antes[k.id] = [k.rep, k.saldo, k.socios, k.plantilla.size(), k.nombre]

	var p := EntradaCampeonato.previsualizar(m, "pagar", "CHI")
	_comprobar(int(p["cuota"]) == cuota, "B: cuota de afiliación = 25 %% de B (%s de %s)" % [_dinero(int(p["cuota"])), _dinero(b)])
	_comprobar(int(p["presupuesto"]) == b - cuota, "B: presupuesto de partida = 0,75 × B (%s)" % _dinero(int(p["presupuesto"])))
	_comprobar(int(p["rep"]) == Mundo.REP_FUNDACION - 20, "B: reputación = la de un club recién creado − 20 (%d)" % int(p["rep"]))
	_comprobar(int(p["confianza"]) == 40 and int(p["animo_delta"]) == -15, "B: confianza 40 y ánimo −15 en la previsualización")
	_comprobar(int(p["clubes_liga"]) == n0 + 1 and bool(p["descansos"]) == ((n0 + 1) % 2 == 1), "B: la liga pasa a %d clubes (descansos: %s)" % [n0 + 1, str(p["descansos"])])

	var c := EntradaCampeonato.aplicar(m, {"tipo": "pagar", "pais": "CHI"}, DATOS)
	_comprobar(c != null and not antes.has(c.id), "B: nace un club NUEVO (%s)" % (c.id if c != null else "null"))
	if c == null:
		return
	_comprobar(m.clubes.size() == total0 + 1 and l.clubes.size() == n0 + 1 and l.clubes.has(c), "B: un club más en el mundo y en la liga más baja")
	_comprobar(c.division == l.division(), "B: empieza en la división más baja (%d)" % c.division)
	_comprobar(c.rep == Mundo.REP_FUNDACION - 20, "B: reputación aplicada %d" % c.rep)
	_comprobar(c.saldo == b - cuota, "B: caja aplicada = 0,75 × B (%s)" % _dinero(c.saldo))
	_comprobar(m.directiva.confianza == 40, "B: confianza de la directiva 40 (%d)" % m.directiva.confianza)
	_comprobar(m.prensa.animo == animo_serie - 15, "B: ánimo de la afición −15 (%d → %d)" % [animo_serie, m.prensa.animo])
	var mov: Dictionary = m.libro_financiero.back() if not m.libro_financiero.is_empty() else {}
	_comprobar(int(mov.get("monto", 0)) == -cuota, "B: la cuota queda anotada en las finanzas (%s)" % _dinero(int(mov.get("monto", 0))))
	_comprobar(c.plantilla.size() >= 18, "B: plantel de club recién fundado (%d fichas)" % c.plantilla.size())
	var intacto := true
	for k: Club in m.clubes.values():
		if k != c and antes.get(k.id) != [k.rep, k.saldo, k.socios, k.plantilla.size(), k.nombre]:
			intacto = false
	_comprobar(intacto, "B: ningún otro club se toca")
	## El calendario con un club más: cada club juega 2·(n−1) partidos y nadie juega dos veces por jornada.
	var partidos := 0
	var doble := false
	for jornada: Array in l.calendario:
		var vistos: Dictionary = {}
		for par: Array in jornada:
			for k: Club in par:
				doble = doble or vistos.has(k.id)
				vistos[k.id] = true
			if par.has(c):
				partidos += 1
	_comprobar(partidos == 2 * n0 and not doble, "B: calendario rehecho: %d partidos para el club nuevo, sin dobles" % partidos)
	_comprobar(String(m.prensa.portadas[0]["t"]).contains("compra su plaza"), "B: portada «Un club compra su plaza»")
	_comprobar((EntradaCampeonato.pregunta_primera_rueda(p).get("opciones", []) as Array).size() == 3, "B: hay pregunta dura para la primera rueda")
	for _i in 8:
		if l.jornada_actual >= 1:
			break
		m.avanzar_semana()
	_comprobar(l.jornada_actual >= 1, "B: la liga de %d clubes juega su primera jornada sin romperse" % l.clubes.size())
	var tarde := EntradaCampeonato.previsualizar(m, "pagar", "CHI")
	_comprobar(tarde.has("error"), "B: con la liga empezada ya no se puede comprar plaza")
	var n_antes := m.clubes.size()
	_comprobar(EntradaCampeonato.aplicar(m, {"tipo": "pagar", "pais": "CHI"}, DATOS) == null and m.clubes.size() == n_antes, "B: y aplicar no toca nada")

func _probar_normalizar() -> void:
	_titulo("ENTRADA · VOCABULARIO COMPARTIDO CON EL ORQUESTADOR")
	var e := EntradaCampeonato.normalizar({"tipo": "confederacion"})
	_comprobar(String(e["modo"]) == "pagar", "«confederacion» se lee como «pagar»")
	e = EntradaCampeonato.normalizar({"entrada": "x", "reemplaza": "c7"})
	_comprobar(String(e["modo"]) == "reemplazar" and String(e["club_reemplazado"]) == "c7", "«reemplaza» se lee como el club reemplazado")
	var d := EntradaCampeonato.datos_de_config({"nombre_club": " Club X ", "col1": Color("ff0000"), "color2": "00ff00"})
	_comprobar(String(d["nombre"]) == "Club X" and String(d["color1"]) == "#ff0000" and String(d["color2"]) == "#00ff00", "los datos del club salen de la configuración (%s)" % str(d))
	## El orquestador es de otra zona: se carga en tiempo de ejecución para que un cambio suyo a medias no
	## rompa la compilación de esta prueba.
	var om: Variant = load("res://ui/entrada/orquestador_mundo.gd")
	if om is GDScript:
		var pagar := String((om as GDScript).get_script_constant_map().get("PAGAR", ""))
		_comprobar(String((om as GDScript).call("tipo_entrada", {"entrada": {"tipo": EntradaCampeonato.MODO_CONFEDERACION}})) == pagar,
			"el orquestador entiende «pagar» de esta pantalla")
	else:
		_linea("  (sin orquestador cargable: se omite la comprobación de vocabulario)")
