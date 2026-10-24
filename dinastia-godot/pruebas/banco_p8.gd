extends "res://pruebas/banco_p7.gd"
## [Capa 8/27 de `banco.gd`] _probar_pulso_de_roles, _probar_cantera, _probar_logros, _dinero_prueba, _probar_cesiones, _probar_desafios

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

func _dinero_prueba(n: int) -> String:
	return "%dk" % (n / 1000)

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
