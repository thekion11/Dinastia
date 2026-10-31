extends BaseIdea
## f3v · LA VIDA EN 3D (fase 3), sin pantalla. Engancha `VidaCiudad` al paseo de la
## ciudad real y comprueba los siete bloques del plan: el reloj corre al pasear y
## manda sobre la luz; la jornada en el club cuenta como trabajo y las horas extra
## suben preparación y estrés; comer (casa, comedor del plantel, bar) y dormir mueven
## las necesidades; la casa tiene a la familia y sus usos; la agenda del móvil
## adelanta con la rutina sin disparar el hambre; el coche depende de la vida; tres
## multas = calabozo (−3 de confianza una vez); el desmayo te deja en casa con titular;
## dormir el domingo avanza la semana con la MISMA huella que el menú; y una partida
## cargada sabe dónde arrancar (casa / oficina / menú).

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad

func _ready() -> void:
	await get_tree().process_frame
	await _probar_async()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _reloj_en(dia: int, hora: int) -> void:
	_m.reloj.dia = dia
	_m.reloj.minuto = hora * 60

func _probar_async() -> void:
	_titulo("f3v: la vida en 3D")
	_m = _mundo(4242)
	_m.reloj.sincronizar(_m.anio, _m.semana)
	## --- arranque de una partida cargada y transporte (sin ciudad) ---------------
	_comprobar(VidaCiudad.arranque_3d(_m) == "", "sin prólogo visto, una carga va al menú de siempre")
	_m.prologo_visto = true
	_comprobar(VidaCiudad.arranque_3d(_m) == "casa", "el lunes a las 08:00 se empieza en casa")
	_m.reloj.avanzar_minutos(60)
	_comprobar(VidaCiudad.arranque_3d(_m) == "oficina", "a otra hora, en la oficina")
	_m.necesidades.poner_modo("apagada")
	_comprobar(VidaCiudad.arranque_3d(_m) == "oficina", "con la vida apagada, siempre la oficina con el PC")
	_m.necesidades.poner_modo("completa")
	_m.vida.transporte = "micro"
	_comprobar(not bool(VidaCiudad.transporte(_m)["coche"]), "sin coche propio no se sale en coche")
	_m.vida.transporte = "usado"
	var transp := VidaCiudad.transporte(_m)
	_comprobar(bool(transp["coche"]) or String(transp["motivo"]).contains("taller"), "con coche propio se sale en coche salvo la semana de avería")
	## Adelantar con la rutina no castiga.
	_reloj_en(0, 8)
	var e0 := _m.necesidades.energia()
	var h0 := _m.necesidades.hambre()
	_m.reloj.avanzar_con_rutina(24 * 60)
	_comprobar(_m.reloj.dia == 1 and _m.reloj.hora() == 8, "avanzar 24 h con la rutina deja el martes a las 08:00")
	_comprobar(absi(_m.necesidades.energia() - e0) <= 15 and absi(_m.necesidades.hambre() - h0) <= 15,
		"y la energía y el hambre quedan donde estaban (%d→%d, %d→%d)" % [e0, _m.necesidades.energia(), h0, _m.necesidades.hambre()])
	## --- la ciudad y el enganche -------------------------------------------------
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	var perfil := _m.perfil_estadio_de(club)
	_vista.abrir(club, _m.obras, _m.ciudad, perfil)
	var est := TunelVestuario.datos(perfil, StadiumBuilder.niveles_de(perfil, int(perfil.get("aforo", 20000))))
	_vista.explorar("pie", CityBuilder.ESTADIO_EN + (est["puerta"] as Vector3) + Vector3(0, 0, 7.0))
	_e = _vista._explorador
	await _frames(2)
	_v = VidaCiudad.enganchar(_e, _vista, _m)
	_comprobar(_v != null and _e.vida == _v, "la vida se engancha al paseo")
	if _v == null:
		return
	_comprobar(not _vista._ciclo_activo and absf(_vista._hora - _m.reloj.hora_decimal()) < 0.01, "la luz de la ciudad es la hora del reloj")
	_comprobar(_v.etiqueta_hora().contains(":"), "la etiqueta dice día y hora (%s)" % _v.etiqueta_hora())
	## --- reloj vivo --------------------------------------------------------------
	_reloj_en(1, 10)
	var min0 := _m.reloj.minuto
	_v._process(6.1)
	_comprobar(_m.reloj.minuto == min0 + 1, "pasear 6 s hace pasar un minuto de juego")
	_comprobar(absf(_vista._hora - _m.reloj.hora_decimal()) < 0.01, "y la luz lo sigue")
	_e.pausar(true)
	_v._process(6.1)
	_comprobar(_m.reloj.minuto == min0 + 1, "en pausa (diálogo, PC, móvil) el tiempo no corre")
	_e.pausar(false)
	_e._physics_process(0.016)
	_comprobar(_e._hud.text.begins_with("🕒"), "el HUD del paseo empieza por la hora")
	## --- jornada -----------------------------------------------------------------
	_comprobar(_v.actividad_actual() == "libre", "en la calle el tiempo es libre")
	_e.estado = "estadio"
	_comprobar(_v.actividad_actual() == "trabajo", "en el club de 09 a 18 es jornada")
	_reloj_en(1, 19)
	_comprobar(_v.actividad_actual() == "horas_extra", "después de las 18, horas extra")
	var bal0 := _m.vida.balance
	var est0 := _m.vida.estres
	_v._al_cambiar_hora(19, 1)
	_comprobar(_m.vida.balance == mini(bal0 + 1, 100) and _m.vida.estres == mini(est0 + 1, 100), "cada hora extra suma preparación y estrés")
	_reloj_en(5, 11)
	_comprobar(_v.actividad_actual() == "libre", "el sábado en el club no cuenta como jornada")
	_e.estado = "calle"
	_reloj_en(1, 12)
	## --- comer en el comedor y en un bar -------------------------------------------
	_m.necesidades.hambre_m = 60 * Necesidades.ESCALA
	_comprobar(not _v.usar_en_estadio("Vestuario"), "la E en el vestuario no es comer")
	_comprobar(_v.usar_en_estadio("Comedor del plantel") and _m.necesidades.hambre() < 10 and _m.reloj.minuto == 12 * 60 + 30,
		"el comedor del plantel quita el hambre en media hora")
	_e._entrar_en_edificio("edificio_bar")
	await _frames(1)
	_m.necesidades.hambre_m = 60 * Necesidades.ESCALA
	_v.avisar_interior()
	_comprobar(_e.estado == "interior" and _e._aviso.text.contains(Idiomas.t("E: pedir algo de comer · la puerta: salir")), "en un bar la E ofrece comer")
	_comprobar(_v.usar_interior() and _m.necesidades.hambre() < 10, "y comer algo quita el hambre")
	_e._salir_del_edificio()
	await _frames(1)
	## --- la casa -----------------------------------------------------------------
	var calle := _e.cuerpo.position
	_v.entrar_casa()
	await _frames(1)
	_comprobar(_v.en_casa and _v.casa != null and _e.estado == "interior" and _e._int == _v.casa.interior, "E en la Casa Grande te mete en tu casa")
	if not _v.en_casa:
		return
	_comprobar(_v.casa.puntos().size() >= 3, "la casa tiene cama, mesa y sofá (y la familia: %d puntos)" % _v.casa.puntos().size())
	_e.cuerpo.position = _e._INT_ORIGEN + (CasaDT.POS_USO["mesa"] as Vector3)
	_v.avisar_interior()
	_comprobar(_e._aviso.text == "E: " + Idiomas.t("Comer"), "junto a la mesa, la E es comer")
	_m.necesidades.hambre_m = 50 * Necesidades.ESCALA
	_comprobar(_v.usar_interior() and _m.necesidades.hambre() < 10, "comer en casa quita el hambre")
	_e.cuerpo.position = _e._INT_ORIGEN + (CasaDT.POS_USO["sofa"] as Vector3)
	_v.avisar_interior()
	_m.vida.estres = 40
	_comprobar(_v.usar_interior() and _m.vida.estres == 40 - CasaDT.ESTRES_SOFA, "el sofá baja el estrés")
	if not _v.casa.cuerpos.is_empty():
		var c: Dictionary = _v.casa.cuerpos[0]
		_e.cuerpo.position = _e._INT_ORIGEN + (c["pos"] as Vector3)
		_v.avisar_interior()
		_m.vida.familia = 50
		_comprobar(_e._aviso.text.begins_with("E: ") and _v.usar_interior() and _m.vida.familia == 51, "hablar con la familia (%s) suma uno a la familia" % String(c["nombre"]))
	_reloj_en(1, 23)
	_m.necesidades.energia_m = 30 * Necesidades.ESCALA
	_e.cuerpo.position = _e._INT_ORIGEN + (CasaDT.POS_USO["cama"] as Vector3)
	_v.avisar_interior()
	_comprobar(_v.usar_interior() and _m.reloj.dia == 2 and _m.reloj.hora() == 8 and _m.necesidades.energia() > 60, "dormir salta a las 08:00 del día siguiente y recarga")
	_e._salir_del_edificio()
	await _frames(1)
	_comprobar(not _v.en_casa and _e.estado == "calle" and _e._int == null and _e.cuerpo.position.distance_to(calle) < 0.01, "salir de casa te deja en la calle donde estabas")
	## --- el calabozo -------------------------------------------------------------
	_m.prensa.titular_pendiente = {}
	var conf0 := _m.directiva.confianza
	_reloj_en(2, 20)
	_e.multas = 3
	_v._process(0.1)
	_comprobar(_e.multas == 0 and _m.directiva.confianza == maxi(conf0 - 3, 0) and _m.reloj.dia == 3 and _m.reloj.hora() == 8,
		"tres multas: noche en el calabozo, −3 de confianza y amanece a las 08:00")
	_comprobar(not _m.prensa.titular_pendiente.is_empty(), "y mañana sales en portada")
	_e.multas = 3
	_v._process(0.1)
	_comprobar(_m.directiva.confianza == maxi(conf0 - 3, 0), "la misma semana no se descuenta dos veces")
	## --- el desmayo --------------------------------------------------------------
	_m.prensa.titular_pendiente = {}
	_reloj_en(3, 22)
	var es0 := _m.vida.estres
	_m.necesidades.energia_m = 40
	_m.necesidades.pasar(1, "libre")
	_comprobar(_m.necesidades.energia() > 20 and _m.vida.estres == mini(es0 + VidaCiudad.ESTRES_DESMAYO, 100) and _e.estado == "calle",
		"energía a cero en la calle: despiertas en casa con estrés")
	_comprobar(not _m.prensa.titular_pendiente.is_empty() and _m.reloj.dia == 4 and _m.reloj.hora() == 8, "con titular y a las 08:00 del día siguiente")
	## --- dormir el domingo avanza la semana por el MISMO camino que el menú -----------
	## (`Mundo.avanzar_semana()`, una sola vez; dos mundos iguales avanzados en un mismo
	## proceso no dan la misma huella ni desde el menú, por el estado estático del motor,
	## así que la huella se compara por procesos en `pruebas/huella_mundo.tscn`).
	var mb := _mundo(99)
	mb.reloj.sincronizar(mb.anio, mb.semana)
	var v2 := VidaCiudad.new()
	v2.mundo = mb
	v2.expl = _e
	v2.vista = _vista
	add_child(v2)
	var avances := {"n": 0}
	mb.semana_avanzada.connect(func(_s: int, _a: int) -> void: avances["n"] += 1)
	mb.reloj.dia = 6
	mb.reloj.minuto = Reloj.MINUTOS_DIA - 1
	var sem0 := mb.semana
	v2._tras_dormir()
	_comprobar(mb.semana == sem0 + 1 and avances["n"] == 1, "dormir el domingo por la noche avanza la semana (una sola vez, por `Mundo.avanzar_semana`)")
	_comprobar(mb.reloj.dia == 0 and mb.reloj.hora() == 8, "y amanece el lunes a las 08:00")
	mb.reloj.dia = 3
	v2._tras_dormir()
	_comprobar(mb.semana == sem0 + 1 and avances["n"] == 1, "dormir entre semana no avanza nada")
	v2.queue_free()
	## --- la agenda del móvil -----------------------------------------------------
	_reloj_en(1, 10)
	var tel := Telefono.crear(_m)
	add_child(tel)
	tel.abrir_app("agenda")
	await _frames(1)
	_comprobar(tel._cuerpo.get_child_count() >= 6, "la app Agenda se pinta (hora, día, lo próximo, adelantar)")
	var h1 := _m.necesidades.hambre()
	tel._adelantar("manana")
	_comprobar(_m.reloj.dia == 2 and _m.reloj.hora() == 8 and _m.necesidades.hambre() <= 20,
		"«hasta mañana» deja las 08:00 con el desayuno hecho, sin disparar el hambre (%d→%d)" % [h1, _m.necesidades.hambre()])
	tel._adelantar("1h")
	_comprobar(_m.reloj.hora() == 9, "«una hora» adelanta una hora")
	tel._adelantar("partido")
	_comprobar(_m.reloj.dia == 5 and _m.reloj.hora() == VidaCiudad.HORA_PARTIDO, "«hasta el partido» deja el sábado a la hora del partido")
	tel._adelantar("partido")
	_comprobar(_m.reloj.dia == 5 and _m.reloj.hora() == VidaCiudad.HORA_PARTIDO, "y pasado el partido, no salta a la semana siguiente")
	_comprobar(absf(_vista._hora - _m.reloj.hora_decimal()) < 0.01, "la luz de la ciudad siguió al móvil")
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
			_comprobar((_m.mi_club().saldo if _m.mi_club() != null else 0) == club_saldo, "y el club no paga la gasolina")
			_m.vida.combustible = 5.0
			_m.roles.patrimonio = 0
			var gas1: float = sr.modelo.gas[int(surt["id"])]
			_v.usar_surtidor("surtidor_0", "normal")
			_comprobar(_m.vida.combustible == 5.0 and is_equal_approx(float(sr.modelo.gas[int(surt["id"])]), gas1), "sin dinero no echa gasolina ni gasta existencias")
			_m.roles.cartera.efectivo = 80
			_v.usar_surtidor("surtidor_0", "normal")
			_comprobar(_m.vida.combustible > 40.0 and _m.roles.cartera.efectivo < 80 and gas0 > 0.0, "con efectivo paga en efectivo")
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
			_comprobar(panel_ok and gasto_p < gasto_n, "el surtidor ofrece normal y premium, y la premium gasta menos (%.2f l contra %.2f l en 10 km)" % [gasto_p, gasto_n])
			var id0 := int(surt["id"])
			var gas_g: float = sr.modelo.gas[id0]
			sr.modelo.gas[id0] = RedesCiudad.GAS_DEPOSITO * 0.1
			var caro := sr.modelo.precio_litro(id0)
			sr.modelo.gas[id0] = RedesCiudad.GAS_DEPOSITO * 0.9
			var normal := sr.modelo.precio_litro(id0)
			sr.modelo.gas[id0] = gas_g
			_comprobar(caro > normal and is_equal_approx(normal, 1.4) and sr.modelo.precio_litro(id0, "premium") > normal, "el precio sube con pocas existencias (%.2f contra %.2f €/l) y la premium cuesta más" % [caro, normal])
	## Sin cartera (mundo sin roles) la gasolina no sale gratis: la paga el club como antes.
	if _v != null and _v._redes() != null and _m.mi_club() != null and not _v._redes().surtidor(0).is_empty():
		var roles_guardados: Roles = _m.roles
		_m.roles = null
		_m.vida.combustible = 5.0
		var saldo_sin := _m.mi_club().saldo
		_v.usar_surtidor("surtidor_0", "normal")
		_comprobar(_m.vida.combustible > 40.0 and _m.mi_club().saldo < saldo_sin, "sin cartera repostar lo paga el club (nunca sale gratis)")
		_m.roles = roles_guardados
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
	## Las expendedoras puestas: ciudad (centro comercial, gasolineras, estación, estadio) y andenes del metro.
	if _v != null and _e != null and _e.cb != null:
		_v.poner_extras()
		var n_mq := 0
		for pc: Dictionary in _e.cb.puntos_clic:
			if String(pc.get("k", "")).begins_with("expendedora_"):
				n_mq += 1
		_comprobar(n_mq >= 5, "hay expendedoras en la ciudad: centro comercial, gasolineras, estación y estadio (%d)" % n_mq)
		_comprobar(_e.metro != null and not _e.metro.expendedoras.is_empty() and _e.metro.expendedora_cerca(_e.metro.expendedoras[0]) and not _e.metro.expendedora_cerca(_e.metro.expendedoras[0] + Vector3(10, 0, 0)), "los andenes del metro tienen su máquina y se detecta a menos de 2,2 m")
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
	if _v != null:
		_v.poner_balon()
		_comprobar(is_instance_valid(_v._balon) and _v._balon.is_inside_tree(), "hay un balón suelto en el parque más cercano")
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
	tel.queue_free()
	PedidoPartida.mundo_pregenerado = null
	PedidoPartida.mundo_a_cargar = null
