extends "res://pruebas/banco/varios_p4_h.gd"
## [Capa 4/10 de `varios.gd`] _probar_fundar_club, _probar_consejeros, _probar_bilbao_solo_local, _probar_sala_de_prensa, _probar_auspicio, _media_techo_camada … (+1)


func _probar_fundar_club() -> void:
	_titulo("CREAR TU CLUB: FUNDAR DE CERO")
	var m := Mundo.new()
	m.generar([], 6001)
	var club := _fc_fundar_chile(m)
	_fc_fundar_esp(m)
	_fc_guardado(m, club)

func _probar_consejeros() -> void:
	_titulo("CONSEJEROS DEL DIRECTORIO")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_cs_contratos_ojeo(m)
	_cs_embajador(m)
	_cs_dt_empleado()

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
## `LEEME.md` del historial de git).
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

func _probar_sala_de_prensa() -> void:
	_titulo("SALA DE PRENSA (portavoz, television, portadas y el ano contado)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 7373)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_sp_proyeccion_tv(m)
	_sp_vocero(m)
	_sp_portadas_relato(m)

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
	_er_epocas(m)
	_er_ciclo_mercado(m)
	_er_precios(m)
	_er_frase_uniforme(m)
