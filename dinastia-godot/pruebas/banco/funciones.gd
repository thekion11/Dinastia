extends "res://pruebas/banco/base.gd"
## [Banco · grupo «funciones»] (13-11-2026, sesión 15) Pruebas DIRECTAS de funciones puras de `nucleo/` que ninguna prueba nombraba: entradas y salidas conocidas, con los casos límite
## (vacío, 0, negativos, fuera de rango, empates) y países y clubes distintos en los ejemplos (regla 34). Cada expectativa sale de leer la función, no de ejecutarla.

## ECONOMÍA, REPUTACIÓN Y CLIMA: mes del año, clima extremo, multiplicador de patrocinio por nivel, rareza de la carta, meses de ingreso y delegación de viaje.
func _probar_fun_economia() -> void:
	_titulo("FUNCIONES PURAS: ECONOMÍA, REPUTACIÓN Y CLIMA")
	## Clima.mes_de: la semana 1 es el mes 1, 2 → 2, 13 → 4, 26 → 7, 40 → 10, y nunca pasa de 12 (ni baja de 1 con semanas 0 o negativas).
	var meses := {-3: 1, 0: 1, 1: 1, 2: 2, 5: 2, 13: 4, 26: 7, 40: 10, 52: 12, 53: 12, 200: 12}
	var mal_mes := []
	for s: int in meses:
		if Clima.mes_de(s) != int(meses[s]):
			mal_mes.append("%d→%d" % [s, Clima.mes_de(s)])
	_comprobar(mal_mes.is_empty(), "Clima.mes_de: semana → mes (%s)" % str(mal_mes))
	_comprobar(Clima.es_extremo({"clave": "lluvia"}) and Clima.es_extremo({"clave": "nieve"}) and Clima.es_extremo({"clave": "tormenta"}) and Clima.es_extremo({"clave": "niebla"}), "Clima.es_extremo: lluvia, nieve, tormenta y niebla lo son")
	_comprobar(not Clima.es_extremo({}) and not Clima.es_extremo({"clave": "sol"}) and not Clima.es_extremo({"clave": "sol", "calor": false, "altura": false}), "Clima.es_extremo: vacío y sol, no")
	_comprobar(Clima.es_extremo({"clave": "sol", "calor": true}) and Clima.es_extremo({"altura": true}), "Clima.es_extremo: el calor o la altura bastan solos")
	## Reputacion.mult_patrocinio: el multiplicador de la tabla en el nivel que toca (los cortes están en 35, 52, 68, 80 y 90).
	var esperado := {-5: 1.00, 0: 1.00, 34: 1.00, 35: 1.05, 51: 1.05, 52: 1.12, 67: 1.12, 68: 1.22, 79: 1.22, 80: 1.35, 89: 1.35, 90: 1.50, 100: 1.50, 500: 1.50}
	var mal_rep := []
	for r: int in esperado:
		if not is_equal_approx(Reputacion.mult_patrocinio(r), float(esperado[r])):
			mal_rep.append("%d→%.2f" % [r, Reputacion.mult_patrocinio(r)])
	_comprobar(mal_rep.is_empty(), "Reputacion.mult_patrocinio por nivel (%s)" % str(mal_rep))
	var sube := true
	for r in range(0, 101):
		sube = sube and Reputacion.mult_patrocinio(r) >= Reputacion.mult_patrocinio(maxi(r - 1, 0))
	_comprobar(sube, "Reputacion.mult_patrocinio nunca baja al subir la reputación")
	## Meta.rareza_de: la leyenda manda sobre el ovr; si no, oro desde 80, plata desde 70 y bronce el resto.
	_comprobar(Meta.rareza_de(10, true) == "leyenda" and Meta.rareza_de(99, true) == "leyenda", "Meta.rareza_de: la leyenda lo es con cualquier ovr")
	_comprobar(Meta.rareza_de(80, false) == "oro" and Meta.rareza_de(99, false) == "oro" and Meta.rareza_de(79, false) == "plata", "Meta.rareza_de: oro desde 80")
	_comprobar(Meta.rareza_de(70, false) == "plata" and Meta.rareza_de(69, false) == "bronce" and Meta.rareza_de(0, false) == "bronce" and Meta.rareza_de(-4, false) == "bronce", "Meta.rareza_de: plata desde 70, bronce debajo (también 0 y negativos)")
	## Finanzas.meses_de: sin partidos en casa, la temporada entera; si no, 2 por partido entre las semanas del mes, con un mínimo de 1.
	_comprobar(Finanzas.meses_de(0) == Finanzas.MESES_TEMPORADA and Finanzas.meses_de(-3) == Finanzas.MESES_TEMPORADA, "Finanzas.meses_de: 0 o negativo → la temporada entera (%d)" % Finanzas.MESES_TEMPORADA)
	var k := Finanzas.SEMANAS_DEL_MES
	_comprobar(Finanzas.meses_de(1) == 1 and Finanzas.meses_de(2) == maxi(1, 4 / k), "Finanzas.meses_de: pocos partidos → mínimo 1 mes")
	_comprobar(Finanzas.meses_de(19) == 19 * 2 / k and Finanzas.meses_de(38) == 38 * 2 / k, "Finanzas.meses_de: liga de 20 (19 en casa) y de 39 → %d y %d" % [19 * 2 / k, 38 * 2 / k])
	## Viajes.delegacion: 38 personas con reputación 70, sube 0,45 por punto y se queda entre 32 y 52.
	_comprobar(Viajes.delegacion(70) == 38 and Viajes.delegacion(60) == 34 and Viajes.delegacion(100) == 52, "Viajes.delegacion: 70 → 38, 60 → 34, 100 → 52")
	_comprobar(Viajes.delegacion(0) == 32 and Viajes.delegacion(-50) == 32 and Viajes.delegacion(500) == 52, "Viajes.delegacion: tope inferior 32 y superior 52")

## JUGADOR Y FORMACIÓN: techo de crecimiento, estrellas de habilidad, agenda, foco del portero, nombres de formación propia y orden del once.
func _probar_fun_jugador_y_formacion() -> void:
	_titulo("FUNCIONES PURAS: JUGADOR Y FORMACIÓN")
	## Jugador.techo_tope: por encima de 90 el techo cuenta la mitad, nunca por debajo del ovr actual y nunca más de 97.
	_comprobar(Jugador.techo_tope(85, 60) == 85 and Jugador.techo_tope(90, 60) == 90, "Jugador.techo_tope: hasta 90 se queda igual")
	_comprobar(Jugador.techo_tope(95, 60) == 93 and Jugador.techo_tope(99, 60) == 95 and Jugador.techo_tope(100, 60) == 95, "Jugador.techo_tope: sobre 90 cuenta la mitad (95 → 93, 99 → 95)")
	_comprobar(Jugador.techo_tope(70, 82) == 82 and Jugador.techo_tope(40, 97) == 97, "Jugador.techo_tope: nunca por debajo de su ovr actual")
	_comprobar(Jugador.techo_tope(200, 50) <= 97 and Jugador.techo_tope(97, 97) == 97, "Jugador.techo_tope: tope de 97")
	## HabilidadesJugador.estrellas_de: 1, 2 y 3 estrellas desde 74, 81 y 88 puntos.
	var casos := {-5.0: 0, 0.0: 0, 73.9: 0, 74.0: 1, 80.9: 1, 81.0: 2, 87.9: 2, 88.0: 3, 100.0: 3, 1000.0: 3}
	var mal := []
	for p: float in casos:
		if HabilidadesJugador.estrellas_de(p) != int(casos[p]):
			mal.append("%.1f→%d" % [p, HabilidadesJugador.estrellas_de(p)])
	_comprobar(mal.is_empty(), "HabilidadesJugador.estrellas_de en los cortes (%s)" % str(mal))
	## CarreraAgenda y CarreraPortero: valores fijos.
	_comprobar(is_equal_approx(CarreraAgenda.extra_entreno("extra"), 0.12) and is_zero_approx(CarreraAgenda.extra_entreno("descanso")) and is_zero_approx(CarreraAgenda.extra_entreno("")), "CarreraAgenda.extra_entreno: solo la agenda «extra» suma 0,12")
	_comprobar(CarreraPortero.foco_inicial("POR") == "estirada" and CarreraPortero.foco_inicial("DC") == "tiro" and CarreraPortero.foco_inicial("") == "tiro", "CarreraPortero.foco_inicial: el portero entrena la estirada; el resto, el tiro")
	## FormacionPropia: el nombre siempre lleva el prefijo ★, sin repetirlo, recortado a 24 y con un nombre por defecto.
	var p := FormacionPropia.PREFIJO
	_comprobar(FormacionPropia.nombre_valido("  Ataque total  ") == p + "Ataque total", "FormacionPropia.nombre_valido: recorta los espacios")
	_comprobar(FormacionPropia.nombre_valido("") == p + "Mi formación" and FormacionPropia.nombre_valido("    ") == p + "Mi formación", "FormacionPropia.nombre_valido: vacío → nombre por defecto")
	_comprobar(FormacionPropia.nombre_valido(p + "Ya la tengo") == p + "Ya la tengo" and FormacionPropia.nombre_valido(FormacionPropia.nombre_valido("Dos veces")) == p + "Dos veces", "FormacionPropia.nombre_valido: no repite el ★")
	var largo := "0123456789012345678901234567890"
	_comprobar(FormacionPropia.nombre_valido(largo) == p + largo.left(24) and FormacionPropia.nombre_valido(largo).length() == p.length() + 24, "FormacionPropia.nombre_valido: máximo 24 caracteres")
	_comprobar(FormacionPropia.es_propia(p + "X") and not FormacionPropia.es_propia("4-3-3") and not FormacionPropia.es_propia(""), "FormacionPropia.es_propia: solo con el prefijo")
	## OnceAuto.orden_de: con tres formaciones de la tabla, el portero va primero y salen todas las ranuras una sola vez.
	var forms: Dictionary = Datos.tabla("FORMS")
	var mal_orden := []
	for f: String in ["4-4-2", "3-5-2", "4-3-3", "4-2-3-1"]:
		if not forms.has(f):
			continue
		var ranuras: Array = (forms[f] as Dictionary).get("s", [])
		var orden: Array = OnceAuto.orden_de(ranuras)
		var visto := {}
		for i: int in orden:
			visto[i] = true
		var primero_portero := not orden.is_empty() and PesosPuesto.es_portero(String(ranuras[int(orden[0])][0]))
		if orden.size() != ranuras.size() or visto.size() != ranuras.size() or not primero_portero:
			mal_orden.append(f)
	_comprobar(mal_orden.is_empty() and not forms.is_empty(), "OnceAuto.orden_de: portero primero y todas las ranuras (%s)" % str(mal_orden))
	## Trabajadores.es_mujer: por el primer nombre de la lista femenina; el resto y el vacío, no.
	_comprobar(Trabajadores.es_mujer({"nombre": "Marta Rojas"}) and Trabajadores.es_mujer({"nombre": "Camila"}) and Trabajadores.es_mujer({"nombre": "Rocío Pérez Soto"}), "Trabajadores.es_mujer: nombres de la lista")
	_comprobar(not Trabajadores.es_mujer({"nombre": "Pedro Marta"}) and not Trabajadores.es_mujer({}) and not Trabajadores.es_mujer({"nombre": ""}), "Trabajadores.es_mujer: solo cuenta el primer nombre; sin nombre, no")

## CALENDARIO, RELOJ, TÁCTICA Y PLANOS: cuándo toca cada continental de selecciones, la rutina del día, los cambios tácticos rápidos, el plano de las ocasiones y los límites del núcleo.
func _probar_fun_calendario_y_planos() -> void:
	_titulo("FUNCIONES PURAS: CALENDARIO, RELOJ, TÁCTICA Y PLANOS")
	## Calendario.toca_continental_selecciones: cada confederación en su ciclo de años.
	_comprobar(Calendario.toca_continental_selecciones("ucl", 2028) and Calendario.toca_continental_selecciones("lib", 2032) and Calendario.toca_continental_selecciones("oce", 2024), "Calendario.toca_continental_selecciones: ucl, lib y oce cada 4 años desde 2028 (también hacia atrás)")
	_comprobar(not Calendario.toca_continental_selecciones("ucl", 2029) and not Calendario.toca_continental_selecciones("lib", 2030) and not Calendario.toca_continental_selecciones("oce", 2031), "Calendario.toca_continental_selecciones: los demás años, no")
	_comprobar(Calendario.toca_continental_selecciones("conc", 2027) and Calendario.toca_continental_selecciones("afr", 2029) and not Calendario.toca_continental_selecciones("conc", 2028) and not Calendario.toca_continental_selecciones("afr", 2030), "Calendario.toca_continental_selecciones: conc y afr en años impares")
	_comprobar(Calendario.toca_continental_selecciones("asia", 2027) and Calendario.toca_continental_selecciones("asia", 2031) and not Calendario.toca_continental_selecciones("asia", 2029) and not Calendario.toca_continental_selecciones("zzz", 2028) and not Calendario.toca_continental_selecciones("", 2028), "Calendario.toca_continental_selecciones: asia cada 4 años desde 2027; clave desconocida o vacía, nunca")
	## Reloj.actividad_de_rutina: en cada inicio de tramo la actividad de la tabla; entre medias, la del último que empezó; a medianoche, dormir.
	var mal_rutina := []
	for tramo: Array in Reloj.RUTINA:
		var ini := int(tramo[0])
		if Reloj.actividad_de_rutina(ini) != String(tramo[1]):
			mal_rutina.append("%d" % ini)
	_comprobar(mal_rutina.is_empty(), "Reloj.actividad_de_rutina: cada tramo empieza con su actividad (%s)" % str(mal_rutina))
	_comprobar(Reloj.actividad_de_rutina(0) == "dormir" and Reloj.actividad_de_rutina(419) == "dormir" and Reloj.actividad_de_rutina(420) == "comer" and Reloj.actividad_de_rutina(600) == "trabajo" and Reloj.actividad_de_rutina(1439) == "dormir", "Reloj.actividad_de_rutina: dormir de noche, comer a las 7:00, trabajo a media mañana")
	_comprobar(Reloj.actividad_de_rutina(-30) == "dormir" and Reloj.actividad_de_rutina(5000) == "dormir", "Reloj.actividad_de_rutina: fuera del día (negativo o pasado) no rompe")
	## Tactica.cambio_de: dos cambios rápidos con su mentalidad y su línea; cualquier otro nombre, vacío.
	var of := Tactica.cambio_de("ofensivo")
	var ce := Tactica.cambio_de("cerrojo")
	_comprobar(int(of["mentalidad"]) == Tactica.Mentalidad.OFENSIVA and int(of["linea"]) == Tactica.Nivel.ALTO, "Tactica.cambio_de(ofensivo): mentalidad ofensiva y línea alta")
	_comprobar(int(ce["mentalidad"]) == Tactica.Mentalidad.DEFENSIVA and int(ce["linea"]) == Tactica.Nivel.BAJO, "Tactica.cambio_de(cerrojo): defensiva y línea baja")
	_comprobar(Tactica.cambio_de("").is_empty() and Tactica.cambio_de("Ofensivo").is_empty() and Tactica.cambio_de("otro").is_empty(), "Tactica.cambio_de: nombre vacío, con otras mayúsculas o desconocido → {}")
	## OcasionesDT.a_plano: el eje largo del campo pasa a X del plano y se invierte para el visitante; la altura no cuenta.
	var pl := OcasionesDT.a_plano(Vector3(10.0, 5.0, 30.0), true)
	var pv := OcasionesDT.a_plano(Vector3(10.0, 5.0, 30.0), false)
	_comprobar(is_equal_approx(pl.x, 30.0) and is_equal_approx(pl.y, 10.0), "OcasionesDT.a_plano (local): (x, y, z) → (z, x)")
	_comprobar(is_equal_approx(pv.x, -30.0) and is_equal_approx(pv.y, -10.0), "OcasionesDT.a_plano (visitante): se invierte")
	_comprobar(OcasionesDT.a_plano(Vector3.ZERO, true).is_equal_approx(Vector2.ZERO) and OcasionesDT.a_plano(Vector3(-4.0, 9.0, -7.0), true).is_equal_approx(Vector2(-7.0, -4.0)), "OcasionesDT.a_plano: el origen y los negativos")
	## CallesCiudad.dentro_nucleo: caja del núcleo con límites estrictos y margen hacia dentro.
	var cx := (CallesCiudad.NUC_X0 + CallesCiudad.NUC_X1) * 0.5
	var cz := (CallesCiudad.NUC_Z0 + CallesCiudad.NUC_Z1) * 0.5
	_comprobar(CallesCiudad.dentro_nucleo(cx, cz) and CallesCiudad.dentro_nucleo(cx, cz, 100.0), "CallesCiudad.dentro_nucleo: el centro está dentro, con y sin margen")
	_comprobar(not CallesCiudad.dentro_nucleo(CallesCiudad.NUC_X0, cz) and not CallesCiudad.dentro_nucleo(CallesCiudad.NUC_X1, cz) and not CallesCiudad.dentro_nucleo(cx, CallesCiudad.NUC_Z0) and not CallesCiudad.dentro_nucleo(cx, CallesCiudad.NUC_Z1), "CallesCiudad.dentro_nucleo: el borde exacto cuenta como fuera")
	_comprobar(CallesCiudad.dentro_nucleo(CallesCiudad.NUC_X0 + 5.0, cz) and not CallesCiudad.dentro_nucleo(CallesCiudad.NUC_X0 + 5.0, cz, 10.0) and not CallesCiudad.dentro_nucleo(5000.0, 5000.0), "CallesCiudad.dentro_nucleo: el margen estrecha la caja; muy lejos, fuera")

## CONTINENTALES, FORMATOS Y PARTIDAS: premio por defecto, ronda de la semana y nombres de archivo de partida.
func _probar_fun_continentales_y_partidas() -> void:
	_titulo("FUNCIONES PURAS: CONTINENTALES Y PARTIDAS")
	_comprobar(Continental.premio_de("clave_que_no_existe") == Continental.PREMIO_POR_DEFECTO and Continental.premio_de("") == Continental.PREMIO_POR_DEFECTO, "Continental.premio_de: confederación desconocida → premio por defecto")
	var con_premio := 0
	for k: String in Continental.PRINCIPALES:
		if Continental.premio_de(k) > 0:
			con_premio += 1
	_comprobar(con_premio == Continental.PRINCIPALES.size(), "Continental.premio_de: todas las principales pagan algo")
	var semanas_con := 0
	var semanas_sin := 0
	var otros := 0
	for s in range(1, 53):
		var r := Continental.toca_ronda(s)
		if r == 0:
			semanas_con += 1
		elif r == -1:
			semanas_sin += 1
		else:
			otros += 1
		if (r == 0) != FormatosConti.hay_partido_en(s):
			otros += 1
	_comprobar(otros == 0 and semanas_con > 0 and semanas_sin > 0, "Continental.toca_ronda: 0 si hay partido continental y -1 si no (%d semanas con, %d sin, %d incoherentes)" % [semanas_con, semanas_sin, otros])
	_comprobar(Continental.paises_de("zzz").is_empty() and FormatosConti.paises_de("zzz").is_empty(), "Continental.paises_de: confederación desconocida → vacío")
	_comprobar(PartidaExportar.nombre_de_archivo("user://partidas/chile_2031.json") == "chile_2031" and PartidaExportar.nombre_de_archivo("C:/copias/arg.final.json") == "arg.final" and PartidaExportar.nombre_de_archivo("sin_extension") == "sin_extension" and PartidaExportar.nombre_de_archivo("") == "", "PartidaExportar.nombre_de_archivo: sin carpeta ni extensión (también con puntos y vacío)")

## PROGRESO, MARCA, VESTUARIO, PELUCHES Y REDES: probabilidad semanal de subir, marca personal, motivo de satisfacción, nombre de logro y usuario de red.
func _probar_fun_club_y_redes() -> void:
	_titulo("FUNCIONES PURAS: PROGRESO, MARCA, VESTUARIO, PELUCHES Y REDES")
	var j := Jugador.new()
	## ProgresoJugador.prob_semanal = 0,10 × freno (× 1,5 con el rasgo «motor»). Sin margen hasta el techo o con 24 años o más: 0.
	j.edad = 18
	j.ovr = 60
	j.pot = 68
	_comprobar(is_equal_approx(ProgresoJugador.prob_semanal(j), 0.08), "prob_semanal: 18 años y 8 de margen = 0,08")
	j.rasgo = "motor"
	_comprobar(is_equal_approx(ProgresoJugador.prob_semanal(j), 0.12), "prob_semanal: el rasgo «motor» la multiplica por 1,5")
	j.rasgo = ""
	j.edad = 21
	j.pot = 64
	_comprobar(is_equal_approx(ProgresoJugador.prob_semanal(j), 0.025), "prob_semanal: 21 años y 4 de margen = 0,025")
	j.edad = 23
	j.pot = 61
	_comprobar(is_equal_approx(ProgresoJugador.prob_semanal(j), 0.0105), "prob_semanal: con 1 punto de margen el freno mínimo es 0,35 (23 años: 0,0105)")
	j.pot = 60
	_comprobar(is_equal_approx(ProgresoJugador.prob_semanal(j), 0.0), "prob_semanal: en su techo, 0")
	j.edad = 24
	j.pot = 90
	j.rasgo = "motor"
	_comprobar(is_equal_approx(ProgresoJugador.prob_semanal(j), 0.0), "prob_semanal: con 24 años no crece más, ni siendo «motor»")
	## Mundo.marca_personal = (ovr−60)·2,2 + ídolo·0,35 + habilidades·3, redondeado y acotado a 0..100.
	j.ovr = 80
	_comprobar(Mundo.marca_personal(j, 40, 2) == 64, "marca_personal: 80 de media, ídolo 40, 2 habilidades = 64")
	j.ovr = 50
	_comprobar(Mundo.marca_personal(j, 0, 0) == 0, "marca_personal: por debajo de 60 no baja de 0")
	j.ovr = 99
	_comprobar(Mundo.marca_personal(j, 100, 5) == 100, "marca_personal: nunca pasa de 100")
	_comprobar(Mundo.marca_personal(j, 0, 0) == 86, "marca_personal: 99 de media sin ídolo ni habilidades = 86")
	## Vestuario.motivo_satisfaccion: el factor más bajo (baja) o más alto (sube); en empate gana el primero de «min, rend, tact, inst».
	var sat := {"min": 50, "rend": 30, "tact": 70, "inst": 60}
	_comprobar(Vestuario.motivo_satisfaccion(sat, true) == "Su mal rendimiento", "motivo_satisfaccion: el peor factor es el rendimiento")
	_comprobar(Vestuario.motivo_satisfaccion(sat, false) == "Cómodo en su puesto", "motivo_satisfaccion: el mejor factor es la táctica")
	var igual := {"min": 40, "rend": 40, "tact": 40, "inst": 40}
	_comprobar(Vestuario.motivo_satisfaccion(igual, true) == "Pocos minutos de juego" and Vestuario.motivo_satisfaccion(igual, false) == "Minutos de juego", "motivo_satisfaccion: en empate, los minutos de juego")
	var ultimo := {"min": 70, "rend": 70, "tact": 70, "inst": 10}
	_comprobar(Vestuario.motivo_satisfaccion(ultimo, true) == "Instalaciones pobres", "motivo_satisfaccion: el último factor también se elige")
	## Peluches.nombre_logro: el nombre de cada logro definido; un id desconocido (o vacío) se devuelve tal cual.
	var mal_logro := []
	for l: Dictionary in Peluches.definicion_logros():
		if Peluches.nombre_logro(String(l["id"])) != String(l["nombre"]):
			mal_logro.append(String(l["id"]))
	_comprobar(mal_logro.is_empty() and Peluches.definicion_logros().size() == Peluches.SERIES.size() + 1, "Peluches.nombre_logro: un nombre por logro (%s)" % str(mal_logro))
	_comprobar(Peluches.nombre_logro("no_existe") == "no_existe" and Peluches.nombre_logro("") == "", "Peluches.nombre_logro: un id desconocido o vacío vuelve igual")
	## Redes.usuario_de: minúsculas, sin acentos ni ñ, espacios → «_», sin puntos ni apóstrofos y sin espacios en los bordes.
	var usuarios := {"Ángel Ñ. O'Brien": "angel_n_obrien", "  Zé Müller ": "ze_muller", "Núñez": "nunez", "": "", "FC Lautaro": "fc_lautaro", "Seán Ó Súilleabháin": "sean_o_suilleabhain", "S.L. Benfica": "sl_benfica"}
	var mal_usu := []
	for n: String in usuarios:
		if Redes.usuario_de(n) != String(usuarios[n]):
			mal_usu.append("%s→%s" % [n, Redes.usuario_de(n)])
	_comprobar(mal_usu.is_empty(), "usuario_de: nombre → usuario (%s)" % str(mal_usu))

## OBJETIVOS, HISTORIA, MUNDIAL, PARTIDAS, ROPERO Y TROFEOS: copa grande por país, rondas hasta el cupo, textos de historia, plazas, nombre libre, artículo del ropero y receta del trofeo.
func _probar_fun_objetivos_y_textos() -> void:
	_titulo("FUNCIONES PURAS: OBJETIVOS, HISTORIA, MUNDIAL, PARTIDAS, ROPERO Y TROFEOS")
	## ObjetivosClub.copa_grande: «ucl» si el país tiene cupo en la Champions, «lib» si es el anfitrión o tiene cupo en la Libertadores, "" si no.
	var cupos_ucl: Array = FormatosConti.cupos("ucl")
	var cupos_lib: Array = FormatosConti.cupos("lib")
	var mal_copa := []
	for f: Array in cupos_ucl:
		if ObjetivosClub.copa_grande(String(f[0])) != "ucl":
			mal_copa.append("ucl " + String(f[0]))
	for f2: Array in cupos_lib:
		var p2 := String(f2[0])
		var en_ucl := false
		for f3: Array in cupos_ucl:
			en_ucl = en_ucl or String(f3[0]) == p2
		if not en_ucl and ObjetivosClub.copa_grande(p2) != "lib":
			mal_copa.append("lib " + p2)
	_comprobar(not cupos_ucl.is_empty() and not cupos_lib.is_empty() and mal_copa.is_empty(), "copa_grande: cada país de un cupo tiene su copa (%s)" % str(mal_copa))
	_comprobar(ObjetivosClub.copa_grande("") == "" and ObjetivosClub.copa_grande("Narnia") == "", "copa_grande: país vacío o inexistente = sin copa grande")
	_comprobar(ObjetivosClub.copa_grande(Continental.PAIS_ANFITRION) in ["ucl", "lib"], "copa_grande: el anfitrión continental juega una de las dos")
	## ObjetivosClub.rondas_para: rondas de la copa (log2 de los participantes) menos las que quedan desde el cupo.
	var copa := Copa.new("Copa de prueba")
	var tabla := {[16, 4]: 2, [16, 1]: 4, [16, 0]: 4, [16, 16]: 0, [16, 64]: 0, [32, 2]: 4, [64, 8]: 3, [20, 2]: 3, [2, 1]: 1, [1, 1]: 0, [0, 4]: 0}
	var mal_rondas := []
	for k: Array in tabla:
		var clubes: Array[Club] = []
		for i in int(k[0]):
			clubes.append(Club.new("c%d" % i, "Club %d" % i))
		copa.participantes = clubes
		if ObjetivosClub.rondas_para(copa, int(k[1])) != int(tabla[k]):
			mal_rondas.append("%s→%d" % [str(k), ObjetivosClub.rondas_para(copa, int(k[1]))])
	_comprobar(mal_rondas.is_empty(), "rondas_para: (participantes, cupo) → rondas (%s)" % str(mal_rondas))
	## HistoriaClub.texto_clasicos / texto_historia.
	_comprobar(HistoriaClub.texto_clasicos({}) == "" and HistoriaClub.texto_clasicos({"rival": ""}) == "", "texto_clasicos: sin rival ni clásicos, vacío")
	_comprobar(HistoriaClub.texto_clasicos({"rival": "Estudiantes del Plata"}) == "Rival de siempre: %s." % Nombres.visible("Estudiantes del Plata"), "texto_clasicos: sin clásicos, el rival de siempre")
	var dos := {"clasicos": [{"nombre": "El Superclásico", "rival": "Boca Unidos"}, {"nombre": "Derbi del Norte", "rival": "Sporting Vasco"}], "rival": "Otro"}
	var txt := HistoriaClub.texto_clasicos(dos)
	_comprobar(txt.begins_with("⚔️ El Superclásico contra %s · Derbi del Norte contra %s" % [Nombres.visible("Boca Unidos"), Nombres.visible("Sporting Vasco")]) and not txt.contains("Otro"), "texto_clasicos: los clásicos van unidos con « · » y mandan sobre el rival (%s)" % txt)
	_comprobar(HistoriaClub.texto_historia({"guino": "Fundado por tranviarios", "origen": "Barrio del puerto"}) == "Fundado por tranviarios", "texto_historia: el guiño manda")
	_comprobar(HistoriaClub.texto_historia({"guino": "", "origen": "Barrio del puerto"}) == "Barrio del puerto" and HistoriaClub.texto_historia({}) == "", "texto_historia: sin guiño, el origen; sin nada, vacío")
	## SeleccionesTorneos.plazas_mundial: 32 hasta 2025; desde 2026 son 48 si la tabla de selecciones los alcanza.
	var hay48 := Selecciones._tabla_selecciones().size() >= SeleccionesTorneos.PLAZAS_MUNDIAL_48
	var mal_plazas := []
	for a: int in [1930, 1998, 2022, 2025, 2026, 2030, 2100]:
		var esp: int = SeleccionesTorneos.PLAZAS_MUNDIAL_48 if (a >= SeleccionesTorneos.ANIO_MUNDIAL_48 and hay48) else SeleccionesTorneos.PLAZAS_MUNDIAL
		if SeleccionesTorneos.plazas_mundial(null, a) != esp:
			mal_plazas.append("%d→%d" % [a, SeleccionesTorneos.plazas_mundial(null, a)])
	_comprobar(mal_plazas.is_empty() and SeleccionesTorneos.plazas_mundial(null, 2025) == 32, "plazas_mundial: 32 antes de 2026, 48 después (%s)" % str(mal_plazas))
	## PartidaExportar.nombre_libre: nombre válido de archivo, sin bordes con espacios; vacío = «importada»; si ya existe, «(2)», «(3)»…
	_comprobar(PartidaExportar.nombre_libre("") == "importada" and PartidaExportar.nombre_libre("   ") == "importada", "nombre_libre: vacío = «importada»")
	var libre := PartidaExportar.nombre_libre("  Liga Austral/Sur:2031  ")
	_comprobar(not libre.contains("/") and not libre.contains(":") and libre == libre.strip_edges() and libre.begins_with("Liga Austral"), "nombre_libre: quita barras y dos puntos (%s)" % libre)
	_comprobar(PartidaExportar.nombre_libre("Dinastía Ñuble 2040") == "Dinastía Ñuble 2040", "nombre_libre: un nombre limpio y libre se conserva")
	## RoperoDT.articulo: la ficha del catálogo, o {} si no existe.
	_comprobar(RoperoDT.articulo("balon")["precio"] == 25 and not bool(RoperoDT.articulo("balon")["una"]), "RoperoDT.articulo: el balón vale 25 y se repite")
	_comprobar(RoperoDT.articulo("camiseta_club")["precio"] == 40 and bool(RoperoDT.articulo("camiseta_club")["una"]), "RoperoDT.articulo: la camiseta vale 40 y es única")
	_comprobar(RoperoDT.articulo("").is_empty() and RoperoDT.articulo("Balon").is_empty() and RoperoDT.articulo("nada").is_empty(), "RoperoDT.articulo: vacío, otra mayúscula o desconocido = {}")
	## TrofeosReales.para_titulo = receta(id_de(título, país)); lo no reconocido cae en «generico».
	_comprobar(TrofeosReales.para_titulo("Mundial de Clubes", "ARG") == TrofeosReales.receta("mundial"), "para_titulo: el Mundial de Clubes, sea del país que sea")
	_comprobar(TrofeosReales.para_titulo("Liga", "ESP") == TrofeosReales.receta("liga:ESP") and TrofeosReales.para_titulo("Liga", "GER") == TrofeosReales.receta("liga:GER"), "para_titulo: «Liga» a secas depende del país")
	_comprobar(TrofeosReales.id_de("Torneo Inventado del Sur", "BRA") == "generico" and TrofeosReales.para_titulo("Torneo Inventado del Sur", "BRA") == TrofeosReales.receta("generico"), "para_titulo: un título desconocido = receta genérica")
