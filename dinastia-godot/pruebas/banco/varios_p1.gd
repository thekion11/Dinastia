extends "res://pruebas/banco/varios_p1_h.gd"
## [Capa 1/10 de `varios.gd`] _probar_datos, _probar_mundo, _probar_cubierta_nombres, _probar_base_ficticia, _probar_reales

# ---------------------------------------------------------------------------

func _probar_datos() -> void:
	_titulo("DATOS EXPORTADOS DEL HTML")
	_comprobar(Datos.cargado, "el JSON de tablas carga")
	_linea("  %d tablas disponibles" % Datos.cuantas())
	for t in ["DATA_P1", "DATA_P2", "PAISES_LIGAS", "POSD", "FORMS", "NOMBRES", "APELLIDOS", "RASGOS"]:
		_comprobar(Datos.tiene(t), "esta la tabla %s" % t)
	## El CONTENIDO de las tablas, no solo su presencia. Que una tabla exista no
	## significa que traiga lo que dice su nombre: el script de exportacion tenia
	## una variable llamada NOMBRES que tapaba a la constante NOMBRES del juego, y
	## se exportaron los nombres de las TABLAS como si fueran nombres de pila.
	## Todos los futbolistas se llamaban "VALOR_PIVOTE Ahumada" y el banco daba
	## cero fallos, porque comprobaba que la tabla estuviera, no que sirviera.
	var pila: Array = Datos.tabla("NOMBRES")
	var apes: Array = Datos.tabla("APELLIDOS")
	_comprobar(pila.size() > 20 and not String(pila[0]).is_empty(), "NOMBRES trae una lista larga (%d)" % pila.size())
	_comprobar(not String(pila[0]).to_upper() == String(pila[0]), "NOMBRES trae nombres de pila, no constantes en mayusculas (%s)" % pila[0])
	_comprobar(apes.size() > 20, "APELLIDOS trae una lista larga (%d)" % apes.size())
	var p1: Array = Datos.tabla("DATA_P1")
	_comprobar(p1.size() > 10 and p1[0].size() >= 5, "DATA_P1 trae filas de club completas")
	_comprobar(int(p1[0][3]) > 0 and int(p1[0][4]) > 0, "las filas de club traen reputacion y aforo")

	## El leetspeak tiene que deshacerse solo donde toca.
	_comprobar(Nombres.limpiar("C0lo-C0lo") == "Colo-Colo", "descensurar: C0lo-C0lo -> Colo-Colo")
	_comprobar(Nombres.limpiar("B0ca Juni0rs") == "Boca Juniors", "descensurar: B0ca Juni0rs -> Boca Juniors")
	_comprobar(Nombres.limpiar("Racing 1904") == "Racing 1904", "descensurar NO toca los anos sueltos")

func _probar_mundo() -> void:
	_titulo("GENERACION DEL MUNDO")
	var m := Mundo.new()
	m.generar([], 7)
	_linea("  %d clubes, %d jugadores, %d ligas" % [m.clubes.size(), m.cuantos_jugadores(), m.ligas.size()])
	_comprobar(m.clubes.size() > 300, "se generan mas de 300 clubes")
	_comprobar(m.ligas.size() >= 20, "se generan al menos 20 ligas")
	var sin_plantilla := 0
	var sin_portero := 0
	var media_mala := 0
	for c: Club in m.clubes.values():
		if c.plantilla.size() < 18:
			sin_plantilla += 1
		var porteros := 0
		for j in c.plantilla:
			if j.es_portero():
				porteros += 1
			if j.ovr < 40 or j.ovr > 96:
				media_mala += 1
		if porteros == 0:
			sin_portero += 1
	_comprobar(sin_plantilla == 0, "ningun club se queda sin plantilla (%d)" % sin_plantilla)
	_comprobar(sin_portero == 0, "todos los clubes tienen portero (%d sin)" % sin_portero)
	_comprobar(media_mala == 0, "ninguna media fuera de [40,96] (%d)" % media_mala)
	## El once tiene que salir completo incluso con la enfermeria llena: en el
	## HTML esto no estaba al principio y un club sin once dejaba el partido a
	## medias y reventaba la jornada entera.
	var uno: Club = m.clubes.values()[0]
	for j in uno.plantilla:
		j.lesion = 5
	var once := uno.once()
	_comprobar(once.size() == 11, "sale un once de 11 aunque esten todos lesionados (%d)" % once.size())

	## La edad tiene que pesar en la media. Sin el castigo del HTML a los menores
	## de 20 salian canteranos de 17 anos con media 96 y 223 millones de valor,
	## que en un manager es lo mismo que decirle al jugador que no se lo crea.
	var media_joven := 0.0
	var n_joven := 0
	var media_pico := 0.0
	var n_pico := 0
	var cracks_ninos := 0
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if j.edad <= 19:
				media_joven += float(j.ovr); n_joven += 1
				if j.ovr >= 90:
					cracks_ninos += 1
			elif j.edad >= 25 and j.edad <= 29:
				media_pico += float(j.ovr); n_pico += 1
	media_joven /= float(maxi(n_joven, 1))
	media_pico /= float(maxi(n_pico, 1))
	_linea("  media de los menores de 20: %.1f   |   de los 25-29: %.1f" % [media_joven, media_pico])
	_comprobar(media_joven < media_pico, "los chicos son peores que los de su mejor edad")
	_comprobar(cracks_ninos == 0, "no hay ninos de 19 con media 90+ (%d)" % cracks_ninos)

	## Y el reparto por puestos: ningun club puede quedarse sin una demarcacion.
	var incompletos := 0
	for c: Club in m.clubes.values():
		var tiene := {}
		for j in c.plantilla:
			tiene[Datos.grupo(j.pos_e)] = true
		if tiene.size() < 4:
			incompletos += 1
	_comprobar(incompletos == 0, "todos los clubes tienen las cuatro lineas (%d sin)" % incompletos)


## LA BASE FICTICIA (25-9-2026). Lo que se publica no puede llevar ni un club,
## ni una liga, ni un jugador, ni una foto, ni una equipación real. Se
## comprueba contra el propio pack: todo nombre real que el pack conoce tiene
## que haber desaparecido de la base, y la base tiene que seguir teniendo la
## MISMA forma (mismos colores, reputación, aforo y orden), para que el mundo
## ficticio juegue exactamente igual que el real.
## LA CUBIERTA DE LOS NOMBRES REALES (25-9-2026). Con el pack real, clubes,
## copas, árbitros y futbolistas reales se enseñan cubiertos ("C0lo-C0lo"),
## no en claro. Y todo lo que busca por nombre -plantillas reales, fotos,
## camisetas- tiene que seguir encontrándolo a pesar de la cubierta.
func _probar_cubierta_nombres() -> void:
	_titulo("CUBIERTA DE LOS NOMBRES REALES")
	if not Datos.hay_pack_real():
		_comprobar(false, "hace falta el pack real para probar la cubierta")
		return
	Datos.usar_base_real(true)
	_comprobar(Nombres.cubierta_activa(), "con el pack real la cubierta está activa")
	var m := Mundo.new()
	m.generar([], 7)
	var reales_aplicados := 0
	var clubes := 0
	var clubes_cubiertos := 0
	var jugadores := 0
	var jugadores_cubiertos := 0
	var con_foto := 0
	var con_camiseta := 0
	var ejemplo_club := ""
	var ejemplo_jugador := ""
	for c: Club in m.clubes.values():
		clubes += 1
		if Nombres.limpiar(c.nombre) != c.nombre:
			clubes_cubiertos += 1
			if ejemplo_club == "" or c.nombre.begins_with("C0lo"):
				ejemplo_club = c.nombre
		if Jersey.fichero_real(c) != "":
			con_camiseta += 1
		for j: Jugador in c.plantilla:
			if not j.real:
				continue
			reales_aplicados += 1
			jugadores += 1
			if Nombres.limpiar(j.nombre) != j.nombre:
				jugadores_cubiertos += 1
				if ejemplo_jugador == "":
					ejemplo_jugador = j.nombre
			if con_foto < 3 and Cara.foto_real(j) != null:
				con_foto += 1
	_linea("  por ejemplo: %s, %s" % [ejemplo_club, ejemplo_jugador])
	_comprobar(reales_aplicados > 500, "las plantillas reales se siguen encontrando con el club cubierto (%d jugadores)" % reales_aplicados)
	_comprobar(clubes_cubiertos >= int(clubes * 0.95), "clubes cubiertos: %d de %d" % [clubes_cubiertos, clubes])
	_comprobar(jugadores > 0 and jugadores_cubiertos >= int(jugadores * 0.95), "futbolistas reales cubiertos: %d de %d" % [jugadores_cubiertos, jugadores])
	_comprobar(con_foto > 0, "las caras reales se siguen encontrando con el nombre cubierto")
	_comprobar(con_camiseta > 0, "y las camisetas reales también (%d clubes)" % con_camiseta)
	var arb := String(Previa.arbitro_de("c1", 3).get("nombre", ""))
	_comprobar(arb != Nombres.limpiar(arb), "el árbitro va cubierto (%s)" % arb)
	var copa := Continental.nombre_conti("ucl")
	_comprobar(copa != Nombres.limpiar(copa), "la copa continental va cubierta (%s)" % copa)
	_comprobar(Nombres.de_tabla("Colo-Colo") != "Colo-Colo" and Nombres.limpiar(Nombres.de_tabla("Colo-Colo")) == "Colo-Colo",
		"un nombre en claro se cubre y se puede volver a limpiar")

	## Con la base ficticia no hay nada que tapar: todo limpio, como antes.
	Datos.usar_base_real(false)
	_comprobar(not Nombres.cubierta_activa(), "con la base ficticia la cubierta se apaga")
	var mf := Mundo.new()
	mf.generar([], 7)
	var con_numeros := 0
	for c: Club in mf.clubes.values():
		if Nombres.limpiar(c.nombre) != c.nombre:
			con_numeros += 1
	_comprobar(con_numeros == 0, "y los clubes ficticios se leen limpios (%d con números)" % con_numeros)
	Datos.usar_base_real(true)

func _probar_base_ficticia() -> void:
	_titulo("BASE FICTICIA: LO QUE SE PUBLICA NO LLEVA NADA REAL")
	_comprobar(Datos.hay_pack_real(), "el pack real del proyecto se encuentra (%s)" % Datos.ruta_pack())
	if not Datos.hay_pack_real():
		return
	_bf_leer_pack()
	_bf_quitar_pack()
	_bf_misma_forma()
	_bf_mundo_sin_nombres()
	_bf_sin_registrados()
	_bf_foto_y_guardado()

func _probar_reales() -> void:
	_titulo("PLANTILLAS REALES: NOMBRES DE VERDAD SOBRE EL MUNDO GENERADO")
	## Reales.aplicar() ya corrio dentro de generar(); aqui solo se comprueba
	## lo que dejo.
	var m := Mundo.new()
	m.generar(["CHI"], 2323)
	var colo: Club = null
	for c: Club in m.ligas[0].clubes:
		if Nombres.limpiar(c.nombre) == "Colo-Colo":
			colo = c
			break
	_comprobar(colo != null, "Colo-Colo esta entre los clubes generados")
	if colo == null:
		return

	var reales_en_colo: Array[Jugador] = []
	for j: Jugador in colo.plantilla:
		if j.real:
			reales_en_colo.append(j)
	_comprobar(reales_en_colo.size() >= 12, "Colo-Colo trae su plantel real completo (%d reales)" % reales_en_colo.size())

	var vidal: Jugador = null
	for j: Jugador in colo.plantilla:
		if Nombres.limpiar(j.nombre) == "Arturo Vidal":
			vidal = j
			break
	_comprobar(vidal != null, "Arturo Vidal aparece en el plantel real de Colo-Colo")
	if vidal != null:
		_comprobar(vidal.real, "y queda marcado como real")
		_comprobar(vidal.pos_e == "MC", "en su demarcacion real (MC)")
		_comprobar(not vidal.atributos.is_empty(), "con atributos generados para su nueva media")

	## Nadie se repite dentro del mismo club -el "usados" de Reales.gd-.
	var nombres := {}
	var repetidos := 0
	for j: Jugador in reales_en_colo:
		if nombres.has(j.nombre):
			repetidos += 1
		nombres[j.nombre] = true
	_comprobar(repetidos == 0, "ningun nombre real se repite dentro del mismo club")

	## El fondo de plantel inventado no puede pisar a los reales -reescalado
	## del cuartil bajo-.
	if reales_en_colo.size() >= 6:
		var generados: Array[Jugador] = []
		for j: Jugador in colo.plantilla:
			if not j.real:
				generados.append(j)
		var reales_ovr: Array[int] = []
		for j: Jugador in reales_en_colo:
			reales_ovr.append(j.ovr)
		reales_ovr.sort()
		reales_ovr.reverse()
		var idx_cuartil := mini(reales_ovr.size() - 1, int(floor(float(reales_ovr.size()) * 0.75)))
		var techo := maxi(42, reales_ovr[idx_cuartil] - 1)
		var todos_bajo_el_techo := true
		for j: Jugador in generados:
			if j.ovr > techo:
				todos_bajo_el_techo = false
		_comprobar(todos_bajo_el_techo, "ningun generado supera el techo del fondo de plantel real (%d)" % techo)

	## Un pais sin ninguno de sus clubes en la tabla REALES no rompe nada: sigue
	## saliendo un mundo 100% generado, como antes de portar esto -Japon no
	## esta entre los 256 clubes con plantel real-.
	var m2 := Mundo.new()
	m2.generar(["JPN"], 2323)
	_comprobar(m2.cuantos_jugadores() > 0, "un pais sin datos reales genera su mundo igual")

	## CARA REAL: la foto que ya bajo caras_reales_buscar.ps1 pisa al retrato
	## procedural solo para reales con foto encontrada, nunca para nadie mas.
	if vidal != null:
		var foto := Cara.foto_real(vidal)
		_comprobar(foto != null, "Arturo Vidal (real y con foto ya encontrada) tiene foto de verdad")
		if foto != null:
			_comprobar(foto.get_width() == foto.get_height(), "la foto queda recortada a cuadrado (%dx%d)" % [foto.get_width(), foto.get_height()])
			_comprobar(Cara.textura(vidal, "#000000", "#ffffff", 64) == foto, "textura() prefiere la foto real sobre el dibujo procedural")
			_comprobar(foto.get_width() == 256, "usa el retrato recortado por la cara (256 px), no la foto de prensa entera (%d px)" % foto.get_width())
			var cred := Cara.credito_foto(vidal)
			_comprobar(cred.contains("Wikimedia Commons") and cred.contains("CC"), "la ficha puede citar autor y licencia de la foto: " + cred)
	var generado_cualquiera: Jugador = null
	for j: Jugador in colo.plantilla:
		if not j.real:
			generado_cualquiera = j
			break
	if generado_cualquiera != null:
		_comprobar(Cara.foto_real(generado_cualquiera) == null, "un jugador generado -no real- nunca tiene foto de verdad")

## CANDADO DE LA VARIANTE DEL MOTOR (17-11-2026, pedido de la sesión de auditoría): el juego crea el motor con `MotorFabrica.crear()` (C4 por defecto, orden 39).
## Un `MotorCombinado.new()` sin variante es C1 (colocación y locomoción de League, sin MejorasC4): un perfil o una sonda así mide OTRO motor (pasó con
## `perfil_colocacion`, y el «50 % del partido en C++» salió de C1). Toda prueba, sonda o perfil que cree `MotorCombinado` o una subclase suya tiene que aplicar
## la variante (`aplicar_variante`), usar `MotorFabrica.crear` o declarar «## C1 A PROPÓSITO» (las que comprueban a propósito el código de League).
func _probar_variante_motor() -> void:
	_titulo("CANDADO: LAS PRUEBAS DEL PARTIDO USAN LA VARIANTE DEL JUEGO")
	var malos: Array[String] = []
	var vistos := 0
	var re := RegEx.create_from_string("(MotorCombinado|PerfC)\\.new\\(\\)")
	for dir: String in ["res://pruebas", "res://pruebas/_sonda", "res://pruebas/banco"]:
		for f: String in DirAccess.get_files_at(dir):
			if not f.ends_with(".gd"):
				continue
			var ruta := dir.path_join(f)
			var lineas := FileAccess.get_file_as_string(ruta).split("\n")
			for i in lineas.size():
				if re.search(lineas[i]) == null or lineas[i].strip_edges().begins_with("##"):
					continue
				vistos += 1
				var cerca := "\n".join(lineas.slice(i, mini(i + 3, lineas.size())))
				if not ("aplicar_variante(" in cerca or "C1 A PROPÓSITO" in lineas[i]):
					malos.append("%s:%d" % [ruta, i + 1])
	_comprobar(vistos >= 3, "se encuentran las pruebas que crean el motor combinado (%d)" % vistos)
	_comprobar(malos.is_empty(), "cada una aplica la variante del juego o declara C1 a propósito en esa línea%s" % ("" if malos.is_empty() else (": faltan " + ", ".join(malos))))
