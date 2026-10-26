extends "res://pruebas/banco/base.gd"
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
	## Los nombres reales, sacados del pack, antes de quitarlo.
	var reales_clubes := {}
	var filas_reales: Array = []
	for t in ["DATA_P1", "DATA_P2"]:
		for fila: Array in Datos.tabla(t):
			reales_clubes[Nombres.limpiar(String(fila[0])).to_lower()] = true
			filas_reales.append(fila)
	var ligas_reales := {}
	var pl_real: Dictionary = Datos.tabla("PAISES_LIGAS")
	for pais: String in pl_real:
		ligas_reales[String(pl_real[pais].get("liga", ""))] = true
		for fila: Array in pl_real[pais]["clubes"]:
			reales_clubes[Nombres.limpiar(String(fila[0])).to_lower()] = true
			filas_reales.append(fila)
	var copas_reales := {}
	for k: String in (Datos.tabla("CONFED") as Dictionary):
		copas_reales[Nombres.limpiar(String(Datos.tabla("CONFED")[k]["n"]))] = true
	var arbitros_reales := {}
	for fila: Array in Datos.tabla("ARBITROS"):
		arbitros_reales[Nombres.limpiar(String(fila[0]))] = true
	var jugadores_reales := {}
	for club: String in (Datos.tabla("REALES") as Dictionary):
		for fila: Variant in Datos.tabla("REALES")[club]:
			jugadores_reales[String(fila).split("|")[0]] = true
	_linea("  el pack trae %d clubes y %d jugadores reales" % [reales_clubes.size(), jugadores_reales.size()])

	var quedo := Datos.usar_base_real(false)
	_comprobar(not quedo and not Datos.base_real, "se puede quitar el pack")
	## Desde el 26-9-2026 la base SÍ trae plantillas, pero con nombres de guiño
	## (`herramientas/jugadores_guino.py`): ninguno puede ser un nombre real.
	var guinos_reales: Array = []
	var n_guinos := 0
	for club_f: String in (Datos.tabla("REALES") as Dictionary):
		for fila_f: Variant in Datos.tabla("REALES")[club_f]:
			n_guinos += 1
			var nf := String(fila_f).split("|")[0]
			if jugadores_reales.has(nf) or Nombres.vetado(nf):
				guinos_reales.append(nf)
	_comprobar(n_guinos > 0 and guinos_reales.is_empty(), "la base trae %d jugadores con guiño y ninguno con nombre real %s" % [n_guinos, str(guinos_reales.slice(0, 5))])
	_comprobar((Datos.tabla("EQUIP_REAL") as Dictionary).is_empty(), "ni fotos de equipaciones reales")

	## Misma forma: fila a fila, todo igual salvo el nombre.
	var filas_fic: Array = []
	for t in ["DATA_P1", "DATA_P2"]:
		filas_fic.append_array(Datos.tabla(t))
	var pl_fic: Dictionary = Datos.tabla("PAISES_LIGAS")
	for pais: String in pl_fic:
		filas_fic.append_array(pl_fic[pais]["clubes"])
	var misma_forma := filas_fic.size() == filas_reales.size()
	if misma_forma:
		for i in filas_fic.size():
			if (filas_fic[i] as Array).slice(1) != (filas_reales[i] as Array).slice(1):
				misma_forma = false
				break
	_comprobar(misma_forma, "mismos %d clubes, en el mismo orden y con los mismos colores, reputación y aforo" % filas_fic.size())

	## Ningún nombre real en el mundo generado.
	var m := Mundo.new()
	m.generar([], 7)
	var clubes_reales_vistos: Array[String] = []
	var jugadores_marcados := 0
	var jugadores_reales_vistos := 0
	var con_equipacion := 0
	for c: Club in m.clubes.values():
		if reales_clubes.has(c.nombre.to_lower()):
			clubes_reales_vistos.append(c.nombre)
		if Jersey.fichero_real(c) != "":
			con_equipacion += 1
		for j: Jugador in c.plantilla:
			if j.real:
				jugadores_marcados += 1
			if jugadores_reales.has(j.nombre):
				jugadores_reales_vistos += 1
	_comprobar(m.clubes.size() == filas_fic.size(), "el mundo ficticio tiene sus %d clubes" % m.clubes.size())
	_comprobar(clubes_reales_vistos.is_empty(), "ningún club lleva un nombre real %s" % str(clubes_reales_vistos.slice(0, 5)))
	_comprobar(jugadores_marcados > 0 and jugadores_reales_vistos == 0, "los jugadores fijos llevan su guiño, no el nombre real (%d fijos, %d reales)" % [jugadores_marcados, jugadores_reales_vistos])
	## Antes del filtro de vetados salían 110 -"Mohamed Salah", "Christian
	## Pulisic", "Claudio Bravo"...-, porque varias bolsas de nombres eran la
	## convocatoria de una selección. Ahora el generador vuelve a sortear.
	_comprobar(jugadores_reales_vistos == 0, "ningún jugador generado se llama como uno real (%d)" % jugadores_reales_vistos)
	_comprobar(Nombres.vetado("Mohamed Salah") and Nombres.vetado("arturo vidal"),
		"el filtro reconoce a un real, sin importar mayúsculas")
	_comprobar(Nombres.vetado("Óscar Opazo"), "y con tildes: la huella de Godot es la misma que la de Python")
	_comprobar(not Nombres.vetado("Zacarías Quintupal"), "y deja pasar un nombre inventado")
	var huellas_legibles := 0
	for h: Variant in Datos.tabla("NOMBRES_VETADOS"):
		if String(h).contains(" "):
			huellas_legibles += 1
	_comprobar(huellas_legibles == 0 and (Datos.tabla("NOMBRES_VETADOS") as Array).size() == jugadores_reales.size(),
		"la base lleva %d huellas, ningún nombre legible" % (Datos.tabla("NOMBRES_VETADOS") as Array).size())
	_comprobar(con_equipacion == 0, "ningún club viste una equipación real (%d)" % con_equipacion)
	var ligas_mal: Array[String] = []
	for l: Liga in m.ligas:
		if ligas_reales.has(l.nombre) and not ["Primera División", "Primera B"].has(l.nombre):
			for marca in ["Premier", "Bundesliga", "Serie A", "Ligue 1", "La Liga", "Liga MX", "Brasileir", "Botola", "League", "J-Liga", "K-"]:
				if l.nombre.contains(marca):
					ligas_mal.append(l.nombre)
	_comprobar(ligas_mal.is_empty(), "ninguna liga con nombre registrado %s" % str(ligas_mal))
	var copas_mal: Array[String] = []
	for k: String in (Datos.tabla("CONFED") as Dictionary):
		var n := Nombres.limpiar(String(Datos.tabla("CONFED")[k]["n"]))
		if copas_reales.has(n) and n != "Copa África de Clubes" and n != "Liga de Oceanía":
			copas_mal.append(n)
	_comprobar(copas_mal.is_empty(), "ningún torneo continental con nombre registrado %s" % str(copas_mal))
	var arbitros_mal := 0
	for fila: Array in Datos.tabla("ARBITROS"):
		if arbitros_reales.has(Nombres.limpiar(String(fila[0]))):
			arbitros_mal += 1
	_comprobar(arbitros_mal == 0, "ningún árbitro real (%d)" % arbitros_mal)

	## Una foto real no se enseña con la base ficticia aunque el jugador venga
	## marcado como real de un guardado viejo.
	var falso := m.clubes.values()[0].plantilla[0] as Jugador
	falso.real = true
	_comprobar(Cara.foto_real(falso) == null, "con la base ficticia no se enseña ninguna foto real")
	falso.real = false

	## El guardado recuerda la base y la vuelve a poner al cargar.
	m.mi_club_id = m.ligas[0].clubes[0].id
	var foto := Partida.instantanea(m)
	_comprobar(foto.get("base_real", true) == false, "el guardado anota que se jugó con la base ficticia")
	Datos.usar_base_real(true)
	var m2 := Partida.desde_instantanea(foto)
	_comprobar(m2 != null and not Datos.base_real, "y al cargarlo vuelve a la base ficticia aunque el pack estuviera puesto")
	## Un guardado sin la clave es anterior a todo esto: se jugó con lo real.
	foto.erase("base_real")
	var m3 := Partida.desde_instantanea(foto)
	_comprobar(m3 != null and Datos.base_real, "un guardado viejo (sin la clave) se carga con el pack real")

	## Y con el pack otra vez puesto, lo real vuelve entero.
	Datos.usar_base_real(true)
	var mr := Mundo.new()
	mr.generar(["CHI"], 7)
	var hay_colo := false
	for c: Club in mr.clubes.values():
		if Nombres.limpiar(c.nombre) == "Colo-Colo":
			hay_colo = true
	_comprobar(hay_colo, "con el pack puesto vuelve Colo-Colo")

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
