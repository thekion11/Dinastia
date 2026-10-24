extends "res://pruebas/banco_p16.gd"
## [Capa 18/27 de `banco.gd`] _probar_aspecto_y_audio, _probar_tutorial, _probar_moneda, _probar_academia, _probar_modos_simulacion

## LO QUE SE AÑADIÓ EN LA TANDA DE ASPECTO Y AUDIO. Comprueba lo que de verdad
## puede quedarse callado sin dar ningún error: una receta de sonido que sale en
## silencio, una pieza de música que no hace bucle, un idioma con la columna
## corta, un fondo que no rasteriza. Nada de esto lanza excepción; simplemente
## no se ve ni se oye, que es la peor clase de fallo.
func _probar_aspecto_y_audio() -> void:
	_titulo("ASPECTO Y AUDIO (fondos, clima, sonidos, musica, idiomas)")

	## LOS FONDOS. Veinticuatro, y todos tienen que rasterizar de verdad.
	_comprobar(Fondo.NOMBRES.size() == 24, "hay 24 fondos (%d)" % Fondo.NOMBRES.size())
	var sin_titulo: Array[String] = []
	var flacos: Array[String] = []
	for k: String in Fondo.NOMBRES:
		if not Fondo.TITULOS.has(k):
			sin_titulo.append(k)
		## Un SVG que no dibuja nada tambien "funciona": sale un string corto.
		if Fondo.svg_de(k).length() < 800:
			flacos.append(k)
	_comprobar(sin_titulo.is_empty(), "todos los fondos tienen nombre en el menu")
	_comprobar(flacos.is_empty(), "y todos dibujan algo (%s)" % ("ninguno vacio" if flacos.is_empty() else ", ".join(flacos)))
	var tex := Fondo.textura("aeropuerto")
	_comprobar(tex != null and tex.get_width() > 100, "un fondo nuevo rasteriza a imagen de verdad")

	## EL CLIMA. Diez modos, y el que no existe no puede reventar.
	_comprobar(FondoAnimado.MODOS.size() == 10, "hay 10 climas (%d)" % FondoAnimado.MODOS.size())
	_comprobar(FondoAnimado.MODOS.has("ninguno"), "y se puede apagar el movimiento")

	## LOS SONIDOS. Que existan no basta: tienen que tener onda.
	var cat: Array = Sonido.catalogo()
	_comprobar(cat.size() >= 60, "hay al menos 60 efectos (%d)" % cat.size())
	var mudos: Array[String] = []
	var largos: Array[String] = []
	for n: String in cat:
		var f: Dictionary = Sonido.ficha(n)
		if int(f.get("pico", 0)) < 200:
			mudos.append(n)
		if float(f.get("segundos", 0.0)) > 6.0:
			largos.append(n)
	_comprobar(mudos.is_empty(), "y ninguno sale en silencio (%s)" % ("todos suenan" if mudos.is_empty() else ", ".join(mudos)))
	_comprobar(largos.is_empty(), "y ninguno se pasa de 6 s (%s)" % ("ninguno" if largos.is_empty() else ", ".join(largos)))
	for pedido: String in ["clausula", "lesion_grave", "oferta", "contrato_vence",
			"obra", "venta", "ronda_superada"]:
		_comprobar(cat.has(pedido), "existe el sonido propio de «%s» que pedia el LEEME" % pedido)

	## Y QUE NO TOQUEN `Azar`. Es la regla que ya se rompio una vez en este
	## proyecto: un adorno que consume el generador determinista cambia la liga.
	var m := Mundo.new()
	m.generar(["CHI"], 4242)
	var antes := Azar.ent(0, 1000000)
	for i in 40:
		Sonido.toca("clic")
		Sonido.toca("gol")
	Azar.sembrar(4242)
	var despues_a := Azar.ent(0, 1000000)
	Azar.sembrar(4242)
	var despues_b := Azar.ent(0, 1000000)
	_comprobar(despues_a == despues_b, "el azar sigue siendo reproducible tras sembrar")
	_comprobar(antes >= 0, "  (referencia %d)" % antes)

	## LA MÚSICA. Seis piezas, con onda y en bucle.
	_comprobar(Musica.PIEZAS.size() == 6, "hay 6 piezas de musica (%d)" % Musica.PIEZAS.size())
	for clave: String in Musica.PIEZAS:
		var fm: Dictionary = Musica.ficha(clave)
		_comprobar(int(fm.get("pico", 0)) > 500, "«%s» suena (pico %d)" % [clave, int(fm.get("pico", 0))])
		_comprobar(bool(fm.get("bucle", false)), "  y esta en bucle")
		_comprobar(float(fm.get("segundos", 0.0)) > 15.0,
			"  y dura lo suyo (%.1f s)" % float(fm.get("segundos", 0.0)))

	## LOS IDIOMAS. Lo que se comprueba no es que la traduccion sea buena -eso no
	## lo sabe un banco- sino que ninguna fila se quede CORTA: una fila con menos
	## columnas que idiomas deja ese idioma en castellano sin avisar.
	_comprobar(Idiomas.ORDEN.size() == 8, "hay 8 idiomas ademas del castellano (%d)" % Idiomas.ORDEN.size())
	var cortas: Array[String] = []
	for k2: String in Idiomas.TABLA:
		var fila: Array = Idiomas.TABLA[k2]
		if fila.size() != Idiomas.COLUMNAS_TABLA:
			cortas.append(k2)
	_comprobar(cortas.is_empty(), "y ninguna fila se queda corta (%s)" % ("todas completas" if cortas.is_empty() else ", ".join(cortas)))
	for idi: String in Idiomas.ORDEN:
		## Al menos las de la tabla: los de columna, por la tabla; polaco y turco,
		## porque su diccionario la trae entera.
		_comprobar(Idiomas.cobertura(idi) >= Idiomas.TABLA.size(),
			"«%s» tiene al menos las %d frases (%d)" % [idi, Idiomas.TABLA.size(), Idiomas.cobertura(idi)])
	Idiomas.idioma = "en"
	_comprobar(Idiomas.t("Guardar") == "Save", "traducir funciona (Guardar -> %s)" % Idiomas.t("Guardar"))
	_comprobar(Idiomas.t("Una frase que no existe") == "Una frase que no existe",
		"y lo que no esta traducido se queda en castellano en vez de salir en blanco")
	## Ordinales y mayúsculas por idioma (MEGAPLAN fase 1).
	Idiomas.idioma = "fr"
	var o_fr := Idiomas.t("vas 1º (meta: 3º)")
	_comprobar(o_fr.contains("1er") and o_fr.contains("3e"), "francés: 1er y 3e (%s)" % o_fr)
	Idiomas.idioma = "ca"
	var o_ca := Idiomas.t("vas 2º (meta: 12º)")
	_comprobar(o_ca.contains("2n") and o_ca.contains("12è"), "catalán: 2n y 12è (%s)" % o_ca)
	Idiomas.idioma = "tr"
	_comprobar(Idiomas.mayusculas("lig") == "LİG", "turco: la i con punto en mayúscula (%s)" % Idiomas.mayusculas("lig"))
	Idiomas.idioma = "es"
	_comprobar(Idiomas.t("Guardar") == "Guardar", "y volver al castellano no deja nada traducido")

	## LAS FORMAS Y MARCAS DE TARJETA.
	_comprobar(MarcaPanel.ESTILOS.size() == 7, "hay 7 marcas de tarjeta (%d)" % MarcaPanel.ESTILOS.size())
	_comprobar(MarcaPanel.ESTILOS.has("ninguno"), "y se pueden quitar")

## EL GUION DEL TUTORIAL (25-9-2026). La interfaz la recorre
## `pruebas/captura_tutorial.gd`; aquí solo el guion de cada modo, que no
## necesita pantalla: todos terminan en "A jugar", cada modo trae su paso
## propio y ningún paso apunta a un control que `Principal` no sepa encontrar.
func _probar_tutorial() -> void:
	_titulo("TUTORIAL INMERSIVO")
	const OBJETIVOS := ["estado", "grupos", "chips", "plantel", "ficha", "dinero", "partido",
		"tabla", "registro", "calendario", "un_dia", "guardar"]
	const SIMPLES := ["grupo", "ficha", "grupo_club", "plantel", "dinero", "partido"]
	var modos := ["dt", "dir", "ayudante", "interino", "cantera", "imperio", "jeque", "creador"]
	## Con una partida de verdad: el mentor tiene que hablar de ELLA.
	var m := Mundo.new()
	m.generar(["CHI"], 5150)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	var ctx := Tutorial.contexto(m)
	var malos: Array[String] = []
	var prologos := {}
	var mentores := {}
	var misiones_por_modo := {}
	for modo: String in modos:
		var g := Tutorial.guion(modo, ctx)
		var pasos: Array = g["pasos"]
		prologos[String(g["prologo"])] = true
		mentores[String(g["mentor"]["cargo"])] = true
		if not String(g["prologo"]).contains(String(ctx["club"])) and modo != "interino":
			if not String(g["prologo"]).contains(String(g["mentor"]["nombre"])):
				malos.append("%s: el prólogo no nombra al club ni al mentor" % modo)
		if pasos.size() < 8 or not bool((pasos[pasos.size() - 1] as Dictionary).get("final", false)):
			malos.append("%s: %d pasos o sin epílogo" % [modo, pasos.size()])
		var misiones := 0
		for p: Dictionary in pasos:
			if p.has("mision"):
				misiones += 1
				if not p.has("hecho"):
					malos.append("%s: misión sin forma de cumplirse (%s)" % [modo, p["mision"]])
			if p.has("objetivo") and not OBJETIVOS.has(String(p["objetivo"])):
				malos.append("%s: objetivo %s" % [modo, p["objetivo"]])
			for k in ["hecho", "mostrar"]:
				if not p.has(k):
					continue
				var v := String(p[k])
				var ok := SIMPLES.has(v)
				if v.begins_with("tab:"):
					ok = Tutorial.PESTANAS.has(v.substr(4))
				elif v.begins_with("chip:"):
					ok = Tutorial.CHIPS.has(v.substr(5))
				elif v.begins_with("ficha:"):
					ok = false
					for j: Jugador in m.mi_club().plantilla:
						if j.id == v.substr(6):
							ok = true
				if not ok:
					malos.append("%s: %s %s" % [modo, k, v])
		misiones_por_modo[modo] = misiones
		if misiones < 4:
			malos.append("%s: solo %d misiones" % [modo, misiones])
	_linea("  misiones por modo: %s" % str(misiones_por_modo))
	_comprobar(malos.is_empty(), "el guion de los 8 modos es coherente %s" % str(malos))
	_comprobar(prologos.size() == 8, "cada modo tiene su propio prólogo (%d distintos)" % prologos.size())
	_comprobar(mentores.size() >= 6, "y su propio mentor (%d cargos distintos)" % mentores.size())
	var todo_dt := ""
	for p: Dictionary in Tutorial.guion("dt", ctx)["pasos"]:
		todo_dt += String(p["texto"]) + " " + String(p.get("mision", ""))
	_comprobar(String(ctx["rival"]) != "" and todo_dt.contains(String(ctx["rival"])), "el presidente habla del rival de verdad (%s)" % ctx["rival"])
	_comprobar(todo_dt.contains(String(ctx["estrella"].get("nombre", "?"))), "y de tu mejor jugador por su nombre (%s)" % ctx["estrella"].get("nombre", "?"))
	_comprobar(todo_dt.contains(String(ctx["objetivo"]).to_lower()), "y del objetivo del directorio (%s)" % ctx["objetivo"])
	var m1 := Tutorial.mentor_de("dt", ctx)
	_comprobar(m1["nombre"] == Tutorial.mentor_de("dt", ctx)["nombre"] and not Nombres.vetado(String(m1["nombre"])),
		"el mentor es siempre el mismo para el mismo club, e inventado (%s)" % m1["nombre"])
	_comprobar(Tutorial.pasos_para("dt", "Lautaro FC").size() >= 8, "sin partida también hay guion")

## LA MONEDA (25-9-2026). Una sola función escribe el dinero en todo el juego,
## con la moneda elegida. Se cambia `Eco.moneda` a mano, sin `elegir_moneda()`,
## para no tocar la preferencia guardada del jugador.
func _probar_moneda() -> void:
	_titulo("MONEDA SELECCIONABLE")
	var antes := Eco.moneda
	Eco.moneda = "EUR"
	## 1.000.008 y no 1.000.000: el millón no es múltiplo de `ECO` (12) y el
	## redondeo daba 999.996, que se escribe -bien- "999k".
	var un_millon := int(ceil(1000000.0 / Eco.ECO))
	_comprobar(Eco.dinero(un_millon) == "1.0M EUR", "un millón interno se escribe en euros (%s)" % Eco.dinero(un_millon))
	_comprobar(Eco.dinero(-un_millon).begins_with("-"), "y los negativos llevan signo (%s)" % Eco.dinero(-un_millon))
	Eco.moneda = "USD"
	_comprobar(Eco.dinero(un_millon) == "1.1M USD", "en dólares, al cambio fijo (%s)" % Eco.dinero(un_millon))
	Eco.moneda = "CLP"
	_comprobar(Eco.dinero(un_millon).ends_with("MM CLP"), "en pesos chilenos salta a miles de millones (%s)" % Eco.dinero(un_millon))
	## Las ocho copias que había se escribían distinto; ahora todas pasan por Eco.
	_comprobar(Cesiones.dinero(un_millon) == Eco.dinero(un_millon), "cesiones escribe igual que el resto")
	var todas_eco := true
	for ruta in ["res://ui/principal.gd", "res://ui/inicio.gd", "res://nucleo/prensa.gd",
			"res://ui/componentes/panel_mercado.gd", "res://ui/componentes/panel_finanzas.gd",
			"res://ui/componentes/panel_plantel.gd", "res://ui/componentes/ficha_jugador_acciones.gd"]:
		var f := FileAccess.open(ruta, FileAccess.READ)
		var texto := f.get_as_text()
		f.close()
		for linea in texto.split("\n"):
			if linea.strip_edges().begins_with("#"):
				continue
			if linea.contains("M EUR\"") or linea.contains("\"$%d\""):
				todas_eco = false
	_comprobar(todas_eco, "ninguna pantalla escribe \"EUR\" ni \"$\" a mano")
	Eco.moneda = antes

## LA ACADEMIA DE 10 A 16 AÑOS (25-9-2026). Cada regla de `Academia` con un
## número: formar bien se nota, comer mal se nota, el colegio se nota, y lo que
## llega al primer equipo a los 16 es consecuencia de todo eso.
func _probar_academia() -> void:
	_titulo("ACADEMIA: LOS CHICOS DE 10 A 16")
	Azar.sembrar(1016)
	var m := Mundo.new()
	m.generar(["CHI"], 1016)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var a := m.academia
	_comprobar(a != null and a.chicos.size() == 6, "la academia arranca con seis chicos (%d)" % (a.chicos.size() if a != null else 0))
	if a == null:
		return
	var edades := {}
	for ch in a.chicos:
		edades[int(ch["edad"])] = true
	_comprobar(edades.size() == 6 and edades.has(10) and edades.has(15), "de 10 a 15 años, uno por edad")
	_comprobar(a.candidatos.size() == Academia.CANDIDATOS_POR_TEMPORADA, "y %d candidatos para captar" % a.candidatos.size())

	## Dos gemelos de laboratorio: mismo chico, dos formaciones opuestas.
	var base: Dictionary = a.chicos[0].duplicate(true)
	base["nivel"] = 30.0; base["techo"] = 80; base["fisico"] = 45.0; base["nota"] = 5.0; base["animo"] = 70.0
	base["personalidad"] = {"disciplina": 50.0, "liderazgo": 40.0, "temple": 40.0, "ambicion": 40.0}
	var bien: Dictionary = base.duplicate(true)
	bien.merge({"plan": "tecnico", "dieta": "deportiva", "estudios": "futbol", "molde": "disciplina"}, true)
	var mal: Dictionary = base.duplicate(true)
	mal.merge({"plan": "descanso", "dieta": "libre", "estudios": "estudios", "molde": "liderazgo"}, true)
	for sem in 76:
		bien["lesion"] = 0
		mal["lesion"] = 0
		a._semana_de(bien)
		a._semana_de(mal)
	_linea("  dos temporadas: bien formado nivel %.1f / físico %.0f / nota %.1f   |   mal formado nivel %.1f / físico %.0f / nota %.1f" % [
		float(bien["nivel"]), float(bien["fisico"]), float(bien["nota"]),
		float(mal["nivel"]), float(mal["fisico"]), float(mal["nota"])])
	_comprobar(float(bien["nivel"]) > float(mal["nivel"]) + 3.0, "entrenar técnico, comer bien y priorizar el fútbol hace crecer más")
	_comprobar(float(bien["fisico"]) > float(mal["fisico"]) + 10.0, "el plan de nutricionista desarrolla el cuerpo más que el comedor libre")
	_comprobar(float(bien["nota"]) < float(mal["nota"]), "pero priorizar el fútbol hunde las notas y priorizar el colegio las sube")
	_comprobar(float(bien["nivel"]) < 80.0, "y nadie supera su techo (%.1f < 80)" % float(bien["nivel"]))
	_comprobar(float(mal["personalidad"]["liderazgo"]) > 70.0, "el molde forja carácter: liderazgo de 40 a %.0f" % float(mal["personalidad"]["liderazgo"]))
	_comprobar(a.rasgo_dominante(mal) == "liderazgo", "y ese carácter domina")
	_comprobar(a.techo_al_entregar(bien) > a.techo_al_entregar(mal), "la formación sube el techo con el que llega (%d contra %d)" % [
		a.techo_al_entregar(bien), a.techo_al_entregar(mal)])

	## La familia: con notas hundidas, primero avisa el colegio y luego se lo llevan.
	var flojo: Dictionary = base.duplicate(true)
	flojo.merge({"id": "flojo", "nota": 3.0, "estudios": "futbol", "aviso_notas": false}, true)
	a.chicos.append(flojo)
	var hubo_aviso := false
	var se_fue := false
	for sem in 150:
		for s2 in a.procesar_semana():
			if String(s2["id"]) == "flojo":
				hubo_aviso = hubo_aviso or String(s2["tipo"]) == "aviso"
				se_fue = se_fue or String(s2["tipo"]) == "abandono"
		if se_fue:
			break
	_comprobar(hubo_aviso and se_fue, "con notas hundidas avisa el colegio y la familia acaba sacándolo")
	_comprobar(a.chico("flojo").is_empty(), "y deja de estar en la academia")

	## La residencia cuesta: la semana descuenta la caja.
	var c := m.mi_club()
	var antes := c.saldo
	a.procesar_semana()
	_comprobar(c.saldo < antes, "la residencia se paga cada semana (%s)" % Eco.dinero(antes - c.saldo))

	## Captar: cuesta, ocupa plaza y respeta el cupo.
	var n_antes := a.chicos.size()
	var err := a.captar(0)
	_comprobar(err == "" and a.chicos.size() == n_antes + 1, "captar a un candidato lo trae a la residencia %s" % err)
	while a.chicos.size() < Academia.CUPO:
		a.chicos.append(a._nuevo_chico(10))
	_comprobar(a.captar(0) != "", "con la residencia llena no se capta a nadie más")

	## Entrega: a los 16 pasa al plantel como Jugador de verdad.
	var chico15: Dictionary = {}
	for ch in a.chicos:
		if int(ch["edad"]) == 15:
			chico15 = ch
	if chico15.is_empty():
		chico15 = a.chicos[0]
		chico15["edad"] = 15
	chico15["personalidad"]["liderazgo"] = 92.0
	var nombre15 := String(chico15["nombre"])
	var de14: Dictionary = a._nuevo_chico(14)
	a.chicos.append(de14)
	_comprobar(a.entregar(String(de14["id"])) != "", "no se puede entregar a uno de 14")
	while c.plantilla.size() >= Cantera.TOPE_PLANTEL:
		c.plantilla.pop_back()
	var entregados := a.fin_de_temporada()
	var nuevo: Jugador = null
	for j in entregados:
		if j.nombre == nombre15:
			nuevo = j
	_comprobar(nuevo != null, "al cumplir 16 pasa al primer equipo")
	if nuevo != null:
		_comprobar(c.plantilla.has(nuevo) and nuevo.edad == 16, "con 16 años y dentro de la plantilla")
		_comprobar(nuevo.pot >= nuevo.ovr and nuevo.ovr >= 40, "media %d, proyección %d" % [nuevo.ovr, nuevo.pot])
		_comprobar(nuevo.rasgo == "lider", "el carácter que forjaste es su rasgo (%s)" % nuevo.rasgo)
		_comprobar(m.cantera.es_canterano(nuevo), "y cuenta como canterano de la casa")
		_comprobar(a.chico(String(chico15["id"])).is_empty(), "y deja la academia")
	_comprobar(a.candidatos.size() == Academia.CANDIDATOS_POR_TEMPORADA, "la temporada nueva trae otra tanda de candidatos")

	## El guardado se la lleva entera.
	var ids: Array[String] = []
	for ch in a.chicos:
		ids.append(String(ch["id"]))
	var foto := Partida.instantanea(m)
	var m2 := Partida.desde_instantanea(foto)
	var ids2: Array[String] = []
	if m2 != null and m2.academia != null:
		for ch in m2.academia.chicos:
			ids2.append(String(ch["id"]))
	_comprobar(ids2 == ids, "guardar y cargar conserva a los %d chicos" % ids.size())


## LOS CINCO MODOS DE MIRAR UN PARTIDO (25-9-2026, plan maestro B2). Con la
## misma semilla, el partido jugado de una vez (Instantáneo), el Resumen y el
## partido en vivo tienen que dar EXACTAMENTE lo mismo: mirar no decide nada.
## El 3D usa los mismos `simular_minuto()` a su propio ritmo. Se juega con la
## grada al límite (ánimo 10) y a varias semillas para que la invasión de
## campo -que antes solo tiraba el partido en vivo- entre en juego.
func _probar_modos_simulacion() -> void:
	_titulo("MODOS DE SIMULACIÓN: MISMO PARTIDO, DISTINTA VISTA")
	## Un mundo por camino, idénticos (misma semilla): un partido le cambia a
	## los jugadores el físico, las lesiones y las tarjetas, así que reusar los
	## mismos clubes haría que el segundo camino jugara con otro plantel.
	var mundos: Array[Mundo] = []
	for via in 3:
		var mv := Mundo.new()
		mv.generar(["CHI"], 77)
		mundos.append(mv)
	var iguales := 0
	var invasiones := 0
	var semillas := 40
	for k in semillas:
		var huellas: Array[String] = []
		for via in 3:
			var l := mundos[via].ligas[0]
			var a: Club = l.clubes[k % l.clubes.size()]
			var b: Club = l.clubes[(k + 3) % l.clubes.size()]
			Azar.sembrar(9000 + k)
			var p := Partido.new(a, b)
			match via:
				0:
					p.preparar()
					p.fijar_hinchada(a, 10)
					while not p.terminado_ya:
						p.simular_minuto()
				1:
					p.preparar()
					p.fijar_hinchada(a, 10)
					var capa := Control.new()
					var r := ResumenPartido.mostrar(capa, p, a, false, true)
					r.free()
					capa.free()
				2:
					## El partido en vivo sin 3D, saltado al final.
					p.fijar_hinchada(a, 10)
					var vivo := PartidoVivo.new()
					vivo.con_3d = false
					vivo.abrir(p, a)
					vivo.call("_hasta_el_final")
					vivo.free()
			huellas.append("%d-%d|%d|%s" % [p.goles_local, p.goles_visita, p.cronica.size(), str(p.invasion_ya)])
			if via == 0 and p.invasion_ya:
				invasiones += 1
		if huellas[0] == huellas[1] and huellas[1] == huellas[2]:
			iguales += 1
		elif iguales == k:
			print("    distinto en la semilla %d: %s" % [9000 + k, str(huellas)])
	_comprobar(iguales == semillas, "Instantáneo, Resumen y En vivo dan el mismo partido en %d de %d semillas" % [iguales, semillas])
	_comprobar(invasiones > 0, "la invasión de campo sigue pudiendo ocurrir, ahora en cualquier modo (%d de %d)" % [invasiones, semillas])
	## EL DESCANSO NO BLOQUEA (28-9-2026, informe externo: "después de la charla
	## del medio tiempo no deja continuar"). Se juega con el reloj real: se
	## para en el 45, se da la charla, se sale y el partido termina.
	var mh := mundos[0]
	var lh := mh.ligas[0]
	var ph := Partido.new(lh.clubes[0], lh.clubes[1])
	var vh := PartidoVivo.new()
	vh.con_3d = false
	vh.abrir(ph, lh.clubes[0], mh.vestuario)
	var vueltas := 0
	## Una lesión propia para el reloj a propósito (hay que mover el banco):
	## la prueba reanuda como lo haría el jugador.
	var reanudar := func() -> void:
		if int(vh.get("_velocidad")) == 0 and not bool(vh.get("_entretiempo")):
			vh.call("_poner_velocidad", 2)
	while ph.minuto < 45 and vueltas < 2000:
		reanudar.call()
		vh._process(1.0)
		vueltas += 1
	var parado := bool(vh.get("_entretiempo"))
	var min_parado := ph.minuto
	for _i in 20:
		vh._process(1.0)
	_comprobar(parado and ph.minuto == min_parado, "el reloj se para en el descanso (%d')" % min_parado)
	vh.call("_dar_charla", String(Vestuario.TONOS.keys()[0]))
	vh.call("_salir_segunda")
	vueltas = 0
	while not ph.terminado_ya and vueltas < 5000:
		reanudar.call()
		vh._process(1.0)
		vueltas += 1
	_comprobar(ph.terminado_ya, "tras la charla y salir a la segunda parte, el partido llega al final")
	vh.free()
