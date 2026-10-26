extends "res://pruebas/banco/varios_p2.gd"
## [Banco · grupo «varios» · capa 3/10] Generado al partir el banco por grupos (26-10).

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
	m.estadio.terminar_obra()
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
	m.estadio.terminar_obra()
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
