extends "res://pruebas/ideas/f3v_vida_p2.gd"
## f3v · LA VIDA EN 3D (fase 3), sin pantalla. Engancha `VidaCiudad` al paseo de la
## ciudad real y comprueba los siete bloques del plan: el reloj corre al pasear y
## manda sobre la luz; la jornada en el club cuenta como trabajo y las horas extra
## suben preparación y estrés; comer (casa, comedor del plantel, bar) y dormir mueven
## las necesidades; la casa tiene a la familia y sus usos; la agenda del móvil
## adelanta con la rutina sin disparar el hambre; el coche depende de la vida; tres
## multas = calabozo (−3 de confianza una vez); el desmayo te deja en casa con titular;
## dormir el domingo avanza la semana con la MISMA huella que el menú; y una partida
## cargada sabe dónde arrancar (casa / oficina / menú).

func _ready() -> void:
	InterruptorCiudad.activa = true   ## (9-11) esta prueba es de la ciudad 3D (apagada por defecto)
	await get_tree().process_frame
	await _probar_async()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _probar_async() -> void:
	f3v_inicio()
	f3v_arranque_de_una_partida_carg()
	if not await f3v_la_ciudad_y_el_enganche():
		return
	f3v_reloj_vivo()
	f3v_jornada()
	await f3v_comer_en_el_comedor_y_en_un_()
	if not await f3v_la_casa():
		return
	f3v_el_calabozo()
	f3v_el_desmayo()
	f3v_dormir_el_domingo_avanza_la_()
	await f3v_la_agenda_del_m_vil()
	f3v_sin_cartera_mundo_sin_ro()
	f3v_la_ventanilla_del_banco_()
	f3v_los_cajeros_est_n_puesto()
	f3v_las_expendedoras_puestas()
	f3v_la_expendedora_cobra_de_()
	f3v_m_180_el_vendedor_del_an()
	f3v_la_tienda_de_la_gasoline()
	f3v_mejora_d_31_10_f_para_ba()

func f3v_la_agenda_del_m_vil() -> void:
	## --- la agenda del móvil -----------------------------------------------------
	_reloj_en(1, 10)
	_tel = Telefono.crear(_m)
	add_child(_tel)
	_tel.abrir_app("agenda")
	await _frames(1)
	_comprobar(_tel._cuerpo.get_child_count() >= 6, "la app Agenda se pinta (hora, día, lo próximo, adelantar)")
	var h1 := _m.necesidades.hambre()
	_tel._adelantar("manana")
	_comprobar(_m.reloj.dia == 2 and _m.reloj.hora() == 8 and _m.necesidades.hambre() <= 20,
		"«hasta mañana» deja las 08:00 con el desayuno hecho, sin disparar el hambre (%d→%d)" % [h1, _m.necesidades.hambre()])
	_tel._adelantar("1h")
	_comprobar(_m.reloj.hora() == 9, "«una hora» adelanta una hora")
	_tel._adelantar("partido")
	_comprobar(_m.reloj.dia == 5 and _m.reloj.hora() == VidaCiudad.HORA_PARTIDO, "«hasta el partido» deja el sábado a la hora del partido")
	_tel._adelantar("partido")
	_comprobar(_m.reloj.dia == 5 and _m.reloj.hora() == VidaCiudad.HORA_PARTIDO, "y pasado el partido, no salta a la semana siguiente")
	_comprobar(absf(_vista._hora - _m.reloj.hora_decimal()) < 0.01, "la luz de la ciudad siguió al móvil")
	f3v_la_agenda_del_m_vil_01()

func f3v_la_agenda_del_m_vil_01() -> void:
	## EL SURTIDOR COBRA AL BOLSILLO DEL DT (pieza C de §2.2h), no al club.
	if _v != null and _v._redes() != null and _m.roles != null:
		var sr := _v._redes()
		var surt: Dictionary = sr.surtidor(0)
		if not surt.is_empty():
			var club_saldo := _m.mi_club().saldo if _m.mi_club() != null else 0
			_m.vida.combustible = 5.0
			_m.roles.patrimonio = 500
			_m.roles.cartera.efectivo = 0
			var gas0: float = sr.modelo.gas[int(surt["id"])]
			_v.usar_surtidor("surtidor_0", "normal")
			_comprobar(_m.vida.combustible > 40.0 and _m.roles.patrimonio < 500, "repostar cobra de la cuenta del DT con la tarjeta sin contacto")
			_comprobar(is_instance_valid(_v._tarjeta) and _v._tarjeta.visible, "y la tarjeta sube a la mano con el importe (§2.5)")
			## Decisiones del dueño (31-10): la multa temeraria cuesta 60 € y el consumo es 0,5 l/km.
			var multas0 := _e.multas
			_m.roles.cartera.efectivo = 100
			_v.multa_temeraria()
			_comprobar(_e.multas == multas0 + 1 and _m.roles.cartera.efectivo == 40, "la multa por conducción temeraria cobra 60 € y cuenta para el calabozo")
			_e.multas = multas0
			var c0 := _m.vida.combustible
			_m.vida.premium = false
			_m.vida.gastar_combustible(10000.0)
			_comprobar(is_equal_approx(c0 - _m.vida.combustible, 5.0), "10 km gastan 5 l (0,5 l/km: un depósito da ~90 km)")
			## Mejora A (31-10): indicador de gasolina con luz de reserva.
			_m.vida.combustible = VidaDT.DEPOSITO_L * 0.5
			var t_ok := _v.texto_gasolina()
			_m.vida.combustible = VidaDT.DEPOSITO_L * 0.1
			_comprobar(t_ok.contains("50 %") and not t_ok.contains(Idiomas.t("RESERVA")) and _v.reserva() and _v.texto_gasolina().contains(Idiomas.t("RESERVA")),
				"el indicador de gasolina dice «%s» y en reserva «%s»" % [t_ok, _v.texto_gasolina()])
			_m.vida.combustible = c0
			## Mejora C (31-10): los golpes suman daño; con 70 o más el coche va al taller y vuelve reparado.
			_m.vida.danio = 0
			DanioCoche.tick(_v)
			_e._t_golpe += 1.0
			_e._sacudida_golpe = 12.0 / 18.0
			DanioCoche.tick(_v)
			var d1 := _m.vida.danio
			_m.vida.danio = 75
			var taller := not bool(VidaCiudad.transporte(_m)["coche"])
			_m.vida.semana(_m.mi_club(), _m.roles, _m.anio, _m.semana, 0)
			_comprobar(d1 == 24 and taller and _m.vida.danio == 0, "un golpe a 43 km/h suma %d de daño; con 75 el coche va al taller y la semana lo repara" % d1)
			_ag_peatones()
			_comprobar((_m.mi_club().saldo if _m.mi_club() != null else 0) == club_saldo, "y el club no paga la gasolina")
			_m.vida.combustible = 5.0
			_m.roles.patrimonio = 0
			var gas1: float = sr.modelo.gas[int(surt["id"])]
			_v.usar_surtidor("surtidor_0", "normal")
			_comprobar(is_equal_approx(_m.vida.combustible, 5.0) and is_equal_approx(float(sr.modelo.gas[int(surt["id"])]), gas1), "sin dinero no echa gasolina ni gasta existencias")
			_m.roles.cartera.efectivo = 80
			_v.usar_surtidor("surtidor_0", "normal")
			_comprobar(_m.vida.combustible > 40.0 and _m.roles.cartera.efectivo < 80 and gas0 > 0.0, "con efectivo paga en efectivo")
			var dos := _ag_dos_combustibles()
			var panel_ok: bool = dos["panel_ok"]
			var gasto_p: float = dos["gasto_p"]
			var gasto_n: float = dos["gasto_n"]
			_ag_coche_sin_gasolina()
			_comprobar(panel_ok and gasto_p < gasto_n, "el surtidor ofrece normal y premium, y la premium gasta menos (%.2f l contra %.2f l en 10 km)" % [gasto_p, gasto_n])
			_ag_precio(sr, surt)

func _ag_peatones() -> void:
	## Mejoras E y G (31-10): el claxon y la velocidad asustan a los peatones cercanos (aprietan el paso).
	if _e.trafico != null:
		var pe: Dictionary = {}
		for v: Dictionary in _e.trafico._vehiculos:
			if bool(v.get("peaton", false)) and is_instance_valid(v["nodo"]):
				pe = v
				break
		if not pe.is_empty():
			var pp: Vector3 = (pe["nodo"] as Node3D).position
			var n_sust := _e.trafico.asustar(pp, 3.0)
			_comprobar(n_sust >= 1 and float(pe.get("susto", 0.0)) > 0.0 and _e.trafico.asustar(pp + Vector3(500, 0, 500), 3.0) == 0,
				"el claxon asusta a los peatones de alrededor (%d) y a los lejanos no" % n_sust)
			pe["susto"] = 0.0
			## Mejora F: el golpe que multa contra una persona es un atropello con reacción (150 €).
			var morro := _e.cuerpo.position + Vector3(sin(_e.rumbo), 0, cos(_e.rumbo)) * 2.0
			(pe["nodo"] as Node3D).position = morro
			_m.roles.cartera.efectivo = 200
			var mult0 := _e.multas
			_v.multa_temeraria()
			var lejos := ((pe["nodo"] as Node3D).position - morro).length()
			_comprobar(_m.roles.cartera.efectivo == 50 and lejos >= 1.3 and float(pe.get("espera", 0.0)) > 0.0 and _e.multas == mult0 + 1,
				"atropello: el peatón se aparta de un salto (%.1f m) y se queda aturdido; multa de 150 € (efectivo %d, espera %.1f, multas %d→%d)" % [lejos, _m.roles.cartera.efectivo, float(pe.get("espera", 0.0)), mult0, _e.multas])
			_e.multas = mult0

func _ag_dos_combustibles() -> Dictionary:
	## §2.5: dos combustibles; la E sin tipo abre el surtidor con los dos precios; la premium rinde más.
	_m.vida.combustible = 5.0
	_m.roles.patrimonio = 5000
	_v.usar_surtidor("surtidor_0")
	var panel_ok := is_instance_valid(_v._panel_cajero) and (_v._panel_cajero as PanelTienda).surtido.size() == 2
	if is_instance_valid(_v._panel_cajero):
		_v._panel_cajero.free()
	_v.usar_surtidor("surtidor_0", "premium")
	var lleno := _m.vida.combustible
	_m.vida.gastar_combustible(10000.0)
	var gasto_p := lleno - _m.vida.combustible
	_m.vida.premium = false
	_m.vida.combustible = lleno
	_m.vida.gastar_combustible(10000.0)
	var gasto_n := lleno - _m.vida.combustible
	return {"panel_ok": panel_ok, "gasto_p": gasto_p, "gasto_n": gasto_n}

func _ag_coche_sin_gasolina() -> void:
	## Auditoría del coche (31-10): con el depósito vacío, el pedal no mueve el coche.
	var comb_ok := _m.vida.combustible
	_m.vida.combustible = 0.0
	_v.gasolina_tick(0.016)
	var vel0 := _e.vel
	_e._pedal = 1.0
	_e.vel = 0.0
	_e._conducir(Vector2(0, 1), 0.1)
	_comprobar(_e.sin_gasolina and is_zero_approx(_e.vel), "sin gasolina el acelerador no mueve el coche")
	_m.vida.combustible = comb_ok
	_v.gasolina_tick(0.016)
	_e.vel = vel0
	_e._pedal = 0.0

func _ag_precio(sr: RedesCiudadVista, surt: Dictionary) -> void:
	var id0 := int(surt["id"])
	var gas_g: float = sr.modelo.gas[id0]
	sr.modelo.gas[id0] = RedesCiudad.GAS_DEPOSITO * 0.1
	var caro := sr.modelo.precio_litro(id0)
	sr.modelo.gas[id0] = RedesCiudad.GAS_DEPOSITO * 0.9
	var normal := sr.modelo.precio_litro(id0)
	sr.modelo.gas[id0] = gas_g
	_comprobar(caro > normal and is_equal_approx(normal, 1.4) and sr.modelo.precio_litro(id0, "premium") > normal, "el precio sube con pocas existencias (%.2f contra %.2f €/l) y la premium cuesta más" % [caro, normal])

func f3v_sin_cartera_mundo_sin_ro() -> void:
	## Sin cartera (mundo sin roles) la gasolina no sale gratis: la paga el club como antes.
	if _v != null and _v._redes() != null and _m.mi_club() != null and not _v._redes().surtidor(0).is_empty():
		var roles_guardados: Roles = _m.roles
		_m.roles = null
		_m.vida.combustible = 5.0
		var saldo_sin := _m.mi_club().saldo
		_v.usar_surtidor("surtidor_0", "normal")
		_comprobar(_m.vida.combustible > 40.0 and _m.mi_club().saldo < saldo_sin, "sin cartera repostar lo paga el club (nunca sale gratis)")
		_m.roles = roles_guardados

func f3v_la_ventanilla_del_banco_() -> void:
	## LA VENTANILLA DEL BANCO está en la plaza y la E abre el panel de la sucursal.
	if _v != null and _e != null and _e.cb != null and _m.roles != null:
		var kb := ""
		for pc: Dictionary in _e.cb.puntos_clic:
			if String(pc.get("k", "")).begins_with("banco_"):
				kb = String(pc["k"])
				break
		_comprobar(kb != "", "hay una sucursal bancaria (ventanilla) en la plaza mayor")
		if kb != "":
			_v.usar_banco(kb)
			_comprobar(is_instance_valid(_v._panel_cajero) and (_v._panel_cajero as PanelCajero).ventanilla, "la E ante la ventanilla abre el panel en modo sucursal")
			if is_instance_valid(_v._panel_cajero):
				_v._panel_cajero.free()

func f3v_los_cajeros_est_n_puesto() -> void:
	## LOS CAJEROS están puestos en la ciudad y la E abre el panel.
	if _v != null and _e != null and _e.cb != null and _m.roles != null:
		var kc := ""
		for pc: Dictionary in _e.cb.puntos_clic:
			if String(pc.get("k", "")).begins_with("cajero_"):
				kc = String(pc["k"])
				break
		_comprobar(kc != "", "hay cajeros automáticos puestos en la ciudad")
		if kc != "":
			_v.usar_cajero(kc)
			_comprobar(is_instance_valid(_v._panel_cajero) and _v._panel_cajero.is_inside_tree(), "la E ante un cajero abre el panel")
			if is_instance_valid(_v._panel_cajero):
				_v._panel_cajero.free()
			## §2.5: sin corriente en su sector, «fuera de servicio».
			if _v._redes() != null:
				var posc := Vector3.ZERO
				for pc: Dictionary in _e.cb.puntos_clic:
					if String(pc.get("k", "")) == kc:
						posc = pc["pos"]
				var sec := RedesCiudad.sector_en(posc.x, posc.z)
				var luz0: Variant = _v._redes().modelo.luz.get(sec, true)
				_v._redes().modelo.luz[sec] = false
				_v.usar_cajero(kc)
				_comprobar(not is_instance_valid(_v._panel_cajero), "sin corriente en su sector el cajero está fuera de servicio")
				_v._redes().modelo.luz[sec] = luz0

func f3v_las_expendedoras_puestas() -> void:
	## Las expendedoras puestas: ciudad (centro comercial, gasolineras, estación, estadio) y andenes del metro.
	if _v != null and _e != null and _e.cb != null:
		_v.poner_extras()
		var n_mq := 0
		for pc: Dictionary in _e.cb.puntos_clic:
			if String(pc.get("k", "")).begins_with("expendedora_"):
				n_mq += 1
		_comprobar(n_mq >= 5, "hay expendedoras en la ciudad: centro comercial, gasolineras, estación y estadio (%d)" % n_mq)
		## §2.5: cajeros también en hospital, universidad, estación y estadio.
		var cajeros: Array = []
		for pc: Dictionary in _e.cb.puntos_clic:
			if String(pc.get("k", "")).begins_with("cajero_"):
				cajeros.append(pc["pos"])
		_comprobar(cajeros.size() >= 8, "hay %d cajeros (también en hospital, universidad, estación y estadio)" % cajeros.size())
		_comprobar(_e.metro != null and not _e.metro.expendedoras.is_empty() and _e.metro.expendedora_cerca(_e.metro.expendedoras[0]) and not _e.metro.expendedora_cerca(_e.metro.expendedoras[0] + Vector3(10, 0, 0)), "los andenes del metro tienen su máquina y se detecta a menos de 2,2 m")

func f3v_la_expendedora_cobra_de_() -> void:
	## LA EXPENDEDORA cobra de la cartera y sube la energía; el balón suelto del parque aparece.
	if _v != null and _m.roles != null and _m.necesidades != null:
		_m.roles.patrimonio = 100
		_m.roles.cartera.cargo_pend = 0
		_m.roles.cartera.efectivo = 0
		_m.necesidades.energia_m = 30 * Necesidades.ESCALA
		_v.usar_expendedora()
		_comprobar(_m.necesidades.energia() == 45 and _m.roles.cartera.cuenta_eur(_m.roles) == 1197, "la expendedora cobra 3 € de la cartera y sube la energía de 30 a 45")
		_m.roles.patrimonio = 0
		_m.necesidades.energia_m = 30 * Necesidades.ESCALA
		_v.usar_expendedora()
		_comprobar(_m.necesidades.energia() == 30, "sin dinero la expendedora no da nada")

func f3v_m_180_el_vendedor_del_an() -> void:
	## M-180: el vendedor del andén (mostrador en cada estación) cobra 3 € y quita hambre.
	if _e != null and _e.metro != null and not _e.metro.vendedores.is_empty():
		var v0: Dictionary = _e.metro.vendedores[0]
		_comprobar(_e.metro.vendedor_cerca(v0["p"]) and not _e.metro.vendedor_cerca((v0["p"] as Vector3) + Vector3(10, 0, 0)), "los andenes tienen su vendedor y se detecta a menos de 2,4 m")
		if _v != null and _m.roles != null and _m.necesidades != null:
			_m.roles.patrimonio = 100
			_m.roles.cartera.cargo_pend = 0
			_m.roles.cartera.efectivo = 10
			_m.necesidades.hambre_m = 80 * Necesidades.ESCALA
			VendedorAnden.usar(_v)
			_comprobar(_m.roles.cartera.efectivo == 7 and _m.necesidades.hambre() == 55, "la empanada cuesta 3 € del efectivo y baja el hambre de 80 a 55")
	if _v != null:
		_v.poner_balon()
		_comprobar(is_instance_valid(_v._balon) and _v._balon.is_inside_tree(), "hay un balón suelto en el parque más cercano")

func f3v_la_tienda_de_la_gasoline() -> void:
	## LA TIENDA DE LA GASOLINERA: la E abre la caja; comprar cobra al DT (no al club) y baja el hambre.
	if _v != null and _m.roles != null and _m.necesidades != null:
		_m.roles.patrimonio = 100
		_m.roles.cartera.cargo_pend = 0
		_m.roles.cartera.efectivo = 0
		_m.necesidades.hambre_m = 80 * Necesidades.ESCALA
		var club_t := _m.mi_club().saldo if _m.mi_club() != null else 0
		_v.usar_tienda()
		_comprobar(is_instance_valid(_v._panel_cajero) and _v._panel_cajero is PanelTienda, "la E ante el mostrador abre la caja de la tienda")
		_v._panel_cajero.free()
		_v.comprar_surtido(TiendaGasolinera.SURTIDO[0])
		_comprobar(_m.necesidades.hambre() < 80 and _m.roles.cartera.cuenta_eur(_m.roles) == 1196, "comprar un bocadillo (4 €, con tarjeta) baja el hambre")
		_comprobar((_m.mi_club().saldo if _m.mi_club() != null else 0) == club_t, "y el club no paga la compra")
		_m.necesidades.energia_m = 30 * Necesidades.ESCALA
		_v.comprar_surtido(TiendaGasolinera.SURTIDO[4])
		_comprobar(_m.necesidades.energia() == 45, "la bebida energética de la tienda sube la energía de 30 a 45")
		_m.roles.patrimonio = 0
		_m.roles.cartera.cargo_pend = 0
		var h_antes := _m.necesidades.hambre()
		_v.comprar_surtido(TiendaGasolinera.SURTIDO[0])
		_comprobar(_m.necesidades.hambre() == h_antes, "sin dinero no se lleva nada")
	_tel.queue_free()

func f3v_mejora_d_31_10_f_para_ba() -> void:
	## Mejora D (31-10): F para bajarse del coche (queda aparcado y sólido) y volver a subir.
	if _e != null and _e.cb != null and String(_e.estado) == "calle":
		AparcarCoche._cambiar_cuerpo(_e, "coche", _e.cuerpo.position, _e.rumbo)
		_e.vel = 10.0
		var no_baja := AparcarCoche.alternar(_e)
		_e.vel = 0.0
		var pos_coche := _e.cuerpo.position
		AparcarCoche.alternar(_e)
		var aparcado := AparcarCoche.aparcado(_e)
		_comprobar(no_baja != "" and _e.modo == "pie" and aparcado != null and aparcado.position.distance_to(pos_coche) < 0.01
			and _e._choca_circulos(pos_coche, 0.3) and _e.cuerpo != aparcado,
			"en marcha no se baja; parado, F te baja: el coche queda aparcado y es sólido")
		_e.cuerpo.position = pos_coche + Vector3(2.0, 0, 0)
		AparcarCoche.alternar(_e)
		_comprobar(_e.modo == "coche" and _e.cuerpo == aparcado and AparcarCoche.aparcado(_e) == null and not _e._choca_circulos(pos_coche, 0.3),
			"F junto al coche te sube de nuevo y deja de ser un obstáculo")
		AparcarCoche._cambiar_cuerpo(_e, "pie", _e.cuerpo.position, _e.rumbo)
	PedidoPartida.mundo_pregenerado = null
	PedidoPartida.mundo_a_cargar = null
