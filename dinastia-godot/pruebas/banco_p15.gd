extends "res://pruebas/banco_p14.gd"
## [Capa 16/27 de `banco.gd`] _probar_ideas_del_documento, _probar_marca, _probar_carga_de_ui, _probar_narracion_traducida, _frases_de_idiomas_t, _probar_paridad_idiomas … (+1)

func _probar_ideas_del_documento() -> void:
	_titulo("LO QUE PEDIA EL DOCUMENTO (ventana, FPF, desgaste, staff, fondos)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 1717)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	mio.mover_saldo(80000000)

	## LA VENTANA DE MERCADO. Dos por temporada, como en el HTML.
	m.semana = 1
	_comprobar(m.mercado_abierto(), "en la semana 1 el mercado esta abierto")
	m.semana = Mundo.VENTANA_VERANO
	_comprobar(m.mercado_abierto() and m.semanas_de_mercado() == 1,
		"la ultima semana de la ventana de verano avisa de que queda una")
	m.semana = Mundo.VENTANA_VERANO + 1
	_comprobar(not m.mercado_abierto(), "y a la siguiente ya esta cerrado")
	_comprobar(m.semanas_hasta_mercado() > 0, "y dice cuanto falta para la siguiente (%d semanas)" % m.semanas_hasta_mercado())
	m.semana = Mundo.VENTANA_INVIERNO_INI + 1
	_comprobar(m.mercado_abierto(), "la ventana de invierno vuelve a abrir")
	m.semana = Mundo.VENTANA_INVIERNO_FIN + 1
	_comprobar(not m.mercado_abierto(), "y cierra a su hora")
	_linea("  %s" % m.texto_de_mercado())

	## EL FAIR PLAY FINANCIERO. Dos temporadas gastando de mas y hay multa.
	var fed := m.federacion
	_comprobar(not fed.fpf_activo, "el fair play financiero no esta en vigor de entrada")
	_comprobar(fed.revisar_fair_play(mio, 95) == "", "y sin estar en vigor no juzga a nadie")
	fed.fpf_activo = true
	_comprobar(fed.revisar_fair_play(mio, 95) == "aviso", "la primera temporada por encima es un aviso")
	var caja := mio.saldo
	_comprobar(fed.revisar_fair_play(mio, 95) == "sancion", "la segunda es sancion")
	_comprobar(mio.saldo < caja, "con multa de verdad (%s)" % _dinero(caja - mio.saldo))
	_comprobar(not fed.puede_pagar_traspaso(), "y con el mercado de pago cerrado")
	fed.revisar_fair_play(mio, 40)
	_comprobar(fed.puede_pagar_traspaso() and fed.fpf_avisos == 0,
		"cuadrar las cuentas cierra el expediente")

	## EL DESGASTE DEL ENTRENADOR.
	var r := m.roles
	_comprobar(r.desgaste == 0, "se empieza entero")
	for i in 40:
		r.semana_desgaste(false, 80)
	_linea("  cuarenta semanas perdiendo y con funa: desgaste %d" % r.desgaste)
	_comprobar(r.quemado(), "cuarenta semanas malas queman al entrenador")
	_comprobar(r.factor_desgaste() < 1.0, "y quemado, lo que dices en rueda vale menos")
	for i in 30:
		r.semana_desgaste(true, 0)
	_linea("  treinta semanas ganando: desgaste %d" % r.desgaste)
	_comprobar(not r.quemado(), "ganando se recupera")

	## EL CURRICULUM.
	_comprobar(r.curriculum.size() == 1, "hay un capitulo abierto en tu club actual")
	var otro: Club = m.ligas[1].clubes[0]
	m.tomar_el_mando(otro.id)
	_comprobar(m.roles.curriculum.size() == 2, "cambiar de club abre un capitulo nuevo (%d)" % m.roles.curriculum.size())
	var primero: Dictionary = m.roles.curriculum[0]
	_comprobar(int(primero["hasta"]) > 0, "y cierra el anterior con su año de salida")
	_linea("  curriculum: %s" % ", ".join(m.roles.curriculum.map(func(c: Dictionary) -> String:
		return "%s %d-%s" % [String(c["nombre"]), int(c["desde"]),
			"hoy" if int(c["hasta"]) == 0 else str(int(c["hasta"]))])))

	## EL CUERPO TECNICO NUEVO. Los seis puestos que pedian las ideas 91-105.
	var st := m.staff
	for p: String in ["arqueros", "nutri", "seg", "traductor", "cm", "utilero"]:
		_comprobar(Staff.PUESTOS.has(p), "existe el puesto «%s»" % p)
	m.mi_club().mover_saldo(90000000)
	st.subir("arqueros", m.mi_club())
	_comprobar(st.bono_portero() > 0.0, "el entrenador de arqueros suma a la defensa")
	st.subir("nutri", m.mi_club())
	_comprobar(st.recuperacion_fisica() > 0, "el nutricionista acelera la recuperacion")
	st.subir("seg", m.mi_club())
	_comprobar(st.bono_seguridad() > 0.0, "el jefe de seguridad baja el riesgo de incidente")
	st.subir("traductor", m.mi_club())
	_comprobar(st.adaptacion_extranjeros() < 1.0, "el traductor amortigua la adaptacion")
	st.subir("cm", m.mi_club())
	_comprobar(st.empuje_redes() > 0.0, "el community manager suma seguidores")
	## Y el sueldo del cuerpo tecnico sube al contratar: si no, contratar seria
	## gratis y no habria que elegir.
	var s0 := st.sueldo_semanal(m.mi_club().rep)
	st.subir("utilero", m.mi_club())
	_comprobar(st.sueldo_semanal(m.mi_club().rep) > s0,
		"y cada puesto nuevo pesa en la nomina (%s -> %s)" % [_dinero(s0), _dinero(st.sueldo_semanal(m.mi_club().rep))])

	## LOS FONDOS DE INVERSION.
	var ce := m.cesiones
	var joven: Jugador = null
	for j: Jugador in m.mi_club().plantilla:
		if j.edad <= 23:
			joven = j
			break
	if joven != null:
		var caja2 := m.mi_club().saldo
		_comprobar(ce.participacion_de(joven) == 0, "de entrada nadie tiene derechos de tus canteranos")
		_comprobar(ce.vender_participacion(joven, "delta", 25, m.mi_club()) == "",
			"se puede vender el 25% de un futuro traspaso")
		_comprobar(m.mi_club().saldo > caja2, "y entra dinero hoy (%s)" % _dinero(m.mi_club().saldo - caja2))
		_comprobar(ce.participacion_de(joven) == 25, "queda apuntado el 25%")
		_comprobar(ce.vender_participacion(joven, "delta", 40, m.mi_club()) != "",
			"y no se puede pasar del %d%% de un mismo jugador" % Cesiones.PCT_MAX)
		_comprobar(ce.neto_de_venta(joven, 1000) == 750,
			"al venderlo, el club se queda el 75%% (%d de 1000)" % ce.neto_de_venta(joven, 1000))
		var viejo: Jugador = null
		for j2: Jugador in m.mi_club().plantilla:
			if j2.edad > 23:
				viejo = j2
				break
		if viejo != null:
			_comprobar(ce.vender_participacion(viejo, "delta", 25, m.mi_club()) != "",
				"los fondos no compran derechos de veteranos")

	## LA OCUPACIÓN HOSTIL Y EL FICHAJE COMERCIAL. Los dos dejan un "impuesto"
	## -un jugador que TIENE que salir de titular- y `Prensa.revisar_impuesto()`
	## es quien lo cobra tras cada partido si no jugó.
	var pr := m.prensa
	var figura: Jugador = m.mi_club().plantilla[0]
	var st2 := m.staff
	st2.subir("ayudante", m.mi_club())
	var nivel_antes := st2.nivel("ayudante")
	pr.pendiente = {"id": "hostil", "pid": figura.id, "txt": "", "opcion_a": "", "opcion_b": ""}
	var conf_antes := m.directiva.confianza
	pr.resolver("a")
	_comprobar(pr.impuesto_pid == figura.id, "aceptar la ocupacion hostil impone al fichaje franquicia")
	_comprobar(pr.impuesto_hasta == -1, "y no tiene fecha de vencimiento")
	_comprobar(m.directiva.confianza > conf_antes, "el dueño respalda: sube la confianza (%d -> %d)" % [conf_antes, m.directiva.confianza])
	_comprobar(st2.nivel("ayudante") <= nivel_antes, "y purga algo del cuerpo tecnico (nivel %d -> %d)" % [nivel_antes, st2.nivel("ayudante")])

	## Si NO sale de titular, el patrocinador lo cobra.
	var xi_sin_el: Array[Jugador] = m.mi_club().plantilla.filter(func(j: Jugador) -> bool: return j.id != figura.id).slice(0, 10)
	var caja3 := m.mi_club().saldo
	pr.revisar_impuesto(m.mi_club(), xi_sin_el, m.anio)
	_comprobar(m.mi_club().saldo < caja3, "dejarlo en la reserva cuesta plata (%s)" % _dinero(caja3 - m.mi_club().saldo))

	## Si SÍ sale, no pasa nada.
	var xi_con_el: Array[Jugador] = xi_sin_el.duplicate()
	xi_con_el.append(figura)
	var caja4 := m.mi_club().saldo
	pr.revisar_impuesto(m.mi_club(), xi_con_el, m.anio)
	_comprobar(m.mi_club().saldo == caja4, "y alinearlo no cuesta nada")

	## El trato comercial SÍ vence al pasar de año; la ocupacion hostil no.
	pr.impuesto_pid = figura.id
	pr.impuesto_hasta = m.anio
	pr.revisar_impuesto(m.mi_club(), xi_con_el, m.anio + 1)
	_comprobar(pr.impuesto_pid == "", "el trato comercial se cae solo al cerrar la temporada pactada")

	pr.pendiente = {"id": "comercial", "pid": figura.id, "txt": "", "opcion_a": "", "opcion_b": ""}
	var caja5 := m.mi_club().saldo
	pr.resolver("a")
	_comprobar(pr.impuesto_pid == figura.id and pr.impuesto_hasta == m.anio,
		"el fichaje comercial impone al mismo jugador solo por esta temporada")
	_comprobar(m.mi_club().saldo > caja5, "y entra plata de patrocinio (%s)" % _dinero(m.mi_club().saldo - caja5))

	pr.pendiente = {"id": "comercial", "pid": figura.id, "txt": "", "opcion_a": "", "opcion_b": ""}
	var conf_antes2 := m.directiva.confianza
	var caja6 := m.mi_club().saldo
	pr.resolver("b")
	_comprobar(m.directiva.confianza < conf_antes2, "rechazar el trato comercial baja la confianza")
	_comprobar(m.mi_club().saldo < caja6, "y descuenta el bono comercial en el acto")

	## EL CRECIMIENTO POR TEMPORADA.
	var quien: Jugador = m.mi_club().plantilla[0]
	quien.ovr_al_empezar = quien.ovr - 4
	_comprobar(quien.crecimiento_temporada() == 4,
		"se puede ver cuanto crecio un jugador esta temporada (+%d)" % quien.crecimiento_temporada())

	## LAS COPAS DE CADA PAIS.
	var eng := Copa.copas_de("ENG", "Inglaterra")
	var esp := Copa.copas_de("ESP", "España")
	_linea("  Inglaterra juega: %s" % ", ".join(eng.map(func(c: Array) -> String: return String(c[0]))))
	_comprobar(eng.size() == 2 and String(eng[0][0]) == "FA Cup", "Inglaterra tiene FA Cup y copa de liga")
	_comprobar(String(esp[0][0]) == "Copa del Rey", "y España la Copa del Rey")
	_comprobar(not Copa.copas_de("XXX", "Pais Raro").is_empty(),
		"un pais sin copa propia juega una generica y no se queda sin copa")

	## EL MAPA DEL PAIS.
	_comprobar(MapaPais.hay("CHI") and MapaPais.hay("ENG"), "hay silueta para los paises con liga")
	_comprobar(MapaPais.poligono("CHI", Vector2(100, 200)).size() >= 3,
		"y se puede pintar al tamaño que haga falta")

## EL LOGO DEL SPONSOR. `MARCAS` en tablas.json siempre fue solo [nombre,
## color] y ninguna pantalla dibujaba nada más que esa palabra en ese color:
## `Marca` es lo nuevo, mismo patrón que `Escudo` pero sin depender de un id
## de club -las marcas no tienen uno, así que la clave es el propio nombre-.
func _probar_marca() -> void:
	_titulo("EL LOGO DEL SPONSOR (Marca)")
	var tabla: Array = Datos.tabla("MARCAS")
	_comprobar(tabla != null and tabla.size() >= 30, "hay al menos 30 marcas en la tabla (%d)" % (tabla.size() if tabla != null else 0))
	var vacios: Array[String] = []
	var formas_vistas: Dictionary = {}
	var patrones_vistos: Dictionary = {}
	for fila: Array in tabla:
		var nombre := String(fila[0])
		var color := String(fila[1])
		var tex := Marca.textura(nombre, color)
		if tex == null or tex.get_width() < 32:
			vacios.append(nombre)
		formas_vistas[Marca.forma_de(nombre)] = true
		patrones_vistos[Marca.patron_de(nombre)] = true
	_comprobar(vacios.is_empty(), "todas rasterizan de verdad (%s)" % ("ninguna vacia" if vacios.is_empty() else ", ".join(vacios)))
	_comprobar(formas_vistas.size() >= 3, "las marcas se reparten en varias formas, no todas la misma (%d de %d)" % [formas_vistas.size(), Marca.FORMAS.size()])
	_comprobar(patrones_vistos.size() >= 3, "y en varios patrones (%d de %d)" % [patrones_vistos.size(), Marca.PATRONES.size()])

	## Determinismo: la misma marca da siempre el mismo logo -no se sortea-.
	if not tabla.is_empty():
		var f0: Array = tabla[0]
		var n0 := String(f0[0])
		var c0 := String(f0[1])
		_comprobar(Marca.forma_de(n0) == Marca.forma_de(n0) and Marca.patron_de(n0) == Marca.patron_de(n0),
			"la forma y el patron de una marca no cambian entre llamadas")
		_comprobar(Marca.iniciales(n0) != "", "las iniciales nunca salen vacias (\"%s\" -> \"%s\")" % [n0, Marca.iniciales(n0)])
	## Y DOS MARCAS DISTINTAS NO COMPARTEN SIEMPRE EL MISMO LOGO -si compartieran
	## forma Y patron a la vez para nombres distintos seria una casualidad de
	## hash aceptable, pero comprobamos que no TODAS caen en la misma combinacion-.
	if tabla.size() >= 2:
		var combinaciones: Dictionary = {}
		for fila2: Array in tabla:
			var n2 := String(fila2[0])
			combinaciones["%s|%s" % [Marca.forma_de(n2), Marca.patron_de(n2)]] = true
		_comprobar(combinaciones.size() >= 4, "no todas las marcas caen en la misma combinacion forma+patron (%d combinaciones)" % combinaciones.size())

## LAS TRES ESCENAS RAÍZ CARGAN Y COMPILAN (25-9-2026).
##
## Pedido del usuario tras encontrar y arreglar un bug crítico el mismo día:
## "que no sea tan frágil". El bug era este de libro: `principal.gd` -15.000+
## líneas, un solo archivo del que depende TODO el juego- tenía un bloque de
## código muerto que citaba una variable (`_lista_mercado`) borrada al conectar
## `PanelMercado`. GDScript con tipado estático no tolera un identificador no
## declarado: el archivo entero dejaba de PARSEAR, y como `ui/inicio.gd` (la
## escena `run/main_scene`) depende de esa clase, **el juego no arrancaba desde
## ningún lanzador** -ni el .exe, ni el proyecto abierto en el editor-.
##
## Y este mismo banco, que se corrió una decena de veces esa sesión siempre en
## 0 fallos, JAMÁS LO VIO: `banco.gd` prueba el `nucleo/` -economía, partidos,
## mercado, todo lo que no necesita ventana-, pero nunca había cargado una sola
## escena de `ui/`. Un error de sintaxis ahí era invisible para "0 fallos".
##
## La prueba es deliberadamente simple: cargar e instanciar cada escena raíz ES
## SUFICIENTE para forzar a Godot a compilar el script y todo lo que importa
## -no hace falta meterlas al árbol ni esperar a `_ready()`, el error de
## parseo ya habría reventado en `load()`/`instantiate()`-. Así que esto es
## barato (no dispara sonido, música, ni construye el mundo 3D) y cubre
## exactamente el hueco que dejó pasar el bug de hoy, para siempre, en TODAS
## las escenas raíz y no solo en la que falló esta vez.
func _probar_carga_de_ui() -> void:
	_titulo("LAS ESCENAS RAÍZ COMPILAN Y CARGAN (red contra un archivo roto en silencio)")
	for ruta in ["res://escenas/inicio.tscn", "res://escenas/eleccion_club.tscn",
			"res://escenas/principal.tscn"]:
		var paquete: PackedScene = load(ruta)
		_comprobar(paquete != null, "%s se carga como recurso" % ruta)
		if paquete == null:
			continue
		## BUG DE VERIFICACIÓN REAL, ENCONTRADO ESCRIBIENDO ESTA MISMA PRUEBA
		## (25-9-2026): `PackedScene.instantiate()` NUNCA devuelve null aunque
		## el script de la raíz esté completamente roto -Godot igual crea el
		## `Node` base, simplemente sin el script pegado-. Comprobar
		## `nodo != null` es un candado que siempre pasa: es exactamente el
		## tipo de prueba que miente por ausencia que ya advierte
		## `feedback-verification-discipline` en la memoria del proyecto.
		## `get_script()` sí distingue los dos casos -confirmado con un script
		## roto de mentira antes de confiar en esto-: da `null` cuando el
		## script no pudo compilar y el recurso real cuando sí.
		var nodo := paquete.instantiate()
		_comprobar(nodo != null and nodo.get_script() != null,
			"%s instancia CON su script compilado (no solo el Node vacío)" % ruta)
		if nodo != null:
			nodo.free()

## LA NARRACIÓN, AL INGLÉS Y AL PORTUGUÉS (punto 10 del MEGAPLAN): los
## titulares de las noticias.
func _probar_narracion_traducida() -> void:
	_titulo("NARRACIÓN TRADUCIDA: TITULARES DE NOTICIAS")
	var antes := Idiomas.idioma
	Idiomas.idioma = "en"
	Idiomas._cache.clear()
	_comprobar(Idiomas.t("🗳️ Campaña electoral") == "🗳️ Election campaign", "titular con icono en inglés: %s" % Idiomas.t("🗳️ Campaña electoral"))
	_comprobar(Idiomas.t("Llega la camada juvenil") == "The youth intake arrives", "titular en inglés")
	_comprobar(Idiomas.t("Representantes: R. Prueba") == "Agents: R. Prueba", "titular con nombre (patrón)")
	Idiomas.idioma = "pt"
	Idiomas._cache.clear()
	_comprobar(Idiomas.t("Se retira una figura") == "Um craque se aposenta", "titular en portugués")
	## Los cuerpos (7-10-2026): con nombres y cifras dentro, por patrón.
	var cuerpo_pt := Idiomas.t("Juan Ríos se lesiona entrenando: 3 semanas de baja.")
	_comprobar(cuerpo_pt == "Juan Ríos se machuca no treino: 3 semanas fora.", "cuerpo con nombre en portugués: %s" % cuerpo_pt)
	Idiomas.idioma = "en"
	Idiomas._cache.clear()
	var cuerpo_en := Idiomas.t("Juan Ríos se lesiona entrenando: 3 semanas de baja.")
	_comprobar(cuerpo_en == "Juan Ríos gets injured in training: out for 3 weeks.", "cuerpo con nombre en inglés: %s" % cuerpo_en)
	var fijo_en := Idiomas.t("El estadio vuelve a abrir con normalidad.")
	_comprobar(fijo_en == "The stadium reopens as normal.", "cuerpo fijo en inglés")
	var tv := Idiomas.t("Ana Sol termina su préstamo y se reincorpora a la pretemporada.")
	_comprobar(tv == "Ana Sol ends his loan and rejoins pre-season.", "otro cuerpo en inglés: %s" % tv)
	## La prensa y la carrera de jugador (7-10-2026), y frases pegadas.
	_comprobar(Idiomas.t("Prensa: '¿Le preocupa la falta de gol?'") == "Press: 'Are you worried about the lack of goals?'", "pregunta de prensa en inglés")
	_comprobar(Idiomas.t("Los chicos empujan fuerte, tendrán su chance").contains("pushing hard"), "respuesta de prensa en inglés")
	var pegadas := Idiomas.t("Sumamos; el equipo dio la cara. Tardaste en contestar: en la sala se notó.")
	_comprobar(pegadas.contains("You took a while to answer"), "frases pegadas, oración por oración: %s" % pegadas)
	var cesion := Idiomas.t("Leo Mar se va cedido una temporada. Juega en Cumbres. Pagan el 50% del sueldo.")
	_comprobar(cesion.begins_with("Leo Mar leaves on a season-long loan.") and cesion.ends_with("They pay 50% of his wages."), "texto de varias oraciones con patrón entero: %s" % cesion)
	## Los otros seis idiomas (7-10-2026): la misma narración en fr/it/de/ca/pl/tr.
	var esperado := {
		"fr": "Juan Ríos se blesse à l'entraînement : 3 semaines d'absence.",
		"it": "Juan Ríos si infortuna in allenamento: 3 settimane di stop.",
		"de": "Juan Ríos verletzt sich im Training: 3 Wochen Pause.",
		"ca": "Juan Ríos es lesiona entrenant: 3 setmanes de baixa.",
		"pl": "Juan Ríos doznaje kontuzji na treningu: 3 tyg. przerwy.",
		"tr": "Juan Ríos antrenmanda sakatlandı: 3 hafta yok.",
	}
	for k: String in esperado:
		Idiomas.idioma = k
		Idiomas._cache.clear()
		var c := Idiomas.t("Juan Ríos se lesiona entrenando: 3 semanas de baja.")
		_comprobar(c == esperado[k], "cuerpo con nombre en %s: %s" % [k, c])
		_comprobar(Idiomas.t("Se retira una figura") != "Se retira una figura", "titular fijo en %s" % k)
	Idiomas.idioma = antes
	Idiomas._cache.clear()

func _frases_de_idiomas_t(dir: String, re: RegEx, frases: Dictionary) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			for m in re.search_all(FileAccess.get_file_as_string(dir + "/" + f)):
				frases[m.get_string(1).c_unescape()] = true
	for d in DirAccess.get_directories_at(dir):
		_frases_de_idiomas_t(dir + "/" + d, re, frases)

## LOS 8 IDIOMAS CON LAS MISMAS FRASES (15-10-2026, INFORME_INTERNO §9 / I-01).
## Las frases castellanas son la UNIÓN de todos los catálogos: la tabla del
## esqueleto (`Idiomas.TABLA`), `datos/idiomas_extra.json` de cada idioma (con
## los diálogos de la ciudad dentro) y las directas de la narración. Ningún
## idioma puede tener menos que esa unión; los patrones (con números o nombres)
## tienen que tener plantilla en los 8, y las frases de `DialogosCiudad`
## (generado por `herramientas/dialogos_ciudad.py`) tienen que estar en todos.
func _probar_paridad_idiomas() -> void:
	_titulo("IDIOMAS: LOS 8 TIENEN LAS MISMAS FRASES QUE EL CASTELLANO")
	var antes := Idiomas.idioma
	var castellano := {}
	for k: String in Idiomas.TABLA:
		castellano[k] = true
	for idi: String in Idiomas.ORDEN:
		for k: String in (Idiomas._extra.get(idi, {}) as Dictionary):
			castellano[k] = true
	## Las frases de los vecinos, sacadas del propio script generado.
	var re := RegEx.new()
	re.compile('Idiomas\\.t\\("((?:[^"\\\\]|\\\\.)*)"\\)')
	var vecinos := 0
	for m in re.search_all(FileAccess.get_file_as_string("res://nucleo/dialogos_ciudad.gd")):
		castellano[m.get_string(1).c_unescape()] = true
		vecinos += 1
	_comprobar(vecinos >= 72, "los diálogos de la ciudad aportan sus frases (%d)" % vecinos)
	_comprobar(castellano.size() > 2500, "frases castellanas en los catálogos: %d" % castellano.size())
	for idi: String in Idiomas.ORDEN:
		Idiomas.idioma = idi
		var faltan: Array[String] = []
		for k: String in castellano:
			if Idiomas._directa(k) == "":
				faltan.append(k)
		_comprobar(faltan.is_empty(), "«%s» tiene las %d frases (faltan %d%s)" % [idi, castellano.size(),
			faltan.size(), "" if faltan.is_empty() else ": " + ", ".join(faltan.slice(0, 6))])
	var cortos := {}
	for par: Array in Idiomas._patrones:
		for idi: String in Idiomas.ORDEN:
			if String((par[1] as Dictionary).get(idi, "")) == "":
				cortos[idi] = int(cortos.get(idi, 0)) + 1
	_comprobar(cortos.is_empty(), "los %d patrones tienen plantilla en los 8 idiomas %s" % [Idiomas._patrones.size(),
		"" if cortos.is_empty() else str(cortos)])
	## Cada `Idiomas.t("…")` escrito en el código (M-446): traducido en los 8.
	## Lo mismo que `pruebas/frases_sin_traducir.gd`, pero aquí falla.
	var del_codigo := {}
	for dir: String in ["res://ui", "res://visor", "res://nucleo"]:
		_frases_de_idiomas_t(dir, re, del_codigo)
	var sin: Array[String] = []
	for f: String in del_codigo:
		if f.strip_edges() == "%s":
			continue
		for idi: String in Idiomas.ORDEN:
			Idiomas.idioma = idi
			if Idiomas._directa(f) == "" and Idiomas._t(f, 0) == f:
				sin.append("%s: %s" % [idi, f])
	_comprobar(del_codigo.size() > 200 and sin.is_empty(), "las %d frases de Idiomas.t(\"…\") del código, en los 8 idiomas (%d sin traducir%s)" % [
		del_codigo.size(), sin.size(), "" if sin.is_empty() else ": " + ", ".join(sin.slice(0, 6))])
	## Y los marcadores no se pierden al traducir: lo que lleva %s/%d en
	## castellano lo lleva igual en cada idioma (si no, el `%` revienta).
	var huecos := RegEx.new()
	huecos.compile("%[+-]?(?:\\.\\d+)?[sd]")
	var malos: Array[String] = []
	for idi: String in Idiomas.ORDEN:
		var ex: Dictionary = Idiomas._extra.get(idi, {})
		for k: String in ex:
			if huecos.search_all(k).size() != huecos.search_all(String(ex[k])).size():
				malos.append("%s: %s" % [idi, k])
	_comprobar(malos.is_empty(), "los %%s y %%d se conservan en cada idioma (%d mal%s)" % [malos.size(),
		"" if malos.is_empty() else ": " + ", ".join(malos.slice(0, 4))])
	Idiomas.idioma = antes
	Idiomas._cache.clear()

## LA TRIBUNA COMO TERMÓMETRO (fase 5): los hinchas citan jugadas reales.
func _probar_tribuna_real() -> void:
	_titulo("TRIBUNA: LOS HINCHAS CITAN JUGADAS REALES (FASE 5)")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var citado := false
	var intentos := 0
	while not citado and intentos < 12:
		m.avanzar_semana()
		intentos += 1
		var u: Dictionary = Partido.ultimo_mio
		if u.is_empty() or m.redes == null:
			continue
		var autores: Array = []
		for e: Dictionary in u["cronica"]:
			if String(e.get("tipo", "")) == "gol" and String(e.get("club", "")) == m.mi_club_id:
				autores.append(String(e["autor"]))
		var posts := m.redes.comentar_ultimo_partido(m)
		for f: Dictionary in m.redes.publicaciones.slice(0, 6):
			for a: String in autores:
				if String(f["texto"]).contains(a):
					citado = true
	_comprobar(citado, "un hincha nombra a quien marcó en tu último partido (en %d semanas)" % intentos)
