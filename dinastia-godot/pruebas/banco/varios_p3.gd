extends "res://pruebas/banco/varios_p3_h.gd"
## [Capa 3/10 de `varios.gd`] _probar_roles_y_federacion, _probar_pulso_de_roles, _probar_logros, _probar_desafios

func _probar_roles_y_federacion() -> void:
	_titulo("ROLES, ENTRENAMIENTO, FEDERACION Y ESTADIO")
	var m := Mundo.new()
	m.generar(["CHI"], 909090)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_roles_cargos(m)
	var liga := _entrenamiento_y_federacion(m)
	_estadio_propio(m, liga)

## Cargos del DT: cada uno tiene que apagar cosas distintas (ayudante, interino, DT clasico).
func _roles_cargos(m: Mundo) -> void:
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

## Entrenamiento y federación: el campeón sale de la tabla de la liga del mando.
func _entrenamiento_y_federacion(m: Mundo) -> Liga:
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
	return liga

## Estadio propio: perfil, bandejas y componentes, tramos y los 24 estilos.
func _estadio_propio(m: Mundo, liga: Liga) -> void:
	_ep_perfil(m, liga)
	_ep_bandejas()
	_ep_componentes_reforma(m)
	_estadio_tramos(m, _ep_p, _ep_mio, _ep_rival)
	_ep_estilos(m)

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
	_dz_pobreza_local_bolsas()
	_dz_invicto_derbis()
	_dz_trotamundos_guardado()

## (17-11) El jugador real sin rasgos propios toma el promedio de SU NACIONALIDAD (`j.pais`), no el del país de su club: los de Asia oriental salen más claros que los de África occidental aunque jueguen en la misma liga.
func _probar_cara_por_nacionalidad() -> void:
	_titulo("CARA POR NACIONALIDAD DEL JUGADOR, NO DEL CLUB")
	var m := Mundo.new()
	m.generar(["ENG", "FRA", "GER", "ESP", "ITA", "BRA", "JPN", "KOR", "NGA", "GHA"], 23)
	var asia := []
	var africa := []
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			if not j.real or Cara.rasgos_conocido(j) is Dictionary:
				continue
			var lum: float = Color(String(Cara.look_de(j)["piel"])).get_luminance()
			if j.pais in ["JPN", "KOR", "CHN"]:
				asia.append(lum)
			elif j.pais in ["NGA", "GHA", "SEN", "CIV", "CMR", "COD", "MLI", "GUI"]:
				africa.append(lum)
	_comprobar(asia.size() >= 3 and africa.size() >= 3, "hay reales sin rasgos de Asia oriental (%d) y de África occidental (%d)" % [asia.size(), africa.size()])
	if asia.size() >= 3 and africa.size() >= 3:
		var ma := 0.0
		for v: float in asia:
			ma += v
		var mf := 0.0
		for v: float in africa:
			mf += v
		ma /= float(asia.size())
		mf /= float(africa.size())
		_comprobar(ma > mf + 0.08, "los de Asia oriental salen más claros que los de África occidental (%.2f frente a %.2f)" % [ma, mf])

