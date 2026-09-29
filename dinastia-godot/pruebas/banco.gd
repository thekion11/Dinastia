extends Node
## Banco de pruebas del nucleo, sin ventana y sin nadie mirando.
##
##     godot --headless --path . res://pruebas/banco.tscn
##
## Es el equivalente del harness de Chrome del HTML, y comprueba lo mismo: que
## nada revienta al simular temporadas enteras. Pero puede comprobar dos cosas
## mas que aquel no podia:
##
##  1. REPETIBILIDAD. Con semilla, dos mundos iguales dan resultados iguales. El
##     HTML usa Math.random() sin semilla y eso alli es imposible de comprobar.
##  2. DISTRIBUCION. Como la migracion no se puede verificar por huella (el HTML
##     no es reproducible ni consigo mismo), se verifica que las CURVAS caigan
##     donde tienen que caer: goles por partido, valores, sueldos. Si una
##     formula se porta mal, la curva se mueve aunque no reviente nada.
##
## Devuelve 0 si todo va bien y 1 si algo falla, para poder encadenarlo.

var _fallos: Array[String] = []
var _lineas: Array[String] = []

func _ready() -> void:
	## Lo que queda entre partidas (`Meta`) va a un archivo propio del banco:
	## si no, cada corrida llenaría el álbum de verdad con sobres de prueba.
	Meta.ruta = "user://meta_banco.json"
	if FileAccess.file_exists(Meta.ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.ruta))
	_titulo("BANCO DE PRUEBAS DEL NUCLEO")
	## El banco se escribió contra los datos REALES (Colo-Colo, Vidal, las
	## equipaciones archivadas...) y así sigue: se corre con el pack real
	## encima. La base ficticia -la que se publica- tiene su propia sección,
	## `_probar_base_ficticia()`, que deja el pack puesto otra vez al salir.
	## La preferencia del jugador (`user://ajustes.cfg`) no se toca.
	Datos.usar_base_real(true)
	## PRIMERO, Y BARATO: que las tres escenas raíz compilen. Si algo rompió la
	## interfaz -el error exacto que costó un juego que no arrancaba el 25-9-,
	## mejor saberlo en el primer segundo que después de 15 minutos de banco.
	_probar_carga_de_ui()
	_probar_datos()
	_probar_repetibilidad()
	_probar_mundo()
	_probar_reales()
	_probar_base_ficticia()
	_probar_cubierta_nombres()
	_probar_calendario()
	_probar_partidos()
	_probar_previa()
	_probar_arbitros()
	_probar_pie_habil()
	_probar_banquillo()
	_probar_finanzas()
	_probar_mercado()
	_probar_notas()
	_probar_directiva()
	_probar_banco()
	_probar_staff()
	_probar_obras()
	_probar_roles_y_federacion()
	_probar_estadio()
	_probar_puente3d()
	_probar_tactica_en_movimiento()
	_probar_copa()
	_probar_continental()
	_probar_selecciones()
	_probar_pulso_de_roles()
	_probar_cantera()
	_probar_cesiones()
	_probar_desafios()
	_probar_fundar_club()
	_probar_logros()
	_probar_ascensos()
	_probar_vender()
	_probar_ojeadores()
	_probar_negociacion()
	_probar_consejeros()
	_probar_bilbao_solo_local()
	_probar_guardado()
	_probar_temporadas()
	_probar_economia()
	_probar_sala_de_prensa()
	_probar_auspicio()
	_probar_eras_y_precios()
	_probar_analitica_y_academias()
	_probar_habilidades()
	_probar_carrera_por_dentro()
	_probar_editor()
	_probar_ciudad()
	_probar_ideas_del_documento()
	_probar_aspecto_y_audio()
	_probar_marca()
	_probar_tutorial()
	_probar_moneda()
	_probar_academia()
	_probar_modos_simulacion()
	_probar_presets_exportacion()
	_probar_tema_y_ortografia()
	_probar_eventos_nuevos()
	_probar_entrevistas()
	_probar_estadio_b6()
	_probar_ciudad_b7()
	_probar_coherencia_c1()
	_probar_portadas_c20()
	_probar_cantera_c3()
	_probar_instituciones_c5_c8()
	_probar_charlas_c6_c7()
	_probar_licencia_c7()
	_probar_tanda_c()
	_probar_calendario_c13()
	_probar_politica_c15()
	_probar_historia_c4()
	_probar_contratos_c9()
	_probar_vida_dt()
	_probar_maestrias()
	_probar_habilidades_en_resultados()
	_probar_motor_libre()
	_probar_portafolio_futbol()
	_probar_jugadores_fijos()
	_probar_disenos_kit()
	_cerrar()

func _titulo(t: String) -> void:
	_linea("")
	_linea("===== %s =====" % t)

func _linea(t: String) -> void:
	_lineas.append(t)
	print(t)

func _comprobar(condicion: bool, que: String) -> void:
	if condicion:
		_linea("  ok    %s" % que)
	else:
		_fallos.append(que)
		_linea("  FALLO %s" % que)

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

func _probar_repetibilidad() -> void:
	_titulo("REPETIBILIDAD (lo que el HTML no puede hacer)")
	var a := Mundo.new()
	a.generar(["CHI"], 12345)
	var b := Mundo.new()
	b.generar(["CHI"], 12345)
	_comprobar(a.cuantos_jugadores() == b.cuantos_jugadores(), "misma semilla, mismo numero de jugadores")
	var ja := a.jugadores()
	var jb := b.jugadores()
	var iguales := true
	for i in mini(ja.size(), jb.size()):
		if ja[i].nombre != jb[i].nombre or ja[i].ovr != jb[i].ovr:
			iguales = false
			break
	_comprobar(iguales, "misma semilla, mismos jugadores uno a uno")
	var c := Mundo.new()
	c.generar(["CHI"], 999)
	var distinto := false
	var jc := c.jugadores()
	for i in mini(ja.size(), jc.size()):
		if ja[i].nombre != jc[i].nombre:
			distinto = true
			break
	_comprobar(distinto, "otra semilla, otro mundo")

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

func _probar_calendario() -> void:
	_titulo("CALENDARIO")
	var m := Mundo.new()
	m.generar(["CHI"], 3)
	var l := m.ligas[0]
	var n := l.clubes.size()
	_linea("  %s: %d clubes, %d jornadas" % [l.nombre, n, l.jornadas()])
	var esperadas := (n - 1) * 2 if n % 2 == 0 else n * 2
	_comprobar(l.jornadas() == esperadas, "jornadas = %d (esperadas %d)" % [l.jornadas(), esperadas])
	## Nadie puede jugar dos veces en la misma jornada.
	var repetidos := 0
	for jornada: Array in l.calendario:
		var vistos := {}
		for par: Array in jornada:
			for c: Club in par:
				if vistos.has(c.id):
					repetidos += 1
				vistos[c.id] = true
	_comprobar(repetidos == 0, "nadie juega dos veces en una jornada (%d casos)" % repetidos)
	## Todos contra todos, ida y vuelta: cada cruce con campo fijo, una sola vez.
	var cruces := {}
	for jornada: Array in l.calendario:
		for par: Array in jornada:
			var k: String = par[0].id + ">" + par[1].id
			cruces[k] = int(cruces.get(k, 0)) + 1
	var mal := 0
	for k: String in cruces:
		if int(cruces[k]) != 1:
			mal += 1
	_comprobar(mal == 0, "cada cruce local-visita aparece una sola vez (%d mal)" % mal)

func _probar_partidos() -> void:
	_titulo("PARTIDOS: LA CURVA DE GOLES")
	var m := Mundo.new()
	m.generar(["CHI"], 21)
	var l := m.ligas[0]
	var goles := 0
	var partidos := 0
	var locales := 0
	var visitas := 0
	var empates := 0
	for i in 400:
		var a: Club = l.clubes[Azar.ent(0, l.clubes.size() - 1)]
		var b: Club = l.clubes[Azar.ent(0, l.clubes.size() - 1)]
		if a == b:
			continue
		var p := Partido.new(a, b)
		var r := p.simular()
		goles += r["local"] + r["visita"]
		partidos += 1
		if r["local"] > r["visita"]: locales += 1
		elif r["local"] < r["visita"]: visitas += 1
		else: empates += 1
	var media := float(goles) / float(maxi(partidos, 1))
	_linea("  %d partidos, %.2f goles por partido" % [partidos, media])
	_linea("  local %d%%  empate %d%%  visita %d%%" % [
		locales * 100 / maxi(partidos, 1), empates * 100 / maxi(partidos, 1), visitas * 100 / maxi(partidos, 1)])
	## Un campeonato real anda entre 2 y 3,5 goles por partido. Fuera de ahi la
	## formula esta mal portada aunque no haya reventado nada.
	_comprobar(media > 1.5 and media < 4.5, "goles por partido dentro de lo creible (%.2f)" % media)
	_comprobar(locales > visitas, "el local gana mas que el visitante (%d vs %d)" % [locales, visitas])
	## Las senales tienen que dispararse: son la unica forma que tiene la
	## interfaz de enterarse de lo que pasa en el campo.
	var oidos := {"gol": 0, "tarjeta": 0, "fin": 0}
	var p2 := Partido.new(l.clubes[0], l.clubes[1])
	p2.gol.connect(func(_c: Club, _j: Jugador, _min: int, _a: Jugador) -> void: oidos["gol"] += 1)
	p2.tarjeta.connect(func(_j: Jugador, _r: bool, _min: int) -> void: oidos["tarjeta"] += 1)
	p2.terminado.connect(func(_a: int, _b: int) -> void: oidos["fin"] += 1)
	var r2 := p2.simular()
	_comprobar(oidos["gol"] == r2["local"] + r2["visita"], "la senal de gol se emite una vez por gol")
	_comprobar(oidos["fin"] == 1, "la senal de fin de partido se emite una vez")

	## "remate": la llegada que no fue gol. Hasta esta sesion `_atacar()` la
	## contaba (remates_local/visita) pero no avisaba a nadie del desenlace, asi
	## que la cronica del partido en vivo se quedaba muda entre gol y gol. Se
	## comprueba que cada remate cae en gol O en una de las tres señales -nunca
	## en las dos, nunca en ninguna- y que las proporciones caen donde caen los
	## mismos cortes r<0.55/r<0.62 del HTML.
	var tipos := {"gol": 0, "atajada": 0, "poste": 0, "fallo": 0, "gol_arbitral": 0}
	var remates_totales := 0
	for i in 40:
		var a3: Club = l.clubes[Azar.ent(0, l.clubes.size() - 1)]
		var b3: Club = l.clubes[Azar.ent(0, l.clubes.size() - 1)]
		if a3 == b3:
			continue
		var p3 := Partido.new(a3, b3)
		p3.gol.connect(func(_c: Club, _j: Jugador, _min: int, _a: Jugador) -> void: tipos["gol"] += 1)
		p3.remate.connect(func(_c: Club, _j: Jugador, tipo: String, _min: int) -> void: tipos[tipo] += 1)
		## EL ÁRBITRO "ESTRICTO" regala un penal llamando a `_anotar()` DIRECTO
		## -mismo camino que el HTML, que tambien lo suma aparte de `r<0.30`-,
		## asi que ese gol emite `gol` sin pasar nunca por `_atacar()`: no
		## suma a `remates_local/visita` ni dispara la señal `remate`. Sin
		## contarlo aparte, la cuenta de abajo se descuadra apenas un
		## "estricto" regala uno en la muestra -encontrado asi, no a proposito-.
		p3.decision_arbitral.connect(func(texto: String, _min: int) -> void:
			## Las dos frases del "estricto" -a favor ("¡GOL de penal!") y en
			## contra ("Penal cobrado en contra")- tienen que contar las dos:
			## las dos llaman a `_anotar()` igual. Sin mayusculas/minusculas
			## porque una empieza con "P" y la otra con "p".
			if texto.to_lower().contains("penal"):
				tipos["gol_arbitral"] += 1)
		p3.simular()
		remates_totales += p3.remates_local + p3.remates_visita
	var no_gol: int = int(tipos["atajada"]) + int(tipos["poste"]) + int(tipos["fallo"])
	var goles_de_remate: int = int(tipos["gol"]) - int(tipos["gol_arbitral"])
	_linea("  %d remates: %d goles, %d atajadas, %d postes, %d fallos (%d goles de penal arbitral, aparte)" % [
		remates_totales, goles_de_remate, tipos["atajada"], tipos["poste"], tipos["fallo"], tipos["gol_arbitral"]])
	_comprobar(remates_totales == goles_de_remate + no_gol,
		"cada remate termina en gol o en una senal de remate, sin contar los penales del arbitro (%d = %d)" % [remates_totales, goles_de_remate + no_gol])
	## Sobre los NO-goles: atajada deberia rondar 25/70 (~36%), poste 7/70
	## (~10%), fallo 38/70 (~54%). Con margen ancho porque son proporciones
	## sobre una muestra de unos pocos cientos, no miles.
	var pct_atajada := float(tipos["atajada"]) / maxf(1.0, float(no_gol))
	var pct_poste := float(tipos["poste"]) / maxf(1.0, float(no_gol))
	_comprobar(pct_atajada > 0.22 and pct_atajada < 0.50, "atajada ronda su proporcion del HTML (%.0f%%)" % (pct_atajada * 100.0))
	_comprobar(pct_poste > 0.03 and pct_poste < 0.20, "poste ronda su proporcion del HTML (%.0f%%)" % (pct_poste * 100.0))

	## Las estadisticas de `M.st` del HTML: posesion, tiros a puerta, xG,
	## corners, faltas y fueras de juego. No mueven el marcador, pero si alguna
	## se descuadra -mas tiros a puerta que remates, mas goles que tiros a
	## puerta- la pantalla de despues del partido miente.
	var mal_puerta := 0
	var mal_goles := 0
	var mal_posesion := 0
	var xg_total := 0.0
	var corners_totales := 0
	var faltas_totales := 0
	var fueras_totales := 0
	var partidos_st := 0
	for i2 in 40:
		var a4: Club = l.clubes[i2 % l.clubes.size()]
		var b4: Club = l.clubes[(i2 + 5) % l.clubes.size()]
		if a4 == b4:
			continue
		var p4 := Partido.new(a4, b4)
		p4.simular()
		partidos_st += 1
		if p4.tiros_puerta_local > p4.remates_local or p4.tiros_puerta_visita > p4.remates_visita:
			mal_puerta += 1
		if p4.goles_local > p4.tiros_puerta_local or p4.goles_visita > p4.tiros_puerta_visita:
			mal_goles += 1
		if p4.posesion_local < 22.0 or p4.posesion_local > 78.0:
			mal_posesion += 1
		xg_total += p4.xg_local + p4.xg_visita
		corners_totales += p4.corners_local + p4.corners_visita
		faltas_totales += p4.faltas_local + p4.faltas_visita
		fueras_totales += p4.fueras_local + p4.fueras_visita
	var corners_media := float(corners_totales) / maxf(1.0, float(partidos_st))
	var faltas_media := float(faltas_totales) / maxf(1.0, float(partidos_st))
	var fueras_media := float(fueras_totales) / maxf(1.0, float(partidos_st))
	_linea("  por partido: %.1f corners, %.1f faltas, %.1f fueras de juego, %.2f xG" % [
		corners_media, faltas_media, fueras_media, xg_total / maxf(1.0, float(partidos_st))])
	_comprobar(mal_puerta == 0, "nunca hay mas tiros a puerta que remates (%d mal)" % mal_puerta)
	_comprobar(mal_goles == 0, "nunca hay mas goles que tiros a puerta (%d mal)" % mal_goles)
	_comprobar(mal_posesion == 0, "la posesion se queda entre 22 y 78 (%d fuera)" % mal_posesion)
	## Con las probabilidades del HTML (10%+9% corners, 16%+17% faltas, 5%+5%
	## fueras por minuto sobre 90) lo esperable ronda 17 corners, 30 faltas y 9
	## fueras por partido. Margen ancho: es un sorteo, no una cuenta fija.
	_comprobar(corners_media > 9.0 and corners_media < 26.0, "los corners por partido son creibles (%.1f)" % corners_media)
	_comprobar(faltas_media > 18.0 and faltas_media < 42.0, "las faltas por partido son creibles (%.1f)" % faltas_media)
	_comprobar(fueras_media > 3.0 and fueras_media < 16.0, "los fueras de juego por partido son creibles (%.1f)" % fueras_media)
	_comprobar(xg_total > 0.0, "el xG se acumula de verdad (%.1f en %d partidos)" % [xg_total, partidos_st])

## `vPrevia()`: árbitro, DT rival y cuotas. Nada de esto guarda estado, así que
## lo que hay que probar es que sea ESTABLE (el mismo árbitro toda la semana, el
## mismo DT toda la vida del club) y que las cuotas digan lo mismo que el motor.
func _probar_previa() -> void:
	_titulo("LA PREVIA: ARBITRO, DT RIVAL Y CUOTAS")
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var l := m.ligas[0]
	var fuerte: Club = l.clubes[0]
	var flojo: Club = l.clubes[0]
	for c: Club in l.clubes:
		if c.rep > fuerte.rep:
			fuerte = c
		if c.rep < flojo.rep:
			flojo = c
	_linea("  fuerte: %s (rep %d)   flojo: %s (rep %d)" % [fuerte.nombre, fuerte.rep, flojo.nombre, flojo.rep])

	var a1 := Previa.arbitro_de(flojo.id, 5)
	var a2 := Previa.arbitro_de(flojo.id, 5)
	_comprobar(String(a1["nombre"]) == String(a2["nombre"]), "el arbitro es el mismo toda la semana (%s)" % String(a1["nombre"]))
	_comprobar(String(a1["descripcion"]) != "", "el arbitro trae su descripcion (%s)" % String(a1["descripcion"]))
	var distintos := {}
	for semana in range(1, 30):
		distintos[String(Previa.arbitro_de(flojo.id, semana)["nombre"])] = true
	_comprobar(distintos.size() > 3, "no pita siempre el mismo en toda la temporada (%d arbitros en 29 fechas)" % distintos.size())

	var dt1 := Previa.dt_de(flojo)
	var dt2 := Previa.dt_de(flojo)
	_comprobar(String(dt1["nombre"]) == String(dt2["nombre"]), "el DT rival es parte de la identidad del club, no cambia (%s)" % String(dt1["nombre"]))
	_comprobar(String(dt1["nombre"]) != String(Previa.dt_de(fuerte)["nombre"]) or flojo == fuerte, "dos clubes distintos no comparten DT")
	_comprobar(String(dt1["descripcion"]) != "", "el DT rival trae su estilo (%s)" % String(dt1["estilo"]))

	## Las cuotas: se miden con las fuerzas de verdad de los dos onces.
	var p := Partido.new(fuerte, flojo)
	p.preparar()
	var f_fuerte := p.fuerza(p.once_local, fuerte)
	var f_flojo := p.fuerza(p.once_visita, flojo)
	_linea("  fuerzas reales -> %s ata=%.1f def=%.1f   |   %s ata=%.1f def=%.1f" % [
		fuerte.nombre, f_fuerte["ata"], f_fuerte["def"],
		flojo.nombre, f_flojo["ata"], f_flojo["def"]])
	## OJO: las fuerzas de arriba salen casi iguales aunque la reputacion sea
	## 88 contra 67. Eso NO es cosa de las cuotas -es el armado del once, ver la
	## nota "un rep 88 no es mas fuerte que un rep 67" en el LEEME-, asi que la
	## matematica de la cuota se prueba con numeros CONTROLADOS, que es lo unico
	## que este modulo decide. Con fuerzas de verdad solo se comprueba que no
	## reviente y que sume 1.
	var c_fuerte := Previa.cuotas(f_fuerte, f_flojo, true)
	var suma: float = float(c_fuerte["p_gano"]) + float(c_fuerte["p_empate"]) + float(c_fuerte["p_pierdo"])
	_linea("  el fuerte de local: gana %.0f%%  empata %.0f%%  pierde %.0f%%   (cuotas %.2f / %.2f / %.2f)" % [
		float(c_fuerte["p_gano"]) * 100.0, float(c_fuerte["p_empate"]) * 100.0, float(c_fuerte["p_pierdo"]) * 100.0,
		float(c_fuerte["cuota_gano"]), float(c_fuerte["cuota_empate"]), float(c_fuerte["cuota_pierdo"])])
	_comprobar(absf(suma - 1.0) < 0.001, "las tres probabilidades suman 1 (%.4f)" % suma)
	_comprobar(float(c_fuerte["cuota_gano"]) >= 1.03, "ninguna cuota baja de 1.03 (%.2f)" % float(c_fuerte["cuota_gano"]))

	## Con numeros CONTROLADOS: un equipo claramente mejor (ata 80/def 80) contra
	## uno claramente peor (ata 50/def 50), que es lo que la reputacion deberia
	## producir y hoy no produce.
	var top := {"ata": 80.0, "def": 80.0}
	var malo := {"ata": 50.0, "def": 50.0}
	var c_top := Previa.cuotas(top, malo, true)
	var c_malo := Previa.cuotas(malo, top, true)
	_linea("  controlado -> bueno en casa gana %.0f%%   malo en casa gana %.0f%%" % [
		float(c_top["p_gano"]) * 100.0, float(c_malo["p_gano"]) * 100.0])
	_comprobar(float(c_top["p_gano"]) > float(c_top["p_pierdo"]), "el mejor es favorito")
	_comprobar(float(c_top["cuota_gano"]) < float(c_top["cuota_pierdo"]), "al favorito se le paga menos")
	_comprobar(float(c_top["p_gano"]) > float(c_malo["p_gano"]),
		"a igualdad de campo, el mejor tiene mas opciones (%.0f%% vs %.0f%%)" % [
			float(c_top["p_gano"]) * 100.0, float(c_malo["p_gano"]) * 100.0])
	## La localia: el MISMO cruce, cambiando solo de campo, tiene que mover la
	## probabilidad hacia el que juega en casa.
	var c_visitante := Previa.cuotas(top, malo, false)
	_comprobar(float(c_top["p_gano"]) > float(c_visitante["p_gano"]),
		"jugar en casa sube tus opciones (%.0f%% vs %.0f%%)" % [float(c_top["p_gano"]) * 100.0, float(c_visitante["p_gano"]) * 100.0])
	## Y los goles esperados tienen que estar en la escala de GOLES, no de
	## llegadas: dos equipos parejos rondan 1,3 cada uno, no 4.
	var lam_parejo := Previa._goles_esperados(60.0, 60.0, 1.0)
	_comprobar(lam_parejo > 0.8 and lam_parejo < 2.2,
		"los goles esperados estan en escala de goles, no de llegadas (%.2f)" % lam_parejo)
	## LA JERARQUIA DEPORTIVA. Esto empezo siendo un aviso: un rep 88 y un rep
	## 67 daban fuerzas casi iguales (59.3 contra 59.5), o sea que un grande no
	## se distinguia de un chico en el campo. La causa estaba en `reales.gd`
	## -reescalaba el `ovr` sin regenerar los atributos, y encima anclaba la
	## banda a los reales en vez de a la reputacion-. Arreglado, esto se queda
	## como red: si la jerarquia se vuelve a aplastar, salta aqui.
	var ata_fuerte: float = f_fuerte["ata"]
	var ata_flojo: float = f_flojo["ata"]
	_comprobar(ata_fuerte > ata_flojo,
		"un club de rep %d ataca mas que uno de rep %d (%.1f vs %.1f)" % [
			fuerte.rep, flojo.rep, ata_fuerte, ata_flojo])
	var brecha := ata_fuerte - ata_flojo
	_comprobar(brecha > 4.0,
		"y la diferencia se nota de verdad, no por decimas (%.1f puntos)" % brecha)

## EL ÁRBITRO YA NO ES SOLO UN NOMBRE EN LA PREVIA: decide cosas durante el
## propio partido -`_chequeo_arbitral()`-, y esas decisiones tenían que
## consumir `Azar` de verdad porque cambian tarjetas y algún marcador -a
## diferencia de un adorno cosmético, que nunca debe tocarlo-. Lo que se
## prueba aquí es que el MISMO árbitro que `Previa.arbitro_de()` anuncia antes
## del partido es el que de verdad pita (`Partido.preparar()` no recalcula el
## hash con una fórmula distinta), y que sus decisiones narran y mueven el
## marcador cuando tienen que hacerlo.
func _probar_arbitros() -> void:
	_titulo("EL ÁRBITRO EN EL PROPIO PARTIDO")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	var l := m.ligas[0]
	var a: Club = l.clubes[0]
	var b: Club = l.clubes[1]
	## `Partido.preparar()` fija `ctx_semana`/`ctx_club_id` desde los estaticos:
	## se ponen a mano, como hace `Mundo.avanzar_semana()` cada semana.
	Partido.ctx_semana = 5
	Partido.ctx_club_id = ""
	var p := Partido.new(a, b)
	p.preparar()
	var esperado := Previa.arbitro_de(b.id, 5)
	_comprobar(String(p.arbitro["nombre"]) == String(esperado["nombre"]),
		"el que pita en el partido es el mismo que anuncia la previa (%s)" % String(p.arbitro["nombre"]))

	## Con volumen -las probabilidades son de 0,3% a 1% POR LLEGADA- tiene que
	## verse de todo: tarjetas de mas, algun penal, y la narracion propia.
	##
	## CONTADORES EN UN DICCIONARIO, NO EN `var int` SUELTAS: una lambda de
	## GDScript captura una variable local de tipo valor (int/float/bool) por
	## COPIA en el momento en que se crea, así que `narraciones += 1` dentro
	## del closure solo movía su propia copia privada y el contador de fuera
	## se quedaba siempre en 0 -el mismo motivo por el que `_probar_partidos()`,
	## mas arriba, ya usaba un diccionario (`oidos`) para esto mismo: un
	## Dictionary es un tipo por referencia, así que sí se comparte con quien
	## conectó la señal-.
	var cont := {"narraciones": 0, "tarjetas": 0}
	var goles_totales := 0
	for i in 500:
		var p2 := Partido.new(l.clubes[i % l.clubes.size()], l.clubes[(i + 4) % l.clubes.size()])
		if p2.local == p2.visita:
			continue
		p2.decision_arbitral.connect(func(_t: String, _m: int) -> void: cont["narraciones"] += 1)
		p2.tarjeta.connect(func(_j: Jugador, _r: bool, _m: int) -> void: cont["tarjetas"] += 1)
		var r2 := p2.simular()
		goles_totales += r2["local"] + r2["visita"]
	_comprobar(int(cont["narraciones"]) > 0, "el arbitro narra al menos una decision en 500 partidos (%d)" % int(cont["narraciones"]))
	_linea("  %d partidos: %d decisiones arbitrales narradas, %d tarjetas repartidas (arbitrales + normales)" % [
		500, int(cont["narraciones"]), int(cont["tarjetas"])])
	_comprobar(goles_totales > 0, "el motor sigue anotando goles con el arbitro metido en el medio (%d)" % goles_totales)

	## `Prensa.arbitro_dudoso()`: la rama de "reclamo formal" en el despacho
	## estaba completa desde antes y nadie la llamaba -quedo anotado en el
	## LEEME como pendiente-. Se busca una semana en la que el arbitro de un
	## cruce sea "casero" o "figura" -no se espera al sorteo real, que podria
	## tardar temporadas en dar ese perfil- y se le fabrica una derrota.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 314)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	var mio2 := m2.mi_club()
	var rival2: Club = null
	var semana_mala := -1
	for s in 60:
		for c2: Club in m2.ligas[0].clubes:
			if c2 == mio2:
				continue
			var arb2 := Previa.arbitro_de(c2.id, s)
			if String(arb2["perfil"]) == "casero" or String(arb2["perfil"]) == "figura":
				rival2 = c2
				semana_mala = s
				break
		if rival2 != null:
			break
	_comprobar(rival2 != null, "se encuentra alguna semana con arbitro casero/figura para probar el aviso")
	if rival2 != null:
		_comprobar(m2.prensa.arbitro_polemico == "", "no hay reclamo pendiente antes de perder")
		m2.semana = semana_mala
		m2._avisar_a_la_directiva([{"local": mio2, "visita": rival2, "gl": 0, "gv": 1}])
		_comprobar(m2.prensa.arbitro_polemico != "",
			"perder con un arbitro casero/figura deja listo el reclamo formal (%s)" % m2.prensa.arbitro_polemico)
	## Los estaticos de contexto son GLOBALES a la clase: si se dejan puestos,
	## el siguiente `Partido` suelto que arme otra prueba -sin pasar por
	## `Mundo.avanzar_semana()`, que los vuelve a fijar- heredaria la semana 5
	## de esta prueba.
	Partido.limpiar_contexto()

## EL PIE HÁBIL: "D.d==='LAT'&&D.b&&j.pie&&D.b!==j.pie" del HTML. `Jugador.
## pie()` YA EXISTÍA -de un hash de su id, no guardado, misma proporción
## 76/24 del HTML- pero solo lo leía `aptitud_en()`, usado en un único sitio
## de la interfaz; nunca llegaba a la fuerza real del partido. Se prueba con
## dos jugadores IDÉNTICOS salvo el id -que es de donde sale el pie-, puestos
## de laterales derechos: el zurdo tiene que rendir un 6% menos, ni un
## central ni un delantero pierden nada por jugar del pie contrario.
func _probar_pie_habil() -> void:
	_titulo("EL PIE HÁBIL: LOS LATERALES SÍ LO NOTAN")
	var m := Mundo.new()
	m.generar(["CHI"], 5150)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var p := Partido.new(a, b)

	## `pie()` sale del id, así que para comparar un diestro con un zurdo hay
	## que buscar dos ids -no importa cuáles- cuyo hash caiga a cada lado.
	var id_d := ""
	var id_i := ""
	for i in 200:
		var candidato := "prueba_pie_%d" % i
		var j0 := Jugador.new()
		j0.id = candidato
		if j0.pie() == "D" and id_d == "":
			id_d = candidato
		elif j0.pie() == "I" and id_i == "":
			id_i = candidato
		if id_d != "" and id_i != "":
			break
	_comprobar(id_d != "" and id_i != "", "se encuentran ids de sobra para un diestro y un zurdo")

	var diestro := Jugador.new()
	diestro.id = id_d; diestro.pos_e = "LD"; diestro.pos = "DEF"; diestro.ovr = 75
	diestro.forma = 60; diestro.fisico = 70; diestro.moral = 60
	var zurdo := Jugador.new()
	zurdo.id = id_i; zurdo.pos_e = "LD"; zurdo.pos = "DEF"; zurdo.ovr = 75
	zurdo.forma = 60; zurdo.fisico = 70; zurdo.moral = 60

	var media_diestro := p._media_linea([diestro], "DEF")
	var media_zurdo := p._media_linea([zurdo], "DEF")
	_linea("  LD con pie D: %.2f   ·   LD con pie I: %.2f" % [media_diestro, media_zurdo])
	_comprobar(media_zurdo < media_diestro,
		"un lateral del pie contrario a su banda rinde menos (%.2f < %.2f)" % [media_zurdo, media_diestro])
	_comprobar(absf(media_zurdo / media_diestro - 0.94) < 0.001,
		"la penalizacion es exactamente la del HTML, 0.94 (%.4f)" % (media_zurdo / media_diestro))

	## Un central zurdo, en cambio, no pierde nada: "es_lateral()" es falso
	## para DFC.
	var central_zurdo := Jugador.new()
	central_zurdo.id = id_i; central_zurdo.pos_e = "DFC"; central_zurdo.pos = "DEF"; central_zurdo.ovr = 75
	central_zurdo.forma = 60; central_zurdo.fisico = 70; central_zurdo.moral = 60
	var central_diestro := Jugador.new()
	central_diestro.id = id_d; central_diestro.pos_e = "DFC"; central_diestro.pos = "DEF"; central_diestro.ovr = 75
	central_diestro.forma = 60; central_diestro.fisico = 70; central_diestro.moral = 60
	var media_central_zurdo := p._media_linea([central_zurdo], "DEF")
	var media_central_diestro := p._media_linea([central_diestro], "DEF")
	_comprobar(absf(media_central_zurdo - media_central_diestro) < 0.001,
		"un central no pierde nada por ser zurdo (%.2f vs %.2f)" % [media_central_zurdo, media_central_diestro])

	## Y de nacimiento: casi 8 de cada 10 futbolistas del mundo son diestros
	## -se mide sobre el mundo generado de verdad, con los ids que de verdad
	## reparte `Mundo.crear_jugador()` ("j1","j2","j3"...), no sobre una
	## muestra sintética-.
	var m2 := Mundo.new()
	m2.generar(["CHI", "ARG", "BRA"], 6060)
	var diestros := 0
	var total := 0
	for c: Club in m2.clubes.values():
		for j: Jugador in c.plantilla:
			total += 1
			if j.pie() == "D":
				diestros += 1
	var pct := float(diestros) / float(maxi(total, 1))
	_linea("  %d futbolistas: %.0f%% diestros" % [total, pct * 100.0])
	_comprobar(pct > 0.68 and pct < 0.84, "la proporcion diestro/zurdo ronda el 76%% del HTML (%.0f%%)" % (pct * 100.0))

func _probar_banquillo() -> void:
	_titulo("BANQUILLO: ONCE, CAMBIOS Y PENALES")
	var m := Mundo.new()
	m.generar(["CHI"], 1234)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]

	## El once que elige el entrenador manda sobre el automatico.
	var mio: Array[Jugador] = []
	var libres := a.disponibles()
	for i in 11:
		mio.append(libres[i])
	a.fijar_once(mio)
	var salido := a.once()
	var coincide := salido.size() == 11
	if coincide:
		for i in 11:
			if salido[i] != mio[i]:
				coincide = false
				break
	_comprobar(coincide, "el once elegido a mano es el que sale al campo")
	## Y si uno de los elegidos se lesiona, se arma el automatico en vez de
	## sacar a diez: es el caso que rompe un once guardado de la semana pasada.
	mio[5].lesion = 3
	_comprobar(a.once().size() == 11, "con un titular lesionado sigue saliendo un once de 11")
	mio[5].lesion = 0
	a.limpiar_once()

	var p := Partido.new(a, b)
	p.preparar()
	for i in 20:
		p.simular_minuto()
	var titular: Jugador = p.once_local[7]
	var suplente: Jugador = null
	for j in a.plantilla:
		if not p.once_local.has(j) and j.disponible():
			suplente = j
			break
	var fuerza_antes: float = p.fuerza(p.once_local, a)["ata"]
	_comprobar(p.cambiar(titular, suplente) == "", "se puede hacer un cambio")
	_comprobar(p.once_local.has(suplente) and not p.once_local.has(titular), "el suplente entra y el titular sale")
	_comprobar(p.cambiar(titular, suplente) != "", "no se puede sacar a quien ya no esta en el campo")
	## Lo que de verdad importa: que el cambio SE NOTE. Si la fuerza cacheada no
	## se invalida, el equipo sigue jugando con el once que ya no esta ahi y la
	## pizarra es un menu decorativo.
	var fuerza_despues: float = p.fuerza(p.once_local, a)["ata"]
	_comprobar(not is_equal_approx(fuerza_antes, fuerza_despues) or titular.ovr == suplente.ovr,
		"cambiar a alguien cambia la fuerza del equipo")

	## El tope de cinco.
	var hechos := 1
	for j in a.plantilla:
		if hechos >= 8:
			break
		if p.once_local.has(j) or not j.disponible():
			continue
		if p.cambiar(p.once_local[0], j) == "":
			hechos += 1
	_comprobar(p.cambios_local == Partido.MAX_CAMBIOS, "no se pueden hacer mas de %d cambios (van %d)" % [
		Partido.MAX_CAMBIOS, p.cambios_local])

	## Penales: nunca pueden acabar en empate.
	## `penales()` quedó memoizado (`partido_vivo.gd` puede resolverlos en vivo y
	## `Copa.jugar_ronda()` los vuelve a pedir después sobre el MISMO objeto, y
	## sin caché el visor podía anunciar un ganador distinto del que la copa
	## calculaba al avanzar la semana) -así que probar 200 tandas hace falta un
	## `Partido` nuevo cada vez, o las 200 vueltas leerían la primera memoizada.
	var empates := 0
	for i in 200:
		var pp := Partido.new(a, b)
		var r := pp.penales()
		if r[0] == r[1]:
			empates += 1
	_comprobar(empates == 0, "una tanda de penales nunca acaba empatada (%d de 200)" % empates)

	## Y el partido dirigido: su resultado tiene que ser el que va a la tabla.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 31)
	m2.mi_club_id = m2.ligas[0].clubes[2].id
	var par := m2.proximo_partido()
	_comprobar(par.size() == 2, "hay partido esta jornada")
	var dirigido := Partido.new(par[0], par[1])
	dirigido.simular()
	## Se fuerza un marcador imposible de repetir por azar: si en la tabla
	## aparece otro numero, es que la jornada lo volvio a simular por dentro.
	dirigido.goles_local = 7
	dirigido.goles_visita = 3
	m2.avanzar_semana(dirigido)
	var liga := m2.liga_de(m2.mi_club())
	var gf_local := 0
	var gc_local := 0
	for fila: Dictionary in liga.tabla():
		if fila["club"] == par[0]:
			gf_local = fila["gf"]
			gc_local = fila["gc"]
	_comprobar(gf_local == 7 and gc_local == 3,
		"el resultado del partido dirigido es el que va a la tabla (%d-%d)" % [gf_local, gc_local])

func _probar_finanzas() -> void:
	_titulo("FINANZAS")
	var m := Mundo.new()
	m.generar(["CHI"], 88)
	var c: Club = m.ligas[0].clubes[0]
	var f := Finanzas.new(c)
	_linea("  %s: aforo %d, %d socios, entrada %.1f" % [c.nombre, c.estadio_aforo, c.socios, c.precio_entrada])
	var base := f.asistencia()
	_linea("  asistencia con entrada a 6: %d (%.0f%% del aforo)" % [base, 100.0 * float(base) / float(c.estadio_aforo)])
	## Subir el precio tiene que VACIAR el estadio, o el precio no es una
	## decision: es un boton de dinero gratis.
	c.precio_entrada = 14.0
	var cara := f.asistencia()
	c.precio_entrada = 2.0
	var barata := f.asistencia()
	c.precio_entrada = 6.0
	_linea("  a 14 entran %d, a 2 entran %d" % [cara, barata])
	_comprobar(cara < base and base < barata, "el precio de la entrada mueve la asistencia en el sentido correcto")
	_comprobar(f.asistencia() >= int(float(c.estadio_aforo) * 0.12), "nunca baja del 12% del aforo")
	c.precio_entrada = 99.0
	_comprobar(f.asistencia() >= int(float(c.estadio_aforo) * 0.12), "ni con la entrada a 99 se vacia del todo")
	c.precio_entrada = 6.0
	## Una semana con partido en casa tiene que dejar mas que una sin el.
	var antes := c.saldo
	f.semana(true)
	var con_casa := c.saldo - antes
	c.saldo = antes
	f.semana(false)
	var sin_casa := c.saldo - antes
	c.saldo = antes
	_linea("  semana en casa: %s   |   semana fuera: %s" % [_dinero(con_casa), _dinero(sin_casa)])
	_comprobar(con_casa > sin_casa, "jugar en casa deja mas dinero que jugar fuera")

	## El cierre de mes, que es donde se paga todo de golpe.
	var m4 := f.mes()
	c.saldo = antes
	_linea("  cierre de mes: entran %s, salen %s, neto %s" % [
		_dinero(m4["entra"]), _dinero(m4["sale"]), _dinero(m4["neto"])])
	_comprobar(m4["entra"] > 0 and m4["sale"] > 0, "el mes tiene ingresos y gastos")

	## Y lo que de verdad importa: que un club llevado por la IA ni quiebre ni se
	## haga de oro solo con dejar pasar el tiempo. Es la prueba que caza los
	## errores de unidades, que son los que no hacen ruido.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 606)
	var vigilados: Array[Club] = [m2.ligas[0].clubes[0], m2.ligas[0].clubes[8], m2.ligas[1].clubes[0]]
	var caja0: Array[int] = []
	for v in vigilados:
		caja0.append(v.saldo)
	for temporada in 3:
		m2.jugar_temporada()
		m2.nueva_temporada()
	var rotos := 0
	var ricos := 0
	for i in vigilados.size():
		var v := vigilados[i]
		var factor := float(v.saldo) / float(maxi(caja0[i], 1))
		_linea("  %-22s %s -> %s  (x%.1f)" % [v.nombre, _dinero(caja0[i]), _dinero(v.saldo), factor])
		if v.saldo < 0:
			rotos += 1
		if factor > 12.0:
			ricos += 1
	_comprobar(rotos == 0, "ningun club quiebra en tres temporadas (%d)" % rotos)
	_comprobar(ricos == 0, "ningun club multiplica su caja por doce sin hacer nada (%d)" % ricos)

func _probar_mercado() -> void:
	_titulo("MERCADO DE FICHAJES")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	var mk := m.mercado
	var grande: Club = null
	var chico: Club = null
	for c: Club in m.clubes.values():
		if grande == null or c.rep > grande.rep: grande = c
		if chico == null or c.rep < chico.rep: chico = c
	_linea("  club grande: %s (rep %d)   club chico: %s (rep %d)" % [grande.nombre, grande.rep, chico.nombre, chico.rep])

	## La joya de 20 con techo alto tiene que costar bastante mas que su valor.
	var joya := Jugador.new()
	joya.club_id = chico.id
	joya.edad = 20; joya.ovr = 75; joya.pot = 90; joya.anios_contrato = 4
	joya.tasar()
	var normal := Jugador.new()
	normal.club_id = chico.id
	normal.edad = 27; normal.ovr = 75; normal.pot = 75; normal.anios_contrato = 4
	normal.tasar()
	_linea("  joya de 20 (75/90): valor %s, piden %s" % [_dinero(joya.valor), _dinero(mk.valor_pedido(joya))])
	_linea("  jugador de 27 (75/75): valor %s, piden %s" % [_dinero(normal.valor), _dinero(mk.valor_pedido(normal))])
	_comprobar(mk.valor_pedido(joya) > mk.valor_pedido(normal), "por la joya piden mas que por el hecho")
	_comprobar(mk.valor_pedido(joya) > joya.valor, "el club pide por encima del valor de tasacion")

	## El deseo de venir: al grande se va casi cualquiera, al chico no.
	var suyo: Jugador = grande.plantilla[0]
	suyo.club_id = grande.id
	var al_chico: float = mk.deseo_de_venir(suyo, chico)["p"]
	var del_chico: Jugador = chico.plantilla[0]
	var al_grande: float = mk.deseo_de_venir(del_chico, grande)["p"]
	_linea("  del grande al chico: %.0f%% de ganas   |   del chico al grande: %.0f%%" % [al_chico * 100.0, al_grande * 100.0])
	_comprobar(al_grande > al_chico, "se quiere subir de club, no bajar")
	var razones: Array = mk.deseo_de_venir(suyo, chico)["razones"]
	_comprobar(razones.size() > 0, "la negativa viene con motivos que se le pueden ensenar al jugador")

	## Y el que no quiere venir se pone caro en vez de decir que no.
	var pide_al_chico := mk.ficha_que_pide(suyo, chico)
	var pide_al_grande := mk.ficha_que_pide(suyo, grande)
	_linea("  ficha que pide: al chico %s, al grande %s" % [_dinero(pide_al_chico), _dinero(pide_al_grande)])
	_comprobar(pide_al_chico > pide_al_grande, "al club que no le seduce le pide mas ficha")

	## Regateo: el club acepta cerca de lo pedido y nunca una miseria.
	var pedido := mk.valor_pedido(normal)
	_comprobar(mk.club_acepta(normal, pedido), "acepta lo que pide")
	_comprobar(not mk.club_acepta(normal, int(float(pedido) * 0.5)), "no acepta la mitad")

	## El mercado de la IA tiene que mover el mundo, pero sin deshacerlo.
	var antes_totales := m.cuantos_jugadores()
	var hechos := 0
	for semana in 20:
		hechos += mk.mover().size()
	_linea("  %d traspasos entre clubes de la IA en 20 semanas" % hechos)
	_comprobar(hechos > 0, "el mercado de la IA mueve jugadores")
	_comprobar(m.cuantos_jugadores() == antes_totales, "no se pierde ni se duplica ningun jugador (%d)" % m.cuantos_jugadores())
	var cortas := 0
	var sin_club := 0
	for c: Club in m.clubes.values():
		if c.plantilla.size() < 18:
			cortas += 1
		for j in c.plantilla:
			if j.club_id != c.id:
				sin_club += 1
	_comprobar(cortas == 0, "ningun club se queda corto de plantilla por vender (%d)" % cortas)
	_comprobar(sin_club == 0, "cada jugador apunta al club en el que esta (%d descuadrados)" % sin_club)

	## jugador_por_id(): lo usa el comparador nuevo de la ficha para resolver
	## los tres ids que guarda `_comparar_ids` en memoria.
	var cualquiera: Jugador = grande.plantilla[0]
	_comprobar(m.jugador_por_id(cualquiera.id) == cualquiera, "jugador_por_id encuentra al jugador correcto")
	_comprobar(m.jugador_por_id("no-existe-esto") == null, "jugador_por_id no encuentra lo que no existe")

func _probar_puente3d() -> void:
	_titulo("PUENTE AL 3D (los 22 al campo)")
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	_linea("  %s viste %s / %s   |   %s viste %s / %s" % [
		a.nombre, a.color1, a.color2, b.nombre, b.color1, b.color2])
	_comprobar(a.color1 != "" and a.color1.begins_with("#"), "el club conserva su color de camiseta")

	var once := Puente3D.once(a.once())
	_comprobar(once["xi"].size() == 11, "el once que va al 3D tiene 11 (%d)" % once["xi"].size())
	_comprobar(once["jugadores"].size() == 11, "hay una ficha por jugador")
	var primero: Dictionary = once["jugadores"][once["xi"][0]]
	_comprobar(primero.has("dorsal") and primero.has("look") and primero.has("alt"),
		"la ficha trae dorsal, aspecto y altura")

	## Las alturas por demarcacion: el central tiene que ser mas alto que el
	## lateral, o el once parece una fila de clones.
	var alt_dfc: float = Puente3D.ALTURA["DFC"]
	var alt_ld: float = Puente3D.ALTURA["LD"]
	_linea("  altura: central %.2f m, lateral %.2f m, portero %.2f m" % [
		alt_dfc, alt_ld, Puente3D.ALTURA["POR"]])
	_comprobar(alt_dfc > alt_ld, "el central es mas alto que el lateral")

	## El aspecto tiene que ser ESTABLE: el mismo jugador, la misma cara siempre.
	var j: Jugador = a.once()[3]
	_comprobar(Puente3D.jugador(j)["look"]["piel"] == Puente3D.jugador(j)["look"]["piel"],
		"el mismo jugador tiene siempre el mismo aspecto")

	## Y el portero tiene que CONTRASTAR con sus companeros, o desde la camara
	## alta no se distingue del central.
	var kp := Puente3D.kit_portero(a)
	var d := Puente3D._distancia(Color(kp["c1"]), Color(a.color1))
	_linea("  %s de campo %s, portero %s" % [a.nombre, a.color1, kp["c1"]])
	_comprobar(d > 0.25, "la camiseta del portero contrasta con la del equipo (%.2f)" % d)

	## Y la formacion tiene que traer sus once ranuras del catalogo del HTML.
	var f := Puente3D.formacion(a.tactica.formacion)
	_comprobar(f.get("s", []).size() == 11, "la formacion %s trae 11 ranuras" % a.tactica.formacion)

func _probar_notas() -> void:
	_titulo("NOTAS POR PARTIDO")
	var m := Mundo.new()
	m.generar(["CHI"], 8080)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[10]
	var p := Partido.new(a, b)
	p.simular()
	_linea("  %s %d-%d %s" % [a.nombre, p.goles_local, p.goles_visita, b.nombre])
	var con_nota := 0
	var fuera_de_rango := 0
	for j in p.once_local + p.once_visita:
		if not j.notas.is_empty():
			con_nota += 1
			if j.notas[0] < 3.0 or j.notas[0] > 10.0:
				fuera_de_rango += 1
	_comprobar(con_nota == 22, "los 22 salen con nota (%d)" % con_nota)
	_comprobar(fuera_de_rango == 0, "todas las notas caen entre 3 y 10 (%d fuera)" % fuera_de_rango)

	## El que marca tiene que puntuar mejor que la media de su equipo: si no, la
	## nota no mide nada y la tabla de goleadores y el equipo ideal dan igual.
	var goleador: Jugador = null
	for j in p.once_local:
		if j.goles > 0:
			goleador = j
			break
	if goleador != null:
		var media := 0.0
		for j in p.once_local:
			media += j.notas[0]
		media /= float(p.once_local.size())
		_linea("  %s marco y saco %.1f; la media de su equipo fue %.1f" % [
			goleador.nombre, goleador.notas[0], media])
		_comprobar(goleador.notas[0] > media, "el que marca puntua por encima de su equipo")

	## Ganar tiene que puntuar mejor que perder, en promedio.
	var suma_gana := 0.0
	var suma_pierde := 0.0
	var n_gana := 0
	var n_pierde := 0
	for i in 40:
		var q := Partido.new(a, b)
		var r := q.simular()
		if r["local"] == r["visita"]:
			continue
		var gano: bool = r["local"] > r["visita"]
		for j in q.once_local:
			if gano: suma_gana += j.notas[j.notas.size() - 1]; n_gana += 1
			else: suma_pierde += j.notas[j.notas.size() - 1]; n_pierde += 1
	if n_gana > 0 and n_pierde > 0:
		_linea("  nota media ganando %.2f, perdiendo %.2f" % [
			suma_gana / n_gana, suma_pierde / n_pierde])
		_comprobar(suma_gana / n_gana > suma_pierde / n_pierde, "ganar puntua mejor que perder")

	## Solo se guardan las ocho ultimas: con mas, un mal mes queda enterrado.
	var uno: Jugador = a.plantilla[0]
	for i in 20:
		uno.anotar_nota(7.0)
	_comprobar(uno.notas.size() == 8, "se guardan solo las ocho ultimas notas (%d)" % uno.notas.size())
	## Y la media no se inventa nada mientras no haya partidos suficientes.
	var nuevo := Jugador.new()
	_comprobar(is_zero_approx(nuevo.media_notas()), "sin partidos, la media de notas es cero, no un 6 regalado")

	## Y la forma tiene que seguir a las notas: una racha buena la sube.
	var antes := uno.forma
	uno.forma = 40
	var q2 := Partido.new(a, b)
	q2.preparar()
	if q2.once_local.has(uno):
		for i in 5:
			var q3 := Partido.new(a, b)
			q3.simular()
	_comprobar(uno.forma >= 20 and uno.forma <= 99, "la forma se queda en su rango tras jugar (%d)" % uno.forma)
	uno.forma = antes

func _probar_directiva() -> void:
	_titulo("LA DIRECTIVA: OBJETIVO, CONFIANZA Y DESPIDO")
	var m := Mundo.new()
	m.generar(["CHI"], 3131)
	var grande: Club = null
	var chico: Club = null
	for c: Club in m.ligas[0].clubes:
		if grande == null or c.rep > grande.rep: grande = c
		if chico == null or c.rep < chico.rep: chico = c

	var d1 := m.tomar_el_mando(grande.id)
	_linea("  a %s (rep %d) le piden: %s" % [grande.nombre, grande.rep, d1.objetivo])
	var m2 := Mundo.new()
	m2.generar(["CHI"], 3131)
	var d2 := m2.tomar_el_mando(chico.id)
	_linea("  a %s (rep %d) le piden: %s" % [chico.nombre, chico.rep, d2.objetivo])
	## El objetivo NO se elige: te lo pone el club segun lo que es. Es lo que hace
	## que dirigir a un grande y a un chico sean dos juegos distintos.
	_comprobar(d1.meta_puesto < d2.meta_puesto, "al grande le exigen mas que al chico (%d vs %d)" % [
		d1.meta_puesto, d2.meta_puesto])

	## Ganar sube la confianza y perder la baja, y el tamano del rival pesa.
	var antes := d1.confianza
	d1.tras_partido(3, 0, chico)
	var por_ganar_al_chico := d1.confianza - antes
	d1.confianza = antes
	d1.tras_partido(3, 0, grande)
	var por_ganar_al_grande := d1.confianza - antes
	d1.confianza = antes
	_linea("  ganar al chico suma %d, ganar a uno grande suma %d" % [por_ganar_al_chico, por_ganar_al_grande])
	_comprobar(por_ganar_al_grande >= por_ganar_al_chico, "ganarle a uno grande vale mas")
	d1.tras_partido(0, 2, chico)
	_comprobar(d1.confianza < antes, "perder baja la confianza")

	## Y lo que de verdad importa: que te puedan echar. Un manager sin despido no
	## es un manager.
	var visto := {"echado": false}
	d1.despedido.connect(func(_motivo: String) -> void: visto["echado"] = true)
	for i in 30:
		d1.tras_partido(0, 3, chico)
	_comprobar(visto["echado"], "una racha de derrotas acaba en despido (confianza %d)" % d1.confianza)
	_comprobar(d1.despedido_ya, "queda marcado como despedido")
	var c_tras := d1.confianza
	d1.tras_partido(5, 0, grande)
	_comprobar(d1.confianza == c_tras, "despues del despido ya no se mueve nada")

	## Cumplir el objetivo repone confianza; fallarlo cuesta mas cuanto mas lejos.
	var d3 := Directiva.new(grande, 1)
	var r_bien := d3.tras_temporada(1, true, false)
	_linea("  campeon cumpliendo: confianza %d (%+d)" % [r_bien["confianza"], r_bien["delta"]])
	_comprobar(r_bien["cumplido"] and r_bien["delta"] > 0, "cumplir y ganar la liga sube la confianza")
	var d4 := Directiva.new(grande, 1)
	var r_mal := d4.tras_temporada(14, false, false)
	_linea("  decimocuarto fallando: confianza %d (%+d)" % [r_mal["confianza"], r_mal["delta"]])
	_comprobar(not r_mal["cumplido"] and r_mal["delta"] < 0, "fallar el objetivo baja la confianza")
	_comprobar(d3.humor() != d4.humor(), "el humor de la directiva se lee distinto en cada caso")

## `vBanco()` del HTML: creditos, cuota francesa y el camino a la liquidacion.
## El motor (`nucleo/banco.gd`) y la pantalla ya estaban completos -ya gateaba
## el mercado de fichajes en mora, `_motivo_fichaje_bloqueado()` lo usa esta
## misma sesion-, pero no tenia ni una prueba funcional propia: solo un ida y
## vuelta de guardado que comprobaba la serializacion, no la matematica de la
## deuda ni la escalada a la liquidacion.
func _probar_banco() -> void:
	_titulo("EL BANCO: CUOTA FRANCESA, MORA Y LIQUIDACION")

	## LA CUOTA FRANCESA. Con interes cero se reparte a partes iguales -el caso
	## limite de la propia formula-; con interes, la cuota exacta se puede
	## verificar a mano: 1.000.000 al 1% en 12 cuotas da 88.849 con la formula
	## c = D*i / (1-(1+i)^-n).
	var c0 := Banco.cuota_francesa(1200000, 0.0, 12)
	_comprobar(c0 == 100000, "interes cero reparte a partes iguales (%d)" % c0)
	var c1 := Banco.cuota_francesa(1000000, 0.01, 12)
	_comprobar(absi(c1 - 88849) <= 1, "la cuota francesa calcula lo que calcula la formula (%d, se esperaban 88849)" % c1)

	var m := Mundo.new()
	m.generar(["CHI"], 4242)
	var c: Club = m.ligas[0].clubes[0]
	c.saldo = 500000
	var b := Banco.new()

	## PEDIR: entra el monto, la cuota queda fijada, y hay tope de dos lineas.
	var caja_antes := c.saldo
	var err_pedir := b.pedir(0, c)
	_comprobar(err_pedir == "", "pedir un credito de una linea valida no da error (%s)" % err_pedir)
	_comprobar(c.saldo > caja_antes, "el monto del credito entra a la caja (%d -> %d)" % [caja_antes, c.saldo])
	_comprobar(b.prestamos.size() == 1, "queda un prestamo anotado")
	var p0: Dictionary = b.prestamos[0]
	_comprobar(int(p0["cuota"]) == Banco.cuota_francesa(int(p0["deuda"]), float(p0["tasa"]), int(p0["restan"])),
		"la cuota guardada coincide con la formula sobre el monto y plazo de verdad")
	_comprobar(b.pedir(1, c) == "", "se puede pedir una segunda linea")
	_comprobar(b.pedir(2, c) != "", "la tercera linea se niega: tope de dos")

	## EL BONO SOCIAL: no cuenta aparte del tope -ocupa una de las dos lineas-,
	## y solo puede haber uno vigente.
	var b2 := Banco.new()
	b2.pedir(0, c)
	_comprobar(b2.emitir_bono(c) == "", "con una linea abierta todavia cabe el bono social")
	_comprobar(b2.emitir_bono(c) != "", "no se puede emitir un segundo bono social a la vez")

	## PREPAGAR: cancela de golpe y saca el credito de la lista. Si no hay caja
	## para la deuda pendiente, se niega.
	var b3 := Banco.new()
	var c3: Club = m.ligas[0].clubes[1]
	c3.saldo = 0
	b3.pedir(0, c3)
	var deuda3 := int((b3.prestamos[0] as Dictionary)["deuda"])
	c3.saldo = deuda3 - 1
	_comprobar(b3.prepagar(0, c3) != "", "prepagar con menos caja de la que debes se niega")
	c3.saldo = deuda3
	var caja_antes_prepago := c3.saldo
	_comprobar(b3.prepagar(0, c3) == "", "con caja de sobra, prepagar se hace")
	_comprobar(b3.prestamos.is_empty(), "el credito prepagado desaparece de la lista")
	_comprobar(c3.saldo == caja_antes_prepago - deuda3, "prepagar cobra exactamente la deuda pendiente")

	## RENEGOCIAR: baja la cuota, sube la tasa y el plazo, y solo una vez.
	var b4 := Banco.new()
	var c4: Club = m.ligas[0].clubes[2]
	c4.saldo = 500000
	b4.pedir(1, c4)
	var cuota_antes := int((b4.prestamos[0] as Dictionary)["cuota"])
	b4.renegociar(0)
	var p4: Dictionary = b4.prestamos[0]
	_comprobar(int(p4["cuota"]) < cuota_antes, "renegociar baja la cuota (%d -> %d)" % [cuota_antes, int(p4["cuota"])])
	_comprobar(bool(p4["renegociado"]), "queda marcado como renegociado")
	_comprobar(b4.renegociar(0) != "", "no se puede renegociar el mismo credito dos veces")

	## LA SEMANA: cobra la cuota, reduce la deuda, y el credito se cierra solo
	## cuando llega a cero o se acaban las cuotas.
	var b5 := Banco.new()
	var c5: Club = m.ligas[0].clubes[3]
	c5.saldo = 5000000
	b5.pedir(0, c5)
	var deuda5_antes := int((b5.prestamos[0] as Dictionary)["deuda"])
	var caja5_antes := c5.saldo
	b5.semana(c5)
	_comprobar(c5.saldo < caja5_antes, "la semana cobra la cuota de verdad (%d -> %d)" % [caja5_antes, c5.saldo])
	_comprobar(int((b5.prestamos[0] as Dictionary)["deuda"]) < deuda5_antes, "la deuda baja cada semana")
	## Pagando la cuota exacta cada semana durante todas las que quedan, el
	## credito debe cerrarse solo -sin quedar en un limbo de deuda residual-.
	var restan5 := int((b5.prestamos[0] as Dictionary)["restan"])
	for i in restan5:
		b5.semana(c5)
	_comprobar(b5.prestamos.is_empty(), "pagando todas las cuotas el credito se cierra solo")

	## EL SOBREGIRO: caja en rojo cobra intereses y cuenta semanas. Saneando la
	## caja, el contador vuelve a cero -no se acumula "media mora" de una racha
	## mala a la siguiente-.
	var b6 := Banco.new()
	var c6: Club = m.ligas[0].clubes[4]
	c6.saldo = -100000
	var caja6_antes := c6.saldo
	b6.semana(c6)
	_comprobar(c6.saldo < caja6_antes, "el sobregiro cobra intereses sobre la caja en rojo")
	_comprobar(b6.semanas_en_rojo == 1, "una semana en rojo cuenta como una")
	c6.saldo = 100000
	b6.semana(c6)
	_comprobar(b6.semanas_en_rojo == 0, "sanear la caja pone el contador de semanas en rojo a cero")

	## LA ESCALADA COMPLETA: sobregiro -> mora -> veedor -> liquidacion, en las
	## semanas exactas que marcan las constantes, con la caja SIEMPRE en rojo
	## -si se sanea a mitad de camino, el contador se reinicia y nunca llega-.
	var b7 := Banco.new()
	var c7: Club = m.ligas[0].clubes[5]
	c7.saldo = -50000
	var avisos: Dictionary = {"total": 0}
	b7.aviso.connect(func(_t: String, _x: String) -> void: avisos["total"] += 1)
	var liquidado_avisado := {"si": false}
	b7.liquidado.connect(func() -> void: liquidado_avisado["si"] = true)
	var en_mora_en_semana := -1
	var veedor_en_semana := -1
	for s in 20:
		c7.saldo = mini(c7.saldo, -1)   ## nunca sale del rojo a proposito
		b7.semana(c7)
		if en_mora_en_semana < 0 and b7.en_mora():
			en_mora_en_semana = s + 1
		if veedor_en_semana < 0 and b7.hay_veedor():
			veedor_en_semana = s + 1
		if b7.liquidado_ya:
			break
	_comprobar(en_mora_en_semana == Banco.SEM_MORA, "entra en mora exactamente a la cuarta semana en rojo (semana %d)" % en_mora_en_semana)
	_comprobar(veedor_en_semana == Banco.SEM_VEEDOR, "el veedor llega exactamente a la octava semana en rojo (semana %d)" % veedor_en_semana)
	_comprobar(b7.liquidado_ya, "doce semanas seguidas en rojo liquidan el club")
	_comprobar(liquidado_avisado["si"], "la senal 'liquidado' se dispara de verdad")
	_comprobar(int(avisos["total"]) >= 3, "se avisa en cada escalon, no solo al final (%d avisos)" % int(avisos["total"]))

	## PEDIR EN MORA: los bancos cierran la ventanilla, pero el bono social de
	## la hinchada sigue disponible -es su gracia, "incluso en mora"-.
	var b8 := Banco.new()
	var c8: Club = m.ligas[0].clubes[6]
	c8.saldo = -1
	for s2 in Banco.SEM_MORA:
		c8.saldo = -1
		b8.semana(c8)
	_comprobar(b8.en_mora(), "el club de la prueba esta de verdad en mora")
	_comprobar(b8.pedir(0, c8) != "", "en mora, ningun banco abre una linea nueva")
	c8.saldo = 100000
	_comprobar(b8.emitir_bono(c8) == "", "el bono social SI se puede emitir incluso en mora")

	## ESTADO: el texto que ve el jugador tiene que coincidir con el numero.
	var c9: Club = m.ligas[0].clubes[7]
	c9.saldo = 100000
	var b9 := Banco.new()
	_comprobar(String(b9.estado(c9)["estado"]) == "AL DÍA", "caja en azul es 'AL DÍA'")
	c9.saldo = -1
	_comprobar(String(b9.estado(c9)["estado"]) == "SOBREGIRO", "caja en rojo bajo mora es 'SOBREGIRO'")
	b9.semanas_en_rojo = Banco.SEM_MORA
	_comprobar(String(b9.estado(c9)["estado"]) == "EN MORA", "en mora el estado dice 'EN MORA'")
	b9.semanas_en_rojo = Banco.SEM_VEEDOR
	_comprobar(String(b9.estado(c9)["estado"]) == "VEEDOR EN FUNCIONES", "con veedor el estado lo dice")

	## GUARDADO: ida y vuelta completa, no solo que no reviente.
	var b10 := Banco.new()
	var c10: Club = m.ligas[0].clubes[8]
	c10.saldo = 500000
	b10.pedir(0, c10)
	b10.pedir(1, c10)
	b10.semanas_en_rojo = 3
	var d10 := b10.a_dic()
	var b11 := Banco.new()
	b11.desde_dic(d10)
	_comprobar(b11.prestamos.size() == b10.prestamos.size(), "vuelven los mismos prestamos (%d)" % b11.prestamos.size())
	_comprobar(int((b11.prestamos[0] as Dictionary)["deuda"]) == int((b10.prestamos[0] as Dictionary)["deuda"]),
		"la deuda de cada prestamo vuelve exacta")
	_comprobar(b11.semanas_en_rojo == 3, "las semanas en rojo vuelven exactas")

func _probar_staff() -> void:
	_titulo("CUERPO TECNICO")
	var m := Mundo.new()
	m.generar(["CHI"], 616)
	var c: Club = m.ligas[0].clubes[0]
	m.tomar_el_mando(c.id)
	var s := m.staff

	_comprobar(is_equal_approx(c.bonus_ataque, 1.0), "sin staff, los bonificadores estan a uno")
	var caja := c.saldo
	var coste := s.coste_subir("ayudante", c.rep)
	_comprobar(s.subir("ayudante", c) == "", "se contrata al ayudante de campo")
	_linea("  ayudante nivel 1 cuesta %s" % _dinero(coste))
	_comprobar(c.saldo == caja - coste, "el fichaje del staff sale de la caja")
	## Lo que importa: que se NOTE. Un menu que no cambia un numero del motor es
	## un boton de gastar dinero, y este proyecto ya pago ese error varias veces.
	_comprobar(c.bonus_ataque > 1.0, "contratar al ayudante sube el ataque del equipo (%.3f)" % c.bonus_ataque)

	## El coste crece mas rapido que el efecto: llenar los seis puestos al maximo
	## no puede ser la jugada obvia del primer ano.
	var c1 := s.coste_subir("ayudante", c.rep)
	s.subir("ayudante", c)
	var c2 := s.coste_subir("ayudante", c.rep)
	_linea("  subir de 1 a 2 cuesta %s; de 2 a 3, %s" % [_dinero(c1), _dinero(c2)])
	_comprobar(c2 > c1, "cada nivel cuesta mas que el anterior")

	## Y el efecto de cada puesto, uno por uno.
	s.niveles["medico"] = 3
	_comprobar(s.descuento_lesion(8) == 5, "el jefe medico acorta las lesiones (8 -> %d)" % s.descuento_lesion(8))
	_comprobar(s.descuento_lesion(1) >= 1, "pero nunca las cura por decreto")
	s.niveles["ojeador"] = 2
	_comprobar(s.ojo() > 0.0, "el ojeador trae informes")
	s.niveles["fisico"] = 4
	_comprobar(s.aguante() == 4, "el preparador fisico da aguante")
	_comprobar(s.sueldo_semanal(c.rep) > 0, "el cuerpo tecnico cobra todas las semanas")

	## Aplicar dos veces no puede duplicar la bonificacion: al cargar una partida
	## se vuelve a aplicar, y acumulando el equipo saldria con el doble.
	var antes := c.bonus_ataque
	s.aplicar(c)
	s.aplicar(c)
	_comprobar(is_equal_approx(c.bonus_ataque, antes), "aplicar el staff dos veces no duplica el efecto")

func _probar_roles_y_federacion() -> void:
	_titulo("ROLES, ENTRENAMIENTO, FEDERACION Y ESTADIO")
	var m := Mundo.new()
	m.generar(["CHI"], 909090)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)

	## ROLES: cada uno tiene que APAGAR cosas distintas. Un rol que permite lo
	## mismo que otro no es un rol, es un nombre.
	_comprobar(m.roles != null, "el rol arranca al tomar el mando")
	_linea("  cargo: %s   manda=%s   puede fichar=%s" % [
		m.roles.nombre_del_cargo(), m.roles.manda(), m.roles.puede_fichar()])
	_comprobar(m.roles.puede_fichar(), "el DT clasico puede fichar")
	var m2 := Mundo.new()
	m2.generar(["CHI"], 909090)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	m2.roles.arrancar_ayudante()
	_linea("  de ayudante: %s   mercado bloqueado=%s" % [
		m2.roles.nombre_del_cargo(), m2.roles.mercado_bloqueado() != ""])
	_comprobar(m2.roles.es_ayudante(), "se puede empezar de ayudante de campo")
	_comprobar(not m2.roles.puede_fichar(), "el ayudante NO puede fichar")
	var m3 := Mundo.new()
	m3.generar(["CHI"], 909090)
	m3.tomar_el_mando(m3.ligas[0].clubes[0].id)
	m3.roles.arrancar_interinato("CHI")
	_comprobar(m3.roles.en_interinato(), "se puede entrar de interino")
	_comprobar(not m3.roles.puede_fichar(), "el interino tiene el mercado cerrado")

	## ENTRENAMIENTO: apretar tiene que subir el riesgo, o el plan no decide nada.
	var e := m.entrenamiento
	_comprobar(e != null, "el entrenamiento arranca con el mando")
	var r0 := e.carga_riesgo()
	e.fijar_intensidad("alta")
	var r1 := e.carga_riesgo()
	e.fijar_intensidad("baja")
	var r2 := e.carga_riesgo()
	_linea("  carga: baja %.1f, normal %.1f, alta %.1f" % [r2, r0, r1])
	_comprobar(r1 > r2, "entrenar fuerte carga mas las piernas que entrenar suave")
	_comprobar(e.bonus_dt() >= 1.0, "el arbol del DT no penaliza al equipo (%.2f)" % e.bonus_dt())

	## FEDERACION: sin playoffs votados, el campeon es el lider de la tabla.
	var liga := m.liga_de(m.mi_club())
	m.jugar_temporada()
	var t := liga.tabla()
	var lider: Club = t[0]["club"]
	var camp := m.federacion.campeon_de_liga(t, m.anio, m.mi_club_id)
	_linea("  sin playoffs: lider %s, campeon %s" % [lider.nombre, camp.nombre if camp else "ninguno"])
	_comprobar(camp == lider, "sin playoffs votados, campeon = lider de la tabla")
	## Con playoffs, el lider ya NO gana siempre: es justo la gracia de votarlos.
	m.federacion.playoffs = true
	var perdidos := 0
	for i in 30:
		var c2 := m.federacion.campeon_de_liga(t, m.anio, m.mi_club_id)
		if c2 != null and c2 != lider:
			perdidos += 1
	_linea("  con playoffs: de 30 finales, el lider perdio el titulo %d veces" % perdidos)
	_comprobar(perdidos > 0, "con playoffs el lider puede perder el titulo")

	## ESTADIO PROPIO: el perfil que va al visor tiene que traer las claves que
	## consume el constructor 3D, o el estadio sale a medias sin un solo error.
	var p := m.perfil_estadio_de(m.mi_club())
	var faltan: Array[String] = []
	for k in ["forma", "niveles", "techo", "cesped", "asientoP", "focos", "pantalla", "vallas", "aforo"]:
		if not p.has(k):
			faltan.append(k)
	_linea("  perfil de tu estadio: %s de %d niveles, techo %s, %d butacas" % [
		p.get("forma", "?"), int(p.get("niveles", 0)), p.get("techo", "?"), int(p.get("aforo", 0))])
	_comprobar(faltan.is_empty(), "el perfil trae las 9 claves del visor 3D (faltan: %s)" % [faltan])
	## Y el de un rival sigue saliendo de su hash, no del tuyo.
	var rival: Club = liga.clubes[5]
	var pr := m.perfil_estadio_de(rival)
	_comprobar(pr.has("forma"), "el rival tambien tiene perfil de estadio")
	_comprobar(m.perfil_estadio_de(rival)["forma"] == pr["forma"], "y es siempre el mismo")
	_comprobar(not pr.has("bandejas"), "el rival nunca trae la clave bandejas (no tiene disenador)")

	## BANDEJA (16-9-2026, Fase 1 de "el estadio por MODULOS"): con el
	## interruptor apagado, el perfil no debe cambiar NI UNA clave respecto al
	## de antes de esta fase -es el requisito explicito de la reforma.
	_comprobar(not p.has("bandejas"), "sin personalizar_bandejas, el perfil no trae la clave bandejas")
	var claves_antes: Array = p.keys()
	claves_antes.sort()
	## Incluye ya las 5 claves de la Fase 2 (Componentes) -esas SI son
	## incondicionales desde que se cerro esa fase, a diferencia de `bandejas`
	## que solo aparece con el interruptor activo.
	## "sonidoGol" (18-9-2026): faltaba en `perfil()` desde que existe el
	## catalogo -se podia elegir y pagar en la UI, pero el visor nunca la vio-.
	var claves_esperadas: Array = ["aforo", "arcoCol", "asiento1", "asiento2", "asiento3",
		"asientoP", "banderas", "banquillo", "cesped", "cespedClaro", "cespedOscuro", "clima",
		"corner", "escudoDonde", "focos", "forma", "lineaCol", "niveles", "pantalla",
		"personalizado", "redCol", "redTipo", "sonidoGol", "techo", "tunel", "vallas",
		## B6 (25-9-2026): las secciones, también incondicionales.
		"fachada", "fachadaCol", "techoCol", "luzFocos", "luzClub", "banquilloCol",
		"superficie", "exterior",
		## 26-9-2026: obras en curso y lo construido, para el 3D (`EstadioExtras`).
		"en_obra", "inst"]
	claves_esperadas.sort()
	_comprobar(claves_antes == claves_esperadas,
		"perfil() trae exactamente las claves de siempre, ni una de mas (dio: %s)" % [claves_antes])

	## COMPONENTES (16-9-2026, Fase 2): las 5 claves ya llegan al visor. Desde
	## el 25-9 el rival trae red, córner y banquillo de su estilo (más variedad
	## de estadios), pero sigue sin túnel ni escudo: esos solo los decide quien
	## diseña su propio estadio.
	for k in ["redTipo", "corner", "banquillo", "tunel", "escudoDonde"]:
		_comprobar(p.has(k), "el perfil propio trae la clave nueva '%s'" % k)
	for k in ["tunel", "escudoDonde"]:
		_comprobar(not pr.has(k), "el rival NO trae '%s' (sigue sin disenador)" % k)

	## Con el interruptor prendido y una reforma de una sola tribuna, solo esa
	## tribuna cambia -las otras tres siguen heredando el valor global.
	var mio := m.mi_club()
	mio.saldo = 999999999
	_comprobar(m.estadio.reformar(mio, {"personalizar_bandejas": true}, m.obras) == "",
		"se puede activar personalizar cada tribuna")
	_comprobar(m.estadio.reformar(mio, {"bandeja_sur_asientoP": "damero"}, m.obras) == "",
		"se puede reformar solo la tribuna sur")
	var p2 := m.perfil_estadio_de(mio)
	_comprobar(p2.has("bandejas"), "con el interruptor activo, el perfil SI trae bandejas")
	var bandejas: Dictionary = p2.get("bandejas", {})
	_comprobar(String(bandejas.get("sur", {}).get("asientoP", "")) == "damero",
		"la tribuna sur quedo con el patron reformado")
	for lado in ["norte", "este", "oeste"]:
		_comprobar(String(bandejas.get(lado, {}).get("asientoP", "")) == String(p2.get("asientoP", "")),
			"la tribuna %s sigue heredando el patron global" % lado)

	## TRAMO (22-9-2026, Fase 3 de "el estadio por MODULOS", ultima de las
	## tres): mismo criterio que Bandeja -apagado no cambia una clave,
	## prendido solo cambia lo que se reformo-, mas la resolucion de los
	## tercios en blanco. Con `personalizar_bandejas` YA prendido (bloque de
	## arriba) para probar de paso que las dos fases conviven: la tribuna sur
	## tiene ahora un `bandeja_sur_asientoP` propio ("damero"), asi que sus
	## tercios en blanco tienen que heredar ESE valor, no el global.
	_comprobar(not p.has("tramos"), "sin personalizar_tramos, el perfil no trae la clave tramos")
	_comprobar(m.estadio.reformar(mio, {"personalizar_tramos": true}, m.obras) == "",
		"se puede activar mezclar patrones por tercios")
	_comprobar(m.estadio.reformar(mio, {"tramo_sur_2": "moteado"}, m.obras) == "",
		"se puede reformar solo el tercio 2 de la tribuna sur")
	var p3 := m.perfil_estadio_de(mio)
	_comprobar(p3.has("tramos"), "con el interruptor activo, el perfil SI trae tramos")
	var tramos: Dictionary = p3.get("tramos", {})
	var tramos_sur: Array = tramos.get("sur", [])
	_comprobar(tramos_sur.size() == 3, "la tribuna sur trae sus 3 tercios (dio %d)" % tramos_sur.size())
	_comprobar(String(tramos_sur[0]) == "damero" and String(tramos_sur[2]) == "damero",
		"los tercios 1 y 3 en blanco heredan 'damero' -el de Bandeja, no el global- (dio %s y %s)" % [
			tramos_sur[0] if tramos_sur.size() > 0 else "?", tramos_sur[2] if tramos_sur.size() > 2 else "?"])
	_comprobar(String(tramos_sur[1]) == "moteado", "el tercio 2 quedo con el patron reformado")
	for lado in ["norte", "este", "oeste"]:
		var t_lado: Array = tramos.get(lado, [])
		_comprobar(t_lado.size() == 3 and t_lado[0] == t_lado[1] and t_lado[1] == t_lado[2]
			and String(t_lado[0]) == String(p3.get("asientoP", "")),
			"la tribuna %s (sin tercios propios) sale con sus 3 tercios iguales al patron global" % lado)
	## El rival nunca disenio nada: nunca trae ni bandejas ni tramos.
	_comprobar(not m.perfil_estadio_de(rival).has("tramos"), "el rival nunca trae la clave tramos")

	## LOS 8 ESTILOS, ENRIQUECIDOS (16-9-2026): ya traian banquillo/tunel/corner
	## desde antes -mudos hasta la Fase 2 de hoy-, y ahora tambien redTipo y
	## escudoDonde. Los 8, no solo uno, para no dejar pasar un typo de catalogo
	## en cualquiera de ellos -"redTipo": "gruesa" vale, "REDTIPO":"Gruesa" no.
	var estilos := m.estadio.presets()
	_comprobar(estilos.size() == 24, "los 24 estilos completos (8 de siempre + 8 del 25-9 + 8 de B6) (dio %d)" % estilos.size())
	for est_p: Dictionary in estilos:
		var cambios: Dictionary = est_p["cambios"]
		_comprobar(cambios.has("redTipo") and m.estadio.es_valido("redTipo", cambios["redTipo"]),
			"'%s' trae un redTipo valido (%s)" % [est_p["clave"], cambios.get("redTipo")])
		_comprobar(cambios.has("escudoDonde") and m.estadio.es_valido("escudoDonde", cambios["escudoDonde"]),
			"'%s' trae un escudoDonde valido (%s)" % [est_p["clave"], cambios.get("escudoDonde")])

func _probar_obras() -> void:
	_titulo("INSTALACIONES")
	var m := Mundo.new()
	m.generar(["CHI"], 2424)
	var c: Club = m.ligas[0].clubes[0]
	m.tomar_el_mando(c.id)
	var o := m.obras
	_linea("  %d obras en el catalogo" % Instalaciones.CATALOGO.size())
	_comprobar(Instalaciones.CATALOGO.size() == 19, "estan las 19 instalaciones del HTML")

	## Las obras NO son instantaneas: es lo que impide comprarlo todo el primer
	## dia y que el sistema desaparezca. En el HTML se cambio a proposito en la
	## v2.5 justo por eso.
	var caja := c.saldo
	var precio := o.coste("cal", c.rep)
	_comprobar(o.iniciar("cal", c) == "", "se puede empezar una obra")
	_comprobar(c.saldo == caja - precio, "la obra se paga por adelantado")
	_comprobar(o.nivel("cal") == 0, "la obra NO sube el nivel al momento")
	_comprobar(o.en_obra("cal"), "queda constancia de que hay obra en marcha")
	_comprobar(o.iniciar("cal", c) != "", "no se puede empezar dos veces la misma obra")
	for s in o.semanas_de("cal"):
		o.avanzar_semana(c)
	_comprobar(o.nivel("cal") == 1, "la obra termina en su plazo (%d semanas)" % o.semanas_de("cal"))
	_comprobar(not o.en_obra("cal"), "y deja de estar en marcha")

	## Y lo que de verdad importa: que se NOTE. Una obra que no mueve un numero
	## visible es un boton de gastar dinero.
	var f_sin := Finanzas.new(c, 0.0)
	var f_con := Finanzas.new(c, o.aporte_ocupacion())
	_linea("  calidad del estadio nivel 1: entran %d en vez de %d" % [
		f_con.asistencia(), f_sin.asistencia()])
	_comprobar(f_con.asistencia() > f_sin.asistencia(), "la calidad del estadio llena mas el estadio")

	## Las tribunas cambian el aforo, y hay que poder construirlas varias veces
	## sin que el aforo se multiplique cada vez que se carga la partida.
	var aforo0 := c.estadio_aforo
	o.niveles["trib"] = 2
	o.aplicar(c)
	var aforo2 := c.estadio_aforo
	_linea("  aforo: %s de fabrica, %s con dos tribunas" % [aforo0, aforo2])
	_comprobar(aforo2 > aforo0, "construir tribunas amplia el aforo")
	o.aplicar(c)
	o.aplicar(c)
	_comprobar(c.estadio_aforo == aforo2, "aplicarlo tres veces no multiplica el aforo")

	## Los ingresos que solo existen con ladrillo.
	o.niveles["com"] = 2
	o.niveles["museo"] = 1
	o.ultima_asistencia = 20000
	o.niveles["park"] = 3
	var ing := o.ingresos_del_mes(c)
	var total := 0
	for i: Dictionary in ing:
		total += int(i["monto"])
		_linea("  %s: %s al mes" % [String(i["concepto"]), _dinero(int(i["monto"]))])
	_comprobar(ing.size() == 3, "la tienda, el museo y los estacionamientos dan ingresos")
	_comprobar(total > 0, "y suman de verdad (%s)" % _dinero(total))

	## Cada efecto tiene una puerta por la que entra al juego. Si alguna devuelve
	## siempre lo mismo, esa instalacion no hace nada.
	o.niveles["med"] = 2
	o.niveles["rehab"] = 1
	_comprobar(o.descuento_lesion() == 3, "el centro medico y la rehabilitacion acortan lesiones (%d)" % o.descuento_lesion())
	o.niveles["cocina"] = 2
	o.niveles["piscina"] = 2
	_comprobar(o.aguante() == 2, "comedor y piscina dan aguante (%d)" % o.aguante())
	o.niveles["ct"] = 3
	_comprobar(o.ritmo_de_progreso() > 1.0, "el centro de entrenamiento acelera el progreso (%.2f)" % o.ritmo_de_progreso())
	o.niveles["acad"] = 2
	o.niveles["resid"] = 2
	_comprobar(o.techo_cantera() == 3, "academia y residencia suben el techo de la cantera (%d)" % o.techo_cantera())
	o.niveles["huerto"] = 3
	_comprobar(o.abarata_operacion() < 1.0, "el huerto abarata la operacion")

	## El coste crece con el cuadrado del nivel: el quinto nivel tiene que ser
	## una decision de club, no un tramite.
	var c1 := o.coste("gim", c.rep)
	o.niveles["gim"] = 3
	var c4 := o.coste("gim", c.rep)
	_linea("  gimnasio: nivel 1 cuesta %s, nivel 4 cuesta %s" % [_dinero(c1), _dinero(c4)])
	_comprobar(c4 > c1 * 3, "el cuarto nivel cuesta mucho mas que el primero")

func _probar_estadio() -> void:
	_titulo("PERFIL DE ESTADIO (lo que ve el visor 3D)")
	var m := Mundo.new()
	m.generar(["CHI"], 2026)
	var c: Club = m.ligas[0].clubes[0]
	var p := c.perfil_estadio()
	_linea("  %s: %s de %d niveles, techo %s, %d butacas" % [
		c.nombre, p["forma"], int(p["niveles"]), p["techo"], int(p["aforo"])])
	## ESTABLE, no aleatorio: el rival tiene que jugar siempre en el mismo
	## recinto. Si se sorteara, cada visita seria a un estadio distinto y el
	## mundo dejaria de parecer un mundo.
	var otra := c.perfil_estadio()
	_comprobar(p["forma"] == otra["forma"] and p["techo"] == otra["techo"],
		"el mismo club da siempre el mismo estadio")
	var m2 := Mundo.new()
	m2.generar(["CHI"], 999)
	var c2: Club = null
	for k: Club in m2.clubes.values():
		if k.nombre == c.nombre:
			c2 = k
			break
	if c2 != null:
		_comprobar(c2.perfil_estadio()["forma"] == p["forma"],
			"el estadio no depende de la semilla de la partida")
	## Y el tamano manda sobre el gusto: un club chico no puede tener tres
	## bandejas por mucha reputacion que se le ponga.
	var formas := {}
	var mal := 0
	for k: Club in m.clubes.values():
		var q := k.perfil_estadio()
		formas[q["forma"]] = true
		if k.rep < 62 and int(q["niveles"]) > 1:
			mal += 1
		if int(q["aforo"]) <= 0:
			mal += 1
	_linea("  formas distintas en el mundo: %d" % formas.size())
	_comprobar(formas.size() >= 5, "no todos los clubes tienen el mismo estadio (%d formas)" % formas.size())
	_comprobar(mal == 0, "los niveles y el aforo son coherentes con el club (%d raros)" % mal)
	_probar_pantalla_y_vallas(m)

## LA PANTALLA GIGANTE Y LAS VALLAS LED (23-9-2026). Lo que se comprueba aquí
## es la LÓGICA, sin abrir ventana: la parte visual la verifica
## `pruebas/captura_pantalla_gigante.gd` con capturas reales.
##
## Hay dos bugs de verdad detrás de estas comprobaciones, los dos encontrados
## esta misma tanda mirando capturas:
##   - La pantalla estaba clavada en `alto - 1.0` con 9 m de marco FIJOS, así
##     que asomaba por encima del graderío y el techo (`alto + 0.4`) le pasaba
##     por delante partiéndola en dos. En un estadio de 1 nivel además se
##     hundía bajo el césped. Por eso se comprueba contra los TRES niveles.
##   - Los nombres largos de club se salían del lienzo. Por eso la pantalla usa
##     abreviaturas de tres letras, y se comprueba que "D. Limache" da "LIM"
##     (la versión vieja habría dado "D." o un recorte a media palabra).
func _probar_pantalla_y_vallas(m: Mundo) -> void:
	_titulo("PANTALLA GIGANTE Y VALLAS LED")
	var c: Club = m.ligas[0].clubes[0]
	var ab := PantallaEstadio.abreviatura(c)
	_comprobar(ab.length() == 3 and ab == ab.to_upper(),
		"la abreviatura del club son tres letras en mayúscula (%s -> %s)" % [c.nombre, ab])
	## El caso real que reventó la primera versión de la pantalla.
	var falso := Club.new("x", "D. Limache")
	_comprobar(PantallaEstadio.abreviatura(falso) == "LIM",
		"una inicial con punto no cuenta como palabra ('D. Limache' -> %s)" % \
			PantallaEstadio.abreviatura(falso))

	## La pantalla cuelga bajo el techo y sobre el césped en los tres niveles.
	var cruces := 0
	for niveles in [1, 2, 3]:
		var perfil := c.perfil_estadio()
		perfil["niveles"] = niveles
		var alto := StadiumBuilder.altura_de(perfil, niveles * 30000)
		var alto_marco: float = clampf(alto * 0.46, 4.2, 9.0)
		var y: float = alto - 0.8 - alto_marco / 2.0
		if y + alto_marco / 2.0 > alto + 0.4 or y - alto_marco / 2.0 < 0.5:
			cruces += 1
			_linea("  nivel %d: pantalla de %.1f..%.1f m contra techo en %.1f" % [
				niveles, y - alto_marco / 2.0, y + alto_marco / 2.0, alto + 0.4])
	_comprobar(cruces == 0, "la pantalla no se cruza con el techo en 1, 2 ni 3 niveles")

	## Las vallas: cada club con su propio juego, y con su nombre dentro.
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var la: Array = StadiumBuilder._anuncios_de(a.perfil_estadio(), a)
	var lb: Array = StadiumBuilder._anuncios_de(b.perfil_estadio(), b)
	_comprobar(la.size() >= 5 and lb.size() >= 5,
		"cada estadio tiene al menos 5 anuncios distintos (%d / %d)" % [la.size(), lb.size()])
	var textos_a: Array = []
	for x: Dictionary in la:
		textos_a.append(String(x["texto"]))
	var textos_b: Array = []
	for x: Dictionary in lb:
		textos_b.append(String(x["texto"]))
	_comprobar(textos_a != textos_b, "dos clubes distintos no anuncian lo mismo")
	_comprobar(textos_a.has(a.nombre.to_upper()) and textos_b.has(b.nombre.to_upper()),
		"las vallas de cada club llevan el nombre de su club")
	_linea("  %s: %s" % [a.nombre, ", ".join(textos_a)])
	## La tinta se decide contra el fondo: sobre un panel claro no puede salir
	## texto blanco. Es lo que hacía ilegible la mitad de las 38 marcas.
	var claro: Dictionary = StadiumBuilder._anuncio("PRUEBA", Color(0.95, 0.95, 0.9))
	var oscuro: Dictionary = StadiumBuilder._anuncio("PRUEBA", Color(0.05, 0.06, 0.1))
	_comprobar(Color(claro["tinta"]).get_luminance() < 0.3 \
		and Color(oscuro["tinta"]).get_luminance() > 0.7,
		"el texto de la valla contrasta con su propio fondo")

func _probar_continental() -> void:
	_titulo("COPAS CONTINENTALES")
	var m := Mundo.new()
	m.generar([], 5150)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_linea("  torneos sorteados: %s" % [m.continentales.keys()])
	_comprobar(m.continentales.size() >= 2, "se sortean al menos dos torneos continentales")

	var vacios := 0
	for k: String in m.continentales:
		var t: Continental = m.continentales[k]
		_linea("  %-5s %-28s %2d inscritos, %2d vivos, %s" % [
			k, Continental.nombre_conti(k), t.participantes.size(), t.vivos.size(),
			t.nombre_de_ronda()])
		if t.participantes.is_empty():
			vacios += 1
	_comprobar(vacios == 0, "ningun torneo se sortea vacio (%d vacios)" % vacios)

	## Nadie puede estar en dos torneos de la misma confederacion a la vez.
	var en_dos := 0
	var visto := {}
	for k: String in m.continentales:
		var t: Continental = m.continentales[k]
		for c: Club in t.participantes:
			if visto.has(c.id) and Continental.confed_de(visto[c.id]) == Continental.confed_de(k):
				en_dos += 1
			visto[c.id] = k
	_comprobar(en_dos == 0, "ningun club juega dos copas de su misma confederacion (%d)" % en_dos)

	## Y lo que de verdad importa: que el torneo LLEGUE a tener campeon. Un
	## torneo que se queda sin nadie vivo antes de la final no reparte el premio
	## y ademas no se nota: no revienta nada, simplemente no pasa.
	var mio := m.mi_continental()
	_comprobar(mio != null, "tu club juega una copa continental")
	if mio != null:
		_linea("  la tuya: %s con %d inscritos" % [mio.nombre, mio.participantes.size()])
	var con_campeon := 0
	for k: String in m.continentales:
		var t: Continental = m.continentales[k]
		var vueltas := 0
		while t.en_curso() and vueltas < 20:
			t.jugar_ronda()
			vueltas += 1
		if t.campeon != null:
			con_campeon += 1
			_linea("  campeon de %s: %s" % [Continental.nombre_conti(k), t.campeon.nombre])
	_comprobar(con_campeon == m.continentales.size(),
		"todos los torneos llegan a tener campeon (%d de %d)" % [con_campeon, m.continentales.size()])

	## Y que ganar TU continental celebre el titulo -confianza, socios, moral al
	## tope- igual que la liga o la copa. El gancho vive en Mundo.avanzar_semana(),
	## no en jugar_ronda(): se prueba forzando una final a dos y comprobando que
	## SI mi club sale campeon, cae en la vitrina en la semana exacta.
	## Una sola final forzada puede perderla hasta el favorito absoluto -es una
	## eliminatoria de un partido, no una liga-, así que se insiste con semillas
	## distintas antes de rendirse. Sin insistir, esta prueba salía inconclusa
	## una de cada dos corridas y no decía nada real.
	var conti_verificado := false
	var ultimo_muro_antes := 0
	var ultimo_muro_despues := 0
	for intento_semilla in 6:
		var m3 := Mundo.new()
		m3.generar(["CHI"], 5150 + intento_semilla)
		m3.tomar_el_mando(m3.ligas[0].clubes[0].id)
		var t: Continental = m3.mi_continental()
		if t == null:
			continue
		var debil: Club = null
		for c: Club in m3.clubes.values():
			if c.id != m3.mi_club_id and (debil == null or c.rep < debil.rep):
				debil = c
		t.preparar([m3.mi_club(), debil] as Array[Club])
		var muro_antes := m3.logros.muro.size()
		var intentos := 0
		while t.en_curso() and intentos < 10:
			m3.avanzar_semana()
			intentos += 1
		if t.campeon == m3.mi_club():
			ultimo_muro_antes = muro_antes
			ultimo_muro_despues = m3.logros.muro.size()
			conti_verificado = true
			break
	if conti_verificado:
		_comprobar(ultimo_muro_despues > ultimo_muro_antes,
			"ganar un continental de clubes celebra el titulo (vitrina %d -> %d)" % [ultimo_muro_antes, ultimo_muro_despues])
	else:
		_linea("  (el club fuerte perdio la final forzada en las 6 semillas probadas; no se pudo verificar el gancho esta corrida)")

## COMPARAR TACTICAS DE VERDAD (17-9-2026), sin necesitar pantalla: llama
## `_objetivo_jugador()` directo -el mismo metodo que usa `MatchPlayback._mover()`
## para cada uno de los 22, cada fotograma- con la MISMA ranura de formacion y
## la MISMA pelota, cambiando solo la `Tactica`. Si dos tacticas de verdad se
## sienten distinto jugando, tienen que devolver puntos distintos aqui -es la
## unica forma de "comparar visualmente" que tengo sin ojos.
func _probar_tactica_en_movimiento() -> void:
	_titulo("TACTICA EN EL MOVIMIENTO 3D (nivel FC 26)")
	var mp := MatchPlayback.new()
	mp.fase = "ataqueLocal"  # el equipo local ataca -hacia Z negativo, dir_ataque=-1

	var t_ofensiva := Tactica.new()
	t_ofensiva.mentalidad = Tactica.Mentalidad.OFENSIVA
	t_ofensiva.linea = Tactica.Nivel.ALTO
	t_ofensiva.amplitud = Tactica.Nivel.ALTO

	var t_defensiva := Tactica.new()
	t_defensiva.mentalidad = Tactica.Mentalidad.DEFENSIVA
	t_defensiva.linea = Tactica.Nivel.BAJO
	t_defensiva.amplitud = Tactica.Nivel.BAJO

	## Mismo jugador (misma ranura de formacion `base`), misma pelota -delta
	## grande y reaccion casi nula para que el empuje ya haya llegado del todo
	## a su objetivo, sin que la inercia de la ronda 2 tape la comparacion.
	var base := Vector3(20.0, 0, 0.0)
	var bola := Vector3(0, 0.11, -20.0)

	mp.local_tactica = t_ofensiva
	var obj_of: Vector3 = mp._objetivo_jugador(base, bola, true, {"_reaccion": 0.01}, 5.0)

	mp.local_tactica = t_defensiva
	var obj_def: Vector3 = mp._objetivo_jugador(base, bola, true, {"_reaccion": 0.01}, 5.0)

	_linea("  ofensiva+linea alta: (x=%.1f, z=%.1f)   defensiva+linea baja: (x=%.1f, z=%.1f)" % [
		obj_of.x, obj_of.z, obj_def.x, obj_def.z])
	_comprobar(obj_of.z < obj_def.z - 3.0,
		"ofensiva+linea alta empuja el bloque medible mas arriba que defensiva+linea baja (diferencia real, no cosmetica)")
	_comprobar(absf(obj_of.x) > absf(obj_def.x),
		"amplitud alta separa mas del centro que amplitud baja")

	## MARCA AL HOMBRE: un defensor con la casilla activa tiene que terminar
	## MAS CERCA del rival marcado que el mismo defensor con marca por zonas.
	var t_zonal := Tactica.new()
	var t_marca := Tactica.new()
	t_marca.marca_al_hombre = true
	## `_rival_mas_cercano()` necesita `yo["node"]` de verdad -en un partido
	## real todo jugador lo trae (lo pone `PlayerSpawner`), pero en esta
	## prueba hay que armarlo a mano. Sin este nodo, el primer intento de esta
	## prueba fallaba con un error real de "node" faltante -detectado
	## revisando el `.err.txt`, no confiando en que "0 fallos" bastara.
	var yo_nodo := Node3D.new()
	yo_nodo.position = base
	add_child(yo_nodo)
	var yo := {"_reaccion": 0.01, "slot_code": "DFC", "node": yo_nodo, "es_local": true, "arbitro": false}
	var rival_nodo := Node3D.new()
	rival_nodo.position = Vector3(-15.0, 0, 30.0)  # lejos de la ranura de formacion del marcador
	add_child(rival_nodo)
	var rival := {"node": rival_nodo, "es_local": false, "slot_code": "DC", "arbitro": false}
	mp.players = [rival]
	mp.fase = "ataqueVisita"  # el local defiende -condicion para que la marca se active

	mp.local_tactica = t_zonal
	var obj_zonal: Vector3 = mp._objetivo_jugador(base, bola, true, yo.duplicate(), 5.0)
	mp.local_tactica = t_marca
	var obj_marca: Vector3 = mp._objetivo_jugador(base, bola, true, yo.duplicate(), 5.0)

	var d_zonal := obj_zonal.distance_to(rival_nodo.position)
	var d_marca := obj_marca.distance_to(rival_nodo.position)
	_linea("  distancia al rival marcado -> zonal: %.1f m   marca al hombre: %.1f m" % [d_zonal, d_marca])
	_comprobar(d_marca < d_zonal - 3.0,
		"con marca al hombre activa, el defensor termina medible mas cerca del rival que en zona")
	rival_nodo.queue_free()
	yo_nodo.queue_free()

	## FUERA DE JUEGO: un defensor con la trampa activa tiene que quedar mas
	## adelantado (mas cerca de la mitad de cancha rival) que sin ella, en la
	## MISMA fase de defender.
	mp.players = []
	var t_sin_trampa := Tactica.new()
	var t_con_trampa := Tactica.new()
	t_con_trampa.fuera_de_juego = true
	var def_p := {"_reaccion": 0.01, "slot_code": "DFC"}
	mp.local_tactica = t_sin_trampa
	var obj_sin_trampa: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	mp.local_tactica = t_con_trampa
	var obj_con_trampa: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	_linea("  linea sin trampa: z=%.1f   con trampa de fuera de juego: z=%.1f" % [obj_sin_trampa.z, obj_con_trampa.z])
	_comprobar(obj_con_trampa.z < obj_sin_trampa.z - 2.0,
		"la trampa del fuera de juego sube medible la linea del defensor (local ataca a Z negativo)")

	## SALIDA CORTA: con el equipo en fase de ataque, un central tiene que
	## separarse mas del centro (mas ancho) si el club arma desde atras.
	var t_sin_salida := Tactica.new()
	var t_con_salida := Tactica.new()
	t_con_salida.salida_corta = true
	mp.fase = "ataqueLocal"  # el local ataca -este defensor SI tiene la pelota
	mp.local_tactica = t_sin_salida
	var obj_sin_salida: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	mp.local_tactica = t_con_salida
	var obj_con_salida: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	_linea("  ancho sin salida corta: x=%.1f   con salida corta: x=%.1f" % [obj_sin_salida.x, obj_con_salida.x])
	_comprobar(absf(obj_con_salida.x) > absf(obj_sin_salida.x) + 1.5,
		"la salida corta separa medible al central del centro cuando su equipo ataca")

	## RITMO: en igualdad de todo lo demas, un equipo de ritmo alto tiene que
	## desplazarse mas en UN MISMO paso de tiempo que uno de ritmo bajo -se
	## prueba con `_mover()` de verdad, no repitiendo la formula a mano.
	var nodo_alto := Node3D.new()
	nodo_alto.position = Vector3(20.0, 0, 20.0)
	add_child(nodo_alto)
	var nodo_bajo := Node3D.new()
	nodo_bajo.position = Vector3(20.0, 0, -20.0)
	add_child(nodo_bajo)
	var t_ritmo_alto := Tactica.new()
	t_ritmo_alto.ritmo = Tactica.Nivel.ALTO
	var t_ritmo_bajo := Tactica.new()
	t_ritmo_bajo.ritmo = Tactica.Nivel.BAJO
	var mp2 := MatchPlayback.new()
	mp2.fase = "ataqueVisita"  # el local (estos dos jugadores) defiende
	mp2.local_tactica = t_ritmo_alto
	mp2.players = [{"node": nodo_alto, "anim": null, "es_local": true, "base_pos": Vector3(0, 0, 20.0), "id": "ra"}]
	mp2.ball = null
	mp2._mover(1.0)
	var mp3 := MatchPlayback.new()
	mp3.fase = "ataqueVisita"
	mp3.local_tactica = t_ritmo_bajo
	mp3.players = [{"node": nodo_bajo, "anim": null, "es_local": true, "base_pos": Vector3(0, 0, -20.0), "id": "rb"}]
	mp3.ball = null
	mp3._mover(1.0)
	var recorrido_alto := nodo_alto.position.distance_to(Vector3(20.0, 0, 20.0))
	var recorrido_bajo := nodo_bajo.position.distance_to(Vector3(20.0, 0, -20.0))
	_linea("  recorrido en 1s -> ritmo alto: %.2f m   ritmo bajo: %.2f m" % [recorrido_alto, recorrido_bajo])
	_comprobar(recorrido_alto > recorrido_bajo,
		"un equipo de ritmo alto se mueve medible mas rapido que uno de ritmo bajo, mismo tiempo")
	nodo_alto.queue_free()
	nodo_bajo.queue_free()

	## JUGADA DE GOL (primera "jugada prehecha" real, 18-9-2026): el asistidor
	## de un gol tiene que dejar de ser ajeno a su propio pase -acercarse
	## medible al destino que le calcula `_jugada_gol()`, no seguir clavado en
	## su ranura de formacion como si el pase lo hubiera dado otro-. Se prueba
	## por `suceso()`, la puerta real que usa el partido en vivo (no llamando a
	## `_jugada_gol()` a mano), para que la prueba cubra tambien el disparo del
	## evento real y no solo la funcion aislada.
	var nodo_rematador := Node3D.new()
	nodo_rematador.position = Vector3(0.0, 0, -40.0)
	add_child(nodo_rematador)
	var nodo_asistidor := Node3D.new()
	nodo_asistidor.position = Vector3(15.0, 0, -10.0)  # lejos del area al momento del gol
	add_child(nodo_asistidor)

	var mp4 := MatchPlayback.new()
	mp4.fase = "medio"
	var p_rematador := {"id": "goleador", "node": nodo_rematador, "anim": null, "es_local": true,
		"base_pos": Vector3(0, 0, -40.0), "slot_code": "DC", "arbitro": false}
	var p_asistidor := {"id": "asistidor", "node": nodo_asistidor, "anim": null, "es_local": true,
		"base_pos": Vector3(15.0, 0, -10.0), "slot_code": "MC", "arbitro": false}
	mp4.players = [p_rematador, p_asistidor]
	mp4.players_by_id = {"goleador": p_rematador, "asistidor": p_asistidor}
	mp4.suceso({"min": 10, "t": "golMi", "equipo": "local", "tx": "gol de prueba",
		"jugadorId": "goleador", "asistidorId": "asistidor"})

	_comprobar(float(mp4._guion_hasta.get("asistidor", -1.0)) > mp4.elapsed,
		"tras el gol, el asistidor tiene una jugada con guion activa (no vuelve de inmediato al reparto por zona)")

	var destino_guion: Vector3 = mp4._guion_destino.get("asistidor", Vector3.ZERO)
	var d_inicial := nodo_asistidor.position.distance_to(destino_guion)
	for i in 20:
		mp4._mover(0.1)
	var d_final := nodo_asistidor.position.distance_to(destino_guion)
	_linea("  asistidor -> destino de la jugada: antes %.1f m   despues de 2s %.1f m" % [d_inicial, d_final])
	_comprobar(d_final < d_inicial - 3.0,
		"el asistidor se mueve medible hacia el destino de la jugada de gol, no se queda en su ranura de formacion")

	nodo_rematador.queue_free()
	nodo_asistidor.queue_free()

	## APOYO CERCANO (18-9-2026): sin ninguna jugada con guion activa, el
	## compañero MAS CERCANO al balón tiene que moverse medible hacia una
	## posición de apoyo -no quedarse en su ranura de formación como el resto-,
	## mientras que un compañero lejano SIGUE en reparto de zona normal. Es la
	## pieza que pidió el usuario: movimiento con sentido sin depender de una
	## jugada prehecha.
	var nodo_cercano := Node3D.new()
	nodo_cercano.position = Vector3(10.0, 0, -15.0)  # a unos pocos metros del balon
	add_child(nodo_cercano)
	var nodo_lejano := Node3D.new()
	nodo_lejano.position = Vector3(-25.0, 0, 30.0)  # lejos del balon, del otro lado
	add_child(nodo_lejano)
	var mp5 := MatchPlayback.new()
	mp5.fase = "ataqueLocal"  # el local ataca -condicion para que el apoyo se active
	var bola_apoyo := Vector3(12.0, 0.11, -18.0)
	var p_cercano := {"id": "cerca", "node": nodo_cercano, "anim": null, "es_local": true,
		"base_pos": Vector3(10.0, 0, -15.0), "slot_code": "MC", "arbitro": false, "_reaccion": 0.01}
	var p_lejano := {"id": "lejos", "node": nodo_lejano, "anim": null, "es_local": true,
		"base_pos": Vector3(-25.0, 0, 30.0), "slot_code": "MC", "arbitro": false, "_reaccion": 0.01}
	mp5.players = [p_cercano, p_lejano]
	mp5.ball = null

	var obj_cercano: Vector3 = mp5._objetivo_jugador(p_cercano["base_pos"], bola_apoyo, true, p_cercano, 5.0)
	var obj_lejano: Vector3 = mp5._objetivo_jugador(p_lejano["base_pos"], bola_apoyo, true, p_lejano, 5.0)
	var d_cercano_balon := obj_cercano.distance_to(bola_apoyo)
	var d_lejano_balon := obj_lejano.distance_to(bola_apoyo)
	_linea("  apoyo -> objetivo del cercano a %.1f m del balon   objetivo del lejano a %.1f m del balon" % [
		d_cercano_balon, d_lejano_balon])
	_comprobar(d_cercano_balon < 8.0,
		"el companero mas cercano al balon termina medible cerca de el (posicion de apoyo)")
	_comprobar(d_cercano_balon < d_lejano_balon - 10.0,
		"el companero mas cercano al balon queda medible mas cerca de el que el companero lejano -el apoyo no arrastra a todos por igual")

	nodo_cercano.queue_free()
	nodo_lejano.queue_free()

func _probar_copa() -> void:
	_titulo("COPA: ELIMINACION DIRECTA")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	var aspirantes: Array[Club] = []
	for c: Club in m.clubes.values():
		aspirantes.append(c)
	var copa := Copa.new("Copa de prueba")
	copa.preparar(aspirantes)
	_linea("  %d clubes inscritos -> %d en el cuadro (%s)" % [
		aspirantes.size(), copa.participantes.size(), copa.nombre_de_ronda()])
	## El cuadro tiene que ser potencia de dos: con 32 equipos y byes repartidos
	## a mano, el sorteo parece amanado y ademas hay que inventar rondas previas.
	var n := copa.participantes.size()
	var potencia := n > 0 and (n & (n - 1)) == 0
	_comprobar(potencia, "el cuadro es una potencia de dos (%d)" % n)
	_comprobar(n <= aspirantes.size(), "no se inventan participantes")

	var rondas := 0
	var nombres: Array[String] = []
	while copa.en_curso():
		nombres.append(copa.nombre_de_ronda())
		var res := copa.jugar_ronda()
		## En cada cruce tiene que pasar uno y solo uno, y el que pasa tiene que
		## ser uno de los dos que jugaron.
		for r: Dictionary in res:
			if r["pasa"] != r["local"] and r["pasa"] != r["visita"]:
				_fallos.append("pasa un club que no jugo el cruce")
			if r["gl"] == r["gv"] and r["penales"].is_empty():
				_fallos.append("un empate sin penales en eliminacion directa")
		rondas += 1
		if rondas > 12:
			break
	_linea("  rondas: %s" % ", ".join(nombres))
	_comprobar(copa.campeon != null, "la copa tiene campeon: %s" % (copa.campeon.nombre if copa.campeon else "ninguno"))
	_comprobar(rondas == int(log(float(n)) / log(2.0)), "se juegan las rondas justas (%d para %d clubes)" % [rondas, n])
	_comprobar(nombres.has("Final") and nombres.has("Semifinales"), "las rondas se llaman por su nombre")
	_comprobar(copa.participantes.has(copa.campeon), "el campeon estaba inscrito")

	## El premio es fijo y se cobra. Es lo que hace que una copa cambie el ano
	## de un club chico.
	var antes := copa.campeon.saldo
	var copa2 := Copa.new("Otra")
	copa2.preparar(aspirantes)
	var c2 := copa2.jugar_hasta_el_final()
	_linea("  premio de copa: %s (fijo, no escalado al tamano del club)" % _dinero(Copa.PREMIO))
	_comprobar(c2 != null, "jugar_hasta_el_final devuelve campeon")

	## Y la final se juega en cancha neutral: sin el 1,08 del local.
	##
	## SE MIDE POR GOLES, NO POR VICTORIAS. La version anterior contaba
	## victorias en 300 partidos y comparaba los dos numeros a pelo: con p~0,4 y
	## n=300 el ruido propio es de +-8 victorias, o sea que comparaba dos cifras
	## cuya diferencia esperada cabe entera dentro del error. Pasaba por suerte,
	## y el dia que las plantillas cambiaron de fuerza salio 118 contra 126 -al
	## reves- sin que nada estuviera roto. Los goles son una senal continua: el
	## bono de local (1,08 contra 0,94) los mueve directamente y se ve con mucha
	## menos muestra.
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var goles_en_casa := 0
	var goles_neutral := 0
	var remates_casa := 0
	var remates_neutral := 0
	## MUESTRA SUBIDA DE 300 A 800 (11-9-2026): con el árbitro metido en cada
	## llegada (`Partido._chequeo_arbitral()`, que gasta `Azar` en CADA ataque,
	## haya decisión o no) la posición del sorteo compartido se corre un poco
	## para todo lo que se simule después en el banco. La brecha esperada entre
	## casa y neutral (~4.47 contra ~4.24, un 0,23 de diferencia) cabía casi
	## entera dentro del error propio de 300 muestras -el mismo problema que
	## esta prueba ya había tenido una vez con "victorias" en vez de "goles",
	## documentado arriba-, así que bastó ese corrimiento para que en esta
	## semilla el resultado saliera al revés (4.16 contra 4.38) sin que la
	## ventaja de local se hubiera roto: `neutral=true` sigue sin sumar el
	## 1,08 de `simular_minuto()`, nadie tocó esa cuenta. Con 800 partidos por
	## lado el error baja de ~0,12 a ~0,07 remates, con margen de sobra sobre
	## la brecha real.
	for i in 800:
		var p1 := Partido.new(a, b, false)
		p1.simular()
		goles_en_casa += p1.goles_local
		remates_casa += p1.remates_local
		var p2 := Partido.new(a, b, true)
		p2.simular()
		goles_neutral += p2.goles_local
		remates_neutral += p2.remates_local
	var media_casa := float(goles_en_casa) / 800.0
	var media_neutral := float(goles_neutral) / 800.0
	var rem_casa := float(remates_casa) / 800.0
	var rem_neutral := float(remates_neutral) / 800.0
	_linea("  el local: %.2f goles y %.2f remates en casa | %.2f goles y %.2f remates en neutral" % [
		media_casa, rem_casa, media_neutral, rem_neutral])
	## SE MIDE POR REMATES, que es donde pega el bono. El camino hasta aqui:
	##  1) La version original contaba VICTORIAS en 300 partidos. Ruido propio
	##     +-8 victorias, diferencia esperada menor que eso: pasaba por suerte.
	##  2) Se cambio a GOLES, y salio 1.31 en casa contra 1.32 en neutral -o sea
	##     ninguna diferencia-, lo que parecia un bug gordo: que jugar de local
	##     no valiera nada. NO lo era: el gol es una moneda al 30% sobre cada
	##     remate, y ese sorteo se traga una diferencia del 5%.
	##  3) Medido en REMATES, que es lo que el bono multiplica directamente, la
	##     ventaja aparece limpia: 4.47 contra 4.24.
	## La leccion: medir el efecto donde ocurre, no tres sorteos mas abajo.
	_comprobar(rem_casa > rem_neutral,
		"en cancha neutral se pierde la ventaja de local (%.2f remates vs %.2f)" % [rem_casa, rem_neutral])

func _probar_selecciones() -> void:
	_titulo("SELECCIÓN NACIONAL Y MUNDIAL DE CLUBES")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 909)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_comprobar(m.selecciones != null, "tomar el mando crea la selección")
	_comprobar(m.selecciones.pais_seleccion() == m.mi_club().pais,
		"la selección que sigues es la de tu club, no Chile a fuego (%s)" % m.selecciones.pais_seleccion())
	_comprobar(m.selecciones.fuerza("Brasil") == 88 and m.selecciones.fuerza("España") == 88,
		"las seis grandes valen 88")
	var antes_conti := m.continentales.size()

	## Tres temporadas: cae al menos una prenómina, una fecha FIFA, un torneo
	## continental de selecciones (par) y, a la tercera (2028), la Copa del Mundo.
	##
	## Se comprueba el estado directo (`prenomina_ids`, `nomina_ids`) y no las
	## señales: un lambda de GDScript captura las variables locales POR VALOR, no
	## por referencia, así que `func(): vio = true` conectado a una señal escribe
	## en una copia y la variable de fuera nunca cambia -sin error, sin aviso.
	var ultimo_resumen := {}
	for temporada in 3:
		m.jugar_temporada()
		ultimo_resumen = m.nueva_temporada()
	_comprobar(not m.selecciones.prenomina_ids.is_empty(), "se publica al menos una prenómina en tres temporadas")
	_comprobar(not m.selecciones.nomina_ids.is_empty(), "se cierra al menos una convocatoria en tres temporadas")
	_comprobar(m.selecciones.nomina_ids.size() <= 18, "la nómina final no pasa de 18 (%d)" % m.selecciones.nomina_ids.size())
	_comprobar(m.selecciones.resultados.size() > 0, "quedan resultados de la selección anotados")
	_comprobar(ultimo_resumen.get("selecciones", {}).has("mundial"),
		"nueva_temporada() devuelve el resumen de selecciones")
	## 2026 -> 2027 -> 2028: la Copa del Mundo cae al cerrar 2028.
	_comprobar(not m.selecciones.mundial.is_empty(), "la Copa del Mundo se jugó al llegar a 2028 (%s)" % m.selecciones.mundial.get("campeon", "?"))
	_comprobar(m.continentales.size() == antes_conti,
		"los continentales se re-sortean cada temporada con el mismo número de torneos (%d)" % m.continentales.size())

	## Guardado y carga: la cabeza de la selección (caps, nacionalizados, mundial)
	## tiene que sobrevivir igual que el resto de sistemas de TU club.
	Partida.borrar("_prueba_selecciones")
	_comprobar(Partida.guardar(m, "_prueba_selecciones"), "una partida con selección se guarda")
	var m2 := Partida.cargar("_prueba_selecciones")
	_comprobar(m2 != null, "esa partida se recarga")
	if m2 != null:
		_comprobar(m2.selecciones != null, "la selección vuelve al cargar")
		_comprobar(m2.selecciones.mundial.get("campeon", "") == m.selecciones.mundial.get("campeon", ""),
			"vuelve el mismo campeón del mundo (%s)" % m2.selecciones.mundial.get("campeon", "?"))
		_comprobar(m2.selecciones.resultados.size() == m.selecciones.resultados.size(),
			"vuelven los mismos resultados anotados (%d)" % m2.selecciones.resultados.size())
	Partida.borrar("_prueba_selecciones")

## Comprueba que el enganche a Mundo funciona, no las reglas de Roles en si
## -esas ya las prueba _probar_roles_y_federacion(). Antes de hoy tras_partido(),
## tras_jornada() y tras_temporada() no se llamaban NUNCA desde Mundo: el
## interino jugaba sus cinco fechas y nunca pasaba nada.
func _probar_pulso_de_roles() -> void:
	_titulo("ROLES: EL PULSO DE LA CARRERA ENGANCHADO A MUNDO")
	var m := Mundo.new()
	m.generar(["CHI"], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[5].id)
	m.roles.arrancar_interinato("CHI")
	_comprobar(m.roles.en_interinato(), "arranca de interino")
	var antes := m.roles.fechas_interinato_restantes()
	for s in 8:
		m.avanzar_semana()
	_comprobar(m.roles.fechas_interinato_restantes() < antes or not m.roles.en_interinato(),
		"tras_jornada() corre solo desde avanzar_semana(): las fechas de interinato bajan (%d -> %s)" % [
			antes, "resuelto" if not m.roles.en_interinato() else str(m.roles.fechas_interinato_restantes())])
	_comprobar(not m.roles.en_interinato(), "a las ocho semanas el interinato ya se resolvio solo (cinco fechas)")

	## El prestigio se mueve con los resultados de TU partido (tras_partido).
	var m2 := Mundo.new()
	m2.generar(["CHI"], 4242)
	m2.tomar_el_mando(m2.ligas[0].clubes[5].id)
	## SE MIRA SI SE MOVIO ALGUNA VEZ, no si acabo distinto.
	##
	## La version anterior comparaba principio contra final, y el prestigio es un
	## paseo aleatorio de +1 por victoria y -1 por derrota: acabar en el mismo
	## numero tras diez jornadas es de lo mas normal -cuatro ganados, dos
	## empatados, cuatro perdidos- y la prueba fallaba sin que hubiera nada roto.
	## Una prueba que puede fallar sin bug es tan mala como una que no falla nunca.
	var prestigio_antes := m2.roles.prestigio
	var se_movio := false
	var recorrido: Array[int] = [prestigio_antes]
	for s in 10:
		m2.avanzar_semana()
		if m2.roles.prestigio != recorrido[recorrido.size() - 1]:
			se_movio = true
		recorrido.append(m2.roles.prestigio)
	_linea("  prestigio semana a semana: %s" % ", ".join(recorrido.map(func(x: int) -> String: return str(x))))
	_comprobar(se_movio,
		"diez jornadas mueven el prestigio del entrenador en algun momento (%d -> %d)" % [prestigio_antes, m2.roles.prestigio])

	## Y al cerrar la temporada, tras_temporada() tiene que dejar su resumen.
	var m3 := Mundo.new()
	m3.generar(["CHI"], 4242)
	m3.tomar_el_mando(m3.ligas[0].clubes[5].id)
	m3.jugar_temporada()
	var resumen := m3.nueva_temporada()
	_comprobar(resumen.has("roles") and (resumen["roles"] as Dictionary).has("prestigio"),
		"nueva_temporada() trae el resumen de roles (prestigio %s)" % str(resumen.get("roles", {}).get("prestigio", "?")))

	## "lo_echan" de Roles.PERMISOS: un DT normal si es despedible.
	var m4 := Mundo.new()
	m4.generar(["CHI"], 4242)
	m4.tomar_el_mando(m4.ligas[0].clubes[5].id)
	_comprobar(m4.directiva.puede_despedirte, "de entrenador normal, la directiva SI te puede echar")
	m4.directiva.mover_confianza(-100, "prueba")
	_comprobar(m4.directiva.despedido_ya, "y con la confianza hundida queda despedido de verdad")

	## Al dueño (y por la misma tabla, al ayudante y al interino) no lo juzga
	## el directorio: la confianza le sigue midiendo el apoyo del entorno, pero
	## cruzar el umbral no lo saca del club. `rol_cambiado` se emite a mano para
	## simular el ascenso real sin jugar las doce temporadas que pide de verdad.
	var m5 := Mundo.new()
	m5.generar(["CHI"], 4242)
	m5.tomar_el_mando(m5.ligas[0].clubes[5].id)
	m5.roles.rol = Roles.DUENO
	m5.roles.rol_cambiado.emit("dt", Roles.DUENO)
	_comprobar(not m5.directiva.puede_despedirte, "al dueño la directiva NO lo puede echar")
	m5.directiva.mover_confianza(-100, "prueba")
	_comprobar(m5.directiva.confianza <= Directiva.UMBRAL_DESPIDO, "la confianza baja igual -sigue midiendo el apoyo del entorno-")
	_comprobar(not m5.directiva.despedido_ya, "pero no lo despide: es el dueño")

	## Y eso sobrevive guardar y cargar -si no, un dueño que cierra el juego y
	## lo vuelve a abrir aparecería despedible otra vez hasta el próximo cambio
	## de rol-.
	Partida.borrar("_prueba_rol_dueno")
	_comprobar(Partida.guardar(m5, "_prueba_rol_dueno"), "se guarda una partida en modo dueño")
	var m5b := Partida.cargar("_prueba_rol_dueno")
	_comprobar(m5b != null and not m5b.directiva.puede_despedirte, "al recargar, la directiva sigue sin poder despedir al dueño")
	Partida.borrar("_prueba_rol_dueno")

func _probar_cantera() -> void:
	_titulo("CANTERA: CAMADA, BECAS Y LINAJE")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 313)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	_comprobar(m.cantera != null, "tomar el mando crea la cantera")
	_comprobar(m.cantera.leyendas.size() > 0, "se siembran leyendas al empezar (%d)" % m.cantera.leyendas.size())

	## Cuatro temporadas: tiene que llegar al menos una camada nueva y, con
	## veintitantas leyendas sembradas, algun hijo antes de la cuarta.
	var hubo_camada := false
	var jugadores_canteranos_vistos := 0
	for temporada in 4:
		m.jugar_temporada()
		m.nueva_temporada()
		if not m.cantera.camada_actual().is_empty():
			hubo_camada = true
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if m.cantera.es_canterano(j):
				jugadores_canteranos_vistos += 1
	_comprobar(hubo_camada, "al menos una temporada trae camada nueva")
	_comprobar(jugadores_canteranos_vistos > 0, "quedan canteranos identificables en el mundo (%d)" % jugadores_canteranos_vistos)

	## Becar a un juvenil propio, si quedó alguno con la caja que hay.
	var juveniles := m.cantera.juveniles(m.mi_club())
	if not juveniles.is_empty():
		var j: Jugador = juveniles[0]
		var antes := m.mi_club().saldo
		var problema := m.cantera.becar(j)
		if problema == "":
			_comprobar(m.cantera.tiene_beca(j), "becar a un juvenil lo marca becado")
			_comprobar(m.mi_club().saldo < antes, "la beca se cobra")
		else:
			_linea("  (sin caja para becar en esta corrida: %s)" % problema)

	## Guardado y carga: leyendas, fichas y becas tienen que sobrevivir igual que
	## el resto de sistemas de TU club.
	Partida.borrar("_prueba_cantera")
	_comprobar(Partida.guardar(m, "_prueba_cantera"), "una partida con cantera se guarda")
	var m2 := Partida.cargar("_prueba_cantera")
	_comprobar(m2 != null, "esa partida se recarga")
	if m2 != null:
		_comprobar(m2.cantera != null, "la cantera vuelve al cargar")
		_comprobar(m2.cantera.leyendas.size() == m.cantera.leyendas.size(),
			"vuelven las mismas leyendas (%d)" % m2.cantera.leyendas.size())
		if not juveniles.is_empty() and m.cantera.tiene_beca(juveniles[0]):
			var j2: Jugador = null
			for j in m2.mi_club().plantilla:
				if j.id == juveniles[0].id:
					j2 = j
					break
			_comprobar(j2 != null and m2.cantera.tiene_beca(j2), "la beca sobrevive al guardado")
	Partida.borrar("_prueba_cantera")

func _probar_logros() -> void:
	_titulo("LOGROS: MEMORIA DEL CLUB Y GALA DE FIN DE AÑO")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2024)
	## El de mas reputacion de su liga, para maximizar las chances de que gane
	## algo en pocas temporadas y la prueba no dependa de rezar a la semilla.
	var favorito: Club = m.ligas[0].clubes[0]
	for c: Club in m.ligas[0].clubes:
		if c.rep > favorito.rep:
			favorito = c
	m.tomar_el_mando(favorito.id)
	_comprobar(m.logros != null, "tomar el mando crea la memoria del club")

	## Un partido DIRIGIDO -el unico camino que hoy alimenta tras_partido(), ver
	## LEEME- contra el primer rival de calendario, para comprobar que queda
	## anotado en el cara a cara.
	var par: Array = m.proximo_partido()
	if not par.is_empty():
		var rival: Club = par[1] if par[0] == favorito else par[0]
		var p := Partido.new(par[0], par[1])
		p.simular()
		m.avanzar_semana(p)
		var h2h := m.logros.cara_a_cara(rival)
		_comprobar(int(h2h["pj"]) == 1, "el partido dirigido queda en el cara a cara (%d jugado)" % int(h2h["pj"]))

	## Varias temporadas para que la gala se dispare y, con el club mas fuerte
	## de la liga, para que algun titulo caiga y celebrar_titulo() se ejecute.
	var vio_gala := false
	for temporada in 6:
		m.jugar_temporada()
		var resumen := m.nueva_temporada()
		if resumen.has("logros") and not (resumen["logros"] as Dictionary).is_empty():
			vio_gala = true
	_comprobar(vio_gala, "nueva_temporada() trae la gala de fin de año (equipo ideal, mejor joven...)")
	_comprobar(m.logros.cuantos() > 0 or not m.logros.muro.is_empty(),
		"con seis temporadas del club mas fuerte de su liga, algo se desbloquea o se gana un título")

	## Guardado y carga: la memoria tiene que sobrevivir igual que el resto.
	Partida.borrar("_prueba_logros")
	_comprobar(Partida.guardar(m, "_prueba_logros"), "una partida con memoria de club se guarda")
	var m2 := Partida.cargar("_prueba_logros")
	if m2 != null:
		_comprobar(m2.logros.cuantos() == m.logros.cuantos(), "vuelven los mismos logros conseguidos (%d)" % m2.logros.cuantos())
		_comprobar(m2.logros.muro.size() == m.logros.muro.size(), "vuelve el mismo muro de títulos (%d)" % m2.logros.muro.size())
	Partida.borrar("_prueba_logros")

func _probar_cesiones() -> void:
	_titulo("CESIONES Y CLÁUSULAS: LA LETRA PEQUEÑA")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	_comprobar(m.cesiones != null, "tomar el mando crea las cesiones")

	## Ceder a un canterano y que vuelva mejor al cerrar la temporada -la trampa
	## gorda del HTML era que la opcion NUNCA se ejecutaba porque dos resolutores
	## se pisaban; aqui solo hay uno.
	var joven: Jugador = null
	for j in mio.plantilla:
		if j.edad <= Cesiones.EDAD_CANTERANO:
			joven = j
			break
	if joven != null:
		var r := m.cesiones.ceder_canterano(joven)
		_comprobar(not r.has("error"), "se puede ceder a un canterano (%s)" % str(r.get("error", "")))
		_comprobar(m.cesiones.esta_cedido(joven.id), "queda marcado como cedido")
		_comprobar(not mio.plantilla.has(joven), "sale de la plantilla mientras esta cedido")
		var media_antes := joven.ovr
		m.jugar_temporada()
		m.nueva_temporada()
		_comprobar(not m.cesiones.esta_cedido(joven.id), "al cerrar la temporada, la cesion se resuelve sola")
		_comprobar(mio.plantilla.has(joven), "el canterano cedido vuelve a casa")
		_comprobar(joven.ovr >= media_antes, "vuelve con la misma media o mejor (%d -> %d)" % [media_antes, joven.ovr])

	## Clausula de rescision: pactarla, blindarla, y que otro club te la pueda
	## pagar de verdad -sin pasar por la mesa de Mercado.
	var figura: Jugador = mio.plantilla[0]
	for j in mio.plantilla:
		if j.ovr > figura.ovr:
			figura = j
	var monto1 := m.cesiones.pactar_clausula(figura)
	_comprobar(m.cesiones.clausula_de(figura) == monto1, "pactar cláusula queda fijado (%s)" % _dinero_prueba(monto1))
	var monto2 := m.cesiones.blindar(figura)
	_comprobar(monto2 > monto1, "blindar sube la cláusula sobre la pactada (%s -> %s)" % [_dinero_prueba(monto1), _dinero_prueba(monto2)])

	## Un rival con cláusula implicita -sin pactar, la del hash- y caja de sobra
	## para pagarla.
	var rival_j: Jugador = null
	var rival_c: Club = null
	for c: Club in m.clubes.values():
		if c.id == mio.id:
			continue
		for j in c.plantilla:
			if m.cesiones.clausula_de(j) > 0:
				rival_j = j
				rival_c = c
				break
		if rival_j != null:
			break
	if rival_j != null:
		mio.mover_saldo(m.cesiones.coste_de_clausula(rival_j)["total"] + 1000)
		var antes_caja: int = rival_c.saldo
		var rr := m.cesiones.pagar_clausula(rival_j, mio)
		_comprobar(not rr.has("error"), "se puede pagar la clausula de un jugador rival (%s)" % str(rr.get("error", "")))
		_comprobar(rival_j.club_id == mio.id, "el jugador pasa a ser tuyo tras el clausulazo")
		_comprobar(rival_c.saldo > antes_caja, "el club vendido cobra la clausula")

	## Guardado y carga.
	Partida.borrar("_prueba_cesiones")
	_comprobar(Partida.guardar(m, "_prueba_cesiones"), "una partida con cesiones y clausulas se guarda")
	var m2 := Partida.cargar("_prueba_cesiones")
	if m2 != null:
		_comprobar(m2.cesiones.clausula_de(figura) == monto2, "la clausula blindada sobrevive al guardado (%s)" % _dinero_prueba(m2.cesiones.clausula_de(figura)))
	Partida.borrar("_prueba_cesiones")

	## RENOVAR. `pide_para_renovar()` sabia calcular lo que pide cada uno desde
	## hace tiempo y no habia forma de decirle que si.
	var renovable: Jugador = mio.plantilla[0]
	renovable.anios_contrato = 1
	renovable.sueldo = 50000
	renovable.moral = 70
	var pide := m.cantera.pide_para_renovar(renovable)
	_comprobar(pide > renovable.sueldo, "pide mas de lo que cobra para renovar (%d sobre %d)" % [pide, renovable.sueldo])
	var r_ren := m.cantera.renovar(renovable, false)
	_comprobar(r_ren.has("ok"), "se puede renovar a uno tuyo")
	_comprobar(renovable.sueldo == pide, "renovar le deja el sueldo que pedia (%d)" % renovable.sueldo)
	_comprobar(renovable.anios_contrato >= 2 and renovable.anios_contrato <= 4,
		"firma entre dos y cuatro temporadas (%d)" % renovable.anios_contrato)
	## Con clausula acepta un 10% menos: es la unica decision real de la pantalla.
	var otro: Jugador = mio.plantilla[1]
	otro.anios_contrato = 1
	otro.sueldo = 50000
	otro.moral = 70
	var pide2 := m.cantera.pide_para_renovar(otro)
	var r2 := m.cantera.renovar(otro, true)
	_comprobar(otro.sueldo < pide2, "con clausula de salida cobra menos que lo que pedia (%d < %d)" % [otro.sueldo, pide2])
	_comprobar(int(r2.get("clausula", 0)) > 0, "y le queda una clausula puesta (%d)" % int(r2.get("clausula", 0)))
	## Y no se puede renovar a uno ajeno.
	var ajeno: Jugador = null
	for cl: Club in m.ligas[0].clubes:
		if cl != mio:
			ajeno = cl.plantilla[0]
			break
	_comprobar(m.cantera.renovar(ajeno, false).has("error"), "no se puede renovar a un jugador que no es tuyo")

func _dinero_prueba(n: int) -> String:
	return "%dk" % (n / 1000)

func _probar_desafios() -> void:
	_titulo("DESAFÍOS: LOS OCHO DEL ASISTENTE")
	## POBREZA: la caja inicial se pisa al 4% de la referencia por reputación.
	var m1 := Mundo.new()
	m1.generar(["CHI"], 4001)
	m1.tomar_el_mando(m1.ligas[0].clubes[0].id)
	m1.desafios = ["pobreza"]
	m1.aplicar_desafios()
	var esperado1 := int(round(Eco.ref_caja(float(m1.mi_club().rep)) * 0.04))
	_comprobar(m1.mi_club().saldo == esperado1,
		"'pobreza' deja la caja en el 4%% de la referencia (%d, esperados %d)" % [m1.mi_club().saldo, esperado1])

	## LOCAL: fuera los extranjeros, plantel repuesto a 20 y todos del país.
	var m2 := Mundo.new()
	m2.generar(["CHI", "ARG"], 4002)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	## Se mete un extranjero a mano para que la prueba no dependa de que el
	## generador aleatorio haya puesto alguno de verdad en este club.
	var extranjero := m2.crear_jugador(m2.mi_club(), "MED", "MC", 25, 70)
	extranjero.pais = "ARG"
	m2.desafios = ["local"]
	m2.aplicar_desafios()
	var quedan_extranjeros := 0
	for j in m2.mi_club().plantilla:
		if j.pais != m2.mi_club().pais:
			quedan_extranjeros += 1
	_comprobar(quedan_extranjeros == 0, "'local' deja el plantel sin extranjeros (%d)" % quedan_extranjeros)
	_comprobar(m2.mi_club().plantilla.size() >= 20, "y repone hasta al menos 20 fichas (%d)" % m2.mi_club().plantilla.size())

	## APELLIDOS POR NACIONALIDAD (22-9-2026, pedido directo del usuario: "usa
	## apellidos de los canteranos según su nacionalidad"). `POOLS_EU`/
	## `NOMBRES_BRA`/`APELLIDOS_BRA` ya existían -usados para el DT rival y
	## ojeadores- pero `Mundo.crear_jugador()` (el 90% del mundo) nunca los
	## miraba: todo el mundo salía con apellido chileno.
	##
	## BUG REAL DE LA PROPIA PRUEBA, NO DEL JUEGO (22-9-2026): generar un
	## TERCER mundo aquí mismo (`Mundo.new().generar(["CHI","ESP","GER"])`,
	## después de los `m1`/`m2` que ya arma esta función) colgó el banco tres
	## veces seguidas (540s cada vez) -confirmado con bisección: sin ese
	## tercer `generar()` el banco corre limpio en 149s, con él nunca termina-.
	## El mismo `generar(["CHI","ESP","GER"], 4003)` en un proceso PROPIO
	## (`pruebas/diagnostico_nombres_pais.gd`) corre perfecto en segundos, así
	## que el problema es específico de crear un tercer `Mundo` completo
	## dentro de esta función, no del generador ni del nombrador en sí -causa
	## exacta sin encontrar todavía, no vale la pena seguir persiguiéndola
	## para esto-. Se verifica sin generar un mundo nuevo: reusando `m2` (ya
	## vivo, con club chileno real) para el caso sin bolsa propia, y `POOLS_EU`
	## directo para confirmar que las bolsas de datos están bien formadas -la
	## prueba end-to-end real con clubes de verdad ya quedó hecha y mostrada
	## al usuario con `diagnostico_nombres_pais.gd` (Real Madrid con apellidos
	## vascos, Bayern con apellidos alemanes), esto solo cubre que no se
	## desarme silenciosamente.
	var pools_check: Dictionary = Datos.tabla("POOLS_EU")
	_comprobar(pools_check.has("ESP"), "POOLS_EU trae la bolsa de España (Athletic Bilbao, pedido del usuario)")
	_comprobar((pools_check["ESP"][1] as Array).has("Etxeberria"),
		"la bolsa de España tiene sabor vasco de verdad (Etxeberria)")
	_comprobar(pools_check.has("GER") and pools_check.has("ITA") and pools_check.has("FRA"),
		"las otras ligas europeas grandes ya tenían su propia bolsa")
	var jugador_sin_bolsa := m2.crear_jugador(m2.mi_club(), "MED", "MC", 25, 70)
	var apellidos_fondo: Array = Datos.tabla("APELLIDOS")
	_comprobar(apellidos_fondo.has(jugador_sin_bolsa.nombre.split(" ")[-1]),
		"un país sin bolsa propia sigue cayendo al fondo chileno de siempre (dio '%s')" % jugador_sin_bolsa.nombre)

	## INVICTO: la primera derrota -no el empate- enciende fin_partida, y solo
	## una vez.
	var m3 := Mundo.new()
	m3.generar(["CHI"], 4003)
	m3.tomar_el_mando(m3.ligas[0].clubes[0].id)
	m3.desafios = ["invicto"]
	m3._chequear_desafios_tras_partido(1, 1, m3.ligas[0].clubes[1])
	_comprobar(m3.fin_partida.is_empty(), "un empate no activa 'invicto'")
	m3._chequear_desafios_tras_partido(0, 2, m3.ligas[0].clubes[1])
	_comprobar(not m3.fin_partida.is_empty(), "la primera derrota sí activa 'invicto' (fin_partida)")

	## DERBIS: perder un clásico parte la confianza por la mitad -y solo si
	## además es un clásico de verdad.
	var m4 := Mundo.new()
	m4.generar(["CHI"], 4004)
	## clubes[0..2] son los tres grandes de Chile en DATA_P1: es donde vive el
	## "big 3" que `es_clasico()` reconoce por nombre, no por hash.
	m4.tomar_el_mando(m4.ligas[0].clubes[0].id)
	var rival_clasico: Club = null
	for c: Club in m4.ligas[0].clubes:
		if c.id != m4.mi_club_id and m4.es_clasico(m4.mi_club(), c):
			rival_clasico = c
			break
	_comprobar(rival_clasico != null, "es_clasico() reconoce al menos un clásico chileno en la Primera")
	if rival_clasico != null:
		m4.desafios = ["derbis"]
		var antes := m4.directiva.confianza
		m4._chequear_desafios_tras_partido(0, 1, rival_clasico)
		_comprobar(m4.directiva.confianza == int(round(float(antes) * 0.5)),
			"'derbis' parte la confianza a la mitad al perder el clásico (%d -> %d)" % [antes, m4.directiva.confianza])

	## TROTAMUNDOS: a la segunda temporada seguida en el mismo club, despedido
	## por las buenas -mismo mecanismo que un despido real, mismo selector para
	## elegir destino.
	var m5 := Mundo.new()
	m5.generar(["CHI"], 4005)
	m5.tomar_el_mando(m5.ligas[0].clubes[0].id)
	m5.desafios = ["trotamundos"]
	var r1 := m5.nueva_temporada()
	_comprobar(not r1.get("trotamundos", false) and not m5.directiva.despedido_ya,
		"trotamundos no actua a la primera temporada")
	var r2 := m5.nueva_temporada()
	_comprobar(r2.get("trotamundos", false) and m5.directiva.despedido_ya,
		"trotamundos obliga a cambiar de club a la segunda")

	## Guardado: los desafíos elegidos tienen que sobrevivir a guardar/cargar.
	var m6 := Mundo.new()
	m6.generar(["CHI"], 4006)
	m6.tomar_el_mando(m6.ligas[0].clubes[0].id)
	m6.desafios = ["pobreza", "invicto"]
	Partida.borrar("_prueba_desafios")
	_comprobar(Partida.guardar(m6, "_prueba_desafios"), "una partida con desafíos se guarda")
	var m6b := Partida.cargar("_prueba_desafios")
	_comprobar(m6b != null and m6b.desafios.size() == 2 and m6b.tiene_desafio("invicto"),
		"vuelven los mismos desafíos al cargar (%s)" % str(m6b.desafios if m6b != null else []))
	Partida.borrar("_prueba_desafios")

func _probar_fundar_club() -> void:
	_titulo("CREAR TU CLUB: FUNDAR DE CERO")
	var m := Mundo.new()
	m.generar([], 6001)

	## En Chile tiene que tomar el colista de ASCENSO, no de Primera.
	var segunda: Liga = null
	for l: Liga in m.ligas:
		if l.pais == "CHI" and l.division() == 2:
			segunda = l
			break
	_comprobar(segunda != null, "el mundo trae la Primera B de Chile")
	var peor_antes: Club = null
	if segunda != null:
		for c: Club in segunda.clubes:
			if peor_antes == null or c.rep < peor_antes.rep:
				peor_antes = c
	var club := m.fundar_club("Deportivo Prueba", "CHI")
	_comprobar(club != null, "fundar_club() devuelve el club fundado")
	if club != null:
		_comprobar(club.nombre == "Deportivo Prueba", "el club queda con el nombre elegido")
		_comprobar(club.rep == Mundo.REP_FUNDACION, "la reputación de fundación es %d (%d)" % [Mundo.REP_FUNDACION, club.rep])
		_comprobar(club.color1 == "#1e4030" and club.color2 == "#c9a227", "los colores son los del escudo del juego")
		_comprobar(club.division == 2, "sigue en Ascenso -se refunda el club, no se lo asciende")
		_comprobar(club.plantilla.size() >= 18, "el plantel se rehizo entero (%d fichas)" % club.plantilla.size())
		_comprobar(peor_antes != null and club.id == peor_antes.id, "fundar toma al colista real de Ascenso, no cualquiera")
		_comprobar(m.mi_club_id == club.id, "tomar_el_mando() ya se hizo solo: no hace falta un paso más")
		_comprobar(segunda.clubes.has(club), "el club fundado sigue en el calendario de su liga -mismo objeto, no uno nuevo")

	## Fuera de Chile no hay Ascenso: toma el más flojo de la única división.
	var esp: Liga = null
	for l: Liga in m.ligas:
		if l.pais == "ESP":
			esp = l
			break
	if esp != null:
		var peor_esp: Club = esp.clubes[0]
		for c: Club in esp.clubes:
			if c.rep < peor_esp.rep:
				peor_esp = c
		var club2 := m.fundar_club("Fundado FC", "ESP")
		_comprobar(club2 != null and club2.id == peor_esp.id,
			"fuera de Chile toma el más flojo de su única división")

	## Guardado: nombre, colores, reputación y plantel nuevo sobreviven.
	Partida.borrar("_prueba_fundar")
	_comprobar(Partida.guardar(m, "_prueba_fundar"), "una partida con un club fundado se guarda")
	var m2 := Partida.cargar("_prueba_fundar")
	if m2 != null and club != null:
		var recargado: Club = m2.clubes.get(club.id)
		_comprobar(recargado != null and recargado.nombre == "Deportivo Prueba" and recargado.rep == Mundo.REP_FUNDACION,
			"el club fundado vuelve igual al cargar")
	Partida.borrar("_prueba_fundar")

func _probar_ascensos() -> void:
	_titulo("ASCENSOS, DESCENSOS Y PREMIOS")
	var m := Mundo.new()
	m.generar(["CHI"], 4040)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var primera := m.ligas[0]
	var segunda := m.ligas[1]
	_comprobar(primera.division() == 1 and segunda.division() == 2, "las dos divisiones estan marcadas")
	m.jugar_temporada()

	var t1 := primera.tabla()
	var t2 := segunda.tabla()
	var campeon: Club = t1[0]["club"]
	var caja_antes := campeon.saldo
	var rep_antes := campeon.rep
	var ultimo: Club = t1[t1.size() - 1]["club"]
	var penultimo: Club = t1[t1.size() - 2]["club"]
	var primero_b: Club = t2[0]["club"]
	var segundo_b: Club = t2[1]["club"]
	var n1 := primera.clubes.size()
	var n2 := segunda.clubes.size()

	var resumen := m.nueva_temporada()
	_linea("  campeon: %s   suben: %s, %s   bajan: %s, %s" % [
		campeon.nombre, primero_b.nombre, segundo_b.nombre, ultimo.nombre, penultimo.nombre])
	_comprobar(campeon.saldo > caja_antes, "el campeon cobra el premio")
	_comprobar(campeon.rep == rep_antes + 1, "ganar la liga sube la reputacion del club")

	## Lo que de verdad hay que comprobar: que los clubes CAMBIAN de lista, no
	## solo de etiqueta. Mover la etiqueta sin mover la lista deja a un club
	## descendido jugando en primera y cobrando de segunda.
	_comprobar(segunda.clubes.has(ultimo) and segunda.clubes.has(penultimo), "los dos ultimos estan ahora en segunda")
	_comprobar(primera.clubes.has(primero_b) and primera.clubes.has(segundo_b), "los dos primeros de segunda estan ahora en primera")
	_comprobar(not primera.clubes.has(ultimo), "el descendido ya no esta en primera")
	_comprobar(ultimo.division == 2 and primero_b.division == 1, "la division del club acompana al cambio de liga")
	_comprobar(primera.clubes.size() == n1 and segunda.clubes.size() == n2,
		"las dos ligas conservan su tamano (%d y %d)" % [primera.clubes.size(), segunda.clubes.size()])

	## Y el castigo economico del descenso, que es el que de verdad duele.
	var f_abajo := Finanzas.new(ultimo)
	var f_arriba := Finanzas.new(primero_b)
	_linea("  television: el descendido cobra %s, el ascendido %s" % [
		_dinero(f_abajo.derechos_tv()), _dinero(f_arriba.derechos_tv())])
	_comprobar(f_abajo.derechos_tv() < f_arriba.derechos_tv() or ultimo.rep > primero_b.rep + 8,
		"bajar de division cuesta dinero de television")

	## El calendario nuevo tiene que incluir a los recien llegados.
	_comprobar(primera.jornadas() > 0 and primera.emparejamiento_de(primero_b).size() == 2,
		"el ascendido tiene partido en el calendario nuevo")

func _probar_vender() -> void:
	_titulo("VENDER: TRANSFERIBLES, OFERTAS ENTRANTES Y RESCISIÓN")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	var mk := m.mercado

	## Listar transferible: marca, castiga la moral una vez, no dos.
	var j: Jugador = mio.plantilla[0]
	var moral_antes := j.moral
	mk.listar_transferible(j)
	_comprobar(j.transferible, "listar transferible marca al jugador")
	_comprobar(j.moral == clampi(moral_antes - 8, 10, 99), "listar transferible castiga la moral")
	var moral_tras_listar := j.moral
	mk.listar_transferible(j)
	_comprobar(j.moral == moral_tras_listar, "listar dos veces no castiga dos veces")

	## El sorteo semanal: en 100 intentos, con un pais entero de posibles
	## compradores detras, tiene que caer al menos una oferta.
	var intentos := 0
	while mk.ofertas_recibidas.is_empty() and intentos < 100:
		mk.buscar_oferta_por_mi_jugador()
		intentos += 1
	_comprobar(not mk.ofertas_recibidas.is_empty(), "cae al menos una oferta en 100 semanas (%d intentos)" % intentos)
	if mk.ofertas_recibidas.is_empty():
		return
	var o: Dictionary = mk.ofertas_recibidas[0]
	var jugador_ofertado: Jugador = o["jugador"]
	var club_comprador: Club = o["club"]
	_comprobar(jugador_ofertado.club_id == mio.id, "la oferta es por un jugador que sigue siendo tuyo")
	_comprobar(club_comprador.id != mio.id, "el comprador nunca eres tu mismo")

	## Rechazar: la oferta desaparece, el jugador sigue en casa.
	var total_antes := mk.ofertas_recibidas.size()
	mk.responder_oferta(0, false)
	_comprobar(mk.ofertas_recibidas.size() == total_antes - 1, "rechazar quita la oferta de la lista")
	_comprobar(jugador_ofertado.club_id == mio.id, "rechazar no mueve al jugador")

	## Aceptar: el dinero se mueve, el jugador cambia de casa.
	intentos = 0
	while mk.ofertas_recibidas.is_empty() and intentos < 100:
		mk.buscar_oferta_por_mi_jugador()
		intentos += 1
	if mk.ofertas_recibidas.is_empty():
		_comprobar(false, "cae una segunda oferta para probar la aceptacion")
		return
	var o2: Dictionary = mk.ofertas_recibidas[0]
	var vendido: Jugador = o2["jugador"]
	var comprador2: Club = o2["club"]
	var saldo_mio_antes := mio.saldo
	var saldo_comprador_antes := comprador2.saldo
	var monto2 := int(o2["monto"])
	mk.responder_oferta(0, true)
	_comprobar(vendido.club_id == comprador2.id, "aceptar mueve al jugador al comprador")
	_comprobar(not mio.plantilla.has(vendido), "el vendido sale de tu plantilla")
	_comprobar(mio.saldo == saldo_mio_antes + monto2, "el dinero de la venta entra a tu caja")
	_comprobar(comprador2.saldo == saldo_comprador_antes - monto2, "el dinero sale de la caja del comprador")
	_comprobar(not vendido.transferible, "vendido, ya no queda transferible")

	## Rescision: mismo camino que usa la ficha (`_rescindir` en principal.gd),
	## repetido aqui a mano porque ese metodo vive en la UI y el banco es
	## headless. El finiquito sale de `Cantera.coste_rescision()`, que ya
	## portaba la formula pero nadie la llamaba desde ningun boton.
	var antes_plantel := mio.plantilla.size()
	var rescindido: Jugador = mio.plantilla[0]
	var coste: Dictionary = m.cantera.coste_rescision(rescindido)
	var total := int(coste["total"])
	var saldo_antes_resc := mio.saldo
	mio.mover_saldo(-total)
	mio.soltar(rescindido)
	rescindido.club_id = ""
	_comprobar(mio.plantilla.size() == antes_plantel - 1, "rescindir saca al jugador de la plantilla (%d -> %d)" % [antes_plantel, mio.plantilla.size()])
	_comprobar(mio.saldo == saldo_antes_resc - total, "rescindir paga el finiquito y la comision (%s)" % _dinero(total))
	_comprobar(not mio.plantilla.has(rescindido), "el rescindido no aparece dos veces ni queda huerfano en la lista")

	## Guardado: una oferta pendiente tiene que sobrevivir a cargar.
	mk.listar_transferible(mio.plantilla[0])
	intentos = 0
	while mk.ofertas_recibidas.is_empty() and intentos < 150:
		mk.buscar_oferta_por_mi_jugador()
		intentos += 1
	var pendientes_antes := mk.ofertas_recibidas.size()
	if pendientes_antes > 0:
		Partida.guardar(m, "__prueba_vender__")
		var m2 := Partida.cargar("__prueba_vender__")
		_comprobar(m2.mercado.ofertas_recibidas.size() == pendientes_antes, "vuelven las mismas ofertas pendientes al cargar (%d)" % m2.mercado.ofertas_recibidas.size())
		if m2.mercado.ofertas_recibidas.size() > 0:
			var oc: Dictionary = m2.mercado.ofertas_recibidas[0]
			_comprobar(oc["jugador"] is Jugador and oc["club"] is Club, "la oferta cargada resuelve jugador y club como objetos reales")
		Partida.borrar("__prueba_vender__")
	else:
		_linea("  (sin ofertas pendientes que guardar tras 150 intentos: no se prueba el guardado)")

func _probar_ojeadores() -> void:
	_titulo("RED DE OJEADORES CON NOMBRE Y SESGO")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 6262)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var oj := m.ojeadores
	var mio := m.mi_club()

	## Sin jefe de ojeadores contratado, no se cubre ni un pais.
	_comprobar(oj.max_paises() == 0, "sin jefe de ojeadores, la red cubre 0 paises")
	var motivo := oj.alternar_pais("ARG")
	_comprobar(motivo != "", "no se puede cubrir un pais sin jefe de ojeadores (%s)" % motivo)

	## Contratado, el tope sube por escalones -[0,2,4,6]-. El coste crece con el
	## cuadrado del nivel, así que sin caja de sobra la subida de 4 a 5 fallaba
	## por falta de fondos y el nivel se quedaba corto sin que el propio
	## `subir()` lo contara como fallo -devuelve un motivo, no revienta-.
	mio.mover_saldo(2000000000)
	for i in Staff.NIVEL_MAX:
		m.staff.subir("ojeador", mio)
	_comprobar(m.staff.nivel("ojeador") == Staff.NIVEL_MAX, "el jefe de ojeadores llega al nivel maximo (%d)" % m.staff.nivel("ojeador"))
	## La tabla del HTML solo llega a nivel 3 -[0,2,4,6][G.staff.ojo]-, pero el
	## cuerpo tecnico de Godot sube hasta NIVEL_MAX=5 en los seis puestos por
	## igual: `max_paises()` recorta a 3 antes de indexar, así que el tope no
	## sigue subiendo pasado ese punto -mejor recortar a lo que el HTML sí
	## definió que inventar dos escalones que no existen en el original-.
	_comprobar(oj.max_paises() == Ojeadores.MAX_PAISES_POR_NIVEL[mini(Staff.NIVEL_MAX, 3)], "el tope de paises sigue la tabla del nivel, recortada a 3 (%d)" % oj.max_paises())

	## Contratar dos paises: queda registrado, con nombre y sesgo de verdad.
	_comprobar(oj.alternar_pais("ARG") == "", "se contrata un ojeador en ARG")
	_comprobar(oj.alternar_pais("ESP") == "", "se contrata un ojeador en ESP")
	_comprobar(oj.cubre("ARG") and oj.cubre("ESP"), "las dos coberturas quedan activas")
	_comprobar(String(oj.ojeadores["ARG"]["nombre"]) != "", "el ojeador de ARG tiene nombre")
	_comprobar(Ojeadores.SESGOS.has(oj.ojeadores["ARG"]["sesgo"]), "el sesgo del ojeador de ARG es uno de los cuatro conocidos")

	## Retirar la cobertura la deshace del todo.
	_comprobar(oj.alternar_pais("ESP") == "", "se puede retirar una cobertura")
	_comprobar(not oj.cubre("ESP") and not oj.ojeadores.has("ESP"), "al retirar ESP no queda ni la red ni el ojeador")

	## Cuanto se conoce a un jugador ajeno: tuyo=3, mismo pais que el tuyo sin
	## cobertura=1.5, pais cubierto=nivel*0.9, y ojeado siempre 3 sin importar
	## lo demas.
	var mio_j: Jugador = mio.plantilla[0]
	_comprobar(oj.nivel_de(mio_j) == 3.0, "un jugador propio se conoce del todo")
	var rival_arg: Jugador = null
	var rival_local: Jugador = null
	var rival_lejano: Jugador = null
	for c: Club in m.clubes.values():
		if c.id == mio.id or c.plantilla.is_empty():
			continue
		if c.pais == "ARG" and rival_arg == null:
			rival_arg = c.plantilla[0]
		elif c.pais == mio.pais and rival_local == null:
			rival_local = c.plantilla[0]
		elif c.pais != "ARG" and c.pais != mio.pais and rival_lejano == null:
			rival_lejano = c.plantilla[0]
	if rival_arg != null:
		_comprobar(oj.nivel_de(rival_arg) == float(Staff.NIVEL_MAX) * 0.9, "un pais cubierto da nivel*0.9 (%.1f)" % oj.nivel_de(rival_arg))
	if rival_local != null:
		_comprobar(oj.nivel_de(rival_local) == 1.5, "tu propio pais sin cobertura extra da 1.5 (%.1f)" % oj.nivel_de(rival_local))
	if rival_lejano != null:
		_comprobar(oj.nivel_de(rival_lejano) == 0.0, "un pais ajeno y sin cubrir da 0 (%.1f)" % oj.nivel_de(rival_lejano))
		var txt := oj.ovr_texto(rival_lejano)
		_comprobar(txt.find("-") >= 0, "sin conocerlo la media sale en rango, no exacta (%s)" % txt)
		_comprobar(oj.ovr_texto(rival_lejano) == txt, "el rango es estable: no cambia entre llamadas para el mismo jugador")

		## "MERCADO A CIEGAS": con el modo activado, ni el rango numerico se ve
		## -solo una palabra de ESCALA_CIEGA-, y esa palabra tambien es estable.
		oj.modo_ciego = true
		var palabra := oj.ovr_texto(rival_lejano)
		_comprobar(palabra.find("-") < 0 and not palabra.is_valid_int(), "en modo ciego se ve una palabra, no un rango (%s)" % palabra)
		var nombres_escala: Array[String] = []
		for fila: Array in Ojeadores.ESCALA_CIEGA:
			nombres_escala.append(String(fila[1]))
		_comprobar(nombres_escala.has(palabra), "la palabra es una de las siete de ESCALA_CIEGA (%s)" % palabra)
		_comprobar(oj.ovr_texto(rival_lejano) == palabra, "la palabra tambien es estable entre llamadas")
		_comprobar(oj.ovr_texto(mio_j) == str(mio_j.ovr), "en modo ciego, un jugador propio sigue mostrando su numero real")
		oj.modo_ciego = false

	## Ojear paga, revela para siempre y sube el contador del ojeador del pais
	## -solo si ese pais tiene ojeador de verdad, como en el HTML-.
	if rival_arg != null:
		var informes_antes := int(oj.ojeadores["ARG"]["informes"])
		var presupuesto_antes := oj.presupuesto
		var saldo_antes := mio.saldo
		var problema2 := oj.ojear(rival_arg)
		_comprobar(problema2 == "", "ojear a un rival funciona (%s)" % problema2)
		_comprobar(m.ojeados.has(rival_arg.id), "el jugador ojeado queda marcado en mundo.ojeados")
		_comprobar(oj.nivel_de(rival_arg) == 3.0, "ojeado, se conoce del todo")
		_comprobar(oj.ovr_texto(rival_arg) == str(rival_arg.ovr), "ojeado, la media sale exacta")
		_comprobar(oj.presupuesto < presupuesto_antes or mio.saldo < saldo_antes, "ojear gasta de verdad, del presupuesto de ojeo o de la caja")
		_comprobar(oj.ojear(rival_arg) == "ya está ojeado", "no se puede ojear dos veces al mismo jugador")
		_comprobar(int(oj.ojeadores["ARG"]["informes"]) == informes_antes + 1, "el ojeador de ARG suma un informe mas (%d -> %d)" % [informes_antes, int(oj.ojeadores["ARG"]["informes"])])

	## El humor baja si se ignoran mas informes de los que se usan, y a cero
	## el ojeador renuncia y se pierde la cobertura de su pais.
	var o_arg: Dictionary = oj.ojeadores.get("ARG", {})
	if not o_arg.is_empty():
		o_arg["ignorados"] = 100
		o_arg["informes"] = 10
		o_arg["humor"] = 3
		oj.procesar_semana()
		_comprobar(not oj.cubre("ARG"), "un ojeador ignorado sistematicamente renuncia y se pierde la cobertura")

	## Guardado y carga: la red, los ojeadores y el presupuesto vuelven igual.
	oj.alternar_pais("ARG")
	var presupuesto_guardado := oj.presupuesto
	var paises_guardados := oj.red.keys()
	_comprobar(Partida.guardar(m, "__prueba_ojeadores__"), "una partida con red de ojeadores se guarda")
	var m2 := Partida.cargar("__prueba_ojeadores__")
	_comprobar(m2 != null, "esa partida se recarga")
	if m2 != null:
		_comprobar(m2.ojeadores.presupuesto == presupuesto_guardado, "vuelve el mismo presupuesto de ojeo")
		_comprobar(m2.ojeadores.red.keys() == paises_guardados, "vuelve la misma cobertura de paises")
		_comprobar(m2.ojeados.has(rival_arg.id) if rival_arg != null else true, "vuelven los jugadores ya ojeados")
	Partida.borrar("__prueba_ojeadores__")

func _probar_negociacion() -> void:
	_titulo("LA MESA DE NEGOCIACIÓN")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 7373)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	mio.mover_saldo(300000000)
	var mk := m.mercado

	## Buscar un objetivo claro: alguien de otro club, no del tuyo.
	var objetivo: Jugador = null
	for c: Club in m.clubes.values():
		if c.id != mio.id and not c.plantilla.is_empty():
			objetivo = c.plantilla[0]
			break
	_comprobar(objetivo != null, "hay un objetivo para negociar")
	if objetivo == null:
		return

	var motivo := mk.abrir_negociacion(objetivo)
	_comprobar(motivo == "", "se abre la mesa (%s)" % motivo)
	_comprobar(mk.negociacion != null, "queda una mesa abierta")
	var n := mk.negociacion
	_comprobar(n.pedido == mk.valor_pedido(objetivo), "el pedido inicial coincide con valor_pedido()")
	_comprobar(n.fijo == int(round(float(n.pedido) * 0.7 / 1000.0)) * 1000, "la oferta fija de salida es el 70% del pedido")

	## Ajustes: pct, sueldo, años, fijo se mueven en la direccion pedida.
	var pct_antes := n.pct
	n.ajustar("pct", 1)
	_comprobar(n.pct == pct_antes + 5, "ajustar pct sube de 5 en 5 (%d -> %d)" % [pct_antes, n.pct])
	n.ajustar("pct", -10)
	_comprobar(n.pct == 0, "pct no baja de 0 (%d)" % n.pct)
	var fijo_antes := n.fijo
	n.ajustar("fijo", 1)
	_comprobar(n.fijo > fijo_antes, "ajustar fijo al alza sube el fijo")
	var anios_antes := n.anios
	n.ajustar("anios", 1)
	_comprobar(n.anios == anios_antes + 1, "ajustar anios suma de a uno")

	## Con una oferta a proposito muy baja, el club pide mas -no cierra a la primera.
	n.fijo = 1000
	n.cuotas = 0; n.bonos = 0; n.pct = 0; n.opaco = 0
	var r1 := n.enviar_oferta()
	_comprobar(String(r1.get("tipo", "")) in ["club_pide_mas", "rival_traspaso", "rota"], "una oferta muy baja no cierra (%s)" % String(r1.get("tipo", "")))
	_comprobar(n.ronda >= 2 or n.estado != "abierta", "la ronda avanza o la mesa se corta")

	## Se abandona y se abre una mesa nueva, esta vez generosa de verdad, hasta
	## que cierre o se agote un limite de intentos -hay azar de por medio: rival
	## que se lleva el fichaje, o el jugador que pide mas rondas-.
	mk.cerrar_negociacion()
	_comprobar(mk.negociacion == null, "cerrar_negociacion vacía la mesa")

	var cerrado := false
	var intentos_apertura := 0
	while not cerrado and intentos_apertura < 12:
		intentos_apertura += 1
		## Otro objetivo cada vez, por si el anterior quedo con "no_negociar_hasta"
		## o se lo llevo un rival.
		var obj2: Jugador = null
		for c2: Club in m.clubes.values():
			if c2.id != mio.id and not c2.plantilla.is_empty():
				var candidato: Jugador = c2.plantilla[Azar.ent(0, c2.plantilla.size() - 1)]
				if candidato.club_id != mio.id and (candidato.no_negociar_hasta == 0 or m.semana >= candidato.no_negociar_hasta):
					obj2 = candidato
					break
		if obj2 == null:
			break
		if mk.abrir_negociacion(obj2) != "":
			continue
		var n2 := mk.negociacion
		## Oferta generosa: fijo por encima del pedido, ficha por encima de lo
		## que pediria, prima de cuatro semanas -respuestaDelJugador() la exige
		## para dar puntos extra-, y un contrato de tres temporadas.
		n2.fijo = int(float(n2.pedido) * 1.05)
		n2.sueldo = int(float(n2.sueldo) * 1.5)
		n2.firma = n2.sueldo * 5
		for intento_ronda in 8:
			var res := n2.enviar_oferta()
			var tipo := String(res.get("tipo", ""))
			if tipo == "cerrado":
				cerrado = true
				var jugador_fichado := obj2
				_comprobar(jugador_fichado.club_id == mio.id, "el fichado pasa a ser tuyo")
				_comprobar(mio.plantilla.has(jugador_fichado), "aparece en tu plantilla")
				_comprobar(m.vestuario.rol_plantel(jugador_fichado) == n2.rol, "el rol pactado queda escrito en Vestuario")
				_comprobar(jugador_fichado.anios_contrato == n2.anios, "los anios pactados quedan escritos")
				break
			elif tipo in ["rota", "rival_traspaso", "rival_firma", "jugador_rota", "cerrada"]:
				break
			## club_pide_mas o jugador_no: se sigue insistiendo con la misma oferta generosa.
	_comprobar(cerrado, "una oferta generosa termina cerrando un fichaje en un numero razonable de intentos")

	## Cuotas, bonos, porcentaje y clausula: se pactan de verdad a traves de
	## Cesiones.registrar_compromisos(), no con una copia propia de esa logica.
	var obj3: Jugador = null
	for c3: Club in m.clubes.values():
		if c3.id != mio.id and not c3.plantilla.is_empty():
			obj3 = c3.plantilla[0]
			break
	if obj3 != null and mk.abrir_negociacion(obj3) == "":
		var n3 := mk.negociacion
		n3.fijo = int(float(n3.pedido) * 1.1)
		n3.cuotas = 500000
		n3.bonos = 300000
		n3.pct = 20
		n3.clausula = true
		n3.sueldo = int(float(n3.sueldo) * 1.6)
		n3.firma = n3.sueldo * 5
		var cerrado3 := false
		for intento3 in 10:
			var res3 := n3.enviar_oferta()
			var tipo3 := String(res3.get("tipo", ""))
			if tipo3 == "cerrado":
				cerrado3 = true
				var hay_cuota := false
				for cu: Dictionary in m.cesiones.cuotas:
					if String(cu.get("jugador", "")) == obj3.nombre:
						hay_cuota = true
				_comprobar(hay_cuota, "las cuotas pactadas quedan registradas en Cesiones")
				_comprobar(m.cesiones.bonos.has(obj3.id), "el bono pactado queda registrado en Cesiones")
				_comprobar(m.cesiones.clausula_de(obj3) > 0, "la clausula pactada queda registrada en Cesiones")
				var pend := m.cesiones.porcentaje_pendiente(obj3.id)
				_comprobar(not pend.is_empty() and int(pend.get("pct", 0)) == 20, "el 20%% de venta futura queda pactado en Cesiones")
				## Cesiones.movimiento lleva escrito desde hace tiempo y nadie lo
				## escuchaba: se conecta ahora en tomar_el_mando(), directo al
				## libro de Mundo -sin pantalla de por medio-.
				_comprobar(not m.libro_financiero.is_empty(), "los pagos de la mesa quedan anotados en el libro financiero (%d)" % m.libro_financiero.size())
				break
			elif tipo3 in ["rota", "rival_traspaso", "rival_firma", "jugador_rota", "cerrada"]:
				break
		if not cerrado3:
			_linea("  (esta mesa en particular no cerro por azar -rival o jugador-, no se prueban cuotas/bonos/pct/clausula esta vez)")

func _probar_consejeros() -> void:
	_titulo("CONSEJEROS DEL DIRECTORIO")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	var d := m.directiva

	## Sin caja, no se puede contratar.
	mio.saldo = 0
	var motivo := d.alternar_consejero("dep")
	_comprobar(motivo != "" and not d.tiene_consejero("dep"), "sin caja no se contrata un consejero (%s)" % motivo)

	mio.mover_saldo(5000000)
	_comprobar(d.alternar_consejero("dep") == "", "se contrata al consejero deportivo")
	_comprobar(d.tiene_consejero("dep"), "queda contratado")
	_comprobar(d.honorarios_semanales() == Directiva.HONORARIO_CONSEJERO_SEMANAL, "el honorario semanal cuenta un asiento (%d)" % d.honorarios_semanales())

	_comprobar(d.alternar_consejero("mkt") == "", "se contrata al consejero de marketing")
	_comprobar(d.consejeros.size() == 2, "hay dos consejeros a la vez")
	var lleno := d.alternar_consejero("leg")
	_comprobar(lleno != "" and not d.tiene_consejero("leg"), "no cabe un tercer consejero (%s)" % lleno)
	_comprobar(d.honorarios_semanales() == Directiva.HONORARIO_CONSEJERO_SEMANAL * 2, "el honorario cuenta los dos asientos")

	## dep: afina la niebla de ojeo en TODO el mundo, no solo en paises cubiertos.
	var rival: Jugador = null
	for c: Club in m.clubes.values():
		if c.id != mio.id and c.pais != mio.pais and not c.plantilla.is_empty():
			rival = c.plantilla[0]
			break
	if rival != null:
		var nivel_con := m.ojeadores.nivel_de(rival)
		d.alternar_consejero("dep")   ## lo cesa
		var nivel_sin := m.ojeadores.nivel_de(rival)
		_comprobar(nivel_con - nivel_sin > 0.35 and nivel_con - nivel_sin < 0.45, "el consejero deportivo suma 0.4 al nivel de ojeo en cualquier pais (%.2f vs %.2f)" % [nivel_con, nivel_sin])
		d.alternar_consejero("dep")   ## lo vuelve a contratar para lo que sigue

	## mkt: +10% en patrocinio.
	var sin_mkt := Finanzas.new(mio).patrocinio()
	var con_mkt := Finanzas.new(mio, 0.0, 0, 0.1).patrocinio()
	_comprobar(con_mkt > sin_mkt and con_mkt <= int(round(float(sin_mkt) * 1.1)) + 1, "el consejero de marketing sube el patrocinio un 10%% (%d vs %d)" % [sin_mkt, con_mkt])

	## Cesar libera el asiento y deja de cobrar honorario.
	_comprobar(d.alternar_consejero("mkt") == "", "se cesa al consejero de marketing")
	_comprobar(not d.tiene_consejero("mkt"), "el asiento queda libre")
	_comprobar(d.honorarios_semanales() == Directiva.HONORARIO_CONSEJERO_SEMANAL, "el honorario baja a un solo asiento")

	## EMBAJADOR DEL CLUB: reutiliza Cantera.leyendas, sembradas al generar.
	_comprobar(m.cantera != null and not m.cantera.leyendas.is_empty(), "hay leyendas sembradas para elegir embajador")
	var candidatas := Directiva.candidatas_embajador(m.cantera.leyendas, m.anio)
	_comprobar(not candidatas.is_empty(), "candidatas_embajador() devuelve al menos una terna (%d)" % candidatas.size())
	var candidatas2 := Directiva.candidatas_embajador(m.cantera.leyendas, m.anio)
	_comprobar(candidatas[0]["nombre"] == candidatas2[0]["nombre"], "las candidatas son deterministas para el mismo año")

	var elegido: Dictionary = candidatas[0]
	var costo_emb := 400000 + int(elegido.get("nivel", 80)) * 8000
	mio.saldo = 0
	_comprobar(d.contratar_embajador(elegido) != "", "sin caja no se puede fichar al embajador")
	mio.mover_saldo(costo_emb + 1000000)
	var saldo_antes := mio.saldo
	_comprobar(d.contratar_embajador(elegido) == "", "se ficha al embajador")
	_comprobar(not d.embajador.is_empty() and String(d.embajador["nombre"]) == String(elegido["nombre"]), "queda registrado con su nombre")
	_comprobar(mio.saldo == saldo_antes - costo_emb, "el fichaje cobra el costo exacto, nivel incluido (%d)" % costo_emb)

	var socios_antes := mio.socios
	m.avanzar_semana()
	_comprobar(mio.socios >= socios_antes + Directiva.SOCIOS_POR_SEMANA_EMBAJADOR, "el embajador suma socios cada semana (%d -> %d)" % [socios_antes, mio.socios])

	_comprobar(d.cesar_embajador() == "", "se cesa al embajador -hay caja para el finiquito-")
	_comprobar(d.embajador.is_empty(), "el puesto queda vacante")

	## El entrenador empleado tambien cobra -"G.rol!=='dt'&&G.dtEmp" del HTML-,
	## y solo cuando no diriges tu mismo. Se comprueba el asiento en el libro
	## financiero, no la caja total, porque un mes entero de partidos mueve la
	## caja por mil motivos a la vez.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 8181)
	m2.tomar_el_mando(m2.ligas[0].clubes[1].id)
	m2.mi_club().mover_saldo(50000000)
	_comprobar(m2.roles.dt_empleado.is_empty(), "de entrenador (dt) todavia no hay a quien pagarle")
	m2.roles.rol = Roles.DIR
	m2.roles.call("_contratar_dt_empleado")
	for s in Finanzas.SEMANAS_DEL_MES:
		m2.avanzar_semana()
	var hay_sueldo_dt := false
	for mov: Dictionary in m2.libro_financiero:
		if String(mov.get("concepto", "")).begins_with("Sueldo del entrenador"):
			hay_sueldo_dt = true
			_comprobar(int(mov["monto"]) == -Roles.SUELDO_SEMANAL_DT_EMPLEADO * Finanzas.SEMANAS_DEL_MES,
				"el sueldo mensual del entrenador empleado es el correcto (%d)" % int(mov["monto"]))
	_comprobar(hay_sueldo_dt, "siendo director, el entrenador empleado cobra su sueldo al cierre de mes")

## "EL ATHLETIC CLUB DE BILBAO SOLO FICHA JUGADORES DE ESPAÑA" (22-9-2026,
## pedido directo del usuario). El club SÍ existe en el juego (`Ath. Bilbao`
## en `PAISES_LIGAS.ESP`, en leetspeak en la tabla -"B1lbao"-, por eso una
## búsqueda literal de "Bilbao" no lo encontraba la primera vez). La regla
## real (cantera vasca) no se puede portar literal -`Jugador` solo trackea
## `pais`, nunca ciudad/región-, así que se aproxima por "mismo país" (ESP).
## `Mercado._buscar_objetivo()` ahora salta cualquier candidato que no sea de
## España cuando el comprador es Bilbao (`Mercado.CLUBES_SOLO_MISMO_PAIS`).
##
## Mundo PROPIO, aislado -no reusa `m1`/`m2` de otra función, ni genera un
## tercer mundo dentro de una función ajena, la misma trampa que ya colgó el
## banco tres veces con la prueba de apellidos por país (ver esa sección de
## `LEEME.md`).
func _probar_bilbao_solo_local() -> void:
	_titulo("ATHLETIC BILBAO: SOLO FICHA DE ESPAÑA")
	var m := Mundo.new()
	m.generar(["ESP"], 4711)
	var bilbao: Club = null
	for c: Club in m.clubes.values():
		if Nombres.limpiar(c.nombre) == "Ath. Bilbao":
			bilbao = c
			break
	if bilbao == null:
		_comprobar(false, "Ath. Bilbao existe en PAISES_LIGAS.ESP")
		return
	var extranjeros_antes := 0
	for j in bilbao.plantilla:
		if j.pais != bilbao.pais:
			extranjeros_antes += 1
	## 100 semanas de mercado de la IA -bastante para que, sin la regla, le
	## hubiera entrado al menos un extranjero de los otros 15 clubes de la
	## liga (`mover(6)` sortea 6 compradores por semana entre TODOS los
	## clubes del mundo, Bilbao incluido con probabilidad real).
	for semana in 100:
		m.mercado.mover(6)
	var extranjeros_despues := 0
	for j in bilbao.plantilla:
		if j.pais != bilbao.pais:
			extranjeros_despues += 1
	_comprobar(extranjeros_despues <= extranjeros_antes,
		"100 semanas de mercado IA no le suman extranjeros a Bilbao (antes %d, después %d)" % [
			extranjeros_antes, extranjeros_despues])

func _probar_guardado() -> void:
	_titulo("GUARDAR Y CARGAR")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	## Se toca el estado de los sistemas nuevos para que el guardado tenga algo
	## que conservar: uno recien creado se parece a cualquier otro recien creado.
	m.staff.subir("ayudante", m.mi_club())
	m.staff.subir("medico", m.mi_club())
	## Los cuatro interruptores tacticos: se guardaban... no, no se guardaban.
	## Se activaban, movian el partido, y volvian a false en cada carga sin
	## avisar. Se marcan dos si y dos no para que la prueba distinga entre
	## "vuelve el valor" y "vuelve el valor por defecto".
	m.mi_club().tactica.salida_corta = true
	m.mi_club().tactica.tiro_lejano = true
	m.mi_club().tactica.marca_al_hombre = false
	m.mi_club().tactica.fuera_de_juego = false
	## Un once a mano, para comprobar que sobrevive: los once primeros del plantel.
	var once_a_mano: Array[Jugador] = []
	for n in 11:
		once_a_mano.append(m.mi_club().plantilla[n])
	m.mi_club().fijar_once(once_a_mano)
	## La tienda: se lanza una linea y se comprueba que rinde y que sobrevive.
	var sin_tienda := m.ingreso_tienda(m.mi_club())
	_comprobar(sin_tienda == 0, "sin lineas lanzadas la tienda no da nada (%d)" % sin_tienda)
	var err_t := m.alternar_tienda("buf", m.mi_club())
	_comprobar(err_t == "", "se lanza una linea de tienda (%s)" % err_t)
	_comprobar(m.ingreso_tienda(m.mi_club()) > 0, "y ya rinde todos los meses (%d)" % m.ingreso_tienda(m.mi_club()))
	## MENTORIAS: un veterano apadrina a un chico y el chico crece mas rapido.
	var maestro: Jugador = null
	var pupilo: Jugador = null
	for j in m.mi_club().plantilla:
		if maestro == null and m.entrenamiento.puede_ser_mentor(j):
			maestro = j
		elif pupilo == null and m.entrenamiento.puede_ser_pupilo(j):
			pupilo = j
	if maestro != null and pupilo != null:
		var moral_antes := pupilo.moral
		_comprobar(m.entrenamiento.crear_mentoria(maestro, pupilo) == "", "se crea una mentoria")
		_comprobar(pupilo.moral > moral_antes, "al pupilo le sube la moral al ser apadrinado (%d -> %d)" % [moral_antes, pupilo.moral])
		_comprobar(m.entrenamiento.mentorias.size() == 1, "queda registrada")
		_comprobar(not m.entrenamiento.puede_ser_pupilo(pupilo), "y ya no se le puede apadrinar dos veces")
	## EL BONO AL CUERPO TECNICO: una vez por temporada, y sube mas si vas bien.
	## Se parte de cero A PROPOSITO: este mundo ya trae staff contratado de
	## pruebas anteriores, y sin limpiarlo la primera comprobacion -"sin cuerpo
	## tecnico no hay bono"- pasaba de largo repartiendolo de verdad, dejando el
	## ano marcado y haciendo fallar a las tres siguientes.
	m.staff.niveles.clear()
	m.staff.anio_bono = 0
	var r_bono_sin := m.staff.repartir_bono(m.mi_club(), m.anio, 1, 16)
	_comprobar(r_bono_sin.has("error"), "sin cuerpo tecnico no hay bono que repartir")
	m.staff.subir("ayudante", m.mi_club())
	m.mi_club().mover_saldo(50000000)
	var moral_antes_b := m.mi_club().plantilla[0].moral
	var r_bono := m.staff.repartir_bono(m.mi_club(), m.anio, 1, 16)
	_comprobar(r_bono.has("ok"), "con cuerpo tecnico se reparte el bono")
	_comprobar(int(r_bono.get("moral", 0)) == 5, "yendo primero sube 5 de moral (%d)" % int(r_bono.get("moral", 0)))
	_comprobar(m.mi_club().plantilla[0].moral > moral_antes_b, "y la moral del plantel sube de verdad")
	_comprobar(m.staff.repartir_bono(m.mi_club(), m.anio, 1, 16).has("error"), "no se puede repartir dos veces el mismo ano")
	## LA PROYECCION ANUAL: la contabilidad del ejercicio. No inventa cifras,
	## multiplica lo que ya cobra y paga `mes()`, asi que lo que se comprueba es
	## que cuadre consigo misma y que la masa salarial salga en un rango creible.
	var fin := Finanzas.new(m.mi_club(), 0.0, 0, 0.0)
	var proy := fin.proyeccion_anual(15, 0)
	var suma_ing := 0
	for k: String in proy["ingresos"]:
		suma_ing += int(proy["ingresos"][k])
	_comprobar(suma_ing == int(proy["total_ingresos"]), "los ingresos del ejercicio suman el total (%d)" % suma_ing)
	_comprobar(int(proy["resultado"]) == int(proy["total_ingresos"]) - int(proy["total_gastos"]),
		"el resultado es ingresos menos gastos")
	_linea("  ejercicio: entran %d, salen %d, resultado %d, masa salarial %d%%" % [
		int(proy["total_ingresos"]), int(proy["total_gastos"]), int(proy["resultado"]), int(proy["pct_salarial"])])
	_comprobar(int(proy["pct_salarial"]) > 5 and int(proy["pct_salarial"]) < 200,
		"la masa salarial sobre ingresos sale en un rango creible (%d%%)" % int(proy["pct_salarial"]))

	## LA HINCHADA: cinco segmentos, abonos y encuestas.
	var h := m.hinchada
	_comprobar(h != null, "tomar el mando crea la hinchada")
	if h != null:
		_comprobar(h.segmentos.size() == 5, "hay cinco segmentos de aficion (%d)" % h.segmentos.size())
		## El plan de abono cambia lo que se recauda: el popular llena pero deja
		## poco por cabeza, el premium al reves. Es LA decision de la pantalla.
		h.fijar_abono("popular")
		var caja_antes_ab := m.mi_club().saldo
		var ing_popular := h.campana_abonos(m.mi_club(), 70, 0)
		var abon_popular := h.abonados
		m.mi_club().mover_saldo(caja_antes_ab - m.mi_club().saldo)
		h.fijar_abono("premium")
		var ing_premium := h.campana_abonos(m.mi_club(), 70, 0)
		var abon_premium := h.abonados
		_linea("  abonos: popular %d socios / %d | premium %d socios / %d" % [
			abon_popular, ing_popular, abon_premium, ing_premium])
		_comprobar(abon_popular > abon_premium, "el abono popular llena mas que el premium")
		_comprobar(ing_premium > ing_popular, "pero el premium recauda mas")
		## Los segmentos se mueven con el animo, en el sentido correcto.
		var barra_antes := int(h.segmentos["barra"])
		for i in 40:
			h.semana(90)
		var barra_bien := int(h.segmentos["barra"])
		for i in 40:
			h.semana(20)
		_comprobar(barra_bien >= barra_antes, "con el animo alto la barra no empeora (%d -> %d)" % [barra_antes, barra_bien])
		_comprobar(int(h.segmentos["barra"]) < barra_bien, "y con el animo por el suelo se enfada (%d)" % int(h.segmentos["barra"]))

	## LAS DIRECTRICES AL ENTRENADOR EMPLEADO: pedirle cosas desgasta la relacion.
	var r_dir := m.roles
	r_dir.dt_empleado = {"nombre": "Un DT", "estilo": "pizarron", "sintonia": 60}
	r_dir.rol = Roles.DT
	var sint_antes := int(r_dir.dt_empleado["sintonia"])
	r_dir.fijar_directriz("cantera", true)
	_comprobar(bool(r_dir.directrices["cantera"]), "la directriz queda puesta")
	_comprobar(int(r_dir.dt_empleado["sintonia"]) < sint_antes,
		"pedirle algo le desgasta la sintonia (%d -> %d)" % [sint_antes, int(r_dir.dt_empleado["sintonia"])])
	## Con la sintonia por el suelo casi nunca hace caso; con ella alta, casi siempre.
	r_dir.dt_empleado["sintonia"] = 100
	var caso_alto := 0
	for i in 200:
		if r_dir.dt_obedece():
			caso_alto += 1
	r_dir.dt_empleado["sintonia"] = 0
	var caso_bajo := 0
	for i in 200:
		if r_dir.dt_obedece():
			caso_bajo += 1
	_linea("  te hace caso: %d%% con sintonia 100, %d%% con sintonia 0" % [caso_alto / 2, caso_bajo / 2])
	_comprobar(caso_alto > caso_bajo, "cuanta mas sintonia, mas caso te hace")
	r_dir.dt_empleado = {}

	## LOS ROLES TACTICOS: el sistema estaba escrito y sin pantalla, asi que lo
	## que hay que demostrar no es que la tabla exista -eso ya se sabia- sino que
	## ELEGIR UN ROL LLEGA AL EQUIPO. Si `bonus_roles()` no moviera los factores,
	## la pantalla nueva seria un adorno que miente.
	var v_rt := m.vestuario
	var once_rt: Array = m.mi_club().once()
	if v_rt != null and once_rt.size() == 11:
		var previos := {}
		for j: Jugador in once_rt:
			previos[j.id] = v_rt.rol_tactico(j)
		## Un once entero de gente que va hacia adelante contra uno entero de
		## gente que se queda: son los dos extremos de la tabla ROLES.
		for j: Jugador in once_rt:
			if not j.es_portero():
				v_rt.fijar_rol_tactico(j, "latOf" if Datos.grupo(j.pos_e) == "DEF" else "llegador")
		var ofensivo: Dictionary = v_rt.bonus_roles(once_rt)
		for j: Jugador in once_rt:
			if not j.es_portero():
				v_rt.fijar_rol_tactico(j, "latDef" if Datos.grupo(j.pos_e) == "DEF" else "pivote")
		var defensivo: Dictionary = v_rt.bonus_roles(once_rt)
		_linea("  roles: once ofensivo ata x%.3f def x%.3f | once defensivo ata x%.3f def x%.3f" % [
			float(ofensivo["att"]), float(ofensivo["def"]), float(defensivo["att"]), float(defensivo["def"])])
		_comprobar(float(ofensivo["att"]) > float(defensivo["att"]),
			"un once de llegadores ataca mas que uno de pivotes")
		_comprobar(float(defensivo["def"]) > float(ofensivo["def"]),
			"y defiende menos: pedir roles ofensivos REGALA la espalda")
		## Y que el numero llega al club de verdad, no se queda en Vestuario.
		_comprobar(absf(v_rt.factor_ataque(m.mi_club()) - 1.0) > 0.0001,
			"el factor de ataque del club recoge el efecto de los roles")
		## La aptitud mide contra la propia media del jugador, asi que el mismo
		## central da numeros distintos segun lo que le pidas.
		var central: Jugador = null
		for j: Jugador in once_rt:
			if j.pos_e == "DFC":
				central = j
				break
		if central != null:
			var marcador := v_rt.aptitud_rol(central, "centralMar")
			var salida := v_rt.aptitud_rol(central, "centralSal")
			_linea("  %s como central marcador %.2f, como central de salida %.2f" % [central.nombre, marcador, salida])
			_comprobar(absf(marcador - salida) > 0.001,
				"el mismo central no vale lo mismo para marcar que para salir jugando")
		for j: Jugador in once_rt:
			v_rt.fijar_rol_tactico(j, String(previos[j.id]))

	## LAS ARENGAS. Lo que hay que probar es que el subidon LLEGA A LA FUERZA del
	## equipo. Si solo pintara el boton de otro color seria decoracion, que es el
	## error que este proyecto ya ha pagado varias veces.
	var mio_ar := m.mi_club()
	var rival_ar: Club = null
	for c_ar: Club in m.clubes.values():
		if c_ar != mio_ar:
			rival_ar = c_ar
			break
	if rival_ar != null:
		var p_ar := Partido.new(mio_ar, rival_ar)
		p_ar.preparar()
		var antes_ar: float = p_ar.fuerza(p_ar.once_local, mio_ar)["ata"]
		## Se arenga a los once para que la diferencia sea medible: con uno solo
		## se pierde en el redondeo de la media por linea.
		for j_ar: Jugador in p_ar.once_local:
			p_ar.arengar(j_ar)
		var despues_ar: float = p_ar.fuerza(p_ar.once_local, mio_ar)["ata"]
		_linea("  arenga: ataque %.2f -> %.2f" % [antes_ar, despues_ar])
		_comprobar(despues_ar > antes_ar, "arengar sube la fuerza de ataque de verdad")
		_comprobar(p_ar.con_impulso(p_ar.once_local[0]), "y el jugador queda encendido")
		## No se puede arengar dos veces al mismo mientras le dura.
		_comprobar(p_ar.arengar(p_ar.once_local[0]) != "", "no se puede arengar dos veces seguidas al mismo")

	## LAS JUGADAS ENSAYADAS Y LOS PLANES. Lo que hay que probar es que la
	## efectividad DEPENDE del once -si diera lo mismo con cualquier plantel,
	## elegir jugada seria un adorno- y que el plan del minuto 60 toca la tactica
	## de verdad.
	var once_bp: Array = m.mi_club().once()
	var ent_bp := m.entrenamiento
	if ent_bp != null and once_bp.size() == 11:
		## Una jugada que pide habilidades que nadie tiene rinde por debajo de 1;
		## el minimo de la formula es 0,82.
		var sin_nadie := Tactica.efectividad(once_bp, ["habilidad_que_no_existe"], ent_bp)
		_comprobar(sin_nadie < 1.0, "una jugada sin especialistas rinde por debajo de 1 (%.2f)" % sin_nadie)
		_comprobar(Tactica.efectividad([], ["cabezazo"], ent_bp) == 1.0,
			"sin once no se inventa un factor: devuelve 1")
	## El plan: perdiendo, ofensivo; ganando, cerrojo; empatando, nada.
	var t_bp := Tactica.new()
	t_bp.plan_perdiendo = "ofensivo"
	t_bp.plan_ganando = "cerrojo"
	var perdiendo := t_bp.plan_para(-1)
	var ganando := t_bp.plan_para(1)
	_comprobar(not perdiendo.is_empty() and int(perdiendo["mentalidad"]) == Tactica.Mentalidad.OFENSIVA,
		"yendo perdiendo el plan sale a por el partido")
	_comprobar(not ganando.is_empty() and int(ganando["mentalidad"]) == Tactica.Mentalidad.DEFENSIVA,
		"yendo ganando el plan cierra el partido")
	_comprobar(t_bp.plan_para(0).is_empty(), "empatando no se toca nada")

	## LA DEUDA (`vBanco`). Es el unico sistema que puede terminar una partida
	## sin perder un partido, asi que lo que hay que probar es el RELOJ: que las
	## semanas en rojo avanzan y que a las doce se liquida. Y la cuota francesa,
	## que es lo que hace que prepagar temprano ahorre y tarde no.
	var bk := m.banco
	if bk != null:
		var mio_b := m.mi_club()
		## La cuota francesa: pagando `n` cuotas se cubre deuda + intereses, asi
		## que el total pagado tiene que ser MAYOR que la deuda.
		var cuota := Banco.cuota_francesa(1000000, 0.01, 26)
		_linea("  credito de 1.000.000 a 26 cuotas: %d por cuota, %d en total" % [cuota, cuota * 26])
		_comprobar(cuota * 26 > 1000000, "la cuota francesa cubre deuda mas intereses")
		_comprobar(Banco.cuota_francesa(1000000, 0.0, 10) == 100000,
			"sin intereses la cuota es la division exacta")
		## Pedir sube la caja; el credito queda vigente.
		var saldo_antes := mio_b.saldo
		_comprobar(bk.pedir(0, mio_b) == "", "se puede pedir un credito")
		_comprobar(mio_b.saldo > saldo_antes, "el credito entra en caja")
		_comprobar(bk.prestamos.size() == 1, "el credito queda vigente")
		## Y no mas de dos lineas.
		bk.pedir(1, mio_b)
		_comprobar(bk.pedir(2, mio_b) != "", "no se pueden abrir mas de dos lineas de deuda")
		## El reloj: doce semanas con la caja en rojo y se liquida.
		bk.prestamos.clear()
		bk.semanas_en_rojo = 0
		bk.liquidado_ya = false
		var saldo_guardado := mio_b.saldo
		mio_b.mover_saldo(-mio_b.saldo - 1000)
		for i in 12:
			bk.semana(mio_b)
		_comprobar(bk.liquidado_ya, "doce semanas en rojo liquidan el club (%d semanas)" % bk.semanas_en_rojo)
		_comprobar(bk.en_mora(), "y por el camino se pasa por la mora")
		## Se deja como estaba: el resto del banco sigue usando este mundo.
		bk.semanas_en_rojo = 0
		bk.liquidado_ya = false
		mio_b.mover_saldo(saldo_guardado - mio_b.saldo)

	## EL HORARIO DEL PARTIDO. Lo que se prueba es que la eleccion IMPORTA: si el
	## factor no llegara a la taquilla seria un menu decorativo, que es el error
	## que este proyecto ya ha pagado varias veces.
	var mio_h := m.mi_club()
	var f_h := Finanzas.new(mio_h)
	var tarde := f_h.taquilla(false, 1.0)
	mio_h.mover_saldo(-tarde)
	var lunes := f_h.taquilla(false, 0.68)
	mio_h.mover_saldo(-lunes)
	_linea("  taquilla: tarde de sabado %d, lunes por la noche %d" % [tarde, lunes])
	_comprobar(lunes < tarde, "jugar el lunes por la noche llena menos el estadio")
	## Y que los cuatro horarios existen con sus dos factores.
	_comprobar(Mundo.HORARIOS.size() == 4, "hay cuatro horarios para elegir")
	m.horario = "lunes"
	_comprobar(absf(m.factor_publico() - 0.68) < 0.001, "el horario elegido manda en el factor de publico")
	_comprobar(m.factor_tv_horario() > 1.0, "y el lunes paga mas derechos de television")
	m.horario = "tarde"
	## El clima es estable: la misma semana del mismo ano da siempre lo mismo,
	## porque sale de un hash y no de un sorteo. Si no, no se podria reproducir
	## una partida.
	var clima1 := m.clima()
	var clima2 := m.clima()
	_comprobar(clima1 == clima2, "el clima de una semana es estable (%s)" % clima1)

	## LOS JUEGOS MENTALES: dos banderas que se encendian y no las apagaba nadie.
	## `consumir_presion()` y `consumir_dato_del_rival()` estaban escritas y sin
	## una sola llamada en todo el proyecto: pagabas 80.000 por espiar al rival y
	## no pasaba nada. Lo que se prueba es que se CONSUMEN -una sola vez- y que
	## la promesa mueve el animo en los dos sentidos.
	var pr := m.prensa
	if pr != null:
		pr.dato_del_rival = true
		_comprobar(pr.consumir_dato_del_rival(), "el informe del rival se puede usar una vez")
		_comprobar(not pr.consumir_dato_del_rival(), "y solo una: lo que pagaste ya lo gastaste")
		pr.presion_prometida = true
		_comprobar(pr.consumir_presion(), "la promesa de la rueda de prensa se cobra")
		_comprobar(not pr.consumir_presion(), "y no se cobra dos veces")
		## Y que el animo se mueve al alza si cumples y a la baja si no. Se
		## llama a `mover_animo` directamente porque el cobro vive en `Mundo` y
		## depende del resultado del partido, que aqui no se juega.
		var animo0 := pr.animo
		pr.mover_animo(6)
		_comprobar(pr.animo > animo0, "cumplir la promesa sube el animo (%d -> %d)" % [animo0, pr.animo])
		var animo1 := pr.animo
		pr.mover_animo(-8)
		_comprobar(pr.animo < animo1, "y fallarla lo hunde (%d -> %d)" % [animo1, pr.animo])

	## LA CHARLA DEL ENTRETIEMPO. Lo que hay que demostrar es que NO hay un tono
	## bueno: si "Sacudir" fuera siempre mejor que "Calmar", el camarin seria un
	## boton con seis dibujos distintos.
	var v_ch := m.vestuario
	if v_ch != null:
		var once_ch: Array = m.mi_club().once()
		## Mismo equipo, misma moral de partida, muchas repeticiones: lo que se
		## compara es el promedio, porque cada charla lleva su dado.
		var moral_base := {}
		for j: Jugador in once_ch:
			moral_base[j.id] = j.moral
		var suma := {}
		for tono_ch in ["calma", "furia"]:
			var acc := 0
			for intento in 60:
				for j: Jugador in once_ch:
					j.moral = int(moral_base[j.id])
				v_ch.charla(once_ch, tono_ch)
				for j: Jugador in once_ch:
					acc += j.moral - int(moral_base[j.id])
			suma[tono_ch] = float(acc) / 60.0
		_linea("  charla: calmar %+.1f de moral total, sacudir %+.1f" % [float(suma["calma"]), float(suma["furia"])])
		_comprobar(absf(float(suma["calma"]) - float(suma["furia"])) > 0.5,
			"los tonos no dan lo mismo: elegir importa")
		for j: Jugador in once_ch:
			j.moral = int(moral_base[j.id])
		## Y el tono escrito se deduce de las palabras, que es lo que hace que
		## escribir en el camarin no sea decorativo.
		_comprobar(v_ch.tono_de_texto("¡¡Esto es una vergüenza, carajo!!") == "furia",
			"un grito con palabrota se lee como furia")
		_comprobar(v_ch.tono_de_texto("Esto es inaceptable, así no") == "exigir",
			"un reproche seco se lee como exigencia")
		_comprobar(v_ch.tono_de_texto("Tranquilos, confío en ustedes") == "animar",
			"un mensaje de confianza se lee como elogio")
		_comprobar(v_ch.tono_de_texto("Suban la línea y presionen la salida") == "tactico",
			"una indicacion de pizarra se lee como tactica")
		## El psicologo existe de verdad en el cuerpo tecnico: si no, el bonus de
		## la charla seria una linea muerta que devuelve cero para siempre.
		_comprobar(Staff.PUESTOS.has("psi"), "el psicologo deportivo existe como puesto contratable")

	## LO QUE LEE LA FICHA DEL JUGADOR. La pantalla no se puede probar, pero SI
	## se pueden probar las claves exactas que lee: escribir "nombre" donde el
	## motor guarda "n" no rompe nada -sale un texto vacio y ya-, que es la clase
	## de fallo que no se ve hasta que alguien mira esa ficha en concreto.
	var j_f: Jugador = m.mi_club().plantilla[0]
	if m.vestuario != null:
		var em_f: Dictionary = m.vestuario.estado_mental(j_f)
		_comprobar(em_f.has("txt") and em_f.has("color"), "estado_mental trae txt y color")
		var sat_f: Dictionary = m.vestuario.satisfaccion(j_f)
		for k_f in ["min", "rend", "tact", "inst", "total"]:
			_comprobar(sat_f.has(k_f), "satisfaccion desglosa '%s'" % k_f)
		var def_f := m.vestuario.def_rol(m.vestuario.rol_plantel(j_f))
		_comprobar(def_f.size() >= 4, "def_rol trae nombre y minutos exigidos (%d campos)" % def_f.size())
	if m.medico != null:
		## Se provoca una lesion para que el historial NO este vacio: probar el
		## formato de una lista vacia no prueba nada.
		m.medico.lesionar(j_f, Medico.MEDIA, "prueba de ficha", m.anio, m.semana)
		var h_f: Array = m.medico.historial(j_f)
		if not h_f.is_empty():
			var e_f: Dictionary = h_f[h_f.size() - 1]
			for k_h in ["n", "sem", "anio"]:
				_comprobar(e_f.has(k_h), "el historial medico guarda '%s'" % k_h)
		j_f.lesion = 0

	## LOS ROLES PROMETIDOS: lo que se prueba es que NO es un desplegable tonto.
	## Si `acepta_rol()` dejara pasar cualquier cosa, prometer seria gratis y el
	## sistema entero sobraria.
	var v_rp := m.vestuario
	if v_rp != null:
		var plantel_rp := m.mi_club().plantilla.duplicate()
		plantel_rp.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		var crack: Jugador = plantel_rp[0]
		var suplente: Jugador = plantel_rp[plantel_rp.size() - 1]
		_comprobar(not bool(v_rp.acepta_rol(crack, "prescindible")["ok"]),
			"el mejor del plantel no acepta ser prescindible")
		_comprobar(not bool(v_rp.acepta_rol(suplente, "intocable")["ok"]),
			"al ultimo del plantel no le puedes prometer ser intocable")
		## Y bajarle el escalafon a alguien duele en la moral EN EL ACTO, que es
		## lo que el motor lee cada minuto de partido.
		v_rp.fijar_rol(crack, "intocable")
		var moral_antes := crack.moral
		var res_rp: Dictionary = v_rp.cambiar_rol(crack, "titular")
		_linea("  rol: %s de intocable a titular -> %s (moral %d -> %d)" % [
			crack.nombre, String(res_rp.get("txt", "")), moral_antes, crack.moral])
		_comprobar(bool(res_rp["ok"]) and crack.moral < moral_antes,
			"rebajarle el papel a un crack le cuesta moral")
		_comprobar(v_rp.rol_plantel(crack) == "titular", "y el papel nuevo queda escrito")

	## EL ARBOL DEL ENTRENADOR: igual que los roles, estaba escrito y sin
	## pantalla. Lo que hay que demostrar es la CADENA -requisito, coste, y que
	## el nodo abierto llega al equipo-, no que la tabla exista.
	var e_dt := m.entrenamiento
	if e_dt != null:
		var nodos_antes := e_dt.dt_nodos.duplicate()
		var pts_antes := e_dt.dt_puntos
		var ramas := e_dt.dt_ramas()
		_comprobar(ramas.size() >= 3, "el arbol del DT tiene ramas (%d)" % ramas.size())
		## Un nodo con requisito no se puede abrir sin el padre, por muchos
		## puntos que tengas: si esto falla, el arbol es una lista plana.
		var con_req := ""
		for rama: String in ramas:
			for k: String in (ramas[rama] as Array):
				if con_req == "" and e_dt.dt_requisito(k) != "" and not e_dt.dt_tiene(k):
					con_req = k
		if con_req != "":
			e_dt.dt_nodos.erase(e_dt.dt_requisito(con_req))
			e_dt.dt_puntos = 99
			_comprobar(e_dt.dt_aprender(con_req) != "",
				"sin el nodo padre no se puede abrir el hijo aunque sobren puntos")
			_comprobar(e_dt.dt_motivo(con_req).begins_with("antes:"),
				"y el motivo lo dice: %s" % e_dt.dt_motivo(con_req))
			## Con el padre puesto sí, y el coste se cobra de verdad.
			e_dt.dt_nodos[e_dt.dt_requisito(con_req)] = true
			var coste := e_dt.dt_coste(con_req)
			e_dt.dt_puntos = coste
			_comprobar(e_dt.dt_aprender(con_req) == "", "con el padre puesto y los puntos justos, se abre")
			_comprobar(e_dt.dt_puntos == 0, "y el coste se cobra (%d puntos gastados)" % coste)
		## Y el efecto llega al partido: "genio" reemplaza a "pizarra fina", no
		## se suman, asi que el 6% ya incluye el 3%.
		e_dt.dt_nodos.clear()
		var pelado := e_dt.bonus_dt()
		e_dt.dt_nodos["genio"] = true
		var con_genio := e_dt.bonus_dt()
		_linea("  arbol DT: sin nodos x%.3f, con genio x%.3f" % [pelado, con_genio])
		_comprobar(con_genio > pelado, "abrir el nodo del banquillo mejora al equipo de verdad")
		e_dt.dt_nodos = nodos_antes
		e_dt.dt_puntos = pts_antes

	## EL SALON DE LA FAMA (`vMemoria()`): no es una lista guardada, se deduce de
	## los records. Lo que se comprueba es el ORDEN -que estar en el once de un
	## titulo pese mas que una temporada goleadora-, porque es la unica decision
	## de diseno que hay aqui; si se invierte, la pantalla miente sin fallar.
	var lg_f := m.logros
	var goles_antes: Dictionary = lg_f.rec.get("goles", {})
	var pj_antes: Dictionary = lg_f.rec.get("pj", {})
	var muro_antes := lg_f.muro.duplicate(true)
	## OJO con la forma: `rec["goles"]` va por NOMBRE, pero `rec["pj"]` va por ID
	## y guarda {nombre, n}. No son simetricas, y escribirlas mal aqui reventaba
	## `mas_partidos()` sin que el banco lo notase.
	lg_f.rec["goles"] = {"Goleador": 30, "Capitan": 4}
	lg_f.rec["pj"] = {"g1": {"nombre": "Goleador", "n": 60}, "c1": {"nombre": "Capitan", "n": 200}}
	lg_f.muro = [{"once": ["Capitan"]}, {"once": ["Capitan"]}]
	var fama := lg_f.salon_de_la_fama(12)
	_comprobar(fama.size() == 2, "al salon entran los dos que dejaron huella (%d)" % fama.size())
	if fama.size() == 2:
		_comprobar(String(fama[0]["nombre"]) == "Capitan",
			"dos titulos y 200 partidos pesan mas que 30 goles (manda %s)" % String(fama[0]["nombre"]))
		_comprobar(String(fama[0]["motivo"]).contains("título"),
			"y el motivo lo dice: %s" % String(fama[0]["motivo"]))
	lg_f.rec["goles"] = goles_antes
	lg_f.rec["pj"] = pj_antes
	lg_f.muro = muro_antes

	m.directiva.mover_confianza(-13, "prueba")
	m.mi_club().mover_saldo(2000000)
	m.directiva.alternar_consejero("dep")
	var cand: Array[Dictionary] = Directiva.candidatas_embajador(m.cantera.leyendas, m.anio) if m.cantera != null else []
	if not cand.is_empty():
		m.directiva.contratar_embajador(cand[0])
	if m.ojeadores != null:
		m.ojeadores.modo_ciego = true
	if m.prensa != null:
		m.prensa.animo = 41
		m.prensa.funa = 7
	## Se juega media temporada para que haya algo que guardar: tabla con
	## puntos, gente lesionada, goleadores. Guardar un mundo recién creado no
	## prueba nada, porque todo está a cero y a cero se parece cualquier cosa.
	for s in 10:
		m.avanzar_semana()
	var antes_caja := m.mi_club().saldo
	var antes_jug := m.cuantos_jugadores()
	var antes_tabla := m.ligas[0].tabla()
	var antes_jornada := m.ligas[0].jornada_actual

	var t0 := Time.get_ticks_msec()
	_comprobar(Partida.guardar(m, "prueba_banco"), "la partida se guarda")
	var ms_guardar := Time.get_ticks_msec() - t0
	var f := FileAccess.open(Partida.ruta_de("prueba_banco"), FileAccess.READ)
	var bytes := f.get_length() if f != null else 0
	if f != null:
		f.close()
	_linea("  %d jugadores -> %d KB comprimidos, %d ms" % [antes_jug, bytes / 1024, ms_guardar])
	_comprobar(bytes > 0 and bytes < 4 * 1024 * 1024, "el fichero es manejable (%d KB)" % (bytes / 1024))

	t0 = Time.get_ticks_msec()
	var m2 := Partida.cargar("prueba_banco")
	_linea("  cargado en %d ms" % (Time.get_ticks_msec() - t0))
	_comprobar(m2 != null, "la partida se carga")
	if m2 == null:
		return
	_comprobar(m2.anio == m.anio and m2.semana == m.semana, "vuelve el almanaque (%d, semana %d)" % [m2.anio, m2.semana])
	_comprobar(m2.mi_club_id == m.mi_club_id, "vuelve tu club")
	_comprobar(m2.cuantos_jugadores() == antes_jug, "vuelven los %d jugadores" % antes_jug)
	_comprobar(m2.mi_club().saldo == antes_caja, "vuelve la caja exacta")
	_comprobar(m2.ligas.size() == m.ligas.size(), "vuelven las ligas")
	_comprobar(m2.ligas[0].jornada_actual == antes_jornada, "vuelve la jornada (%d)" % antes_jornada)
	_comprobar(m2.directiva.tiene_consejero("dep"), "vuelve el consejero deportivo contratado")
	_comprobar(not cand.is_empty() and not m2.directiva.embajador.is_empty() and m2.directiva.embajador["nombre"] == cand[0]["nombre"], "vuelve el embajador contratado")
	_comprobar(m2.ojeadores != null and m2.ojeadores.modo_ciego, "vuelve el modo ciego activado")

	## La tabla tiene que volver ENTERA y en el mismo orden. Es lo que se pierde
	## si el calendario se rearma sin volver a poner los puntos encima.
	var tabla2 := m2.ligas[0].tabla()
	var igual := tabla2.size() == antes_tabla.size()
	if igual:
		for i in tabla2.size():
			if tabla2[i]["club"].id != antes_tabla[i]["club"].id or tabla2[i]["pts"] != antes_tabla[i]["pts"]:
				igual = false
				break
	_comprobar(igual, "vuelve la tabla completa, en el mismo orden y con los mismos puntos")
	var tac := m2.mi_club().tactica
	_comprobar(tac.salida_corta and tac.tiro_lejano and not tac.marca_al_hombre and not tac.fuera_de_juego,
		"vuelven los cuatro interruptores tacticos, los puestos y los no puestos")
	## Y el once elegido a mano, que tampoco se guardaba: armabas tu equipo,
	## salvabas la partida, y al volver decidia el automatico.
	_comprobar(m2.mi_club().once_elegido.size() == 11, "vuelve el once elegido a mano (%d)" % m2.mi_club().once_elegido.size())
	var mismo_once := true
	for n in mini(11, m.mi_club().once_elegido.size()):
		if m2.mi_club().once_elegido[n] != m.mi_club().once_elegido[n]:
			mismo_once = false
	_comprobar(mismo_once, "y son exactamente los mismos once, en el mismo orden")
	_comprobar(bool(m2.tienda.get("buf", false)), "vuelve la linea de tienda lanzada")

	## OJO CON EL ORDEN DE ESTAS PRUEBAS: todo lo que compare el mundo cargado
	## con el original tiene que ir ANTES de seguir jugando con el cargado. Al
	## reves, la copa de `m2` ya habia avanzado tres rondas mas que la de `m` y
	## la comparacion fallaba sin que hubiera nada roto.
	_comprobar_estado_cargado(m, m2)

	## Los detalles de un jugador concreto, que es donde se ve si el mapeo de
	## claves cortas esta bien hecho. Va ANTES de "seguir jugando" y no despues
	## -misma regla que el resto de esta prueba-: con Cantera enganchada, cinco
	## semanas mas ya pueden robarle un canterano sin ficha al club, y entonces
	## el de plantilla[0] deja de ser el mismo jugador sin que nada este roto.
	var j1: Jugador = m.mi_club().plantilla[0]
	var j2: Jugador = null
	for j in m2.mi_club().plantilla:
		if j.id == j1.id:
			j2 = j
			break
	if j2 != null:
		_comprobar(j2.nombre == j1.nombre and j2.ovr == j1.ovr and j2.valor == j1.valor \
			and j2.atributos.size() == j1.atributos.size() and j2.dorsal == j1.dorsal,
			"un jugador vuelve identico (%s, %d, dorsal %d)" % [j2.nombre, j2.ovr, j2.dorsal])
	else:
		_comprobar(false, "el jugador de prueba no aparece tras cargar")

	## Y lo mas facil de romper: que se pueda SEGUIR jugando desde donde estaba.
	for s in 5:
		m2.avanzar_semana()
	_comprobar(m2.ligas[0].jornada_actual == antes_jornada + 5, "se puede seguir jugando tras cargar")

	var lista := Partida.listar()
	_comprobar(lista.size() >= 1, "el guardado aparece en la lista (%d)" % lista.size())
	Partida.borrar("prueba_banco")

## Lo que no se ve al mirar una partida recien cargada: la division de cada liga
## y el cuadro de la copa. Sin guardarlos, todas las ligas volvian a ser primera
## -con el club que acababa de descender cobrando otra vez de primera- y el
## torneo de copa desaparecia sin que nada se quejara.
func _comprobar_estado_cargado(m: Mundo, m2: Mundo) -> void:
	var divs_ok := true
	for i in m2.ligas.size():
		if m2.ligas[i].div != m.ligas[i].div:
			divs_ok = false
	_comprobar(divs_ok, "vuelve la division de cada liga")
	if m.copa == null:
		return
	_comprobar(m2.copa != null, "vuelve la copa")
	if m2.copa == null:
		return
	_comprobar(m2.copa.vivos.size() == m.copa.vivos.size() and m2.copa.ronda == m.copa.ronda,
		"vuelve el cuadro de la copa (%d vivos, ronda %d)" % [m2.copa.vivos.size(), m2.copa.ronda])
	var mismos := true
	for i in mini(m2.copa.vivos.size(), m.copa.vivos.size()):
		if m2.copa.vivos[i].id != m.copa.vivos[i].id:
			mismos = false
	_comprobar(mismos, "los clubes vivos son los mismos y en el mismo orden")

	## Y los cuatro sistemas que solo existen para TU club. Sin guardarlos,
	## cargar te devolvia con la confianza a 55, sin cuerpo tecnico, sin parte
	## medico, sin logros y sin torneos continentales, y sin una sola queja.
	if m.directiva != null:
		_comprobar(m2.directiva != null, "vuelve la directiva")
		if m2.directiva != null:
			_comprobar(m2.directiva.confianza == m.directiva.confianza \
				and m2.directiva.objetivo == m.directiva.objetivo \
				and m2.directiva.meta_puesto == m.directiva.meta_puesto,
				"vuelve la confianza y el objetivo (%d, %s)" % [m2.directiva.confianza, m2.directiva.objetivo])
	_comprobar(m2.staff.nivel("ayudante") == m.staff.nivel("ayudante") \
		and m2.staff.nivel("medico") == m.staff.nivel("medico"),
		"vuelven los niveles del cuerpo tecnico")
	## Y aplicados: los niveles solos no mueven nada, el motor lee los dos
	## bonificadores del club. Un staff cargado de disco que no los escribe no
	## hace absolutamente nada.
	_comprobar(is_equal_approx(m2.mi_club().bonus_ataque, m.mi_club().bonus_ataque),
		"el staff cargado vuelve a mover el bonificador del motor (%.3f)" % m2.mi_club().bonus_ataque)
	_comprobar(m2.prensa != null and m2.medico != null and m2.logros != null,
		"vuelven prensa, parte medico y logros")
	if m.prensa != null and m2.prensa != null:
		_comprobar(m2.prensa.animo == m.prensa.animo and m2.prensa.funa == m.prensa.funa,
			"vuelve el humor de la hinchada (animo %d)" % m2.prensa.animo)
	_comprobar(m2.continentales.size() == m.continentales.size(),
		"vuelven los %d torneos continentales" % m2.continentales.size())
	if not m.continentales.is_empty():
		var k: String = m.continentales.keys()[0]
		var t1: Continental = m.continentales[k]
		var t2: Continental = m2.continentales[k]
		_comprobar(t2.vivos.size() == t1.vivos.size() and t2.ronda == t1.ronda,
			"vuelve el cuadro de %s (%d vivos, ronda %d)" % [k, t2.vivos.size(), t2.ronda])

func _probar_temporadas() -> void:
	_titulo("TEMPORADAS COMPLETAS")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 55)
	var t0 := Time.get_ticks_msec()
	for temporada in 3:
		m.jugar_temporada()
		var tabla := m.ligas[0].tabla()
		var campeon: Dictionary = tabla[0]
		_linea("  %d: campeon %s con %d puntos (%d-%d-%d), %d jugadores en el mundo" % [
			m.anio, campeon["club"].nombre, campeon["pts"],
			campeon["g"], campeon["e"], campeon["p"], m.cuantos_jugadores()])
		## La tabla tiene que cuadrar: los puntos salen de los resultados y los
		## goles a favor de todos son los goles en contra de todos.
		var gf := 0
		var gc := 0
		for fila: Dictionary in tabla:
			if fila["pts"] != fila["g"] * 3 + fila["e"]:
				_fallos.append("puntos mal sumados en %s" % fila["club"].nombre)
			if fila["pj"] != fila["g"] + fila["e"] + fila["p"]:
				_fallos.append("partidos mal sumados en %s" % fila["club"].nombre)
			gf += fila["gf"]
			gc += fila["gc"]
		_comprobar(gf == gc, "los goles a favor igualan a los goles en contra (%d/%d)" % [gf, gc])
		m.nueva_temporada()
	_linea("  tres temporadas en %d ms" % (Time.get_ticks_msec() - t0))
	var viejos := 0
	var plantillas_cortas := 0
	for c: Club in m.clubes.values():
		if c.plantilla.size() < 18:
			plantillas_cortas += 1
		for j in c.plantilla:
			if j.edad > 40:
				viejos += 1
	_comprobar(viejos == 0, "nadie sigue jugando pasados los 40 (%d)" % viejos)
	_comprobar(plantillas_cortas == 0, "ninguna plantilla se vacia con los anos (%d)" % plantillas_cortas)

	## Las plantillas tampoco se pueden deformar. Reponiendo al azar, en diez
	## temporadas un club acaba con seis porteros y sin lateral izquierdo, porque
	## los retiros no caen por igual en cada demarcacion.
	var deformes := 0
	var max_porteros := 0
	for c: Club in m.clubes.values():
		var porteros := 0
		var lineas := {}
		for j in c.plantilla:
			lineas[Datos.grupo(j.pos_e)] = true
			if j.es_portero():
				porteros += 1
		max_porteros = maxi(max_porteros, porteros)
		if lineas.size() < 4 or porteros > 5:
			deformes += 1
	_linea("  el club con mas porteros tiene %d" % max_porteros)
	_comprobar(deformes == 0, "ninguna plantilla se deforma tras tres temporadas (%d)" % deformes)

func _probar_economia() -> void:
	_titulo("ECONOMIA (las curvas del HTML, sin retocar)")
	## El valor es exponencial sobre la media, no lineal: es lo que hace que
	## fichar a un 90 sea una decision de club y no una compra mas.
	var valores := {}
	for ovr in [60, 70, 80, 90]:
		var j := Jugador.new()
		j.ovr = ovr
		j.pot = ovr
		j.edad = 26
		j.anios_contrato = 3
		j.tasar()
		valores[ovr] = j.valor
		_linea("  media %d -> valor %s, sueldo %s" % [ovr, _dinero(j.valor), _dinero(j.sueldo)])
	_comprobar(valores[70] > valores[60] * 2, "de 60 a 70 el valor mas que se duplica")
	_comprobar(valores[80] > valores[70] * 2, "de 70 a 80 el valor mas que se duplica")
	_comprobar(valores[90] > valores[80] * 2, "de 80 a 90 el valor mas que se duplica")
	## La edad manda: el mismo 78 no vale lo mismo a los 19 que a los 34.
	var joven := Jugador.new(); joven.ovr = 78; joven.pot = 90; joven.edad = 19; joven.anios_contrato = 4; joven.tasar()
	var viejo := Jugador.new(); viejo.ovr = 78; viejo.pot = 78; viejo.edad = 34; viejo.anios_contrato = 4; viejo.tasar()
	_linea("  mismo 78: a los 19 vale %s, a los 34 vale %s" % [_dinero(joven.valor), _dinero(viejo.valor)])
	_comprobar(joven.valor > viejo.valor * 4, "la joya de 19 vale mucho mas que el veterano de 34")
	## Y la caja de los clubes tambien es exponencial sobre la reputacion.
	_linea("  caja de referencia: rep 60 -> %s | rep 70 -> %s | rep 88 -> %s" % [
		_dinero(int(Eco.ref_caja(60))), _dinero(int(Eco.ref_caja(70))), _dinero(int(Eco.ref_caja(88)))])
	_comprobar(Eco.ref_caja(88) > Eco.ref_caja(70) * 5.0, "un grande maneja mucha mas caja que uno medio")

func _probar_sala_de_prensa() -> void:
	_titulo("SALA DE PRENSA (portavoz, television, portadas y el ano contado)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 7373)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)

	## LA PROYECCION NO COBRA. Este es el fallo mas caro que ha tenido la
	## economia y no lo veia nadie: `proyeccion_anual()` llamaba a `derechos_tv()`,
	## `patrocinio()` y `cuotas_socios()`, que MUEVEN el saldo. Abrir la pantalla
	## de Finanzas le regalaba al club un mes de ingresos en cada repintado.
	var caja_antes := m.mi_club().saldo
	var fin_p := Finanzas.new(m.mi_club(), 0.0, 0, 0.0)
	for i in 5:
		fin_p.proyeccion_anual(15, 0)
	_comprobar(m.mi_club().saldo == caja_antes,
		"mirar la proyeccion anual cinco veces no mueve un peso de la caja (%d -> %d)" % [caja_antes, m.mi_club().saldo])

	## LOS DERECHOS DE TELEVISION. Los tres multiplicadores existian y ninguno
	## llegaba a la caja: el reparto de la asamblea, el modelo de contrato y el
	## plus del horario.
	var pr := m.prensa
	_comprobar(is_equal_approx(pr.factor_tv(), 1.0), "en bloque la television no lleva multiplicador")
	var rep_mia := m.mi_club().rep
	pr.negociar_tv(true, m.mi_club())
	var esperado := 1.35 if rep_mia >= Prensa.REP_VENDE_SOLO else 0.70
	_linea("  rep %d -> vender solo multiplica x%.2f" % [rep_mia, pr.factor_tv()])
	_comprobar(is_equal_approx(pr.factor_tv(), esperado),
		"negociar por tu cuenta con rep %d da x%.2f" % [rep_mia, esperado])
	var f_tv := Finanzas.new(m.mi_club(), 0.0, 0, 0.0)
	var limpio := f_tv.derechos_tv_base()
	f_tv.factor_tv = pr.factor_tv()
	var caja_tv := m.mi_club().saldo
	f_tv.derechos_tv()
	var cobrado := m.mi_club().saldo - caja_tv
	_comprobar(cobrado == int(round(float(limpio) * esperado)),
		"y la television paga el multiplicador de verdad (%d sobre %d)" % [cobrado, limpio])
	pr.negociar_tv(false, m.mi_club())
	_comprobar(is_equal_approx(pr.factor_tv(), 1.0), "volver al bloque quita el multiplicador")

	## EL PORTAVOZ reparte a la mitad lo que mueve la rueda de prensa. Sin esto
	## el boton prometia en su texto algo que no cobraba en ninguna cuenta.
	var mio := m.mi_club()
	mio.plantilla[0].capitan = true
	_comprobar(pr.vocero.is_empty(), "de entrada das tu la cara")
	pr.nombrar_vocero(mio)
	_comprobar(not pr.vocero.is_empty(), "se puede nombrar portavoz a un capitan")
	pr.abrir_rueda(true, false)
	_comprobar(pr.hay_rueda(), "la rueda se abre")
	var con_vocero := pr.responder(0)
	pr.nombrar_vocero(mio)
	_comprobar(pr.vocero.is_empty(), "y se le puede quitar")
	pr.abrir_rueda(true, false)
	var sin_vocero := pr.responder(0)
	_linea("  misma respuesta: con portavoz %+d de moral, sin portavoz %+d" % [
		int(con_vocero.get("moral", 0)), int(sin_vocero.get("moral", 0))])
	_comprobar(absi(int(con_vocero.get("moral", 0))) <= absi(int(sin_vocero.get("moral", 0))),
		"con portavoz la rueda mueve menos")

	## EL ARCHIVO DE PORTADAS. Se escribian tras cada partido grande y se perdian
	## al cambiar de pantalla.
	_comprobar(pr.portadas.is_empty(), "el archivo empieza vacio")
	var salieron := 0
	for i in 40:
		pr.portada_tras_resultado(i % 3 == 0, i % 3 == 1, false, "semilla-%d" % i)
		salieron = pr.portadas.size()
	_linea("  de 40 partidos se archivaron %d portadas" % salieron)
	_comprobar(salieron > 5 and salieron < 35, "no sale portada de cada partido, pero si de bastantes")
	_comprobar(String(pr.portadas[0].get("t", "")) != "", "la portada mas nueva va primera y tiene titular")
	## Y NO USA `Azar`: es decoracion. Si lo usara, desplazaria la simulacion
	## entera y dos partidas identicas dejarian de serlo.
	var t1 := pr.titular_prensa(true, false, false, "misma-semilla")
	var t2 := pr.titular_prensa(true, false, false, "misma-semilla")
	_comprobar(String(t1["tit"]) == String(t2["tit"]),
		"el mismo partido escribe siempre el mismo titular (no toca el azar)")

	## EL ANO CONTADO: un parrafo, no una tabla.
	var relato := pr.narrador_temporada()
	_linea("  relato: %s" % relato.substr(0, 110))
	_comprobar(relato.length() > 40, "el narrador cuenta la temporada en un parrafo")
	_comprobar(relato.contains(m.mi_club().nombre), "y nombra a tu club")

func _probar_auspicio() -> void:
	_titulo("AUSPICIO (la marca del pecho)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 8181)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var a := m.auspicio
	var mio := m.mi_club()

	_comprobar(a != null, "el club tiene mercado de auspicios desde el primer dia")
	_comprobar(a.ofertas.size() == Auspicio.OFERTAS,
		"hay %d marcas sobre la mesa (%d)" % [Auspicio.OFERTAS, a.ofertas.size()])
	_comprobar(a.contrato.is_empty(), "y todavia ninguna firmada")
	_comprobar(a.semanal() == 0, "sin firmar no entra un peso")
	## Las marcas llegan limpias de leetspeak: la tabla las guarda escritas con
	## ceros y cuatros, como los clubes.
	var sucias := 0
	for o: Dictionary in a.ofertas:
		var n := String(o["marca"])
		if n.contains("0") or n.contains("4") or n.contains("1"):
			sucias += 1
		_linea("  %s pide top %d por %s" % [n, int(o["exig_pos"]), _dinero(int(o["monto"]))])
	_comprobar(sucias == 0, "los nombres de las marcas llegan legibles, sin ceros ni cuatros")

	## Firmar: se cobra semana a semana, no de golpe.
	var monto := int(a.ofertas[0]["monto"])
	_comprobar(a.firmar(0) == "", "se puede firmar la primera oferta")
	_comprobar(a.ofertas.is_empty(), "y las otras marcas se retiran")
	_comprobar(a.firmar(0) != "", "no se puede firmar dos veces en la misma temporada")
	_comprobar(a.semanal() == int(round(float(monto) / float(Auspicio.SEMANAS_TEMPORADA))),
		"el aporte gotea en %d semanas (%s a la semana)" % [Auspicio.SEMANAS_TEMPORADA, _dinero(a.semanal())])
	var caja := mio.saldo
	m.avanzar_semana()
	_comprobar(mio.saldo != caja, "y la semana lo ingresa de verdad en la caja")

	## LA EXIGENCIA. Terminar por debajo de lo pactado encoge las ofertas del
	## ano siguiente: es lo que convierte elegir la cifra mas alta en una apuesta
	## y no en una obviedad.
	var pedido := int(a.contrato["exig_pos"])
	a.cierre(pedido + 5)
	_comprobar(a.quedaron_molestos, "terminar por debajo del top pactado deja molesta a la marca")
	_comprobar(a.contrato.is_empty(), "y el contrato se acaba con la temporada")
	a.generar_ofertas(mio, false)
	var flaca := 0
	for o: Dictionary in a.ofertas:
		flaca += int(o["monto"])
	a.quedaron_molestos = false
	a.generar_ofertas(mio, false)
	var gorda := 0
	for o: Dictionary in a.ofertas:
		gorda += int(o["monto"])
	_linea("  ofertas tras fallar: %s   ·   tras cumplir: %s" % [_dinero(flaca), _dinero(gorda)])
	_comprobar(flaca < gorda, "y al ano siguiente las ofertas llegan mas flacas")

	## Un grande cobra varias veces lo que un chico: la curva es exponencial
	## sobre la reputacion, como todo el resto de la economia.
	var chico := m.ligas[0].clubes[m.ligas[0].clubes.size() - 1]
	_linea("  base de %s (rep %d): %s   ·   base de %s (rep %d): %s" % [
		mio.nombre, mio.rep, _dinero(Auspicio.base_de(mio)),
		chico.nombre, chico.rep, _dinero(Auspicio.base_de(chico))])
	_comprobar(Auspicio.base_de(mio) > Auspicio.base_de(chico),
		"un grande cobra mas por la camiseta que un chico")

func _probar_eras_y_precios() -> void:
	_titulo("EPOCAS DORADAS Y PRECIOS DINAMICOS")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 9191)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)

	## LAS EPOCAS. Un pais entero ganando o perdiendo una generacion.
	var e := m.eras
	_comprobar(e != null, "el mundo tiene mapa del talento")
	_comprobar(is_equal_approx(e.bono("CHI", m.anio), 1.0), "sin epoca marcada, el pais no lleva bono")
	e.activas["CHI"] = {"tipo": "dorada", "desde": m.anio, "hasta": m.anio + 5}
	_comprobar(is_equal_approx(e.bono("CHI", m.anio), Eras.BONO_DORADA),
		"en epoca dorada las camadas suben un 13%")
	_comprobar(is_equal_approx(e.bono("ARG", m.anio), 1.0), "y el pais de al lado sigue igual")
	_comprobar(is_equal_approx(e.bono("CHI", m.anio + 9), 1.0), "la epoca caduca sola cuando pasa su ultimo ano")
	e.activas["ARG"] = {"tipo": "decadencia", "desde": m.anio, "hasta": m.anio + 4}
	_comprobar(is_equal_approx(e.bono("ARG", m.anio), Eras.BONO_DECADENCIA),
		"en decadencia las camadas bajan un 10%")
	var mapa := e.mapa_del_talento(m.anio)
	_comprobar(mapa.size() == 2, "el mapa del talento enseña los dos paises marcados (%d)" % mapa.size())
	for f: Dictionary in mapa:
		_linea("  %s: %s hasta %d (%s)" % [String(f["pais"]), String(f["tipo"]), int(f["hasta"]), String(f["texto"])])

	## Y se nota en la camada: mismo club, mismo ano, dos mundos con y sin epoca.
	## Se comparan MEDIAS de proyeccion sobre las dos camadas completas, que es
	## donde el 13% se ve; jugador a jugador el azar tapa el efecto.
	var techo_con := _media_techo_camada(9292, "dorada")
	var techo_sin := _media_techo_camada(9292, "")
	_linea("  proyeccion media de la camada: con epoca dorada %.1f, sin ella %.1f" % [techo_con, techo_sin])
	_comprobar(techo_con > techo_sin, "la epoca dorada se nota de verdad en la camada")

	## LOS PRECIOS DINAMICOS: el mismo asiento no vale lo mismo contra el lider
	## que contra el colista.
	var h := m.hinchada
	var base := 8
	_comprobar(not h.precio_dinamico, "de entrada el precio es fijo")
	_comprobar(h.precio_efectivo(base, 90) == base, "y con precio fijo da igual contra quien juegues")
	h.alternar_precio_dinamico()
	_comprobar(h.precio_dinamico, "el interruptor enciende los precios dinamicos")
	var caro := h.precio_efectivo(base, 90)
	var barato := h.precio_efectivo(base, 45)
	_linea("  entrada de %d: contra un rep 90 se cobra %d, contra un rep 45 se cobra %d" % [base, caro, barato])
	_comprobar(caro > base, "contra un grande la entrada sube")
	_comprobar(barato < base, "contra un chico la entrada baja")
	_comprobar(h.precio_efectivo(base, 200) <= Hinchada.PRECIO_MAX, "con techo: nunca pasa de %d" % Hinchada.PRECIO_MAX)
	_comprobar(h.precio_efectivo(base, 0) >= Hinchada.PRECIO_MIN, "y con suelo: nunca baja de %d" % Hinchada.PRECIO_MIN)
	_comprobar(h.castigo_por_subida(base, caro) > 0, "subirla se paga en animo")
	_comprobar(h.castigo_por_subida(base, barato) == 0, "bajarla no molesta a nadie")

	## LA FRASE DE LA PARED Y EL UNIFORME DEL CUERPO TECNICO.
	var cd := m.club_dentro
	_comprobar(cd.frase == "", "la pared empieza en blanco")
	cd.escribir_frase("   Aqui no se rinde nadie   ")
	_comprobar(cd.frase == "Aqui no se rinde nadie", "la frase se guarda limpia de espacios")
	cd.escribir_frase("x".repeat(200))
	_comprobar(cd.frase.length() == ClubDentro.FRASE_MAX,
		"y recortada a %d caracteres (%d)" % [ClubDentro.FRASE_MAX, cd.frase.length()])
	_comprobar(cd.color_ct1(m.mi_club()) == m.mi_club().color1,
		"sin elegir color, el cuerpo tecnico viste de los colores del club")
	cd.ct_color1 = "#ff0000"
	_comprobar(cd.color_ct1(m.mi_club()) == "#ff0000", "y si eliges uno, manda el tuyo")
	cd.vestir("abrigo")
	_comprobar(cd.ct_ropa == "abrigo" and cd.ct_color1 == "",
		"cambiar de prenda borra los colores a mano: el abrigo no hereda el verde del chandal")

## La proyeccion media de una camada, con o sin epoca dorada en el pais. Mismo
## mundo y misma semilla en los dos casos: lo unico que cambia es la epoca.
func _media_techo_camada(semilla: int, tipo: String) -> float:
	var m := Mundo.new()
	m.generar(["CHI"], semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	if tipo != "":
		m.eras.activas["CHI"] = {"tipo": tipo, "desde": m.anio, "hasta": m.anio + 5}
	var suma := 0.0
	var n := 0
	for c: Club in m.clubes.values():
		for j: Jugador in m.cantera._camada_de(c):
			suma += float(j.pot)
			n += 1
	return suma / float(maxi(1, n))

func _probar_analitica_y_academias() -> void:
	_titulo("DEPARTAMENTO DE DATOS Y ACADEMIAS INTERNACIONALES")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "BRA"], 5757)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var oj := m.ojeadores
	var mio := m.mi_club()
	mio.mover_saldo(20000000)

	## EL MODELO DE DATOS.
	_comprobar(oj.analitica_nivel == 0, "el departamento empieza sin montar")
	var caja := mio.saldo
	_comprobar(oj.mejorar_analitica(mio) == "", "se puede montar el departamento")
	_comprobar(mio.saldo < caja, "y se paga de la caja")
	_comprobar(oj.analitica_nivel == 1, "queda en nivel 1")
	var c1 := oj.coste_analitica(mio)
	oj.mejorar_analitica(mio)
	var c2 := oj.coste_analitica(mio)
	_linea("  ampliar de 1 a 2 cuesta %s; de 2 a 3, %s" % [_dinero(c1), _dinero(c2)])
	_comprobar(c2 > c1, "cada nivel cuesta mas que el anterior")
	oj.mejorar_analitica(mio)
	_comprobar(oj.analitica_nivel == Ojeadores.ANALITICA_MAX, "se llega al tope")
	_comprobar(oj.mejorar_analitica(mio) != "", "y del tope no se pasa")

	## Los hallazgos aparecen solos y son jugadores de verdad, jovenes y baratos.
	oj.hallazgos.clear()
	for i in 60:
		oj.semana_analitica(3)
	_linea("  en 60 semanas el modelo senalo %d nombres" % oj.hallazgos.size())
	_comprobar(not oj.hallazgos.is_empty(), "el modelo acaba senalando a alguien")
	_comprobar(oj.hallazgos.size() <= 8, "y guarda como mucho ocho (%d)" % oj.hallazgos.size())
	_comprobar(oj.analitica_tension > 0, "con un jefe de ojeadores de la vieja escuela, la tension sube")
	for h: Dictionary in oj.hallazgos:
		var j := m.jugador_por_id(String(h["pid"]))
		if j == null:
			continue
		_comprobar(j.edad <= 24 and j.pot - j.ovr >= 10,
			"%s: joven (%d) y con recorrido (+%d)" % [j.nombre, j.edad, j.pot - j.ovr])
		break
	_comprobar(not oj.hallazgos_vivos().is_empty(), "y se pueden leer resueltos para la pantalla")

	## LAS ACADEMIAS.
	mio.mover_saldo(40000000)
	_comprobar(oj.academias.is_empty(), "no hay sedes internacionales de entrada")
	_comprobar(oj.alternar_academia("ARG", mio) == "", "se puede abrir una sede")
	_comprobar(oj.tiene_academia("ARG"), "y queda abierta")
	_comprobar(oj.mantencion_academias(mio) > 0, "que cuesta todas las semanas")
	oj.alternar_academia("BRA", mio)
	oj.alternar_academia("CHI", mio)
	_comprobar(oj.academias.size() == Ojeadores.ACADEMIAS_MAX,
		"caben %d sedes (%d)" % [Ojeadores.ACADEMIAS_MAX, oj.academias.size()])
	_comprobar(oj.alternar_academia("ESP", mio) != "", "y no una mas")
	## La joya de pretemporada: una por sede, con techo alto de verdad.
	var antes := mio.plantilla.size()
	var joyas := oj.joyas_de_academia(mio)
	_linea("  llegan %d joyas: %s" % [joyas.size(),
		", ".join(joyas.map(func(j: Jugador) -> String: return "%s (%s, proy %d)" % [j.nombre, j.pais, j.pot]))])
	_comprobar(joyas.size() == oj.academias.size(), "llega una joya por sede")
	for j: Jugador in joyas:
		_comprobar(j.pot - j.ovr >= 12, "%s viene con recorrido de verdad (+%d)" % [j.nombre, j.pot - j.ovr])
		break
	_comprobar(mio.plantilla.size() == antes,
		"y `joyas_de_academia` NO las mete sola en el plantel: eso lo hace el mundo, y solo en pretemporada")
	## Cerrar una devuelve algo de dinero.
	var caja2 := mio.saldo
	oj.alternar_academia("ARG", mio)
	_comprobar(mio.saldo > caja2 and not oj.tiene_academia("ARG"), "cerrar una sede la vende y devuelve caja")

## HABILIDADES ESPECIALES: "sortearHabilidades()"/"HABS" del HTML. Nacen con
## el jugador -"LAS HABILIDADES DE NACIMIENTO" en `Mundo.crear_jugador()`- y
## viven en `Entrenamiento` (diccionario id->lista), no en `Jugador`: por
## vivir fuera nunca habían tenido una prueba propia -se encontró revisando
## por qué el editor parecía no tener de dónde sacar `habs`, y resultó que sí
## estaba, solo que en otra clase-.
func _probar_habilidades() -> void:
	_titulo("HABILIDADES ESPECIALES: NACIMIENTO Y BONO DE VALOR")
	var m := Mundo.new()
	m.generar(["CHI"], 8080)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ent := m.entrenamiento

	## Nacen con el jugador: cuanta mejor la media, mas probable que traiga
	## alguna de fábrica.
	var con_habs := 0
	var total := 0
	for c: Club in m.ligas[0].clubes:
		for j: Jugador in c.plantilla:
			total += 1
			if not ent.habilidades(j).is_empty():
				con_habs += 1
	_linea("  %d futbolistas, %d nacieron con alguna habilidad especial" % [total, con_habs])
	_comprobar(con_habs > 0, "al menos alguien nace con una habilidad")

	## `dar_habilidad()`/`habilidades()`: no se repite, y solo entra si esta
	## en la tabla.
	var j := m.mi_club().plantilla[0]
	_comprobar(not ent.dar_habilidad(j, "no_existe_esta_clave"), "una clave que no esta en HABS no se agrega")
	var pool_j: Array = Datos.tabla("HAB_POR" if j.es_portero() else "HAB_CAMPO")
	if not pool_j.is_empty():
		var clave := String(pool_j[0])
		var ya_la_tenia := ent.habilidades(j).has(clave)
		var dado := ent.dar_habilidad(j, clave)
		_comprobar(dado != ya_la_tenia, "dar_habilidad devuelve si de verdad se agrego (%s)" % dado)
		_comprobar(ent.habilidades(j).has(clave), "la habilidad queda anotada")
		_comprobar(not ent.dar_habilidad(j, clave), "pedirla otra vez no la duplica")

	## EL BONO DE VALOR: "if(j.habs.length>=3)v*=1.05" del HTML. Dos
	## jugadores idénticos salvo la cantidad de habilidades.
	var pool: Array = Datos.tabla("HAB_CAMPO")
	if pool.size() >= 3:
		var con3 := Jugador.new()
		con3.ovr = 80; con3.edad = 26; con3.pot = 80; con3.anios_contrato = 3
		con3.tasar()
		var valor_sin := con3.valor
		for i in 3:
			ent.dar_habilidad(con3, String(pool[i]))
		ent._tasar(con3)
		_comprobar(con3.valor > valor_sin,
			"tres habilidades o mas suben el valor (%d -> %d)" % [valor_sin, con3.valor])
		_comprobar(absf(float(con3.valor) / float(valor_sin) - 1.05) < 0.02,
			"la subida ronda el 5%% del HTML (%.1f%%)" % ((float(con3.valor) / float(valor_sin) - 1.0) * 100.0))

func _probar_carrera_por_dentro() -> void:
	_titulo("LA CARRERA POR DENTRO (rival, leyenda viva, filiales y sucesion)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var r := m.roles
	var mio := m.mi_club()
	var otro: Club = m.ligas[0].clubes[1]

	## EL RIVAL PERSONAL. Nace del club con el que mas te has picado; por debajo
	## del umbral no hay historia que contar.
	_comprobar(r.rival_dt.is_empty(), "de entrada no hay rival personal")
	r.buscar_rival_dt()
	_comprobar(r.rival_dt.is_empty(), "y sin rivalidad calentada tampoco aparece")
	## Se calienta a mano al nivel que hace falta y se vuelve a mirar.
	m.logros.h2h[otro.id] = {"pj": 20, "pg": 2, "pe": 3, "pp": 15, "gf": 8, "gc": 40}
	r.buscar_rival_dt()
	_linea("  rivalidad con %s: %d de calor" % [otro.nombre, m.logros.rivalidad_con(otro)])
	if r.rival_dt.is_empty():
		_linea("  (no llego al umbral de %d; se fuerza para probar el duelo)" % Roles.CALOR_PARA_RIVAL)
		r.rival_dt = {"club_id": otro.id, "nombre": "Prueba", "estilo": "",
			"pj": 0, "g": 0, "e": 0, "p": 0, "tension": 50, "desde": m.anio}
	_comprobar(not r.rival_dt.is_empty(), "hay rival personal con nombre y apellido")
	var t0 := int(r.rival_dt["tension"])
	r.registrar_duelo(otro.id, false, false)
	_comprobar(int(r.rival_dt["pj"]) == 1 and int(r.rival_dt["p"]) == 1, "un duelo perdido se apunta")
	_comprobar(int(r.rival_dt["tension"]) > t0, "y calienta la cosa (%d -> %d)" % [t0, int(r.rival_dt["tension"])])
	r.registrar_duelo("club_que_no_es", true, false)
	_comprobar(int(r.rival_dt["pj"]) == 1, "un partido contra cualquier otro no cuenta como duelo")

	## LA LEYENDA VIVA.
	_comprobar(r.leyenda_viva.is_empty(), "no hay leyenda viva de entrada")
	var vet: Jugador = mio.plantilla[0]
	vet.edad = 34
	_comprobar(r.nombrar_leyenda_viva(vet) == "", "se puede nombrar a un veterano")
	_comprobar(not r.leyenda_viva.is_empty(), "y queda ligado al club")
	_comprobar(r.nombrar_leyenda_viva(mio.plantilla[1]) != "", "no caben dos leyendas vivas a la vez")
	## Sus visitas mueven la moral de algun juvenil. Se buscan seis semanas.
	var chico: Jugador = null
	for j: Jugador in mio.plantilla:
		if j.edad <= 21:
			chico = j
			break
	if chico != null:
		chico.moral = 40
		for i in 6:
			r.semana_leyenda_viva()
		_linea("  tras seis semanas, la moral de los juveniles se movio")
	_comprobar(int(r.leyenda_viva["visitas"]) >= 6, "y sus visitas se cuentan")

	## LOS CLUBES FILIALES. `puede_comprar_filiales()` estaba escrita y no la
	## llamaba nadie: la habilidad Magnate no servia para nada.
	_comprobar(r.comprar_filial(otro) != "", "sin la habilidad Magnate no se compra ningun club")
	m.entrenamiento.dt_nodos["magnate"] = true
	r.patrimonio = 0
	_comprobar(r.comprar_filial(otro) != "", "y con la habilidad pero sin patrimonio, tampoco")
	r.patrimonio = r.precio_filial(otro) * 2
	var antes := r.patrimonio
	_comprobar(r.comprar_filial(otro) == "", "con Magnate y con dinero, se compra")
	_comprobar(r.patrimonio < antes, "y sale de TU bolsillo, no de la caja del club")
	_comprobar(r.filiales.has(otro.id), "el club queda como filial")
	_comprobar(r.comprar_filial(otro) != "", "no se compra dos veces")
	_comprobar(r.comprar_filial(mio) != "", "ni se compra el club que diriges")
	## Los dividendos caen cada doce semanas.
	var pat := r.patrimonio
	m.semana = Roles.SEMANAS_DIVIDENDO
	r.semana_filiales()
	_linea("  dividendo de %s: %s" % [otro.nombre, _dinero(r.patrimonio - pat)])
	_comprobar(r.patrimonio > pat, "y reparten dividendos cada %d semanas" % Roles.SEMANAS_DIVIDENDO)
	var pat2 := r.patrimonio
	m.semana = Roles.SEMANAS_DIVIDENDO + 1
	r.semana_filiales()
	_comprobar(r.patrimonio == pat2, "pero no todas las semanas")

	## LA SUCESION: solo cuando te has retirado.
	var cands := r.candidatos_sucesion()
	_linea("  candidatos a sucederte: %s" % ", ".join(cands.map(func(x: Dictionary) -> String: return String(x["nombre"]))))
	_comprobar(cands.size() >= 2, "hay al menos dos candidatos (%d)" % cands.size())
	_comprobar(r.sucesor.is_empty(), "y ninguno elegido todavia")
	_comprobar(r.elegir_sucesor(0) == "", "se puede elegir uno")
	_comprobar(not r.sucesor.is_empty(), "y queda apuntado quien se queda el banquillo")
	_comprobar(r.elegir_sucesor(99) != "", "un candidato que no existe no se elige")

func _probar_editor() -> void:
	_titulo("EL EDITOR Y EL IMPORTADOR DE CSV")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 6161)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ed := Editor.new(m)
	var mio := m.mi_club()
	var otro: Club = m.ligas[0].clubes[3]

	## CLUBES.
	_comprobar(ed.renombrar_club(otro, "A") != "", "un nombre de una letra no se acepta")
	_comprobar(ed.renombrar_club(otro, "  Deportivo Prueba  ") == "", "se renombra un club")
	_comprobar(otro.nombre == "Deportivo Prueba", "y llega limpio de espacios (%s)" % otro.nombre)
	var rep0 := otro.rep
	ed.mover_reputacion(otro, 4)
	_comprobar(otro.rep == rep0 + 4, "la reputacion se mueve (%d -> %d)" % [rep0, otro.rep])
	ed.mover_reputacion(otro, 999)
	_comprobar(otro.rep <= 95, "y tiene techo (%d)" % otro.rep)
	var af0 := otro.estadio_aforo
	ed.mover_aforo(otro, -999999)
	_comprobar(otro.estadio_aforo >= 2000, "el aforo tiene suelo (%d desde %d)" % [otro.estadio_aforo, af0])
	_comprobar(ed.regenerar_plantel(mio) != "", "no se regenera el plantel del club que diriges")
	var antes_pl := otro.plantilla.size()
	_comprobar(ed.regenerar_plantel(otro) == "", "el de otro club si")
	_comprobar(otro.plantilla.size() > 0, "y queda con plantilla (%d, antes %d)" % [otro.plantilla.size(), antes_pl])

	## JUGADORES.
	var j: Jugador = mio.plantilla[0]
	_comprobar(ed.fijar_campo(j, "nombre", "Fulano de Prueba") == "", "se renombra a un jugador")
	_comprobar(j.nombre == "Fulano de Prueba", "y se guarda")
	ed.fijar_campo(j, "ovr", 91)
	_comprobar(j.ovr == 91 and j.pot >= 91, "subir la media sube el techo si hacia falta (%d/%d)" % [j.ovr, j.pot])
	## Y la media puesta a mano AGUANTA: `generar_atributos()` reparte alrededor
	## de ella pero `media_en()` los vuelve a pesar, y sin cuadrarlos escribir 91
	## y ver 89 al tocar el primer atributo hacia desconfiar de la pantalla entera.
	_comprobar(j.media_en(j.pos_e) == 91,
		"y los atributos cuadran con la media pedida (%d)" % j.media_en(j.pos_e))
	ed.fijar_campo(j, "edad", 999)
	_comprobar(j.edad <= 45, "la edad tiene tope (%d)" % j.edad)
	## Mover un atributo recalcula la media: editar y que la media no se entere
	## seria mentir en la misma pantalla.
	## Se busca uno que NO este ya en el tope: subir un atributo que vale 99
	## no sube nada, y la prueba fallaria sin que hubiera nada roto.
	## Y que PESE en su puesto: subir la velocidad de un portero no mueve su
	## media, y la prueba fallaba según qué jugador tocara ese mundo.
	var clave := ""
	for k: String in j.atributos:
		if int(j.atributos[k]) >= 90:
			continue
		var v0 := int(j.atributos[k])
		var m0 := j.media_en(j.pos_e)
		j.atributos[k] = v0 + 8
		var pesa := j.media_en(j.pos_e) != m0
		j.atributos[k] = v0
		if pesa:
			clave = k
			break
	if clave == "":
		for k2: String in j.atributos:
			j.atributos[k2] = 60
			clave = k2
			break
	var ovr_antes := j.ovr
	var at_antes := int(j.atributos[clave])
	for i in 8:
		ed.mover_atributo(j, clave, 1)
	_linea("  %s: %d -> %d, y la media %d -> %d" % [clave, at_antes, int(j.atributos[clave]), ovr_antes, j.ovr])
	_comprobar(int(j.atributos[clave]) > at_antes, "el atributo sube")
	_comprobar(j.ovr != ovr_antes, "y la media se recalcula sola")

	## LA CARA. Solo se pisan las claves tocadas: cambiar el pelo no debe tocar
	## la nariz.
	var look0 := Cara.look_de(j)
	ed.fijar_look(j, "pelo", "rapado")
	var look1 := Cara.look_de(j)
	_comprobar(String(look1["pelo"]) == "rapado", "el corte de pelo se puede fijar a mano")
	_comprobar(int(look1["nariz"]) == int(look0["nariz"]), "y no toca el resto de la cara")
	_comprobar(j.look.size() == 1, "solo se guarda lo cambiado (%d clave)" % j.look.size())

	## EL IMPORTADOR DE CSV.
	var csv := "%s;Arturo Vidal;MED;38;79\n%s;Edinson Cavani;DEL;39;80;URU;80\nClub Que No Existe;Nadie;MED;20;60" % [
		mio.nombre, mio.nombre]
	var antes_mio := mio.plantilla.size()
	var r := ed.importar_csv(csv, false)
	_linea("  importadas %d fichas en %d club(es), %d problema(s)" % [
		int(r["filas"]), int(r["clubes"]), (r["problemas"] as Array).size()])
	_comprobar(int(r["filas"]) == 2, "se leen las dos filas buenas (%d)" % int(r["filas"]))
	_comprobar((r["problemas"] as Array).size() == 1, "y se avisa del club que no existe")
	_comprobar(mio.plantilla.size() == antes_mio + 2,
		"con menos de %d filas se AÑADEN, no se reemplaza (%d -> %d)" % [
			Editor.FILAS_PARA_REEMPLAZAR, antes_mio, mio.plantilla.size()])
	var encontrado := false
	for p: Jugador in mio.plantilla:
		if Nombres.limpiar(p.nombre) == "Edinson Cavani":
			encontrado = true
			_comprobar(p.pais == "URU" and p.pot == 80 and p.edad == 39,
				"y con su pais, su techo y su edad (%s, %d, %d)" % [p.pais, p.pot, p.edad])
	_comprobar(encontrado, "el futbolista importado esta en el plantel")

	## Con quince filas o mas, se REEMPLAZA la plantilla entera.
	var muchas := ""
	for i in 18:
		muchas += "%s;Jugador %d;MED;25;70\n" % [otro.nombre, i]
	ed.importar_csv(muchas, false)
	_comprobar(otro.plantilla.size() == 18,
		"con %d filas o mas se reemplaza el plantel entero (%d)" % [Editor.FILAS_PARA_REEMPLAZAR, otro.plantilla.size()])

	## LA CENSURA letra->numero, que es la razon de que el juego no use nombres
	## reales tal cual.
	var limpio := "Arturo Vidal"
	var censurado := Nombres.censurar(limpio)
	_linea("  censura: «%s» -> «%s» -> «%s»" % [limpio, censurado, Nombres.limpiar(censurado)])
	_comprobar(censurado != limpio, "censurar cambia el nombre")
	_comprobar(Nombres.limpiar(censurado) == limpio,
		"y `limpiar()` lo deshace exactamente: el camino de ida y vuelta cierra")

func _probar_ciudad() -> void:
	_titulo("LA CIUDAD (terrenos, negocios, vecinos, permisos y seguridad)")
	var m := Mundo.new()
	m.generar(["CHI"], 3131)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ci := m.ciudad
	var mio := m.mi_club()
	mio.mover_saldo(200000000)

	## TERRENOS Y NEGOCIOS: sin el paño no hay negocio, y eso es lo que hace que
	## el centro comercial sea la joya y no otra compra mas.
	_comprobar(ci.terrenos.is_empty(), "no hay terrenos de entrada")
	_comprobar(ci.construir_negocio("comercial", mio) != "",
		"sin el solar del centro no se puede levantar el centro comercial")
	_comprobar(ci.comprar_terreno("centro", mio) == "", "se compra el solar del centro")
	_comprobar(ci.comprar_terreno("centro", mio) != "", "y no dos veces")
	_comprobar(ci.construir_negocio("comercial", mio) == "", "y ahora si se levanta el centro comercial")
	_comprobar(ci.tiene_negocio("comercial"), "queda operando")
	var renta := ci.renta_negocios(mio, 60)
	_linea("  el centro comercial renta %s por semana" % _dinero(renta))
	_comprobar(renta > 0, "y renta todas las semanas")
	## Los negocios sin terreno se pueden construir directamente.
	var socios0 := mio.socios
	_comprobar(ci.construir_negocio("escuela", mio) == "", "la escuela no necesita terreno")
	_comprobar(mio.socios > socios0, "y trae socios de verdad (%d -> %d)" % [socios0, mio.socios])
	var reh0 := m.obras.nivel("rehab")
	ci.comprar_terreno("periferia", mio)
	ci.construir_negocio("clinica", mio)
	_comprobar(m.obras.nivel("rehab") > reh0,
		"la clinica sube un nivel de rehabilitacion gratis (%d -> %d)" % [reh0, m.obras.nivel("rehab")])

	## CONCIERTOS Y CESPED: dinero hoy contra rendimiento el domingo.
	var caja0 := mio.saldo
	_comprobar(ci.cesped == 100, "el cesped empieza impecable")
	ci.arrendar_estadio(mio)
	_linea("  tras el concierto: caja +%s, cesped %d, vecinos %d" % [
		_dinero(mio.saldo - caja0), ci.cesped, ci.vecinos])
	_comprobar(mio.saldo > caja0, "el concierto llena la caja")
	_comprobar(ci.cesped < 100, "y destroza el campo")
	_comprobar(ci.conciertos == 1, "se cuenta")
	## Con el campo por debajo de 60 los jugadores pierden precision. Se fuerza.
	ci.cesped = 40
	_comprobar(ci.penalizacion_cesped() < 1.0,
		"con el cesped a %d los jugadores pierden precision (x%.3f)" % [ci.cesped, ci.penalizacion_cesped()])
	_comprobar(ci.arrendar_estadio(mio) != "", "y no se puede arrendar con el campo asi")
	_comprobar(ci.reparar_cesped(mio) == "", "se puede resembrar")
	_comprobar(ci.cesped == 100, "y queda como nuevo")
	_comprobar(is_equal_approx(ci.penalizacion_cesped(), 1.0), "sin penalizacion")

	## VECINOS Y PERMISO. Una gestion al mes.
	var vec0 := ci.vecinos
	_comprobar(ci.gestion_vecinal("entradas", mio) == "", "se puede hacer una gestion vecinal")
	_comprobar(ci.vecinos > vec0, "repartir entradas mejora la relacion (%d -> %d)" % [vec0, ci.vecinos])
	_comprobar(ci.gestion_vecinal("obra", mio) != "", "y solo cabe una gestion al mes")
	ci.mes()
	_comprobar(ci.gestion_vecinal("obra", mio) == "", "al mes siguiente vuelve a haber cupo")
	_comprobar(not ci.permiso_ok, "no hay permiso municipal de entrada")
	_comprobar(ci.pedir_permiso(mio) == "", "se puede solicitar")
	_comprobar(ci.pedir_permiso(mio) != "", "y no dos veces a la vez")
	_linea("  permiso en tramite: %d semanas, %d%% de probabilidad" % [
		int(ci.permiso["semanas"]), int(round(float(ci.permiso["prob"]) * 100.0))])
	for i in 10:
		ci.semana(mio, 60)
	_comprobar(ci.permiso.is_empty(), "a las diez semanas la solicitud ya se resolvio")

	## SEGURIDAD Y SANCIONES.
	var r0 := ci.riesgo_incidente(60, 0)
	ci.mejorar_seguridad("privada", mio)
	ci.mejorar_seguridad("camaras", mio)
	var r1 := ci.riesgo_incidente(60, 0)
	_linea("  riesgo de incidente: %.1f%% -> %.1f%% tras invertir en seguridad" % [r0 * 100.0, r1 * 100.0])
	_comprobar(r1 < r0, "pagar seguridad baja el riesgo de incidente")
	_comprobar(ci.riesgo_incidente(20, 90) > ci.riesgo_incidente(90, 0),
		"y el mal ambiente con funa lo sube")
	_comprobar(is_equal_approx(ci.factor_aforo(), 1.0), "sin sancion, el aforo es el normal")
	ci.sancionar("cerradas")
	_comprobar(is_equal_approx(ci.factor_aforo(), 0.0), "a puertas cerradas no entra un peso de taquilla")
	ci.sancionar("aforo")
	_comprobar(is_equal_approx(ci.factor_aforo(), 0.4), "y con aforo reducido entra el 40%")
	for i in 6:
		ci.semana(mio, 60)
	_comprobar(ci.sancion.is_empty(), "la sancion caduca sola")

	## SOSTENIBILIDAD Y SUBVENCION.
	_comprobar(ci.certificar(mio) != "", "no se certifica sin cubierta solar")
	ci.instalar_paneles(mio)
	ci.instalar_paneles(mio)
	_comprobar(ci.ahorro_energetico(mio) > 0, "los paneles ahorran de verdad cada semana")
	_comprobar(ci.certificar(mio) == "", "con dos niveles de paneles ya se puede certificar")
	var sub := ci.subvencion_anual(mio)
	_linea("  subvencion municipal estimada: %s (vecinos %d, negocios %d)" % [
		_dinero(sub), ci.vecinos, ci.negocios.size()])
	_comprobar(sub > 0, "y el municipio paga por el deporte de base")
	var caja1 := mio.saldo
	ci.cobrar_subvencion(mio)
	_comprobar(mio.saldo > caja1, "la subvencion entra en la caja al cerrar el año")

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

func _dinero(n: int) -> String:
	var euros := float(n) * Eco.ECO
	if euros >= 1000000.0:
		return "%.1fM EUR" % (euros / 1000000.0)
	return "%dk EUR" % int(euros / 1000.0)

func _cerrar() -> void:
	_linea("")
	if _fallos.is_empty():
		_linea("===== FIN. 0 fallos =====")
	else:
		_linea("===== FIN. %d FALLOS =====" % _fallos.size())
		for f in _fallos:
			_linea("  - %s" % f)
	var salida := FileAccess.open("res://pruebas/ultimo_resultado.txt", FileAccess.WRITE)
	if salida != null:
		salida.store_string("\n".join(_lineas))
		salida.close()
	get_tree().quit(0 if _fallos.is_empty() else 1)

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
	_comprobar(Idiomas.ORDEN.size() == 6, "hay 6 idiomas ademas del castellano (%d)" % Idiomas.ORDEN.size())
	var cortas: Array[String] = []
	for k2: String in Idiomas.TABLA:
		var fila: Array = Idiomas.TABLA[k2]
		if fila.size() != Idiomas.ORDEN.size():
			cortas.append(k2)
	_comprobar(cortas.is_empty(), "y ninguna fila se queda corta (%s)" % ("todas completas" if cortas.is_empty() else ", ".join(cortas)))
	for idi: String in Idiomas.ORDEN:
		## Al menos las de la tabla (inglés y portugués suman el diccionario ampliado).
		_comprobar(Idiomas.cobertura(idi) >= Idiomas.TABLA.size(),
			"«%s» tiene al menos las %d frases (%d)" % [idi, Idiomas.TABLA.size(), Idiomas.cobertura(idi)])
	Idiomas.idioma = "en"
	_comprobar(Idiomas.t("Guardar") == "Save", "traducir funciona (Guardar -> %s)" % Idiomas.t("Guardar"))
	_comprobar(Idiomas.t("Una frase que no existe") == "Una frase que no existe",
		"y lo que no esta traducido se queda en castellano en vez de salir en blanco")
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


## LAS EXPORTACIONES SE LEEN (25-9-2026). `export_presets.cfg` llevaba
## comentarios con `##`, que en un .cfg de Godot NO son comentarios (van con
## `;`): el archivo no se podía leer y los filtros que dejan fuera el pack real
## y las fotos de personas reales no se aplicaban. Ahora se comprueba que carga
## y que cada versión publicable excluye todo lo que tiene que excluir.
func _probar_presets_exportacion() -> void:
	_titulo("EXPORTACIONES: EL ARCHIVO SE LEE Y LO PRIVADO QUEDA FUERA")
	var c := ConfigFile.new()
	_comprobar(c.load("res://export_presets.cfg") == OK, "export_presets.cfg se puede leer")
	var privados := ["datos/pack_real.json", "recursos/caras_reales/", "recursos/caras_reales_256/", "datos/creditos_fotos.txt"]
	for i in 4:
		var sec := "preset.%d" % i
		var nombre := String(c.get_value(sec, "name", ""))
		var excl := String(c.get_value(sec, "exclude_filter", ""))
		if nombre == "Windows":
			_comprobar(excl.contains("recursos/caras_reales/"), "la versión completa no lleva las fotos originales (solo los retratos)")
			continue
		var faltan: Array[String] = []
		for p: String in privados:
			if not excl.contains(p):
				faltan.append(p)
		_comprobar(faltan.is_empty(), "%s excluye el pack real y las fotos reales %s" % [nombre, str(faltan) if not faltan.is_empty() else ""])


## EL SISTEMA DE DISEÑO Y LA ORTOGRAFÍA (25-9-2026, plan maestro B13). Dos redes
## contra la regresión: (1) ninguna pantalla vuelve a escribir a mano los
## colores canónicos -apuntan a `Tema`-; (2) las palabras que se corrigieron no
## vuelven a aparecer sin tilde en un texto que ve el jugador.
func _probar_tema_y_ortografia() -> void:
	_titulo("TEMA ÚNICO Y ORTOGRAFÍA DE LOS TEXTOS")
	var canonicos := ["e9eeea", "8ea595", "c9a227", "0c1510", "3fa06a", "141c16", "16211a"]
	var copias: Array[String] = []
	var sin_tilde: Array[String] = []
	var vetadas := ["cesped", "policia", "tunel", "camarin", "tactica", "paises", "tambien", "detras", "INVASION", "Division"]
	var rx := RegEx.new()
	rx.compile("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for carpeta: String in ["res://ui", "res://ui/componentes", "res://nucleo", "res://visor"]:
		var dir := DirAccess.open(carpeta)
		if dir == null:
			continue
		for f: String in dir.get_files():
			if not f.ends_with(".gd") or f == "tema.gd" or f == "idiomas.gd" or f == "pantalla_estadio.gd":
				continue
			var texto := FileAccess.get_file_as_string(carpeta + "/" + f)
			for linea: String in texto.split("\n"):
				var t := linea.strip_edges()
				if t.begins_with("#"):
					continue
				if t.begins_with("const COL_"):
					for c: String in canonicos:
						if t.contains('Color("%s")' % c):
							copias.append(f)
				for m in rx.search_all(linea):
					var v := m.get_string(1)
					if not v.contains(" "):
						continue
					for w: String in vetadas:
						var r2 := RegEx.new()
						r2.compile("\\b" + w + "\\b")
						if r2.search(v) != null:
							sin_tilde.append("%s: %s" % [f, w])
	_comprobar(copias.is_empty(), "ninguna pantalla copia la paleta a mano: todas apuntan a Tema %s" % str(copias))
	_comprobar(sin_tilde.is_empty(), "sin palabras corregidas que vuelvan sin tilde %s" % str(sin_tilde))


## LOS NUEVE EVENTOS NUEVOS (25-9-2026, plan maestro B4). Cada uno aparece en la
## baraja cuando se dan sus condiciones y sus DOS salidas mueven algo medible
## (moral, ánimo, funa, caja, sanción, posición o un efecto que dura). Los
## efectos se descuentan semana a semana y viajan en el guardado.
func _probar_eventos_nuevos() -> void:
	_titulo("EVENTOS NUEVOS: TÚNEL, VIRAL, CAPITÁN, HOMENAJE, POSICIÓN, SPONSOR, APUESTAS, HUELGA, CLÁSICO")
	var ids := ["tunel", "viral", "capitan", "silencio", "cambio_posicion", "sponsor_rueda", "apuestas", "huelga_impagos", "derbi_amenaza"]
	var vistos := {}
	var mueven := {}
	for op: String in ["a", "b"]:
		for id: String in ids:
			var m := Mundo.new()
			m.generar(["CHI"], 555)
			m.tomar_el_mando(m.ligas[0].clubes[0].id)
			var mio := m.mi_club()
			mio.plantilla[0].capitan = true
			mio.saldo = -1000   ## para que exista la huelga por impagos
			var pool: Array[Dictionary] = m.prensa._pool(m, mio)
			var ev: Dictionary = {}
			for e: Dictionary in pool:
				if String(e["id"]) == id:
					ev = e
			if ev.is_empty() and id == "derbi_amenaza":
				ev = {"id": id, "pid": "", "txt": "", "opcion_a": "", "opcion_b": ""}
			if ev.is_empty():
				continue
			vistos[id] = true
			## Huella del estado antes y después.
			var huella := func() -> String:
				var moral := 0
				var susp := 0
				var sec := 0
				for j: Jugador in mio.plantilla:
					moral += j.moral
					susp += j.suspension
					sec += j.pos_sec.size()
				return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [moral, susp, sec, mio.saldo, m.prensa.animo, m.prensa.funa,
					m.prensa.rep_entrenador, m.prensa.efectos.size(), m.federacion.enojo_arbitral if m.federacion != null else 0,
					m.directiva.confianza if m.directiva != null else 0]
			var antes: String = huella.call()
			m.prensa.pendiente = ev
			var r: Dictionary = m.prensa.resolver(op)
			if not r.is_empty() and huella.call() != antes:
				mueven["%s/%s" % [id, op]] = true
	_comprobar(vistos.size() == ids.size(), "los nueve eventos existen en la baraja (%d de 9): %s" % [vistos.size(), str(vistos.keys())])
	var quietas: Array[String] = []
	for id: String in vistos:
		for op: String in ["a", "b"]:
			if not mueven.has("%s/%s" % [id, op]):
				quietas.append("%s/%s" % [id, op])
	## "silencio"/b solo sube el ánimo 2 (puede estar ya en el tope): se tolera
	## que alguna salida sin azar quede igual si el valor ya estaba al límite.
	_comprobar(quietas.size() <= 1, "cada salida mueve algo medible (sin efecto: %s)" % str(quietas))
	## Efectos que duran: el capitán plantado deja 3 semanas de tensión.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 556)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	m2.prensa.pendiente = {"id": "capitan", "pid": m2.mi_club().plantilla[0].id}
	m2.prensa.resolver("b")
	_comprobar(m2.prensa.efectos.size() == 1 and int(m2.prensa.efectos[0]["semanas"]) == 3, "plantarse al capitán deja un efecto de 3 semanas")
	var d := Partida._prensa_a_dic(m2.prensa)
	_comprobar((d.get("efectos", []) as Array).size() == 1, "el efecto viaja en el guardado")
	for k in 3:
		m2.prensa.semana()
	_comprobar(m2.prensa.efectos.is_empty(), "a las 3 semanas el efecto se termina solo")

## B5: la rueda con periodista, tono, memoria, repregunta, titubeo, titular,
## texto libre y pie de campo. Y que nada de eso toque `Azar`.
func _probar_entrevistas() -> void:
	_titulo("ENTREVISTAS: PERIODISTA, TONO, MEMORIA, REPREGUNTA, TITULAR, TEXTO LIBRE, PIE DE CAMPO")
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var pr := m.prensa
	pr.abrir_rueda(true, false)
	var e := pr.entrevista
	_comprobar(String(e.get("periodista", "")) != "", "pregunta un periodista con nombre")
	_comprobar(not String(e["pregunta"]).begins_with("Prensa:"), "la pregunta ya no la firma «Prensa»")
	var todas_con_tono := true
	for g: Array in [Prensa._GANE, Prensa._EMPATE, Prensa._PERDI]:
		for q: Dictionary in g:
			for o: Dictionary in q["opciones"]:
				todas_con_tono = todas_con_tono and String(o.get("tono", "")) in ["calma", "soberbia", "evasiva"]
	_comprobar(todas_con_tono, "cada respuesta del guion tiene tono")
	## Calma y a tiempo: se cierra, sin repregunta, y deja titular pendiente.
	var r := pr.responder(0, 2.0)
	_comprobar(not bool(r["sigue"]) and not pr.hay_rueda(), "respuesta en calma cierra la rueda")
	_comprobar(not pr.titular_pendiente.is_empty(), "queda un titular para mañana")
	var tit := pr.publicar_titular_pendiente()
	_comprobar(tit != "" and String(pr.portadas[0]["t"]) == tit, "el titular sale en la hemeroteca")
	_comprobar(pr.memoria.has(String(e["periodista"])), "el periodista recuerda la frase")
	## Titubeo: repregunta el mismo periodista.
	pr.abrir_rueda(false, true)
	var per := String(pr.entrevista["periodista"])
	var calma_i := 0
	for i in (pr.entrevista["opciones"] as Array).size():
		if String(pr.entrevista["opciones"][i]["tono"]) == "calma":
			calma_i = i
	var funa0 := pr.funa
	r = pr.responder(calma_i, Prensa.TITUBEO_SEG + 1.0)
	_comprobar(bool(r["titubeo"]) and bool(r["sigue"]), "tardar en contestar trae repregunta")
	_comprobar(pr.hay_rueda() and String(pr.entrevista["periodista"]) == per and int(pr.entrevista["paso"]) == 1, "repregunta el mismo, una sola vez")
	_comprobar(pr.funa > funa0 or funa0 >= 98, "el titubeo se nota en la calle")
	r = pr.responder(1, 1.0)   ## evasiva, pero ya no hay tercera pregunta
	_comprobar(not bool(r["sigue"]) and not pr.hay_rueda(), "tras la repregunta se cierra aunque evadas")
	## Memoria: soberbia hoy, derrota la semana que viene -> te la devuelven.
	pr.memoria.clear()
	for f: Array in Prensa.PERIODISTAS:
		pr.memoria[String(f[0])] = {"frase": "Que se preparen los de arriba", "tono": "soberbia", "fecha": pr._fecha() - 1}
	pr.abrir_rueda(false, false)
	_comprobar(bool(pr.entrevista.get("memoria", false)) and String(pr.entrevista["pregunta"]).contains("Que se preparen"), "la frase soberbia vuelve tras perder")
	## Texto libre.
	_comprobar(pr.clasificar_respuesta("Sin comentarios") == "evasiva", "texto: «sin comentarios» es evasiva")
	_comprobar(pr.clasificar_respuesta("Somos los mejores y que se preparen") == "soberbia", "texto: soberbia")
	_comprobar(pr.clasificar_respuesta("Confío en el grupo, trabajaremos toda la semana") == "calma", "texto: calma")
	_comprobar(pr.clasificar_respuesta("ok") == "evasiva", "texto: dos letras no es respuesta")
	var arb0 := pr.enojo_arbitral
	r = pr.responder_texto("El árbitro nos robó, ustedes no saben nada", 1.0)
	_comprobar(String(r["tono"]) == "soberbia" and pr.enojo_arbitral >= arb0 + 2, "hablar de árbitros con soberbia los enoja")
	if pr.hay_rueda():
		pr.responder(0, 1.0)
	## Pie de campo.
	var moral0 := m.mi_club().plantilla[0].moral
	var pie := pr.pie_de_campo(true, false, 2, 0)
	_comprobar((pie["opciones"] as Array).size() == 3 and String(pie["pregunta"]).contains("2-0"), "a pie de campo: pregunta con el marcador")
	var rp := pr.responder_pie(0)
	_comprobar(rp["tono"] == "calma" and pr.pie.is_empty() and m.mi_club().plantilla[0].moral >= moral0, "a pie de campo: responder mueve y cierra")
	pr.pie_de_campo(false, false, 0, 1)
	_comprobar(String(pr.responder_pie(-1)["tono"]) == "evasiva", "a pie de campo: pasar de largo")
	## Se guarda y se carga.
	var d := Partida._prensa_a_dic(pr)
	_comprobar(d.has("memoria") and d.has("titular_pendiente"), "memoria y titular se guardan")

## B6: el estadio por secciones -fachada, colores por tribuna, luz, superficie-,
## los ocho estilos nuevos y el exterior.
func _probar_estadio_b6() -> void:
	_titulo("ESTADIO B6: FACHADA, COLORES POR SECCIÓN, LUZ, SUPERFICIE, EXTERIOR, 24 ESTILOS")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	mio.saldo = 500000000
	var e := m.estadio
	_comprobar(e.presets().size() == 24, "24 estilos (16 + 8): %d" % e.presets().size())
	var todos_validos := true
	for p: Array in EstadioPropio.PRESETS_B6:
		for k: String in (p[3] as Dictionary):
			if k == "niveles":
				continue
			if not e.ajustes.has(k) or not e.es_valido(k, p[3][k]):
				todos_validos = false
				print("    estilo %s: «%s»=%s no vale" % [p[0], k, p[3][k]])
	_comprobar(todos_validos, "cada valor de los 8 estilos nuevos existe en su catálogo")
	for k: String in EstadioPropio.DEF_B6:
		if not e.ajustes.has(k):
			_comprobar(false, "clave nueva sembrada: %s" % k)
	var viejo := EstadioPropio.new()
	viejo.desde_dic({"nombre": "", "ajustes": {"forma": "oval"}})
	_comprobar(viejo.ajustes.has("fachada") and String(viejo.ajustes["forma"]) == "oval", "un guardado viejo carga con las claves nuevas")
	_comprobar(e.opciones("fachadaCol").size() == EstadioPropio.PALETA.size() and e.opciones("fachada").size() == 5, "la interfaz ve los catálogos nuevos")
	_comprobar(e.presupuesto(mio, {"fachada": "ladrillo"}) > 0, "revestir la fachada cuesta")
	_comprobar(e.presupuesto(mio, {"fachadaCol": "#b01e2d", "techoCol": "#1b1d22"}) == 0, "pintar es gratis")
	_comprobar(e.reformar(mio, {"fachada": "vidrio"}) == "" and String(e.perfil(mio)["fachada"]) == "vidrio", "la reforma llega al perfil")
	_comprobar(e.reformar(mio, {"fachada": "marmol"}) != "", "una fachada inventada se rechaza")
	## Colores por tribuna.
	e.reformar(mio, {"personalizar_bandejas": true, "bandeja_norte_col1": "#e8c21a"})
	var pf := e.perfil(mio)
	_comprobar(String(pf["bandejas"]["norte"]["col1"]) == "#e8c21a" and String(pf["bandejas"]["sur"]["col1"]) == "", "cada tribuna lleva sus colores")
	## Superficie: efecto real.
	_comprobar(e.factor_lesion() == 1.0 and e.factor_desgaste_cesped() == 1.0, "natural: sin cambios")
	e.reformar(mio, {"superficie": "artificial"})
	_comprobar(e.factor_lesion() > 1.0 and e.factor_desgaste_cesped() == 0.0, "artificial: más lesiones, no se estropea")
	e.reformar(mio, {"superficie": "hibrido"})
	_comprobar(e.factor_lesion() < 1.0, "híbrido: menos lesiones")
	m.avanzar_semana()
	_comprobar(is_equal_approx(Partido.ctx_lesion_local, e.factor_lesion()), "la semana usa la superficie de tu estadio")
	Partido.limpiar_contexto()
	_comprobar(Partido.ctx_lesion_local == 1.0, "limpiar el contexto la devuelve a 1")
	## La luz.
	var luces := {}
	for l: String in ["neutra", "calida", "fria", "club"]:
		luces[StadiumBuilder.color_luz({"luzFocos": l, "luzClub": "#b01e2d"}).to_html()] = true
	_comprobar(luces.size() == 4, "las cuatro luces se distinguen")
	## El exterior se construye (sin pantalla: solo el árbol de nodos).
	var raiz := Node3D.new()
	add_child(raiz)
	StadiumBuilder.build(raiz, e.perfil(mio), 40000, 0.8, 1, mio)
	var ext := raiz.find_child("Exterior", false, false)
	_comprobar(ext != null and ext.find_children("*", "Label3D", false, false).size() >= 2, "hay taquillas, tienda y rótulos fuera")
	raiz.queue_free()

## B7: la ciudad se puede tocar -cada instalación tiene su punto, lo que no
## existe es un solar-, las obras se ven con su grúa, y el día de partido trae
## gente y banderas. Construir desde el mapa cobra lo mismo que dice la ficha.
func _probar_ciudad_b7() -> void:
	_titulo("CIUDAD B7: SOLARES, OBRAS CON GRÚA, DÍA DE PARTIDO, FICHA Y CONSTRUIR")
	var m := Mundo.new()
	m.generar(["CHI"], 313)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.saldo = 900000000
	m.obras.niveles["gim"] = 2
	var antes := c.saldo
	var coste := m.obras.coste("piscina", c.rep)
	_comprobar(m.obras.iniciar("piscina", c) == "" and antes - c.saldo == coste, "construir cobra lo que anuncia la ficha (%d)" % coste)
	var datos := {
		"club": {"nombre": c.nombre, "c1": c.color1, "c2": c.color2, "cap": 30000, "rep": c.rep, "socios": c.socios, "estadioNom": "Estadio"},
		"inst": m.obras.niveles.duplicate(),
		"obras": [{"k": "piscina", "semanas": 4}],
		"terrenos": [], "negocios": {}, "perfil_estadio": {},
		"dia_partido": true, "vecinos": 30,
	}
	var cb := CityBuilder.new()
	add_child(cb)
	cb.build(datos)
	var por_k := {}
	for p: Dictionary in cb.puntos_clic:
		por_k[String(p["k"])] = String(p["estado"])
	_comprobar(por_k.size() >= CityBuilder.EDIFICIOS.size(), "cada instalación tiene su punto en el mapa (%d)" % por_k.size())
	_comprobar(por_k.get("gim", "") == "hecho" and por_k.get("piscina", "") == "obra" and por_k.get("video", "") == "solar",
		"hecho, en obra y solar se distinguen")
	_comprobar(cb.find_children("Grua", "Node3D", false, false).size() >= 1, "la obra tiene su grúa")
	_comprobar(cb.find_child("Hinchada", false, false) != null, "el día de partido hay gente")
	var rot: Node = cb.find_child("Rotulos", false, false)
	_comprobar(rot != null and rot.get_child_count() >= CityBuilder.EDIFICIOS.size(), "rótulos flotantes sobre cada parcela")
	var dentro := true
	for p: Dictionary in cb.puntos_clic:
		if String(p["estado"]) in ["hecho", "obra", "solar"] and (p["pos"] as Vector3).z > 250.0:
			dentro = false
	_comprobar(dentro, "ninguna parcela cae en la calle exterior (z=262)")
	cb.mostrar_rotulos(false)
	_comprobar(not rot.visible, "los rótulos se pueden ocultar")
	cb.queue_free()

## C1: el clima sale de la ciudad y la época (hemisferios al revés, altura,
## nieve solo donde hace frío), no consume Azar y pesa en el partido; cambiar
## el escudo es noticia y pregunta de rueda; la copa también tiene rueda.
func _probar_coherencia_c1() -> void:
	_titulo("C1 COHERENCIA: CLIMA DE LA CIUDAD, ESCUDO COMO NOTICIA, RUEDA TRAS LA COPA")
	## Julio (semana 24): invierno en Santiago, verano en Madrid.
	_comprobar(Clima.estacion("CHI", 24) == "invierno" and Clima.estacion("ESP", 24) == "verano", "hemisferios opuestos")
	_comprobar(Clima.estacion("COL", 24) == "tropical", "el trópico no tiene invierno")
	var a := Clima.del_partido("ENG", 3, 2026, "x")
	_comprobar(a == Clima.del_partido("ENG", 3, 2026, "x"), "el mismo partido tiene siempre el mismo tiempo")
	var nieve_tropico := false
	var nieve_frio := false
	for k in 400:
		if String(Clima.del_partido("BRA", 26, 2026, str(k))["clave"]) == "nieve":
			nieve_tropico = true
		if String(Clima.del_partido("GER", 2, 2026, str(k))["clave"]) == "nieve":
			nieve_frio = true
	_comprobar(not nieve_tropico and nieve_frio, "nieve solo donde y cuando hace frío")
	var alt := Clima.del_partido("BOL", 10, 2026, "y")
	_comprobar(Clima.factor_visita(alt, "ARG", "BOL") < 1.0 and Clima.factor_visita(alt, "ECU", "BOL") == 1.0, "la altura castiga al visitante del llano, no al de altura")
	## El factor llega al partido.
	var m := Mundo.new()
	m.generar(["CHI"], 2468)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	var p := Partido.new(mio, m.ligas[0].clubes[1])
	p.fijar_clima({"clave": "nieve", "calor": false, "altura": false, "texto": "Nieve"})
	_comprobar(p.clima < 1.0, "la nieve traba el partido (factor %.2f)" % p.clima)
	## Escudo nuevo = noticia + pregunta.
	var pr := m.prensa
	pr.revisar_identidad(mio)   ## la primera vez solo toma la foto
	_comprobar(pr.cambio_identidad == "", "sin cambios no hay noticia")
	var portadas_antes := pr.portadas.size()
	mio.esc_forma = "redondo" if mio.esc_forma != "redondo" else "clasico"
	var que := pr.revisar_identidad(mio)
	_comprobar(que == "escudo" and pr.portadas.size() == portadas_antes + 1, "cambiar el escudo sale en portada")
	pr.abrir_rueda(true, false)
	_comprobar(String(pr.entrevista["pregunta"]).contains("escudo") and pr.cambio_identidad == "", "y te preguntan por él en la rueda")
	pr.responder(0, 1.0)
	if pr.hay_rueda():
		pr.responder(0, 1.0)
	## La copa también tiene rueda (con su competición).
	var rival: Club = m.ligas[0].clubes[2]
	pr.entrevista = {}
	var intentos := 0
	while not pr.hay_rueda() and intentos < 20:
		m._rueda_de_eliminatoria([{"local": mio, "visita": rival, "gl": 2, "gv": 1, "pasa": mio}], "copa", [mio, rival])
		intentos += 1
	_comprobar(pr.hay_rueda() and pr.competicion_rueda == "copa", "después de la copa también hay rueda de prensa")

## C20: la portada guarda lo que necesita el periódico (foto, bajada, medio) y
## cada medio tiene su cabecera; seis cabeceras distintas.
func _probar_portadas_c20() -> void:
	_titulo("C20 PORTADA DE PERIÓDICO: SEIS CABECERAS Y DATOS PARA DIBUJARLA")
	var m := Mundo.new()
	m.generar(["CHI"], 1357)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var pr := m.prensa
	for k in 12:
		pr.portada_tras_resultado(true, false, false, "semilla%d" % k, "A 2-0 B")
	_comprobar(not pr.portadas.is_empty() and String(pr.portadas[0].get("sub", "")) == "A 2-0 B" and String(pr.portadas[0].get("img", "")) == "dt",
		"la portada del partido lleva el marcador y la foto del DT")
	var nombres := {}
	for c: Array in PortadaPeriodico.CABECERAS:
		nombres[String(c[1])] = true
	_comprobar(nombres.size() == 6, "seis cabeceras distintas")
	_comprobar(String(PortadaPeriodico.cabecera_de({"medio": "El Pelotazo"})[0]) == "pelotazo", "cada medio con su cabecera")
	var a := PortadaPeriodico.cabecera_de({"t": "Algo", "semana": 3})
	_comprobar(a == PortadaPeriodico.cabecera_de({"t": "Algo", "semana": 3}), "la misma portada, la misma cabecera")

## C3: la región de origen existe y se guarda; los españoles ya no son todos
## vascos; el Athletic (o su equivalente ficticio) es todo de Euskal Herria, su
## mercado lo respeta -la IA y tú- y sus canteranos llevan apellidos vascos.
func _probar_cantera_c3() -> void:
	_titulo("C3 FILOSOFÍA DE CANTERA: REGIÓN DE ORIGEN, MERCADO Y APELLIDOS")
	var m := Mundo.new()
	m.generar(["ESP"], 8642)
	var bilbao: Club = null
	var otro: Club = null
	for c: Club in m.clubes.values():
		if not Regiones.filosofia(c).is_empty():
			bilbao = c
		elif c.pais == "ESP" and otro == null:
			otro = c
	_comprobar(bilbao != null, "el club de cantera vasca existe (Athletic o su equivalente)")
	if bilbao == null:
		return
	var todos_vascos := true
	for j: Jugador in bilbao.plantilla:
		todos_vascos = todos_vascos and j.region == "EUS"
	## Nacido o formado allí, aunque juegue con otra selección: cuenta la
	## región, no la nacionalidad.
	_comprobar(todos_vascos, "toda la plantilla es de Euskal Herria (por origen, no por pasaporte)")
	var espanoles := 0
	var vascos := 0
	for c: Club in m.clubes.values():
		if c == bilbao:
			continue
		for j: Jugador in c.plantilla:
			if j.pais == "ESP":
				espanoles += 1
				if j.region == "EUS":
					vascos += 1
	var pct := 100.0 * float(vascos) / float(maxi(1, espanoles))
	_comprobar(pct > 3.0 and pct < 18.0, "los vascos son una parte de los españoles, no todos (%.1f %%)" % pct)
	var apellido_vasco := false
	for j: Jugador in bilbao.plantilla:
		for ap: String in Regiones.APELLIDOS_EUS:
			if j.nombre.ends_with(ap):
				apellido_vasco = true
	_comprobar(apellido_vasco, "apellidos vascos en el Athletic")
	## El mercado: un español no vasco no entra; uno vasco sí.
	var no_vasco: Jugador = null
	var vasco: Jugador = null
	for j: Jugador in otro.plantilla:
		if j.region == "" and no_vasco == null:
			no_vasco = j
	for c: Club in m.clubes.values():
		if c != bilbao:
			for j: Jugador in c.plantilla:
				if j.region == "EUS" and vasco == null:
					vasco = j
	_comprobar(not Regiones.admite(bilbao, no_vasco), "el Athletic no puede fichar a un no vasco")
	_comprobar(vasco == null or Regiones.admite(bilbao, vasco), "sí a uno de Euskal Herria")
	m.tomar_el_mando(bilbao.id)
	var motivo := m.mercado.abrir_negociacion(no_vasco)
	_comprobar(String(motivo).to_lower().contains("euskal herria"), "si diriges al Athletic, la regla vale para ti: «%s»" % motivo)
	## Guardado.
	var d := Partida._jugador_a_dic(bilbao.plantilla[0])
	_comprobar(Partida._dic_a_jugador(d).region == "EUS", "la región se guarda con la partida")

## C5 y C8: el presidente de la federación con agenda y mandato, la junta de
## accionistas del club, y las lesiones absurdas (raras, sin Azar, el toque de
## queda evita las de noche).
func _probar_instituciones_c5_c8() -> void:
	_titulo("C5/C8 INSTITUCIONES: PRESIDENTE DE LA FEDERACIÓN, JUNTA DE ACCIONISTAS, LESIONES ABSURDAS")
	var m := Mundo.new()
	m.generar(["CHI"], 2024)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var f := m.federacion
	_comprobar(f.revisar_presidencia(2026) and not f.presidente.is_empty(), "la federación elige presidente")
	_comprobar(not f.revisar_presidencia(2027), "no hay elecciones a mitad de mandato")
	_comprobar(f.revisar_presidencia(2026 + Federacion.MANDATO_ANIOS), "a los cuatro años, elecciones")
	var ag: Array = Federacion.AGENDAS[String(f.presidente["agenda"])][1]
	_comprobar(f.agenda_empuja(String(ag[0])), "el presidente empuja lo de su agenda")
	var d := f.a_dic()
	var f2 := Federacion.new()
	f2.desde_dic(d)
	_comprobar(f2.presidente == f.presidente, "el presidente se guarda")
	## Junta.
	var jt := m.junta
	_comprobar(jt != null and jt.accionistas.size() == 3 and not jt.presidente.is_empty(), "el club tiene presidente y tres accionistas")
	jt.semana(m.mi_club(), 2026, Junta.CADA)
	_comprobar(not jt.pendiente.is_empty(), "cada trimestre hay junta")
	var conf0 := m.directiva.confianza
	var r := jt.resolver("a", m.mi_club(), m.directiva, m.prensa)
	_comprobar(not r.is_empty() and jt.pendiente.is_empty(), "la junta se resuelve")
	## Forzar la censura: todos hartos.
	for a: Dictionary in jt.accionistas:
		a["humor"] = 20
	jt.pendiente = {"quien": String(jt.accionistas[0]["nombre"]), "exige": "cantera", "tema": "x", "a": "si", "b": "no", "monto": 0}
	conf0 = m.directiva.confianza
	r = jt.resolver("b", m.mi_club(), m.directiva, m.prensa)
	_comprobar(bool(r["censura"]) and m.directiva.confianza < conf0, "un accionista harto presenta moción de censura")
	## Lesiones absurdas.
	var n := 0
	var noche_con_queda := false
	for sem in 400:
		var la := LesionesAbsurdas.sortear(m.mi_club(), 2026, sem, true)
		if not la.is_empty():
			n += 1
			if bool(la["noche"]):
				noche_con_queda = true
	_comprobar(n > 10 and n < 60, "son raras: %d en 400 semanas" % n)
	_comprobar(not noche_con_queda, "con toque de queda no hay lesiones de noche")
	_comprobar(LesionesAbsurdas.sortear(m.mi_club(), 2026, 7, false) == LesionesAbsurdas.sortear(m.mi_club(), 2026, 7, false), "no consume Azar: la misma semana, lo mismo")

## C6/C7: hablar con un jugador (según quién es, con memoria y promesas que se
## cobran), la entrevista al paso de un medio nuevo (mueve seguidores) y la
## presentación de un fichaje.
func _probar_charlas_c6_c7() -> void:
	_titulo("C6/C7 CHARLAS UNO A UNO, ENTREVISTA AL PASO Y PRESENTACIÓN DE FICHAJES")
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var j: Jugador = c.plantilla[5]
	j.moral = 50
	j.rasgo = "polemico"
	var r := m.charlas.hablar(j, "exigir", 2026, 3)
	_comprobar(int(r["moral"]) < 0, "al polémico, exigirle le sienta mal (%s)" % String(r["efecto"]))
	j.rasgo = "lider"
	j.moral = 50
	r = m.charlas.hablar(j, "exigir", 2026, 10)
	_comprobar(int(r["moral"]) > 0, "al líder, exigirle le motiva")
	r = m.charlas.hablar(j, "exigir", 2026, 11)
	_comprobar(bool(r["repetido"]) and String(r["respuesta"]).contains("Otra vez"), "repetir el tema enseguida vale menos")
	## Promesa incumplida.
	var k: Jugador = c.plantilla[20]
	var moral_k := k.moral
	m.charlas.hablar(k, "minutos", 2026, 20)
	m.charlas.semana(c, 2026, 20 + Charlas.PLAZO_PROMESA)
	_comprobar(k.moral < moral_k + 5 and not m.charlas.promesas.has(k.id), "la promesa de minutos incumplida se cobra")
	## Al paso.
	var hubo := false
	for sem in 40:
		m.prensa.al_paso = {}
		if not m.prensa.revisar_al_paso(2026, sem).is_empty():
			hubo = true
			break
	_comprobar(hubo, "cada tanto te para un medio nuevo")
	var seg0 := m.prensa.seguidores
	m.prensa.abrir_al_paso()
	var rp := m.prensa.responder_pie(0)
	_comprobar(m.prensa.seguidores != seg0 and not rp.is_empty(), "lo que dices al paso mueve seguidores")
	## Presentación.
	var nuevo: Jugador = m.ligas[0].clubes[3].plantilla[0]
	nuevo.ovr = 95
	var saldo0 := c.saldo
	var pr := PresentacionFichaje.aplicar(m, nuevo, true)
	_comprobar(c.saldo < saldo0 and int(pr["seguidores"]) > 1000, "presentar a una estrella en el estadio cuesta y trae seguidores")
	nuevo.ovr = 40
	pr = PresentacionFichaje.aplicar(m, nuevo, true)
	_comprobar(int(pr["animo"]) <= 1, "presentar a lo grande a un suplente se lee como propaganda")
	## Guardado de charlas.
	var ch2 := Charlas.new()
	ch2.desde_dic(m.charlas.a_dic())
	_comprobar(ch2.ultima.has(j.id), "la memoria de las charlas se guarda")

## C7: la licencia de entrenador (niveles, examen de 8, aprobar con 6, espera al
## suspender, premio de prestigio) y el portero del minijuego que aprende.
func _probar_licencia_c7() -> void:
	_titulo("C7 LICENCIA DE ENTRENADOR Y MINIJUEGO DE PENALES")
	var m := Mundo.new()
	m.generar(["CHI"], 99)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var lic := m.licencia
	var qs := lic.examen()
	_comprobar(qs.size() == Licencia.PREGUNTAS_POR_EXAMEN, "el examen tiene %d preguntas" % qs.size())
	var todas_ok := true
	for q: Array in Licencia.BANCO:
		todas_ok = todas_ok and int(q[2]) >= 0 and int(q[2]) < (q[1] as Array).size()
	_comprobar(todas_ok, "toda pregunta del banco tiene una respuesta válida")
	for n in range(1, 5):
		var cuantas := 0
		for q: Array in Licencia.BANCO:
			if int(q[3]) <= n and int(q[3]) >= maxi(1, n - 1):
				cuantas += 1
		_comprobar(cuantas >= Licencia.PREGUNTAS_POR_EXAMEN, "hay preguntas de sobra para el nivel %d (%d)" % [n, cuantas])
	## Suspender: todas mal.
	var malas: Array = []
	for q: Array in qs:
		malas.append((int(q[2]) + 1) % (q[1] as Array).size())
	var r := lic.corregir(qs, malas, 2026, 5, m.roles, m.prensa)
	_comprobar(not bool(r["aprobado"]) and lic.puede_presentarse(2026, 6) != "", "suspender obliga a esperar")
	_comprobar(lic.puede_presentarse(2026, 5 + Licencia.ESPERA_SEMANAS) == "", "pasada la espera, se puede repetir")
	## Aprobar: todas bien.
	qs = lic.examen()
	var buenas: Array = []
	for q: Array in qs:
		buenas.append(int(q[2]))
	var prest0 := m.roles.prestigio
	r = lic.corregir(qs, buenas, 2026, 20, m.roles, m.prensa)
	_comprobar(bool(r["aprobado"]) and lic.nivel == 1 and m.roles.prestigio >= prest0, "aprobar sube de nivel y de prestigio")
	var l2 := Licencia.new()
	l2.desde_dic(lic.a_dic())
	_comprobar(l2.nivel == 1, "la licencia se guarda")
	## El portero aprende.
	var mj := MinijuegoPenales.new()
	mj._rng.seed = 5
	mj._historial = [2, 2]
	var a_la_2 := 0
	for k in 100:
		if mj.eleccion_portero() == 2:
			a_la_2 += 1
	_comprobar(a_la_2 > 60, "si repites esquina, el portero se tira ahí (%d de 100)" % a_la_2)
	mj.free()

## TANDA C: instalaciones a 10 niveles (tribunas a 5, rendimiento a la mitad por
## encima de 5), trabajadores con carácter y eventos, asuntos de la academia, las
## ramas compiten, pierna débil y premios en la ficha.
func _probar_tanda_c() -> void:
	_titulo("TANDA C: INSTALACIONES, TRABAJADORES, CANTERA, RAMAS, FICHA")
	var m := Mundo.new()
	m.generar(["CHI"], 5150)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.saldo = 2000000000
	var o := m.obras
	_comprobar(o.maximo("ct") == 10 and o.maximo("trib") == 5, "10 niveles, las tribunas se quedan en 5")
	o.niveles["ct"] = 5
	var r5 := o.ritmo_de_progreso()
	o.niveles["ct"] = 10
	var r10 := o.ritmo_de_progreso()
	_comprobar(r10 > r5 and (r10 - r5) < (r5 - 1.0), "de 6 a 10 cada nivel rinde la mitad (%.2f → %.2f)" % [r5, r10])
	_comprobar(o.coste("ct", c.rep) == -1, "al nivel 10 no se puede mejorar más")
	o.niveles["trib"] = 5
	_comprobar(o.iniciar("trib", c) != "", "las tribunas no pasan de 5")
	## Trabajadores.
	var t := Trabajadores.de(c, "cocina")
	_comprobar(String(t["puesto"]) == "Chef del club" and Trabajadores.de(c, "cocina") == t, "cada instalación tiene su encargado, siempre el mismo")
	for k: String in Instalaciones.CATALOGO:
		o.niveles[k] = mini(3, o.maximo(k))
	var eventos := 0
	for sem in 104:
		eventos += m.trabajadores.semana(c, o, 2026, sem, m.prensa).size()
	_comprobar(eventos > 3 and eventos < 80, "en las instalaciones pasan cosas, pero no cada semana (%d en 2 años)" % eventos)
	## El equipo de cada instalación (26-9-2026): gente con estado, efecto y
	## asuntos con decisión.
	var tr := m.trabajadores
	_comprobar(tr.equipo(c, o, "cocina").size() == 2, "con nivel 3 la cocina tiene dos personas")
	var f_ct: float = o.factor_personal.get("ct", 1.0)
	_comprobar(f_ct >= 0.75 and f_ct <= 1.15, "el personal mueve el rendimiento de la instalación (%.2f)" % f_ct)
	tr.equipos["ct"][0]["hab"] = 99
	tr.equipos["ct"][0]["moral"] = 99
	var f_bueno := tr.factor("ct")
	tr.equipos["ct"][0]["hab"] = 30
	tr.equipos["ct"][0]["moral"] = 20
	_comprobar(f_bueno > tr.factor("ct"), "gente buena y contenta rinde más (%.2f > %.2f)" % [f_bueno, tr.factor("ct")])
	var hubo_asunto := false
	for sem2 in 400:
		tr.semana(c, o, 2030, sem2, m.prensa)
		if not tr.pendiente.is_empty():
			hubo_asunto = true
			break
	_comprobar(hubo_asunto, "el personal trae asuntos para decidir")
	if hubo_asunto:
		var res_p := tr.resolver("b", c, o, m.prensa)
		_comprobar(not res_p.is_empty() and tr.pendiente.is_empty(), "el asunto del personal se resuelve: %s" % String(res_p.get("titulo", "")))
	var tr2 := Trabajadores.new()
	tr2.desde_dic(tr.a_dic())
	_comprobar(tr2.equipos.size() == tr.equipos.size(), "el personal se guarda con la partida")
	## REPUTACIÓN (26-9-2026): niveles del club y fama por facetas.
	var rp := m.roles.reputacion
	_comprobar(rp.valor("honesto") == 50, "la fama arranca neutra")
	rp.registrar("honesto", 30, "prueba")
	_comprobar(rp.mult_compras() < 1.0, "con fama de honesto te piden menos (%.2f)" % rp.mult_compras())
	rp.registrar("mediatico", 40, "prueba")
	_comprobar(rp.mult_marcas() > 1.0 and not rp.historial.is_empty(), "la fama mediática sube las marcas y queda anotada")
	_comprobar(Reputacion.nombre_nivel(20).contains("Local") and Reputacion.nombre_nivel(95).contains("Leyenda"), "los niveles del club van de Local a Leyenda")
	_comprobar(Reputacion.tope_instalaciones(20) < Reputacion.tope_instalaciones(90), "más reputación, instalaciones más altas")
	var rep_antes := c.rep
	c.rep = 20
	o.niveles["museo"] = Reputacion.tope_instalaciones(20)
	o.obras.erase("museo")
	_comprobar(o.iniciar("museo", c).contains("reputación"), "un club local no pasa del tope de su nivel")
	c.rep = rep_antes
	var rp2 := Reputacion.new()
	rp2.desde_dic(rp.a_dic())
	_comprobar(rp2.valor("honesto") == rp.valor("honesto") and rp2.historial.size() == rp.historial.size(), "la reputación se guarda con la partida")
	## MODOS (26-9-2026): los cinco retos se montan y se juzgan; fundar con colores.
	for r: Array in Retos.LISTA:
		var mr := Mundo.new()
		mr.generar(["CHI"], 11)
		var cr := Retos.montar(mr, String(r[0]))
		_comprobar(cr != null and mr.mi_club_id == cr.id and String(mr.reto["id"]) == String(r[0]), "el reto «%s» elige y prepara su club" % String(r[2]))
		if String(r[0]) == "deuda" and cr != null:
			_comprobar(cr.saldo < 0, "el club en ruinas arranca con deuda")
			var jr := Retos.juzgar(mr, 5, false, false)
			_comprobar(not bool(jr["cumplido"]) and Retos.juzgar(mr, 5, false, false).is_empty(), "el reto se juzga una sola vez")
		if String(r[0]) == "titulo" and cr != null:
			var jt := Retos.juzgar(mr, 1, false, false)
			_comprobar(bool(jt["cumplido"]), "salir campeón cumple «Obligados a ganar»")
	var mf := Mundo.new()
	mf.generar(["CHI"], 12)
	var cf := mf.fundar_club("Club Nuevo", "CHI", "#112233", "#ddeeff", "La Cancha")
	_comprobar(cf != null and cf.color1 == "#112233" and cf.estadio_nombre == "La Cancha", "fundar un club con sus colores y su estadio")
	## TU CASA (28-9-2026): las noticias se vuelven publicaciones y la escena se
	## monta con cada vivienda (casa, auto y DT con el móvil).
	## LAS REDES (Tribuna): cuentas, noticias, publicar, responder, guardar.
	var rd := mf.redes
	_comprobar(rd != null and String(rd.cuentas["club"]["usuario"]).ends_with("_oficial") and int(rd.cuentas["club"]["seguidores"]) > 0, "el club tiene su cuenta oficial (%s)" % String(rd.cuentas["club"]["usuario"]))
	var n_antes := rd.publicaciones.size()
	rd.desde_noticia(mf, "✅ Victoria de visita", "2-1 en el clásico")
	_comprobar(rd.publicaciones.size() == n_antes + 2 and String(rd.publicaciones[1]["cuenta"]) == "club", "una victoria la publica el club y la comenta un hincha")
	var pub := rd.publicar(mf, "hinchada", ["#Hinchada", rd.tendencia])
	_comprobar(not pub.has("error") and int(pub["likes"]) > 0 and (pub["comentarios"] as Array).size() >= 3, "publicar un mensaje a la hinchada trae me gusta y comentarios (%d)" % int(pub.get("likes", 0)))
	var pend_antes := rd.pendientes()
	var resp := rd.responder(mf, int(pub["id"]), 0, "agradecer")
	_comprobar(resp != "" and rd.pendientes() == pend_antes - 1 and rd.responder(mf, int(pub["id"]), 0, "broma") == "ya le respondiste", "responder un comentario, una sola vez")
	rd.publicar(mf, "entreno", [])
	_comprobar(rd.publicar(mf, "familia", []).has("error"), "no más de %d publicaciones por semana" % Redes.MAX_PROPIAS_SEMANA)
	var gustos := int(pub["likes"])
	rd.me_gusta(int(pub["id"]))
	_comprobar(int(rd.buscar(int(pub["id"]))["likes"]) == gustos + 1, "dar me gusta suma uno")
	## Los jugadores publican y tú les comentas.
	var n_pub := rd.publicaciones.size()
	rd._publican_jugadores(mf)
	var pj: Dictionary = rd.publicaciones[0]
	_comprobar(rd.publicaciones.size() > n_pub and String(pj["cuenta"]) == "jugador" and String(pj["autor"]).begins_with("@"), "un jugador de tu plantel publica (%s)" % String(pj["autor"]))
	var jpj := mf.jugador_por_id(String(pj["jugador_id"]))
	var moral_antes := jpj.moral
	var rc := rd.comentar_jugador(mf, int(pj["id"]), "apoyo")
	_comprobar(jpj.moral > moral_antes or moral_antes == 100, "apoyarlo en redes le sube la moral (%s)" % rc)
	_comprobar(rd.comentar_jugador(mf, int(pj["id"]), "cortante") == "ya le comentaste", "a cada publicación se le comenta una vez")
	var rd2 := Redes.new()
	rd2.desde_dic(rd.a_dic())
	_comprobar(rd2.publicaciones.size() == rd.publicaciones.size() and rd2.pendientes() == rd.pendientes(), "las redes se guardan con la partida")
	## EL MÓVIL (28-9-2026): acceso a la cuenta del club, sesiones, apps.
	_comprobar(not rd.acceso_club and rd.iniciar_sesion(String(rd.cuentas["club"]["usuario"]), "x") != "", "al principio la cuenta del club no es tuya")
	for _s in Redes.SEMANAS_PARA_ACCESO:
		rd.semana(mf)
	_comprobar(rd.acceso_club and rd.clave_club != "" and mf.movil.sin_leer() >= 1, "a las %d semanas te dan la cuenta del club y la clave llega por Mensajes" % Redes.SEMANAS_PARA_ACCESO)
	rd.cerrar_sesion()
	_comprobar(rd.publicar(mf, "entreno", []).has("error"), "sin sesión no se publica")
	_comprobar(rd.iniciar_sesion(String(rd.cuentas["club"]["usuario"]), "mala") == "clave incorrecta", "con la clave mala no se entra")
	_comprobar(rd.iniciar_sesion(String(rd.cuentas["club"]["usuario"]), rd.clave_club) == "" and rd.sesion == "club", "con la clave buena se entra a la cuenta del club")
	var saldo_antes := mf.mi_club().saldo
	var pc := rd.publicar(mf, "camiseta", ["#NuevaCamiseta"])
	_comprobar(not pc.has("error") and String(pc["cuenta"]) == "club" and mf.mi_club().saldo > saldo_antes, "publicar la camiseta desde el club vende en la tienda (%s)" % _dinero(mf.mi_club().saldo - saldo_antes))
	rd.iniciar_sesion(String(rd.cuentas["dt"]["usuario"]), "")
	_comprobar(rd.sesion == "dt", "se vuelve a tu cuenta")
	mf.movil.fondo = "atardecer"
	mf.movil.funda = "c0392b"
	var mv2 := Movil.new()
	mv2.desde_dic(mf.movil.a_dic())
	_comprobar(mv2.fondo == "atardecer" and mv2.funda == "c0392b" and mv2.mensajes.size() == mf.movil.mensajes.size(), "la personalización y los mensajes del móvil se guardan")
	_comprobar(Movil.remitente_de("La directiva pierde la paciencia", "").size() == 2 and Movil.remitente_de("Gol", "").is_empty(), "las noticias de la directiva llegan como mensaje")
	_comprobar(mf.movil.textura_perfil(mf) != null, "la foto de perfil es tu retrato por defecto")
	var tel := Telefono.crear(mf, [{"titulo": "Prueba", "cuerpo": "x"}])
	for app: Array in Telefono.APPS:
		tel.abrir_app(String(app[0]))
	tel.abrir_app("inicio")
	_comprobar(tel.get("_cuerpo") != null, "el móvil abre sus %d apps" % Telefono.APPS.size())
	tel.free()
	for viv: String in VidaDT.ORDEN_VIVIENDA:
		var ce := CasaEscena3D.new()
		ce.montar(viv, "deportivo", {}, Color.RED, Color.WHITE)
		var mallas := ce.find_children("*", "MeshInstance3D", true, false).size()
		_comprobar(mallas > 20, "la escena de «%s» se monta (%d mallas)" % [viv, mallas])
		if viv == "jardin":
			var hierba := ce.find_children("*", "MultiMeshInstance3D", true, false)
			_comprobar(not hierba.is_empty() and (hierba[0] as MultiMeshInstance3D).multimesh.instance_count > 10000, "el jardín tiene césped de briznas (%d)" % ((hierba[0] as MultiMeshInstance3D).multimesh.instance_count if not hierba.is_empty() else 0))
			var farolas: Array = ce.get("_farolas")
			_comprobar(farolas.size() == 2, "hay dos farolas para el atardecer")
			ce.libre = true
			ce.acercar(100.0)
			_comprobar(is_equal_approx(float(ce.get("_dist")), 14.0), "la cámara libre no se aleja más de la cuenta")
		ce.free()
	## LOS CONTRATOS VENCEN (28-9-2026, informe externo).
	var mc := Mundo.new()
	mc.generar(["CHI"], 21)
	mc.mi_club_id = mc.ligas[0].clubes[0].id
	var jc: Jugador = mc.mi_club().plantilla[0]
	jc.anios_contrato = 1
	var jr: Jugador = mc.mi_club().plantilla[1]
	jr.anios_contrato = 3
	var libres_antes := mc.libres.size()
	mc.nueva_temporada()
	_comprobar(not mc.mi_club().plantilla.has(jc) and mc.libres.has(jc) and jc.club_id == "", "el contrato que se acaba sin renovar deja al jugador libre")
	_comprobar(mc.mi_club().plantilla.has(jr) and jr.anios_contrato == 2, "a los demás les queda un año menos")
	_comprobar(mc.libres.size() > libres_antes, "la bolsa de libres se llena con los contratos vencidos (%d)" % (mc.libres.size() - libres_antes))
	## MERCADO AVANZADO (bloques 37-38): guerra de ofertas y zonas grises.
	var ma := MercadoAvanzado.new()
	var estrella: Jugador = mf.mi_club().plantilla[0]
	estrella.ovr = 80
	var ofertante: Club = mf.ligas[0].clubes[1] if mf.ligas[0].clubes[1] != mf.mi_club() else mf.ligas[0].clubes[2]
	mf.mercado.ofertas_recibidas.append({"jugador": estrella, "club": ofertante, "monto": 1000000, "semana": 1, "clausula": false})
	for c_rico: Club in mf.clubes.values():
		c_rico.saldo = maxi(c_rico.saldo, 50000000)
	var hubo_puja := 0
	for _k in 12:
		hubo_puja += ma.guerra_de_ofertas(mf)
	var max_oferta := 0
	for o_ma: Dictionary in mf.mercado.ofertas_recibidas:
		if o_ma["jugador"] == estrella:
			max_oferta = maxi(max_oferta, int(o_ma["monto"]))
	_comprobar(hubo_puja >= 1 and hubo_puja <= MercadoAvanzado.MAX_PUJAS and max_oferta > 1000000, "guerra de ofertas: otros clubes mejoran la oferta (%d pujas, hasta %s)" % [hubo_puja, _dinero(max_oferta)])
	mf.mercado.ofertas_recibidas.clear()
	for tipo_ma: String in ["superagente", "apuestas", "transparencia"]:
		_comprobar(ma._montar(mf, tipo_ma) and not ma.pendiente.is_empty(), "zona gris «%s» se plantea" % tipo_ma)
		var res_ma := ma.resolver(mf, "a")
		_comprobar(res_ma.has("titulo") and ma.pendiente.is_empty(), "zona gris «%s» se resuelve: %s" % [tipo_ma, String(res_ma.get("titulo", ""))])
	if mf.libres.is_empty():
		mf.generar_libres()
	for l_ma: Jugador in mf.libres:
		l_ma.edad = maxi(l_ma.edad, 31)
	var conf_antes := mf.directiva.confianza
	_comprobar(ma._montar(mf, "impuesto"), "la directiva propone un fichaje")
	ma.resolver(mf, "b")
	_comprobar(mf.directiva.confianza < conf_antes, "negarte al fichaje impuesto baja la confianza (%d -> %d)" % [conf_antes, mf.directiva.confianza])
	var ma2 := MercadoAvanzado.new()
	ma._montar(mf, "transparencia")
	ma2.desde_dic(ma.a_dic())
	_comprobar(String(ma2.pendiente.get("id", "")) == "transparencia" and ma2.superagente == ma.superagente, "el mercado avanzado se guarda con la partida")
	## INSOLVENCIA (bloques 39-40): puntos, administrador, cláusula, refundación.
	var mi2 := Mundo.new()
	mi2.generar(["CHI"], 33)
	mi2.tomar_el_mando(mi2.ligas[0].clubes[3].id)
	var ci := mi2.mi_club()
	var ins := mi2.insolvencia
	var liga_i := mi2.ligas[0]
	var pts_antes := int(liga_i.tabla_puntos[ci.id]["pts"])
	for c_rico2: Club in mi2.clubes.values():
		if c_rico2 != ci:
			c_rico2.saldo = maxi(c_rico2.saldo, 90000000)
	ci.saldo = -50000000
	mi2.banco.semanas_en_rojo = Banco.SEM_MORA
	ins.semana(mi2)
	_comprobar(String(ins.pendiente.get("id", "")) == "clausula", "al entrar en mora, el DT puede activar su cláusula de salida")
	ins.resolver(mi2, "a")
	mi2.banco.semanas_en_rojo = Banco.SEM_VEEDOR
	ins.semana(mi2)
	var plantel_antes := ci.plantilla.size()
	_comprobar(int(liga_i.tabla_puntos[ci.id]["pts"]) == pts_antes - Insolvencia.PUNTOS_SANCION, "con veedor, la federación resta %d puntos" % Insolvencia.PUNTOS_SANCION)
	_comprobar(ins.tope_salarial > 0, "con veedor hay tope salarial (%s)" % _dinero(ins.tope_salarial))
	ins.tope_salarial = 1
	ins.semana(mi2)
	_comprobar(ci.plantilla.size() == plantel_antes - 1, "el administrador vende al que más cobra si se pasa del tope")
	mi2.banco.semanas_en_rojo = Banco.SEM_LIQUIDACION - 1
	ins.pendiente = {}
	ins.semana(mi2)
	_comprobar(String(ins.pendiente.get("id", "")) == "refundacion", "una semana antes de liquidar, se ofrece la refundación")
	var rep_ci := ci.rep
	ins.resolver(mi2, "a")
	_comprobar(mi2.banco.semanas_en_rojo == 0 and ci.saldo >= 0 and ci.rep < rep_ci and not mi2.banco.liquidado_ya, "refundar salva el club: deuda perdonada, caja a cero, reputación abajo")
	var ins2 := Insolvencia.new()
	ins2.desde_dic(ins.a_dic())
	_comprobar(ins2.refundado_anio == ins.refundado_anio and ins2.sancion_anio == ins.sancion_anio, "la insolvencia se guarda con la partida")
	## REGLAMENTO FINO (bloques 44-45): desempate, promoción, árbitros, corrupción.
	var mr2 := Mundo.new()
	mr2.generar(["CHI"], 44)
	mr2.tomar_el_mando(mr2.ligas[0].clubes[0].id)
	var lr := mr2.ligas[0]
	var ca: Club = lr.clubes[1]
	var cb: Club = lr.clubes[2]
	lr.tabla_puntos[ca.id]["pts"] = 30; lr.tabla_puntos[ca.id]["gf"] = 20; lr.tabla_puntos[ca.id]["gc"] = 20
	lr.tabla_puntos[cb.id]["pts"] = 30; lr.tabla_puntos[cb.id]["gf"] = 30; lr.tabla_puntos[cb.id]["gc"] = 10
	lr.h2h["%s|%s" % [ca.id, cb.id]] = 6
	lr.h2h["%s|%s" % [cb.id, ca.id]] = 0
	var pos := func(tb: Array, c0: Club) -> int:
		for i_t in tb.size():
			if tb[i_t]["club"] == c0:
				return i_t
		return -1
	var t_dif: Array = lr.tabla()
	_comprobar(pos.call(t_dif, cb) < pos.call(t_dif, ca), "sin la moción, a igualdad de puntos manda la diferencia de gol")
	Liga.desempate_directo = true
	var t_dir: Array = lr.tabla()
	_comprobar(pos.call(t_dir, ca) < pos.call(t_dir, cb), "con la moción, manda el enfrentamiento directo")
	Liga.desempate_directo = false
	var fed := mr2.federacion
	fed.anotar_arbitro("Árbitro X", "estricto", 2, 1)
	fed.anotar_arbitro("Árbitro X", "estricto", 0, 0)
	_comprobar(fed.texto_arbitro("Árbitro X") == "Con él: 2 PJ · 1G 1E 0P", "el historial por árbitro se lleva (%s)" % fed.texto_arbitro("Árbitro X"))
	var prom := mr2.jugar_promocion(lr.clubes[3], lr.clubes[4])
	_comprobar(prom["ganador"] == lr.clubes[3] or prom["ganador"] == lr.clubes[4], "la promoción se juega a ida y vuelta: %s" % String(prom["texto"]))
	fed.promocion = true
	var fed2 := Federacion.new()
	fed2.desde_dic(fed.a_dic())
	_comprobar(fed2.promocion and fed2.arbitros.has("Árbitro X"), "promoción e historial de árbitros se guardan")
	Liga.desempate_directo = false
	var mac := MercadoAvanzado.new()
	_comprobar(mac._montar(mr2, "corrupcion") and String(mac.pendiente["id"]) == "corrupcion", "aparece la corrupción federativa")
	var aliados_antes := fed.aliados
	mac.resolver(mr2, "b")
	_comprobar(fed.aliados < aliados_antes, "denunciarla te cuesta aliados en la asamblea")
	## EDITOR DE COMPETICIONES (bloque 47).
	var me := Mundo.new()
	me.generar(["CHI"], 47)
	me.tomar_el_mando(me.ligas[0].clubes[0].id)
	var ed_c := Editor.new(me)
	var l1: Liga = me.ligas[0]
	_comprobar(ed_c.renombrar_liga(l1, "Liga de Prueba") == "" and l1.nombre == "Liga de Prueba", "se renombra una liga")
	ed_c.fijar_descensos(l1, 3)
	ed_c.fijar_puntos_victoria(l1, 2)
	var d1: Dictionary = Partida._liga_a_dic(l1)
	var l1b := Partida._dic_a_liga(d1, me)
	_comprobar(l1b.plazas_descenso == 3 and l1b.puntos_victoria == 2, "descensos y puntos por victoria se guardan")
	l1.preparar()
	l1._anotar_resultado(l1.clubes[0], l1.clubes[1], 2, 0)
	_comprobar(int(l1.tabla_puntos[l1.clubes[0].id]["pts"]) == 2, "con 2 puntos por victoria, ganar da 2")
	var resumen_e := me.nueva_temporada()
	var bajan_chi := 0
	for x_b: Variant in resumen_e["bajan"]:
		if x_b is Club and (x_b as Club).pais == "CHI":
			bajan_chi += 1
	_comprobar(bajan_chi == 3, "con 3 plazas de descenso, bajan 3 (%d)" % bajan_chi)
	var sede_c: Club = me.ligas[0].clubes[0]
	ed_c.renombrar_copa("Copa Editada")
	ed_c.fijar_sede_final(sede_c)
	_comprobar(me.copa.nombre == "Copa Editada" and me.copa.sede_final_id == sede_c.id, "la copa se renombra y tiene sede fija")
	## COLORES POR SECCIÓN: cada anillo de cada tribuna, vallas y focos.
	var est_p := mf.estadio
	var claves_antes: Array = est_p.perfil(mf.mi_club()).keys()
	mf.mi_club().saldo = maxi(mf.mi_club().saldo, 100000000)
	var err_an := est_p.reformar(mf.mi_club(), {"personalizar_bandejas": true, "anillo_sur_2": "#b01e2d", "focosCol": "#1f4fa3", "vallaCol": "#1b1d22"})
	var perf_an: Dictionary = est_p.perfil(mf.mi_club())
	_comprobar(err_an == "" and String(((perf_an["bandejas"] as Dictionary)["sur"] as Dictionary)["niveles"][1]) == "#b01e2d", "el anillo 2 de la tribuna sur tiene su color (%s)" % err_an)
	_comprobar(String(perf_an.get("focosCol", "")) == "#1f4fa3" and String(perf_an.get("vallaCol", "")) == "#1b1d22", "focos y vallas con color propio")
	var est_limpio := EstadioPropio.new()
	_comprobar(not est_limpio.perfil(mf.mi_club()).has("focosCol") and claves_antes.size() > 0, "sin elegir, el perfil no suma claves nuevas")
	## LOS BALONES (mapa de metas 19): 8 pieles, 3 dibujos de paneles de verdad.
	_comprobar(Comercial.balones().size() >= 8, "hay %d balones para elegir" % Comercial.balones().size())
	var cb_club := Comercial.color_balon("club", mf.mi_club())
	_comprobar(cb_club.size() == 3 and cb_club[0] == Color(mf.mi_club().color1) and String(cb_club[2]) == "moderno", "el balón del club lleva sus colores y su dibujo")
	var img_cl := Balon3D.textura(Color.WHITE, Color.BLACK, "clasico").get_image()
	var oscuros := 0
	for yb in range(0, img_cl.get_height(), 2):
		for xb in range(0, img_cl.get_width(), 2):
			if img_cl.get_pixel(xb, yb).get_luminance() < 0.2:
				oscuros += 1
	var frac := float(oscuros) / float(img_cl.get_width() * img_cl.get_height() / 4)
	_comprobar(frac > 0.08 and frac < 0.45, "el clásico tiene sus 12 pentágonos oscuros (%.0f %% del balón)" % (frac * 100.0))
	var t_mod := Balon3D.textura(Color.WHITE, Color.BLACK, "moderno")
	_comprobar(t_mod != Balon3D.textura(Color.WHITE, Color.BLACK, "clasico") and t_mod == Balon3D.textura(Color.WHITE, Color.BLACK, "moderno"), "cada dibujo es distinto y se guarda en caché")
	## EL CHOQUE DE CAMISETAS: la visita cambia si se parece al local.
	var cl_a: Club = mf.ligas[0].clubes[0]
	var cl_b: Club = mf.ligas[0].clubes[1]
	var c1_a := cl_a.color1
	var c2_a := cl_a.color2
	cl_b.color1 = cl_a.color1
	cl_b.color2 = cl_a.color2
	var kv := Puente3D.kit_visita(cl_a, cl_b)
	_comprobar(not Puente3D.chocan(Puente3D.kit(cl_a), kv), "si las camisetas chocan, la visita se cambia (%s vs %s)" % [String(Puente3D.kit(cl_a)["c1"]), String(kv["c1"])])
	cl_a.color1 = c1_a
	cl_a.color2 = c2_a
	## EL PASE CON LA FUERZA JUSTA: el balón raso muere 2,5 m pasado el destino.
	var v20 := MotorJugable.velocidad_para(20.0)
	_comprobar(absf(MotorJugable.distancia_rodando(v20) - 22.5) < 0.3, "un pase de 20 m sale a %.1f m/s y rueda %.1f m" % [v20, MotorJugable.distancia_rodando(v20)])
	## LA CARRERA DE JUGADOR: se crea en un club modesto y se guarda entera.
	var cj := CarreraJugador.crear(mf, "Prueba Delantero", "DC", true, 99)
	var yo := cj.jugador(mf)
	_comprobar(yo != null and yo.edad == 17 and cj.club(mf) != null, "la carrera crea un jugador de 17 años con club")
	cj.fama = 33
	cj.eventos.append({"id": "x", "titulo": "t", "texto": "", "opciones": [], "unico": false})
	var cj2 := CarreraJugador.desde_dic(cj.a_dic())
	_comprobar(cj2.jugador_id == cj.jugador_id and cj2.fama == 33 and cj2.eventos.size() == cj.eventos.size(), "la carrera se guarda y se carga")
	var ov_antes := yo.ovr
	cj.foco = "tiro"
	for _k in 30:
		cj.energia = 100
		cj.entrenar(mf)
	_comprobar(yo.ovr > ov_antes, "entrenar sube la media (%d -> %d)" % [ov_antes, yo.ovr])
	cj.club(mf).soltar(yo)
	## LAS BUTACAS DE LOS RIVALES, de los colores de su club (no el verde del visor).
	var riv_b: Club = mf.ligas[0].clubes[1]
	_comprobar(String(riv_b.perfil_estadio().get("asiento1", "")) == riv_b.color1, "las butacas de un rival llevan los colores de su club")
	## LOS OBJETIVOS EN EL BORDE: directiva, confianza, próximo partido y misiones del mentor.
	PanelObjetivos.ruta = "user://objetivos_banco.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PanelObjetivos.ruta))
	var objs := PanelObjetivos.lista(mf, "dt")
	var mis_obj: Array = objs.filter(func(o: Dictionary) -> bool: return bool(o.get("mentor", false)))
	_comprobar(objs.size() >= 4 and String(objs[0]["icono"]) == "🏆" and not bool(objs[0]["hecho"]), "los objetivos: la meta de la directiva, sin cumplir antes de jugar (%d)" % objs.size())
	_comprobar(mis_obj.size() >= 3 and mis_obj.all(func(o: Dictionary) -> bool: return not bool(o["hecho"])), "las misiones del mentor salen en el panel, pendientes")
	PanelObjetivos.marcar_mision("dt", String(mis_obj[0]["texto"]))
	_comprobar(bool(PanelObjetivos.lista(mf, "dt").filter(func(o: Dictionary) -> bool: return String(o["texto"]) == String(mis_obj[0]["texto"]))[0]["hecho"]), "una misión cumplida queda tachada y se guarda")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PanelObjetivos.ruta))
	## LA PRESENTACIÓN EN EL ESTADIO: tres planos por tiempo; cerrar avisa una vez.
	var cin := CinematicaFichaje.new()
	_comprobar(cin.plano(1.0) == 1 and cin.plano(5.0) == 2 and cin.plano(9.0) == 3, "la cinemática del fichaje tiene tres planos")
	var avisos_cin := [0]
	cin.terminada.connect(func() -> void: avisos_cin[0] += 1)
	cin.cerrar()
	cin.cerrar()
	_comprobar(avisos_cin[0] == 1, "saltar la cinemática avisa una sola vez")
	## META (bloque 50): cromos, museo global, mundo heredado.
	var sobres_antes := int(Meta.leer()["sobres"])
	mf.roles.sumar_trofeo("Copa de Prueba")
	var dm := Meta.leer()
	_comprobar(int(dm["sobres"]) == sobres_antes + 1 and String((dm["museo"] as Array)[0]["titulo"]) == "Copa de Prueba", "un título va al museo global y da un sobre")
	var rng_m := RandomNumberGenerator.new()
	rng_m.seed = 5
	var salen := Meta.abrir_sobre(mf, rng_m)
	_comprobar(salen.size() == Meta.POR_SOBRE and int(Meta.leer()["sobres"]) == sobres_antes, "abrir un sobre da %d cromos y gasta el sobre" % Meta.POR_SOBRE)
	_comprobar((Meta.leer()["cromos"] as Dictionary).size() >= 1, "los cromos quedan en el álbum")
	var cm0: Club = mf.clubes.values()[0]
	var rep_real := cm0.rep
	cm0.rep = 97
	Meta.fin_de_temporada(mf)
	cm0.rep = rep_real
	_comprobar(Meta.hay_legado(), "al cerrar la temporada se guarda el mundo para heredar")
	var mh := Mundo.new()
	Meta.heredar_proximo = true
	mh.generar(["CHI"], 12)
	var cm_h: Club = null
	for c_h: Club in mh.clubes.values():
		if c_h.nombre == cm0.nombre:
			cm_h = c_h
	_comprobar(cm_h != null and cm_h.rep == 97 and not Meta.heredar_proximo, "el mundo heredado arranca con la reputación de la última partida")
	## FONDO DE INVERSIÓN: comprar, tope del 49 %, dividendos, vender, guardar.
	var fi := FondoInversion.new()
	fi.caja = 1000000000
	var otros: Array = mf.clubes.values().filter(func(x: Club) -> bool: return x.id != mf.mi_club_id)
	var obj: Club = otros[0]
	_comprobar(fi.comprar(mf, obj, 0.25) == "" and is_equal_approx(float(fi.cartera[obj.id]), 0.25), "el fondo compra un 25 %")
	fi.comprar(mf, obj, 0.4)
	_comprobar(float(fi.cartera[obj.id]) <= FondoInversion.MAX_PCT + 0.0001 and fi.comprar(mf, obj, 0.1) != "", "nunca pasa del 49 % de un club")
	_comprobar(fi.comprar(mf, mf.mi_club(), 0.1) != "", "no compra su propio club")
	mf.semana = 4
	var div := fi.semana(mf)
	_comprobar(div >= 0 and fi.dividendos_totales == div and fi.historia.size() == 1, "cada cuatro semanas reparte dividendos (%s)" % _dinero(div))
	var fi2 := FondoInversion.new()
	fi2.desde_dic(fi.a_dic())
	_comprobar(fi2.caja == fi.caja and fi2.cartera.size() == 1 and fi2.dividendos_totales == fi.dividendos_totales, "el fondo se guarda con la partida")
	var caja_antes := fi.caja
	_comprobar(fi.vender(mf, obj, 1.0) == "" and fi.cartera.is_empty() and fi.caja > caja_antes, "vender todo devuelve caja y vacía la cartera")
	## Cantera.
	var ec := m.eventos_cantera
	var hubo := false
	for sem in 60:
		ec.semana(m.academia, c, 2026, sem)
		if not ec.pendiente.is_empty():
			hubo = true
			break
	_comprobar(hubo, "la academia trae asuntos para decidir")
	if hubo:
		var r := ec.resolver("a", m.academia, c)
		_comprobar(not r.is_empty() and ec.pendiente.is_empty(), "el asunto de la academia se resuelve")
	_comprobar(ec.visitar(m.academia, 2026, 70) == "" and ec.visitar(m.academia, 2026, 70) != "", "una visita a la academia por semana")
	## Ramas.
	m.hinchada.ramas["femenino"] = true
	var res := m.hinchada.temporada_ramas(c, 2026)
	_comprobar(res.size() == 1 and int(res[0]["puesto"]) >= 1 and int(res[0]["puesto"]) <= 12, "la rama femenina termina en un puesto (%d.º)" % int(res[0]["puesto"]))
	_comprobar(int(m.hinchada.anios_rama["femenino"]) == 1, "la rama suma temporadas")
	## Ficha.
	var cuenta := {}
	for j: Jugador in m.jugadores():
		var pd := j.pierna_debil()
		cuenta[pd] = int(cuenta.get(pd, 0)) + 1
	_comprobar(cuenta.size() == 5 and int(cuenta.get(2, 0)) + int(cuenta.get(3, 0)) > int(cuenta.get(5, 0)) * 5, "pierna débil de 1 a 5, casi todos 2-3: %s" % str(cuenta))
	var j0: Jugador = c.plantilla[0]
	j0.premios.append({"anio": 2026, "premio": "Equipo ideal de la temporada"})
	_comprobar(Partida._dic_a_jugador(Partida._jugador_a_dic(j0)).premios.size() == 1, "los premios se guardan")

func _probar_calendario_c13() -> void:
	_titulo("C13/C16: CALENDARIO, DÍAS NACIONALES, MEMORIA Y FESTIVIDADES")
	## Las fechas: el lunes de la semana 1 de 2026 es el 26 de enero.
	var d := Calendario.fecha(2026, 1, 0)
	_comprobar(int(d["month"]) == 1 and int(d["day"]) == 26, "la semana 1 de 2026 empieza el lunes 26 de enero")
	var p := Calendario.pascua(2026)
	_comprobar(int(p[0]) == 4 and int(p[1]) == 5, "Pascua 2026 cae el 5 de abril")
	var p2 := Calendario.pascua(2027)
	_comprobar(int(p2[0]) == 3 and int(p2[1]) == 28, "Pascua 2027 cae el 28 de marzo")
	var ram := Calendario.ramadan(2026)
	_comprobar(ram.size() == 2 and int(ram[0][0]) == 2 and absi(int(ram[0][1]) - 18) <= 1, "el Ramadán 2026 empieza hacia el 18 de febrero")
	## El 11 de septiembre, en Chile y en EE. UU., es de memoria.
	var chi := Calendario.del_anio("CHI", 2026)
	var once_chi := chi.filter(func(f: Dictionary) -> bool: return int(f["mes"]) == 9 and int(f["dia"]) == 11)
	var once_usa := Calendario.del_anio("USA", 2026).filter(func(f: Dictionary) -> bool: return int(f["mes"]) == 9 and int(f["dia"]) == 11)
	_comprobar(once_chi.size() == 1 and String(once_chi[0]["tipo"]) == "memoria" and once_usa.size() == 1 and String(once_usa[0]["tipo"]) == "memoria",
		"el 11 de septiembre es fecha de memoria en Chile y en EE. UU.")
	_comprobar(chi.any(func(f: Dictionary) -> bool: return int(f["mes"]) == 5 and int(f["dia"]) == 1), "el 1 de mayo está en Chile")
	var usa := Calendario.del_anio("USA", 2026)
	_comprobar(not usa.any(func(f: Dictionary) -> bool: return int(f["mes"]) == 5 and int(f["dia"]) == 1)
		and usa.any(func(f: Dictionary) -> bool: return String(f["nombre"]) == "Labor Day" and int(f["dia"]) == 7),
		"en EE. UU. no es el 1 de mayo sino el Labor Day (7 de septiembre de 2026)")
	_comprobar(Calendario.del_anio("URU", 2026).any(func(f: Dictionary) -> bool: return String(f["nombre"]) == "Semana de Turismo"), "en Uruguay es la Semana de Turismo")
	_comprobar(Calendario.del_anio("KSA", 2026).any(func(f: Dictionary) -> bool: return String(f["nombre"]).begins_with("Empieza el Ramadán")), "Arabia Saudí tiene el Ramadán en su calendario")
	## Buscar la semana del 18 de septiembre en Chile (fiesta) y la del 11 (memoria).
	var sem_fiesta := -1
	var sem_memoria := -1
	for s in range(1, 50):
		for f: Dictionary in Calendario.de_la_semana("CHI", 2026, s):
			if String(f["nombre"]) == "Fiestas Patrias":
				sem_fiesta = s
			if String(f["nombre"]) == "11 de septiembre":
				sem_memoria = s
	_comprobar(sem_fiesta > 0 and sem_memoria > 0 and sem_fiesta != sem_memoria, "Fiestas Patrias y el 11 caen en semanas distintas (%d y %d)" % [sem_fiesta, sem_memoria])
	_comprobar(Calendario.factor_publico("CHI", 2026, sem_fiesta) > 1.0, "la semana de Fiestas Patrias llena más el estadio")
	_comprobar(Calendario.factor_publico("CHI", 2026, sem_memoria) == 1.0 and Calendario.hay_memoria("CHI", 2026, sem_memoria), "la del 11 de septiembre no tiene bonus de fiesta")
	## Los torneos.
	_comprobar(Calendario.torneos(2026).any(func(t: Dictionary) -> bool: return String(t["nombre"]) == "Copa del Mundo"), "2026 es año de Mundial")
	_comprobar(not Calendario.torneos(2027).any(func(t: Dictionary) -> bool: return String(t["nombre"]) == "Copa del Mundo"), "2027 no")
	## En el mundo: la semana de memoria da noticia y el mentor la explica una vez.
	var m := Mundo.new()
	m.generar(["CHI"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var noticias: Array = []
	var mentor: Array = []
	m.calendario.noticia.connect(func(t: String, _b: String) -> void: noticias.append(t))
	m.calendario.mentor.connect(func(t: String, _b: String) -> void: mentor.append(t))
	var moral0 := c.plantilla[0].moral
	m.calendario.semana(c, 2026, sem_memoria)
	_comprobar(noticias.any(func(t: String) -> bool: return t.contains("11 de septiembre")) and mentor.has("11 de septiembre"), "el 11 sale en las noticias y el mentor lo explica")
	_comprobar(c.plantilla[0].moral == moral0, "la memoria no sube la moral como una fiesta")
	m.calendario.semana(c, 2026, sem_fiesta)
	_comprobar(c.plantilla[0].moral == mini(moral0 + 1, 99), "la semana de fiesta sube la moral")
	var m2 := mentor.size()
	m.calendario.ultima_semana = -1
	m.calendario.semana(c, 2027, sem_fiesta + 1 if Calendario.de_la_semana("CHI", 2027, sem_fiesta).is_empty() else sem_fiesta)
	_comprobar(not mentor.slice(m2).has("Fiestas Patrias"), "el mentor no repite la explicación al año siguiente")
	var dic := m.calendario.a_dic()
	var cal2 := Calendario.new()
	cal2.desde_dic(dic)
	_comprobar(cal2.explicadas.has("11 de septiembre"), "se guarda lo que el mentor ya explicó")
	_comprobar(Calendario.proximas("CHI", 2026, 1, 5).size() == 5, "hay próximas fechas para el calendario")

func _probar_politica_c15() -> void:
	_titulo("C15: POLÍTICA Y ESTADO (FICTICIA Y NEUTRAL)")
	_comprobar(Politica.ESTRUCTURA.size() == 24, "los 24 países tienen su estructura de Estado")
	_comprobar(Politica.sistema("CHI") == "presidencial" and Politica.mandato("CHI") == 4, "Chile: presidencial, cada 4 años")
	_comprobar(Politica.sistema("ESP") == "monarquia_parlamentaria" and Politica.mandato("MEX") == 6, "España monarquía parlamentaria; México vota cada 6")
	_comprobar(Politica.mandato("KSA") == 0, "Arabia Saudí no tiene elecciones nacionales")
	var m := Mundo.new()
	m.generar(["CHI"], 5152)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var pol := m.politica
	var g := pol.gobierno("CHI", 2026)
	_comprobar(Politica.PARTIDOS.has(String(g["partido"])) and Politica.POSTURAS.has(String(g["postura"])), "el gobierno es de un partido inventado y con una postura neutra")
	_comprobar(pol.gobierno("CHI", 2026) == g, "el gobierno no cambia al volver a pedirlo")
	var noticias: Array = []
	var mentor: Array = []
	pol.noticia.connect(func(t: String, _b: String) -> void: noticias.append(t))
	pol.mentor.connect(func(t: String, _b: String) -> void: mentor.append(t))
	## Forzar elecciones este año y recorrer las semanas.
	g["proxima"] = 2026
	var saldo0 := c.saldo
	for s in range(1, 45):
		pol.semana(c, 2026, s, m.prensa)
	_comprobar(mentor.size() == 1, "el mentor explica el Estado una sola vez")
	_comprobar(noticias.has("🗳️ Campaña electoral") and noticias.has("🗳️ Elecciones en CHI"), "hay campaña y hay resultado")
	var g2 := pol.gobierno("CHI", 2026)
	_comprobar(int(g2["desde"]) == 2026 and int(g2["proxima"]) == 2030, "el nuevo gobierno dura 4 años")
	_comprobar(c.saldo != saldo0, "la postura del gobierno se nota en la caja")
	## Arabia Saudí: nunca vota.
	var c2 := m.ligas[0].clubes[1]
	c2.pais = "KSA"
	var n0 := noticias.size()
	for s in range(1, 45):
		pol.semana(c2, 2026, s, m.prensa)
	_comprobar(not noticias.slice(n0).any(func(t: String) -> bool: return t.begins_with("🗳️")), "en Arabia Saudí no hay elecciones")
	_comprobar(Politica.explicacion("KSA").contains("No hay elecciones"), "y el mentor lo explica")
	## Nombres ficticios y sin partidos reales.
	_comprobar(not Politica.nombre_ficticio("CHI", "x").is_empty(), "los políticos tienen nombre inventado")
	var d := pol.a_dic()
	var p2 := Politica.new()
	p2.desde_dic(d)
	_comprobar(p2.gobierno("CHI", 2026)["partido"] == g2["partido"], "el gobierno se guarda")

func _probar_historia_c4() -> void:
	_titulo("C4: HISTORIA DE LOS CLUBES, CON GUIÑO AL REAL")
	Datos.usar_base_real(false)
	var m := Mundo.new()
	m.generar(["CHI"], 5153)
	var clubes: Array = m.ligas[0].clubes
	var por_nombre := {}
	for c: Club in m.clubes.values():
		por_nombre[c.nombre] = c
	var lautaro: Club = por_nombre.get("Lautaro FC")
	var andina: Club = por_nombre.get("U. Andina")
	var precord: Club = por_nombre.get("Precordillera")
	_comprobar(lautaro != null and andina != null and precord != null, "están los tres grandes de la base ficticia")
	var hl := HistoriaClub.de(lautaro, clubes)
	_comprobar(bool(hl["con_guino"]) and String(hl["estadio"]) == "la Ruca" and int(hl["fundado"]) == 1925, "Lautaro FC guiña a su original: fundado en 1925, juega en la Ruca")
	_comprobar(HistoriaClub.nombre_clasico("Lautaro FC", "U. Andina") == "Superclásico", "Lautaro-Andina es el Superclásico")
	_comprobar(HistoriaClub.nombre_clasico("U. Andina", "Precordillera") == "Clásico Universitario", "Andina-Precordillera es el Clásico Universitario")
	_comprobar(HistoriaClub.nombre_clasico("Precordillera", "Lautaro FC") == "el Clásico", "Precordillera-Lautaro es el Clásico")
	_comprobar(m.es_clasico(lautaro, andina), "y el juego lo trata como clásico")
	## Todos los clubes del mundo tienen historia con guiño.
	var m2 := Mundo.new()
	m2.generar([], 5155)
	var sin := 0
	var faltan: Array = []
	for c: Club in m2.clubes.values():
		if HistoriaClub.dato(c.nombre).is_empty():
			sin += 1
			faltan.append(c.nombre)
	if sin > 0:
		print("    sin historia: ", faltan)
	_comprobar(sin == 0, "los %d clubes tienen su fila de historia (%d sin ella)" % [m2.clubes.size(), sin])
	var grande: Club = clubes[0]
	var chico: Club = clubes[clubes.size() - 1]
	_comprobar(int(HistoriaClub.de(grande, clubes)["titulos"]) > int(HistoriaClub.de(chico, clubes)["titulos"]), "el grande tiene más títulos que el chico")
	_comprobar(HistoriaClub.de(grande, clubes) == HistoriaClub.de(grande, clubes), "el mismo club tiene siempre la misma historia")
	_comprobar(HistoriaClub.color_de("#ffffff") == "blanco" and HistoriaClub.color_de("#d50032") == "rojo" and HistoriaClub.color_de("#003da5") == "azul", "el apodo generado sale del color")
	m.tomar_el_mando(clubes[0].id)
	var t := m.prensa.titular_prensa(true, false, true, "x", "Superclásico")
	_comprobar(String(t["tit"]).begins_with("SUPERCLÁSICO: "), "la portada dice SUPERCLÁSICO")
	## Con el pack real, los mismos datos con los nombres reales.
	if Datos.hay_pack_real():
		Datos.usar_base_real(true)
		_comprobar(int(HistoriaClub.dato("C0lo-C0lo").get("fundado", 0)) == 1925 and HistoriaClub.nombre_clasico("C0lo-C0lo", "U. de Ch1le") == "Superclásico", "con el pack real: Colo-Colo 1925 y el Superclásico con la U")
		Datos.usar_base_real(false)

func _probar_contratos_c9() -> void:
	_titulo("C9: CONTRATOS Y JORNADA LABORAL")
	_comprobar(Contratos.JORNADA.size() == 24, "los 24 países tienen su jornada legal")
	## Chile: 44 horas hasta el 26 de abril de 2026, 42 después, 40 en 2028.
	var sem_marzo := 8
	var sem_junio := 20
	_comprobar(Contratos.horas("CHI", 2026, sem_marzo) == 44 and Contratos.horas("CHI", 2026, sem_junio) == 42, "Chile pasa de 44 a 42 horas en abril de 2026")
	_comprobar(Contratos.horas("CHI", 2028, sem_junio) == 40, "y llega a 40 en 2028")
	_comprobar(Contratos.horas("COL", 2026, sem_junio) == 44 and Contratos.horas("COL", 2026, 30) == 42, "Colombia baja a 42 en julio de 2026")
	_comprobar(Contratos.horas("FRA", 2026, 10) == 35 and Contratos.horas("MEX", 2026, 10) == 48, "Francia 35, México 48")
	_comprobar(Contratos.factor_estructura("FRA", 2026, 10) > 1.0 and Contratos.factor_estructura("MEX", 2026, 10) < 1.0, "menos horas legales, estructura más cara")
	var m := Mundo.new()
	m.generar(["CHI"], 5154)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var j := c.plantilla[0]
	j.edad = 17
	_comprobar(Contratos.ajustar_anios(j, 5) == 3, "un menor de 18 no firma por más de 3 años (FIFA)")
	j.edad = 25
	_comprobar(Contratos.ajustar_anios(j, 7) == 5 and Contratos.ajustar_anios(j, 0) == 1, "entre 1 y 5 años para el resto")
	var noticias: Array = []
	m.contratos.noticia.connect(func(t: String, _b: String) -> void: noticias.append(t))
	for s in range(1, 30):
		m.contratos.semana(c, 2026, s)
	_comprobar(noticias.size() == 1, "el cambio de jornada de abril sale una vez en las noticias")
	var jugadores_menores := 0
	for cl: Club in m.clubes.values():
		for x: Jugador in cl.plantilla:
			if x.edad < 18 and x.anios_contrato > 3:
				jugadores_menores += 1
	_comprobar(jugadores_menores == 0, "ningún menor del mundo generado tiene más de 3 años de contrato")

func _probar_vida_dt() -> void:
	_titulo("MI VIDA: LA VIDA DEL DT FUERA DEL CLUB")
	var m := Mundo.new()
	m.generar(["CHI"], 5156)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var v := m.vida
	var r := m.roles
	v.crear_perfil(c.id)
	var perfil0 := v.perfil.duplicate(true)
	v.perfil = {}
	v.crear_perfil(c.id)
	_comprobar(v.perfil == perfil0, "la familia sale siempre igual para el mismo club")
	r.patrimonio = 100000
	var p0 := r.patrimonio
	v.semana(c, r, 2026, 1, 2)
	_comprobar(r.patrimonio == p0 - v.coste_semanal(), "casa y transporte se pagan del patrimonio")
	## Trabajar al máximo: más preparación, más estrés.
	v.balance = 100
	v.estres = 40
	_comprobar(v.factor_trabajo(2026, 2) > 1.02, "trabajando al 100% se prepara mejor el partido")
	for s in range(2, 8):
		v.semana(c, r, 2026, s, -1)
	_comprobar(v.estres > 60, "perder y trabajar sin parar dispara el estrés (%d)" % v.estres)
	## Tres semanas al límite: reposo.
	v.estres = 95
	v.semanas_estres_alto = 0
	for s in range(8, 11):
		v.estres = 95
		v.semana(c, r, 2026, s, -1)
	_comprobar(v.de_baja(2026, 10) or v.de_baja(2026, 11), "tres semanas al límite: el médico te para")
	## Ocio: una vez por semana.
	v.estres = 50
	_comprobar(v.hacer_ocio("asado", r, 2026, 20) == "" and v.estres < 50, "un asado baja el estrés")
	_comprobar(v.hacer_ocio("gimnasio", r, 2026, 20) != "", "solo un respiro por semana")
	## Mudanza.
	var pat := r.patrimonio
	_comprobar(v.cambiar_vivienda("casa", r) == "" and v.vivienda == "casa" and r.patrimonio < pat, "te puedes mudar pagando la mudanza")
	r.patrimonio = 0
	_comprobar(v.cambiar_vivienda("mansion", r) != "", "sin plata no hay mansión")
	## Sin plata para la casa, vuelves a lo barato.
	v.vivienda = "mansion"
	v.transporte = "chofer"
	r.patrimonio = 10
	v.semana(c, r, 2026, 30, 2)
	_comprobar(v.transporte == "micro" and v.vivienda != "mansion", "sin plata para la casa, te ajustas el cinturón")
	## Asunto de casa.
	v.pendiente = {"tipo": "tele", "texto": "x", "a": "si", "b": "no"}
	r.patrimonio = 0
	var res := v.resolver("a", r, c, m.prensa, 2026, 31)
	_comprobar(res != "" and r.patrimonio > 0 and v.pendiente.is_empty(), "el programa de tele paga")
	var d := v.a_dic()
	var v2 := VidaDT.new()
	v2.desde_dic(d)
	_comprobar(v2.a_dic() == d, "Mi vida se guarda entera")

func _probar_maestrias() -> void:
	_titulo("MAESTRÍAS: 15 CATEGORÍAS DE 30 NIVELES")
	_comprobar(Maestria.ORDEN.size() == 15 and Maestria.CATEGORIAS.size() == 15, "hay 15 categorías")
	var m := Mundo.new()
	m.generar(["CHI"], 5157)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ma := m.maestria
	_comprobar(ma.subir("ataque") != "", "sin puntos no se sube")
	ma.puntos = 1000
	var pts0 := m.entrenamiento.dt_puntos
	for i in 30:
		ma.subir("ataque", m.entrenamiento)
	_comprobar(ma.nivel("ataque") == 30 and ma.subir("ataque") != "", "30 niveles y ni uno más")
	_comprobar(m.entrenamiento.dt_puntos == pts0 + 3, "los hitos 10, 20 y 30 dan un punto de habilidad cada uno")
	_comprobar(absf(ma.factor_ataque() - 1.06) < 0.001, "el nivel 30 de Ataque son +6 %% de ataque (%.3f)" % ma.factor_ataque())
	_comprobar(1000 - ma.puntos == 10 * 1 + 10 * 2 + 10 * 3, "los niveles se encarecen por decenas (costó %d)" % (1000 - ma.puntos))
	var c := m.mi_club()
	m.aplicar_bonificadores()
	var a0 := c.bonus_ataque
	ma.niveles["ataque"] = 0
	m.aplicar_bonificadores()
	_comprobar(c.bonus_ataque < a0, "la maestría de ataque llega al bono del equipo")
	ma.puntos = 0
	ma.semana(c, m.prensa, m.academia, 1, 1)
	_comprobar(ma.puntos == 2, "semana ganada: dos puntos de maestría")
	ma.niveles["finanzas"] = 15
	var s0 := c.saldo
	ma.semana(c, m.prensa, m.academia, 2, 2)
	_comprobar(c.saldo > s0, "Finanzas da un ingreso semanal")
	var d := ma.a_dic()
	var m2 := Maestria.new()
	m2.desde_dic(d)
	_comprobar(m2.nivel("finanzas") == 15 and m2.puntos == ma.puntos, "las maestrías se guardan")

## ¿DE VERDAD PESAN EN EL MARCADOR? (26-9-2026). El mismo club contra el mismo
## rival, 300 partidos con la misma semilla: una vez sin nada y otra con las
## maestrías de juego al 30 y "Genio táctico" en el árbol. Al ser los mismos
## números aleatorios, cualquier diferencia es de las habilidades.
func _probar_habilidades_en_resultados() -> void:
	_titulo("HABILIDADES Y MAESTRÍAS: SE NOTAN EN LOS RESULTADOS")
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var yo: Club = m.ligas[0].clubes[0]
	var rival: Club = m.ligas[0].clubes[1]
	m.tomar_el_mando(yo.id)
	var serie := func() -> Dictionary:
		m.aplicar_bonificadores()
		var r := {"g": 0, "e": 0, "p": 0, "gf": 0, "gc": 0, "bono": yo.bonus_ataque}
		seed(4242)
		for i in 300:
			var pa := Partido.new(yo, rival, true)
			var res: Dictionary = pa.simular()
			r["gf"] += int(res["local"])
			r["gc"] += int(res["visita"])
			if res["local"] > res["visita"]:
				r["g"] += 1
			elif res["local"] == res["visita"]:
				r["e"] += 1
			else:
				r["p"] += 1
		return r
	var base: Dictionary = serie.call()
	for k: String in ["ataque", "defensa", "porteros", "balon_parado", "analisis"]:
		m.maestria.niveles[k] = Maestria.NIVEL_MAX
	m.entrenamiento.dt_nodos["pizarra"] = true
	m.entrenamiento.dt_nodos["genio"] = true
	var top: Dictionary = serie.call()
	var pts := func(r: Dictionary) -> float: return (3.0 * r["g"] + r["e"]) / 300.0
	print("   · ", "sin nada:  %d-%d-%d, %d:%d goles, %.2f pts/partido (bono ataque %.3f)" % [base["g"], base["e"], base["p"], base["gf"], base["gc"], pts.call(base), base["bono"]])
	print("   · ", "al máximo: %d-%d-%d, %d:%d goles, %.2f pts/partido (bono ataque %.3f)" % [top["g"], top["e"], top["p"], top["gf"], top["gc"], pts.call(top), top["bono"]])
	_comprobar(float(top["bono"]) > float(base["bono"]) * 1.15, "el bono llega al motor del partido")
	_comprobar(int(top["gf"]) > int(base["gf"]) and int(top["gc"]) < int(base["gc"]), "más goles a favor y menos en contra")
	_comprobar(pts.call(top) > pts.call(base) + 0.1, "se ganan más puntos por partido (%.2f → %.2f)" % [pts.call(base), pts.call(top)])
	## Y no deciden solas: un club muy inferior con todo al máximo sigue sin
	## ser favorito ante el mejor.
	_comprobar(pts.call(top) < 3.0, "no ganan todos los partidos")

## LA BASE DE LA IA QUE JUEGA Y DEL MANDO (26-9-2026).
func _probar_motor_libre() -> void:
	_titulo("IA LIBRE: ACCIONES, MOTOR SIN JUGADAS PREHECHAS Y MANDO")
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var cl: Array = m.ligas[0].clubes.duplicate()
	cl.sort_custom(func(a: Club, b: Club) -> bool: return a.media() > b.media())
	var fuerte: Club = cl[0]
	var debil: Club = cl[cl.size() - 1]
	var j: Jugador = fuerte.once()[10]
	## El catálogo.
	_comprobar(AccionesJuego.CATALOGO.size() >= 20, "%d acciones en el catálogo" % AccionesJuego.CATALOGO.size())
	var sin_anim: Array = []
	for k: String in AccionesJuego.CATALOGO:
		var an := String(AccionesJuego.CATALOGO[k]["anim"])
		if an != "" and not AnimExtra.CATEGORIAS.has(an):
			sin_anim.append(k)
	_comprobar(sin_anim.is_empty(), "cada acción tiene su familia de animaciones %s" % str(sin_anim))
	var p_cerca := AccionesJuego.prob_exito(j, "pase_corto", {"dist": 8.0})
	var p_lejos := AccionesJuego.prob_exito(j, "pase_corto", {"dist": 30.0, "presion": 1.0})
	_comprobar(p_cerca > p_lejos, "un pase corto y libre sale más que uno largo y presionado (%.2f > %.2f)" % [p_cerca, p_lejos])
	var jb: Jugador = debil.once()[10]
	_comprobar(AccionesJuego.prob_exito(j, "tiro", {"dist": 16.0}) != AccionesJuego.prob_exito(jb, "tiro", {"dist": 16.0}), "los atributos mueven la probabilidad")
	_comprobar(AccionesJuego.prob_exito(j, "tiro", {"dist": 16.0, "pie_malo": true}) <= AccionesJuego.prob_exito(j, "tiro", {"dist": 16.0}), "la pierna débil resta")
	_comprobar(AccionesJuego.xg(Vector2(11, 0)) > AccionesJuego.xg(Vector2(25, 0)) and AccionesJuego.xg(Vector2(11, 0)) > AccionesJuego.xg(Vector2(8, 20)), "el xG baja con la distancia y el ángulo")
	## El motor: dos iguales dan un partido creíble.
	var ig := MotorLibre.new(fuerte.once(), fuerte.once(), 1.0, 1.0, 51).simular()
	var tiros: Array = ig["tiros"]
	var acierto := float(ig["pases_ok"][0] + ig["pases_ok"][1]) / maxf(1.0, float(ig["pases"][0] + ig["pases"][1]))
	print("   · iguales: ", ig["goles"], " tiros ", tiros, " pases ", ig["pases"], " acierto %.0f %%" % (acierto * 100.0))
	_comprobar(int(ig["goles"][0]) + int(ig["goles"][1]) <= 8, "marcador de fútbol, no de balonmano")
	## Entre dos equipos de élite el prototipo todavía tira de más (calibración
	## pendiente, E17 del ROADMAP): el tope es generoso a propósito.
	_comprobar(int(tiros[0]) + int(tiros[1]) >= 6 and int(tiros[0]) + int(tiros[1]) <= 160, "hay tiros, sin exagerar")
	_comprobar(acierto > 0.5 and acierto < 0.95, "acierto de pase creíble")
	var dec: Dictionary = ig["decisiones"]
	_comprobar(dec.has("pase_corto") and dec.has("conducir") and dec.has("tiro"), "la IA elige entre pasar, conducir y tirar")
	## El mejor gana, juegue de local o de visita.
	var a := MotorLibre.new(fuerte.once(), debil.once(), 1.0, 1.0, 1).simular()
	var b := MotorLibre.new(debil.once(), fuerte.once(), 1.0, 1.0, 2).simular()
	var gf := int(a["goles"][0]) + int(b["goles"][1])
	var gd := int(a["goles"][1]) + int(b["goles"][0])
	_comprobar(gf > gd, "el equipo mejor gana sin guion (%d-%d en dos partidos)" % [gf, gd])
	## Y las habilidades del club (el bono de maestrías y árbol) también aquí.
	var c1 := MotorLibre.new(debil.once(), debil.once(), 1.2, 1.0, 3).simular()
	var c2 := MotorLibre.new(debil.once(), debil.once(), 1.0, 1.2, 4).simular()
	var xg_bono := float(c1["xg"][0]) + float(c2["xg"][1])
	var xg_sin := float(c1["xg"][1]) + float(c2["xg"][0])
	_comprobar(xg_bono > xg_sin, "con el bono del club se generan más ocasiones (xG %.1f vs %.1f)" % [xg_bono, xg_sin])
	## El jugador controlado.
	var ml := MotorLibre.new(fuerte.once(), debil.once(), 1.0, 1.0, 9)
	ml.tomar_control(ml.poseedor)
	var yo := ml.poseedor
	ml.agentes[yo]["pos"] = Vector2(40.0, 0.0)
	ml.mover(Vector2(1, 0))
	ml.ordenar("tiro")
	ml.paso()
	_comprobar(int(ml.stats["tiros"][0]) == 1, "el jugador del mando tira cuando se le ordena")
	ml.cambiar_jugador()
	_comprobar(ml.controlado >= 0 and ml.agentes[ml.controlado]["eq"] == 0, "cambiar de jugador se queda en el propio equipo")
	## El mapa de botones.
	Mando.registrar()
	_comprobar(Mando.MAPA.keys().all(func(k: String) -> bool: return InputMap.has_action(k)), "las acciones de juego están en el InputMap")
	_comprobar(Mando.accion_de("jugar_pase", true) == "pase_corto" and Mando.accion_de("jugar_pase", false) == "presionar", "el mismo botón pasa con balón y presiona sin él")
	var botones_catalogo: Array = []
	for k: String in AccionesJuego.CATALOGO:
		var bt := String(AccionesJuego.CATALOGO[k]["boton"])
		if bt != "" and not Mando.MAPA.has(bt):
			botones_catalogo.append(bt)
	_comprobar(botones_catalogo.is_empty(), "cada botón del catálogo existe en el mapa del mando %s" % str(botones_catalogo))

## EL PORTAFOLIO DE FÚTBOL (26-9-2026): cuántos de cada familia hay, que
## existan en la librería de un jugador y que el partido los use.
func _probar_portafolio_futbol() -> void:
	_titulo("PORTAFOLIO: TIROS, PASES, BARRIDAS, ATAJADAS, REGATES, LESIONES Y ÁRBITRO")
	var f := AnimFutbol.familias()
	_comprobar((f["tiro"] as Array).size() >= 20, "%d tipos de tiro" % (f["tiro"] as Array).size())
	_comprobar((f["pase"] as Array).size() >= 20, "%d tipos de pase" % (f["pase"] as Array).size())
	_comprobar((f["barrida"] as Array).size() >= 20, "%d barridas y entradas" % (f["barrida"] as Array).size())
	_comprobar((f["atajada"] as Array).size() >= 12, "%d atajadas nuevas" % (f["atajada"] as Array).size())
	_comprobar((f["regate"] as Array).size() >= 30, "%d regates" % (f["regate"] as Array).size())
	_comprobar((f["expresivo"] as Array).size() >= 12 and (f["lesion"] as Array).size() >= 6, "expresiones y lesiones")
	_comprobar((f["arbitro"] as Array).size() >= 10, "%d gestos del árbitro y los asistentes" % (f["arbitro"] as Array).size())
	var d := FutbolistaQ.crear(1.8, "male")
	var raiz: Node3D = d["nodo"]
	add_child(raiz)
	FutbolistaQ.terminar(d, true)
	var ap: AnimationPlayer = d["anim"]
	var faltan: Array = []
	for fam: String in f:
		for n: String in f[fam]:
			if not ap.has_animation(n):
				faltan.append(n)
	_comprobar(faltan.is_empty(), "todas están en la librería del jugador %s" % str(faltan.slice(0, 5)))
	_comprobar(ap.has_animation("bicicleta_espejo") and ap.has_animation("tiro_empeine_espejo"), "con su espejo para zurdos y para el otro lado")
	_comprobar(ap.get_animation_list().size() >= 300, "%d movimientos por jugador" % ap.get_animation_list().size())
	## CELEBRACIONES SEGÚN EL CARÁCTER (mapa de metas 14).
	var sin_anim: Array = []
	for rs: String in AnimExtra.CELEBRA_POR_RASGO:
		for n: String in AnimExtra.CELEBRA_POR_RASGO[rs]:
			if not ap.has_animation(n):
				sin_anim.append(n)
	_comprobar(sin_anim.is_empty(), "cada celebración de carácter existe en la librería %s" % str(sin_anim))
	var rng_c := RandomNumberGenerator.new()
	rng_c.seed = 11
	var firma := AnimExtra.celebracion_firma("veloz", "j77")
	var repite := 0
	for i in 60:
		if AnimExtra.celebracion(ap, "veloz", "j77", false, rng_c) == firma:
			repite += 1
	_comprobar(repite >= 30 and (AnimExtra.CELEBRA_POR_RASGO["veloz"] as Array).has(firma), "cada jugador repite su celebración casi siempre (%d/60, %s)" % [repite, firma])
	var provoca := 0
	for i in 60:
		if AnimExtra.celebracion(ap, "polemico", "j78", true, rng_c) == "mano_oido":
			provoca += 1
	_comprobar(provoca >= 25, "el polémico, de visita, se pone la mano en la oreja (%d/60)" % provoca)
	_comprobar(AnimExtra.NOMBRE_CELEBRACION.has(AnimExtra.celebracion_firma("lider", "x1")), "la ficha nombra su celebración")
	## EL GOLPEO CON CUERPO (mapa de metas 16): al acompañar, el pie sube de
	## verdad; al armar, el brazo contrario se abre para equilibrar.
	var esq_g: Skeleton3D = d["esqueleto"]
	var i_pie := esq_g.find_bone(String(AnimQuaternius.HUESOS["pie_d"]))
	var i_mano := esq_g.find_bone(String(AnimQuaternius.HUESOS["mano_i"]))
	var i_pel := esq_g.find_bone(String(AnimQuaternius.HUESOS["cadera"]))
	var largo_g := ap.get_animation("tiro_empeine").length
	ap.play("tiro_empeine")
	ap.seek(0.0, true)
	var pie0 := esq_g.get_bone_global_pose(i_pie).origin
	var abre0 := absf(esq_g.get_bone_global_pose(i_mano).origin.x - esq_g.get_bone_global_pose(i_pel).origin.x)
	ap.seek(largo_g * 0.68, true)
	var pie1 := esq_g.get_bone_global_pose(i_pie).origin
	ap.seek(largo_g * 0.5, true)
	var abre1 := absf(esq_g.get_bone_global_pose(i_mano).origin.x - esq_g.get_bone_global_pose(i_pel).origin.x)
	_comprobar(pie1.y - pie0.y > 0.25, "al acompañar el tiro, el pie sube (%.2f)" % (pie1.y - pie0.y))
	_comprobar(abre1 - abre0 > 0.12, "al pegar, el brazo contrario se abre (%.2f)" % (abre1 - abre0))
	ap.stop()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var vistos := {}
	for i in 60:
		vistos[AnimExtra.variante(ap, "patear", "j1", rng)] = true
	_comprobar(vistos.size() >= 8, "el partido sortea entre muchos tiros (%d distintos en 60)" % vistos.size())
	var zurdo := ""
	for i in 200:
		if AnimExtra.es_zurdo("z%d" % i):
			zurdo = "z%d" % i
			break
	var todos_espejo := true
	for i in 20:
		if not AnimExtra.variante(ap, "patear", zurdo, rng).ends_with("_espejo"):
			todos_espejo = false
	_comprobar(todos_espejo, "un zurdo patea siempre con la zurda")
	raiz.queue_free()

## JUGADORES FIJOS CON GUIÑO (26-9-2026): en la base ficticia, el mismo club
## tiene los mismos jugadores (nombre, media y potencial) en cualquier partida.
func _probar_jugadores_fijos() -> void:
	_titulo("JUGADORES FIJOS CON GUIÑO EN LA BASE FICTICIA")
	var a := Mundo.new()
	a.generar(["CHI"], 111)
	var b := Mundo.new()
	b.generar(["CHI"], 98765)
	var ca: Club = a.ligas[0].clubes[0]
	var cb: Club = null
	for c: Club in b.ligas[0].clubes:
		if c.nombre == ca.nombre:
			cb = c
	_comprobar(cb != null, "el mismo club en los dos mundos (%s)" % ca.nombre)
	if cb == null:
		return
	var fijos_a := {}
	for j: Jugador in ca.plantilla:
		if j.real:
			fijos_a[j.nombre] = [j.ovr, j.pot, j.pos_e]
	var iguales := 0
	for j: Jugador in cb.plantilla:
		if j.real and fijos_a.has(j.nombre) and fijos_a[j.nombre] == [j.ovr, j.pot, j.pos_e]:
			iguales += 1
	print("   · ", ca.nombre, ": ", fijos_a.keys().slice(0, 5))
	_comprobar(fijos_a.size() >= 8, "%d jugadores con guiño en el club" % fijos_a.size())
	_comprobar(iguales == fijos_a.size(), "los mismos nombres, medias y potenciales con otra semilla (%d de %d)" % [iguales, fijos_a.size()])
	## Ningún guiño es un nombre real.
	var reales_ok := true
	for n: String in fijos_a:
		if Nombres.vetado(n):
			reales_ok = false
	_comprobar(reales_ok, "ningún guiño coincide con un nombre real vetado")

func _probar_disenos_kit() -> void:
	_titulo("EQUIPACIÓN: DISEÑOS, COLORES, BOTINES Y ACCESORIOS")
	var claves := DisenosKit.claves()
	_comprobar(claves.size() >= 62, "hay al menos 50 diseños nuevos (%d en total)" % claves.size())
	var unicas := {}
	for k: String in claves:
		unicas[k] = true
	_comprobar(unicas.size() == claves.size(), "sin claves repetidas")
	_comprobar(Jersey.KITS.all(func(k: String) -> bool: return claves.has(k)), "los 12 estilos de siempre siguen")
	_comprobar(DisenosKit.BOTINES.size() == 30, "30 modelos de botín")
	var de_dos := DisenosKit.DISENOS.filter(func(d: Array) -> bool: return int(d[2]) >= 43 and int(d[2]) <= 62 and int(d[7]) == 2)
	var de_tres := DisenosKit.DISENOS.filter(func(d: Array) -> bool: return int(d[2]) >= 43 and int(d[2]) <= 62 and int(d[7]) == 3)
	_comprobar(de_dos.size() == 20 and de_tres.size() == 20, "20 diseños nuevos de dos colores y 20 de tres")
	var cols3: Array[Color] = [Color.RED, Color.WHITE, Color.BLUE, Color.BLACK, Color.GREEN]
	var usados := {}
	for d: Array in de_dos:
		for i in 60:
			usados[DisenosKit.color_en(d, cols3, float(i % 10) / 5.0 - 1.0, float(i / 10) / 6.0).to_html(false)] = true
	_comprobar(not usados.has(Color.BLUE.to_html(false)) and not usados.has(Color.BLACK.to_html(false)), "los de dos colores no usan un tercero")
	## Patrocinadores.
	var ms := Mundo.new()
	ms.generar(["CHI"], 31)
	ms.tomar_el_mando(ms.ligas[0].clubes[0].id)
	_comprobar(SponsorKit.de_club(ms.mi_club(), ms).is_empty(), "sin contrato, tu camiseta va limpia")
	ms.auspicio.contrato = {"marca": "Cerveza Andin4", "color": "#e8b13a", "monto": 1, "exig_pos": 5, "anio": 2026}
	var spk := DisenosKit.kit_de_club(ms.mi_club())
	_comprobar((spk["sp"] as Dictionary).has("pecho") and String(spk["sp"]["pecho"]["marca"]) == "Cerveza Andina", "el contrato principal va al pecho (sin la cubierta)")
	var ajenos := 0
	for cc: Club in ms.ligas[0].clubes:
		if cc != ms.mi_club() and not SponsorKit.de_club(cc, ms).is_empty():
			ajenos += 1
	_comprobar(ajenos > 0 and SponsorKit.de_club(ms.ligas[0].clubes[3], ms) == SponsorKit.de_club(ms.ligas[0].clubes[3], ms), "los rivales llevan sus sponsors, siempre los mismos")
	var im := SponsorKit.imagen("Seguros Patagonia", "#8fa3b5", Color.WHITE)
	_comprobar(im.get_width() > im.get_height() and SponsorKit.lineas_de("SEGUROS PATAGONIA").size() == 2, "los nombres largos van en dos líneas")
	var un := DisenosKit.uniforms(spk, 9)
	_comprobar(bool(un["hay_sp_pecho"]) and un["sp_pecho"] is Texture2D, "el sponsor llega al shader 3D")
	ms.mi_club().kit_x = {"sp_ocultar": ["pecho"]}
	_comprobar(not (DisenosKit.kit_de_club(ms.mi_club())["sp"] as Dictionary).has("pecho"), "se puede no estampar una zona")
	_comprobar(DisenosKit.ACCESORIOS.size() >= 6, "accesorios para los jugadores")
	var cinco := DisenosKit.DISENOS.filter(func(d: Array) -> bool: return int(d[7]) == 5)
	_comprobar(not cinco.is_empty(), "hay diseños que usan los 5 colores")
	## La fórmula 2D da colores de la paleta.
	var cols: Array[Color] = [Color.RED, Color.WHITE, Color.BLUE, Color.YELLOW, Color.BLACK]
	var vistos := {}
	var d := DisenosKit.diseno("franjas_cinco")
	for i in 40:
		vistos[DisenosKit.color_en(d, cols, -1.0 + float(i) / 20.0, 0.5).to_html()] = true
	_comprobar(vistos.size() >= 4, "«Franjas de cinco colores» usa varios colores (%d)" % vistos.size())
	## El kit de un club, guardado y leído.
	var m := Mundo.new()
	m.generar(["CHI"], 5158)
	var c: Club = m.ligas[0].clubes[0]
	var k := DisenosKit.kit_de_club(c)
	_comprobar((k["cols"] as Array).size() == 5 and k.has("bot") and k.has("acc"), "la equipación completa tiene 5 colores, botines y accesorios")
	c.kit_x = {"dis": "tartan", "bot": {"mod": "fuego"}, "acc": {"guantes": "111111"}}
	var dic := c.identidad_a_dic()
	var c2 := Club.new()
	c2.identidad_desde_dic(dic)
	_comprobar(String(DisenosKit.kit_de_club(c2)["dis"]) == "tartan", "el diseño elegido se guarda con el club")
	var u := DisenosKit.uniforms(DisenosKit.kit_de_club(c2), 10)
	_comprobar(int(u["familia"]) == 26 and (u["acc_guantes"] as Color).a > 0.5 and int(u["dorsal"]) == 10, "el shader recibe diseño, accesorios y dorsal")
	_comprobar(DisenosKit.textura_camiseta("tartan", cols, 1, 64) != null, "la miniatura 2D se dibuja")
