class_name VidaCiudad
extends "res://visor/vida_ciudad_p1.gd"
## (Parte 2 de 2 de `vida_ciudad.gd`.)

## Las redes de la ciudad (luz, agua, drenaje, gas), si la ciudad ya está levantada.
func _redes() -> RedesCiudadVista:
	if expl == null or expl.cb == null or expl.cb.expansion == null:
		return null
	return expl.cb.expansion.redes

## El depósito del coche (solo en coche y en la calle): gasta con la distancia, avisa al bajar del 15 % (una vez por semana)
## y vacío el coche no arranca hasta repostar en un surtidor (E).
func gasolina_tick(delta: float) -> void:
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

## E ante un surtidor: llena el depósito del coche a 1,4 €/l (10 minutos). Sin corriente en el sector, no hay bomba.
func usar_surtidor(k: String) -> bool:
	var redes := _redes()
	if not k.begins_with("surtidor_") or redes == null:
		return false
	var s := redes.surtidor(int(k.get_slice("_", 1)))
	if s.is_empty():
		return false
	var falta := VidaDT.DEPOSITO_L - mundo.vida.combustible if mundo.vida != null else 45.0
	if falta < 1.0:
		_decir(Idiomas.t("Gasolinera"), Idiomas.t("Tienes el depósito lleno."))
		return true
	## El DT paga de SU bolsillo (efectivo y, si no alcanza, la tarjeta sin contacto), no el club. Se mira ANTES de echar gasolina.
	var cartera: CarteraDT = mundo.roles.cartera if mundo.roles != null else null
	var dia := CarteraDT.clave_dia(mundo.anio, mundo.semana, mundo.reloj.dia)
	if cartera != null:
		var tope := roundi(minf(falta, float(redes.modelo.gas.get(int(s["id"]), 0.0))) * RedesCiudad.PRECIO_LITRO)
		var motivo := cartera.puede_cobrar(mundo.roles, tope, dia)
		if motivo != "" and tope > 0:
			_decir(Idiomas.t("Gasolinera"), CarteraDT.texto_error(motivo, tope))
			return true
	var r := redes.modelo.repostar(int(s["id"]), s["sector"], falta)
	if int(r["coste"]) <= 0:
		_decir(Idiomas.t("Gasolinera"), Idiomas.t("Sin corriente (o sin existencias): las bombas no funcionan."))
		return true
	mundo.reloj.avanzar_minutos(10, "libre")
	if mundo.vida != null:
		mundo.vida.combustible = minf(VidaDT.DEPOSITO_L, mundo.vida.combustible + float(r["litros"]))
	var via := ""
	if cartera != null:
		via = String(cartera.cobrar(mundo.roles, int(r["coste"]), "Gasolina", dia)["via"])
	elif mundo.mi_club() != null:
		mundo.mi_club().mover_saldo(-int(r["coste"]))   ## sin cartera (partida sin roles) paga el club, como antes: nunca gratis
	_decir(Idiomas.t("Gasolinera"), Idiomas.t("Depósito lleno: %d l por %d € (%s).") % [roundi(float(r["litros"])), int(r["coste"]), Idiomas.t(via if via != "" else "efectivo")])
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	return true

## E ante el mostrador de la tienda de la gasolinera: compra lo que pide el hambre y lo paga el DT (efectivo o tarjeta sin contacto).
func usar_tienda() -> bool:
	var it := TiendaGasolinera.elegir(mundo.necesidades.hambre() if mundo.necesidades != null else 50)
	var cartera: CarteraDT = mundo.roles.cartera if mundo.roles != null else null
	if cartera == null:
		return false
	var dia := CarteraDT.clave_dia(mundo.anio, mundo.semana, mundo.reloj.dia)
	var r := cartera.cobrar(mundo.roles, int(it["precio"]), String(it["nombre"]), dia)
	if String(r["error"]) != "":
		_decir(Idiomas.t("Tienda de la gasolinera"), CarteraDT.texto_error(String(r["error"]), int(it["precio"])))
		return true
	if mundo.necesidades != null:
		mundo.necesidades.picar(int(it["hambre"]))
	_decir(Idiomas.t("Tienda de la gasolinera"), Idiomas.t("%s por %d € (%s).") % [Idiomas.t(String(it["nombre"])), int(it["precio"]), Idiomas.t(String(r["via"]))])
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	return true

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
