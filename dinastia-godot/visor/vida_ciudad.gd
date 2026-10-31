class_name VidaCiudad
extends "res://visor/vida_ciudad_p1.gd"
## (Parte 2 de 2 de `vida_ciudad.gd`.)

var _mq_estadio := false
var _balon: BalonSuelto
var _panel_cajero: Control   ## el panel abierto (cajero, ventanilla o caja de la tienda), si lo hay

## Las redes de la ciudad (luz, agua, drenaje, gas), si la ciudad ya está levantada.
func _redes() -> RedesCiudadVista:
	if expl == null or expl.cb == null or expl.cb.expansion == null:
		return null
	return expl.cb.expansion.redes

## El depósito del coche (solo en coche y en la calle): gasta con la distancia, avisa al bajar del 15 % (una vez por semana)
## y vacío el coche no arranca hasta repostar en un surtidor (E).
func gasolina_tick(delta: float) -> void:
	expl.sin_gasolina = mundo.vida != null and mundo.vida.combustible <= 0.01
	if expl._movil != null and mundo.vida != null:   ## mejora A: la gasolina en el móvil de la mano (ámbar en reserva)
		expl._movil.gasolina_texto = "⛽ %d %%" % roundi(mundo.vida.fraccion_comb() * 100.0)
		expl._movil.reserva = reserva()
	if mundo.vida == null or String(expl.modo) != "coche" or String(expl.estado) != "calle":
		return
	var vd := mundo.vida
	vd.gastar_combustible(absf(expl.vel) * delta)
	_t_vacio -= delta
	if vd.combustible <= 0.01:
		expl.vel = 0.0
		if _t_vacio <= 0.0:
			_t_vacio = 20.0
			_notificar(Idiomas.t("⛽ Sin gasolina: el coche no arranca hasta que repostes en un surtidor (E)."))
	elif vd.fraccion_comb() < 0.15 and vd.aviso_comb != mundo.anio * 100 + mundo.semana:
		vd.aviso_comb = mundo.anio * 100 + mundo.semana
		_notificar(Idiomas.t("⛽ Te queda menos del 15 % de gasolina: busca un surtidor (E)."))

## E ante un surtidor: elige combustible (normal o premium, precio según las existencias, §2.5) y llena
## el depósito (10 minutos). Sin corriente en el sector, no hay bomba. Con `tipo` ya dado, reposta directo.
func usar_surtidor(k: String, tipo := "") -> bool:
	var redes := _redes()
	if not k.begins_with("surtidor_") or redes == null:
		return false
	var s := redes.surtidor(int(k.get_slice("_", 1)))
	if s.is_empty():
		return false
	if tipo != "" or expl == null or expl._capa == null:
		_decir(Idiomas.t("Gasolinera"), repostar(k, tipo if tipo != "" else "normal"))
		return true
	if is_instance_valid(_panel_cajero):
		return true
	var falta := VidaDT.DEPOSITO_L - mundo.vida.combustible if mundo.vida != null else 45.0
	var surtido: Array = []
	for t: String in RedesCiudad.COMBUSTIBLES:
		var litros := minf(falta, float(redes.modelo.gas.get(int(s["id"]), 0.0)))
		surtido.append({"tipo": t, "nombre": String(RedesCiudad.COMBUSTIBLES[t][0]), "precio": roundi(litros * redes.modelo.precio_litro(int(s["id"]), t))})
	var saldo := func() -> String:
		return Idiomas.t("En el bolsillo") + ": " + Eco.dinero_euros(float(mundo.roles.cartera.efectivo)) if mundo.roles != null else ""
	_panel_cajero = PanelTienda.abrir(expl._capa, Idiomas.t("Gasolinera"), surtido, func(it: Dictionary) -> String: return repostar(k, String(it["tipo"])),
		saldo, expl.cuerpo.position, expl.cuerpo)
	return true

## Llena el depósito con `tipo` en el surtidor `k`. Devuelve el mensaje (traducido).
func repostar(k: String, tipo: String) -> String:
	var redes := _redes()
	var s := redes.surtidor(int(k.get_slice("_", 1))) if redes != null else {}
	if s.is_empty():
		return ""
	var falta := VidaDT.DEPOSITO_L - mundo.vida.combustible if mundo.vida != null else 45.0
	if falta < 1.0:
		return Idiomas.t("Tienes el depósito lleno.")
	## El DT paga de SU bolsillo (efectivo y, si no alcanza, la tarjeta sin contacto), no el club. Se mira ANTES de echar gasolina.
	var cartera: CarteraDT = mundo.roles.cartera if mundo.roles != null else null
	var dia := CarteraDT.clave_dia(mundo.anio, mundo.semana, mundo.reloj.dia)
	if cartera != null:
		var tope := roundi(minf(falta, float(redes.modelo.gas.get(int(s["id"]), 0.0))) * redes.modelo.precio_litro(int(s["id"]), tipo))
		var motivo := cartera.puede_cobrar(mundo.roles, tope, dia)
		if motivo != "" and tope > 0:
			return CarteraDT.texto_error(motivo, tope)
	var r := redes.modelo.repostar(int(s["id"]), s["sector"], falta, tipo)
	if int(r["coste"]) <= 0:
		return Idiomas.t("Sin corriente (o sin existencias): las bombas no funcionan.")
	mundo.reloj.avanzar_minutos(10, "libre")
	if mundo.vida != null:
		mundo.vida.combustible = minf(VidaDT.DEPOSITO_L, mundo.vida.combustible + float(r["litros"]))
		mundo.vida.premium = tipo == "premium"
	var via := ""
	if cartera != null:
		via = String(cartera.cobrar(mundo.roles, int(r["coste"]), "Gasolina", dia)["via"])
	elif mundo.mi_club() != null:
		mundo.mi_club().mover_saldo(-maxi(1, roundi(float(r["coste"]) / Eco.ECO)))   ## sin cartera (partida sin roles) paga el club (puntos internos): nunca gratis
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	return Idiomas.t("Depósito lleno: %d l por %d € (%s).") % [roundi(float(r["litros"])), int(r["coste"]), Idiomas.t(via if via != "" else "efectivo")]

## El balón suelto del parque más cercano al DT (una sola vez, la primera que se le ve): se patea a pie. Ver `BalonSuelto`.
func poner_extras() -> void:
	poner_balon()
	## Una máquina expendedora en el exterior, junto a la puerta del club del estadio (una sola vez).
	if not _mq_estadio and expl != null and expl.cb != null and not expl._est.is_empty():
		_mq_estadio = true
		var pu: Vector3 = CityBuilder.ESTADIO_EN + (expl._est["puerta"] as Vector3)
		ExpendedoraCiudad.montar(expl.cb, Vector3(pu.x - 6.0, 0.2, pu.z + 1.0), 0.0)
		if expl.cb.expansion != null:
			CajeroCiudad.montar(expl.cb.expansion, Vector3(pu.x - 8.0, 0.2, pu.z + 1.0), 0.0)   ## y un cajero (§2.5)

func poner_balon() -> void:
	if is_instance_valid(_balon) or expl == null or expl.cb == null or expl.cb.expansion == null or expl.cuerpo == null:
		return
	var mejor: Rect2
	var d_mejor := INF
	for bl: Dictionary in expl.cb.expansion.bloques:
		if String(bl["uso"]) == "parque":
			var r: Rect2 = bl["rect"]
			var d := r.get_center().distance_to(Vector2(expl.cuerpo.position.x, expl.cuerpo.position.z))
			if d < d_mejor:
				d_mejor = d
				mejor = r
	if d_mejor == INF:
		return
	_balon = BalonSuelto.new()
	_balon.jugador = expl.cuerpo
	_balon.activo = func() -> bool: return String(expl.modo) == "pie"
	_balon.limites = mejor.grow(-3.0)
	_balon.position = Vector3(mejor.get_center().x + 3.0, 1.0, mejor.get_center().y + 3.0)
	expl.cb.add_child(_balon)

## E ante un cajero: abre el panel de PIN y operaciones (retirar, ingresar, cambiar el PIN) con la cartera del DT.
func usar_cajero(k: String) -> bool:
	if mundo.roles == null:
		return false
	if is_instance_valid(_panel_cajero):
		return true
	var banco := CajeroCiudad.banco_de(k)
	var pos := Vector3.ZERO
	for pc: Dictionary in expl.cb.puntos_clic:
		if String(pc.get("k", "")) == k:
			pos = pc["pos"]
	## (§2.5, 30-10) Sin corriente en su sector, el cajero está fuera de servicio (como las bombas del surtidor).
	var redes := _redes()
	if redes != null and not redes.modelo.hay_luz(RedesCiudad.sector_en(pos.x, pos.z)):
		_decir(Idiomas.t(String(banco["nombre"])), Idiomas.t("Fuera de servicio: el sector está sin corriente."))
		return true
	var dia := CarteraDT.clave_dia(mundo.anio, mundo.semana, mundo.reloj.dia)
	_panel_cajero = PanelCajero.abrir(expl._capa, mundo.roles.cartera, mundo.roles, dia, Idiomas.t(String(banco["nombre"])), int(banco["comision"]), pos, expl.cuerpo)
	return true

## E ante la ventanilla del banco: el panel de la sucursal (desbloquear, restablecer el PIN, movimientos).
func usar_banco(k: String) -> bool:
	if mundo.roles == null:
		return false
	if is_instance_valid(_panel_cajero):
		return true
	var pos := Vector3.ZERO
	for pc: Dictionary in expl.cb.puntos_clic:
		if String(pc.get("k", "")) == k:
			pos = pc["pos"]
	var dia := CarteraDT.clave_dia(mundo.anio, mundo.semana, mundo.reloj.dia)
	_panel_cajero = PanelCajero.abrir(expl._capa, mundo.roles.cartera, mundo.roles, dia, Idiomas.t("Banco Andino"), 0, pos, expl.cuerpo, true)
	return true

## E ante una máquina expendedora: compra lo que pide el cansancio o el hambre y lo cobra la cartera del DT (sin gastar tiempo).
func usar_expendedora() -> bool:
	if mundo.roles == null or mundo.necesidades == null:
		return false
	var it := Expendedora.elegir(mundo.necesidades.energia(), mundo.necesidades.hambre())
	var dia := CarteraDT.clave_dia(mundo.anio, mundo.semana, mundo.reloj.dia)
	var r := mundo.roles.cartera.cobrar(mundo.roles, int(it["precio"]), String(it["nombre"]), dia)
	if String(r["error"]) != "":
		_decir(Idiomas.t("Máquina expendedora"), CarteraDT.texto_error(String(r["error"]), int(it["precio"])))
		return true
	mundo.necesidades.animar(int(it["energia"]))
	mundo.necesidades.picar(int(it["hambre"]))
	_decir(Idiomas.t("Máquina expendedora"), Idiomas.t("%s por %d € (%s).") % [Idiomas.t(String(it["nombre"])), int(it["precio"]), Idiomas.t(String(r["via"]))])
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	return true

## E ante una máquina de billetes del metro: recarga la tarjeta Red con `CarteraDT.RECARGA` € de la cartera (M-182).
func usar_billetes() -> bool:
	if mundo.roles == null:
		return false
	var dia := CarteraDT.clave_dia(mundo.anio, mundo.semana, mundo.reloj.dia)
	var c := mundo.roles.cartera
	var r := c.recargar_transporte(mundo.roles, CarteraDT.RECARGA, dia)
	if String(r["error"]) != "":
		_decir(Idiomas.t("Máquina de billetes"), CarteraDT.texto_error(String(r["error"]), CarteraDT.RECARGA))
		return true
	_decir(Idiomas.t("Máquina de billetes"), Idiomas.t("Recarga de %d € (%s). Saldo de la tarjeta Red: %d €.") % [CarteraDT.RECARGA, Idiomas.t(String(r["via"])), c.saldo_transporte])
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	return true

## Cobra un pasaje (`metro`, `bus`, `teleferico`) de la tarjeta Red. false (con aviso) si no hay saldo: no se sube (M-182).
func cobrar_pasaje(tipo: String) -> bool:
	if mundo.roles == null:
		return true
	var c := mundo.roles.cartera
	var tarifa := int(CarteraDT.TARIFAS.get(tipo, 1))
	if c.pagar_pasaje(tipo) == "":
		expl._aviso.text = Idiomas.t("Pasaje: -%d € · saldo de la tarjeta Red: %d €") % [tarifa, c.saldo_transporte]
		return true
	_decir(Idiomas.t("Tarjeta Red"), Idiomas.t("Sin saldo (%d €): el pasaje cuesta %d €. Recarga la tarjeta en una máquina de billetes del metro.") % [c.saldo_transporte, tarifa])
	return false

## E ante el mostrador de la tienda de la gasolinera: abre la caja con el surtido (`PanelTienda`); cada compra pasa por `comprar_surtido`.
func usar_tienda() -> bool:
	if mundo.roles == null:
		return false
	if is_instance_valid(_panel_cajero):
		return true
	var pos := expl.cuerpo.position
	var mejor := INF
	for pc: Dictionary in expl.cb.puntos_clic:
		if String(pc.get("k", "")).begins_with("tienda_") and (pc["pos"] as Vector3).distance_to(expl.cuerpo.position) < mejor:
			mejor = (pc["pos"] as Vector3).distance_to(expl.cuerpo.position)
			pos = pc["pos"]
	var saldo := func() -> String:
		return Idiomas.t("En el bolsillo") + ": " + Eco.dinero_euros(float(mundo.roles.cartera.efectivo)) + "  ·  " + Idiomas.t("Cuenta") + ": " + Eco.dinero_euros(float(mundo.roles.cartera.cuenta_eur(mundo.roles)))
	_panel_cajero = PanelTienda.abrir(expl._capa, Idiomas.t("Tienda de la gasolinera"), TiendaGasolinera.SURTIDO, comprar_surtido, saldo, pos, expl.cuerpo)
	return true

## Compra un artículo del surtido: lo cobra la cartera del DT, baja el hambre o sube la energía. Devuelve el mensaje (traducido) para la caja.
func comprar_surtido(it: Dictionary) -> String:
	if mundo.roles == null:
		return ""
	var dia := CarteraDT.clave_dia(mundo.anio, mundo.semana, mundo.reloj.dia)
	var r := mundo.roles.cartera.cobrar(mundo.roles, int(it["precio"]), String(it["nombre"]), dia)
	if String(r["error"]) != "":
		return CarteraDT.texto_error(String(r["error"]), int(it["precio"]))
	if mundo.necesidades != null:
		mundo.necesidades.picar(int(it.get("hambre", 0)))
		mundo.necesidades.animar(int(it.get("energia", 0)))
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	return Idiomas.t("%s por %d € (%s).") % [Idiomas.t(String(it["nombre"])), int(it["precio"]), Idiomas.t(String(r["via"]))]

func _comer(texto: String) -> void:
	mundo.reloj.avanzar_minutos(30, "comer")
	_decir(Idiomas.t("Comer"), texto)
	Sonido.toca("clic", Sonido.Bus.EFECTOS)

# ============================================================================ CASA

## ¿Esta E en la ciudad es la puerta de tu casa?
func es_mi_casa(k: String) -> bool:
	return k == "casa_grande" and String(expl.estado) == "calle" and expl.modo == "pie"

## Entra a la Casa Grande por dentro: la misma mecánica que cualquier interior
## (`_mover_en_interior`, salir por la puerta), con `CasaDT` como sala.
func entrar_casa() -> void:
	if en_casa or expl.cb == null:
		return
	expl._fundido()
	var raiz := Node3D.new()
	raiz.name = "CasaPaseo"
	raiz.position = expl._INT_ORIGEN
	expl.cb.add_child(raiz)
	casa = CasaDT.new()
	casa.montar(raiz, mundo, Vector3.ZERO)
	if casa.interior == null:
		raiz.queue_free()
		casa = null
		return
	expl._int_raiz = raiz
	expl._int = casa.interior
	expl._int_circulos = casa.obstaculos()
	expl._calle_pos = expl.cuerpo.position
	expl._calle_rumbo = expl.rumbo
	expl.estado = "interior"
	expl._bajo_tierra(true)
	expl._vel_pie = 0.0
	var t := casa.interior.tam_sala()
	expl.cuerpo.position = expl._INT_ORIGEN + Vector3(0, 0.05, t.z * 0.5 - 1.6)
	expl.rumbo = PI
	expl.cuerpo.rotation.y = PI
	expl.cuerpo.visible = not expl.primera_persona
	expl._cerca = {}
	expl._aviso.text = ""
	expl._colocar_camara(1.0)
	en_casa = true
	Sonido.toca("puerta", Sonido.Bus.EFECTOS)

## Lo llama el explorador al empezar a salir de un interior: la sala de la casa
## la libera `CasaDT` (no cuelga del árbol), no el explorador.
func al_salir_interior() -> void:
	if en_casa:
		expl._int = null
		en_casa = false
		casa = null
		_punto_casa = {}

## El aviso de la E dentro de un interior: tu casa (cama, mesa, sofá, familia) o
## pedir algo de comer en un bar. Lo llama `_mover_en_interior` cada cuadro.
func avisar_interior() -> void:
	_punto_casa = {}
	if en_casa and casa != null:
		_punto_casa = casa.cercano(expl.cuerpo.position)
		if not _punto_casa.is_empty():
			expl._aviso.text = String(_punto_casa["texto"])
	elif _clave_interior() in COMIDAS and expl._int_cerca.is_empty():
		expl._aviso.text = Idiomas.t("E: pedir algo de comer · la puerta: salir")

func _clave_interior() -> String:
	return String(expl._int.clave).get_slice("|", 0) if is_instance_valid(expl._int) else ""

## E dentro de un interior. true si la vida se lo quedó (si no, charla o salida de siempre).
func usar_interior() -> bool:
	if en_casa and casa != null and not _punto_casa.is_empty():
		var r := casa.usar(String(_punto_casa["clave"]), String(_punto_casa.get("nombre", "")))
		if r.is_empty():
			return false
		if String(_punto_casa["clave"]) == "cama":
			expl._fundido()
		elif String(_punto_casa["clave"]) == "sofa":
			expl._gesto_propio("sentarse", "sentado")   ## se sienta y se QUEDA sentado hasta moverse (§2.2e P3)
		_decir(String(r["titulo"]), String(r["texto"]))
		if String(_punto_casa["clave"]) == "cama":
			_tras_dormir()
		return true
	var k := _clave_interior()
	if k in COMIDAS and expl._int_cerca.is_empty():
		_comer(Idiomas.t(String(COMIDAS[k])))
		return true
	return false

## Tras dormir: si era domingo por la noche, la semana avanza (la MISMA llamada que
## el PC) y amanece el lunes a las 08:00.
func _tras_dormir() -> void:
	if mundo.reloj.agotada():
		_avanzar_semana_3d()
	_sincronizar_luz()

func _avanzar_semana_3d() -> void:
	if not mundo.temporada_en_curso():
		_decir(Idiomas.t("Temporada terminada"), Idiomas.t("En el PC: «Temporada siguiente»."))
		return
	mundo.avanzar_semana()
	## El menú central del PC, si ya está creado, se entera.
	for pc in get_tree().root.find_children("*", "PcOficina", true, false):
		var pr: Variant = pc.get("_principal")
		if pr != null and is_instance_valid(pr) and (pr as Node).has_method("_refrescar"):
			(pr as Node).call("_refrescar")
	_notificar(Idiomas.t("📅 Nueva semana: lunes, 08:00."))

# ======================================================================== TELÉFONO

## La T del paseo: el móvil de siempre (con la app Agenda) sobre el mundo, en pausa.
func abrir_telefono() -> void:
	if is_instance_valid(_capa_tel) or not expl.is_physics_processing():
		return
	_capa_tel = CanvasLayer.new()
	_capa_tel.layer = 45
	add_child(_capa_tel)
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_tel.add_child(raiz)
	var pop := Telefono.abrir(raiz, mundo)
	## La app «Red» busca el paradero más cercano al DT.
	for n in pop.find_children("*", "PanelContainer", true, false):
		if n is Telefono and is_instance_valid(expl.cuerpo):
			(n as Telefono).en_la_calle = true
			(n as Telefono).posicion_dt = expl.cuerpo.global_position
	expl.pausar(true)
	pop.tree_exited.connect(func() -> void:
		if is_instance_valid(expl):
			expl.pausar(false)
		if is_instance_valid(_capa_tel):
			_capa_tel.queue_free()
		_sincronizar_luz())

# ======================================================================= CALABOZO

## Tres multas por conducción temeraria: noche en el calabozo. −3 de confianza de la
## directiva y un titular, una vez por semana; el reloj salta a las 08:00.
func _calabozo() -> void:
	expl.multas = 0
	var clave := "%d|%d" % [mundo.anio, mundo.semana]
	if _calabozo_semana == clave:
		return
	_calabozo_semana = clave
	expl._fundido()
	mundo.reloj.esperar_hasta(CasaDT.HORA_LEVANTARSE, "dormir")
	if mundo.directiva != null:
		mundo.directiva.confianza = clampi(mundo.directiva.confianza - CONFIANZA_CALABOZO, 0, 100)
	if mundo.vida != null:
		mundo.vida.estres = clampi(mundo.vida.estres + ESTRES_CALABOZO, 0, 100)
		mundo.vida._anotar("Una noche en el calabozo por conducción temeraria.", mundo.anio, mundo.semana)
	_titular("El DT, una noche en comisaría por conducción temeraria", "Tres multas en una tarde. La directiva, «muy molesta».")
	_decir(Idiomas.t("Una noche en el calabozo"), Idiomas.t("Tres multas en una tarde: pasas la noche en comisaría. La directiva te lo descuenta en confianza y mañana sales en portada."))
	_tras_dormir()

# ========================================================================= AVISOS

func _titular(t: String, c: String, tipo: String = "mal") -> void:
	if mundo.prensa != null and mundo.prensa.titular_pendiente.is_empty():
		mundo.prensa.titular_pendiente = {"t": Idiomas.t(t), "c": Idiomas.t(c), "tipo": tipo, "medio": "La Tribuna"}

func _notificar(texto: String) -> void:
	if expl._movil != null:
		expl._movil.notificar(texto, 5.0)
	elif expl._aviso != null:
		expl._aviso.text = texto

## Un cuadro de diálogo corto (el de las charlas del paseo) que se cierra solo.
func _decir(titulo: String, texto: String) -> void:
	if _cuadro == null or not is_instance_valid(_cuadro):
		_cuadro = CuadroDialogo.new()
		add_child(_cuadro)
	_cuadro.decir(titulo, texto, Color(1.0, 0.86, 0.5), 0, 1)
	_t_cuadro = 5.0

## (§2.5, 31-10) Pagar con tarjeta enseña la tarjeta en la mano (`TarjetaMano`) con el importe.
var _tarjeta: TarjetaMano
func _al_pagar_con_tarjeta(importe: int, _concepto: String) -> void:
	if expl == null or not is_instance_valid(expl) or expl._capa == null:
		return
	if not is_instance_valid(_tarjeta):
		var titular := mundo.roles.nombre if mundo.roles != null else Idiomas.t("Entrenador")
		_tarjeta = TarjetaMano.crear("Banco Andino", String(titular), TarjetaMano.digitos_de(String(titular)))
		expl._capa.add_child(_tarjeta)
	_tarjeta.mostrar(importe)

## (31-10, decisión del dueño) La multa por conducción temeraria cuesta dinero: 60 € de la cartera del
## DT (efectivo y, si no alcanza, la tarjeta); si no puede pagarla, queda anotada. Sigue contando para el calabozo.
const MULTA_TEMERARIA := 60
var _titular_atropello := -1
func multa_temeraria() -> void:
	expl.multas += 1
	## Mejora F: si el golpe fue contra una persona, atropello con reacción (multa de 150 € y titular).
	var pe := AtropelloCiudad.peaton_delante(expl)
	if not pe.is_empty():
		AtropelloCiudad.reaccionar(expl, pe)
		_notificar(AtropelloCiudad.multar(self))
		return
	var via := ""
	if mundo.roles != null and mundo.roles.cartera != null:
		via = String(mundo.roles.cartera.cobrar(mundo.roles, MULTA_TEMERARIA, "Multa por conducción temeraria", CarteraDT.clave_dia(mundo.anio, mundo.semana, mundo.reloj.dia))["via"])
	if via != "":
		_notificar(Idiomas.t("🚓 Multa de %d € por conducción temeraria (%d de 3; pagada en %s).") % [MULTA_TEMERARIA, expl.multas, Idiomas.t(via)])
	else:
		_notificar(Idiomas.t("🚓 Multa de %d € por conducción temeraria (%d de 3): no pudiste pagarla y queda anotada.") % [MULTA_TEMERARIA, expl.multas])

## (31-10, mejora A del coche) El indicador de gasolina del HUD y del salpicadero: «⛽ 62 %» y, por
## debajo del 15 %, «⛽ 9 % · RESERVA» (la luz de reserva).
func reserva() -> bool:
	return mundo.vida != null and mundo.vida.fraccion_comb() < 0.15

func texto_gasolina() -> String:
	if mundo.vida == null:
		return ""
	var t := "⛽ %d %%" % roundi(mundo.vida.fraccion_comb() * 100.0)
	return t + " · " + Idiomas.t("RESERVA") if reserva() else t
