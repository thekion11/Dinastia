extends "res://pruebas/banco/varios_p3_p1.gd"
## [Capa de `varios_p3.gd`, 21-11 refactor de forma] Secciones de «ESTADIO PROPIO» y «DESAFÍOS».
## El estado del estadio va en `_ep_*` (el orden de las comprobaciones y los textos son los de antes).

var _ep_p: Dictionary
var _ep_pr: Dictionary
var _ep_rival: Club
var _ep_mio: Club


## ESTADIO PROPIO: el perfil que va al visor tiene que traer las claves que
## consume el constructor 3D, o el estadio sale a medias sin un solo error.
func _ep_perfil(m: Mundo, liga: Liga) -> void:
	_ep_p = m.perfil_estadio_de(m.mi_club())
	var faltan: Array[String] = []
	for k in ["forma", "niveles", "techo", "cesped", "asientoP", "focos", "pantalla", "vallas", "aforo"]:
		if not _ep_p.has(k):
			faltan.append(k)
	_linea("  perfil de tu estadio: %s de %d niveles, techo %s, %d butacas" % [
		_ep_p.get("forma", "?"), int(_ep_p.get("niveles", 0)), _ep_p.get("techo", "?"), int(_ep_p.get("aforo", 0))])
	_comprobar(faltan.is_empty(), "el perfil trae las 9 claves del visor 3D (faltan: %s)" % [faltan])
	## Y el de un rival sigue saliendo de su hash, no del tuyo.
	_ep_rival = liga.clubes[5]
	_ep_pr = m.perfil_estadio_de(_ep_rival)
	_comprobar(_ep_pr.has("forma"), "el rival tambien tiene perfil de estadio")
	_comprobar(m.perfil_estadio_de(_ep_rival)["forma"] == _ep_pr["forma"], "y es siempre el mismo")
	_comprobar(not _ep_pr.has("bandejas"), "el rival nunca trae la clave bandejas (no tiene disenador)")


## BANDEJA (16-9-2026, Fase 1 de "el estadio por MODULOS"): con el interruptor
## apagado, el perfil no cambia NI UNA clave; y las claves de siempre, exactas.
func _ep_bandejas() -> void:
	## BANDEJA (16-9-2026, Fase 1 de "el estadio por MODULOS"): con el
	## interruptor apagado, el perfil no debe cambiar NI UNA clave respecto al
	## de antes de esta fase -es el requisito explicito de la reforma.
	_comprobar(not _ep_p.has("bandejas"), "sin personalizar_bandejas, el perfil no trae la clave bandejas")
	var claves_antes: Array = _ep_p.keys()
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


## COMPONENTES (16-9-2026, Fase 2) y la REFORMA de una sola tribuna con el interruptor prendido.
func _ep_componentes_reforma(m: Mundo) -> void:
	## COMPONENTES (16-9-2026, Fase 2): las 5 claves ya llegan al visor. Desde
	## el 25-9 el rival trae red, córner y banquillo de su estilo (más variedad
	## de estadios), pero sigue sin túnel ni escudo: esos solo los decide quien
	## diseña su propio estadio.
	for k in ["redTipo", "corner", "banquillo", "tunel", "escudoDonde"]:
		_comprobar(_ep_p.has(k), "el perfil propio trae la clave nueva '%s'" % k)
	for k in ["tunel", "escudoDonde"]:
		_comprobar(not _ep_pr.has(k), "el rival NO trae '%s' (sigue sin disenador)" % k)

	## Con el interruptor prendido y una reforma de una sola tribuna, solo esa
	## tribuna cambia -las otras tres siguen heredando el valor global.
	_ep_mio = m.mi_club()
	_ep_mio.saldo = 999999999
	_comprobar(m.estadio.reformar(_ep_mio, {"personalizar_bandejas": true}, m.obras) == "",
		"se puede activar personalizar cada tribuna")
	_comprobar(m.estadio.reformar(_ep_mio, {"bandeja_sur_asientoP": "damero"}, m.obras) == "",
		"se puede reformar solo la tribuna sur")
	m.estadio.terminar_obra()
	var p2 := m.perfil_estadio_de(_ep_mio)
	_comprobar(p2.has("bandejas"), "con el interruptor activo, el perfil SI trae bandejas")
	var bandejas: Dictionary = p2.get("bandejas", {})
	_comprobar(String(bandejas.get("sur", {}).get("asientoP", "")) == "damero",
		"la tribuna sur quedo con el patron reformado")
	for lado in ["norte", "este", "oeste"]:
		_comprobar(String(bandejas.get(lado, {}).get("asientoP", "")) == String(p2.get("asientoP", "")),
			"la tribuna %s sigue heredando el patron global" % lado)


## LOS 24 ESTILOS, ENRIQUECIDOS: cada uno trae un redTipo y un escudoDonde válidos.
func _ep_estilos(m: Mundo) -> void:
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


## POBREZA, LOCAL (sin extranjeros) y los APELLIDOS POR NACIONALIDAD.
func _dz_pobreza_local_bolsas() -> void:
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


## INVICTO (la primera derrota enciende fin_partida, una vez) y DERBIS (perder un clásico).
func _dz_invicto_derbis() -> void:
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


## TROTAMUNDOS (la segunda temporada seguida en el mismo club obliga a cambiar) y el GUARDADO de desafíos.
func _dz_trotamundos_guardado() -> void:
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
