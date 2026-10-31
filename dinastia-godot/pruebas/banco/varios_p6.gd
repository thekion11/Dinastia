extends "res://pruebas/banco/varios_p5.gd"
## [Capa 6/10 de `varios.gd`] _probar_dinastias, _probar_rotulo_y_sala, _probar_mesa_agente, _probar_plantillas_fijas, _probar_aspecto_y_audio, _probar_tutorial … (+1)

## DINASTÍAS FAMILIARES (fase 5): tu hijo llega a la cantera que diriges.
func _probar_dinastias() -> void:
	_titulo("DINASTÍAS FAMILIARES (FASE 5)")
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	var mio := m.mi_club()
	while mio.plantilla.size() > 26:
		mio.plantilla.pop_back()
	## 1) Leyenda propia (de la Carrera de Jugador).
	m.cantera.leyendas.append({"nombre": "Ramiro Valdivia", "club_id": m.ligas[0].clubes[7].id, "pos": "DEL",
		"nivel": 86, "anio_hijo": m.anio, "usado": false, "propio": true})
	var copia := Cantera.new(m)
	copia.desde_dic(m.cantera.a_dic())
	var guardado_propio := false
	for L: Dictionary in copia.leyendas:
		if String(L["nombre"]) == "Ramiro Valdivia" and bool(L.get("propio", false)):
			guardado_propio = true
	_comprobar(guardado_propio, "la dinastía propia sobrevive al guardado")
	m.cantera.call("_hijos_de_leyendas")
	var hijo: Jugador = null
	for j: Jugador in mio.plantilla:
		if j.nombre.ends_with("Valdivia"):
			hijo = j
	_comprobar(hijo != null, "el hijo de tu jugador retirado llega a TU cantera (no a otro club)")
	if hijo != null:
		_comprobar(hijo.edad <= 17 and hijo.pot > hijo.ovr, "llega joven y con techo (%d años, %d → %d)" % [hijo.edad, hijo.ovr, hijo.pot])
	## 2) El hijo del entrenador (familia de VidaDT) al cumplir 16.
	m.vida.perfil = {"pareja": "", "hijos": [{"nombre": "Mateo", "edad": 15}], "mascota": "", "anio0": m.anio - 1}
	m.cantera.call("_hijos_del_dt")
	var del_dt := false
	for j2: Jugador in mio.plantilla:
		if j2.nombre.begins_with("Mateo "):
			del_dt = true
	_comprobar(del_dt, "el hijo del míster entra en la cantera al cumplir 16")

## LA CIUDAD GRANDE (7-10-2026): red vial en datos, semáforos, transporte.
func _probar_rotulo_y_sala() -> void:
	## 15-10-2026: el rótulo de la fachada y la sala de dentro se sorteaban por
	## separado («Farmacia» que abría un taller). Ahora manda el rótulo.
	_titulo("CIUDAD: LO QUE DICE EL RÓTULO ES LO QUE HAY DENTRO")
	var sin_sala: Array = []
	for com: Array in CiudadExpansion.COMERCIOS:
		var texto := String(com[0])
		var nombre := texto.substr(texto.find(" ") + 1)
		var k := String(ExploradorCiudad.SALA_DE_ROTULO.get(nombre, ""))
		if k == "" or not InteriorInstalacion.tiene(k):
			sin_sala.append(nombre)
	_comprobar(sin_sala.is_empty(), "los %d comercios tienen una sala que existe %s" % [CiudadExpansion.COMERCIOS.size(), str(sin_sala)])
	var cb := CityBuilder.new()
	cb.expansion = CiudadExpansion.new(cb)
	cb.expansion.rotulos = [
		{"pos": Vector3(100, 0, 50), "ancho": 8.0, "texto": "💊 Farmacia"},
		{"pos": Vector3(110, 0, 50), "ancho": 8.0, "texto": "🥖 Panadería"},
	]
	var ex := ExploradorCiudad.new()
	ex.cb = cb
	_comprobar(String(ex._rotulo_en(Vector3(101, 0, 51)).get("texto", "")) == "💊 Farmacia", "la puerta de la farmacia es la de la farmacia")
	_comprobar(String(ex._rotulo_en(Vector3(109, 0, 51)).get("texto", "")) == "🥖 Panadería", "y la de al lado, la de la panadería")
	_comprobar(ex._rotulo_en(Vector3(140, 0, 50)).is_empty(), "lejos de los rótulos no hay rótulo")
	ex.free()
	cb.free()
	## OCLUSIÓN (21-10-2026): 4 paredes por edificio grande; ni quioscos ni estadio.
	var cbo := CityBuilder.new()
	cbo._frentes = [Rect2(300, 300, 20, 30), Rect2(400, 400, 4, 4)] as Array[Rect2]
	cbo.huellas = [Rect2(300, 300, 20, 30), Rect2(CityBuilder.ESTADIO_EN.x - 10.0, CityBuilder.ESTADIO_EN.z - 10.0, 20, 20), Rect2(-500, 200, 12, 12)] as Array[Rect2]
	var raiz_o := OclusoresCiudad.montar(cbo)
	_comprobar(OclusoresCiudad.cuantas(cbo) == 8, "oclusión: 2 edificios grandes = 8 paredes (sin quiosco, sin estadio, sin repetir) → %d" % OclusoresCiudad.cuantas(cbo))
	OclusoresCiudad.activar(cbo, false)
	_comprobar(not raiz_o.visible, "oclusión: se apaga al entrar en un edificio")
	cbo.free()
	## EL CHOQUE DEL COCHE (21-10-2026, M-172): golpe y multa contra otro coche.
	var exc := ExploradorCiudad.new()
	exc.modo = "coche"
	exc._golpe_coche(12.0, false)
	_comprobar(exc.multas == 1 and exc._sacudida_golpe > 0.0, "chocar a 43 km/h contra otro coche: golpe y multa")
	exc._golpe_coche(12.0, false)
	_comprobar(exc.multas == 1, "rozando no se multa en bucle (un golpe cada medio segundo)")
	var exc2 := ExploradorCiudad.new()
	exc2._golpe_coche(5.0, false)
	var exc3 := ExploradorCiudad.new()
	exc3._golpe_coche(12.0, true)
	_comprobar(exc2.multas == 0 and exc3.multas == 0 and exc3._sacudida_golpe > 0.0, "despacio, o contra una pared, golpe sin multa")
	exc.free()
	exc2.free()
	exc3.free()
	_comprobar(Sonido.NOMBRES.has("choque_coche") and not Sonido._sintetizar("choque_coche", 1.0).data.is_empty(), "el choque de coche suena")

## FASE 4: el mini-juego de representantes (la mesa de regateo).
func _probar_mesa_agente() -> void:
	_titulo("MINI-JUEGO DE REPRESENTANTES (FASE 4)")
	var ex := {"tipo": "mejora", "agente": "R. Prueba", "perfil": "discreto", "pid": "j1"}
	var m := MesaAgente.new(ex, 0, 0.0, 7)
	m.ceder()
	_comprobar(m.estado == "acuerdo" and is_equal_approx(m.fraccion(), 1.0), "ceder cierra al 100 %")
	var sin_favor := MesaAgente.new(ex, 0, 0.0, 7)
	m = MesaAgente.new(ex, 0, 0.0, 7)
	m.aplicar_favor()
	_comprobar(m.pide == 95 and m.minimo == maxi(20, sin_favor.minimo - 5), "con el favor del agente (cita en persona) pide un 5 %% menos y su mínimo baja (%d → %d)" % [sin_favor.minimo, m.minimo])
	m = MesaAgente.new(ex, 0, 0.0, 7)
	m.plantarse()
	_comprobar(m.estado == "plantado" and m.fraccion() < 0.0, "plantarse es un no")
	m = MesaAgente.new(ex, 0, 0.0, 7)
	var rondas := 0
	while m.estado == "abierta" and rondas < 20:
		m.regatear(0)
		rondas += 1
	_comprobar(m.estado == "se_fue" and rondas <= m.paciencia_max, "ofrecer nada lo ofende: se va en %d rondas (paciencia %d)" % [rondas, m.paciencia_max])
	m = MesaAgente.new(ex, 0, 0.0, 7)
	m.farol()
	var pide := m.pide
	var pac := m.paciencia
	m.farol()
	_comprobar(m.farol_usado and m.pide == pide and m.paciencia == pac, "un solo farol por mesa")
	## Una estrategia sensata (la oferta del medio; ceder a la última taza)
	## saca tratos mejores al formador que al tiburón, y casi siempre cierra.
	var medias := {}
	for perfil: String in ["formador", "tiburon"]:
		var suma := 0.0
		var tratos := 0
		for k in 300:
			var mm := MesaAgente.new({"tipo": "comision", "agente": "A%d" % k, "perfil": perfil}, 0, 0.0, 1000 + k)
			while mm.estado == "abierta":
				if mm.paciencia <= 1:
					mm.ceder()
				else:
					var o := mm.ofertas()
					mm.regatear(o[mini(1, o.size() - 1)])
			if mm.estado == "acuerdo":
				tratos += 1
				suma += float(mm.acordado)
		medias[perfil] = suma / maxf(1.0, float(tratos))
		_comprobar(tratos >= 240, "%s: %d de 300 mesas cierran con trato" % [perfil, tratos])
	_comprobar(float(medias["formador"]) + 8.0 < float(medias["tiburon"]), "el formador cede más que el tiburón (%.0f %% / %.0f %%)" % [medias["formador"], medias["tiburon"]])
	_comprobar(float(medias["tiburon"]) < 99.0, "regatear sirve: al tiburón tampoco se le paga siempre todo (%.0f %%)" % medias["tiburon"])
	## El trato se aplica a escala: una mejora al 50 % sube el sueldo un 15 %.
	var w := Mundo.new()
	w.generar(["CHI"], 31)
	w.tomar_el_mando(w.ligas[0].clubes[0].id)
	var j: Jugador = w.mi_club().plantilla[0]
	var antes := j.sueldo
	w.cantera.exigencia = {"tipo": "mejora", "agente": "R. Prueba", "pid": j.id, "ids": [j.id], "perfil": "discreto"}
	var r := w.cantera.resolver_agente("a", 0.5)
	_comprobar(absi(j.sueldo - int(round(float(antes) * 1.15))) <= 1, "mejora pactada al 50 %%: sueldo %d → %d (+15 %%)" % [antes, j.sueldo])
	_comprobar(String(r.get("cuerpo", "")).contains("50 %"), "la noticia cuenta lo pactado en la mesa")

## FASE 4: las plantillas de arranque son las mismas con cualquier semilla y
## con cualquier mezcla de países cargados (sembradas con el nombre del club).
func _probar_plantillas_fijas() -> void:
	_titulo("PLANTILLAS FIJAS DE ARRANQUE (FASE 4)")
	var a := Mundo.new()
	a.generar(["CHI", "GER"], 5)
	var b := Mundo.new()
	b.generar(["CHI", "ARG", "GER", "ESP"], 424242)
	var firma := func(c: Club) -> Array:
		var f: Array = []
		for j: Jugador in c.plantilla:
			f.append("%s|%s|%d|%d|%d" % [j.nombre, j.pos_e, j.edad, j.ovr, j.pot])
		f.sort()
		return f
	var por_nombre := {}
	for c: Club in b.clubes.values():
		por_nombre[c.nombre] = c
	var iguales := 0
	var sin_reales := 0
	var total := 0
	for c: Club in a.clubes.values():
		if not por_nombre.has(c.nombre):
			continue
		total += 1
		var reales := 0
		for j: Jugador in c.plantilla:
			if j.real:
				reales += 1
		if reales == 0:
			sin_reales += 1
		if firma.call(c) == firma.call(por_nombre[c.nombre]):
			iguales += 1
	_comprobar(total >= 40, "%d clubes (Chile y Alemania) en los dos mundos" % total)
	_comprobar(iguales == total, "misma plantilla (nombre, puesto, edad, media, potencial) con otra semilla y otros países: %d de %d" % [iguales, total])
	_comprobar(sin_reales >= 1, "incluye clubes sin tabla REALES (%d)" % sin_reales)
	## Los canteranos que llegan después siguen siendo de cada partida.
	var j1 := a.crear_jugador(a.ligas[0].clubes[0], "DEL", "DC")
	var j2 := b.crear_jugador(a.ligas[0].clubes[0], "DEL", "DC")
	_comprobar(j1.nombre != j2.nombre or j1.ovr != j2.ovr, "lo que nace después varía con la semilla (%s / %s)" % [j1.nombre, j2.nombre])


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
